import 'package:eClassify/app/app.dart';
import 'package:eClassify/app/app_localization.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/register_cubits.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/ui/screens/onboarding/widgets/onboarding_page_view.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// v2.10.0 ///

void main() => initApp();

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  EntryPointState createState() => EntryPointState();
}

class EntryPointState extends State<EntryPoint> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: RegisterCubits().providers,
      child: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    context.read<LanguageCubit>().loadCurrentLanguage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheGlobalBackgrounds();
    });

    if (HiveUtils.isUserFirstTime()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheOnboardingAssets();
      });
    }
  }

  Future<void> _precacheOnboardingAssets() async {
    for (final data in kOnboardingList) {
      final assetName = data['svg'] as String;
      try {
        if (assetName.toLowerCase().endsWith('.svg')) {
          await SvgAssetLoader(assetName).loadBytes(context);
        } else {
          await precacheImage(AssetImage(assetName), context);
        }
      } catch (e) {
        debugPrint('Failed to precache asset "$assetName": $e');
      }
    }
  }

  Future<void> _precacheGlobalBackgrounds() async {
    const backgrounds = [
      'assets/images/de0108d22adca050b1b5e779a2aefac2.jpg',
      'assets/images/c2d6e8bf43e7bd6444705255acc28dd3.jpg',
    ];

    for (final assetName in backgrounds) {
      try {
        await precacheImage(AssetImage(assetName), context);
      } catch (e) {
        debugPrint('Failed to precache background "$assetName": $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppTheme currentTheme = context.watch<AppThemeCubit>().state;
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return MaterialApp(
          initialRoute: Routes.splash,
          navigatorKey: Constant.navigatorKey,
          title: AppConfig.applicationName,
          debugShowCheckedModeBanner: false,
          //showPerformanceOverlay: true,
          onGenerateRoute: Routes.onGenerateRouted,
          theme: appThemeData[currentTheme],
          builder: (context, child) {
            TextDirection direction = TextDirection.ltr;

            if (languageState is LanguageLoader) {
              direction = languageState.language['rtl']
                  ? TextDirection.rtl
                  : TextDirection.ltr;
            }
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Directionality(
                textDirection: direction,
                child: _AppPatternBackground(
                  theme: currentTheme,
                  child: child!,
                ),
              ),
            );
          },
          localizationsDelegates: const [
            AppLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: loadLocalLanguageIfFail(languageState),
        );
      },
    );
  }

  dynamic loadLocalLanguageIfFail(LanguageState state) {
    if ((state is LanguageLoader)) {
      return Locale(state.language['code']);
    } else if (state is LanguageLoadFail) {
      return const Locale("en");
    }
  }
}

class _AppPatternBackground extends StatelessWidget {
  const _AppPatternBackground({required this.theme, required this.child});

  final AppTheme theme;
  final Widget child;

  String get _assetPath => theme == AppTheme.dark
      ? 'assets/images/de0108d22adca050b1b5e779a2aefac2.jpg'
      : 'assets/images/c2d6e8bf43e7bd6444705255acc28dd3.jpg';

  double get _backgroundOpacity => theme == AppTheme.dark ? 0.30 : 0.08;

  Color get _baseTint => theme == AppTheme.dark
      ? const Color(0xFF070B15)
      : const Color(0xFFFBFDFF);

  Widget get _patternImage {
    if (theme == AppTheme.light) {
      return Image.asset(
        _assetPath,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        color: const Color(0xFFFCFEFF),
        colorBlendMode: BlendMode.multiply,
      );
    }
    return Image.asset(
      _assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: ColoredBox(color: _baseTint)),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(opacity: _backgroundOpacity, child: _patternImage),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
