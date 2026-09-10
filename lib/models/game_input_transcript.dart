import 'dart:convert';
import 'dart:typed_data';

/// Timed button identities, never client-provided scores or reward claims.
/// Twenty-second Academy lessons fit in one bounded command (40 inputs/sec).
class SchoolTap {
  const SchoolTap(this.milliseconds, this.target);
  final int milliseconds, target;
}

abstract final class SchoolInputTranscript {
  static const maximumInputs = 800;
  static String encode(List<SchoolTap> inputs) {
    if (inputs.length > maximumInputs) {
      throw const FormatException('input_limit');
    }
    final bytes = Uint8List(inputs.length * 3);
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      if (input.milliseconds < 0 ||
          input.milliseconds >= 20000 ||
          input.target < 0 ||
          input.target > 8) {
        throw const FormatException('input_invalid');
      }
      bytes[i * 3] = input.milliseconds >> 8;
      bytes[i * 3 + 1] = input.milliseconds & 255;
      bytes[i * 3 + 2] = input.target;
    }
    return base64Encode(bytes);
  }

  static List<SchoolTap> decode(String encoded) {
    if (encoded.length > maximumInputs * 4 ||
        !RegExp(r'^(?:[A-Za-z0-9+/]{4})*$').hasMatch(encoded)) {
      throw const FormatException('input_invalid');
    }
    final bytes = base64Decode(encoded);
    final result = <SchoolTap>[];
    var previous = -25;
    for (var i = 0; i < bytes.length; i += 3) {
      final at = bytes[i] * 256 + bytes[i + 1];
      final target = bytes[i + 2];
      if (at - previous < 25 || at >= 20000 || target > 8) {
        throw const FormatException('input_invalid');
      }
      result.add(SchoolTap(at, target));
      previous = at;
    }
    return List.unmodifiable(result);
  }
}
