import 'package:eClassify/utils/pakistan_phone_utils.dart';

enum ServiceRequestType { carInspection, sellForMe }

extension ServiceRequestTypeX on ServiceRequestType {
  String get apiPath => switch (this) {
    ServiceRequestType.carInspection => 'car-inspection-requests',
    ServiceRequestType.sellForMe => 'sell-for-me-requests',
  };

  String get apiValue => switch (this) {
    ServiceRequestType.carInspection => 'car_inspection',
    ServiceRequestType.sellForMe => 'sell_for_me',
  };

  String get displayName => switch (this) {
    ServiceRequestType.carInspection => 'Car inspection',
    ServiceRequestType.sellForMe => 'Sell it for me',
  };
}

class ServiceRequestPayload {
  const ServiceRequestPayload({
    required this.type,
    required this.fullName,
    required this.phoneNumber,
    required this.cityId,
    required this.carModelId,
    required this.modelYear,
    required this.carVariant,
    required this.carCondition,
    required this.visitArea,
    required this.visitDate,
    required this.visitStartTime,
    required this.visitEndTime,
    this.servicePackageId,
    this.registrationArea,
  });

  final ServiceRequestType type;
  final int? servicePackageId;
  final String fullName;
  final String phoneNumber;
  final int cityId;
  final int carModelId;
  final int modelYear;
  final String carVariant;
  final String carCondition;
  final String? registrationArea;
  final String visitArea;
  final String visitDate;
  final String visitStartTime;
  final String visitEndTime;

  Map<String, dynamic> toApiMap() {
    return {
      if (servicePackageId != null) 'service_package_id': servicePackageId,
      'full_name': fullName.trim(),
      'phone_number': PakistanPhoneUtils.normalize(phoneNumber),
      'city_id': cityId,
      'car_model_id': carModelId,
      'model_year': modelYear,
      'car_variant': carVariant.trim(),
      'car_condition': carCondition,
      if (type == ServiceRequestType.sellForMe)
        'registration_area': registrationArea,
      'visit_area': visitArea.trim(),
      'visit_date': visitDate,
      'visit_start_time': visitStartTime,
      'visit_end_time': visitEndTime,
    };
  }
}

class ServiceRequestResult {
  const ServiceRequestResult({
    required this.id,
    required this.type,
    required this.status,
    required this.message,
    this.visitDate,
    this.visitStartTime,
    this.visitEndTime,
  });

  factory ServiceRequestResult.fromResponse({
    required Map<String, dynamic> response,
    required ServiceRequestType fallbackType,
  }) {
    final rawData = response['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final serviceType = data['service_type']?.toString();

    return ServiceRequestResult(
      id: _parseInt(data['id']),
      type: serviceType == ServiceRequestType.sellForMe.apiValue
          ? ServiceRequestType.sellForMe
          : serviceType == ServiceRequestType.carInspection.apiValue
          ? ServiceRequestType.carInspection
          : fallbackType,
      status: data['status']?.toString() ?? 'pending',
      message:
          response['message']?.toString() ??
          'Service request submitted successfully.',
      visitDate: data['visit_date']?.toString(),
      visitStartTime: data['visit_start_time']?.toString(),
      visitEndTime: data['visit_end_time']?.toString(),
    );
  }

  final int id;
  final ServiceRequestType type;
  final String status;
  final String message;
  final String? visitDate;
  final String? visitStartTime;
  final String? visitEndTime;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
