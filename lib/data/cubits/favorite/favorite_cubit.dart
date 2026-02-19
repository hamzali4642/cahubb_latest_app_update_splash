import 'dart:math' as math;

import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/favourites_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FavoriteState {}

class FavoriteInitial extends FavoriteState {}

class FavoriteFetchInProgress extends FavoriteState {}

class FavoriteFetchSuccess extends FavoriteState {
  final List<ItemModel> favorite;
  final bool isLoadingMore;
  final int totalFavoriteCount;
  final bool hasMoreFetchError;
  final bool hasMore;
  final int page;

  FavoriteFetchSuccess({
    required this.favorite,
    required this.isLoadingMore,
    required this.totalFavoriteCount,
    required this.hasMoreFetchError,
    required this.page,
    required this.hasMore,
  });

  FavoriteFetchSuccess copyWith({
    List<ItemModel>? favorite,
    bool? isLoadingMore,
    int? totalFavoriteCount,
    bool? hasMoreFetchError,
    bool? hasMore,
    int? page,
  }) {
    return FavoriteFetchSuccess(
      favorite: favorite ?? this.favorite,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      hasMoreFetchError: hasMoreFetchError ?? this.hasMoreFetchError,
      totalFavoriteCount: totalFavoriteCount ?? this.totalFavoriteCount,
    );
  }
}

class FavoriteFetchFailure extends FavoriteState {
  final String errorMessage;

  FavoriteFetchFailure(this.errorMessage);
}

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository favoriteRepository;

  FavoriteCubit(this.favoriteRepository) : super(FavoriteInitial());

  void getFavorite() async {
    try {
      emit(FavoriteFetchInProgress());
      final result = await favoriteRepository.fetchFavorites(page: 1);
      emit(
        FavoriteFetchSuccess(
          favorite: result.modelList,
          totalFavoriteCount: result.total,
          hasMoreFetchError: false,
          page: 1,
          isLoadingMore: false,
          hasMore: (result.modelList.length < result.total),
        ),
      );
    } catch (e) {
      if (e.toString() == "No Data Found") {
        //incase of 0 Favorite length - make it success for fresh users
        emit(
          FavoriteFetchSuccess(
            favorite: [],
            isLoadingMore: false,
            totalFavoriteCount: 0,
            page: 1,
            hasMoreFetchError: false,
            hasMore: false,
          ),
        );
      } else {
        emit(FavoriteFetchFailure(e.toString()));
      }
    }
  }

  bool hasMoreFavorite() {
    return (state is FavoriteFetchSuccess)
        ? (state as FavoriteFetchSuccess).hasMore
        : false;
  }

  void getMoreFavorite() async {
    if (state is FavoriteFetchSuccess) {
      try {
        if ((state as FavoriteFetchSuccess).isLoadingMore) {
          return;
        }
        emit((state as FavoriteFetchSuccess).copyWith(isLoadingMore: true));
        final result = await favoriteRepository.fetchFavorites(
          page: (state as FavoriteFetchSuccess).page + 1,
        );
        List<ItemModel> updatedResults =
            (state as FavoriteFetchSuccess).favorite;
        updatedResults.addAll(result.modelList);
        emit(
          FavoriteFetchSuccess(
            isLoadingMore: false,
            favorite: updatedResults,
            totalFavoriteCount: result.total,
            hasMoreFetchError: false,
            page: (state as FavoriteFetchSuccess).page + 1,
            hasMore: updatedResults.length < result.total,
          ),
        );
      } catch (e) {
        emit(
          FavoriteFetchSuccess(
            isLoadingMore: false,
            favorite: (state as FavoriteFetchSuccess).favorite,
            hasMoreFetchError: (e.toString() == "No Data Found") ? false : true,
            page: (state as FavoriteFetchSuccess).page + 1,
            totalFavoriteCount:
                (state as FavoriteFetchSuccess).totalFavoriteCount,
            hasMore: (state as FavoriteFetchSuccess).hasMore,
          ),
        );
      }
    }
  }

  void addFavoriteitem(ItemModel model) {
    final currentState = state;
    final favoriteList = currentState is FavoriteFetchSuccess
        ? List<ItemModel>.from(currentState.favorite)
        : <ItemModel>[];

    final existingIndex = favoriteList.indexWhere(
      (item) => item.id == model.id,
    );

    if (existingIndex == -1) {
      model.totalLikes = (model.totalLikes ?? 0) + 1;
      favoriteList.insert(0, model);
    } else {
      favoriteList[existingIndex] = model;
    }

    emit(
      FavoriteFetchSuccess(
        isLoadingMore: false,
        favorite: favoriteList,
        hasMoreFetchError: false,
        page: currentState is FavoriteFetchSuccess ? currentState.page : 1,
        totalFavoriteCount: currentState is FavoriteFetchSuccess
            ? math.max(currentState.totalFavoriteCount, favoriteList.length)
            : favoriteList.length,
        hasMore: currentState is FavoriteFetchSuccess
            ? currentState.hasMore
            : false,
      ),
    );
  }

  void removeFavoriteItem(ItemModel model) {
    if (state is FavoriteFetchSuccess) {
      final currentState = state as FavoriteFetchSuccess;
      final favorite = List<ItemModel>.from(currentState.favorite);

      // Find the index of the item to be removed
      int indexToRemove = favorite.indexWhere(
        (element) => element.id == model.id,
      );
      if (indexToRemove != -1) {
        // Decrement totalLikes of the item being removed
        ItemModel removedItem = favorite[indexToRemove];
        removedItem.totalLikes = math.max(0, (removedItem.totalLikes ?? 0) - 1);
        favorite.removeAt(indexToRemove);

        emit(
          FavoriteFetchSuccess(
            isLoadingMore: false,
            favorite: favorite,
            hasMoreFetchError: false,
            page: currentState.page,
            totalFavoriteCount: math.max(
              0,
              currentState.totalFavoriteCount - 1,
            ),
            hasMore: currentState.hasMore,
          ),
        );
      }
    }
  }

  bool isItemFavorite(int itemId) {
    if (state is FavoriteFetchSuccess) {
      final favorite = (state as FavoriteFetchSuccess).favorite;
      return (favorite.isNotEmpty)
          ? (favorite.indexWhere((element) => (element.id == itemId)) != -1)
          : false;
    }
    return false;
  }

  void resetState() {
    emit(FavoriteFetchInProgress());
  }
}
