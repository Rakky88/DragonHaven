import 'dart:convert';
import 'dart:io';

import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'account_legacy_game_storage.dart';
import 'canonical_legacy_upload.dart';
import 'egg_altar_repository.dart';
import 'social_repository.dart';

/// Joins a known-owner save, its writers and the optimistic migration uploader.
/// The account root must remove gameplay before invoking close or upload.
class CanonicalLegacyAccountSource {
  CanonicalLegacyAccountSource({
    required this.storage,
    required this.game,
    required this.online,
    required this.altar,
    required SocialRepository repository,
    required Directory directory,
    required String? Function() currentOwner,
    required int Function() sessionEpoch,
    required Future<String> Function() deviceId,
    required String clientVersion,
    this.beforeClose,
  }) {
    if (!identical(game.legacyStorage, storage) ||
        !identical(altar.game, game)) {
      throw ArgumentError(
          'Legacy account source and writers must share storage.');
    }
    _upload = CanonicalLegacyUpload(
        repository: repository,
        directory: directory,
        currentOwner: currentOwner,
        sourceOwner: () => storage.owner,
        sessionEpoch: sessionEpoch,
        settleLegacySources: (_) async {
          await retire();
          _sealed = await game.sealLegacySave();
        },
        exportState: () =>
            Map<String, dynamic>.from(jsonDecode(_sealed!.json) as Map),
        localRevision: () => _sealed!.revision,
        loadBaseRevision: (_) => storage.cloudBaseRevision(),
        saveBaseRevision: (_, revision) =>
            storage.saveCloudBaseRevision(revision),
        deviceId: deviceId,
        clientVersion: clientVersion);
  }

  final AccountLegacyGameStorage storage;
  final HouseholdProvider game;
  final OnlineAccountProvider online;
  final EggAltarRepository altar;
  final void Function()? beforeClose;
  late final CanonicalLegacyUpload _upload;
  Future<void>? _retiring;
  Future<int>? _uploading;
  ({String json, int revision})? _sealed;
  bool _disposed = false;

  Future<void> retire() => _retiring ??= (() async {
        // Online refreshes may themselves own an Altar operation. Drain them first
        // while that operation's transport can still complete its existing request.
        await online.stopLegacyOperations();
        await game.stopAltarOperations();
        await altar.stopLegacyOperations();
        await game.retireLegacySave();
      })();

  Future<int> upload() {
    if (_disposed) return Future.error(StateError('Account source is closed.'));
    if (_uploading != null) return _uploading!;
    final operation = _upload.upload(storage.owner);
    _uploading = operation;
    return operation.whenComplete(() => _uploading = null);
  }

  Future<void> close() async {
    await retire();
    // The root normally serializes these paths, but an account change can close
    // the visible lease while a final upload still holds its request journal.
    try {
      await _uploading;
    } on Object {/* The upload caller owns the error. */}
    if (_disposed) return;
    _disposed = true;
    beforeClose?.call();
    online.dispose();
    game.dispose();
  }
}
