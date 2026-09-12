import 'canonical_dragons_screen.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/ui_bits.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/house.dart';
import '../models/pet.dart';
import 'canonical_room_editor.dart';
import 'canonical_school_screen.dart';
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
          if (house.floorRoomIds.length >= 5)
            TextButton.icon(
                key: const Key('canonical-open-school'),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                            appBar: AppBar(
                                title: Text(s.pick(
                                    'Dragon Academy', 'Drakenacademie'))),
                            body: const CanonicalSchoolScreen()))),
                icon: Image.asset(
                    'assets/images/ui/dragon_school/school_graduate.png',
                    width: 28,
                    height: 28),
                label: Text(s.pick('Dragon Academy', 'Drakenacademie'))),
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
                          extra: Wrap(alignment: WrapAlignment.end, children: [
                            OutlinedButton.icon(
                                key: Key('canonical-visit-floor-$i'),
                                onPressed: house.damagedFloors.contains(i)
                                    ? null
                                    : () => _visitFloor(context, room.id, i),
                                icon: const Icon(Icons.zoom_in),
                                label: Text(s.pick('Visit', 'Bezoeken'))),
                            OutlinedButton.icon(
                                key: Key('canonical-change-floor-$i'),
                                onPressed: session.canAct
                                    ? () => _chooseFloor(context, floorIndex: i)
                                    : null,
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: Text(s.pick('Change room (free)',
                                    'Kamer wijzigen (gratis)'))),
                            IconButton(
                                key: Key('canonical-floor-up-$i'),
                                tooltip:
                                    s.pick('Move up', 'Omhoog verplaatsen'),
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                                onPressed: session.canAct &&
                                        i < house.floorRoomIds.length - 1
                                    ? () => runShopAction(
                                        context,
                                        () => actions.reorderFloor(
                                            house.floorRoomIds.length - i - 1,
                                            house.floorRoomIds.length - i - 2))
                                    : null,
                                icon: const Icon(Icons.arrow_upward_rounded)),
                            IconButton(
                                key: Key('canonical-floor-down-$i'),
                                tooltip:
                                    s.pick('Move down', 'Omlaag verplaatsen'),
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                                onPressed: session.canAct && i > 0
                                    ? () => runShopAction(
                                        context,
                                        () => actions.reorderFloor(
                                            house.floorRoomIds.length - i - 1,
                                            house.floorRoomIds.length - i))
                                    : null,
                                icon: const Icon(Icons.arrow_downward_rounded)),
                            CanonicalActionButton(
                                key: Key('canonical-clear-floor-$i'),
                                label: s.pick('Clear room', 'Kamer leegmaken'),
                                action: session.canAct &&
                                        house.floorRoomIds.length > 1
                                    ? () => actions.clearFloor(i)
                                    : null),
                          ]),
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
                        extra: house.unlockedRooms.contains(room.id)
                            ? OutlinedButton(
                                key: Key('canonical-edit-room-${room.id}'),
                                onPressed: () =>
                                    openCanonicalRoomEditor(context, room.id),
                                child: Text(s.pick(
                                    'Arrange your room', 'Richt je kamer in')))
                            : null,
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

  Future<void> _chooseFloor(BuildContext context, {int? floorIndex}) async {
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
                                  key: Key(floorIndex == null
                                      ? 'canonical-build-${room.id}'
                                      : 'canonical-convert-${room.id}'),
                                  label: floorIndex != null
                                      ? s.pick(
                                          'Choose (free)', 'Kiezen (gratis)')
                                      : '${s.pick('Build', 'Bouwen')} · ${price ?? '—'}',
                                  confirmation: floorIndex != null
                                      ? null
                                      : '${s.pick('Build', 'Bouwen')} ${s.roomName(room)} · $price ${s.pick('coins', 'munten')}?',
                                  action: canAct &&
                                          sameAccount &&
                                          (floorIndex != null
                                              ? floorIndex <
                                                  view.house.floorRoomIds.length
                                              : price != null &&
                                                  view.coins >= price)
                                      ? () async {
                                          if (floorIndex != null) {
                                            await actions.changeFloorRoom(
                                                floorIndex, room.id);
                                          } else {
                                            await actions.buildFloor(room.id);
                                          }
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
  const _RoomCard(
      {required this.room, required this.heading, this.control, this.extra});
  final HouseRoomDefinition room;
  final String heading;
  final Widget? control, extra;
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
                  if (extra != null) extra!,
                  if (control != null) ...[const SizedBox(height: 8), control!],
                ])),
      ]));
}

