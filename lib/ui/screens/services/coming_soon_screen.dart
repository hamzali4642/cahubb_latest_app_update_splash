import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
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
      appBar: AppBar(
        backgroundColor: context.color.secondaryColor,
        foregroundColor: context.color.textDefaultColor,
        elevation: 0,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 52,
                  color: context.color.territoryColor,
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
