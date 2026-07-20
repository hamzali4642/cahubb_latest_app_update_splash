import 'package:eClassify/data/cubits/service/fetch_service_packages_cubit.dart';
import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:eClassify/data/repositories/service_packages_repository.dart';
import 'package:eClassify/ui/screens/services/service_booking_navigator.dart';
import 'package:eClassify/ui/screens/services/service_page_config.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServicePackagesScreen extends StatefulWidget {
  const ServicePackagesScreen({required this.config, super.key});

  final ServicePageConfig config;

  static Route route({
    required ServicePageConfig config,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final repository = ServicePackagesRepository();
        final cachedPackages = repository.getCachedPackages(
          type: config.apiType,
        );
        return BlocProvider(
          create: (_) {
            final cubit = FetchServicePackagesCubit();
            if (cachedPackages != null && cachedPackages.isNotEmpty) {
              cubit.seedCachedPackages(cachedPackages);
            }
            cubit.fetchPackages(type: config.apiType);
            return cubit;
          },
          child: ServicePackagesScreen(config: config),
        );
      },
    );
  }

  @override
  State<ServicePackagesScreen> createState() => _ServicePackagesScreenState();
}

class _ServicePackagesScreenState extends State<ServicePackagesScreen> {
  final GlobalKey _packagesSectionKey = GlobalKey();

  Future<void> _refreshPackages() {
    return context.read<FetchServicePackagesCubit>().fetchPackages(
      type: widget.config.apiType,
      forceRefresh: true,
    );
  }

  void _scrollToPackages() {
    final targetContext = _packagesSectionKey.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _handlePrimaryActionTap(FetchServicePackagesState state) {
    if (state is FetchServicePackagesSuccess && state.packages.isNotEmpty) {
      ServiceBookingNavigator.open(
        context,
        state.packages.first,
        showSelectedPackage: false,
      );
      return;
    }

    _scrollToPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: widget.config.appBarTitle,
      ),
      body: RefreshIndicator(
        color: context.color.territoryColor,
        onRefresh: _refreshPackages,
        child:
            BlocBuilder<FetchServicePackagesCubit, FetchServicePackagesState>(
              builder: (context, state) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                  children: [
                    _ServiceHeroSection(
                      config: widget.config,
                      onPrimaryActionTap: () => _handlePrimaryActionTap(state),
                    ),
                    20.vGap,
                    _ServicePackagesSection(
                      key: _packagesSectionKey,
                      config: widget.config,
                      state: state,
                      onRetry: _refreshPackages,
                    ),
                    20.vGap,
                    _ServiceProcessSection(config: widget.config),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _ServiceHeroSection extends StatelessWidget {
  const _ServiceHeroSection({
    required this.config,
    required this.onPrimaryActionTap,
  });

  final ServicePageConfig config;
  final VoidCallback onPrimaryActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: serviceHeroGradient(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      config.appBarTitle,
                      fontSize: context.font.extraLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    8.vGap,
                    CustomText(
                      config.heroTitle,
                      fontSize: context.font.large,
                      fontWeight: FontWeight.w600,
                    ),
                    8.vGap,
                    CustomText(
                      config.heroSubtitle,
                      fontSize: context.font.normal,
                      color: context.color.textLightColor,
                    ),
                  ],
                ),
              ),
              12.hGap,
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: serviceImageSurface(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(config.imageAssetPath, fit: BoxFit.contain),
              ),
            ],
          ),
          18.vGap,
          ...config.heroHighlights.map((highlight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ServiceBulletPoint(label: highlight),
            );
          }),
          10.vGap,
          UiUtils.buildButton(
            context,
            onPressed: onPrimaryActionTap,
            buttonTitle: config.primaryActionLabel,
            radius: 12,
            height: 52,
          ),
        ],
      ),
    );
  }
}

class _ServicePackagesSection extends StatelessWidget {
  const _ServicePackagesSection({
    required this.config,
    required this.state,
    required this.onRetry,
    super.key,
  });

  final ServicePageConfig config;
  final FetchServicePackagesState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                config.packagesTitle,
                fontSize: context.font.extraLarge,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (state is FetchServicePackagesSuccess &&
                (state as FetchServicePackagesSuccess).isRefreshing)
              _RefreshPill(
                isFromCache: (state as FetchServicePackagesSuccess).isFromCache,
              ),
          ],
        ),
        12.vGap,
        if (state is FetchServicePackagesInProgress) ...[
          const _ServicePackagesLoadingState(),
        ] else if (state is FetchServicePackagesFailure) ...[
          _ServicePackagesFailureState(
            errorMessage: (state as FetchServicePackagesFailure).errorMessage,
            onRetry: onRetry,
          ),
        ] else if (state is FetchServicePackagesSuccess) ...[
          _ServicePackagesSuccessState(
            config: config,
            packages: (state as FetchServicePackagesSuccess).packages,
            onRetry: onRetry,
          ),
        ] else ...[
          const SizedBox.shrink(),
        ],
      ],
    );
  }
}

