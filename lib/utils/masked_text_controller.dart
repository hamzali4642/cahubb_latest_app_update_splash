import 'package:flutter/widgets.dart';

/// A [TextEditingController] that formats typed or pasted text using a mask.
///
/// `0` accepts a digit, `A` a letter, `@` an alphanumeric character, and `*`
/// any character. Other mask characters are inserted automatically.
class MaskedTextController extends TextEditingController {
  MaskedTextController({
    required this.mask,
    super.text,
    Map<String, RegExp>? translator,
  }) : translator = translator ?? getDefaultTranslator() {
    addListener(_handleTextChange);
    updateText(text);
  }

  static const String cardNumberMask = '0000 0000 0000 0000';
  static const String expiryDateMask = '00/00';
  static const String cvvMask = '0000';
  static const String cnicMask = '00000-0000000-0';

  String mask;
  final Map<String, RegExp> translator;

  bool Function(String previous, String next) beforeChange = (_, __) => true;
  void Function(String previous, String next) afterChange = (_, __) {};

  String _lastUpdatedText = '';
  bool _isUpdating = false;

  void _handleTextChange() {
    if (_isUpdating || text == _lastUpdatedText) return;

    final previous = _lastUpdatedText;
    if (!beforeChange(previous, text)) {
      _setText(previous);
      return;
    }

    updateText(text);
    afterChange(previous, _lastUpdatedText);
  }

  void updateText(String value) {
    _setText(value.isEmpty ? '' : _applyMask(mask, value));
  }

  void updateMask(String value, {bool moveCursorToEnd = true}) {
    mask = value;
    updateText(text);
    if (moveCursorToEnd) this.moveCursorToEnd();
  }

  void moveCursorToEnd() {
    selection = TextSelection.collapsed(offset: text.length);
  }

  void _setText(String value) {
    _isUpdating = true;
    super.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _lastUpdatedText = value;
    _isUpdating = false;
  }

  static Map<String, RegExp> getDefaultTranslator() {
    return <String, RegExp>{
      'A': RegExp(r'[A-Za-z]'),
      '0': RegExp(r'[0-9]'),
      '@': RegExp(r'[A-Za-z0-9]'),
      '*': RegExp(r'.*'),
    };
  }

  String _applyMask(String mask, String value) {
    final buffer = StringBuffer();
    var maskIndex = 0;
    var valueIndex = 0;

    while (maskIndex < mask.length && valueIndex < value.length) {
      final maskCharacter = mask[maskIndex];
      final valueCharacter = value[valueIndex];

      if (maskCharacter == valueCharacter) {
        buffer.write(maskCharacter);
        maskIndex++;
        valueIndex++;
        continue;
      }

      final allowedPattern = translator[maskCharacter];
      if (allowedPattern != null) {
        if (allowedPattern.hasMatch(valueCharacter)) {
          buffer.write(valueCharacter);
          maskIndex++;
        }
        valueIndex++;
        continue;
      }

      buffer.write(maskCharacter);
      maskIndex++;
    }

    return buffer.toString();
  }
}
