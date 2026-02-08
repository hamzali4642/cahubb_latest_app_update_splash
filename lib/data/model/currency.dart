class Currency {
  int? id;
  String? code;
  String? symbol;
  int? selected; // 1 if currency belongs to user's country, else 0

  Currency.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['iso_code'];
    symbol = json['symbol'];
    selected = json['selected'];
  }
}
