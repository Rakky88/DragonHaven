import 'economy_chest_intent_store.dart';
import 'economy_inventory_snapshot.dart';
import 'economy_snapshot_store.dart';
import 'server_economy_repository.dart';

/// Retried server receipts are historical facts; only a fresh complete snapshot
/// may replace the player's displayed balances and inventory.
class EconomyChestReconciler {
  EconomyChestReconciler(
      {required this.intents,
      required this.snapshots,
      required this.reader,
      required this.currentOwner,
      required this.open,
      required this.applyToGame});

  final EconomyChestIntentStore intents;
  final EconomySnapshotStore snapshots;
  final EconomyInventoryReader reader;
  final String? Function() currentOwner;
  final Future<ChestOpeningReceipt> Function(EconomyChestIntent) open;

  /// Must check the owner and persist the complete game projection before return.
  final Future<void> Function(EconomyInventorySnapshot) applyToGame;
  Future<ChestOpeningReceipt?>? _pending;
  String? _pendingOwner;

  Future<ChestOpeningReceipt?> resume(String owner) {
    if (_pending != null) {
      if (_pendingOwner != owner) {
        return Future.error(
            const ServerEconomyException('economy_account_changed'));
      }
      return _pending!;
    }
    _pendingOwner = owner;
    final future = _resume(owner);
    _pending = future;
    return future.whenComplete(() {
      _pending = null;
      _pendingOwner = null;
    });
  }

  void _requireOwner(String owner) {
    if (currentOwner() != owner) {
      throw const ServerEconomyException('economy_account_changed');
    }
  }

  Future<ChestOpeningReceipt?> _resume(String owner) async {
    _requireOwner(owner);
    final intent = await intents.pending(owner);
    if (intent == null) return null;
    _requireOwner(owner);
    final receipt = await open(intent);
    _requireOwner(owner);
    final previous = await snapshots.load(owner);
    _requireOwner(owner);
    final snapshot = await reader.fetch(
        ownerId: owner,
        minimumServerRevision:
            _max(receipt.serverRevision, previous?.serverRevision ?? 0),
        minimumWalletRevision:
            _max(receipt.walletRevision, previous?.walletRevision ?? 0));
    _requireOwner(owner);
    await snapshots.persist(snapshot);
    _requireOwner(owner);
    await applyToGame(snapshot);
    _requireOwner(owner);
    await intents.acknowledge(ownerId: owner, requestId: intent.requestId);
    return receipt;
  }
}

int _max(int a, int b) => a > b ? a : b;
