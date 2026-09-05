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
      'productionTarget': false,
      'virtualUsers': 100,
      'result': 'passed',
      'errorRatePercent': 0.5,
    };
    expect(() => validateBaselineReport(passing), returnsNormally);
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

  test('percentiles use the conservative upper rank', () {
    final values = <int>[10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    expect(percentile(values, 50), 60);
    expect(percentile(values, 95), 100);
    expect(percentile(values, 99), 100);
    expect(percentile(const <int>[], 95), 0);
  });

  test('repository versions are derived without runtime credentials', () {
    expect(discoverAppVersion(), 'v0.05.10');
    expect(discoverMigrationVersion(), '202609020036');
  });
}
