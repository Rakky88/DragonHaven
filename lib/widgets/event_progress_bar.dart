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
    EventPointFlight.trialRewards.addListener(_trialReward);
  }

  void _trialReward() {
    final points =
        EventPointFlight.trialRewards.value[widget.progress.key] ?? 0;
    if (points <= 0 || !mounted) return;
    EventPointFlight.show(
        context,
        _destination,
        EventAppearance.logoForEvent(widget.progress.eventId),
        EventAppearance.forEvent(widget.progress.eventId).accent,
        points);
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
    EventPointFlight.trialRewards.removeListener(_trialReward);
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
      child: SizedBox(
          height: 58,
          child: Row(children: [
            Expanded(
                child: TweenAnimationBuilder<double>(
              key: _destination,
              tween: Tween(end: p.fraction),
              duration:
                  reduced ? Duration.zero : const Duration(milliseconds: 1100),
              curve: Curves.easeInOutCubic,
              builder: (context, fill, child) =>
                  Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                    child: AnimatedBuilder(
                        animation: _glimmer,
                        builder: (context, child) => CustomPaint(
                            painter: _ElixirPainter(fill, _glimmer.value, theme,
                                p.eventId, fill >= 1 && p.canClaim)))),
                if (fill >= 1 && p.complete)
                  Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: p.claimed
                            ? s.pick('Claimed', 'Opgehaald')
                            : s.pick('Claim', 'Ophalen'),
                        child: SizedBox.square(
                            dimension: 52,
                            child: FilledButton(
                              key: Key('event-claim-${p.key}'),
                              style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: theme.primary,
                                  shape: const CircleBorder()),
                              onPressed: p.canClaim ? widget.onClaim : null,
                              child: Image.asset(
                                  p.claimed
                                      ? chest.openedAssetPath
                                      : chest.closedAssetPath,
                                  width: 46,
                                  height: 42,
                                  excludeFromSemantics: true),
                            )),
                      )),
              ]),
            )),
            if (widget.partnerAction != null)
              SizedBox(width: 48, child: widget.partnerAction!),
          ])),
    );
  }
}

