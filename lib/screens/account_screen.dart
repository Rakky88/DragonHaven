import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/profile_portrait.dart';
import '../models/supporter_pack.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'notification_settings_screen.dart';
import 'jukebox_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/online_account_access.dart';
import '../widgets/profile_portrait_sprite.dart';

enum _CloudConflictChoice { viewCloud, keepLocal, replaceCloud, restoreCloud }

const _noFrameSelection = '__no_frame__';
const _noBadgeSelection = '__no_badge__';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final online = context.watch<OnlineAccountProvider>();
    final selectedFrame = keeperFrameById(game.selectedFrameId);
    final selectedBadge = keeperBadgeById(game.selectedBadgeId);
    return Scaffold(
      appBar: AppBar(title: Text(strings.tr('account'))),
      body: ListView(
        key: const PageStorageKey('account-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          _AccountIdentityCard(
            game: game,
            onEditName: () => _editName(context, game.accountName),
            onChoosePortrait: () => _choosePortrait(context),
            onChooseTitle: () => _chooseTitle(context),
          ),
          const SizedBox(height: 18),
          Text(strings.pick('Vanity', 'Uiterlijk'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('account-portrait-collection'),
              contentPadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              leading: KeeperPortrait(
                portraitKey: game.selectedPortraitId ?? 'portrait_001',
                displayName: game.accountName,
                frameKey: game.selectedFrameId,
                badgeKey: game.selectedBadgeId,
                radius: 32,
              ),
              title: Text(
                strings.pick('Account portrait', 'Accountportret'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(strings.pick(
                '${game.portraitCount} collected',
                '${game.portraitCount} verzameld',
              )),
              trailing: const Icon(Icons.grid_view_rounded),
              onTap: () => _choosePortrait(context),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              key: const Key('account-title-collection'),
              contentPadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              leading: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE39A), Color(0xFFE1C8FF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.twilight,
                  size: 34,
                ),
              ),
              title: Text(
                game.selectedAccountTitle == null
                    ? strings.pick('Dragon keeper', 'Drakenhoeder')
                    : strings.accountTitle(game.selectedAccountTitle!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(strings.pick(
                '${game.titleCount} collected',
                '${game.titleCount} verzameld',
              )),
              trailing: const Icon(Icons.format_list_bulleted_rounded),
              onTap: () => _chooseTitle(context),
            ),
          ),
          if (game.ownedBadgeIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                key: const Key('account-badge-collection'),
                contentPadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                leading: selectedBadge == null
                    ? const SizedBox.square(
                        dimension: 54,
                        child: Icon(Icons.shield_outlined, size: 34),
                      )
                    : Image.asset(
                        selectedBadge.assetPath,
                        width: 54,
                        height: 54,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.shield_rounded),
                      ),
                title: Text(
                  selectedBadge == null
                      ? strings.pick('No keeper badge', 'Geen Keeper-badge')
                      : strings.pick(
                          selectedBadge.nameEn,
                          selectedBadge.nameNl,
                        ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(strings.pick(
                  '${game.ownedBadgeIds.length} collected',
                  '${game.ownedBadgeIds.length} verzameld',
                )),
                trailing: const Icon(Icons.verified_rounded),
                onTap: () => _chooseBadge(context),
              ),
            ),
          ],
          if (game.ownedFrameIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                key: const Key('account-frame-collection'),
                contentPadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                leading: KeeperPortrait(
                  portraitKey: game.selectedPortraitId ?? 'portrait_001',
                  displayName: game.accountName,
                  frameKey: game.selectedFrameId,
                  radius: 32,
                ),
                title: Text(
                  selectedFrame != null
                      ? strings.pick(
                          selectedFrame.nameEn,
                          selectedFrame.nameNl,
                        )
                      : strings.pick('No portrait frame', 'Geen portretframe'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(strings.pick(
                  '${game.ownedFrameIds.length} collected',
                  '${game.ownedFrameIds.length} verzameld',
                )),
                trailing: const Icon(Icons.filter_frames_rounded),
                onTap: () => _chooseFrame(context),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (online.isSignedIn) ...[
            Text(strings.pick('Cloud backup', 'Cloudback-up'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              key: const Key('cloud-save-card'),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GameIconSprite(
                          GameIconKind.screenAccount,
                          size: 54,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            online.cloudGameSave == null
                                ? strings.pick(
                                    'Keep a versioned copy of this device\'s progress online.',
                                    'Bewaar online een versieback-up van de voortgang op dit apparaat.',
                                  )
                                : '${strings.pick(
                                    'Cloud backup revision',
                                    'Cloudback-up revisie',
                                  )} ${online.cloudGameSave!.revision}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const Key('cloud-backup-button'),
                            onPressed: online.busy
                                ? null
                                : () => _backupToCloud(context),
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: Text(strings.pick('Back up', 'Back-up')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('cloud-restore-button'),
                            onPressed: online.busy
                                ? null
                                : () => _restoreFromCloud(context),
                            icon: const Icon(Icons.cloud_download_rounded),
                            label: Text(strings.pick('Restore', 'Herstellen')),
                          ),
                        ),
                      ],
                    ),
                    if (online.cloudGameSave != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const Key('cloud-history-button'),
                          onPressed: online.busy
                              ? null
                              : () => _showCloudHistory(context, online),
                          icon: const Icon(Icons.history_rounded),
                          label: Text(strings.pick(
                            'Backup history',
                            'Back-upgeschiedenis',
                          )),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                key: const Key('copy-support-diagnostics'),
                leading: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.twilight,
                ),
                title: Text(
                  strings.pick(
                    'Copy support diagnostics',
                    'Supportdiagnose kopiëren',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(strings.pick(
                  'Contains technical IDs and timings, never your password, e-mail or game save.',
                  'Bevat technische ID’s en tijden, nooit je wachtwoord, e-mail of gamesave.',
                )),
                trailing: const Icon(Icons.copy_rounded),
                onTap: () => _copySupportDiagnostics(context, online),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(strings.pick('Preferences', 'Voorkeuren'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('notification-settings-button'),
              contentPadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              leading: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE49A), Color(0xFFDCCEFF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.twilight,
                  size: 32,
                ),
              ),
              title: Text(
                strings.pick('Notifications', 'Notificaties'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(strings.pick(
                'Choose which reminders you receive',
                'Kies welke meldingen je ontvangt',
              )),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              key: const Key('jukebox-settings-button'),
              contentPadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              leading: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB7E8FF), Color(0xFFE1C8FF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: AppColors.twilight,
                  size: 34,
                ),
              ),
              title: Text(
                strings.pick('Jukebox', 'Jukebox'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(strings.pick(
                '${game.musicTrackCount} tracks collected',
                '${game.musicTrackCount} nummers verzameld',
              )),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const JukeboxScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFFF5DE)],
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('music-switch'),
                    secondary: const GameIconSprite(
                      GameIconKind.audioMusic,
                      size: 58,
                    ),
                    title: Text(
                        strings.pick('Background music', 'Achtergrondmuziek'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(game.musicEnabled
                        ? strings.tr('on')
                        : strings.tr('off')),
                    value: game.musicEnabled,
                    onChanged: game.setMusicEnabled,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('sound-effects-switch'),
                    secondary: const GameIconSprite(
                      GameIconKind.audioSfx,
                      size: 58,
                    ),
                    title: Text(strings.tr('sound_effects'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(game.soundEffectsEnabled
                        ? strings.tr('on')
                        : strings.tr('off')),
                    value: game.soundEffectsEnabled,
                    onChanged: game.setSoundEffectsEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.pick(
              'Both settings react immediately and are stored independently for this local account.',
              'Beide instellingen reageren meteen en worden los van elkaar voor dit lokale account bewaard.',
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _backupToCloud(BuildContext context) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
                strings.pick('Back up progress?', 'Voortgang back-uppen?')),
            content: Text(strings.pick(
              'This stores the current progress from this device in your online account. An older cloud backup will be replaced.',
              'Hiermee wordt de huidige voortgang van dit apparaat in je online account opgeslagen. Een oudere cloudback-up wordt vervangen.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.pick('Back up', 'Back-up')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final online = context.read<OnlineAccountProvider>();
    final success = await online.backupToCloud();
    if (!context.mounted) return;
    if (!success && online.errorCode == 'cloud_save_conflict') {
      await _showCloudSaveConflict(context, online);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? strings.pick('Cloud backup saved.', 'Cloudback-up opgeslagen.')
          : socialMessage(
              strings,
              online.errorCode ?? 'cloud_save_failed',
              supportCode: online.supportCode,
            )),
    ));
  }

  Future<void> _copySupportDiagnostics(
    BuildContext context,
    OnlineAccountProvider online,
  ) async {
    final strings = AppStrings.of(context);
    await Clipboard.setData(ClipboardData(
      text: online.buildSupportDiagnosticReport(
        appVersion: AppInfo.displayVersion,
      ),
    ));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(strings.pick(
        'Support diagnostics copied. Only share them with trusted DragonHaven support.',
        'Supportdiagnose gekopieerd. Deel deze alleen met vertrouwde DragonHaven-support.',
      )),
    ));
  }

  Future<void> _showCloudSaveConflict(
    BuildContext context,
    OnlineAccountProvider online,
  ) async {
    final strings = AppStrings.of(context);
    final remote = online.cloudConflictSave;
    final material = MaterialLocalizations.of(context);
    final updated = remote == null
        ? null
        : '${material.formatFullDate(remote.updatedAt.toLocal())}, '
            '${material.formatTimeOfDay(TimeOfDay.fromDateTime(remote.updatedAt.toLocal()))}';
    final choice = await showDialog<_CloudConflictChoice>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.pick(
              'Different cloud progress found',
              'Andere cloudvoortgang gevonden',
            )),
            content: Text(strings.pick(
              'This device is not based on the latest cloud revision${remote == null ? '' : ' ${remote.revision} from $updated'}. Nothing was overwritten. Restore the cloud copy, or keep playing locally for now.',
              'Dit apparaat is niet gebaseerd op de nieuwste cloudrevisie${remote == null ? '' : ' ${remote.revision} van $updated'}. Er is niets overschreven. Herstel de cloudkopie, of speel voorlopig lokaal verder.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _CloudConflictChoice.viewCloud,
                ),
                child: Text(strings.pick('View cloud', 'Cloud bekijken')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _CloudConflictChoice.keepLocal,
                ),
                child: Text(strings.pick(
                  'Keep local for now',
                  'Voorlopig lokaal houden',
                )),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _CloudConflictChoice.replaceCloud,
                ),
                child: Text(strings.pick(
                  'Replace cloud',
                  'Cloud vervangen',
                )),
              ),
              FilledButton(
                onPressed: remote == null
                    ? null
                    : () => Navigator.pop(
                          dialogContext,
                          _CloudConflictChoice.restoreCloud,
                        ),
                child: Text(strings.pick(
                  'Restore cloud',
                  'Cloud herstellen',
                )),
              ),
            ],
          ),
        ) ??
        _CloudConflictChoice.keepLocal;
    if (!context.mounted || choice == _CloudConflictChoice.keepLocal) return;
    if (choice == _CloudConflictChoice.viewCloud) {
      await _showCloudHistory(context, online);
      return;
    }
    if (choice == _CloudConflictChoice.replaceCloud) {
      await _replaceCloudWithLocal(context, online);
      return;
    }
    final success = await online.restoreFromCloud();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? strings.pick(
              'Cloud progress restored. A local recovery copy was kept.',
              'Cloudvoortgang hersteld. Er is een lokale herstelkopie bewaard.',
            )
          : socialMessage(
              strings,
              online.errorCode ?? 'cloud_save_failed',
              supportCode: online.supportCode,
            )),
    ));
  }

  Future<void> _replaceCloudWithLocal(
    BuildContext context,
    OnlineAccountProvider online,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.pick(
              'Replace cloud progress?',
              'Cloudvoortgang vervangen?',
            )),
            content: Text(strings.pick(
              'The current cloud progress will be replaced by this device. The previous cloud revision remains recoverable for up to thirty days.',
              'De huidige cloudvoortgang wordt vervangen door dit apparaat. De vorige cloudrevisie blijft maximaal dertig dagen herstelbaar.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.pick(
                  'Replace cloud',
                  'Cloud vervangen',
                )),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final success = await online.replaceCloudWithLocal();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? strings.pick(
              'Cloud progress replaced safely.',
              'Cloudvoortgang veilig vervangen.',
            )
          : socialMessage(
              strings,
              online.errorCode ?? 'cloud_save_failed',
              supportCode: online.supportCode,
            )),
    ));
  }

  Future<void> _showCloudHistory(
    BuildContext context,
    OnlineAccountProvider online,
  ) async {
    final strings = AppStrings.of(context);
    final loaded = await online.loadCloudSaveHistory();
    if (!context.mounted) return;
    if (!loaded) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(socialMessage(
          strings,
          online.errorCode ?? 'cloud_save_failed',
          supportCode: online.supportCode,
        )),
      ));
      return;
    }
    final history = online.cloudSaveHistory;
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(strings.pick(
          'No cloud backup history is available.',
          'Er is geen cloudback-upgeschiedenis beschikbaar.',
        )),
      ));
      return;
    }
    final material = MaterialLocalizations.of(context);
    final selectedSaveId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.pick('Backup history', 'Back-upgeschiedenis')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.pick(
                'Up to five cloud revisions are kept for thirty days.',
                'Maximaal vijf cloudrevisies worden dertig dagen bewaard.',
              )),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final save = history[index];
                    final localDate = save.updatedAt.toLocal();
                    final updated =
                        '${material.formatShortDate(localDate)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(localDate))}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${strings.pick('Revision', 'Revisie')} ${save.revision}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (save.isCurrent)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(strings.pick('Current', 'Huidig')),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '$updated\n${strings.pick('App version', 'Appversie')} ${save.clientVersion} · ${strings.pick('Save schema', 'Opslagschema')} ${save.schemaVersion}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.restore_rounded),
                      onTap: () => Navigator.pop(dialogContext, save.saveId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.tr('cancel')),
          ),
        ],
      ),
    );
    if (selectedSaveId == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.pick(
              'Restore this revision?',
              'Deze revisie herstellen?',
            )),
            content: Text(strings.pick(
              'Your local progress will be replaced by this cloud revision. A local recovery copy is kept.',
              'Je lokale voortgang wordt vervangen door deze cloudrevisie. Er blijft een lokale herstelkopie bewaard.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.pick(
                  'Restore revision',
                  'Revisie herstellen',
                )),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final success = await online.restoreCloudRevision(selectedSaveId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? strings.pick(
              'Cloud progress restored. A local recovery copy was kept.',
              'Cloudvoortgang hersteld. Er is een lokale herstelkopie bewaard.',
            )
          : socialMessage(
              strings,
              online.errorCode ?? 'cloud_save_failed',
              supportCode: online.supportCode,
            )),
    ));
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.pick(
              'Restore cloud progress?',
              'Cloudvoortgang herstellen?',
            )),
            content: Text(strings.pick(
              'Your current local progress will be replaced by the latest cloud backup. A local recovery copy is kept.',
              'Je huidige lokale voortgang wordt vervangen door de nieuwste cloudback-up. Er blijft een lokale herstelkopie bewaard.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.pick('Restore', 'Herstellen')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final online = context.read<OnlineAccountProvider>();
    final success = await online.restoreFromCloud();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? strings.pick('Cloud progress restored.', 'Cloudvoortgang hersteld.')
          : socialMessage(
              strings,
              online.errorCode ?? 'cloud_save_missing',
              supportCode: online.supportCode,
            )),
    ));
  }

  Future<void> _editName(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final strings = AppStrings.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title:
            Text(strings.pick('Edit keeper name', 'Naam van hoeder wijzigen')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(strings.tr('save'))),
        ],
      ),
    );
    controller.dispose();
    if (result != null && context.mounted) {
      await context.read<HouseholdProvider>().updateAccountName(result);
      if (context.mounted) {
        final online = context.read<OnlineAccountProvider>();
        if (online.isSignedIn) await online.synchronizeProfile();
      }
    }
  }

  Future<void> _choosePortrait(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final portraits = allProfilePortraits
        .where((portrait) => game.ownedPortraitIds.contains(portrait.id))
        .toList(growable: false);
    if (portraits.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const GameIconSprite(GameIconKind.screenAccount, size: 84),
          title: Text(strings.pick(
            'No portraits collected yet',
            'Nog geen portretten verzameld',
          )),
          content: Text(strings.pick(
            'Portrait Chests cost 100 gems in the Shop and always reveal a portrait you do not own yet.',
            'Portretkisten kosten 100 edelstenen in de Shop en onthullen altijd een portret dat je nog niet bezit.',
          )),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.pick('Understood', 'Begrepen')),
            ),
          ],
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<ProfilePortrait>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .82,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.pick(
                          'Choose account portrait',
                          'Kies accountportret',
                        ),
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${portraits.length}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  key: const Key('account-portrait-grid'),
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                  ),
                  itemCount: portraits.length,
                  itemBuilder: (context, index) {
                    final portrait = portraits[index];
                    final active = portrait.id == game.selectedPortraitId;
                    return Material(
                      color: active
                          ? AppColors.goldLight
                          : const Color(0xFFF4F0FA),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        key: Key('select-portrait-${portrait.id}'),
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.pop(sheetContext, portrait),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: ProfilePortraitSprite(
                                  portrait: portrait,
                                  size: 110,
                                ),
                              ),
                            ),
                            if (active)
                              const Positioned(
                                right: 6,
                                top: 6,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.twilight,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await context
          .read<HouseholdProvider>()
          .selectProfilePortrait(selected.id);
      if (context.mounted) {
        final online = context.read<OnlineAccountProvider>();
        if (online.isSignedIn) await online.synchronizeProfile();
      }
    }
  }

  Future<void> _chooseTitle(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final titles = allAccountTitles
        .where((title) => game.ownedTitleIds.contains(title.id))
        .toList(growable: false)
      ..sort(
          (a, b) => strings.accountTitle(a).compareTo(strings.accountTitle(b)));
    final selected = await showModalBottomSheet<AccountTitle>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .82,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.pick(
                          'Choose account title',
                          'Kies accounttitel',
                        ),
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${titles.length}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: const Key('account-title-list'),
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  itemCount: titles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final title = titles[index];
                    final active = title.id == game.selectedTitleId;
                    return Material(
                      color: active
                          ? AppColors.goldLight
                          : const Color(0xFFF4F0FA),
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        key: Key('select-title-${title.id}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: Icon(
                          active
                              ? Icons.workspace_premium_rounded
                              : Icons.auto_awesome_rounded,
                          color: AppColors.twilight,
                        ),
                        title: Text(
                          strings.accountTitle(title),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        trailing: active
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.twilight,
                              )
                            : null,
                        onTap: () => Navigator.pop(sheetContext, title),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await context.read<HouseholdProvider>().selectAccountTitle(selected.id);
      if (context.mounted) {
        final online = context.read<OnlineAccountProvider>();
        if (online.isSignedIn) await online.synchronizeProfile();
      }
    }
  }

  Future<void> _chooseFrame(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final frames = allKeeperFrames
        .where((frame) => game.ownedFrameIds.contains(frame.id))
        .toList(growable: false);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .72,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.pick(
                          'Choose portrait frame',
                          'Kies portretframe',
                        ),
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${frames.length}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: const Key('account-frame-list'),
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  itemCount: frames.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final frame = index == 0 ? null : frames[index - 1];
                    final active = frame?.id == game.selectedFrameId &&
                        (frame != null || game.selectedFrameId == null);
                    return Material(
                      color: active
                          ? AppColors.goldLight
                          : const Color(0xFFF4F0FA),
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        key: Key(frame == null
                            ? 'select-frame-none'
                            : 'select-frame-${frame.id}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: frame == null
                            ? const SizedBox.square(
                                dimension: 58,
                                child: Icon(Icons.hide_image_rounded),
                              )
                            : KeeperPortrait(
                                portraitKey:
                                    game.selectedPortraitId ?? 'portrait_001',
                                displayName: game.accountName,
                                frameKey: frame.id,
                                radius: 29,
                              ),
                        title: Text(
                          frame == null
                              ? strings.pick(
                                  'No portrait frame',
                                  'Geen portretframe',
                                )
                              : strings.pick(frame.nameEn, frame.nameNl),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        trailing: active
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.twilight,
                              )
                            : null,
                        onTap: () => Navigator.pop(
                          sheetContext,
                          frame?.id ?? _noFrameSelection,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await context.read<HouseholdProvider>().selectKeeperFrame(
          selected == _noFrameSelection ? null : selected,
        );
    if (context.mounted) {
      final online = context.read<OnlineAccountProvider>();
      if (online.isSignedIn) await online.synchronizeProfile();
    }
  }

  Future<void> _chooseBadge(BuildContext context) async {
    final game = context.read<HouseholdProvider>();
    final strings = AppStrings.of(context);
    final badges = allKeeperBadges
        .where((badge) => game.ownedBadgeIds.contains(badge.id))
        .toList(growable: false);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .68,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.pick(
                          'Choose keeper badge',
                          'Kies Keeper-badge',
                        ),
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${badges.length}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: const Key('account-badge-list'),
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  itemCount: badges.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final badge = index == 0 ? null : badges[index - 1];
                    final active = badge?.id == game.selectedBadgeId &&
                        (badge != null || game.selectedBadgeId == null);
                    return Material(
                      color: active
                          ? AppColors.goldLight
                          : const Color(0xFFF4F0FA),
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        key: Key(badge == null
                            ? 'select-badge-none'
                            : 'select-badge-${badge.id}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: badge == null
                            ? const SizedBox.square(
                                dimension: 54,
                                child: Icon(Icons.shield_outlined),
                              )
                            : Image.asset(
                                badge.assetPath,
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                              ),
                        title: Text(
                          badge == null
                              ? strings.pick(
                                  'No keeper badge',
                                  'Geen Keeper-badge',
                                )
                              : strings.pick(badge.nameEn, badge.nameNl),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        trailing: active
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.twilight,
                              )
                            : null,
                        onTap: () => Navigator.pop(
                          sheetContext,
                          badge?.id ?? _noBadgeSelection,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await context.read<HouseholdProvider>().selectKeeperBadge(
          selected == _noBadgeSelection ? null : selected,
        );
    if (context.mounted) {
      final online = context.read<OnlineAccountProvider>();
      if (online.isSignedIn) await online.synchronizeProfile();
    }
  }
}

class _AccountIdentityCard extends StatelessWidget {
  const _AccountIdentityCard({
    required this.game,
    required this.onEditName,
    required this.onChoosePortrait,
    required this.onChooseTitle,
  });

  final HouseholdProvider game;
  final VoidCallback onEditName;
  final VoidCallback onChoosePortrait;
  final VoidCallback onChooseTitle;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<OnlineAccountProvider>();
    final strings = AppStrings.of(context);
    final profile = online.profile;
    return Card(
      key: const Key('online-account-profile'),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF0EAFF), Color(0xFFFFF6DC)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  key: const Key('account-current-portrait'),
                  borderRadius: BorderRadius.circular(50),
                  onTap: onChoosePortrait,
                  child: KeeperPortrait(
                    portraitKey: game.selectedPortraitId ?? 'portrait_001',
                    displayName: game.accountName,
                    frameKey: game.selectedFrameId,
                    badgeKey: game.selectedBadgeId,
                    radius: 46,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.accountName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (keeperBadgeById(game.selectedBadgeId)
                          case final selectedBadge?) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Image.asset(
                              selectedBadge.assetPath,
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield_rounded,
                                size: 20,
                                color: AppColors.twilight,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                strings.pick(
                                  selectedBadge.nameEn,
                                  selectedBadge.nameNl,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF9A671C),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 3),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onChooseTitle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            game.selectedAccountTitle == null
                                ? strings.pick('Dragon keeper', 'Drakenhoeder')
                                : strings
                                    .accountTitle(game.selectedAccountTitle!),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.twilight,
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: strings.pick('Edit name', 'Naam wijzigen'),
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            if (!online.isConfigured)
              _IdentityInfoRow(
                icon: Icons.cloud_off_rounded,
                label: strings.pick(
                  'Online server is not configured',
                  'Online server is niet ingesteld',
                ),
              )
            else if (!online.isSignedIn) ...[
              _IdentityInfoRow(
                icon: Icons.shield_outlined,
                label: strings.pick(
                  'This profile is currently stored offline',
                  'Dit profiel is momenteel offline opgeslagen',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('create-online-account'),
                      onPressed: () => showOnlineAuthDialog(
                        context,
                        createAccount: true,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(strings.pick('Create', 'Maken')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('sign-in-online-account'),
                      onPressed: () => showOnlineAuthDialog(
                        context,
                        createAccount: false,
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(strings.pick('Sign in', 'Inloggen')),
                    ),
                  ),
                ],
              ),
            ] else if (profile == null)
              const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              )
            else ...[
              _IdentityInfoRow(
                icon: Icons.verified_user_rounded,
                label: online.currentEmail ?? '',
                trailing: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2B8B68),
                ),
              ),
              _IdentityInfoRow(
                icon: Icons.badge_outlined,
                label: profile.keeperCode,
                labelStyle: const TextStyle(
                  color: AppColors.twilight,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
                trailing: IconButton(
                  tooltip: strings.pick('Copy Keeper ID', 'Keeper-ID kopiëren'),
                  onPressed: () => copyKeeperCode(context, profile.keeperCode),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 2,
                children: [
                  TextButton.icon(
                    key: const Key('delete-online-account'),
                    onPressed: online.busy
                        ? null
                        : () => _deleteOnlineAccount(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB3261E),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text(
                        strings.pick('Delete account', 'Account verwijderen')),
                  ),
                  TextButton.icon(
                    key: const Key('sign-out-online-account'),
                    onPressed: online.busy ? null : online.signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(strings.pick('Sign out', 'Uitloggen')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _deleteOnlineAccount(BuildContext context) async {
  final strings = AppStrings.of(context);
  final passwordController = TextEditingController();
  final password = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.pick(
        'Delete online account?',
        'Online account verwijderen?',
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.pick(
            'This permanently deletes your online profile, friends, trades and cloud backup. Your current offline save stays on this device.',
            'Hiermee verwijder je permanent je online profiel, vrienden, trades en cloudback-up. Je huidige offline save blijft op dit apparaat staan.',
          )),
          const SizedBox(height: 14),
          TextField(
            key: const Key('delete-account-password'),
            controller: passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText:
                  strings.pick('Confirm password', 'Bevestig wachtwoord'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.tr('cancel')),
        ),
        FilledButton(
          key: const Key('confirm-delete-online-account'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB3261E),
          ),
          onPressed: () {
            final value = passwordController.text;
            if (value.isNotEmpty) Navigator.pop(dialogContext, value);
          },
          child:
              Text(strings.pick('Delete permanently', 'Permanent verwijderen')),
        ),
      ],
    ),
  );
  passwordController.dispose();
  if (password == null || !context.mounted) return;
  final success =
      await context.read<OnlineAccountProvider>().deleteAccount(password);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(success
        ? strings.pick('Online account deleted.', 'Online account verwijderd.')
        : strings.pick(
            'Account deletion failed. Check your password and connection.',
            'Account verwijderen mislukt. Controleer je wachtwoord en verbinding.',
          )),
  ));
}

class _IdentityInfoRow extends StatelessWidget {
  const _IdentityInfoRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.labelStyle,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Row(
          children: [
            Icon(icon, color: AppColors.twilight, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle ??
                    const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (trailing case final child?) child,
          ],
        ),
      );
}
