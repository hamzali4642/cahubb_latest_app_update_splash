import 'dart:developer';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/advertisement/details/widgets/seller_profile/verified_badge.dart';
import 'package:eClassify/ui/screens/widgets/bottom_navigation_bar/svg_color_mapper.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerProfileCard extends StatelessWidget {
  const SellerProfileCard({required this.user, required this.item, super.key});

  final User user;
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final sellerRatings = context.watch<FetchSellerRatingsCubit>();

    final seller = sellerRatings.sellerData();
    final totalRating = sellerRatings.totalSellerRatings();
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.sellerProfileScreen,
          arguments: {"sellerId": user.id},
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomImage(
                src: user.profile ?? '',
                size: Size.square(70),
                resolution: Size.square(100),
                fit: BoxFit.cover,
                errorImage: CustomImage(
                  src: AppIcons.defaultPersonLogo,
                  size: Size.square(50),
                  fit: BoxFit.cover,
                  svgColorMapper: SvgColorMapper(),
                ),
              ),
            ),
            10.hGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.isVerified ?? false) VerifiedBadge(),
                  CustomText(user.name!, fontSize: context.font.large),
                  if (seller != null && seller.averageRating != null)
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(
                                  Icons.star_rounded,
                                  color: context.color.textDefaultColor,
                                  size: 16,
                                ),
                              ),
                              TextSpan(
                                text: seller.averageRating!.toStringAsFixed(2),
                                style: TextStyle(
                                  color: context.color.textDefaultColor,
                                  fontSize: context.font.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10, child: VerticalDivider()),
                        if (totalRating != null)
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: totalRating.toString(),
                                  style: TextStyle(
                                    color: context.color.textDefaultColor,
                                    fontSize: context.font.normal,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: 'ratings'.translate(context),
                                  style: TextStyle(
                                    color: context.color.textDefaultColor,
                                    fontSize: context.font.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  if (user.email != null && user.email!.isNotEmpty)
                    CustomText(user.email!, fontSize: context.font.small),
                ],
              ),
            ),
            if (user.mobile != null && user.mobile!.isNotEmpty) ...[
              IconButton(
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.color.borderColor),
                  ),
                ),
                onPressed: () {
                  final number = _normalizePhoneNumber(
                    user.mobile!,
                    user.phoneCode,
                  );

                  Uri redirectUri = Uri.parse("tel:$number");
                  launchUrl(redirectUri);
                },
                icon: CustomImage(
                  src: AppIcons.call,
                  size: Size.square(20),
                  svgColorMapper: SvgColorMapper(),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.color.borderColor),
                  ),
                ),
                onPressed: () {
                  // For backwards compatibility
                  // If you want to use SMS instead of Whatsapp
                  // Set this to true
                  final useSMS = false;

                  // ignore: dead_code
                  if (useSMS) {
                    final smsLink = Uri.parse(
                      'sms:${_normalizePhoneNumber(user.mobile!, user.phoneCode)}',
                    );
                    launchUrl(smsLink);
                  } else {
                    final whatsappLink = _generateWhatsappLink(
                      _normalizePhoneNumber(user.mobile!, user.phoneCode),
                    );
                    launchUrl(whatsappLink);
                  }
                },
                icon: CustomImage(
                  src: AppIcons.message,
                  size: Size.square(20),
                  svgColorMapper: SvgColorMapper(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _normalizePhoneNumber(String mobile, String? phoneCode) {
    final effectivePhoneCode = phoneCode ?? AppConfig.defaultPhoneCode;
    var number = '$effectivePhoneCode$mobile';
    if (!number.startsWith('+')) {
      number = '+$number';
    }
    return number;
  }

  Uri _generateWhatsappLink(String normalizedNumber) {
    final message =
        'Hi! I saw your advertisement for ${item.name} on ${AppConfig.applicationName} '
        'and I’m interested in buying it. Is it still available?'
        '\n${HelperUtils.shareUrl('ad-details', item.slug!)}';

    final encodedMessage = Uri.encodeComponent(message);

    final uri = Uri.parse(
      'https://wa.me/$normalizedNumber?text=$encodedMessage',
    );
    log('$uri');
    return uri;
  }
}
