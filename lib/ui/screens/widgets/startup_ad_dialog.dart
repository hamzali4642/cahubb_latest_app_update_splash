import 'dart:async';
import 'dart:math' as math;

import 'package:eClassify/data/model/startup_ad_model.dart';
import 'package:eClassify/data/repositories/startup_ad_repository.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class StartupAdPlacement {
  static final StartupAdRepository _repository = StartupAdRepository();

  static Future<void> fetchAndShow(BuildContext context, {String? type}) async {
    try {
      final ad = await _repository.fetch(type: type);
      if (ad == null || !context.mounted) return;

      final image = NetworkImage(ad.imageUrl);
      final imageSize = await _resolveImageSize(image, context);
      if (!context.mounted) return;

      await StartupAdDialog.show(
        context,
        ad,
        image: image,
        imageSize: imageSize,
      );
    } on Exception {
      // Ads are optional and must never interrupt the normal screen flow.
    }
  }

  static Future<Size> _resolveImageSize(
    ImageProvider image,
    BuildContext context,
  ) {
    final completer = Completer<Size>();
    final stream = image.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(
          Size(info.image.width / info.scale, info.image.height / info.scale),
        );
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

class StartupAdDialog extends StatelessWidget {
  const StartupAdDialog({
    required this.ad,
    required this.image,
    required this.imageSize,
    super.key,
  });

  final StartupAdModel ad;
  final ImageProvider image;
  final Size imageSize;

  static Future<void> show(
    BuildContext context,
    StartupAdModel ad, {
    required ImageProvider image,
    required Size imageSize,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) =>
          StartupAdDialog(ad: ad, image: image, imageSize: imageSize),
    );
  }

  Future<void> _openDestination(BuildContext context) async {
    final destination = ad.destinationUri;
    if (destination == null) return;

    Navigator.of(context, rootNavigator: true).pop();
    await launchUrl(destination, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final destination = ad.destinationUri;
    final maxWidth = screenSize.width - 48;
    final maxHeight = screenSize.height * 0.8;
    final scale = math.min(
      1.0,
      math.min(maxWidth / imageSize.width, maxHeight / imageSize.height),
    );
    final displaySize = imageSize * scale;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox.fromSize(
          size: displaySize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: destination == null
                    ? null
                    : () => _openDestination(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image(image: image, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: const SizedBox.square(
                      dimension: 38,
                      child: Icon(Icons.close, color: Colors.black, size: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
