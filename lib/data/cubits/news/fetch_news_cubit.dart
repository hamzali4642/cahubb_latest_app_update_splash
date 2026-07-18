import 'package:eClassify/data/model/news/news_model.dart';
import 'package:eClassify/data/repositories/news_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class FetchNewsState {}

class FetchNewsInitial extends FetchNewsState {}

class FetchNewsInProgress extends FetchNewsState {}

class FetchNewsSuccess extends FetchNewsState {
  FetchNewsSuccess({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  final List<NewsModel> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreError;

  FetchNewsSuccess copyWith({
    List<NewsModel>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return FetchNewsSuccess(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

class FetchNewsFailure extends FetchNewsState {
  FetchNewsFailure(this.message);

  final String message;
}

class FetchNewsCubit extends Cubit<FetchNewsState> {
  FetchNewsCubit({NewsRepository? repository})
    : _repository = repository ?? NewsRepository(),
      super(FetchNewsInitial());

  final NewsRepository _repository;
  int? _cityId;

  Future<void> fetch({int? cityId}) async {
    _cityId = cityId;
    emit(FetchNewsInProgress());
    try {
      final page = await _repository.fetchNews(page: 1, cityId: cityId);
      emit(
        FetchNewsSuccess(
          items: page.items,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        ),
      );
    } catch (error) {
      emit(FetchNewsFailure(error.toString()));
    }
  }

  Future<void> fetchMore() async {
    final current = state;
    if (current is! FetchNewsSuccess ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true, loadMoreError: false));
    try {
      final page = await _repository.fetchNews(
        page: current.currentPage + 1,
        cityId: _cityId,
      );
      emit(
        current.copyWith(
          items: [...current.items, ...page.items],
          currentPage: page.currentPage,
          hasMore: page.items.isNotEmpty && page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false, loadMoreError: true));
    }
  }
}
