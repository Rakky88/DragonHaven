import '../widgets/restored_collection_cards.dart';
import 'canonical_dragons_screen.dart';
import '../services/canonical_game_snapshot.dart';
import '../widgets/ui_bits.dart';
import '../widgets/haven_lighting.dart';
import '../widgets/game_icon_sprite.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/house.dart';
import '../models/shop_item.dart';
import '../widgets/furniture_art.dart';
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
  const CanonicalHouseScreen(
      {super.key, this.header, this.toolbar, this.showHeading = true});
  final Widget? header, toolbar;
  final bool showHeading;
  @override
  Widget build(BuildContext context) => ShopEconomyBoundary(
      child: _HouseContents(
          header: header, toolbar: toolbar, showHeading: showHeading));
}

class _HouseContents extends StatelessWidget {
  const _HouseContents({this.header, this.toolbar, required this.showHeading});
  final Widget? header, toolbar;
  final bool showHeading;
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
          if (showHeading)
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
          if (showHeading)
            TabBar(tabs: [
              Tab(text: s.pick('Tower', 'Toren')),
              Tab(text: s.pick('Rooms', 'Kamers')),
            ]),
          Expanded(
              child: TabBarView(
                  physics:
                      showHeading ? null : const NeverScrollableScrollPhysics(),
                  children: [
                ListView(
                    key: const Key('canonical-tower-list'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (toolbar != null) toolbar!,
                      Row(children: [
                        const GameIconSprite(GameIconKind.clock, size: 21),
                        const SizedBox(width: 5),
                        Expanded(
                            child: HavenClockBuilder(
                                builder: (_, __, phase) => Text(
                                    s.dayPhase(phase),
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700)))),
                        IconButton(
                            key: const Key('reorder-tower-rooms'),
                            tooltip: s.pick(
                                'Change room order', 'Kamervolgorde wijzigen'),
                            visualDensity: VisualDensity.compact,
                            onPressed: house.floorRoomIds.length < 2
                                ? null
                                : () => showCanonicalRoomOrder(context),
                            icon: const Icon(Icons.swap_vert_rounded)),
                        Text(
                            '${house.floorRoomIds.length}/20 ${s.pick('floors', 'verdiepingen')}',
                            textAlign: TextAlign.end),
                      ]),
                      const SizedBox(height: 10),
                      if (header != null) header!,
                      if (showHeading ||
                          house.damagedFloors.isNotEmpty ||
                          house.wardLevel > 0)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                            key: const Key(
                                                'canonical-upgrade-ward'),
                                            label:
                                                '${s.pick('Upgrade ward', 'Ward verbeteren')} · $wardPrice',
                                            confirmation:
                                                '${s.pick('Upgrade ward', 'Ward verbeteren')} · $wardPrice ${s.pick('coins', 'munten')}?',
                                            action: session.canAct &&
                                                    house.damagedFloors
                                                        .isNotEmpty &&
                                                    view.coins >= wardPrice
                                                ? actions.upgradeWard
                                                : null),
                                      ],
                                    ]))),
                      const SizedBox(height: 12),
                      for (var i = house.floorRoomIds.length - 1; i >= 0; i--)
                        if (houseRoomById(house.floorRoomIds[i])
                            case final room?)
                          _RoomCard(
                              room: room,
                              floorIndex: i,
                              heading: '${i + 1} · ${s.roomName(room)}',
                              extra: _floorControls(context, i),
                              control: _floorRepair(context, i)),
                      if (floorPrice != null)
                        OutlinedButton(
                            key: const Key('canonical-add-floor'),
                            onPressed:
                                session.canAct && view.coins >= floorPrice
                                    ? () => _chooseFloor(context)
                                    : null,
                            child: Text(
                                '${s.pick('Add a floor', 'Verdieping toevoegen')} · $floorPrice ${s.pick('coins', 'munten')}',
                                textAlign: TextAlign.center))
                      else
                        Text(s.pick('Maximum height reached',
                            'Maximale hoogte bereikt')),
                      const SizedBox(height: 12),
                      RestoredAcademyEntrance(
                          key: const Key('tutorial-dragon-school-title'),
                          unlocked: house.floorRoomIds.length >= 5,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => Scaffold(
                                      appBar: AppBar(
                                          title: Text(s.pick('Dragon Academy',
                                              'Drakenacademie'))),
                                      body: const CanonicalSchoolScreen())))),
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
                                    onPressed: () => openCanonicalRoomEditor(
                                        context, room.id),
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
                                            key: Key(
                                                'canonical-room-${room.id}'),
                                            label:
                                                '${s.pick('Unlock', 'Ontgrendelen')} · ${room.price}',
                                            confirmation:
                                                '${s.pick('Unlock', 'Ontgrendelen')} ${s.roomName(room)} · ${room.price} ${s.pick('coins', 'munten')}?',
                                            action: session.canAct &&
                                                    level >= room.unlockLevel &&
                                                    view.coins >= room.price
                                                ? () =>
                                                    actions.unlockRoom(room.id)
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
      {required this.room,
      required this.heading,
      this.control,
      this.extra,
      this.floorIndex});
  final HouseRoomDefinition room;
  final int? floorIndex;
  final String heading;
  final Widget? control, extra;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final epoch = session.connection.sessionEpoch;
    final residents = view.dragons
        .where((d) =>
            d.owned &&
            d.roamsTower &&
            d.adventureId == null &&
            d.floorIndex == floorIndex)
        .take(3);
    return Card(
        margin: const EdgeInsets.only(bottom: 7),
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
              key: floorIndex == null
                  ? null
                  : Key('canonical-visit-floor-$floorIndex'),
              onTap: floorIndex == null ||
                      view.house.damagedFloors.contains(floorIndex)
                  ? null
                  : () => _visitFloor(context, room.id, floorIndex!),
              child: SizedBox(
                  height: floorIndex == null ? 130 : 92,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(room.backgroundAsset,
                        fit: BoxFit.cover, excludeFromSemantics: true),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                      Color(0xB5201C3F),
                      Color(0x18201C3F)
                    ]))),
                    Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(children: [
                          if (floorIndex != null) ...[
                            CircleAvatar(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.twilight,
                                child: Text('${floorIndex! + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900))),
                            const SizedBox(width: 11),
                          ],
                          Expanded(
                              child: Text(AppStrings.of(context).roomName(room),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          if (residents.isNotEmpty)
                            SizedBox(
                                width: 36 + (residents.length - 1) * 18,
                                height: 56,
                                child: Stack(children: [
                                  for (final (index, dragon)
                                      in residents.indexed)
                                    Positioned(
                                        left: index * 18,
                                        top: index.isOdd ? 3 : 0,
                                        child: Container(
                                            width: 36,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: const Color(0xD9FFF9ED),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: const Color(
                                                        0xFFFFD86B))),
                                            child: CanonicalDragonArt(
                                                dragon: dragon, height: 46)))
                                ])),
                          if (floorIndex != null)
                            IconButton.filledTonal(
                                key: Key('canonical-floor-options-$floorIndex'),
                                tooltip: AppStrings.of(context)
                                    .pick('Room options', 'Kameropties'),
                                icon: const Icon(Icons.swap_horiz_rounded),
                                onPressed: () => showModalBottomSheet<void>(
                                    context: context,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (_) => CanonicalEntityDialog(
                                        ownerId: view.ownerId,
                                        builder: (context, current, canAct) =>
                                            SingleChildScrollView(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(heading,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleLarge),
                                                      if (session.connection.sessionEpoch ==
                                                              epoch &&
                                                          floorIndex! <
                                                              current
                                                                  .house
                                                                  .floorRoomIds
                                                                  .length &&
                                                          current.house
                                                                      .floorRoomIds[
                                                                  floorIndex!] ==
                                                              room.id) ...[
                                                        _floorControls(context,
                                                            floorIndex!),
                                                        if (_floorRepair(
                                                                context,
                                                                floorIndex!)
                                                            case final repair?)
                                                          repair,
                                                      ],
                                                      TextButton(
                                                          key: const Key(
                                                              'close-floor-options'),
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: Text(AppStrings
                                                                  .of(context)
                                                              .pick('Close',
                                                                  'Sluiten'))),
                                                    ]))))),
                          Icon(
                              view.house.damagedFloors.contains(floorIndex)
                                  ? Icons.construction_rounded
                                  : Icons.zoom_in_rounded,
                              color: Colors.white),
                        ])),
                  ]))),
          if (floorIndex == null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(heading,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (extra != null) extra!,
                      if (control != null) control!,
                    ])),
        ]));
  }
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
            return _RoomVisitView(
                title: Text(s.roomName(houseRoomById(roomId)!)),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (valid)
                    SizedBox(
                        width: 420,
                        child: AspectRatio(
                            aspectRatio: 1.25,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LayoutBuilder(
                                    builder: (context, box) =>
                                        Stack(fit: StackFit.expand, children: [
                                          Image.asset(
                                              houseRoomById(roomId)!
                                                  .backgroundAsset,
                                              fit: BoxFit.cover),
                                          for (final placement in current
                                              .house.placements
                                              .where((p) => p.roomId == roomId))
                                            if (shopItemById(placement.itemId)
                                                case final item?)
                                              Positioned(
                                                  left: placement.x *
                                                          box.maxWidth -
                                                      30,
                                                  top: placement.y *
                                                          box.maxHeight -
                                                      30,
                                                  width: 60,
                                                  height: 60,
                                                  child:
                                                      FurnitureArt(item: item)),
                                          for (final (i, resident)
                                              in residents.indexed)
                                            Positioned(
                                                left: 10 + i * box.maxWidth / 3,
                                                bottom: 10,
                                                width: box.maxWidth / 3,
                                                child: InkWell(
                                                    onTap: () =>
                                                        showCanonicalDragonDetails(
                                                            context,
                                                            resident.id),
                                                    child: CanonicalDragonArt(
                                                        dragon: resident,
                                                        height: 90))),
                                        ]))))),
                  if (valid)
                    TextButton.icon(
                        icon: const GameIconSprite(GameIconKind.roomDecorate,
                            size: 28),
                        label: Text(
                            s.pick('Arrange your room', 'Richt je kamer in')),
                        onPressed: () =>
                            openCanonicalRoomEditor(context, roomId)),
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

