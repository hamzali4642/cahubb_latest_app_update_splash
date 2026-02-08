import 'package:eClassify/data/model/blog_model.dart';
import 'package:eClassify/data/repositories/blogs_repository.dart';
import 'package:eClassify/utils/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BlogDetailsState {}

class BlogDetailsInitial extends BlogDetailsState {}

class BlogDetailsLoading extends BlogDetailsState {}

class BlogDetailsSuccess extends BlogDetailsState {
  BlogDetailsSuccess({required this.blog});

  final BlogModel? blog;
}

class BlogDetailsFailure extends BlogDetailsState {
  BlogDetailsFailure({required this.errorMessage});

  final String errorMessage;
}

class BlogDetailsCubit extends Cubit<BlogDetailsState> {
  BlogDetailsCubit() : super(BlogDetailsInitial());
  final _repo = BlogsRepository();

  Future<void> getBlogDetails({required BlogModel blog}) async {
    try {
      emit(BlogDetailsLoading());

      final result = await _repo.getBlogDetails(blog: blog);

      emit(BlogDetailsSuccess(blog: result));
    } on Exception catch (e, stack) {
      Log.error(e.toString(), e, stack);
      emit(BlogDetailsFailure(errorMessage: e.toString()));
    }
  }
}
