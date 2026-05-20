import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/cubits/currency/fetch_currencies_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_language_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

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

  // 🔥 Animation
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _controller.forward();

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
    _controller.dispose();
    subscription.cancel();
    super.dispose();
  }

  Future<void> startTimer() async {
    if (_timerStarted) return;
    _timerStarted = true;

    Timer(const Duration(seconds: 3), () {
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
    if (context.read<FetchSystemSettingsCubit>().getSetting(
      SystemSetting.maintenanceMode,
    ) ==
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
    } else {
      if (HiveUtils.isUserSkip()) {
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
        BlocListener<FetchSystemSettingsCubit,
            FetchSystemSettingsState>(
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
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF132A6B),

          body: Container(
            color: Colors.white, // 🔥 full white background

            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double t = _controller.value;

                  return Stack(
                    alignment: Alignment.center,
                    children: [

                      // 🔥 LOGO (moves from left → center)
                      Transform.translate(
                        offset: Offset(-120 * (1 - t), 0),
                        child: Transform.scale(
                          scale: 0.6 + (0.4 * t),
                          child: SvgPicture.asset(
                            'assets/svg/Logo/splashlogo.svg',
                            height: 90,
                          ),
                        ),
                      ),

                      // 🔵 CAHUBB.COM (moves INTO logo)
                      Transform.translate(
                        offset: Offset(0, 0),
                        child: Opacity(
                          opacity: 1 - t,
                          child: Transform.translate(
                            offset: Offset(0, 0),
                            child: const Text(
                              "CAHUBB.COM",
                              style: TextStyle(
                                color: Color(0xFF0A1F44),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 🟡 BUY & SELL (same merge behavior)
                      Opacity(
                        opacity: 1 - t,
                        child: Transform.translate(
                          offset: Offset(0, 30),
                          child: const Text(
                            "BUY & SELL",
                            style: TextStyle(
                              color: Color(0xFFB08D2A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),        ),
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
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:eClassify/app/routes.dart';
// import 'package:eClassify/app_config.dart';
// import 'package:eClassify/data/cubits/currency/fetch_currencies_cubit.dart';
// import 'package:eClassify/data/cubits/system/fetch_language_cubit.dart';
// import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
// import 'package:eClassify/data/cubits/system/language_cubit.dart';
// import 'package:eClassify/data/model/system_settings_model.dart';
// import 'package:eClassify/ui/screens/widgets/custom_image.dart';
// import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
// import 'package:eClassify/ui/theme/theme.dart';
// import 'package:eClassify/utils/app_icon.dart';
// import 'package:eClassify/utils/constant.dart';
// import 'package:eClassify/utils/custom_text.dart';
// import 'package:eClassify/utils/extensions/extensions.dart';
// import 'package:eClassify/utils/hive_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({this.itemSlug, super.key, this.sellerId});
//
//   final String? itemSlug;
//   final String? sellerId;
//
//   @override
//   SplashScreenState createState() => SplashScreenState();
// }
//
// class SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//
//   bool isTimerCompleted = false;
//   bool isSettingsLoaded = false;
//   bool _hasNavigated = false;
//   bool _timerStarted = false;
//   bool hasInternet = true;
//
//   late StreamSubscription<List<ConnectivityResult>> subscription;
//
//   /// 🔥 ANIMATION CONTROLLER
//   late AnimationController _controller;
//   late Animation<Offset> _cAnimation;
//   late Animation<Offset> _aAnimation;
//   late Animation<double> _textOpacity;
//   late Animation<Offset> _textSlide;
//
//   @override
//   void initState() {
//     super.initState();
//
//     /// 🔥 INIT ANIMATION
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//
//     _cAnimation = Tween<Offset>(
//       begin: const Offset(-2, 0),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     ));
//
//     _aAnimation = Tween<Offset>(
//       begin: const Offset(2, 0),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//     ));
//
//     _textOpacity = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
//       ),
//     );
//
//     _textSlide = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
//     ));
//
//     _controller.forward();
//
//     /// 🔥 EXISTING LOGIC (UNCHANGED)
//     context.read<FetchSystemSettingsCubit>().fetchSettings();
//     startTimer();
//
//     subscription = Connectivity().onConnectivityChanged.listen((result) {
//       setState(() {
//         hasInternet = (!result.contains(ConnectivityResult.none));
//       });
//
//       if (hasInternet) {
//         context.read<FetchSystemSettingsCubit>().fetchSettings(
//           forceRefresh: true,
//         );
//         startTimer();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     subscription.cancel();
//     super.dispose();
//   }
//
//   Future<void> startTimer() async {
//     if (_timerStarted) return;
//     _timerStarted = true;
//     Timer(const Duration(seconds: 2), () {
//       isTimerCompleted = true;
//       navigateCheck();
//     });
//   }
//
//   void navigateCheck() {
//     if (_hasNavigated) return;
//     if (isTimerCompleted && isSettingsLoaded) {
//       _hasNavigated = true;
//       navigateToScreen();
//     }
//   }
//
//   void navigateToScreen() {
//     if (context.read<FetchSystemSettingsCubit>().getSetting(
//       SystemSetting.maintenanceMode,
//     ) ==
//         "1") {
//       Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
//     } else if (HiveUtils.isUserFirstTime()) {
//       Navigator.of(context).pushReplacementNamed(Routes.onboarding);
//     } else if (HiveUtils.isUserAuthenticated()) {
//       Navigator.of(context).pushReplacementNamed(
//         Routes.main,
//         arguments: {
//           'from': "main",
//           "slug": widget.itemSlug,
//           "sellerId": widget.sellerId,
//         },
//       );
//     } else {
//       if (HiveUtils.isUserSkip()) {
//         Navigator.of(context).pushReplacementNamed(
//           Routes.main,
//           arguments: {
//             'from': "main",
//             "slug": widget.itemSlug,
//             "sellerId": widget.sellerId,
//           },
//         );
//       } else {
//         Navigator.of(context).pushReplacementNamed(Routes.login);
//       }
//     }
//   }
//
//   Widget? _companyLogo() {
//     if (AppConfig.showCompanyLogo) {
//       return Padding(
//         padding: const EdgeInsets.only(bottom: 10),
//         child: CustomImage(src: AppIcons.companyLogo),
//       );
//     }
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return hasInternet
//         ? MultiBlocListener(
//       listeners: [
//         BlocListener<FetchLanguageCubit, FetchLanguageState>(
//           listener: (context, state) {
//             if (state is FetchLanguageSuccess) {
//               Map<String, dynamic> map = state.toMap();
//               var data = map['file_name'];
//               map['data'] = data;
//               map.remove("file_name");
//
//               HiveUtils.storeLanguage(map);
//               context.read<LanguageCubit>().changeLanguages(map);
//             }
//           },
//         ),
//         BlocListener<FetchSystemSettingsCubit,
//             FetchSystemSettingsState>(
//           listener: (context, state) {
//             if (state is FetchSystemSettingsSuccess) {
//               Constant.isDemoModeOn = context
//                   .read<FetchSystemSettingsCubit>()
//                   .getSetting(SystemSetting.demoMode);
//
//               if (HiveUtils.getLanguage() == null) {
//                 context.read<FetchLanguageCubit>().getLanguage(
//                   state.settings['data']['default_language'],
//                 );
//               }
//               context.read<FetchCurrenciesCubit>().fetchCurrencies();
//
//               isSettingsLoaded = true;
//               navigateCheck();
//             }
//             if (state is FetchSystemSettingsFailure) {
//               isSettingsLoaded = true;
//               navigateCheck();
//             }
//           },
//         ),
//       ],
//       child: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: const SystemUiOverlayStyle(
//           statusBarColor: Colors.white,
//           statusBarIconBrightness: Brightness.dark,
//           systemNavigationBarColor: Colors.white,
//           systemNavigationBarIconBrightness: Brightness.dark,
//         ),
//         child: Scaffold(
//           backgroundColor: Colors.white,
//           // bottomNavigationBar: _companyLogo(),
//           body: Stack(
//             children: [
//
//               /// 🔥 BACKGROUND SVG
//               Positioned(
//                 bottom: 2, // 👈 gap remove (adjust -10 / -15)
//                 left: -10,    // 👈 side spacing (zyada = choti lagegi)
//                 right: -10,
//                 child: FractionallySizedBox(
//                   widthFactor: 0.80, // 👈 🔥 size control (0.6–0.85 try karo)
//                   child: Image.asset(
//                     'assets/images/sdfs.png',
//                     fit: BoxFit.fitWidth,
//                   ),
//                 ),
//               ),
//               /// 🔥 MAIN CONTENT (tumhari animation)
//               Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//
//                     /// 🔥 PREMIUM BOX (ONLY LOGO)
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFF1E3A8A).withOpacity(0.18),
//                             blurRadius: 28,
//                             spreadRadius: 2,
//                             offset: const Offset(0, 12),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//
//                           /// C
//                           SlideTransition(
//                             position: Tween<Offset>(
//                               begin: const Offset(-0.4, 0),
//                               end: Offset.zero,
//                             ).animate(
//                               CurvedAnimation(
//                                 parent: _controller,
//                                 curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
//                               ),
//                             ),
//                             child: const Text(
//                               "C",
//                               style: TextStyle(
//                                 fontSize: 72,
//                                 fontWeight: FontWeight.w900,
//                                 color: Color(0xFF1E3A8A),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 6),
//
//                           /// A
//                           SlideTransition(
//                             position: Tween<Offset>(
//                               begin: const Offset(0.4, 0),
//                               end: Offset.zero,
//                             ).animate(
//                               CurvedAnimation(
//                                 parent: _controller,
//                                 curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
//                               ),
//                             ),
//                             child: const Text(
//                               "A",
//                               style: TextStyle(
//                                 fontSize: 72,
//                                 fontWeight: FontWeight.w900,
//                                 color: Color(0xFF1E3A8A),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 25),
//
//                     /// TEXT
//                     FadeTransition(
//                       opacity: _textOpacity,
//                       child: SlideTransition(
//                         position: _textSlide,
//                         child: const Text(
//                           "CA HUBB",
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 3,
//                             color: Color(0xFF1E3A8A),
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 30),
//
//                     /// LOADER
//                     FadeTransition(
//                       opacity: _textOpacity,
//                       child: const SizedBox(
//                         height: 28,
//                         width: 28,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.8,
//                           color: Color(0xFF1E3A8A),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     )
//         : Material(
//       child: Center(
//         child: NoInternet(
//           onRetry: () {
//             setState(() {});
//           },
//         ),
//       ),
//     );
//   }
// }