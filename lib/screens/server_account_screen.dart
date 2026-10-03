import 'dart:async';

import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../models/music_track.dart';
import '../models/keeper_level.dart';
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
import '../widgets/keeper_name_validation.dart';
import '../widgets/game_icon_sprite.dart';

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
        _KeeperLevelCard(
          level: view.profile.keeperLevel,
          xp: view.profile.keeperXp,
          floorXp: view.profile.keeperLevelFloorXp,
          nextLevelXp: view.profile.keeperNextLevelXp,
          progress: view.profile.keeperProgress,
          pendingRewards: view.profile.pendingKeeperLevelRewardLevels.length,
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
    final owner = session.snapshot?.ownerId;
    final epoch = session.connection.sessionEpoch;
    final s = AppStrings.of(context);
    final controller =
        TextEditingController(text: session.snapshot!.profile.name);
    final formKey = GlobalKey<FormState>();
    try {
      final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(s.pick('Keeper name', 'Naam van je hoeder')),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    maxLength: 24,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => keeperNameValidationMessage(s, value),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.tr('cancel'))),
                  FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() == true) {
                          Navigator.pop(context, controller.text.trim());
                        }
                      },
                      child: Text(s.pick('Save', 'Opslaan')))
                ],
              ));
      if (name != null &&
          context.mounted &&
          owner != null &&
          session.snapshot?.ownerId == owner &&
          session.connection.sessionEpoch == epoch &&
          session.canAct) {
        await runShopAction(
            context, () => CanonicalGameActions(session).setAccountName(name));
      }
    } finally {
      // Let the dialog finish its reverse transition before disposing its field.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
    }
  }
}

class _KeeperLevelCard extends StatelessWidget {
  const _KeeperLevelCard({
    required this.level,
    required this.xp,
    required this.floorXp,
    required this.nextLevelXp,
    required this.progress,
    required this.pendingRewards,
  });

  final int level;
  final int xp;
  final int floorXp;
  final int nextLevelXp;
  final double progress;
  final int pendingRewards;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final maximum = level >= maximumKeeperLevel;
    final earnedInLevel = xp - floorXp;
    final requiredInLevel = nextLevelXp - floorXp;
    final nextLevel = (level + 1).clamp(1, maximumKeeperLevel);
    return Container(
      key: const Key('keeper-level-card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25184C), Color(0xFF6849A1)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x66FFE49A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x303C236F),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -34,
            top: -42,
            child: _KeeperLevelGlow(size: 132),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 12, 13),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE49A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66FFD66E), blurRadius: 16),
                        ],
                      ),
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          color: Color(0xFF35215E),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.pick(
                                'Keeper Level $level', 'Hoederniveau $level'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            maximum
                                ? s.pick('Maximum level reached',
                                    'Maximaal niveau bereikt')
                                : s.pick('Next: Level $nextLevel',
                                    'Volgende: niveau $nextLevel'),
                            style: const TextStyle(
                              color: Color(0xFFE4D8F5),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pendingRewards > 0)
                      Badge.count(
                        count: pendingRewards,
                        backgroundColor: const Color(0xFFFFD66E),
                        textColor: const Color(0xFF35215E),
                        child: const Icon(Icons.inventory_2_rounded,
                            color: Colors.white),
                      ),
                    IconButton(
                      key: const Key('keeper-level-info'),
                      tooltip: s.pick(
                          'How to earn Keeper XP', 'Zo verdien je Hoeder-XP'),
                      color: Colors.white,
                      onPressed: () => _showXpInfo(context),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    key: const Key('keeper-level-progress'),
                    value: progress,
                    minHeight: 11,
                    color: const Color(0xFFFFD66E),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 7, 18, 12),
                child: Row(
                  children: [
                    const GameIconSprite(GameIconKind.experience, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      maximum
                          ? '${_compactXp(xp)} XP'
                          : '${_compactXp(earnedInLevel)} / ${_compactXp(requiredInLevel)} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingRewards > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0x24FFE49A),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.redeem_rounded,
                          size: 20, color: Color(0xFFFFE49A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.pick(
                            'A Level Chest is waiting in Inventory.',
                            'Er staat een Levelkist klaar in Inventaris.',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.white10,
                  hoverColor: Colors.white10,
                ),
                child: ExpansionTile(
                  key: const Key('keeper-level-rewards'),
                  iconColor: const Color(0xFFFFE49A),
                  collapsedIconColor: const Color(0xFFFFE49A),
                  textColor: Colors.white,
                  collapsedTextColor: Colors.white,
                  tilePadding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 17),
                  leading: const Icon(Icons.card_giftcard_rounded,
                      color: Color(0xFFFFE49A)),
                  title: Text(
                    s.pick('Level rewards', 'Levelbeloningen'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    s.pick('Open one Level Chest after every new level.',
                        'Open na elk nieuw niveau één Levelkist.'),
                    style: const TextStyle(
                      color: Color(0xFFDCCFED),
                      fontSize: 11,
                    ),
                  ),
                  children: [
                    _KeeperRewardLine(
                        icon: Icons.emoji_emotions_rounded,
                        text: s.pick('A level-specific emote',
                            'Een levelspecifieke emote')),
                    _KeeperRewardLine(
                        icon: Icons.egg_alt_rounded,
                        text: s.pick('One egg · 25% Mythical chance',
                            'Eén ei · 25% kans op Mythisch')),
                    _KeeperRewardLine(
                        icon: Icons.military_tech_rounded,
                        text: s.pick('A badge for that Keeper Level',
                            'Een badge voor dat Hoederniveau')),
                    _KeeperRewardLine(
                        icon: Icons.auto_awesome_rounded,
                        text: s.pick('One guaranteed random Relic',
                            'Eén gegarandeerd willekeurig reliek')),
                    _KeeperRewardLine(
                        icon: Icons.workspace_premium_rounded,
                        text: s.pick(
                            'Level 40: exclusive frame and achievement',
                            'Niveau 40: exclusieve lijst en achievement')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showXpInfo(BuildContext context) {
    final s = AppStrings.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('keeper-level-xp-dialog'),
        icon: const GameIconSprite(GameIconKind.experience, size: 72),
        title: Text(s.pick('How to earn Keeper XP', 'Zo verdien je Hoeder-XP')),
        content: Text(
          s.pick(
            'After a dragon reaches Level 50, every Dragon XP point it earns goes to your Keeper level instead. Adventures, Trials, Dragon School and Starlight Treats all count. XP boosts on that dragon also carry over.',
            'Zodra een draak level 50 bereikt, gaat elk nieuw Draak-XP-punt naar je Hoederniveau. Avonturen, Trials, Dragon School en Starlight Treats tellen allemaal mee. XP-boosts op die draak tellen ook door.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.pick('Got it', 'Begrepen')),
          ),
        ],
      ),
    );
  }

  static String _compactXp(int value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(value >= 10000000000 ? 0 : 1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return '$value';
  }
}

class _KeeperLevelGlow extends StatelessWidget {
  const _KeeperLevelGlow({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x55FFE49A), Color(0x00FFE49A)],
          ),
        ),
      );
}

class _KeeperRewardLine extends StatelessWidget {
  const _KeeperRewardLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: const Color(0xFFFFE49A)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      );
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
  final owner = session.snapshot?.ownerId;
  final epoch = session.connection.sessionEpoch;
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
  if (code != null &&
      context.mounted &&
      owner != null &&
      session.snapshot?.ownerId == owner &&
      session.connection.sessionEpoch == epoch &&
      session.canAct) {
    await runShopAction(
        context,
        () => CanonicalGameActions(session)
            .setPreferences({'languageCode': code}));
  }
}
