import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/ui/screens/subscription/widget/planHelper.dart';
import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/lib/build_context.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/extensions/lib/translate.dart';
import 'package:eClassify/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItemListingPackageFrontCard extends StatefulWidget {
  const ItemListingPackageFrontCard({
    required this.model,
    required this.onTap,
    this.inAppPurchaseManager,
    super.key,
  });

  final SubscriptionPackageModel model;
  final InAppPurchaseManager? inAppPurchaseManager;
  final VoidCallback onTap;

  @override
  State<ItemListingPackageFrontCard> createState() =>
      _ItemListingPackageFrontCardState();
}

class _ItemListingPackageFrontCardState
    extends State<ItemListingPackageFrontCard> {
  String? _selectedGateway;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: context.color.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(
            color: widget.model.isActive!
                ? context.color.territoryColor
                : context.color.secondaryColor,
            width: 1.5,
          ),
        ),
        elevation: 0,
        margin: EdgeInsets.only(top: 33),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            20.vGap,
            ClipPath(
              clipper: HexagonClipper(),
              child: Container(
                width: 100,
                height: 110,
                padding: EdgeInsets.all(30),
                color: context.color.primaryColor,
                child: CustomImage(
                  src: widget.model.icon!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 18),
            CustomText(
              widget.model.name!,
              firstUpperCaseWidget: true,
              fontWeight: FontWeight.w600,
              fontSize: context.font.extraLarge,
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: ListView(
                children: [
                  _detailsSection(
                    'featuresList'.translate(context),
                    _features(context, widget.model.isActive!),
                  ),
                  if (widget.model.categories?.isNotEmpty ?? false)
                    _detailsSection('categoriesIncluded', _categories(context)),
                ],
              ),
            ),
            CustomText(
              widget.model.finalPrice! > 0
                  ? (widget.model.formattedFinalPrice ??
                        widget.model.finalPrice!.currencyFormat)
                  : "free".translate(context),
              fontSize: context.font.xxLarge,
              fontWeight: FontWeight.bold,
              color: context.color.textDefaultColor,
            ),
            if (widget.model.discount! > 0)
              Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    "${widget.model.discount?.decimalFormat}%\t${"OFF".translate(context)}",
                    color: context.color.forthColor,
                    fontWeight: FontWeight.bold,
                  ),
                  Text(
                    widget.model.formattedPrice ??
                        widget.model.price?.currencyFormat ??
                        '',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            GestureDetector(
              onTap: () {}, // Prevents tap propagation to parent
              child: payButtonWidget(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          CustomText(
            title,
            fontWeight: FontWeight.w600,
            fontSize: context.font.large,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.color.borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _features(BuildContext context, bool isActiveAds) {
    final bool isListing = widget.model.type == Constant.itemTypeListing;
    final bool isAdvertisement =
        widget.model.type == Constant.itemTypeAdvertisement;
    final String listingLabel =
        (isListing ? "adsListing" : "featuredAdsListing").translate(context);

    final userPackage =
        (isActiveAds &&
            (widget.model.userPurchasedPackages?.isNotEmpty ?? false))
        ? widget.model.userPurchasedPackages!.first
        : null;

    final List<Widget> items = [];

    if (isListing || isAdvertisement) {
      if (isActiveAds && userPackage != null) {
        final bool unlimited = userPackage.totalLimit == null;
        final String totalText = unlimited
            ? "unlimitedLbl".translate(context)
            : userPackage.totalLimit.toString();
        final remaining =
            userPackage.remainingItemLimit == Constant.itemLimitUnlimited
            ? "unlimitedLbl".translate(context)
            : userPackage.remainingItemLimit;
        items.add(
          checkmarkPoint(context, "${remaining} / $totalText\t$listingLabel"),
        );
      } else {
        final bool unlimited =
            widget.model.limit == Constant.itemLimitUnlimited;
        final String totalText = unlimited
            ? "unlimitedLbl".translate(context)
            : widget.model.limit.toString();
        items.add(checkmarkPoint(context, "$totalText\t$listingLabel"));
      }
    }

    if (isActiveAds && userPackage != null) {
      final bool unlimited = userPackage.endDate == null;
      var totalDuration;
      if (!unlimited) {
        final DateTime endDate = DateFormat(
          'yyyy-MM-dd',
        ).parse(userPackage.endDate!);
        final DateTime startDate = DateFormat(
          'yyyy-MM-dd',
        ).parse(userPackage.startDate!);
        totalDuration = endDate.difference(startDate).inDays.toString();
      } else {
        totalDuration = "unlimitedLbl".translate(context);
      }
      final String totalText = unlimited
          ? "unlimitedLbl".translate(context)
          : totalDuration;
      final remaining = userPackage.remainingDays == Constant.itemLimitUnlimited
          ? "unlimitedLbl".translate(context)
          : userPackage.remainingDays;
      items.add(
        checkmarkPoint(
          context,
          "${'packageValidity'.translate(context)}: ${remaining} / $totalText\t${"days".translate(context)}",
        ),
      );
    } else {
      final bool unlimited =
          widget.model.duration == Constant.itemLimitUnlimited;
      final String totalText = unlimited
          ? "unlimitedLbl".translate(context)
          : widget.model.duration.toString();
      items.add(
        checkmarkPoint(
          context,
          "${'packageValidity'.translate(context)}: ${totalText}\t${"days".translate(context)}",
        ),
      );
    }

    if (isActiveAds && userPackage != null) {
      final unlimited = userPackage.listingDurationDays == 'unlimited';
      final totalText = unlimited
          ? "unlimitedLbl".translate(context)
          : userPackage.listingDurationDays;
      items.add(
        checkmarkPoint(
          context,
          "${'listingValidity'.translate(context)}: ${totalText}\t${"days".translate(context)}",
        ),
      );
    } else {
      final bool unlimited = widget.model.listingDuration == 'unlimited';
      final String totalText = unlimited
          ? "unlimitedLbl".translate(context)
          : widget.model.listingDuration!;
      items.add(
        checkmarkPoint(
          context,
          "${'listingValidity'.translate(context)}: ${totalText}\t${"days".translate(context)}",
        ),
      );
    }

    if (widget.model.keyPoints != null && widget.model.keyPoints!.isNotEmpty) {
      items.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.model.keyPoints!
              .map((p) => checkmarkPoint(context, p))
              .toList(),
        ),
      );
    } else if (widget.model.description != null &&
        widget.model.description!.trim().isNotEmpty) {
      items.add(
        Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.only(
            start: 20,
            end: 20,
            top: 20,
          ),
          child: CustomText(
            widget.model.description!,
            color: context.color.textDefaultColor.withValues(alpha: 0.7),
            textAlign: TextAlign.start,
          ),
        ),
      );
    }

    return items;
  }

  List<Widget> _categories(BuildContext context) {
    return [
      ...widget.model.categories!.take(3).map((category) {
        return Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 3,
              backgroundColor: context.color.territoryColor,
            ),
            Expanded(
              child: CustomText(
                category,
                textAlign: TextAlign.start,
                color: context.color.textDefaultColor,
              ),
            ),
          ],
        );
      }),
      if (widget.model.categories!.length > 3)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.color.territoryColor,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onTap,
            child: Text('View More'.translate(context)),
          ),
        ),
    ];
  }

  Widget activeAdsData(BuildContext context, bool isActiveAds) {
    return ListView(
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      children: [
        5.vGap,
        if (widget.model.categories?.isNotEmpty ?? false) ...[],
      ],
    );
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UiUtils.getSvg(AppIcons.active_mark),
          Expanded(child: CustomText(text, textAlign: TextAlign.start)),
        ],
      ),
    );
  }

  Widget payButtonWidget(BuildContext context) {
    return PlanHelper().purchaseButtonWidget(
      context,
      widget.model,
      _selectedGateway,
      iosCallback: (String productId, String packageId) {
        widget.inAppPurchaseManager!.buy(productId, packageId);
      },
      btnTitle: widget.model.isActive ?? false
          ? "purchased".translate(context)
          : "purchaseThisPackage".translate(context),
      changePaymentGateway: (String selectedPaymentGateway) {
        setState(() {
          _selectedGateway = selectedPaymentGateway;
        });
      },
    );
  }
}
