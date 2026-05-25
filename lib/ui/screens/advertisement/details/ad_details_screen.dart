// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ui' as ui;

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/cubits/chat/delete_message_cubit.dart';
import 'package:eClassify/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/load_chat_messages.dart';
import 'package:eClassify/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:eClassify/data/cubits/chat/send_message.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:eClassify/data/cubits/item/change_my_items_status_cubit.dart';
import 'package:eClassify/data/cubits/item/create_featured_ad_cubit.dart';
import 'package:eClassify/data/cubits/item/delete_item_cubit.dart';
import 'package:eClassify/data/cubits/item/fetch_item_cubit.dart';
import 'package:eClassify/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:eClassify/data/cubits/item/item_total_click_cubit.dart';
import 'package:eClassify/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:eClassify/data/cubits/item/related_item_cubit.dart';
import 'package:eClassify/data/cubits/renew_item_cubit.dart';
import 'package:eClassify/data/cubits/report/item_report_cubit.dart';
import 'package:eClassify/data/cubits/report/item_report_list_cubit.dart';
import 'package:eClassify/data/cubits/safety_tips_cubit.dart';
import 'package:eClassify/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:eClassify/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:eClassify/data/cubits/subscription/fetch_user_package_limit_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/chat/chat_user_model.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/item/job_application.dart'
    show JobApplication;
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/model/safety_tips_model.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/ad_banner_screen.dart';
import 'package:eClassify/ui/screens/advertisement/details/widgets/report_ads/repord_ad_card.dart';
import 'package:eClassify/ui/screens/advertisement/details/widgets/seller_profile/seller_profile_card.dart';
import 'package:eClassify/ui/screens/chat/chat_screen.dart';
import 'package:eClassify/ui/screens/google_map_screen.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/item_card_widget.dart';
import 'package:eClassify/ui/screens/item/my_item_tab_screen.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/gallery_view.dart';
import 'package:eClassify/ui/screens/widgets/location_map/location_map_controller.dart';
import 'package:eClassify/ui/screens/widgets/location_map/location_map_widget.dart';
import 'package:eClassify/ui/screens/widgets/package_select_bottom_sheet.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/screens/widgets/video_view_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:eClassify/utils/whatsapp_launcher.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AdDetailsScreen extends StatefulWidget {
  const AdDetailsScreen({
    super.key,
    this.model,
    this.slug,
    this.itemId,
    this.tabStatus,
  });
  final ItemModel? model;
  final String? slug;
  final int? itemId;
  // This is only relevant when the user renews an item.
  // Previously, renewing an item would pop this screen and refresh
  // the entire tab list for the current status — which was poor UX.
  //
  // Now, instead of popping the screen, we just refresh the list
  // for the currently active tab. To achieve that, we need a reference
  // to the selected tab's status.
  final String? tabStatus;

  @override
  AdDetailsScreenState createState() => AdDetailsScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => FetchMyItemsCubit()),
          BlocProvider(create: (context) => CreateFeaturedAdCubit()),
          BlocProvider(create: (context) => SubmitItemReportCubit()),
          BlocProvider(create: (context) => MakeAnOfferItemCubit()),
          BlocProvider(create: (context) => FetchItemCubit()),
        ],
        child: AdDetailsScreen(
          model: arguments?['model'],
          slug: arguments?['slug'],
          itemId: arguments?['item_id'],
          tabStatus: arguments?['status_tab'],
        ),
      ),
    );
  }
}

