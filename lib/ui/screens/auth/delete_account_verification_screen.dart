import 'dart:async';

import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/ui/theme/theme.dart';
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

class DeleteAccountVerificationScreen extends StatefulWidget {
  const DeleteAccountVerificationScreen({super.key});

  static MaterialPageRoute route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return const DeleteAccountVerificationScreen();
      },
    );
  }

  @override
  State<DeleteAccountVerificationScreen> createState() =>
      _DeleteAccountVerificationScreenState();
}

class _DeleteAccountVerificationScreenState
    extends State<DeleteAccountVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? otp;
  bool isResendEnabled = false;
  int _start = 60;
  Timer? _resendTimer;
  late PhoneLoginPayload phoneLoginPayload;
  String? signature;
  SmsAutoFill smsAutoFill = SmsAutoFill();
  bool isOtpSent = false;

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
      _sendOTP();
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
      _start = 60;
      isResendEnabled = false;
    });

    _resendTimer?.cancel();
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

  void _sendOTP() {
    final userDetails = HiveUtils.getUserDetails();
    final phoneNumber = userDetails.mobile;
    final countryCode = userDetails.countryCode ?? '+1';
    final regionCode = userDetails.regionCode ?? 'US';

    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        HelperUtils.showSnackBarMessage(context, 'Phone number not found');
        Navigator.pop(context);
      }
      return;
    }

    startResendOtpTimer();

    phoneLoginPayload = PhoneLoginPayload(
      phoneNumber,
      countryCode.replaceAll('+', ''),
      regionCode,
    );

    context.read<AuthenticationCubit>().setData(
      payload: phoneLoginPayload,
      type: AuthenticationType.phone,
    );
    context.read<AuthenticationCubit>().verify();
  }

  void _verifyOTPAndDelete() {
    if (otp == null || otp!.trim().length < 6) {
      HelperUtils.showSnackBarMessage(
        context,
        "pleaseEnterSixDigits".translate(context),
      );
      return;
    }

    // Set OTP in payload and authenticate
    phoneLoginPayload.setOTP(otp!.trim());
    context.read<AuthenticationCubit>().authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // NOTE: The Listener for DeleteUserCubit is also handled by profile_screen
        // and hence is not used here to process the deletion going forward.
        BlocListener<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationInProcess) {
              LoadingWidgets.showLoader(context);
            }

            if (state is AuthenticationSuccess) {
              // OTP verified successfully, now delete the user
              LoadingWidgets.hideLoader(context);
              context.read<AuthenticationCubit>().deleteUser();
            }

            if (state is AuthenticationFail) {
              LoadingWidgets.hideLoader(context);
              // HelperUtils.showSnackBarMessage(
              //   context,
              //   state.errorKey.translate(context),
              // );
            }

            if (state is AuthenticationUserDeleted) {
              // User deleted from Firebase, now call backend API
              // NOTE: The listener for this is set in profile_screen which handles
              // navigation and session clearing.
              // A really bad way to handle this but since both these screens are listening
              // to same cubit events, the navigation happens twice leading black screen states.
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.color.backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.color.textColorDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: CustomText(
            "verifyAccount".translate(context),
            fontSize: context.font.large,
            fontWeight: FontWeight.w600,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                CustomText(
                  "deleteAccountVerification".translate(context),
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 12),
                CustomText(
                  "weNeedToVerifyIdentity".translate(context),
                  fontSize: context.font.normal,
                  color: context.color.textColorDark.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                CustomText(
                  HiveUtils.getUserDetails().mobile != null
                      ? "${HiveUtils.getUserDetails().countryCode ?? ''}${HiveUtils.getUserDetails().mobile}"
                      : '',
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 32),
                if (isOtpSent) ...[
                  CustomText(
                    "enterOTP".translate(context),
                    fontSize: context.font.normal,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 32),
                  UiUtils.buildButton(
                    context,
                    onPressed: _verifyOTPAndDelete,
                    buttonTitle: "verifyAndDelete".translate(context),
                    radius: 8,
                  ),
                ] else ...[
                  Center(
                    child: CircularProgressIndicator(
                      color: context.color.territoryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
