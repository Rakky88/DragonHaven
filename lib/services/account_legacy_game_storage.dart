import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_state_envelope.dart';
import 'canonical_game_intent.dart';
import 'canonical_game_snapshot.dart';
import 'legacy_game_storage.dart';
import 'social_repository.dart';

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
          value['cloudBaseRevision'] < 1) {
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
