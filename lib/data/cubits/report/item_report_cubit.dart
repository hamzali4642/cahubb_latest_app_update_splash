import 'package:eClassify/data/repositories/item_report/report_item_repository.dart';
import 'package:eClassify/utils/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SubmitItemReportState {}

class SubmitItemReportInitial extends SubmitItemReportState {}

class SubmitItemReportLoading extends SubmitItemReportState {}

class SubmitItemReportSuccess extends SubmitItemReportState {
  SubmitItemReportSuccess({required this.message});

  final String message;
}

class SubmitItemReportFailure extends SubmitItemReportState {
  SubmitItemReportFailure({required this.message});

  final String message;
}

class SubmitItemReportCubit extends Cubit<SubmitItemReportState> {
  SubmitItemReportCubit() : super(SubmitItemReportInitial());

  void report({required int itemId, int? reasonId, String? message}) async {
    try {
      emit(SubmitItemReportLoading());

      final response = await ReportItemRepository().reportItem(
        itemId: itemId,
        reasonId: reasonId,
        message: message,
      );

      emit(SubmitItemReportSuccess(message: response['message']));
    } catch (e, st) {
      Log.error(e.toString(), e, st);
      emit(SubmitItemReportFailure(message: e.toString()));
    }
  }
}
