import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'canonical_game_intent.dart';
import 'canonical_game_snapshot.dart';

class CanonicalAccountStatus {
  const CanonicalAccountStatus._(this.ownerId, this.phase,
      this.migrationEnabled, this.sourceRevision, this.serverRevision);
  final String ownerId;
  final String phase;
  final bool migrationEnabled;
  final int? sourceRevision;
  final int? serverRevision;

  factory CanonicalAccountStatus.parse(Object? raw, String owner) {
    bool revision(Object? value) =>
        value is int && value > 0 && value <= 9007199254740991;
    if (raw is! Map<String, dynamic> ||
        raw.length != 5 ||
        raw['owner_id'] != owner ||
        !CanonicalGameIntent.validOwner(owner) ||
        !const {'legacy', 'captured', 'active'}.contains(raw['phase']) ||
        raw['migration_enabled'] is! bool ||
        (raw['source_revision'] != null && !revision(raw['source_revision'])) ||
        (raw['server_revision'] != null && !revision(raw['server_revision'])) ||
        (raw['phase'] == 'active' && !revision(raw['server_revision'])) ||
        (raw['phase'] == 'captured' &&
            (!revision(raw['source_revision']) ||
                raw['server_revision'] != null)) ||
        (raw['phase'] == 'legacy' &&
            (raw['source_revision'] != null ||
                raw['server_revision'] != null))) {
      throw const CanonicalGameException('game_migration_status_invalid');
    }
    return CanonicalAccountStatus._(
        owner,
        raw['phase'] as String,
        raw['migration_enabled'] as bool,
        raw['source_revision'] as int?,
        raw['server_revision'] as int?);
  }
}

enum CanonicalHandoffPhase {
  checking,
  legacy,
  preparing,
  transferring,
  server,
  failed
}

/// Orchestrates the last legacy upload and the authority transition. It never
/// applies a reward, edits a saved inventory or infers authority while offline.
/// Callers keep gameplay closed until either legacy or server is confirmed.
class CanonicalAccountHandoff extends ChangeNotifier {
  CanonicalAccountHandoff(
      {required this.directory,
      required this.currentOwner,
      required this.sessionEpoch,
      required this.readStatus,
      required this.prepareAndUploadLegacy,
      required this.activate,
      String Function()? newRequestId})
      : newRequestId = newRequestId ?? const Uuid().v4;
  final Directory directory;
  final String? Function() currentOwner;
  final int Function() sessionEpoch;
  final Future<CanonicalAccountStatus> Function(String owner) readStatus;
  final Future<int> Function(String owner) prepareAndUploadLegacy;
  final Future<int> Function(String owner, String requestId, int sourceRevision)
      activate;
  final String Function() newRequestId;
  CanonicalHandoffPhase _phase = CanonicalHandoffPhase.checking;
  String? _owner;
  int? _epoch;
  String? _error;
  int? _minimumServerRevision;
  bool _disposed = false;
  Future<void>? _pending;

  bool get _current =>
      !_disposed && _owner == currentOwner() && _epoch == sessionEpoch();
  CanonicalHandoffPhase get phase =>
      _current ? _phase : CanonicalHandoffPhase.checking;
  String? get errorCode => _current ? _error : null;
  int? get minimumServerRevision => _current ? _minimumServerRevision : null;
  bool get busy => _pending != null;

  File _intent(String owner) =>
      File('${directory.path}/migration-v1-$owner.json');

