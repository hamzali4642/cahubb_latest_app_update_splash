import 'dart:io';

import 'package:eClassify/utils/hive_keys.dart';
import 'package:eClassify/utils/password_reset_cooldown.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'password_reset_cooldown_test',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox(HiveKeys.authBox);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  group('strong password rules', () {
    test('accepts a password that meets every requirement', () {
      const password = 'Secure1!';

      expect(Validator.hasMinimumPasswordLength(password), isTrue);
      expect(Validator.hasLowercase(password), isTrue);
      expect(Validator.hasUppercase(password), isTrue);
      expect(Validator.hasNumber(password), isTrue);
      expect(Validator.hasSpecialCharacter(password), isTrue);
    });

    test('detects each missing character class', () {
      expect(Validator.hasLowercase('SECURE1!'), isFalse);
      expect(Validator.hasUppercase('secure1!'), isFalse);
      expect(Validator.hasNumber('Secure!!'), isFalse);
      expect(Validator.hasSpecialCharacter('Secure12'), isFalse);
      expect(Validator.hasMinimumPasswordLength('Sec1!'), isFalse);
    });
  });

  test('formats the five-minute reset cooldown', () {
    expect(PasswordResetCooldown.format(const Duration(minutes: 5)), '5:00');
    expect(PasswordResetCooldown.format(const Duration(seconds: 61)), '1:01');
  });

  test('blocks password reset retries for five minutes', () async {
    final requestedAt = DateTime(2026, 8, 5, 12);
    const identifier = 'email:user@example.com';
    await PasswordResetCooldown.start(identifier, now: requestedAt);

    expect(
      PasswordResetCooldown.remainingFor(
        identifier,
        now: requestedAt.add(const Duration(minutes: 4)),
      ),
      const Duration(minutes: 1),
    );
    expect(
      PasswordResetCooldown.remainingFor(
        identifier,
        now: requestedAt.add(const Duration(minutes: 5)),
      ),
      Duration.zero,
    );
  });
}
