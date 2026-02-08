import 'package:eClassify/data/model/location/leaf_location.dart';

class AppConfig {
  /// Used in SplashScreen to display application name under splash logo
  static const String applicationName = 'CA HUBB';

  /// DO NOT ADD "/" AT THE END OF DOMAINS ///
  /// Admin Panel URL
  static const String hostUrl = "https://admin.cahubb.com";

  /// Website URL to generate share links
  static const String shareDomain = "https://admin.cahubb.com";

  /// Default location to be used when App is unable to fetch current location
  static LeafLocation defaultLocation = LeafLocation.global();



static double defaultLatitude = 30.3753;
static double defaultLongitude = 69.3451;

  /// 2-Digit ISO code of Country
  /// Refer to countrycode.org to find out country's 2-Digit ISO code
  static const String defaultCountryCode = 'PK';

  /// Calling code of country
  /// DO NOT USE + SIGN IN FRONT OF CODE
  static const String defaultPhoneCode = '92';

  /// Show the company logo at the bottom of splash screen
  /// To change the logo, replace assets/svg/Logo/company_logo.svg
  /// SVG format is recommended here.
  /// To use any other formats, provide full asset URL in splash_screen.dart
  static const bool showCompanyLogo = true;
}
