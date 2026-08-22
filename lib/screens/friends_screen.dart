import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/game_icon_sprite.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListView(
      key: const PageStorageKey('friends-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const GameIconSprite(GameIconKind.navFriends, size: 94),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.tr('friends'),
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    strings.pick(
                      'Visit towers, lend a friendly dragon and trade eggs, chests or furniture.',
                      'Bezoek torens, leen een bevriende draak en ruil eieren, kisten of meubels.',
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFFEDE8FF),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              const GameIconSprite(GameIconKind.navFriends, size: 94),
              const SizedBox(height: 5),
              Text(strings.tr('coming_online'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                strings.pick(
                  'This build keeps your collection safely on this device. A real friend list needs authenticated accounts and a server, so no local demo person is shown as if they were online.',
                  'Deze build bewaart je collectie veilig op dit toestel. Een echte vriendenlijst heeft accounts en een server nodig; daarom wordt geen lokale demo-persoon als online voorgesteld.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        _PlannedFeature(
          kind: GameIconKind.friendsAdd,
          title: strings.pick('Add a keeper', 'Hoeder toevoegen'),
          description: strings.pick(
              'Search by a stable player code; names are never treated as unique IDs.',
              'Zoek met een vaste spelerscode; namen worden nooit als unieke ID gebruikt.'),
        ),
        _PlannedFeature(
          kind: GameIconKind.friendsTrade,
          title: strings.pick('Two-sided trade', 'Tweezijdige ruil'),
          description: strings.pick(
              'Both keepers must offer at least one egg, chest or item and confirm the final trade.',
              'Beide hoeders bieden minimaal één ei, kist of item aan en bevestigen de definitieve ruil.'),
        ),
        _PlannedFeature(
          kind: GameIconKind.friendsVisit,
          title: strings.pick('Tower visits', 'Torenbezoeken'),
          description: strings.pick(
              'Read-only visits can show the favorite dragon, rooms and achievements—including locked ??? secrets.',
              'Alleen-lezen-bezoeken tonen de favoriete draak, kamers en prestaties—inclusief vergrendelde ???-geheimen.'),
        ),
      ],
    );
  }
}

class _PlannedFeature extends StatelessWidget {
  const _PlannedFeature(
      {required this.kind, required this.title, required this.description});
  final GameIconKind kind;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          minVerticalPadding: 12,
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          leading: SizedBox.square(
            dimension: 64,
            child: GameIconSprite(kind, size: 64),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(description),
          trailing:
              const Icon(Icons.lock_clock_rounded, color: AppColors.muted),
        ),
      );
}
