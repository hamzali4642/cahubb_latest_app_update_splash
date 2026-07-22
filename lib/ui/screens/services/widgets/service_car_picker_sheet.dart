import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:flutter/material.dart';

/// Shared searchable car picker for all service request flows.
class ServiceCarPickerSheet extends StatefulWidget {
  const ServiceCarPickerSheet({
    required this.title,
    required this.cars,
    this.selectedCar,
    super.key,
  });

  final String title;
  final List<CarModelModel> cars;
  final CarModelModel? selectedCar;

  static Future<CarModelModel?> show({
    required BuildContext context,
    required List<CarModelModel> cars,
    CarModelModel? selectedCar,
    String title = 'Select car',
  }) {
    return showModalBottomSheet<CarModelModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceCarPickerSheet(
        title: title,
        cars: cars,
        selectedCar: selectedCar,
      ),
    );
  }

  @override
  State<ServiceCarPickerSheet> createState() => _ServiceCarPickerSheetState();
}

class _ServiceCarPickerSheetState extends State<ServiceCarPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<CarModelModel> _filteredCars;

  @override
  void initState() {
    super.initState();
    _filteredCars = widget.cars;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCars(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    setState(() {
      _filteredCars = normalizedQuery.isEmpty
          ? widget.cars
          : widget.cars.where((car) {
              return _carLabel(car).toLowerCase().contains(normalizedQuery);
            }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterCars('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.76,
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
                color: serviceUnselectedControlBorder(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            18.vGap,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    widget.title,
                    fontSize: context.font.extraLarge,
                    fontWeight: FontWeight.w700,
                  ),
                  14.vGap,
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _filterCars,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by make or model',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.color.textLightColor,
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: serviceUnselectedControlSurface(context),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: serviceUnselectedControlBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: serviceSelectionColor(context),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            12.vGap,
            Expanded(
              child: _filteredCars.isEmpty
                  ? Center(
                      child: CustomText(
                        'No cars found.',
                        color: context.color.textLightColor,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _filteredCars.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final car = _filteredCars[index];
                        final isSelected = widget.selectedCar?.id == car.id;
                        return _CarOption(
                          car: car,
                          isSelected: isSelected,
                          onTap: () => Navigator.of(context).pop(car),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _carLabel(CarModelModel car) {
    return '${car.brandName} ${car.name}'.trim();
  }
}

class _CarOption extends StatelessWidget {
  const _CarOption({
    required this.car,
    required this.isSelected,
    required this.onTap,
  });

  final CarModelModel car;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? serviceAccentSurface(context)
              : serviceMutedSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? serviceSelectionColor(context)
                : serviceUnselectedControlBorder(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                '${car.brandName} ${car.name}',
                fontSize: context.font.large,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: serviceSelectionColor(context),
              ),
          ],
        ),
      ),
    );
  }
}
