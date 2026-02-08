import 'dart:io';

import 'package:eClassify/data/model/version.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionUpdateDialog {
  static void show(
    BuildContext context, {
    required Version availableVersion,
    required bool isForceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !isForceUpdate,
          child: AlertDialog.adaptive(
            backgroundColor: context.color.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: CustomText(
              'updateAvailable'.translate(context),
              textAlign: TextAlign.center,
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                Center(
                  child: CustomText(
                    availableVersion.toString(),
                    fontSize: context.font.larger,
                  ),
                ),
                CustomText('newVersionAvailable'.translate(context)),
                if (isForceUpdate) CustomText('forceUpdate'.translate(context)),
              ],
            ),
            actions: [
              Row(
                spacing: 10,
                children: [
                  if (!isForceUpdate)
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          foregroundColor: context.color.textDefaultColor,
                          backgroundColor: context.color.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: context.color.borderColor),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('cancel'.translate(context)),
                      ),
                    ),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        foregroundColor: context.color.secondaryColor,
                        backgroundColor: context.color.territoryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final uri = Uri.tryParse(
                          Platform.isAndroid
                              ? Constant.playStoreUrl
                              : Constant.appStoreUrl,
                        );
                        if (uri == null) return;
                        launchUrl(uri);
                      },
                      child: Text('update'.translate(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
