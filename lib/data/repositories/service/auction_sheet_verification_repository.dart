import 'package:eClassify/data/model/service/auction_sheet_verification_model.dart';
import 'package:eClassify/utils/api.dart';

class AuctionSheetVerificationRepository {
  const AuctionSheetVerificationRepository();

  static const String _priceEndpoint = 'auction-sheet-verification-price';
  static const String _requestEndpoint = 'auction-sheet-verification-requests';

  Future<AuctionSheetVerificationPrice> fetchPrice() async {
    final response = await Api.get(url: _priceEndpoint);
    final rawData = response['data'];
    if (rawData is! Map) {
      throw ApiException('Unable to load the verification price.');
    }
    try {
      return AuctionSheetVerificationPrice.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    } on FormatException {
      throw ApiException('Unable to load the verification price.');
    }
  }

  Future<AuctionSheetVerificationResult> submitRequest({
    required String chassisNumber,
    required String phoneNumber,
  }) async {
    final response = await Api.post(
      url: _requestEndpoint,
      parameter: {'chassis_number': chassisNumber, 'phone_number': phoneNumber},
    );
    try {
      return AuctionSheetVerificationResult.fromResponse(response);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid auction sheet request ID.',
      );
    }
  }
}
