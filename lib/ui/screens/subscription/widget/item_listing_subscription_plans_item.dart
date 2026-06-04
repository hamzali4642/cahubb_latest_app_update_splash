import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/ui/screens/subscription/widget/item_listing_package_back_card.dart';
import 'package:eClassify/ui/screens/subscription/widget/item_listing_package_front_card.dart';
import 'package:eClassify/ui/screens/subscription/widget/planHelper.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:flutter/material.dart';

class ItemListingSubscriptionPlansItem extends StatefulWidget {
  final SubscriptionPackageModel model;
  final InAppPurchaseManager? inAppPurchaseManager;

  const ItemListingSubscriptionPlansItem({
    super.key,
    required this.model,
    required this.inAppPurchaseManager,
  });

  @override
  _ItemListingSubscriptionPlansItemState createState() =>
      _ItemListingSubscriptionPlansItemState();
}

class _ItemListingSubscriptionPlansItemState
    extends State<ItemListingSubscriptionPlansItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    final bool shouldShowCategories =
        widget.model.categories != null && widget.model.categories!.length > 3;
    if (!shouldShowCategories) {
      return;
    }
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (widget.model.isActive!)
          ClipPath(
            clipper: CapShapeClipper(),
            child: Container(
              alignment: Alignment.center,
              color: context.color.territoryColor,
              width: MediaQuery.of(context).size.width / 1.6,
              height: 33,
              padding: EdgeInsets.only(top: 3),
              child: CustomText(
                'activePlanLbl'.translate(context),
                color: context.color.secondaryColor,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * 3.14159265359;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: angle >= 1.5708
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(3.14159265359),
                      alignment: Alignment.center,
                      child: ItemListingPackageBackCard(
                        model: widget.model,
                        onTap: _toggleFlip,
                      ),
                    )
                  : ItemListingPackageFrontCard(
                      model: widget.model,
                      onTap: _toggleFlip,
                      inAppPurchaseManager: widget.inAppPurchaseManager,
                    ),
            );
          },
        ),
      ],
    );
  }
}
