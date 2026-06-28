import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:eClassify/data/repositories/service_packages_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchServicePackagesState {}

class FetchServicePackagesInitial extends FetchServicePackagesState {}

class FetchServicePackagesInProgress extends FetchServicePackagesState {}

class FetchServicePackagesSuccess extends FetchServicePackagesState {
  final List<ServicePackageModel> packages;
  final bool isRefreshing;
  final bool isFromCache;

  FetchServicePackagesSuccess({
    required this.packages,
    this.isRefreshing = false,
    this.isFromCache = false,
  });
}

class FetchServicePackagesFailure extends FetchServicePackagesState {
  final String errorMessage;

  FetchServicePackagesFailure(this.errorMessage);
}

class FetchServicePackagesCubit extends Cubit<FetchServicePackagesState> {
  FetchServicePackagesCubit() : super(FetchServicePackagesInitial());

  final ServicePackagesRepository _repository = ServicePackagesRepository();

  void seedCachedPackages(List<ServicePackageModel> packages) {
    emit(
      FetchServicePackagesSuccess(
        packages: packages,
        isRefreshing: true,
        isFromCache: true,
      ),
    );
  }

  Future<void> fetchPackages({
    required String type,
    bool forceRefresh = false,
  }) async {
    try {
      final cachedPackages = forceRefresh
          ? null
          : _repository.getCachedPackages(type: type);

      if (cachedPackages != null && cachedPackages.isNotEmpty) {
        emit(
          FetchServicePackagesSuccess(
            packages: cachedPackages,
            isRefreshing: true,
            isFromCache: true,
          ),
        );
      } else {
        emit(FetchServicePackagesInProgress());
      }

      final packages = await _repository.fetchAndCachePackages(type: type);
      emit(FetchServicePackagesSuccess(packages: packages));
    } catch (e) {
      if (state is FetchServicePackagesSuccess) {
        emit(
          FetchServicePackagesSuccess(
            packages: (state as FetchServicePackagesSuccess).packages,
            isRefreshing: false,
            isFromCache: true,
          ),
        );
        return;
      }
      emit(FetchServicePackagesFailure(e.toString()));
    }
  }
}
