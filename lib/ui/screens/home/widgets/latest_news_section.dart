import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/news/fetch_news_cubit.dart';
import 'package:eClassify/ui/screens/news/widgets/news_list_tile.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LatestNewsSection extends StatelessWidget {
  const LatestNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchNewsCubit, FetchNewsState>(
      builder: (context, state) {
        if (state is FetchNewsInProgress || state is FetchNewsInitial) {
          return const _LatestNewsLoading();
        }
        if (state is FetchNewsFailure) {
          return _LatestNewsError(
            message: state.message,
            onRetry: context.read<FetchNewsCubit>().fetch,
          );
        }
        if (state is FetchNewsSuccess && state.items.isNotEmpty) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.color.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        'latestNews'.translate(context),
                        fontSize: context.font.larger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.newsScreenRoute),
                      child: Text('viewAll'.translate(context)),
                    ),
                  ],
                ),
                ...state.items.take(3).map((news) => NewsListTile(news: news)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LatestNewsLoading extends StatelessWidget {
  const _LatestNewsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CustomShimmer(width: 140, height: 20),
          ),
          SizedBox(height: 18),
          _NewsRowShimmer(),
          _NewsRowShimmer(),
          _NewsRowShimmer(),
        ],
      ),
    );
  }
}

class _NewsRowShimmer extends StatelessWidget {
  const _NewsRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CustomShimmer(width: 112, height: 88, borderRadius: 8),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmer(width: double.infinity, height: 14),
                SizedBox(height: 8),
                CustomShimmer(width: 150, height: 14),
                SizedBox(height: 12),
                CustomShimmer(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestNewsError extends StatelessWidget {
  const _LatestNewsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              message,
              color: context.color.textLightColor,
              maxLines: 2,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('retry'.translate(context)),
          ),
        ],
      ),
    );
  }
}
