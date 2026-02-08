import 'dart:developer';

import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/notification_model.dart';
import 'package:eClassify/utils/api.dart';

class NotificationsRepository {
  Future<DataOutput<NotificationData>> fetchNotifications(
      {required int page}) async {
    try {
      Map<String, dynamic> parameters = {
        Api.page: page,
      };
      Map<String, dynamic> response = await Api.get(
          url: Api.getNotificationListApi, queryParameters: parameters);

      List<NotificationData> modelList = (response['data']['data'] as List).map(
        (e) {
          return NotificationData.fromJson(e);
        },
      ).toList();

      return DataOutput(total: response['data']['total'], modelList: modelList);
    } catch (e, stack) {
      log(e.toString());
      log('$stack');
      rethrow;
    }
  }

  Future<NotificationData> fetchNotificationById({required String id}) async {
    try {
      Map<String, dynamic> parameters = {
        Api.id: id,
      };
      Map<String, dynamic> response = await Api.get(
          url: Api.getNotificationListApi, queryParameters: parameters);

      return NotificationData.fromJson(response['data']);
    } catch (e, stack) {
      log(e.toString());
      log('$stack');
      rethrow;
    }
  }
}
