import 'dart:math' as math;

import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/model/service/car_finance_api_model.dart';
import 'package:eClassify/data/repositories/service/service_lead_repository.dart';
import 'package:eClassify/data/repositories/service/car_finance_repository.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CarFinanceType { newCar, usedCar }

class CarFinanceBank {
  final int id;
  final String code;
  final String name;
  final double financeRate;
  final double insuranceRate;
  final int processingFee;
  final Color accentColor;
  final String? logoUrl;

  const CarFinanceBank({
    required this.id,
    required this.code,
    required this.name,
    required this.financeRate,
    required this.insuranceRate,
    required this.processingFee,
    required this.accentColor,
    this.logoUrl,
  });
}

class CarFinanceCalculatorRequest {
  final CarFinanceType financeType;
  final City? city;
  final CarModelModel? selectedCar;
  final int? usedCarPrice;
  final int? selectedModelYear;
  final String carVariant;
  final int? tenureYears;
  final int? downPaymentPercent;

  const CarFinanceCalculatorRequest({
    this.financeType = CarFinanceType.newCar,
    this.city,
    this.selectedCar,
    this.usedCarPrice,
    this.selectedModelYear,
    this.carVariant = '',
    this.tenureYears,
    this.downPaymentPercent,
  });

  int? carPrice({required int newCarFallbackPrice}) {
    if (financeType == CarFinanceType.usedCar) return usedCarPrice;
    final carPrice = selectedCar?.price;
    return carPrice != null && carPrice > 0
        ? carPrice
        : newCarFallbackPrice > 0
        ? newCarFallbackPrice
        : null;
  }

  String? get carLabel {
    if (selectedCar == null) return null;
    final base = '${selectedCar!.brandName} ${selectedCar!.name}';
    if (financeType == CarFinanceType.newCar) return base;

    final details = <String>[
      if (selectedModelYear != null) selectedModelYear.toString(),
      if (carVariant.trim().isNotEmpty) carVariant.trim(),
    ];
    return details.isEmpty ? base : '$base ${details.join(' ')}';
  }

  CarFinanceCalculatorRequest copyWith({
    CarFinanceType? financeType,
    City? city,
    CarModelModel? selectedCar,
    int? usedCarPrice,
    int? selectedModelYear,
    String? carVariant,
    int? tenureYears,
    int? downPaymentPercent,
    bool clearCity = false,
    bool clearSelectedCar = false,
    bool clearUsedCarPrice = false,
    bool clearSelectedModelYear = false,
    bool clearTenure = false,
    bool clearDownPayment = false,
  }) {
    return CarFinanceCalculatorRequest(
      financeType: financeType ?? this.financeType,
      city: clearCity ? null : (city ?? this.city),
      selectedCar: clearSelectedCar ? null : (selectedCar ?? this.selectedCar),
      usedCarPrice: clearUsedCarPrice
          ? null
          : (usedCarPrice ?? this.usedCarPrice),
      selectedModelYear: clearSelectedModelYear
          ? null
          : (selectedModelYear ?? this.selectedModelYear),
      carVariant: carVariant ?? this.carVariant,
      tenureYears: clearTenure ? null : (tenureYears ?? this.tenureYears),
      downPaymentPercent: clearDownPayment
          ? null
          : (downPaymentPercent ?? this.downPaymentPercent),
    );
  }
}

class CarFinancePlanQuote {
  final CarFinanceBank bank;
  final String carLabel;
  final int carPrice;
  final int tenureYears;
  final int downPaymentPercent;
  final int downPaymentAmount;
  final int bankLoan;
  final int processingFee;
  final int firstYearInsurance;
  final int monthlyInstallment;
  final int? totalInitialDepositOverride;

  const CarFinancePlanQuote({
    required this.bank,
    required this.carLabel,
    required this.carPrice,
    required this.tenureYears,
    required this.downPaymentPercent,
    required this.downPaymentAmount,
    required this.bankLoan,
    required this.processingFee,
    required this.firstYearInsurance,
    required this.monthlyInstallment,
    this.totalInitialDepositOverride,
  });

  int get totalInitialDeposit =>
      totalInitialDepositOverride ??
      downPaymentAmount + processingFee + firstYearInsurance;
}

