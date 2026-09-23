import 'dart:io';

import 'package:dragon_haven/services/privacy_notice.dart';
import 'package:flutter_test/flutter_test.dart';

const _currentVersion = '2026-09-23';
const _legacyVersion = '2026-09-20';

String _compact(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  late String migration;
  late String compact;

  setUpAll(() {
    migration = File(
      'supabase/migrations/202609230095_rewarded_ads_privacy_notice.sql',
    ).readAsStringSync();
    compact = _compact(migration);
  });

  test('rewarded-ad privacy notice stays accurately versioned', () {
    final publicNotice = File('PRIVACY.md').readAsStringSync();
    final setup = File('REWARDED_CHESTS_SETUP.md').readAsStringSync();

    expect(PrivacyNotice.version, _currentVersion);
    expect(PrivacyNotice.text(dutch: false), contains('Google Mobile Ads'));
    expect(PrivacyNotice.text(dutch: true), contains('Google Mobile Ads'));
    expect(publicNotice, contains('Version $_currentVersion'));
    expect(publicNotice, contains('Versie $_currentVersion'));
    expect(setup, contains(_currentVersion));
  });

  test('privacy rollout keeps the released client compatible', () {
    expect(
      compact,
      contains(
        "notice_version in ('$_legacyVersion','$_currentVersion')",
      ),
    );
    expect(
      compact,
      contains(
        'create or replace function public.'
        'get_my_privacy_acknowledgement_for_version( p_version text )',
      ),
    );
    expect(
      compact,
      contains('where user_id=keeper and notice_version=p_version'),
    );
    expect(
      compact,
      contains("p_version is distinct from '$_currentVersion'"),
    );
    expect(
      compact,
      contains(
        "p_version is distinct from '$_legacyVersion' and "
        "p_version is distinct from '$_currentVersion'",
      ),
    );
    expect(
      compact,
      contains(
        "not (account_privacy_acknowledgements.notice_version="
        "'$_currentVersion' and excluded.notice_version='$_legacyVersion')",
      ),
      reason: 'An older client must never downgrade a current acceptance.',
    );
    expect(
      compact,
      contains(
        'grant execute on function public.'
        'get_my_privacy_acknowledgement_for_version(text) to authenticated',
      ),
    );
  });

  test('only the current notice unlocks rewarded ads', () {
    expect(
      compact,
      contains(
        'create or replace function private.rewarded_ad_account_ready',
      ),
    );
    expect(
      compact,
      contains(
        "a.user_id=p_owner and a.notice_version='$_currentVersion'",
      ),
    );
    expect(compact, contains('begin_server_account_initialization'));
    expect(
      RegExp(
        "notice_version in \\('$_legacyVersion','$_currentVersion'\\)",
      ).allMatches(compact),
      hasLength(2),
      reason: 'Only the legacy getter and ordinary account initialization '
          'accept either notice version.',
    );
  });
}
