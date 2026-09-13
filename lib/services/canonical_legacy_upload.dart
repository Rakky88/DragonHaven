import '../domain/game_time_bridge.dart';
import '../models/social.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_snapshot.dart';
import 'social_repository.dart';

/// Final optimistic upload while the caller has closed legacy gameplay and
/// drained its background writers. A cloud conflict never selects a winner.
/// In particular, a lost upload reply is resolved by the existing cloud
/// reconciliation flow, never by replacing a newer revision automatically.
class CanonicalLegacyUpload {
  CanonicalLegacyUpload({
    required this.repository,
    required this.currentOwner,
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
  final String? Function() currentOwner;
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
          sessionEpoch() != epoch ||
          repository.currentUserId != owner ||
          !repository.isSignedIn) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireOwner();
    await settleLegacySources(owner);
    requireOwner();
    final base = await loadBaseRevision(owner);
    requireOwner();
    final remote = await repository.loadCloudGameSave();
    requireOwner();
    if ((base == null && remote != null) ||
        (base != null && base != (remote?.revision ?? 0))) {
      throw const SocialException('cloud_save_conflict');
    }
    final device = await deviceId();
    requireOwner();
    final revision = localRevision();
    final state = GameTimeBridge.forUpload(exportState());
    final CloudGameSave saved = await repository.pushCloudGameSave(
        expectedRevision: base ?? 0,
        state: state,
        deviceId: device,
        clientVersion: clientVersion);
    requireOwner();
    if (saved.revision != (base ?? 0) + 1 ||
        saved.revision > 9007199254740991 ||
        saved.deviceId != device) {
      throw const CanonicalGameException('game_import_source_changed');
    }
    await saveBaseRevision(owner, saved.revision);
    requireOwner();
    // Persist the acknowledged base even when another local writer escaped
    // the gate, then refuse activation so its new changes can be uploaded.
    if (localRevision() != revision) {
      throw const CanonicalGameException('game_import_source_changed');
    }
    return saved.revision;
  }
}
