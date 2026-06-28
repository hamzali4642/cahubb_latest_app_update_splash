import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:eClassify/data/repositories/category_repository.dart';
import 'package:eClassify/data/repositories/location/location_repository.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class SellItForMeBookingScreen extends StatefulWidget {
  const SellItForMeBookingScreen({required this.package, super.key});

  final ServicePackageModel package;

  static Route route(RouteSettings settings) {
    final arguments = settings.arguments! as Map<String, dynamic>;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => SellItForMeBookingScreen(
        package: arguments['package'] as ServicePackageModel,
      ),
    );
  }

  @override
  State<SellItForMeBookingScreen> createState() =>
      _SellItForMeBookingScreenState();
}

class _SellItForMeBookingScreenState extends State<SellItForMeBookingScreen> {
  static const int _carsCategoryId = 130;
  static List<City> _cachedCities = const [];

  final CategoryRepository _categoryRepository = CategoryRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carVariantController = TextEditingController();
  final TextEditingController _visitAreaController = TextEditingController();

  final List<_InspectionStep> _steps = const [
    _InspectionStep(title: 'Basic info', headline: "Let's get you started"),
    _InspectionStep(title: 'Expert visit', headline: 'Book seller visit'),
  ];

  final List<_InspectionTimeSlot> _timeSlots = List.generate(7, (index) {
    final startHour = 10 + index;
    return _InspectionTimeSlot(
      startHour: startHour,
      label: '${_formatHour(startHour)} - ${_formatHour(startHour + 1)}',
    );
  });

  int _currentStepIndex = 0;
  bool _isUsedCar = true;
  bool _isLoadingCarBrands = true;
  bool _isLoadingCities = false;
  bool _isSubmitting = false;
  String? _citiesErrorMessage;

  CategoryModel? _selectedCarBrand;
  City? _selectedLivingCity;
  DateTime? _selectedVisitDate;
  _InspectionTimeSlot? _selectedTimeSlot;

  List<CategoryModel> _carBrands = const [];

