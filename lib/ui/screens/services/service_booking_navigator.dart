import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/service/service_package_model.dart';
import 'package:flutter/material.dart';

class ServiceBookingNavigator {
  const ServiceBookingNavigator._();

  static void open(
    BuildContext context,
    ServicePackageModel package, {
    bool showSelectedPackage = true,
  }) {
    switch (package.type) {
      case 'car_inspection':
        Navigator.pushNamed(
          context,
          Routes.carInspectionBookingScreen,
          arguments: {
            'package': package,
            'showSelectedPackage': showSelectedPackage,
          },
        );
        break;
      case 'sell_for_me':
        Navigator.pushNamed(
          context,
          Routes.sellItForMeBookingScreen,
          arguments: {
            'package': package,
            'showSelectedPackage': showSelectedPackage,
          },
        );
        break;
      default:
        break;
    }
  }
}
