import 'package:eClassify/data/model/service/car_finance_api_model.dart';
import 'package:eClassify/utils/api.dart';

class CarFinanceRepository {
  const CarFinanceRepository();

  Future<CarFinanceBanksConfig> fetchBanks() async {
    final response = await Api.get(url: 'car-finance-banks');
    try {
      return CarFinanceBanksConfig.fromResponse(response);
    } on FormatException {
      throw ApiException('Unable to load car finance plans.');
    }
  }

  Future<CarFinanceApplicationResult> submitApplication(
    CarFinanceApplicationPayload payload,
  ) async {
    final response = await Api.post(
      url: 'car-finance-requests',
      parameter: payload.toApiMap(),
    );
    try {
      return CarFinanceApplicationResult.fromResponse(response);
    } on FormatException {
      throw ApiException('The server returned an invalid finance request.');
    }
  }
}
