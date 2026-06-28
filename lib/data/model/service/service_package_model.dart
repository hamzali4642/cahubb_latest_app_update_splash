class ServicePackageModel {
  final int id;
  final String name;
  final List<String> features;
  final String? icon;
  final String price;
  final String type;
  final String typeLabel;

  const ServicePackageModel({
    required this.id,
    required this.name,
    required this.features,
    required this.icon,
    required this.price,
    required this.type,
    required this.typeLabel,
  });

  factory ServicePackageModel.fromJson(Map<String, dynamic> json) {
    return ServicePackageModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      features: (json['features'] as List? ?? const [])
          .map((feature) => feature.toString())
          .where((feature) => feature.isNotEmpty)
          .toList(),
      icon: json['icon']?.toString(),
      price: json['price']?.toString() ?? '0',
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'features': features,
      'icon': icon,
      'price': price,
      'type': type,
      'type_label': typeLabel,
    };
  }
}
