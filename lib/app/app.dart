import 'package:eClassify/firebase_options.dart';
import 'package:eClassify/main.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:eClassify/utils/map_style.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// List of Hive box names that need to be initialized
final List<String> _hiveBoxes = [
  HiveKeys.userDetailsBox,
  HiveKeys.authBox,
  HiveKeys.languageBox,
  HiveKeys.themeBox,
  HiveKeys.jwtToken,
  HiveKeys.historyBox,
];

/// Initializes the application with all necessary configurations
Future<void> initApp() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    //debugRepaintRainbowEnabled = true;

    // Configure Google Maps for Android
    _configureGoogleMaps();

    // Set up error handling for release mode
    if (kReleaseMode) {
      _setupErrorHandling();
    }

    _setupFilePath();

    // Initialize Mobile Ads
    MobileAds.instance.initialize();

    // Configure system UI and launch app
    _configureSystemUI();

    // Initialize regions for phone number
    init();

    // Load map styles from assets
    MapStyle.init();

    // Initialize Firebase
    await _initializeFirebase();

    // Initialize Hive and open boxes
    await _initializeHive();

    AppSession.create();

    runApp(const EntryPoint());
  } catch (e, stackTrace) {
    debugPrint('Error initializing app: $e\n$stackTrace');
    rethrow;
  }
}

/// Configures Google Maps for Android platform
void _configureGoogleMaps() {
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = false;
  }
}

/// Sets up error handling for release mode
void _setupErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) {
    return SomethingWentWrong();
  };
}

/// Initializes Firebase with appropriate options
Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    androidProvider: AndroidProvider.playIntegrity,
  );
}

/// Initializes Hive and opens all required boxes
Future<void> _initializeHive() async {
  await Hive.initFlutter();
  for (final boxName in _hiveBoxes) {
    await Hive.openBox(boxName);
  }
}

/// Configures system UI and launches the app
Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
}

/// Setup the file path for saving internal files
Future<void> _setupFilePath() async {
  final directory = await getApplicationDocumentsDirectory();
  Constant.savePath = directory.path;
}
