import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/currency/fetch_currencies_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_language_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.itemSlug, super.key, this.sellerId});

  final String? itemSlug;
  final String? sellerId;

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  static const String _splashVideoAsset = 'assets/videos/splash.MOV';

  late final VideoPlayerController _videoController;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isVideoReady = false;
  bool _isVideoCompleted = false;
  bool _isSettingsLoaded = false;
  bool _hasNavigated = false;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    context.read<FetchSystemSettingsCubit>().fetchSettings();

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;

      final isConnected = !result.contains(ConnectivityResult.none);
      setState(() => hasInternet = isConnected);

      if (isConnected) {
        context.read<FetchSystemSettingsCubit>().fetchSettings(
          forceRefresh: true,
        );
      }
    });
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(_splashVideoAsset);

    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      _videoController.addListener(_handleVideoProgress);

      if (!mounted) return;
      setState(() => _isVideoReady = true);
      await _videoController.play();
    } catch (error) {
      debugPrint('Failed to play splash video: $error');
      _markVideoCompleted();
    }
  }

  void _handleVideoProgress() {
    final value = _videoController.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;

    if (value.position >= value.duration && !_isVideoCompleted) {
      _markVideoCompleted();
    }
  }

  void _markVideoCompleted() {
    if (_isVideoCompleted || !mounted) return;
    _isVideoCompleted = true;
    _navigateCheck();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _videoController.removeListener(_handleVideoProgress);
    _videoController.dispose();
    super.dispose();
  }

  void _navigateCheck() {
    if (_hasNavigated || !_isVideoCompleted || !_isSettingsLoaded || !mounted) {
      return;
    }

    _hasNavigated = true;
    _navigateToScreen();
  }

  void _navigateToScreen() {
    if (context.read<FetchSystemSettingsCubit>().getSetting(
          SystemSetting.maintenanceMode,
        ) ==
        '1') {
      Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
    } else if (HiveUtils.isUserFirstTime()) {
      Navigator.of(context).pushReplacementNamed(Routes.onboarding);
    } else if (HiveUtils.isUserAuthenticated() || HiveUtils.isUserSkip()) {
      Navigator.of(context).pushReplacementNamed(
        Routes.main,
        arguments: {
          'from': 'main',
          'slug': widget.itemSlug,
          'sellerId': widget.sellerId,
        },
      );
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return hasInternet
        ? MultiBlocListener(
            listeners: [
              BlocListener<FetchLanguageCubit, FetchLanguageState>(
                listener: (context, state) {
                  if (state is FetchLanguageSuccess) {
                    final map = state.toMap();
                    map['data'] = map['file_name'];
                    map.remove('file_name');

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
                    _isSettingsLoaded = true;
                    _navigateCheck();
                  } else if (state is FetchSystemSettingsFailure) {
                    _isSettingsLoaded = true;
                    _navigateCheck();
                  }
                },
              ),
            ],
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.black,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
              child: Scaffold(
                backgroundColor: Colors.black,
                body: _SplashVideo(
                  controller: _videoController,
                  isReady: _isVideoReady,
                ),
              ),
            ),
          )
        : Material(
            child: Center(child: NoInternet(onRetry: () => setState(() {}))),
          );
  }
}

class _SplashVideo extends StatelessWidget {
  const _SplashVideo({required this.controller, required this.isReady});

  final VideoPlayerController controller;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const SizedBox.expand(child: ColoredBox(color: Colors.black));
    }

    final videoSize = controller.value.size;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
