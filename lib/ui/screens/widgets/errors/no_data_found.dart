import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class NoDataFound extends StatelessWidget {
  final double? height;
  final String? mainMessage;
  final String? subMessage;
  final VoidCallback? onTap;
  final double? mainMsgStyle;
  final double? subMsgStyle;
  final bool? showImage;
  final bool? showBtn;
  final String? btnName;

  const NoDataFound({
    super.key,
    this.onTap,
    this.height,
    this.mainMessage,
    this.subMessage,
    this.mainMsgStyle,
    this.subMsgStyle,
    this.showImage,
    this.showBtn = false,
    this.btnName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.55;

        return InkWell(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: availableHeight,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showImage != false)
                      UiUtils.getSvg(
                        AppIcons.no_data_found,
                        height: height,
                        color: territoryColor_,
                      ),
                    const SizedBox(height: 20),
                    CustomText(
                      mainMessage ?? "nodatafound".translate(context),
                      fontSize: mainMsgStyle ?? context.font.normal,
                      color: context.color.territoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      subMessage ?? "sorryLookingFor".translate(context),
                      fontSize: subMsgStyle ?? context.font.normal,
                      textAlign: TextAlign.center,
                    ),
                    if (showBtn == true && onTap != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: UiUtils.buildButton(
                          context,
                          onPressed: onTap!,
                          buttonTitle: btnName ?? "",
                          height: 40,
                          width: MediaQuery.of(context).size.width / 1.5,
                          radius: 8,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
