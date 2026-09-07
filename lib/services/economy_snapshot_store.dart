import 'dart:convert';
import 'dart:io';

import 'economy_inventory_snapshot.dart';
import 'server_economy_repository.dart';

/// A separate, owner-scoped journal. Cloud restore never rewinds this fence.
/// Atomic file replacement means a crash exposes either complete revision.
class EconomySnapshotStore {
  EconomySnapshotStore(this.directory);
  final Directory directory;
  static final Map<String, Future<void>> _queues = {};
  static final _uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  Future<T> _serial<T>(String owner, Future<T> Function() action) {
    if (!_uuid.hasMatch(owner)) {
      return Future.error(
          const ServerEconomyException('economy_request_invalid'));
    }
    final key = '${directory.absolute.path}/$owner';
    final result = (_queues[key] ?? Future<void>.value()).then((_) => action());
    final settled =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _queues[key] = settled;
    settled.then((_) {
      if (identical(_queues[key], settled)) _queues.remove(key);
    });
    return result;
  }

  File _file(String owner) => File('${directory.path}/snapshot-$owner.json');

  Future<EconomyInventorySnapshot?> _load(String owner) async {
    final file = _file(owner);
    if (!await file.exists()) return null;
    if (await file.length() > 64 * 1024 * 1024) {
      throw const ServerEconomyException('economy_snapshot_invalid');
    }
    try {
      final snapshot = EconomyInventorySnapshot.fromCache(
          jsonDecode(await file.readAsString()));
      if (snapshot.ownerId != owner) {
        throw const ServerEconomyException('economy_snapshot_invalid');
      }
      return snapshot;
    } on FormatException {
      throw const ServerEconomyException('economy_snapshot_invalid');
    }
  }

  Future<EconomyInventorySnapshot?> load(String owner) =>
      _serial(owner, () => _load(owner));

  Future<void> persist(EconomyInventorySnapshot snapshot) =>
      _serial(snapshot.ownerId, () async {
        final previous = await _load(snapshot.ownerId);
        if (previous != null) {
          if (snapshot.serverRevision < previous.serverRevision ||
              snapshot.walletRevision < previous.walletRevision) {
            throw const ServerEconomyException('economy_snapshot_stale');
          }
          if (snapshot.serverRevision == previous.serverRevision) {
            if (jsonEncode(snapshot.toJson()) !=
                jsonEncode(previous.toJson())) {
              throw const ServerEconomyException('economy_snapshot_invalid');
            }
            return;
          }
        }
        await directory.create(recursive: true);
        final target = _file(snapshot.ownerId);
        final temporary = File('${target.path}.tmp');
        await temporary.writeAsString(jsonEncode(snapshot.toJson()),
            flush: true);
        await temporary.rename(target.path);
      });
}