/// A glass reservoir in engraved metal, with event-colored liquid and motifs.
/// The whole instrument is painted at its final size; no oversized card surface.
class _ElixirPainter extends CustomPainter {
  _ElixirPainter(this.fill, this.phase, this.theme, this.eventId, this.ready);
  final double fill, phase;
  final EventAppearance theme;
  final String eventId;
  final bool ready;
  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final left = 5.0, right = size.width - 5;
    if (right <= left) return;
    final gold = Color.lerp(theme.accent, const Color(0xFFD7B970), .65)!;
    final outer = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, mid - 14, right, mid + 14),
        const Radius.circular(14));
    canvas.drawRRect(
        outer.shift(const Offset(0, 3)),
        Paint()
          ..color = theme.primary.withValues(alpha: .35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawRRect(
        outer,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF9E9B8),
                gold,
                const Color(0xFF655032),
                gold
              ]).createShader(outer.outerRect));
    final chamber = Rect.fromLTRB(left + 3, mid - 10, right - 3, mid + 10);
    final glass = RRect.fromRectAndRadius(chamber, const Radius.circular(10));
    canvas.drawRRect(
        glass,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(theme.primary, Colors.black, .65)!,
                theme.primary,
                Color.lerp(theme.primary, Colors.black, .4)!
              ]).createShader(chamber));
    canvas.save();
    canvas.clipRRect(glass);
    final liquidEnd = chamber.left + chamber.width * fill;
    if (fill > 0) {
      final liquid = Path()
        ..moveTo(chamber.left, chamber.top)
        ..lineTo(liquidEnd, chamber.top);
      for (var y = 0.0; y <= chamber.height; y += 1) {
        liquid.lineTo(liquidEnd + math.sin(y * .24 + phase * math.pi * 2) * 1.6,
            chamber.top + y);
      }
      liquid
        ..lineTo(chamber.left, chamber.bottom)
        ..close();
      canvas.drawPath(
          liquid,
          Paint()
            ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(theme.accent, Colors.white, .85)!,
                  theme.accent,
                  Color.lerp(theme.accent, theme.primary, .5)!
                ]).createShader(chamber));
      canvas.save();
      canvas.clipPath(liquid);
      for (var i = 0; i < 9; i++) {
        final x = chamber.left + ((i / 9 + phase * .22) % 1) * chamber.width;
        final y = mid + math.sin(i * 2 + phase * math.pi * 2) * 5;
        canvas.drawCircle(Offset(x, y), i.isEven ? 1.2 : .65,
            Paint()..color = Colors.white60);
      }
      canvas.restore();
      canvas.drawOval(
          Rect.fromCenter(center: Offset(liquidEnd, mid), width: 4, height: 15),
          Paint()
            ..color = Colors.white.withValues(alpha: .65)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
    // The glass reflection spans empty and full sections alike.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(chamber.left + 6, chamber.top + 2, chamber.right - 6,
                chamber.top + 5),
            const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
                  colors: [Colors.white10, Colors.white38, Colors.white10])
              .createShader(chamber));
    for (var i = 1; i < 10; i++) {
      final x = chamber.left + chamber.width * i / 10;
      canvas.drawLine(
          Offset(x, chamber.bottom - 1),
          Offset(x, chamber.bottom - (i == 5 ? 5 : 3)),
          Paint()
            ..color = gold.withValues(alpha: .45)
            ..strokeWidth = 1);
    }
    canvas.restore();
    // Symmetric engraved tendrils frame the instrument without adding height.
    for (final flip in [false, true]) {
      canvas.save();
      if (flip) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      final line = Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      for (final sign in [-1.0, 1.0]) {
        final vine = Path()
          ..moveTo(19, mid + sign * 17)
          ..cubicTo(
              40, mid + sign * 28, 49, mid + sign * 13, 68, mid + sign * 18)
          ..quadraticBezierTo(83, mid + sign * 22, 95, mid + sign * 17);
        canvas.drawPath(vine, line);
        _motif(canvas, Offset(56, mid + sign * 20), gold, sign);
      }
      canvas.restore();
    }
    if (ready) {
      canvas.drawCircle(
          Offset(size.width - 27, mid),
          22,
          Paint()
            ..color = theme.accent
                .withValues(alpha: .2 + .1 * math.sin(phase * math.pi * 2))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  void _motif(Canvas canvas, Offset at, Color color, double sign) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    final p = Paint()..color = color.withValues(alpha: .9);
    final path = Path();
    if (eventId.contains('valentine')) {
      path
        ..moveTo(0, 3)
        ..cubicTo(-9, -2, -3, -6, 0, -2)
        ..cubicTo(3, -6, 9, -2, 0, 3);
    } else if (eventId.contains('halloween')) {
      path
        ..moveTo(-6, 1)
        ..lineTo(-5, -3)
        ..lineTo(-1, -1)
        ..lineTo(0, -3)
        ..lineTo(1, -1)
        ..lineTo(5, -3)
        ..lineTo(6, 1)
        ..lineTo(2, 0)
        ..lineTo(0, 3)
        ..lineTo(-2, 0)
        ..close();
    } else if (eventId.contains('christmas')) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var i = 0; i < 3; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 3);
        canvas.drawLine(const Offset(-4, 0), const Offset(4, 0), p);
        canvas.restore();
      }
    } else {
      path
        ..moveTo(0, -4)
        ..lineTo(1.4, -1.4)
        ..lineTo(4, 0)
        ..lineTo(1.4, 1.4)
        ..lineTo(0, 4)
        ..lineTo(-1.4, 1.4)
        ..lineTo(-4, 0)
        ..lineTo(-1.4, -1.4)
        ..close();
    }
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ElixirPainter old) =>
      fill != old.fill ||
      phase != old.phase ||
      theme != old.theme ||
      ready != old.ready ||
      eventId != old.eventId;
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
