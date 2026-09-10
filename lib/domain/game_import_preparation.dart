import 'dart:convert';

import '../models/dragon_lineage.dart';
import '../models/egg_altar.dart';
import '../providers/household_provider.dart';
import 'game_asset_snapshot.dart';
import 'game_state_envelope.dart';
import 'server_entropy.dart';

/// Prepares an isolated database copy, never a client-supplied migration or a
/// live write. The operator must commit against the captured source/Altar
/// revisions and recheck active trades before promoting an account.
abstract final class GameImportPreparation {
  static PreparedGameImport prepare({
    required String ownerId,
    required Map<String, dynamic> source,
    required Map<String, dynamic>? authoritativeAltar,
    required DateTime now,
    required String secretSeed,
  }) {
    if (!RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')
        .hasMatch(ownerId)) {
      throw const GameImportException('game_import_owner_invalid');
    }
    if (source['_activeGameAttempt'] != null ||
        source['_lastGameResult'] != null) {
      throw const GameImportException('game_import_server_metadata_untrusted');
    }
    if (source['pendingAltarOperation'] != null) {
      throw const GameImportException('game_import_pending_altar');
    }
    final before = GameAssetSnapshot(source);
    final candidate = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    final saved = Map<String, dynamic>.from(candidate['eggAltar'] as Map);
    if (saved['ownerId'] != null && saved['ownerId'] != ownerId) {
      throw const GameImportException('game_import_foreign_altar');
    }
    final trusted = authoritativeAltar == null
        ? null
        : jsonDecode(jsonEncode(authoritativeAltar)) as Map<String, dynamic>;
    if (trusted != null && trusted['ownerId'] != ownerId) {
      throw const GameImportException('game_import_foreign_altar');
    }
    if (trusted == null && saved['ownerId'] != null) {
      throw const GameImportException('game_import_altar_snapshot_missing');
    }
    if (trusted != null) {
      if (saved['ownerId'] == null && _hasStock(saved)) {
        throw const GameImportException('game_import_offline_altar_review');
      }
      if (_count(trusted['revision']) < _count(saved['revision'])) {
        throw const GameImportException('game_import_altar_snapshot_stale');
      }
      final consumed = Set<String>.from(trusted['returnedIds'] as List);
      if (!(saved['returnedIds'] as List).every(consumed.contains)) {
        throw const GameImportException('game_import_return_history_conflict');
      }
    }
    final altar = <String, dynamic>{...saved, ...?trusted, 'ownerId': ownerId};
    final consumed = Set<String>.from(altar['returnedIds'] as List);
    final pet = candidate['pet'] as Map<String, dynamic>;
    final sanctuary = candidate['sanctuaryDragons'] as List;
    final released = candidate['releasedDragons'] as List;
    if (consumed.contains(pet['id']) ||
        [...sanctuary, ...released]
            .any((dragon) => consumed.contains(dragon['id']))) {
      // Never delete a valuable dragon or invent a replacement active pet to
      // repair a contradictory old backup. Preserve it for explicit review.
      throw const GameImportException('game_import_returned_dragon_conflict');
    }
    final eggs = candidate['eggStash'] as List;
    for (final egg in eggs.where((egg) => consumed.contains(egg['id']))) {
      if (egg['specialEggId'] != null ||
          dragonLineageById(egg['lineageId'] as String).rarity ==
              DragonRarity.specialEvent) {
        throw const GameImportException(
            'game_import_protected_return_conflict');
      }
    }
    eggs.removeWhere((egg) => consumed.contains(egg['id']));
    if (consumed.contains((candidate['incubatingEgg'] as Map?)?['id'])) {
      throw const GameImportException('game_import_returned_nest_conflict');
    }

    final savedKnowledge = Map<String, dynamic>.from(saved['eggs'] as Map);
    final serverKnowledge = Map<String, dynamic>.from(altar['eggs'] as Map);
    final effective = <String, dynamic>{...serverKnowledge};
    final rarity = Set<String>.from(candidate['eggRarityRevealedIds'] as List);
    final names = Map<String, dynamic>.from(altar['names'] as Map);
    for (final entity in [
      pet,
      ...eggs,
      ...sanctuary,
      if (candidate['incubatingEgg'] != null) candidate['incubatingEgg'],
    ]) {
      final id = entity['id'] as String;
      final localKnowledge = AltarEggKnowledge.fromJson(
              Map<String, dynamic>.from(entity['altarKnowledge'] as Map? ?? {}))
          .merge(AltarEggKnowledge.fromJson(
              Map<String, dynamic>.from(savedKnowledge[id] as Map? ?? {})));
      final registered = serverKnowledge[id] as Map?;
      final known = registered == null
          ? localKnowledge
          : AltarEggKnowledge.fromJson(Map<String, dynamic>.from(registered));
      final merged = localKnowledge.merge(known).toJson();
      if (registered != null) {
        // A larger revision from an old or edited client never overwrites the
        // server's current tag. Revealed facts are retained through migration.
        merged['tagged'] = known.tagged;
        merged['tagRevision'] = known.tagRevision;
      }
      merged['moral'] = merged['moral'] == true ||
          entity['moralAxisKnown'] == true ||
          (entity['stage'] == null && entity['lineageId'] == 'sinisterra');
      merged['order'] =
          merged['order'] == true || entity['lawAxisKnown'] == true;
      merged['rarity'] = merged['rarity'] == true || rarity.contains(id);
      entity['altarKnowledge'] = merged;
      effective[id] = merged;
      if (entity.containsKey('stage')) {
        entity['moralAxisKnown'] = merged['moral'];
        entity['lawAxisKnown'] = merged['order'];
        if (entity['stage'] != 'egg' && names.containsKey(id)) {
          entity['name'] = names[id];
        }
      }
      if (merged['rarity'] == true) rarity.add(id);
    }
    for (final id in consumed) {
      effective.remove(id);
      rarity.remove(id);
    }
    altar['eggs'] = effective;
    candidate['eggAltar'] = altar;
    candidate['eggRarityRevealedIds'] = rarity.toList();
    final identities = ServerEntropy(secretSeed, stream: 'identities');
    final game = HouseholdProvider.forServerState(candidate,
        random: ServerEntropy(secretSeed, stream: 'rewards'),
        now: now,
        idGenerator: identities.uuid);
    try {
      final prepared = GameStateEnvelope.preserveUnknownMetadata(
          candidate, game.exportState());
      return PreparedGameImport(
          prepared,
          before.differenceKinds(GameAssetSnapshot(prepared)),
          authoritativeAltar == null
              ? null
              : _count(authoritativeAltar['revision']));
    } finally {
      game.dispose();
    }
  }

  static int _count(Object? value) {
    if (value is! int || value < 0) {
      throw const GameImportException('game_import_altar_invalid');
    }
    return value;
  }

  static bool _hasStock(Map<String, dynamic> altar) =>
      (altar['wallet'] as Map).values.any((value) => _count(value) > 0) ||
      (altar['crafted'] as Map).values.any((value) => _count(value) > 0);
}

class PreparedGameImport {
  const PreparedGameImport(
      this.state, this.changedAssetKinds, this.altarRevision);
  final Map<String, dynamic> state;
  final Set<String> changedAssetKinds;
  final int? altarRevision;
}

class GameImportException implements Exception {
  const GameImportException(this.code);
  final String code;
  @override
  String toString() => 'GameImportException($code)';
}
