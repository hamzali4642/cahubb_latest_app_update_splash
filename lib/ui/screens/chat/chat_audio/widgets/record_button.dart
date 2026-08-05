import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:eClassify/ui/screens/chat/chat_audio/audio_state.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/globals.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/widgets/flow_shader.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/widgets/lottie_animation.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    required this.controller,
    required this.callback,
    required this.isSending,
  });

  final AnimationController controller;
  final Function(dynamic path)? callback;
  final bool isSending;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  static const double size = 43;

  final LayerLink _buttonLayerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final double lockerHeight = 150;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  late AudioRecorder record;

  //final record = AudioRecorder();

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    record = AudioRecorder();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _overlayController.show();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 2 * ChatGlobals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(
          begin: timerWidth + ChatGlobals.defaultPadding,
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: widget.controller,
            curve: const Interval(0.2, 1, curve: Curves.easeIn),
          ),
        );
    lockerAnimation = Tween<double>(begin: -lockerHeight, end: size + 8)
        .animate(
          CurvedAnimation(
            parent: widget.controller,
            curve: const Interval(0.2, 1, curve: Curves.easeIn),
          ),
        );
  }

  @override
  void dispose() {
    record.dispose();
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildRecordingOverlay,
      child: CompositedTransformTarget(
        link: _buttonLayerLink,
        child: audioButton(),
      ),
    );
  }

  Widget _buildRecordingOverlay(BuildContext overlayContext) {
    final isRecording = timer?.isActive ?? false;
    final textDirection = Directionality.of(context);
    final topEnd = AlignmentDirectional.topEnd.resolve(textDirection);
    final centerEnd = AlignmentDirectional.centerEnd.resolve(textDirection);
    final horizontalDirection = textDirection == TextDirection.ltr ? 1.0 : -1.0;

    return Stack(
      children: [
        if (isRecording && !isLocked) ...[
          CompositedTransformFollower(
            link: _buttonLayerLink,
            showWhenUnlinked: false,
            targetAnchor: topEnd,
            followerAnchor: AlignmentDirectional.bottomEnd.resolve(
              textDirection,
            ),
            offset: Offset(0, size - lockerAnimation.value),
            child: IgnorePointer(child: lockSlider()),
          ),
          CompositedTransformFollower(
            link: _buttonLayerLink,
            showWhenUnlinked: false,
            targetAnchor: topEnd,
            followerAnchor: topEnd,
            offset: Offset(timerAnimation.value * horizontalDirection, 0),
            child: IgnorePointer(child: cancelSlider()),
          ),
        ],
        if (isLocked)
          CompositedTransformFollower(
            link: _buttonLayerLink,
            showWhenUnlinked: false,
            targetAnchor: centerEnd,
            followerAnchor: centerEnd,
            child: Material(
              type: MaterialType.transparency,
              child: timerLocked(),
            ),
          ),
      ],
    );
  }

  Widget lockSlider() {
    return Container(
      height: lockerHeight,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
        color: context.color.secondaryColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.lock, size: 20),
          const SizedBox(height: 8),
          FlowShader(
            direction: Axis.vertical,
            child: const Column(
              children: [
                Icon(Icons.keyboard_arrow_up),
                Icon(Icons.keyboard_arrow_up),
                Icon(Icons.keyboard_arrow_up),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cancelSlider() {
    return Container(
      height: size,
      width: timerWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
        color: context.color.primaryColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            showLottie ? const LottieAnimation() : CustomText(recordDuration),
            FlowShader(
              duration: const Duration(seconds: 3),
              flowColors: [
                context.color.territoryColor,
                const Color(0xFF9E9E9E),
              ],
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_sharp, size: 14),
                  CustomText("slidetocancel".translate(context)),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            const SizedBox(width: size),
          ],
        ),
      ),
    );
  }

  Widget timerLocked() {
    return Container(
      height: size,
      width: timerWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
        color: context.color.secondaryColor,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Discard recording',
              onPressed: _discardRecording,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            Expanded(
              child: CustomText(
                recordDuration,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Send recording',
              onPressed: () async {
                await saveFile();
                if (mounted) setState(() => isLocked = false);
              },
              icon: Icon(
                Icons.send_rounded,
                color: context.color.territoryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.isSending) return;

        bool hasPermission = await record.hasPermission();
        if (!hasPermission) {
          showPermissionDeniedSnackbar();
          return;
        }

        await startRecording();
      },
      child: Transform.scale(
        scale: buttonScaleAnimation.value,
        child: Container(
          height: size,
          width: size,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.color.territoryColor,
          ),
          child: widget.isSending
              ? CircularProgressIndicator()
              : Icon(Icons.mic, color: Colors.white),
        ),
      ),
      onLongPressDown: (_) {
        if (widget.isSending) return;

        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        if (widget.isSending) return;

        if (isCancelled(details.localPosition, context)) {
          // if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.heavy);
          Vibration.vibrate();
          timer?.cancel();
          timer = null;
          //startTime = null;
          recordDuration = "00:00";

          setState(() {
            showLottie = true;
          });

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();

            var filePath = await record.stop();

            File(filePath!).delete();
            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();

          //if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.heavy);
          Vibration.vibrate();
          setState(() {
            isLocked = true;
          });
        } else {
          widget.controller.reverse();
          saveFile();
        }
      },
      onLongPressCancel: () {
        if (widget.isSending) return;
        widget.controller.reverse();
      },
      onLongPress: () async {
        if (widget.isSending) return;
        bool hasPermission = await record.hasPermission();
        if (!hasPermission) {
          showPermissionDeniedSnackbar();
          return;
        }
        Vibration.vibrate();
        await startRecording();
      },
    );
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
      growable: false,
    ).join();
  }

  Future<void> startRecording() async {
    if (await record.hasPermission()) {
      try {
        String filePath = await getApplicationDocumentsDirectory().then(
          (value) => '${value.path}/${_generateRandomId()}.wav',
        );

        await record.start(
          const RecordConfig(
            // specify the codec to be `.wav`
            encoder: AudioEncoder.wav,
          ),
          path: filePath,
        );
      } catch (e) {
        debugPrint('ERROR WHILE RECORDING: $e');
      }

      startTime = DateTime.now();

      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final minDur = DateTime.now().difference(startTime!).inMinutes;
        final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
        String min = minDur < 10 ? "0$minDur" : minDur.toString();
        String sec = secDur < 10 ? "0$secDur" : secDur.toString();

        setState(() {
          recordDuration = "$min:$sec";
        });
      });
    }
  }

  Future<void> saveFile() async {
    Vibration.vibrate();
    timer?.cancel();
    timer = null;
    startTime = null;
    recordDuration = "00:00";

    var filePath = await record.stop();

    // Reinitialize recorder to fix the issue for next recordings
    setState(() {
      record = AudioRecorder();
    });

    AudioState.files.add(filePath!);
    if (ChatGlobals.audioListKey.currentState != null) {
      ChatGlobals.audioListKey.currentState!.insertItem(
        AudioState.files.length - 1,
      );
    }

    final fileAudio = File(filePath);
    widget.callback!(fileAudio.path);
  }

  Future<void> _discardRecording() async {
    Vibration.vibrate();
    timer?.cancel();
    timer = null;
    startTime = null;
    recordDuration = "00:00";

    final filePath = await record.stop();
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    }
    record = AudioRecorder();
    widget.controller.reverse();
    if (mounted) {
      setState(() {
        isLocked = false;
        showLottie = false;
      });
    }
  }

  void showPermissionDeniedSnackbar() {
    HelperUtils.showSnackBarMessage(
      context,
      'microphonePermissionIsDeniedEnableIt'.translate(context),
      snackBarAction: SnackBarAction(
        textColor: context.color.secondaryColor,
        label: 'settingsLbl'.translate(context),
        onPressed: () {
          openAppSettings();
        },
      ),
    );
  }

  bool checkIsLocked(Offset offset) {
    return offset.dy < -70 && offset.dx.abs() < size;
  }

  bool isCancelled(Offset offset, BuildContext context) {
    final threshold = MediaQuery.sizeOf(context).width * .2;
    if (Directionality.of(context) == TextDirection.ltr) {
      return (offset.dx < -threshold);
    } else {
      return (offset.dx > threshold);
    }
  }
}
