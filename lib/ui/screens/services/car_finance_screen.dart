import 'package:eClassify/data/cubits/service/car_finance_cubit.dart';
import 'package:eClassify/ui/screens/services/car_finance_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CarFinanceScreen extends StatelessWidget {
  const CarFinanceScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => BlocProvider(
        create: (_) => CarFinanceCubit()..initialize(),
        child: const CarFinanceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CarFinanceLandingScreen();
  }
}