class CarFinanceState {
  final List<CarFinanceBank> banks;
  final List<City> cities;
  final List<CarModelModel> carModels;
  final List<int> modelYears;
  final List<int> tenureOptions;
  final List<int> downPaymentOptions;
  final bool isLoadingCities;
  final bool isLoadingCars;
  final bool isLoadingBanks;
  final bool isSubmitting;
  final CarFinanceCalculatorRequest request;
  final CarFinanceApplicantDetails applicant;
  final CarFinanceBank? selectedBank;
  final int selectedTenure;
  final int selectedDownPayment;
  final int newCarFallbackPrice;
  final String currencyCode;
  final CarFinanceApplicationResult? submissionResult;
  final int submissionToken;
  final int loginRequiredToken;
  final String? banksErrorMessage;
  final String? feedbackMessage;
  final int feedbackToken;

  const CarFinanceState({
    required this.banks,
    required this.cities,
    required this.carModels,
    required this.modelYears,
    required this.tenureOptions,
    required this.downPaymentOptions,
    required this.isLoadingCities,
    required this.isLoadingCars,
    required this.isLoadingBanks,
    required this.isSubmitting,
    required this.request,
    required this.applicant,
    required this.selectedTenure,
    required this.selectedDownPayment,
    required this.newCarFallbackPrice,
    required this.currencyCode,
    this.selectedBank,
    this.submissionResult,
    this.submissionToken = 0,
    this.loginRequiredToken = 0,
    this.banksErrorMessage,
    this.feedbackMessage,
    this.feedbackToken = 0,
  });

  factory CarFinanceState.initial() {
    final cachedCities = ServiceLeadRepository.cachedCities;
    return CarFinanceState(
      banks: const [],
      cities: cachedCities,
      carModels: const [],
      modelYears: [
        for (int year = DateTime.now().year; year >= 1990; year--) year,
      ],
      tenureOptions: const [],
      downPaymentOptions: const [],
      isLoadingCities: cachedCities.isEmpty,
      isLoadingCars: true,
      isLoadingBanks: true,
      isSubmitting: false,
      request: const CarFinanceCalculatorRequest(
        tenureYears: null,
        downPaymentPercent: null,
      ),
      applicant: const CarFinanceApplicantDetails(),
      selectedTenure: 0,
      selectedDownPayment: 0,
      newCarFallbackPrice: 0,
      currencyCode: 'PKR',
    );
  }

  CarFinanceState copyWith({
    List<CarFinanceBank>? banks,
    List<City>? cities,
    List<CarModelModel>? carModels,
    List<int>? modelYears,
    List<int>? tenureOptions,
    List<int>? downPaymentOptions,
    bool? isLoadingCities,
    bool? isLoadingCars,
    bool? isLoadingBanks,
    bool? isSubmitting,
    CarFinanceCalculatorRequest? request,
    CarFinanceApplicantDetails? applicant,
    CarFinanceBank? selectedBank,
    int? selectedTenure,
    int? selectedDownPayment,
    int? newCarFallbackPrice,
    String? currencyCode,
    CarFinanceApplicationResult? submissionResult,
    int? submissionToken,
    int? loginRequiredToken,
    String? banksErrorMessage,
    String? feedbackMessage,
    bool clearSelectedBank = false,
    bool clearFeedbackMessage = false,
    bool clearBanksErrorMessage = false,
    bool clearSubmissionResult = false,
    int? feedbackToken,
  }) {
    return CarFinanceState(
      banks: banks ?? this.banks,
      cities: cities ?? this.cities,
      carModels: carModels ?? this.carModels,
      modelYears: modelYears ?? this.modelYears,
      tenureOptions: tenureOptions ?? this.tenureOptions,
      downPaymentOptions: downPaymentOptions ?? this.downPaymentOptions,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingCars: isLoadingCars ?? this.isLoadingCars,
      isLoadingBanks: isLoadingBanks ?? this.isLoadingBanks,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      request: request ?? this.request,
      applicant: applicant ?? this.applicant,
      selectedBank: clearSelectedBank
          ? null
          : (selectedBank ?? this.selectedBank),
      selectedTenure: selectedTenure ?? this.selectedTenure,
      selectedDownPayment: selectedDownPayment ?? this.selectedDownPayment,
      newCarFallbackPrice: newCarFallbackPrice ?? this.newCarFallbackPrice,
      currencyCode: currencyCode ?? this.currencyCode,
      submissionResult: clearSubmissionResult
          ? null
          : (submissionResult ?? this.submissionResult),
      submissionToken: submissionToken ?? this.submissionToken,
      loginRequiredToken: loginRequiredToken ?? this.loginRequiredToken,
      banksErrorMessage: clearBanksErrorMessage
          ? null
          : (banksErrorMessage ?? this.banksErrorMessage),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackToken: feedbackToken ?? this.feedbackToken,
    );
  }
}

