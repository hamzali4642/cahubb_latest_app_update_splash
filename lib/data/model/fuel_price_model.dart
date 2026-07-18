class FuelPriceModel {
  const FuelPriceModel({
    required this.id,
    required this.petrolSuper,
    required this.highOctane,
    required this.highSpeedDiesel,
    required this.lpg,
    required this.keroseneOil,
    required this.createdDate,
    required this.createdAt,
  });

  final int id;
  final String petrolSuper;
  final String highOctane;
  final String highSpeedDiesel;
  final String lpg;
  final String keroseneOil;
  final String createdDate;
  final DateTime? createdAt;

  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      petrolSuper: _price(json['petrol_super']),
      highOctane: _price(json['high_octane']),
      highSpeedDiesel: _price(json['high_speed_diesel']),
      lpg: _price(json['lpg']),
      keroseneOil: _price(json['kerosene_oil']),
      createdDate: json['created_date']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static String _price(dynamic value) => value?.toString() ?? '';
}
