import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 44100;

typedef _Wave = double Function(double seconds);

void main(List<String> args) {
  final output = Directory('android/app/src/main/res/raw')
    ..createSync(recursive: true);
  final themes = <String, ({double root, List<double> chord, int seed})>{
    'sunwake': (root: 329.63, chord: [1, 1.25, 1.5, 2], seed: 720),
    'harvestmoon': (root: 196.0, chord: [1, 1.25, 1.5, 1.875], seed: 907),
    'birthday': (root: 261.63, chord: [1, 1.25, 1.5, 2], seed: 513),
    'witchlight': (root: 146.83, chord: [1, 1.2, 1.5, 2], seed: 13),
    'starlight': (root: 261.63, chord: [1, 1.25, 1.5, 2], seed: 25),
    'firstlight': (root: 220.0, chord: [1, 1.26, 1.5, 2], seed: 365),
    'twinheart': (root: 246.94, chord: [1, 1.2, 1.5, 1.8], seed: 214),
    'radiant': (root: 293.66, chord: [1, 1.26, 1.5, 1.78], seed: 7),
  };
  for (final entry in themes.entries) {
    final id = entry.key;
    if (args.isNotEmpty && !args.contains(id)) continue;
    final theme = entry.value;
    if (id != 'birthday') {
      _write(
        '${output.path}/event_${id}_chest.wav',
        2.35,
        _chest(theme.root, theme.chord, theme.seed),
      );
    }
    _write(
      '${output.path}/event_${id}_success.wav',
      .48,
      _success(theme.root, theme.seed),
    );
    _write(
      '${output.path}/event_${id}_failure.wav',
      .52,
      _failure(theme.root, theme.seed),
    );
    _write(
      '${output.path}/event_${id}_finish.wav',
      1.45,
      _finish(theme.root, theme.chord, theme.seed),
    );
  }
}

_Wave _chest(double root, List<double> chord, int seed) {
  final random = Random(seed);
  final shimmer = List<double>.generate(12, (_) => random.nextDouble() * 2 - 1);
  return (time) {
    var value = 0.0;
    final swell = pow((time / .38).clamp(0, 1), 1.6).toDouble() *
        exp(-max(0, time - .38) * .72);
    for (var index = 0; index < chord.length; index++) {
      final frequency = root * chord[index];
      value += sin(2 * pi * frequency * time + index * .42) *
          (.19 / (index + 1)) *
          swell;
      value += sin(2 * pi * frequency * 2.01 * time) *
          (.06 / (index + 1)) *
          exp(-time * 1.8);
    }
    for (var index = 0; index < shimmer.length; index++) {
      final starts = .22 + index * .105;
      final local = time - starts;
      if (local >= 0) {
        final frequency = root * (2.4 + index * .17);
        value += sin(2 * pi * frequency * local + shimmer[index]) *
            .105 *
            exp(-local * 7.2);
      }
    }
    final finale = time - 1.18;
    if (finale > 0) {
      value += sin(2 * pi * root * 2 * finale) * .22 * exp(-finale * 2.1);
      value += sin(2 * pi * root * 3 * finale) * .11 * exp(-finale * 2.8);
    }
    final driven = value * 1.7;
    return driven / (1 + driven.abs()) * .82;
  };
}

_Wave _success(double root, int seed) => (time) {
      final note = time < .16
          ? root * 2
          : time < .31
              ? root * 2.5
              : root * 3;
      final local = time.remainder(.16);
      return (sin(2 * pi * note * time) * .42 +
              sin(2 * pi * note * 2.01 * time) * .13) *
          exp(-local * 5.5) *
          exp(-time * .7);
    };

_Wave _failure(double root, int seed) => (time) {
      final frequency = root * (1.5 - time * .72);
      final wobble = sin(time * 31) * 7;
      return (sin(2 * pi * (frequency + wobble) * time) * .38 +
              sin(2 * pi * frequency * .5 * time) * .16) *
          exp(-time * 4.2);
    };

_Wave _finish(double root, List<double> chord, int seed) => (time) {
      var value = 0.0;
      for (var index = 0; index < 5; index++) {
        final starts = index * .13;
        final local = time - starts;
        if (local < 0) continue;
        final frequency = root * chord[index.remainder(chord.length)] * 2;
        value += sin(2 * pi * frequency * local) * .24 * exp(-local * 3.2);
        value += sin(2 * pi * frequency * 2 * local) * .07 * exp(-local * 4.8);
      }
      final crown = time - .65;
      if (crown > 0) {
        for (final ratio in chord) {
          value += sin(2 * pi * root * ratio * crown) * .12 * exp(-crown * 1.6);
        }
      }
      final driven = value * 1.5;
      return driven / (1 + driven.abs()) * .82;
    };

void _write(String path, double duration, _Wave wave) {
  final sampleCount = (duration * _sampleRate).round();
  final bytes = ByteData(44 + sampleCount * 2);
  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + sampleCount * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _sampleRate, Endian.little);
  bytes.setUint32(28, _sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, sampleCount * 2, Endian.little);
  for (var index = 0; index < sampleCount; index++) {
    final time = index / _sampleRate;
    final fadeOut = ((duration - time) / .06).clamp(0, 1).toDouble();
    final sample = (wave(time).clamp(-1, 1) * fadeOut * 32767).round();
    bytes.setInt16(44 + index * 2, sample, Endian.little);
  }
  File(path).writeAsBytesSync(bytes.buffer.asUint8List(), flush: true);
}
