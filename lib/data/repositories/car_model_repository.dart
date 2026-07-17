import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/json_helper.dart';

class CarModelRepository {
  Future<List<CarModelModel>> fetchCarModels({
    String? search,
    String? brandName,
    String? sortBy,
    String? sortOrder,
  }) async {
    final response = await Api.get(
      url: Api.getCarModelsApi,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty)
          Api.search: search.trim(),
        if (brandName != null && brandName.trim().isNotEmpty)
          Api.brandName: brandName.trim(),
        if (sortBy != null && sortBy.trim().isNotEmpty)
          Api.sortBy: sortBy.trim(),
        if (sortOrder != null && sortOrder.trim().isNotEmpty)
          Api.sortOrder: sortOrder.trim(),
      },
    );

    return JsonHelper.parseList(
      response['data'] as List?,
      CarModelModel.fromJson,
    );
  }
}
