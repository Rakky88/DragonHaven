import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';

class CompactEggHatchTime extends StatefulWidget {
  const CompactEggHatchTime({super.key, required this.egg});

  final Pet egg;

  @override
  State<CompactEggHatchTime> createState() => _CompactEggHatchTimeState();
}

class _CompactEggHatchTimeState extends State<CompactEggHatchTime>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void didUpdateWidget(covariant CompactEggHatchTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.egg.id != widget.egg.id ||
        oldWidget.egg.stageStartedAt != widget.egg.stageStartedAt) {
      _refresh();
    }
  }

  void _refresh() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hatchAt =
        widget.egg.stageStartedAt.add(widget.egg.incubationDuration);
    final remaining =
        hatchAt.isAfter(_now) ? hatchAt.difference(_now) : Duration.zero;
    final value = formatCompactEggHatchTime(remaining);
    final strings = AppStrings.of(context);
    return Semantics(
      label: strings.pick('Hatches in $value', 'Komt uit over $value'),
      child: Text(
        value,
        key: const Key('tower-nest-hatch-remaining'),
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

String formatCompactEggHatchTime(Duration duration) {
  final roundedUpSeconds = duration <= Duration.zero
      ? 0
      : (duration.inMicroseconds + Duration.microsecondsPerSecond - 1) ~/
          Duration.microsecondsPerSecond;
  final hours = roundedUpSeconds ~/ Duration.secondsPerHour;
  final minutes =
      (roundedUpSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final seconds = roundedUpSeconds % Duration.secondsPerMinute;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(hours)}:${two(minutes)}:${two(seconds)}';
}
