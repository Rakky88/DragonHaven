import 'package:flutter/material.dart';

import '../models/seasonal_minigame.dart';
import '../models/trial.dart';

/// Connects whole-screen gestures to the same actions as the game controls.
class TrialTouchControls {
  ValueChanged<int>? strikeChime;
  int Function(Offset globalPosition)? chimeLaneAt;
  VoidCallback? dropCake;
  ValueChanged<HeartDirection>? moveHearts;
}

class TrialTouchSurface extends StatefulWidget {
  const TrialTouchSurface(
      {super.key,
      required this.kind,
      required this.active,
      required this.controls,
      required this.child});
  final TrialKind kind;
  final bool active;
  final TrialTouchControls controls;
  final Widget child;

  @override
  State<TrialTouchSurface> createState() => _TrialTouchSurfaceState();
}

class _TrialTouchSurfaceState extends State<TrialTouchSurface> {
  Offset? _swipeStart;

  @override
  Widget build(BuildContext context) {
    if (widget.kind == TrialKind.midnightChime) {
      return LayoutBuilder(
          builder: (context, box) => Listener(
              key: const Key('trial-fullscreen-chimes'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: widget.active
                  ? (event) => widget.controls.strikeChime?.call(
                      widget.controls.chimeLaneAt?.call(event.position) ??
                          (event.localPosition.dx / box.maxWidth * 4)
                              .floor()
                              .clamp(0, 3))
                  : null,
              child: widget.child));
    }
    if (widget.kind == TrialKind.wishcakeTower) {
      // Child canvas/buttons win the gesture arena, so every tap drops once.
      return GestureDetector(
          key: const Key('trial-fullscreen-cake'),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.active ? () => widget.controls.dropCake?.call() : null,
          child: widget.child);
    }
    if (widget.kind == TrialKind.rosevowRelay) {
      return GestureDetector(
          key: const Key('trial-fullscreen-hearts'),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onPanStart:
              widget.active ? (d) => _swipeStart = d.localPosition : null,
          onPanCancel: () => _swipeStart = null,
          onPanEnd: (_) => _swipeStart = null,
          onPanUpdate: widget.active
              ? (d) {
                  final start = _swipeStart;
                  if (start == null) return;
                  final delta = d.localPosition - start;
                  if (delta.distance < 26) return;
                  _swipeStart = null;
                  widget.controls.moveHearts
                      ?.call(delta.dx.abs() > delta.dy.abs()
                          ? delta.dx > 0
                              ? HeartDirection.right
                              : HeartDirection.left
                          : delta.dy > 0
                              ? HeartDirection.down
                              : HeartDirection.up);
                }
              : null,
          child: widget.child);
    }
    return widget.child;
  }
}
