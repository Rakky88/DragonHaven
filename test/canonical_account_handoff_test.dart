import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dragon_haven/services/canonical_account_handoff.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

const keeper = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
Matcher error(String code) =>
    throwsA(isA<CanonicalGameException>().having((e) => e.code, 'code', code));
CanonicalAccountStatus status(String owner,
        {String phase = 'legacy', bool enabled = true}) =>
    CanonicalAccountStatus.parse({
      'owner_id': owner,
      'phase': phase,
      'migration_enabled': enabled,
      'source_revision': phase == 'legacy' ? null : 42,
      'server_revision': phase == 'active' ? 3 : null
    }, owner);

void main() {
  late Directory directory;
  late CanonicalAccountHandoff handoff;
  var owner = keeper;
  var epoch = 1;
  var uploads = 0;
  var ids = 0;
  late Future<CanonicalAccountStatus> Function(String) read;
  late Future<int> Function(String, String, int) activate;
  CanonicalAccountHandoff build() => CanonicalAccountHandoff(
      directory: directory,
      currentOwner: () => owner,
      sessionEpoch: () => epoch,
      readStatus: (id) => read(id),
      prepareAndUploadLegacy: (id) async {
        expect(id, owner);
        uploads++;
        return 42 + uploads - 1;
      },
      activate: (id, request, revision) => activate(id, request, revision),
      newRequestId: () =>
          '33333333-3333-4333-8333-${(++ids).toString().padLeft(12, '0')}');
  File getIntent() => File('${directory.path}/migration-v1-$keeper.json');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dh-handoff-test-');
    owner = keeper;
    epoch = 1;
    uploads = 0;
    ids = 0;
    read = (id) async => status(id);
    activate = (id, request, revision) async => 3;
    handoff = build();
  });
  tearDown(() async {
    handoff.dispose();
    await directory.delete(recursive: true);
  });

  test(
      'lost committed activation resumes through status without another upload',
      () async {
    var active = false;
    var calls = 0;
    read = (id) async => status(id, phase: active ? 'active' : 'legacy');
    activate = (id, request, revision) async {
      expect(jsonDecode(await getIntent().readAsString()),
          {'owner': keeper, 'requestId': request, 'sourceRevision': 42});
      calls++;
      active = true;
      throw const CanonicalGameException('game_command_unavailable');
    };
    await expectLater(handoff.synchronize(), error('game_command_unavailable'));
    expect(handoff.phase, CanonicalHandoffPhase.failed);
    expect(await getIntent().exists(), isTrue);
    handoff.dispose();
    handoff = build();
    await handoff.synchronize();
    expect(handoff.phase, CanonicalHandoffPhase.server);
    expect(handoff.minimumServerRevision, 3);
    expect(uploads, 1);
    expect(calls, 1);
    expect(await getIntent().exists(), isFalse);
  });

  test(
      'lost request before activation keeps its UUID and upload across restart',
      () async {
    final sent = <String>[];
    activate = (id, request, revision) async {
      sent.add(request);
      expect(revision, 42);
      if (sent.length == 1) {
        throw const CanonicalGameException('game_command_unavailable');
      }
      return 3;
    };
    await expectLater(handoff.synchronize(), error('game_command_unavailable'));
    handoff.dispose();
    handoff = build();
    read = (id) async => status(id, phase: 'captured');
    await handoff.synchronize();
    expect(sent.length, 2);
    expect(sent[0], sent[1]);
    expect(uploads, 1);
    expect(handoff.phase, CanonicalHandoffPhase.server);
  });

  test(
      'stale source refusal reuploads with a new request while network failure cannot',
      () async {
    final sent = <String>[];
    activate = (id, request, revision) async {
      sent.add(request);
      if (sent.length == 1) {
        throw const CanonicalGameException('game_import_source_changed');
      }
      expect(revision, 43);
      return 3;
    };
    await expectLater(
        handoff.synchronize(), error('game_import_source_changed'));
    expect(await getIntent().exists(), isFalse);
    await handoff.synchronize();
    expect(uploads, 2);
    expect(sent[0], isNot(sent[1]));
  });

  test('unknown offline authority never permits legacy play or an upload',
      () async {
    read = (_) async =>
        throw const CanonicalGameException('game_migration_unavailable');
    await expectLater(
        handoff.synchronize(), error('game_migration_unavailable'));
    expect(handoff.phase, CanonicalHandoffPhase.failed);
    expect(uploads, 0);
    read = (id) async => status(id, enabled: false);
    await handoff.synchronize();
    expect(handoff.phase, CanonicalHandoffPhase.legacy);
    expect(uploads, 0);
  });

  test('A to B to A before a status reply cannot activate the wrong session',
      () async {
    final held = Completer<CanonicalAccountStatus>();
    read = (_) => held.future;
    final pending = handoff.synchronize();
    expect(identical(pending, handoff.synchronize()), isTrue);
    owner = other;
    epoch++;
    owner = keeper;
    epoch++;
    held.complete(status(keeper));
    await expectLater(pending, error('game_account_changed'));
    expect(handoff.phase, CanonicalHandoffPhase.checking);
    expect(uploads, 0);
    expect(await getIntent().exists(), isFalse);
  });

  test(
      'corrupt local journal cannot trigger an upload for an already active account',
      () async {
    await getIntent().writeAsString('broken');
    read = (id) async => status(id, phase: 'active');
    await handoff.synchronize();
    expect(handoff.phase, CanonicalHandoffPhase.server);
    expect(uploads, 0);
    expect(await getIntent().exists(), isFalse);
    expect(
        () => CanonicalAccountStatus.parse({
              'owner_id': other,
              'phase': 'active',
              'migration_enabled': true,
              'source_revision': 42,
              'server_revision': 3
            }, keeper),
        error('game_migration_status_invalid'));
  });
}
