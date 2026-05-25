import 'package:eClassify/data/model/item/item_filter.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Constant {
  /// Immutable constants that will never be mutated during runtime

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static double horizontalPadding = 16;
  static EdgeInsets appContentPadding = EdgeInsets.symmetric(
    horizontal: horizontalPadding,
  );

  // Interval for showing native ads in home screen's infinite scrolling
  // ONLY ADD EVEN NUMBERS
  static int nativeAdsAfterItemNumber = 12;

  // This is only to show the actual google map in ad_details_screen.dart
  // It can be set to false in case there are any lags in loading the screen
  static bool showGoogleMap = false;

  // Quality of image to preserve during compression
  static const int uploadImageQuality = 20;

  // Maximum allowed size to be uploaded per image and file
  static const int maxSize = 2; // In MB
  static const int maxSizeInBytes = maxSize * 1000000;

  // Decides whether to use lottie for loading indicator or regular circular indicator
  static const bool useLottieProgress = true;

  // Notification types
  static String notificationTypeItemUpdate = "item-update";
  static String notificationTypeItemEdit = "item-edit";
  static String notificationTypeChat = "chat";
  static String notificationTypeOffer = "offer";
  static String notificationTypePayment = "payment";
  static String notificationTypeJobApplication = "job-application";
  static String notificationTypeApplicationStatus = "application-status";
  static String notificationTypeItemReview = 'item-review';

  //====== This is not a typing error ====== //
  static String notificationTypeVerificationStatus =
      "verifcation-request-update";

  // Item/Seller status
  static const String statusReview = "review";
  static const String statusResubmitted = "resubmitted";
  static const String statusActive = "active";
  static const String statusApproved = "approved";
  static const String statusInactive = "inactive";
  static const String statusSoldOut = "sold out";
  static const String statusPermanentRejected = "permanent rejected";
  static const String statusSoftRejected = "soft rejected";
  static const String statusExpired = "expired";
  static const String statusRejected = "rejected";
  static const String statusPending = "pending";
  static const String statusUnderReview = "under review";

  // Payment types
  static const String paymentTypeBankTransfer = "bankTransfer";

  // Subscription packages
  static const String itemTypeListing = "item_listing";
  static const String itemTypeAdvertisement = "advertisement";
  static const String itemLimitUnlimited = "unlimited";

  // Notification Topics
  static const String generalNotificationTopic = kReleaseMode
      ? 'allUsers'
      : 'allUsersDevPanel';

  // API response keys for config API used to set the Mutable values below
  static Map<SystemSetting, String> systemSettingKeys = {
    SystemSetting.otpServiceProvider: "otp_service_provider",
    SystemSetting.mapProvider: "map_provider",
    SystemSetting.currencySymbol: "currency_symbol",
    SystemSetting.currencySymbolPosition: "currency_symbol_position",
    SystemSetting.freeAdListing: "free_ad_listing",
    SystemSetting.privacyPolicy: "privacy_policy",
    SystemSetting.contactUs: "contact_us",
    SystemSetting.maintenanceMode: "maintenance_mode",
    SystemSetting.termsConditions: "terms_conditions",
    SystemSetting.subscription: "subscription",
    SystemSetting.language: "languages",
    SystemSetting.defaultLanguage: "default_language",
    SystemSetting.forceUpdate: "force_update",
    SystemSetting.androidVersion: "android_version",
    SystemSetting.numberWithSuffix: "number_with_suffix",
    SystemSetting.iosVersion: "ios_version",
    SystemSetting.bannerAdStatus: "banner_ad_status",
    SystemSetting.bannerAdAndroidAd: "banner_ad_id_android",
    SystemSetting.bannerAdiOSAd: "banner_ad_id_ios",
    SystemSetting.interstitialAdStatus: "interstitial_ad_status",
    SystemSetting.interstitialAdAndroidAd: "interstitial_ad_id_android",
    SystemSetting.interstitialAdiOSAd: "interstitial_ad_id_ios",
    SystemSetting.nativeAdStatus: "native_ad_status",
    SystemSetting.nativeAndroidAd: "native_app_id_android",
    SystemSetting.nativeAdiOSAd: "native_app_id_android",
    SystemSetting.playStoreLink: "play_store_link",
    SystemSetting.appStoreLink: "app_store_link",
    SystemSetting.defaultLatitude: "default_latitude",
    SystemSetting.defaultLongitude: "default_longitude",
    SystemSetting.mobileAuthentication: "mobile_authentication",
    SystemSetting.googleAuthentication: "google_authentication",
    SystemSetting.appleAuthentication: "apple_authentication",
    SystemSetting.emailAuthentication: "email_authentication",
    SystemSetting.minRadius: "min_length",
    SystemSetting.maxRadius: "max_length",
    SystemSetting.autoApproveEditedItem: "auto_approve_edited_item",
  };

  ///=============================///

  /// Mutable values that are set after the initial API call and remains Immutable
  /// throughout the App's lifecycle

  // App Information
  static String playStoreUrl = "";
  static String appStoreUrl = "";
  static String iOSAppId = '';

  // Storage path for media downloads
  static String savePath = '';

  // Google AdMob IDs and Switches
  // Todo(I): Use booleans for switches instead of String based comparison
  static String isGoogleBannerAdsEnabled = "";
  static String bannerAdIdAndroid = '';
  static String bannerAdIdIOS = "";

  static String isGoogleInterstitialAdsEnabled = "";
  static String interstitialAdIdAndroid = '';
  static String interstitialAdIdIOS = '';

  static String isGoogleNativeAdsEnabled = "1";
  static String nativeAdIdAndroid = '';
  static String nativeAdIdIOS = '';

  static String currencySymbol = "";
  static bool currencyPositionIsLeft = true;

  // Enabled authentication modules
  // Todo(I): Use booleans instead of String based comparison
  static String mobileAuthentication = "";
  static String googleAuthentication = "";
  static String emailAuthentication = "";
  static String appleAuthentication = "";

  // Service providers
  // Todo(I): Maybe use enums instead of strings
  static String otpServiceProvider = "";
  static String mapProvider = "";

  // These values are set after the initial API call and used with radius range
  // in Map Widget
  static double minRadius = 0;
  static double maxRadius = 0;

  static String maintenanceMode = "0";

  static int otpTimeOutSecond = 60;

  static ItemFilter? itemFilter;

  static bool isUpdateAvailable = false;
  static String newVersionNumber = "";

  //Demo mode settings
  static bool isDemoModeOn = false;
  static String demoCountryCode = "";
  static String demoMobileNumber = "";
  static String demoModeOTP = "";

  static String forceDisableDemoMode = "force-disable-demo-mode";
}
