class StartupAdModel {
  const StartupAdModel({
    required this.id,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    this.name,
    this.destinationUrl,
    this.type,
  });

  factory StartupAdModel.fromJson(Map<String, dynamic> json) {
    return StartupAdModel(
      id: (json['id'] as num?)?.toInt(),
      name: _optionalString(json['name']),
      imageUrl: json['image']?.toString().trim() ?? '',
      destinationUrl: _optionalString(json['url']),
      type: _optionalString(json['type']),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  final int? id;
  final String? name;
  final String imageUrl;
  final String? destinationUrl;
  final String? type;
  final bool isActive;
  final DateTime? createdAt;

  Uri? get destinationUri {
    final uri = Uri.tryParse(destinationUrl ?? '');
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
