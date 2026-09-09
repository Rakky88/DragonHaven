import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../theme/event_appearance.dart';

/// A newly started personal event takes priority; ties are deterministic.
SpecialAdventureWindow? appEventWindow(
    Iterable<SpecialAdventureWindow> windows, DateTime now) {
  final active = windows.where((w) => w.contains(now)).toList()
    ..sort((a, b) {
      final preview = (a.key.contains(':preview:') ? 0 : 1)
          .compareTo(b.key.contains(':preview:') ? 0 : 1);
      if (preview != 0) return preview;
      final start = b.startsAt.compareTo(a.startsAt);
      return start == 0 ? a.key.compareTo(b.key) : start;
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
  const SeasonalAppLogo({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) => Image.asset(
        EventAppearance.logoForEvent(eventId),
        key: const Key('app-event-logo'),
        width: 48,
        height: 48,
        fit: BoxFit.contain,
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
          gradient: LinearGradient(colors: appearance.panelColors)),
      child: LayoutBuilder(builder: (context, constraints) {
        final title =
            s.pick(widget.window.event.titleEn, widget.window.event.titleNl);
        final timer = '${s.pick('Ends in', 'Nog')} $clock';
        final testLabel = s.pick('Test event', 'Testevent');
        final titleStyle = DefaultTextStyle.of(context).style.merge(
            const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12));
        // A pale timer stays readable on every event's darkest panel.
        final clockStyle = titleStyle.copyWith(
            color: Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()]);
        double width(String text, TextStyle style) {
          final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context))
            ..layout();
          final result = painter.width.ceilToDouble();
          painter.dispose();
          return result;
        }

        final officialWidth =
            width(title, titleStyle) + 12 + width(timer, clockStyle);
        final spare = constraints.maxWidth - officialWidth;
        Widget previewLabel(double available) => SizedBox(
            width: available.clamp(0, width(testLabel, titleStyle)),
            child: Text(testLabel,
                key: const Key('event-preview-label'),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: titleStyle.copyWith(color: Colors.white70)));
        final titleText = Text(title,
            key: const Key('event-countdown-title'), style: titleStyle);
        final clockText = Text(timer,
            key: const Key('event-countdown-clock'), style: clockStyle);
        if (spare >= 0) {
          return Row(children: [
            titleText,
            const Spacer(),
            if (preview && spare > 8) ...[
              previewLabel(spare - 8),
              const SizedBox(width: 8)
            ],
            const SizedBox(width: 12),
            clockText,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          titleText,
          const SizedBox(height: 3),
          clockText,
        ]);
      }),
    );
  }
}
