import 'package:flutter/material.dart';

import '../models/trial.dart';

class TrialIconSprite extends StatelessWidget {
  const TrialIconSprite({
    super.key,
    required this.kind,
    this.size = 32,
  });

  final TrialKind kind;
  final double size;

  static String assetFor(TrialKind kind) => switch (kind) {
        TrialKind.cavernFlight =>
          'assets/images/ui/trials/trial_record_cavern_flight.png',
        TrialKind.ruinBreaker =>
          'assets/images/ui/trials/trial_record_ruin_breaker.png',
        TrialKind.runeweaver =>
          'assets/images/ui/trials/trial_record_runeweaver.png',
      };

  @override
  Widget build(BuildContext context) => Image.asset(
        assetFor(kind),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: '${kind.name} high score',
      );
}
