import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'notification_service.dart';
import 'push_device_controller.dart';

class FirebasePushTokenClient implements PushTokenClient {
  @override
  Future<String?> token() =>
      FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 8));
  @override
  Future<void> deleteToken() => FirebaseMessaging.instance
      .deleteToken()
      .timeout(const Duration(seconds: 8));
  @override
  Future<void> setAutoInitEnabled(bool enabled) => FirebaseMessaging.instance
      .setAutoInitEnabled(enabled)
      .timeout(const Duration(seconds: 8));
}

class SupabasePushDeviceBackend implements PushDeviceBackend {
  SupabasePushDeviceBackend(this.client);
  final SupabaseClient client;

  @override
  Future<bool> register(PushDeviceIntent intent, String token) async {
    final result = await client.rpc('register_my_push_device', params: {
      'p_expected_user_id': intent.ownerId,
      'p_installation_id': intent.installationId,
      'p_token': token,
      'p_language_code': intent.languageCode,
      'p_enabled_kinds': intent.enabledKinds,
    }).timeout(const Duration(seconds: 10));
    if (result is! Map ||
        result['registered'] != true ||
        result['delivery_enabled'] is! bool) {
      throw StateError('push_registration_invalid');
    }
    return result['delivery_enabled'] as bool;
  }

  @override
  Future<void> unregister(PushDeviceIntent intent) async {
    if (client.auth.currentUser?.id != intent.ownerId) return;
    await client.rpc('unregister_my_push_device', params: {
      'p_installation_id': intent.installationId,
    }).timeout(const Duration(seconds: 10));
  }
}

/// App-lifetime coordinator. FCM carries generic text and a routing kind only;
/// private message bodies and player names are fetched through authenticated RPCs.
class FirebasePushCoordinator {
  FirebasePushCoordinator(this.game, this.online, SupabaseClient client) {
    _controller = PushDeviceController(
      messaging: FirebasePushTokenClient(),
      backend: SupabasePushDeviceBackend(client),
      hasPermission: () async =>
          await HavenNotifications.platformPermissionStatus() ==
          HavenNotificationPermissionStatus.granted,
      availabilityChanged: online.setPushAvailable,
    );
    game.addListener(_schedule);
    online.addListener(_schedule);
    _lifecycle = AppLifecycleListener(onResume: () => _schedule(force: true));
    _subscriptions.add(FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => _schedule(force: true),
      onError: (Object _) => online.setPushAvailable(false),
    ));
    _subscriptions.add(FirebaseMessaging.onMessage.listen(
      (_) => unawaited(online.pollSocialNotifications()),
    ));
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
    unawaited(_initial());
    _schedule();
  }

  final HouseholdProvider game;
  final OnlineAccountProvider online;
  late final PushDeviceController _controller;
  late final AppLifecycleListener _lifecycle;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _debounce;
  bool _disposed = false;
  bool _force = false;
  bool _signingOut = false;

  static const kindCategories = {
    'friend_request': HavenNotificationCategory.friendRequests,
    'friend_accepted': HavenNotificationCategory.friendAcceptances,
    'friend_message': HavenNotificationCategory.friendMessages,
    'trade_request': HavenNotificationCategory.tradeRequests,
    'trade_return': HavenNotificationCategory.tradeReturns,
    'trade_completed': HavenNotificationCategory.tradeCompletions,
    'seasonal_pair_invite': HavenNotificationCategory.specialEvents,
    'seasonal_pair_accepted': HavenNotificationCategory.specialEvents,
    'seasonal_pair_ready': HavenNotificationCategory.specialEvents,
  };

  Future<void> _initial() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null && !_disposed) _open(message);
    } on Object {
      // The durable inbox is still refreshed at normal startup.
    }
  }

  void _open(RemoteMessage message) {
    final kind = message.data['kind'];
    if (kind is! String || !kindCategories.containsKey(kind)) return;
    HavenNotifications.openRemoteDestination(kind.startsWith('seasonal_pair_')
        ? 'special_adventure_available'
        : kind.startsWith('trade_')
            ? 'trade'
            : kind);
    unawaited(online.pollSocialNotifications());
  }

  void _schedule({bool force = false}) {
    if (_disposed || _signingOut) return;
    _force = _force || force;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_synchronize());
    });
  }

  Future<void> _synchronize() async {
    final owner = online.isSignedIn && online.profile != null
        ? online.currentUserId
        : null;
    final force = _force;
    _force = false;
    try {
      if (owner == null) {
        await _controller.synchronize(null, force: force);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final key = 'push.installation.$owner';
      var installation = prefs.getString(key);
      if (installation == null) {
        installation = const Uuid().v4();
        if (!await prefs.setString(key, installation)) return;
      }
      if (_disposed || _signingOut || online.currentUserId != owner) return;
      await _controller.synchronize(
        PushDeviceIntent(
          ownerId: owner,
          installationId: installation,
          languageCode: game.languageCode,
          enabledKinds: kindCategories.entries
              .where((entry) => game.notificationEnabled(entry.value))
              .map((entry) => entry.key),
        ),
        force: force,
      );
    } on Object {
      online.setPushAvailable(false);
    }
  }

  Future<void> unregisterBeforeSignOut() async {
    _signingOut = true;
    _debounce?.cancel();
    await _controller.unregisterBeforeSignOut();
  }

  void afterSignOutAttempt() {
    _signingOut = false;
    _schedule(force: true);
  }

  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    _debounce?.cancel();
    game.removeListener(_schedule);
    online.removeListener(_schedule);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _controller.dispose();
  }
}
