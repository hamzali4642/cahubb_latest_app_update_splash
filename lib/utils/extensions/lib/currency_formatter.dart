import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:intl/intl.dart';

extension NumberFormatter on double {
  String get currencyFormat {
    final formatted = this.decimalFormat;

    return Constant.currencyPositionIsLeft
        ? '${Constant.currencySymbol} $formatted'
        : '$formatted ${Constant.currencySymbol}';
  }

  String get decimalFormat {
    final supportsLocale = NumberFormat.localeExists(AppSession.currentLocale);
    final numberFormat = NumberFormat(
      '#,##0.##',
      supportsLocale ? AppSession.currentLocale : Intl.defaultLocale,
    );
    return numberFormat.format(this);
  }
}
