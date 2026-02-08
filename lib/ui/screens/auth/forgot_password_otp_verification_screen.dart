import 'dart:async';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/auth/login_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/login/lib/login_status.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_autofill/sms_autofill.dart';

class ForgotPasswordOtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String phoneCode;
  final String regionCode;

  const ForgotPasswordOtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.phoneCode,
    required this.regionCode,
  });

  static MaterialPageRoute route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return ForgotPasswordOtpVerificationScreen(
          phoneNumber: args['phoneNumber'] as String,
          phoneCode: args['phoneCode'] as String,
          regionCode: args['regionCode'] as String,
        );
      },
    );
  }

  @override
  State<ForgotPasswordOtpVerificationScreen> createState() =>
      _ForgotPasswordOtpVerificationScreenState();
}

class _ForgotPasswordOtpVerificationScreenState
    extends State<ForgotPasswordOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? otp;
  bool isResendEnabled = false;
  int _start = 60;
  Timer? _resendTimer;
  String? signature;
  SmsAutoFill smsAutoFill = SmsAutoFill();
  bool isOtpSent = false;

  late PhoneLoginPayload phoneLoginPayload;

  @override
  void initState() {
    super.initState();
    getSignature();
    context.read<AuthenticationCubit>().init();
    context.read<AuthenticationCubit>().listen((MLoginState state) {
      if (state is MOtpSendInProgress) {
        if (mounted) LoadingWidgets.showLoader(context);
      }

      if (state is MVerificationPending) {
        if (mounted) {
          LoadingWidgets.hideLoader(context);
          isOtpSent = true;
          setState(() {});
          HelperUtils.showSnackBarMessage(
            context,
            "optsentsuccessflly".translate(context),
          );
        }
      }

      if (state is MFail) {
        if (mounted) {
          LoadingWidgets.hideLoader(context);
          if (state.error case FirebaseAuthException e) {
            final message = switch (e.code) {
              'session-expired' => e.message,
              'invalid-verification-code' => e.message,
              _ => 'defaultErrorMsg'.translate(context),
            };
            HelperUtils.showSnackBarMessage(
              context,
              message ?? 'defaultErrorMsg'.translate(context),
            );
          } else {
            HelperUtils.showSnackBarMessage(context, state.error.toString());
          }
        }
      }
    });

    // Send OTP after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      phoneLoginPayload = PhoneLoginPayload(
        widget.phoneNumber,
        widget.phoneCode,
        widget.regionCode,
      );

      context.read<AuthenticationCubit>().setData(
        payload: phoneLoginPayload,
        type: AuthenticationType.phone,
      );
      context.read<AuthenticationCubit>().verify();

      startResendOtpTimer();
    });
  }

  @override
  void dispose() {
    smsAutoFill.unregisterListener();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> getSignature() async {
    signature = await smsAutoFill.getAppSignature;
    smsAutoFill.listenForCode;
    setState(() {});
  }

  void startResendOtpTimer() {
    setState(() {
      isResendEnabled = false;
      _start = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          isResendEnabled = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void onVerifyOTP() {
    if (otp == null || otp!.trim().length < 6) {
      HelperUtils.showSnackBarMessage(
        context,
        "pleaseEnterSixDigits".translate(context),
      );
      return;
    }

    phoneLoginPayload.setOTP(otp!.trim());
    context.read<AuthenticationCubit>().authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      body: Padding(
        padding: Constant.appContentPadding,
        child: MultiBlocListener(
          listeners: [
            BlocListener<LoginCubit, LoginState>(
              listener: (context, state) {
                if (state is LoginInProgress) {
                  LoadingWidgets.showLoader(context);
                }
                if (state is LoginSuccess) {
                  LoadingWidgets.hideLoader(context);
                  context.read<UserDetailsCubit>().fill(
                    HiveUtils.getUserDetails(),
                  );
                  if (state.isProfileCompleted) {
                    HiveUtils.setUserIsAuthenticated(true);
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.resetPassword,
                    (route) => false,
                    arguments: {
                      'phoneNumber': widget.phoneNumber,
                      'phoneCode': widget.phoneCode,
                      'regionCode': widget.regionCode,
                    },
                  );
                }

                if (state is LoginFailure) {
                  LoadingWidgets.hideLoader(context);
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.errorMessage.toString(),
                  );
                }
              },
            ),
            BlocListener<AuthenticationCubit, AuthenticationState>(
              listener: (context, state) {
                if (state is AuthenticationSuccess) {
                  LoadingWidgets.hideLoader(context);

                  final payload = state.payload as PhoneLoginPayload;

                  if (Constant.otpServiceProvider == 'twilio') {
                    context.read<LoginCubit>().loginWithTwilio(
                      phoneNumber: payload.phoneNumber,
                      firebaseUserId: state.credential['id']?.toString() ?? '',
                      type: state.type.name,
                      credential: state.credential,
                      countryCode: "+${payload.phoneCode}",
                      regionCode: payload.regionCode,
                    );
                  } else {
                    context.read<LoginCubit>().login(
                      phoneNumber: payload.phoneNumber,
                      firebaseUserId: state.credential.user!.uid,
                      type: state.type.name,
                      credential: state.credential,
                      countryCode: "+${payload.phoneCode}",
                      regionCode: payload.regionCode,
                    );
                  }
                }

                if (state is AuthenticationFail) {
                  LoadingWidgets.hideLoader(context);
                  // HelperUtils.showSnackBarMessage(
                  //   context,
                  //   state.errorKey.translate(context),
                  //   type: MessageType.error,
                  // );
                }

                if (state is AuthenticationInProcess) {
                  LoadingWidgets.showLoader(context);
                }
              },
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 66),
                CustomText(
                  "verifyPhoneNumber".translate(context),
                  fontSize: context.font.extraLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CustomText(
                      '${widget.phoneCode} ${widget.phoneNumber}',
                      fontSize: context.font.large,
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      child: CustomText(
                        "change".translate(context),
                        color: context.color.territoryColor,
                        fontSize: context.font.large,
                        showUnderline: true,
                      ),
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(Routes.login);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: PinFieldAutoFill(
                    decoration: UnderlineDecoration(
                      textStyle: TextStyle(
                        fontSize: 20,
                        color: context.color.textColorDark,
                      ),
                      colorBuilder: FixedColorBuilder(
                        context.color.territoryColor,
                      ),
                    ),
                    currentCode: otp,
                    codeLength: 6,
                    onCodeChanged: (String? code) {
                      otp = code;
                    },
                    onCodeSubmitted: (String code) {
                      otp = code;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: isResendEnabled
                      ? MaterialButton(
                          onPressed: () {
                            context.read<AuthenticationCubit>().setData(
                              payload: phoneLoginPayload,
                              type: AuthenticationType.phone,
                            );
                            context.read<AuthenticationCubit>().verify();
                            startResendOtpTimer();
                          },
                          child: CustomText(
                            "resendOTP".translate(context),
                            color: context.color.territoryColor,
                          ),
                        )
                      : CustomText(
                          "${"resendOtpIn".translate(context)} 0:${_start.toString().padLeft(2, '0')}",
                          color: context.color.textColorDark.withValues(
                            alpha: 0.7,
                          ),
                        ),
                ),
                const SizedBox(height: 19),
                UiUtils.buildButton(
                  context,
                  onPressed: onVerifyOTP,
                  buttonTitle: "verify".translate(context),
                  radius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
