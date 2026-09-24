import 'dart:async';
import 'dart:io';

import 'package:dragon_haven/services/canonical_account_bootstrap.dart';
import 'package:dragon_haven/services/canonical_account_handoff.dart';
import 'package:dragon_haven/services/canonical_game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = '11111111-1111-4111-8111-111111111111';
  const b = '22222222-2222-4222-8222-222222222222';
  late Directory directory;
  late StreamController<int> changes;
  String? owner;
  var epoch = 0;
  CanonicalAccountStatus status(String id,
          {bool active = false, bool migrating = false}) =>
      CanonicalAccountStatus.parse({
        'owner_id': id,
        'phase': active ? 'active' : 'legacy',
        'migration_enabled': migrating,
        'source_revision': active ? 6 : null,
        'server_revision': active ? 7 : null,
      }, id);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bootstrap-test-');
    changes = StreamController<int>.broadcast();
    owner = a;
    epoch = 1;
  });
  tearDown(() async {
    await changes.close();
    await directory.delete(recursive: true);
  });
  CanonicalAccountBootstrap<String> make({
    required Future<CanonicalAccountStatus> Function(String) read,
    required Future<CanonicalGameplayLease<String>> Function(String) legacy,
    Future<CanonicalAccountStatus> Function(String)? check,
    Future<CanonicalGameplayLease<String>> Function(String, int)? server,
    Future<int> Function(String)? upload,
    Future<int> Function(String, String, int)? activate,
  }) =>
      CanonicalAccountBootstrap<String>(
          directory: directory,
          currentOwner: () => owner,
          sessionEpoch: () => epoch,
          accountChanges: changes.stream,
          readStatus: read,
          checkConnection: check,
          openLegacy: legacy,
          openServer: server ??
              (_, __) async => throw StateError('unexpected server load'),
          prepareAndUploadLegacy: upload ??
              (_) async => throw StateError('unexpected legacy upload'),
          activate: activate ??
              (_, __, ___) async => throw StateError('unexpected activation'));
  Future<void> finish(CanonicalAccountBootstrap<String> root) async {
    await root.shutdown();
    root.dispose();
  }

  test(
      'active boot never loads local gameplay and keeps the confirmed revision',
      () async {
    var legacyLoads = 0;
    final root = make(
        read: (id) async => status(id, active: true),
        legacy: (_) async {
          legacyLoads++;
          throw StateError('legacy');
        },
        server: (id, revision) async {
          expect(id, a);
          expect(revision, 7);
          return CanonicalGameplayLease('server', close: () async {});
        });
    await root.synchronize();
    expect(root.phase, CanonicalBootstrapPhase.server);
    expect(root.gameplay, 'server');
    expect(legacyLoads, 0);
    await finish(root);
  });

  test('confirmed heartbeat owner and phase mismatches resynchronize at once',
      () async {
    for (final mismatch in [
      status(b, active: true),
      status(a),
    ]) {
      var opens = 0;
      var closes = 0;
      final root = make(
          read: (id) async => status(id, active: true),
          check: (_) async => mismatch,
          legacy: (_) async => throw StateError('unexpected legacy load'),
          server: (_, __) async => CanonicalGameplayLease('server-${++opens}',
              close: () async => closes++));
      await root.synchronize();
      expect(root.gameplay, 'server-1');

      await root.verifyConnection();

      expect(closes, 1);
      expect(opens, 2);
      expect(root.phase, CanonicalBootstrapPhase.server);
      expect(root.gameplay, 'server-2');
      await finish(root);
    }
  });

  test('confirmed migration mismatch retires a legacy lease immediately',
      () async {
    var migrating = false;
    var closes = 0;
    final root = make(
        read: (id) async => status(id, migrating: migrating),
        check: (id) async => status(id, migrating: migrating),
        legacy: (_) async => CanonicalGameplayLease('legacy', close: () async {
              closes++;
            }));
    await root.synchronize();
    expect(root.gameplay, 'legacy');

    migrating = true;
    await root.verifyConnection();

    expect(closes, 1);
    expect(root.gameplay, isNull);
    expect(root.phase, CanonicalBootstrapPhase.failed);
    await finish(root);
  });

  test('server heartbeat grants no grace to a non-transport failure', () async {
    var opens = 0;
    var closes = 0;
    final root = make(
        read: (id) async => status(id, active: true),
        check: (_) async =>
            throw const CanonicalGameException('game_login_required'),
        legacy: (_) async => throw StateError('unexpected legacy load'),
        server: (_, __) async =>
            CanonicalGameplayLease('server-${++opens}', close: () async {
              closes++;
            }));
    await root.synchronize();

    await root.verifyConnection();

    expect(closes, 1);
    expect(opens, 2);
    expect(root.gameplay, 'server-2');
    await finish(root);
  });

  test('unknown authority and signed out never silently load a local save',
      () async {
    var loads = 0;
    final root = make(
        read: (_) async =>
            throw const CanonicalGameException('game_migration_unavailable'),
        legacy: (_) async {
          loads++;
          throw StateError('legacy');
        });
    await root.synchronize();
    expect(root.phase, CanonicalBootstrapPhase.failed);
    expect(root.gameplay, isNull);
    owner = null;
    epoch++;
    await root.synchronize();
    expect(root.phase, CanonicalBootstrapPhase.signedOut);
    expect(loads, 0);
    await finish(root);
  });

  test('returning to foreground drains the old game before reading authority',
      () async {
    final closing = Completer<void>();
    var reads = 0;
    var loads = 0;
    final root = make(
        read: (id) async {
          reads++;
          return status(id);
        },
        legacy: (_) async => CanonicalGameplayLease('legacy-${++loads}',
            close: () => loads == 1 ? closing.future : Future.value()));
    await root.synchronize();
    final stopped = root.setForeground(false);
    expect(root.gameplay, isNull);
    final resumed = root.setForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(reads, 1);
    expect(loads, 1);
    closing.complete();
    await stopped;
    await resumed;
    expect(reads, 2);
    expect(root.gameplay, 'legacy-2');
    await finish(root);
  });

  test(
      'a late A load closes before B opens, even before its auth event is delivered',
      () async {
    final loadingA = Completer<CanonicalGameplayLease<String>>();
    final startedA = Completer<void>();
    final closedA = Completer<void>();
    final visible = <String>[];
    final root = make(
        read: (id) async => status(id),
        legacy: (id) {
          if (id == a) {
            startedA.complete();
            return loadingA.future;
          }
          expect(closedA.isCompleted, isTrue);
          return Future.value(CanonicalGameplayLease('B', close: () async {}));
        });
    root.addListener(() {
      if (root.gameplay != null) visible.add(root.gameplay!);
    });
    final boot = root.synchronize();
    await startedA.future;
    owner = b;
    epoch++;
    expect(root.gameplay, isNull);
    loadingA.complete(CanonicalGameplayLease('A', close: () async {
      closedA.complete();
    }));
    await boot;
    expect(root.gameplay, 'B');
    expect(visible, isNot(contains('A')));
    await finish(root);
  });

  test('pause-resume while status is pending requires a fresh check', () async {
    final first = Completer<CanonicalAccountStatus>();
    final started = Completer<void>();
    var reads = 0;
    var loads = 0;
    final root = make(read: (id) {
      if (++reads == 1) {
        started.complete();
        return first.future;
      }
      return Future.value(status(id));
    }, legacy: (_) async {
      loads++;
      return CanonicalGameplayLease('legacy', close: () async {});
    });
    final boot = root.synchronize();
    await started.future;
    unawaited(root.setForeground(false));
    unawaited(root.setForeground(true));
    first.complete(status(a));
    await boot;
    expect(reads, 2);
    expect(loads, 1);
    await finish(root);
  });

  test('missing source ownership refuses activation and all gameplay',
      () async {
    var activated = false;
    final root = make(
        read: (id) async => status(id, migrating: true),
        legacy: (_) async => throw StateError('must not load UI'),
        upload: (_) async => throw const CanonicalGameException(
            'game_import_source_owner_required'),
        activate: (_, __, ___) async {
          activated = true;
          return 8;
        });
    await root.synchronize();
    expect(root.phase, CanonicalBootstrapPhase.failed);
    expect(root.errorCode, 'game_import_source_owner_required');
    expect(root.gameplay, isNull);
    expect(activated, isFalse);
    await finish(root);
  });

  test(
      'migration passes the final upload and activation revision without opening legacy UI',
      () async {
    final calls = <String>[];
    final root = make(
        read: (id) async => status(id, migrating: true),
        legacy: (_) async => throw StateError('must not load UI'),
        upload: (id) async {
          calls.add('upload:$id');
          return 10;
        },
        activate: (id, request, revision) async {
          expect(revision, 10);
          calls.add('activate:$id');
          return 12;
        },
        server: (id, revision) async {
          expect(revision, 12);
          calls.add('server:$id');
          return CanonicalGameplayLease('server', close: () async {});
        });
    await root.synchronize();
    expect(calls, ['upload:$a', 'activate:$a', 'server:$a']);
    expect(root.phase, CanonicalBootstrapPhase.server);
    await finish(root);
  });

  test('failure to drain an old root prevents opening another one', () async {
    var reads = 0;
    final root = make(
        read: (id) async {
          reads++;
          return status(id);
        },
        legacy: (_) async => CanonicalGameplayLease('legacy',
            close: () async => throw StateError('unsaved source')));
    await root.synchronize();
    owner = b;
    epoch++;
    await root.synchronize();
    expect(root.gameplay, isNull);
    expect(root.phase, CanonicalBootstrapPhase.failed);
    expect(reads, 1);
    await expectLater(root.shutdown(), throwsStateError);
    root.dispose();
  });
}
