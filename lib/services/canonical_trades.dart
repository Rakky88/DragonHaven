import '../models/chest.dart';
import '../models/mystic_relic.dart';
import 'canonical_game_snapshot.dart';

/// An existing, publicly visible inventory item. Commands send only its ID and
/// variant; the database supplies the corresponding private item at commit.
class CanonicalTradeChoice {
  const CanonicalTradeChoice.egg(CanonicalEggView value)
      : egg = value,
        chest = null,
        relic = null,
        variant = 0;
  const CanonicalTradeChoice.chest(ChestTier value)
      : egg = null,
        chest = value,
        relic = null,
        variant = 0;
  const CanonicalTradeChoice.relic(MysticRelic value, {this.variant = 0})
      : egg = null,
        chest = null,
        relic = value;
  final CanonicalEggView? egg;
  final ChestTier? chest;
  final MysticRelic? relic;
  final int variant;
  String get kind => egg != null
      ? 'egg'
      : chest != null
          ? 'chest'
          : 'relic';
  String get key => egg?.id ?? chest?.name ?? relic!.name;
  String get identity => '$kind:$key:$variant';
  factory CanonicalTradeChoice.display(CanonicalTradeItemView item) =>
      item.egg != null
          ? CanonicalTradeChoice.egg(item.egg!)
          : item.chest != null
              ? CanonicalTradeChoice.chest(item.chest!)
              : CanonicalTradeChoice.relic(item.relic!, variant: item.variant);

  static List<CanonicalTradeChoice> available(CanonicalGameSnapshot view) {
    final choices = <CanonicalTradeChoice>[
      for (final egg in view.eggs)
        if (egg.location == 'stash' &&
            !view.inventory.reservedEggIds.contains(egg.id))
          CanonicalTradeChoice.egg(egg),
      for (final chest in ChestTier.values)
        if (chest.isTradeable &&
            (view.shop.chests[chest.name] ?? 0) >
                (view.shop.reservedChests[chest.name] ?? 0))
          CanonicalTradeChoice.chest(chest),
    ];
    for (final relic in MysticRelic.values) {
      if (relic.isAlwaysUntradeable) continue;
      final count = (view.inventory.usableRelics[relic] ?? 0) -
          (view.shop.untradeableRelics[relic.name] ?? 0);
      if (count <= 0) continue;
      if (relic == MysticRelic.chronoshard) {
        final variants = view.inventory.chronoshards.toSet().toList()..sort();
        for (final variant in variants) {
          if (view.inventory.canUseChronoshard(variant)) {
            choices.add(CanonicalTradeChoice.relic(relic, variant: variant));
          }
        }
      } else {
        choices.add(CanonicalTradeChoice.relic(relic));
      }
    }
    return List.unmodifiable(choices);
  }
}
