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

class CustomCheckboxField extends CustomField {
  @override
  String type = "checkbox";

  final List<OptionItem> options = List.empty(growable: true);
  final Set<String> selectedOptions = <String>{};

  @override
  void init() {
    options.clear();
    selectedOptions.clear();
    final englishValues = parameters['values'] as List;
    final translatedValues = parameters['translated_value'] as List?;
    final selectedValues = parameters['value'] as List? ?? [];

    for (int i = 0; i < englishValues.length; ++i) {
      final selected = selectedValues.contains(englishValues[i]);

      options.add(
        OptionItem(value: englishValues[i], label: translatedValues?[i]),
      );

      if (selected) {
        selectedOptions.add(options.last.value);
      }
    }
    super.init();
  }

  @override
  Widget render() {
    if (options.isEmpty) return const SizedBox.shrink();
    final title = parameters['translated_name'] ?? parameters['name'];

    return CustomValidator<List>(
      initialValue: selectedOptions.toList(),
      validator: (List? value) {
        if (parameters['required'] != 1) {
          return null;
        }

        if (value?.isNotEmpty == true || selectedOptions.isNotEmpty) {
          return null;
        }

        return "pleaseSelectValue".translate(context);
      },
      builder: (state) {
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
                  selectedValues: selectedOptions.toList(),
                  allowMultiple: true,
                );

                if (result == null) return;

                selectedOptions
                  ..clear()
                  ..addAll(result);
                AbstractField.fieldsData.addAll({
                  parameters['id'].toString(): selectedOptions.toList(),
                });
                state.didChange(selectedOptions.toList());
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
                        selectedOptions.isEmpty
                            ? "selectLbl".translate(context)
                            : "${selectedOptions.length} ${"selected".translate(context)}",
                        color: selectedOptions.isEmpty
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
            if (selectedOptions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedOptions.map((value) {
                  final label = options
                      .where((option) => option.value == value)
                      .firstOrNull
                      ?.label;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.color.territoryColor.withValues(
                        alpha: 0.1,
                      ),
                      border: Border.all(
                        color: context.color.territoryColor.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      label ?? value,
                      color: context.color.territoryColor,
                      fontSize: context.font.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 24,
              width: 24,
              child: FittedBox(
                fit: BoxFit.none,
                child: UiUtils.imageType(
                  parameters['image'],
                  width: 24,
                  height: 24,
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
            color: context.color.textDefaultColor,
          ),
        ),
      ],
    );
  }
}