  List<DateTime> get _nextSevenDates => List.generate(7, (index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + index);
  });

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _loadCarBrands();
    _loadCities();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _carModelController.dispose();
    _carVariantController.dispose();
    _visitAreaController.dispose();
    super.dispose();
  }

  void _prefillUserData() {
    if (!HiveUtils.isUserAuthenticated()) return;

    final user = HiveUtils.getUserDetails();
    _fullNameController.text = user.name ?? '';
    _phoneController.text = user.mobile ?? '';
  }

  Future<void> _loadCarBrands() async {
    setState(() {
      _isLoadingCarBrands = true;
    });

    try {
      final brands = await _fetchCarBrands();

      if (!mounted) return;
      setState(() {
        _carBrands = brands;
        _isLoadingCarBrands = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCarBrands = false;
      });
      HelperUtils.showSnackBarMessage(
        context,
        'Unable to load car brands right now.',
      );
    }
  }

  Future<List<CategoryModel>> _fetchCarBrands() async {
    final categories = <CategoryModel>[];
    var page = 1;
    var total = 1;

    while (categories.length < total) {
      final response = await _categoryRepository.fetchCategories(
        page: page,
        categoryId: _carsCategoryId,
        isForListing: true,
      );
      categories.addAll(response.modelList);

      total = response.total;
      page += 1;

      if (response.modelList.isEmpty) break;
    }

    categories.sort(
      (left, right) => (left.name ?? '').compareTo(right.name ?? ''),
    );
    return categories;
  }

  Future<void> _loadCities() async {
    if (_cachedCities.isNotEmpty) return;

    setState(() {
      _isLoadingCities = true;
      _citiesErrorMessage = null;
    });

    try {
      final cities = <City>[];
      var page = 1;
      var total = 1;

      while (cities.length < total) {
        final response = await _locationRepository.fetchCities(page: page);
        cities.addAll(response.modelList);
        total = response.total;
        page += 1;

        if (response.modelList.isEmpty) break;
      }

      cities.sort(
        (left, right) => left.name.localized.compareTo(right.name.localized),
      );
      _cachedCities = cities;

      if (!mounted) return;
      setState(() {
        _isLoadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCities = false;
        _citiesErrorMessage = 'Unable to load cities right now.';
      });
    }
  }

  Future<void> _selectCity() async {
    if (_cachedCities.isEmpty && _isLoadingCities) return;

    if (_cachedCities.isEmpty && _citiesErrorMessage != null) {
      HelperUtils.showSnackBarMessage(context, _citiesErrorMessage!);
      return;
    }

    final result = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CityPickerSheet(
          title: 'Select city',
          selectedCity: _selectedLivingCity,
          cities: _cachedCities,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedLivingCity = result;
    });
  }

  Future<void> _selectCarBrand() async {
    final brand = await _showCategoryPickerSheet(
      title: 'Select car brand',
      categories: _carBrands,
      selectedCategory: _selectedCarBrand,
    );

    if (brand == null || brand.id == _selectedCarBrand?.id) return;

    setState(() {
      _selectedCarBrand = brand;
      _carModelController.clear();
      _carVariantController.clear();
    });
  }

  Future<CategoryModel?> _showCategoryPickerSheet({
    required String title,
    required List<CategoryModel> categories,
    CategoryModel? selectedCategory,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryPickerSheet(
          title: title,
          categories: categories,
          selectedCategory: selectedCategory,
        );
      },
    );
  }

  bool _validateBasicInfo({bool showMessage = true}) {
    String? errorMessage;

    if (_fullNameController.text.trim().isEmpty) {
      errorMessage = 'Full name is required.';
    } else if (_phoneController.text.trim().isEmpty) {
      errorMessage = 'Phone number is required.';
    } else if (_selectedLivingCity == null) {
      errorMessage = 'Please select your city.';
    } else if (_selectedCarBrand == null) {
      errorMessage = 'Please select a car brand.';
    } else if (_carModelController.text.trim().isEmpty) {
      errorMessage = 'Please enter the car model.';
    } else if (_carVariantController.text.trim().isEmpty) {
      errorMessage = 'Please enter the car variant.';
    }

    if (errorMessage != null && showMessage) {
      HelperUtils.showSnackBarMessage(context, errorMessage);
    }

    return errorMessage == null;
  }

  bool _validateVisitInfo({bool showMessage = true}) {
    String? errorMessage;

    if (_visitAreaController.text.trim().isEmpty) {
      errorMessage = 'Please enter area.';
    } else if (_selectedVisitDate == null) {
      errorMessage = 'Please select a visit date.';
    } else if (_selectedTimeSlot == null) {
      errorMessage = 'Please select a time slot.';
    }

    if (errorMessage != null && showMessage) {
      HelperUtils.showSnackBarMessage(context, errorMessage);
    }

    return errorMessage == null;
  }

  void _continueToVisitStep() {
    if (!_validateBasicInfo()) return;

    setState(() {
      _currentStepIndex = 1;
    });
  }

  Future<void> _submit() async {
    if (!_validateBasicInfo() || !_validateVisitInfo()) return;

    setState(() {
      _isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    HelperUtils.showSnackBarMessage(
      context,
      'Sell it for me request validated. API will be connected next.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            _InspectionBookingHeader(
              title: _steps[_currentStepIndex].title,
              headline: _steps[_currentStepIndex].headline,
              steps: _steps,
              currentStepIndex: _currentStepIndex,
              onBack: () {
                if (_currentStepIndex == 0) {
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    _currentStepIndex = 0;
                  });
                }
              },
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: context.color.secondaryColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                  child: _currentStepIndex == 0
                      ? _InspectionBasicInfoStep(
                          package: widget.package,
                          fullNameController: _fullNameController,
                          phoneController: _phoneController,
                          carModelController: _carModelController,
                          carVariantController: _carVariantController,
                          selectedLivingCity: _selectedLivingCity,
                          selectedCarBrand: _selectedCarBrand,
                          isUsedCar: _isUsedCar,
                          isLoadingCarBrands: _isLoadingCarBrands,
                          onSelectLivingCity: () {
                            _selectCity();
                          },
                          onSelectCarBrand: _selectCarBrand,
                          onCarTypeChanged: (isUsed) {
                            setState(() {
                              _isUsedCar = isUsed;
                            });
                          },
                        )
                      : _InspectionVisitStep(
                          package: widget.package,
                          visitAreaController: _visitAreaController,
                          selectedVisitDate: _selectedVisitDate,
                          selectedTimeSlot: _selectedTimeSlot,
                          availableDates: _nextSevenDates,
                          timeSlots: _timeSlots,
                          onAreaChanged: () => setState(() {}),
                          onDateSelected: (date) {
                            setState(() {
                              _selectedVisitDate = date;
                              _selectedTimeSlot = null;
                            });
                          },
                          onTimeSlotSelected: (slot) {
                            setState(() {
                              _selectedTimeSlot = slot;
                            });
                          },
                        ),
                ),
              ),
            ),
            Container(
              color: context.color.secondaryColor,
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                MediaQuery.of(context).padding.bottom + 14,
              ),
              child: UiUtils.buildButton(
                context,
                onPressed: _currentStepIndex == 0
                    ? _continueToVisitStep
                    : _submit,
                buttonTitle: _currentStepIndex == 0 ? 'Continue' : 'Submit',
                isInProgress: _isSubmitting,
                disabled: _isSubmitting,
                radius: 28,
                height: 58,
                buttonColor: context.color.territoryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionBookingHeader extends StatelessWidget {
  const _InspectionBookingHeader({
    required this.title,
    required this.headline,
    required this.steps,
    required this.currentStepIndex,
    required this.onBack,
  });

  final String title;
  final String headline;
  final List<_InspectionStep> steps;
  final int currentStepIndex;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border(bottom: BorderSide(color: context.color.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.color.borderColor),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: context.color.textDefaultColor,
                    size: 20,
                  ),
                ),
              ),
              12.hGap,
              Expanded(
                child: CustomText(
                  title,
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w700,
                  color: context.color.textDefaultColor,
                ),
              ),
            ],
          ),
          20.vGap,
          CustomText(
            'Sell it for me service',
            fontSize: context.font.small,
            fontWeight: FontWeight.w700,
            color: context.color.territoryColor,
          ),
          10.vGap,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.color.primaryColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.color.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Sell it for me booking',
                  fontSize: context.font.small,
                  fontWeight: FontWeight.w700,
                  color: context.color.territoryColor,
                ),
                10.vGap,
                CustomText(
                  headline,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: context.color.textDefaultColor,
                ),
                8.vGap,
                CustomText(
                  currentStepIndex == 0
                      ? 'Share your basic details to start the selling request.'
                      : 'Choose the area, date, and preferred time slot for our team visit.',
                  fontSize: context.font.normal,
                  color: context.color.textLightColor,
                  height: 1.45,
                ),
                18.vGap,
                _InspectionProgressStepper(
                  steps: steps,
                  currentStepIndex: currentStepIndex,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionProgressStepper extends StatelessWidget {
  const _InspectionProgressStepper({
    required this.steps,
    required this.currentStepIndex,
  });

  final List<_InspectionStep> steps;
  final int currentStepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          return Expanded(
            child: _StepCircle(
              title: steps[stepIndex].title,
              index: stepIndex,
              isCompleted: stepIndex < currentStepIndex,
              isCurrent: stepIndex == currentStepIndex,
            ),
          );
        }

        final connectorIndex = index ~/ 2;
        final isCompleted = connectorIndex < currentStepIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              height: 2,
              color: isCompleted
                  ? context.color.territoryColor.withValues(alpha: 0.45)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.title,
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String title;
  final int index;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.color.territoryColor;
    final isActive = isCompleted || isCurrent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? accentColor : context.color.secondaryColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? accentColor : context.color.borderColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : CustomText(
                    '${index + 1}',
                    color: isCurrent
                        ? Colors.white
                        : context.color.textLightColor,
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ),
        8.vGap,
        CustomText(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          fontSize: context.font.small,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent
              ? context.color.textDefaultColor
              : context.color.textLightColor,
        ),
      ],
    );
  }
}

