import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/house.dart';
import '../models/shop_item.dart';
import '../services/canonical_game_actions.dart';
import '../services/canonical_game_session.dart';
import '../widgets/canonical_game_controls.dart';
import '../widgets/furniture_art.dart';
import '../widgets/shop_economy_scope.dart';

/// The editor keeps only a selection locally. Every placement goes through the
/// durable account/revision-fenced command lane, never a second house save.
void openCanonicalRoomEditor(BuildContext context, String roomId) {
  final session = context.read<CanonicalGameSession>();
  final owner = session.snapshot?.ownerId;
  if (owner == null) return;
  final epoch = session.connection.sessionEpoch;
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => Scaffold(
            appBar: AppBar(
                title: Text(AppStrings.of(context)
                    .pick('Arrange your room', 'Richt je kamer in'))),
            body: ShopEconomyBoundary(
                child: _Editor(roomId: roomId, owner: owner, epoch: epoch)),
          )));
}

class _Editor extends StatefulWidget {
  const _Editor(
      {required this.roomId, required this.owner, required this.epoch});
  final String roomId, owner;
  final int epoch;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  String? selectedId;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CanonicalGameSession>();
    final view = session.snapshot!;
    final s = AppStrings.of(context);
    if (view.ownerId != widget.owner ||
        session.connection.sessionEpoch != widget.epoch) {
      return Center(
          child: Text(gameConnectionMessage(s, 'game_account_changed')));
    }
    final room = houseRoomById(widget.roomId);
    if (room == null || !view.house.unlockedRooms.contains(room.id)) {
      return Center(
          child: Text(gameConnectionMessage(s, 'game_action_unavailable')));
    }
    final actions = CanonicalGameActions(session);
    final enabled = session.canAct && !busy;
    final selected = selectedId == null ? null : shopItemById(selectedId!);
    final placements = view.house.placements.where((p) => p.roomId == room.id);
    final items =
        allFurnitureCatalog.where((i) => view.shop.ownedItems.contains(i.id));
    return ListView(
        key: const Key('canonical-room-editor-list'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.roomName(room), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AspectRatio(
              aspectRatio: 1.25,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                      builder: (context, box) => GestureDetector(
                          key: const Key('canonical-room-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onTapUp: enabled && selected != null
                              ? (details) async {
                                  final x =
                                      (details.localPosition.dx / box.maxWidth)
                                          .clamp(.08, .92)
                                          .toDouble();
                                  final y =
                                      (details.localPosition.dy / box.maxHeight)
                                          .clamp(
                                              selected.slot == ItemSlot.wall ||
                                                      selected.slot ==
                                                          ItemSlot.light
                                                  ? room.wallMinY
                                                  : room.floorMinY,
                                              selected.slot == ItemSlot.wall ||
                                                      selected.slot ==
                                                          ItemSlot.light
                                                  ? room.wallMaxY
                                                  : room.floorMaxY)
                                          .toDouble();
                                  setState(() => busy = true);
                                  try {
                                    await runShopAction(
                                        context,
                                        () => actions.placeHouseItem(
                                            selected.id, room.id, x, y));
                                  } finally {
                                    if (mounted) setState(() => busy = false);
                                  }
                                }
                              : null,
                          child: Stack(fit: StackFit.expand, children: [
                            Image.asset(room.backgroundAsset,
                                fit: BoxFit.cover, excludeFromSemantics: true),
                            for (final placement in placements)
                              if (shopItemById(placement.itemId) case final item?)
                                Positioned(
                                    left: (placement.x * box.maxWidth - 36 * placement.scale)
                                        .clamp(0,
                                            box.maxWidth - 72 * placement.scale)
                                        .toDouble(),
                                    top: (placement.y * box.maxHeight -
                                            36 * placement.scale)
                                        .clamp(
                                            0,
                                            box.maxHeight -
                                                72 * placement.scale)
                                        .toDouble(),
                                    width: 72 * placement.scale,
                                    height: 72 * placement.scale,
                                    child: IgnorePointer(
                                        child: DecoratedBox(
                                            key: Key(
                                                'canonical-placement-${item.id}'),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: selectedId == item.id
                                                    ? Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        width: 2)
                                                    : null),
                                            child: FurnitureArt(item: item)))),
                          ]))))),
          const SizedBox(height: 12),
          Text(s.pick('Select an item, then tap the room to place it.',
              'Selecteer een meubel en tik in de kamer om het te plaatsen.')),
          if (selected != null) ...[
            const SizedBox(height: 8),
            Text(s.itemName(selected),
                style: Theme.of(context).textTheme.titleMedium),
            CanonicalActionButton(
                key: const Key('canonical-remove-furniture'),
                label: s.pick('Put away', 'Opbergen'),
                action: enabled && view.shop.placedItems.contains(selected.id)
                    ? () => actions.removeHouseItem(selected.id)
                    : null),
          ],
          const SizedBox(height: 12),
          for (final item in items)
            Card(
                child: ListTile(
                    key: Key('canonical-select-furniture-${item.id}'),
                    selected: selectedId == item.id,
                    leading: SizedBox(
                        width: 48, height: 48, child: FurnitureArt(item: item)),
                    title: Text(s.itemName(item)),
                    trailing: selectedId == item.id
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    onTap: enabled
                        ? () => setState(() => selectedId = item.id)
                        : null)),
          if (items.isEmpty)
            Text(s.pick('No furniture yet', 'Nog geen meubels')),
        ]);
  }
}
