import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/fetch_notification_detail_cubit.dart';
import 'package:eClassify/data/model/notification_model.dart';
import 'package:eClassify/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationDetail extends StatefulWidget {
  final NotificationData? notificationData;
  final String? notificationId;

  const NotificationDetail({
    super.key,
    this.notificationData,
    this.notificationId,
  }) : assert(
         notificationData != null || notificationId != null,
         'Either notificationData or notificationId must be provided',
       );

  @override
  State<NotificationDetail> createState() => _NotificationDetailState();

  static Route route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => FetchNotificationDetailCubit(),
        child: NotificationDetail(
          notificationData: args?['notificationData'] as NotificationData?,
          notificationId: args?['notificationId'] as String?,
        ),
      ),
    );
  }
}

class _NotificationDetailState extends State<NotificationDetail> {
  @override
  void initState() {
    super.initState();
    if (widget.notificationData != null) {
      context.read<FetchNotificationDetailCubit>().setNotificationData(
        widget.notificationData!,
      );
    } else if (widget.notificationId != null) {
      context.read<FetchNotificationDetailCubit>().fetchNotificationDetail(
        id: widget.notificationId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        title: "notifications".translate(context),
        showBackButton: true,
      ),
      body:
          BlocBuilder<
            FetchNotificationDetailCubit,
            FetchNotificationDetailState
          >(
            builder: (context, state) {
              if (state is FetchNotificationDetailInProgress) {
                return _buildShimmer();
              }

              if (state is FetchNotificationDetailFailure) {
                if (state.errorMessage == "no-internet") {
                  return NoInternet(
                    onRetry: () {
                      if (widget.notificationId != null) {
                        context
                            .read<FetchNotificationDetailCubit>()
                            .fetchNotificationDetail(
                              id: widget.notificationId!,
                            );
                      }
                    },
                  );
                }
                return const SomethingWentWrong();
              }

              if (state is FetchNotificationDetailSuccess) {
                return _buildContent(state.notificationData);
              }

              return const SizedBox.shrink();
            },
          ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
      children: <Widget>[
        CustomShimmer(width: double.infinity, height: 200, borderRadius: 10),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CustomShimmer(width: 250, height: 20, borderRadius: 5),
              const SizedBox(height: 10),
              CustomShimmer(
                width: double.infinity,
                height: 15,
                borderRadius: 5,
              ),
              const SizedBox(height: 5),
              CustomShimmer(width: 200, height: 15, borderRadius: 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(NotificationData notification) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 13.0),
      children: <Widget>[
        if (notification.image != null && notification.image!.isNotEmpty)
          CustomImage(src: notification.image!, fit: BoxFit.cover),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: _detailWidget(notification),
        ),
      ],
    );
  }

  Column _detailWidget(NotificationData notification) {
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          notification.title ?? '',
          style: Theme.of(context).textTheme.titleMedium!.merge(
            const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          notification.message ?? '',
          style: Theme.of(context).textTheme.bodySmall!,
        ),
        if (notification.item != null)
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                Routes.adDetailsScreen,
                arguments: {'slug': notification.item!.slug},
              );
            },
            child: ItemHorizontalCard(
              item: notification.item!,
              showLikeButton: false,
            ),
          ),
      ],
    );
  }
}
