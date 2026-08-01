import 'dart:io';

import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/login/lib/login_status.dart';
import 'package:eClassify/utils/login/lib/login_system.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneLogin extends LoginSystem {
  String? verificationId;
  String? phoneNumber;
  int? _resendingToken;
  String? _verificationPhoneNumber;

  @override
  Future<UserCredential?> login() async {
    try {
      emit(MProgress());

      final phonePayload = payload as PhoneLoginPayload;

      // OTP-based login
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId ?? "",
        smsCode: phonePayload.getOTP()!,
      );

      UserCredential userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      emit(MSuccess());

      return userCredential;
    } catch (e) {
      emit(MFail(e));
    }
    return null;
  }

  @override
  Future<void> requestVerification() async {
    emit(MOtpSendInProgress());

    if (Constant.otpServiceProvider == 'twilio') {
      try {
        await getTwilioOtp();
        super.requestVerification();
      } on ApiException catch (e) {
        emit(MFail(e.errorMessage));
      } catch (e) {
        emit(MFail(e.toString()));
      }
      return;
    }

    final requestedPhoneNumber =
        "+${(payload as PhoneLoginPayload).phoneCode}${(payload as PhoneLoginPayload).phoneNumber}";
    if (_verificationPhoneNumber != requestedPhoneNumber) {
      _verificationPhoneNumber = requestedPhoneNumber;
      verificationId = null;
      _resendingToken = null;
    }

    await FirebaseAuth.instance
        .verifyPhoneNumber(
          timeout: Duration(seconds: Constant.otpTimeOutSecond),
          phoneNumber: requestedPhoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            // A stale resend/reCAPTCHA session must not leak into the next try.
            _resendingToken = null;
            emit(MFail(e));
          },
          codeSent: (String verificationId, int? resendToken) {
            super.requestVerification();
            _resendingToken = resendToken;
            this.verificationId = verificationId;
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
          // Firebase resend tokens are Android-only. Supplying stale state to
          // the iOS reCAPTCHA flow can invalidate a subsequent attempt.
          forceResendingToken: Platform.isAndroid ? _resendingToken : null,
        )
        .then((value) {});
  }

  Future<Map<String, dynamic>> getTwilioOtp() async {
    phoneNumber =
        (payload as PhoneLoginPayload).phoneCode +
        (payload as PhoneLoginPayload).phoneNumber;
    final parameters = {
      'number':
          "${(payload as PhoneLoginPayload).phoneCode}${(payload as PhoneLoginPayload).phoneNumber}",
    };
    final response = await Api.get(
      url: Api.getTwilioOtp,
      queryParameters: parameters,
    );

    return response;
  }

  @override
  void onEvent(MLoginState state) {}
}
