import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _FileType { network, asset, file }

class CustomImage extends StatefulWidget {
  const CustomImage({
    required this.src,
    this.fit = BoxFit.contain,
    this.size,
    this.resolution,
    this.placeHolder,
    this.errorImage,
    this.svgColorMapper,
    super.key,
  });

  final String src;
  final BoxFit fit;
  final Size? size;
  final Size? resolution;
  final Widget? placeHolder;
  final Widget? errorImage;

  // This is ignored if the src has type other than SVG
  final ColorMapper? svgColorMapper;

  @override
  State<CustomImage> createState() => _CustomImageState();
}

class _CustomImageState extends State<CustomImage> {
  late bool _isSvg;
  late _FileType _fileType;

  late Widget placeHolderImage;
  late Widget errorImage;

  double? get height => widget.size?.height;
  double? get width => widget.size?.width;

  Size? get res => widget.resolution ?? widget.size;
  Color get _defaultSvgTint =>
      AppSession.isDarkMode ? territoryColorDark : territoryColor_;

  @override
  void initState() {
    super.initState();
    _resolveImageProvider(widget.src);
    placeHolderImage =
        widget.placeHolder ??
        SvgPicture.asset(
          AppIcons.placeHolder,
          height: height,
          width: width,
          fit: widget.fit,
          colorFilter: ColorFilter.mode(_defaultSvgTint, BlendMode.srcIn),
        );
    errorImage =
        widget.errorImage ??
        SvgPicture.asset(
          AppIcons.placeHolder,
          height: height,
          width: width,
          fit: widget.fit,
          colorFilter: ColorFilter.mode(_defaultSvgTint, BlendMode.srcIn),
        );
  }

  @override
  void didUpdateWidget(covariant CustomImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _resolveImageProvider(widget.src);
    }
    if (oldWidget.errorImage != widget.errorImage ||
        oldWidget.placeHolder != widget.placeHolder) {
      placeHolderImage =
          widget.placeHolder ??
          SvgPicture.asset(
            AppIcons.placeHolder,
            height: height,
            width: width,
            fit: widget.fit,
            colorFilter: ColorFilter.mode(_defaultSvgTint, BlendMode.srcIn),
          );
      errorImage =
          widget.errorImage ??
          SvgPicture.asset(
            AppIcons.placeHolder,
            height: height,
            width: width,
            fit: widget.fit,
            colorFilter: ColorFilter.mode(_defaultSvgTint, BlendMode.srcIn),
          );
    }
  }

  void _resolveImageProvider(String src) {
    final uri = Uri.tryParse(src);
    if (uri == null) return;

    if (uri.hasScheme && ['http', 'https'].contains(uri.scheme)) {
      _fileType = _FileType.network;
    } else if (uri.path.contains('assets')) {
      _fileType = _FileType.asset;
    } else {
      _fileType = _FileType.file;
    }
    _isSvg = uri.pathSegments.lastOrNull?.endsWith('svg') ?? false;
  }

  double clampSize(double size, double dpr) {
    final scaledSize = size * dpr;
    return min(scaledSize, 700);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      final colorFilter = widget.svgColorMapper == null
          ? ColorFilter.mode(_defaultSvgTint, BlendMode.srcIn)
          : null;
      return switch (_fileType) {
        _FileType.asset => SvgPicture.asset(
          widget.src,
          height: height,
          width: width,
          fit: widget.fit,
          errorBuilder: (_, _, _) => errorImage,
          placeholderBuilder: (_) => placeHolderImage,
          colorFilter: colorFilter,
          colorMapper: widget.svgColorMapper,
        ),
        _FileType.network => SvgPicture.network(
          widget.src,
          height: height,
          width: width,
          fit: widget.fit,
          errorBuilder: (_, _, _) => errorImage,
          placeholderBuilder: (_) => placeHolderImage,
          colorFilter: colorFilter,
          colorMapper: widget.svgColorMapper,
        ),
        _FileType.file => SvgPicture.file(
          File(widget.src),
          height: height,
          width: width,
          fit: widget.fit,
          errorBuilder: (_, _, _) => errorImage,
          placeholderBuilder: (_) => placeHolderImage,
          colorFilter: colorFilter,
          colorMapper: widget.svgColorMapper,
        ),
      };
    } else {
      var dpr = MediaQuery.of(context).devicePixelRatio;
      dpr = min(dpr, 2.5);

      final int? cacheWidth = res != null
          ? clampSize(res!.width, dpr).toInt()
          : null;
      final int? cacheHeight = res != null
          ? clampSize(res!.height, dpr).toInt()
          : null;

      return switch (_fileType) {
        _FileType.asset => Image.asset(
          widget.src,
          height: height,
          width: width,
          fit: widget.fit,
          cacheHeight: cacheHeight,
          cacheWidth: cacheWidth,
          errorBuilder: (_, _, _) => errorImage,
        ),
        _FileType.network => CachedNetworkImage(
          imageUrl: widget.src,
          height: height,
          width: width,
          fit: widget.fit,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          maxWidthDiskCache: cacheWidth,
          maxHeightDiskCache: cacheHeight,
          errorWidget: (_, _, _) => errorImage,
          placeholder: (_, _) => placeHolderImage,
        ),
        _FileType.file => Image.file(
          File(widget.src),
          height: height,
          width: width,
          fit: widget.fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (_, _, _) => errorImage,
        ),
      };
    }
  }
}
