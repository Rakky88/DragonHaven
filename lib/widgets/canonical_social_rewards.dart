import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/adventure.dart';
import '../models/social_reward_claim.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import 'canonical_game_controls.dart';
import 'game_icon_sprite.dart';

class CanonicalSocialRewards extends StatelessWidget {
  const CanonicalSocialRewards({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot;
    final claims = view?.adventures.socialClaims ?? const <SocialRewardClaim>[];
    if (claims.isEmpty) return const SizedBox.shrink();
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final canClaim = session.canAct &&
        view!.trialAttempt == null &&
        view.schoolAttempt == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 16),
      Text(s.pick('Rewards ready', 'Beloningen klaar'),
          style: Theme.of(context).textTheme.titleMedium),
      for (final claim in claims)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  GameIconSprite(
                      claim.kind == SocialRewardKind.group
                          ? GameIconKind.adventureGroup
                          : claim.kind == SocialRewardKind.pair
                              ? GameIconKind.adventureSpecial
                              : GameIconKind.chest,
                      size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(claim.kind == SocialRewardKind.group
                            ? s.adventureTitle(
                                AdventureCatalog.byId[claim.catalogId]!)
                            : s.pick(
                                specialAdventureEventById(claim.catalogId)!
                                    .titleEn,
                                specialAdventureEventById(claim.catalogId)!
                                    .titleNl)),
                        if (claim.position != null) Text('#${claim.position}'),
                        if (claim.dragonId != null)
                          if (view!.dragon(claim.dragonId!) case final dragon?)
                            Text(dragon.displayName),
                        const SizedBox(height: 6),
                        CanonicalActionButton(
                            key: Key('canonical-social-claim-${claim.id}'),
                            label: s.pick('Claim', 'Ophalen'),
                            action: canClaim
                                ? () => switch (claim.kind) {
                                      SocialRewardKind.group =>
                                        actions.claimGroupReward(claim.id),
                                      SocialRewardKind.pair =>
                                        actions.claimPairReward(claim.id),
                                      SocialRewardKind.podium =>
                                        actions.claimPodiumPrize(claim.id),
                                    }
                                : null),
                      ])),
                ]))),
    ]);
  }
}
