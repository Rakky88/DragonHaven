import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/app_info.dart';
import 'package:dragon_haven/services/canonical_game_reader.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/canonical_game_snapshot_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _other = '22222222-2222-4222-8222-222222222222';
late Map<String, dynamic> _data;
Map<String, dynamic> _wire({int revision = 5}) => jsonDecode(jsonEncode({
      'protocol': 2,
      'owner_id': _owner,
      'server_revision': revision,
      'state_sha256': 'ab' * 32,
      'ruleset_sha256': 'cd' * 32,
      'ruleset_revision': 2,
      'authority_mode': 'shadow',
      'mutations_enabled': false,
      'server_time': '2026-09-07T12:00:00Z',
      'data': _data,
    })) as Map<String, dynamic>;
CanonicalGameSnapshot _parse(Object? value, {int minimum = 0}) =>
    CanonicalGameSnapshot.parse(value,
        expectedOwner: _owner, minimumRevision: minimum);
Matcher _error(String code) => throwsA(
    isA<CanonicalGameException>().having((e) => e.code, 'fixed code', code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fixture = await runGameDomainProbe();
    _data = fixture['projections'].first as Map<String, dynamic>;
  });

  test('partner points may update at the same private game revision', () {
    final before = _wire();
    final progress = {
      'eventId': 'valentine_two_heartlights',
      'key': 'valentine_two_heartlights:launch:2027',
      'chestId': 'twinheart_keepsake_chest_v1',
      'startsAt': '2027-02-13T23:00:00Z',
      'endsAt': '2027-02-14T23:00:00Z',
      'target': 2000,
      'points': 100,
      'partnerPoints': 500,
      'claimed': false,
      'preview': false,
    };
    before['data']['adventures']['eventProgress'] = [progress];
    final after = jsonDecode(jsonEncode(before)) as Map<String, dynamic>;
    after['data']['adventures']['eventProgress'][0]['partnerPoints'] = 1900;
    expect(_parse(before).hasSameOwnedState(_parse(after)), true);
    expect(_parse(after).adventures.eventProgress.single.canClaim, true);
    after['data']['wallet']['coins']++;
    expect(_parse(before).hasSameOwnedState(_parse(after)), false);
  });

  test('parses real server projection without inventing hidden egg information',
      () {
    final snapshot = _parse(_wire());
    expect(snapshot.eggs, isNotEmpty);
    for (final egg in snapshot.eggs) {
      expect(egg.revealedLineageId, isNull);
      expect(egg.revealedRarity, isNull);
      expect(egg.hint('en'), isNotEmpty);
      expect(egg.incubation.inSeconds, greaterThan(0));
    }
    expect(snapshot.coins, _data['wallet']['coins']);
    expect(snapshot.canApplyToLiveGame, isFalse);
    expect(_parse(_wire()..['mutations_enabled'] = true).canApplyToLiveGame,
        isFalse);
  });

  test('nested data is an immutable copy, including egg clues and stock', () {
    final raw = _wire();
    final snapshot = _parse(raw);
    raw['data']['wallet']['coins'] = 999999;
    raw['data']['eggs'][0]['hints']['en'] = 'altered';
    expect(snapshot.coins, isNot(999999));
    expect(snapshot.eggs.first.hint('en'), isNot('altered'));
    expect(() => snapshot.data['wallet']['coins'] = 7, throwsUnsupportedError);
    expect(() => snapshot.data['eggs'].clear(), throwsUnsupportedError);
  });

  test('wrong account, stale revision and a live-mode impostor are rejected',
      () {
    expect(() => _parse(_wire()..['owner_id'] = _other),
        _error('game_snapshot_invalid'));
    expect(() => _parse(_wire(), minimum: 6), _error('game_snapshot_stale'));
    expect(() => _parse(_wire()..['authority_mode'] = 'server'),
        _error('game_snapshot_invalid'));
    expect(() => _parse(_wire()..['server_revision'] = 5.5),
        _error('game_snapshot_invalid'));
  });

  test(
      'malformed wallet, duplicate entity, missing nest time and private fields are refused',
      () {
    final invalid = <Map<String, dynamic>>[];
    final wallet = _wire();
    wallet['data']['wallet']['coins'] = -1;
    invalid.add(wallet);
    final duplicate = _wire();
    duplicate['data']['eggs'].add(duplicate['data']['eggs'][0]);
    invalid.add(duplicate);
    final nest = _wire();
    nest['data']['eggs'][0]['location'] = 'nest';
    invalid.add(nest);
    final secret = _wire();
    secret['data']['presentations'].add({'hatchSeed': 12345});
    invalid.add(secret);
    final active = _wire();
    active['data']['activeDragonId'] = 'missing';
    invalid.add(active);
    for (final wire in invalid) {
      expect(() => _parse(wire), _error('game_snapshot_invalid'));
    }
  });

  test(
      'equal revision tolerates JSON key order, read time and paused status only',
      () {
    final a = _parse(_wire());
    final changed = _wire()
      ..['server_time'] = '2026-09-08T12:00:00Z'
      ..['mutations_enabled'] = true;
    changed['data']['wallet'] = {'gems': a.gems, 'coins': a.coins};
    expect(a.hasSameState(_parse(changed)), isTrue);
    changed['data']['wallet']['coins'] = a.coins + 1;
    expect(a.hasSameState(_parse(changed)), isFalse);
    expect(a.hasSameState(_parse(_wire(revision: 6))), isFalse);
  });

  test('reader sends no owner or local game and fences revision', () async {
    final requests = <Map<String, dynamic>>[];
    final reader = CanonicalGameReader(
        currentOwner: () => _owner,
        sessionEpoch: () => 3,
        invoke: (request) async {
          requests.add(request);
          return _wire();
        });
    expect((await reader.fetch(_owner, minimumRevision: 5)).serverRevision, 5);
    expect(requests.single, {
      'protocol': 2,
      'clientBuild': AppInfo.buildNumber,
      'action': 'read_state'
    });
    await expectLater(reader.fetch(_owner, minimumRevision: 6),
        _error('game_snapshot_stale'));
    await expectLater(reader.fetch(_owner, minimumRulesetRevision: 3),
        _error('game_snapshot_stale'));
  });

  test('account switch and A to B to A session switch reject delayed responses',
      () async {
    for (final returnToSameOwner in [false, true]) {
      var owner = _owner;
      var epoch = 3;
      final delayed = Completer<Object?>();
      final reader = CanonicalGameReader(
          currentOwner: () => owner,
          sessionEpoch: () => epoch,
          invoke: (_) => delayed.future);
      final result = reader.fetch(_owner);
      final assertion = expectLater(result, _error('game_account_changed'));
      owner = returnToSameOwner ? _owner : _other;
      epoch += 2;
      delayed.complete(_wire());
      await assertion;
    }
  });

  test('read timeout is fixed and never invents fallback inventory', () async {
    final delayed = Completer<Object?>();
    final reader = CanonicalGameReader(
        currentOwner: () => _owner,
        sessionEpoch: () => 0,
        timeout: const Duration(milliseconds: 5),
        invoke: (_) => delayed.future);
    await expectLater(
        reader.fetch(_owner), _error('game_snapshot_unavailable'));
    delayed.complete(_wire());
  });

  group('durable display journal', () {
    late Directory directory;
    late CanonicalGameSnapshotStore store;
    File file(String suffix) =>
        File('${directory.path}/game-v2-$_owner$suffix');
    setUp(() async {
      directory =
          await Directory.systemTemp.createTemp('dragonhaven-canonical-cache-');
      store = CanonicalGameSnapshotStore(directory);
    });
    tearDown(() async {
      // Only the unique test directory returned by createTemp is removed.
      await directory.delete(recursive: true);
    });

    test('server cache is isolated and rejects shadow data at any revision',
        () async {
      final live = CanonicalGameSnapshotStore(directory,
          expectedAuthority: CanonicalGameAuthority.server);
      final server = CanonicalGameSnapshot.parse(
          _wire()..['authority_mode'] = 'server',
          expectedOwner: _owner,
          expectedAuthority: CanonicalGameAuthority.server);
      await store.persistFresh(_parse(_wire(revision: 99)));
      expect((await live.inspect(_owner)).snapshot, isNull);
      await live.persistFresh(server);
      expect((await live.inspect(_owner)).snapshot!.serverRevision, 5);
      expect((await store.inspect(_owner)).snapshot!.serverRevision, 99);
      await expectLater(live.persistFresh(_parse(_wire(revision: 100))),
          _error('game_snapshot_invalid'));
      await expectLater(
          store.persistFresh(server), _error('game_snapshot_invalid'));
    });

    test(
        'event expiration can refresh availability without changing owned stock',
        () async {
      final first = _wire();
      first['data']['adventures']['activeEvents'] = [
        {
          'eventId': 'sunwake_summer_sea',
          'key': 'sunwake_summer_sea:preview:1',
          'startsAt': '2026-09-05T12:00:00Z',
          'endsAt': '2026-09-07T12:00:01Z'
        }
      ];
      first['data']['adventures']['adventureOptionIds']
          ['special'] = ['special_sunwake_summer_sea'];
      await store.persistFresh(_parse(first));
      final closed = jsonDecode(jsonEncode(first)) as Map<String, dynamic>;
      closed['server_time'] = '2026-09-07T12:00:02Z';
      closed['data']['adventures']['activeEvents'] = [];
      closed['data']['adventures']['adventureOptionIds']['special'] = [];
      await store.persistFresh(_parse(closed));
      expect((await store.inspect(_owner)).snapshot!.adventures.activeEvents,
          isEmpty);
      final altered = jsonDecode(jsonEncode(closed)) as Map<String, dynamic>;
      altered['server_time'] = '2026-09-07T12:00:03Z';
      altered['data']['wallet']['coins'] += 1;
      await expectLater(store.persistFresh(_parse(altered)),
          _error('game_snapshot_conflict'));
    });

    test('persists across instances, serializes races and rejects rewinds',
        () async {
      await store.persistFresh(_parse(_wire()));
      final reopened = CanonicalGameSnapshotStore(directory);
      expect((await reopened.inspect(_owner)).snapshot!.serverRevision, 5);
      final newer = reopened.persistFresh(_parse(_wire(revision: 7)));
      final older = store.persistFresh(_parse(_wire(revision: 6)));
      final rejected = expectLater(older, _error('game_snapshot_stale'));
      await newer;
      await rejected;
      expect((await store.inspect(_owner)).minimumRevision, 7);
      expect((await store.inspect(_other)).snapshot, isNull);
    });

    test(
        'corrupt snapshot retains its independent floor and is repaired by fresh data',
        () async {
      await store.persistFresh(_parse(_wire()));
      await file('.json').writeAsString('{truncated');
      final broken = await store.inspect(_owner);
      expect(broken.snapshot, isNull);
      expect(broken.needsRepair, isTrue);
      expect(broken.minimumRevision, 5);
      await expectLater(store.persistFresh(_parse(_wire(revision: 4))),
          _error('game_snapshot_stale'));
      await store.persistFresh(_parse(_wire()));
      expect((await store.inspect(_owner)).needsRepair, isFalse);
    });

    test(
        'well-formed JSON corruption is caught by checksum and does not mint coins',
        () async {
      await store.persistFresh(_parse(_wire()));
      final raw = jsonDecode(await file('.json').readAsString());
      raw['value']['data']['wallet']['coins'] = 999999;
      await file('.json').writeAsString(jsonEncode(raw));
      expect((await store.inspect(_owner)).snapshot, isNull);
      await store.persistFresh(_parse(_wire()));
      expect((await store.inspect(_owner)).snapshot!.coins,
          _data['wallet']['coins']);
    });

    test(
        'a crash between fence and snapshot cannot make the old display current',
        () async {
      await store.persistFresh(_parse(_wire()));
      final obstruction = Directory(file('.json.tmp').path);
      await obstruction.create();
      await expectLater(store.persistFresh(_parse(_wire(revision: 6))),
          throwsA(isA<FileSystemException>()));
      final interrupted = await store.inspect(_owner);
      expect(interrupted.minimumRevision, 6);
      expect(interrupted.snapshot, isNull);
      await obstruction.delete();
      await store.persistFresh(_parse(_wire(revision: 6)));
      expect((await store.inspect(_owner)).snapshot!.serverRevision, 6);
    });

    test(
        'corrupt fence retains surviving snapshot revision and can be repaired',
        () async {
      await store.persistFresh(_parse(_wire()));
      await file('.revision.json').writeAsString('broken');
      final interrupted = await store.inspect(_owner);
      expect(interrupted.minimumRevision, 5);
      expect(interrupted.needsRepair, isTrue);
      await store.persistFresh(_parse(_wire()));
      expect((await store.inspect(_owner)).needsRepair, isFalse);
    });

    test('shared reservations can change without rewriting private inventory',
        () async {
      final initial = _wire();
      final dragonId = initial['data']['dragons'][0]['id'] as String;
      initial['data']['dragons'][0]['activeAdventureId'] =
          'online-group:$_other';
      await store.persistFresh(_parse(initial));
      final released = jsonDecode(jsonEncode(initial)) as Map<String, dynamic>;
      released['server_time'] = '2026-09-07T12:00:01Z';
      released['data']['dragons'][0]['activeAdventureId'] = null;
      await store.persistFresh(_parse(released));
      expect(
          (await store.inspect(_owner)).snapshot!.dragon(dragonId)!.adventureId,
          isNull);
      await expectLater(
          store.persistFresh(_parse(initial)), _error('game_snapshot_stale'));
      final reserved = jsonDecode(jsonEncode(released)) as Map<String, dynamic>;
      reserved['server_time'] = '2026-09-07T12:00:02Z';
      reserved['data']['dragons'][0]['activeAdventureId'] =
          'online-seasonal:$_other';
      await store.persistFresh(_parse(reserved));
      final corrupt = jsonDecode(jsonEncode(reserved)) as Map<String, dynamic>;
      corrupt['server_time'] = '2026-09-07T12:00:03Z';
      corrupt['data']['dragons'][0]['xp'] += 1;
      await expectLater(store.persistFresh(_parse(corrupt)),
          _error('game_snapshot_conflict'));
      corrupt['data']['dragons'][0]['xp'] -= 1;
      corrupt['data']['dragons'][0]['activeAdventureId'] = 'ordinary-solo-run';
      await expectLater(store.persistFresh(_parse(corrupt)),
          _error('game_snapshot_conflict'));
      final sameTime = jsonDecode(jsonEncode(reserved)) as Map<String, dynamic>;
      sameTime['data']['dragons'][0]['activeAdventureId'] = null;
      await expectLater(store.persistFresh(_parse(sameTime)),
          _error('game_snapshot_conflict'));
    });

    test(
        'later social claim offers preserve wallet and private revision fences',
        () async {
      final initial = _wire();
      await store.persistFresh(_parse(initial));
      final ready = _wire()..['server_time'] = '2026-09-07T12:00:01Z';
      ready['data']['adventures']['socialClaims'] = [
        {
          'id': _other,
          'kind': 'group',
          'catalogId': 'group_1',
          'dragonId': ready['data']['dragons'][0]['id'],
          'position': null,
          'readyAt': '2026-09-07T12:00:00Z'
        }
      ];
      await store.persistFresh(_parse(ready));
      await expectLater(
          store.persistFresh(_parse(initial)), _error('game_snapshot_stale'));
      final bad = jsonDecode(jsonEncode(ready)) as Map<String, dynamic>;
      bad['server_time'] = '2026-09-07T12:00:02Z';
      bad['data']['wallet']['coins'] += 10;
      await expectLater(
          store.persistFresh(_parse(bad)), _error('game_snapshot_conflict'));
    });

    test(
        'trade expiry updates reservations, but cannot alter counts or egg identity at the same revision',
        () async {
      final initial = _wire();
      final eggId = initial['data']['eggs'][0]['id'];
      initial['data']['inventory']['reservedOnlineTradeEggIds'] = [eggId];
      await store.persistFresh(_parse(initial));
      final released = jsonDecode(jsonEncode(initial)) as Map<String, dynamic>;
      released['server_time'] = '2026-09-07T12:00:01Z';
      released['data']['inventory']['reservedOnlineTradeEggIds'] = [];
      await store.persistFresh(_parse(released));
      final corrupted =
          jsonDecode(jsonEncode(released)) as Map<String, dynamic>;
      corrupted['server_time'] = '2026-09-07T12:00:02Z';
      corrupted['data']['inventory']['chestInventory']['gold'] += 1;
      await expectLater(store.persistFresh(_parse(corrupted)),
          _error('game_snapshot_conflict'));
      corrupted['data']['inventory']['chestInventory']['gold'] -= 1;
      corrupted['data']['eggs'][0]['xp'] += 1;
      await expectLater(store.persistFresh(_parse(corrupted)),
          _error('game_snapshot_conflict'));
      await expectLater(
          store.persistFresh(_parse(initial)), _error('game_snapshot_stale'));
    });

    test('equal-revision conflicts and account path traversal are refused',
        () async {
      await store.persistFresh(_parse(_wire()));
      final changed = _wire();
      changed['data']['wallet']['coins'] = 999999;
      await expectLater(store.persistFresh(_parse(changed)),
          _error('game_snapshot_conflict'));
      await expectLater(
          store.inspect('../somebody-else'), _error('game_snapshot_invalid'));
      expect((await store.inspect(_owner)).snapshot!.coins,
          _data['wallet']['coins']);
    });

    test(
        'a new ruleset can update an unchanged game, and delayed old rules cannot replace it',
        () async {
      await store.persistFresh(_parse(_wire()));
      final upgraded = _wire()
        ..['ruleset_revision'] = 3
        ..['ruleset_sha256'] = 'ef' * 32;
      upgraded['data']['eggs'][0]['hints']['en'] = 'Updated clue presentation';
      await store.persistFresh(_parse(upgraded));
      final current = await store.inspect(_owner);
      expect(current.minimumRevision, 5);
      expect(current.minimumRulesetRevision, 3);
      expect(
          current.snapshot!.eggs.first.hint('en'), 'Updated clue presentation');
      await expectLater(
          store.persistFresh(_parse(_wire())), _error('game_snapshot_stale'));
      await expectLater(store.persistFresh(_parse(_wire(revision: 6))),
          _error('game_snapshot_stale'));
      final invalidHash = _wire(revision: 6)
        ..['ruleset_revision'] = 3
        ..['ruleset_sha256'] = '12' * 32;
      await expectLater(store.persistFresh(_parse(invalidHash)),
          _error('game_snapshot_conflict'));
    });

    test('an interrupted rules-only update preserves its independent minimum',
        () async {
      await store.persistFresh(_parse(_wire()));
      final upgraded = _wire()
        ..['ruleset_revision'] = 3
        ..['ruleset_sha256'] = 'ef' * 32;
      final obstruction = Directory(file('.json.tmp').path);
      await obstruction.create();
      await expectLater(store.persistFresh(_parse(upgraded)),
          throwsA(isA<FileSystemException>()));
      final broken = await store.inspect(_owner);
      expect(broken.snapshot, isNull);
      expect(broken.minimumRulesetRevision, 3);
      expect(broken.minimumRevision, 5);
      await obstruction.delete();
      await expectLater(
          store.persistFresh(_parse(_wire())), _error('game_snapshot_stale'));
      await store.persistFresh(_parse(upgraded));
      expect((await store.inspect(_owner)).snapshot!.rulesetRevision, 3);
    });
  });
}
