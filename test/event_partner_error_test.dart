import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/services/social_repository.dart';
import 'package:dragon_haven/widgets/event_partner_control.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('partner failures distinguish cloud conflict from reserved partner', () {
    const strings = AppStrings('en');
    expect(
        eventPartnerErrorMessage(
            strings, const SocialException('cloud_save_conflict')),
        contains('Account Info'));
    expect(
        eventPartnerErrorMessage(
            strings,
            const PostgrestException(
                message: 'event_partner_already_selected')),
        contains('already has a partner'));
    expect(
        eventPartnerErrorMessage(strings,
            const PostgrestException(message: 'event_friend_required')),
        contains('accepted friends'));
    expect(
        eventPartnerErrorMessage(strings,
            const PostgrestException(message: 'private database detail')),
        isNot(contains('private database detail')));
  });
}
