import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

class SkipButtonWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final String labelKey;

  const SkipButtonWidget({super.key, this.onTap, this.labelKey = 'skip'});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.color.territoryColor;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: backgroundColor.computeLuminance() > 0.5
            ? context.color.textDefaultColor
            : context.color.buttonColor,
        shape: StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      child: Text(labelKey.translate(context)),
    );
  }
}
