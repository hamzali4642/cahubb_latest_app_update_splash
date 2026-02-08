import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/fetch_notifications_cubit.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/notification_model.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/interstitial_ad_on_exit_mixin.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Notifications extends StatefulWidget {
  const Notifications({this.id, super.key});

  final String? id;
  @override
  NotificationsState createState() => NotificationsState();

  static Route route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map?;

    return MaterialPageRoute(
      builder: (_) => Notifications(id: args?['notificationId'] as String?),
    );
  }
}

class NotificationsState extends State<Notifications>
    with InterstitialAdOnExitMixin {
  late final ScrollController _pageScrollController = ScrollController();

  List<ItemModel> itemData = [];

  @override
  void initState() {
    super.initState();
    context.read<FetchNotificationsCubit>().fetchNotifications();
    _pageScrollController.addListener(_pageScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.id != null && widget.id != '') {
        Navigator.of(context).pushNamed(
          Routes.notificationDetailPage,
          arguments: {'notificationId': widget.id},
        );
      }
    });
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchNotificationsCubit>().hasMoreData()) {
        context.read<FetchNotificationsCubit>().fetchNotificationsMore();
      }
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        title: "notifications".translate(context),
        showBackButton: true,
      ),
      body: SafeArea(
        bottom: Platform.isAndroid,
        child: BlocBuilder<FetchNotificationsCubit, FetchNotificationsState>(
          builder: (context, state) {
            if (state is FetchNotificationsInProgress) {
              return buildNotificationShimmer();
            }
            if (state is FetchNotificationsFailure) {
              if (state.errorMessage == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context
                        .read<FetchNotificationsCubit>()
                        .fetchNotifications();
                  },
                );
              }

              return const SomethingWentWrong();
            }

            if (state is FetchNotificationsSuccess) {
              if (state.notificationData.isEmpty) {
                return NoDataFound(
                  onTap: () {
                    context
                        .read<FetchNotificationsCubit>()
                        .fetchNotifications();
                  },
                );
              }

              return buildNotificationListWidget(state);
            }

            return const SizedBox.square();
          },
        ),
      ),
    );
  }

  Widget buildNotificationShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: 20,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return SizedBox(
          height: 55,
          child: Row(
            spacing: 5,
            children: <Widget>[
              const CustomShimmer(width: 50, height: 50, borderRadius: 11),
              Column(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CustomShimmer(height: 7, width: 200),
                  CustomShimmer(height: 7, width: 100),
                  CustomShimmer(height: 7, width: 150),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Column buildNotificationListWidget(FetchNotificationsSuccess state) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: _pageScrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: state.notificationData.length,
            itemBuilder: (context, index) {
              NotificationData notificationData = state.notificationData[index];
              return GestureDetector(
                onTap: () {
                  HelperUtils.goToNextPage(
                    Routes.notificationDetailPage,
                    context,
                    false,
                    args: {'notificationData': notificationData},
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.color.textLightColor.withValues(
                        alpha: 0.28,
                      ),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ClipRRect(
                        clipBehavior: Clip.hardEdge,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(15),
                        ),
                        child: UiUtils.getImage(
                          notificationData.image!,
                          height: 53,
                          width: 53,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 3,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              notificationData.title!.firstUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .merge(
                                    const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                            ),
                            Text(
                              notificationData.message!.firstUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(
                                    color: context.color.textLightColor,
                                  ),
                            ),
                            CustomText(
                              notificationData.createdAt!
                                  .formatDate()
                                  .toString(),
                              fontSize: context.font.smaller,
                              color: context.color.textLightColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (state.isLoadingMore) UiUtils.progress(),
      ],
    );
  }
}
