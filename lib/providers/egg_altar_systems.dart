part of 'household_provider.dart';

extension EggAltarSystems on HouseholdProvider {
  AltarEggKnowledge eggKnowledge(String id) {
    var knowledge = eggAltar.knowledge(id);
    for (final egg in eggStash.where((egg) => egg.id == id)) {
      knowledge = knowledge.merge(egg.altarKnowledge).merge(
          AltarEggKnowledge(moral: egg.moralAxisKnown || egg.isSinisterEgg));
    }
    for (final dragon in [
      pet,
      ...sanctuaryDragons,
      if (incubatingEgg != null) incubatingEgg!
    ].where((dragon) => dragon.id == id)) {
      knowledge = knowledge.merge(dragon.altarKnowledge).merge(
          AltarEggKnowledge(
              moral: dragon.moralAxisKnown, order: dragon.lawAxisKnown));
    }
    return knowledge
        .merge(AltarEggKnowledge(rarity: eggRarityRevealedIds.contains(id)));
  }

  bool isEggTagged(String id) => eggKnowledge(id).tagged;

  String? weaveReturnBlockReason(String id) {
    if (eggAltar.returnedIds.contains(id)) return 'already_returned';
    if (nestEgg?.id == id) return 'egg_in_nest';
    final egg = eggStash.where((egg) => egg.id == id).firstOrNull;
    if (egg == null) return 'egg_not_found';
    if (egg.lineage.rarity == DragonRarity.specialEvent ||
        egg.specialEggId != null) {
      return 'special_egg';
    }
    if (isEggTagged(id)) return 'egg_tagged';
    if (isEggReservedForTrade(id)) return 'egg_reserved';
    return null;
  }

  Future<void> setEggTagged(String id, bool tagged) async {
    await _performAltar('tag', {'eggId': id, 'tagged': tagged});
  }

  Future<WeaveWallet> returnEggToWeave(String id,
      {bool sinisterConfirmed = false}) async {
    final receipt = await _performAltar(
        'return',
        {
          'eggId': id,
          'sinisterConfirmed': sinisterConfirmed,
        },
        operationId: 'return:$id');
    return WeaveWallet.fromJson(
        Map<String, dynamic>.from(receipt['reward'] as Map));
  }

  Future<void> craftAltarRelic(AltarRelic relic) async {
    await _performAltar('craft', {'relic': relic.name});
  }

  Future<void> useAltarRelic(AltarRelic relic, String eggId) async {
    await _performAltar('reveal', {'relic': relic.name, 'eggId': eggId});
  }

  Future<bool> renameDragonWithQuill(String id, String value) async {
    final name = value.trim();
    final dragon = dragonById(id);
    if (dragon == null ||
        dragon.isEgg ||
        dragon.name.trim().isEmpty ||
        name.isEmpty ||
        name.runes.length > 24 ||
        name == dragon.name.trim()) {
      return false;
    }
    try {
      await _performAltar('rename', {'dragonId': id, 'name': name});
      return true;
    } on EggAltarException {
      return false;
    }
  }

  Future<void> donateWeaveFragments(String conclaveId, int amount) async {
    await _performAltar('donate', {'conclaveId': conclaveId, 'amount': amount});
  }

  Future<void> retryPendingAltarOperation() async {
    final pending = pendingAltarOperation;
    if (pending == null) return;
    await _performAltar(pending['action'] as String,
        Map<String, dynamic>.from(pending['payload'] as Map),
        operationId: pending['id'] as String);
  }

