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

  Future<CanonicalGameIntent?> pending(String owner) =>
      _serial(owner, () => _pending(owner));

  Future<CanonicalGameIntent> prepare(CanonicalGameIntent intent) =>
      _serial(intent.ownerId, () async {
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
}
