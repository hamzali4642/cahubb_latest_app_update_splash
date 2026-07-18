import 'package:eClassify/data/model/news/news_model.dart';
import 'package:eClassify/utils/api.dart';

class NewsRepository {
  Future<NewsPageModel> fetchNews({required int page, int? cityId}) async {
    final response = await Api.get(
      url: Api.newsApi,
      queryParameters: {'page': page, if (cityId != null) 'city_id': cityId},
    );
    _validateResponse(response);

    final data = response['data'];
    if (data is! Map) throw ApiException('Failed to fetch news');
    return NewsPageModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<NewsModel> fetchNewsDetails({required int newsId}) async {
    final response = await Api.get(
      url: Api.newsApi,
      queryParameters: {'news_id': newsId},
    );
    _validateResponse(response);

    final data = response['data'];
    if (data is! Map) throw ApiException('Failed to fetch news');
    return NewsModel.fromJson(Map<String, dynamic>.from(data));
  }

  void _validateResponse(Map<String, dynamic> response) {
    final code = int.tryParse(response['code']?.toString() ?? '');
    if (response['error'] == true || (code != null && code != 200)) {
      throw ApiException(
        response['message']?.toString() ?? 'Failed to fetch news',
      );
    }
  }
}