Widget _floorControls(BuildContext context, int i) {
  final session = context.watch<CanonicalGameSession>();
  final view = session.snapshot!;
  final house = view.house;
  final s = AppStrings.of(context);
  final actions = CanonicalGameActions(session);
  final room = houseRoomById(house.floorRoomIds[i])!;
  return Wrap(alignment: WrapAlignment.end, children: [
    OutlinedButton.icon(
        key: Key('canonical-visit-floor-option-$i'),
        onPressed: house.damagedFloors.contains(i)
            ? null
            : () => _visitFloor(context, room.id, i),
        icon: const Icon(Icons.zoom_in),
        label: Text(s.pick('Visit', 'Bezoeken'))),
    OutlinedButton.icon(
        key: Key('canonical-change-floor-$i'),
        onPressed: session.canAct
            ? () => const _HouseContents(showHeading: true)
                ._chooseFloor(context, floorIndex: i)
            : null,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: Text(s.pick('Change room (free)', 'Kamer wijzigen (gratis)'))),
    IconButton(
        key: Key('canonical-floor-up-$i'),
        tooltip: s.pick('Move up', 'Omhoog verplaatsen'),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: session.canAct && i < house.floorRoomIds.length - 1
            ? () => runShopAction(
                context,
                () => actions.reorderFloor(house.floorRoomIds.length - i - 1,
                    house.floorRoomIds.length - i - 2))
            : null,
        icon: const Icon(Icons.arrow_upward_rounded)),
    IconButton(
        key: Key('canonical-floor-down-$i'),
        tooltip: s.pick('Move down', 'Omlaag verplaatsen'),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: session.canAct && i > 0
            ? () => runShopAction(
                context,
                () => actions.reorderFloor(house.floorRoomIds.length - i - 1,
                    house.floorRoomIds.length - i))
            : null,
        icon: const Icon(Icons.arrow_downward_rounded)),
    CanonicalActionButton(
        key: Key('canonical-clear-floor-$i'),
        label: s.pick('Clear room', 'Kamer leegmaken'),
        action: session.canAct && house.floorRoomIds.length > 1
            ? () => actions.clearFloor(i)
            : null),
  ]);
}

