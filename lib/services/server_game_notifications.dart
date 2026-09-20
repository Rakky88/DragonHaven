import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/game_strings.dart';
import 'canonical_game_session.dart';
import 'canonical_game_snapshot.dart';
import 'notification_service.dart';

/// Only reminder IDs live on the device. Deadlines and choices come from the
/// confirmed account. Revoking an OS permission never changes those choices.
class ServerGameNotifications {
  ServerGameNotifications(this.session) {
    session.addListener(_changed);
    _changed();
  }
  final CanonicalGameSession session;
  static const _registry = 'server-game-reminder-ids-v1';
  Future<void> _pending = Future.value();
  String? _configuration;
  bool _closed = false;

  void _changed() {
    final view = session.snapshot;
    if (_closed || view == null || !session.fresh) return;
    final reminders = plan(view);
    final configuration =
        jsonEncode([view.ownerId, view.profile.preferences, reminders]);
    if (_configuration == configuration) return;
    _configuration = configuration;
    HavenNotifications.configure(
        (view.profile.preferences['enabledNotificationCategories'] as List)
            .map((v) => HavenNotificationCategory.values.byName(v as String))
            .toSet());
    _pending = _pending.then((_) => _replace(reminders)).catchError((Object _) {
      // A device reminder failure must not invalidate confirmed progress.
      _configuration = null;
    });
  }

  static List<Map<String, dynamic>> plan(CanonicalGameSnapshot view) {
    final prefs = view.profile.preferences;
    final strings = GameStrings(prefs['languageCode'] as String);
    final enabled =
        (prefs['enabledNotificationCategories'] as List).cast<String>();
    final result = <Map<String, dynamic>>[];
    void add(String id, DateTime at, String kind, String title, String body) {
      if (at.isAfter(view.serverTime)) {
        result.add({
          'id': 'server-${view.ownerId}-$id',
          'at': at.toIso8601String(),
          'kind': kind,
          'title': title,
          'body': body,
        });
      }
    }

    if (view.nest case final egg? when enabled.contains('eggReady')) {
      add(
          'egg-${egg.id}',
          egg.hatchAt!,
          'egg',
          strings.pick('Your egg is ready', 'Je ei is klaar'),
          strings.pick('Something inside wants to hatch in the Rooftop Nest.',
              'Iets binnenin wil uitkomen in het Daknest.'));
    }
    for (final run in view.adventures.runs) {
      final dragon = view.dragon(run.dragonId);
      add(
          'adventure-${run.id}',
          run.endsAt,
          'adventure_complete',
          strings.pick('${dragon?.name ?? 'Your dragon'} has returned',
              '${dragon?.name ?? 'Je draak'} is teruggekeerd'),
          strings.pick('An Adventure reward is ready in DragonHaven.',
              'Er staat een avontuurbeloning klaar in DragonHaven.'));
    }
    final missing = 3 - view.trialOffers.length;
    final refill = DateTime.tryParse(
        view.data['trials']['trialRefilledAt']?.toString() ?? '');
    if (missing > 0 && refill != null && enabled.contains('trialsFull')) {
      add(
          'trials-full',
          refill.add(Duration(minutes: 15 * missing)),
          'trials_full',
          strings.pick('Three Trials are ready', 'Drie Trials staan klaar'),
          strings.pick('Choose a dragon and chase a new high score.',
              'Kies een draak en jaag op een nieuwe highscore.'));
    }
    return result;
  }

  Future<void> _replace(List<Map<String, dynamic>> reminders) async {
    final storage = await SharedPreferences.getInstance();
    final old = storage.getStringList(_registry) ?? const <String>[];
    for (final id in old) {
      await HavenNotifications.cancel(id);
    }
    if (_closed) {
      await storage.remove(_registry);
      return;
    }
    await storage.setStringList(
        _registry, reminders.map((r) => r['id'] as String).toList());
    for (final r in reminders) {
      if (_closed) return;
      await HavenNotifications.schedule(
          id: r['id'] as String,
          at: DateTime.parse(r['at'] as String),
          kind: r['kind'] as String,
          title: r['title'] as String,
          body: r['body'] as String);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    session.removeListener(_changed);
    await _pending;
    try {
      await _replace(const []);
    } catch (_) {/* Device settings failure must not prevent account logout. */}
  }
}
