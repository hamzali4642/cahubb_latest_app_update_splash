// ignore_for_file: file_names

import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/favourites_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UpdateFavoriteState {
  const UpdateFavoriteState({required this.itemId});

  final int itemId;
}

class UpdateFavoriteInitial extends UpdateFavoriteState {
  UpdateFavoriteInitial() : super(itemId: 0);
}

class UpdateFavoriteInProgress extends UpdateFavoriteState {
  UpdateFavoriteInProgress({required super.itemId});
}

class UpdateFavoriteSuccess extends UpdateFavoriteState {
  UpdateFavoriteSuccess(this.item, this.wasProcess) : super(itemId: item.id!);
  final ItemModel item;
  final bool wasProcess; //to check that process of Favorite done or not
}

class UpdateFavoriteFailure extends UpdateFavoriteState {
  UpdateFavoriteFailure(this.errorMessage, {required super.itemId});

  final String errorMessage;
}

class UpdateFavoriteCubit extends Cubit<UpdateFavoriteState> {
  final FavoriteRepository favoriteRepository;

  UpdateFavoriteCubit(this.favoriteRepository) : super(UpdateFavoriteInitial());

  void setFavoriteItem({required ItemModel item, required int type}) {
    emit(UpdateFavoriteInProgress(itemId: item.id!));
    favoriteRepository
        .manageFavorites(item.id!)
        .then((value) {
          emit(UpdateFavoriteSuccess(item, type == 1 ? true : false));
        })
        .catchError((e) {
          emit(UpdateFavoriteFailure(e.toString(), itemId: item.id!));
        });
  }
}
