import 'package:eClassify/data/cubits/service/vehicle_service_request_cubit.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/ui/screens/services/widgets/service_form_fields.dart';
import 'package:eClassify/ui/screens/services/widgets/service_car_picker_sheet.dart';
import 'package:eClassify/ui/screens/services/service_booking_navigator.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VehicleServiceFlowConfig {
  final String serviceTitle;
  final String appBarTitle;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> heroHighlights;
  final String imageAssetPath;
  final String primaryActionLabel;
  final List<String> processSteps;
  final String requestRouteName;
  final String summaryHeadline;
  final String summaryInfoLabel;
  final String summaryNextStepsTitle;
  final List<String> summaryNextSteps;

  const VehicleServiceFlowConfig({
    required this.serviceTitle,
    required this.appBarTitle,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroHighlights,
    required this.imageAssetPath,
    required this.primaryActionLabel,
    required this.processSteps,
    required this.requestRouteName,
    required this.summaryHeadline,
    required this.summaryInfoLabel,
    required this.summaryNextStepsTitle,
    required this.summaryNextSteps,
  });
}

class VehicleServiceLandingScreen extends StatelessWidget {
  const VehicleServiceLandingScreen({required this.config, super.key});

  final VehicleServiceFlowConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: config.appBarTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VehicleServiceHero(config: config),
            18.vGap,
            UiUtils.buildButton(
              context,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  config.requestRouteName,
                  arguments: {'config': config},
                );
              },
              buttonTitle: config.primaryActionLabel,
              radius: 12,
              height: 52,
            ),
            24.vGap,
            CustomText(
              'How ${config.serviceTitle} works?',
              fontSize: context.font.extraLarge,
              fontWeight: FontWeight.w700,
            ),
            14.vGap,
            ...config.processSteps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ProcessStepTile(
                  index: entry.key + 1,
                  label: entry.value,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class VehicleServiceRequestScreen extends StatefulWidget {
  const VehicleServiceRequestScreen({required this.config, super.key});

  final VehicleServiceFlowConfig config;

  @override
  State<VehicleServiceRequestScreen> createState() =>
      _VehicleServiceRequestScreenState();
}

class _VehicleServiceRequestScreenState
    extends State<VehicleServiceRequestScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carVariantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<VehicleServiceRequestCubit>();
    _fullNameController.text = cubit.state.fullName;
    _phoneController.text = cubit.state.phoneNumber;
    _carVariantController.text = cubit.state.carVariant;

    _fullNameController.addListener(() {
      cubit.updateFullName(_fullNameController.text);
    });
    _phoneController.addListener(() {
      cubit.updatePhoneNumber(_phoneController.text);
    });
    _carVariantController.addListener(() {
      cubit.updateCarVariant(_carVariantController.text);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _carVariantController.dispose();
    super.dispose();
  }

  Future<void> _selectCar() async {
    final cubit = context.read<VehicleServiceRequestCubit>();
    final selectedCar = await ServiceCarPickerSheet.show(
      context: context,
      cars: cubit.state.carModels,
      selectedCar: cubit.state.selectedCar,
    );
    if (selectedCar != null) {
      cubit.selectCar(selectedCar);
    }
  }

  void _closeFlow() {
    Navigator.of(context).popUntil((route) {
      return route.settings.name == widget.config.requestRouteName ||
          route.isFirst;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VehicleServiceRequestCubit, VehicleServiceRequestState>(
      listenWhen: (previous, current) =>
          previous.feedbackToken != current.feedbackToken ||
          previous.submissionToken != current.submissionToken ||
          previous.fullName != current.fullName ||
          previous.phoneNumber != current.phoneNumber ||
          previous.carVariant != current.carVariant,
      listener: (context, state) {
        if (_fullNameController.text != state.fullName) {
          _fullNameController.value = _fullNameController.value.copyWith(
            text: state.fullName,
            selection: TextSelection.collapsed(offset: state.fullName.length),
            composing: TextRange.empty,
          );
        }
        if (_phoneController.text != state.phoneNumber) {
          _phoneController.value = _phoneController.value.copyWith(
            text: state.phoneNumber,
            selection: TextSelection.collapsed(
              offset: state.phoneNumber.length,
            ),
            composing: TextRange.empty,
          );
        }
        if (_carVariantController.text != state.carVariant) {
          _carVariantController.value = _carVariantController.value.copyWith(
            text: state.carVariant,
            selection: TextSelection.collapsed(offset: state.carVariant.length),
            composing: TextRange.empty,
          );
        }
        if (state.feedbackMessage != null) {
          HelperUtils.showSnackBarMessage(
            context,
            state.feedbackMessage!,
            type: MessageType.error,
          );
          context.read<VehicleServiceRequestCubit>().clearFeedback();
        }
        if (state.submissionResult != null && state.submissionToken > 0) {
          ServiceBookingNavigator.showSuccess(context, state.submissionResult!);
          return;
        }
      },
      builder: (context, state) {
        final isSummary = state.currentStepIndex == 2;

        return Scaffold(
          backgroundColor: context.color.primaryColor,
          body: SafeArea(
            child: Column(
              children: [
                _RequestHeader(
                  title: isSummary
                      ? 'Summary'
                      : state.currentStepIndex == 0
                      ? 'Basic info'
                      : 'Car Info',
                  headline: isSummary
                      ? widget.config.summaryHeadline
                      : state.currentStepIndex == 0
                      ? 'Basic info'
                      : 'Car Info',
                  currentStepIndex: state.currentStepIndex,
                  onBack: () {
                    if (state.currentStepIndex == 0) {
                      Navigator.of(context).pop();
                    } else {
                      context.read<VehicleServiceRequestCubit>().goBack();
                    }
                  },
                  onClose: isSummary
                      ? _closeFlow
                      : () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: context.color.secondaryColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                      child: switch (state.currentStepIndex) {
                        0 => _BasicInfoStep(
                          fullNameController: _fullNameController,
                          phoneController: _phoneController,
                          isFiler: state.isFiler,
                          onFilerChanged: (value) {
                            context
                                .read<VehicleServiceRequestCubit>()
                                .updateFiler(value);
                          },
                        ),
                        1 => _CarInfoStep(
                          carVariantController: _carVariantController,
                          request: state,
                          isLoadingCars: state.isLoadingCars,
                          modelYears: VehicleServiceRequestCubit.modelYears,
                          registrationPlaces:
                              VehicleServiceRequestCubit.registrationPlaces,
                          onCarSelected: _selectCar,
                          onModelYearSelected: (year) {
                            context
                                .read<VehicleServiceRequestCubit>()
                                .selectModelYear(year);
                          },
                          onRegistrationChanged: (place) {
                            context
                                .read<VehicleServiceRequestCubit>()
                                .updateRegistrationPlace(place);
                          },
                        ),
                        _ => _SummaryStep(
                          config: widget.config,
                          request: state,
                        ),
                      },
                    ),
                  ),
                ),
                if (!isSummary)
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
                                .read<VehicleServiceRequestCubit>()
                                .continueToCarInfo
                          : context.read<VehicleServiceRequestCubit>().submit,
                      buttonTitle: state.currentStepIndex == 0
                          ? 'Continue'
                          : 'Submit',
                      isInProgress: state.isSubmitting,
                      disabled: state.isSubmitting,
                      radius: 28,
                      height: 58,
                      buttonColor: serviceSelectionColor(context),
                      textColor: serviceSelectionForeground(context),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VehicleServiceHero extends StatelessWidget {
  const _VehicleServiceHero({required this.config});

  final VehicleServiceFlowConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: serviceHeroGradient(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  config.serviceTitle,
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w700,
                ),
                8.vGap,
                CustomText(
                  config.heroTitle,
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w600,
                ),
                8.vGap,
                CustomText(
                  config.heroSubtitle,
                  fontSize: context.font.normal,
                  color: context.color.textLightColor,
                  height: 1.45,
                ),
                16.vGap,
                ...config.heroHighlights.map((highlight) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HeroBullet(label: highlight),
                  );
                }),
              ],
            ),
          ),
          12.hGap,
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: serviceImageSurface(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(config.imageAssetPath, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _HeroBullet extends StatelessWidget {
  const _HeroBullet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: serviceAccentSurface(context),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 15,
            color: context.color.territoryColor,
          ),
        ),
        10.hGap,
        Expanded(
          child: CustomText(
            label,
            fontSize: context.font.normal,
            color: context.color.textDefaultColor,
          ),
        ),
      ],
    );
  }
}

class _ProcessStepTile extends StatelessWidget {
  const _ProcessStepTile({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: serviceAccentSurface(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Center(
            child: CustomText(
              '$index',
              fontWeight: FontWeight.w700,
              color: context.color.territoryColor,
            ),
          ),
        ),
        12.hGap,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CustomText(
              label,
              fontSize: context.font.large,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({
    required this.title,
    required this.headline,
    required this.currentStepIndex,
    required this.onBack,
    required this.onClose,
  });

  final String title;
  final String headline;
  final int currentStepIndex;
  final VoidCallback onBack;
  final VoidCallback onClose;

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
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: serviceMutedSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.color.borderColor),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: context.color.textDefaultColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          20.vGap,
          _FlowStepper(currentStepIndex: currentStepIndex),
          18.vGap,
          CustomText(
            headline,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: context.color.textDefaultColor,
          ),
        ],
      ),
    );
  }
}

