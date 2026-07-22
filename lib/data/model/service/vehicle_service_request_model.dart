import 'package:eClassify/utils/pakistan_phone_utils.dart';

enum VehicleServiceRequestType { registration, ownership }

extension VehicleServiceRequestTypeX on VehicleServiceRequestType {
  String get endpoint => switch (this) {
    VehicleServiceRequestType.registration => 'car-registration-requests',
    VehicleServiceRequestType.ownership => 'car-ownership-requests',
  };

  String get displayName => switch (this) {
    VehicleServiceRequestType.registration => 'Car registration',
    VehicleServiceRequestType.ownership => 'Ownership transfer',
  };
}

class VehicleServiceRequestPayload {
  const VehicleServiceRequestPayload({
    required this.fullName,
    required this.phoneNumber,
    required this.isFiler,
    required this.carModelId,
    required this.modelYear,
    required this.carVariant,
    required this.registrationPlace,
  });

  final String fullName;
  final String phoneNumber;
  final bool isFiler;
  final int carModelId;
  final int modelYear;
  final String carVariant;
  final String registrationPlace;

  Map<String, dynamic> toApiMap() {
    return {
      'full_name': fullName.trim(),
      'phone_number': PakistanPhoneUtils.normalize(phoneNumber),
      'is_filer': isFiler ? 1 : 0,
      'car_model_id': carModelId,
      'model_year': modelYear,
      'car_variant': carVariant.trim(),
      'registration_place': registrationPlace,
    };
  }
}

class VehicleServiceRequestResult {
  const VehicleServiceRequestResult({
    required this.id,
    required this.type,
    required this.status,
    required this.message,
  });

  factory VehicleServiceRequestResult.fromResponse(
    Map<String, dynamic> response,
    VehicleServiceRequestType fallbackType,
  ) {
    final rawData = response['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final rawId = data['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (id == null || id <= 0) {
      throw const FormatException('Invalid vehicle service request ID.');
    }

    return VehicleServiceRequestResult(
      id: id,
      type: fallbackType,
      status: data['status']?.toString() ?? 'pending',
      message:
          response['message']?.toString() ??
          'Your request was submitted successfully.',
    );
  }

  final int id;
  final VehicleServiceRequestType type;
  final String status;
  final String message;
}
