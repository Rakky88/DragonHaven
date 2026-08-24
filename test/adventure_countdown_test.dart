import 'package:dragon_haven/l10n/app_strings.dart';
import 'package:dragon_haven/screens/adventure_hub_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 12);
  const english = AppStrings('en');
  const dutch = AppStrings('nl');

  test('adventure countdown switches to seconds for its final minute', () {
    expect(
      adventureRemainingLabel(
        now.add(const Duration(seconds: 61)),
        english,
        now: now,
      ),
      '1m',
    );
    expect(
      adventureRemainingLabel(
        now.add(const Duration(seconds: 60)),
        english,
        now: now,
      ),
      '60s',
    );
    expect(
      adventureRemainingLabel(
        now.add(const Duration(seconds: 17)),
        english,
        now: now,
      ),
      '17s',
    );
  });

  test('completed adventure countdown is localized', () {
    expect(adventureRemainingLabel(now, english, now: now), 'Ready');
    expect(adventureRemainingLabel(now, dutch, now: now), 'Klaar');
  });
}
