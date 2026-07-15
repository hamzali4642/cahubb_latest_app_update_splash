import 'package:eClassify/ui/screens/services/car_finance_flow.dart';
import 'package:flutter/material.dart';

class CarFinanceScreen extends StatelessWidget {
  const CarFinanceScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const CarFinanceScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CarFinanceLandingScreen();
  }
}
