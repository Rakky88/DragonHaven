import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_state_envelope.dart';
import '../models/social.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_snapshot.dart';
import 'legacy_game_storage.dart';
import 'social_repository.dart';
import 'storage_service.dart';

enum AccountSaveChoice { local, cloud }

/// An immutable comparison, tied to the authenticated session and exact local
/// bytes that were shown. Re-reading either source invalidates a stale choice.
class AccountSaveReview {
  AccountSaveReview._(
      this.owner,
      this.epoch,
      this._accountRaw,
      this._deviceRaw,
      this._deviceOwner,
      this._localJson,
      this._cloudJson,
      this.cloudRevision,
      this.cloudUpdatedAt,
      this.needsChoice);
  final String owner;
  final int epoch;
  final String? _accountRaw, _deviceRaw, _deviceOwner, _localJson, _cloudJson;
  final int cloudRevision;
  final DateTime? cloudUpdatedAt;
  final bool needsChoice;
  Map<String, dynamic>? get local => _localJson == null
      ? null
      : jsonDecode(_localJson) as Map<String, dynamic>;
  Map<String, dynamic>? get cloud => _cloudJson == null
      ? null
      : jsonDecode(_cloudJson) as Map<String, dynamic>;
  bool get unassignedLocal => _accountRaw == null && _localJson != null;

  /// A fresh game may be proposed only when neither source exists. The caller
  /// must still show the explicit start action and use chooseSource afterward.
  AccountSaveReview withFreshState(Map<String, dynamic> state) {
    if (_localJson != null ||
        _cloudJson != null ||
        _accountRaw != null ||
        state['pet'] is! Map) {
      throw const CanonicalGameException('game_legacy_source_exists');
    }
    return AccountSaveReview._(owner, epoch, _accountRaw, _deviceRaw,
        _deviceOwner, jsonEncode(state), null, 0, null, true);
  }

  bool get canChooseCloud =>
      cloud != null && local?['pendingAltarOperation'] == null;
}

/// Owner-scoped storage. Only an authenticated cloud read can establish a new
/// source here; signing in does not assign ownership of the device-global save.
class AccountLegacyGameStorage implements LegacyGameStorage {
  AccountLegacyGameStorage._(this.owner, this._prefs);
  final String owner;
  final SharedPreferences _prefs;
  Future<void> _queue = Future.value();
  Map<String, dynamic>? _original;
  String get _key => 'dragon_haven_account_legacy_v1_$owner';
  @override
  bool get allowsFreshState => false;
  static const deviceSourceOwnerKey = 'dragon_haven_device_source_owner_v1';

  static void _requireSession(SocialRepository repository, String owner,
      String? Function() currentOwner, int Function() sessionEpoch, int epoch) {
    if (!CanonicalGameIntent.validOwner(owner) ||
        currentOwner() != owner ||
        sessionEpoch() != epoch ||
        !repository.isSignedIn ||
        repository.currentUserId != owner) {
      throw const CanonicalGameException('game_account_changed');
    }
  }

  static Future<AccountSaveReview> reviewSources({
    required SocialRepository repository,
    required String owner,
    required String? Function() currentOwner,
    required int Function() sessionEpoch,
  }) async {
    final epoch = sessionEpoch();
    void check() =>
        _requireSession(repository, owner, currentOwner, sessionEpoch, epoch);
    check();
    final store = await open(owner);
    check();
    final remote = await repository.loadCloudGameSave();
    check();
    final prefs = await SharedPreferences.getInstance();
    check();
    final scoped = store == null ? null : prefs.getString(store._key);
    final device = prefs.getString(StorageService.currentKey);
    final deviceOwner = prefs.getString(deviceSourceOwnerKey);
    final local = scoped != null
        ? store!._decode(scoped)!['state']
        : (deviceOwner == null || deviceOwner == owner) && device != null
            ? jsonDecode(device)
            : null;
    if (local != null &&
        (local is! Map<String, dynamic> || local['pet'] is! Map)) {
      throw const CanonicalGameException('game_legacy_source_invalid');
    }
    return AccountSaveReview._(
        owner,
        epoch,
        scoped,
        device,
        deviceOwner,
        local == null ? null : jsonEncode(local),
        remote == null ? null : jsonEncode(remote.state),
        remote?.revision ?? 0,
        remote?.updatedAt,
        scoped == null ||
            store!._decode(scoped)!['cloudBaseRevision'] !=
                (remote?.revision ?? 0) ||
            (prefs.getBool('${StorageService.recoveryReviewPrefix}$owner') ??
                false));
  }

