import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/lib/build_context.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/extensions/lib/translate.dart';
import 'package:flutter/material.dart';

class ItemListingPackageBackCard extends StatelessWidget {
  const ItemListingPackageBackCard({
    required this.model,
    required this.onTap,
    super.key,
  });

  final SubscriptionPackageModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: context.color.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(
            color: model.isActive!
                ? context.color.territoryColor
                : context.color.secondaryColor,
            width: 1.5,
          ),
        ),
        elevation: 0,
        margin: EdgeInsets.only(top: 33),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              20.vGap,
              CustomText(
                'categoriesIncluded'.translate(context),
                fontSize: context.font.extraLarge,
                fontWeight: FontWeight.bold,
                color: context.color.textDefaultColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: model.categories!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: context.color.territoryColor,
                          ),
                          Expanded(
                            child: CustomText(
                              model.categories![index],
                              textAlign: TextAlign.start,
                              color: context.color.textDefaultColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.color.territoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.color.territoryColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flip_to_front,
                        color: context.color.territoryColor,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      CustomText(
                        'backToDetails'.translate(context),
                        color: context.color.territoryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
