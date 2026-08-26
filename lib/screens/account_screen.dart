import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/profile_portrait.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import 'notification_settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
import '../widgets/online_account_access.dart';
import '../widgets/profile_portrait_sprite.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final game = context.watch<HouseholdProvider>();
    final online = context.watch<OnlineAccountProvider>();
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
              leading: ProfilePortraitSprite(
                portrait: game.selectedPortrait,
                size: 64,
              ),
              title: Text(
                strings.pick('Account portrait', 'Accountportret'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(strings.pick(
                '${game.portraitCount} of ${profilePortraitCatalog.length} collected',
                '${game.portraitCount} van ${profilePortraitCatalog.length} verzameld',
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
                '${game.titleCount} of ${accountTitleCatalog.length} collected',
                '${game.titleCount} van ${accountTitleCatalog.length} verzameld',
              )),
              trailing: const Icon(Icons.format_list_bulleted_rounded),
              onTap: () => _chooseTitle(context),
            ),
          ),
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
                  ],
                ),
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
                        strings.pick('Music · Rêverie', 'Muziek · Rêverie'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? strings.pick('Cloud backup saved.', 'Cloudback-up opgeslagen.')
          : strings.pick(
              'Cloud backup failed. Refresh and try again.',
              'Cloudback-up mislukt. Ververs en probeer opnieuw.',
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
          : strings.pick(
              'No usable cloud backup was found.',
              'Er is geen bruikbare cloudback-up gevonden.',
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
    final portraits = profilePortraitCatalog
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
            'Portrait Chests cost 99 gems in the Shop and always reveal a portrait you do not own yet.',
            'Portretkisten kosten 99 edelstenen in de Shop en onthullen altijd een portret dat je nog niet bezit.',
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
                      '${portraits.length}/${profilePortraitCatalog.length}',
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
    final titles = accountTitleCatalog
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
                      '${titles.length}/${accountTitleCatalog.length}',
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
                  child: ProfilePortraitSprite(
                    portrait: game.selectedPortrait,
                    size: 92,
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
