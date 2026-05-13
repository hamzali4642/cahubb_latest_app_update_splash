import 'dart:developer';

import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/data/repositories/system_repository.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/network/network_availability.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base state for system settings
abstract class FetchSystemSettingsState {}

class FetchSystemSettingsInitial extends FetchSystemSettingsState {}

class FetchSystemSettingsInProgress extends FetchSystemSettingsState {}

class FetchSystemSettingsSuccess extends FetchSystemSettingsState {
  final Map settings;

  FetchSystemSettingsSuccess({required this.settings});

  Map<String, dynamic> toMap() => {'settings': settings};

  factory FetchSystemSettingsSuccess.fromMap(Map<String, dynamic> map) =>
      FetchSystemSettingsSuccess(settings: map['settings'] as Map);
}

class FetchSystemSettingsFailure extends FetchSystemSettingsState {
  final String errorMessage;

  FetchSystemSettingsFailure(this.errorMessage);
}

/// Cubit responsible for managing system settings
class FetchSystemSettingsCubit extends Cubit<FetchSystemSettingsState> {
  FetchSystemSettingsCubit() : super(FetchSystemSettingsInitial());

  final SystemRepository _systemRepository = SystemRepository();

  /// Fetches system settings
  ///
  /// [forceRefresh] - If true, forces a refresh of the settings
  Future<void> fetchSettings({bool? forceRefresh}) async {
    try {
      if (!_shouldFetch(forceRefresh)) return;

      emit(FetchSystemSettingsInProgress());

      if (forceRefresh ?? false || state is! FetchSystemSettingsSuccess) {
        await _fetchAndUpdateSettings();
      } else {
        await _checkInternetAndUpdateSettings();
      }
    } catch (e, st) {
      log('$st');
      emit(FetchSystemSettingsFailure(e.toString()));
    }
  }

  /// Determines if the fetch operation should proceed
  bool _shouldFetch(bool? forceRefresh) {
    if (forceRefresh == true) return true;
    if (state is FetchSystemSettingsSuccess) {
      return false;
    }
    return true;
  }

  /// Fetches and updates system settings
  Future<void> _fetchAndUpdateSettings() async {
    try {
      final settings = await _systemRepository.fetchSystemSettings();
      _updateConstants(settings);
      emit(FetchSystemSettingsSuccess(settings: settings));
    } on Exception catch (e, st) {
      log('$e $st');
      emit(FetchSystemSettingsFailure(e.toString()));
    }
  }

  /// Checks internet connection and updates settings accordingly
  Future<void> _checkInternetAndUpdateSettings() async {
    await CheckInternet.check(
      onInternet: () async {
        await _fetchAndUpdateSettings();
      },
      onNoInternet: () {
        if (state is FetchSystemSettingsSuccess) {
          emit(
            FetchSystemSettingsSuccess(
              settings: (state as FetchSystemSettingsSuccess).settings,
            ),
          );
        }
      },
    );
  }

  /// Updates all constant values from settings
  void _updateConstants(Map settings) {
    Constant.otpServiceProvider = _getSettingAsString(
      settings,
      SystemSetting.otpServiceProvider,
    );
    Constant.mapProvider = _getSettingAsString(
      settings,
      SystemSetting.mapProvider,
    );
    Constant.currencySymbol = _getSettingAsString(
      settings,
      SystemSetting.currencySymbol,
    );
    Constant.currencyPositionIsLeft =
        _getSetting(settings, SystemSetting.currencySymbolPosition) == 'left';
    Constant.maintenanceMode = _getSettingAsString(
      settings,
      SystemSetting.maintenanceMode,
    );

    // Ad settings
    _updateAdSettings(settings);

    // Location settings
    if (AppConfig.defaultLatitude == 0.0) {
      final latitude = double.tryParse(
        _getSettingAsString(settings, SystemSetting.defaultLatitude),
      );
      if (latitude != null) {
        AppConfig.defaultLatitude = latitude;
      }
    }
    if (AppConfig.defaultLongitude == 0.0) {
      final longitude = double.tryParse(
        _getSettingAsString(settings, SystemSetting.defaultLongitude),
      );
      if (longitude != null) {
        AppConfig.defaultLongitude = longitude;
      }
    }

    // Store URLs
    _updateStoreUrls(settings);

    // Authentication settings
    _updateAuthenticationSettings(settings);

    // Radius settings
    Constant.minRadius =
        double.tryParse(
          _getSettingAsString(settings, SystemSetting.minRadius),
        ) ??
        0.0;
    Constant.maxRadius =
        double.tryParse(
          _getSettingAsString(settings, SystemSetting.maxRadius),
        ) ??
        10.0;
    AppConfig.defaultLocation = AppConfig.defaultLocation.copyWith(
      radius: Constant.minRadius,
    );
    if (Constant.minRadius != AppSession.currentLocation?.radius) {
      final persistedLocation = AppSession.currentLocation;
      if (persistedLocation != null) {
        final updatedLocation = persistedLocation.copyWith(
          radius: Constant.minRadius,
        );
        AppSession.setCurrentLocation(updatedLocation);
        HiveUtils.setLocation(location: updatedLocation);
      }
    }
  }

