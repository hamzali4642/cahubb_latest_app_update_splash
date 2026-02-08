import 'dart:developer';
import 'dart:io';

import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/log.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static int? forceResendingToken;

  Future<Map<String, dynamic>> numberLoginWithApi({
    String? phone,
    required String uid,
    required String type,
    String? fcmId,
    String? email,
    String? name,
    String? profile,
    String? countryCode,
    String? regionCode,
  }) async {
    Map<String, String> parameters = {
      Api.mobile: ?phone,
      Api.firebaseId: uid,
      Api.type: type,
      Api.platformType: Platform.isAndroid ? "android" : "ios",
      Api.fcmId: ?fcmId,
      Api.email: ?email,
      Api.name: ?name,
      Api.countryCode: ?countryCode,
      Api.regionCode: ?regionCode,
    };

    Map<String, dynamic> response = await Api.post(
      url: Api.loginApi,
      parameter: parameters,
    );

    return {"token": response['token'], "data": response['data']};
  }

  /// Login with phone number and password
  Future<Map<String, dynamic>> loginWithPhonePassword({
    required String phoneNumber,
    required String password,
    required String phoneCode,
    required String regionCode,
    String? fcmId,
  }) async {
    Map<String, String> parameters = {
      Api.mobile: phoneNumber,
      'password': password,
      Api.countryCode: phoneCode,
      Api.regionCode: regionCode,
      Api.platformType: Platform.isAndroid ? "android" : "ios",
      Api.fcmId: ?fcmId,
      Api.type: 'phone',
      'is_login': '1', // Indicates this is a login request, not signup
    };

    Map<String, dynamic> response = await Api.post(
      url: Api.loginApi,
      parameter: parameters,
    );

    return {"token": response['token'], "data": response['data']};
  }

  Future<dynamic> deleteUser() async {
    Map<String, dynamic> response = await Api.delete(url: Api.deleteUserApi);

    return response;
  }

  Future<void> logoutUser({required String fcmToken}) async {
    try {
      await Api.post(url: Api.logoutApi, parameter: {'fcm_token': fcmToken});
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'logoutUser');
      log('$stack', name: 'logoutUser');
      throw ApiException(e.toString());
    }
  }

  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    Function(dynamic e)? onError,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      timeout: Duration(seconds: Constant.otpTimeOutSecond),
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onError?.call(ApiException(e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        forceResendingToken = resendToken;
        onCodeSent.call(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> verifyOTP({
    required String otpVerificationId,
    required String otp,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: otpVerificationId,
      smsCode: otp,
    );
    UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    return userCredential;
  }

  /// Check if user exists with the given phone number
  Future<bool> checkUserExists({
    required String phoneNumber,
    required String countryCode,
    required bool isFromForgotPassword,
  }) async {
    try {
      Map<String, String> parameters = {
        'mobile': phoneNumber,
        'country_code': countryCode,
        'forgot_password': ?isFromForgotPassword ? '1' : null,
      };

      final response = await Api.get(
        url: Api.userExistsApi,
        queryParameters: parameters,
      );

      return response['data']['user_exists'] as bool;
    } catch (e, st) {
      Log.error(e.toString(), e, st);
      return false;
    }
  }

  /// Reset password for phone number after OTP verification
  Future<void> resetPassword({
    required String phoneNumber,
    required String countryCode,
    required String newPassword,
  }) async {
    try {
      Map<String, String> parameters = {
        'number': phoneNumber,
        'country_code': countryCode,
        'new_password': newPassword,
      };

      await Api.post(url: Api.resetPasswordApi, parameter: parameters);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
