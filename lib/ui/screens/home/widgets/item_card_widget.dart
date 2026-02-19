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

class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.item,
    this.aspectRatio = 3 / 2,
    this.onTap,
    super.key,
  });

  final ItemModel? item;
  final VoidCallback? onTap;
  final double aspectRatio;

  // Cache the border radius to avoid repeated allocations
  static final _borderRadius = BorderRadius.circular(18);

  String _capitalizeWordStart(String word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }

  String _formatProductTitle(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return title;

    for (int i = 0; i < words.length && i < 2; i++) {
      words[i] = _capitalizeWordStart(words[i]);
    }

    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates this card's rasterization from the scroll view,
    // reducing raster thread work during rapid scrolling
    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.pushNamed(
          context,
          Routes.adDetailsScreen,
          arguments: {"model": item},
        );
      },
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.color.textLightColor.withValues(alpha: 0.13),
              width: 1,
            ),
            color: context.color.secondaryColor,
            borderRadius: _borderRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: _borderRadius,
                        child: CustomImage(
                          key: ValueKey(item?.id),
                          src: item?.image ?? '',
                          size: Size.square(300),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (item?.isFeature ?? false)
                      const PositionedDirectional(
                        start: 10,
                        top: 5,
                        child: PromotedCard(type: PromoteCardType.icon),
                      ),
                    PositionedDirectional(
                      bottom: 2,
                      end: 4,
                      child: _FavoriteButton(item: item!),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (UiUtils.displayPrice(item!))
                        UiUtils.getPriceWidget(item!, context),
                      if ((item?.translatedName ?? "").trim().isNotEmpty)
                        CustomText(
                          _formatProductTitle(item!.translatedName ?? ""),
                          fontSize: context.font.large,
                          maxLines: 1,
                        ),
                      if (item?.translatedAddress != "")
                        Row(
                          children: [
                            UiUtils.getSvg(
                              AppIcons.location,
                              width: 8,
                              height: 11,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 3.0,
                                ),
                                child: CustomText(
                                  UiUtils.formatDisplayAddress(
                                    item?.translatedAddress ?? '',
                                  ),
                                  fontSize: context.font.smaller,
                                  color: context.color.textDefaultColor
                                      .withValues(alpha: 0.5),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (item?.created != "")
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 10,
                              color: context.color.textDefaultColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 3.0,
                                ),
                                child: CustomText(
                                  timeago.format(
                                    DateTime.parse(item!.created!),
                                    locale: AppSession.currentLocale,
                                  ),
                                  fontSize: context.font.smaller,
                                  color: context.color.textDefaultColor
                                      .withValues(alpha: 0.5),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
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

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    // Use context.select for granular rebuilds - only rebuilds when this specific
    // item's favorite status changes, not when any favorite changes
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
            child: isLoading
                ? Center(child: UiUtils.progress(width: 18, height: 18))
                : Center(
                    child: UiUtils.getSvg(
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
}
