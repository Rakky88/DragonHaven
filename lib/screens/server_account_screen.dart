import 'dart:async';

import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../models/music_track.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_rewarded_ads.dart';
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
    final rewardedAds = context.watch<CanonicalRewardedAds?>();
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
        ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(s.pick('Language', 'Taal')),
            subtitle:
                Text(AppStrings.supportedLanguages[p['languageCode']] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: session.canAct
                ? () => showServerLanguagePicker(context)
                : null),
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
              DeviceNotificationAccess(
                  hasEnabledCategories:
                      (p['enabledNotificationCategories'] as List).isNotEmpty),
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
        if (rewardedAds?.privacyOptionsRequired == true)
          ListTile(
            key: const Key('rewarded-ad-privacy-options'),
            leading: const Icon(Icons.ads_click_rounded),
            title: Text(s.pick(
                'Ad privacy choices', 'Privacykeuzes voor advertenties')),
            subtitle: Text(s.pick('Review or change your advertising consent.',
                'Bekijk of wijzig je toestemming voor advertenties.')),
            onTap: () =>
                runShopAction(context, () => rewardedAds!.showPrivacyOptions()),
          ),
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

class DeviceNotificationAccess extends StatefulWidget {
  const DeviceNotificationAccess(
      {super.key, required this.hasEnabledCategories});

  final bool hasEnabledCategories;

  @override
  State<DeviceNotificationAccess> createState() =>
      _DeviceNotificationAccessState();
}

class _DeviceNotificationAccessState extends State<DeviceNotificationAccess>
    with WidgetsBindingObserver {
  HavenNotificationPermissionStatus? _status;
  bool? _exactAlarmGranted;
  bool _busy = false;
  late final StreamSubscription<HavenNotificationPermissionStatus>
      _permissionChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionChanges = HavenNotifications.permissionStatusChanges.listen(
      (status) {
        if (!mounted) return;
        setState(() => _status = status);
      },
    );
    unawaited(_refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_permissionChanges.cancel());
    super.dispose();
  }

  Future<void> _refresh() async {
    final values = await Future.wait<Object>([
      HavenNotifications.platformPermissionStatus(),
      HavenNotifications.exactAlarmPermissionGranted(),
    ]);
    if (!mounted) return;
    setState(() {
      _status = values[0] as HavenNotificationPermissionStatus;
      _exactAlarmGranted = values[1] as bool;
    });
  }

  Future<void> _allow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final granted = await HavenNotifications.requestPlatformPermission();
    if (!granted) {
      await HavenNotifications.openPlatformNotificationSettings();
    }
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).pick(
              'Notifications are allowed on this device.',
              'Notificaties zijn toegestaan op dit apparaat.'))));
    }
  }

  Future<void> _openSettings() async {
    if (_busy) return;
    setState(() => _busy = true);
    await HavenNotifications.openPlatformNotificationSettings();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final granted = _status == HavenNotificationPermissionStatus.granted;
    final denied = _status == HavenNotificationPermissionStatus.denied;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            key: const Key('device-notification-access-card'),
            color: granted
                ? const Color(0xFFEAF7EE)
                : denied
                    ? const Color(0xFFFFF3E2)
                    : AppColors.mist,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    granted
                        ? Icons.notifications_active_rounded
                        : denied
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_none_rounded,
                    color: granted
                        ? const Color(0xFF287A46)
                        : denied
                            ? const Color(0xFF9B4A20)
                            : AppColors.twilight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status == null
                          ? s.pick('Checking device access…',
                              'Apparaattoegang controleren…')
                          : granted
                              ? s.pick('Allowed on this device',
                                  'Toegestaan op dit apparaat')
                              : denied
                                  ? s.pick(
                                      'Android notifications are off for DragonHaven.',
                                      'Android-meldingen staan uit voor DragonHaven.')
                                  : s.pick(
                                      'Allow Android to deliver DragonHaven notifications.',
                                      'Sta Android toe om DragonHaven-notificaties te bezorgen.'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_busy)
                    const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                  else if (granted)
                    TextButton(
                      key: const Key('manage-device-notifications'),
                      onPressed: _openSettings,
                      child: Text(s.pick('Manage', 'Beheren')),
                    )
                  else
                    TextButton(
                      key: const Key('allow-device-notifications'),
                      onPressed: denied ? _openSettings : _allow,
                      child: Text(denied
                          ? s.pick('Open settings', 'Open instellingen')
                          : s.pick('Allow', 'Toestaan')),
                    ),
                ],
              ),
            ),
          ),
          if (granted && _exactAlarmGranted == false) ...[
            const SizedBox(height: 8),
            Card(
              key: const Key('server-exact-alarm-permission-card'),
              color: const Color(0xFFFFF3E2),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_rounded, color: Color(0xFF9B4A20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.pick(
                          'Allow precise timing so egg, Adventure and Trial reminders arrive on time.',
                          'Sta precieze timing toe zodat meldingen voor eieren, avonturen en Trials op tijd komen.')),
                    ),
                    TextButton(
                      key: const Key('server-open-exact-alarm-settings'),
                      onPressed: HavenNotifications.openExactAlarmSettings,
                      child: Text(s.pick('Allow', 'Toestaan')),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!widget.hasEnabledCategories) ...[
            const SizedBox(height: 8),
            Text(
              s.pick('Choose at least one notification type below.',
                  'Kies hieronder minstens één type notificatie.'),
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showServerLanguagePicker(BuildContext context) async {
  final session = context.read<CanonicalGameSession>();
  final actions = CanonicalGameActions(session);
  final selected = session.snapshot!.profile.preferences['languageCode'];
  final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .78,
              child: ListView(
                  key: const Key('language-picker-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text(AppStrings.of(context).tr('language'),
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    for (final entry in AppStrings.supportedLanguages.entries)
                      Card(
                          child: ListTile(
                              tileColor: selected == entry.key
                                  ? AppColors.mist
                                  : Colors.white,
                              leading: Icon(
                                  selected == entry.key
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: AppColors.twilight),
                              title: Text(entry.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              trailing: Text(entry.key.toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w800)),
                              onTap: () => Navigator.pop(context, entry.key))),
                  ]))));
  if (code != null && context.mounted) {
    await runShopAction(
        context, () => actions.setPreferences({'languageCode': code}));
  }
}