  /// Called only after an explicit source choice, while all gameplay writers
  /// are closed. This changes local storage only; the next cloud write still
  /// uses optimistic revision checking. Both compared copies are preserved.
  static Future<AccountLegacyGameStorage> chooseSource({
    required AccountSaveReview review,
    required AccountSaveChoice choice,
    required SocialRepository repository,
    required String? Function() currentOwner,
    required int Function() sessionEpoch,
  }) async {
    void check() => _requireSession(
        repository, review.owner, currentOwner, sessionEpoch, review.epoch);
    check();
    if (choice == AccountSaveChoice.cloud && !review.canChooseCloud) {
      throw const CanonicalGameException('game_legacy_source_invalid');
    }
    final selected =
        choice == AccountSaveChoice.cloud ? review.cloud : review.local;
    if (selected == null) {
      throw const CanonicalGameException('game_legacy_source_missing');
    }
    final CloudGameSave? remote = await repository.loadCloudGameSave();
    check();
    if ((remote?.revision ?? 0) != review.cloudRevision ||
        (remote == null ? null : jsonEncode(remote.state)) !=
            review._cloudJson) {
      throw const SocialException('cloud_save_conflict');
    }
    final prefs = await SharedPreferences.getInstance();
    final store = AccountLegacyGameStorage._(review.owner, prefs);
    void checkLocal() {
      check();
      if (prefs.getString(store._key) != review._accountRaw ||
          prefs.getString(StorageService.currentKey) != review._deviceRaw ||
          prefs.getString(deviceSourceOwnerKey) != review._deviceOwner) {
        throw const CanonicalGameException('game_import_source_changed');
      }
    }

    checkLocal();
    // Keep the first comparison independently from rolling autosave backups.
    final checkpoint = '${store._key}_source_review';
    if (!prefs.containsKey(checkpoint)) {
      await store._write(
          checkpoint,
          jsonEncode({
            'owner': review.owner,
            'local': review.local,
            'cloud': review.cloud,
            'cloudRevision': review.cloudRevision,
          }));
    }
    checkLocal();
    if (review.local != null) {
      await StorageService.preserveBeforeCloudRestore(review.local!,
          ownerId: review.owner);
    }
    checkLocal();
    if (review._accountRaw != null) {
      await store._write('${store._key}_backup', review._accountRaw);
    }
    checkLocal();
    if (choice == AccountSaveChoice.local &&
        review.unassignedLocal &&
        review._deviceRaw != null &&
        (review._deviceOwner == null || review._deviceOwner == review.owner)) {
      // Mark before adoption. A failed write can be retried by this owner, but
      // a different sign-in cannot adopt the same legacy source afterward.
      await store._write(deviceSourceOwnerKey, review.owner);
    }
    check();
    final record = jsonEncode({
      'version': 1,
      'owner': review.owner,
      'cloudBaseRevision': review.cloudRevision,
      'state': selected
    });
    await store._write(store._key, record);
    check();
    store._original = selected;
    await prefs.remove('${StorageService.recoveryReviewPrefix}${review.owner}');
    check();
    return store;
  }

  static Future<AccountLegacyGameStorage?> open(String owner) async {
    if (!CanonicalGameIntent.validOwner(owner)) {
      throw const CanonicalGameException('game_account_changed');
    }
    final store = AccountLegacyGameStorage._(
        owner, await SharedPreferences.getInstance());
    if (!store._prefs.containsKey(store._key) &&
        !store._prefs.containsKey('${store._key}_backup')) {
      return null;
    }
    // Establish ownership from the persisted envelope before exposing a writer.
    await store.load();
    return store;
  }

