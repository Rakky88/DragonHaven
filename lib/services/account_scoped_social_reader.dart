import 'dart:async';
import 'package:flutter/foundation.dart';
import 'canonical_game_connection.dart';
import 'canonical_game_snapshot.dart';

/// Account-epoch fencing also rejects an old reply after sign-out/sign-in to
/// the same keeper. Failed refreshes retain no actionable stale offer.
class AccountScopedSocialReader<T> extends ChangeNotifier {
  AccountScopedSocialReader({required this.connection, required this.load}) {
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _changes = connection.accountChanges.listen((_) => _reset(),
        onError: (Object _, StackTrace __) => _reset());
  }
  final CanonicalGameConnection connection;
  final Future<T> Function(String owner) load;
  late final StreamSubscription<int> _changes;
  String? _owner;
  int _epoch = 0;
  bool _disposed = false;
  Future<void>? _loading;
  T? _value;
  String? _error;
  bool get _same =>
      !_disposed &&
      _owner == connection.currentOwner &&
      _epoch == connection.sessionEpoch;
  bool get loading => _same && _loading != null;
  T? get value => _same ? _value : null;
  String? get error => _same ? _error : null;
  void _reset() {
    if (_disposed) return;
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _loading = null;
    _value = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() {
    if (!_same) _reset();
    if (_disposed || _owner == null) return Future.value();
    if (_loading != null) return _loading!;
    final owner = _owner!;
    final epoch = _epoch;
    final done = Completer<void>();
    _loading = done.future;
    _error = null;
    notifyListeners();
    unawaited(() async {
      bool stillCurrent() => _same && _owner == owner && _epoch == epoch;
      try {
        final loaded = await load(owner);
        if (!stillCurrent()) return;
        _value = loaded;
      } on Object catch (error) {
        if (!stillCurrent()) return;
        _value = null;
        _error = error is CanonicalGameException
            ? error.code
            : 'game_connection_failed';
      } finally {
        if (stillCurrent()) {
          _loading = null;
          notifyListeners();
        }
        done.complete();
      }
    }());
    return done.future;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_changes.cancel());
    super.dispose();
  }
}
