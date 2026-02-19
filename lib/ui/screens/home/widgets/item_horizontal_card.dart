// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/screens/widgets/promoted_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

class ItemHorizontalCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onDeleteTap;
  final bool? showLikeButton;
  final VoidCallback? onTap;

  const ItemHorizontalCard({
    super.key,
    required this.item,
    this.onDeleteTap,
    this.showLikeButton,
    this.onTap,
  });

  Widget favButton(BuildContext context) {
    final bool isLike = context.select(
      (FavoriteCubit cubit) => cubit.isItemFavorite(item.id!),
    );

    return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
      listenWhen: (previous, current) => current.itemId == item.id,
      listener: (context, state) {
        if (state is UpdateFavoriteSuccess) {
          if (state.wasProcess) {
            context.read<FavoriteCubit>().addFavoriteitem(state.item);
          } else {
            context.read<FavoriteCubit>().removeFavoriteItem(state.item);
          }
        }
      },
      buildWhen: (previous, current) => current.itemId == item.id,
      builder: (context, state) {
        final isLoading = state is UpdateFavoriteInProgress;

        return GestureDetector(
          onTap: () {
            UiUtils.checkUser(
              onNotGuest: () {
                context.read<UpdateFavoriteCubit>().setFavoriteItem(
                  item: item,
                  type: isLike ? 0 : 1,
                );
              },
              context: context,
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.none,
              child: isLoading
                  ? Center(child: UiUtils.progress())
                  : UiUtils.getSvg(
                      isLike ? AppIcons.like_fill : AppIcons.like,
                      width: 22,
                      height: 22,
                      color: context.color.territoryColor,
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.pushNamed(
          context,
          Routes.adDetailsScreen,
          arguments: {"model": item},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Container(
          height: 124,
          decoration: BoxDecoration(
            border: Border.all(
              color: context.color.textLightColor.withValues(alpha: 0.28),
            ),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 122, maxWidth: 100),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomImage(
                        src: item.image!,
                        size: Size.square(200),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (item.isFeature ?? false)
                    const PositionedDirectional(
                      start: 5,
                      top: 5,
                      child: PromotedCard(type: PromoteCardType.icon),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: 0,
                    start: 12,
                    bottom: 5,
                    end: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Row(
                        children: [
                          if (UiUtils.displayPrice(item))
                            Expanded(
                              child: UiUtils.getPriceWidget(item, context),
                            )
                          else
                            Expanded(
                              child: CustomText(
                                item.translatedName ?? "",
                                maxLines: 2,
                                firstUpperCaseWidget: true,
                              ),
                            ),
                          if (showLikeButton ?? true) favButton(context),
                        ],
                      ),
                      if (UiUtils.displayPrice(item) &&
                          (item.translatedName ?? "").trim().isNotEmpty)
                        CustomText(
                          item.translatedName!.firstUpperCase(),
                          fontSize: context.font.normal,
                          color: context.color.textDefaultColor,
                          maxLines: 2,
                        ),
                      if (item.translatedAddress != "")
                        RichText(
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: context.color.textLightColor,
                                ),
                              ),
                              TextSpan(text: ' '),
                              TextSpan(
                                text: UiUtils.formatDisplayAddress(
                                  item.translatedAddress ?? '',
                                ),
                                style: TextStyle(
                                  fontSize: context.font.smaller,
                                  color: context.color.textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.created != null && item.created != '')
                        RichText(
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: context.color.textLightColor,
                                ),
                              ),
                              TextSpan(text: ' '),
                              TextSpan(
                                text: timeago.format(
                                  DateTime.parse(item.created!),
                                  locale: AppSession.currentLocale,
                                ),
                                style: TextStyle(
                                  fontSize: context.font.smaller,
                                  color: context.color.textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
