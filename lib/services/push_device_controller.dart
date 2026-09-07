import 'dart:async';
import 'dart:convert';

/// A snapshot of account identity and user preferences, never an FCM payload.
class PushDeviceIntent {
  PushDeviceIntent({
    required this.ownerId,
    required this.installationId,
    required this.languageCode,
    required Iterable<String> enabledKinds,
  }) : enabledKinds = List.unmodifiable(enabledKinds.toSet().toList()..sort());

  final String ownerId;
  final String installationId;
  final String languageCode;
  final List<String> enabledKinds;

  String get fingerprint =>
      jsonEncode([ownerId, installationId, languageCode, enabledKinds]);
}

abstract interface class PushTokenClient {
  Future<String?> token();
  Future<void> deleteToken();
  Future<void> setAutoInitEnabled(bool enabled);
}

abstract interface class PushDeviceBackend {
  Future<bool> register(PushDeviceIntent intent, String token);
  Future<void> unregister(PushDeviceIntent intent);
}

/// Serializes token/account/preference transitions. Responses from a previous
/// identity never make the new account appear registered. Errors only affect
/// push; the durable notification inbox and foreground polling remain usable.
class PushDeviceController {
  PushDeviceController({
    required PushTokenClient messaging,
    required PushDeviceBackend backend,
    required Future<bool> Function() hasPermission,
    required void Function(bool) availabilityChanged,
    DateTime Function()? now,
  })  : _messaging = messaging,
        _backend = backend,
        _hasPermission = hasPermission,
        _availabilityChanged = availabilityChanged,
        _now = now ?? DateTime.now;

  final PushTokenClient _messaging;
  final PushDeviceBackend _backend;
  final Future<bool> Function() _hasPermission;
  final void Function(bool) _availabilityChanged;
  final DateTime Function() _now;
  PushDeviceIntent? _desired;
  PushDeviceIntent? _registered;
  DateTime? _lastSuccess;
  Future<void>? _inFlight;
  Timer? _retry;
  int _revision = 0;
  int _retrySeconds = 30;
  bool _disposed = false;
  bool _dirty = false;

  Future<void> synchronize(PushDeviceIntent? intent, {bool force = false}) {
    if (_disposed) return Future.value();
    if (!force &&
        intent?.fingerprint == _desired?.fingerprint &&
        _lastSuccess != null &&
        _now().difference(_lastSuccess!) < const Duration(hours: 24)) {
      return _inFlight ?? Future.value();
    }
    _desired = intent;
    _revision++;
    _dirty = true;
    if (_registered?.ownerId != intent?.ownerId) {
      _availabilityChanged(false);
    }
    if (_inFlight != null) return _inFlight!;
    final run = _drain();
    _inFlight = run;
    return run.whenComplete(() {
      _inFlight = null;
      if (_dirty && !_disposed) {
        unawaited(synchronize(_desired, force: true));
      }
    });
  }

  Future<void> _drain() async {
    while (_dirty && !_disposed) {
      _dirty = false;
      final revision = _revision;
      final intent = _desired;
      try {
        final allowed = intent != null &&
            intent.enabledKinds.isNotEmpty &&
            await _hasPermission();
        if (revision != _revision || _disposed) continue;
        if (!allowed) {
          await _disable();
          if (revision == _revision) _lastSuccess = _now();
          continue;
        }
        if (_registered != null && _registered!.ownerId != intent.ownerId) {
          await _disable();
        }
        if (revision != _revision || _disposed) continue;
        await _messaging.setAutoInitEnabled(true);
        final token = await _messaging.token();
        if (revision != _revision || _disposed) continue;
        if (token == null || token.isEmpty) {
          throw StateError('push_token_missing');
        }
        final available = await _backend.register(intent, token);
        if (revision != _revision || _disposed) {
          // Remember the old registration so a subsequent logout can revoke it.
          _registered = intent;
          continue;
        }
        _registered = intent;
        _lastSuccess = _now();
        _retrySeconds = 30;
        _retry?.cancel();
        _availabilityChanged(available);
      } on Object {
        if (revision != _revision || _disposed) continue;
        _availabilityChanged(false);
        _lastSuccess = null;
        _retry?.cancel();
        _retry = Timer(Duration(seconds: _retrySeconds), () {
          if (!_disposed) unawaited(synchronize(_desired, force: true));
        });
        _retrySeconds = (_retrySeconds * 2).clamp(30, 900);
      }
    }
  }

  Future<void> _disable() async {
    _availabilityChanged(false);
    final previous = _registered;
    // Revocation is attempted while the old account is still signed in when
    // called by beforeSignOut. Token deletion also invalidates delayed pushes.
    try {
      if (previous != null) await _backend.unregister(previous);
    } on Object {
      // Expiry and server token invalidation provide the offline fallback.
    }
    await _messaging.setAutoInitEnabled(false);
    await _messaging.deleteToken();
    _registered = null;
  }

  Future<void> unregisterBeforeSignOut() => synchronize(null, force: true);

  void dispose() {
    _disposed = true;
    _revision++;
    _retry?.cancel();
  }
}
