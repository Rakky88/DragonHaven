import 'dart:async';
import 'dart:io';

import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/providers/online_account_provider.dart';
import 'package:dragon_haven/services/account_legacy_game_storage.dart';
import 'package:dragon_haven/services/canonical_legacy_account_source.dart';
import 'package:dragon_haven/services/egg_altar_repository.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const owner = '11111111-1111-4111-8111-111111111111';

class _Repository extends Fake implements SocialRepository {
  @override
  void dispose() {}
  late CloudGameSave remote;
  bool loseReply = false;
  int pushes = 0;
  Future<void> Function()? afterWrite;
  @override
  String get currentUserId => owner;
  @override
  bool get isSignedIn => true;
  @override
  Future<CloudGameSave?> loadCloudGameSave() async => remote;
  @override
  Future<CloudGameSave> pushCloudGameSave(
      {required int expectedRevision,
      required Map<String, dynamic> state,
      required String deviceId,
      required String clientVersion}) async {
    expect(expectedRevision, remote.revision);
    pushes++;
    remote = CloudGameSave(
        revision: expectedRevision + 1,
        state: state,
        updatedAt: DateTime.now(),
        deviceId: deviceId);
    await afterWrite?.call();
    if (loseReply) {
      loseReply = false;
      throw const SocialException('online_timeout');
    }
    return remote;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repository repository;
  late AccountLegacyGameStorage storage;
  late HouseholdProvider game;
  late SupabaseClient client;
  late CanonicalLegacyAccountSource source;
  late Directory directory;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('dh-account-source-');
    final initial = HouseholdProvider(persistenceEnabled: false);
    repository = _Repository()
      ..remote = CloudGameSave(
          revision: 7,
          state: initial.exportState()..['futureMetadata'] = 'preserved',
          updatedAt: DateTime.now(),
          deviceId: 'original');
    initial.dispose();
    storage = await AccountLegacyGameStorage.importCloud(
        repository: repository,
        owner: owner,
        currentOwner: () => owner,
        sessionEpoch: () => 0);
    game = await HouseholdProvider.loadFromStorage(storage: storage);
    client = SupabaseClient('https://example.test', 'synthetic-public-key');
    final online = OnlineAccountProvider(
        repository: repository,
        inventorySnapshot: () => OnlineInventorySnapshot.fromGame(game));
    final altar = EggAltarRepository(client, repository, game);
    source = CanonicalLegacyAccountSource(
        storage: storage,
        game: game,
        online: online,
        altar: altar,
        repository: repository,
        directory: directory,
        currentOwner: () => owner,
        sessionEpoch: () => 0,
        deviceId: () async => 'final-upload-device',
        clientVersion: 'test');
  });
  tearDown(() async {
    await source.close();
    await client.dispose();
    await directory.delete(recursive: true);
  });

  test('real local writers freeze once and a lost upload recovers one revision',
      () async {
    final pending = game.setLanguage('nl');
    repository.loseReply = true;
    await expectLater(source.upload(), throwsA(isA<SocialException>()));
    await pending;
    expect(repository.pushes, 1);
    expect(repository.remote.state['languageCode'], 'nl');
    expect(repository.remote.state['futureMetadata'], 'preserved');
    expect(await source.upload(), 8);
    expect(repository.pushes, 1);
    expect(await storage.cloudBaseRevision(), 8);
    expect(
        await File('${directory.path}/legacy-upload-v1-$owner.json').exists(),
        false);
    await expectLater(game.setLanguage('de'), throwsStateError);
    expect(repository.remote.state['languageCode'], 'nl');
  });

  test('closing waits for the actual final upload and then refuses new uploads',
      () async {
    final sent = Completer<void>();
    final response = Completer<void>();
    repository.afterWrite = () {
      sent.complete();
      return response.future;
    };
    final upload = source.upload();
    await sent.future;
    var closed = false;
    final closing = source.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, false);
    response.complete();
    expect(await upload, 8);
    await closing;
    expect(closed, true);
    await expectLater(source.upload(), throwsStateError);
  });
}
