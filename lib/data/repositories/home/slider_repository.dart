import 'dart:developer';

import 'package:eClassify/data/model/home/home_slider.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/json_helper.dart';

class SliderRepository {
  factory SliderRepository() => _instance;

  SliderRepository._internal();

  static final SliderRepository _instance = SliderRepository._internal();

  Future<List<HomeSlider>> fetchSliders({
    required LeafLocation? location,
  }) async {
    try {
      final response = await Api.get(
        url: Api.getSliderApi,
        queryParameters: {
          Api.city: ?location?.city?.canonical,
          Api.state: ?location?.state?.canonical,
          Api.country: ?location?.country?.canonical,
        },
      );
      return JsonHelper.parseList(
        response['data'] as List?,
        HomeSlider.fromJson,
      );
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'fetchSliders');
      log('$stack', name: 'fetchSliders');
      rethrow;
    }
  }
}
