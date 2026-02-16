import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:device_region/device_region.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/full_screen_image_view.dart';
import 'package:eClassify/ui/screens/widgets/toast_message.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/lottie_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime_type/mime_type.dart';

class UiUtils {
  // Temporary
  // This is to fulfil the case when bottom-sheet cannot show default snack-bars
  // due to absence of Scaffold widget.
  static Future<void> showOverlaySnackBar({
    required BuildContext context,
    required String message,
    MessageType? type,
  }) async {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => ToastMessage(
        backgroundColor: type?.value ?? context.color.inverseThemeColor,
        errorMessage: message,
      ),
    );

    overlayState.insert(overlayEntry);
    await Future<void>.delayed(const Duration(milliseconds: 3000));
    overlayEntry.remove();
  }

  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool isDraggable = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      enableDrag: isDraggable,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) =>
          Padding(padding: MediaQuery.viewInsetsOf(context), child: child),
    );
  }

  static SvgPicture getSvg(
    String path, {
    Color? color,
    BoxFit? fit,
    double? width,
    double? height,
  }) {
    return SvgPicture.asset(
      path,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit ?? BoxFit.contain,
      width: width,
      height: height,
    );
  }

  static void checkUser({
    required Function() onNotGuest,
    required BuildContext context,
  }) {
    if (!HiveUtils.isUserAuthenticated()) {
      _loginBox(context);
    } else {
      onNotGuest.call();
    }
  }

  static void imagePickerBottomSheet(
    BuildContext context, {
    Function? callback,
    bool isRemovalWidget = false,
  }) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: CustomText("gallery".translate(context)),
                onTap: () async {
                  if (callback != null) callback(false, ImageSource.gallery);

                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: CustomText("camera".translate(context)),
                onTap: () async {
                  if (callback != null) callback(false, ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              if (isRemovalWidget)
                ListTile(
                  leading: const Icon(Icons.clear_rounded),
                  title: CustomText("lblremove".translate(context)),
                  onTap: () {
                    if (callback != null) callback(true, null);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static void _loginBox(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            30,
            30,
            30,
            MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "loginIsRequiredForAccessingThisFeatures".translate(context),
                fontSize: context.font.larger,
              ),
              const SizedBox(height: 5),
              CustomText(
                "tapOnLoginToAuthorize".translate(context),
                fontSize: context.font.small,
              ),
              const SizedBox(height: 10),
              MaterialButton(
                elevation: 0,
                color: context.color.territoryColor,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    Routes.login,
                    arguments: {"popToCurrent": true},
                  );
                },
                child: CustomText(
                  "loginNow".translate(context),
                  color: context.color.buttonColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget getSvgImage(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    String? blurHash,
    bool? showFullScreenImage,
    Color? color,
  }) {
    return SvgPicture.network(
      url,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      width: width,
      height: height,
      fit: fit!,
      placeholderBuilder: (context) {
        return placeholderWidget(context, width, height);
      },
    );
  }

  @Deprecated('Use CustomImage instead')
  static Widget getImage(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    String? blurHash,
    bool? showFullScreenImage,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit ?? BoxFit.cover,
      width: width,
      height: height,
      placeholder: (context, url) {
        return placeholderWidget(context, width, height);
      },
      errorWidget: (context, url, error) {
        return placeholderWidget(context, width, height);
      },
    );
  }

  static Widget placeholderWidget(
    BuildContext context,
    double? width,
    double? height,
  ) {
    return Container(
      width: width,
      color: context.color.territoryColor.withValues(alpha: 0.1),
      height: height,
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: width,
        height: height,
        child: getSvg(
          AppIcons.placeHolder,
          width: width ?? 70,
          height: height ?? 70,
        ),
      ),
    );
  }

  static Widget progress({
    double? width,
    double? height,
    Color color = territoryColor_,
  }) {
    if (Constant.useLottieProgress) {
      return LottieUtility.loadingIndicator(
        width: width,
        height: height,
        color: color,
      );
    } else {
      return CircularProgressIndicator(color: color);
    }
  }

  static SystemUiOverlayStyle getSystemUiOverlayStyle({
    required BuildContext context,
    required Color statusBarColor,
    Color? navigationBarColor,
  }) {
    bool isDarkMode = AppSession.isDarkMode;
    Brightness iconBrightness = isDarkMode ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarColor:
          navigationBarColor ?? context.color.secondaryColor,
      statusBarColor: statusBarColor,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: iconBrightness,
    );
  }

  static PreferredSize buildAppBar(
    BuildContext context, {
    String? title,
    bool? showBackButton,
    List<Widget>? actions,
    List<Widget>? bottom,
    double? bottomHeight,
    bool? hideTopBorder,
    VoidCallback? onBackPress,
    Color? backgroundColor,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(55 + (bottomHeight ?? 0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: RoundedBorderOnSomeSidesWidget(
              borderColor: context.color.borderColor,
              borderRadius: 0,
              borderWidth: 1.5,
              contentBackgroundColor:
                  backgroundColor ?? context.color.secondaryColor,
              bottomLeft: true,
              bottomRight: true,
              topLeft: false,
              topRight: false,
              child: Container(
                alignment: AlignmentDirectional.bottomStart,
                padding: EdgeInsets.symmetric(
                  horizontal: (showBackButton ?? false) ? 0 : 20,
                  vertical: (showBackButton ?? false) ? 0 : 18,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBackButton ?? false) ...[
                      Material(
                        clipBehavior: Clip.antiAlias,
                        color: Colors.transparent,
                        type: MaterialType.circle,
                        child: InkWell(
                          onTap: () {
                            if (onBackPress != null) {
                              onBackPress.call();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Directionality(
                              textDirection: Directionality.of(context),
                              child: RotatedBox(
                                quarterTurns:
                                    Directionality.of(context) ==
                                        ui.TextDirection.rtl
                                    ? 2
                                    : -4,
                                child: UiUtils.getSvg(
                                  AppIcons.arrowLeft,
                                  fit: BoxFit.none,
                                  color: context.color.textDefaultColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: CustomText(
                        title ?? "",
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        color: context.color.textDefaultColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    if (actions != null) ...actions,
                  ],
                ),
              ),
            ),
          ),
          if (bottom != null) ...bottom,
        ],
      ),
    );
  }

  static Widget buildButton(
    BuildContext context, {
    double? height,
    double? width,
    BorderSide? border,
    String? titleWhenProgress,
    bool isInProgress = false,
    double? fontSize,
    double? radius,
    bool? autoWidth,
    Widget? prefixWidget,
    EdgeInsetsGeometry? padding,
    required VoidCallback onPressed,
    required String buttonTitle,
    bool? showProgressTitle,
    double? progressWidth,
    double? progressHeight,
    bool? showElevation,
    Color? textColor,
    Color? buttonColor,
    EdgeInsetsGeometry? outerPadding,
    Color? disabledColor,
    VoidCallback? onTapDisabledButton,
    bool disabled = false,
  }) {
    String title = buttonTitle;

    if (isInProgress) {
      title = titleWhenProgress ?? buttonTitle;
    }

    return Padding(
      padding: outerPadding ?? EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (disabled) {
            onTapDisabledButton?.call();
          }
        },
        child: MaterialButton(
          minWidth: autoWidth == true ? null : (width ?? double.infinity),
          height: height ?? 56,
          padding: padding,
          shape: RoundedRectangleBorder(
            side: border ?? BorderSide.none,
            borderRadius: BorderRadius.circular(radius ?? 8),
          ),
          elevation: (showElevation ?? true) ? 0.5 : 0,
          color: buttonColor ?? context.color.territoryColor,
          disabledColor: disabledColor ?? context.color.deactivateColor,
          onPressed: (isInProgress || disabled)
              ? null
              : () {
                  HelperUtils.unfocus();
                  onPressed.call();
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInProgress) ...{
                UiUtils.progress(
                  width: progressWidth ?? 16,
                  height: progressHeight ?? 16,
                ),
              },
              if (!isInProgress && prefixWidget != null) prefixWidget,
              if (!isInProgress || (showProgressTitle ?? false))
                Flexible(
                  child: CustomText(
                    title,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    color: textColor ?? context.color.buttonColor,
                    fontSize: fontSize ?? context.font.larger,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @Deprecated('Use CustomImage instead')
  static Widget imageType(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
  }) {
    String? extension = mime(url);
    if (extension == "image/svg+xml") {
      return getSvgImage(
        url,
        fit: fit,
        height: height,
        width: width,
        color: color,
      );
    } else {
      return getImage(url, fit: fit, height: height, width: width);
    }
  }

  static void showFullScreenImage(
    BuildContext context, {
    required ImageProvider provider,
    VoidCallback? then,
  }) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            barrierDismissible: true,
            builder: (BuildContext context) =>
                FullScreenImageView(provider: provider),
          ),
        )
        .then((value) {
          then?.call();
        });
  }

  static void noPackageAvailableDialog(BuildContext context) async {
    UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: 'noPackage'.translate(context),
        acceptButtonName: 'subscribe'.translate(context),
        cancelButtonName: 'cancel'.translate(context),
        acceptButtonColor: context.color.territoryColor,
        acceptTextColor: context.color.secondaryColor,
        content: StatefulBuilder(
          builder: (context, update) {
            return CustomText('plsSubscribe'.translate(context));
          },
        ),
        isAcceptContainerPush: false,
        onAccept: () async {
          Future.delayed(Duration(seconds: 1), () {
            Navigator.pushNamed(context, Routes.subscriptionPackageListRoute);
          });
        },
      ),
    );
  }

  static Future showBlurredDialoge(
    BuildContext context, {
    required BlurDialog dialoge,
    double? sigmaX,
    double? sigmaY,
  }) async {
    return await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          if (dialoge is BlurredDialogBox) return dialoge;
          if (dialoge is BlurredDialogBuilderBox) return dialoge;
          if (dialoge is EmptyDialogBox) return dialoge;

          return Container();
        },
      ),
    );
  }

  static String monthYearDate(String date) {
    DateTime dateTime = DateTime.parse(date);

    final supportsLocale = DateFormat.localeExists(AppSession.currentLocale);

    return DateFormat(
      'MMMM yyyy',
      supportsLocale ? AppSession.currentLocale : Intl.defaultLocale,
    ).format(dateTime);
  }

  /// it will return user's sim cards country code
  static Future<Country> getSimCountry() async {
    CountryService countryCodeService = CountryService();
    List<Country> countryList = countryCodeService.getAll();
    String? simCountryCode;

    try {
      simCountryCode = await DeviceRegion.getSIMCountryCode();
    } catch (e) {}

    Country simCountry = countryList.firstWhere(
      (element) {
        if (Constant.isDemoModeOn) {
          return countryList.any(
            (element) => element.phoneCode == AppConfig.defaultCountryCode,
          );
        } else {
          return element.phoneCode == simCountryCode;
        }
      },
      orElse: () {
        return countryList
            .where((element) => element.phoneCode == AppConfig.defaultPhoneCode)
            .first;
      },
    );

    if (Constant.isDemoModeOn) {
      simCountry = countryList
          .where((element) => element.phoneCode == Constant.demoCountryCode)
          .first;
    }

    return simCountry;
  }

  static bool displayPrice(ItemModel item) {
    final category = item.category;

    if (category?.isJobCategory == 1) {
      return item.formattedSalary != null;
    } else if (category?.priceOptional == 1) {
      return item.formattedPrice != null;
    } else {
      return true;
    }
  }

  static Widget getPriceWidget(ItemModel item, BuildContext context) {
    final category = item.category;
    final color = context.color.territoryColor;

    if (category?.isJobCategory == 1) {
      return CustomText(
        '${item.formattedSalary}',
        color: color,
        fontWeight: FontWeight.bold,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        fontSize: context.font.large,
        maxLines: 1,
      );
    } else if (category?.priceOptional == 1) {
      if (item.price != null) {
        return CustomText(
          item.formattedPrice ?? item.price!.currencyFormat,
          color: color,
          fontWeight: FontWeight.bold,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          fontSize: context.font.large,
          maxLines: 1,
        );
      }
    } else {
      return CustomText(
        item.formattedPrice ?? (item.price ?? 0.0).currencyFormat,
        color: color,
        fontWeight: FontWeight.bold,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        fontSize: context.font.larger,
        maxLines: 1,
      );
    }

    return SizedBox.shrink();
  }

  static String formatDisplayAddress(String address) {
    // Split by comma and trim extra spaces
    List<String> parts = address.split(',').map((e) => e.trim()).toList();

    // Remove consecutive duplicates
    List<String> uniqueParts = [];
    for (int i = 0; i < parts.length; i++) {
      if (i == 0 || parts[i].toLowerCase() != parts[i - 1].toLowerCase()) {
        uniqueParts.add(parts[i]);
      }
    }

    // Join back into formatted address
    return uniqueParts.join(', ');
  }
}

///Format string
extension FormatAmount on String {
  String formatDate({String? format}) {
    DateFormat dateFormat;
    final locale = DateFormat.localeExists(AppSession.currentLocale)
        ? AppSession.currentLocale
        : Intl.defaultLocale;
    dateFormat = DateFormat(format ?? "MMM d, yyyy", locale);
    String formatted = dateFormat.format(DateTime.parse(this));
    return formatted;
  }

  String firstUpperCase() {
    String upperCase = "";
    var suffix = "";
    if (isNotEmpty) {
      upperCase = this[0].toUpperCase();
      suffix = substring(1, length);
    }
    return (upperCase + suffix);
  }
}

//scroll controller extenstion

extension ScrollEndListen on ScrollController {
  /// Detect near-bottom instead of exact end to reduce repeated triggers
  bool isEndReached({double offsetThreshold = 400}) {
    if (!hasClients || position.outOfRange) return false;
    return position.extentAfter < offsetThreshold;
  }
}

class RoundedBorderOnSomeSidesWidget extends StatelessWidget {
  /// Color of the content behind this widget
  final Color contentBackgroundColor;
  final Color borderColor;
  final Widget child;

  final double borderRadius;
  final double borderWidth;

  /// The sides where we want the rounded border to be
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const RoundedBorderOnSomeSidesWidget({
    super.key,
    required this.borderColor,
    required this.contentBackgroundColor,
    required this.child,
    required this.borderRadius,
    required this.borderWidth,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    Radius mainRadius = Radius.circular(borderRadius);
    Radius subRadius = Radius.circular(borderRadius - borderWidth);
    return Container(
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: BorderRadius.only(
          topLeft: topLeft ? mainRadius : Radius.zero,
          topRight: topRight ? mainRadius : Radius.zero,
          bottomLeft: bottomLeft ? mainRadius : Radius.zero,
          bottomRight: bottomRight ? mainRadius : Radius.zero,
        ),
      ),
      child: Container(
        margin: EdgeInsetsDirectional.only(
          top: topLeft || topRight ? borderWidth : 0,
          start: topLeft || bottomLeft ? borderWidth : 0,
          bottom: bottomLeft || bottomRight ? borderWidth : 0,
          end: topRight || bottomRight ? borderWidth : 0,
        ),
        decoration: BoxDecoration(
          color: contentBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: topLeft ? subRadius : Radius.zero,
            topRight: topRight ? subRadius : Radius.zero,
            bottomLeft: bottomLeft ? subRadius : Radius.zero,
            bottomRight: bottomRight ? subRadius : Radius.zero,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AnnotatedSafeArea extends StatefulWidget {
  final Widget child;
  final bool isAnnotated;
  final Color? statusBarColor;
  final Color? navigationBarColor;

  const AnnotatedSafeArea({
    super.key,
    required this.child,
    this.isAnnotated = false,
    this.navigationBarColor,
    this.statusBarColor,
  });

  @override
  State<AnnotatedSafeArea> createState() => _AnnotatedSafeAreaState();
}

class _AnnotatedSafeAreaState extends State<AnnotatedSafeArea> {
  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: widget.statusBarColor ?? context.color.secondaryColor,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: widget.child,
    );

    if (widget.isAnnotated) {
      content = AnnotatedRegion<SystemUiOverlayStyle>(
        value: UiUtils.getSystemUiOverlayStyle(
          context: context,
          statusBarColor: widget.statusBarColor ?? context.color.secondaryColor,
          navigationBarColor:
              widget.navigationBarColor ?? context.color.secondaryColor,
        ),
        child: content,
      );
    }

    return content;
  }
}
