import 'dart:async';
import 'dart:convert';

import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/models/egg_altar.dart';
import 'package:dragon_haven/providers/household_provider.dart';
import 'package:dragon_haven/services/account_legacy_game_storage.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
String key(String owner) => 'dragon_haven_account_legacy_v1_$owner';

class _Repository extends Fake implements SocialRepository {
  String owner = a;
  late Future<CloudGameSave?> Function() read;
  @override
  String get currentUserId => owner;
  @override
  bool get isSignedIn => true;
  @override
  Future<CloudGameSave?> loadCloudGameSave() => read();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repository repository;
  late Map<String, dynamic> source;
  var epoch = 0;
  Future<AccountLegacyGameStorage> import() =>
      AccountLegacyGameStorage.importCloud(
          repository: repository,
          owner: repository.owner,
          currentOwner: () => repository.owner,
          sessionEpoch: () => epoch);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    epoch = 0;
    final game = HouseholdProvider(persistenceEnabled: false);
    source = game.exportState()..['futureMetadata'] = {'kept': true};
    game.dispose();
    repository = _Repository()
      ..read = () async => CloudGameSave(
          revision: 7,
          state: source,
          updatedAt: DateTime.now(),
          deviceId: 'test');
  });

  test('sign-in cannot adopt a device-global save', () async {
    await StorageService.save(source);
    expect(await AccountLegacyGameStorage.open(a), isNull);
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString(StorageService.currentKey);
    final scoped = await import();
    expect(scoped.owner, a);
    expect(await scoped.cloudBaseRevision(), 7);
    expect(prefs.getString(StorageService.currentKey), before);
  });

  Future<AccountSaveReview> review() => AccountLegacyGameStorage.reviewSources(
      repository: repository,
      owner: repository.owner,
      currentOwner: () => repository.owner,
      sessionEpoch: () => epoch);
  Future<AccountLegacyGameStorage> choose(
          AccountSaveReview comparison, AccountSaveChoice choice) =>
      AccountLegacyGameStorage.chooseSource(
          review: comparison,
          choice: choice,
          repository: repository,
          currentOwner: () => repository.owner,
          sessionEpoch: () => epoch);

  test('explicit local choice retains both copies and binds only this account',
      () async {
    final local = {
      ...source,
      'accountName': 'Latest device',
      'futureField': 42
    };
    await StorageService.save(local);
    final comparison = await review();
    expect(comparison.needsChoice, true);
    expect(await AccountLegacyGameStorage.open(a), isNull);
    comparison.local!['accountName'] = 'Mutated preview';
    final selected = await choose(comparison, AccountSaveChoice.local);
    expect(await selected.load(), local);
    expect(await selected.cloudBaseRevision(), 7);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(StorageService.currentKey)!), local);
    final evidence = jsonDecode(prefs.getString('${key(a)}_source_review')!);
    expect(evidence['local'], local);
    expect(evidence['cloud'], source);
    repository.owner = b;
    final other = await review();
    expect(other.local, isNull);
    expect(await AccountLegacyGameStorage.open(b), isNull);
  });

  test(
      'changed cloud or device refuses a stale comparison without replacing progress',
      () async {
    await StorageService.save(source);
    final comparison = await review();
    await StorageService.save({...source, 'accountName': 'Newer'});
    await expectLater(choose(comparison, AccountSaveChoice.cloud),
        throwsA(isA<CanonicalGameException>()));
    expect(await AccountLegacyGameStorage.open(a), isNull);
    final updated = await review();
    repository.read = () async => CloudGameSave(
        revision: 8,
        state: source,
        updatedAt: DateTime.now(),
        deviceId: 'other');
    await expectLater(choose(updated, AccountSaveChoice.local),
        throwsA(isA<SocialException>()));
    expect(await AccountLegacyGameStorage.open(a), isNull);
  });

  test('cloud choice cannot discard an unresolved local Altar request',
      () async {
    final local = {
      ...source,
      'pendingAltarOperation': {'id': 'original', 'action': 'tag'}
    };
    await StorageService.save(local);
    final comparison = await review();
    expect(comparison.canChooseCloud, false);
    await expectLater(choose(comparison, AccountSaveChoice.cloud),
        throwsA(isA<CanonicalGameException>()));
    final selected = await choose(comparison, AccountSaveChoice.local);
    expect((await selected.load())!['pendingAltarOperation'],
        local['pendingAltarOperation']);
  });

  test(
      'cloud choice preserves the old owner save and cannot be reused after A-B-A',
      () async {
    final store = await import();
    final local = {...source, 'accountName': 'Newer local'};
    await store.save(local);
    final comparison = await review();
    epoch += 2;
    await expectLater(choose(comparison, AccountSaveChoice.cloud),
        throwsA(isA<CanonicalGameException>()));
    expect(await store.load(), local);
    final selected = await choose(await review(), AccountSaveChoice.cloud);
    expect(await selected.load(), source);
    expect(await selected.loadBackup(), local);
  });

  test(
      'an account without cloud can explicitly adopt local progress at revision zero',
      () async {
    await StorageService.save(source);
    repository.read = () async => null;
    final selected = await choose(await review(), AccountSaveChoice.local);
    expect(await selected.cloudBaseRevision(), 0);
    await selected.save({...source, 'languageCode': 'nl'});
    expect((await selected.load())!['languageCode'], 'nl');
    await selected.saveCloudBaseRevision(1);
    expect(await selected.cloudBaseRevision(), 1);
  });

  test(
      'retiring A preserves its journal while B can open; migration still refuses',
      () async {
    final storeA = await import();
    final gameA = await HouseholdProvider.loadFromStorage(storage: storeA);
    gameA.pendingAltarOperation = {
      'id': 'original-request',
      'action': 'tag',
      'payload': {'eggId': 'one'}
    };
    await gameA.retireLegacySave();
    await expectLater(
        gameA.sealLegacySave(),
        throwsA(isA<EggAltarException>()
            .having((e) => e.code, 'code', 'altar_pending')));
    repository.owner = b;
    final storeB = await import();
    final gameB = await HouseholdProvider.loadFromStorage(storage: storeB);
    expect(gameB.pendingAltarOperation, isNull);
    await gameB.setLanguage('de');
    final reopenedA = await AccountLegacyGameStorage.open(a);
    expect((await reopenedA!.load())!['pendingAltarOperation']['id'],
        'original-request');
    await expectLater(gameA.setLanguage('nl'), throwsStateError);
    expect((await storeB.load())!['languageCode'], 'de');
    gameA.dispose();
    gameB.dispose();
  });

  test('late writes stay with their original owner and preserve metadata',
      () async {
    final first = await import();
    repository.owner = b;
    final second = await import();
    final gameA = await HouseholdProvider.loadFromStorage(storage: first);
    final gameB = await HouseholdProvider.loadFromStorage(storage: second);
    await gameB.setLanguage('de');
    await gameA.setLanguage('nl');
    final sealed = await gameA.sealLegacySave();
    expect(jsonDecode(sealed.json)['futureMetadata'], {'kept': true});
    expect((await first.load())!['languageCode'], 'nl');
    expect((await second.load())!['languageCode'], 'de');
    expect((await first.load())!['futureMetadata'], {'kept': true});
    await first.saveCloudBaseRevision(8);
    expect(await first.cloudBaseRevision(), 8);
    expect(await second.cloudBaseRevision(), 7);
    gameA.dispose();
    gameB.dispose();
  });

  test('a cloud response after A-B-A cannot establish a source', () async {
    final response = Completer<CloudGameSave?>();
    repository.read = () => response.future;
    final rejected =
        expectLater(import(), throwsA(isA<CanonicalGameException>()));
    repository.owner = b;
    epoch++;
    repository.owner = a;
    epoch++;
    response.complete(CloudGameSave(
        revision: 7,
        state: source,
        updatedAt: DateTime.now(),
        deviceId: 'test'));
    await rejected;
    expect(await AccountLegacyGameStorage.open(a), isNull);
    expect(await AccountLegacyGameStorage.open(b), isNull);
  });

  test('an existing local account source is never silently overwritten',
      () async {
    final store = await import();
    final saved = {...source, 'languageCode': 'nl'};
    await store.save(saved);
    await expectLater(import(), throwsA(isA<CanonicalGameException>()));
    expect((await store.load())!['languageCode'], 'nl');
  });

  test('corrupt current recovers only its own backup and preserves bad bytes',
      () async {
    final store = await import();
    await store.save({...source, 'languageCode': 'nl'});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key(a), 'broken');
    final recovered = await AccountLegacyGameStorage.open(a);
    expect(await recovered!.load(), source);
    expect(prefs.getString('${key(a)}_recovery'), 'broken');
    expect(await AccountLegacyGameStorage.open(b), isNull);
  });

  test('foreign owner envelope cannot be opened or overwritten', () async {
    await import();
    final prefs = await SharedPreferences.getInstance();
    final foreign = jsonDecode(prefs.getString(key(a))!) as Map;
    foreign['owner'] = b;
    final raw = jsonEncode(foreign);
    await prefs.setString(key(a), raw);
    await expectLater(AccountLegacyGameStorage.open(a),
        throwsA(isA<CanonicalGameException>()));
    expect(prefs.getString(key(a)), raw);
  });

  test('invalid account game cannot be replaced by a fresh dragon', () async {
    source = {'languageCode': 'nl'};
    final store = await import();
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString(key(a));
    await expectLater(
        HouseholdProvider.loadFromStorage(storage: store), throwsStateError);
    expect(prefs.getString(key(a)), before);
  });

  test('game recovery cannot overwrite its valid backup while validating',
      () async {
    final store = await import();
    await store.save({...source, 'languageCode': 'de'});
    final prefs = await SharedPreferences.getInstance();
    final record = jsonDecode(prefs.getString(key(a))!) as Map;
    record['state'] = {'languageCode': 'nl'};
    final broken = jsonEncode(record);
    await prefs.setString(key(a), broken);
    final reopened = await AccountLegacyGameStorage.open(a);
    final game = await HouseholdProvider.loadFromStorage(storage: reopened!);
    expect(game.pet.id, (source['pet'] as Map)['id']);
    expect((await reopened.load())!['futureMetadata'], {'kept': true});
    expect(prefs.getString('${key(a)}_recovery'), broken);
    game.dispose();
  });
}
