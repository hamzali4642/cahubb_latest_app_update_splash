class PakistanPhoneUtils {
  const PakistanPhoneUtils._();

  static const String countryCode = '+92';

  static String localNumber(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0092')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('92')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  static String normalize(String value) => '$countryCode${localNumber(value)}';

  static bool isValid(String value) {
    return RegExp(r'^\d{10}$').hasMatch(localNumber(value));
  }
}
