import 'package:eClassify/ui/screens/services/vehicle_service_flow.dart';
import 'package:flutter/material.dart';

const _carRegistrationConfig = VehicleServiceFlowConfig(
  serviceTitle: 'Car Registration',
  appBarTitle: 'Car Registration',
  heroTitle: 'New car, karo apne naam',
  heroSubtitle:
      'Handle registration in a guided flow with cleaner coordination and fewer hassles.',
  heroHighlights: [
    'Hassle-free process',
    'Quick car registration',
    'Safe and secure',
    'Trusted partner',
  ],
  imageAssetPath: 'assets/images/carRegistration.png',
  primaryActionLabel: 'Get my car registered now',
  processSteps: [
    "Fill in your car's info and your registration details.",
    'Our service advisor will call to confirm your registration request.',
    'Submit your documents and move forward with the registration process.',
    'The team handles the remaining coordination for you.',
    'Receive updates and get back on the road with less friction.',
  ],
  requestRouteName: '/carRegistrationRequestScreen',
  summaryHeadline: 'Thank you for choosing CA Hubb',
  summaryInfoLabel: 'Your request includes',
  summaryNextStepsTitle: 'Next steps',
  summaryNextSteps: [
    'You will receive a call during business hours for confirmation of your details.',
    'Car registration will be scheduled once the documents are verified.',
    'Drive your car without the usual process headaches.',
  ],
);

class CarRegistrationScreen extends StatelessWidget {
  const CarRegistrationScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const CarRegistrationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const VehicleServiceLandingScreen(config: _carRegistrationConfig);
  }
}

class CarRegistrationRequestScreen extends StatelessWidget {
  const CarRegistrationRequestScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const CarRegistrationRequestScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const VehicleServiceRequestScreen(config: _carRegistrationConfig);
  }
}
