import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../theme/app_theme.dart';

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
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: Text(game.accountName,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(strings.pick('Dragon keeper', 'Drakenhoeder')),
              trailing: IconButton(
                tooltip: strings.pick('Edit name', 'Naam wijzigen'),
                onPressed: () => _editName(context, game.accountName),
                icon: const Icon(Icons.edit_rounded),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(strings.pick('Audio', 'Audio'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('music-switch'),
                  secondary: const Icon(Icons.music_note_rounded,
                      color: AppColors.twilight),
                  title: Text(strings.tr('music'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      game.musicEnabled ? strings.tr('on') : strings.tr('off')),
                  value: game.musicEnabled,
                  onChanged: game.setMusicEnabled,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const Key('sound-effects-switch'),
                  secondary: const Icon(Icons.volume_up_rounded,
                      color: AppColors.twilight),
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
}
