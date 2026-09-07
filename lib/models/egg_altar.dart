import 'dart:math';

import 'mystic_relic.dart';

enum WeaveMaterial { shellFragments, draconicEssence, weaveheart }

extension WeaveMaterialPresentation on WeaveMaterial {
  String get label => switch (this) {
        WeaveMaterial.shellFragments => 'Shell Fragments',
        WeaveMaterial.draconicEssence => 'Draconic Essence',
        WeaveMaterial.weaveheart => 'Weaveheart',
      };
  String get asset => 'assets/images/egg_altar/${switch (this) {
        WeaveMaterial.shellFragments => 'shell_fragments',
        WeaveMaterial.draconicEssence => 'draconic_essence',
        WeaveMaterial.weaveheart => 'weaveheart',
      }}.png';
}

/// Crafted stock is separate from the existing drop inventory: it cannot enter
/// a trade pool or be restored over the authoritative crafting ledger.
enum AltarRelic {
  moralEcho,
  orderSigil,
  astralLens,
  weaveOracle,
  nameweaversQuill
}

extension AltarRelicPresentation on AltarRelic {
  String get label => switch (this) {
        AltarRelic.moralEcho => 'Moral Echo',
        AltarRelic.orderSigil => 'Order Sigil',
        AltarRelic.astralLens => 'Astral Lens',
        AltarRelic.weaveOracle => 'Weave Oracle',
        AltarRelic.nameweaversQuill => "Nameweaver's Quill",
      };
  String get asset => this == AltarRelic.astralLens
      ? MysticRelic.astralLens.assetPath
      : 'assets/images/egg_altar/${switch (this) {
          AltarRelic.moralEcho => 'moral_echo',
          AltarRelic.orderSigil => 'order_sigil',
          AltarRelic.weaveOracle => 'weave_oracle',
          AltarRelic.nameweaversQuill => 'nameweavers_quill',
          AltarRelic.astralLens => 'astral_lens',
        }}.png';
  WeaveWallet get cost => switch (this) {
        AltarRelic.moralEcho => const WeaveWallet(20, 1, 0),
        AltarRelic.orderSigil => const WeaveWallet(30, 2, 0),
        AltarRelic.astralLens => const WeaveWallet(50, 5, 1),
        AltarRelic.weaveOracle => const WeaveWallet(125, 12, 2),
        AltarRelic.nameweaversQuill => const WeaveWallet(10, 1, 0),
      };
  String get knownKey => switch (this) {
        AltarRelic.moralEcho => 'moral',
        AltarRelic.orderSigil => 'order',
        AltarRelic.astralLens => 'rarity',
        AltarRelic.weaveOracle => 'lineage',
        AltarRelic.nameweaversQuill => 'name',
      };
}

class WeaveWallet {
  const WeaveWallet(this.fragments, this.essence, this.hearts);
  final int fragments;
  final int essence;
  final int hearts;
  int count(WeaveMaterial material) => switch (material) {
        WeaveMaterial.shellFragments => fragments,
        WeaveMaterial.draconicEssence => essence,
        WeaveMaterial.weaveheart => hearts,
      };
  bool covers(WeaveWallet cost) =>
      fragments >= cost.fragments &&
      essence >= cost.essence &&
      hearts >= cost.hearts;
  WeaveWallet operator +(WeaveWallet other) => WeaveWallet(
      fragments + other.fragments,
      essence + other.essence,
      hearts + other.hearts);
  WeaveWallet operator -(WeaveWallet other) => WeaveWallet(
      fragments - other.fragments,
      essence - other.essence,
      hearts - other.hearts);
  Map<String, dynamic> toJson() => {
        'fragments': fragments,
        'essence': essence,
        'hearts': hearts,
      };
  factory WeaveWallet.fromJson(Map<String, dynamic> json) => WeaveWallet(
      _count(json['fragments']),
      _count(json['essence']),
      _count(json['hearts']));
}

int _count(Object? value) => value is num ? max(0, value.toInt()) : 0;

