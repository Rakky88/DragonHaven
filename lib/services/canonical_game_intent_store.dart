import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'canonical_game_intent.dart';
import 'canonical_game_snapshot.dart';

/// Persist both account-private copies before sending a command. A crash or
/// one corrupt copy cannot silently replace the original request UUID. Acknowledge
/// only after a fresh snapshot is durable and its display has been applied.
class CanonicalGameIntentStore {
  CanonicalGameIntentStore(this.directory);
  final Directory directory;
  static final _queues = <String, Future<void>>{};

  Future<T> _serial<T>(String owner, Future<T> Function() action) {
    if (!CanonicalGameIntent.validOwner(owner)) {
      return Future.error(const CanonicalGameException('game_intent_invalid'));
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

  File _file(String owner, bool backup) =>
      File('${directory.path}/intent-v2-$owner${backup ? '.backup' : ''}.json');
  File _recoveryFile(String owner, bool backup) => File(
      '${directory.path}/recovery-v2-$owner${backup ? '.backup' : ''}.json');
  static String _checksum(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(value))).toString();

  Future<CanonicalGameIntent?> _pending(String owner) async {
    final valid = <CanonicalGameIntent>[];
    var corrupted = false;
    for (final backup in [false, true]) {
      final file = _file(owner, backup);
      if (!await file.exists()) continue;
      try {
        if (await file.length() > 10000) {
          throw const FormatException('Intent length');
        }
        final raw = jsonDecode(await file.readAsString());
        if (raw is! Map ||
            raw.length != 2 ||
            _checksum(raw['intent']) != raw['checksum']) {
          throw const FormatException('Intent checksum');
        }
        final intent = CanonicalGameIntent.parse(raw['intent']);
        if (intent.ownerId != owner) {
          throw const FormatException('Intent owner');
        }
        valid.add(intent);
      } on FormatException {
        corrupted = true;
      } on CanonicalGameException {
        corrupted = true;
      }
    }
    if (valid.isEmpty && corrupted ||
        valid.length == 2 && !valid[0].sameIntent(valid[1])) {
      throw const CanonicalGameException('game_intent_recovery_required');
    }
    return valid.firstOrNull;
  }

  Future<bool> _hasRecovery(String owner) async =>
      await _recoveryFile(owner, false).exists() ||
      await _recoveryFile(owner, true).exists();

  Future<CanonicalGameIntent?> pending(String owner) =>
      _serial(owner, () async {
        if (await _hasRecovery(owner)) {
          throw const CanonicalGameException('game_intent_recovery_required');
        }
        return _pending(owner);
      });

  Future<CanonicalGameIntent> prepare(CanonicalGameIntent intent) =>
      _serial(intent.ownerId, () async {
        if (await _hasRecovery(intent.ownerId)) {
          throw const CanonicalGameException('game_intent_recovery_required');
        }
        final previous = await _pending(intent.ownerId);
        if (previous != null && !previous.sameIntent(intent)) {
          throw const CanonicalGameException('game_intent_pending');
        }
        await directory.create(recursive: true);
        final value = intent.toJson();
        final bytes =
            jsonEncode({'intent': value, 'checksum': _checksum(value)});
        for (final backup in [false, true]) {
          final target = _file(intent.ownerId, backup);
          final temporary = File('${target.path}.tmp');
          await temporary.writeAsString(bytes, flush: true);
          await temporary.rename(target.path);
        }
        return previous ?? intent;
      });

  Future<void> acknowledge(String owner, String requestId) =>
      _serial(owner, () async {
        if (await _hasRecovery(owner)) {
          throw const CanonicalGameException('game_intent_recovery_required');
        }
        final pending = await _pending(owner);
        if (pending == null) return;
        if (pending.requestId != requestId) {
          throw const CanonicalGameException('game_intent_mismatch');
        }
        for (final backup in [false, true]) {
          final file = _file(owner, backup);
          if (await file.exists()) await file.delete();
        }
      });

  Future<String?> _recoveryId(String owner) async {
    final ids = <String>{};
    for (final backup in [false, true]) {
      final file = _recoveryFile(owner, backup);
      if (!await file.exists()) continue;
      try {
        if (await file.length() > 1024) continue;
        final raw = jsonDecode(await file.readAsString());
        if (raw is! Map ||
            raw.length != 2 ||
            _checksum(raw['recovery']) != raw['checksum']) {
          continue;
        }
        final value = raw['recovery'];
        if (value is Map &&
            value.length == 3 &&
            value['version'] == 1 &&
            value['owner'] == owner &&
            value['request'] is String &&
            CanonicalGameIntent.validOwner(value['request'] as String)) {
          ids.add(value['request'] as String);
        }
      } on FormatException {
        // An unreadable recovery marker needs another harmless server barrier,
        // never a newly invented purchase or an inferred reward.
      }
    }
    return ids.length == 1 ? ids.single : null;
  }

  /// Called only for a corrupt intent or an interrupted recovery. Keep this
  /// separate marker until the server boundary AND absolute display are durable.
  Future<String> beginRecovery(String owner, String candidateRequestId) =>
      _serial(owner, () async {
        if (!CanonicalGameIntent.validOwner(candidateRequestId)) {
          throw const CanonicalGameException('game_intent_invalid');
        }
        final marked = await _hasRecovery(owner);
        if (!marked) {
          try {
            await _pending(owner);
            throw const CanonicalGameException('game_recovery_not_required');
          } on CanonicalGameException catch (error) {
            if (error.code != 'game_intent_recovery_required') rethrow;
          }
        }
        final requestId = await _recoveryId(owner) ?? candidateRequestId;
        await directory.create(recursive: true);
        final value = {'version': 1, 'owner': owner, 'request': requestId};
        final bytes =
            jsonEncode({'recovery': value, 'checksum': _checksum(value)});
        for (final backup in [false, true]) {
          final target = _recoveryFile(owner, backup);
          final temporary = File('${target.path}.tmp');
          await temporary.writeAsString(bytes, flush: true);
          await temporary.rename(target.path);
        }
        return requestId;
      });

  Future<void> finishRecovery(String owner, String requestId) =>
      _serial(owner, () async {
        if (await _recoveryId(owner) != requestId) {
          throw const CanonicalGameException('game_recovery_mismatch');
        }
        // Remove old intents first. Even if deletion is interrupted, remaining
        // recovery markers keep prepare/send blocked until reconciliation repeats.
        for (final backup in [false, true]) {
          final file = _file(owner, backup);
          if (await file.exists()) await file.delete();
        }
        for (final backup in [false, true]) {
          final file = _recoveryFile(owner, backup);
          if (await file.exists()) await file.delete();
        }
      });
}
