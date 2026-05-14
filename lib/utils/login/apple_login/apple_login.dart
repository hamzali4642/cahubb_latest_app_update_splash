import 'dart:convert';

import 'package:eClassify/utils/login/lib/login_status.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:eClassify/utils/login/lib/login_system.dart';

class AppleLogin extends LoginSystem {
  OAuthCredential? credential;
  OAuthProvider? oAuthProvider;

  @override
  void init() async {}

  Future<UserCredential?> login() async {
    try {
      emit(MProgress());

      final rawNonce = generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final AuthorizationCredentialAppleID appleIdCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );

      oAuthProvider = OAuthProvider('apple.com');
      if (oAuthProvider != null) {
        credential = oAuthProvider!.credential(
          idToken: appleIdCredential.identityToken,
          rawNonce: rawNonce,
        );

        final UserCredential userCredential = await firebaseAuth
            .signInWithCredential(credential!);

        if (userCredential.additionalUserInfo!.isNewUser) {
          final String givenName = appleIdCredential.givenName ?? "";
          final String familyName = appleIdCredential.familyName ?? "";
          final displayName = "$givenName $familyName".trim();

          if (displayName.isNotEmpty) {
            await userCredential.user!.updateDisplayName(displayName);
            await userCredential.user!.reload();
          }
        }

        emit(MSuccess());

        return userCredential;
      }
      return null;
    } catch (e) {
      emit(MFail(e.toString()));
      rethrow;
    }
  }

  @override
  void onEvent(MLoginState state) {
    print("Login state is $state");
  }
}
