import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Presentation only: the saved reward never depends on animation completion.
class EventPointFlight {
  static final trialRewards = ValueNotifier<Map<String, int>>({});

  /// Called after the Trial result route has left the screen.
  static void returnFromTrial(BuildContext context, Map<String, int> earned) {
    if (!earned.values.any((points) => points > 0)) return;
    _origin = Offset(MediaQuery.sizeOf(context).width / 2,
        MediaQuery.sizeOf(context).height * .72);
    _claimedAt = DateTime.now();
    trialRewards.value = Map.of(earned);
    _claimedAt = null;
  }

  static Offset? _pointer;
  static Offset? _origin;
  static DateTime? _claimedAt;
  static int _listeners = 0;
  static void _route(PointerEvent event) {
    if (event is PointerDownEvent) remember(event);
  }

  static void attach() {
    if (_listeners++ == 0) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_route);
    }
  }

  static void detach() {
    if (--_listeners == 0) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_route);
      _pointer = null;
      _claimedAt = null;
    }
  }

  static void remember(PointerDownEvent event) => _pointer = event.position;

  static Future<T> claim<T>(BuildContext context, Future<T> Function() action) {
    _origin = _pointer ??
        Offset(MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height * .8);
    _claimedAt = DateTime.now();
    return action();
  }

  static void show(BuildContext context, GlobalKey destination, String sprite,
      Color color, int points) {
    if (MediaQuery.disableAnimationsOf(context) ||
        _claimedAt == null ||
        DateTime.now().difference(_claimedAt!) > const Duration(seconds: 8)) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final target = destination.currentContext?.findRenderObject();
    final root = overlay?.context.findRenderObject();
    if (overlay == null ||
        target is! RenderBox ||
        root is! RenderBox ||
        !target.hasSize ||
        !root.hasSize) {
      return;
    }
    final end = root
        .globalToLocal(target.localToGlobal(target.size.center(Offset.zero)));
    final start = root.globalToLocal(_origin!);
    late final OverlayEntry entry;
    entry = OverlayEntry(
        builder: (_) => IgnorePointer(
            child: _Flight(
                start: start,
                end: end,
                sprite: sprite,
                color: color,
                points: points,
                done: () {
                  entry.remove();
                  entry.dispose();
                })));
    overlay.insert(entry);
  }
}

class _Flight extends StatefulWidget {
  const _Flight(
      {required this.start,
      required this.end,
      required this.sprite,
      required this.color,
      required this.points,
      required this.done});
  final Offset start, end;
  final String sprite;
  final Color color;
  final int points;
  final VoidCallback done;
  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.done();
    })
    ..forward();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(children: [
            for (var i = 0; i < 6; i++) _particle(i),
            Positioned(
                left: widget.start.dx - 44,
                top: widget.start.dy - 46 - _controller.value * 28,
                child: Opacity(
                    opacity: (1 - _controller.value * 2).clamp(0, 1),
                    child: Material(
                        color: Colors.transparent,
                        child: Text('+${widget.points}',
                            style: TextStyle(
                                color: widget.color,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 5)
                                ])))))
          ]));
  Widget _particle(int index) {
    final t = ((_controller.value - index * .045) / .73).clamp(0.0, 1.0);
    final ease = Curves.easeInOutCubic.transform(t);
    final bend = Offset(widget.start.dx + (index - 2.5) * 28,
        math.min(widget.start.dy, widget.end.dy) - 60);
    final pos = widget.start * ((1 - ease) * (1 - ease)) +
        bend * (2 * ease * (1 - ease)) +
        widget.end * (ease * ease);
    return Positioned(
        left: pos.dx - 12,
        top: pos.dy - 12,
        child: Opacity(
            opacity: t == 0 || t == 1 ? 0 : 1,
            child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(
                      color: widget.color.withValues(alpha: .7), blurRadius: 12)
                ]),
                child:
                    Image.asset(widget.sprite, excludeFromSemantics: true))));
  }
}
