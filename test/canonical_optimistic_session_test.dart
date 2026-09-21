import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
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
    expect(session.canAct, isFalse);
    expect(session.snapshot!.canApplyToLiveGame, isFalse);
    expect(() => session.snapshot!.toJson(), throwsStateError);
    await expectLater(session.snapshots.persistFresh(session.snapshot!),
        throwsA(isA<CanonicalGameException>()));
    expect(
        (await session.snapshots.inspect(CanonicalUiServer.owner))
            .snapshot!
            .coins,
        before.coins);
    await expectLater(session.execute('purchase_music_chest', {}),
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
