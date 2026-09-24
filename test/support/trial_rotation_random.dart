import 'dart:math';

/// Deterministically selects the event branch of the Trial rotation's
/// four-way first-stage category roll.
///
/// Other rolls use their first outcome so tests can exercise a seasonal Trial
/// without restoring the old behavior where an event forced every offer to be
/// seasonal.
final class EventCategoryRandom implements Random {
  const EventCategoryRandom();

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => .5;

  @override
  int nextInt(int max) {
    if (max <= 0) throw RangeError.range(max, 1, null, 'max');
    return max == 4 ? 3 : 0;
  }
}
