import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

const List kOnboardingList = [
  {
    'svg': "assets/svg/Illustrators/onbo_a.svg",
    'title': "onboarding_1_title",
    'description': "onboarding_1_des",
  },
  {
    'svg': "assets/svg/Illustrators/onbo_b.svg",
    'title': "onboarding_2_title",
    'description': "onboarding_2_des",
  },
  {
    'svg': "assets/svg/Illustrators/onbo_c.svg",
    'title': "onboarding_3_title",
    'description': "onboarding_3_des",
  },
];

class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({required this.controller, super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: kOnboardingList.length,
      itemBuilder: (context, index) {
        final data = kOnboardingList[index];
        return Column(
          spacing: 30,
          children: [
            Expanded(
              flex: 2,
              child: SvgPicture.asset(
                data['svg'] as String,
                colorFilter: ColorFilter.mode(
                  context.color.territoryColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Flexible(
              child: CustomText(
                (data['title'] as String).translate(context),
                fontSize: context.font.extraLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            Flexible(
              child: CustomText(
                (data['description'] as String).translate(context),
                fontSize: context.font.large,
                color: context.color.textLightColor,
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
            ),
          ],
        );
      },
    );
  }
}
