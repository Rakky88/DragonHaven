import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../models/music_track.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/shop_economy_scope.dart';
import 'canonical_profile_screen.dart';
import 'account_screen.dart' show deleteOnlineAccount;
import '../providers/online_account_provider.dart';
import 'privacy_screen.dart';
import 'notification_settings_screen.dart' show NotificationPreferenceToggle;
import '../services/notification_service.dart';

class ServerAccountScreen extends StatelessWidget {
  const ServerAccountScreen({super.key, required this.auth});
  final SupabaseClient auth;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final s = AppStrings.of(context);
    final p = view.profile.preferences;
    Future<void> change(Map<String, dynamic> changes) => runShopAction(
        context, () => CanonicalGameActions(session).setPreferences(changes));
    return Scaffold(
      appBar: AppBar(title: Text(s.tr('account'))),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        ListTile(
          title: Text(view.profile.name),
          subtitle: Text(auth.auth.currentUser?.email ?? ''),
          trailing: const Icon(Icons.edit_outlined),
          onTap: session.canAct ? () => _name(context) : null,
        ),
        ListTile(
          leading: const Icon(Icons.face_retouching_natural),
          title: Text(s.pick('Portrait, title and decorations',
              'Portret, titel en versieringen')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(s.pick('Profile', 'Profiel'))),
                      body: const CanonicalProfileScreen()))),
        ),
        DropdownButtonFormField<String>(
          initialValue: p['languageCode'] as String,
          decoration: InputDecoration(labelText: s.pick('Language', 'Taal')),
          items: [
            for (final entry in AppStrings.supportedLanguages.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value))
          ],
          onChanged: session.canAct
              ? (v) {
                  if (v != null) change({'languageCode': v});
                }
              : null,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
            title: Text(s.pick('Music', 'Muziek')),
            value: p['musicEnabled'] as bool,
            onChanged:
                session.canAct ? (v) => change({'musicEnabled': v}) : null),
        SwitchListTile(
            title: Text(s.pick('Sound effects', 'Geluidseffecten')),
            value: p['soundEffectsEnabled'] as bool,
            onChanged: session.canAct
                ? (v) => change({'soundEffectsEnabled': v})
                : null),
        ExpansionTile(title: const Text('Jukebox'), children: [
          SwitchListTile(
              title: Text(s.pick('Shuffle', 'Willekeurige volgorde')),
              value: p['jukeboxShuffle'] as bool,
              onChanged:
                  session.canAct ? (v) => change({'jukeboxShuffle': v}) : null),
          SwitchListTile(
              title: Text(s.pick('Repeat', 'Herhalen')),
              value: p['jukeboxRepeat'] as bool,
              onChanged:
                  session.canAct ? (v) => change({'jukeboxRepeat': v}) : null),
          for (final track in [
            ...seasonalMusicCatalog.where((t) => view.adventures.activeEvents
                .any((w) =>
                    w.eventId == t.temporaryEventId &&
                    w.contains(view.serverTime))),
            ...musicCatalog.where((t) => view.shop.music.contains(t.id)),
          ])
            SwitchListTile(
                title: Text(track.title),
                subtitle: Text(track.composer),
                value: track.isTemporaryEventTrack
                    ? !(p['disabledSeasonalMusicTrackIds'] as List)
                        .contains(track.id)
                    : (p['enabledMusicTrackIds'] as List).contains(track.id),
                onChanged: session.canAct
                    ? (v) {
                        final key = track.isTemporaryEventTrack
                            ? 'disabledSeasonalMusicTrackIds'
                            : 'enabledMusicTrackIds';
                        final ids = (p[key] as List).cast<String>().toSet();
                        if (track.isTemporaryEventTrack ? !v : v) {
                          ids.add(track.id);
                        } else {
                          ids.remove(track.id);
                        }
                        change({key: ids.toList()});
                      }
                    : null),
        ]),
        ExpansionTile(
            title: Text(s.pick('Notifications', 'Notificaties')),
            children: [
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(s.pick(
                      'Your notification choices follow your account. Allow notifications on each device where you want to receive them.',
                      'Je notificatiekeuzes horen bij je account. Geef toestemming op elk apparaat waarop je ze wilt ontvangen.'))),
              OutlinedButton(
                  onPressed: () async {
                    if (!await HavenNotifications.requestPlatformPermission()) {
                      await HavenNotifications
                          .openPlatformNotificationSettings();
                    }
                  },
                  child: Text(s.pick(
                      'Allow on this device', 'Toestaan op dit apparaat'))),
              for (final category in HavenNotificationCategory.values)
                NotificationPreferenceToggle(
                    category: category,
                    enabled: (p['enabledNotificationCategories'] as List)
                        .contains(category.name),
                    onChanged: session.canAct
                        ? (v) {
                            final ids =
                                (p['enabledNotificationCategories'] as List)
                                    .cast<String>()
                                    .toSet();
                            if (v) {
                              ids.add(category.name);
                            } else {
                              ids.remove(category.name);
                            }
                            change({
                              'enabledNotificationCategories': ids.toList()
                            });
                          }
                        : null),
            ]),
        ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(s.pick('Privacy notice', 'Privacyverklaring')),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const PrivacyScreen()))),
        OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(s.pick('Sign out', 'Uitloggen')),
            onPressed: session.busy
                ? null
                : () async {
                    await context.read<OnlineAccountProvider>().signOut();
                  }),
        TextButton(
            onPressed: session.busy ? null : () => deleteOnlineAccount(context),
            child: Text(s.pick('Delete account', 'Account verwijderen'),
                style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        Text('DragonHaven ${AppInfo.version}', textAlign: TextAlign.center),
      ]),
    );
  }

  Future<void> _name(BuildContext context) async {
    final session = context.read<CanonicalGameSession>();
    final actions = CanonicalGameActions(session);
    final s = AppStrings.of(context);
    final controller =
        TextEditingController(text: session.snapshot!.profile.name);
    try {
      final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(s.pick('Keeper name', 'Naam van je hoeder')),
                content: TextField(
                    controller: controller, maxLength: 24, autofocus: true),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.tr('cancel'))),
                  FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          Navigator.pop(context, controller.text.trim());
                        }
                      },
                      child: Text(s.pick('Save', 'Opslaan')))
                ],
              ));
      if (name != null && context.mounted) {
        await runShopAction(context, () => actions.setAccountName(name));
      }
    } finally {
      // Let the dialog finish its reverse transition before disposing its field.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
    }
  }
}
