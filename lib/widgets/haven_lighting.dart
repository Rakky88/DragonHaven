import 'dart:async';

import 'package:flutter/material.dart';

import '../models/day_phase.dart';

typedef PhaseAssetBuilder = String Function(HavenDayPhase phase);
typedef HavenClockWidgetBuilder = Widget Function(
  BuildContext context,
  DateTime now,
  HavenDayPhase phase,
);

class HavenClockBuilder extends StatefulWidget {
  const HavenClockBuilder({super.key, required this.builder});
  final HavenClockWidgetBuilder builder;

  @override
  State<HavenClockBuilder> createState() => _HavenClockBuilderState();
}

class _HavenClockBuilderState extends State<HavenClockBuilder>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
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
  Widget build(BuildContext context) =>
      widget.builder(context, _now, havenDayPhaseAt(_now));
}

/// Displays separately painted lighting states and blends them through the
/// twenty-minute transition window around each configured phase boundary.
class HavenPhaseImage extends StatefulWidget {
  const HavenPhaseImage({
    super.key,
    required this.assetFor,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final PhaseAssetBuilder assetFor;
  final BoxFit fit;
  final Alignment alignment;

  @override
  State<HavenPhaseImage> createState() => _HavenPhaseImageState();
}

class _HavenPhaseImageState extends State<HavenPhaseImage>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final phase in HavenDayPhase.values) {
      precacheImage(AssetImage(widget.assetFor(phase)), context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
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
    final lighting = havenLightingAt(_now);
    final from = Image.asset(
      widget.assetFor(lighting.from),
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    );
    if (lighting.from == lighting.to) return from;
    return Stack(fit: StackFit.expand, children: [
      from,
      Opacity(
        opacity: lighting.progress,
        child: Image.asset(
          widget.assetFor(lighting.to),
          fit: widget.fit,
          alignment: widget.alignment,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    ]);
  }
}
