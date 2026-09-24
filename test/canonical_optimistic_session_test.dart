import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/models/adventure.dart';
import 'package:dragon_haven/models/pet.dart';
import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  late CanonicalUiServer server;
  late CanonicalUiConnection connection;
  late CanonicalGameSession session;
  late Directory directory;
  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-prediction-');
    server = CanonicalUiServer(jsonDecode(jsonEncode(fixture)));
    connection = CanonicalUiConnection(server);
    session =
        CanonicalGameSession(connection: connection, directory: directory);
    await session.synchronize();
  });
  tearDown(() async {
    await session.close();
    await directory.delete(recursive: true);
  });

  test(
      'purchase displays immediately, confirmed cache and authority stay unchanged',
      () async {
    final before = session.confirmedSnapshot!;
    final hold = Completer<void>();
    server.hold = hold.future;
    final pending = session.execute('purchase_title_chest', {});
    expect(session.snapshot!.isSpeculative, isTrue);
    expect(session.snapshot!.coins, before.coins - 500);
    expect(session.snapshot!.shop.chests['title'],
        (before.shop.chests['title'] ?? 0) + 1);
    expect(session.confirmedSnapshot, same(before));
    expect(session.canAct, isTrue);
    expect(session.canRunAutomatic, isFalse);
    expect(session.snapshot!.canApplyToLiveGame, isFalse);
    expect(() => session.snapshot!.toJson(), throwsStateError);
    await expectLater(session.snapshots.persistFresh(session.snapshot!),
        throwsA(isA<CanonicalGameException>()));
    expect(
        (await session.snapshots.inspect(CanonicalUiServer.owner))
            .snapshot!
            .coins,
        before.coins);
    await expectLater(
        session.execute('open_chests', {'tier': 'wooden', 'count': 1}),
        throwsA(isA<CanonicalGameException>()));
    expect(session.execute('purchase_title_chest', {}), same(pending));
    hold.complete();
    expect((await pending)!.succeeded, isTrue);
    expect(session.snapshot!.isSpeculative, isFalse);
    expect(session.snapshot!.coins, before.coins - 500);
    expect(server.sent, hasLength(1));
  });

  test('server rejection rolls display back to authoritative state', () async {
    final before = session.snapshot!;
    final hold = Completer<void>();
    server.hold = hold.future;
    server.revision++;
    final pending = session.execute('purchase_title_chest', {});
    expect(session.snapshot!.coins, before.coins - 500);
    hold.complete();
    expect((await pending)!.succeeded, isFalse);
    expect(session.snapshot!.coins, before.coins);
    expect(session.snapshot!.isSpeculative, isFalse);
  });

  test('two immediate previews serialize at confirmed revisions', () async {
    final before = session.confirmedSnapshot!;
    final hold = Completer<void>();
    server.hold = hold.future;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_music_chest', {});
    expect(session.snapshot!.coins, before.coins - 500);
    expect(session.snapshot!.gems, before.gems - 250);
    expect(session.canAct, true);
    expect(session.confirmedSnapshot, same(before));
    hold.complete();
    final receipts = await Future.wait([first, second]);
    expect(receipts.every((r) => r!.succeeded), true);
    expect(server.sent.map((i) => i.minimumRevision),
        [before.serverRevision, before.serverRevision + 1]);
    expect(session.snapshot!.coins, before.coins - 500);
    expect(session.snapshot!.gems, before.gems - 250);
    expect(session.snapshot!.isSpeculative, false);
    expect(await session.intents.pending(CanonicalUiServer.owner), isNull);
  });

  test('rejected head rolls back and rebases later independent action',
      () async {
    final before = session.confirmedSnapshot!;
    final hold = Completer<void>();
    server.hold = hold.future;
    server.revision++;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_music_chest', {});
    hold.complete();
    expect((await first)!.succeeded, false);
    expect((await second)!.succeeded, true);
    expect(session.snapshot!.coins, before.coins);
    expect(session.snapshot!.gems, before.gems - 250);
    expect(server.sent.last.minimumRevision, before.serverRevision + 1);
  });

  test('A B A preserves ordering while adjacent duplicate taps share',
      () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final a = session.execute('set_account_name', {'name': 'Keeper A'});
    final duplicate = session.execute('set_account_name', {'name': 'Keeper A'});
    expect(duplicate, same(a));
    final b = session.execute('set_account_name', {'name': 'Keeper B'});
    final again = session.execute('set_account_name', {'name': 'Keeper A'});
    expect(again, isNot(same(a)));
    expect(session.snapshot!.profile.name, 'Keeper A');
    hold.complete();
    await Future.wait([a, b, again]);
    expect(server.sent, hasLength(3));
    expect(session.snapshot!.profile.name, 'Keeper A');
  });

  test('projected spending cannot spend the same gems twice', () async {
    server.state['pet']['gems'] = 250;
    server.revision++;
    await session.synchronize();
    final hold = Completer<void>();
    server.hold = hold.future;
    final purchase = session.execute('purchase_music_chest', {});
    expect(session.snapshot!.gems, 0);
    await expectLater(session.execute('purchase_portrait_chest', {}),
        throwsA(isA<CanonicalGameException>()));
    hold.complete();
    expect((await purchase)!.succeeded, true);
    expect(server.sent, hasLength(1));
  });

  test(
      'rebase drops unaffordable dependent command but preserves independent tail',
      () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final first = session.execute('purchase_title_chest', {});
    final invalidated = session.execute('purchase_music_chest', {});
    final tail = session.execute('set_account_name', {'name': 'Still valid'});
    final failure =
        expectLater(invalidated, throwsA(isA<CanonicalGameException>()));
    server.state['pet']['gems'] = 0;
    server.revision++;
    hold.complete();
    expect((await first)!.succeeded, false);
    await failure;
    expect((await tail)!.succeeded, true);
    expect(server.sent.map((i) => i.action),
        ['purchase_title_chest', 'set_account_name']);
    expect(session.snapshot!.profile.name, 'Still valid');
    expect(session.snapshot!.gems, 0);
  });

  test('background synchronize joins queue without stealing its dispatch slot',
      () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_music_chest', {});
    final projected = session.snapshot;
    final sync = session.synchronize();
    expect(session.snapshot, same(projected));
    expect(session.canAct, true);
    hold.complete();
    await Future.wait([first, second, sync]);
    expect(server.sent, hasLength(2));
    expect(session.canRunAutomatic, true);
  });

  test('tower scenery is immediate and matches confirmed occupants', () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final pending = session
        .execute('change_tower_floor_room', {'index': 0, 'roomId': 'crystal'});
    expect(session.snapshot!.data['house']['towerFloorRoomIds'][0], 'crystal');
    for (final dragon
        in session.snapshot!.dragons.where((d) => d.floorIndex == 0)) {
      expect(dragon.roomId, 'crystal');
    }
    hold.complete();
    expect((await pending)!.succeeded, true);
    expect(session.snapshot!.data['house']['towerFloorRoomIds'][0], 'crystal');
  });

  test('rejected tower scenery rolls back the room and its occupants',
      () async {
    final before = session.snapshot!;
    final roomBefore = before.house.floorRoomIds.first;
    final hold = Completer<void>();
    server.hold = hold.future;
    server.revision++;

    final pending = session.execute('change_tower_floor_room',
        {'index': 0, 'roomId': roomBefore == 'crystal' ? 'hearth' : 'crystal'});
    expect(session.snapshot!.house.floorRoomIds.first, isNot(roomBefore));

    hold.complete();
    expect((await pending)!.succeeded, isFalse);
    expect(session.snapshot!.house.floorRoomIds.first, roomBefore);
    for (final dragon
        in session.snapshot!.dragons.where((d) => d.floorIndex == 0)) {
      expect(dragon.roomId, roomBefore);
    }
  });

  test('calling the favorite into a room is immediate and server-confirmed',
      () async {
    server.state['towerFloorRoomIds'] = ['hearth', 'garden'];
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'garden'];
    server.state['damagedTowerFloors'] = <int>[];
    server.state['damagedTowerRepairFactors'] = <String, dynamic>{};
    server.state['pet']['currentFloorIndex'] = 0;
    server.state['pet']['currentRoomId'] = 'hearth';
    server.state['pet']['roamsTower'] = true;
    server.state['pet']['favorite'] = true;
    server.revision++;
    await session.synchronize();
    final id = session.snapshot!.activeDragonId!;
    final hold = Completer<void>();
    server.hold = hold.future;

    final pending = session
        .execute('call_dragon_to_floor', {'roomId': 'garden', 'index': 1});
    expect(session.snapshot!.isSpeculative, isTrue);
    expect(session.snapshot!.dragon(id)!.floorIndex, 1);
    expect(session.snapshot!.dragon(id)!.roomId, 'garden');

    hold.complete();
    expect((await pending)!.succeeded, isTrue);
    expect(session.snapshot!.isSpeculative, isFalse);
    expect(session.snapshot!.dragon(id)!.floorIndex, 1);
    expect(session.snapshot!.dragon(id)!.roomId, 'garden');
  });

  test('a rejected room call restores the favorite to its previous floor',
      () async {
    server.state['towerFloorRoomIds'] = ['hearth', 'garden'];
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'garden'];
    server.state['damagedTowerFloors'] = <int>[];
    server.state['damagedTowerRepairFactors'] = <String, dynamic>{};
    server.state['pet']['currentFloorIndex'] = 0;
    server.state['pet']['currentRoomId'] = 'hearth';
    server.state['pet']['roamsTower'] = true;
    server.state['pet']['favorite'] = true;
    server.revision++;
    await session.synchronize();
    final id = session.snapshot!.activeDragonId!;
    final hold = Completer<void>();
    server.hold = hold.future;
    server.revision++;

    final pending = session
        .execute('call_dragon_to_floor', {'roomId': 'garden', 'index': 1});
    expect(session.snapshot!.dragon(id)!.floorIndex, 1);
    expect(session.snapshot!.dragon(id)!.roomId, 'garden');

    hold.complete();
    expect((await pending)!.succeeded, isFalse);
    expect(session.snapshot!.isSpeculative, isFalse);
    expect(session.snapshot!.dragon(id)!.floorIndex, 0);
    expect(session.snapshot!.dragon(id)!.roomId, 'hearth');
  });

  test('active returning visitors prevent an optimistic call into a full floor',
      () async {
    server.state['towerFloorRoomIds'] = ['hearth', 'garden'];
    server.state['unlockedRoomIds'] = ['nest', 'hearth', 'garden'];
    server.state['damagedTowerFloors'] = <int>[];
    server.state['damagedTowerRepairFactors'] = <String, dynamic>{};
    server.state['pet']['currentFloorIndex'] = 0;
    server.state['pet']['currentRoomId'] = 'hearth';
    server.state['pet']['roamsTower'] = true;
    server.state['pet']['favorite'] = true;
    final visitors = <Map<String, dynamic>>[];
    final returning = <String, String>{};
    for (var i = 0; i < 3; i++) {
      final visitor =
          jsonDecode(jsonEncode(server.state['pet'])) as Map<String, dynamic>;
      final id = 'returning-visitor-$i';
      visitor
        ..['id'] = id
        ..['favorite'] = false
        ..['currentFloorIndex'] = 1
        ..['currentRoomId'] = 'garden';
      visitors.add(visitor);
      returning[id] =
          server.now.add(const Duration(hours: 1)).toIso8601String();
    }
    server.state['releasedDragons'] = visitors;
    server.state['returningVisitors'] = returning;
    server.revision++;
    await session.synchronize();
    final id = session.snapshot!.activeDragonId!;
    final hold = Completer<void>();
    server.hold = hold.future;

    final pending = session
        .execute('call_dragon_to_floor', {'roomId': 'garden', 'index': 1});
    expect(session.snapshot!.isSpeculative, isFalse);
    expect(session.snapshot!.dragon(id)!.floorIndex, 0);

    hold.complete();
    expect((await pending)!.succeeded, isTrue);
    expect(session.snapshot!.dragon(id)!.floorIndex, 0);
  });

  test('abort adventure frees dragon immediately without awarding loot',
      () async {
    await session.execute('refresh', {});
    final before = session.snapshot!;
    final offer = before.adventures.offers(AdventureKind.mini).first;
    final dragon = before.dragons.first;
    await session.execute(
        'start_adventure', {'adventureId': offer, 'dragonId': dragon.id});
    final active = session.snapshot!;
    final run = active.adventures.runs.single;
    final hold = Completer<void>();
    server.hold = hold.future;
    final pending = session.execute('abort_adventure', {'runId': run.id});
    expect(session.snapshot!.adventures.runs, isEmpty);
    expect(session.snapshot!.dragon(dragon.id)!.adventureId, isNull);
    expect(session.snapshot!.shop.chests, active.shop.chests);
    hold.complete();
    expect((await pending)!.succeeded, true);
    expect(session.snapshot!.adventures.runs, isEmpty);
  });

  test('starting an adventure reserves its dragon and timer immediately',
      () async {
    await session.execute('refresh', {});
    final before = session.snapshot!;
    final offer = before.adventures.offers(AdventureKind.mini).first;
    final definition = AdventureCatalog.byId[offer]!;
    final dragon = before.dragons.firstWhere((candidate) =>
        candidate.owned &&
        candidate.stage.name != 'egg' &&
        candidate.adventureId == null);
    final hold = Completer<void>();
    server.hold = hold.future;

    final pending = session.execute(
        'start_adventure', {'adventureId': offer, 'dragonId': dragon.id});
    final preview = session.snapshot!;
    final run = preview.adventures.runs.single;
    expect(preview.isSpeculative, isTrue);
    expect(run.id, 'pending-adventure-${dragon.id}');
    expect(run.adventureId, offer);
    expect(run.dragonId, dragon.id);
    expect(run.revealedReward, isNull);
    expect(
        run.endsAt.difference(run.startedAt),
        expertiseAdjustedAdventureDurationFromScores(
          definition,
          [dragon.trainingFor(definition.focus)],
          combinedExpertise: TrainingFocus.values
              .fold(0, (total, focus) => total + dragon.trainingFor(focus)),
        ));
    expect(preview.dragon(dragon.id)!.adventureId, run.id);
    expect(
        preview.adventures.offers(AdventureKind.mini), isNot(contains(offer)));
    expect(session.confirmedSnapshot!.dragon(dragon.id)!.adventureId, isNull);

    hold.complete();
    expect((await pending)!.succeeded, isTrue);
    expect(session.snapshot!.isSpeculative, isFalse);
    expect(session.snapshot!.adventures.runs.single.id,
        isNot(startsWith('pending-adventure-')));
    expect(session.snapshot!.dragon(dragon.id)!.adventureId,
        session.snapshot!.adventures.runs.single.id);
  });

  test('claim then next adventure stay playable while receipts serialize',
      () async {
    await session.execute('refresh', {});
    final initial = session.snapshot!;
    final firstOffer = initial.adventures.offers(AdventureKind.mini).first;
    final dragon = initial.dragons.firstWhere((candidate) =>
        candidate.owned &&
        candidate.stage.name != 'egg' &&
        candidate.adventureId == null);
    await session.execute(
        'start_adventure', {'adventureId': firstOffer, 'dragonId': dragon.id});
    final activeRun = session.snapshot!.adventures.runs.single;
    server.now = activeRun.endsAt.add(const Duration(seconds: 1));
    await session.synchronize();
    final ready = session.snapshot!.adventures.runs.single;
    final chestsBefore = Map<String, int>.of(session.snapshot!.shop.chests);
    final nextOffer = session.snapshot!.adventures
        .offers(AdventureKind.mini)
        .firstWhere((id) => id != firstOffer);
    final hold = Completer<void>();
    server.hold = hold.future;

    final claim = session.execute('claim_adventure', {'runId': ready.id});
    expect(session.snapshot!.adventures.runs, isEmpty);
    expect(session.snapshot!.dragon(dragon.id)!.adventureId, isNull);
    expect(session.snapshot!.shop.chests, chestsBefore);
    final start = session.execute(
        'start_adventure', {'adventureId': nextOffer, 'dragonId': dragon.id});
    expect(session.snapshot!.adventures.runs.single.adventureId, nextOffer);
    expect(session.snapshot!.dragon(dragon.id)!.adventureId,
        startsWith('pending-adventure-'));

    hold.complete();
    final receipts = await Future.wait([claim, start]);
    expect(receipts.every((receipt) => receipt!.succeeded), isTrue);
    expect(server.sent.reversed.take(2).map((intent) => intent.action).toList(),
        ['start_adventure', 'claim_adventure']);
    expect(session.snapshot!.adventures.runs.single.adventureId, nextOffer);
    expect(session.snapshot!.isSpeculative, isFalse);
  });

  test('lost reply cancels unsent queue and recovers original request once',
      () async {
    final before = session.confirmedSnapshot!;
    final hold = Completer<void>();
    server.hold = hold.future;
    server.loseReply = true;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_music_chest', {});
    final failures = Future.wait([
      expectLater(first, throwsA(isA<CanonicalGameException>())),
      expectLater(second, throwsA(isA<CanonicalGameException>())),
    ]);
    hold.complete();
    await failures;
    expect(server.sent, hasLength(1));
    expect(session.snapshot!.coins, before.coins);
    expect(session.snapshot!.gems, before.gems);
    await session.synchronize();
    expect(session.snapshot!.coins, before.coins - 500);
    expect(session.snapshot!.gems, before.gems);
    expect(server.sent.map((i) => i.requestId).toSet(), hasLength(1));
  });

  test(
      'account change settles every queued future without dispatching later actions',
      () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_music_chest', {});
    final failures = Future.wait([
      expectLater(first, throwsA(isA<CanonicalGameException>())),
      expectLater(second, throwsA(isA<CanonicalGameException>())),
    ]);
    connection.signOut();
    hold.complete();
    await failures;
    expect(session.snapshot, isNull);
    await session.close();
    expect(server.sent.length, lessThanOrEqualTo(1));
  });

  test('close drains admitted queue before disposing connection', () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final first = session.execute('purchase_title_chest', {});
    final second = session.execute('purchase_music_chest', {});
    final closing = session.close();
    hold.complete();
    expect((await first)!.succeeded, true);
    expect((await second)!.succeeded, true);
    await closing;
    expect(server.sent, hasLength(2));
    expect(session.snapshot, isNull);
  });

  test(
      'lost committed reply rolls back temporarily and replays same purchase once',
      () async {
    final before = session.snapshot!;
    server.loseReply = true;
    await expectLater(session.execute('purchase_title_chest', {}),
        throwsA(isA<CanonicalGameException>()));
    expect(session.snapshot!.coins, before.coins);
    expect(session.snapshot!.isSpeculative, isFalse);
    expect(session.canAct, isFalse);
    await session.synchronize();
    expect(session.snapshot!.coins, before.coins - 500);
    expect(server.sent.map((i) => i.requestId).toSet(), hasLength(1));
    expect(session.snapshot!.shop.chests['title'],
        (before.shop.chests['title'] ?? 0) + 1);
  });

  test('account change hides pending display and never installs its reply',
      () async {
    final hold = Completer<void>();
    server.hold = hold.future;
    final pending = session.execute('purchase_title_chest', {});
    final failure =
        expectLater(pending, throwsA(isA<CanonicalGameException>()));
    expect(session.snapshot!.isSpeculative, isTrue);
    connection.signOut();
    expect(session.snapshot, isNull);
    expect(session.confirmedSnapshot, isNull);
    hold.complete();
    await failure;
    expect(session.snapshot, isNull);
  });

  test('unknown random rewards are never predicted', () async {
    final before = session.snapshot!;
    final hold = Completer<void>();
    server.hold = hold.future;
    final pending =
        session.execute('open_chests', {'tier': 'wooden', 'count': 1});
    expect(session.snapshot, same(before));
    hold.complete();
    await pending;
  });

  test('language and dragon changes appear before the request and reconcile',
      () async {
    for (final (action, payload, read) in <(
      String,
      Map<String, dynamic>,
      Object? Function(CanonicalGameSnapshot)
    )>[
      (
        'set_preferences',
        {
          'changes': jsonEncode({'languageCode': 'nl'})
        },
        (s) => s.profile.preferences['languageCode']
      ),
      ('set_account_name', {'name': 'Immediate Keeper'}, (s) => s.profile.name),
      (
        'set_dragon_highlight',
        {
          'dragonId': session.snapshot!.dragons.first.id,
          'focus': 'might',
          'highlighted': true
        },
        (s) => s.data['dragons'][0]['highlightedExpertises']
      ),
    ]) {
      final hold = Completer<void>();
      server.hold = hold.future;
      final pending = session.execute(action, payload);
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });
      expect(session.snapshot!.isSpeculative, isTrue, reason: action);
      final predicted = read(session.snapshot!);
      hold.complete();
      expect((await pending)!.succeeded, isTrue, reason: action);
      expect(read(session.snapshot!), predicted, reason: action);
    }
  });
}