  Future<void> synchronize() {
    if (_pending != null) return _pending!;
    final owner = currentOwner();
    final epoch = sessionEpoch();
    if (_disposed || owner == null || !CanonicalGameIntent.validOwner(owner)) {
      return Future.error(const CanonicalGameException('game_login_required'));
    }
    _owner = owner;
    _epoch = epoch;
    _error = null;
    _minimumServerRevision = null;
    _phase = CanonicalHandoffPhase.checking;
    final completion = Completer<void>();
    _pending = completion.future;
    notifyListeners();
    void requireSession() {
      if (_disposed || currentOwner() != owner || sessionEpoch() != epoch) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    void setPhase(CanonicalHandoffPhase value) {
      requireSession();
      _phase = value;
      notifyListeners();
    }

    unawaited(() async {
      try {
        final status = await readStatus(owner);
        requireSession();
        if (status.ownerId != owner) {
          throw const CanonicalGameException('game_account_changed');
        }
        final file = _intent(owner);
        if (status.phase == 'active') {
          _minimumServerRevision = status.serverRevision;
          if (await file.exists()) await file.delete();
          setPhase(CanonicalHandoffPhase.server);
        } else if (!status.migrationEnabled) {
          setPhase(CanonicalHandoffPhase.legacy);
        } else {
          String? requestId;
          int? sourceRevision;
          // A damaged local journal cannot justify overwriting an active game:
          // its fresh status was checked first, and SQL fences the final upload.
          if (await file.exists()) {
            requireSession();
            try {
              if (await file.length() > 4096) throw const FormatException();
              final saved = jsonDecode(await file.readAsString());
              if (saved is! Map<String, dynamic> ||
                  saved.length != 3 ||
                  saved['owner'] != owner ||
                  saved['requestId'] is! String ||
                  !CanonicalGameIntent.validOwner(saved['requestId']) ||
                  saved['sourceRevision'] is! int ||
                  saved['sourceRevision'] < 1 ||
                  saved['sourceRevision'] > 9007199254740991) {
                throw const FormatException();
              }
              requestId = saved['requestId'] as String;
              sourceRevision = saved['sourceRevision'] as int;
            } on FormatException {
              requestId = null;
              sourceRevision = null;
            }
          }
          requireSession();
          if (requestId == null || sourceRevision == null) {
            setPhase(CanonicalHandoffPhase.preparing);
            sourceRevision = await prepareAndUploadLegacy(owner);
            requireSession();
            if (sourceRevision < 1 || sourceRevision > 9007199254740991) {
              throw const CanonicalGameException('game_import_source_changed');
            }
            requestId = newRequestId();
            if (!CanonicalGameIntent.validOwner(requestId)) {
              throw const CanonicalGameException('game_request_invalid');
            }
            await directory.create(recursive: true);
            requireSession();
            final temporary = File('${file.path}.tmp');
            await temporary.writeAsString(
                jsonEncode({
                  'owner': owner,
                  'requestId': requestId,
                  'sourceRevision': sourceRevision
                }),
                flush: true);
            requireSession();
            await temporary.rename(file.path);
          }
          setPhase(CanonicalHandoffPhase.transferring);
          final revision = await activate(owner, requestId, sourceRevision);
          requireSession();
          if (revision < 1 || revision > 9007199254740991) {
            throw const CanonicalGameException('game_migration_unavailable');
          }
          _minimumServerRevision = revision;
          if (await file.exists()) await file.delete();
          setPhase(CanonicalHandoffPhase.server);
        }
        completion.complete();
      } on Object catch (error, stack) {
        if (!_disposed && currentOwner() == owner && sessionEpoch() == epoch) {
          _phase = CanonicalHandoffPhase.failed;
          _error = error is CanonicalGameException
              ? error.code
              : 'game_migration_unavailable';
          // These SQL refusals prove activation did not occur for this request.
          // Next try must settle/re-upload current legacy progress, not loop on
          // the obsolete capture. Network failures retain the original intent.
          if (const {
            'game_import_source_changed',
            'game_import_altar_changed',
            'game_migration_social_changed',
            'game_idempotency_conflict',
            'game_migration_trade_pending'
          }.contains(_error)) {
            try {
              final file = _intent(owner);
              if (await file.exists()) await file.delete();
            } on FileSystemException {
              /* Keep the retry fenced if cleanup fails. */
            }
          }
        }
        completion.completeError(error, stack);
      } finally {
        _pending = null;
        if (!_disposed) notifyListeners();
      }
    }());
    return completion.future;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
