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
        TrialKind.witchlightWard =>
          'assets/images/events/halloween/trial_icon.webp',
        TrialKind.hollyfrostGiftforge =>
          'assets/images/events/christmas/trial_icon.webp',
        TrialKind.midnightChime =>
          'assets/images/events/new_year/trial_icon.webp',
        TrialKind.rosevowRelay =>
          'assets/images/events/valentine/trial_icon.webp',
        TrialKind.sunwakeSurf => 'assets/images/events/sunwake/trial_icon.png',
        TrialKind.moonlitOrchard =>
          'assets/images/events/harvestmoon/trial_icon.png',
        TrialKind.wishcakeTower =>
          'assets/images/events/golden_wings/trial_icon.png',
        TrialKind.prismaticParade =>
          'assets/images/events/pride/trial_icon.webp',
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
