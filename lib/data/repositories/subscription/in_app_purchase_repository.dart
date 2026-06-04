import 'package:eClassify/utils/api.dart';

class InAppPurchaseRepository {
  Future<Map> inAppPurchases({
    required String method,
    required String packageId,
    required String paymentTransactionId,
  }) async {
    return Api.post(
      url: Api.inAppPurchaseApi,
      parameter: {
        Api.paymentMethod: method,
        Api.packageId: packageId,
        Api.paymentTransectionId: paymentTransactionId,
      },
    );
  }
}
