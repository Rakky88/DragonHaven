import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/house.dart';
import '../models/pet.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/shop_economy_scope.dart';

/// The tower's economic controls consume public facts and durable commands.
/// Prices are quotes from shared rules; the server checks funds and eligibility.
class CanonicalHouseScreen extends StatelessWidget {
  const CanonicalHouseScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ShopEconomyBoundary(child: _HouseContents());
}

class _HouseContents extends StatelessWidget {
  const _HouseContents();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final house = view.house;
    final s = AppStrings.of(context);
    final actions = CanonicalGameActions(session);
    final wardPrice = house.nextWardPrice;
    final floorPrice = house.nextFloorPrice;
    final level =
        Pet.levelAtXp(view.dragon(view.activeDragonId ?? '')?.xp ?? 0);
    return DefaultTabController(
        length: 2,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(s.pick('Haven', 'Haven'),
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('${view.coins} ${s.pick('coins', 'munten')}',
                        key: const Key('canonical-house-balance'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ])),
          TabBar(tabs: [
            Tab(text: s.pick('Tower', 'Toren')),
            Tab(text: s.pick('Rooms', 'Kamers')),
          ]),
          Expanded(
              child: TabBarView(children: [
            ListView(
                key: const Key('canonical-tower-list'),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                    '${s.pick('Dragon Ward', 'Drakenward')} · ${house.wardLevel}/3',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                if (wardPrice != null) ...[
                                  if (house.damagedFloors.isEmpty)
                                    Text(s.pick(
                                        'Available after a floor is damaged.',
                                        'Beschikbaar wanneer een verdieping beschadigd is.')),
                                  CanonicalActionButton(
                                      key: const Key('canonical-upgrade-ward'),
                                      label:
                                          '${s.pick('Upgrade ward', 'Ward verbeteren')} · $wardPrice',
                                      confirmation:
                                          '${s.pick('Upgrade ward', 'Ward verbeteren')} · $wardPrice ${s.pick('coins', 'munten')}?',
                                      action: session.canAct &&
                                              house.damagedFloors.isNotEmpty &&
                                              view.coins >= wardPrice
                                          ? actions.upgradeWard
                                          : null),
                                ],
                              ]))),
                  const SizedBox(height: 12),
                  Text(
                      '${house.floorRoomIds.length}/20 ${s.pick('floors', 'verdiepingen')}',
                      style: Theme.of(context).textTheme.titleMedium),
                  for (var i = house.floorRoomIds.length - 1; i >= 0; i--)
                    if (houseRoomById(house.floorRoomIds[i]) case final room?)
                      _RoomCard(
                          room: room,
                          heading: '${i + 1} · ${s.roomName(room)}',
                          control: switch (house.repairPrice(i)) {
                            final price? => CanonicalActionButton(
                                key: Key('canonical-repair-$i'),
                                label:
                                    '${s.pick('Repair', 'Repareer')} · $price',
                                confirmation:
                                    '${s.pick('Repair', 'Repareer')} ${i + 1} · ${s.roomName(room)} · $price ${s.pick('coins', 'munten')}?',
                                action: session.canAct && view.coins >= price
                                    ? () => actions.repairFloor(i)
                                    : null),
                            null => null,
                          }),
                  if (floorPrice != null)
                    OutlinedButton(
                        key: const Key('canonical-add-floor'),
                        onPressed: session.canAct && view.coins >= floorPrice
                            ? () => _chooseFloor(context)
                            : null,
                        child: Text(
                            '${s.pick('Add a floor', 'Verdieping toevoegen')} · $floorPrice ${s.pick('coins', 'munten')}',
                            textAlign: TextAlign.center))
                  else
                    Text(s.pick(
                        'Maximum height reached', 'Maximale hoogte bereikt')),
                ]),
            ListView(
                key: const Key('canonical-rooms-list'),
                padding: const EdgeInsets.all(16),
                children: [
                  for (final room in houseRoomCatalog)
                    _RoomCard(
                        room: room,
                        heading: s.roomName(room),
                        control: house.unlockedRooms.contains(room.id)
                            ? CanonicalActionButton(
                                key: Key('canonical-room-${room.id}'),
                                label: s.pick(
                                    house.activeRoomId == room.id
                                        ? 'Selected'
                                        : 'Select',
                                    house.activeRoomId == room.id
                                        ? 'Geselecteerd'
                                        : 'Selecteren'),
                                action: session.canAct &&
                                        house.activeRoomId != room.id
                                    ? () => actions.unlockRoom(room.id)
                                    : null)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    Text(
                                        '${s.pick('Level', 'Level')} ${room.unlockLevel}'),
                                    CanonicalActionButton(
                                        key: Key('canonical-room-${room.id}'),
                                        label:
                                            '${s.pick('Unlock', 'Ontgrendelen')} · ${room.price}',
                                        confirmation:
                                            '${s.pick('Unlock', 'Ontgrendelen')} ${s.roomName(room)} · ${room.price} ${s.pick('coins', 'munten')}?',
                                        action: session.canAct &&
                                                level >= room.unlockLevel &&
                                                view.coins >= room.price
                                            ? () => actions.unlockRoom(room.id)
                                            : null),
                                  ])),
                ]),
          ])),
        ]));
  }

  Future<void> _chooseFloor(BuildContext context) async {
    final session = context.read<CanonicalGameSession>();
    final owner = session.snapshot!.ownerId;
    final epoch = session.connection.sessionEpoch;
    await showDialog<void>(
        context: context,
        builder: (context) => CanonicalEntityDialog(
            ownerId: owner,
            builder: (context, view, canAct) {
              final s = AppStrings.of(context);
              final price = view.house.nextFloorPrice;
              final actions =
                  CanonicalGameActions(context.read<CanonicalGameSession>());
              final sameAccount = epoch ==
                  context.read<CanonicalGameSession>().connection.sessionEpoch;
              return AlertDialog(
                  insetPadding: const EdgeInsets.all(16),
                  title:
                      Text(s.pick('Choose a room type', 'Kies een kamertype')),
                  content: SizedBox(
                      width: 340,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final room
                            in houseRoomCatalog.where((r) => r.id != 'nest'))
                          _RoomCard(
                              room: room,
                              heading: s.roomName(room),
                              control: CanonicalActionButton(
                                  key: Key('canonical-build-${room.id}'),
                                  label:
                                      '${s.pick('Build', 'Bouwen')} · ${price ?? '—'}',
                                  confirmation:
                                      '${s.pick('Build', 'Bouwen')} ${s.roomName(room)} · $price ${s.pick('coins', 'munten')}?',
                                  action: canAct &&
                                          sameAccount &&
                                          price != null &&
                                          view.coins >= price
                                      ? () async {
                                          await actions.buildFloor(room.id);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        }
                                      : null)),
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s.pick('Close', 'Sluiten')))
                  ]);
            }));
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.heading, this.control});
  final HouseRoomDefinition room;
  final String heading;
  final Widget? control;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Image.asset(room.backgroundAsset,
            height: 108, fit: BoxFit.cover, excludeFromSemantics: true),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(heading, style: Theme.of(context).textTheme.titleMedium),
                  if (control != null) ...[const SizedBox(height: 8), control!],
                ])),
      ]));
}
