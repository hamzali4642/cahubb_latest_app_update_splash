import 'package:eClassify/data/cubits/service/car_finance_cubit.dart';
import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/ui/screens/services/car_finance_applicant_screen.dart';
import 'package:eClassify/ui/screens/services/widgets/service_form_fields.dart';
import 'package:eClassify/ui/screens/services/widgets/service_city_picker.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CarFinanceLandingScreen extends StatelessWidget {
  const CarFinanceLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarFinanceCubit, CarFinanceState>(
      listenWhen: (previous, current) =>
          previous.feedbackToken != current.feedbackToken,
      listener: (context, state) {
        if (state.feedbackMessage == null) return;
        HelperUtils.showSnackBarMessage(
          context,
          state.feedbackMessage!,
          type: MessageType.error,
        );
        context.read<CarFinanceCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: 'Car Finance',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CarFinanceHero(),
                18.vGap,
                UiUtils.buildButton(
                  context,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<CarFinanceCubit>(),
                          child: const CarFinanceCalculatorScreen(),
                        ),
                      ),
                    );
                  },
                  buttonTitle: 'Apply Easily Now',
                  disabled: state.isLoadingBanks || state.banks.isEmpty,
                  radius: 12,
                  height: 52,
                ),
                24.vGap,
                CustomText(
                  'Best car financing banks and rates in Pakistan',
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w700,
                ),
                14.vGap,
                if (state.isLoadingBanks)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.banks.isEmpty)
                  _FinanceBanksUnavailable(
                    message:
                        state.banksErrorMessage ??
                        'Finance plans are unavailable right now.',
                    onRetry: () => context.read<CarFinanceCubit>().loadBanks(),
                  )
                else
                  _BankRatesTable(banks: state.banks),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CarFinanceCalculatorScreen extends StatefulWidget {
  const CarFinanceCalculatorScreen({super.key});

  @override
  State<CarFinanceCalculatorScreen> createState() =>
      _CarFinanceCalculatorScreenState();
}