class _ViewMapButton extends StatelessWidget {
  const _ViewMapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.color.territoryColor,
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                color: context.color.buttonColor,
                size: 18,
              ),
              const SizedBox(width: 7),
              CustomText(
                'viewMap'.translate(context),
                color: context.color.buttonColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdDetailsScreenState extends CloudState<AdDetailsScreen> {
  int currentPage = 0;

  bool isShowReportAds = true;
  final PageController pageController = PageController();
  final List<String?> images = [];
  final TextEditingController _makeAnOfferMessageController =
      TextEditingController();
  final GlobalKey<FormState> _offerFormKey = GlobalKey();

  late ItemModel model;

  late bool isAddedByMe;
  bool isFeaturedWidget = true;
  String youtubeVideoThumbnail = "";
  int? categoryId;
  FlickManager? flickManager;
  LocationMapController? _locationController;
  bool isAdminEditedReasonExpanded = false;
  late bool isAlreadyReported;

  late final LeafLocation? location;
  List<dynamic> _uniqueCustomFields = [];

  @override
  void initState() {
    super.initState();
    location = AppSession.currentLocation;
    if (widget.model != null) {
      initVariables(widget.model!);
    }
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page!.round();
      });
    });
  }

  void initVariables(ItemModel itemModel) {
    model = itemModel;

    isAddedByMe =
        (model.user?.id != null ? model.user!.id.toString() : model.userId) ==
        HiveUtils.getUserId();

    categoryId = model.category != null ? model.category?.id : model.categoryId;
    isAlreadyReported =
        model.isAlreadyReported! ||
        context.read<ItemReportListCubit>().contains(itemId: model.id!);

    _prepareCustomFields();

    images.clear();
    combineImages();

    // LocationMapController is now created lazily when user taps "View Map"
    // to avoid blocking the UI during screen initialization
    _locationController?.dispose();
    if (model.latitude != null && model.longitude != null) {
      _locationController = LocationMapController(
        initialCoordinates: LatLng(model.latitude!, model.longitude!),
      );
    } else {
      _locationController = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isAddedByMe) {
        context
            .read<FetchAdsListingSubscriptionPackagesCubit>()
            .fetchPackages();
      } else {
        context.read<FetchSafetyTipsListCubit>().fetchSafetyTips();
        context.read<FetchSellerRatingsCubit>().fetch(
          sellerId: (model.user?.id != null ? model.user!.id! : model.userId!),
        );
      }

      context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
        categoryId: categoryId!,
        location: location,
      );

      setItemClick();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    _makeAnOfferMessageController.dispose();
    flickManager?.dispose();
    _locationController?.dispose();
    super.dispose();
  }

  void combineImages() {
    images.add(model.image);
    if (model.galleryImages != null && model.galleryImages!.isNotEmpty) {
      for (var element in model.galleryImages!) {
        images.add(element.image);
      }
    }

    if (model.videoLink != null && model.videoLink!.trim().isNotEmpty) {
      images.add(model.videoLink);

      if (HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
        String? videoId = YoutubePlayer.convertUrlToId(model.videoLink!);
        if (videoId != null) {
          String thumbnail = YoutubePlayer.getThumbnail(videoId: videoId);

          youtubeVideoThumbnail = thumbnail;
        }
      }
      // FlickManager initialization is deferred to when the video is actually
      // tapped to avoid blocking the UI during navigation. See VideoViewScreen.
    }
  }

  /// Lazily initializes FlickManager only when needed (when user taps video)
  FlickManager? _getOrCreateFlickManager() {
    if (flickManager != null) return flickManager;

    if (model.videoLink != null &&
        model.videoLink!.trim().isNotEmpty &&
        !HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(model.videoLink!),
        ),
      );
      flickManager?.onVideoEnd = () {};
    }
    return flickManager;
  }

  void setItemClick() {
    if (!isAddedByMe) {
      context.read<ItemTotalClickCubit>().itemTotalClick(model.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedSafeArea(
      statusBarColor: context.color.secondaryDetailsColor,
      isAnnotated: true,
      child: BlocConsumer<FetchItemCubit, FetchItemState>(
        listener: (context, state) {
          if (state is FetchItemSuccess) {
            initVariables(state.item);
          }
        },
        builder: (context, state) {
          if (state is FetchItemInitial &&
              (widget.slug != null || widget.itemId != null)) {
            context.read<FetchItemCubit>().fetchItem(
              itemId: widget.itemId,
              slug: widget.slug,
            );
            return Center(child: UiUtils.progress());
          } else if (state is FetchItemLoading) {
            return Center(child: UiUtils.progress());
          } else if (state is FetchItemFailure) {
            return Material(child: Center(child: SomethingWentWrong()));
          }
          return MultiBlocListener(
            listeners: [
              BlocListener<MakeAnOfferItemCubit, MakeAnOfferItemState>(
                listener: (context, state) {
                  if (state is MakeAnOfferItemInProgress) {
                    LoadingWidgets.showLoader(context);
                  }
                  if (state is MakeAnOfferItemSuccess ||
                      state is MakeAnOfferItemFailure) {
                    LoadingWidgets.hideLoader(context);
                  }
                },
              ),
              BlocListener<RenewItemCubit, RenewItemState>(
                listener: (context, changeState) {
                  if (changeState is RenewItemInProgress) {
                    LoadingWidgets.showLoader(context);
                  }
                  if (changeState is RenewItemInSuccess) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      changeState.responseMessage,
                    );
                    context.read<FetchItemCubit>().fetchItem(slug: model.slug);
                    // There was no other way to refresh the list without referencing this
                    // global array of references because FetchItemCubit is littered
                    // everywhere in the code, so you don't really know which
                    // reference belongs to which cubit. Hence, this temporary
                    // but dirty solution to avoid breaking the system.
                    // TODO: Refactor this entire global references of cubit
                    myAdsCubitReference[widget.tabStatus]?.fetchMyItems(
                      getItemsWithStatus: widget.tabStatus,
                    );
                    LoadingWidgets.hideLoader(context);
                  } else if (changeState is RenewItemFailure) {
                    LoadingWidgets.hideLoader(context);
                    HelperUtils.showSnackBarMessage(context, changeState.error);
                  }
                },
              ),
            ],
            child: Scaffold(
              appBar: UiUtils.buildAppBar(
                context,
                backgroundColor: context.color.secondaryDetailsColor,
                showBackButton: true,
                actions: [
                  if (isAddedByMe && model.status == Constant.statusActive ||
                      model.status == Constant.statusApproved)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        end:
                            isAddedByMe &&
                                (model.status != Constant.statusSoldOut &&
                                    model.status != Constant.statusReview &&
                                    model.status !=
                                        Constant.statusResubmitted &&
                                    model.status != Constant.statusInactive &&
                                    model.status !=
                                        Constant.statusPermanentRejected &&
                                    model.status != Constant.statusSoftRejected)
                            ? 30.0
                            : 15,
                      ),
                      child: IconButton(
                        onPressed: () {
                          HelperUtils.shareItem(
                            context,
                            "ad-details",
                            model.slug!,
                          );
                        },
                        icon: Icon(
                          Icons.share,
                          size: 24,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                    ),
                  if (isAddedByMe &&
                      (model.status != Constant.statusSoldOut &&
                          model.status != Constant.statusReview &&
                          model.status != Constant.statusResubmitted &&
                          model.status != Constant.statusInactive &&
                          model.status != Constant.statusPermanentRejected) &&
                      model.status != Constant.statusExpired)
                    MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (context) => DeleteItemCubit()),
                        BlocProvider(
                          create: (context) => ChangeMyItemStatusCubit(),
                        ),
                      ],
                      child: Builder(
                        builder: (context) {
                          return BlocListener<DeleteItemCubit, DeleteItemState>(
                            listener: (context, deleteState) {
                              if (deleteState is DeleteItemSuccess) {
                                HelperUtils.showSnackBarMessage(
                                  context,
                                  "deleteItemSuccessMsg".translate(context),
                                );
                                context.read<FetchMyItemsCubit>().deleteItem(
                                  model,
                                );
                                Navigator.pop(context, "refresh");
                              } else if (deleteState is DeleteItemFailure) {
                                HelperUtils.showSnackBarMessage(
                                  context,
                                  deleteState.errorMessage,
                                );
                              }
                            },
                            child:
                                BlocListener<
                                  ChangeMyItemStatusCubit,
                                  ChangeMyItemStatusState
                                >(
                                  listener: (context, changeState) {
                                    if (changeState
                                        is ChangeMyItemStatusSuccess) {
                                      HelperUtils.showSnackBarMessage(
                                        context,
                                        "adsStatusUpdatedSuccessfully"
                                            .translate(context),
                                      );
                                      Navigator.pop(context, "refresh");
                                    } else if (changeState
                                        is ChangeMyItemStatusFailure) {
                                      HelperUtils.showSnackBarMessage(
                                        context,
                                        changeState.errorMessage,
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 24,
                                    width: 24,
                                    margin: EdgeInsetsDirectional.only(
                                      end: 30.0,
                                    ),
                                    alignment: AlignmentDirectional.center,
                                    child: PopupMenuButton(
                                      color: context.color.territoryColor,
                                      offset: Offset(-12, 15),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(17),
                                          bottomRight: Radius.circular(17),
                                          topLeft: Radius.circular(17),
                                          topRight: Radius.circular(0),
                                        ),
                                      ),
                                      child: SvgPicture.asset(
                                        AppIcons.more,
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.contain,
                                        colorFilter: ColorFilter.mode(
                                          context.color.textDefaultColor,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      itemBuilder: (context) => [
                                        if (model.status ==
                                                Constant.statusActive ||
                                            model.status ==
                                                Constant.statusApproved)
                                          PopupMenuItem(
                                            onTap: () {
                                              Future.delayed(Duration.zero, () {
                                                context
                                                    .read<
                                                      ChangeMyItemStatusCubit
                                                    >()
                                                    .changeMyItemStatus(
                                                      id: model.id!,
                                                      status: Constant
                                                          .statusInactive,
                                                    );
                                              });
                                            },
                                            child: CustomText(
                                              "deactivate".translate(context),
                                              color: context.color.buttonColor,
                                            ),
                                          ),
                                        if (model.status ==
                                                Constant.statusActive ||
                                            model.status ==
                                                Constant.statusApproved ||
                                            model.status ==
                                                Constant.statusSoftRejected)
                                          PopupMenuItem(
                                            child: CustomText(
                                              "lblremove".translate(context),
                                              color: context.color.buttonColor,
                                            ),
                                            onTap: () async {
                                              var delete =
                                                  await UiUtils.showBlurredDialoge(
                                                    context,
                                                    dialoge: BlurredDialogBox(
                                                      title: "deleteBtnLbl"
                                                          .translate(context),
                                                      content: CustomText(
                                                        "deleteitemwarning"
                                                            .translate(context),
                                                      ),
                                                    ),
                                                  );
                                              if (delete == true) {
                                                Future.delayed(
                                                  Duration.zero,
                                                  () {
                                                    context
                                                        .read<DeleteItemCubit>()
                                                        .deleteItem(
                                                          id: model.id!,
                                                        );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              backgroundColor: context.color.secondaryDetailsColor,
              bottomNavigationBar: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: 10,
                  end: 10,
                  top: 5,
                  bottom: 10,
                ),
                child: bottomButtonWidget(),
              ),
              body: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(13.0, 0.0, 13.0, 13.0),
                // physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  setImageViewer(),
                  if (isAddedByMe) setLikesAndViewsCount(),
                  if (model.isEditedByAdmin == 1 &&
                      model.translatedAdminEditReason != null &&
                      isAddedByMe) ...[
                    SizedBox(height: 20),
                    adminEditedReason(),
                    SizedBox(height: 5),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: CustomText(
                            model.translatedName!,
                            color: context.color.textDefaultColor,
                            fontSize: context.font.large,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (model.category?.isJobCategory == 1 &&
                            isAddedByMe) ...[
                          SizedBox(width: 10),
                          Expanded(
                            child: UiUtils.buildButton(
                              context,
                              disabled: model.status == 'sold out',
                              onTapDisabledButton: () {
                                HelperUtils.showSnackBarMessage(
                                  context,
                                  'jobIsClosed'.translate(context),
                                );
                              },
                              onPressed: () => Navigator.of(context).pushNamed(
                                Routes.jobApplicationList,
                                arguments: {"itemId": model.id},
                              ),
                              height: 30,
                              buttonTitle: 'jobApplications'.translate(context),
                              fontSize: context.font.small,
                              buttonColor: context.color.territoryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  setPriceAndStatus(),
                  if (isAddedByMe) setRejectedReason(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (model.translatedAddress != null)
                        Expanded(child: setAddress()),
                      Flexible(
                        child: CustomText(
                          "${_resolvedPostedOnLabel()}: ${model.created!.formatDate(format: "d MMM yyyy")}",
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          color: context.color.textDefaultColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (Constant.isGoogleBannerAdsEnabled == "1") ...[
                    AdBannerWidget(),
                  ],
                  const SizedBox(height: 10),
                  if (isAddedByMe)
                    if (!model.isFeature!) createFeaturesAds(),
                  if (model.allTranslatedCustomFields?.isNotEmpty ?? false)
                    customFields(),
                  //Dynamic Ads here
                  Divider(
                    thickness: 1,
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  setDescription(),
                  Divider(
                    thickness: 1,
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  if (!isAddedByMe && model.user != null)
                    SellerProfileCard(user: model.user!, item: model),
                  //Dynamic Ads here
                  setLocation(),
                  if (Constant.isGoogleBannerAdsEnabled == "1") ...[
                    Divider(
                      thickness: 1,
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    AdBannerWidget(margin: const EdgeInsets.only(top: 10)),
                  ],
                  10.vGap,
                  if (!isAddedByMe && !isAlreadyReported)
                    ReportAdCard(
                      itemId: model.id!,
                      isReported: isAlreadyReported,
                      onReport: () {
                        // This should not use setState but somehow, without setState
                        // the card is being painted even though we are setting the
                        // isAlreadyReported flag to true. Perhaps, due to Flutter's
                        // internal caching mechanism.
                        setState(() {
                          isAlreadyReported = true;
                        });
                      },
                    ),
                  if (!isAddedByMe) relatedAds(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget relatedAds() {
    return BlocBuilder<FetchRelatedItemsCubit, FetchRelatedItemsState>(
      builder: (context, state) {
        if (state is FetchRelatedItemsInProgress) {
          return relatedItemShimmer();
        }
        if (state is FetchRelatedItemsFailure) {
          return const SizedBox.shrink();
        }

        if (state is FetchRelatedItemsSuccess) {
          if (state.itemModel.isEmpty || state.itemModel.length == 1) {
            return SizedBox.shrink();
          }

          return buildRelatedListWidget(state);
        }

        return const SizedBox.square();
      },
    );
  }

  Widget buildRelatedListWidget(FetchRelatedItemsSuccess state) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "relatedAds".translate(context),
            fontSize: context.font.large,
            fontWeight: FontWeight.w600,
            maxLines: 1,
          ),
          SizedBox(height: 15),
          SizedBox(
            height: HelperUtils.lerpHeight(
              screenHeight: MediaQuery.sizeOf(context).height,
              minHeight: 243,
              maxHeight: 285,
              minScreen: 600,
              maxScreen: 850,
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return ItemCard(item: state.itemModel[index], aspectRatio: .7);
              },
              separatorBuilder: (_, _) => 10.hGap,
              itemCount: state.itemModel.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget relatedItemShimmer() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: 5,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
            child: const CustomShimmer(height: 200, width: 300),
          );
        },
      ),
    );
  }

  Widget createFeaturesAds() {
    if (model.status == Constant.statusActive ||
        model.status == Constant.statusApproved) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => CreateFeaturedAdCubit()),
          BlocProvider(create: (context) => FetchUserPackageLimitCubit()),
        ],
        child: Builder(
          builder: (context) {
            return BlocListener<CreateFeaturedAdCubit, CreateFeaturedAdState>(
              listener: (context, state) {
                if (state is CreateFeaturedAdInSuccess) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.responseMessage.toString(),
                    messageDuration: 3,
                  );

                  Navigator.pop(context, "refresh");
                }
                if (state is CreateFeaturedAdFailure) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.error.toString(),
                    messageDuration: 3,
                  );
                }
              },
              child:
                  BlocListener<
                    FetchUserPackageLimitCubit,
                    FetchUserPackageLimitState
                  >(
                    listener: (context, state) async {
                      if (state is FetchUserPackageLimitFailure) {
                        UiUtils.noPackageAvailableDialog(context);
                      }
                      if (state is FetchUserPackageLimitInSuccess) {
                        await UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            title: "createFeaturedAd".translate(context),
                            content: CustomText(
                              "areYouSureToCreateThisItemAsAFeaturedAd"
                                  .translate(context),
                            ),
                            isAcceptContainerPush: true,
                            onAccept: () => Future.value().then((_) {
                              if (context
                                      .read<FetchUserPackageLimitCubit>()
                                      .state
                                  is FetchUserPackageLimitInProgress) {
                                return;
                              }
                              Future.delayed(Duration.zero, () {
                                context
                                    .read<CreateFeaturedAdCubit>()
                                    .createFeaturedAds(itemId: model.id!);
                                Navigator.pop(context);
                                return;
                              });
                            }),
                          ),
                        );
                      }
                    },
                    child: AnimatedCrossFade(
                      duration: Duration(milliseconds: 500),
                      crossFadeState: isFeaturedWidget
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(12),
                        //height: 116,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: context.color.territoryColor.withValues(
                            alpha: 0.1,
                          ),
                          border: Border.all(
                            color: context.color.textLightColor.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 12,
                              ),
                              child: SvgPicture.asset(
                                AppIcons.createAddIcon,
                                height: 74,
                                width: 62,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "${"featureYourAdsAttractMore".translate(context)}\n${"clientsAndSellFaster".translate(context)}",
                                    color: context.color.textDefaultColor
                                        .withValues(alpha: 0.7),
                                    fontSize: context.font.large,
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () {
                                      context
                                          .read<FetchUserPackageLimitCubit>()
                                          .fetchUserPackageLimit(
                                            packageType: "advertisement",
                                          );
                                    },
                                    child: Container(
                                      height: 33,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: context.color.territoryColor,
                                      ),
                                      child: CustomText(
                                        "createFeaturedAd".translate(context),
                                        color: context.color.secondaryColor,
                                        fontSize: context.font.small,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondChild: SizedBox.shrink(),
                    ),
                  ),
            );
          },
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget customFields() {
    if (_uniqueCustomFields.isEmpty) {
      return SizedBox.shrink();
    }

    final featureFields = _uniqueCustomFields
        .where((field) => _isFeaturesField(field))
        .toList();
    final registrationPlaceFields = _uniqueCustomFields
        .where((field) => _isRegistrationPlaceField(field))
        .toList();
    final standardFields = _uniqueCustomFields
        .where(
          (field) =>
              !_isFeaturesField(field) && !_isRegistrationPlaceField(field),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "featuresList".translate(context),
            fontWeight: FontWeight.bold,
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          const SizedBox(height: 12),
          if (standardFields.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  runSpacing: 10,
                  spacing: 10,
                  children: standardFields.map((field) {
                    return SizedBox(
                      width: itemWidth,
                      child: _FeatureTile(
                        field: field,
                        valueBuilder: (values) => valueContent(values),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ...featureFields.map(
            (field) => Padding(
              padding: EdgeInsets.only(top: standardFields.isEmpty ? 0 : 10),
              child: _FeaturesChipSection(field: field),
            ),
          ),
          ...registrationPlaceFields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _RegistrationPlaceTile(field: field),
            ),
          ),
        ],
      ),
    );
  }

  bool _isFeaturesField(dynamic field) {
    return _fieldName(field) == "features";
  }

  bool _isRegistrationPlaceField(dynamic field) {
    final name = _fieldName(field);
    return name.contains("registration") && name.contains("place");
  }

  String _fieldName(dynamic field) {
    return (field['translated_name'] ?? field['name'] ?? "")
        .toString()
        .trim()
        .toLowerCase();
  }

  String _fieldTitle(dynamic field) {
    return (field['translated_name'] ?? field['name'] ?? "").toString();
  }

  List<dynamic> _fieldValues(dynamic field) {
    final rawValues = field['type'] == 'fileinput'
        ? [field['value']]
        : field['translated_selected_values'] as List<dynamic>?;
    return rawValues
            ?.where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .toList() ??
        [];
  }

  Widget _FeatureTile({
    required dynamic field,
    required Widget Function(List<dynamic>? values) valueBuilder,
  }) {
    final name = _fieldTitle(field);
    final values = _fieldValues(field);

    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.color.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureIcon(field: field, values: values),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: name,
                  child: CustomText(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontSize: context.font.small,
                    fontWeight: FontWeight.w600,
                    color: context.color.textLightColor,
                  ),
                ),
                const SizedBox(height: 6),
                valueBuilder(values),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _FeaturesChipSection({required dynamic field}) {
    final values = _fieldValues(field);
    if (values.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.territoryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.color.territoryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: context.color.territoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  _fieldTitle(field),
                  color: context.color.textDefaultColor,
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.color.territoryColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: context.color.territoryColor,
                    ),
                    const SizedBox(width: 5),
                    CustomText(
                      value.toString(),
                      color: context.color.textDefaultColor,
                      fontSize: context.font.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _RegistrationPlaceTile({required dynamic field}) {
    final values = _fieldValues(field);
    if (values.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureIcon(field: field, values: values),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  _fieldTitle(field),
                  color: context.color.textLightColor,
                  fontSize: context.font.small,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 6),
                valueContent(values),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _FeatureIcon({
    required dynamic field,
    required List<dynamic>? values,
  }) {
    final colorValue = _maybeParseColorValue(field, values);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.color.territoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: colorValue != null
          ? Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colorValue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.color.borderColor,
                  width: 1.5,
                ),
              ),
            )
          : field['image'] != null && field['image'].toString().isNotEmpty
          ? UiUtils.imageType(
              field['image'],
              fit: BoxFit.contain,
              width: 22,
              height: 22,
              color: context.color.territoryColor,
            )
          : Icon(
              _featureFallbackIcon(field['translated_name'] ?? field['name']),
              color: context.color.territoryColor,
              size: 22,
            ),
    );
  }

  IconData _featureFallbackIcon(dynamic name) {
    final normalized = name?.toString().toLowerCase() ?? "";
    if (normalized.contains("mile") || normalized.contains("km")) {
      return Icons.speed_outlined;
    }
    if (normalized.contains("color") || normalized.contains("colour")) {
      return Icons.palette_outlined;
    }
    if (normalized.contains("fuel")) {
      return Icons.local_gas_station_outlined;
    }
    if (normalized.contains("transmission")) {
      return Icons.settings_outlined;
    }
    return Icons.tune_outlined;
  }

  Color? _maybeParseColorValue(dynamic field, List<dynamic>? values) {
    final name =
        field['translated_name']?.toString().toLowerCase() ??
        field['name']?.toString().toLowerCase() ??
        "";
    if (!name.contains("color") && !name.contains("colour")) return null;
    if (values == null || values.isEmpty) return null;

    final value = values.first.toString().trim().toLowerCase();
    const namedColors = {
      "black": Colors.black,
      "white": Colors.white,
      "red": Colors.red,
      "blue": Colors.blue,
      "green": Colors.green,
      "yellow": Colors.yellow,
      "grey": Colors.grey,
      "gray": Colors.grey,
      "silver": Color(0xFFC0C0C0),
      "brown": Colors.brown,
      "orange": Colors.orange,
      "purple": Colors.purple,
      "gold": Color(0xFFFFD700),
    };
    if (namedColors.containsKey(value)) return namedColors[value];

    final hex = value.replaceFirst("#", "");
    if (RegExp(r'^[0-9a-f]{6}$').hasMatch(hex)) {
      return Color(int.parse("ff$hex", radix: 16));
    }
    return null;
  }

  void _prepareCustomFields() {
    final List<dynamic> allFields = model.allTranslatedCustomFields ?? [];

    final int currentLanguageId = (HiveUtils.getLanguage()?['id'] ?? 1) as int;

    final Map<int, Map<int, dynamic>> fieldsByIdAndLang = {};
    for (var field in allFields) {
      final int id = field['id'];
      final int langId = field['language_id'] ?? 1;
      fieldsByIdAndLang.putIfAbsent(id, () => {});
      fieldsByIdAndLang[id]![langId] = field;
    }

    final Map<int, dynamic> uniqueFields = {};
    fieldsByIdAndLang.forEach((id, langMap) {
      if (langMap.containsKey(currentLanguageId)) {
        uniqueFields[id] = langMap[currentLanguageId];
      } else {
        uniqueFields[id] = langMap.values.first;
      }
    });

    _uniqueCustomFields = uniqueFields.values.toList();
  }

  Widget valueContent(List<dynamic>? value) {
    if (value == null || value.isEmpty) return SizedBox.shrink();
    if (((value[0].toString()).startsWith("http") ||
        (value[0].toString()).startsWith("https"))) {
      if ((value[0].toString()).toLowerCase().endsWith(".pdf")) {
        // Render PDF link as clickable text
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.pdfViewerScreen,
              arguments: {"url": value[0]},
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: UiUtils.getSvg(
              AppIcons.pdfIcon,
              color: context.color.textColorDark,
              width: 24,
              height: 24,
            ),
          ),
        );
      } else if ((value[0]).toLowerCase().endsWith(".png") ||
          (value[0]).toLowerCase().endsWith(".jpg") ||
          (value[0]).toLowerCase().endsWith(".jpeg") ||
          (value[0]).toLowerCase().endsWith(".svg")) {
        // Render image
        return InkWell(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(value[0]),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.color.territoryColor.withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: UiUtils.imageType(
                value[0],
                color: context.color.territoryColor,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    final values = value
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .toList();

    if (values.isEmpty) return SizedBox.shrink();

    if (values.length > 1) {
      return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: values.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: CustomText(
              item.toString(),
              color: context.color.textDefaultColor,
              fontSize: context.font.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      );
    }

    return CustomText(
      values.first.toString(),
      softWrap: true,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      color: context.color.textDefaultColor,
      fontWeight: FontWeight.w600,
    );
  }

  Widget deleteItemWidget() {
    return BlocProvider(
      create: (context) => DeleteItemCubit(),
      child: Builder(
        builder: (context) {
          return BlocListener<DeleteItemCubit, DeleteItemState>(
            listener: (context, deleteState) {
              if (deleteState is DeleteItemSuccess) {
                HelperUtils.showSnackBarMessage(
                  context,
                  "deleteItemSuccessMsg".translate(context),
                );
                context.read<FetchMyItemsCubit>().deleteItem(model);
                Navigator.pop(context, "refresh");
              } else if (deleteState is DeleteItemFailure) {
                HelperUtils.showSnackBarMessage(
                  context,
                  deleteState.errorMessage,
                );
              }
            },
            child: Expanded(
              child: _buildButton(
                "lblremove".translate(context),
                () async {
                  final delete =
                      await UiUtils.showBlurredDialoge(
                            context,
                            dialoge: BlurredDialogBox(
                              title: "deleteBtnLbl".translate(context),
                              content: CustomText(
                                "deleteitemwarning".translate(context),
                              ),
                            ),
                          )
                          as bool? ??
                      false;
                  if (delete) {
                    context.read<DeleteItemCubit>().deleteItem(id: model.id!);
                  }
                },
                null,
                null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget changeItemStatusWidget({
    required String buttonName,
    required String status,
  }) {
    return BlocListener<ChangeMyItemStatusCubit, ChangeMyItemStatusState>(
      listener: (context, changeState) {
        if (changeState is ChangeMyItemStatusSuccess) {
          HelperUtils.showSnackBarMessage(
            context,
            "adsStatusUpdatedSuccessfully".translate(context),
          );
          Navigator.pop(context, "refresh");
        } else if (changeState is ChangeMyItemStatusFailure) {
          HelperUtils.showSnackBarMessage(context, changeState.errorMessage);
        }
      },
      child: Expanded(
        child: _buildButton(
          buttonName,
          () {
            Future.delayed(Duration.zero, () {
              context.read<ChangeMyItemStatusCubit>().changeMyItemStatus(
                id: model.id!,
                status: status,
              );
            });
          },
          null,
          null,
        ),
      ),
    );
  }

  bool isEditBtnVisible() {
    List statuslist = [
      Constant.statusReview,
      Constant.statusResubmitted,
      Constant.statusActive,
      Constant.statusApproved,
      Constant.statusSoftRejected,
    ];
    return statuslist.contains(model.status);
  }

  bool isDeleteBtnVisible() {
    List statuslist = [
      Constant.statusReview,
      Constant.statusResubmitted,
      Constant.statusSoldOut,
      Constant.statusInactive,
      Constant.statusExpired,
      Constant.statusPermanentRejected,
    ];
    return statuslist.contains(model.status);
  }

  Widget bottomButtonWidget() {
    if (isAddedByMe) {
      final contextColor = context.color;

      return Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditBtnVisible())
            Expanded(
              child: _buildButton(
                "editBtnLbl".translate(context),
                () {
                  addCloudData("edit_request", model);
                  addCloudData("edit_from", model.status);
                  Navigator.pushNamed(
                    context,
                    Routes.addItemDetails,
                    arguments: {"isEdit": true},
                  );
                },
                contextColor.secondaryColor,
                contextColor.territoryColor,
              ),
            ),
          if (model.status == Constant.statusExpired)
            Expanded(
              child: _buildButton(
                "renew".translate(context),
                () {
                  final isFreeAdListingEnabled =
                      context.read<FetchSystemSettingsCubit>().getSetting(
                        SystemSetting.freeAdListing,
                      ) ==
                      "1";
                  if (isFreeAdListingEnabled) {
                    context.read<RenewItemCubit>().renewItem(itemId: model.id!);
                  } else {
                    PackageSelectBottomSheet.show(context, (packageId) {
                      Future.delayed(Duration.zero, () {
                        context.read<RenewItemCubit>().renewItem(
                          packageId: packageId,
                          itemId: model.id!,
                        );
                      });
                    });
                  }
                },
                contextColor.secondaryColor,
                contextColor.territoryColor,
              ),
            ),
          if (model.status == Constant.statusInactive)
            changeItemStatusWidget(
              buttonName: "activate".translate(context),
              status: Constant.statusActive,
            ),
          if (isDeleteBtnVisible()) deleteItemWidget(),
          if (model.status == Constant.statusActive ||
              model.status == Constant.statusApproved)
            Expanded(
              child: _buildButton(
                model.category!.isJobCategory == 1
                    ? "markAsClosed".translate(context)
                    : "soldOut".translate(context),
                () async {
                  Navigator.pushNamed(
                    context,
                    Routes.soldOutBoughtScreen,
                    arguments: {
                      "itemId": model.id,
                      "price": model.price,
                      "itemName": model.translatedName,
                      "itemImage": model.image,
                      "isJobCategory": model.category!.isJobCategory == 1,
                    },
                  );
                },
                null,
                null,
              ),
            ),
          if (model.status == Constant.statusSoftRejected)
            changeItemStatusWidget(
              buttonName: "resubmit".translate(context),
              status: Constant.statusResubmitted,
            ),
        ],
      );
    } else {
      return BlocBuilder<FetchJobApplicationCubit, FetchJobApplicationState>(
        builder: (context, state) {
          JobApplication? itemJobApplied = context.select(
            (FetchJobApplicationCubit cubit) =>
                cubit.getJobAppliedItem(model.id!),
          );
          return BlocBuilder<GetBuyerChatListCubit, GetBuyerChatListState>(
            bloc: context.read<GetBuyerChatListCubit>(),
            builder: (context, State) {
              ChatUser? chatedUser = context.select(
                (GetBuyerChatListCubit cubit) =>
                    cubit.getOfferForItem(model.id!),
              );

              final bool showMakeOfferButton =
                  model.category?.isJobCategory != 1 &&
                  (model.category?.priceOptional != 1 && model.price != null) &&
                  chatedUser == null;
              final bool showApplyButton =
                  model.category?.isJobCategory == 1 && itemJobApplied == null;
              final bool showPrimaryAction =
                  showMakeOfferButton || showApplyButton;
              final bool showCallAction = _getSellerDialNumber() != null;
              final bool showChatAction = !showMakeOfferButton;
              final bool showWhatsAppAction =
                  _getSellerWhatsAppNumber() != null;

              return BlocListener<MakeAnOfferItemCubit, MakeAnOfferItemState>(
                listener: (context, state) {
                  if (state is MakeAnOfferItemSuccess) {
                    dynamic data = state.data;

                    context.read<GetBuyerChatListCubit>().addOrUpdateChat(
                      ChatUser(
                        itemId: data['item_id'] is String
                            ? int.parse(data['item_id'])
                            : data['item_id'],
                        amount: data['amount'] != null
                            ? double.parse(data['amount'])
                            : null,
                        buyerId: data['buyer_id'],
                        createdAt: data['created_at'],
                        id: data['id'],
                        sellerId: data['seller_id'],
                        updatedAt: data['updated_at'],
                        buyer: Buyer.fromJson(data['buyer']),
                        item: Item.fromJson(data['item']),
                        seller: Seller.fromJson(data['seller']),
                      ),
                    );

                    if (state.from == 'offer') {
                      HelperUtils.showSnackBarMessage(
                        context,
                        state.message.toString(),
                      );
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return MultiBlocProvider(
                            providers: [
                              BlocProvider(
                                create: (context) => SendMessageCubit(),
                              ),
                              BlocProvider(
                                create: (context) => LoadChatMessagesCubit(),
                              ),
                              BlocProvider(
                                create: (context) => DeleteMessageCubit(),
                              ),
                            ],
                            child: ChatScreen(
                              profilePicture: model.user!.profile ?? "",
                              userName: model.user!.name!,
                              userId: model.user!.id!.toString(),
                              from: "item",
                              itemImage: model.image!,
                              itemId: model.id.toString(),
                              date: model.created!,
                              itemTitle: model.translatedName!,
                              itemOfferId: state.data['id'],
                              itemPrice: model.price != null
                                  ? model.price.toString()
                                  : null,
                              status: model.status!,
                              buyerId: HiveUtils.getUserId(),
                              itemOfferPrice: state.data['amount'] != null
                                  ? double.parse(state.data['amount'])
                                  : null,
                              isPurchased: model.isPurchased!,
                              alreadyReview: model.review == null
                                  ? false
                                  : model.review!.isEmpty
                                  ? false
                                  : true,
                              isFromBuyerList: true,
                            ),
                          );
                        },
                      ),
                    );
                  }
                  if (state is MakeAnOfferItemFailure) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      state.errorMessage.toString(),
                    );
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showPrimaryAction)
                      Expanded(
                        child: _buildButton(
                          showMakeOfferButton
                              ? "makeAnOffer".translate(context)
                              : "applyNow".translate(context),
                          () {
                            UiUtils.checkUser(
                              onNotGuest: () {
                                if (showMakeOfferButton) {
                                  safetyTipsBottomSheet();
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.jobApplicationForm,
                                    arguments: widget.model,
                                  );
                                }
                              },
                              context: context,
                            );
                          },
                          null,
                          null,
                          height: 52,
                        ),
                      ),
                    if (showPrimaryAction) const SizedBox(width: 10),
                    if (showCallAction)
                      _buildIconActionButton(
                        icon: Icons.call_rounded,
                        onPressed: () {
                          UiUtils.checkUser(
                            onNotGuest: _openSellerDialer,
                            context: context,
                          );
                        },
                      ),
                    if (showCallAction) const SizedBox(width: 10),
                    if (showChatAction)
                      _buildIconActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        onPressed: () {
                          UiUtils.checkUser(
                            onNotGuest: () {
                              if (chatedUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return MultiBlocProvider(
                                        providers: [
                                          BlocProvider(
                                            create: (context) =>
                                                SendMessageCubit(),
                                          ),
                                          BlocProvider(
                                            create: (context) =>
                                                LoadChatMessagesCubit(),
                                          ),
                                          BlocProvider(
                                            create: (context) =>
                                                DeleteMessageCubit(),
                                          ),
                                        ],
                                        child: ChatScreen(
                                          itemId: chatedUser.itemId.toString(),
                                          profilePicture:
                                              chatedUser.seller != null &&
                                                  chatedUser.seller!.profile !=
                                                      null
                                              ? chatedUser.seller!.profile!
                                              : "",
                                          userName:
                                              chatedUser.seller != null &&
                                                  chatedUser.seller!.name !=
                                                      null
                                              ? chatedUser.seller!.name!
                                              : "",
                                          date: chatedUser.createdAt!,
                                          itemOfferId: chatedUser.id!,
                                          itemPrice:
                                              chatedUser.item != null &&
                                                  chatedUser.item!.price != null
                                              ? chatedUser.item!.price
                                                    .toString()
                                              : null,
                                          itemOfferPrice:
                                              chatedUser.amount != null
                                              ? chatedUser.amount!
                                              : null,
                                          itemImage:
                                              chatedUser.item != null &&
                                                  chatedUser.item!.image != null
                                              ? chatedUser.item!.image!
                                              : "",
                                          itemTitle:
                                              chatedUser.item != null &&
                                                  chatedUser.item!.name != null
                                              ? chatedUser.item!.name!.localized
                                              : "",
                                          userId: chatedUser.sellerId
                                              .toString(),
                                          buyerId: chatedUser.buyerId
                                              .toString(),
                                          status: chatedUser.item!.status,
                                          from: "item",
                                          isPurchased: model.isPurchased!,
                                          alreadyReview: model.review == null
                                              ? false
                                              : model.review!.isEmpty
                                              ? false
                                              : true,
                                          isFromBuyerList: true,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              } else {
                                context
                                    .read<MakeAnOfferItemCubit>()
                                    .makeAnOfferItem(
                                      id: model.id!,
                                      from: "chat",
                                    );
                              }
                            },
                            context: context,
                          );
                        },
                      ),
                    if (showChatAction && showWhatsAppAction)
                      const SizedBox(width: 10),
                    if (showWhatsAppAction)
                      _buildWhatsAppActionButton(
                        onPressed: () {
                          UiUtils.checkUser(
                            onNotGuest: _openSellerWhatsApp,
                            context: context,
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  String? _getSellerDialNumber() {
    final contact = model.contact?.trim();
    if (contact != null && contact.isNotEmpty) {
      final cleaned = _sanitizePhoneNumber(contact);
      return cleaned.isEmpty ? null : cleaned;
    }

    final mobile = model.user?.mobile?.trim();
    if (mobile == null || mobile.isEmpty) return null;

    final phoneCode = model.user?.phoneCode?.trim() ?? '';
    final combined = '$phoneCode$mobile';
    final cleaned = _sanitizePhoneNumber(combined);
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _getSellerWhatsAppNumber() {
    return _getSellerDialNumber();
  }

  String _sanitizePhoneNumber(String value) {
    final hasPlus = value.trim().startsWith('+');
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    if (digitsOnly.startsWith('00')) return '+${digitsOnly.substring(2)}';
    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  void _openSellerDialer() {
    final number = _getSellerDialNumber();
    if (number == null) {
      HelperUtils.showSnackBarMessage(
        context,
        "defaultErrorMsg".translate(context),
      );
      return;
    }

    HelperUtils.launchPathURL(
      isTelephone: true,
      isSMS: false,
      isMail: false,
      value: number,
      context: context,
    );
  }

  Future<void> _openSellerWhatsApp() async {
    final number = _getSellerWhatsAppNumber();
    if (number == null) {
      HelperUtils.showSnackBarMessage(
        context,
        "defaultErrorMsg".translate(context),
      );
      return;
    }

    final message =
        'Hi! I saw your advertisement for ${model.translatedName ?? model.name} on ${AppConfig.applicationName} '
        'and I’m interested in buying it. Is it still available?'
        '\n${HelperUtils.shareUrl('ad-details', model.slug!)}';

    final launched = await WhatsAppLauncher.launch(number, message: message);
    if (!mounted || launched) return;
    HelperUtils.showSnackBarMessage(
      context,
      "defaultErrorMsg".translate(context),
    );
  }

  void safetyTipsBottomSheet() {
    List<SafetyTipsModel>? tipsList = context
        .read<FetchSafetyTipsListCubit>()
        .getList();
    if (tipsList == null || tipsList.isEmpty) {
      makeOfferBottomSheet(model);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0),
          topRight: Radius.circular(18.0),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.color.textColorDark.withValues(alpha: 0.1),
                    ),
                    height: 6,
                    width: 60,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: UiUtils.getSvg(AppIcons.safetyTipsIcon),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 5),
                child: CustomText(
                  'safetyTips'.translate(context),
                  fontWeight: FontWeight.w600,
                  fontSize: context.font.larger,
                  textAlign: TextAlign.center,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: tipsList.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return checkmarkPoint(
                    context,
                    tipsList[index].translatedName!,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildButton(
                  "continueToOffer".translate(context),
                  () {
                    Navigator.pop(context);
                    makeOfferBottomSheet(model);
                  },
                  context.color.territoryColor,
                  context.color.secondaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiUtils.getSvg(AppIcons.active_mark),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              text.firstUpperCase(),
              textAlign: TextAlign.start,
              color: context.color.textDefaultColor,
              fontSize: context.font.large,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: context.color.territoryColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Icon(icon, color: context.color.buttonColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildWhatsAppActionButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: UiUtils.getSvg(
              AppIcons.whatsapp,
              width: 24,
              height: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String title,
    VoidCallback onPressed,
    Color? buttonColor,
    Color? textColor, {
    double height = 46,
  }) {
    return UiUtils.buildButton(
      context,
      onPressed: onPressed,
      radius: 10,
      height: height,
      border: buttonColor != null
          ? BorderSide(color: context.color.territoryColor)
          : null,
      buttonColor: buttonColor,
      textColor: textColor,
      buttonTitle: title,
      width: 50,
    );
  }

  //ImageView
  Widget setImageViewer() {
    return Container(
      height: 300,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              // Increase itemCount if videoLink is present
              controller: pageController,
              itemBuilder: (context, index) {
                if (index == images.length - 1 &&
                    model.videoLink != "" &&
                    model.videoLink != null) {
                  return Stack(
                    children: [
                      // Thumbnail Image
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return VideoViewScreen(
                                  videoUrl: model.videoLink ?? "",
                                  flickManager: _getOrCreateFlickManager(),
                                );
                              },
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CustomImage(
                            src: youtubeVideoThumbnail,
                            fit: BoxFit.cover,
                            size: Size.fromHeight(300),
                          ),
                        ),
                      ),
                      // Play Button
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return VideoViewScreen(
                                    videoUrl: model.videoLink ?? "",
                                    flickManager: _getOrCreateFlickManager(),
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Display image
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GalleryViewWidget(
                            images: images,
                            initalIndex: index,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomImage(
                        src: images[index]!,
                        fit: BoxFit.cover,
                        size: Size(MediaQuery.sizeOf(context).width, 300),
                      ),
                    ),
                  );
                }
              },
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images
                      .asMap()
                      .keys
                      .map((index) => buildDot(index))
                      .toList(),
                ),
              ),
            ),
            if (model.isFeature != null)
              if (model.isFeature!)
                setTopRowItem(
                  alignment: AlignmentDirectional.topStart,
                  marginVal: 15,
                  cornerRadius: 5,
                  backgroundColor: context.color.territoryColor,
                  childWidget: CustomText(
                    "featured".translate(context),
                    fontSize: context.font.small,
                    color: context.color.backgroundColor,
                  ),
                ),
            favouriteButton(),
          ],
        ),
      ),
    );
  }

  Widget favouriteButton() {
    if (!isAddedByMe) {
      return BlocBuilder<FavoriteCubit, FavoriteState>(
        bloc: context.read<FavoriteCubit>(),
        builder: (context, favState) {
          bool isLike = context.select(
            (FavoriteCubit cubit) => cubit.isItemFavorite(model.id!),
          );

          return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
            bloc: context.read<UpdateFavoriteCubit>(),
            listenWhen: (previous, current) => current.itemId == model.id,
            listener: (context, state) {
              if (state is UpdateFavoriteSuccess) {
                if (state.wasProcess) {
                  context.read<FavoriteCubit>().addFavoriteitem(state.item);
                } else {
                  context.read<FavoriteCubit>().removeFavoriteItem(state.item);
                }
              }
            },
            buildWhen: (previous, current) => current.itemId == model.id,
            builder: (context, state) {
              return setTopRowItem(
                alignment: AlignmentDirectional.topEnd,
                marginVal: 10,
                backgroundColor: context.color.backgroundColor,
                cornerRadius: 30,
                childWidget: InkWell(
                  onTap: () {
                    UiUtils.checkUser(
                      onNotGuest: () {
                        context.read<UpdateFavoriteCubit>().setFavoriteItem(
                          item: model,
                          type: isLike ? 0 : 1,
                        );
                      },
                      context: context,
                    );
                  },
                  child: state is UpdateFavoriteInProgress
                      ? UiUtils.progress(height: 22, width: 22)
                      : UiUtils.getSvg(
                          isLike ? AppIcons.like_fill : AppIcons.like,
                          color: context.color.territoryColor,
                          width: 22,
                          height: 22,
                        ),
                ),
              );
            },
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget setTopRowItem({
    required AlignmentDirectional alignment,
    required double marginVal,
    required double cornerRadius,
    required Color backgroundColor,
    required Widget childWidget,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.all(marginVal),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          color: backgroundColor,
        ),
        child: childWidget,
      ),
    );
  }

  Widget buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      width: currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: currentPage == index ? Colors.white : Colors.grey,
      ),
    );
  }

  //ImageView

  Widget setLikesAndViewsCount() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  width: 1,
                  color: context.color.textDefaultColor.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiUtils.getSvg(
                    AppIcons.eye,
                    color: context.color.textDefaultColor,
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    model.views != null ? model.views!.toString() : "0",
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: context.font.large,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  width: 1,
                  color: context.color.textDefaultColor.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              height: 46,
              //alignment: AlignmentDirectional.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiUtils.getSvg(
                    AppIcons.like,
                    color: context.color.textDefaultColor,
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    model.totalLikes == null
                        ? "0"
                        : model.totalLikes.toString(),
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: context.font.large,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget setRejectedReason() {
    if (model.status == Constant.statusPermanentRejected ||
        model.status == Constant.statusSoftRejected &&
            (model.translatedRejectedReason != null ||
                model.translatedRejectedReason != "")) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.color.textDefaultColor.withValues(alpha: 0.1),
          ),

          // Background color
        ),
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Row(
          //crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.report,
              size: 20,
              color: Colors.red, // Icon color can be adjusted
            ),
            SizedBox(width: 5),
            Expanded(
              child: CustomText(
                '${"rejection_reason".translate(context)}: ${model.translatedRejectedReason ?? 'N/A'}',
                color: context.color.textDefaultColor,
                fontSize: context.font.large,
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget adminEditedReason() {
    String message = model.translatedAdminEditReason!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deactivateButtonColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: deactivateButtonColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiUtils.getSvg(
            AppIcons.adminEditIcon,
            height: 40,
            width: 40,
            color: deactivateButtonColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "adEditedBy".translate(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                      TextSpan(
                        text: "\t${"admin".translate(context)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final span = TextSpan(
                      text: message,
                      style: TextStyle(color: context.color.textDefaultColor),
                    );
                    final tp = TextPainter(
                      text: span,
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                    );
                    tp.layout(maxWidth: (constraints.maxWidth - 65));
                    final isOverflowing = tp.didExceedMaxLines;

                    String displayText = message;
                    if (!isAdminEditedReasonExpanded && isOverflowing) {
                      int endIndex = tp
                          .getPositionForOffset(Offset(tp.width, tp.height))
                          .offset;
                      displayText = message.substring(0, endIndex).trim();
                    }

                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: isAdminEditedReasonExpanded || !isOverflowing
                                ? message
                                : displayText + "...",
                            style: TextStyle(
                              color: context.color.textDefaultColor,
                            ),
                          ),
                          if (isOverflowing)
                            TextSpan(
                              text: isAdminEditedReasonExpanded
                                  ? "\t${"readLessLbl".translate(context)}"
                                  : "\t${"readMoreLbl".translate(context)}",
                              style: const TextStyle(
                                color: deactivateButtonColor,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    isAdminEditedReasonExpanded =
                                        !isAdminEditedReasonExpanded;
                                  });
                                },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget setPriceAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: UiUtils.getPriceWidget(model, context)),
        if (model.status != null && isAddedByMe)
          Container(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _getStatusColor(model.status),
            ),
            child: CustomText(
              _getStatusCustomText(model.status)!,
              fontSize: context.font.normal,
              color: _getStatusTextColor(model.status),
            ),
          ),
      ],
    );
  }

  String? _getStatusCustomText(String? status) {
    switch (status) {
      case Constant.statusReview:
        return "underReview".translate(context);
      case Constant.statusActive:
        return "active".translate(context);
      case Constant.statusApproved:
        return "approved".translate(context);
      case Constant.statusInactive:
        return "deactivate".translate(context);
      case Constant.statusSoldOut:
        return model.category!.isJobCategory == 1
            ? "jobClosed".translate(context)
            : "soldOut".translate(context);
      case Constant.statusPermanentRejected:
        return "permanentRejected".translate(context);
      case Constant.statusSoftRejected:
        return "softRejected".translate(context);
      case Constant.statusExpired:
        return "expired".translate(context);
      case Constant.statusResubmitted:
        return "resubmitted".translate(context);
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case Constant.statusReview || Constant.statusResubmitted:
        return pendingButtonColor.withValues(alpha: 0.1);
      case Constant.statusActive || Constant.statusApproved:
        return activateButtonColor.withValues(alpha: 0.1);
      case Constant.statusInactive:
        return deactivateButtonColor.withValues(alpha: 0.1);
      case Constant.statusSoldOut:
        return soldOutButtonColor.withValues(alpha: 0.1);
      case Constant.statusPermanentRejected || Constant.statusSoftRejected:
        return deactivateButtonColor.withValues(alpha: 0.1);
      case Constant.statusExpired:
        return deactivateButtonColor.withValues(alpha: 0.1);
      default:
        return context.color.territoryColor.withValues(alpha: 0.1);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case Constant.statusReview || Constant.statusResubmitted:
        return pendingButtonColor;
      case Constant.statusActive || Constant.statusApproved:
        return activateButtonColor;
      case Constant.statusInactive:
        return deactivateButtonColor;
      case Constant.statusSoldOut:
        return soldOutButtonColor;
      case Constant.statusPermanentRejected || Constant.statusSoftRejected:
        return deactivateButtonColor;
      case Constant.statusExpired:
        return deactivateButtonColor;
      default:
        return context.color.territoryColor;
    }
  }

  Widget setAddress() {
    final address = UiUtils.formatDisplayAddress(
      model.translatedAddress ?? '',
    ).trimLeft();

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: 0.76,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: context.color.textDefaultColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: CustomText(
              address,
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _resolvedPostedOnLabel() {
    final translated = "postedOnLbl".translate(context).trim();
    if (translated == "postedOnLbl") return "Posted on";
    return translated.replaceAll(RegExp(r'[:\s]+$'), '');
  }

  Widget setDescription() {
    final descriptionPoints = (model.translatedDescription ?? '')
        .split(RegExp(r'[\r\n]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          "aboutThisItemLbl".translate(context),
          fontWeight: FontWeight.bold,
          fontSize: context.font.large,
        ),
        if (descriptionPoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Column(
              children: descriptionPoints.map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, right: 6.0),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: context.color.textDefaultColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomText(
                          point,
                          color: context.color.textDefaultColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _navigateToGoogleMapScreen(BuildContext context) {
    // Lazily create the controller only when user wants to view the map
    _locationController ??= LocationMapController(
      initialCoordinates: LatLng(model.latitude!, model.longitude!),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        barrierDismissible: true,
        builder: (context) {
          return GoogleMapScreen(controller: _locationController!);
        },
      ),
    );
  }

  Widget setLocation() {
    // Show map section only if coordinates are available
    if (model.latitude == null || model.longitude == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "locationLbl".translate(context),
          fontWeight: FontWeight.bold,
          fontSize: context.font.large,
        ),
        SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.28,
            child: _locationController != null
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 1.6,
                            sigmaY: 1.6,
                          ),
                          child: LocationMapWidget(
                            controller: _locationController!,
                            showMyLocationButton: false,
                            showMarker: true,
                            interactive: false,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      Center(
                        child: _ViewMapButton(
                          onTap: () => _navigateToGoogleMapScreen(context),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            _navigateToGoogleMapScreen(context);
                          },
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: context.color.territoryColor.withValues(
                            alpha: 0.08,
                          ),
                        ),
                        child: Icon(
                          Icons.map_outlined,
                          size: 54,
                          color: context.color.territoryColor.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      Center(
                        child: _ViewMapButton(
                          onTap: () => _navigateToGoogleMapScreen(context),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void makeOfferBottomSheet(ItemModel model) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        content: makeAnOffer(),
        onCancel: () {
          _makeAnOfferMessageController.clear();
        },
        acceptButtonName: "send".translate(context),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (_offerFormKey.currentState!.validate()) {
            context.read<MakeAnOfferItemCubit>().makeAnOfferItem(
              id: model.id!,
              from: "offer",
              amount: double.parse(_makeAnOfferMessageController.text.trim()),
            );
            Navigator.pop(context);
            return;
          }
        }),
      ),
    );
  }

  Widget makeAnOffer() {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _offerFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "makeAnOffer".translate(context),
                fontSize: context.font.larger,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              Divider(
                thickness: 1,
                color: context.color.textLightColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 15),
              RichText(
                text: TextSpan(
                  text: '${"sellerPrice".translate(context)} ',
                  style: TextStyle(
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.5,
                    ),
                    fontSize: 16,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: model.price!.currencyFormat,
                      style: TextStyle(
                        color: context.color.textDefaultColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: isBottomPaddingNegative ? 0 : bottomPadding,
                  start: 20,
                  end: 20,
                  top: 18,
                ),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    // Allows only numeric input with optional decimal point
                  ],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: context.color.textDefaultColor,
                  ),
                  controller: _makeAnOfferMessageController,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(
                        val,
                        context: context,
                      );
                    } else {
                      double parsedVal = double.parse(val);
                      if (parsedVal <= 0.0) {
                        return "valueMustBeGreaterThanZeroLbl".translate(
                          context,
                        );
                      } else if (parsedVal > model.price!) {
                        return "offerPriceWarning".translate(context);
                      }
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                    fillColor: context.color.textLightColor.withValues(
                      alpha: 0.15,
                    ),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    hintText: "yourOffer".translate(context),
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    focusColor: context.color.territoryColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.color.textLightColor.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.color.textLightColor.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: context.color.territoryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
