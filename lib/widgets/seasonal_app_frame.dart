import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../theme/event_appearance.dart';

/// Actual events take priority over personal previews; ties are deterministic.
SpecialAdventureWindow? appEventWindow(
    Iterable<SpecialAdventureWindow> windows, DateTime now) {
  final active = windows.where((w) => w.contains(now)).toList()
    ..sort((a, b) {
      final preview = (a.key.contains(':preview:') ? 1 : 0)
          .compareTo(b.key.contains(':preview:') ? 1 : 0);
      if (preview != 0) return preview;
      final end = a.endsAt.compareTo(b.endsAt);
      return end == 0 ? a.key.compareTo(b.key) : end;
    });
  return active.firstOrNull;
}

class SeasonalAppFrame extends InheritedWidget {
  const SeasonalAppFrame(
      {super.key, required this.window, required super.child});
  final SpecialAdventureWindow? window;

  static SpecialAdventureWindow? windowOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SeasonalAppFrame>()?.window;

  @override
  bool updateShouldNotify(SeasonalAppFrame oldWidget) =>
      oldWidget.window?.key != window?.key;
}

class EventBackdrop extends StatelessWidget {
  const EventBackdrop(
      {super.key, required this.appearance, required this.child});
  final EventAppearance appearance;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned.fill(
            child: IgnorePointer(
                child: DecoratedBox(
          key: const Key('app-event-background'),
          decoration: BoxDecoration(
            color: appearance.paper,
            image: appearance.background == null
                ? null
                : DecorationImage(
                    image: AssetImage(appearance.background!),
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
          ),
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appearance.paper.withValues(alpha: .95),
              appearance.paper.withValues(alpha: .89),
              appearance.paper.withValues(alpha: .80)
            ],
          ))),
        ))),
        child,
      ]);
}

class SeasonalAppLogo extends StatelessWidget {
  const SeasonalAppLogo({super.key, required this.appearance});
  final EventAppearance appearance;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 48,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
              child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  RadialGradient(colors: [Colors.white, appearance.paper]),
              border: Border.all(color: appearance.accent, width: 1.8),
              boxShadow: [
                BoxShadow(
                    color: appearance.accent.withValues(alpha: .35),
                    blurRadius: 12)
              ],
            ),
            child: Image.asset('assets/images/dragonhaven_logo.png',
                fit: BoxFit.contain),
          )),
          Positioned(
              right: -3,
              bottom: -2,
              child: Container(
                key: const Key('app-event-logo-emblem'),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appearance.primary,
                    border: Border.all(color: appearance.accent)),
                child: appearance.emblem == null
                    ? Icon(appearance.motif, color: appearance.accent, size: 17)
                    : Padding(
                        padding: const EdgeInsets.all(1),
                        child: Image.asset(appearance.emblem!,
                            fit: BoxFit.contain)),
              )),
        ]),
      );
}

class EventCountdownBanner extends StatefulWidget {
  const EventCountdownBanner(
      {super.key, required this.window, required this.now});
  final SpecialAdventureWindow window;
  final DateTime Function() now;

  @override
  State<EventCountdownBanner> createState() => _EventCountdownBannerState();
}

class _EventCountdownBannerState extends State<EventCountdownBanner> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.window.endsAt.difference(widget.now());
    if (remaining <= Duration.zero) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final appearance = EventAppearance.forEvent(widget.window.event.id);
    final days = remaining.inDays;
    final hours = (remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final clock = '${days > 0 ? '${days}d ' : ''}$hours:$minutes:$seconds';
    final preview = widget.window.key.contains(':preview:');
    return Container(
      key: const Key('app-event-countdown'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        appearance.primary,
        Color.lerp(appearance.primary, Colors.black, .18)!,
      ])),
      child: Wrap(
          spacing: 12,
          runSpacing: 3,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                s.pick(
                    widget.window.event.titleEn, widget.window.event.titleNl),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            Text(
                '${preview ? s.pick('Test event · ', 'Testevent · ') : ''}${s.pick('Ends in', 'Nog')} $clock',
                style: TextStyle(
                    color: appearance.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
    );
  }
}
