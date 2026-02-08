import 'dart:developer';

import 'package:eClassify/data/model/version.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/version_utility.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AppUpdateState {}

class AppUpdateInitial extends AppUpdateState {}

class AppUpdateAvailable extends AppUpdateState {
  AppUpdateAvailable({
    required this.current,
    required this.required,
    required this.isMandatory,
  });

  final Version current;
  final Version required;
  final bool isMandatory;
}

class AppUpdateCheckCompleted extends AppUpdateState {}

class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit() : super(AppUpdateInitial());

  Future<void> checkForUpdates({
    required String remoteVersion,
    required bool forceUpdate,
  }) async {
    log('$state');
    if (state is AppUpdateCheckCompleted) return;
    try {
      final required = Version.fromString(remoteVersion);
      final current = await VersionUtility.currentPackageVersion;
      log('${required.toString()} ${current.toString()}');
      final isUpdateAvailable = await VersionUtility.isUpdateAvailable(
        required,
      );
      if (isUpdateAvailable) {
        Constant.isUpdateAvailable = true;
        Constant.newVersionNumber = required.toString();
        emit(
          AppUpdateAvailable(
            current: current,
            required: required,
            isMandatory: forceUpdate,
          ),
        );
      }
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'checkForUpdates');
      log('$stack', name: 'checkForUpdates');
    } finally {
      /// We emit this state to avoid re-showing the update dialog.
      ///
      /// Since the checkForUpdates is called in initState of main_activity,
      /// the transitions after login/logout will cause this check to fire again
      /// leading to dialog showing multiple times.
      ///
      /// To resolve this scenario we emit this state to avoid re-showing the dialog.
      /// This way, update dialog is only shown once per app lifecycle.
      emit(AppUpdateCheckCompleted());
    }
  }
}
