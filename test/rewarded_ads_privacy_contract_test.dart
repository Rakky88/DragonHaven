import 'dart:io';

import 'package:dragon_haven/services/privacy_notice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rewarded-ad privacy notice and server acknowledgement stay versioned',
      () {
    const version = '2026-09-23';
    final migration =
        File('supabase/migrations/202609230095_rewarded_ads_privacy_notice.sql')
            .readAsStringSync();
    final publicNotice = File('PRIVACY.md').readAsStringSync();
    final setup = File('REWARDED_CHESTS_SETUP.md').readAsStringSync();

    expect(PrivacyNotice.version, version);
    expect(PrivacyNotice.text(dutch: false), contains('Google Mobile Ads'));
    expect(PrivacyNotice.text(dutch: true), contains('Google Mobile Ads'));
    expect(migration, contains("notice_version='$version'"));
    expect(migration, contains("p_version is distinct from '$version'"));
    expect(
        migration,
        contains(
            'create or replace function private.rewarded_ad_account_ready'));
    expect(migration,
        contains("a.user_id=p_owner and a.notice_version='$version'"));
    expect(migration, contains('begin_server_account_initialization'));
    expect(publicNotice, contains('Version $version'));
    expect(publicNotice, contains('Versie $version'));
    expect(setup, contains(version));
  });
}
