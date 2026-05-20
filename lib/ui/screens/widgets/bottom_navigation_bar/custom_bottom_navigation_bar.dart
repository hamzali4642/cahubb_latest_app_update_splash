import 'dart:io';

import 'package:eClassify/ui/screens/widgets/bottom_navigation_bar/svg_color_mapper.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Custom Navigation bar that gives space to the centerDocked FAB button
class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({
    required this.controller,
    super.key,
  });

  final BottomNavigationController controller;

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState
    extends State<CustomBottomNavigationBar> {
  final items = [
    _BottomNavigationItem(
      icon: AppIcons.homeNav,
      activeIcon: AppIcons.homeNavActive,
      label: 'homeTab',
    ),
    _BottomNavigationItem(
      icon: AppIcons.chatNav,
      activeIcon: AppIcons.chatNavActive,
      label: 'chat',
    ),

    // Space for FAB
    null,

    _BottomNavigationItem(
      icon: AppIcons.myAdsNav,
      activeIcon: AppIcons.myAdsNavActive,
      label: 'myAdsTab',
    ),
    _BottomNavigationItem(
      icon: AppIcons.profileNav,
      activeIcon: AppIcons.profileNavActive,
      label: 'profileTab',
    ),
  ];

  @override
  Widget build(BuildContext context) {
double bottomNavHeight = 78;
    if (Platform.isIOS) {
      bottomNavHeight += MediaQuery.paddingOf(context).bottom;
    }

    return SafeArea(
  bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SizedBox(
          height: bottomNavHeight,
          child: Container(
            decoration: BoxDecoration(
color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                final selectedIndex = widget.controller.index;

                int itemIndex = 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: items.map((item) {
                    if (item == null) {
                      return const SizedBox(width: 40);
                    }

                    final index = itemIndex++;

                    return Expanded(
                      child: _BottomNavigationItemWidget(
                        item: item,
                        selected: selectedIndex == index,
                        onPressed: () {
                          if (item.label == 'chat' ||
                              item.label == 'myAdsTab') {
                            UiUtils.checkUser(
                              onNotGuest: () {
                                widget.controller.changeIndex(index);
                              },
                              context: context,
                            );
                          } else {
                            widget.controller.changeIndex(index);
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavigationController extends ChangeNotifier {
  int index = 0;

  void changeIndex(int index) {
    this.index = index;
    notifyListeners();
  }
}

class _BottomNavigationItemWidget extends StatelessWidget {
  const _BottomNavigationItemWidget({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _BottomNavigationItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
    style: TextButton.styleFrom(
  overlayColor: Colors.transparent,
  padding: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(0),
  ),
),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            selected ? item.activeIcon : item.icon,
            height: 24,
            width: 24,
            colorMapper: SvgColorMapper(),
           colorFilter: ColorFilter.mode(
  selected
      ? const Color(0xFFC9A227)
      : Colors.white70,
  BlendMode.srcIn,
),
          ),

          const SizedBox(height: 4),

          CustomText(
            item.label.translate(context),
            maxLines: 1,
            textAlign: TextAlign.center,
color: Colors.white,
                fontSize: 12,
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationItem {
  _BottomNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String icon;
  final String activeIcon;
  final String label;
}