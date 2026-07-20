import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/service/car_finance_cubit.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/masked_text_controller.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Collects the contact and eligibility details required by the finance API.
///
/// The calculator owns the selected vehicle and finance plan; this screen only
/// updates the applicant portion of [CarFinanceState].
class CarFinanceApplicantScreen extends StatefulWidget {
  const CarFinanceApplicantScreen({super.key});

  @override
  State<CarFinanceApplicantScreen> createState() =>
      _CarFinanceApplicantScreenState();
}

class _CarFinanceApplicantScreenState extends State<CarFinanceApplicantScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final MaskedTextController _cnicController;
  late final TextEditingController _bankController;

  @override
  void initState() {
    super.initState();
    final applicant = context.read<CarFinanceCubit>().state.applicant;
    _nameController = TextEditingController(text: applicant.fullName);
    _phoneController = TextEditingController(text: applicant.phoneNumber);
    _emailController = TextEditingController(text: applicant.email);
    _cnicController = MaskedTextController(
      mask: MaskedTextController.cnicMask,
      text: applicant.cnic,
    );
    _bankController = TextEditingController(text: applicant.currentBank);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _syncControllers(CarFinanceState state) {
    _syncController(_nameController, state.applicant.fullName);
    _syncController(_phoneController, state.applicant.phoneNumber);
    _syncController(_emailController, state.applicant.email);
    _syncController(_cnicController, state.applicant.cnic);
    _syncController(_bankController, state.applicant.currentBank);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  bool _canSubmit(CarFinanceState state) {
    final applicant = state.applicant;
    return applicant.fullName.trim().isNotEmpty &&
        applicant.phoneNumber.trim().isNotEmpty &&
        applicant.email.trim().isNotEmpty &&
        applicant.cnic.trim().isNotEmpty &&
        state.request.city != null &&
        applicant.incomeSource != null &&
        applicant.monthlyIncome != null &&
        applicant.currentBank.trim().isNotEmpty &&
        applicant.hasCreditCardsOrLoans != null &&
        applicant.processingTime != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarFinanceCubit, CarFinanceState>(
      listenWhen: (previous, current) =>
          previous.feedbackToken != current.feedbackToken ||
          previous.loginRequiredToken != current.loginRequiredToken ||
          previous.submissionToken != current.submissionToken ||
          previous.applicant != current.applicant,
      listener: (context, state) {
        _syncControllers(state);
        final cubit = context.read<CarFinanceCubit>();
        if (state.feedbackMessage != null) {
          HelperUtils.showSnackBarMessage(
            context,
            state.feedbackMessage!,
            type: MessageType.error,
          );
          cubit.clearFeedback();
        }
        if (state.loginRequiredToken > 0) {
          cubit.clearLoginRequest();
          Navigator.of(context).pushNamed(Routes.login);
        }
        if (state.submissionResult != null && state.submissionToken > 0) {
          HelperUtils.showSnackBarMessage(
            context,
            state.submissionResult!.message,
            messageDuration: 4,
            type: MessageType.success,
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final cubit = context.read<CarFinanceCubit>();
        return Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: 'Car Finance',
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  child: Column(
                    children: [
                      _ApplicantHero(),
                      16.vGap,
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                        decoration: BoxDecoration(
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ApplicantTextField(
                              label: 'Name',
                              icon: Icons.person_outline,
                              controller: _nameController,
                              hintText: 'Enter your name',
                              textCapitalization: TextCapitalization.words,
                              onChanged: cubit.updateApplicantFullName,
                            ),
                            18.vGap,
                            _ApplicantTextField(
                              label: 'Phone number',
                              icon: Icons.phone_outlined,
                              controller: _phoneController,
                              hintText: '03XX-XXXXXXX',
                              keyboardType: TextInputType.phone,
                              onChanged: cubit.updateApplicantPhoneNumber,
                            ),
                            18.vGap,
                            _ApplicantTextField(
                              label: 'Email address',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              hintText: 'Enter email',
                              keyboardType: TextInputType.emailAddress,
                              onChanged: cubit.updateApplicantEmail,
                            ),
                            18.vGap,
                            _ApplicantTextField(
                              label: 'CNIC number',
                              icon: Icons.badge_outlined,
                              controller: _cnicController,
                              hintText: 'XXXXX-XXXXXXX-X',
                              keyboardType: TextInputType.number,
                              onChanged: cubit.updateApplicantCnic,
                            ),
                            18.vGap,
                            _ApplicantSelectorField(
                              label: 'Where do you live?',
                              icon: Icons.location_on_outlined,
                              value: state.request.city?.name.localized,
                              hintText: state.isLoadingCities
                                  ? 'Loading cities...'
                                  : 'Select city',
                              onTap: state.isLoadingCities
                                  ? null
                                  : () async {
                                      final city = await _showApplicantChoices(
                                        context: context,
                                        title: 'Select city',
                                        items: state.cities,
                                        labelBuilder: (city) =>
                                            city.name.localized,
                                      );
                                      if (city != null) cubit.updateCity(city);
                                    },
                            ),
                            18.vGap,
                            _ApplicantLabel(
                              label: 'What is your source of income?',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            10.vGap,
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _ApplicantChoicePill(
                                  label: 'Salaried',
                                  selected:
                                      state.applicant.incomeSource ==
                                      'salaried',
                                  onTap: () => cubit
                                      .updateApplicantIncomeSource('salaried'),
                                ),
                                _ApplicantChoicePill(
                                  label: 'Self-employed',
                                  selected:
                                      state.applicant.incomeSource ==
                                      'self_employed',
                                  onTap: () =>
                                      cubit.updateApplicantIncomeSource(
                                        'self_employed',
                                      ),
                                ),
                              ],
                            ),
                            18.vGap,
                            _ApplicantSelectorField(
                              label: 'What is your monthly income?',
                              icon: Icons.payments_outlined,
                              value: _monthlyIncomeLabel(
                                state.applicant.monthlyIncome,
                              ),
                              hintText: 'Select monthly income',
                              onTap: () async {
                                final value = await _showApplicantChoices(
                                  context: context,
                                  title: 'Select Monthly Income',
                                  items: const ['above_80000'],
                                  labelBuilder: (income) =>
                                      _monthlyIncomeLabel(income) ?? '',
                                );
                                if (value != null) {
                                  cubit.updateApplicantMonthlyIncome(value);
                                }
                              },
                            ),
                            18.vGap,
                            _ApplicantTextField(
                              label: 'Where do you bank?',
                              icon: Icons.account_balance_outlined,
                              controller: _bankController,
                              hintText: 'Your current bank',
                              textCapitalization: TextCapitalization.words,
                              onChanged: cubit.updateApplicantCurrentBank,
                            ),
                            18.vGap,
                            _ApplicantLabel(
                              label: 'Do you have any credit cards or loans?',
                              icon: Icons.credit_card_outlined,
                            ),
                            10.vGap,
                            Wrap(
                              spacing: 10,
                              children: [
                                _ApplicantChoicePill(
                                  label: 'Yes',
                                  selected:
                                      state.applicant.hasCreditCardsOrLoans ==
                                      true,
                                  onTap: () =>
                                      cubit.updateApplicantCreditStatus(true),
                                ),
                                _ApplicantChoicePill(
                                  label: 'No',
                                  selected:
                                      state.applicant.hasCreditCardsOrLoans ==
                                      false,
                                  onTap: () =>
                                      cubit.updateApplicantCreditStatus(false),
                                ),
                              ],
                            ),
                            18.vGap,
                            _ApplicantSelectorField(
                              label: 'How soon do you want the loan?',
                              icon: Icons.calendar_month_outlined,
                              value: _processingTimeLabel(
                                state.applicant.processingTime,
                              ),
                              hintText: 'Please select processing time',
                              onTap: () async {
                                final value = await _showApplicantChoices(
                                  context: context,
                                  title: 'Please Select Processing Time',
                                  items: const [
                                    'next_2_weeks',
                                    'next_month',
                                    'just_information',
                                  ],
                                  labelBuilder: (processingTime) =>
                                      _processingTimeLabel(processingTime) ??
                                      '',
                                );
                                if (value != null) {
                                  cubit.updateApplicantProcessingTime(value);
                                }
                              },
                            ),
                            22.vGap,
                            Text(
                              'By submitting your details, you authorize CA Hubb to share your contact information with our partner banks to get in touch with you through email, phone or SMS.',
                              style: TextStyle(
                                color: context.color.textLightColor,
                                height: 1.4,
                                fontSize: context.font.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  color: context.color.secondaryColor,
                  child: UiUtils.buildButton(
                    context,
                    onPressed: cubit.submitApplication,
                    buttonTitle: 'Submit',
                    isInProgress: state.isSubmitting,
                    disabled: !_canSubmit(state) || state.isSubmitting,
                    radius: 16,
                    height: 54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApplicantHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        gradient: serviceHeroGradient(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Apply Now',
        style: TextStyle(
          color: context.color.textDefaultColor,
          fontSize: context.font.extraLarge * 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ApplicantTextField extends StatelessWidget {
  const _ApplicantTextField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ApplicantLabel(label: label, icon: icon),
        9.vGap,
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          decoration: _fieldDecoration(context, hintText),
        ),
      ],
    );
  }
}

class _ApplicantSelectorField extends StatelessWidget {
  const _ApplicantSelectorField({
    required this.label,
    required this.icon,
    required this.value,
    required this.hintText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? value;
  final String hintText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayText = value ?? hintText;
    final isPlaceholder = value == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ApplicantLabel(label: label, icon: icon),
        9.vGap,
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: serviceMutedSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.color.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: context.font.normal,
                        color: isPlaceholder
                            ? context.color.textLightColor
                            : context.color.textDefaultColor,
                      ),
                    ),
                  ),
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

class _ApplicantLabel extends StatelessWidget {
  const _ApplicantLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.color.textLightColor),
        9.hGap,
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.color.textDefaultColor,
              fontSize: context.font.large,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicantChoicePill extends StatelessWidget {
  const _ApplicantChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: serviceAccentSurface(context),
      side: BorderSide(
        color: selected
            ? context.color.territoryColor
            : context.color.borderColor,
      ),
      labelStyle: TextStyle(
        color: selected
            ? context.color.territoryColor
            : context.color.textDefaultColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: context.color.textLightColor),
    filled: true,
    fillColor: serviceMutedSurface(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.color.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.color.territoryColor, width: 1.4),
    ),
  );
}

Future<T?> _showApplicantChoices<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.color.secondaryColor,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: sheetContext.color.textDefaultColor,
                fontSize: sheetContext.font.extraLarge,
                fontWeight: FontWeight.w700,
              ),
            ),
            14.vGap,
            ...items.map(
              (item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: serviceMutedSurface(sheetContext),
                title: Text(
                  labelBuilder(item),
                  style: TextStyle(
                    color: sheetContext.color.textDefaultColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(item),
              ),
            ),
          ].expand((widget) => [widget, 8.vGap]).toList()..removeLast(),
        ),
      ),
    ),
  );
}

String? _monthlyIncomeLabel(String? value) {
  return switch (value) {
    'above_80000' => 'Above 80,000',
    _ => null,
  };
}

String? _processingTimeLabel(String? value) {
  return switch (value) {
    'next_2_weeks' => 'Next 2 weeks',
    'next_month' => 'Next month',
    'just_information' => 'Just looking for information',
    _ => null,
  };
}
