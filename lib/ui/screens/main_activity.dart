// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/app_update_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/listeners/notification_provider.dart';
import 'package:eClassify/ui/screens/chat/chat_list_screen.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/item/my_items_screen.dart';
import 'package:eClassify/ui/screens/user_profile/profile_screen.dart';
import 'package:eClassify/ui/screens/widgets/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:eClassify/ui/screens/widgets/bottom_navigation_bar/diamond_fab.dart';
import 'package:eClassify/ui/screens/widgets/maintenance_mode.dart';
import 'package:eClassify/ui/screens/widgets/version_update_dialog.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Map<String, dynamic> searchBody = {};
String selectedCategoryId = "0";
String selectedCategoryName = "";
dynamic selectedCategory;

//this will set when i will visit in any category
dynamic currentVisitingCategoryId = "";
dynamic currentVisitingCategory = "";

class MainActivity extends StatefulWidget {
  final String from;
  final String? itemSlug;
  final String? sellerId;
  static final GlobalKey<MainActivityState> globalKey =
      GlobalKey<MainActivityState>();

  MainActivity({Key? key, required this.from, this.itemSlug, this.sellerId})
    : super(key: globalKey);

  @override
  State<MainActivity> createState() => MainActivityState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => NotificationProvider(
        child: BlocProvider(
          create: (context) => AppUpdateCubit(),
          child: MainActivity(
            from: arguments['from'] as String,
            itemSlug: arguments['slug'] as String?,
            sellerId: arguments['sellerId'] as String?,
          ),
        ),
      ),
    );
  }
}

class MainActivityState extends State<MainActivity> {
  final PageController _pageController = PageController();
  final BottomNavigationController _bottomNavigationController =
      BottomNavigationController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    FetchSystemSettingsCubit settings = context
        .read<FetchSystemSettingsCubit>();
    if (!bool.fromEnvironment(
      Constant.forceDisableDemoMode,
      defaultValue: false,
    )) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) ?? false;
    }

    ///This will check for update
    versionCheck(settings);

    if (widget.itemSlug != null) {
      Navigator.of(context).pushNamed(
        Routes.adDetailsScreen,
        arguments: {"slug": widget.itemSlug!},
      );
    }
    if (widget.sellerId != null) {
      Navigator.pushNamed(
        context,
        Routes.sellerProfileScreen,
        arguments: {"sellerId": int.parse(widget.sellerId!)},
      );
    }

    _bottomNavigationController.addListener(() {
      _pageController.jumpToPage(_bottomNavigationController.index);
    });
  }

  void versionCheck(FetchSystemSettingsCubit settings) async {
    final remoteVersion =
        settings.getSetting(
              Platform.isIOS
                  ? SystemSetting.iosVersion
                  : SystemSetting.androidVersion,
            )
            as String;
    final forceUpdate =
        settings.getSetting(SystemSetting.forceUpdate) as String == '1';

    context.read<AppUpdateCubit>().checkForUpdates(
      remoteVersion: remoteVersion,
      forceUpdate: forceUpdate,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomNavigationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.primaryColor,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_bottomNavigationController.index != 0) {
            _bottomNavigationController.changeIndex(0);
          } else {
            if (_timer == null) {
              _timer = Timer(const Duration(seconds: 2), () {
                _timer?.cancel();
                _timer = null;
              });
              HelperUtils.showSnackBarMessage(
                context,
                "pressAgainToExit".translate(context),
                isFloating: true,
              );
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          bottomNavigationBar: CustomBottomNavigationBar(
            controller: _bottomNavigationController,
          ),
          floatingActionButton: DiamondFab(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          body: BlocListener<AppUpdateCubit, AppUpdateState>(
            listener: (context, state) {
              if (state is AppUpdateAvailable) {
                VersionUpdateDialog.show(
                  context,
                  availableVersion: state.required,
                  isForceUpdate: state.isMandatory,
                );
              }
            },
            child: Stack(
              children: <Widget>[
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    HomeScreen(from: widget.from),
                    ChatListScreen(),
                    ItemsScreen(),
                    const ProfileScreen(),
                  ],
                ),
                if (Constant.maintenanceMode == "1") MaintenanceMode(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onItemTapped(int index) {
    _bottomNavigationController.changeIndex(index);
  }
}
