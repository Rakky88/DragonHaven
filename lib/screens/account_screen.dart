import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/profile_portrait.dart';
import '../providers/household_provider.dart';
import '../providers/online_account_provider.dart';
import '../services/audio_service.dart';
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
          Text(strings.pick('Portraits', 'Portretten'),
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
          const SizedBox(height: 18),
          Text(strings.pick('Titles', 'Titels'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
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
          Text(strings.pick('Audio', 'Audio'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
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
                  Padding(
                    key: const Key('music-style-selector'),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tr('music_style'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<HavenMusicStyle>(
                            key: const Key('music-style-segments'),
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: HavenMusicStyle.basic,
                                label: Text(strings.tr('basic')),
                              ),
                              ButtonSegment(
                                value: HavenMusicStyle.classic,
                                label: Text(strings.tr('classic')),
                              ),
                            ],
                            selected: {game.musicStyle},
                            onSelectionChanged: (selection) =>
                                game.setMusicStyle(selection.single),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('music-switch'),
                    secondary: const GameIconSprite(
                      GameIconKind.audioMusic,
                      size: 58,
                    ),
                    title: Text(strings.tr('music'),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('sign-out-online-account'),
                  onPressed: online.busy ? null : online.signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(strings.pick('Sign out', 'Uitloggen')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
