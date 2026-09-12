import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/event_progress.dart';
import '../theme/event_appearance.dart';
import 'event_point_flight.dart';

/// A compact event keepsake, with a luminous trail leading to its real chest.
class EventProgressBar extends StatefulWidget {
  const EventProgressBar(
      {super.key, required this.progress, this.onClaim, this.partnerAction});
  final EventProgress progress;
  final VoidCallback? onClaim;
  final Widget? partnerAction;
  @override
  State<EventProgressBar> createState() => _EventProgressBarState();
}

class _EventProgressBarState extends State<EventProgressBar>
    with SingleTickerProviderStateMixin {
  final _destination = GlobalKey();
  late int _points;
  late final AnimationController _glimmer =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _glimmer.stop();
    } else {
      _glimmer.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _points = widget.progress.points;
    EventPointFlight.attach();
  }

  @override
  void didUpdateWidget(covariant EventProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.progress.points - _points;
    _points = widget.progress.points;
    if (oldWidget.progress.key == widget.progress.key && delta > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        EventPointFlight.show(
            context,
            _destination,
            EventAppearance.logoForEvent(widget.progress.eventId),
            EventAppearance.forEvent(widget.progress.eventId).accent,
            delta);
      });
    }
  }

  @override
  void dispose() {
    EventPointFlight.detach();
    _glimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final s = AppStrings.of(context);
    final event = specialAdventureEventById(p.eventId)!;
    final theme = EventAppearance.forEvent(p.eventId);
    final chest = specialChestById(p.chestId)!;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
        label:
            '${s.pick(event.titleEn, event.titleNl)}: ${p.total} / ${p.target}',
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.panelColors),
                border: Border.all(color: theme.accent.withValues(alpha: .5)),
                boxShadow: [
                  BoxShadow(
                      color: theme.primary.withValues(alpha: .18),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Image.asset(EventAppearance.logoForEvent(p.eventId),
                        width: 32, height: 42, excludeFromSemantics: true),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(
                              '${p.preview ? "TEST ? " : ""}${s.pick(event.titleEn, event.titleNl)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${math.min(p.total, p.target)} / ${p.target} ${s.pick('points', 'punten')}',
                              style: TextStyle(
                                  color: theme.paper,
                                  fontSize: 11,
                                  height: 1.15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          TweenAnimationBuilder<double>(
                              key: _destination,
                              tween: Tween(end: p.fraction),
                              duration: reduced
                                  ? Duration.zero
                                  : const Duration(milliseconds: 1100),
                              curve: Curves.easeInOutCubic,
                              builder: (context, fill, child) =>
                                  AnimatedBuilder(
                                      animation: _glimmer,
                                      builder: (context, child) => CustomPaint(
                                          painter: _StarlightPainter(fill,
                                              _glimmer.value, theme.accent),
                                          child: const SizedBox(
                                              height: 12,
                                              width: double.infinity)))),
                        ])),
                    const SizedBox(width: 6),
                    Tooltip(
                        message: p.claimed
                            ? s.pick('Claimed', 'Opgehaald')
                            : s.pick('Event reward', 'Eventbeloning'),
                        child: SizedBox(
                            width: 56,
                            child: FilledButton(
                                key: Key('event-claim-${p.key}'),
                                style: FilledButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(48, 48),
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    foregroundColor: theme.paper,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                onPressed: p.canClaim ? widget.onClaim : null,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                          p.claimed
                                              ? chest.openedAssetPath
                                              : chest.closedAssetPath,
                                          height: 46,
                                          width: 52,
                                          excludeFromSemantics: true),
                                      if (p.canClaim)
                                        Text(s.pick('Claim', 'Ophalen'),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: theme.paper)),
                                      if (p.claimed)
                                        const Icon(Icons.check_rounded,
                                            size: 14, color: Colors.white70),
                                    ])))),
                  ]),
                  if (widget.partnerAction != null) ...[
                    const SizedBox(height: 5),
                    Divider(
                        height: 1, color: theme.accent.withValues(alpha: .2)),
                    widget.partnerAction!,
                  ],
                  if (p.partnerPoints > 0)
                    Text(
                        s.pick('Friend +${p.partnerPoints}',
                            'Vriend +${p.partnerPoints}'),
                        style: TextStyle(color: theme.paper, fontSize: 10)),
                ])));
  }
}

class _StarlightPainter extends CustomPainter {
  _StarlightPainter(this.fill, this.phase, this.color);
  final double fill, phase;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 1, size.width, 10);
    final track = RRect.fromRectAndRadius(bounds, const Radius.circular(6));
    canvas.drawRRect(
        track, Paint()..color = Colors.black.withValues(alpha: .3));
    canvas.drawRRect(
        track,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke);
    if (fill <= 0) return;
    final rect = Rect.fromLTWH(0, 1, size.width * fill, 10);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  colors: [color.withValues(alpha: .55), color, Colors.white])
              .createShader(rect));
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
          Offset(((i / 7 + phase) % 1) * size.width,
              6 + math.sin(i * 2 + phase * math.pi * 2) * 2),
          i.isEven ? 1 : .6,
          Paint()..color = Colors.white70);
    }
    canvas.restore();
    canvas.drawCircle(
        Offset(math.max(3, rect.right - 3), 6),
        3,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(_StarlightPainter old) =>
      fill != old.fill || phase != old.phase || color != old.color;
}

class EventRewardCard extends StatefulWidget {
  const EventRewardCard(
      {super.key, required this.progress, required this.claim});
  final EventProgress progress;
  final Future<void> Function()? claim;
  @override
  State<EventRewardCard> createState() => _EventRewardCardState();
}

class _EventRewardCardState extends State<EventRewardCard> {
  bool _busy = false;
  EventProgress get progress => widget.progress;
  Future<void> _claim() async {
    if (_busy || widget.claim == null) return;
    setState(() => _busy = true);
    try {
      await widget.claim!();
    } on Object {
      if (mounted) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.pick(
                'Could not claim the reward. Refresh and try again.',
                'De beloning kon niet worden opgehaald. Vernieuw en probeer opnieuw.'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final event = specialAdventureEventById(progress.eventId)!;
    final chest = specialChestById(progress.chestId)!;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Image.asset(chest.closedAssetPath, height: 72),
              Text(s.pick(event.titleEn, event.titleNl)),
              Text(s.pick('Event completed · ${progress.target} points',
                  'Event voltooid · ${progress.target} punten')),
              if (progress.preview)
                Text(s.pick('TEST reward preview', 'TEST-beloningvoorbeeld')),
              FilledButton(
                  onPressed: progress.canClaim && !_busy && widget.claim != null
                      ? _claim
                      : null,
                  child: Text(progress.claimed
                      ? s.pick('Claimed', 'Opgehaald')
                      : s.pick('Claim', 'Ophalen'))),
            ])));
  }
}
