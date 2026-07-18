import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/news/news_model.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class NewsListTile extends StatelessWidget {
  const NewsListTile({required this.news, this.showCity = false, super.key});

  final NewsModel news;
  final bool showCity;

  @override
  Widget build(BuildContext context) {
    final textDirection = news.isUrdu ? TextDirection.rtl : TextDirection.ltr;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.newsDetailsScreenRoute,
          arguments: {'news': news},
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImage(
                src: news.coverImage,
                fit: BoxFit.cover,
                size: const Size(112, 88),
                resolution: const Size(224, 176),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Directionality(
                textDirection: textDirection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      news.previewTitle,
                      fontSize: context.font.normal,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      height: 1.3,
                      textAlign: news.isUrdu ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 7),
                    CustomText(
                      formatNewsDate(news.createdAt),
                      fontSize: context.font.small,
                      color: context.color.textLightColor,
                      maxLines: 1,
                    ),
                    if (showCity &&
                        news.city?.localizedName.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        news.city!.localizedName,
                        fontSize: context.font.small,
                        color: context.color.textLightColor,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatNewsDate(DateTime? date) {
  if (date == null) return '';
  final locale = intl.DateFormat.localeExists(AppSession.currentLocale)
      ? AppSession.currentLocale
      : intl.Intl.defaultLocale;
  return intl.DateFormat('MMMM d, yyyy h:mm a', locale).format(date.toLocal());
}
