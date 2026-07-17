class CarModelModel {
  final int id;
  final String name;
  final String brandName;
  final int? price;
  final String createdAt;
  final int? createdBy;
  final String updatedAt;
  final int? updatedBy;

  const CarModelModel({
    required this.id,
    required this.name,
    required this.brandName,
    required this.price,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory CarModelModel.fromJson(Map<String, dynamic> json) {
    return CarModelModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt(),
      createdAt: json['created_at'] as String? ?? '',
      createdBy: (json['created_by'] as num?)?.toInt(),
      updatedAt: json['updated_at'] as String? ?? '',
      updatedBy: (json['updated_by'] as num?)?.toInt(),
    );
  }
}
