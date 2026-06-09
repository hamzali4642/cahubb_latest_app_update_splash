import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:flutter/material.dart';

class HomeServicesWidget extends StatelessWidget {
  const HomeServicesWidget({super.key});

  static const List<HomeServiceItem> _featuredServices = [
    HomeServiceItem(
      title: 'Car Inspection',
      subtitle: 'Buy & Sell Confidently',
      imagePath: 'assets/images/inspection.png',
      layout: HomeServiceLayout.large,
    ),
    HomeServiceItem(
      title: 'Sell It For Me',
      subtitle: 'Hassle Free Selling',
      imagePath: 'assets/images/sellForMe.png',
    ),
    HomeServiceItem(
      title: 'Autostore',
      subtitle: 'Products For You',
      layout: HomeServiceLayout.placeholder,
    ),
  ];

  static const List<HomeServiceItem> _scrollableServices = [
    HomeServiceItem(
      title: 'Auction Sheet Verification',
      imagePath: 'assets/images/auctionSheet.png',
    ),
    HomeServiceItem(
      title: 'Car Registration',
      imagePath: 'assets/images/carRegistration.png',
    ),
    HomeServiceItem(
      title: 'Ownership Transfer',
      imagePath: 'assets/images/ownershipTransfer.png',
    ),
    HomeServiceItem(
      title: 'Car Finance',
      imagePath: 'assets/images/carFinance.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
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
}

enum HomeServiceLayout { large, regular, placeholder }

class HomeServiceItem {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final HomeServiceLayout layout;

  const HomeServiceItem({
    required this.title,
    this.subtitle,
    this.imagePath,
    this.layout = HomeServiceLayout.regular,
  });
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

    return Container(
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
    );
  }
}

class _CompactServiceCard extends StatelessWidget {
  const _CompactServiceCard({required this.item});

  final HomeServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: Expanded(
                child: Image(
                  image: AssetImage(item.imagePath!),

                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          CustomText(
            item.title + "\n",
            fontSize: context.font.small,
            fontWeight: FontWeight.w600,
            maxLines: 2,
          ),
        ],
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
              gradient: const LinearGradient(
                colors: [Color(0xFFD9E8FF), Color(0xFFF3F8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
