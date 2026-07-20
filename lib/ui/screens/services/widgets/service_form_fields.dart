import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:flutter/material.dart';

/// Shared visual contract for inputs used by every vehicle service flow.
class ServiceTextField extends StatelessWidget {
  const ServiceTextField({
    required this.controller,
    super.key,
    this.title,
    this.icon,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.prefixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? title;
  final IconData? icon;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          ServiceFieldLabel(title: title!, icon: icon),
          10.vGap,
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          decoration: serviceFieldDecoration(
            context,
            hintText: hintText,
            prefixIcon: prefixIcon,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}

class ServiceSelectionField extends StatelessWidget {
  const ServiceSelectionField({
    required this.title,
    required this.hintText,
    super.key,
    this.icon,
    this.value,
    this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String hintText;
  final IconData? icon;
  final String? value;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.trim().isNotEmpty == true;
    final enabled = onTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceFieldLabel(title: title, icon: icon),
        10.vGap,
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: serviceFieldBoxDecoration(context, enabled: enabled),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      hasValue ? value! : hintText,
                      fontSize: context.font.large,
                      color: hasValue
                          ? context.color.textDefaultColor
                          : context.color.textLightColor,
                      maxLines: 2,
                    ),
                  ),
                  12.hGap,
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.color.territoryColor,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.color.textLightColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ServiceFieldLabel extends StatelessWidget {
  const ServiceFieldLabel({required this.title, super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final label = CustomText(
      title,
      fontSize: context.font.larger,
      fontWeight: FontWeight.w600,
      color: context.color.textDefaultColor,
    );

    if (icon == null) return label;
    return Row(
      children: [
        Icon(icon, size: 20, color: context.color.territoryColor),
        9.hGap,
        Expanded(child: label),
      ],
    );
  }
}
