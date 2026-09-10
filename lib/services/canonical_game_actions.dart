import '../models/tower_interaction.dart';
import '../models/account_title.dart';
import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/dragon_emote.dart';
import '../models/music_track.dart';
import '../models/mystic_relic.dart';
import '../models/egg_altar.dart';
import '../models/profile_portrait.dart';
import '../models/pet.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';

/// Captures the account and inventory actually shown by a screen/dialog.
/// Delayed callbacks cannot act on a newly signed-in account or a newer view.
class CanonicalGameActions {
  CanonicalGameActions(this.session)
      : observed = session.snapshot,
        epoch = session.connection.sessionEpoch;
  final CanonicalGameSession session;
  final CanonicalGameSnapshot? observed;
  final int epoch;

  Future<Object?> execute(String action, Map<String, dynamic> payload) async {
    if (epoch != session.connection.sessionEpoch ||
        observed?.ownerId != session.connection.currentOwner) {
      throw const CanonicalGameException('game_account_changed');
    }
    if (observed == null ||
        observed!.serverRevision != session.snapshot?.serverRevision ||
        observed!.rulesetRevision != session.snapshot?.rulesetRevision) {
      throw const CanonicalGameException('game_refresh_required');
    }
    final receipt = await session.execute(action, payload);
    if (receipt?.succeeded != true) {
      throw CanonicalGameException(
          receipt?.failureCode ?? 'game_command_unavailable');
    }
    return receipt!.result;
  }

  Future<ChestRewardBundle?> openChests(ChestTier tier,
      {int count = 1, String? specialChestId}) async {
    if ((tier == ChestTier.special) != (specialChestId != null)) {
      throw const CanonicalGameException('game_intent_invalid');
    }
    final result = await execute(
        specialChestId == null ? 'open_chests' : 'open_special_chests', {
      if (specialChestId == null)
        'tier': tier.name
      else
        'catalogId': specialChestId,
      'count': count,
    });
    if (result == null) return null;
    return decodeChestRewards(result,
        tier: tier, count: count, specialChestId: specialChestId);
  }

  Future<void> _boolean(String action, Map<String, dynamic> payload) async {
    final result = await execute(action, payload);
    if (result is! bool) {
      throw const CanonicalGameException('game_result_invalid');
    }
    if (!result) throw const CanonicalGameException('game_action_unavailable');
  }

  Future<void> tagEgg(String id, bool tagged) =>
      _boolean('tag_egg', {'eggId': id, 'tagged': tagged});
  Future<void> activateEgg(String id) =>
      _boolean('activate_egg', {'eggId': id});
  Future<void> hatchEgg(String id) => _boolean('hatch_egg', {'eggId': id});
  Future<void> craft(AltarRelic relic) =>
      _boolean('craft_altar_relic', {'relic': relic.name});
  Future<void> revealEgg(AltarRelic relic, String id) =>
      _boolean('use_altar_relic', {'relic': relic.name, 'eggId': id});
  Future<void> nameDragon(String id, String name) =>
      _boolean('name_dragon', {'dragonId': id, 'name': name.trim()});
  Future<void> setDragonHighlight(
          String id, TrainingFocus focus, bool highlighted) =>
      _boolean('set_dragon_highlight',
          {'dragonId': id, 'focus': focus.name, 'highlighted': highlighted});
  Future<void> setFavoriteDragon(String id) =>
      _boolean('set_favorite_dragon', {'dragonId': id});
  Future<void> evolveDragon(String id) =>
      _boolean('evolve_dragon', {'dragonId': id});
  Future<void> buyStarlightTreat(String id) =>
      _boolean('buy_starlight_treat', {'dragonId': id});
  Future<void> equip(MysticRelic relic, String? dragonId) =>
      _boolean('equip_relic', {'relic': relic.name, 'dragonId': dragonId});
  Future<void> releaseDragon(String id) =>
      _boolean('release_dragon', {'dragonId': id});

