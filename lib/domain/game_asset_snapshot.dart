import 'dart:convert';

import '../models/dragon_sex.dart';

/// A semantic inventory fingerprint used before evaluating canonical state.
/// It tolerates map order and explicit zero counts, but detects discarded
/// collections, changed fixed egg properties, missing dragons, rerolled
/// Chronoshards, lost progression and changed Altar protection/stock.
/// It is not a migration: a difference requires explicit reconciliation first.
class GameAssetSnapshot {
  GameAssetSnapshot(Map<String, dynamic> state) {
    final pet = _map(state['pet']);
    _counts('wallet', {'coins': pet['coins'], 'gems': pet['gems']});
    for (final key in const [
      'chestInventory',
      'specialChestInventory',
      'relicInventory',
      'untradeableRelicInventory',
    ]) {
      _counts(key, _map(state[key]));
    }
    for (final key in const [
      'ownedPortraitIds',
      'ownedTitleIds',
      'ownedMusicTrackIds',
      'ownedItemIds',
      'ownedDragonEmoteIds',
      'ownedDragonEmotePackIds',
      'ownedBadgeIds',
      'ownedFrameIds',
      'unlockedRoomIds',
      'achievements',
      'discoveredForms',
      'prismaticForms',
      'eggRarityRevealedIds',
      'appliedVerifiedPurchaseIds',
      'appliedOnlineGroupRewardIds',
      'appliedOnlineTradeIds',
      'appliedOnlineSeasonalPairRewardIds',
      'appliedSeasonalPrizeIds',
      'startedSeasonalSpecialEventKeys',
      'trialStreakCreditedDayKeys',
      'reservedOnlineTradeEggIds',
    ]) {
      final values = state[key];
      if (values is! List || values.any((value) => value is! String)) {
        throw FormatException('Invalid canonical collection: $key');
      }
      for (final value in values.toSet()) {
        _assets[jsonEncode([key, value])] = 1;
      }
    }
    final shards = state['chronoshardReductions'];
    if (shards is! List) {
      throw const FormatException('Missing Chronoshard identities');
    }
    for (final reduction in shards) {
      if (reduction is! int || reduction < 10 || reduction > 90) {
        throw const FormatException('Invalid Chronoshard identity');
      }
      final key = jsonEncode(['chronoshard', reduction]);
      _assets[key] = (_assets[key] as int? ?? 0) + 1;
    }
    final seen = <String>{};
    void entity(Object? value, String location) {
      final data = _map(value);
      final id = data['id'];
      if (id is! String || id.isEmpty || id.length > 100 || !seen.add(id)) {
        throw const FormatException('Invalid or duplicate game identity');
      }
      final properties = <String, dynamic>{};
      // Old saves acquire the same stable value as the model, without rerolls.
      properties['sex'] = DragonSex.fromJson(data).name;
      if (location != 'egg') {
        properties['highlightedExpertises'] =
            (data['highlightedExpertises'] as List? ?? []).toSet().toList()
              ..sort();
      }
      for (final key in const [
        'name',
        'stage',
        'firstEgg',
        'lineageId',
        'hatchSeed',
        'sinister',
        'lawAxis',
        'moralAxis',
        'lawAxisKnown',
        'moralAxisKnown',
        'personalityKnown',
        'personalityTraitIds',
        'sizeFactor',
        'xp',
        'training',
        'evolutionPath',
        'trialHighScores',
        'dragonSchoolRecords',
        'dragonSchoolStars',
        'dragonSchoolAttempts',
        'dragonSchoolFinalizedEarly',
        'dragonSchoolMentorLessons',
        'specialEggId',
        'altarKnowledge',
      ]) {
        if (data.containsKey(key)) properties[key] = data[key];
      }
      // These facts are already visible through eggKnowledge even before its
      // derived flags are materialized on the entity. Compare the effective
      // knowledge, while keeping tags, revisions and Oracle discoveries exact.
      final knowledge = _map(data['altarKnowledge'] ?? <String, dynamic>{});
      properties['altarKnowledge'] = {
        ...knowledge,
        'moral': knowledge['moral'] == true ||
            data['moralAxisKnown'] == true ||
            (location == 'egg' && data['lineageId'] == 'sinisterra'),
        'order': knowledge['order'] == true || data['lawAxisKnown'] == true,
        'rarity': knowledge['rarity'] == true ||
            (state['eggRarityRevealedIds'] as List).contains(id),
      };
      properties['spectral'] =
          data['spectral'] == true || data['prismatic'] == true;
      properties['incubationSeconds'] = data['incubationSeconds'] ??
          (data['incubationMinutes'] is int
              ? (data['incubationMinutes'] as int) * 60
              : null);
      for (final key in const [
        'acquiredAt',
        'stageStartedAt',
        'needsUpdatedAt'
      ]) {
        if (data[key] != null) {
          final parsed = DateTime.tryParse(data[key].toString());
          if (parsed == null) {
            throw const FormatException('Invalid game timestamp');
          }
          properties[key] = parsed.microsecondsSinceEpoch;
        }
      }
      _assets[jsonEncode([location, id])] = _canonical(properties);
    }

    entity(pet, pet['stage'] == 'egg' ? 'nest' : 'dragon');
    if (state['incubatingEgg'] != null) entity(state['incubatingEgg'], 'nest');
    for (final key in const [
      'eggStash',
      'sanctuaryDragons',
      'releasedDragons'
    ]) {
      final values = state[key];
      if (values is! List) {
        throw const FormatException('Invalid game inventory');
      }
      for (final value in values) {
        entity(
            value,
            switch (key) {
              'eggStash' => 'egg',
              'sanctuaryDragons' => 'dragon',
              _ => 'released_dragon',
            });
      }
    }
    for (final key in const [
      'supporterPackOwned',
      'twinstarBroochEverObtained',
      'twinstarBroochDragonId',
      'eggAltar',
      'pendingAltarOperation',
      'adventureRuns',
      'towerFloorRoomIds',
      'dragonWardLevel',
      'damagedTowerFloors',
      'damagedTowerRepairFactors',
      'reservedOnlineTradeChests',
      'reservedOnlineTradeRelics',
      'trialStreakCount',
      'trialStreakRewardReady',
      'dragonSchoolRecords',
      'seasonalPodiumEmoteWinCounts',
    ]) {
      _assets[key] = _canonical(state[key]);
    }
    _counts('progression', {
      for (final entry in state.entries)
        if (entry.key.startsWith('total')) entry.key: entry.value,
    });
  }

