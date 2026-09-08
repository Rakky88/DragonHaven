import 'dart:convert';

import '../models/house.dart';

/// Read-only server display data. It is deliberately incompatible with a local
/// saved game: an unknown lineage is null, never a guessed DragonEgg/Pet.
class CanonicalGameSnapshot {
  CanonicalGameSnapshot._(this._wire, this.eggs, this.shop);
  final Map<String, dynamic> _wire;
  final List<CanonicalEggView> eggs;
  final CanonicalShopView shop;

  String get ownerId => _wire['owner_id'] as String;
  int get serverRevision => _wire['server_revision'] as int;
  String get stateHash => _wire['state_sha256'] as String;
  String get rulesetHash => _wire['ruleset_sha256'] as String;
  int get rulesetRevision => _wire['ruleset_revision'] as int;
  String get authorityMode => _wire['authority_mode'] as String;
  bool get mutationsEnabled => _wire['mutations_enabled'] as bool;
  DateTime get serverTime => DateTime.parse(_wire['server_time'] as String);
  Map<String, dynamic> get data => _wire['data'] as Map<String, dynamic>;
  int get coins => data['wallet']['coins'] as int;
  int get gems => data['wallet']['gems'] as int;
  String? get activeDragonId => data['activeDragonId'] as String?;

  /// No application path may treat a shadow copy as live player inventory.
  bool get canApplyToLiveGame => false;
  Map<String, dynamic> toJson() => _wire;

  factory CanonicalGameSnapshot.parse(Object? value,
      {required String expectedOwner,
      int minimumRevision = 0,
      int minimumRulesetRevision = 0}) {
    final wire = _map(_freeze(value));
    if (!_uuid.hasMatch(expectedOwner) ||
        !_keys(wire, const [
          'protocol',
          'owner_id',
          'server_revision',
          'state_sha256',
          'ruleset_sha256',
          'ruleset_revision',
          'authority_mode',
          'mutations_enabled',
          'server_time',
          'data'
        ]) ||
        wire['protocol'] != 2 ||
        wire['owner_id'] != expectedOwner ||
        !_positive(wire['server_revision']) ||
        !_hashValue(wire['state_sha256']) ||
        !_hashValue(wire['ruleset_sha256']) ||
        !_positive(wire['ruleset_revision']) ||
        wire['authority_mode'] != 'shadow' ||
        wire['mutations_enabled'] is! bool ||
        !_date(wire['server_time'])) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    if ((wire['server_revision'] as int) < minimumRevision ||
        (wire['ruleset_revision'] as int) < minimumRulesetRevision) {
      throw const CanonicalGameException('game_snapshot_stale');
    }
    final data = _map(wire['data']);
    if (!_keys(data, const [
          'projectionVersion',
          'activeDragonId',
          'wallet',
          'eggs',
          'dragons',
          'inventory',
          'collection',
          'house',
          'progress',
          'adventures',
          'trials',
          'presentations',
          'activities'
        ]) ||
        data['projectionVersion'] != 1 ||
        (data['activeDragonId'] != null && !_text(data['activeDragonId']))) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    final wallet = _map(data['wallet']);
    if (!_keys(wallet, const ['coins', 'gems']) ||
        !_count(wallet['coins']) ||
        !_count(wallet['gems'])) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    for (final name in const [
      'inventory',
      'collection',
      'house',
      'progress',
      'adventures',
      'trials'
    ]) {
      _map(data[name]);
    }
    for (final name in const [
      'eggs',
      'dragons',
      'presentations',
      'activities'
    ]) {
      if (data[name] is! List) {
        throw const CanonicalGameException('game_snapshot_invalid');
      }
    }
    final eggs = List<CanonicalEggView>.unmodifiable((data['eggs'] as List)
        .map((value) => CanonicalEggView._parse(_map(value))));
    final identities = <String>{};
    for (final egg in eggs) {
      if (!identities.add(egg.id)) {
        throw const CanonicalGameException('game_snapshot_invalid');
      }
    }
    var activeCount = 0;
    for (final raw in data['dragons'] as List) {
      final dragon = _map(raw);
      if (!_text(dragon['id']) ||
          !_text(dragon['lineageId']) ||
          dragon['name'] is! String ||
          !_count(dragon['xp']) ||
          !const ['hatchling', 'wyrmling', 'ascended']
              .contains(dragon['stage']) ||
          !const ['active', 'sanctuary', 'released']
              .contains(dragon['location']) ||
          !identities.add(dragon['id'] as String)) {
        throw const CanonicalGameException('game_snapshot_invalid');
      }
      if (dragon['location'] == 'active') {
        activeCount++;
        if (dragon['id'] != data['activeDragonId']) {
          throw const CanonicalGameException('game_snapshot_invalid');
        }
      }
    }
    if (activeCount != (data['activeDragonId'] == null ? 0 : 1) ||
        eggs.where((e) => e.location == 'nest').length > 1 ||
        utf8.encode(jsonEncode(wire)).length > 9 * 1024 * 1024) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return CanonicalGameSnapshot._(wire, eggs, CanonicalShopView._parse(data));
  }

