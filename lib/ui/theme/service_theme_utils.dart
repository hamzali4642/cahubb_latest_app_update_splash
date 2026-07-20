import 'package:flutter/material.dart';

import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';

bool isDarkTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color serviceSurface(
  BuildContext context, {
  Color? baseColor,
  double lightAlpha = 0.05,
  double darkAlpha = 0.18,
}) {
  final overlay = context.color.territoryColor.withValues(
    alpha: isDarkTheme(context) ? darkAlpha : lightAlpha,
  );
  return Color.alphaBlend(overlay, baseColor ?? context.color.secondaryColor);
}

Color serviceMutedSurface(
  BuildContext context, {
  double lightAlpha = 0.04,
  double darkAlpha = 0.12,
}) {
  return serviceSurface(
    context,
    baseColor: context.color.primaryColor,
    lightAlpha: lightAlpha,
    darkAlpha: darkAlpha,
  );
}

Color serviceImageSurface(BuildContext context) {
  return serviceSurface(context, lightAlpha: 0.02, darkAlpha: 0.26);
}

Color serviceAccentSurface(
  BuildContext context, {
  double lightAlpha = 0.08,
  double darkAlpha = 0.24,
}) {
  return serviceSurface(context, lightAlpha: lightAlpha, darkAlpha: darkAlpha);
}

Color serviceWarningSurface(BuildContext context) {
  final overlay = warningMessageColor.withValues(
    alpha: isDarkTheme(context) ? 0.22 : 0.12,
  );
  return Color.alphaBlend(overlay, context.color.secondaryColor);
}

Color serviceWarningForeground(BuildContext context) {
  return isDarkTheme(context)
      ? warningMessageColor.withValues(alpha: 0.95)
      : const Color(0xFFC99700);
}

Color serviceShadow(BuildContext context, {double alpha = 0.05}) {
  final resolvedAlpha = isDarkTheme(context) ? alpha * 3 : alpha;
  return Colors.black.withValues(alpha: resolvedAlpha.clamp(0, 1));
}

LinearGradient serviceHeroGradient(BuildContext context) {
  return LinearGradient(
    colors: [
      serviceSurface(context, lightAlpha: 0.08, darkAlpha: 0.22),
      serviceMutedSurface(context, lightAlpha: 0.02, darkAlpha: 0.1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
