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
                    padding:
                        EdgeInsets.fromLTRB(16, showHeading ? 16 : 10, 16, 16),
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
                        Flexible(
                            child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          key: const Key('reorder-tower-rooms'),
                                          tooltip: s.pick('Change room order',
                                              'Kamervolgorde wijzigen'),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: house.floorRoomIds.length <
                                                  2
                                              ? null
                                              : () => showCanonicalRoomOrder(
                                                  context),
                                          icon: const Icon(
                                              Icons.swap_vert_rounded)),
                                      Flexible(
                                          child: Text(
                                              '${house.floorRoomIds.length}/20 ${s.pick('floors', 'verdiepingen')}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end)),
                                    ]))),
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
                        ])),
                  ]))),
          if (floorIndex != null && control != null)
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: control!),
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
            final currentRoomId = index < current.house.floorRoomIds.length
                ? current.house.floorRoomIds[index]
                : null;
            final currentRoom =
                currentRoomId == null ? null : houseRoomById(currentRoomId);
            final valid = session.connection.sessionEpoch == epoch &&
                currentRoom != null &&
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
                    d.roomId == currentRoomId)
                .toList();
            return _RoomVisitView(
                title: Text(s.roomName(currentRoom ?? houseRoomById(roomId)!)),
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
                                              currentRoom.backgroundAsset,
                                              fit: BoxFit.cover),
                                          for (final placement in current
                                              .house.placements
                                              .where((p) =>
                                                  p.roomId == currentRoomId))
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
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                  icon: const GameIconSprite(
                                      GameIconKind.roomDecorate,
                                      size: 28),
                                  label: Text(s.pick('Arrange your room',
                                      'Richt je kamer in')),
                                  onPressed: () => openCanonicalRoomEditor(
                                      context, currentRoomId!)),
                              OutlinedButton.icon(
                                  key: Key('canonical-change-floor-$index'),
                                  onPressed: canAct
                                      ? () => _changeFloorRoom(context, index)
                                      : null,
                                  icon: const Icon(Icons.swap_horiz_rounded),
                                  label: Text(s.pick('Change room (free)',
                                      'Kamer wijzigen (gratis)'))),
                            ])),
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
                            ? () => currentActions.callDragonToFloor(
                                currentRoomId!, index)
                            : null),
                  if (valid && current.house.floorRoomIds.length > 1)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: CanonicalActionButton(
                            key: Key('canonical-clear-floor-$index'),
                            label: s.pick('Clear room', 'Kamer leegmaken'),
                            action: canAct
                                ? () => currentActions.clearFloor(index)
                                : null)),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.pick('Close', 'Sluiten')))
                ]);
          }));
  await visitTask;
}

Future<void> _changeFloorRoom(BuildContext context, int index) async {
  final session = context.read<CanonicalGameSession>();
  final owner = session.snapshot!.ownerId;
  final epoch = session.connection.sessionEpoch;
  final strings = AppStrings.of(context);
  final room = await showModalBottomSheet<HouseRoomDefinition>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        key: const Key('tower-room-picker-scroll'),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        children: [
          Text(
            strings.pick('Choose a room type', 'Kies een kamertype'),
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          Text(strings.pick(
            'Change this room as often as you like, for free.',
            'Verander deze kamer zo vaak je wilt, gratis.',
          )),
          const SizedBox(height: 8),
          for (final definition
              in houseRoomCatalog.where((room) => room.id != 'nest'))
            Card(
              child: ListTile(
                key: Key('canonical-convert-${definition.id}'),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    definition.backgroundAsset,
                    width: 58,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  strings.roomName(definition),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(strings.pick(
                  'Unique atmosphere and layout',
                  'Eigen sfeer en indeling',
                )),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, definition),
              ),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted ||
      room == null ||
      session.connection.sessionEpoch != epoch ||
      session.snapshot?.ownerId != owner ||
      index >= (session.snapshot?.house.floorRoomIds.length ?? 0) ||
      !session.canAct) {
    return;
  }
  await runShopAction(context,
      () => CanonicalGameActions(session).changeFloorRoom(index, room.id));
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
