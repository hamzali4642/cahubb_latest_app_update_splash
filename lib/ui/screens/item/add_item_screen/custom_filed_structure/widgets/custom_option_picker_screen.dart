import 'package:eClassify/ui/screens/item/add_item_screen/custom_filed_structure/option_item.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class CustomOptionPickerScreen extends StatefulWidget {
  const CustomOptionPickerScreen({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.allowMultiple,
  });

  final String title;
  final List<OptionItem> options;
  final List<String> selectedValues;
  final bool allowMultiple;

  static Future<List<String>?> open(
    BuildContext context, {
    required String title,
    required List<OptionItem> options,
    required List<String> selectedValues,
    required bool allowMultiple,
  }) {
    return Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CustomOptionPickerScreen(
          title: title,
          options: options,
          selectedValues: selectedValues,
          allowMultiple: allowMultiple,
        ),
      ),
    );
  }

  @override
  State<CustomOptionPickerScreen> createState() =>
      _CustomOptionPickerScreenState();
}

class _CustomOptionPickerScreenState extends State<CustomOptionPickerScreen> {
  late final Set<String> _selectedValues = widget.selectedValues.toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.color.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.color.textDefaultColor),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: CustomText(
          widget.title,
          color: context.color.textDefaultColor,
          fontSize: context.font.large,
          fontWeight: FontWeight.w700,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.color.borderColor,
          ),
        ),
      ),
      bottomNavigationBar: widget.allowMultiple
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: UiUtils.buildButton(
                context,
                onPressed: () {
                  Navigator.pop(context, _selectedValues.toList());
                },
                height: 48,
                radius: 8,
                buttonTitle: "save".translate(context),
              ),
            )
          : null,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        itemCount: widget.options.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, thickness: 1, color: context.color.borderColor),
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final isSelected = _selectedValues.contains(option.value);

          return InkWell(
            onTap: () {
              if (!widget.allowMultiple) {
                Navigator.pop(context, [option.value]);
                return;
              }

              setState(() {
                if (isSelected) {
                  _selectedValues.remove(option.value);
                } else {
                  _selectedValues.add(option.value);
                }
              });
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      option.label,
                      color: context.color.textDefaultColor,
                      fontSize: context.font.large,
                    ),
                  ),
                  if (widget.allowMultiple && isSelected)
                    Icon(Icons.check, color: context.color.territoryColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
