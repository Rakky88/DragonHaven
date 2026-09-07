import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/staging_load_profile.dart';

void main() {
  test('load plan combines realistic reads with bounded pacing', () {
    final plan = buildLoadPlan(
      virtualUsers: 100,
      durationSeconds: 180,
      rampUpSeconds: 60,
      appVersion: 'v0.05.06',
      migrationVersion: '202608310032',
    );

    expect(plan['environment'], 'staging');
    expect(plan['productionTarget'], isFalse);
    expect(plan['virtualUsers'], 100);
    expect(plan['appVersion'], 'v0.05.06');
    expect(plan['applicationContractVersion'], 1);
    expect(plan['repositoryMigrationVersion'], '202608310032');
    expect(plan['serverMigrationVersionVerified'], isFalse);
    expect(plan['uniqueConfirmedSyntheticAccountsRequired'], 100);
    expect(plan['thinkTimeSeconds'], {'minimum': 8, 'maximum': 20});
    expect(
      browsingOperations.fold(0, (sum, item) => sum + item.weight),
      100,
    );
    expect(
      browsingOperations.map((item) => item.name),
      containsAll(<String>[
        'get_online_snapshot',
        'get_my_profile',
        'list_my_cloud_game_save_revisions',
        'list_group_adventures',
        'list_conclaves',
      ]),
    );
  });

  test('only audited 100 and 1000 user stages are accepted', () {
    expect(
      () => buildLoadPlan(
        virtualUsers: 99,
        durationSeconds: 180,
        rampUpSeconds: 60,
      ),
      throwsArgumentError,
    );
    expect(
      () => buildLoadPlan(
        virtualUsers: 5000,
        durationSeconds: 180,
        rampUpSeconds: 60,
      ),
      throwsArgumentError,
    );
    expect(
      buildLoadPlan(
        virtualUsers: 1000,
        durationSeconds: 180,
        rampUpSeconds: 60,
      )['sequentialGate'],
      contains('successful 100-user report'),
    );
  });

  test('production URL and project reference are both hard blocked', () {
    expect(
      () => validateExecutionTarget(
        url: productionUrl,
        projectRef: 'abcdefghijklmnopqrst',
        publishableKey: 'sb_publishable_test',
      ),
      throwsStateError,
    );
    expect(
      () => validateExecutionTarget(
        url: 'https://abcdefghijklmnopqrst.supabase.co',
        projectRef: productionProjectRef,
        publishableKey: 'sb_publishable_test',
      ),
      throwsStateError,
    );
    expect(
      () => validateExecutionTarget(
        url: 'https://abcdefghijklmnopqrst.supabase.co',
        projectRef: 'abcdefghijklmnopqrst',
        publishableKey: 'sb_publishable_test',
      ),
      returnsNormally,
    );
  });

  test('credential templates create unique accounts without reportable data',
      () {
    final credentials = parseCredentialPool(
      jsonEncode(<String, Object>{
        'emailTemplate': 'dragonhaven-load+{index}@example.invalid',
        'password': 'staging-only-password',
        'count': 100,
      }),
      100,
    );

    expect(credentials, hasLength(100));
    expect(credentials.map((item) => item.email).toSet(), hasLength(100));
    expect(
      () => parseCredentialPool(
        jsonEncode(<String, Object>{
          'accounts': <Map<String, String>>[
            <String, String>{
              'email': 'duplicate@example.invalid',
              'password': 'staging-only-password',
            },
            <String, String>{
              'email': 'duplicate@example.invalid',
              'password': 'staging-only-password',
            },
          ],
        }),
        2,
      ),
      throwsStateError,
    );
  });

  test('1000 user stage requires a clean 100 user report', () {
    final passing = <String, Object?>{
      'kind': 'dragonhaven-staging-load-report',
      'schemaVersion': 2,
      'measurementMode': loadMeasurementMode,
      'environment': 'staging',
      'warmupCompleted': true,
      'sessionsCoverMeasurement': true,
      'preparedUsers': 100,
      'peakConcurrentBrowsingUsers': 100,
      'steadyStateSeconds': 180,
      'minimumReadRequestsPerUser': 10,
      'productionTarget': false,
      'virtualUsers': 100,
      'authenticatedUsers': 100,
      'activeUsers': 100,
      'result': 'passed',
      'errorRatePercent': 0.5,
      'readErrorRatePercent': 0.5,
    };
    expect(() => validateBaselineReport(passing), returnsNormally);
    for (final invalid in <Map<String, Object?>>[
      {'schemaVersion': 1},
      {'measurementMode': 'login_burst'},
      {'peakConcurrentBrowsingUsers': 99},
      {'steadyStateSeconds': 179},
      {'minimumReadRequestsPerUser': 0},
      {'sessionsCoverMeasurement': false},
    ]) {
      expect(() => validateBaselineReport({...passing, ...invalid}),
          throwsStateError);
    }
    expect(() => validateBaselineReport({...passing, 'activeUsers': 99}),
        throwsStateError);
    expect(() => validateBaselineReport({...passing, 'authenticatedUsers': 99}),
        throwsStateError);
    expect(
        () => validateBaselineReport(passing, migrationVersion: '202609070047'),
        throwsStateError);
    expect(
        () => validateBaselineReport(
            {...passing, 'errorRatePercent': double.nan}),
        throwsStateError);
    expect(
      () => validateBaselineReport(<String, Object?>{
        ...passing,
        'errorRatePercent': 2.1,
      }),
      throwsStateError,
    );
    expect(
      () => validateBaselineReport(<String, Object?>{
        ...passing,
        'productionTarget': true,
      }),
      throwsStateError,
    );
  });

  test(
      'session setup paces ordinary logins and completes every bootstrap before browsing',
      () async {
    var now = DateTime.utc(2026, 9, 7);
    final calls = <(String, DateTime)>[];
    final metrics = <String, OperationMetrics>{};
    final sessions = await prepareLoadSessions(
        baseUrl: 'https://synthetic.invalid',
        publishableKey: 'sb_publishable_test',
        credentials: const [
          SyntheticCredential('a@synthetic.invalid', 'private-password'),
          SyntheticCredential('b@synthetic.invalid', 'private-password')
        ],
        metrics: metrics,
        clock: () => now,
        pause: (duration) async {
          now = now.add(duration);
        },
        request: (uri, headers, body, retain) async {
          calls.add((uri.path, now));
          return RequestResult(
              statusCode: 200,
              durationMs: 1,
              responseBytes: 10,
              bodyBytes: retain
                  ? utf8.encode(jsonEncode(
                      {'access_token': 'private-token', 'expires_in': 3600}))
                  : []);
        });
    expect(sessions, hasLength(2));
    expect(calls.map((call) => call.$1), [
      '/auth/v1/token',
      '/rest/v1/rpc/ensure_my_online_account',
      '/auth/v1/token',
      '/rest/v1/rpc/ensure_my_online_account'
    ]);
    expect(calls[2].$2.difference(calls[0].$2), loginSpacing);
    expect(
        jsonEncode({for (final e in metrics.entries) e.key: e.value.toJson()}),
        isNot(contains('private-')));
  });

  test('failed or expiring session setup never starts a partial read load',
      () async {
    for (final status in [429, 200]) {
      var reads = 0;
      var began = false;
      var now = DateTime.utc(2026, 9, 7);
      final report = await executeLoadProfile(
          baseUrl: 'https://synthetic.invalid',
          publishableKey: 'sb_publishable_test',
          credentials: const [
            SyntheticCredential('a@synthetic.invalid', 'private-password')
          ],
          durationSeconds: 180,
          rampUpSeconds: 60,
          maxErrorPercent: 2,
          appVersion: 'test',
          migrationVersion: '202609070047',
          clock: () => now,
          pause: (duration) async {
            now = now.add(duration);
          },
          onMeasurementStarted: () async {
            began = true;
          },
          requestOverride: (uri, headers, body, retain) async {
            if (uri.path == '/auth/v1/token') {
              return RequestResult(
                  statusCode: status,
                  durationMs: 1,
                  responseBytes: 10,
                  bodyBytes: utf8.encode(jsonEncode(
                      {'access_token': 'secret-session', 'expires_in': 30})));
            }
            if (!uri.path.endsWith('ensure_my_online_account')) reads++;
            return const RequestResult(
                statusCode: 200, durationMs: 1, responseBytes: 0);
          });
      expect(report['result'], 'failed');
      expect(report['activeUsers'], 0);
      expect(report['sessionsCoverMeasurement'], isFalse);
      expect(began, isFalse);
      expect(reads, 0);
      expect(jsonEncode(report), isNot(contains('secret-session')));
    }
  });

  test('percentiles use the conservative upper rank', () {
    final values = <int>[10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    expect(percentile(values, 50), 60);
    expect(percentile(values, 95), 100);
    expect(percentile(values, 99), 100);
    expect(percentile(const <int>[], 95), 0);
  });

  test('repository versions are derived without runtime credentials', () {
    expect(discoverAppVersion(), 'v0.05.17');
    expect(discoverMigrationVersion(), '202609070049');
  });
}
