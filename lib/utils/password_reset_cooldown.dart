import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:hive/hive.dart';

class PasswordResetCooldown {
  PasswordResetCooldown._();

  static const duration = Duration(minutes: 5);
  static const _keyPrefix = 'passwordResetCooldown_';

  static String emailIdentifier(String email) =>
      'email:${email.trim().toLowerCase()}';

  static String phoneIdentifier(String phoneCode, String phoneNumber) =>
      'phone:${phoneCode.replaceAll('+', '').trim()}:${phoneNumber.trim()}';

  static Duration remainingFor(String identifier, {DateTime? now}) {
    final storedAt =
        Hive.box(HiveKeys.authBox).get(_storageKey(identifier)) as int?;
    if (storedAt == null) return Duration.zero;

    final elapsed = (now ?? DateTime.now()).difference(
      DateTime.fromMillisecondsSinceEpoch(storedAt),
    );
    final remaining = duration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Future<void> start(String identifier, {DateTime? now}) {
    return Hive.box(HiveKeys.authBox).put(
      _storageKey(identifier),
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  static String format(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 300);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _storageKey(String identifier) =>
      '$_keyPrefix${sha256.convert(utf8.encode(identifier))}';
}
