import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/json_helper.dart';

class CategoryRepository {
  Future<DataOutput<CategoryModel>> fetchCategories({
    required int page,
    int? categoryId,
    bool? isForListing,
  }) async {
    try {
      Map<String, dynamic> parameters = {Api.page: page};

      if (categoryId != null) {
        parameters[Api.categoryId] = categoryId;
      }

      if (isForListing == true) {
        parameters['listing'] = 1;
      }
      Map<String, dynamic> response = await Api.get(
        url: Api.getCategoriesApi,
        queryParameters: parameters,
      );

      List<CategoryModel> modelList = JsonHelper.parseList(
        response['data']['data'] as List?,
        CategoryModel.fromJson,
      );

      return DataOutput(
        total: response['data']['total'] ?? 0,
        modelList: modelList,
      );
    } catch (e) {
      rethrow;
    }
  }
}
