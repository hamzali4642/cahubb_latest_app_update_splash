import 'package:eClassify/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/custom_filed_structure/option_item.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/custom_filed_structure/widgets/custom_option_picker_screen.dart';
import 'package:eClassify/ui/screens/widgets/dynamic_field.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:flutter/material.dart';

class CustomFieldDropdown extends CustomField {
  @override
  String type = "dropdown";
  String? selected;

  final List<OptionItem> options = List.empty(growable: true);

  @override
  void init() {
    options.clear();
    final englishValues = parameters['values'] as List;
    final translatedValues = parameters['translated_value'] as List?;
    final selectedValues = parameters['value'] as List? ?? [];

    for (int i = 0; i < englishValues.length; ++i) {
      final selected = selectedValues.contains(englishValues[i]);

      options.add(
        OptionItem(value: englishValues[i], label: translatedValues?[i]),
      );

      if (selected) {
        this.selected = englishValues[i];
      }
    }
    super.init();
  }

  @override
  Widget render() {
    if (options.isEmpty) return const SizedBox.shrink();
    final title = parameters['translated_name'] ?? parameters['name'];

    return CustomValidator<String>(
      initialValue: selected,
      validator: (_) {
        if (parameters['required'] == 1 &&
            (selected == null || selected!.isEmpty)) {
          return 'field_required'.translate(context);
        }
        return null;
      },
      builder: (state) {
        final selectedLabel = selected == null
            ? null
            : options
                  .where((option) => option.value == selected)
                  .firstOrNull
                  ?.label;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldTitle(parameters: parameters, title: title),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final result = await CustomOptionPickerScreen.open(
                  context,
                  title: title,
                  options: options,
                  selectedValues: selected == null ? [] : [selected!],
                  allowMultiple: false,
                );

                if (result == null || result.isEmpty) return;

                selected = result.first;
                AbstractField.fieldsData.addAll({
                  parameters['id'].toString(): [selected],
                });
                state.didChange(selected);
                update(() {});
              },
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 1,
                    color: state.hasError
                        ? context.color.error
                        : context.color.textLightColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        selectedLabel ?? "selectLbl".translate(context),
                        color: selectedLabel == null
                            ? context.color.textDefaultColor.withValues(
                                alpha: 0.5,
                              )
                            : context.color.textDefaultColor,
                        fontSize: context.font.large,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: context.color.textDefaultColor,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, top: 6),
                child: CustomText(
                  state.errorText ?? "",
                  color: context.color.error,
                  fontSize: context.font.small,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle({required this.parameters, required this.title});

  final Map parameters;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (parameters['image'] != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 20,
              width: 20,
              child: FittedBox(
                fit: BoxFit.none,
                child: UiUtils.imageType(
                  parameters['image'],
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  color: context.color.textDefaultColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: CustomText(
            title,
            fontSize: context.font.large,
            fontWeight: FontWeight.w500,
            color: context.color.textColorDark,
          ),
        ),
      ],
    );
  }
}
