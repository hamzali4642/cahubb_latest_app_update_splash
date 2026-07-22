import 'package:eClassify/data/model/startup_ad_model.dart';
import 'package:eClassify/utils/api.dart';

class StartupAdRepository {
  Future<StartupAdModel?> fetch({String? type}) async {
    final response = await Api.get(
      url: Api.startupAdsApi,
      queryParameters: type == null ? null : {Api.type: type},
    );
    final data = response['data'];
    if (data is! Map) return null;

    final ad = StartupAdModel.fromJson(Map<String, dynamic>.from(data));
    return ad.imageUrl.isEmpty ? null : ad;
  }
}
