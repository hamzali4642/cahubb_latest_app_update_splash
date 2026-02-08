import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/utils/country_locales.dart';
import 'package:eClassify/utils/hive_utils.dart';

/// Holds mutable, session-scoped data used throughout the app.
///
/// This class represents the current app session and should only contain
/// data that is expected to change during a single run of the app.
///
/// For non-session data, see constants.dart.
///
/// Initialized with default values and expected to change during the app's lifecycle.
abstract class AppSession {
  /// To initialize session based values during the app booting time and ensure
  /// we have valid data to be used before accessing any of the data
  static void create() {
    _currentLocation = HiveUtils.getLocation();
    _currentTheme = HiveUtils.getCurrentTheme();
  }

  static void clear() {
    _currentLocation = AppConfig.defaultLocation;
  }

  /// Current selected location
  static LeafLocation? _currentLocation;

  static LeafLocation? get currentLocation => _currentLocation;

  static void setCurrentLocation(LeafLocation? location) {
    _currentLocation = location;
  }

  /// Current active language code.
  static String _currentLanguageCode = 'EN';

  static String get currentLanguageCode => _currentLanguageCode;

  /// Current active locale.
  static String _currentLocale = 'en_US';

  static String get currentLocale => _currentLocale;

  static void setCurrentLanguage(String languageCode, String countryCode) {
    _currentLanguageCode = languageCode;
    _currentLocale = CountryLocales.localeFromCountryCode(countryCode);
  }

  /// Current theme of app
  static AppTheme _currentTheme = AppTheme.light;

  static bool get isDarkMode => _currentTheme == AppTheme.dark;

  static void setCurrentTheme(AppTheme theme) {
    _currentTheme = theme;
  }
}
