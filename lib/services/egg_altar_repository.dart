import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/egg_altar.dart';
import '../models/social.dart';
import '../providers/household_provider.dart';
import 'social_repository.dart';

class EggAltarRepository {
  EggAltarRepository(this.client, this.social, this.game) {
    _owner = social.currentUserId;
    _accounts = client.auth.onAuthStateChange.listen((event) {
      final owner = social.currentUserId;
      if (owner != _owner ||
          event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.signedOut) {
        _owner = owner;
        _epoch++;
      }
    }, onError: (Object _, StackTrace __) {
      _epoch++;
    });
  }
  final SupabaseClient client;
  final SocialRepository social;
  final HouseholdProvider game;
  late final StreamSubscription<AuthState> _accounts;
  String? _owner;
  int _epoch = 0;
  bool _stopped = false;
  Future<void>? _stop;
  final _settling = <Future<void>>{};
  int get sessionEpoch => _epoch;

  /// The root first drains game.stopAltarOperations(), so an admitted command
  /// can finish applying its receipt. Then retire refreshes and this transport.
  Future<void> stopLegacyOperations() {
    if (_stop != null) return _stop!;
    _stopped = true;
    return _stop = (() async {
      // Keep observing session changes until every admitted response is fenced.
      // Cancelling first would miss an A -> B -> A switch while draining.
      await Future.wait<void>([..._settling]);
      await _accounts.cancel();
    })();
  }

  Future<T> _operation<T>(Future<T> Function(void Function()) body) {
    if (_stopped) {
      return Future.error(const EggAltarException('altar_unavailable'));
    }
    final owner = social.currentUserId;
    final epoch = _epoch;
    void requireAccount() {
      if (owner == null ||
          !social.isSignedIn ||
          social.currentUserId != owner ||
          epoch != _epoch) {
        throw const EggAltarException('altar_unavailable');
      }
    }

    final settled = Completer<void>();
    _settling.add(settled.future);
    return Future<T>.sync(() {
      requireAccount();
      return body(requireAccount);
    }).whenComplete(() {
      _settling.remove(settled.future);
      settled.complete();
    });
  }

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
          String id, String action, Map<String, dynamic> payload) =>
      _operation((requireAccount) async {
        await social.ensureAccount();
        requireAccount();
        await social
            .synchronizeTradeInventory(OnlineInventorySnapshot.fromGame(game));
        requireAccount();
        final result = await _rpc('egg_altar_command', {
          'p_operation_id': id,
          'p_action': action,
          'p_payload': payload,
        });
        requireAccount();
        return result;
      });

  Future<void> refresh() async {
    if (!social.isSignedIn || game.altarBusy) return;
    await _operation<void>((requireAccount) async {
      if (game.pendingAltarOperation != null) {
        await game.retryPendingAltarOperation();
        requireAccount();
      }
      final result = await _rpc('get_egg_altar_state');
      requireAccount();
      await game.applyOnlineAltarState(result);
    });
  }

  Future<Map<String, dynamic>> beacon(String conclaveId) =>
      _operation((requireAccount) async {
        final result = await _rpc(
            'get_conclave_weave_beacon', {'p_conclave_id': conclaveId});
        requireAccount();
        return result;
      });
}
