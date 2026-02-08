abstract class LoginPayload {}

class MultiLoginPayload {
  final Map<String, LoginPayload> payloads;

  MultiLoginPayload(this.payloads);
}

enum EmailLoginType { login, signup }

class EmailLoginPayload extends LoginPayload {
  final String email;
  final String password;
  final EmailLoginType type;

  EmailLoginPayload({
    required this.email,
    required this.password,
    required this.type,
  });
}

class GoogleLoginPayload extends LoginPayload {
  GoogleLoginPayload();
}

class AppleLoginPayload extends LoginPayload {
  AppleLoginPayload();
}

class PhoneLoginPayload extends LoginPayload {
  final String phoneNumber;
  final String phoneCode;
  final String regionCode;
  final String? password;
  String? otp;

  PhoneLoginPayload(
    this.phoneNumber,
    this.phoneCode,
    this.regionCode, {
    this.password,
  });

  void setOTP(String value) {
    otp = value;
  }

  String? getOTP() {
    return otp;
  }

  bool hasPassword() {
    return password != null && password!.isNotEmpty;
  }
}
