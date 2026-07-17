import 'dart:math' as math;

import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/repositories/service/service_lead_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CarFinanceType { newCar, usedCar }

class CarFinanceBank {
  final String id;
  final String name;
  final double financeRate;
  final double insuranceRate;
  final int processingFee;
  final Color accentColor;

  const CarFinanceBank({
    required this.id,
    required this.name,
    required this.financeRate,
    required this.insuranceRate,
    required this.processingFee,
    required this.accentColor,
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

  int? get carPrice {
    return financeType == CarFinanceType.newCar
        ? selectedCar?.price
        : usedCarPrice;
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
  });

  int get totalInitialDeposit =>
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
  final CarFinanceCalculatorRequest request;
  final CarFinanceBank? selectedBank;
  final int selectedTenure;
  final int selectedDownPayment;
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
    required this.request,
    required this.selectedTenure,
    required this.selectedDownPayment,
    this.selectedBank,
    this.feedbackMessage,
    this.feedbackToken = 0,
  });

  factory CarFinanceState.initial() {
    return CarFinanceState(
      banks: CarFinanceCubit.defaultBanks,
      cities: const [],
      carModels: const [],
      modelYears: [
        for (int year = DateTime.now().year; year >= 1990; year--) year,
      ],
      tenureOptions: CarFinanceCubit.defaultTenureOptions,
      downPaymentOptions: CarFinanceCubit.defaultDownPaymentOptions,
      isLoadingCities: true,
      isLoadingCars: true,
      request: const CarFinanceCalculatorRequest(
        tenureYears: 1,
        downPaymentPercent: 40,
      ),
      selectedTenure: 1,
      selectedDownPayment: 40,
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
    CarFinanceCalculatorRequest? request,
    CarFinanceBank? selectedBank,
    int? selectedTenure,
    int? selectedDownPayment,
    String? feedbackMessage,
    bool clearSelectedBank = false,
    bool clearFeedbackMessage = false,
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
      request: request ?? this.request,
      selectedBank: clearSelectedBank
          ? null
          : (selectedBank ?? this.selectedBank),
      selectedTenure: selectedTenure ?? this.selectedTenure,
      selectedDownPayment: selectedDownPayment ?? this.selectedDownPayment,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      feedbackToken: feedbackToken ?? this.feedbackToken,
    );
  }
}

class CarFinanceCubit extends Cubit<CarFinanceState> {
  CarFinanceCubit({ServiceLeadRepository? repository})
    : _repository = repository ?? ServiceLeadRepository(),
      super(CarFinanceState.initial());

  final ServiceLeadRepository _repository;

  static const List<CarFinanceBank> defaultBanks = [
    CarFinanceBank(
      id: 'faysal',
      name: 'Faysal Car Finance',
      financeRate: 15.64,
      insuranceRate: 1.50,
      processingFee: 12000,
      accentColor: Color(0xFF1B6B9A),
    ),
    CarFinanceBank(
      id: 'micar',
      name: 'MI Car',
      financeRate: 14.64,
      insuranceRate: 1.29,
      processingFee: 8000,
      accentColor: Color(0xFF1F7A3E),
    ),
    CarFinanceBank(
      id: 'dib',
      name: 'DIB Auto Finance',
      financeRate: 14.64,
      insuranceRate: 1.75,
      processingFee: 8350,
      accentColor: Color(0xFF0E8D6A),
    ),
    CarFinanceBank(
      id: 'mcb',
      name: 'MCB Car4U',
      financeRate: 15.64,
      insuranceRate: 1.75,
      processingFee: 12000,
      accentColor: Color(0xFF1D8E49),
    ),
    CarFinanceBank(
      id: 'albaraka',
      name: 'Al Baraka Carsaaz',
      financeRate: 15.72,
      insuranceRate: 1.50,
      processingFee: 8120,
      accentColor: Color(0xFFC84B31),
    ),
    CarFinanceBank(
      id: 'alfalah',
      name: 'Alfalah Car Financing',
      financeRate: 14.95,
      insuranceRate: 1.60,
      processingFee: 10000,
      accentColor: Color(0xFFD62828),
    ),
  ];

  static const List<int> defaultTenureOptions = [1, 2, 3, 4, 5];
  static const List<int> defaultDownPaymentOptions = [
    40,
    45,
    50,
    55,
    60,
    65,
    70,
  ];

  Future<void> initialize() async {
    await Future.wait([_loadCities(), _loadCars()]);
  }

  Future<void> _loadCities() async {
    emit(state.copyWith(isLoadingCities: true));
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
    final carPrice = request.carPrice;
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
    final bank = state.selectedBank;
    final request = state.request;
    final carPrice = request.carPrice;
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
      ),
    );
  }

  void updateCity(City city) {
    emit(state.copyWith(request: state.request.copyWith(city: city)));
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
      ),
    );
  }

  void updateUsedCarPrice(String value) {
    emit(
      state.copyWith(
        request: state.request.copyWith(usedCarPrice: _parsePrice(value)),
        clearSelectedBank: true,
      ),
    );
  }

  void updateModelYear(int year) {
    emit(
      state.copyWith(
        request: state.request.copyWith(selectedModelYear: year),
        clearSelectedBank: true,
      ),
    );
  }

  void updateCarVariant(String value) {
    emit(
      state.copyWith(
        request: state.request.copyWith(carVariant: value),
        clearSelectedBank: true,
      ),
    );
  }

  void updateTenure(int years) {
    emit(
      state.copyWith(
        request: state.request.copyWith(tenureYears: years),
        clearSelectedBank: true,
      ),
    );
  }

  void updateDownPayment(int percent) {
    emit(
      state.copyWith(
        request: state.request.copyWith(downPaymentPercent: percent),
        clearSelectedBank: true,
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
    } else if ((request.selectedCar?.price ?? 0) <= 0) {
      _emitFeedback('Selected car price is unavailable.');
      return false;
    }
    if (request.tenureYears == null || request.downPaymentPercent == null) {
      _emitFeedback('Please complete tenure and down payment.');
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
      ),
    );
  }

  void updateApplyTenure(int years) {
    emit(state.copyWith(selectedTenure: years));
  }

  void updateApplyDownPayment(int percent) {
    emit(state.copyWith(selectedDownPayment: percent));
  }

  void submitApplication() {
    _emitFeedback(
      'Finance application flow will be connected once the API is ready.',
    );
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
