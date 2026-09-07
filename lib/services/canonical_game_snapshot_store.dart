import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'canonical_game_snapshot.dart';

class CanonicalGameCache {
  const CanonicalGameCache(
      this.snapshot, this.minimumRevision, this.needsRepair);
  final CanonicalGameSnapshot? snapshot;
  final int minimumRevision;
  final bool needsRepair;
}

/// Account-private display journal, outside cloud restores. The small revision
/// fence is flushed first: a crash before the large snapshot finishes requires
/// a fresh server read at least as new as that fence. Checksums detect corrupt
/// cache bytes; they are not authentication or mutation authority.
class CanonicalGameSnapshotStore {
  CanonicalGameSnapshotStore(this.directory);
  final Directory directory;
  static final _queues = <String, Future<void>>{};
  static final _uuid =
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  Future<T> _serial<T>(String owner, Future<T> Function() action) {
    if (!_uuid.hasMatch(owner)) {
      return Future.error(
          const CanonicalGameException('game_snapshot_invalid'));
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

  File _snapshotFile(String owner) =>
      File('${directory.path}/game-v2-$owner.json');
  File _fenceFile(String owner) =>
      File('${directory.path}/game-v2-$owner.revision.json');

  Future<Map<String, dynamic>?> _read(File file, int limit) async {
    if (!await file.exists()) return null;
    if (await file.length() > limit) {
      throw const FormatException('Cache length');
    }
    final value = jsonDecode(await file.readAsString());
    if (value is! Map<String, dynamic> ||
        value.length != 3 ||
        value['version'] != 1 ||
        value['checksum'] is! String ||
        value['value'] is! Map<String, dynamic> ||
        _checksum(value['value']) != value['checksum']) {
      throw const FormatException('Cache checksum');
    }
    return value['value'] as Map<String, dynamic>;
  }

  Future<_Observation> _inspect(String owner) async {
    var corrupt = false;
    Map<String, dynamic>? fence;
    CanonicalGameSnapshot? snapshot;
    try {
      fence = await _read(_fenceFile(owner), 4096);
      if (fence != null &&
          (fence.length != 4 ||
              fence['owner'] != owner ||
              fence['revision'] is! int ||
              (fence['revision'] as int) < 1 ||
              (fence['revision'] as int) > 9007199254740991 ||
              !_hash(fence['stateHash']) ||
              !_hash(fence['rulesetHash']))) {
        throw const FormatException('Cache fence');
      }
    } on FormatException {
      corrupt = true;
      fence = null;
    }
    try {
      final value = await _read(_snapshotFile(owner), 10 * 1024 * 1024);
      if (value != null) {
        snapshot = CanonicalGameSnapshot.parse(value, expectedOwner: owner);
      }
    } on FormatException {
      corrupt = true;
    } on CanonicalGameException {
      corrupt = true;
    }
    final fenceRevision = fence?['revision'] as int? ?? 0;
    final snapshotRevision = snapshot?.serverRevision ?? 0;
    final minimum =
        fenceRevision > snapshotRevision ? fenceRevision : snapshotRevision;
    if (fenceRevision != snapshotRevision ||
        snapshot != null &&
            (fence?['stateHash'] != snapshot.stateHash ||
                fence?['rulesetHash'] != snapshot.rulesetHash)) {
      corrupt = true;
    }
    return _Observation(
        CanonicalGameCache(corrupt ? null : snapshot, minimum, corrupt),
        fence,
        snapshot);
  }

  Future<CanonicalGameCache> inspect(String owner) =>
      _serial(owner, () async => (await _inspect(owner)).cache);

  /// Call only with the result of an authenticated fresh read. Corrupt display
  /// files are replaced without discarding the greatest surviving revision.
  /// A pending command's receipt revision must also fence the caller's read.
  Future<void> persistFresh(CanonicalGameSnapshot snapshot) =>
      _serial(snapshot.ownerId, () async {
        final previous = await _inspect(snapshot.ownerId);
        if (snapshot.serverRevision < previous.cache.minimumRevision) {
          throw const CanonicalGameException('game_snapshot_stale');
        }
        final fence = previous.fence;
        if (fence?['revision'] == snapshot.serverRevision &&
            (fence?['stateHash'] != snapshot.stateHash ||
                fence?['rulesetHash'] != snapshot.rulesetHash)) {
          throw const CanonicalGameException('game_snapshot_conflict');
        }
        if (previous.snapshot?.serverRevision == snapshot.serverRevision &&
            !previous.snapshot!.hasSameState(snapshot)) {
          throw const CanonicalGameException('game_snapshot_conflict');
        }
        await directory.create(recursive: true);
        await _write(_fenceFile(snapshot.ownerId), {
          'owner': snapshot.ownerId,
          'revision': snapshot.serverRevision,
          'stateHash': snapshot.stateHash,
          'rulesetHash': snapshot.rulesetHash,
        });
        await _write(_snapshotFile(snapshot.ownerId), snapshot.toJson());
      });

  Future<void> _write(File target, Map<String, dynamic> value) async {
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'checksum': _checksum(value),
          'value': value,
        }),
        flush: true);
    await temporary.rename(target.path);
  }

  static String _checksum(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(value))).toString();
  static bool _hash(Object? value) =>
      value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
}

class _Observation {
  const _Observation(this.cache, this.fence, this.snapshot);
  final CanonicalGameCache cache;
  final Map<String, dynamic>? fence;
  final CanonicalGameSnapshot? snapshot;
}
