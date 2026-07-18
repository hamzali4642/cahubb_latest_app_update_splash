import 'package:eClassify/data/model/fuel_price_model.dart';
import 'package:eClassify/utils/api.dart';

class FuelPricesRepository {
  Future<FuelPriceModel> fetchLatest() async {
    final response = await Api.get(url: Api.latestFuelPricesApi);
    final data = response['data'];

    if (data is! Map) {
      throw ApiException('Fuel prices are not available yet.');
    }

    return FuelPriceModel.fromJson(Map<String, dynamic>.from(data));
  }
}