class _CarFinanceCalculatorScreenState
    extends State<CarFinanceCalculatorScreen> {
  final TextEditingController _usedCarPriceController = TextEditingController();
  final TextEditingController _carVariantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CarFinanceCubit>().state;
    _usedCarPriceController.text = state.request.usedCarPrice == null
        ? ''
        : _formatPlainNumber(state.request.usedCarPrice!);
    _carVariantController.text = state.request.carVariant;
    _usedCarPriceController.addListener(() {
      context.read<CarFinanceCubit>().updateUsedCarPrice(
        _usedCarPriceController.text,
      );
    });
    _carVariantController.addListener(() {
      context.read<CarFinanceCubit>().updateCarVariant(
        _carVariantController.text,
      );
    });
  }

  @override
  void dispose() {
    _usedCarPriceController.dispose();
    _carVariantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarFinanceCubit, CarFinanceState>(
      listenWhen: (previous, current) =>
          previous.feedbackToken != current.feedbackToken ||
          previous.request.usedCarPrice != current.request.usedCarPrice ||
          previous.request.carVariant != current.request.carVariant,
      listener: (context, state) {
        final normalized = state.request.usedCarPrice == null
            ? ''
            : _formatPlainNumber(state.request.usedCarPrice!);
        if (_usedCarPriceController.text != normalized) {
          _usedCarPriceController.value = _usedCarPriceController.value
              .copyWith(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length),
                composing: TextRange.empty,
              );
        }
        if (_carVariantController.text != state.request.carVariant) {
          _carVariantController.value = _carVariantController.value.copyWith(
            text: state.request.carVariant,
            selection: TextSelection.collapsed(
              offset: state.request.carVariant.length,
            ),
            composing: TextRange.empty,
          );
        }
        if (state.feedbackMessage == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.feedbackMessage!)));
        context.read<CarFinanceCubit>().clearFeedback();
      },
      builder: (context, state) {
        final cubit = context.read<CarFinanceCubit>();
        final isUsedCar = state.request.financeType == CarFinanceType.usedCar;

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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Car loan calculator',
                        fontSize: context.font.extraLarge,
                        fontWeight: FontWeight.w700,
                      ),
                      18.vGap,
                      _FinanceTypeTabs(
                        selectedType: state.request.financeType,
                        onChanged: cubit.updateType,
                      ),
                      22.vGap,
                      ServiceSelectionField(
                        title: 'City',
                        value: state.request.city?.name.localized,
                        hintText: state.isLoadingCities
                            ? 'Loading cities...'
                            : 'Select city',
                        icon: Icons.location_on_outlined,
                        onTap: state.isLoadingCities
                            ? null
                            : () async {
                                final selectedCity =
                                    await ServiceCityPicker.show(
                                      context: context,
                                      cities: state.cities,
                                      selectedCity: state.request.city,
                                    );
                                if (selectedCity != null) {
                                  cubit.updateCity(selectedCity);
                                }
                              },
                      ),
                      18.vGap,
                      ServiceSelectionField(
                        title: 'Car Details',
                        value: state.request.selectedCar == null
                            ? null
                            : '${state.request.selectedCar!.brandName} ${state.request.selectedCar!.name}',
                        hintText: state.isLoadingCars
                            ? 'Loading cars...'
                            : 'Make/model/version',
                        icon: Icons.directions_car_outlined,
                        onTap: state.isLoadingCars
                            ? null
                            : () async {
                                final selectedCar =
                                    await _showSelectionSheet<CarModelModel>(
                                      context: context,
                                      title: 'Select car details',
                                      items: state.carModels,
                                      labelBuilder: (car) =>
                                          '${car.brandName} ${car.name}',
                                      trailingBuilder: (car) => CustomText(
                                        _carSelectionPriceLabel(
                                          car: car,
                                          isUsedCar: isUsedCar,
                                          fallbackPrice:
                                              state.newCarFallbackPrice,
                                        ),
                                        fontSize: context.font.small,
                                        color: context.color.textLightColor,
                                      ),
                                    );
                                if (selectedCar != null) {
                                  cubit.updateCar(selectedCar);
                                }
                              },
                      ),
                      if (isUsedCar) ...[
                        18.vGap,
                        ServiceSelectionField(
                          title: 'Model',
                          value: state.request.selectedModelYear?.toString(),
                          hintText: 'Select model year',
                          icon: Icons.calendar_month_outlined,
                          onTap: () async {
                            final selectedYear = await _showSelectionSheet<int>(
                              context: context,
                              title: 'Select model year',
                              items: state.modelYears,
                              labelBuilder: (year) => year.toString(),
                            );
                            if (selectedYear != null) {
                              cubit.updateModelYear(selectedYear);
                            }
                          },
                        ),
                        18.vGap,
                        ServiceTextField(
                          title: 'Variant',
                          hintText: 'Enter variant',
                          icon: Icons.alt_route_outlined,
                          controller: _carVariantController,
                        ),
                        18.vGap,
                        ServiceTextField(
                          title: 'Price (PKR)',
                          hintText: 'Set a price',
                          icon: Icons.sell_outlined,
                          controller: _usedCarPriceController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      18.vGap,
                      ServiceSelectionField(
                        title: 'Tenure',
                        value: state.request.tenureYears == null
                            ? null
                            : '${state.request.tenureYears} year${state.request.tenureYears == 1 ? '' : 's'}',
                        hintText: 'Select tenure',
                        icon: Icons.calendar_today_outlined,
                        onTap: () async {
                          final selectedTenure = await _showSelectionSheet<int>(
                            context: context,
                            title: 'Select tenure',
                            items: state.tenureOptions,
                            labelBuilder: (years) =>
                                '$years year${years == 1 ? '' : 's'}',
                          );
                          if (selectedTenure != null) {
                            cubit.updateTenure(selectedTenure);
                          }
                        },
                      ),
                      18.vGap,
                      ServiceSelectionField(
                        title: 'Down Payment',
                        value: state.request.downPaymentPercent == null
                            ? null
                            : '${state.request.downPaymentPercent}%',
                        hintText: 'Select percentage',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () async {
                          final selectedDownPayment =
                              await _showSelectionSheet<int>(
                                context: context,
                                title: 'Select down payment',
                                items: state.downPaymentOptions,
                                labelBuilder: (percent) => '$percent%',
                              );
                          if (selectedDownPayment != null) {
                            cubit.updateDownPayment(selectedDownPayment);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: context.color.primaryColor,
                padding: EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  MediaQuery.of(context).padding.bottom + 14,
                ),
                child: UiUtils.buildButton(
                  context,
                  onPressed: () {
                    if (!cubit.validateCalculator()) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: const CarFinancePlansScreen(),
                        ),
                      ),
                    );
                  },
                  buttonTitle: 'Calculate',
                  disabled: state.isLoadingBanks || state.banks.isEmpty,
                  radius: 12,
                  height: 54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CarFinancePlansScreen extends StatelessWidget {
  const CarFinancePlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarFinanceCubit, CarFinanceState>(
      builder: (context, state) {
        final quotes = context.read<CarFinanceCubit>().quotes;

        return Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: 'Car Finance',
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: quotes.length + 1,
            separatorBuilder: (_, _) => 14.vGap,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Available plans',
                      fontSize: context.font.extraLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    14.vGap,
                  ],
                );
              }

              final quote = quotes[index - 1];
              return _PlanQuoteCard(
                quote: quote,
                onTap: () {
                  final cubit = context.read<CarFinanceCubit>();
                  cubit.selectBank(quote.bank);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: const CarFinanceApplyScreen(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class CarFinanceApplyScreen extends StatelessWidget {
  const CarFinanceApplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarFinanceCubit, CarFinanceState>(
      builder: (context, state) {
        final cubit = context.read<CarFinanceCubit>();
        final quote = cubit.selectedQuote;
        if (quote == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: 'Apply for Car Finance',
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.submissionResult != null) ...[
                        _FinanceRequestConfirmation(
                          requestId: state.submissionResult!.id,
                          status: state.submissionResult!.status,
                          priceSource: state.submissionResult!.priceSource,
                          vehiclePrice: state.submissionResult!.vehiclePrice,
                        ),
                        18.vGap,
                      ],
                      _PriceHighlightCard(quote: quote),
                      18.vGap,
                      _SelectedBankCard(bank: quote.bank),
                      22.vGap,
                      _OptionSection<int>(
                        title: 'Tenure (in years)',
                        icon: Icons.calendar_today_outlined,
                        values: state.tenureOptions,
                        selectedValue: state.selectedTenure,
                        labelBuilder: (years) => '$years',
                        onSelected: cubit.updateApplyTenure,
                      ),
                      22.vGap,
                      _OptionSection<int>(
                        title: 'Down Payment',
                        icon: Icons.account_balance_wallet_outlined,
                        values: state.downPaymentOptions,
                        selectedValue: state.selectedDownPayment,
                        labelBuilder: (percent) => '$percent%',
                        onSelected: cubit.updateApplyDownPayment,
                      ),
                      26.vGap,
                      _DetailSection(
                        title: 'Details',
                        rows: [
                          _DetailRowData(
                            label: 'Monthly payment',
                            value: _formatCurrency(quote.monthlyInstallment),
                          ),
                          _DetailRowData(
                            label:
                                'Down Payment (${quote.downPaymentPercent}%)',
                            value: _formatCurrency(quote.downPaymentAmount),
                          ),
                          _DetailRowData(
                            label: 'Tenure (in years)',
                            value:
                                '${quote.tenureYears} year${quote.tenureYears == 1 ? '' : 's'}',
                          ),
                          _DetailRowData(
                            label: 'Bank loan',
                            value: _formatCurrency(quote.bankLoan),
                          ),
                        ],
                      ),
                      24.vGap,
                      _DetailSection(
                        title: 'Initial Payment',
                        rows: [
                          _DetailRowData(
                            label: 'Down Payment',
                            value: _formatCurrency(quote.downPaymentAmount),
                          ),
                          _DetailRowData(
                            label: 'Processing fee',
                            value: _formatCurrency(quote.processingFee),
                          ),
                          _DetailRowData(
                            label: 'First Year Insurance',
                            value: _formatCurrency(quote.firstYearInsurance),
                          ),
                        ],
                      ),
                      24.vGap,
                      _DetailSection(
                        title: 'Yearly Installment Plan',
                        rows: List.generate(
                          quote.tenureYears,
                          (index) => _DetailRowData(
                            label:
                                '${index + 1}${_ordinalSuffix(index + 1)} Year',
                            value:
                                '${_formatCurrency(quote.monthlyInstallment)}/Month',
                          ),
                        ),
                      ),
                      24.vGap,
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.color.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                CustomText(
                                  'Please view ',
                                  fontSize: context.font.small,
                                  color: context.color.textLightColor,
                                ),
                                _FinanceInfoLink(
                                  label: 'Eligibility Criteria',
                                  onTap: () => _showFinanceInfoSheet(
                                    context,
                                    _eligibilityCriteriaSheet,
                                  ),
                                ),
                                CustomText(
                                  ', ',
                                  fontSize: context.font.small,
                                  color: context.color.textLightColor,
                                ),
                                _FinanceInfoLink(
                                  label: 'Required Documents',
                                  onTap: () => _showFinanceInfoSheet(
                                    context,
                                    _requiredDocumentsSheet,
                                  ),
                                ),
                              ],
                            ),
                            12.vGap,
                            CustomText(
                              'Disclaimer: Prices and calculations might vary slightly depending on KIBOR or any other variable rates. Final values can be verified from the selected bank.',
                              fontSize: context.font.small,
                              color: context.color.textLightColor,
                              height: 1.55,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _StickyFinanceFooter(
                totalAmount: quote.totalInitialDeposit,
                onContinue: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: const CarFinanceApplicantScreen(),
                      ),
                    ),
                  );
                },
                isInProgress: false,
                disabled: state.submissionResult != null,
                buttonTitle: state.submissionResult == null
                    ? 'Continue'
                    : 'Application submitted',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CarFinanceHero extends StatelessWidget {
  const _CarFinanceHero();

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
                  'PakWheels Car Finance',
                  fontSize: context.font.extraLarge,
                  fontWeight: FontWeight.w700,
                ),
                8.vGap,
                CustomText(
                  'Best installment plans for car loan',
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w600,
                ),
                12.vGap,
                const _HeroBullet(label: 'Quick processing'),
                10.vGap,
                const _HeroBullet(label: 'No hidden costs'),
                10.vGap,
                const _HeroBullet(label: 'Dedicated customer support'),
                10.vGap,
                const _HeroBullet(label: 'Calculate and compare'),
              ],
            ),
          ),
          12.hGap,
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: serviceImageSurface(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              'assets/images/carFinance.png',
              fit: BoxFit.contain,
            ),
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
        Expanded(child: CustomText(label, fontSize: context.font.normal)),
      ],
    );
  }
}

