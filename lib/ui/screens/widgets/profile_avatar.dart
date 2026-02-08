import 'package:eClassify/ui/screens/widgets/custom_image.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/extensions/lib/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.src, super.key});

  final String src;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (src.isNotEmpty) {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              fullscreenDialog: true,
              barrierColor: Colors.black54,
              barrierDismissible: true,
              pageBuilder: (_, _, _) => Center(
                child: Hero(
                  tag: 'profile',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: CustomImage(
                      src: src,
                      size: Size.square(200),
                      resolution: Size.square(200),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
      child: Hero(
        tag: 'profile',
        child: CircleAvatar(
          radius: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CustomImage(
              src: src,
              size: Size.square(40),
              fit: BoxFit.cover,
              errorImage: SvgPicture.asset(
                AppIcons.profile,
                colorFilter: ColorFilter.mode(
                  context.color.buttonColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
