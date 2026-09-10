import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/social.dart';
import 'account_scoped_social_reader.dart';
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

typedef CanonicalGroupList = ({
  GroupAdventureStatus status,
  List<GroupAdventureLobby> lobbies
});

class CanonicalGroups extends AccountScopedSocialReader<CanonicalGroupList> {
  CanonicalGroups(
      {required super.connection, required CanonicalGroupsSource source})
      : super(load: (owner) async {
          final values = await Future.wait<Object>(
              [source.status(owner), source.lobbies(owner)]);
          return (
            status: values[0] as GroupAdventureStatus,
            lobbies: List<GroupAdventureLobby>.unmodifiable(
                values[1] as List<GroupAdventureLobby>)
          );
        });
  GroupAdventureStatus? get status => value?.status;
  List<GroupAdventureLobby> get lobbies => value?.lobbies ?? const [];
}
