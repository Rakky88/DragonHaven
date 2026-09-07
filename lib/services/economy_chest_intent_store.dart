import 'dart:convert';
import 'dart:io';

import 'server_economy_repository.dart';

/// A pending intent is device-local and account-scoped, outside cloud backups.
/// Persist it BEFORE an RPC. Acknowledge only AFTER reconciling server state;
/// a timeout, app restart or failed local save must retain the same request ID.
class EconomyChestIntent {
  EconomyChestIntent(
      {required this.ownerId,
      required this.requestId,
      required List<String> chestIds})
      : chestIds = List.unmodifiable(chestIds) {
    if (!_uuid.hasMatch(ownerId) ||
        !_uuid.hasMatch(requestId) ||
        chestIds.isEmpty ||
        chestIds.length > 10 ||
        chestIds.any((id) => !_uuid.hasMatch(id)) ||
        chestIds.toSet().length != chestIds.length) {
      throw const ServerEconomyException('economy_request_invalid');
    }
  }

  final String ownerId;
  final String requestId;
  final List<String> chestIds;

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  Map<String, Object> toJson() => {
        'version': 1,
        'owner': ownerId,
        'request': requestId,
        'chests': chestIds,
      };

  factory EconomyChestIntent.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['owner'] is! String ||
        raw['request'] is! String ||
        raw['chests'] is! List ||
        (raw['chests'] as List).any((id) => id is! String)) {
      throw const ServerEconomyException('economy_pending_intent_invalid');
    }
    return EconomyChestIntent(
        ownerId: raw['owner'] as String,
        requestId: raw['request'] as String,
        chestIds: (raw['chests'] as List).cast<String>());
  }
}

/// Use a directory in the application's private support storage. This is a
/// single-isolate store (like the game's existing StorageService); instances
/// share a serialization queue so two UI submits cannot replace an intent.
class EconomyChestIntentStore {
  EconomyChestIntentStore(this.directory);

  final Directory directory;
  static final Map<String, Future<void>> _queues = {};

  Future<T> _serial<T>(String owner, Future<T> Function() action) {
    if (!EconomyChestIntent._uuid.hasMatch(owner)) {
      return Future.error(
          const ServerEconomyException('economy_request_invalid'));
    }
    final key = '${directory.absolute.path}/$owner';
    final previous = _queues[key] ?? Future<void>.value();
    final result = previous.then((_) => action());
    final settled =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _queues[key] = settled;
    settled.then((_) {
      if (identical(_queues[key], settled)) _queues.remove(key);
    });
    return result;
  }

  File _file(String owner) => File('${directory.path}/chest-$owner.json');

  Future<EconomyChestIntent?> _load(String owner) async {
    final file = _file(owner);
    if (!await file.exists()) return null;
    if (await file.length() > 4096) {
      throw const ServerEconomyException('economy_pending_intent_invalid');
    }
    try {
      final intent =
          EconomyChestIntent.fromJson(jsonDecode(await file.readAsString()));
      if (intent.ownerId != owner) {
        throw const ServerEconomyException('economy_pending_intent_invalid');
      }
      return intent;
    } on FormatException {
      throw const ServerEconomyException('economy_pending_intent_invalid');
    }
  }

  Future<EconomyChestIntent?> pending(String owner) =>
      _serial(owner, () => _load(owner));

  Future<EconomyChestIntent> prepare(EconomyChestIntent intent) =>
      _serial(intent.ownerId, () async {
        final existing = await _load(intent.ownerId);
        if (existing != null) {
          if (jsonEncode(existing.toJson()) != jsonEncode(intent.toJson())) {
            throw const ServerEconomyException('economy_pending_intent_exists');
          }
          return existing;
        }
        await directory.create(recursive: true);
        final target = _file(intent.ownerId);
        final temporary = File('${target.path}.tmp');
        await temporary.writeAsString(jsonEncode(intent.toJson()), flush: true);
        await temporary.rename(target.path);
        return intent;
      });

  Future<void> acknowledge(
          {required String ownerId, required String requestId}) =>
      _serial(ownerId, () async {
        final intent = await _load(ownerId);
        if (intent == null) return;
        if (intent.requestId != requestId) {
          throw const ServerEconomyException('economy_pending_intent_mismatch');
        }
        await _file(ownerId).delete();
      });
}

/// Reconciliation applies absolute balances only if revisions are current.
/// Opening receipts can legitimately describe an old chest after a later
/// purchase. They must never be added as currency deltas on the device.
bool acceptsEconomyWalletRevision(
        {required int currentRevision, required int incomingRevision}) =>
    incomingRevision >= currentRevision;
