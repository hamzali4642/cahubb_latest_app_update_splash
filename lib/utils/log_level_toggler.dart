import 'package:eClassify/utils/collection_notifiers.dart';
import 'package:eClassify/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LogLevelToggler extends StatefulWidget {
  const LogLevelToggler({super.key});

  @override
  State<LogLevelToggler> createState() => _LogLevelTogglerState();
}

class _LogLevelTogglerState extends State<LogLevelToggler> {
  final List<Level> _levels = Level.values;
  late final SetNotifier<Level> _activeLogEvents;

  @override
  void initState() {
    super.initState();
    _activeLogEvents = SetNotifier(_levels.sublist(Log.level.index));
  }

  void _changeLogLevels(Level? level) {
    Log.level = level ?? Level.off;
    if (level == null) {
      _activeLogEvents.clear();
      return;
    }
    final activeLogs = _levels.sublist(level.index);
    _activeLogEvents
      ..clear()
      ..addAll(activeLogs);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          isDismissible: true,
          builder: (_) {
            return ListView(
              children: Level.values.map((level) {
                return ListenableBuilder(
                  listenable: _activeLogEvents,
                  builder: (context, value) {
                    return CheckboxListTile(
                      value: _activeLogEvents.contains(level),
                      title: Text(level.name),
                      onChanged: (value) {
                        if (value == null) return;
                        if (value) {
                          _changeLogLevels(level);
                        } else {
                          final unselectedLogIndex = level.index;
                          final nextLevel =
                              unselectedLogIndex == _levels.length - 1
                              ? null
                              : _levels[unselectedLogIndex + 1];
                          _changeLogLevels(nextLevel);
                        }
                      },
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
      icon: Icon(Icons.bug_report),
    );
  }
}
