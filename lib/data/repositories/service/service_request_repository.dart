import 'package:eClassify/data/model/service/service_request_model.dart';
import 'package:eClassify/utils/api.dart';

class ServiceRequestRepository {
  const ServiceRequestRepository();

  Future<ServiceRequestResult> submit(ServiceRequestPayload payload) async {
    final response = await Api.post(
      url: payload.type.apiPath,
      parameter: payload.toApiMap(),
    );

    final result = ServiceRequestResult.fromResponse(
      response: response,
      fallbackType: payload.type,
    );
    if (result.id <= 0) {
      throw ApiException(
        'The request was submitted, but the server returned an invalid request ID.',
      );
    }
    return result;
  }
}
