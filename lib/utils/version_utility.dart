import 'package:eClassify/data/model/version.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionUtility {
  static Future<Version> get currentPackageVersion async {
    final info = await PackageInfo.fromPlatform();
    return Version.fromString('${info.version}+${info.buildNumber}');
  }

  static Future<bool> isUpdateAvailable(Version required) async {
    final current = await currentPackageVersion;
    return required > current;
  }
}
