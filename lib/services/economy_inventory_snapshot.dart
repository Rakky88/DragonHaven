import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'server_economy_repository.dart';

/// A complete, owner-scoped snapshot of the phase 4B wallet/chest/item tables.
/// Egg/dragon lifecycle and Altar ledgers have separate authority boundaries.
class EconomyInventorySnapshot {
  const EconomyInventorySnapshot._({
    required this.ownerId,
    required this.serverRevision,
    required this.walletRevision,
    required this.coins,
    required this.gems,
    required this.instances,
  });

  final String ownerId;
  final int serverRevision;
  final int walletRevision;
  final int coins;
  final int gems;
  final List<EconomyInventoryInstance> instances;
}

class EconomyInventoryInstance {
  const EconomyInventoryInstance._({
    required this.id,
    required this.kind,
    required this.catalogId,
    required this.state,
    required this.tradeable,
    this.itemKind,
    this.specialChestId,
    this.reductionPercent,
  });

  final String id;
  final String kind;
  final String catalogId;
  final String state;
  final bool tradeable;
  final String? itemKind;
  final String? specialChestId;
  final int? reductionPercent;

  String get _key => '$kind/$id';

  factory EconomyInventoryInstance._parse(Object? value) {
    final row = _object(value);
    final kind = row['kind'];
    final id = row['id'];
    final catalog = row['catalog_id'];
    final state = row['state'];
    final special = row['special_chest_id'];
    final item = row['item_kind'];
    final reduction = row['reduction_percent'];
    if (!_validUuid(id) ||
        !const {'chest', 'item'}.contains(kind) ||
        !_validCatalog(catalog) ||
        !const {'owned', 'reserved', 'equipped'}.contains(state) ||
        row['tradeable'] is! bool ||
        (special != null && !_validCatalog(special)) ||
        (kind == 'chest' &&
            (!const {
                  'wooden',
                  'silver',
                  'gold',
                  'dragon',
                  'mythical',
                  'sinister',
                  'special',
                  'portrait',
                  'title',
                  'music'
                }.contains(catalog) ||
                state == 'equipped' ||
                item != null ||
                ((catalog == 'special') != (special != null)))) ||
        (kind == 'item' &&
            (!const {
                  'relic',
                  'furniture',
                  'portrait',
                  'title',
                  'music',
                  'emote',
                  'badge',
                  'portrait_frame',
                  'consumable'
                }.contains(item) ||
                special != null)) ||
        (catalog == 'chronoshard' && item == 'relic'
            ? (reduction is! int || reduction < 10 || reduction > 90)
            : reduction != null)) {
      throw _invalid;
    }
    return EconomyInventoryInstance._(
      id: id as String,
      kind: kind as String,
      catalogId: catalog as String,
      state: state as String,
      tradeable: row['tradeable'] as bool,
      itemKind: item as String?,
      specialChestId: special as String?,
      reductionPercent: reduction as int?,
    );
  }
}

/// Dormant read boundary. The server requires `server` authority; production
/// keepers remain in legacy mode. No UI or local balance mutation is activated.
class EconomyInventoryReader {
  const EconomyInventoryReader(this._invoke);
  final EconomyRpcInvoker _invoke;

  /// Never exposes partial pages. A mutation between pages discards that attempt
  /// and permits one fresh attempt; repeated changes fail without applying data.
  Future<EconomyInventorySnapshot> fetch({
    required String ownerId,
    int minimumServerRevision = 0,
    int minimumWalletRevision = 0,
  }) async {
    if (!_validUuid(ownerId) ||
        minimumServerRevision < 0 ||
        minimumWalletRevision < 0) {
      throw const ServerEconomyException('economy_request_invalid');
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _fetch(
            ownerId, minimumServerRevision, minimumWalletRevision);
      } on ServerEconomyException catch (error) {
        if (error.code != 'economy_snapshot_changed' || attempt == 1) rethrow;
      } on PostgrestException catch (error) {
        if (error.message != 'economy_snapshot_changed' || attempt == 1) {
          rethrow;
        }
      }
    }
    throw _invalid;
  }

  Future<EconomyInventorySnapshot> _fetch(
      String owner, int minimumServer, int minimumWallet) async {
    Map<String, dynamic>? first;
    Map<String, dynamic>? cursor;
    final instances = <EconomyInventoryInstance>[];
    String? previousKey;
    // Bound pathological responses without silently truncating a valid inventory.
    for (var pageIndex = 0; pageIndex < 1000; pageIndex++) {
      final page = _object(await _invoke('get_my_economy_inventory_page', {
        'p_protocol_version': ServerEconomyRepository.protocolVersion,
        'p_client_build': ServerEconomyRepository.clientBuild,
        'p_expected_revision': first?['server_revision'],
        'p_after_kind': cursor?['kind'],
        'p_after_id': cursor?['id'],
        'p_page_size': 100,
      }));
      if (page['snapshot_version'] is! int ||
          page['snapshot_version'] != 1 ||
          page['owner_id'] != owner ||
          !_nonNegativeInt(page['server_revision']) ||
          !_nonNegativeInt(page['wallet_revision']) ||
          page['wallet_revision'] == 0 ||
          !_nonNegativeInt(page['coins']) ||
          !_nonNegativeInt(page['gems']) ||
          page['instances'] is! List ||
          (page['instances'] as List).length > 100 ||
          !page.containsKey('next_cursor')) {
        throw _invalid;
      }
      if ((page['server_revision'] as int) < minimumServer ||
          (page['wallet_revision'] as int) < minimumWallet) {
        throw const ServerEconomyException('economy_snapshot_stale');
      }
      if (first != null) {
        if (page['server_revision'] != first['server_revision']) {
          throw const ServerEconomyException('economy_snapshot_changed');
        }
        for (final field in ['wallet_revision', 'coins', 'gems']) {
          if (page[field] != first[field]) throw _invalid;
        }
      }
      first ??= page;
      final rows = (page['instances'] as List)
          .map(EconomyInventoryInstance._parse)
          .toList();
      for (final entry in rows) {
        if (previousKey != null && entry._key.compareTo(previousKey) <= 0) {
          throw _invalid;
        }
        previousKey = entry._key;
        instances.add(entry);
      }
      final next = page['next_cursor'];
      if (next == null) {
        return EconomyInventorySnapshot._(
          ownerId: owner,
          serverRevision: first['server_revision'] as int,
          walletRevision: first['wallet_revision'] as int,
          coins: first['coins'] as int,
          gems: first['gems'] as int,
          instances: List.unmodifiable(instances),
        );
      }
      cursor = _object(next);
      if (rows.isEmpty ||
          rows.length != 100 ||
          cursor.length != 2 ||
          cursor['kind'] != rows.last.kind ||
          cursor['id'] != rows.last.id) {
        throw _invalid;
      }
    }
    throw const ServerEconomyException('economy_snapshot_too_large');
  }
}

const _invalid = ServerEconomyException('economy_snapshot_invalid');
final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
bool _validUuid(Object? value) => value is String && _uuid.hasMatch(value);
bool _validCatalog(Object? value) =>
    value is String && RegExp(r'^[A-Za-z0-9_.-]{1,100}$').hasMatch(value);
bool _nonNegativeInt(Object? value) => value is int && value >= 0;
Map<String, dynamic> _object(Object? raw) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) throw _invalid;
  return Map<String, dynamic>.from(raw);
}