  Future<int> donateBeacon(String conclaveId, int amount) async {
    final result = await execute(
        'donate_beacon', {'conclaveId': conclaveId, 'amount': amount});
    if (result is! Map ||
        result.length != 2 ||
        result['donated'] != amount ||
        result['fragments'] is! int ||
        result['fragments'] < amount ||
        result['fragments'] > 5000) {
      throw const CanonicalGameException('game_result_invalid');
    }
    return result['fragments'] as int;
  }

  Future<String> invitePairAdventure(String keeperCode, String dragonId) =>
      _socialLifecycleAction('invite_pair_adventure', {
        'keeperCode': keeperCode.trim().toUpperCase(),
        'dragonId': dragonId
      });
  Future<void> acceptPairAdventure(String adventureId, String dragonId) async {
    await _socialLifecycleAction('accept_pair_adventure',
        {'adventureId': adventureId, 'dragonId': dragonId},
        expectedSource: adventureId);
  }

  Future<void> declinePairAdventure(String adventureId) async {
    await _socialLifecycleAction(
        'decline_pair_adventure', {'adventureId': adventureId},
        expectedSource: adventureId);
  }

  Future<void> startPairAdventure(String adventureId) async {
    await _socialLifecycleAction(
        'start_pair_adventure', {'adventureId': adventureId},
        expectedSource: adventureId);
  }

  Future<void> cancelPairAdventure(String adventureId) async {
    await _socialLifecycleAction(
        'cancel_pair_adventure', {'adventureId': adventureId},
        expectedSource: adventureId);
  }

  Future<String> createGroupAdventure(String adventureId, String dragonId) =>
      _socialLifecycleAction('create_group_adventure',
          {'adventureId': adventureId, 'dragonId': dragonId});
  Future<void> joinGroupAdventure(String lobbyId, String dragonId) async {
    await _socialLifecycleAction(
        'join_group_adventure', {'lobbyId': lobbyId, 'dragonId': dragonId},
        expectedSource: lobbyId);
  }

  Future<void> leaveGroupAdventure(String lobbyId) async {
    await _socialLifecycleAction('leave_group_adventure', {'lobbyId': lobbyId},
        expectedSource: lobbyId);
  }

  Future<void> removeGroupAdventureMember(
      String lobbyId, String memberId) async {
    await _socialLifecycleAction('remove_group_adventure_member',
        {'lobbyId': lobbyId, 'memberId': memberId},
        expectedSource: lobbyId);
  }

  Future<String> _socialLifecycleAction(
      String action, Map<String, dynamic> payload,
      {String? expectedSource}) async {
    final result = await execute(action, payload);
    if (result is! Map ||
        result.length != 2 ||
        result['accepted'] != true ||
        result['sourceId'] is! String ||
        !RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
            .hasMatch(result['sourceId'] as String) ||
        (expectedSource != null && result['sourceId'] != expectedSource)) {
      throw const CanonicalGameException('game_result_invalid');
    }
    return result['sourceId'] as String;
  }

  Future<void> claimGroupReward(String lobbyId) =>
      _socialClaim('claim_group_reward', {'lobbyId': lobbyId}, lobbyId);
  Future<void> claimPairReward(String adventureId) => _socialClaim(
      'claim_pair_reward', {'adventureId': adventureId}, adventureId);
  Future<void> claimPodiumPrize(String prizeId) =>
      _socialClaim('claim_podium_prize', {'prizeId': prizeId}, prizeId);
  Future<void> _socialClaim(
      String action, Map<String, dynamic> payload, String sourceId) async {
    final result = await execute(action, payload);
    if (result is! Map ||
        result['accepted'] != true ||
        result['sourceId'] != sourceId ||
        result['alreadyApplied'] is! bool) {
      throw const CanonicalGameException('game_result_invalid');
    }
  }

