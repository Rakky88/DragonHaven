import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../domain/game_time_bridge.dart';
import '../models/social.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_snapshot.dart';
import 'social_repository.dart';

/// Final optimistic upload while the caller has closed legacy gameplay and
/// drained its background writers. A cloud conflict never selects a winner.
/// A durable digest recovers only this device's exact committed upload. A
/// different or newer cloud save still requires explicit conflict resolution.
class CanonicalLegacyUpload {
  CanonicalLegacyUpload({
    required this.repository,
    required this.directory,
    required this.currentOwner,
    required this.sourceOwner,
    required this.sessionEpoch,
    required this.settleLegacySources,
    required this.exportState,
    required this.localRevision,
    required this.loadBaseRevision,
    required this.saveBaseRevision,
    required this.deviceId,
    required this.clientVersion,
  });

  final SocialRepository repository;
  final Directory directory;
  final String? Function() currentOwner;

  /// Owner of the loaded legacy save, established when it was loaded or
  /// explicitly reconciled. Auth alone does not prove ownership of local data.
  final String? Function() sourceOwner;
  final int Function() sessionEpoch;
  final Future<void> Function(String owner) settleLegacySources;
  final Map<String, dynamic> Function() exportState;
  final int Function() localRevision;
  final Future<int?> Function(String owner) loadBaseRevision;
  final Future<void> Function(String owner, int revision) saveBaseRevision;
  final Future<String> Function() deviceId;
  final String clientVersion;

  Future<int> upload(String owner) async {
    final epoch = sessionEpoch();
    void requireOwner() {
      if (!CanonicalGameIntent.validOwner(owner) ||
          currentOwner() != owner ||
          sourceOwner() != owner ||
          sessionEpoch() != epoch ||
          repository.currentUserId != owner ||
          !repository.isSignedIn) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireOwner();
    var base = await loadBaseRevision(owner);
    requireOwner();
    final remote = await repository.loadCloudGameSave();
    requireOwner();
    final journal = File('${directory.path}/legacy-upload-v1-$owner.json');
    var recovered = false;
    if (await journal.exists()) {
      requireOwner();
      Map<String, dynamic> pending;
      try {
        if (await journal.length() > 4096) throw const FormatException();
        final raw = jsonDecode(await journal.readAsString());
        if (raw is! Map<String, dynamic> ||
            raw.length != 4 ||
            raw['owner'] != owner ||
            raw['base'] is! int ||
            raw['base'] < 0 ||
            raw['base'] >= 9007199254740991 ||
            raw['device'] is! String ||
            raw['hash'] is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(raw['hash'])) {
          throw const FormatException();
        }
        pending = raw;
      } on FormatException {
        throw const CanonicalGameException(
            'game_import_upload_journal_invalid');
      }
      requireOwner();
      if (remote != null &&
          remote.revision == pending['base'] + 1 &&
          remote.deviceId == pending['device'] &&
          _digest(remote.state) == pending['hash'] &&
          (base == null && pending['base'] == 0 ||
              base == pending['base'] ||
              base == remote.revision)) {
        await saveBaseRevision(owner, remote.revision);
        requireOwner();
        base = remote.revision;
        recovered = true;
      } else if ((remote?.revision ?? 0) != pending['base'] ||
          (base ?? 0) != pending['base']) {
        throw const SocialException('cloud_save_conflict');
      }
      await journal.delete();
      requireOwner();
    }
    if ((base == null && remote != null) ||
        (base != null && base != (remote?.revision ?? 0))) {
      throw const SocialException('cloud_save_conflict');
    }
    await settleLegacySources(owner);
    requireOwner();
    final device = await deviceId();
    requireOwner();
    final revision = localRevision();
    final state = GameTimeBridge.forUpload(exportState());
    final hash = _digest(state);
    if (recovered && hash == _digest(remote!.state)) return remote.revision;
    await directory.create(recursive: true);
    requireOwner();
    final temporary = File('${journal.path}.tmp');
    await temporary.writeAsString(
        jsonEncode({
          'owner': owner,
          'base': base ?? 0,
          'device': device,
          'hash': hash,
        }),
        flush: true);
    requireOwner();
    await temporary.rename(journal.path);
    requireOwner();
    if (localRevision() != revision) {
      throw const CanonicalGameException('game_import_source_changed');
    }
    final CloudGameSave saved = await repository.pushCloudGameSave(
        expectedRevision: base ?? 0,
        state: state,
        deviceId: device,
        clientVersion: clientVersion);
    requireOwner();
    if (saved.revision != (base ?? 0) + 1 ||
        saved.revision > 9007199254740991 ||
        saved.deviceId != device ||
        _digest(saved.state) != hash) {
      throw const CanonicalGameException('game_import_source_changed');
    }
    await saveBaseRevision(owner, saved.revision);
    requireOwner();
    await journal.delete();
    requireOwner();
    // Persist the acknowledged base even when another local writer escaped
    // the gate, then refuse activation so its new changes can be uploaded.
    if (localRevision() != revision) {
      throw const CanonicalGameException('game_import_source_changed');
    }
    return saved.revision;
  }

  static String _digest(Map<String, dynamic> value) {
    Object? ordered(Object? item) {
      if (item is Map<String, dynamic>) {
        return {
          for (final key in item.keys.toList()..sort()) key: ordered(item[key])
        };
      }
      if (item is List) return item.map(ordered).toList();
      return item;
    }

    return sha256.convert(utf8.encode(jsonEncode(ordered(value)))).toString();
  }
}