  Future<Map<String, dynamic>> _performAltar(
      String action, Map<String, dynamic> payload,
      {String? operationId}) async {
    if (altarBusy) throw const EggAltarException('altar_busy');
    final ownerId = altarCurrentUserId?.call();
    if (altarRequiresAccount && ownerId == null) {
      throw const EggAltarException('altar_sign_in_required');
    }
    if (eggAltar.ownerId != null && ownerId != eggAltar.ownerId) {
      throw const EggAltarException('altar_sign_in_required');
    }
    final pending = pendingAltarOperation;
    if (pending != null &&
        (pending['action'] != action ||
            !mapEquals(Map<String, dynamic>.from(pending['payload'] as Map),
                payload))) {
      throw const EggAltarException('altar_pending');
    }
    final id = pending?['id'] as String? ?? operationId ?? _uuid.v4();
    final previous = EggAltarState.fromJson(eggAltar.toJson());
    final previousEggs =
        eggStash.map((egg) => DragonEgg.fromJson(egg.toJson())).toList();
    final previousRarity = {...eggRarityRevealedIds};
    final previousKnowledge = {
      for (final d in [
        pet,
        ...sanctuaryDragons,
        if (incubatingEgg != null) incubatingEgg!
      ])
        d.id: (d.altarKnowledge, d.moralAxisKnown, d.lawAxisKnown)
    };
    final previousNames = {for (final d in ownedDragons) d.id: d.name};
    var serverCommitted = false;
    altarBusy = true;
    _notifyAltarListeners();
    try {
      Map<String, dynamic> receipt;
      if (ownerId != null && altarCommand != null) {
        pendingAltarOperation = {
          'id': id,
          'action': action,
          'payload': payload
        };
        await _save(); // Persist the request ID before sending an irreversible command.
        final result = await altarCommand!(id, action, payload);
        serverCommitted = true;
        eggAltar = EggAltarState.fromJson(
            Map<String, dynamic>.from(result['state'] as Map));
        receipt = Map<String, dynamic>.from(result['receipt'] as Map? ?? {});
      } else {
        receipt = _localAltarCommand(id, action, payload);
      }
      _applyAltarProtection();
      pendingAltarOperation = null;
      await _notifyAndSave();
      return receipt;
    } on Object catch (error) {
      if (!serverCommitted) {
        eggAltar = previous;
        eggStash = previousEggs;
        eggRarityRevealedIds = previousRarity;
        for (final d in [
          pet,
          ...sanctuaryDragons,
          if (incubatingEgg != null) incubatingEgg!
        ]) {
          final k = previousKnowledge[d.id];
          if (k != null) {
            d.altarKnowledge = k.$1;
            d.moralAxisKnown = k.$2;
            d.lawAxisKnown = k.$3;
          }
        }
        for (final d in ownedDragons) {
          d.name = previousNames[d.id] ?? d.name;
        }
        if (error is EggAltarException && error.code != 'altar_unavailable') {
          pendingAltarOperation = null;
          await _save();
        }
      }
      rethrow;
    } finally {
      altarBusy = false;
      _notifyAltarListeners();
    }
  }

