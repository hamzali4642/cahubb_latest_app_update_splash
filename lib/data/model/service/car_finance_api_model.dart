class CarFinanceBankData {
  const CarFinanceBankData({
    required this.id,
    required this.code,
    required this.name,
    required this.financeRate,
    required this.insuranceRate,
    required this.processingFee,
    this.logoUrl,
    this.accentColor,
  });

  factory CarFinanceBankData.fromJson(Map<String, dynamic> json) {
    return CarFinanceBankData(
      id: _parsePositiveInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      financeRate: _parseDouble(json['finance_rate']),
      insuranceRate: _parseDouble(json['insurance_rate']),
      processingFee: _parseNonNegativeInt(json['processing_fee']),
      logoUrl: json['logo_url']?.toString(),
      accentColor: json['accent_color']?.toString(),
    );
  }

  final int id;
  final String code;
  final String name;
  final double financeRate;
  final double insuranceRate;
  final int processingFee;
  final String? logoUrl;
  final String? accentColor;
}

class CarFinanceBanksConfig {
  const CarFinanceBanksConfig({
    required this.banks,
    required this.tenureOptions,
    required this.downPaymentOptions,
    required this.newCarFallbackPrice,
    required this.currencyCode,
  });

  factory CarFinanceBanksConfig.fromResponse(Map<String, dynamic> response) {
    final rawData = response['data'];
    if (rawData is! Map) {
      throw const FormatException('Invalid car finance banks response.');
    }
    final data = Map<String, dynamic>.from(rawData);
    final banks = (data['banks'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (bank) =>
              CarFinanceBankData.fromJson(Map<String, dynamic>.from(bank)),
        )
        .where((bank) => bank.id > 0 && bank.name.isNotEmpty)
        .toList();
    final tenureOptions = _parseIntegerList(data['tenure_options']);
    final downPaymentOptions = _parseIntegerList(data['down_payment_options']);
    final fallbackPrice = _parsePositiveInt(data['new_car_fallback_price']);
    final currencyCode = data['currency_code']?.toString().trim() ?? '';

    if (banks.isEmpty ||
        tenureOptions.isEmpty ||
        downPaymentOptions.isEmpty ||
        fallbackPrice <= 0 ||
        currencyCode.isEmpty) {
      throw const FormatException('Incomplete car finance banks response.');
    }

    return CarFinanceBanksConfig(
      banks: banks,
      tenureOptions: tenureOptions,
      downPaymentOptions: downPaymentOptions,
      newCarFallbackPrice: fallbackPrice,
      currencyCode: currencyCode.toUpperCase(),
    );
  }

  final List<CarFinanceBankData> banks;
  final List<int> tenureOptions;
  final List<int> downPaymentOptions;
  final int newCarFallbackPrice;
  final String currencyCode;
}

class CarFinanceApplicationPayload {
  const CarFinanceApplicationPayload({
    required this.financeType,
    required this.cityId,
    required this.carModelId,
    required this.bankId,
    required this.tenureYears,
    required this.downPaymentPercent,
    required this.applicant,
    this.modelYear,
    this.carVariant,
    this.usedCarPrice,
  });

  final String financeType;
  final int cityId;
  final int carModelId;
  final int bankId;
  final int tenureYears;
  final int downPaymentPercent;
  final CarFinanceApplicantDetails applicant;
  final int? modelYear;
  final String? carVariant;
  final int? usedCarPrice;

  Map<String, dynamic> toApiMap() {
    return {
      'finance_type': financeType,
      'city_id': cityId,
      'car_model_id': carModelId,
      if (financeType == 'used_car') ...{
        'model_year': modelYear,
        'car_variant': carVariant?.trim(),
        'used_car_price': usedCarPrice,
      },
      'bank_id': bankId,
      'tenure_years': tenureYears,
      'down_payment_percent': downPaymentPercent,
      ...applicant.toApiMap(),
    };
  }
}

class CarFinanceApplicantDetails {
  const CarFinanceApplicantDetails({
    this.fullName = '',
    this.phoneNumber = '',
    this.email = '',
    this.cnic = '',
    this.incomeSource,
    this.monthlyIncome,
    this.currentBank = '',
    this.hasCreditCardsOrLoans,
    this.processingTime,
  });

  final String fullName;
  final String phoneNumber;
  final String email;
  final String cnic;
  final String? incomeSource;
  final String? monthlyIncome;
  final String currentBank;
  final bool? hasCreditCardsOrLoans;
  final String? processingTime;

  CarFinanceApplicantDetails copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? cnic,
    String? incomeSource,
    String? monthlyIncome,
    String? currentBank,
    bool? hasCreditCardsOrLoans,
    String? processingTime,
  }) {
    return CarFinanceApplicantDetails(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      cnic: cnic ?? this.cnic,
      incomeSource: incomeSource ?? this.incomeSource,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currentBank: currentBank ?? this.currentBank,
      hasCreditCardsOrLoans:
          hasCreditCardsOrLoans ?? this.hasCreditCardsOrLoans,
      processingTime: processingTime ?? this.processingTime,
    );
  }

  Map<String, dynamic> toApiMap() {
    return {
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'email': email.trim(),
      'cnic': cnic.trim(),
      'income_source': incomeSource,
      'monthly_income': monthlyIncome,
      'current_bank': currentBank.trim(),
      'has_credit_cards_or_loans': hasCreditCardsOrLoans == true ? 1 : 0,
      'processing_time': processingTime,
    };
  }
}

