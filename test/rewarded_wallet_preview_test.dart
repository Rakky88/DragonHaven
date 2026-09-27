import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dragon_haven/models/game_presentation.dart';
import 'package:dragon_haven/services/canonical_game_session.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/game_domain_probe.dart';
import 'support/canonical_ui_server.dart';

const _gemsClaim = '22222222-2222-4222-8222-222222222222';
const _coinsClaim = '33333333-3333-4333-8333-333333333333';
const _otherOwner = '44444444-4444-4444-8444-444444444444';

class _AccountConnection extends CanonicalUiConnection {
  _AccountConnection(super.server);

  void signIn(String owner) {
    currentOwner = owner;
    sessionEpoch++;
  }

  @override
  Future<Object?> read(Map<String, dynamic> request) async {
    final value = await super.read(request) as Map<String, dynamic>;
    return {...value, 'owner_id': currentOwner};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> fixture;
  late CanonicalUiServer server;
  late _AccountConnection connection;
  late CanonicalGameSession session;
  late Directory directory;

  setUpAll(() async {
    fixture = (await runGameDomainProbe())['state'] as Map<String, dynamic>;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-reward-preview-');
    server = CanonicalUiServer(jsonDecode(jsonEncode(fixture)));
    connection = _AccountConnection(server);
    session =
        CanonicalGameSession(connection: connection, directory: directory);
    await session.synchronize();
  });
  tearDown(() async {
    await session.close();
    await directory.delete(recursive: true);
  });

  test(
      'earned wallet appears immediately but never becomes persisted authority',
      () async {
    final before = session.confirmedSnapshot!;
    session.previewRewardedAd(_gemsClaim, 'gems');
    session.previewRewardedAd(_coinsClaim, 'coins');

    final shown = session.snapshot!;
    expect(shown.gems, before.gems + 15);
    expect(shown.coins, before.coins + 150);
    expect(shown.isSpeculative, isTrue);
    expect(shown.canApplyToLiveGame, isFalse);
    expect(session.confirmedSnapshot, same(before));
    expect(session.snapshot, same(shown));
    expect(() => shown.toJson(), throwsStateError);
    await expectLater(session.snapshots.persistFresh(shown),
        throwsA(isA<CanonicalGameException>()));
    final cached =
        (await session.snapshots.inspect(CanonicalUiServer.owner)).snapshot!;
    expect(cached.coins, before.coins);
    expect(cached.gems, before.gems);
    expect(server.sent, isEmpty);
  });

  test('duplicate SDK callbacks cannot add or change one claim twice', () {
    final before = session.confirmedSnapshot!;
    session.previewRewardedAd(_gemsClaim, 'gems');
    final shown = session.snapshot!;
    session.previewRewardedAd(_gemsClaim, 'gems');
    session.previewRewardedAd(_gemsClaim, 'coins');
    session.previewRewardedAd(_coinsClaim, 'unrecognized');
    expect(session.snapshot, same(shown));
    expect(session.snapshot!.gems, before.gems + 15);
    expect(session.snapshot!.coins, before.coins);
    session.settleRewardedAdPreview(_gemsClaim);
    expect(session.snapshot, same(before));
  });

  test(
      'unverified credit cannot authorize spending even if the displayed wallet can',
      () async {
    server.state['pet']['gems'] = 240;
    server.revision++;
    await session.synchronize();
    final chestCount = session.snapshot!.shop.chests['music'] ?? 0;
    session.previewRewardedAd(_gemsClaim, 'gems');
    expect(session.snapshot!.gems, 255);

    final receipt = await session.execute('purchase_music_chest', {});
    expect(receipt!.result, 'insufficientGems');
    expect(session.confirmedSnapshot!.gems, 240);
    expect(session.snapshot!.gems, 255);
    expect(session.snapshot!.shop.chests['music'] ?? 0, chestCount);
    session.settleRewardedAdPreview(_gemsClaim);
    expect(session.snapshot!.gems, 240);
  });

  test(
      'reward overlays compose with normal queued purchases and their confirmations',
      () async {
    final before = session.confirmedSnapshot!;
    session.previewRewardedAd(_gemsClaim, 'gems');
    session.previewRewardedAd(_coinsClaim, 'coins');
    final hold = Completer<void>();
    server.hold = hold.future;
    final title = session.execute('purchase_title_chest', {});
    final music = session.execute('purchase_music_chest', {});
    expect(session.snapshot!.coins, before.coins - 500 + 150);
    expect(session.snapshot!.gems, before.gems - 250 + 15);
    expect(session.canAct, isTrue);
    hold.complete();
    final receipts = await Future.wait([title, music]);
    expect(receipts.every((r) => r!.succeeded), isTrue);
    expect(session.confirmedSnapshot!.coins, before.coins - 500);
    expect(session.confirmedSnapshot!.gems, before.gems - 250);
    expect(session.snapshot!.coins, before.coins - 500 + 150);
    expect(session.snapshot!.gems, before.gems - 250 + 15);

    session.settleRewardedAdPreview(_gemsClaim);
    expect(session.snapshot!.coins, before.coins - 500 + 150);
    expect(session.snapshot!.gems, before.gems - 250);
    session.settleRewardedAdPreview(_coinsClaim);
    expect(session.snapshot, same(session.confirmedSnapshot));
  });

  test(
      'committed credit replaces its overlay atomically and late callbacks stay deduplicated',
      () async {
    final before = session.confirmedSnapshot!;
    session.previewRewardedAd(_gemsClaim, 'gems');
    session.previewRewardedAd(_coinsClaim, 'coins');
    final observed = <({int gems, int coins})>[];
    void record() {
      final snapshot = session.snapshot;
      if (snapshot != null) {
        observed.add((gems: snapshot.gems, coins: snapshot.coins));
      }
    }

    session.addListener(record);
    addTearDown(() => session.removeListener(record));
    server.state['pet']['gems'] = before.gems + 15;
    (server.state['pendingPresentations'] as List).add(GamePresentation(
      id: 'rewarded-ad-$_gemsClaim',
      type: GamePresentationType.rewardedCurrency,
      createdAt: server.now,
      sortAt: server.now,
      payload: const {'currency': 'gems', 'amount': 15, 'claimId': _gemsClaim},
    ).toJson());
    server.revision++;
    await session.synchronize();

    expect(session.hasConfirmedRewardedAd(_gemsClaim), isTrue);
    expect(session.confirmedSnapshot!.gems, before.gems + 15);
    expect(session.snapshot!.gems, before.gems + 15);
    expect(session.snapshot!.coins, before.coins + 150);
    expect(observed, isNotEmpty);
    expect(
        observed.every(
            (v) => v.gems == before.gems + 15 && v.coins == before.coins + 150),
        isTrue);

    await session.execute(
        'complete_presentation', {'presentationId': 'rewarded-ad-$_gemsClaim'});
    expect(
        session.confirmedSnapshot!.presentations
            .any((p) => p.id == 'rewarded-ad-$_gemsClaim'),
        isFalse);
    session.previewRewardedAd(_gemsClaim, 'gems');
    expect(session.snapshot!.gems, before.gems + 15);
    expect(session.hasConfirmedRewardedAd(_gemsClaim), isTrue);
    session.settleRewardedAdPreview(_coinsClaim);
    expect(session.snapshot, same(session.confirmedSnapshot));
  });

  test(
      'sign-out and account changes discard transient rewards without leaking them',
      () async {
    final original = session.confirmedSnapshot!;
    session.previewRewardedAd(_gemsClaim, 'gems');
    session.previewRewardedAd(_coinsClaim, 'coins');
    connection.signOut();
    expect(session.snapshot, isNull);

    connection.signIn(_otherOwner);
    server.state['pet']['coins'] = 50;
    server.state['pet']['gems'] = 5;
    server.revision++;
    await session.synchronize();
    expect(session.snapshot!.ownerId, _otherOwner);
    expect(session.snapshot!.coins, 50);
    expect(session.snapshot!.gems, 5);
    expect(session.snapshot!.isSpeculative, isFalse);
    final cachedOriginal =
        (await session.snapshots.inspect(CanonicalUiServer.owner)).snapshot!;
    expect(cachedOriginal.coins, original.coins);
    expect(cachedOriginal.gems, original.gems);
  });
}