  /// Updates ad-related settings
  void _updateAdSettings(Map settings) {
    Constant.isGoogleBannerAdsEnabled = _getSettingAsString(
      settings,
      SystemSetting.bannerAdStatus,
    );
    Constant.isGoogleInterstitialAdsEnabled = _getSettingAsString(
      settings,
      SystemSetting.interstitialAdStatus,
    );
    Constant.isGoogleNativeAdsEnabled = _getSettingAsString(
      settings,
      SystemSetting.nativeAdStatus,
    );

    Constant.bannerAdIdAndroid = _getSettingAsString(
      settings,
      SystemSetting.bannerAdAndroidAd,
    );
    Constant.bannerAdIdIOS = _getSettingAsString(
      settings,
      SystemSetting.bannerAdiOSAd,
    );
    Constant.interstitialAdIdAndroid = _getSettingAsString(
      settings,
      SystemSetting.interstitialAdAndroidAd,
    );
    Constant.interstitialAdIdIOS = _getSettingAsString(
      settings,
      SystemSetting.interstitialAdiOSAd,
    );
    Constant.nativeAdIdAndroid = _getSettingAsString(
      settings,
      SystemSetting.nativeAndroidAd,
    );
    Constant.nativeAdIdIOS = _getSettingAsString(
      settings,
      SystemSetting.nativeAdiOSAd,
    );
  }

  /// Updates store URLs and iOS app ID
  void _updateStoreUrls(Map settings) {
    Constant.playStoreUrl = _getSettingAsString(
      settings,
      SystemSetting.playStoreLink,
    );
    Constant.appStoreUrl = _getSettingAsString(
      settings,
      SystemSetting.appStoreLink,
    );
    Constant.iOSAppId = _getSettingAsString(
      settings,
      SystemSetting.appStoreLink,
    ).split('/').last;
  }

  /// Updates authentication-related settings
  void _updateAuthenticationSettings(Map settings) {
    Constant.mobileAuthentication = _getSettingAsString(
      settings,
      SystemSetting.mobileAuthentication,
      fallback: "0",
    );
    Constant.googleAuthentication = _getSettingAsString(
      settings,
      SystemSetting.googleAuthentication,
      fallback: "0",
    );
    Constant.appleAuthentication = _getSettingAsString(
      settings,
      SystemSetting.appleAuthentication,
      fallback: "0",
    );
    Constant.emailAuthentication = _getSettingAsString(
      settings,
      SystemSetting.emailAuthentication,
      fallback: "0",
    );
  }

  /// Gets a specific setting value
  dynamic getSetting(SystemSetting selected) {
    if (state is! FetchSystemSettingsSuccess) return null;

    final settings = (state as FetchSystemSettingsSuccess).settings['data'];

    if (selected == SystemSetting.subscription) {
      return settings['subscription'] == true
          ? settings['package']['user_purchased_package'] as List
          : [];
    }

    if (selected == SystemSetting.language) {
      return (settings['languages'] as List);
    }

    if (selected == SystemSetting.demoMode) {
      return settings.containsKey("demo_mode") ? settings['demo_mode'] : false;
    }

    return settings[Constant.systemSettingKeys[selected]];
  }

  /// Gets raw settings data
  Map getRawSettings() {
    if (state is FetchSystemSettingsSuccess) {
      return (state as FetchSystemSettingsSuccess).settings['data'];
    }
    return {};
  }

  /// Gets a setting value from the settings map
  dynamic _getSetting(Map settings, SystemSetting selected) =>
      settings['data'][Constant.systemSettingKeys[selected]] ?? '';

  String _getSettingAsString(
    Map settings,
    SystemSetting selected, {
    String fallback = '',
  }) {
    final value = _getSetting(settings, selected);
    if (value == null || value.toString().isEmpty) return fallback;
    return value.toString();
  }
}
