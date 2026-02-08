import 'package:eClassify/utils/app_session.dart';
import 'package:flutter/services.dart';

abstract class MapStyle {
  static late final String _light;
  static late final String _dark;

  static void init() async {
    _light = await rootBundle.loadString('assets/map/map_light.json');
    _dark = await rootBundle.loadString('assets/map/map_dark.json');
  }

  static String get style => AppSession.isDarkMode ? _dark : _light;
}
