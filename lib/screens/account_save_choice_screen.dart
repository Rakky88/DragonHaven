import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/account_legacy_game_storage.dart';
import '../theme/app_theme.dart';

class AccountSaveChoiceScreen extends StatelessWidget {
  const AccountSaveChoiceScreen(
      {super.key,
      required this.review,
      required this.onChoose,
      required this.onSignOut,
      this.fresh = false});
  final AccountSaveReview review;
  final void Function(AccountSaveChoice) onChoose;
  final VoidCallback onSignOut;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('DragonHaven'), actions: [
        IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            tooltip: s.pick('Sign out', 'Uitloggen')),
      ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.cloud_done_outlined,
              size: 42, color: AppColors.twilight),
          const SizedBox(height: 12),
          Text(
              s.pick(fresh ? 'Your new Haven' : 'Choose your progress',
                  fresh ? 'Je nieuwe Haven' : 'Kies je voortgang'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(s.pick(
              'Review both copies before continuing. Both are kept for recovery. Signing in never replaces your progress automatically.',
              'Vergelijk de kopieën voordat je verdergaat. Beide blijven bewaard voor herstel. Inloggen vervangt je voortgang nooit automatisch.')),
          if (review.unassignedLocal && !fresh) ...[
            const SizedBox(height: 12),
            Text(s.pick(
                'Choose the device copy only if it belongs to this account.',
                'Kies de apparaatkopie alleen als die bij dit account hoort.')),
          ],
          if (review.local case final local?)
            _source(
                context,
                local,
                fresh
                    ? s.pick('New Haven', 'Nieuwe Haven')
                    : s.pick('On this device', 'Op dit apparaat'),
                AccountSaveChoice.local),
          if (review.cloud case final cloud?)
            _source(context, cloud, s.pick('Cloud backup', 'Cloudback-up'),
                AccountSaveChoice.cloud),
          if (!review.canChooseCloud && review.cloud != null)
            Text(s.pick(
                'An Altar request is still pending on this device. Continue with the device copy to recover it first.',
                'Er staat nog een Altar-verzoek open op dit apparaat. Ga verder met de apparaatkopie om dat eerst af te handelen.')),
        ]),
      ))),
    );
  }

  Widget _source(BuildContext context, Map<String, dynamic> state, String title,
      AccountSaveChoice choice) {
    final s = AppStrings.of(context);
    final pet = state['pet'] as Map? ?? const {};
    final dragons = (state['sanctuaryDragons'] as List? ?? const []).length +
        (pet.isEmpty ? 0 : 1);
    final forms = (state['discoveredForms'] as List? ?? const []).length;
    final cloud = choice == AccountSaveChoice.cloud;
    return Card(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(state['accountName']?.toString() ?? ''),
              Text('${pet['coins'] ?? 0} coins · ${pet['gems'] ?? 0} gems'),
              Text(s.pick('$dragons dragons · $forms forms',
                  '$dragons draken · $forms vormen')),
              Text(s.pick(
                  '${state['totalAdventuresCompleted'] ?? 0} completed adventures',
                  '${state['totalAdventuresCompleted'] ?? 0} afgeronde avonturen')),
              if (cloud && review.cloudUpdatedAt != null)
                Text(MaterialLocalizations.of(context)
                    .formatFullDate(review.cloudUpdatedAt!.toLocal())),
              const SizedBox(height: 12),
              FilledButton(
                  key: Key('choose-${choice.name}-save'),
                  onPressed: cloud && !review.canChooseCloud
                      ? null
                      : () async {
                          if (cloud && review.local != null) {
                            final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                        title: Text(s.pick(
                                            'Use this cloud copy?',
                                            'Deze cloudkopie gebruiken?')),
                                        content: Text(s.pick(
                                            'This copy may be older. Your device progress is preserved separately before switching.',
                                            'Deze kopie kan ouder zijn. Je apparaatvoortgang wordt apart bewaard voordat je wisselt.')),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(s.tr('cancel'))),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(s.pick(
                                                  'Use cloud copy',
                                                  'Cloudkopie gebruiken'))),
                                        ]));
                            if (confirmed != true || !context.mounted) return;
                          }
                          onChoose(choice);
                        },
                  child: Text(cloud
                      ? s.pick('Use cloud copy', 'Cloudkopie gebruiken')
                      : s.pick(
                          fresh ? 'Start new Haven' : 'Keep device progress',
                          fresh
                              ? 'Nieuwe Haven starten'
                              : 'Apparaatvoortgang behouden'))),
            ],
          ),
        ));
  }
}
