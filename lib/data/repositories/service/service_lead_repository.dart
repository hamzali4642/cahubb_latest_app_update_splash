import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/repositories/car_model_repository.dart';
import 'package:eClassify/data/repositories/location/location_repository.dart';

class ServiceLeadRepository {
  final CarModelRepository _carModelRepository = CarModelRepository();
  final LocationRepository _locationRepository = LocationRepository();

  static List<CategoryModel>? _cachedCarBrands;
  static List<CarModelModel>? _cachedCarModels;
  static List<City>? _cachedCities;

  Future<List<CategoryModel>> fetchCarBrands({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedCarBrands != null &&
        _cachedCarBrands!.isNotEmpty) {
      return _cachedCarBrands!;
    }

    final carModels = await fetchCarModels(forceRefresh: forceRefresh);
    final uniqueBrandNames =
        carModels
            .map((model) => model.brandName.trim())
            .where((brandName) => brandName.isNotEmpty)
            .toSet()
            .toList()
          ..sort((left, right) => left.compareTo(right));

    final brands = uniqueBrandNames.asMap().entries.map((entry) {
      return CategoryModel(id: entry.key + 1, name: entry.value);
    }).toList();

    _cachedCarBrands = List.unmodifiable(brands);
    return _cachedCarBrands!;
  }

  Future<List<CarModelModel>> fetchCarModels({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedCarModels != null &&
        _cachedCarModels!.isNotEmpty) {
      return _cachedCarModels!;
    }

    final carModels = await _carModelRepository.fetchCarModels();
    carModels.sort((left, right) {
      final brandCompare = left.brandName.compareTo(right.brandName);
      if (brandCompare != 0) return brandCompare;
      return left.name.compareTo(right.name);
    });

    _cachedCarModels = List.unmodifiable(carModels);
    return _cachedCarModels!;
  }

  Future<List<City>> fetchCities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCities != null && _cachedCities!.isNotEmpty) {
      return _cachedCities!;
    }

    final cities = <City>[];
    var page = 1;
    var total = 1;

    while (cities.length < total) {
      final response = await _locationRepository.fetchCities(page: page);
      cities.addAll(response.modelList);
      total = response.total;
      page += 1;

      if (response.modelList.isEmpty) break;
    }

    cities.sort(
      (left, right) => left.name.localized.compareTo(right.name.localized),
    );

    _cachedCities = List.unmodifiable(cities);
    return _cachedCities!;
  }
}
