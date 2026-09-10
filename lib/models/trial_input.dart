import 'dart:convert';

/// Stable protocol identities. Append new controls; never reorder these values.
enum TrialControl {
  flap,
  strikeRuin,
  tapRune,
  choosePumpkin,
  beginPath,
  followPath,
  releasePath,
  deliverGift,
  strikeChime,
  moveHearts,
  rotatePrism,
  requestHint,
  dropCake,
  rotateFruit,
  placeFruit,
  grabDragon,
  steerDragon,
  releaseDragon,
  configureTrace,
}

class TrialInput {
  const TrialInput(this.milliseconds, this.control, [this.a = 0, this.b = 0]);
  final int milliseconds;
  final TrialControl control;
  final int a, b;
}

/// Each bounded chunk contains only elapsed input and control identities.
/// Its origin comes from the last server checkpoint. Deltas allow an endless
/// run without an ever-growing timestamp or complete-run recording in a request.
abstract final class TrialInputTranscript {
  static const maximumInputs = 384, maximumBytes = 2400, maximumSpan = 60000;

  static String encode(List<TrialInput> inputs,
      {required int startMilliseconds}) {
    if (inputs.length > maximumInputs || startMilliseconds < 0) {
      throw const FormatException('input_limit');
    }
    final bytes = <int>[1];
    void integer(int value) {
      do {
        final next = value % 128;
        value ~/= 128;
        bytes.add(next + (value > 0 ? 128 : 0));
      } while (value > 0);
    }

    var previous = startMilliseconds;
    for (final input in inputs) {
      if (input.milliseconds < previous ||
          input.milliseconds - startMilliseconds > maximumSpan ||
          input.a.abs() > 65535 ||
          input.b.abs() > 65535) {
        throw const FormatException('input_invalid');
      }
      integer(input.milliseconds - previous);
      bytes.add(input.control.index);
      for (final value in [input.a, input.b]) {
        integer(value >= 0 ? value * 2 : -value * 2 - 1);
      }
      previous = input.milliseconds;
    }
    if (bytes.length > maximumBytes) throw const FormatException('input_limit');
    return base64Encode(bytes);
  }

  static List<TrialInput> decode(String encoded,
      {required int startMilliseconds}) {
    if (startMilliseconds < 0 ||
        encoded.length > 3200 ||
        !RegExp(r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$')
            .hasMatch(encoded)) {
      throw const FormatException('input_invalid');
    }
    final bytes = base64Decode(encoded);
    if (bytes.isEmpty ||
        bytes.first != 1 ||
        bytes.length > maximumBytes ||
        base64Encode(bytes) != encoded) {
      throw const FormatException('input_invalid');
    }
    var cursor = 1, at = startMilliseconds;
    int integer(int maxValue) {
      var result = 0, scale = 1, count = 0;
      while (true) {
        if (cursor >= bytes.length || count++ >= 3) {
          throw const FormatException('input_invalid');
        }
        final byte = bytes[cursor++];
        result += (byte % 128) * scale;
        if (result > maxValue) throw const FormatException('input_invalid');
        if (byte < 128) {
          if (count > 1 && byte == 0) {
            throw const FormatException('input_invalid');
          }
          return result;
        }
        scale *= 128;
      }
    }

    final inputs = <TrialInput>[];
    while (cursor < bytes.length) {
      if (inputs.length >= maximumInputs) {
        throw const FormatException('input_limit');
      }
      at += integer(maximumSpan);
      if (at - startMilliseconds > maximumSpan || cursor >= bytes.length) {
        throw const FormatException('input_invalid');
      }
      final control = bytes[cursor++];
      if (control >= TrialControl.values.length) {
        throw const FormatException('input_invalid');
      }
      int signed() {
        final value = integer(131070);
        return value.isEven ? value ~/ 2 : -(value ~/ 2) - 1;
      }

      inputs.add(
          TrialInput(at, TrialControl.values[control], signed(), signed()));
    }
    return List.unmodifiable(inputs);
  }
}
