import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  static const MethodChannel _channel = MethodChannel(
    'com.cahubb.pakistan/whatsapp',
  );

  static String? normalizePhoneNumber(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0')) {
      return '92${digits.substring(1)}';
    }
    if (digits.length == 10) {
      return '92$digits';
    }
    return digits;
  }

  static Future<bool> launch(String rawPhone, {String? message}) async {
    final phone = normalizePhoneNumber(rawPhone);
    if (phone == null) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await _channel.invokeMethod<bool>('openWhatsApp', {
          'phone': phone,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        });
        if (launched == true) return true;
      } on PlatformException {
        // Fall through to URL based launch below.
      } on MissingPluginException {
        // Fall through to URL based launch below.
      }
    }

    final queryParameters = {
      'phone': phone,
      if (message != null && message.trim().isNotEmpty) 'text': message.trim(),
    };

    final regularUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: queryParameters,
    );
    if (await launchUrl(regularUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    final businessUri = Uri(
      scheme: 'whatsapp-business',
      host: 'send',
      queryParameters: queryParameters,
    );
    if (await launchUrl(businessUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    final webUri = Uri.https('wa.me', phone, {
      if (message != null && message.trim().isNotEmpty) 'text': message.trim(),
    });
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