Widget? _floorRepair(BuildContext context, int i) {
  final session = context.watch<CanonicalGameSession>();
  final view = session.snapshot!;
  final house = view.house;
  final s = AppStrings.of(context);
  final actions = CanonicalGameActions(session);
  final room = houseRoomById(house.floorRoomIds[i])!;
  return switch (house.repairPrice(i)) {
    final price? => CanonicalActionButton(
        key: Key('canonical-repair-$i'),
        label: '${s.pick('Repair', 'Repareer')} · $price',
        confirmation:
            '${s.pick('Repair', 'Repareer')} ${i + 1} · ${s.roomName(room)} · $price ${s.pick('coins', 'munten')}?',
        action: session.canAct && view.coins >= price
            ? () => actions.repairFloor(i)
            : null),
    null => null,
  };
}

class _RoomVisitView extends StatelessWidget {
  const _RoomVisitView(
      {required this.title, required this.content, required this.actions});
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
      child: Scaffold(
          appBar: AppBar(title: title, actions: actions),
          body: SizedBox(width: double.infinity, child: content)));
}

Future<void> showCanonicalRoomOrder(BuildContext context) async {
  final strings = AppStrings.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: .82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.pick('Arrange your Tower', 'Richt je Toren in'),
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                strings.pick(
                  'Drag the rooms into your preferred top-to-bottom order.',
                  'Sleep de kamers naar de gewenste volgorde van boven naar beneden.',
                ),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Container(
                key: const Key('fixed-rooftop-room'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x55D39B29)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        houseRoomCatalog.first.backgroundAsset,
                        width: 62,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.pick('Rooftop Nest', 'Daknest'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            strings.pick(
                              'Fixed at the top',
                              'Blijft altijd bovenaan',
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_rounded, color: Color(0xFF9A6A00)),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Expanded(
                child: Consumer<CanonicalGameSession>(
                  builder: (context, game, _) {
                    final rooms =
                        game.snapshot!.house.floorRoomIds.reversed.toList();
                    return ReorderableListView.builder(
                      key: const Key('tower-room-order-list'),
                      buildDefaultDragHandles: false,
                      itemCount: rooms.length,
                      onReorderItem: (oldIndex, newIndex) async {
                        if (!game.canAct) return;
                        await runShopAction(
                            context,
                            () => CanonicalGameActions(game)
                                .reorderFloor(oldIndex, newIndex));
                      },
                      itemBuilder: (context, visualIndex) {
                        final room = houseRoomById(rooms[visualIndex]) ??
                            houseRoomCatalog[1];
                        return Card(
                          key: ValueKey(
                              'tower-room-order-${room.id}-$visualIndex'),
                          margin: const EdgeInsets.only(bottom: 7),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(
                                room.backgroundAsset,
                                width: 56,
                                height: 45,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              strings.roomName(room),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              strings.pick(
                                'Position ${visualIndex + 1} below the nest',
                                'Positie ${visualIndex + 1} onder het nest',
                              ),
                            ),
                            trailing: ReorderableDragStartListener(
                              index: visualIndex,
                              enabled: game.canAct,
                              child: Semantics(
                                label: strings.pick('Drag room', 'Sleep kamer'),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(Icons.drag_handle_rounded),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
