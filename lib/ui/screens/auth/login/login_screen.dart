import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/auth/login_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/ui/screens/auth/widgets/forgot_password_bottom_sheet.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/screens/widgets/phone_input.dart';
import 'package:eClassify/ui/screens/widgets/skip_button_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  final bool? popToCurrent;
  final String? email;

  const LoginScreen({super.key, this.popToCurrent, this.email});

  @override
  State<LoginScreen> createState() => LoginScreenState();

  static MaterialPageRoute route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      settings: routeSettings,
      builder: (_) => LoginScreen(
        popToCurrent: args?['popToCurrent'],
        email: args?['email'] as String?,
      ),
    );
  }
}

class LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.email,
  );
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phonePasswordController =
      TextEditingController();
  final PhoneInputController _phoneInputController = PhoneInputController();
  String phoneCode = AppConfig.defaultPhoneCode;
  bool isResendEnabled = false;
  bool isLoginButtonDisabled = true;
  late final ValueNotifier<bool> isLoginWithMobile = ValueNotifier(
    widget.email == null || widget.email!.isEmpty,
  );
  bool sendMailClicked = false;
  final _formKey = GlobalKey<FormState>();

  bool isObscure = true;
  bool isPhonePasswordObscure = true;
  late PhoneLoginPayload phoneLoginPayload;
  bool isBack = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthenticationCubit>().init();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _phonePasswordController.dispose();
    _emailController.dispose();
    isLoginWithMobile.dispose();
    super.dispose();
  }

  void _onTapContinue() {
    if (_formKey.currentState!.validate()) {
      if (isLoginWithMobile.value) {
        // Phone login requires password (no OTP flow)
        if (_phonePasswordController.text.trim().isEmpty) {
          HelperUtils.showSnackBarMessage(
            context,
            'Password is required for phone login',
          );
          return;
        }

        // Direct login with phone + password
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
        context.read<AuthenticationCubit>().authenticateWithPhonePassword();

        setState(() {});
      } else {
        sendMailClicked = true;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedSafeArea(
      isAnnotated: true,
      navigationBarColor: context.color.backgroundColor,
      statusBarColor: context.color.backgroundColor,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PopScope(
          canPop: isBack,
          onPopInvokedWithResult: (didPop, result) {
            if (sendMailClicked) {
              setState(() {
                sendMailClicked = false;
              });
            } else {
              setState(() {
                isBack = true;
              });
              return;
            }
            setState(() {
              isBack = false;
            });
            return;
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: context.color.backgroundColor,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SkipButtonWidget(
                    labelKey: 'continueAsGuest',
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
            backgroundColor: context.color.backgroundColor,
            bottomNavigationBar: !sendMailClicked
                ? termAndPolicyTxt()
                : SizedBox.shrink(),
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
                      arguments: {'from': 'login'},
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
                  log('${state.errorMessage}');
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
                    LoadingWidgets.hideLoader(context);

                    if (state.type == AuthenticationType.email) {
                      if (state.credential.user!.emailVerified) {
                        context.read<LoginCubit>().login(
                          firebaseUserId: state.credential.user!.uid,
                          type: state.type.name,
                          credential: state.credential,
                          countryCode: null,
                        );
                      }
                    } else if (state.type == AuthenticationType.phone) {
                      final payload = state.payload as PhoneLoginPayload;

                      // Check if it's password-based login
                      if (state.credential is Map &&
                          state.credential['type'] == 'phone_password') {
                        context.read<LoginCubit>().loginWithPhonePassword(
                          phoneNumber: payload.phoneNumber,
                          password: payload.password!,
                          phoneCode: "+${payload.phoneCode}",
                          regionCode: payload.regionCode,
                        );
                      } else if (Constant.otpServiceProvider == 'twilio') {
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
                    } else {
                      context.read<LoginCubit>().login(
                        firebaseUserId: state.credential.user!.uid,
                        type: state.type.name,
                        credential: state.credential,
                        countryCode: null,
                      );
                    }
                  }

                  if (state is AuthenticationFail) {
                    log('fail ${state.errorKey}');
                    HelperUtils.showSnackBarMessage(
                      context,
                      state.errorKey.translate(context),
                    );
                    LoadingWidgets.hideLoader(context);
                  }

                  if (state is AuthenticationInProcess) {
                    LoadingWidgets.showLoader(context);
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: Form(key: _formKey, child: buildLoginWidget()),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mobileLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'loginWithPhoneNumber'.translate(context),
          fontSize: context.font.large,
          color: context.color.textColorDark,
        ),
        const SizedBox(height: 24),
        PhoneInput(controller: _phoneInputController),
        const SizedBox(height: 10),
        CustomTextFormField(
          hintText: "${"password".translate(context)}",
          controller: _phonePasswordController,
          validator: CustomTextFieldValidator.password,
          obscureText: isPhonePasswordObscure,
          suffix: IconButton(
            onPressed: () {
              isPhonePasswordObscure = !isPhonePasswordObscure;
              setState(() {});
            },
            icon: Icon(
              !isPhonePasswordObscure ? Icons.visibility : Icons.visibility_off,
              color: context.color.textColorDark.withValues(alpha: 0.3),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: context.color.textLightColor,
            ),
            onPressed: () {
              // Validate phone before showing bottom sheet
              String? prefilledPhone;
              String? prefilledRegionCode;
              if (_phoneInputController.phoneNumber.isNotEmpty) {
                prefilledPhone = _phoneInputController.phoneNumber;
                prefilledRegionCode = _phoneInputController.regionCode;
              }

              UiUtils.showBottomSheet(
                context,
                child: ForgotPasswordBottomSheet(
                  isEmailMode: false,
                  prefilledPhone: prefilledPhone,
                  prefilledRegionCode: prefilledRegionCode,
                ),
              );
            },
            child: CustomText(
              "${"forgotPassword".translate(context)}?",
              color: context.color.textLightColor,
              fontSize: context.font.normal,
            ),
          ),
        ),
        const SizedBox(height: 8),
        UiUtils.buildButton(
          context,
          onPressed: _onTapContinue,
          buttonTitle: 'continue'.translate(context),
          radius: 10,
          disabledColor: const Color.fromARGB(255, 104, 102, 106),
        ),
      ],
    );
  }

  Widget emailLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'loginWithEmail'.translate(context),
          fontSize: context.font.large,
          color: context.color.textColorDark,
        ),
        const SizedBox(height: 24),
        CustomTextFormField(
          controller: _emailController,
          fillColor: context.color.secondaryColor,
          borderColor: context.color.textLightColor.withValues(alpha: 0.2),
          keyboard: TextInputType.emailAddress,
          validator: CustomTextFieldValidator.email,
          hintText: "emailAddress".translate(context),
        ),
        const SizedBox(height: 10),
        CustomTextFormField(
          hintText: "${"password".translate(context)}",
          controller: _passwordController,
          validator: CustomTextFieldValidator.nullCheck,
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
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: context.color.textLightColor,
            ),
            onPressed: () {
              // Validate email before showing bottom sheet
              String? prefilledEmail;
              if (_emailController.text.isNotEmpty &&
                  Validator.validateEmail(
                        email: _emailController.text,
                        context: context,
                      ) ==
                      null) {
                prefilledEmail = _emailController.text;
              }

              UiUtils.showBottomSheet(
                context,
                child: ForgotPasswordBottomSheet(
                  isEmailMode: true,
                  prefilledEmail: prefilledEmail,
                ),
              );
            },
            child: CustomText(
              "${"forgotPassword".translate(context)}?",
              color: context.color.textLightColor,
              fontSize: context.font.normal,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: Listenable.merge([_emailController, _passwordController]),
          builder: (context, child) {
            return UiUtils.buildButton(
              context,
              onPressed: () {
                if (_passwordController.text.trim().isEmpty) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    'Password cannot be empty',
                  );
                  return;
                }
                context.read<AuthenticationCubit>().setData(
                  payload: EmailLoginPayload(
                    email: _emailController.text,
                    password: _passwordController.text,
                    type: EmailLoginType.login,
                  ),
                  type: AuthenticationType.email,
                );
                context.read<AuthenticationCubit>().authenticate();
              },
              buttonTitle: 'signIn'.translate(context),
              radius: 10,
              disabled:
                  _emailController.text.isEmpty ||
                  _passwordController.text.isEmpty,
              disabledColor: const Color.fromARGB(255, 104, 102, 106),
            );
          },
        ),
      ],
    );
  }

  Widget buildLoginWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "welcomeback".translate(context),
            fontSize: context.font.extraLarge,
            color: context.color.textDefaultColor,
          ),
          const SizedBox(height: 8),
          if (Constant.mobileAuthentication == "1" ||
              Constant.emailAuthentication == "1")
            ValueListenableBuilder(
              valueListenable: isLoginWithMobile,
              builder: (context, isMobileLogin, child) {
                return isMobileLogin ? mobileLogin() : emailLogin();
              },
            ),
          const SizedBox(height: 20),
          if (Constant.emailAuthentication == "1")
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "dontHaveAcc".translate(context),
                  color: context.color.textColorDark.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, Routes.signup);
                  },
                  child: CustomText(
                    "signUp".translate(context),
                    color: context.color.territoryColor,
                    showUnderline: true,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          ...googleAndAppleLogin(),
        ],
      ),
    );
  }

  List<Widget> googleAndAppleLogin() {
    return [
      if (Constant.mobileAuthentication == "1" ||
          Constant.emailAuthentication == "1")
        if ((Constant.googleAuthentication == "1") ||
            (Constant.appleAuthentication == "1" && Platform.isIOS))
          Align(
            alignment: Alignment.center,
            child: CustomText(
              "orSignInWith".translate(context),
              color: context.color.textDefaultColor,
            ),
          ),
      const SizedBox(height: 20),
      if (Constant.googleAuthentication == "1") ...[
        UiUtils.buildButton(
          context,
          prefixWidget: Padding(
            padding: EdgeInsetsDirectional.only(end: 10.0),
            child: UiUtils.getSvg(AppIcons.googleIcon, width: 22, height: 22),
          ),
          showElevation: false,
          buttonColor: secondaryColor_,
          border: !AppSession.isDarkMode
              ? BorderSide(
                  color: context.color.textDefaultColor.withValues(alpha: 0.5),
                )
              : null,
          textColor: textDarkColor,
          onPressed: () {
            context.read<AuthenticationCubit>().setData(
              payload: GoogleLoginPayload(),
              type: AuthenticationType.google,
            );
            context.read<AuthenticationCubit>().authenticate();
          },
          radius: 8,
          height: 46,
          buttonTitle: "continueWithGoogle".translate(context),
        ),
        const SizedBox(height: 12),
      ],
      if (Constant.appleAuthentication == "1" && Platform.isIOS) ...[
        UiUtils.buildButton(
          context,
          prefixWidget: Padding(
            padding: EdgeInsetsDirectional.only(end: 10.0),
            child: UiUtils.getSvg(AppIcons.appleIcon, width: 22, height: 22),
          ),
          showElevation: false,
          buttonColor: secondaryColor_,
          border: !AppSession.isDarkMode
              ? BorderSide(
                  color: context.color.textDefaultColor.withValues(alpha: 0.5),
                )
              : null,
          textColor: textDarkColor,
          onPressed: () {
            context.read<AuthenticationCubit>().setData(
              payload: AppleLoginPayload(),
              type: AuthenticationType.apple,
            );
            context.read<AuthenticationCubit>().authenticate();
          },
          height: 46,
          radius: 8,
          buttonTitle: "continueWithApple".translate(context),
        ),
        const SizedBox(height: 12),
      ],
      if (Constant.emailAuthentication == "1" &&
          Constant.mobileAuthentication == "1")
        ValueListenableBuilder(
          valueListenable: isLoginWithMobile,
          builder: (context, isMobileField, child) {
            return UiUtils.buildButton(
              context,
              onPressed: () {
                isLoginWithMobile.value = !isLoginWithMobile.value;
                _phoneInputController.clear();
                _emailController.clear();
              },
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child: Icon(
                  isMobileField ? Icons.email : Icons.phone,
                  color: textDarkColor,
                ),
              ),
              showElevation: false,
              buttonColor: secondaryColor_,
              textColor: textDarkColor,
              border: !AppSession.isDarkMode
                  ? BorderSide(
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.5,
                      ),
                    )
                  : null,
              height: 46,
              radius: 8,
              buttonTitle:
                  (isMobileField ? 'continueWithEmail' : 'continueWithMobile')
                      .translate(context),
            );
          },
        ),
    ];
  }

  Widget termAndPolicyTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 25.0, end: 25.0),
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
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                  showUnderline: true,
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
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                  showUnderline: true,
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

  Widget enterPasswordWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkipButtonWidget(
            labelKey: 'continueAsGuest',
            onTap: () {
              HelperUtils.killPreviousPages(context, Routes.main, {
                "from": "login",
                "isSkipped": true,
              });
            },
          ),
          const SizedBox(height: 66),
          CustomText(
            "signInWithEmail".translate(context),
            fontSize: context.font.extraLarge,
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 19),
          UiUtils.buildButton(
            context,
            onPressed: () {
              if (_passwordController.text.trim().isEmpty) {
                HelperUtils.showSnackBarMessage(
                  context,
                  'passwordCanNotBeEmpty'.translate(context),
                );
                return;
              }
              context.read<AuthenticationCubit>().setData(
                payload: EmailLoginPayload(
                  email: _emailController.text,
                  password: _passwordController.text,
                  type: EmailLoginType.login,
                ),
                type: AuthenticationType.email,
              );
              context.read<AuthenticationCubit>().authenticate();
            },
            buttonTitle: "signIn".translate(context),
            radius: 8,
          ),
        ],
      ),
    );
  }
}
