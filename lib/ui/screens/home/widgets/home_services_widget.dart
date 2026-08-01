import 'package:eClassify/data/repositories/service_packages_repository.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/ui/theme/service_theme_utils.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class HomeServicesWidget extends StatefulWidget {
  const HomeServicesWidget({super.key});

  @override
  State<HomeServicesWidget> createState() => _HomeServicesWidgetState();
}

class _HomeServicesWidgetState extends State<HomeServicesWidget> {
  final ServicePackagesRepository _servicePackagesRepository =
      ServicePackagesRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _servicePackagesRepository.prefetchPackages(type: 'car_inspection');
      _servicePackagesRepository.prefetchPackages(type: 'sell_for_me');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        color: serviceSurface(context, lightAlpha: 0.08, darkAlpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Explore CA Hubb Services',
            fontSize: context.font.large,
            fontWeight: FontWeight.w700,
            color: context.color.textDefaultColor,
          ),
          14.vGap,
          _FeaturedServicesGrid(items: _featuredServices),
          12.vGap,
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _scrollableServices.length,
              separatorBuilder: (_, _) => 10.hGap,
              itemBuilder: (context, index) {
                return _CompactServiceCard(item: _scrollableServices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  static const List<HomeServiceItem> _featuredServices = [
    HomeServiceItem(
      title: 'Car Inspection',
      subtitle: 'Buy & Sell Confidently',
      imagePath: 'assets/images/inspection.png',
      layout: HomeServiceLayout.large,
      routeName: Routes.carInspectionServiceScreen,
    ),
    HomeServiceItem(
      title: 'Sell It For Me',
      subtitle: 'Hassle Free Selling',
      imagePath: 'assets/images/sellForMe.png',
      routeName: Routes.sellItForMeServiceScreen,
    ),
    HomeServiceItem(
      title: 'Autostore',
      subtitle: 'Products For You',
      layout: HomeServiceLayout.placeholder,
      routeName: Routes.comingSoonScreen,
      requiresAuthentication: false,
    ),
  ];

  static const List<HomeServiceItem> _scrollableServices = [
    HomeServiceItem(
      title: 'Auction Sheet Verification',
      imagePath: 'assets/images/auctionSheet.png',
      routeName: Routes.auctionSheetVerificationScreen,
    ),
    HomeServiceItem(
      title: 'Car Registration',
      imagePath: 'assets/images/carRegistration.png',
      routeName: Routes.carRegistrationScreen,
    ),
    HomeServiceItem(
      title: 'Ownership Transfer',
      imagePath: 'assets/images/ownershipTransfer.png',
      routeName: Routes.carOwnershipScreen,
    ),
    HomeServiceItem(
      title: 'Car Finance',
      imagePath: 'assets/images/carFinance.png',
      routeName: Routes.carFinanceScreen,
    ),
  ];
}

enum HomeServiceLayout { large, regular, placeholder }

class HomeServiceItem {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final HomeServiceLayout layout;
  final String? routeName;
  final bool requiresAuthentication;

  const HomeServiceItem({
    required this.title,
    this.subtitle,
    this.imagePath,
    this.layout = HomeServiceLayout.regular,
    this.routeName,
    this.requiresAuthentication = true,
  });
}

void _openService(BuildContext context, HomeServiceItem item) {
  final routeName = item.routeName;
  if (routeName == null) return;
  if (!item.requiresAuthentication) {
    Navigator.pushNamed(context, routeName, arguments: {'title': item.title});
    return;
  }
  UiUtils.checkUser(
    context: context,
    onNotGuest: () => Navigator.pushNamed(context, routeName),
  );
}

class _FeaturedServicesGrid extends StatelessWidget {
  const _FeaturedServicesGrid({required this.items});

  final List<HomeServiceItem> items;

  @override
  Widget build(BuildContext context) {
    final largeCard = items.firstWhere(
      (item) => item.layout == HomeServiceLayout.large,
    );
    final sideCards = items
        .where((item) => item.layout != HomeServiceLayout.large)
        .toList();

    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.2,
              child: _FeaturedServiceCard(
                item: largeCard,
                imageHeight: 68,
                imageAlignment: Alignment.bottomCenter,
              ),
            ),
          ),
          10.hGap,
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: _FeaturedServiceCard(
                      item: sideCards.first,
                      imageHeight: 42,
                      imageAlignment: Alignment.bottomRight,
                    ),
                  ),
                  10.vGap,
                  Expanded(
                    flex: 2,
                    child: _FeaturedServiceCard(
                      item: sideCards.last,
                      imageHeight: 28,
                      imageAlignment: Alignment.centerRight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedServiceCard extends StatelessWidget {
  const _FeaturedServiceCard({
    required this.item,
    required this.imageHeight,
    required this.imageAlignment,
  });

  final HomeServiceItem item;
  final double imageHeight;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = item.layout == HomeServiceLayout.placeholder;

    return InkWell(
      onTap: item.routeName == null ? null : () => _openService(context, item),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    item.title,
                    fontSize: item.layout == HomeServiceLayout.large
                        ? context.font.larger
                        : context.font.small,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                  ),
                  if (item.subtitle?.isNotEmpty ?? false) ...[
                    CustomText(
                      item.subtitle!,
                      fontSize: context.font.smaller,
                      color: context.color.textLightColor,
                      maxLines: 1,
                    ),
                  ],
                  if (!isPlaceholder) ...[
                    Expanded(
                      child: Align(
                        alignment: imageAlignment,
                        child: SizedBox(
                          child: Image(image: AssetImage(item.imagePath!)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isPlaceholder) _AutostorePlaceholder(height: imageHeight),
          ],
        ),
      ),
    );
  }
}

class _CompactServiceCard extends StatelessWidget {
  const _CompactServiceCard({required this.item});

  final HomeServiceItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.routeName == null ? null : () => _openService(context, item),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 122,
        height: 122,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image(
                  image: AssetImage(item.imagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            CustomText(
              '${item.title}\n',
              fontSize: context.font.small,
              fontWeight: FontWeight.w600,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _AutostorePlaceholder extends StatelessWidget {
  const _AutostorePlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + 8,

      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            height: height + 8,
            width: 48,
            decoration: BoxDecoration(
              gradient: serviceHeroGradient(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: context.color.territoryColor,
            ),
          ),
        ],
      ),
    );
  }
}
