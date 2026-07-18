import 'package:eClassify/data/model/news/news_model.dart';
import 'package:eClassify/data/repositories/news_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class FetchNewsDetailsState {}

class FetchNewsDetailsInProgress extends FetchNewsDetailsState {}

class FetchNewsDetailsSuccess extends FetchNewsDetailsState {
  FetchNewsDetailsSuccess(this.news);

  final NewsModel news;
}

class FetchNewsDetailsFailure extends FetchNewsDetailsState {
  FetchNewsDetailsFailure(this.message);

  final String message;
}

class FetchNewsDetailsCubit extends Cubit<FetchNewsDetailsState> {
  FetchNewsDetailsCubit({NewsRepository? repository})
    : _repository = repository ?? NewsRepository(),
      super(FetchNewsDetailsInProgress());

  final NewsRepository _repository;

  Future<void> fetch(NewsModel news) async {
    emit(FetchNewsDetailsInProgress());
    try {
      emit(
        FetchNewsDetailsSuccess(
          await _repository.fetchNewsDetails(newsId: news.id),
        ),
      );
    } catch (error) {
      emit(FetchNewsDetailsFailure(error.toString()));
    }
  }
}
