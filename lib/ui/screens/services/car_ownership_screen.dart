import 'package:eClassify/data/cubits/service/vehicle_service_request_cubit.dart';
import 'package:eClassify/data/model/service/vehicle_service_request_model.dart';
import 'package:eClassify/ui/screens/services/vehicle_service_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _carOwnershipConfig = VehicleServiceFlowConfig(
  serviceTitle: 'Ownership Transfer',
  appBarTitle: 'Ownership Transfer',
  heroTitle: 'Transfer ownership with less back and forth',
  heroSubtitle:
      'Move the car into your name through a guided service flow built to keep things organized.',
  heroHighlights: [
    'Hassle-free process',
    'Cleaner document handling',
    'Safe and secure',
    'Trusted partner',
  ],
  imageAssetPath: 'assets/images/ownershipTransfer.png',
  primaryActionLabel: 'Start ownership transfer',
  processSteps: [
    "Fill in your car's info and your transfer details.",
    'Our service advisor will call to confirm the ownership transfer request.',
    'Submit your documents and continue the transfer process with guidance.',
    'The team handles the coordination work on your behalf.',
    'Receive updates until the ownership process is completed.',
  ],
  requestRouteName: '/carOwnershipRequestScreen',
  summaryHeadline: 'Thank you for choosing CA Hubb',
  summaryInfoLabel: 'Your request includes',
  summaryNextStepsTitle: 'Next steps',
  summaryNextSteps: [
    'You will receive a call during business hours for confirmation of your details.',
    'Ownership transfer will be scheduled once the payment and documents are verified.',
    'Move ahead without the usual ownership transfer confusion.',
  ],
);

class CarOwnershipScreen extends StatelessWidget {
  const CarOwnershipScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const CarOwnershipScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const VehicleServiceLandingScreen(config: _carOwnershipConfig);
  }
}

class CarOwnershipRequestScreen extends StatelessWidget {
  const CarOwnershipRequestScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => BlocProvider(
        create: (_) => VehicleServiceRequestCubit(
          requestType: VehicleServiceRequestType.ownership,
        )..initialize(),
        child: const CarOwnershipRequestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const VehicleServiceRequestScreen(config: _carOwnershipConfig);
  }
}
