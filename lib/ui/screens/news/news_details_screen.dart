import 'package:eClassify/data/cubits/news/fetch_news_details_cubit.dart';
import 'package:eClassify/data/model/news/news_model.dart';
import 'package:eClassify/ui/screens/news/widgets/news_list_tile.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class NewsDetailsScreen extends StatefulWidget {
  const NewsDetailsScreen({required this.news, super.key});

  final NewsModel news;

  static Route route(RouteSettings settings) {
    final arguments = settings.arguments! as Map;
    final news = arguments['news'] as NewsModel;
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => FetchNewsDetailsCubit()..fetch(news),
        child: NewsDetailsScreen(news: news),
      ),
    );
  }

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: 'newsDetails'.translate(context),
      ),
      body: SafeArea(
        child: BlocBuilder<FetchNewsDetailsCubit, FetchNewsDetailsState>(
          builder: (context, state) {
            if (state is FetchNewsDetailsFailure) {
              if (state.message == 'no-internet') {
                return Center(
                  child: NoInternet(
                    onRetry: () => context.read<FetchNewsDetailsCubit>().fetch(
                      widget.news,
                    ),
                  ),
                );
              }
              return const Center(child: SomethingWentWrong());
            }
            if (state is FetchNewsDetailsSuccess) {
              return _NewsArticle(news: state.news);
            }
            return Center(child: UiUtils.progress());
          },
        ),
      ),
    );
  }
}

class _NewsArticle extends StatelessWidget {
  const _NewsArticle({required this.news});

  final NewsModel news;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: news.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CustomImage(src: news.coverImage, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    formatNewsDate(news.createdAt),
                    fontSize: context.font.small,
                    color: context.color.textLightColor,
                  ),
                ),
                if (news.city?.localizedName.isNotEmpty == true)
                  CustomText(
                    news.city!.localizedName,
                    fontSize: context.font.small,
                    color: context.color.textLightColor,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            HtmlWidget(
              news.localizedHtml,
              textStyle: TextStyle(
                color: context.color.textDefaultColor,
                fontSize: context.font.normal,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