Future<void> _visitFloor(BuildContext context, String roomId, int index) async {
  final session = context.read<CanonicalGameSession>();
  final view = session.snapshot!;
  final owner = view.ownerId;
  final epoch = session.connection.sessionEpoch;
  final actions = CanonicalGameActions(session);
  // Opening a room rolls once. Rebuilds, scrolling and reconnecting the dialog
  // cannot repeatedly roll the cosmetic interaction.
  Future<void> visit() async {
    if (!session.canAct) return;
    try {
      final event = await actions.visitFloor(roomId, index);
      if (!context.mounted ||
          event == null ||
          session.connection.sessionEpoch != epoch ||
          session.snapshot?.ownerId != owner) {
        return;
      }
      final dragon = session.snapshot!.dragon(event.dragonId);
      if (dragon == null) return;
      final s = AppStrings.of(context);
      showAppSnackBar(
          context,
          s
              .pick(event.interaction.messageEn, event.interaction.messageNl)
              .replaceAll('{dragon}', canonicalDragonName(s, dragon)));
    } on CanonicalGameException catch (error) {
      if (context.mounted && session.connection.sessionEpoch == epoch) {
        showAppSnackBar(
            context, gameConnectionMessage(AppStrings.of(context), error.code));
      }
    }
  }

  final visitTask = visit();
  await showDialog<void>(
      context: context,
      builder: (context) => CanonicalEntityDialog(
          ownerId: owner,
          builder: (context, current, canAct) {
            final s = AppStrings.of(context);
            final currentActions = CanonicalGameActions(session);
            final valid = index < current.house.floorRoomIds.length &&
                current.house.floorRoomIds[index] == roomId &&
                !current.house.damagedFloors.contains(index);
            final dragon = current.dragons
                    .where((d) => d.owned && d.favorite)
                    .firstOrNull ??
                current.dragon(current.activeDragonId ?? '');
            final residents = current.dragons
                .where((d) =>
                    d.owned &&
                    d.roamsTower &&
                    d.adventureId == null &&
                    d.floorIndex == index &&
                    d.roomId == roomId)
                .toList();
            return AlertDialog(
                title: Text(s.roomName(houseRoomById(roomId)!)),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (valid)
                    for (final resident in residents)
                      Column(children: [
                        CanonicalDragonArt(dragon: resident, height: 100),
                        Text(canonicalDragonName(s, resident)),
                      ]),
                  if (valid && residents.isEmpty)
                    Text(s.pick('No dragons here', 'Geen draken hier')),
                  if (!valid)
                    Text(s.pick('This room is unavailable.',
                        'Deze kamer is niet beschikbaar.')),
                  if (valid &&
                      dragon != null &&
                      dragon.roamsTower &&
                      dragon.adventureId == null &&
                      dragon.floorIndex != index &&
                      residents.length < towerFloorDragonCapacity)
                    CanonicalActionButton(
                        key: const Key('canonical-call-dragon'),
                        label: s.pick('Call dragon', 'Draak roepen'),
                        action: canAct
                            ? () =>
                                currentActions.callDragonToFloor(roomId, index)
                            : null),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.pick('Close', 'Sluiten')))
                ]);
          }));
  await visitTask;
}