class _FlowStepper extends StatelessWidget {
  const _FlowStepper({required this.currentStepIndex});

  final int currentStepIndex;

  @override
  Widget build(BuildContext context) {
    final isSummary = currentStepIndex == 2;
    final stepOneDone = currentStepIndex > 0;
    final stepTwoDone = isSummary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StepIndicator(
            label: 'Basic info',
            number: 1,
            isDone: stepOneDone,
            isCurrent: currentStepIndex == 0,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Container(
              height: 2,
              color: stepOneDone
                  ? serviceSelectionColor(context).withValues(alpha: 0.55)
                  : context.color.borderColor,
            ),
          ),
        ),
        Expanded(
          child: _StepIndicator(
            label: 'Car Info',
            number: 2,
            isDone: stepTwoDone,
            isCurrent: currentStepIndex == 1,
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.label,
    required this.number,
    required this.isDone,
    required this.isCurrent,
  });

  final String label;
  final int number;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isActive = isDone || isCurrent;
    final activeColor = serviceSelectionColor(context);

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : serviceUnselectedControlSurface(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? activeColor
                  : serviceUnselectedControlBorder(context),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? Icon(
                    Icons.check,
                    color: serviceSelectionForeground(context),
                    size: 18,
                  )
                : CustomText(
                    '$number',
                    color: isCurrent
                        ? serviceSelectionForeground(context)
                        : context.color.textLightColor,
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ),
        8.vGap,
        CustomText(
          label,
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

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({
    required this.fullNameController,
    required this.phoneController,
    required this.isFiler,
    required this.onFilerChanged,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final bool? isFiler;
  final ValueChanged<bool> onFilerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        CustomText(
          'Are you a filer?',
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
        12.vGap,
        Row(
          children: [
            _ChoiceChipButton(
              label: 'Yes',
              isSelected: isFiler == true,
              onTap: () => onFilerChanged(true),
            ),
            12.hGap,
            _ChoiceChipButton(
              label: 'No',
              isSelected: isFiler == false,
              onTap: () => onFilerChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _CarInfoStep extends StatelessWidget {
  const _CarInfoStep({
    required this.carVariantController,
    required this.request,
    required this.isLoadingCars,
    required this.modelYears,
    required this.registrationPlaces,
    required this.onCarSelected,
    required this.onModelYearSelected,
    required this.onRegistrationChanged,
  });

  final TextEditingController carVariantController;
  final VehicleServiceRequestState request;
  final bool isLoadingCars;
  final List<int> modelYears;
  final List<String> registrationPlaces;
  final VoidCallback onCarSelected;
  final ValueChanged<int> onModelYearSelected;
  final ValueChanged<String> onRegistrationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceSelectionField(
          title: 'Select car',
          value: request.selectedCar == null
              ? null
              : '${request.selectedCar!.brandName} ${request.selectedCar!.name}',
          hintText: isLoadingCars ? 'Loading cars...' : 'Choose car',
          onTap: isLoadingCars ? null : onCarSelected,
        ),
        if (request.selectedCar != null) ...[
          18.vGap,
          ServiceSelectionField(
            title: 'Model',
            value: request.selectedModelYear?.toString(),
            hintText: 'Select model year',
            onTap: () async {
              final selectedYear = await _showSelectionSheet<int>(
                context: context,
                title: 'Select model year',
                items: modelYears,
                labelBuilder: (year) => year.toString(),
              );
              if (selectedYear != null) {
                onModelYearSelected(selectedYear);
              }
            },
          ),
          18.vGap,
          ServiceTextField(
            title: 'Variant',
            controller: carVariantController,
            hintText: 'Enter variant',
            textInputAction: TextInputAction.done,
          ),
        ],
        18.vGap,
        CustomText(
          'Place of registration',
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
        12.vGap,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: registrationPlaces.map((place) {
            return _ChoiceChipButton(
              label: place,
              isSelected: request.registrationPlace == place,
              onTap: () => onRegistrationChanged(place),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.config, required this.request});

  final VehicleServiceFlowConfig config;
  final VehicleServiceRequestState request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request.submissionResult != null) ...[
          _SubmissionConfirmationCard(request: request),
          18.vGap,
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: serviceAccentSurface(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: context.color.territoryColor,
                    ),
                  ),
                  12.hGap,
                  Expanded(
                    child: CustomText(
                      config.summaryInfoLabel,
                      fontSize: context.font.larger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              16.vGap,
              _SummaryRow(
                label: 'Car information',
                value: request.selectedCar == null
                    ? '-'
                    : '${request.selectedCar!.brandName} ${request.selectedCar!.name}',
              ),
              12.vGap,
              _SummaryRow(
                label: 'Model',
                value: request.selectedModelYear?.toString() ?? '-',
              ),
              12.vGap,
              _SummaryRow(
                label: 'Variant',
                value: request.carVariant.isEmpty ? '-' : request.carVariant,
              ),
              12.vGap,
              _SummaryRow(
                label: 'Place of registration',
                value: request.registrationPlace,
              ),
              12.vGap,
              _SummaryRow(label: 'Your contact info', value: request.fullName),
              12.vGap,
              _SummaryRow(label: 'Phone number', value: request.phoneNumber),
            ],
          ),
        ),
        24.vGap,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: serviceAccentSurface(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.av_timer_rounded,
                      color: context.color.territoryColor,
                    ),
                  ),
                  12.hGap,
                  Expanded(
                    child: CustomText(
                      config.summaryNextStepsTitle,
                      fontSize: context.font.larger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              16.vGap,
              ...config.summaryNextSteps.map((step) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.color.textDefaultColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      10.hGap,
                      Expanded(
                        child: CustomText(
                          step,
                          fontSize: context.font.large,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        24.vGap,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: serviceHeroGradient(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'CA Hubb Car Insurance',
                      fontSize: context.font.extraLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    10.vGap,
                    CustomText(
                      'Drive with confidence with affordable insurance plans built for your next move.',
                      fontSize: context.font.normal,
                      color: context.color.textLightColor,
                      height: 1.45,
                    ),
                    14.vGap,
                    CustomText(
                      'I want to apply now',
                      fontSize: context.font.large,
                      fontWeight: FontWeight.w700,
                      color: context.color.territoryColor,
                    ),
                  ],
                ),
              ),
              14.hGap,
              SizedBox(
                width: 110,
                height: 90,
                child: Image.asset('assets/images/carRegistration.png'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmissionConfirmationCard extends StatelessWidget {
  const _SubmissionConfirmationCard({required this.request});

  final VehicleServiceRequestState request;

  @override
  Widget build(BuildContext context) {
    final result = request.submissionResult!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successMessageColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: successMessageColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: successMessageColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white),
          ),
          12.hGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  result.message,
                  fontSize: context.font.normal,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
                8.vGap,
                CustomText(
                  'Request #${result.id}  •  ${_formatStatus(result.status)}',
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatStatus(String status) {
    return status
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomText(
            label,
            fontSize: context.font.large,
            color: context.color.textLightColor,
          ),
        ),
        12.hGap,
        Expanded(
          child: CustomText(
            value,
            textAlign: TextAlign.end,
            fontSize: context.font.large,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
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
              ? serviceSelectionColor(context)
              : serviceUnselectedControlSurface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? serviceSelectionColor(context)
                : serviceUnselectedControlBorder(context),
            width: 1.2,
          ),
        ),
        child: CustomText(
          label,
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

Future<T?> _showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.color.secondaryColor,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                title,
                fontSize: sheetContext.font.extraLarge,
                fontWeight: FontWeight.w700,
              ),
              12.vGap,
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: sheetContext.color.borderColor, height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: CustomText(
                        labelBuilder(item),
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