  Future<void> selectPortrait(String id) =>
      _boolean('select_portrait', {'catalogId': id});
  Future<void> selectTitle(String id) =>
      _boolean('select_title', {'catalogId': id});
  Future<void> selectBadge(String? id) =>
      _boolean('select_badge', {'catalogId': id});
  Future<void> selectFrame(String? id) =>
      _boolean('select_frame', {'catalogId': id});
  Future<void> completePresentation(String id) =>
      _boolean('complete_presentation', {'presentationId': id});
  Future<void> callDragonToFloor(String roomId, int index) =>
      _boolean('call_dragon_to_floor', {'roomId': roomId, 'index': index});
  Future<({String dragonId, TowerInteractionDefinition interaction})?>
      visitFloor(String roomId, int index) async {
    final value =
        await execute('visit_tower_floor', {'roomId': roomId, 'index': index});
    if (value == null) return null;
    if (value is! Map ||
        value.length != 2 ||
        value['dragonId'] is! String ||
        value['interactionId'] is! String) {
      throw const CanonicalGameException('game_result_invalid');
    }
    final interaction = [...towerInteractions, roomOnlyInteraction]
        .where((i) => i.id == value['interactionId'])
        .firstOrNull;
    if (interaction == null) {
      throw const CanonicalGameException('game_result_invalid');
    }
    return (dragonId: value['dragonId'] as String, interaction: interaction);
  }

  Future<void> refresh() => _boolean('refresh', {});
  Future<void> unlockRoom(String id) async {
    final result = await execute('unlock_room', {'roomId': id});
    if (result == 'unlocked' || result == 'alreadyUnlocked') return;
    _houseFailure(result);
  }

  Future<void> buildFloor(String id) async {
    final result = await execute('build_floor', {'roomId': id});
    if (result == 'built') return;
    _houseFailure(result);
  }

  Never _houseFailure(Object? result) => throw CanonicalGameException(const [
        'levelLocked',
        'insufficientCoins',
        'maximumReached',
        'invalidRoom'
      ].contains(result)
          ? 'game_action_unavailable'
          : 'game_result_invalid');
  Future<void> repairFloor(int index) =>
      _boolean('repair_floor', {'index': index});
  Future<void> upgradeWard() => _boolean('upgrade_ward', {});
  Future<void> placeHouseItem(
          String itemId, String roomId, double x, double y) =>
      _boolean('place_house_item',
          {'itemId': itemId, 'roomId': roomId, 'x': x, 'y': y});
  Future<void> moveHouseItem(String itemId, double x, double y) =>
      _boolean('move_house_item', {'itemId': itemId, 'x': x, 'y': y});
  Future<void> removeHouseItem(String itemId) =>
      _boolean('remove_house_item', {'itemId': itemId});
  Future<void> reorderFloor(int oldIndex, int newIndex) => _boolean(
      'reorder_tower_floor', {'oldIndex': oldIndex, 'newIndex': newIndex});
  Future<void> clearFloor(int index) =>
      _boolean('clear_tower_floor', {'index': index});
  Future<void> setDragonRoaming(String dragonId, bool enabled) async {
    final result = await execute(
        'set_dragon_roaming', {'dragonId': dragonId, 'enabled': enabled});
    if (result == 'updated' || result == 'unchanged') return;
    throw CanonicalGameException(
        result == 'towerFull' || result == 'dragonNotFound'
            ? 'game_action_unavailable'
            : 'game_result_invalid');
  }

  Future<void> startAdventure(String adventureId, String dragonId) => _use(
      'start_adventure', {'adventureId': adventureId, 'dragonId': dragonId},
      success: 'started');
  Future<void> dismissAdventure(String id) =>
      _boolean('dismiss_adventure', {'adventureId': id});
  Future<void> abortAdventure(String id) =>
      _boolean('abort_adventure', {'runId': id});
  Future<ChestTier> claimAdventure(String id) async {
    final result = await execute('claim_adventure', {'runId': id});
    if (result == null) {
      throw const CanonicalGameException('game_action_unavailable');
    }
    return ChestTier.values.where((t) => t.name == result).firstOrNull ??
        (throw const CanonicalGameException('game_result_invalid'));
  }

