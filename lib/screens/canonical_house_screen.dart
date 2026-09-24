import 'dart:async';
import 'dart:math';

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
import '../models/day_phase.dart';
import '../models/house.dart';
import '../models/pet.dart';
import 'canonical_room_editor.dart';
import 'canonical_school_screen.dart';
import '../services/audio_service.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/house_room_scene.dart';
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
            !view.house.temporarilyAwayDragonIds.contains(d.id) &&
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
  await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _CanonicalFloorRoomScreen(
            floorIndex: index,
            openedRoomId: roomId,
            ownerId: view.ownerId,
            sessionEpoch: session.connection.sessionEpoch,
          )));
}

class _CanonicalFloorRoomScreen extends StatefulWidget {
  const _CanonicalFloorRoomScreen({
    required this.floorIndex,
    required this.openedRoomId,
    required this.ownerId,
    required this.sessionEpoch,
  });

  final int floorIndex;
  final String openedRoomId;
  final String ownerId;
  final int sessionEpoch;

  @override
  State<_CanonicalFloorRoomScreen> createState() =>
      _CanonicalFloorRoomScreenState();
}

class _CanonicalFloorRoomScreenState extends State<_CanonicalFloorRoomScreen> {
  static const _wanderMoveDuration = houseRoomWanderMoveDuration;
  static const _calledMoveDuration = Duration(milliseconds: 5200);

  final _random = Random();
  Timer? _wanderTimer;
  Offset _dragonPosition = const Offset(.24, .76);
  Duration _dragonMoveDuration = _wanderMoveDuration;
  bool _facingRight = true;
  int _wanderStep = 0;
  bool _callingDragon = false;
  bool _visitStarted = false;
  String? _displayedRoomId;
  String? _interactionRoomId;
  String? _interactionMessage;

  @override
  void initState() {
    super.initState();
    unawaited(HavenAudio.setMusicScene(HavenMusicScene.room));
    _startWandering();
    WidgetsBinding.instance.addPostFrameCallback((_) => _visitOnce());
  }

  @override
  void dispose() {
    _wanderTimer?.cancel();
    final hour = DateTime.now().hour;
    unawaited(HavenAudio.setMusicScene(hour >= 21 || hour < 7
        ? HavenMusicScene.towerNight
        : HavenMusicScene.towerDay));
    super.dispose();
  }

  bool _sameSession(CanonicalGameSession session) =>
      session.connection.sessionEpoch == widget.sessionEpoch &&
      session.snapshot?.ownerId == widget.ownerId;

