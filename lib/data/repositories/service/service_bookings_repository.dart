import 'package:eClassify/data/model/service/service_booking_model.dart';
import 'package:eClassify/utils/api.dart';

class ServiceBookingsRepository {
  Future<ServiceBookingsPage> fetchBookings({
    required int page,
    int perPage = 15,
    String? type,
    String? status,
  }) async {
    final response = await Api.get(
      url: Api.myServiceBookingsApi,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      },
    );
    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Unable to load your service bookings.');
    }
    return ServiceBookingsPage.fromJson(Map<String, dynamic>.from(data));
  }
}
