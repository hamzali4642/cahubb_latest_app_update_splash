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

Color serviceFieldSurface(BuildContext context, {bool enabled = true}) {
  if (!enabled) return serviceMutedSurface(context);
  return serviceSurface(context, lightAlpha: 0.055, darkAlpha: 0.2);
}

Color serviceFieldBorder(BuildContext context) {
  if (isDarkTheme(context)) return context.color.borderColor;
  return Color.alphaBlend(
    context.color.territoryColor.withValues(alpha: 0.32),
    context.color.borderColor,
  );
}

InputDecoration serviceFieldDecoration(
  BuildContext context, {
  String? hintText,
  Widget? prefixIcon,
  bool enabled = true,
}) {
  final radius = BorderRadius.circular(12);
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: context.color.textLightColor),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: serviceFieldSurface(context, enabled: enabled),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: serviceFieldBorder(context), width: 1.2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: serviceFieldBorder(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: context.color.territoryColor, width: 1.6),
    ),
  );
}

BoxDecoration serviceFieldBoxDecoration(
  BuildContext context, {
  bool enabled = true,
}) {
  return BoxDecoration(
    color: serviceFieldSurface(context, enabled: enabled),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: serviceFieldBorder(context), width: 1.2),
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

/// A high-contrast selected-control color that remains readable in dark mode.
///
/// The standard territory color is white in the current dark theme, which is
/// unsuitable as a filled control background when paired with white labels.
Color serviceSelectionColor(BuildContext context) {
  return isDarkTheme(context)
      ? const Color(0xFF405E86)
      : context.color.territoryColor;
}

Color serviceSelectionForeground(BuildContext context) => Colors.white;

/// Surface and border for selectable controls before the user selects them.
Color serviceUnselectedControlSurface(BuildContext context) {
  return isDarkTheme(context)
      ? const Color(0xFF292929)
      : context.color.secondaryColor;
}

Color serviceUnselectedControlBorder(BuildContext context) {
  return isDarkTheme(context)
      ? const Color(0xFF505050)
      : context.color.borderColor;
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