class CarFinanceApplicationResult {
  const CarFinanceApplicationResult({
    required this.id,
    required this.applicant,
    required this.financeType,
    required this.cityId,
    required this.carModelId,
    required this.bank,
    required this.vehiclePrice,
    required this.priceSource,
    required this.tenureYears,
    required this.downPaymentPercent,
    required this.financeRate,
    required this.insuranceRate,
    required this.processingFee,
    required this.downPaymentAmount,
    required this.bankLoan,
    required this.firstYearInsurance,
    required this.monthlyInstallment,
    required this.totalInitialDeposit,
    required this.status,
    required this.message,
    this.createdAt,
  });

  factory CarFinanceApplicationResult.fromResponse(
    Map<String, dynamic> response,
  ) {
    final rawData = response['data'];
    if (rawData is! Map) {
      throw const FormatException('Invalid car finance request response.');
    }
    final data = Map<String, dynamic>.from(rawData);
    final rawBank = data['bank'];
    if (rawBank is! Map) {
      throw const FormatException('Missing submitted finance bank.');
    }

    final bankData = Map<String, dynamic>.from(rawBank)
      ..['finance_rate'] = data['finance_rate']
      ..['insurance_rate'] = data['insurance_rate']
      ..['processing_fee'] = data['processing_fee'];

    return CarFinanceApplicationResult(
      id: _parsePositiveInt(data['id']),
      applicant: CarFinanceSubmittedApplicant.fromJson(data),
      financeType: data['finance_type']?.toString() ?? '',
      cityId: _parsePositiveInt(data['city_id']),
      carModelId: _parsePositiveInt(data['car_model_id']),
      bank: CarFinanceBankData.fromJson(bankData),
      vehiclePrice: _parsePositiveInt(data['vehicle_price']),
      priceSource: data['price_source']?.toString() ?? '',
      tenureYears: _parsePositiveInt(data['tenure_years']),
      downPaymentPercent: _parseNonNegativeInt(data['down_payment_percent']),
      financeRate: _parseDouble(data['finance_rate']),
      insuranceRate: _parseDouble(data['insurance_rate']),
      processingFee: _parseNonNegativeInt(data['processing_fee']),
      downPaymentAmount: _parseNonNegativeInt(data['down_payment_amount']),
      bankLoan: _parseNonNegativeInt(data['bank_loan']),
      firstYearInsurance: _parseNonNegativeInt(data['first_year_insurance']),
      monthlyInstallment: _parseNonNegativeInt(data['monthly_installment']),
      totalInitialDeposit: _parseNonNegativeInt(data['total_initial_deposit']),
      status: data['status']?.toString() ?? 'pending',
      message:
          response['message']?.toString() ??
          'Car finance request submitted successfully.',
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
    );
  }

  final int id;
  final CarFinanceSubmittedApplicant applicant;
  final String financeType;
  final int cityId;
  final int carModelId;
  final CarFinanceBankData bank;
  final int vehiclePrice;
  final String priceSource;
  final int tenureYears;
  final int downPaymentPercent;
  final double financeRate;
  final double insuranceRate;
  final int processingFee;
  final int downPaymentAmount;
  final int bankLoan;
  final int firstYearInsurance;
  final int monthlyInstallment;
  final int totalInitialDeposit;
  final String status;
  final String message;
  final DateTime? createdAt;
}

/// Safe applicant details returned by the API after a submission.
///
/// The backend deliberately returns only [cnicMasked], never the full CNIC.
class CarFinanceSubmittedApplicant {
  const CarFinanceSubmittedApplicant({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.cnicMasked,
    required this.incomeSource,
    required this.monthlyIncome,
    required this.currentBank,
    required this.hasCreditCardsOrLoans,
    required this.processingTime,
  });

  factory CarFinanceSubmittedApplicant.fromJson(Map<String, dynamic> json) {
    return CarFinanceSubmittedApplicant(
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cnicMasked: json['cnic_masked']?.toString() ?? '',
      incomeSource: json['income_source']?.toString() ?? '',
      monthlyIncome: json['monthly_income']?.toString() ?? '',
      currentBank: json['current_bank']?.toString() ?? '',
      hasCreditCardsOrLoans: _parseBool(json['has_credit_cards_or_loans']),
      processingTime: json['processing_time']?.toString() ?? '',
    );
  }

  final String fullName;
  final String phoneNumber;
  final String email;
  final String cnicMasked;
  final String incomeSource;
  final String monthlyIncome;
  final String currentBank;
  final bool hasCreditCardsOrLoans;
  final String processingTime;
}

int _parsePositiveInt(dynamic value) {
  final parsed = _parseNonNegativeInt(value);
  if (parsed <= 0) throw const FormatException('Expected a positive integer.');
  return parsed;
}

int _parseNonNegativeInt(dynamic value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null || number < 0) {
    throw const FormatException('Expected a non-negative integer.');
  }
  return number.round();
}

double _parseDouble(dynamic value) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < 0) {
    throw const FormatException('Expected a non-negative number.');
  }
  return parsed;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return switch (value?.toString().trim().toLowerCase()) {
    '1' || 'true' => true,
    _ => false,
  };
}

List<int> _parseIntegerList(dynamic value) {
  final parsed =
      (value as List? ?? const [])
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .where((item) => item > 0)
          .toSet()
          .toList()
        ..sort();
  return parsed;
}
