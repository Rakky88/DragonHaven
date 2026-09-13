import 'dart:async';
import 'package:dragon_haven/models/social.dart';
import 'package:dragon_haven/services/canonical_legacy_upload.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const keeper = '11111111-1111-4111-8111-111111111111';

class Repository implements SocialRepository {
  @override
  String? currentUserId = keeper;
  @override
  bool get isSignedIn => currentUserId != null;
  CloudGameSave? remote;
  int pushes = 0;
  Future<void> Function()? duringPush;
  Map<String, dynamic>? uploaded;
  @override
  Future<CloudGameSave?> loadCloudGameSave() async => remote;
  @override
  Future<CloudGameSave> pushCloudGameSave(
      {required int expectedRevision,
      required Map<String, dynamic> state,
      required String deviceId,
      required String clientVersion}) async {
    expect(expectedRevision, remote?.revision ?? 0);
    pushes++;
    uploaded = state;
    remote = CloudGameSave(
        revision: expectedRevision + 1,
        state: state,
        updatedAt: DateTime.now(),
        deviceId: deviceId);
    await duringPush?.call();
    return remote!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Repository repository;
  late CanonicalLegacyUpload upload;
  int? base;
  var epoch = 1;
  var local = 1;
  var coins = 100;
  Future<void> Function(String)? settle;
  setUp(() {
    repository = Repository();
    base = null;
    epoch = 1;
    local = 1;
    coins = 100;
    settle = null;
    upload = CanonicalLegacyUpload(
        repository: repository,
        currentOwner: () => repository.currentUserId,
        sessionEpoch: () => epoch,
        settleLegacySources: (owner) async {
          await settle?.call(owner);
        },
        exportState: () => {
              'pet': {'coins': coins},
              'futureMetadata': {'kept': true}
            },
        localRevision: () => local,
        loadBaseRevision: (_) async => base,
        saveBaseRevision: (owner, revision) async {
          expect(owner, keeper);
          base = revision;
        },
        deviceId: () async => 'synthetic-device',
        clientVersion: 'test');
  });
  test('final upload captures settled rewards and preserves unknown metadata',
      () async {
    settle = (_) async {
      coins += 25;
      local++;
    };
    expect(await upload.upload(keeper), 1);
    expect(base, 1);
    expect(repository.uploaded!['pet'], {'coins': 125});
    expect(repository.uploaded!['futureMetadata'], {'kept': true});
    expect(repository.pushes, 1);
  });
  test('unknown cloud base never overwrites existing remote progress',
      () async {
    repository.remote = CloudGameSave(
        revision: 4,
        state: {},
        updatedAt: DateTime.now(),
        deviceId: 'other-device');
    await expectLater(
        upload.upload(keeper),
        throwsA(isA<SocialException>()
            .having((e) => e.code, 'code', 'cloud_save_conflict')));
    expect(repository.pushes, 0);
  });
  test('ABA account switch during source settlement refuses upload', () async {
    settle = (_) async {
      epoch += 2;
    };
    await expectLater(
        upload.upload(keeper),
        throwsA(isA<CanonicalGameException>()
            .having((e) => e.code, 'code', 'game_account_changed')));
    expect(repository.pushes, 0);
  });
  test('local change during upload keeps the new base but refuses activation',
      () async {
    repository.duringPush = () async {
      local++;
      coins++;
    };
    await expectLater(
        upload.upload(keeper),
        throwsA(isA<CanonicalGameException>()
            .having((e) => e.code, 'code', 'game_import_source_changed')));
    expect(base, 1);
    repository.duringPush = null;
    expect(await upload.upload(keeper), 2);
    expect(repository.uploaded!['pet'], {'coins': 101});
  });
  test('lost upload reply cannot silently replace its committed revision',
      () async {
    repository.duringPush = () async {
      throw TimeoutException('lost reply');
    };
    await expectLater(upload.upload(keeper), throwsA(isA<TimeoutException>()));
    expect(base, isNull);
    repository.duringPush = null;
    await expectLater(upload.upload(keeper), throwsA(isA<SocialException>()));
    expect(repository.pushes, 1);
  });
}
