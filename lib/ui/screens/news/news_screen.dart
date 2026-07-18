import 'package:eClassify/data/cubits/news/fetch_news_cubit.dart';
import 'package:eClassify/ui/screens/news/widgets/news_list_tile.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => const NewsScreen());
  }

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<FetchNewsCubit>();
    if (cubit.state is! FetchNewsSuccess) cubit.fetch();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.isEndReached()) {
      context.read<FetchNewsCubit>().fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: 'news'.translate(context),
      ),
      body: SafeArea(
        child: BlocBuilder<FetchNewsCubit, FetchNewsState>(
          builder: (context, state) {
            if (state is FetchNewsInProgress || state is FetchNewsInitial) {
              return const _NewsListLoading();
            }
            if (state is FetchNewsFailure) {
              if (state.message == 'no-internet') {
                return Center(
                  child: NoInternet(
                    onRetry: context.read<FetchNewsCubit>().fetch,
                  ),
                );
              }
              return Center(child: SomethingWentWrong());
            }
            if (state is FetchNewsSuccess) {
              if (state.items.isEmpty) return const NoDataFound();
              return RefreshIndicator(
                color: context.color.territoryColor,
                onRefresh: context.read<FetchNewsCubit>().fetch,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: state.items.length + 1,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: context.color.borderColor),
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      if (state.isLoadingMore) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(child: UiUtils.progress()),
                        );
                      }
                      if (state.loadMoreError) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: TextButton(
                              onPressed: context
                                  .read<FetchNewsCubit>()
                                  .fetchMore,
                              child: Text(
                                'retryLoadingMore'.translate(context),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox(height: 8);
                    }
                    return NewsListTile(
                      news: state.items[index],
                      showCity: true,
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _NewsListLoading extends StatelessWidget {
  const _NewsListLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
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
                  CustomShimmer(width: 180, height: 14),
                  SizedBox(height: 12),
                  CustomShimmer(width: 130, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
