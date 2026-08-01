import 'package:eClassify/data/cubits/service/service_booking_form_cubit.dart';
import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/ui/screens/services/widgets/service_form_fields.dart';
import 'package:eClassify/ui/screens/services/widgets/service_car_picker_sheet.dart';
import 'package:eClassify/ui/screens/services/widgets/service_city_picker.dart';
import 'package:eClassify/ui/screens/services/service_booking_navigator.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SellItForMeBookingScreen extends StatefulWidget {
  const SellItForMeBookingScreen({
    required this.package,
    required this.showSelectedPackage,
    super.key,
  });

  final ServicePackageModel package;
  final bool showSelectedPackage;

  static Route route(RouteSettings settings) {
    final arguments = settings.arguments! as Map<String, dynamic>;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => BlocProvider(
        create: (_) => ServiceBookingFormCubit(
          package: arguments['package'] as ServicePackageModel,
          flowType: ServiceBookingFlowType.sellItForMe,
          showSelectedPackage:
              arguments['showSelectedPackage'] as bool? ?? true,
        )..initialize(),
        child: SellItForMeBookingScreen(
          package: arguments['package'] as ServicePackageModel,
          showSelectedPackage:
              arguments['showSelectedPackage'] as bool? ?? true,
        ),
      ),
    );
  }

  @override
  State<SellItForMeBookingScreen> createState() =>
      _SellItForMeBookingScreenState();
}

