import 'package:supabase_flutter/supabase_flutter.dart';
import 'canonical_game_snapshot.dart';

abstract interface class CanonicalBeaconSource {
  Future<int> load(String owner, String conclaveId);
}

class SupabaseCanonicalBeaconSource implements CanonicalBeaconSource {
  SupabaseCanonicalBeaconSource(this.client);
  final SupabaseClient client;
  @override
  Future<int> load(String owner, String conclaveId) async {
    void checkOwner() {
      if (client.auth.currentUser?.id != owner) {
        throw const CanonicalGameException('game_account_changed');
      }
    }

    checkOwner();
    final data = await client.rpc('get_conclave_weave_beacon',
        params: {'p_conclave_id': conclaveId});
    checkOwner();
    if (data is! Map ||
        data.length != 2 ||
        data['goal'] != 5000 ||
        data['fragments'] is! int ||
        data['fragments'] < 0 ||
        data['fragments'] > 5000) {
      throw const CanonicalGameException('game_snapshot_invalid');
    }
    return data['fragments'] as int;
  }
}
