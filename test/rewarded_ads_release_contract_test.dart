import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android build variants fence test and production rewarded ads', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('!dragonHavenEnvironment.isNullOrBlank()'));
    expect(gradle, contains('dragonHavenEnvironment != "production"'));
    expect(
      gradle,
      contains('requestsNonReleaseBuild && !requestsReleaseBuild'),
    );
    expect(gradle, contains('dragonHavenEnvironment == "production"'));
    expect(
      gradle,
      contains('requestsReleaseBuild && !requestsNonReleaseBuild'),
    );
    expect(
      gradle,
      contains(
          'appPublisher == gemsPublisher && appPublisher == coinsPublisher'),
    );
  });

  test('release verifies local SSV and live deployment before ad build', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();
    final configure = workflow.indexOf(
      'name: Configure optional production rewarded ads',
    );
    final denoTest =
        workflow.indexOf('deno test supabase/functions/rewarded-ad-ssv/');
    final preflight = workflow.indexOf(
      './tool/release_server_preflight.ps1 @preflight',
    );
    final build = workflow.indexOf('flutter build appbundle --release');

    expect(workflow,
        contains('deno check supabase/functions/rewarded-ad-ssv/index.ts'));
    expect(configure, greaterThan(-1));
    expect(workflow, contains('-SsvSourceRevision \$env:GITHUB_SHA'));
    expect(denoTest, greaterThan(-1));
    expect(preflight, greaterThan(configure));
    expect(preflight, greaterThan(denoTest));
    expect(build, greaterThan(preflight));
    expect(workflow, contains('RequireRewardedAds = \$true'));
    expect(
      workflow,
      contains('ExpectedRewardedSsvSourceRevision = \$env:GITHUB_SHA'),
    );
  });

  test('server preflight requires deployed SSV source and config parity', () {
    final preflight =
        File('tool/release_server_preflight.ps1').readAsStringSync();

    expect(preflight, contains('[switch]\$RequireRewardedAds'));
    expect(preflight, contains('/functions/v1/rewarded-ad-ssv?health=1'));
    expect(preflight, contains('api.supabase.com/v1/projects/'));
    expect(
        preflight, contains("[string]\$rewardedFunction.status -cne 'ACTIVE'"));
    expect(preflight, contains("PSObject.Properties['verify_jwt']"));
    expect(preflight, contains('\$verifyJwtProperty.Value -isnot [bool]'));
    expect(preflight, contains('[bool]\$verifyJwtProperty.Value -ne \$false'));
    expect(preflight, contains('[string]\$rewarded.sourceRevision -cne'));
    expect(preflight, contains('[string]\$rewarded.gemsAdUnitId -cne'));
    expect(preflight, contains('[string]\$rewarded.coinsAdUnitId -cne'));
    expect(preflight, contains("\$result['RewardedAdsVerified'] = \$true"));
  });
}