  /// Read time and the mutation switch may change without a game revision.
  /// Equal revisions must still identify exactly the same private state and
  /// display under the same compiled rules, independent of JSON map order.
  bool hasSameState(CanonicalGameSnapshot other) =>
      ownerId == other.ownerId &&
      serverRevision == other.serverRevision &&
      stateHash == other.stateHash &&
      rulesetHash == other.rulesetHash &&
      rulesetRevision == other.rulesetRevision &&
      jsonEncode(data) == jsonEncode(other.data);
}

/// Validated display fields used by the ordinary shop. Unknown collection IDs
/// are retained; malformed or contradictory stock cannot enable a purchase.
class CanonicalShopView {
  CanonicalShopView._parse(Map<String, dynamic> data) {
    final inventory = _map(data['inventory']);
    final collection = _map(data['collection']);
    final house = _map(data['house']);
    chests = _counts(inventory['chestInventory']);
    specialChests = _counts(inventory['specialChestInventory']);
    reservedChests = _counts(inventory['reservedOnlineTradeChests']);
    relics = _counts(inventory['relicInventory']);
    untradeableRelics = _counts(inventory['untradeableRelicInventory']);
    portraits = _ids(collection['ownedPortraitIds']);
    titles = _ids(collection['ownedTitleIds']);
    music = _ids(collection['ownedMusicTrackIds']);
    emotePacks = _ids(collection['ownedDragonEmotePackIds']);
    ownedItems = _ids(house['ownedItemIds']);
    if (collection['supporterPackOwned'] is! bool ||
        house['activeRoomId'] is! String ||
        houseRoomById(house['activeRoomId'] as String) == null ||
        house['placements'] is! List ||
        untradeableRelics.entries.any((e) => e.value > (relics[e.key] ?? 0))) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    supporterPackOwned = collection['supporterPackOwned'] as bool;
    activeRoomId = house['activeRoomId'] as String;
    final placed = <String>{};
    for (final raw in house['placements'] as List) {
      final placement = _map(raw);
      final id = placement['itemId'];
      if (id is! String || !ownedItems.contains(id) || !placed.add(id)) {
        throw const CanonicalGameException('game_snapshot_invalid');
      }
    }
    placedItems = Set.unmodifiable(placed);
  }
  late final Map<String, int> chests,
      specialChests,
      reservedChests,
      relics,
      untradeableRelics;
  late final Set<String> portraits,
      titles,
      music,
      emotePacks,
      ownedItems,
      placedItems;
  late final bool supporterPackOwned;
  late final String activeRoomId;

  static Map<String, int> _counts(Object? value) {
    final map = _map(value);
    if (map.entries.any((e) => !_text(e.key) || !_count(e.value))) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return Map.unmodifiable(map.cast<String, int>());
  }

  static Set<String> _ids(Object? value) {
    if (value is! List ||
        value.any((id) => !_text(id)) ||
        value.toSet().length != value.length) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return Set.unmodifiable(value.cast<String>());
  }
}

