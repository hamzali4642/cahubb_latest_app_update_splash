// ignore_for_file: file_names

import 'dart:developer';

import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ErrorFilter {
  final dynamic error;
  ErrorFilter(this.error);

  static final Map<String, String> _errorKeyMap = {
    "network-request-failed": "networkRequestFailed",
    "app-not-authorized": "appNotAuthorized",
    "no-internet": "checkNetwork",
    "email-already-in-use": "emailAlreadyInUse",
    "invalid-credential": "youHaveEnteredInvalidUserNameOrPassword",
    "invalid-login-credentials": "youHaveEnteredInvalidUserNameOrPassword",
    "wrong-password": "wrongPassword",
    "user-not-found": "emailNotRegistered",
    "invalid-email": "invalidEmail",
    "invalid-phone-number": "invalidPhoneNumber",
    "invalid-verification-code": "invalidVerificationCode",
    "session-expired": "sessionExpired",
    "too-many-requests": "tooManyRequests",
    "user-disabled": "userDisabled",
    "operation-not-allowed": "operationNotAllowed",
    "missing-initial-state": "recaptchaSessionFailed",
    "captcha-check-failed": "recaptchaSessionFailed",
    "invalid-app-credential": "recaptchaSessionFailed",
    "quota-exceeded": "tooManyRequests",
  };

  /// Returns the translated message based on FirebaseAuthException
  static String getTranslatedFirebaseAuthException(
    BuildContext context, {
    required FirebaseAuthException error,
  }) {
    final errorKey = getErrorKeyFromFirebaseAuthException(error);
    return errorKey.translate(context);
  }

  /// Returns just the error key (e.g., "userNotFound") for internal use or logging
  static String getErrorKeyFromFirebaseAuthException(
    FirebaseAuthException error,
  ) {
    log('${error.code} ${error.message}');
    final normalizedCode = error.code.trim().toLowerCase().replaceAll('_', '-');
    return _errorKeyMap[normalizedCode] ?? error.message ?? error.code;
  }
}
