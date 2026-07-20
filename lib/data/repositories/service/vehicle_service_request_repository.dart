import 'package:eClassify/data/model/service/vehicle_service_request_model.dart';
import 'package:eClassify/utils/api.dart';

class VehicleServiceRequestRepository {
  const VehicleServiceRequestRepository();

  Future<VehicleServiceRequestResult> submit({
    required VehicleServiceRequestType type,
    required VehicleServiceRequestPayload payload,
  }) async {
    final response = await Api.post(
      url: type.endpoint,
      parameter: payload.toApiMap(),
    );

    try {
      return VehicleServiceRequestResult.fromResponse(response, type);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid vehicle service request ID.',
      );
    }
  }
}
