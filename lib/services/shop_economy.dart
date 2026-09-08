import '../models/account_title.dart';
import '../models/chest.dart';
import '../models/house.dart';
import '../models/music_track.dart';
import '../models/mystic_relic.dart';
import '../models/profile_portrait.dart';
import '../models/shop_item.dart';
import '../providers/household_provider.dart';
import 'canonical_game_session.dart';
import 'canonical_game_actions.dart';
import 'canonical_game_snapshot.dart';

/// The shop reads one inventory source and sends actions to that same source.
/// A missing/offline server view never falls back to the device's old wallet.
class ShopEconomy {
  ShopEconomy.legacy(HouseholdProvider game)
      : _legacy = game,
        _session = null,
        _view = null,
        _actions = null;
  ShopEconomy.canonical(CanonicalGameSession session)
      : _legacy = null,
        _session = session,
        _view = session.snapshot,
        _actions = CanonicalGameActions(session);

  final HouseholdProvider? _legacy;
  final CanonicalGameSession? _session;
  final CanonicalGameSnapshot? _view;
  final CanonicalGameActions? _actions;

  bool get available => _legacy != null || _view != null;
  bool get canAct => _legacy != null || _session!.canAct;
  CanonicalShopView get _shop => _view!.shop;
  int get coins => _legacy?.pet.coins ?? _view!.coins;
  int get gems => _legacy?.pet.gems ?? _view!.gems;
  HouseRoomDefinition get activeRoom =>
      _legacy?.activeRoom ?? houseRoomById(_shop.activeRoomId)!;
  bool owns(ShopItem item) =>
      _legacy?.owns(item) ?? _shop.ownedItems.contains(item.id);
  bool isEquipped(ShopItem item) =>
      _legacy?.isEquipped(item) ?? _shop.placedItems.contains(item.id);
  bool get supporterPackOwned =>
      _legacy?.supporterPackOwned ?? _shop.supporterPackOwned;
  bool ownsDragonEmotePack(String id) =>
      _legacy?.ownsDragonEmotePack(id) ?? _shop.emotePacks.contains(id);
  int relicCount(MysticRelic relic) =>
      _legacy?.relicCount(relic) ?? _shop.relics[relic.name] ?? 0;
  int untradeableRelicCount(MysticRelic relic) =>
      _legacy?.untradeableRelicCount(relic) ??
      _shop.untradeableRelics[relic.name] ??
      0;
  int chestCount(ChestTier tier) =>
      _legacy?.chestCount(tier) ?? _shop.chests[tier.name] ?? 0;
  int get chestPortraitCount =>
      _legacy?.chestPortraitCount ??
      profilePortraitCatalog
          .where((p) => _shop.portraits.contains(p.id))
          .length;
  int get chestTitleCount =>
      _legacy?.chestTitleCount ??
      accountTitleCatalog.where((t) => _shop.titles.contains(t.id)).length;
  int get musicTrackCount => _legacy?.musicTrackCount ?? _shop.music.length;
  bool get hasEveryPortrait =>
      chestPortraitCount >= profilePortraitCatalog.length;
  bool get hasEveryTitle => chestTitleCount >= accountTitleCatalog.length;
  bool get hasEveryMusicTrack => musicTrackCount >= musicCatalog.length;
  bool get portraitChestCapacityReached =>
      chestPortraitCount + chestCount(ChestTier.portrait) >=
      profilePortraitCatalog.length;
  bool get titleChestCapacityReached =>
      chestTitleCount + chestCount(ChestTier.title) >=
      accountTitleCatalog.length;
  bool get musicChestCapacityReached =>
      musicTrackCount + chestCount(ChestTier.music) >= musicCatalog.length;
  Map<PortraitRarity, int> get remainingPortraitsByRarity =>
      _legacy?.remainingPortraitsByRarity ??
      {
        for (final rarity in PortraitRarity.values)
          rarity: profilePortraitCatalog
              .where(
                  (p) => p.rarity == rarity && !_shop.portraits.contains(p.id))
              .length,
      };

  Future<PurchaseResult> purchaseOrEquip(ShopItem item) => _legacy != null
      ? _legacy.purchaseOrEquip(item)
      : _command(
          'purchase_furniture', {'catalogId': item.id}, PurchaseResult.values);
  Future<MysticRelicPurchaseResult> purchaseRelic(MysticRelic relic) =>
      _legacy != null
          ? _legacy.purchaseRelic(relic)
          : _command('purchase_relic', {'relic': relic.name},
              MysticRelicPurchaseResult.values);
  Future<PortraitChestPurchaseResult> purchasePortraitChest() => _legacy != null
      ? _legacy.purchasePortraitChest()
      : _command(
          'purchase_portrait_chest', {}, PortraitChestPurchaseResult.values);
  Future<TitleChestPurchaseResult> purchaseTitleChest() => _legacy != null
      ? _legacy.purchaseTitleChest()
      : _command('purchase_title_chest', {}, TitleChestPurchaseResult.values);
  Future<MusicChestPurchaseResult> purchaseMusicChest() => _legacy != null
      ? _legacy.purchaseMusicChest()
      : _command('purchase_music_chest', {}, MusicChestPurchaseResult.values);

  Future<T> _command<T extends Enum>(
      String action, Map<String, dynamic> payload, List<T> outcomes) async {
    final result = await _actions!.execute(action, payload);
    for (final outcome in outcomes) {
      if (outcome.name == result) return outcome;
    }
    throw const CanonicalGameException('game_result_invalid');
  }
}
