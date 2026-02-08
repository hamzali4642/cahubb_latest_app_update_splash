import 'dart:developer';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/repositories/auth_repository.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/screens/widgets/phone_input.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordBottomSheet extends StatefulWidget {
  final String? prefilledEmail;
  final String? prefilledPhone;
  final String? prefilledRegionCode;
  final bool isEmailMode;

  const ForgotPasswordBottomSheet({
    super.key,
    this.prefilledEmail,
    this.prefilledPhone,
    this.prefilledRegionCode,
    required this.isEmailMode,
  });

  @override
  State<ForgotPasswordBottomSheet> createState() =>
      _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  late final TextEditingController _emailController;
  late final FocusNode _focusNode = FocusNode(canRequestFocus: false);
  late final PhoneInputController _phoneInputController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepository _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  late bool _isEmailMode;

  @override
  void initState() {
    super.initState();
    _isEmailMode = widget.isEmailMode;
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    _phoneInputController = PhoneInputController();

    if (widget.prefilledPhone != null && widget.prefilledPhone!.isNotEmpty) {
      _phoneInputController.phoneNumber = widget.prefilledPhone!;
      if (widget.prefilledRegionCode != null) {
        _phoneInputController.regionCode = widget.prefilledRegionCode!;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailReset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      LoadingWidgets.showLoader(context);
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      LoadingWidgets.hideLoader(context);

      if (!mounted) return;

      HelperUtils.showSnackBarMessage(
        context,
        "resetPasswordSuccess".translate(context),
        type: MessageType.success,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      LoadingWidgets.hideLoader(context);

      if (!mounted) return;

      if (e.code == 'user-not-found') {
        HelperUtils.showSnackBarMessage(
          context,
          "userNotFound".translate(context),
          type: MessageType.error,
        );
      } else {
        HelperUtils.showSnackBarMessage(
          context,
          e.toString(),
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _handlePhoneReset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      LoadingWidgets.showLoader(context);

      // Check if user exists with this phone number
      final userExists = await _authRepository.checkUserExists(
        phoneNumber: _phoneInputController.phoneNumber,
        countryCode: "${_phoneInputController.phoneCode}",
        isFromForgotPassword: true,
      );

      LoadingWidgets.hideLoader(context);

      log('$userExists');
      if (!mounted) return;
      if (!userExists) {
        UiUtils.showOverlaySnackBar(
          context: context,
          message: 'userDoesNotExist'.translate(context),
        );
        return;
      }

      // Set up the phone login payload for OTP verification
      final phoneLoginPayload = PhoneLoginPayload(
        _phoneInputController.phoneNumber,
        _phoneInputController.phoneCode,
        _phoneInputController.regionCode,
      );

      context.read<AuthenticationCubit>().setData(
        payload: phoneLoginPayload,
        type: AuthenticationType.phone,
      );

      // Navigate to OTP verification with forgot password mode
      Navigator.pop(context); // Close bottom sheet first
      Navigator.pushReplacementNamed(
        context,
        Routes.forgotPasswordOtpVerification,
        arguments: {
          'phoneNumber': _phoneInputController.phoneNumber,
          'phoneCode': "+${_phoneInputController.phoneCode}",
          'regionCode': _phoneInputController.regionCode,
        },
      );
    } catch (e) {
      LoadingWidgets.hideLoader(context);
      log('$mounted');
      if (!mounted) return;

      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "forgotPassword".translate(context),
                    fontSize: context.font.extraLarge,
                    fontWeight: FontWeight.w600,
                    color: context.color.textDefaultColor,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: context.color.textDefaultColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomText(
                _isEmailMode
                    ? "forgotSubHeadingTxt".translate(context)
                    : "enterPhoneNumberToResetPassword".translate(context),
                fontSize: context.font.small,
                color: context.color.textLightColor,
              ),
              const SizedBox(height: 24),
              if (_isEmailMode)
                CustomTextFormField(
                  controller: _emailController,
                  focusNode: _focusNode,
                  keyboard: TextInputType.emailAddress,
                  hintText: "emailAddress".translate(context),
                  validator: CustomTextFieldValidator.email,
                )
              else
                PhoneInput(
                  controller: _phoneInputController,
                  focusNode: _focusNode,
                ),
              const SizedBox(height: 24),
              UiUtils.buildButton(
                context,
                buttonTitle: "submit".translate(context),
                radius: 8,
                onPressed: () {
                  if (_isEmailMode) {
                    _handleEmailReset();
                  } else {
                    _handlePhoneReset();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
