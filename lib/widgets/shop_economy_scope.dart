import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/household_provider.dart';
import '../services/canonical_game_session.dart';
import '../services/canonical_game_snapshot.dart';
import '../services/shop_economy.dart';
import 'ui_bits.dart';

ShopEconomy watchShopEconomy(BuildContext context) {
  final server = context.watch<CanonicalGameSession?>();
  return server == null
      ? ShopEconomy.legacy(context.watch<HouseholdProvider>())
      : ShopEconomy.canonical(server);
}

ShopEconomy readShopEconomy(BuildContext context) {
  final server = context.read<CanonicalGameSession?>();
  return server == null
      ? ShopEconomy.legacy(context.read<HouseholdProvider>())
      : ShopEconomy.canonical(server);
}

Future<void> runShopAction(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on CanonicalGameException catch (error) {
    if (context.mounted) {
      showAppSnackBar(
          context, gameConnectionMessage(AppStrings.of(context), error.code));
    }
  }
}

String gameConnectionMessage(AppStrings strings, String? code) =>
    switch (code) {
      'game_login_required' || 'game_account_changed' => strings.pick(
          'Sign in again to load your inventory.',
          'Log opnieuw in om je inventaris te laden.'),
      'game_engine_disabled' => strings.pick(
          'Game actions are temporarily paused. Your inventory is safe.',
          'Spelacties zijn tijdelijk gepauzeerd. Je inventaris is veilig.'),
      'game_command_busy' => strings.pick(
          'Your previous action is still being checked.',
          'Je vorige actie wordt nog gecontroleerd.'),
      'game_storage_unavailable' => strings.pick(
          'Your progress could not be saved on this device. Free some space and try again.',
          'Je voortgang kon niet op dit apparaat worden opgeslagen. Maak ruimte vrij en probeer opnieuw.'),
      'game_state_changed' || 'game_refresh_required' => strings.pick(
          'Your inventory has changed. Refresh it before continuing.',
          'Je inventaris is gewijzigd. Vernieuw deze voordat je verdergaat.'),
      _ => strings.pick(
          'We could not confirm your inventory. Reconnect to check your last action before continuing.',
          'We konden je inventaris niet bevestigen. Verbind opnieuw om je laatste actie te controleren voordat je verdergaat.'),
    };

/// Keeps the ordinary catalog browsable from a cache. It never shows a local
/// balance, an invented zero balance or enabled spending while a read is absent.
class ShopEconomyBoundary extends StatelessWidget {
  const ShopEconomyBoundary({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final server = context.watch<CanonicalGameSession?>();
    if (server == null) return child;
    final strings = AppStrings.of(context);
    final hasView = server.snapshot != null;
    final showStatus = !server.canAct || server.errorCode != null;
    return Column(children: [
      if (showStatus)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (server.busy) ...[
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
            ],
            Expanded(
                child: Text(server.busy
                    ? strings.pick('Checking your inventory…',
                        'Je inventaris wordt gecontroleerd…')
                    : gameConnectionMessage(
                        strings,
                        server.snapshot?.mutationsEnabled == false
                            ? 'game_engine_disabled'
                            : server.errorCode))),
            if (!server.busy)
              IconButton(
                key: const Key('economy-reconnect'),
                tooltip: strings.pick('Reconnect', 'Opnieuw verbinden'),
                onPressed: () => runShopAction(context, () async {
                  await server.synchronize();
                }),
                icon: const Icon(Icons.refresh_rounded),
              ),
          ]),
        ),
      if (hasView)
        Expanded(child: child)
      else
        const Expanded(child: SizedBox.shrink()),
    ]);
  }
}
