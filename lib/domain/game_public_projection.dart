import 'dart:math';

import '../models/adventure.dart';
import '../models/dragon_egg.dart';
import '../models/egg_altar.dart';
import '../models/game_presentation.dart';
import '../models/pet.dart';
import '../providers/household_provider.dart';

/// The authenticated player's display data, never an importable saved game.
/// Every field is selected explicitly. Private seeds, operation history and
/// unknown future save metadata stay on the server, including inside trades.
abstract final class GamePublicProjection {
  static const version = 1;

  static Map<String, dynamic> project({
    required Map<String, dynamic> state,
    required String ownerId,
    required DateTime now,
  }) {
    if (state['pendingAltarOperation'] != null) {
      throw const FormatException('Unresolved Altar operation');
    }
    final game = HouseholdProvider.forServerState(state,
        random: _NoRandom(), now: now, idGenerator: _noIdentity);
    try {
      if (game.eggAltar.ownerId != null && game.eggAltar.ownerId != ownerId) {
        throw const FormatException('Wrong Altar owner');
      }
      final eggs = <Map<String, dynamic>>[
        for (final egg in game.eggStash) _egg(game, egg, location: 'stash'),
      ];
      final dragons = <Map<String, dynamic>>[];
      void resident(Pet dragon, String location) {
        if (dragon.isEgg) {
          // Pet has no specialEggId field. Preserve the saved catalog identity
          // without forwarding the surrounding, potentially private metadata.
          final raw = _findEntity(state, dragon.id);
          eggs.add(_egg(
              game,
              DragonEgg(
                id: dragon.id,
                lineageId: dragon.lineageId,
                acquiredAt: dragon.acquiredAt,
                hatchSeed: dragon.hatchSeed,
                prismatic: dragon.prismatic,
                sinister: dragon.sinister,
                specialEggId: raw?['specialEggId'] as String?,
                lawAxis: dragon.lawAxis,
                moralAxis: dragon.moralAxis,
                moralAxisKnown: dragon.moralAxisKnown,
                sizeFactor: dragon.sizeFactor,
                incubationSeconds: dragon.incubationSeconds,
                xp: dragon.xp,
                altarKnowledge: dragon.altarKnowledge,
              ),
              location: 'nest',
              startedAt: dragon.stageStartedAt));
        } else {
          dragons.add(_dragon(game, dragon, location));
        }
      }

      resident(game.pet, 'active');
      if (game.incubatingEgg != null) resident(game.incubatingEgg!, 'nest');
      for (final dragon in game.sanctuaryDragons) {
        resident(dragon, 'sanctuary');
      }
      for (final dragon in game.releasedDragons) {
        resident(dragon, 'released');
      }
      final exported = game.exportState();
      return {
        'projectionVersion': version,
        'activeDragonId': game.pet.isEgg ? null : game.pet.id,
        'wallet': {'coins': game.pet.coins, 'gems': game.pet.gems},
        'eggs': eggs,
        'dragons': dragons,
        'inventory': {
          ..._select(exported, const [
            'chestInventory',
            'specialChestInventory',
            'relicInventory',
            'untradeableRelicInventory',
            'chronoshardReductions',
            'twinstarBroochEverObtained',
            'twinstarBroochDragonId',
            'reservedOnlineTradeEggIds',
            'reservedOnlineTradeChests',
            'reservedOnlineTradeRelics',
          ]),
          'altar': {
            'wallet': game.eggAltar.wallet.toJson(),
            'crafted': {
              for (final relic in AltarRelic.values)
                relic.name: game.eggAltar.count(relic),
            },
            'totalReturned': game.eggAltar.totalReturned,
          },
        },
        'collection': _select(exported, const [
          'ownedPortraitIds',
          'selectedPortraitId',
          'ownedTitleIds',
          'selectedTitleId',
          'ownedMusicTrackIds',
          'supporterPackOwned',
          'ownedBadgeIds',
          'selectedBadgeId',
          'ownedFrameIds',
          'selectedFrameId',
          'ownedDragonEmoteIds',
          'ownedDragonEmotePackIds',
          'discoveredForms',
          'prismaticForms',
          'achievements',
        ]),
        'house': {
          ..._select(exported, const [
            'ownedItemIds',
            'equippedItemIds',
            'unlockedRoomIds',
            'activeRoomId',
            'towerFloorRoomIds',
            'dragonWardLevel',
            'damagedTowerFloors',
            'damagedTowerRepairFactors',
            'returningVisitors',
            'returningSpecialAdventureId',
            'returningSpecialAvailableUntil',
          ]),
          'placements': [for (final p in game.housePlacements) p.toJson()],
        },
        'progress': _select(exported, const [
          'tutorialCompleted',
          'tutorialFullyViewed',
          'totalHatched',
          'totalNamed',
          'totalWyrmling',
          'totalAscended',
          'totalChestsOpened',
          'totalPortraitChestsOpened',
          'totalTitleChestsOpened',
          'totalMusicChestsOpened',
          'totalAdventuresCompleted',
          'totalShortAdventuresCompleted',
          'totalGroupFourCompleted',
          'totalReleasedReturns',
          'totalSinisterAdventuresCompleted',
          'favoriteChanges',
          'dragonSchoolRecords',
          'seasonalPodiumEmoteWinCounts',
        ]),
        'adventures': {
          ..._select(exported, const [
            'adventureOptionIds',
            'miniAdventureRefilledAt',
            'shortAdventureRefilledAt',
            'longAdventureRefillDay',
          ]),
          'runs': [
            for (final run in game.adventureRuns)
              {
                'id': run.id,
                'adventureId': run.adventureId,
                'dragonId': run.dragonId,
                'startedAt': run.startedAt.toUtc().toIso8601String(),
                'endsAt': run.endsAt.toUtc().toIso8601String(),
                'status': run.status.name,
                'participantCount': run.participantCount,
                'specialEventId': run.specialEventId,
                'specialEventKey': run.specialEventKey,
                // A running adventure's preselected reward is not a UI hint.
                'rewardTier': run.status == AdventureRunStatus.rewardReady
                    ? run.rewardTier?.name
                    : null,
              }
          ],
        },
        'trials': {
          ..._select(exported, const [
            'trialRefilledAt',
            'trialStreakCount',
            'trialStreakLastDayKey',
            'trialStreakLastCompletionDayKey',
            'trialStreakRewardReady',
          ]),
          'offers': [
            for (final offer in game.trialOffers)
              _select(offer.toJson(), const [
                'id',
                'kind',
                'appearedAt',
                'specialEventKey',
                'startedAt',
              ])
          ],
        },
        'presentations': [
          for (final event in game.pendingPresentations)
            _presentation(game, event),
        ],
        'activities': [
          for (final entry in game.activities)
            _select(entry.toJson(), const [
              'id',
              'message',
              'createdAt',
              'type',
              'code',
              'subject',
              'xp',
              'coins',
              'gems',
            ])
        ],
      };
    } finally {
      game.dispose();
    }
  }

