import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A reproducible HMAC-SHA256 stream seeded with 256 secret server-generated
/// bits. Persist the seed with the private intent before evaluating a command;
/// never accept it from, or send it to, a player. Separate streams keep object
/// IDs from revealing the random values used for rewards.
final class ServerEntropy implements Random {
  ServerEntropy(String seedHex, {required String stream}) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(seedHex) ||
        !const {'rewards', 'identities'}.contains(stream)) {
      throw ArgumentError('Invalid server entropy');
    }
    _hmac = Hmac(sha256, [
      for (var index = 0; index < seedHex.length; index += 2)
        int.parse(seedHex.substring(index, index + 2), radix: 16),
    ]);
    _domain = 'dragonhaven/economy/v1/$stream/';
  }

  late final Hmac _hmac;
  late final String _domain;
  List<int> _buffer = const [];
  int _offset = 0;
  int _counter = 0;

  int _byte() {
    if (_offset == _buffer.length) {
      _buffer = _hmac.convert(utf8.encode('$_domain${_counter++}')).bytes;
      _offset = 0;
    }
    return _buffer[_offset++];
  }

  int _word() => _byte() * 16777216 + _byte() * 65536 + _byte() * 256 + _byte();

  @override
  int nextInt(int max) {
    const range = 4294967296;
    if (max < 1 || max > range) throw RangeError.range(max, 1, range);
    final limit = range - range.remainder(max);
    var value = _word();
    while (value >= limit) {
      value = _word();
    }
    return value.remainder(max);
  }

  @override
  double nextDouble() =>
      ((_word() ~/ 64) * 134217728 + (_word() ~/ 32)) / 9007199254740992;

  @override
  bool nextBool() => nextInt(2) == 0;

  String uuid() {
    final bytes = List<int>.generate(16, (_) => _byte());
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
