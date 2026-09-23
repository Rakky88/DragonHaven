import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/chest.dart';
import '../services/audio_service.dart';
import '../services/canonical_game_snapshot.dart';
import 'game_icon_sprite.dart';

Future<void> showRewardedCurrencyReveal(
  BuildContext context,
  CanonicalPresentationView event, {
  required Widget Function(Widget child) guard,
}) async {
  final currency = event.rewardCurrency!;
  final amount = event.rewardAmount!;
  final gems = currency == 'gems';
  unawaited(HavenAudio.play(HavenSound.chestGold));
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final s = AppStrings.of(dialogContext);
      return guard(AlertDialog(
        key: const Key('rewarded-currency-reveal'),
        title: Text(
            gems
                ? s.pick('Free gems', 'Gratis edelstenen')
                : s.pick('Free coins', 'Gratis munten'),
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(ChestTier.gold.openedAssetPath, height: 150),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameIconSprite(gems ? GameIconKind.gem : GameIconKind.coin,
                    size: 38),
                const SizedBox(width: 10),
                Text('+$amount',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.pick('Your verified reward has been saved.',
                  'Je gecontroleerde beloning is opgeslagen.'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.pick('Continue', 'Doorgaan')),
          ),
        ],
      ));
    },
  );
}