  Map<String, dynamic> _localAltarCommand(
      String operationId, String action, Map<String, dynamic> payload) {
    final existing = eggAltar.operations[operationId];
    if (existing != null) return existing;
    final id = payload['eggId'] as String? ?? '';
    final knowledge = eggKnowledge(id);
    final receipt = <String, dynamic>{'action': action};
    switch (action) {
      case 'tag':
        if (!eggStash.any((e) => e.id == id) && nestEgg?.id != id) {
          throw const EggAltarException('egg_not_found');
        }
        eggAltar.eggs[id] = AltarEggKnowledge.fromJson({
          ...knowledge.toJson(),
          'tagged': payload['tagged'] == true,
          'tagRevision':
              max(_clock().microsecondsSinceEpoch, knowledge.tagRevision + 1)
        });
      case 'return':
        final reason = weaveReturnBlockReason(id);
        if (reason != null) throw EggAltarException(reason);
        final egg = eggStash.firstWhere((e) => e.id == id);
        if (egg.isSinisterEgg && payload['sinisterConfirmed'] != true) {
          throw const EggAltarException('sinister_confirmation_required');
        }
        final reward = rollWeaveReturn(_random,
            sinister: egg.isSinisterEgg, misses: eggAltar.misses);
        eggAltar.wallet += reward;
        eggAltar.misses = reward.hearts > 0 ? 0 : eggAltar.misses + 1;
        eggAltar.totalReturned++;
        eggAltar.returnedIds.add(id);
        receipt['reward'] = reward.toJson();
      case 'craft':
        final relic = AltarRelic.values
            .where((r) => r.name == payload['relic'])
            .firstOrNull;
        if (relic == null) throw const EggAltarException('invalid_relic');
        if (!eggAltar.wallet.covers(relic.cost)) {
          throw const EggAltarException('insufficient_materials');
        }
        eggAltar.wallet -= relic.cost;
        eggAltar.crafted[relic.name] = eggAltar.count(relic) + 1;
      case 'reveal':
        final relic = AltarRelic.values
            .where((r) => r.name == payload['relic'])
            .firstOrNull;
        if (relic == null || relic == AltarRelic.nameweaversQuill) {
          throw const EggAltarException('invalid_relic');
        }
        if (!eggStash.any((e) => e.id == id) && nestEgg?.id != id) {
          throw const EggAltarException('egg_not_found');
        }
        if (knowledge.knows(relic)) {
          throw const EggAltarException('already_known');
        }
        if (isEggReservedForTrade(id)) {
          throw const EggAltarException('egg_reserved');
        }
        if (eggAltar.count(relic) <= 0) {
          throw const EggAltarException('relic_not_owned');
        }
        eggAltar.crafted[relic.name] = eggAltar.count(relic) - 1;
        eggAltar.eggs[id] = AltarEggKnowledge.fromJson({
          ...knowledge.toJson(),
          relic.knownKey: true,
          if (relic == AltarRelic.weaveOracle) 'rarity': true
        });
      case 'rename':
        final dragon = dragonById(payload['dragonId'] as String? ?? '');
        final name = (payload['name'] as String? ?? '').trim();
        if (dragon == null ||
            dragon.isEgg ||
            name.isEmpty ||
            name.runes.length > 24 ||
            dragon.name.trim().isEmpty ||
            dragon.name.trim() == name) {
          throw const EggAltarException('invalid_name');
        }
        const quill = AltarRelic.nameweaversQuill;
        if (eggAltar.count(quill) <= 0) {
          throw const EggAltarException('relic_not_owned');
        }
        eggAltar.crafted[quill.name] = eggAltar.count(quill) - 1;
        eggAltar.names[dragon.id] = name;
      case 'donate':
        throw const EggAltarException('altar_sign_in_required');
      default:
        throw const EggAltarException('invalid_action');
    }
    eggAltar.revision++;
    eggAltar.operations[operationId] = receipt;
    return receipt;
  }

  Future<void> applyOnlineAltarState(Map<String, dynamic> json) async {
    final next = EggAltarState.fromJson(json);
    if (next.ownerId == null || next.ownerId != altarCurrentUserId?.call()) {
      return;
    }
    if (eggAltar.ownerId == next.ownerId && next.revision < eggAltar.revision) {
      return;
    }
    eggAltar = next;
    _applyAltarProtection();
    await _notifyAndSave();
  }

  void _mergeRestoredAltar(EggAltarState preserved) {
    final restored = eggAltar;
    if (preserved.ownerId != null || preserved.revision >= restored.revision) {
      eggAltar = preserved;
    }
    eggAltar.returnedIds.addAll(preserved.returnedIds);
    eggAltar.returnedIds.addAll(restored.returnedIds);
    for (final entry in {...restored.eggs, ...preserved.eggs}.entries) {
      eggAltar.eggs[entry.key] =
          (restored.eggs[entry.key] ?? const AltarEggKnowledge())
              .merge(preserved.eggs[entry.key] ?? const AltarEggKnowledge());
    }
    _applyAltarProtection();
  }

  void _applyAltarProtection() {
    eggStash.removeWhere((e) => eggAltar.returnedIds.contains(e.id));
    if (eggAltar.returnedIds.contains(incubatingEgg?.id)) incubatingEgg = null;
    for (final egg in eggStash) {
      egg.altarKnowledge = eggKnowledge(egg.id);
    }
    for (final dragon in [
      pet,
      ...sanctuaryDragons,
      if (incubatingEgg != null) incubatingEgg!
    ]) {
      dragon.altarKnowledge = eggKnowledge(dragon.id);
      dragon.moralAxisKnown |= dragon.altarKnowledge.moral;
      dragon.lawAxisKnown |= dragon.altarKnowledge.order;
      if (!dragon.isEgg && eggAltar.names.containsKey(dragon.id)) {
        dragon.name = eggAltar.names[dragon.id]!;
      }
    }
    for (final id in [
      ...eggStash.map((e) => e.id),
      if (nestEgg != null) nestEgg!.id
    ]) {
      if (eggKnowledge(id).rarity) eggRarityRevealedIds.add(id);
    }
  }
}
