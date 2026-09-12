import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/event_progress.dart';
import '../theme/event_appearance.dart';

/// A liquid starlight trail and orbiting reward seal, themed for each event.
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
  late final AnimationController _orbit =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _orbit.stop();
    } else {
      _orbit.repeat();
    }
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final s = AppStrings.of(context);
    final event = specialAdventureEventById(p.eventId)!;
    final theme = EventAppearance.forEvent(p.eventId);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
        label:
            '${s.pick(event.titleEn, event.titleNl)}: ${p.total} / ${p.target}',
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: theme.panelColors),
                border: Border.all(color: theme.accent.withValues(alpha: .65)),
                boxShadow: [
                  BoxShadow(
                      color: theme.primary.withValues(alpha: .25),
                      blurRadius: 18,
                      offset: const Offset(0, 5))
                ]),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      '${p.preview ? "TEST · " : ""}${s.pick(event.titleEn, event.titleNl)}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                      '${math.min(p.total, p.target)} / ${p.target} ${s.pick('points', 'punten')}',
                      style: TextStyle(color: theme.paper)),
                  Row(children: [
                    Expanded(
                        child: TweenAnimationBuilder<double>(
                      tween: Tween(end: p.fraction),
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, fill, _) => AnimatedBuilder(
                        animation: _orbit,
                        builder: (context, _) => CustomPaint(
                            painter: _StarlightPainter(
                                fill, _orbit.value, theme.accent),
                            child: const SizedBox(height: 42)),
                      ),
                    )),
                    const SizedBox(width: 6),
                    AnimatedBuilder(
                        animation: _orbit,
                        builder: (context, _) => Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (p.complete)
                                      BoxShadow(
                                          color: theme.accent.withValues(
                                              alpha: .25 +
                                                  .15 *
                                                      math.sin(_orbit.value *
                                                          math.pi *
                                                          2)),
                                          blurRadius: 18)
                                  ]),
                              child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: FilledButton(
                                      key: Key('event-claim-${p.key}'),
                                      style: FilledButton.styleFrom(
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(4),
                                          backgroundColor: theme.accent,
                                          foregroundColor: Colors.black87,
                                          disabledBackgroundColor: theme.accent
                                              .withValues(alpha: .8),
                                          disabledForegroundColor:
                                              Colors.black87),
                                      onPressed:
                                          p.canClaim ? widget.onClaim : null,
                                      child: p.canClaim
                                          ? FittedBox(
                                              child: Text(
                                                  s.pick('Claim', 'Ophalen')))
                                          : Icon(
                                              p.claimed
                                                  ? Icons.check_rounded
                                                  : Icons.redeem_rounded,
                                              size: 30))),
                            )),
                  ]),
                  if (p.partnerPoints > 0)
                    Text(
                        s.pick(
                            'Together: your friend contributed ${p.partnerPoints} points.',
                            'Samen: je vriend droeg ${p.partnerPoints} punten bij.'),
                        style: TextStyle(color: theme.paper, fontSize: 12)),
                  if (widget.partnerAction != null) widget.partnerAction!,
                ])));
  }
}

class _StarlightPainter extends CustomPainter {
  _StarlightPainter(this.fill, this.phase, this.color);
  final double fill, phase;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 12, size.width, 18), const Radius.circular(12));
    canvas.drawRRect(
        track, Paint()..color = Colors.black.withValues(alpha: .35));
    canvas.drawRRect(
        track,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke);
    if (fill <= 0) return;
    final rect = Rect.fromLTWH(0, 12, size.width * fill, 18);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  colors: [color.withValues(alpha: .5), color, Colors.white])
              .createShader(rect));
    for (var i = 0; i < 12; i++) {
      final x = ((i / 12 + phase) % 1) * size.width;
      final y = 21 + math.sin(i * 2 + phase * math.pi * 2) * 5;
      canvas.drawCircle(
          Offset(x, y), i.isEven ? 1.8 : 1, Paint()..color = Colors.white70);
    }
    canvas.restore();
    canvas.drawCircle(
        Offset(math.max(3, rect.right - 4), 21),
        4,
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
