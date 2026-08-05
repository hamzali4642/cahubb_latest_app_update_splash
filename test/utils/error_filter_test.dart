import 'package:eClassify/utils/error_filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorFilter.getErrorKeyFromFirebaseAuthException', () {
    test('maps current Firebase invalid credential errors', () {
      final error = FirebaseAuthException(code: 'invalid-credential');

      expect(
        ErrorFilter.getErrorKeyFromFirebaseAuthException(error),
        'youHaveEnteredInvalidUserNameOrPassword',
      );
    });

    test('normalizes uppercase underscore error codes', () {
      final error = FirebaseAuthException(code: 'INVALID_LOGIN_CREDENTIALS');

      expect(
        ErrorFilter.getErrorKeyFromFirebaseAuthException(error),
        'youHaveEnteredInvalidUserNameOrPassword',
      );
    });

    test('keeps the existing wrong password mapping', () {
      final error = FirebaseAuthException(code: 'wrong-password');

      expect(
        ErrorFilter.getErrorKeyFromFirebaseAuthException(error),
        'wrongPassword',
      );
    });

    test('falls back to the Firebase message for unknown codes', () {
      final error = FirebaseAuthException(
        code: 'unexpected-code',
        message: 'Unexpected authentication error',
      );

      expect(
        ErrorFilter.getErrorKeyFromFirebaseAuthException(error),
        'Unexpected authentication error',
      );
    });
  });
}