class _InspectionBasicInfoStep extends StatelessWidget {
  const _InspectionBasicInfoStep({
    required this.package,
    required this.fullNameController,
    required this.phoneController,
    required this.carModelController,
    required this.carVariantController,
    required this.selectedLivingCity,
    required this.selectedCarBrand,
    required this.isUsedCar,
    required this.isLoadingCarBrands,
    required this.onSelectLivingCity,
    required this.onSelectCarBrand,
    required this.onCarTypeChanged,
  });

  final ServicePackageModel package;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController carModelController;
  final TextEditingController carVariantController;
  final City? selectedLivingCity;
  final CategoryModel? selectedCarBrand;
  final bool isUsedCar;
  final bool isLoadingCarBrands;
  final VoidCallback onSelectLivingCity;
  final VoidCallback onSelectCarBrand;
  final ValueChanged<bool> onCarTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelectedPackageBanner(package: package),
        24.vGap,
        _InspectionTextField(
          title: 'Full name',
          controller: fullNameController,
          textInputAction: TextInputAction.next,
        ),
        18.vGap,
        _InspectionTextField(
          title: 'Phone number',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        18.vGap,
        _InspectionSelectionField(
          title: 'Where do you live?',
          value: selectedLivingCity?.name.localized,
          placeholder: 'Select city',
          onTap: onSelectLivingCity,
        ),
        18.vGap,
        _InspectionSelectionField(
          title: 'Tell us about your car',
          value: selectedCarBrand?.name,
          placeholder: isLoadingCarBrands
              ? 'Loading car brands...'
              : 'Select car brand',
          onTap: isLoadingCarBrands ? null : onSelectCarBrand,
          isLoading: isLoadingCarBrands,
        ),
        if (selectedCarBrand != null) ...[
          18.vGap,
          _InspectionTextField(
            title: 'Car model',
            controller: carModelController,
            textInputAction: TextInputAction.next,
          ),
          18.vGap,
          _InspectionTextField(
            title: 'Car variant',
            controller: carVariantController,
            textInputAction: TextInputAction.done,
          ),
        ],
        18.vGap,
        CustomText(
          'Choose Car Type',
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
        12.vGap,
        Row(
          children: [
            Expanded(
              child: _CarTypeChip(
                label: 'Used Car',
                isSelected: isUsedCar,
                onTap: () => onCarTypeChanged(true),
              ),
            ),
            12.hGap,
            Expanded(
              child: _CarTypeChip(
                label: 'New Car',
                isSelected: !isUsedCar,
                onTap: () => onCarTypeChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InspectionVisitStep extends StatelessWidget {
  const _InspectionVisitStep({
    required this.package,
    required this.visitAreaController,
    required this.selectedVisitDate,
    required this.selectedTimeSlot,
    required this.availableDates,
    required this.timeSlots,
    required this.onAreaChanged,
    required this.onDateSelected,
    required this.onTimeSlotSelected,
  });

  final ServicePackageModel package;
  final TextEditingController visitAreaController;
  final DateTime? selectedVisitDate;
  final _InspectionTimeSlot? selectedTimeSlot;
  final List<DateTime> availableDates;
  final List<_InspectionTimeSlot> timeSlots;
  final VoidCallback onAreaChanged;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<_InspectionTimeSlot> onTimeSlotSelected;

  @override
  Widget build(BuildContext context) {
    final showSlots = visitAreaController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelectedPackageBanner(package: package),
        24.vGap,
        _InspectionTextField(
          title: 'Area',
          controller: visitAreaController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onAreaChanged(),
        ),
        if (showSlots) ...[
          24.vGap,
          CustomText(
            'Select a date',
            fontSize: context.font.larger,
            fontWeight: FontWeight.w600,
          ),
          12.vGap,
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              separatorBuilder: (_, _) => 10.hGap,
              itemBuilder: (context, index) {
                final date = availableDates[index];
                return _DateSlotCard(
                  date: date,
                  isSelected: _isSameDay(selectedVisitDate, date),
                  onTap: () => onDateSelected(date),
                );
              },
            ),
          ),
          24.vGap,
          CustomText(
            'Select a time slot',
            fontSize: context.font.larger,
            fontWeight: FontWeight.w600,
          ),
          12.vGap,
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((slot) {
              return _TimeSlotChip(
                slot: slot,
                isSelected: selectedTimeSlot?.startHour == slot.startHour,
                onTap: () => onTimeSlotSelected(slot),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _SelectedPackageBanner extends StatelessWidget {
  const _SelectedPackageBanner({required this.package});

  final ServicePackageModel package;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified_outlined,
              color: context.color.territoryColor,
            ),
          ),
          12.hGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Selected package',
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
                4.vGap,
                CustomText(
                  package.name,
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionTextField extends StatelessWidget {
  const _InspectionTextField({
    required this.title,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  final String title;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
        10.vGap,
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: TextStyle(
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.color.secondaryColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.color.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.color.territoryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _InspectionSelectionField extends StatelessWidget {
  const _InspectionSelectionField({
    required this.title,
    required this.placeholder,
    this.value,
    this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String placeholder;
  final String? value;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final label = value?.isNotEmpty == true ? value! : placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
        10.vGap,
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: onTap == null
                  ? context.color.primaryColor
                  : context.color.secondaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.color.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    label,
                    fontSize: context.font.large,
                    color: value?.isNotEmpty == true
                        ? context.color.textDefaultColor
                        : context.color.textLightColor,
                  ),
                ),
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
                    Icons.keyboard_arrow_right,
                    color: context.color.textLightColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CarTypeChip extends StatelessWidget {
  const _CarTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEAF3FF)
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? context.color.territoryColor
                : context.color.borderColor,
          ),
        ),
        child: Center(
          child: CustomText(
            label,
            fontSize: context.font.large,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? context.color.territoryColor
                : context.color.textDefaultColor,
          ),
        ),
      ),
    );
  }
}

class _DateSlotCard extends StatelessWidget {
  const _DateSlotCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? context.color.territoryColor
              : const Color(0xFFF7F9FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? context.color.territoryColor
                : context.color.borderColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              _weekdayLabel(date),
              fontSize: context.font.small,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : context.color.textLightColor,
            ),
            8.vGap,
            CustomText(
              '${date.day}',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : context.color.textDefaultColor,
            ),
            4.vGap,
            CustomText(
              _monthLabel(date),
              fontSize: context.font.small,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: isSelected ? Colors.white : context.color.textLightColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final _InspectionTimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.color.territoryColor
              : const Color(0xFFF7F9FE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? context.color.territoryColor
                : context.color.borderColor,
          ),
        ),
        child: CustomText(
          slot.label,
          fontSize: context.font.normal,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : context.color.textDefaultColor,
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.title,
    required this.categories,
    required this.selectedCategory,
  });

  final String title;
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          18.vGap,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    title,
                    fontSize: context.font.extraLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          12.vGap,
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory?.id == category.id;

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(category);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEAF3FF)
                          : const Color(0xFFF7F9FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? context.color.territoryColor
                            : context.color.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            category.name ?? '',
                            fontSize: context.font.large,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isSelected)
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
    );
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.title,
    required this.cities,
    this.selectedCity,
  });

  final String title;
  final City? selectedCity;
  final List<City> cities;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<City> _filteredCities = const [];

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

  void _onSearchChanged(String value) {
    final normalizedQuery = value.trim().toLowerCase();
    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredCities = widget.cities;
        return;
      }

      _filteredCities = widget.cities.where((city) {
        final localizedName = city.name.localized.toLowerCase();
        return localizedName.contains(normalizedQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          18.vGap,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        fontSize: context.font.extraLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                14.vGap,
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search city',
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.color.textLightColor,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FE),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.color.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: context.color.territoryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          12.vGap,
          Expanded(
            child: Builder(
              builder: (context) {
                if (_filteredCities.isEmpty) {
                  return Center(
                    child: CustomText(
                      'No cities found.',
                      color: context.color.textLightColor,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  itemCount: _filteredCities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final city = _filteredCities[index];
                    final isSelected = widget.selectedCity?.id == city.id;

                    return InkWell(
                      onTap: () => Navigator.of(context).pop(city),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEAF3FF)
                              : const Color(0xFFF7F9FE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? context.color.territoryColor
                                : context.color.borderColor,
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
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: context.color.territoryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionStep {
  final String title;
  final String headline;

  const _InspectionStep({required this.title, required this.headline});
}

class _InspectionTimeSlot {
  final int startHour;
  final String label;

  const _InspectionTimeSlot({required this.startHour, required this.label});
}

String _weekdayLabel(DateTime date) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[date.weekday - 1];
}

String _monthLabel(DateTime date) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[date.month - 1];
}

bool _isSameDay(DateTime? left, DateTime right) {
  if (left == null) return false;
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _formatHour(int hour) {
  if (hour == 12) return '12 PM';
  if (hour == 24) return '12 AM';
  if (hour > 12) return '${hour - 12} PM';
  return '$hour AM';
}
