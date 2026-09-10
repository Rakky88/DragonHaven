import 'social_pair_lifecycle.dart';
import 'social_group_lifecycle.dart';
import 'social_dragon_reservations.dart';
import 'social_claims.dart';
import 'dart:convert';

import '../models/adventure.dart';
import '../models/game_command_schema.dart';
import '../models/chest.dart';
import '../models/egg_altar.dart';
import '../models/house.dart';
import '../models/mystic_relic.dart';
import '../models/pet.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import 'server_entropy.dart';
import 'game_state_envelope.dart';
import 'school_attempts.dart';
import 'trial_attempts.dart';

/// Runs existing game rules against trusted database state. This is an internal
/// server module, not an HTTP authorization boundary: the worker must verify
/// the owner, reserve the idempotent intent and atomically commit the result.
/// In particular, state, clock, seed and keeperId never come from the request.
abstract final class GameCommandEngine {
  static const protocol = 2;

  static Future<Map<String, dynamic>> execute({
    required Map<String, dynamic> state,
    required String action,
    required Map<String, dynamic> payload,
    required String secretSeed,
    required DateTime now,
    required String keeperId,
    Map<String, dynamic>? verifiedSocialContext,
    Map<String, dynamic>? verifiedSocialReservations,
  }) async {
    final keys = GameCommandSchema.keys[action];
    if (keys == null ||
        payload.length != keys.length ||
        !keys.every(payload.containsKey)) {
      throw const GameCommandException('invalid_command');
    }
    final args = _Arguments(payload);
    if (state['pendingAltarOperation'] != null) {
      throw const GameCommandException('game_state_reconciliation_required');
    }
    final identities = ServerEntropy(secretSeed, stream: 'identities');
    final game = HouseholdProvider.forServerState(
      state,
      random: ServerEntropy(secretSeed, stream: 'rewards'),
      now: now,
      idGenerator: identities.uuid,
    );
    try {
      if (game.eggAltar.ownerId != null && game.eggAltar.ownerId != keeperId) {
        throw const GameCommandException('game_state_owner_mismatch');
      }
      SocialDragonReservations.apply(
        game: game,
        ownerId: keeperId,
        verified: verifiedSocialReservations,
        activeAttempt: state['_activeGameAttempt'] == null
            ? null
            : Map<String, dynamic>.from(state['_activeGameAttempt'] as Map),
      );
      game.altarCurrentUserId = () => keeperId;
      game.altarRequiresAccount = true;
      Map<String, dynamic>? activeAttempt = state['_activeGameAttempt'] == null
          ? null
          : Map<String, dynamic>.from(state['_activeGameAttempt'] as Map);
      Object? lastGameResult = state['_lastGameResult'];
      if (activeAttempt != null &&
          !const {
            'refresh',
            'finish_school',
            'cancel_school',
            'checkpoint_trial',
            'cancel_trial'
          }.contains(action)) {
        throw const GameCommandException('game_attempt_in_progress');
      }
      // Scores and reward amounts never come from a player. Social claims use
      // separately sealed database facts; paid entitlements remain absent.
      final Object? result;
      switch (action) {
        case 'invite_pair_adventure':
        case 'accept_pair_adventure':
        case 'decline_pair_adventure':
        case 'start_pair_adventure':
        case 'cancel_pair_adventure':
          result = SocialPairLifecycle.apply(
              game: game,
              ownerId: keeperId,
              action: action,
              payload: payload,
              context: verifiedSocialContext);
          break;
        case 'create_group_adventure':
        case 'join_group_adventure':
        case 'leave_group_adventure':
        case 'remove_group_adventure_member':
          result = SocialGroupLifecycle.apply(
              game: game,
              ownerId: keeperId,
              action: action,
              payload: payload,
              context: verifiedSocialContext);
        case 'claim_group_reward':
        case 'claim_pair_reward':
        case 'claim_podium_prize':
          result = await SocialClaims.apply(
              game: game,
              ownerId: keeperId,
              action: action,
              sourceId: args.text(switch (action) {
                'claim_group_reward' => 'lobbyId',
                'claim_pair_reward' => 'adventureId',
                _ => 'prizeId',
              }),
              context: verifiedSocialContext);
        case 'refresh':
          if (activeAttempt == null) await game.refreshForCurrentDate();
          result = true;
        case 'start_trial':
          activeAttempt = await TrialAttempts.start(
              game: game,
              id: identities.uuid(),
              seed: identities.nextInt(1 << 31),
              offerId: args.text('offerId'),
              dragonId: args.text('dragonId'),
              now: now);
          result = {
            for (final key in [
              'version',
              'type',
              'elapsedMs',
              'id',
              'seed',
              'gameId',
              'offerId',
              'dragonIds',
              'specialEventKey',
              'startedAt',
              'expiresAt'
            ])
              key: activeAttempt[key]
          };
        case 'checkpoint_trial':
        case 'cancel_trial':
          final inputs = action == 'cancel_trial' ? '' : payload['inputs'];
          if (inputs is! String || inputs.length > 3200) {
            throw const GameCommandException('invalid_argument');
          }
          final finished = await TrialAttempts.update(
              game: game,
              attempt: activeAttempt,
              id: args.text('attemptId'),
              now: now,
              inputs: inputs,
              elapsedMs: action == 'cancel_trial'
                  ? 0
                  : args.integer('elapsedMs', min: 0, max: 9007199254740991),
              finish: action == 'cancel_trial' ? false : args.boolean('finish'),
              cancel: action == 'cancel_trial');
          result = finished.result;
          if (finished.attempt == null) {
            lastGameResult = {
              'attemptId': activeAttempt!['id'],
              'gameId': activeAttempt['gameId'],
              'type': 'trial',
              'result': result
            };
          }
          activeAttempt = finished.attempt;
        case 'start_school':
          final rawIds = jsonDecode(args.text('dragonIds', max: 800));
          if (rawIds is! List ||
              rawIds.isEmpty ||
              rawIds.length > 3 ||
              rawIds.any(
                  (id) => id is! String || id.isEmpty || id.length > 200)) {
            throw const GameCommandException('invalid_argument');
          }
          activeAttempt = SchoolAttempts.start(
              game: game,
              id: identities.uuid(),
              seed: identities.nextInt(1 << 31),
              gameId: args.text('gameId'),
              dragonIds: List<String>.from(rawIds),
              mentorId: args.nullableText('mentorId'),
              now: now);
          result = activeAttempt;
        case 'finish_school':
        case 'cancel_school':
          final inputs = action == 'cancel_school' ? '' : payload['inputs'];
          if (inputs is! String || inputs.length > 3200) {
            throw const GameCommandException('invalid_argument');
          }
          result = await SchoolAttempts.finish(
              game: game,
              attempt: activeAttempt,
              id: args.text('attemptId'),
              now: now,
              inputs: inputs,
              cancel: action == 'cancel_school');
          lastGameResult = {
            'attemptId': activeAttempt!['id'],
            'gameId': activeAttempt['gameId'],
            'type': 'school',
            'result': result
          };
          activeAttempt = null;
        case 'graduate_school':
          result = await game.graduateDragonFromAcademy(args.text('dragonId'));
        case 'purchase_portrait_chest':
          result = (await game.purchasePortraitChest()).name;
        case 'purchase_title_chest':
          result = (await game.purchaseTitleChest()).name;
        case 'purchase_music_chest':
          result = (await game.purchaseMusicChest()).name;
        case 'purchase_furniture':
          final item = shopItemById(args.text('catalogId'));
          if (item == null) throw const GameCommandException('unknown_item');
          result = (await game.purchaseOrEquip(item)).name;
        case 'purchase_relic':
          result = (await game
                  .purchaseRelic(args.enumValue('relic', MysticRelic.values)))
              .name;
        case 'open_chests':
          final tier = args.enumValue('tier', ChestTier.values);
          if (tier == ChestTier.special) {
            throw const GameCommandException('special_chest_id_required');
          }
          result = _bundle(await game.openChests(tier,
              count: args.integer('count', min: 1, max: 10)));
        case 'open_special_chests':
          result = _bundle(await game.openSpecialChests(args.text('catalogId'),
              count: args.integer('count', min: 1, max: 10)));
        case 'use_relic':
          result = (await game.useRelic(
                  args.enumValue('relic', MysticRelic.values),
                  args.text('dragonId')))
              .name;
        case 'use_astral_lens':
          result = (await game.useAstralLens(args.text('eggId'))).name;
        case 'tag_egg':
          await game.setEggTagged(args.text('eggId'), args.boolean('tagged'));
          result = true;
        case 'return_egg':
          result = (await game.returnEggToWeave(args.text('eggId'),
                  sinisterConfirmed: args.boolean('sinisterConfirmed')))
              .toJson();
        case 'craft_altar_relic':
          await game
              .craftAltarRelic(args.enumValue('relic', AltarRelic.values));
          result = true;
        case 'use_altar_relic':
          await game.useAltarRelic(
              args.enumValue('relic', AltarRelic.values), args.text('eggId'));
          result = true;
        case 'use_chronoshard':
          result = (await game.useChronoshard(
                  args.integer('reductionPercent', min: 1, max: 100)))
              .name;
        case 'use_wayfinder':
          result = (await game.useWayfinderSigil(
            args.enumValue('kind', AdventureKind.values),
            replaceAdventureId: args.nullableText('replaceAdventureId'),
          ))
              .name;
        case 'equip_relic':
          result = await game.equipRelic(
              args.enumValue('relic', MysticRelic.values),
              args.nullableText('dragonId'));
        case 'equip_twinstar':
          result =
              await game.equipTwinstarBrooch(args.nullableText('dragonId'));
        case 'activate_egg':
          result = await game.activateEgg(args.text('eggId'));
        case 'hatch_egg':
          result = game.nestEgg?.id == args.text('eggId') &&
              await game.hatchActiveDragon();
        case 'name_dragon':
          result = await game.nameDragon(
              args.text('dragonId'), args.text('name', max: 24));
        case 'set_dragon_highlight':
          final id = args.text('dragonId');
          final focus = args.enumValue('focus', TrainingFocus.values);
          final highlighted = args.boolean('highlighted');
          final dragon = game.ownedDragons.where((d) => d.id == id).firstOrNull;
          result = dragon != null;
          if (dragon != null &&
              dragon.highlightedExpertises.contains(focus) != highlighted) {
            await game.toggleDragonExpertiseHighlight(id, focus);
          }
        case 'set_favorite_dragon':
          final id = args.text('dragonId');
          result = game.ownedDragons.any((d) => d.id == id);
          if (result == true) await game.toggleFavorite(id);
        case 'evolve_dragon':
          result = await game.evolveDragon(args.text('dragonId'));
        case 'buy_starlight_treat':
          result = game.pet.id == args.text('dragonId') &&
              await game.buyStarlightTreat();
        case 'release_dragon':
          result = await game.releaseDragon(args.text('dragonId'));
        case 'start_adventure':
          final adventure = AdventureCatalog.byId[args.text('adventureId')];
          if (adventure == null) {
            throw const GameCommandException('unknown_adventure');
          }
          result = (await game.startAdventure(adventure,
                  dragonId: args.text('dragonId')))
              .name;
        case 'dismiss_adventure':
          final adventure = AdventureCatalog.byId[args.text('adventureId')];
          if (adventure == null) {
            throw const GameCommandException('unknown_adventure');
          }
          await game.dismissAdventure(adventure);
          result = true;
        case 'claim_adventure':
          result = (await game.claimAdventure(args.text('runId')))?.name;
        case 'abort_adventure':
          result = await game.abortAdventure(args.text('runId'));
        case 'dismiss_trial':
          await game.dismissTrial(args.text('offerId'));
          result = true;
        case 'claim_constellation':
          result = (await game.claimTrialStreakReward())?.name;
        case 'unlock_room':
          final room = houseRoomById(args.text('roomId'));
          if (room == null) throw const GameCommandException('unknown_room');
          result = (await game.unlockRoom(room)).name;
        case 'build_floor':
          result = (await game.buildTowerFloor(args.text('roomId'))).name;
        case 'repair_floor':
          result = await game
              .repairTowerFloor(args.integer('index', min: 0, max: 19));
        case 'upgrade_ward':
          result = await game.upgradeDragonWard();
        case 'place_house_item':
          result = await game.placeHouseItem(args.text('itemId'),
              roomId: args.text('roomId'),
              x: args.number('x', min: 0, max: 1),
              y: args.number('y', min: 0, max: 1));
        case 'move_house_item':
          result = await game.moveHouseItem(
              args.text('itemId'),
              args.number('x', min: 0, max: 1),
              args.number('y', min: 0, max: 1));
        case 'remove_house_item':
          result = await game.removeHouseItem(args.text('itemId'));
        case 'reorder_tower_floor':
          result = await game.reorderTowerFloor(
              args.integer('oldIndex', min: 0, max: 19),
              args.integer('newIndex', min: 0, max: 19));
        case 'set_dragon_roaming':
          result = (await game.setDragonRoaming(
                  args.text('dragonId'), args.boolean('enabled')))
              .name;
        case 'clear_tower_floor':
          final index = args.integer('index', min: 0, max: 19);
          result = index < game.towerFloorRoomIds.length &&
              await game.clearDragonsFromRoom(index);
        case 'select_portrait':
          final id = args.text('catalogId');
          result = game.selectedPortraitId == id ||
              await game.selectProfilePortrait(id);
        case 'select_title':
          final id = args.text('catalogId');
          result =
              game.selectedTitleId == id || await game.selectAccountTitle(id);
        case 'select_badge':
          final id = args.nullableText('catalogId');
          result =
              game.selectedBadgeId == id || await game.selectKeeperBadge(id);
        case 'select_frame':
          final id = args.nullableText('catalogId');
          result =
              game.selectedFrameId == id || await game.selectKeeperFrame(id);
        case 'complete_presentation':
          await game.completePresentation(args.text('presentationId'));
          result = true;
        case 'call_dragon_to_floor':
          result = await game.callControllableDragonToRoom(
              args.text('roomId'), args.integer('index', min: 0, max: 19));
        case 'visit_tower_floor':
          final roomId = args.text('roomId');
          final index = args.integer('index', min: 0, max: 19);
          if (index >= game.towerFloorRoomIds.length ||
              game.towerFloorRoomIds[index] != roomId ||
              game.damagedTowerFloors.contains(index)) {
            throw const GameCommandException('game_action_unavailable');
          }
          final event = await game.triggerRoomInteraction(roomId, index);
          result = event == null
              ? null
              : {
                  'dragonId': event.dragonId,
                  'interactionId': event.interactionId
                };
        case 'complete_tutorial':
          await game.completeTutorial(fullyViewed: args.boolean('fullyViewed'));
          result = true;
        case 'redeem_code':
          result = await game.redeemCode(args.text('code', max: 100),
              keeperId: keeperId);
        default:
          throw const GameCommandException('invalid_command');
      }
      return {
        'protocol': protocol,
        'result': result,
        'state': {
          ...GameStateEnvelope.preserveUnknownMetadata(
              state, game.exportState()),
          if (state.containsKey('_activeGameAttempt') || activeAttempt != null)
            '_activeGameAttempt': activeAttempt,
          if (state.containsKey('_lastGameResult') || lastGameResult != null)
            '_lastGameResult': lastGameResult,
        }
      };
    } on SocialPairException {
      throw const GameCommandException('game_action_unavailable');
    } on SocialGroupException {
      throw const GameCommandException('game_action_unavailable');
    } on SocialClaimException catch (error) {
      throw GameCommandException(error.code);
    } on TrialAttemptException catch (error) {
      throw GameCommandException(error.code);
    } on SchoolAttemptException catch (error) {
      throw GameCommandException(error.code);
    } on FormatException {
      throw const GameCommandException('invalid_argument');
    } on EggAltarException catch (error) {
      throw GameCommandException(error.code);
    } finally {
      game.dispose();
    }
  }

