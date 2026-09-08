import '../models/account_title.dart';
import '../models/chest.dart';
import '../models/dragon_emote.dart';
import '../models/music_track.dart';
import '../models/mystic_relic.dart';
import '../models/profile_portrait.dart';
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
