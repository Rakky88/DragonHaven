import '../models/adventure.dart';
import '../models/chest.dart';
import '../models/egg_altar.dart';
import '../models/house.dart';
import '../models/mystic_relic.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import 'server_entropy.dart';
import 'game_state_envelope.dart';

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
  }) async {
    final keys = _commandKeys[action];
    if (keys == null ||
        payload.length != keys.length ||
        !keys.every(payload.containsKey)) {
      throw const GameCommandException('invalid_command');
    }
    final args = _Arguments(payload);
    final identities = ServerEntropy(secretSeed, stream: 'identities');
    final game = HouseholdProvider.forServerState(
      state,
      random: ServerEntropy(secretSeed, stream: 'rewards'),
      now: now,
      idGenerator: identities.uuid,
    );
    try {
      // Scores, reward amounts, paid entitlements, trade settlements and social
      // claims are deliberately absent. They need verified server records.
      final Object? result;
      switch (action) {
        case 'refresh':
          await game.refreshForCurrentDate();
          result = true;
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
        'state':
            GameStateEnvelope.preserveUnknownMetadata(state, game.exportState())
      };
    } on EggAltarException catch (error) {
      throw GameCommandException(error.code);
    } finally {
      game.dispose();
    }
  }

  static const _commandKeys = <String, Set<String>>{
    'refresh': {},
    'purchase_portrait_chest': {},
    'purchase_title_chest': {},
    'purchase_music_chest': {},
    'purchase_furniture': {'catalogId'},
    'purchase_relic': {'relic'},
    'open_chests': {'tier', 'count'},
    'open_special_chests': {'catalogId', 'count'},
    'use_relic': {'relic', 'dragonId'},
    'use_astral_lens': {'eggId'},
    'tag_egg': {'eggId', 'tagged'},
    'return_egg': {'eggId', 'sinisterConfirmed'},
    'craft_altar_relic': {'relic'},
    'use_altar_relic': {'relic', 'eggId'},
    'use_chronoshard': {'reductionPercent'},
    'use_wayfinder': {'kind', 'replaceAdventureId'},
    'equip_twinstar': {'dragonId'},
    'activate_egg': {'eggId'},
    'hatch_egg': {'eggId'},
    'name_dragon': {'dragonId', 'name'},
    'evolve_dragon': {'dragonId'},
    'buy_starlight_treat': {'dragonId'},
    'release_dragon': {'dragonId'},
    'start_adventure': {'adventureId', 'dragonId'},
    'dismiss_adventure': {'adventureId'},
    'claim_adventure': {'runId'},
    'abort_adventure': {'runId'},
    'dismiss_trial': {'offerId'},
    'claim_constellation': {},
    'unlock_room': {'roomId'},
    'build_floor': {'roomId'},
    'repair_floor': {'index'},
    'upgrade_ward': {},
    'complete_tutorial': {'fullyViewed'},
    'redeem_code': {'code'},
  };

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
