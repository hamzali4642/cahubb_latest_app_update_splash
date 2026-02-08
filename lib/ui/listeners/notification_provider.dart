import 'dart:developer';

import 'package:eClassify/data/cubits/notification/notification_event_cubit.dart';
import 'package:eClassify/utils/log.dart';
import 'package:eClassify/utils/notification/notification_handler.dart';
import 'package:eClassify/utils/notification/notification_utility.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationProvider extends StatelessWidget {
  const NotificationProvider({required this.child, super.key});

  final Widget child;

  void _handleNotificationTap(
    BuildContext context,
    Map<String, String?> payload,
  ) {
    NotificationUtility.onTapNotification(context, payload);
  }

  Future<void> _maybeHandleSideEffects(
    BuildContext context, {
    required NotificationMode? mode,
    required RemoteMessage? message,
  }) async {
    if (mode == null ||
        message == null ||
        mode == NotificationMode.terminated) {
      return;
    }
    final notificationType = NotificationUtility.getNotificationType(
      message.data['type'] as String? ?? '',
    );
    if (notificationType == null) return;

    NotificationHandler.handleSideEffects(
      context,
      notificationType,
      message.data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationEventCubit(),
      child: Builder(
        builder: (context) {
          return BlocListener<NotificationEventCubit, NotificationEventState>(
            listener: (context, state) async {
              if (state.remoteMessage != null) {
                Log.info(
                  '${state.remoteMessage?.notification.toString()} ${state.remoteMessage?.data.toString()}',
                );
              }
              await _maybeHandleSideEffects(
                context,
                mode: state.mode,
                message: state.remoteMessage,
              );
              if (context.mounted) {
                if (state is BackgroundNotificationReceived) {
                  final data = Map<String, String?>.from(
                    state.remoteMessage!.data,
                  );
                  _handleNotificationTap(context, data);
                } else if (state is ForegroundNotificationReceived) {
                  log(
                    '${state.remoteMessage?.data}',
                    name: 'Foreground Notification',
                  );
                  NotificationUtility.createLocalNotification(
                    state.remoteMessage!,
                  );
                } else if (state is ForegroundNotificationActionReceived) {
                  _handleNotificationTap(context, state.payload);
                }
              }
            },
            child: child,
          );
        },
      ),
    );
  }
}
