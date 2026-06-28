class ServicePageConfig {
  final String routeName;
  final String apiType;
  final String appBarTitle;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> heroHighlights;
  final String imageAssetPath;
  final String primaryActionLabel;
  final String packagesTitle;
  final String processTitle;
  final List<String> processSteps;

  const ServicePageConfig({
    required this.routeName,
    required this.apiType,
    required this.appBarTitle,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroHighlights,
    required this.imageAssetPath,
    required this.primaryActionLabel,
    required this.packagesTitle,
    required this.processTitle,
    required this.processSteps,
  });

  static const carInspection = ServicePageConfig(
    routeName: '/carInspectionServiceScreen',
    apiType: 'car_inspection',
    appBarTitle: 'Car Inspection',
    heroTitle: 'Book a verified inspection before you buy or sell.',
    heroSubtitle:
        'Get clear checkpoints, credible reporting, and more confidence in every deal.',
    heroHighlights: [
      'Qualified inspectors',
      'Detailed inspection checkpoints',
      'Useful for buyers and sellers',
    ],
    imageAssetPath: 'assets/images/inspection.png',
    primaryActionLabel: 'Order Car Inspection',
    packagesTitle: 'Inspection packages',
    processTitle: 'How it works',
    processSteps: [
      'Choose the package that fits the vehicle.',
      'Confirm the inspection request with our team.',
      'Receive the report and proceed with confidence.',
    ],
  );

  static const sellItForMe = ServicePageConfig(
    routeName: '/sellItForMeServiceScreen',
    apiType: 'sell_for_me',
    appBarTitle: 'Sell It For Me',
    heroTitle: 'Let our team handle the selling process for you.',
    heroSubtitle:
        'Pick a package, share your car details, and move through a cleaner handoff to buyers.',
    heroHighlights: [
      'Dedicated sales assistance',
      'Less back-and-forth with buyers',
      'Structured service packages by vehicle type',
    ],
    imageAssetPath: 'assets/images/sellForMe.png',
    primaryActionLabel: 'Help me sell my car!',
    packagesTitle: 'Selling packages',
    processTitle: 'How it works',
    processSteps: [
      'Select the package that matches your car segment.',
      'Share the vehicle details with the CA Hubb team.',
      'Proceed with the guided selling flow from our side.',
    ],
  );
}
