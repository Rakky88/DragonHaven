import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production server mutations are coupled to an app release', () {
    final policy = File('AGENTS.md').readAsStringSync();
    expect(policy, contains('# Production server release coupling'));
    expect(
      policy,
      contains(
        'Never deploy a new DragonHaven production Edge Function, apply a production',
      ),
    );
    expect(
      policy,
      contains('Production project `tnzathhutuwmohmjfrlo` must remain'),
    );

    final productionWorkflows = Directory('.github/workflows')
        .listSync()
        .whereType<File>()
        .where(
          (file) => file.uri.pathSegments.last.startsWith('production-'),
        )
        .toList();
    expect(productionWorkflows, isNotEmpty);
    for (final workflow in productionWorkflows) {
      final source = workflow.readAsStringSync();
      final runnableJobs =
          RegExp(r'^    runs-on:', multiLine: true).allMatches(source).length;
      final disabledJobs = RegExp(
        r'^    if: \$\{\{ false \}\}$',
        multiLine: true,
      ).allMatches(source).length;
      expect(
        disabledJobs,
        runnableJobs,
        reason:
            '${workflow.path} must retain history without exposing a standalone production mutation job.',
      );
    }

    final rollout =
        File('.github/workflows/game-ruleset-rollout.yml').readAsStringSync();
    expect(
      rollout,
      contains(
        "if: \${{ inputs.environment != 'production' || inputs.mode != 'apply' }}",
      ),
    );

    final release = File('.github/workflows/release.yml').readAsStringSync();
    expect(release, contains('release_server_preflight.ps1'));
    expect(release, contains('supabase db push --linked --include-all --yes'));
    expect(release, contains('supabase functions deploy rewarded-ad-ssv'));
    expect(release, contains('tool/game_ruleset_rollout.py'));
    expect(
      RegExp(
        r'name: Await public APK and activate matching game worker[\s\S]*?SUPABASE_ACCESS_TOKEN: \$\{\{ secrets\.SUPABASE_ACCESS_TOKEN \}\}',
      ).hasMatch(release),
      isTrue,
      reason: 'The guarded rollout needs the production Management API token.',
    );
    expect(
      RegExp(
        r'name: Verify final production server[\s\S]*?SUPABASE_ACCESS_TOKEN: \$\{\{ secrets\.SUPABASE_ACCESS_TOKEN \}\}',
      ).hasMatch(release),
      isTrue,
      reason: 'The mandatory final preflight needs the production token.',
    );
    expect(
      release.indexOf('flutter build appbundle --release'),
      lessThan(
        release.indexOf(
          'name: Apply matching production schema and rewarded-ad worker',
        ),
      ),
    );
  });
}