  static Object? _bundle(ChestRewardBundle? bundle) => bundle == null
      ? null
      : {
          'tier': bundle.tier.name,
          'rewards': [
            for (final reward in bundle.rewards)
              {
                'tier': reward.tier.name,
                'coins': reward.coins,
                'gems': reward.gems,
                'eggFound': reward.eggFound,
                'sinisterEgg': reward.sinisterEgg,
                'specialEgg': reward.specialEgg,
                'specialChestId': reward.specialChestId,
                'specialEggId': reward.specialEggId,
                'relicFound': reward.relicFound?.name,
                'portraitFound': reward.portraitFound?.id,
                'titleFound': reward.titleFound?.id,
                'musicTrackFound': reward.musicTrackFound?.id,
                'emoteFound': reward.emoteFound?.id,
              }
          ],
        };
}

class GameCommandException implements Exception {
  const GameCommandException(this.code);
  final String code;
  @override
  String toString() => 'GameCommandException($code)';
}

class _Arguments {
  const _Arguments(this.values);
  final Map<String, dynamic> values;

  String text(String key, {int max = 200}) {
    final value = values[key];
    if (value is! String ||
        value.trim().isEmpty ||
        value.runes.length > max ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
      throw const GameCommandException('invalid_argument');
    }
    return value;
  }

  String? nullableText(String key) => values[key] == null ? null : text(key);

  int integer(String key, {required int min, required int max}) {
    final value = values[key];
    if (value is! int || value < min || value > max) {
      throw const GameCommandException('invalid_argument');
    }
    return value;
  }

  double number(String key, {required double min, required double max}) {
    final value = values[key];
    if (value is! num || !value.isFinite || value < min || value > max) {
      throw const GameCommandException('invalid_argument');
    }
    return value.toDouble();
  }

  bool boolean(String key) {
    final value = values[key];
    if (value is! bool) throw const GameCommandException('invalid_argument');
    return value;
  }

  T enumValue<T extends Enum>(String key, List<T> options) {
    final name = text(key);
    return options.firstWhere((option) => option.name == name,
        orElse: () => throw const GameCommandException('invalid_argument'));
  }
}