class CarFinanceCubit extends Cubit<CarFinanceState> {
  CarFinanceCubit({
    ServiceLeadRepository? repository,
    CarFinanceRepository? financeRepository,
  }) : _repository = repository ?? ServiceLeadRepository(),
       _financeRepository = financeRepository ?? const CarFinanceRepository(),
       super(CarFinanceState.initial());

  final ServiceLeadRepository _repository;
  final CarFinanceRepository _financeRepository;

  Future<void> initialize() async {
    if (HiveUtils.isUserAuthenticated()) {
      final user = HiveUtils.getUserDetails();
      emit(
        state.copyWith(
          applicant: state.applicant.copyWith(
            fullName: user.name ?? '',
            phoneNumber: user.mobile ?? '',
            email: user.email ?? '',
          ),
        ),
      );
    }
    await Future.wait([_loadCities(), _loadCars(), loadBanks()]);
  }

  Future<void> loadBanks() async {
    emit(state.copyWith(isLoadingBanks: true, clearBanksErrorMessage: true));
    try {
      final config = await _financeRepository.fetchBanks();
      final banks = config.banks.map(_bankFromData).toList();
      final tenure = config.tenureOptions.first;
      final downPayment = config.downPaymentOptions.first;
      emit(
        state.copyWith(
          isLoadingBanks: false,
          banks: banks,
          tenureOptions: config.tenureOptions,
          downPaymentOptions: config.downPaymentOptions,
          newCarFallbackPrice: config.newCarFallbackPrice,
          currencyCode: config.currencyCode,
          request: state.request.copyWith(
            tenureYears:
                state.request.tenureYears != null &&
                    config.tenureOptions.contains(state.request.tenureYears)
                ? state.request.tenureYears
                : tenure,
            downPaymentPercent:
                state.request.downPaymentPercent != null &&
                    config.downPaymentOptions.contains(
                      state.request.downPaymentPercent,
                    )
                ? state.request.downPaymentPercent
                : downPayment,
          ),
          selectedTenure: config.tenureOptions.contains(state.selectedTenure)
              ? state.selectedTenure
              : tenure,
          selectedDownPayment:
              config.downPaymentOptions.contains(state.selectedDownPayment)
              ? state.selectedDownPayment
              : downPayment,
          clearBanksErrorMessage: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isLoadingBanks: false,
          banksErrorMessage: error.errorMessage.toString(),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingBanks: false,
          banksErrorMessage: 'Unable to load car finance plans.',
        ),
      );
    }
  }

  Future<void> _loadCities() async {
    if (state.cities.isEmpty) emit(state.copyWith(isLoadingCities: true));
    try {
      final cities = await _repository.fetchCities();
      emit(state.copyWith(cities: cities, isLoadingCities: false));
    } catch (_) {
      emit(state.copyWith(isLoadingCities: false));
      _emitFeedback('Unable to load cities right now.');
    }
  }

  Future<void> _loadCars() async {
    emit(state.copyWith(isLoadingCars: true));
    try {
      final carModels = await _repository.fetchCarModels();
      emit(state.copyWith(carModels: carModels, isLoadingCars: false));
    } catch (_) {
      emit(state.copyWith(isLoadingCars: false));
      _emitFeedback('Unable to load cars right now.');
    }
  }

