import 'dart:ui';

import 'package:lottie/lottie.dart';

class LottieAssets {
  static const _base = 'assets/lottie';

  static const String loading = '$_base/loading.json';
  static const String success = '$_base/success.json';
  static const String maintenance = '$_base/maintenance.json';

  // Todo(I): Remove this if not required
  static const String loadingWhite = '$_base/loading_white.json';
}

class LottieUtility {
  static LottieBuilder getAsset(String assetName, {bool repeat = true}) =>
      Lottie.asset(assetName, repeat: repeat);

  static LottieBuilder loadingIndicator({
    double? width,
    double? height,
    Color? color,
    bool play = true,
    bool preserveMatte = true,
  }) {
    return LottieBuilder.asset(
      LottieAssets.loading,
      width: width ?? 70,
      height: height ?? 70,
      animate: play,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(const [
            'center dot',
            'Ellipse 1',
            'Fill 1',
          ], value: color),
          ValueDelegate.color(const [
            'center zoom in',
            'Ellipse 1',
            'Fill 1',
          ], value: color),
          ValueDelegate.color(const [
            'center mask out',
            'Ellipse 1',
            'Fill 1',
          ], value: color),

          ValueDelegate.strokeColor(const [
            'Semi circle 1',
            'Ellipse 1',
            'Stroke 1',
          ], value: color),
          ValueDelegate.strokeColor(const [
            'Semi circle 2',
            'Ellipse 1',
            'Stroke 1',
          ], value: color),

          ValueDelegate.strokeColor(const ['**', 'Stroke 1'], value: color),
          ValueDelegate.color(const ['**', 'Fill 1'], value: color),

          if (!preserveMatte)
            ValueDelegate.color(const [
              'matte',
              'Ellipse 1',
              'Fill 1',
            ], value: color),
        ],
      ),
    );
  }
}