  /// The root calls this only after choosing this account's cloud source. It
  /// leaves any unassigned device save untouched for separate reconciliation.
  static Future<AccountLegacyGameStorage> importCloud({
    required SocialRepository repository,
    required String owner,
    required String? Function() currentOwner,
    required int Function() sessionEpoch,
  }) async {
    final epoch = sessionEpoch();
    void requireOwner() {
      if (!CanonicalGameIntent.validOwner(owner) ||
          currentOwner() != owner ||
          sessionEpoch() != epoch ||
          !repository.isSignedIn ||
          repository.currentUserId != owner) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireOwner();
    final remote = await repository.loadCloudGameSave();
    requireOwner();
    if (remote == null) {
      throw const CanonicalGameException('game_legacy_source_missing');
    }
    final store = AccountLegacyGameStorage._(
        owner, await SharedPreferences.getInstance());
    requireOwner();
    if (store._prefs.containsKey(store._key) ||
        store._prefs.containsKey('${store._key}_backup')) {
      throw const CanonicalGameException('game_legacy_source_exists');
    }
    final record = jsonEncode({
      'version': 1,
      'owner': owner,
      'cloudBaseRevision': remote.revision,
      'state': remote.state,
    });
    await store._write(store._key, record);
    requireOwner();
    store._original = store._decode(record)!['state'] as Map<String, dynamic>;
    return store;
  }

  Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> ||
          value['version'] != 1 ||
          value['owner'] != owner ||
          value['state'] is! Map<String, dynamic> ||
          value['cloudBaseRevision'] is! int ||
          value['cloudBaseRevision'] < 0 ||
          value['cloudBaseRevision'] > 9007199254740991) {
        return null;
      }
      return value;
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    if (!await _prefs.setString(key, value)) {
      throw StateError('Account save could not be persisted.');
    }
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    await _queue;
    var record = _decode(_prefs.getString(_key));
    if (record == null) {
      await preserveCurrentForRecovery();
      final backup = _prefs.getString('${_key}_backup');
      record = _decode(backup);
      if (record == null) {
        throw const CanonicalGameException('game_legacy_source_invalid');
      }
      await _write(_key, backup!);
    }
    _original = Map<String, dynamic>.from(record['state'] as Map);
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(_original)) as Map);
  }

  Future<int> cloudBaseRevision() async {
    await _queue;
    final record = _decode(_prefs.getString(_key));
    if (record == null) {
      throw const CanonicalGameException('game_legacy_source_invalid');
    }
    return record['cloudBaseRevision'] as int;
  }

  Future<void> saveCloudBaseRevision(int revision) {
    if (revision < 1 || revision > 9007199254740991) {
      return Future.error(ArgumentError('Invalid cloud base revision.'));
    }
    final operation = _queue.then((_) async {
      final record = _decode(_prefs.getString(_key));
      if (record == null || revision < record['cloudBaseRevision']) {
        throw const CanonicalGameException('game_legacy_source_invalid');
      }
      await _write(
          _key, jsonEncode({...record, 'cloudBaseRevision': revision}));
    });
    _queue = operation;
    return operation;
  }

  @override
  Map<String, dynamic> prepareSave(Map<String, dynamic> state) =>
      _original == null
          ? state
          : GameStateEnvelope.preserveUnknownMetadata(_original!, state);

  @override
  Future<void> save(Map<String, dynamic> state) {
    // Freeze at admission; later UI mutations cannot change queued bytes.
    final encoded = jsonEncode(prepareSave(state));
    final operation = _queue.then((_) async {
      final previous = _prefs.getString(_key);
      final record = _decode(previous);
      if (record == null) {
        throw const CanonicalGameException('game_legacy_source_invalid');
      }
      await _write('${_key}_backup', previous!);
      await _write(_key, jsonEncode({...record, 'state': jsonDecode(encoded)}));
    });
    // Retain failures as a barrier: recovery must reopen the saved source.
    _queue = operation;
    return operation;
  }

  @override
  Future<Map<String, dynamic>?> loadBackup() async {
    await _queue;
    return _decode(_prefs.getString('${_key}_backup'))?['state']
        as Map<String, dynamic>?;
  }

  @override
  Future<void> preserveCurrentForRecovery() async {
    final raw = _prefs.getString(_key);
    if (raw != null) await _write('${_key}_recovery', raw);
  }

  @override
  Future<bool> promoteBackup() async {
    await _queue;
    final raw = _prefs.getString('${_key}_backup');
    if (_decode(raw) == null) return false;
    await preserveCurrentForRecovery();
    await _write(_key, raw!);
    _original = Map<String, dynamic>.from(_decode(raw)!['state'] as Map);
    return true;
  }
}
