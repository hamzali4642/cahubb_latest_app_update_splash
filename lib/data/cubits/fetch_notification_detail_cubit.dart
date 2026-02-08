import 'package:eClassify/data/model/notification_model.dart';
import 'package:eClassify/data/repositories/notifications_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchNotificationDetailState {}

class FetchNotificationDetailInitial extends FetchNotificationDetailState {}

class FetchNotificationDetailInProgress extends FetchNotificationDetailState {}

class FetchNotificationDetailSuccess extends FetchNotificationDetailState {
  final NotificationData notificationData;

  FetchNotificationDetailSuccess({required this.notificationData});
}

class FetchNotificationDetailFailure extends FetchNotificationDetailState {
  final String errorMessage;

  FetchNotificationDetailFailure(this.errorMessage);
}

class FetchNotificationDetailCubit extends Cubit<FetchNotificationDetailState> {
  FetchNotificationDetailCubit() : super(FetchNotificationDetailInitial());

  final NotificationsRepository _notificationsRepository =
      NotificationsRepository();

  Future<void> fetchNotificationDetail({required String id}) async {
    try {
      emit(FetchNotificationDetailInProgress());

      NotificationData result = await _notificationsRepository
          .fetchNotificationById(id: id);

      emit(FetchNotificationDetailSuccess(notificationData: result));
    } catch (e) {
      emit(FetchNotificationDetailFailure(e.toString()));
    }
  }

  void setNotificationData(NotificationData notificationData) {
    emit(FetchNotificationDetailSuccess(notificationData: notificationData));
  }
}
