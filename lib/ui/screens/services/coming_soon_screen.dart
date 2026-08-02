import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.title, super.key});

  final String title;

  static Route<void> route(RouteSettings settings) {
    final arguments = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => ComingSoonScreen(
        title: arguments?['title'] as String? ?? 'Auto Store',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: UiUtils.buildAppBar(context, showBackButton: true, title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Image.asset(
                  'assets/images/autoStore .png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Auto Store products',
                ),
              ),
              const SizedBox(height: 28),
              CustomText(
                '$title is coming soon',
                textAlign: TextAlign.center,
                fontSize: context.font.extraLarge,
                fontWeight: FontWeight.w800,
                color: context.color.textDefaultColor,
              ),
              const SizedBox(height: 10),
              CustomText(
                'We are preparing a better way to shop for products. Stay tuned.',
                textAlign: TextAlign.center,
                fontSize: context.font.normal,
                color: context.color.textLightColor,
                height: 1.45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