  List<CarFinancePlanQuote> get quotes {
    final request = state.request;
    final carPrice = request.carPrice(
      newCarFallbackPrice: state.newCarFallbackPrice,
    );
    if (request.selectedCar == null ||
        request.carLabel == null ||
        carPrice == null ||
        request.tenureYears == null ||
        request.downPaymentPercent == null) {
      return const [];
    }

    final generatedQuotes = state.banks
        .map(
          (bank) => quoteFor(
            bank: bank,
            carLabel: request.carLabel!,
            carPrice: carPrice,
            tenureYears: request.tenureYears!,
            downPaymentPercent: request.downPaymentPercent!,
          ),
        )
        .toList();

    generatedQuotes.sort(
      (left, right) =>
          left.monthlyInstallment.compareTo(right.monthlyInstallment),
    );
    return generatedQuotes;
  }

  CarFinancePlanQuote? get selectedQuote {
    final submittedResult = state.submissionResult;
    if (submittedResult != null) {
      return _quoteFromSubmittedResult(submittedResult);
    }
    final bank = state.selectedBank;
    final request = state.request;
    final carPrice = request.carPrice(
      newCarFallbackPrice: state.newCarFallbackPrice,
    );
    if (bank == null ||
        request.selectedCar == null ||
        request.carLabel == null ||
        carPrice == null) {
      return null;
    }

    return quoteFor(
      bank: bank,
      carLabel: request.carLabel!,
      carPrice: carPrice,
      tenureYears: state.selectedTenure,
      downPaymentPercent: state.selectedDownPayment,
    );
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedbackMessage: true));
  }

  void clearLoginRequest() {
    emit(state.copyWith(loginRequiredToken: 0));
  }

  void updateType(CarFinanceType type) {
    emit(
      state.copyWith(
        request: state.request.copyWith(
          financeType: type,
          clearSelectedCar: true,
          clearUsedCarPrice: true,
          clearSelectedModelYear: true,
          carVariant: '',
        ),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateCity(City city) {
    emit(
      state.copyWith(
        request: state.request.copyWith(city: city),
        clearSubmissionResult: true,
      ),
    );
  }

  void updateCar(CarModelModel car) {
    emit(
      state.copyWith(
        request: state.request.copyWith(
          selectedCar: car,
          clearUsedCarPrice:
              state.request.financeType == CarFinanceType.usedCar,
          clearSelectedModelYear:
              state.request.financeType == CarFinanceType.usedCar,
          carVariant: state.request.financeType == CarFinanceType.usedCar
              ? ''
              : state.request.carVariant,
        ),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateUsedCarPrice(String value) {
    emit(
      state.copyWith(
        request: state.request.copyWith(usedCarPrice: _parsePrice(value)),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateModelYear(int year) {
    emit(
      state.copyWith(
        request: state.request.copyWith(selectedModelYear: year),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateCarVariant(String value) {
    emit(
      state.copyWith(
        request: state.request.copyWith(carVariant: value),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateTenure(int years) {
    emit(
      state.copyWith(
        request: state.request.copyWith(tenureYears: years),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateDownPayment(int percent) {
    emit(
      state.copyWith(
        request: state.request.copyWith(downPaymentPercent: percent),
        clearSelectedBank: true,
        clearSubmissionResult: true,
      ),
    );
  }

  bool validateCalculator() {
    final request = state.request;
    if (request.city == null) {
      _emitFeedback('Please select city.');
      return false;
    }
    if (request.selectedCar == null) {
      _emitFeedback('Please select car details.');
      return false;
    }
    if (request.financeType == CarFinanceType.usedCar) {
      if (request.selectedModelYear == null) {
        _emitFeedback('Please select model year.');
        return false;
      }
      if (request.carVariant.trim().isEmpty) {
        _emitFeedback('Please enter car variant.');
        return false;
      }
      if (request.usedCarPrice == null || request.usedCarPrice! <= 0) {
        _emitFeedback('Please enter car price.');
        return false;
      }
    } else if (request.carPrice(
          newCarFallbackPrice: state.newCarFallbackPrice,
        ) ==
        null) {
      _emitFeedback('New car price is unavailable. Please try again.');
      return false;
    }
    if (request.tenureYears == null || request.downPaymentPercent == null) {
      _emitFeedback('Please complete tenure and down payment.');
      return false;
    }
    if (!state.tenureOptions.contains(request.tenureYears) ||
        !state.downPaymentOptions.contains(request.downPaymentPercent)) {
      _emitFeedback('Please choose an available finance option.');
      return false;
    }
    if (state.banks.isEmpty) {
      _emitFeedback('Car finance plans are unavailable right now.');
      return false;
    }
    return true;
  }

  void selectBank(CarFinanceBank bank) {
    emit(
      state.copyWith(
        selectedBank: bank,
        selectedTenure: state.request.tenureYears ?? 1,
        selectedDownPayment: state.request.downPaymentPercent ?? 40,
        clearSubmissionResult: true,
      ),
    );
  }

  void updateApplyTenure(int years) {
    emit(state.copyWith(selectedTenure: years, clearSubmissionResult: true));
  }

  void updateApplyDownPayment(int percent) {
    emit(
      state.copyWith(selectedDownPayment: percent, clearSubmissionResult: true),
    );
  }

  void updateApplicantFullName(String value) {
    emit(state.copyWith(applicant: state.applicant.copyWith(fullName: value)));
  }

  void updateApplicantPhoneNumber(String value) {
    emit(
      state.copyWith(applicant: state.applicant.copyWith(phoneNumber: value)),
    );
  }

  void updateApplicantEmail(String value) {
    emit(state.copyWith(applicant: state.applicant.copyWith(email: value)));
  }

  void updateApplicantCnic(String value) {
    emit(state.copyWith(applicant: state.applicant.copyWith(cnic: value)));
  }

  void updateApplicantIncomeSource(String value) {
    emit(
      state.copyWith(applicant: state.applicant.copyWith(incomeSource: value)),
    );
  }

  void updateApplicantMonthlyIncome(String value) {
    emit(
      state.copyWith(applicant: state.applicant.copyWith(monthlyIncome: value)),
    );
  }

  void updateApplicantCurrentBank(String value) {
    emit(
      state.copyWith(applicant: state.applicant.copyWith(currentBank: value)),
    );
  }

  void updateApplicantCreditStatus(bool value) {
    emit(
      state.copyWith(
        applicant: state.applicant.copyWith(hasCreditCardsOrLoans: value),
      ),
    );
  }

  void updateApplicantProcessingTime(String value) {
    emit(
      state.copyWith(
        applicant: state.applicant.copyWith(processingTime: value),
      ),
    );
  }

  bool validateApplicantDetails() {
    final applicant = state.applicant;
    if (applicant.fullName.trim().isEmpty) {
      _emitFeedback('Please enter your name.');
      return false;
    }
    if (applicant.fullName.trim().length > 150) {
      _emitFeedback('Name must not exceed 150 characters.');
      return false;
    }
    if (applicant.phoneNumber.trim().isEmpty) {
      _emitFeedback('Please enter your phone number.');
      return false;
    }
    if (applicant.phoneNumber.trim().length > 30 ||
        !RegExp(r'^\+?[0-9()\-\s]+$').hasMatch(applicant.phoneNumber.trim())) {
      _emitFeedback('Please enter a valid phone number.');
      return false;
    }
    if (applicant.email.trim().isEmpty ||
        !RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(applicant.email.trim())) {
      _emitFeedback('Please enter a valid email address.');
      return false;
    }
    if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(applicant.cnic.trim())) {
      _emitFeedback('Please enter CNIC in 12345-1234567-1 format.');
      return false;
    }
    if (state.request.city == null) {
      _emitFeedback('Please select your city.');
      return false;
    }
    if (!const ['salaried', 'self_employed'].contains(applicant.incomeSource)) {
      _emitFeedback('Please select your source of income.');
      return false;
    }
    if (applicant.monthlyIncome != 'above_80000') {
      _emitFeedback('Please select your monthly income.');
      return false;
    }
    if (applicant.currentBank.trim().isEmpty) {
      _emitFeedback('Please enter your current bank.');
      return false;
    }
    if (applicant.currentBank.trim().length > 150) {
      _emitFeedback('Bank name must not exceed 150 characters.');
      return false;
    }
    if (applicant.hasCreditCardsOrLoans == null) {
      _emitFeedback('Please select whether you have credit cards or loans.');
      return false;
    }
    if (!const [
      'next_2_weeks',
      'next_month',
      'just_information',
    ].contains(applicant.processingTime)) {
      _emitFeedback('Please select your preferred processing time.');
      return false;
    }
    return true;
  }

  Future<void> submitApplication() async {
    if (state.isSubmitting) return;
    if (!HiveUtils.isUserAuthenticated()) {
      _emitFeedback('Please sign in to submit a car finance request.');
      emit(state.copyWith(loginRequiredToken: state.loginRequiredToken + 1));
      return;
    }
    if (!validateCalculator() || !validateApplicantDetails()) return;

    final request = state.request;
    if (selectedQuote == null || state.selectedBank == null) {
      _emitFeedback('Please select a finance plan before submitting.');
      return;
    }
    if (!state.tenureOptions.contains(state.selectedTenure) ||
        !state.downPaymentOptions.contains(state.selectedDownPayment)) {
      _emitFeedback('Please choose an available finance option.');
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final result = await _financeRepository.submitApplication(
        CarFinanceApplicationPayload(
          financeType: request.financeType == CarFinanceType.newCar
              ? 'new_car'
              : 'used_car',
          cityId: request.city!.id,
          carModelId: request.selectedCar!.id,
          bankId: state.selectedBank!.id,
          tenureYears: state.selectedTenure,
          downPaymentPercent: state.selectedDownPayment,
          applicant: state.applicant,
          modelYear: request.selectedModelYear,
          carVariant: request.carVariant,
          usedCarPrice: request.usedCarPrice,
        ),
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          submissionResult: result,
          submissionToken: state.submissionToken + 1,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false));
      _emitFeedback(error.errorMessage.toString());
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
      _emitFeedback(
        'Unable to submit the car finance request. Please try again.',
      );
    }
  }

  CarFinancePlanQuote _quoteFromSubmittedResult(
    CarFinanceApplicationResult result,
  ) {
    return CarFinancePlanQuote(
      bank: _bankFromData(result.bank),
      carLabel: state.request.carLabel ?? 'Selected car',
      carPrice: result.vehiclePrice,
      tenureYears: result.tenureYears,
      downPaymentPercent: result.downPaymentPercent,
      downPaymentAmount: result.downPaymentAmount,
      bankLoan: result.bankLoan,
      processingFee: result.processingFee,
      firstYearInsurance: result.firstYearInsurance,
      monthlyInstallment: result.monthlyInstallment,
      totalInitialDepositOverride: result.totalInitialDeposit,
    );
  }

  static CarFinanceBank _bankFromData(CarFinanceBankData bank) {
    return CarFinanceBank(
      id: bank.id,
      code: bank.code,
      name: bank.name,
      financeRate: bank.financeRate,
      insuranceRate: bank.insuranceRate,
      processingFee: bank.processingFee,
      accentColor: _parseAccentColor(bank.accentColor),
      logoUrl: bank.logoUrl,
    );
  }

  static Color _parseAccentColor(String? value) {
    final normalized = value?.trim().replaceFirst('#', '') ?? '';
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null || normalized.length != 6
        ? const Color(0xFF293850)
        : Color(0xFF000000 | parsed);
  }

  static CarFinancePlanQuote quoteFor({
    required CarFinanceBank bank,
    required String carLabel,
    required int carPrice,
    required int tenureYears,
    required int downPaymentPercent,
  }) {
    final downPaymentAmount = ((carPrice * downPaymentPercent) / 100).round();
    final bankLoan = carPrice - downPaymentAmount;
    final firstYearInsurance = ((carPrice * bank.insuranceRate) / 100).round();
    final years = math.max(tenureYears, 1);
    final interestMultiplier = 1 + ((bank.financeRate / 100) * years);
    final totalRepayable = bankLoan * interestMultiplier;
    final monthlyInstallment = (totalRepayable / (years * 12)).round();

    return CarFinancePlanQuote(
      bank: bank,
      carLabel: carLabel,
      carPrice: carPrice,
      tenureYears: tenureYears,
      downPaymentPercent: downPaymentPercent,
      downPaymentAmount: downPaymentAmount,
      bankLoan: bankLoan,
      processingFee: bank.processingFee,
      firstYearInsurance: firstYearInsurance,
      monthlyInstallment: monthlyInstallment,
    );
  }

  int? _parsePrice(String value) {
    final normalized = value.replaceAll(',', '').trim();
    return int.tryParse(normalized);
  }

  void _emitFeedback(String message) {
    emit(
      state.copyWith(
        feedbackMessage: message,
        feedbackToken: state.feedbackToken + 1,
      ),
    );
  }
}