  Future<void> useWayfinder(AdventureKind kind, {String? replaceAdventureId}) =>
      _use('use_wayfinder',
          {'kind': kind.name, 'replaceAdventureId': replaceAdventureId},
          success: 'changed');

  Future<void> _use(String action, Map<String, dynamic> payload,
      {String success = 'revealed'}) async {
    final result = await execute(action, payload);
    if (result == success) return;
    throw CanonicalGameException(switch (result) {
      'notOwned' => 'relic_not_owned',
      'alreadyKnown' => 'already_known',
      'eggNotFound' => 'egg_not_found',
      'dragonNotFound' => 'dragon_not_found',
      'noEggInNest' => 'egg_not_in_nest',
      'dragonBusy' ||
      'eggCannotAdventure' ||
      'groupNeedsFriends' ||
      'requirementsNotMet' ||
      'unavailable' ||
      'unsupportedAdventure' ||
      'adventureNotFound' ||
      'noCapacity' =>
        'game_action_unavailable',
      _ => 'game_result_invalid',
    });
  }

  Future<void> useLens(String id) => _use('use_astral_lens', {'eggId': id});
  Future<void> useRelic(MysticRelic relic, String id) =>
      _use('use_relic', {'relic': relic.name, 'dragonId': id});
  Future<void> useChronoshard(int percent) =>
      _use('use_chronoshard', {'reductionPercent': percent},
          success: 'accelerated');

  Future<WeaveWallet> returnEgg(String id,
      {required bool sinisterConfirmed}) async {
    final result = await execute('return_egg', {
      'eggId': id,
      'sinisterConfirmed': sinisterConfirmed,
    });
    if (result is! Map ||
        result.length != 3 ||
        !const ['fragments', 'essence', 'hearts'].every((k) =>
            result[k] is int &&
            result[k] >= 0 &&
            result[k] <= 9007199254740991)) {
      throw const CanonicalGameException('game_result_invalid');
    }
    return WeaveWallet(result['fragments'] as int, result['essence'] as int,
        result['hearts'] as int);
  }
}

ChestRewardBundle decodeChestRewards(Object? value,
    {required ChestTier tier, required int count, String? specialChestId}) {
  Never invalid() => throw const CanonicalGameException('game_result_invalid');
  if (value is! Map ||
      value['tier'] != tier.name ||
      value['rewards'] is! List ||
      count < 1 ||
      count > 10 ||
      (value['rewards'] as List).length != count) {
    invalid();
  }
  T? catalog<T>(Object? id, T? Function(String) lookup) {
    if (id == null) return null;
    if (id is! String) invalid();
    return lookup(id) ?? invalid();
  }

  int number(Object? n) {
    if (n is! int || n < 0 || n > 9007199254740991) invalid();
    return n;
  }

  bool flag(Object? value) {
    if (value is! bool) invalid();
    return value;
  }

  return ChestRewardBundle(tier: tier, rewards: [
    for (final raw in value['rewards'] as List)
      if (raw is! Map ||
          raw['tier'] != tier.name ||
          raw['specialChestId'] != specialChestId ||
          (raw['specialEggId'] != null && raw['specialEggId'] is! String))
        invalid()
      else
        ChestReward(
          tier: tier,
          coins: number(raw['coins']),
          gems: number(raw['gems']),
          eggFound: flag(raw['eggFound']),
          sinisterEgg: flag(raw['sinisterEgg']),
          specialEgg: flag(raw['specialEgg']),
          specialChestId: specialChestId,
          specialEggId: raw['specialEggId'] as String?,
          relicFound: catalog(
              raw['relicFound'],
              (id) =>
                  MysticRelic.values.where((r) => r.name == id).firstOrNull),
          portraitFound: catalog(raw['portraitFound'], profilePortraitById),
          titleFound: catalog(raw['titleFound'], accountTitleById),
          musicTrackFound:
              catalog(raw['musicTrackFound'], (id) => musicTracksById[id]),
          emoteFound: catalog(raw['emoteFound'], dragonEmoteById),
        ),
  ]);
}
