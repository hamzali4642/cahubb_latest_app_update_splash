import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';

class ServicePackagesRepository {
  static final Map<String, List<ServicePackageModel>> _memoryCache = {};
  static final Set<String> _activePrefetchTypes = {};

  Future<List<ServicePackageModel>> fetchPackages({
    required String type,
  }) async {
    try {
      final response = await Api.get(
        url: Api.getServicePackagesApi,
        queryParameters: {Api.type: type},
      );

      return (response['data'] as List? ?? const []).map((package) {
        return ServicePackageModel.fromJson(
          Map<String, dynamic>.from(package as Map),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  List<ServicePackageModel>? getCachedPackages({required String type}) {
    final memoryPackages = _memoryCache[type];
    if (memoryPackages != null && memoryPackages.isNotEmpty) {
      return List<ServicePackageModel>.from(memoryPackages);
    }

    final persistedPackages = HiveUtils.getCachedServicePackages(type);
    if (persistedPackages == null) return null;

    _memoryCache[type] = List<ServicePackageModel>.from(persistedPackages);
    return List<ServicePackageModel>.from(persistedPackages);
  }

  Future<List<ServicePackageModel>> fetchAndCachePackages({
    required String type,
  }) async {
    final packages = await fetchPackages(type: type);
    await _storePackages(type: type, packages: packages);
    return packages;
  }

  Future<void> prefetchPackages({required String type}) async {
    if (_activePrefetchTypes.contains(type)) return;

    _activePrefetchTypes.add(type);
    try {
      await fetchAndCachePackages(type: type);
    } finally {
      _activePrefetchTypes.remove(type);
    }
  }

  Future<void> _storePackages({
    required String type,
    required List<ServicePackageModel> packages,
  }) async {
    _memoryCache[type] = List<ServicePackageModel>.from(packages);
    await HiveUtils.setCachedServicePackages(type, packages);
  }
}
