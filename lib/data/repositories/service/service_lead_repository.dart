import 'dart:async';

import 'package:eClassify/data/model/car_model_model.dart';
import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/location/location_node.dart' show City;
import 'package:eClassify/data/repositories/car_model_repository.dart';
import 'package:eClassify/data/repositories/location/location_repository.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ServiceLeadRepository {
  final CarModelRepository _carModelRepository = CarModelRepository();
  final LocationRepository _locationRepository = LocationRepository();

  static List<CategoryModel>? _cachedCarBrands;
  static List<CarModelModel>? _cachedCarModels;
  static List<City>? _cachedCities;
  static Future<List<City>>? _citiesRequest;
  static bool _didHydrateCities = false;
  static const Duration _citiesCacheLifetime = Duration(days: 7);

  static List<City> get cachedCities {
    _hydrateCitiesCache();
    return _cachedCities ?? const [];
  }

  Future<List<City>> preloadCities() async {
    final cities = cachedCities;
    if (cities.isNotEmpty) {
      if (_isCitiesCacheExpired()) {
        unawaited(_refreshCitiesSilently());
      }
      return cities;
    }
    try {
      return await fetchCities();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refreshCitiesSilently() async {
    try {
      await fetchCities(forceRefresh: true);
    } catch (_) {}
  }

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
    final cities = cachedCities;
    if (!forceRefresh && cities.isNotEmpty) return cities;
    if (_citiesRequest != null) return _citiesRequest!;

    final request = _fetchAndCacheCities();
    _citiesRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_citiesRequest, request)) _citiesRequest = null;
    }
  }

  Future<List<City>> _fetchAndCacheCities() async {
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
    await _persistCitiesCache(_cachedCities!);
    return _cachedCities!;
  }

  static void _hydrateCitiesCache() {
    if (_didHydrateCities || !Hive.isBoxOpen(HiveKeys.serviceCacheBox)) return;
    _didHydrateCities = true;
    final stored = Hive.box(
      HiveKeys.serviceCacheBox,
    ).get(HiveKeys.serviceCitiesCache);
    if (stored is! List) return;
    try {
      final cities = stored
          .whereType<Map>()
          .map((json) => City.fromCache(Map<String, dynamic>.from(json)))
          .toList();
      if (cities.isNotEmpty) _cachedCities = List.unmodifiable(cities);
    } catch (_) {
      _cachedCities = null;
    }
  }

  static bool _isCitiesCacheExpired() {
    if (!Hive.isBoxOpen(HiveKeys.serviceCacheBox)) return true;
    final cachedAt = Hive.box(
      HiveKeys.serviceCacheBox,
    ).get(HiveKeys.serviceCitiesCachedAt);
    final timestamp = DateTime.tryParse(cachedAt?.toString() ?? '');
    return timestamp == null ||
        DateTime.now().difference(timestamp) > _citiesCacheLifetime;
  }

  static Future<void> _persistCitiesCache(List<City> cities) async {
    if (!Hive.isBoxOpen(HiveKeys.serviceCacheBox)) return;
    final box = Hive.box(HiveKeys.serviceCacheBox);
    await box.put(
      HiveKeys.serviceCitiesCache,
      cities.map((city) => city.toCacheJson()).toList(),
    );
    await box.put(
      HiveKeys.serviceCitiesCachedAt,
      DateTime.now().toIso8601String(),
    );
  }
}
