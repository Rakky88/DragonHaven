import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/egg_altar.dart';
import '../models/social.dart';
import '../providers/household_provider.dart';
import 'social_repository.dart';

class EggAltarRepository {
  EggAltarRepository(this.client, this.social, this.game);
  final SupabaseClient client;
  final SocialRepository social;
  final HouseholdProvider game;

  Future<Map<String, dynamic>> _rpc(String name,
      [Map<String, dynamic> params = const {}]) async {
    try {
      return Map<String, dynamic>.from(
          await client.rpc(name, params: params) as Map);
    } on PostgrestException catch (error) {
      const known = {
        'egg_not_found',
        'egg_not_owned',
        'egg_in_nest',
        'egg_tagged',
        'egg_reserved',
        'special_egg',
        'sinister_confirmation_required',
        'insufficient_materials',
        'already_known',
        'invalid_name',
        'relic_not_owned',
        'conclave_member_not_found',
        'invalid_amount',
        'beacon_amount_exceeds_goal'
      };
      throw EggAltarException(
          known.contains(error.message) ? error.message : 'altar_unavailable');
    } on Object {
      throw const EggAltarException('altar_unavailable');
    }
  }

  Future<Map<String, dynamic>> command(
      String id, String action, Map<String, dynamic> payload) async {
    await social.ensureAccount();
    await social
        .synchronizeTradeInventory(OnlineInventorySnapshot.fromGame(game));
    return _rpc('egg_altar_command', {
      'p_operation_id': id,
      'p_action': action,
      'p_payload': payload,
    });
  }

  Future<void> refresh() async {
    if (!social.isSignedIn || game.altarBusy) return;
    if (game.pendingAltarOperation != null) {
      await game.retryPendingAltarOperation();
    }
    await game.applyOnlineAltarState(await _rpc('get_egg_altar_state'));
  }

  Future<Map<String, dynamic>> beacon(String conclaveId) =>
      _rpc('get_conclave_weave_beacon', {'p_conclave_id': conclaveId});
}
