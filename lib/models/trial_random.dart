import 'dart:math';

/// Reproducible challenge randomness with a bounded checkpoint. This generator
/// is only for public game layouts; secret reward entropy lives on the server.
class TrialRandom implements Random {
  TrialRandom(int seed) : state = seed & 0xffffffff {
    if (state == 0) state = 0x6d2b79f5;
  }
  int state;
  int _next() {
    var value = state;
    value = (value ^ (value << 13)) & 0xffffffff;
    value = (value ^ (value >>> 17)) & 0xffffffff;
    value = (value ^ (value << 5)) & 0xffffffff;
    return state = value;
  }

  @override
  int nextInt(int max) {
    if (max <= 0 || max > 0x100000000) {
      throw RangeError.range(max, 1, 0x100000000);
    }
    final limit = 0x100000000 - 0x100000000 % max;
    int value;
    do {
      value = _next();
    } while (value >= limit);
    return value % max;
  }

  @override
  bool nextBool() => (_next() & 1) == 0;

  @override
  double nextDouble() =>
      ((_next() >>> 6) * 134217728.0 + (_next() >>> 5)) / 9007199254740992.0;
}