class _ServicePackagesLoadingState extends StatelessWidget {
  const _ServicePackagesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: UiUtils.progress(color: context.color.territoryColor),
    );
  }
}

class _ServicePackagesFailureState extends StatelessWidget {
  const _ServicePackagesFailureState({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: errorMessage == 'no-internet'
          ? NoInternet(onRetry: onRetry)
          : const SomethingWentWrong(),
    );
  }
}

class _ServicePackagesSuccessState extends StatelessWidget {
  const _ServicePackagesSuccessState({
    required this.packages,
    required this.onRetry,
    required this.config,
  });

  final List<ServicePackageModel> packages;
  final Future<void> Function() onRetry;
  final ServicePageConfig config;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: NoDataFound(
          onTap: onRetry,
          mainMessage: 'No packages available right now',
          subMessage: 'Pull to refresh or tap here to try again.',
          showBtn: false,
          showImage: false,
        ),
      );
    }

    return Column(
      children: packages.map((package) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ServicePackageCard(package: package, isInteractive: true),
        );
      }).toList(),
    );
  }
}

class _ServicePackageCard extends StatelessWidget {
  const _ServicePackageCard({
    required this.package,
    required this.isInteractive,
  });

  final ServicePackageModel package;
  final bool isInteractive;

  double get _parsedPrice => double.tryParse(package.price) ?? 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isInteractive
          ? () {
              ServiceBookingNavigator.open(context, package);
            }
          : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.color.borderColor),
          boxShadow: [
            BoxShadow(
              color: serviceShadow(context, alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ServicePackageLeading(package: package),
            14.hGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomText(
                          package.name,
                          fontSize: context.font.larger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      8.hGap,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: serviceAccentSurface(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: CustomText(
                              _parsedPrice.currencyFormat,
                              fontWeight: FontWeight.w700,
                              fontSize: context.font.normal,
                              color: context.color.territoryColor,
                            ),
                          ),
                          if (isInteractive) ...[
                            8.hGap,
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: context.color.textLightColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (package.typeLabel.isNotEmpty) ...[
                    6.vGap,
                    CustomText(
                      package.typeLabel,
                      fontSize: context.font.small,
                      color: context.color.textLightColor,
                    ),
                  ],
                  14.vGap,
                  ...package.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ServiceBulletPoint(label: feature),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePackageLeading extends StatelessWidget {
  const _ServicePackageLeading({required this.package});

  final ServicePackageModel package;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: serviceMutedSurface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: package.icon?.isNotEmpty == true
          ? CustomImage(src: package.icon!, fit: BoxFit.contain)
          : Icon(
              Icons.directions_car_filled_rounded,
              color: context.color.territoryColor,
              size: 28,
            ),
    );
  }
}

class _ServiceProcessSection extends StatelessWidget {
  const _ServiceProcessSection({required this.config});

  final ServicePageConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          config.processTitle,
          fontSize: context.font.extraLarge,
          fontWeight: FontWeight.w700,
        ),
        12.vGap,
        ...config.processSteps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ServiceProcessStepTile(
              index: entry.key,
              label: entry.value,
            ),
          );
        }),
      ],
    );
  }
}

class _ServiceProcessStepTile extends StatelessWidget {
  const _ServiceProcessStepTile({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: serviceAccentSurface(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomText(
              '${index + 1}',
              fontWeight: FontWeight.w700,
              color: context.color.territoryColor,
            ),
          ),
          12.hGap,
          Expanded(
            child: CustomText(
              label,
              fontSize: context.font.normal,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceBulletPoint extends StatelessWidget {
  const _ServiceBulletPoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: const Color(0xFF56B881),
        ),
        10.hGap,
        Expanded(
          child: CustomText(label, fontSize: context.font.normal, height: 1.4),
        ),
      ],
    );
  }
}

class _RefreshPill extends StatelessWidget {
  const _RefreshPill({required this.isFromCache});

  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: serviceAccentSurface(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.color.territoryColor,
            ),
          ),
          8.hGap,
          CustomText(
            isFromCache ? 'Refreshing' : 'Loading',
            fontSize: context.font.small,
            fontWeight: FontWeight.w600,
            color: context.color.territoryColor,
          ),
        ],
      ),
    );
  }
}
