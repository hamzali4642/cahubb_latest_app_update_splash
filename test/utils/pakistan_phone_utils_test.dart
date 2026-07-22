import 'package:eClassify/data/model/service/car_finance_api_model.dart';
import 'package:eClassify/data/model/service/service_request_model.dart';
import 'package:eClassify/data/model/service/vehicle_service_request_model.dart';
import 'package:eClassify/utils/pakistan_phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PakistanPhoneUtils', () {
    test('extracts a local number from common Pakistan formats', () {
      expect(PakistanPhoneUtils.localNumber('0300 1234567'), '3001234567');
      expect(PakistanPhoneUtils.localNumber('+92 300 1234567'), '3001234567');
      expect(PakistanPhoneUtils.localNumber('0092-300-1234567'), '3001234567');
    });

    test('normalizes local numbers with exactly one +92 prefix', () {
      expect(PakistanPhoneUtils.normalize('0300 1234567'), '+923001234567');
      expect(PakistanPhoneUtils.normalize('+923001234567'), '+923001234567');
    });

    test('accepts exactly 10 local digits', () {
      expect(PakistanPhoneUtils.isValid('3001234567'), isTrue);
      expect(PakistanPhoneUtils.isValid('+92 300 1234567'), isTrue);
      expect(PakistanPhoneUtils.isValid('300123456'), isFalse);
      expect(PakistanPhoneUtils.isValid('30012345678'), isFalse);
    });
  });

  test('all service request payloads submit normalized phone numbers', () {
    final inspectionPayload = ServiceRequestPayload(
      type: ServiceRequestType.carInspection,
      fullName: 'Test User',
      phoneNumber: '0300 1234567',
      cityId: 1,
      carModelId: 1,
      modelYear: 2024,
      carVariant: 'Test',
      carCondition: 'used',
      visitArea: 'Test area',
      visitDate: '2026-07-23',
      visitStartTime: '10:00:00',
      visitEndTime: '11:00:00',
    );
    final vehiclePayload = VehicleServiceRequestPayload(
      fullName: 'Test User',
      phoneNumber: '92 300 1234567',
      isFiler: true,
      carModelId: 1,
      modelYear: 2024,
      carVariant: 'Test',
      registrationPlace: 'Punjab',
    );
    const financeApplicant = CarFinanceApplicantDetails(
      fullName: 'Test User',
      phoneNumber: '0300-1234567',
    );

    expect(inspectionPayload.toApiMap()['phone_number'], '+923001234567');
    expect(vehiclePayload.toApiMap()['phone_number'], '+923001234567');
    expect(financeApplicant.toApiMap()['phone_number'], '+923001234567');
  });
}
