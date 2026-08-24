import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/account_title.dart';
import '../models/profile_portrait.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';
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
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF0EAFF)],
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    key: const Key('account-current-portrait'),
                    borderRadius: BorderRadius.circular(48),
                    onTap: () => _choosePortrait(context),
                    child: ProfilePortraitSprite(
                      portrait: game.selectedPortrait,
                      size: 88,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.accountName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          game.selectedAccountTitle == null
                              ? strings.pick('Dragon keeper', 'Drakenhoeder')
                              : strings
                                  .accountTitle(game.selectedAccountTitle!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: strings.pick('Edit name', 'Naam wijzigen'),
                    onPressed: () => _editName(context, game.accountName),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
            ),
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
    }
  }
}