  void _startWandering() {
    _wanderTimer?.cancel();
    _wanderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final session = context.read<CanonicalGameSession>();
      final view = session.snapshot;
      if (view == null || !_sameSession(session)) return;
      final roomId = widget.floorIndex < view.house.floorRoomIds.length
          ? view.house.floorRoomIds[widget.floorIndex]
          : null;
      if (_interactionMessage != null && _interactionRoomId == roomId) return;
      final phase = havenDayPhaseAt(DateTime.now());
      final moveChance = switch (phase) {
        HavenDayPhase.deepNight => .12,
        HavenDayPhase.night => .20,
        HavenDayPhase.dusk => .45,
        HavenDayPhase.dawn => .60,
        HavenDayPhase.morning => .82,
        HavenDayPhase.day || HavenDayPhase.goldenHour => .95,
      };
      if (_random.nextDouble() > moveChance) return;
      final dragon = _controllableDragon(view);
      setState(() => _wanderStep++);
      if (dragon == null ||
          dragon.adventureId != null ||
          dragon.floorIndex != widget.floorIndex) {
        return;
      }
      _moveDragonTo(
          Offset(.14 + _random.nextDouble() * .72,
              .60 + _random.nextDouble() * .23),
          duration: _wanderMoveDuration);
    });
  }

  void _moveDragonTo(Offset target, {Duration duration = _wanderMoveDuration}) {
    if (!mounted) return;
    setState(() {
      _facingRight = target.dx >= _dragonPosition.dx;
      _dragonMoveDuration = duration;
      _dragonPosition = Offset(target.dx.clamp(.14, .86).toDouble(),
          target.dy.clamp(.56, .84).toDouble());
    });
  }

  Future<void> _visitOnce() async {
    if (_visitStarted || !mounted) return;
    _visitStarted = true;
    final session = context.read<CanonicalGameSession>();
    if (!session.canAct || !_sameSession(session)) return;
    try {
      final event = await CanonicalGameActions(session)
          .visitFloor(widget.openedRoomId, widget.floorIndex);
      if (!mounted || event == null || !_sameSession(session)) return;
      final dragon = session.snapshot?.dragon(event.dragonId);
      if (dragon == null) return;
      final strings = AppStrings.of(context);
      setState(() {
        _interactionRoomId = widget.openedRoomId;
        _interactionMessage = strings
            .pick(event.interaction.messageEn, event.interaction.messageNl)
            .replaceAll('{dragon}', canonicalDragonName(strings, dragon));
      });
    } on CanonicalGameException catch (error) {
      if (mounted && _sameSession(session)) {
        showAppSnackBar(
            context, gameConnectionMessage(AppStrings.of(context), error.code));
      }
    }
  }

  CanonicalDragonView? _controllableDragon(CanonicalGameSnapshot view) =>
      view.dragons.where((d) => d.owned && d.favorite).firstOrNull ??
      view.dragon(view.activeDragonId ?? '');

  Future<void> _handleRoomTap(Offset position) async {
    final session = context.read<CanonicalGameSession>();
    final view = session.snapshot;
    if (view == null || !_sameSession(session)) return;
    final roomId = widget.floorIndex < view.house.floorRoomIds.length
        ? view.house.floorRoomIds[widget.floorIndex]
        : null;
    final dragon = _controllableDragon(view);
    if (roomId == null || dragon == null) return;
    final here = dragon.roamsTower &&
        !view.house.temporarilyAwayDragonIds.contains(dragon.id) &&
        dragon.adventureId == null &&
        dragon.floorIndex == widget.floorIndex &&
        dragon.roomId == roomId;
    if (here) {
      _moveDragonTo(position, duration: _calledMoveDuration);
      return;
    }
    final occupancy = view.dragons.where((d) =>
        d.floorIndex == widget.floorIndex &&
        !view.house.temporarilyAwayDragonIds.contains(d.id) &&
        ((d.owned && d.roamsTower) ||
            view.house.returningVisitorIds.contains(d.id)));
    if (_callingDragon ||
        !session.canAct ||
        !dragon.roamsTower ||
        view.house.temporarilyAwayDragonIds.contains(dragon.id) ||
        dragon.adventureId != null ||
        view.house.damagedFloors.contains(widget.floorIndex) ||
        occupancy.length >= towerFloorDragonCapacity) {
      return;
    }
    _callingDragon = true;
    setState(() {
      _dragonPosition = const Offset(.24, .76);
      _dragonMoveDuration = Duration.zero;
      _facingRight = position.dx >= .24;
    });
    try {
      final pending = CanonicalGameActions(session)
          .callDragonToFloor(roomId, widget.floorIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sameSession(session)) {
          _moveDragonTo(position, duration: _calledMoveDuration);
        }
      });
      await pending;
    } on CanonicalGameException catch (error) {
      if (mounted && _sameSession(session)) {
        setState(() {
          _dragonPosition = const Offset(.24, .76);
          _dragonMoveDuration = Duration.zero;
        });
        showAppSnackBar(
            context, gameConnectionMessage(AppStrings.of(context), error.code));
      }
    } finally {
      _callingDragon = false;
    }
  }

  Future<void> _clearRoom() async {
    final session = context.read<CanonicalGameSession>();
    if (!_sameSession(session)) return;
    await runShopAction(context,
        () => CanonicalGameActions(session).clearFloor(widget.floorIndex));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot;
    final strings = AppStrings.of(context);
    final sameSession = view != null && _sameSession(session);
    final roomId = view != null &&
            sameSession &&
            widget.floorIndex < view.house.floorRoomIds.length
        ? view.house.floorRoomIds[widget.floorIndex]
        : null;
    final room = roomId == null ? null : houseRoomById(roomId);
    final valid = view != null &&
        sameSession &&
        room != null &&
        !view.house.damagedFloors.contains(widget.floorIndex);

    return Scaffold(
      key: Key('canonical-floor-room-screen-${widget.floorIndex}'),
      appBar: AppBar(
        leadingWidth: 66,
        leading: IconButton(
          key: const Key('zoom-out-room'),
          tooltip: strings.pick('Zoom out', 'Uitzoomen'),
          onPressed: () => Navigator.maybePop(context),
          icon: const GameIconSprite(GameIconKind.roomZoomOut, size: 48),
        ),
        title: Text(room == null
            ? strings.pick('Tower room', 'Torenkamer')
            : strings.roomName(room)),
      ),
      body: !sameSession
          ? Center(
              child:
                  Text(gameConnectionMessage(strings, 'game_account_changed')))
          : !valid
              ? Center(
                  child: Text(strings.pick('This room is unavailable.',
                      'Deze kamer is niet beschikbaar.')))
              : _roomContents(context, view, room),
    );
  }

  Widget _roomContents(BuildContext context, CanonicalGameSnapshot view,
      HouseRoomDefinition room) {
    if (_displayedRoomId != room.id) {
      final changedRoom = _displayedRoomId != null;
      _displayedRoomId = room.id;
      if (changedRoom && _interactionMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _displayedRoomId != room.id) return;
          setState(() {
            _interactionRoomId = null;
            _interactionMessage = null;
          });
        });
      }
    }
    final strings = AppStrings.of(context);
    final session = context.read<CanonicalGameSession>();
    final visitorIds = view.house.returningVisitorIds;
    final residents = view.dragons
        .where((d) =>
            d.adventureId == null &&
            !view.house.temporarilyAwayDragonIds.contains(d.id) &&
            d.floorIndex == widget.floorIndex &&
            d.roomId == room.id &&
            ((d.owned && d.roamsTower) || visitorIds.contains(d.id)))
        .take(towerFloorDragonCapacity)
        .toList(growable: false);
    final controllable = _controllableDragon(view);
    final visuals = [
      for (final dragon in residents)
        RoomDragonVisual(
          id: dragon.id,
          stageKey: dragon.stageKey,
          lineageId: dragon.lineageId,
          evolutionPath: dragon.activeEvolutionPath,
          prismatic: dragon.prismatic,
          sinister: dragon.sinister,
          stage: dragon.stage,
          visualSeed: _stableRoomSeed(dragon.id),
          sizeFactor: dragon.sizeFactor,
        ),
    ];
    final placements = view.house.placements
        .where((placement) => placement.roomId == room.id)
        .toList(growable: false);
    final interactionMessage =
        _interactionRoomId == room.id ? _interactionMessage : null;

    return ListView(
      key: const PageStorageKey('canonical-floor-room-scroll'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(strings.pick('Dragon sanctuary', 'Drakenreservaat'),
              style: Theme.of(context).textTheme.displaySmall),
        ),
        const SizedBox(height: 5),
        Text(
          strings.pick('Build a home that grows with your dragon.',
              'Bouw een thuis dat met jullie draak meegroeit.'),
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 13),
        HouseRoomScene(
          room: room,
          dragons: visuals,
          visitorIds: visitorIds,
          suppressTimeMood: interactionMessage != null,
          activeDragonId: controllable?.id ?? '',
          placements: placements,
          editMode: false,
          selectedItemId: null,
          dragonPosition: _dragonPosition,
          dragonMoveDuration: _dragonMoveDuration,
          facingRight: _facingRight,
          wanderStep: _wanderStep,
          onSelectItem: (_) {},
          onRoomTap: _handleRoomTap,
        ),
        if (interactionMessage case final message?) ...[
          const SizedBox(height: 10),
          Card(
            color: AppColors.goldLight,
            child: ListTile(
              leading: Icon(Icons.auto_awesome_rounded,
                  color: AppColors.eventColor(context, AppColors.twilight)),
              title: Text(strings.pick(
                  'A rare Tower moment', 'Een zeldzaam torenmoment')),
              subtitle: Text(message),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: RoomActionButton(
              key: Key('canonical-edit-floor-${widget.floorIndex}'),
              onPressed: session.canAct
                  ? () => openCanonicalRoomEditor(context, room.id)
                  : null,
              kind: GameIconKind.roomDecorate,
              filled: true,
              label: strings.pick('Decorate', 'Inrichten'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RoomActionButton(
              key: Key('canonical-change-floor-${widget.floorIndex}'),
              onPressed: session.canAct
                  ? () => _changeFloorRoom(context, widget.floorIndex)
                  : null,
              kind: GameIconKind.towerBuild,
              label: strings.pick('Change type', 'Type wijzigen'),
            ),
          ),
        ]),
        const SizedBox(height: 9),
        RoomActionButton(
          key: Key('canonical-clear-floor-${widget.floorIndex}'),
          onPressed: session.canAct ? () => unawaited(_clearRoom()) : null,
          kind: GameIconKind.roomClear,
          label: strings.pick('Clear dragons', 'Draken verplaatsen'),
        ),
      ],
    );
  }
}

int _stableRoomSeed(String id) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
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
