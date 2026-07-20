import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/ui/screens/services/widgets/service_form_fields.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:flutter/material.dart';

class ServiceCityPicker extends StatefulWidget {
  const ServiceCityPicker({
    required this.cities,
    super.key,
    this.title = 'Select city',
    this.selectedCity,
  });

  final String title;
  final City? selectedCity;
  final List<City> cities;

  static Future<City?> show({
    required BuildContext context,
    required List<City> cities,
    City? selectedCity,
    String title = 'Select city',
  }) {
    return showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceCityPicker(
        title: title,
        cities: cities,
        selectedCity: selectedCity,
      ),
    );
  }

  @override
  State<ServiceCityPicker> createState() => _ServiceCityPickerState();
}

class _ServiceCityPickerState extends State<ServiceCityPicker> {
  final TextEditingController _searchController = TextEditingController();
  late List<City> _filteredCities;

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.cities;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    setState(() {
      _filteredCities = normalizedQuery.isEmpty
          ? widget.cities
          : widget.cities.where((city) {
              return city.name.localized.toLowerCase().contains(
                normalizedQuery,
              );
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            12.vGap,
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: context.color.borderColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    widget.title,
                    fontSize: context.font.extraLarge,
                    fontWeight: FontWeight.w700,
                  ),
                  14.vGap,
                  ServiceTextField(
                    controller: _searchController,
                    onChanged: _filterCities,
                    hintText: 'Search city',
                    textInputAction: TextInputAction.search,
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.color.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredCities.isEmpty
                  ? Center(
                      child: CustomText(
                        'No cities found.',
                        color: context.color.textLightColor,
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      itemCount: _filteredCities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        final selected = widget.selectedCity?.id == city.id;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(city),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? serviceAccentSurface(context)
                                  : serviceMutedSurface(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? context.color.territoryColor
                                    : serviceFieldBorder(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomText(
                                    city.name.localized,
                                    fontSize: context.font.large,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle,
                                    color: context.color.territoryColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
