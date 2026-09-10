import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/social.dart';
import 'canonical_game_connection.dart';
import 'canonical_game_snapshot.dart';

abstract interface class CanonicalGroupsSource {
  Future<GroupAdventureStatus> status(String owner);
  Future<List<GroupAdventureLobby>> lobbies(String owner);
}

/// Narrow social reads only. Membership mutations go through the revisioned
/// game command lane; no client dragon snapshot is submitted to a social RPC.
class SupabaseCanonicalGroupsSource implements CanonicalGroupsSource {
  SupabaseCanonicalGroupsSource(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> _read(String owner, String rpc) async {
    void requireOwner() {
      if (client.auth.currentUser?.id != owner) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    requireOwner();
    final data = await client.rpc(rpc);
    requireOwner();
    if (data is! List || data.any((row) => row is! Map)) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  @override
  Future<GroupAdventureStatus> status(String owner) async {
    final rows = await _read(owner, 'get_current_group_adventure_status');
    if (rows.length != 1) {
      throw const CanonicalGameException('game_action_unavailable');
    }
    return GroupAdventureStatus.fromJson(rows.single);
  }

  @override
  Future<List<GroupAdventureLobby>> lobbies(String owner) async =>
      (await _read(owner, 'list_group_adventures'))
          .map(GroupAdventureLobby.fromJson)
          .toList(growable: false);
}

/// Account-epoch fencing also rejects an old reply after sign-out/sign-in to
/// the same keeper. Failed refreshes retain no actionable stale offer.
class CanonicalGroups extends ChangeNotifier {
  CanonicalGroups({required this.connection, required this.source}) {
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _changes = connection.accountChanges.listen((_) => _reset(),
        onError: (Object _, StackTrace __) => _reset());
  }
  final CanonicalGameConnection connection;
  final CanonicalGroupsSource source;
  late final StreamSubscription<int> _changes;
  String? _owner;
  int _epoch = 0;
  bool _disposed = false;
  Future<void>? _loading;
  GroupAdventureStatus? _status;
  List<GroupAdventureLobby> _lobbies = const [];
  String? _error;
  bool get _same =>
      !_disposed &&
      _owner == connection.currentOwner &&
      _epoch == connection.sessionEpoch;
  bool get loading => _same && _loading != null;
  GroupAdventureStatus? get status => _same ? _status : null;
  List<GroupAdventureLobby> get lobbies => _same ? _lobbies : const [];
  String? get error => _same ? _error : null;
  void _reset() {
    if (_disposed) return;
    _owner = connection.currentOwner;
    _epoch = connection.sessionEpoch;
    _loading = null;
    _status = null;
    _lobbies = const [];
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
        final values = await Future.wait<Object>([
          source.status(owner),
          source.lobbies(owner),
        ]);
        if (!stillCurrent()) return;
        _status = values[0] as GroupAdventureStatus;
        _lobbies = List.unmodifiable(values[1] as List<GroupAdventureLobby>);
      } on Object catch (error) {
        if (!stillCurrent()) return;
        _status = null;
        _lobbies = const [];
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
