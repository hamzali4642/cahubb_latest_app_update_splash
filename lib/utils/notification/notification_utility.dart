import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart'
    hide NotificationHandler;
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/notification/notification_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

typedef NotificationActionCallback =
    void Function(Map<String, String?> payload);

enum NotificationType {
  notification,
  itemUpdate,
  itemEdit,
  chat,
  offer,
  payment,
  jobApplication,
  applicationStatus,
  itemReview,
  verificationStatus,
}

class NotificationUtility {
  static final _basicChannel = 'basic_channel';
  static final _chatChannel = 'chat_channel';

  static final AwesomeNotifications _awesomeInstance = AwesomeNotifications();

  static final Map<String, NotificationType> _notificationTypeMap = {
    'notification': NotificationType.notification,
    'item-update': NotificationType.itemUpdate,
    'item-edit': NotificationType.itemEdit,
    'chat': NotificationType.chat,
    'offer': NotificationType.offer,
    'payment': NotificationType.payment,
    'job-application': NotificationType.jobApplication,
    'application-status': NotificationType.applicationStatus,
    'item-review': NotificationType.itemReview,
    'verifcation-request-update': NotificationType.verificationStatus,
  };

  static Map<String, dynamic>? _pendingNotificationPayload;

  static bool get hasPendingNotification => _pendingNotificationPayload != null;

  static NotificationType? getNotificationType(String type) {
    final normalizedType = type.toLowerCase().replaceAll(
      RegExp('[^A-Za-z0-9]+'),
      '-',
    );
    final notificationType = _notificationTypeMap[normalizedType];
    assert(notificationType != null, 'Cannot find suitable notification type');
    return notificationType;
  }

  static Future<bool> _askNotificationPermission() async {
    final notificationSettings = await FirebaseMessaging.instance
        .requestPermission();
    return notificationSettings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        notificationSettings.authorizationStatus ==
            AuthorizationStatus.provisional;
  }

  static Future<bool> initializeNotificationService({
    required NotificationActionCallback onForegroundNotificationTap,
  }) async {
    final notificationSettings = await FirebaseMessaging.instance
        .getNotificationSettings();

    //check if the permission is given. If not, ask for the permission.
    //If still not granted, do not initialize anything related to notification
    final permissionGiven = switch (notificationSettings.authorizationStatus) {
      AuthorizationStatus.authorized => true,
      AuthorizationStatus.provisional => true,
      AuthorizationStatus.denied => await _askNotificationPermission(),
      AuthorizationStatus.notDetermined => await _askNotificationPermission(),
    };

    if (permissionGiven) {
      await _initializeAwesomeNotification(
        onForegroundNotificationTap: onForegroundNotificationTap,
      );
    }
    return permissionGiven;
  }

  static Future<void> _initializeAwesomeNotification({
    required NotificationActionCallback onForegroundNotificationTap,
  }) async {
    final hasInitialized = await _awesomeInstance.initialize(
      'resource://mipmap/notification',
      [
        NotificationChannel(
          channelKey: _basicChannel,
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel',
          importance: NotificationImportance.Max,
        ),
        NotificationChannel(
          channelKey: _chatChannel,
          channelName: 'Chat Notifications',
          channelDescription: 'Chat Notifications',
          importance: NotificationImportance.Max,
        ),
      ],
      channelGroups: [],
      debug: true,
    );
    if (!hasInitialized) {
      log('Awesome notifications was not initialized', name: 'NOTIFICATION');
      return;
    }

    _awesomeInstance.setListeners(
      onActionReceivedMethod: (receivedAction) async {
        if (receivedAction.payload != null) {
          onForegroundNotificationTap.call(receivedAction.payload!);
        }
      },
    );
  }

  static void createLocalNotification(RemoteMessage message) {
    if (Platform.isIOS) return;
    log('${message.data}', name: 'MESSAGE RECEIVED');

    final notificationType = getNotificationType(
      message.data['type'] as String? ?? '',
    );

    final channel = notificationType == NotificationType.chat
        ? _chatChannel
        : _basicChannel;

    _awesomeInstance.createNotification(
      content: NotificationContent(
        id: DateTime.now().microsecondsSinceEpoch % 0x7FFFFFFF,
        channelKey: channel,
        title: message.notification?.title,
        body: message.notification?.body,
        color: territoryColor_,
        groupKey: message.data['item_id'],
        bigPicture: message.data['image'] as String?,
        notificationLayout: message.data['image'] != null
            ? NotificationLayout.BigPicture
            : NotificationLayout.MessagingGroup,
        payload: Map<String, String>.from(message.data),
      ),
    );
  }

  static void onTapNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) {
    final notificationType = getNotificationType(
      payload['type'] as String? ?? '',
    );
    if (notificationType == null) return;

    NotificationHandler.handleNotification(context, notificationType, payload);
  }
}