  final Map<String, Object?> _assets = {};

  void _counts(String kind, Map<String, dynamic> quantities) {
    for (final entry in quantities.entries) {
      final quantity = entry.value;
      if (quantity is! int || quantity < 0 || quantity > 9007199254740991) {
        throw const FormatException('Invalid canonical inventory count');
      }
      if (quantity != 0) _assets[jsonEncode([kind, entry.key])] = quantity;
    }
  }

  bool hasSameAssets(GameAssetSnapshot other) =>
      jsonEncode(_canonical(_assets)) == jsonEncode(_canonical(other._assets));

  /// Fixed field/category names only, never an entity ID or stored value.
  Set<String> differenceKinds(GameAssetSnapshot other) => {
        for (final key in {..._assets.keys, ...other._assets.keys})
          if (jsonEncode(_canonical(_assets[key])) !=
              jsonEncode(_canonical(other._assets[key])))
            key.startsWith('[')
                ? (jsonDecode(key) as List).first as String
                : key,
      };

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid canonical game object');
    }
    return Map<String, dynamic>.from(value);
  }

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {
        for (final key in keys)
          if (value[key] != null && value[key] != 0 && value[key] != false)
            key: _canonical(value[key]),
      };
    }
    if (value is List) return value.map(_canonical).toList();
    if (value is num && value == value.roundToDouble()) return value.toInt();
    return value;
  }
}