  static Map<String, dynamic> _egg(HouseholdProvider game, DragonEgg egg,
      {required String location, DateTime? startedAt}) {
    final known = game.eggKnowledge(egg.id).merge(egg.altarKnowledge).merge(
        AltarEggKnowledge(moral: egg.moralAxisKnown || egg.isSinisterEgg));
    final special = specialEggById(egg.specialEggId) ??
        (egg.isSpecialEgg ? specialEggForLineage(egg.lineageId) : null);
    return {
      'id': egg.id,
      'location': location,
      'kind': egg.isSinisterEgg
          ? 'sinister'
          : egg.isSpecialEgg
              ? 'special'
              : 'ordinary',
      'specialEggId': special?.id,
      'acquiredAt': egg.acquiredAt.toUtc().toIso8601String(),
      'startedAt': startedAt?.toUtc().toIso8601String(),
      'incubationSeconds': egg.incubationSeconds,
      'xp': egg.xp,
      'tagged': known.tagged,
      'returnBlockReason': location == 'stash'
          ? game.weaveReturnBlockReason(egg.id)
          : 'egg_in_nest',
      'hints': {
        for (final locale in const ['en', 'nl'])
          locale: game.eggHintForEgg(egg, locale: locale),
      },
      // Identity implies the catalog rarity; it reveals no spectral roll,
      // hidden alignment, size, personality, seed or eventual evolution.
      'lineageId': known.lineage ? egg.lineageId : null,
      'rarity': known.rarity || known.lineage ? egg.lineage.rarity.name : null,
      'lawAxis': known.order ? egg.lawAxis.name : null,
      'moralAxis': known.moral ? egg.moralAxis.name : null,
    };
  }

