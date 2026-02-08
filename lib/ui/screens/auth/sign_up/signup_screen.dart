import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/auth/login_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/ui/screens/auth/sign_up/email_verification_screen.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/screens/widgets/phone_input.dart';
import 'package:eClassify/ui/screens/widgets/skip_button_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static MaterialPageRoute route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return SignupScreen();
      },
    );
  }

  @override
  CloudState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends CloudState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phonePasswordController =
      TextEditingController();
  final PhoneInputController _phoneInputController = PhoneInputController();
  final TextEditingController _otpController = TextEditingController();

  bool isObscure = true;
  bool isPhonePasswordObscure = true;
  late final ValueNotifier<bool> isSignupWithMobile = ValueNotifier(false);
  bool isOtpSent = false;
  String? otp;
  bool isResendEnabled = false;
  int _start = 60;
  Timer? _resendTimer;
  late PhoneLoginPayload phoneLoginPayload;
  String? signature;
  SmsAutoFill smsAutoFill = SmsAutoFill();

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
          if (isSignupWithMobile.value) {
            HelperUtils.showSnackBarMessage(
              context,
              "optsentsuccessflly".translate(context),
            );
          }
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
  }

  @override
  void dispose() {
    smsAutoFill.unregisterListener();
    _otpController.dispose();
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _phonePasswordController.dispose();
    isSignupWithMobile.dispose();
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
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  void onTapSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (isSignupWithMobile.value) {
        // Mobile signup - send OTP
        if (_phonePasswordController.text.trim().isEmpty) {
          HelperUtils.showSnackBarMessage(context, 'Password is required');
          return;
        }

        phoneLoginPayload = PhoneLoginPayload(
          _phoneInputController.phoneNumber,
          _phoneInputController.phoneCode,
          _phoneInputController.regionCode,
          password: _phonePasswordController.text.trim(),
        );

        context.read<AuthenticationCubit>().setData(
          payload: phoneLoginPayload,
          type: AuthenticationType.phone,
        );

        final userExists = await context
            .read<AuthenticationCubit>()
            .checkIfPhoneUserExists();
        if (userExists) {
          HelperUtils.showSnackBarMessage(
            context,
            'userAlreadyExists'.translate(context),
          );
        } else {
          context.read<AuthenticationCubit>().verify();
          startResendOtpTimer();
        }
      } else {
        // Email signup
        context.read<AuthenticationCubit>().setData(
          payload: EmailLoginPayload(
            email: _emailController.text,
            password: _passwordController.text,
            type: EmailLoginType.signup,
          ),
          type: AuthenticationType.email,
        );
        context.read<AuthenticationCubit>().authenticate();
      }

      _phoneInputController.clear();
      _passwordController.clear();
      _emailController.clear();
    }
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
    return SafeArea(
      top: false,
      bottom: Platform.isIOS,
      child: AnnotatedRegion(
        value: UiUtils.getSystemUiOverlayStyle(
          context: context,
          statusBarColor: context.color.backgroundColor,
          navigationBarColor: context.color.backgroundColor,
        ),
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          bottomNavigationBar: termAndPolicyTxt(),
          appBar: AppBar(
            backgroundColor: context.color.primaryColor,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SkipButtonWidget(
                  onTap: () {
                    HelperUtils.killPreviousPages(context, Routes.main, {
                      "from": "login",
                      "isSkipped": true,
                    });
                  },
                ),
              ),
            ],
          ),
          body: BlocListener<LoginCubit, LoginState>(
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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.main,
                    (route) => false,
                    arguments: {'from': 'signup'},
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    Routes.completeProfile,
                    arguments: {"from": "login", "popToCurrent": false},
                  );
                }
              }

              if (state is LoginFailure) {
                LoadingWidgets.hideLoader(context);
                HelperUtils.showSnackBarMessage(
                  context,
                  state.errorMessage.toString(),
                );
              }
            },
            child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
              listener: (context, state) {
                if (state is AuthenticationSuccess) {
                  if (state.type == AuthenticationType.email) {
                    if (!state.credential.user!.emailVerified) {
                      FirebaseAuth.instance.currentUser
                          ?.sendEmailVerification();

                      Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return EmailVerificationScreen(
                              email: _emailController.text,
                            );
                          },
                        ),
                      );
                    }
                  } else if (state.type == AuthenticationType.phone) {
                    // Phone signup - login directly after OTP verification
                    final payload = state.payload as PhoneLoginPayload;
                    LoadingWidgets.hideLoader(context);

                    log('${state.credential}');

                    if (Constant.otpServiceProvider == 'twilio') {
                      context.read<LoginCubit>().loginWithTwilio(
                        phoneNumber: payload.phoneNumber,
                        firebaseUserId:
                            state.credential['id']?.toString() ?? '',
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
                }

                if (state is AuthenticationFail) {
                  if (context.read<AuthenticationCubit>().payload
                      is! PhoneLoginPayload) {
                    {
                      HelperUtils.showSnackBarMessage(
                        context,
                        state.errorKey.translate(context),
                      );
                    }
                    LoadingWidgets.hideLoader(context);
                  }
                }

                if (state is AuthenticationInProcess) {
                  LoadingWidgets.showLoader(context);
                }
              },
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 18.0,
                        right: 18,
                        top: 23,
                      ),
                      child: isOtpSent
                          ? buildVerifyOTPWidget()
                          : buildSignupWidget(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSignupWidget() {
    return ValueListenableBuilder(
      valueListenable: isSignupWithMobile,
      builder: (context, isMobileSignup, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 66),
            CustomText(
              "welcome".translate(context),
              fontSize: context.font.extraLarge,
            ),
            const SizedBox(height: 8),
            CustomText(
              "signUp".translate(context),
              fontSize: context.font.large,
              color: context.color.textColorDark.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            if (isMobileSignup) ...[
              // Mobile signup
              PhoneInput(controller: _phoneInputController),
              const SizedBox(height: 10),
              CustomTextFormField(
                hintText: "${"password".translate(context)}",
                controller: _phonePasswordController,
                validator: CustomTextFieldValidator.nullCheck,
                obscureText: isPhonePasswordObscure,
                fillColor: context.color.secondaryColor,
                borderColor: context.color.textLightColor.withValues(
                  alpha: 0.3,
                ),
                suffix: IconButton(
                  onPressed: () {
                    isPhonePasswordObscure = !isPhonePasswordObscure;
                    setState(() {});
                  },
                  icon: Icon(
                    !isPhonePasswordObscure
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: context.color.textColorDark.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ] else ...[
              // Email signup
              CustomTextFormField(
                controller: _emailController,
                fillColor: context.color.secondaryColor,
                validator: CustomTextFieldValidator.email,
                hintText: "emailAddress".translate(context),
                borderColor: context.color.textLightColor.withValues(
                  alpha: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              CustomTextFormField(
                controller: _passwordController,
                fillColor: context.color.secondaryColor,
                obscureText: isObscure,
                suffix: IconButton(
                  onPressed: () {
                    isObscure = !isObscure;
                    setState(() {});
                  },
                  icon: Icon(
                    !isObscure ? Icons.visibility : Icons.visibility_off,
                    color: context.color.textColorDark.withValues(alpha: 0.3),
                  ),
                ),
                hintText: "password".translate(context),
                validator: CustomTextFieldValidator.password,
                borderColor: context.color.textLightColor.withValues(
                  alpha: 0.3,
                ),
              ),
            ],
            const SizedBox(height: 36),
            UiUtils.buildButton(
              context,
              onPressed: onTapSignup,
              buttonTitle: isMobileSignup
                  ? "sendOTP".translate(context)
                  : "verifyEmailAddress".translate(context),
              radius: 10,
              disabled: false,
              height: 46,
              disabledColor: const Color.fromARGB(255, 104, 102, 106),
            ),
            const SizedBox(height: 24),
            // Toggle between email and mobile
            if (Constant.mobileAuthentication == "1" &&
                Constant.emailAuthentication == "1")
              Center(
                child: UiUtils.buildButton(
                  context,
                  onPressed: () {
                    isSignupWithMobile.value = !isSignupWithMobile.value;
                    _phoneInputController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                    _phonePasswordController.clear();
                  },
                  prefixWidget: Padding(
                    padding: EdgeInsetsDirectional.only(end: 10.0),
                    child: Icon(
                      isMobileSignup ? Icons.email : Icons.phone,
                      color: textDarkColor,
                    ),
                  ),
                  showElevation: false,
                  buttonColor: secondaryColor_,
                  textColor: textDarkColor,
                  border: BorderSide(
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  height: 46,
                  radius: 8,
                  buttonTitle:
                      (isMobileSignup
                              ? 'continueWithEmail'
                              : 'continueWithMobile')
                          .translate(context),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "alreadyHaveAcc".translate(context),
                  color: context.color.textColorDark.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, Routes.login);
                  },
                  child: CustomText(
                    "login".translate(context),
                    showUnderline: true,
                    color: context.color.territoryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget buildVerifyOTPWidget() {
    return Padding(
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
                _phoneInputController.formattedNumber,
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
                  setState(() {
                    isOtpSent = false;
                  });
                  _otpController.clear();
                  _phoneInputController.clear();
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
                colorBuilder: FixedColorBuilder(context.color.territoryColor),
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
                    color: context.color.textColorDark.withValues(alpha: 0.7),
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
    );
  }

  Widget termAndPolicyTxt() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "bySigningUpLoggingIn".translate(context),
            color: context.color.textLightColor.withValues(alpha: 0.8),
            fontSize: context.font.small,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                child: CustomText(
                  "termsOfService".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {
                    'title': "termsConditions".translate(context),
                    'param': Api.termsAndConditions,
                  },
                ),
              ),
              const SizedBox(width: 5.0),
              CustomText(
                "andTxt".translate(context),
                color: context.color.textLightColor.withValues(alpha: 0.8),
                fontSize: context.font.small,
              ),
              const SizedBox(width: 5.0),
              InkWell(
                child: CustomText(
                  "privacyPolicy".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {
                    'title': "privacyPolicy".translate(context),
                    'param': Api.privacyPolicy,
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