class _FinanceBanksUnavailable extends StatelessWidget {
  const _FinanceBanksUnavailable({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            color: context.color.textLightColor,
            size: 30,
          ),
          12.vGap,
          CustomText(
            message,
            textAlign: TextAlign.center,
            fontSize: context.font.normal,
            color: context.color.textLightColor,
          ),
          14.vGap,
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _FinanceRequestConfirmation extends StatelessWidget {
  const _FinanceRequestConfirmation({
    required this.requestId,
    required this.status,
    required this.priceSource,
    required this.vehiclePrice,
  });

  final int requestId;
  final String status;
  final String priceSource;
  final int vehiclePrice;

  @override
  Widget build(BuildContext context) {
    final formattedStatus = status
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    final usedFallback = priceSource == 'temporary_fallback';
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
          const Icon(Icons.check_circle_rounded, color: successMessageColor),
          12.hGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Finance request #$requestId · $formattedStatus',
                  fontWeight: FontWeight.w700,
                  fontSize: context.font.normal,
                ),
                if (usedFallback) ...[
                  6.vGap,
                  CustomText(
                    'The ${_formatCurrency(vehiclePrice)} fallback vehicle price was used for this estimate.',
                    fontSize: context.font.small,
                    color: context.color.textLightColor,
                    height: 1.4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankRatesTable extends StatelessWidget {
  const _BankRatesTable({required this.banks});

  final List<CarFinanceBank> banks;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 80,
          columnSpacing: 28,
          dividerThickness: 0.6,
          columns: const [
            DataColumn(label: Text('Banks')),
            DataColumn(label: Text('Finance Rate')),
            DataColumn(label: Text('Insurance Rate')),
            DataColumn(label: Text('Processing fee')),
          ],
          rows: banks
              .map(
                (bank) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Row(
                          children: [
                            _BankBadge(bank: bank),
                            10.hGap,
                            Expanded(
                              child: CustomText(
                                bank.name,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text('${bank.financeRate.toStringAsFixed(2)}%')),
                    DataCell(Text('${bank.insuranceRate.toStringAsFixed(2)}%')),
                    DataCell(Text(_formatCurrency(bank.processingFee))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FinanceTypeTabs extends StatelessWidget {
  const _FinanceTypeTabs({required this.selectedType, required this.onChanged});

  final CarFinanceType selectedType;
  final ValueChanged<CarFinanceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: CarFinanceType.values.map((type) {
          final isSelected = type == selectedType;
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final selectedBackground = isDarkMode
              ? const Color(0xFF405E86)
              : context.color.territoryColor;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CustomText(
                    type == CarFinanceType.newCar ? 'New Cars' : 'Used Cars',
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : context.color.textDefaultColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.color.textLightColor),
        10.hGap,
        CustomText(
          label,
          fontSize: context.font.larger,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _PlanQuoteCard extends StatelessWidget {
  const _PlanQuoteCard({required this.quote, required this.onTap});

  final CarFinancePlanQuote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.color.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BankBadge(bank: quote.bank, size: 48),
            14.hGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    quote.bank.name,
                    fontSize: context.font.large,
                    fontWeight: FontWeight.w700,
                  ),
                  12.vGap,
                  _PlanRow(
                    label: 'Monthly Installment',
                    value: _formatCurrency(quote.monthlyInstallment),
                  ),
                  8.vGap,
                  _PlanRow(
                    label: 'Initial deposit',
                    value: _formatCurrency(quote.totalInitialDeposit),
                  ),
                  8.vGap,
                  _PlanRow(
                    label: 'Processing fee',
                    value: _formatCurrency(quote.processingFee),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: CustomText(label, color: context.color.textLightColor)),
        10.hGap,
        CustomText(value, fontWeight: FontWeight.w700),
      ],
    );
  }
}

class _PriceHighlightCard extends StatelessWidget {
  const _PriceHighlightCard({required this.quote});

  final CarFinancePlanQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: serviceWarningSurface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: serviceWarningForeground(context),
          ),
          12.hGap,
          Expanded(
            child: CustomText(
              quote.carLabel,
              fontWeight: FontWeight.w600,
              maxLines: 2,
            ),
          ),
          12.hGap,
          CustomText(
            _formatCurrency(quote.carPrice),
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}

class _SelectedBankCard extends StatelessWidget {
  const _SelectedBankCard({required this.bank});

  final CarFinanceBank bank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: [
          _BankBadge(bank: bank, size: 52),
          14.hGap,
          Expanded(
            child: CustomText(
              bank.name,
              fontSize: context.font.large,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionSection<T> extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.icon,
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String title;
  final IconData icon;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: title, icon: icon),
        14.vGap,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values.map((value) {
            final isSelected = value == selectedValue;
            return ChoiceChip(
              label: CustomText(
                labelBuilder(value),
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? context.color.territoryColor
                    : context.color.textDefaultColor,
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(value),
              backgroundColor: context.color.secondaryColor,
              selectedColor: serviceAccentSurface(context),
              side: BorderSide(
                color: isSelected
                    ? context.color.territoryColor
                    : context.color.borderColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: context.font.larger,
          fontWeight: FontWeight.w700,
        ),
        14.vGap,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Column(
            children: rows
                .map(
                  (row) => Padding(
                    padding: EdgeInsets.only(bottom: row == rows.last ? 0 : 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            row.label,
                            color: context.color.textLightColor,
                          ),
                        ),
                        14.hGap,
                        Flexible(
                          child: CustomText(
                            row.value,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StickyFinanceFooter extends StatelessWidget {
  const _StickyFinanceFooter({
    required this.totalAmount,
    required this.onContinue,
    required this.isInProgress,
    required this.disabled,
    required this.buttonTitle,
  });

  final int totalAmount;
  final VoidCallback onContinue;
  final bool isInProgress;
  final bool disabled;
  final String buttonTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: serviceShadow(context, alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'Total Initial Deposit:',
                  fontSize: context.font.normal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              12.hGap,
              Flexible(
                child: CustomText(
                  _formatCurrency(totalAmount),
                  textAlign: TextAlign.end,
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w800,
                  color: context.color.territoryColor,
                ),
              ),
            ],
          ),
          14.vGap,
          UiUtils.buildButton(
            context,
            onPressed: onContinue,
            buttonTitle: buttonTitle,
            isInProgress: isInProgress,
            disabled: disabled,
            radius: 12,
            height: 54,
          ),
        ],
      ),
    );
  }
}

class _BankBadge extends StatelessWidget {
  const _BankBadge({required this.bank, this.size = 44});

  final CarFinanceBank bank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = bank.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bank.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: CustomText(
          initials,
          fontWeight: FontWeight.w800,
          color: bank.accentColor,
        ),
      ),
    );
  }
}

class _DetailRowData {
  final String label;
  final String value;

  const _DetailRowData({required this.label, required this.value});
}

class _FinanceInfoLink extends StatelessWidget {
  const _FinanceInfoLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: CustomText(
          label,
          fontSize: context.font.small,
          fontWeight: FontWeight.w700,
          color: context.color.territoryColor,
          showUnderline: true,
          underlineOrLineColor: context.color.territoryColor,
        ),
      ),
    );
  }
}

class _FinanceInfoSheetData {
  const _FinanceInfoSheetData({required this.title, required this.sections});

  final String title;
  final List<_FinanceInfoSection> sections;
}

class _FinanceInfoSection {
  const _FinanceInfoSection({this.heading, required this.points});

  final String? heading;
  final List<String> points;
}

const _eligibilityCriteriaSheet = _FinanceInfoSheetData(
  title: 'Eligibility Criteria',
  sections: [
    _FinanceInfoSection(
      points: [
        'Pakistani Citizenship',
        'Minimum Monthly Net Salary / Monthly Income Requirement: PKR 80,000 minimum',
        'Age Requirement: Minimum 22 years. Maximum age at loan maturity: 65 years for salaried applicants and 70 years for self-employed applicants',
        'Employment Length (Salaried): Minimum 6 months',
        'Business Length (Self-Employed): Minimum 1 year',
      ],
    ),
  ],
);

const _requiredDocumentsSheet = _FinanceInfoSheetData(
  title: 'Required Documents',
  sections: [
    _FinanceInfoSection(
      heading: 'SALARIED',
      points: [
        'Copy of CNIC / NICOP / POC',
        'Recent passport size photographs',
        'Latest pay slip / salary certificate from employer',
        'Bank statement for the last 6 months',
        'Duly filled loan application form',
      ],
    ),
    _FinanceInfoSection(
      heading: 'BUSINESSMAN AND SELF-EMPLOYED PROFESSIONAL',
      points: [
        'Copy of CNIC / NICOP / POC',
        '2 recent passport size photographs',
        'Bank statement for the last 6 months',
        'Proof of profession or business proprietorship letter',
        'NTN certificate',
        'Tax Returns of 2 years',
        'Professional Degree',
        'Valid membership of applicable professional body (For SEP only)',
        'Duly filled loan application form',
        'Proprietorship declaration',
        'Certified Partnership Deed',
        'Memorandum & Articles of Association',
        'Form A & Form 29',
        'Company Profile',
        'Bank statement for the last 6 months',
        'Tax Returns and Assessment Order for the last 2 years',
        'Copy of latest utility bill',
      ],
    ),
  ],
);

Future<void> _showFinanceInfoSheet(
  BuildContext context,
  _FinanceInfoSheetData data,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FinanceInfoBottomSheet(data: data),
  );
}

class _FinanceInfoBottomSheet extends StatelessWidget {
  const _FinanceInfoBottomSheet({required this.data});

  final _FinanceInfoSheetData data;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.color.borderColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    14.vGap,
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            data.title,
                            fontSize: context.font.extraLarge,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.color.borderColor),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  itemCount: data.sections.length,
                  separatorBuilder: (_, _) => 26.vGap,
                  itemBuilder: (context, index) {
                    return _FinanceInfoSectionView(
                      section: data.sections[index],
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 14,
                ),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  border: Border(
                    top: BorderSide(color: context.color.borderColor),
                  ),
                ),
                child: UiUtils.buildButton(
                  context,
                  onPressed: () => Navigator.of(context).pop(),
                  buttonTitle: 'I Understand',
                  radius: 14,
                  height: 54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceInfoSectionView extends StatelessWidget {
  const _FinanceInfoSectionView({required this.section});

  final _FinanceInfoSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.heading != null) ...[
          CustomText(
            section.heading!,
            fontSize: context.font.large,
            fontWeight: FontWeight.w800,
            color: context.color.territoryColor,
          ),
          14.vGap,
        ],
        ...section.points.map(
          (point) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    color: context.color.territoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                12.hGap,
                Expanded(
                  child: CustomText(
                    point,
                    fontSize: context.font.normal,
                    color: context.color.textDefaultColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<T?> _showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelBuilder,
  Widget Function(T item)? trailingBuilder,
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
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: CustomText(
                        labelBuilder(item),
                        fontWeight: FontWeight.w600,
                      ),
                      trailing: trailingBuilder?.call(item),
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

String _formatCurrency(int value) {
  return 'PKR ${NumberFormat('#,##0').format(value)}';
}

String _carSelectionPriceLabel({
  required CarModelModel car,
  required bool isUsedCar,
  required int fallbackPrice,
}) {
  if (isUsedCar) return 'Set price next';
  if (car.price != null && car.price! > 0) {
    return _formatCurrency(car.price!);
  }
  if (fallbackPrice > 0) {
    return '${_formatCurrency(fallbackPrice)} fallback';
  }
  return 'Loading fallback price...';
}

String _formatPlainNumber(int value) {
  return NumberFormat('#,##0').format(value);
}

String _ordinalSuffix(int number) {
  if (number >= 11 && number <= 13) return 'th';
  switch (number % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
