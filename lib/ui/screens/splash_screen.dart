import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/cubits/currency/fetch_currencies_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_language_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.itemSlug, super.key, this.sellerId});

  final String? itemSlug;
  final String? sellerId;

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool isTimerCompleted = false;
  bool isSettingsLoaded = false;
  bool _hasNavigated = false;
  bool _timerStarted = false;
  bool hasInternet = true;

  late StreamSubscription<List<ConnectivityResult>> subscription;
  late AnimationController _nameController;
  late Animation<double> _nameOpacity;
  late Animation<Offset> _nameSlide;

  @override
  void initState() {
    super.initState();

    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _nameOpacity = CurvedAnimation(
      parent: _nameController,
      curve: Curves.easeOut,
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _nameController, curve: Curves.easeOutCubic),
        );
    _nameController.forward();

    context.read<FetchSystemSettingsCubit>().fetchSettings();
    startTimer();

    subscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        hasInternet = (!result.contains(ConnectivityResult.none));
      });

      if (hasInternet) {
        context.read<FetchSystemSettingsCubit>().fetchSettings(
          forceRefresh: true,
        );
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    subscription.cancel();
    super.dispose();
  }

  Future<void> startTimer() async {
    if (_timerStarted) return;
    _timerStarted = true;
    Timer(const Duration(seconds: 2), () {
      isTimerCompleted = true;
      navigateCheck();
    });
  }

  void navigateCheck() {
    if (_hasNavigated) return;
    if (isTimerCompleted && isSettingsLoaded) {
      _hasNavigated = true;
      navigateToScreen();
    }
  }

  void navigateToScreen() {
    if (context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.maintenanceMode)
            ?.toString() ==
        "1") {
      Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
    } else if (HiveUtils.isUserFirstTime()) {
      Navigator.of(context).pushReplacementNamed(Routes.onboarding);
    } else if (HiveUtils.isUserAuthenticated()) {
      Navigator.of(context).pushReplacementNamed(
        Routes.main,
        arguments: {
          'from': "main",
          "slug": widget.itemSlug,
          "sellerId": widget.sellerId,
        },
      );
    } else if (HiveUtils.isUserSkip()) {
      Navigator.of(context).pushReplacementNamed(
        Routes.main,
        arguments: {
          'from': "main",
          "slug": widget.itemSlug,
          "sellerId": widget.sellerId,
        },
      );
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    }
  }

  Widget? _companyLogo() {
    if (!AppConfig.showCompanyLogo) return null;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: CustomImage(src: AppIcons.companyLogo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return hasInternet
        ? MultiBlocListener(
            listeners: [
              BlocListener<FetchLanguageCubit, FetchLanguageState>(
                listener: (context, state) {
                  if (state is FetchLanguageSuccess) {
                    Map<String, dynamic> map = state.toMap();
                    var data = map['file_name'];
                    map['data'] = data;
                    map.remove("file_name");

                    HiveUtils.storeLanguage(map);
                    context.read<LanguageCubit>().changeLanguages(map);
                  }
                },
              ),
              BlocListener<FetchSystemSettingsCubit, FetchSystemSettingsState>(
                listener: (context, state) {
                  if (state is FetchSystemSettingsSuccess) {
                    Constant.isDemoModeOn = context
                        .read<FetchSystemSettingsCubit>()
                        .getSetting(SystemSetting.demoMode);

                    if (HiveUtils.getLanguage() == null) {
                      context.read<FetchLanguageCubit>().getLanguage(
                        state.settings['data']['default_language'],
                      );
                    }
                    context.read<FetchCurrenciesCubit>().fetchCurrencies();

                    isSettingsLoaded = true;
                    navigateCheck();
                  }
                  if (state is FetchSystemSettingsFailure) {
                    isSettingsLoaded = true;
                    navigateCheck();
                  }
                },
              ),
            ],
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.white,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: Scaffold(
                backgroundColor: context.color.territoryColor,
                bottomNavigationBar: _companyLogo(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CustomImage(
                            src: AppIcons.splashLogo,
                            size: Size(200, 200),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SlideTransition(
                        position: _nameSlide,
                        child: FadeTransition(
                          opacity: _nameOpacity,
                          child: CustomText(
                            AppConfig.applicationName,
                            fontSize: context.font.xxLarge,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Material(
            child: Center(
              child: NoInternet(
                onRetry: () {
                  setState(() {});
                },
              ),
            ),
          );
  }
}