class AltarEggKnowledge {
  const AltarEggKnowledge(
      {this.tagged = false,
      this.tagRevision = 0,
      this.moral = false,
      this.order = false,
      this.rarity = false,
      this.lineage = false});
  final bool tagged;
  final int tagRevision;
  final bool moral;
  final bool order;
  final bool rarity;
  final bool lineage;
  bool knows(AltarRelic relic) => switch (relic) {
        AltarRelic.moralEcho => moral,
        AltarRelic.orderSigil => order,
        AltarRelic.astralLens => rarity,
        AltarRelic.weaveOracle => lineage,
        AltarRelic.nameweaversQuill => false,
      };
  AltarEggKnowledge merge(AltarEggKnowledge other) => AltarEggKnowledge(
        tagged: other.tagRevision > tagRevision
            ? other.tagged
            : other.tagRevision == tagRevision
                ? tagged || other.tagged
                : tagged,
        tagRevision: max(tagRevision, other.tagRevision),
        moral: moral || other.moral,
        order: order || other.order,
        rarity: rarity || other.rarity,
        lineage: lineage || other.lineage,
      );
  Map<String, dynamic> toJson() => {
        'tagged': tagged,
        'tagRevision': tagRevision,
        'moral': moral,
        'order': order,
        'rarity': rarity,
        'lineage': lineage,
      };
  factory AltarEggKnowledge.fromJson(Map<String, dynamic> json) =>
      AltarEggKnowledge(
        tagged: json['tagged'] == true,
        tagRevision: _count(json['tagRevision']),
        moral: json['moral'] == true,
        order: json['order'] == true,
        rarity: json['rarity'] == true,
        lineage: json['lineage'] == true,
      );
}

class EggAltarState {
  EggAltarState({
    this.ownerId,
    this.revision = 0,
    this.wallet = const WeaveWallet(0, 0, 0),
    this.misses = 0,
    this.totalReturned = 0,
    Map<String, int>? crafted,
    Map<String, AltarEggKnowledge>? eggs,
    Set<String>? returnedIds,
    Map<String, String>? names,
    Map<String, Map<String, dynamic>>? operations,
  })  : crafted = crafted ?? {},
        eggs = eggs ?? {},
        returnedIds = returnedIds ?? {},
        names = names ?? {},
        operations = operations ?? {};
  final String? ownerId;
  int revision;
  WeaveWallet wallet;
  int misses;
  int totalReturned;
  final Map<String, int> crafted;
  final Map<String, AltarEggKnowledge> eggs;
  final Set<String> returnedIds;
  final Map<String, String> names;
  final Map<String, Map<String, dynamic>> operations;
  int count(AltarRelic relic) => crafted[relic.name] ?? 0;
  AltarEggKnowledge knowledge(String id) =>
      eggs[id] ?? const AltarEggKnowledge();
  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'revision': revision,
        'wallet': wallet.toJson(),
        'misses': misses,
        'totalReturned': totalReturned,
        'crafted': crafted,
        'eggs': eggs.map((id, knowledge) => MapEntry(id, knowledge.toJson())),
        'returnedIds': returnedIds.toList(),
        'names': names,
        'operations': operations,
      };
  factory EggAltarState.fromJson(Map<String, dynamic> json) => EggAltarState(
        ownerId: json['ownerId'] as String?,
        revision: _count(json['revision']),
        wallet: WeaveWallet.fromJson(
            Map<String, dynamic>.from(json['wallet'] as Map? ?? {})),
        misses: _count(json['misses']).clamp(0, 39),
        totalReturned: _count(json['totalReturned']),
        crafted: (json['crafted'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), _count(v))),
        eggs: (json['eggs'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(),
            AltarEggKnowledge.fromJson(Map<String, dynamic>.from(v as Map)))),
        returnedIds:
            (json['returnedIds'] as List? ?? []).whereType<String>().toSet(),
        names: (json['names'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        operations: (json['operations'] as Map? ?? {}).map((k, v) =>
            MapEntry(k.toString(), Map<String, dynamic>.from(v as Map))),
      );
}

/// Independent Essence and heart rolls, with account pity once per returned egg.
WeaveWallet rollWeaveReturn(Random random,
    {required bool sinister, required int misses}) {
  final essenceRoll = random.nextDouble();
  final essence =
      sinister ? 3 + (essenceRoll * 3).floor() : (essenceRoll < .25 ? 1 : 0);
  final heart = random.nextDouble() < (sinister ? .10 : .02) || misses >= 39;
  return WeaveWallet(sinister ? 25 : 5, essence, heart ? 1 : 0);
}

class EggAltarException implements Exception {
  const EggAltarException(this.code);
  final String code;
  @override
  String toString() => code;
}

/// The server returns both a current state and the immutable operation receipt.
typedef EggAltarCommand = Future<Map<String, dynamic>> Function(
    String operationId, String action, Map<String, dynamic> payload);
