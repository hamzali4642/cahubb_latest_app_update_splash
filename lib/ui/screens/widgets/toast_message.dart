import 'package:flutter/material.dart';

class ToastMessage extends StatefulWidget {
  const ToastMessage({
    required this.errorMessage,
    required this.backgroundColor,
    super.key,
  });

  final String errorMessage;
  final Color backgroundColor;

  @override
  State<ToastMessage> createState() => _ToastMessageState();
}

class _ToastMessageState extends State<ToastMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late Animation<double> slideAnimation = Tween<double>(begin: -0.5, end: 1)
      .animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOutCirc,
        ),
      );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 2500), () {
      animationController.reverse();
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        final height = MediaQuery.sizeOf(context).height;
        return PositionedDirectional(
          start: width * 0.1,
          bottom: height * 0.07 * (slideAnimation.value),
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: FadeTransition(
              opacity: slideAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  alignment: AlignmentDirectional.center,
                  width: width * 0.8,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.errorMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