class _SellItForMeBookingScreenState extends State<SellItForMeBookingScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carVariantController = TextEditingController();
  final TextEditingController _visitAreaController = TextEditingController();

  final List<_InspectionStep> _steps = const [
    _InspectionStep(title: 'Basic info', headline: "Let's get you started"),
    _InspectionStep(title: 'Expert visit', headline: 'Book seller visit'),
  ];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ServiceBookingFormCubit>();
    _fullNameController.text = cubit.state.fullName;
    _phoneController.text = cubit.state.phoneNumber;
    _carVariantController.text = cubit.state.carVariant;
    _visitAreaController.text = cubit.state.visitArea;

    _fullNameController.addListener(() {
      cubit.updateFullName(_fullNameController.text);
    });
    _phoneController.addListener(() {
      cubit.updatePhoneNumber(_phoneController.text);
    });
    _carVariantController.addListener(() {
      cubit.updateCarVariant(_carVariantController.text);
    });
    _visitAreaController.addListener(() {
      cubit.updateVisitArea(_visitAreaController.text);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _carVariantController.dispose();
    _visitAreaController.dispose();
    super.dispose();
  }

  Future<void> _selectCity() async {
    final cubit = context.read<ServiceBookingFormCubit>();
    final state = cubit.state;

    if (state.cities.isEmpty && state.isLoadingCities) return;

    if (state.cities.isEmpty && state.citiesErrorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.citiesErrorMessage!)));
      return;
    }

    final result = await ServiceCityPicker.show(
      context: context,
      selectedCity: state.selectedLivingCity,
      cities: state.cities,
    );

    if (result == null) return;
    cubit.selectLivingCity(result);
  }

  Future<void> _selectCar() async {
    final cubit = context.read<ServiceBookingFormCubit>();
    final state = cubit.state;
    final car = await ServiceCarPickerSheet.show(
      context: context,
      cars: state.carModels,
      selectedCar: state.selectedCar,
    );

    if (car == null) return;
    cubit.selectCar(car);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceBookingFormCubit, ServiceBookingFormState>(
      listenWhen: (previous, current) =>
          previous.feedbackToken != current.feedbackToken ||
          previous.submissionToken != current.submissionToken ||
          previous.fullName != current.fullName ||
          previous.phoneNumber != current.phoneNumber ||
          previous.carVariant != current.carVariant ||
          previous.visitArea != current.visitArea,
      listener: (context, state) {
        _syncController(_fullNameController, state.fullName);
        _syncController(_phoneController, state.phoneNumber);
        _syncController(_carVariantController, state.carVariant);
        _syncController(_visitAreaController, state.visitArea);

        if (state.submissionResult != null && state.submissionToken > 0) {
          ServiceBookingNavigator.showSuccess(context, state.submissionResult!);
          return;
        }

        if (state.feedbackMessage == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.feedbackMessage!)));
        context.read<ServiceBookingFormCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.color.primaryColor,
          body: SafeArea(
            child: Column(
              children: [
                _InspectionBookingHeader(
                  title: _steps[state.currentStepIndex].title,
                  headline: _steps[state.currentStepIndex].headline,
                  steps: _steps,
                  currentStepIndex: state.currentStepIndex,
                  onBack: () {
                    if (state.currentStepIndex == 0) {
                      Navigator.of(context).pop();
                    } else {
                      context.read<ServiceBookingFormCubit>().goBackStep();
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: context.color.secondaryColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                      child: state.currentStepIndex == 0
                          ? _InspectionBasicInfoStep(
                              package: widget.package,
                              showSelectedPackage: widget.showSelectedPackage,
                              fullNameController: _fullNameController,
                              phoneController: _phoneController,
                              carVariantController: _carVariantController,
                              selectedLivingCity: state.selectedLivingCity,
                              selectedCar: state.selectedCar,
                              selectedModelYear: state.selectedModelYear,
                              isUsedCar: state.isUsedCar,
                              isLoadingCars: state.isLoadingCars,
                              registrationAreas:
                                  ServiceBookingFormCubit.registrationAreas,
                              selectedRegistrationArea:
                                  state.selectedRegistrationArea,
                              onSelectLivingCity: _selectCity,
                              onSelectCar: _selectCar,
                              onSelectModelYear: (year) {
                                context
                                    .read<ServiceBookingFormCubit>()
                                    .selectModelYear(year);
                              },
                              onCarTypeChanged: (isUsed) {
                                context
                                    .read<ServiceBookingFormCubit>()
                                    .updateCarType(isUsed);
                              },
                              onRegistrationAreaChanged: (area) {
                                context
                                    .read<ServiceBookingFormCubit>()
                                    .selectRegistrationArea(area);
                              },
                            )
                          : _InspectionVisitStep(
                              package: widget.package,
                              showSelectedPackage: widget.showSelectedPackage,
                              visitAreaController: _visitAreaController,
                              selectedVisitDate: state.selectedVisitDate,
                              selectedTimeSlot: state.selectedTimeSlot,
                              availableDates: state.availableDates,
                              timeSlots: state.timeSlots,
                              onAreaChanged: () {},
                              onDateSelected: (date) {
                                context
                                    .read<ServiceBookingFormCubit>()
                                    .selectVisitDate(date);
                              },
                              onTimeSlotSelected: (slot) {
                                context
                                    .read<ServiceBookingFormCubit>()
                                    .selectTimeSlot(slot);
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
                    onPressed: state.currentStepIndex == 0
                        ? context
                              .read<ServiceBookingFormCubit>()
                              .continueToVisitStep
                        : context.read<ServiceBookingFormCubit>().submit,
                    buttonTitle: state.currentStepIndex == 0
                        ? 'Continue'
                        : 'Submit',
                    isInProgress: state.isSubmitting,
                    disabled: state.isSubmitting,
                    radius: 28,
                    height: 58,
                    buttonColor: context.color.territoryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
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
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: serviceMutedSurface(context),
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
          8.vGap,
          CustomText(
            'Sell it for me service',
            fontSize: context.font.small,
            fontWeight: FontWeight.w700,
            color: context.color.territoryColor,
          ),
          6.vGap,
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.color.primaryColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.color.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  headline,
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w800,
                  color: context.color.textDefaultColor,
                ),
                4.vGap,
                CustomText(
                  currentStepIndex == 0
                      ? 'Share your basic details to start the selling request.'
                      : 'Choose the area, date, and preferred time slot for our team visit.',
                  fontSize: context.font.normal,
                  color: context.color.textLightColor,
                  height: 1.25,
                ),
                10.vGap,
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
                  ? serviceSelectionColor(context).withValues(alpha: 0.55)
                  : context.color.borderColor,
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
    final accentColor = serviceSelectionColor(context);
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
                ? Icon(
                    Icons.check,
                    color: serviceSelectionForeground(context),
                    size: 18,
                  )
                : CustomText(
                    '${index + 1}',
                    color: isCurrent
                        ? serviceSelectionForeground(context)
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
    required this.showSelectedPackage,
    required this.fullNameController,
    required this.phoneController,
    required this.carVariantController,
    required this.selectedLivingCity,
    required this.selectedCar,
    required this.selectedModelYear,
    required this.isUsedCar,
    required this.isLoadingCars,
    required this.registrationAreas,
    required this.selectedRegistrationArea,
    required this.onSelectLivingCity,
    required this.onSelectCar,
    required this.onSelectModelYear,
    required this.onCarTypeChanged,
    required this.onRegistrationAreaChanged,
  });

  final ServicePackageModel package;
  final bool showSelectedPackage;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController carVariantController;
  final City? selectedLivingCity;
  final CarModelModel? selectedCar;
  final int? selectedModelYear;
  final bool isUsedCar;
  final bool isLoadingCars;
  final List<String> registrationAreas;
  final String? selectedRegistrationArea;
  final VoidCallback onSelectLivingCity;
  final VoidCallback onSelectCar;
  final ValueChanged<int> onSelectModelYear;
  final ValueChanged<bool> onCarTypeChanged;
  final ValueChanged<String> onRegistrationAreaChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSelectedPackage) ...[
          _SelectedPackageBanner(package: package),
          24.vGap,
        ],
        ServiceTextField(
          title: 'Full name',
          controller: fullNameController,
          textInputAction: TextInputAction.next,
        ),
        18.vGap,
        PakistanPhoneField(
          controller: phoneController,
          textInputAction: TextInputAction.next,
        ),
        18.vGap,
        ServiceSelectionField(
          title: 'Where do you live?',
          value: selectedLivingCity?.name.localized,
          hintText: 'Select city',
          onTap: onSelectLivingCity,
        ),
        18.vGap,
        ServiceSelectionField(
          title: 'Tell us about your car',
          value: selectedCar == null
              ? null
              : '${selectedCar!.brandName} ${selectedCar!.name}',
          hintText: isLoadingCars ? 'Loading cars...' : 'Select car',
          onTap: isLoadingCars ? null : onSelectCar,
          isLoading: isLoadingCars,
        ),
        if (selectedCar != null) ...[
          18.vGap,
          ServiceSelectionField(
            title: 'Model',
            value: selectedModelYear?.toString(),
            hintText: 'Select model year',
            onTap: () async {
              final year = await _showYearPickerSheet(
                context,
                selectedModelYear,
              );
              if (year != null) onSelectModelYear(year);
            },
          ),
          18.vGap,
          ServiceTextField(
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
        18.vGap,
        CustomText(
          'Which area your vehicle registered in',
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
        12.vGap,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: registrationAreas.map((area) {
            return _RegistrationAreaChip(
              label: area,
              isSelected: selectedRegistrationArea == area,
              onTap: () => onRegistrationAreaChanged(area),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InspectionVisitStep extends StatelessWidget {
  const _InspectionVisitStep({
    required this.package,
    required this.showSelectedPackage,
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
  final bool showSelectedPackage;
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
        if (showSelectedPackage) ...[
          _SelectedPackageBanner(package: package),
          24.vGap,
        ],
        ServiceTextField(
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
        color: serviceMutedSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: serviceAccentSurface(context),
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
              ? serviceAccentSurface(context)
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

class _RegistrationAreaChip extends StatelessWidget {
  const _RegistrationAreaChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? serviceAccentSurface(context)
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? context.color.territoryColor
                : context.color.borderColor,
          ),
        ),
        child: CustomText(
          label,
          fontSize: context.font.normal,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? serviceSelectionColor(context)
              : context.color.textDefaultColor,
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
              ? serviceSelectionColor(context)
              : serviceMutedSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? serviceSelectionColor(context)
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
              color: isSelected
                  ? serviceSelectionForeground(context)
                  : context.color.textLightColor,
            ),
            8.vGap,
            CustomText(
              '${date.day}',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? serviceSelectionForeground(context)
                  : context.color.textDefaultColor,
            ),
            4.vGap,
            CustomText(
              _monthLabel(date),
              fontSize: context.font.small,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              color: isSelected
                  ? serviceSelectionForeground(context)
                  : context.color.textLightColor,
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
              ? serviceSelectionColor(context)
              : serviceMutedSurface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? serviceSelectionColor(context)
                : context.color.borderColor,
          ),
        ),
        child: CustomText(
          slot.label,
          fontSize: context.font.normal,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? serviceSelectionForeground(context)
              : context.color.textDefaultColor,
        ),
      ),
    );
  }
}

Future<int?> _showYearPickerSheet(BuildContext context, int? selectedYear) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _YearPickerSheet(selectedYear: selectedYear),
  );
}

class _YearPickerSheet extends StatelessWidget {
  const _YearPickerSheet({required this.selectedYear});

  final int? selectedYear;

  @override
  Widget build(BuildContext context) {
    final years = ServiceBookingFormCubit.modelYears;
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
                    'Select model year',
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
              itemCount: years.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = selectedYear == year;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(year),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? serviceAccentSurface(context)
                          : serviceMutedSurface(context),
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
                            '$year',
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

class _InspectionStep {
  final String title;
  final String headline;

  const _InspectionStep({required this.title, required this.headline});
}

typedef _InspectionTimeSlot = ServiceBookingTimeSlot;

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