class CanonicalEggView {
  CanonicalEggView._(this._data);
  final Map<String, dynamic> _data;
  String get id => _data['id'] as String;
  String get location => _data['location'] as String;
  String get kind => _data['kind'] as String;
  String? get specialEggId => _data['specialEggId'] as String?;
  String? get revealedLineageId => _data['lineageId'] as String?;
  String? get revealedRarity => _data['rarity'] as String?;
  String? get revealedLawAxis => _data['lawAxis'] as String?;
  String? get revealedMoralAxis => _data['moralAxis'] as String?;
  bool get tagged => _data['tagged'] as bool;
  String? get returnBlockReason => _data['returnBlockReason'] as String?;
  DateTime get acquiredAt => DateTime.parse(_data['acquiredAt'] as String);
  DateTime? get startedAt => _data['startedAt'] == null
      ? null
      : DateTime.parse(_data['startedAt'] as String);
  Duration get incubation =>
      Duration(seconds: _data['incubationSeconds'] as int);
  int get xp => _data['xp'] as int;
  String hint(String locale) =>
      _data['hints'][locale == 'nl' ? 'nl' : 'en'] as String;

  static CanonicalEggView _parse(Map<String, dynamic> data) {
    if (!_keys(data, const [
          'id',
          'location',
          'kind',
          'specialEggId',
          'acquiredAt',
          'startedAt',
          'incubationSeconds',
          'xp',
          'tagged',
          'returnBlockReason',
          'hints',
          'lineageId',
          'rarity',
          'lawAxis',
          'moralAxis'
        ]) ||
        !_text(data['id']) ||
        !const ['stash', 'nest'].contains(data['location']) ||
        !const ['ordinary', 'sinister', 'special'].contains(data['kind']) ||
        !_date(data['acquiredAt']) ||
        !_positive(data['incubationSeconds']) ||
        (data['incubationSeconds'] as int) > 14 * 24 * 3600 ||
        !_count(data['xp']) ||
        data['tagged'] is! bool ||
        (data['location'] == 'nest'
            ? !_date(data['startedAt'])
            : data['startedAt'] != null)) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    for (final name in const [
      'specialEggId',
      'lineageId',
      'rarity',
      'lawAxis',
      'moralAxis',
      'returnBlockReason'
    ]) {
      if (data[name] != null && !_text(data[name])) {
        throw const CanonicalGameException('game_snapshot_invalid');
      }
    }
    if (data['lineageId'] != null && data['rarity'] == null) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    final hints = _map(data['hints']);
    if (!_keys(hints, const ['en', 'nl']) ||
        !_text(hints['en']) ||
        !_text(hints['nl'])) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return CanonicalEggView._(data);
  }
}

class CanonicalGameException implements Exception {
  const CanonicalGameException(this.code);
  final String code;
  @override
  String toString() => 'CanonicalGameException($code)';
}

final _uuid =
    RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
bool _hashValue(Object? value) =>
    value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
bool _count(Object? value) =>
    value is int && value >= 0 && value <= 9007199254740991;
bool _positive(Object? value) => _count(value) && (value as int) > 0;
bool _text(Object? value) =>
    value is String && value.isNotEmpty && value.length <= 2000;
bool _date(Object? value) =>
    value is String &&
    RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value) &&
    DateTime.tryParse(value) != null;
bool _keys(Map<String, dynamic> data, List<String> keys) =>
    data.length == keys.length && keys.every(data.containsKey);
Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const CanonicalGameException('game_snapshot_invalid');
  }
  return value;
}

Object? _freeze(Object? value, [int depth = 0]) {
  if (depth > 32) throw const CanonicalGameException('game_snapshot_invalid');
  if (value is Map) {
    if (value.length > 100000 ||
        value.keys.any((key) => key is! String) ||
        value.keys.any(const {
          'hatchSeed',
          'secretSeed',
          'secret_seed',
          'lease_token',
          'pendingAltarOperation',
          'operations'
        }.contains)) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    final keys = value.keys.cast<String>().toList()..sort();
    return Map<String, dynamic>.unmodifiable({
      for (final key in keys) key: _freeze(value[key], depth + 1),
    });
  }
  if (value is List && value.length <= 100000) {
    return List<Object?>.unmodifiable(
        value.map((item) => _freeze(item, depth + 1)));
  }
  if (value == null ||
      value is String ||
      value is bool ||
      value is num && value.isFinite) {
    return value;
  }
  throw const CanonicalGameException('game_snapshot_invalid');
}
