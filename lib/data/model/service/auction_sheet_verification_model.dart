class AuctionSheetVerificationPrice {
  const AuctionSheetVerificationPrice({
    required this.amount,
    required this.currencyCode,
  });

  factory AuctionSheetVerificationPrice.fromJson(Map<String, dynamic> json) {
    final amount = num.tryParse(json['price_amount']?.toString() ?? '');
    final currencyCode = json['currency_code']?.toString().trim() ?? '';
    if (amount == null || amount < 0 || currencyCode.isEmpty) {
      throw const FormatException('Invalid auction sheet verification price.');
    }
    return AuctionSheetVerificationPrice(
      amount: amount,
      currencyCode: currencyCode.toUpperCase(),
    );
  }

  final num amount;
  final String currencyCode;
}

class AuctionSheetVerificationResult {
  const AuctionSheetVerificationResult({
    required this.id,
    required this.chassisNumber,
    required this.status,
    required this.message,
  });

  factory AuctionSheetVerificationResult.fromResponse(
    Map<String, dynamic> response,
  ) {
    final rawData = response['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final rawId = data['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (id == null || id <= 0) {
      throw const FormatException('Invalid auction sheet request ID.');
    }

    return AuctionSheetVerificationResult(
      id: id,
      chassisNumber: data['chassis_number']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      message:
          response['message']?.toString() ??
          'Auction sheet verification request submitted successfully.',
    );
  }

  final int id;
  final String chassisNumber;
  final String status;
  final String message;
}
