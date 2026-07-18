import 'package:eClassify/utils/app_session.dart';

class NewsModel {
  const NewsModel({
    required this.id,
    required this.cityId,
    required this.coverImage,
    required this.englishHtml,
    required this.urduHtml,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.city,
  });

  final int id;
  final int cityId;
  final String coverImage;
  final String englishHtml;
  final String urduHtml;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final NewsCityModel? city;

  bool get isUrdu => AppSession.currentLanguageCode.toLowerCase() == 'ur';

  String get localizedHtml {
    if (isUrdu && urduHtml.trim().isNotEmpty) return urduHtml;
    return englishHtml;
  }

  String get previewTitle {
    final html = localizedHtml;
    final heading = RegExp(
      r'<(?:h1|h2|h3|title)[^>]*>(.*?)</(?:h1|h2|h3|title)>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (heading != null) return _plainText(heading.group(1) ?? '');

    final paragraph = RegExp(
      r'<p[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (paragraph != null) return _plainText(paragraph.group(1) ?? '');

    return _plainText(html);
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final cityJson = json['city'];
    return NewsModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      cityId: int.tryParse(json['city_id']?.toString() ?? '') ?? 0,
      coverImage: json['cover_image']?.toString() ?? '',
      englishHtml: json['english_html']?.toString() ?? '',
      urduHtml: json['urdu_html']?.toString() ?? '',
      createdBy: int.tryParse(json['created_by']?.toString() ?? ''),
      updatedBy: int.tryParse(json['updated_by']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      city: cityJson is Map
          ? NewsCityModel.fromJson(Map<String, dynamic>.from(cityJson))
          : null,
    );
  }

  static String _plainText(String html) {
    return html
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'<style[^>]*>.*?</style>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class NewsCityModel {
  const NewsCityModel({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.stateId,
    required this.countryId,
  });

  final int id;
  final String name;
  final String? translatedName;
  final int? stateId;
  final int? countryId;

  String get localizedName {
    if (AppSession.currentLanguageCode.toLowerCase() != 'en' &&
        translatedName?.trim().isNotEmpty == true) {
      return translatedName!;
    }
    return name;
  }

  factory NewsCityModel.fromJson(Map<String, dynamic> json) {
    return NewsCityModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      translatedName: json['translated_name']?.toString(),
      stateId: int.tryParse(json['state_id']?.toString() ?? ''),
      countryId: int.tryParse(json['country_id']?.toString() ?? ''),
    );
  }
}

class NewsPageModel {
  const NewsPageModel({
    required this.currentPage,
    required this.items,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.nextPageUrl,
    required this.previousPageUrl,
  });

  final int currentPage;
  final List<NewsModel> items;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? previousPageUrl;

  bool get hasMore =>
      items.isNotEmpty && currentPage < lastPage && nextPageUrl != null;

  factory NewsPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    return NewsPageModel(
      currentPage: int.tryParse(json['current_page']?.toString() ?? '') ?? 1,
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => NewsModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      lastPage: int.tryParse(json['last_page']?.toString() ?? '') ?? 1,
      perPage: int.tryParse(json['per_page']?.toString() ?? '') ?? 10,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      nextPageUrl: json['next_page_url']?.toString(),
      previousPageUrl: json['prev_page_url']?.toString(),
    );
  }
}