  static Map<String, dynamic> _dragon(
      HouseholdProvider game, Pet dragon, String location) {
    final known = game.eggKnowledge(dragon.id);
    return {
      ..._select(dragon.toJson(), const [
        'id',
        'name',
        'xp',
        'stage',
        'firstEgg',
        'spectral',
        'sinister',
        'sizeFactor',
        'favorite',
        'roamsTower',
        'currentRoomId',
        'currentFloorIndex',
        'activeAdventureId',
        'joy',
        'energy',
        'comfort',
        'acquiredAt',
        'stageStartedAt',
        'needsUpdatedAt',
        'training',
        'trialHighScores',
        'dragonSchoolRecords',
        'dragonSchoolStars',
        'dragonSchoolAttempts',
        'dragonSchoolFinalizedEarly',
        'dragonSchoolMentorLessons',
        'lineageId',
        'evolutionPath',
      ]),
      'location': location,
      'lawAxis':
          known.order || dragon.lawAxisKnown ? dragon.lawAxis.name : null,
      'moralAxis':
          known.moral || dragon.moralAxisKnown ? dragon.moralAxis.name : null,
      'personalityTraitIds': dragon.personalityKnown
          ? List<String>.of(dragon.personalityTraitIds)
          : null,
      'leadingPath': dragon.leadingPath,
      'activeEvolutionPath': dragon.activeEvolutionPath,
    };
  }

  static Map<String, dynamic> _presentation(
          HouseholdProvider game, GamePresentation event) =>
      {
        'id': event.id,
        'type': event.type.name,
        'createdAt': event.createdAt.toUtc().toIso8601String(),
        'sortAt': event.sortAt.toUtc().toIso8601String(),
        'dragonId': event.dragonId,
        'achievementId': event.achievementId,
        'previousStageKey': event.previousStageKey,
        if (event.type == GamePresentationType.trade)
          'trade': {
            for (final direction in const ['sent', 'received'])
              direction: _tradeItem(game, event.payload, direction),
          },
      };

  static Map<String, dynamic>? _tradeItem(
      HouseholdProvider game, Map<String, dynamic> payload, String direction) {
    final kind = payload['${direction}Kind'];
    if (kind == 'egg') {
      final data = payload['${direction}Data'];
      if (data is! Map<String, dynamic> || data['id'] is! String) return null;
      return {
        'kind': 'egg',
        'egg': _egg(game, DragonEgg.fromJson(data), location: 'trade')
      };
    }
    if (kind == 'chest' || kind == 'relic') {
      final key = payload['${direction}Key'];
      return key is String ? {'kind': kind, 'catalogId': key} : null;
    }
    return null;
  }

  static Map<String, dynamic>? _findEntity(
      Map<String, dynamic> state, String id) {
    for (final candidate in [
      state['pet'],
      state['incubatingEgg'],
      ...?state['sanctuaryDragons'] as List?,
      ...?state['releasedDragons'] as List?
    ]) {
      if (candidate is Map<String, dynamic> && candidate['id'] == id) {
        return candidate;
      }
    }
    return null;
  }

  static Map<String, dynamic> _select(
          Map<String, dynamic> data, List<String> keys) =>
      {
        for (final key in keys) key: data[key],
      };

  static String _noIdentity() =>
      throw StateError('Projection cannot create identities');
}

class _NoRandom implements Random {
  @override
  bool nextBool() => throw StateError('Projection cannot roll rewards');
  @override
  double nextDouble() => throw StateError('Projection cannot roll rewards');
  @override
  int nextInt(int max) => throw StateError('Projection cannot roll rewards');
}
