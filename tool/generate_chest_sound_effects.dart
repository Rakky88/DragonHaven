import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 44100;

class _StereoTrack {
  _StereoTrack(double seconds)
      : left = Float64List((seconds * _sampleRate).ceil()),
        right = Float64List((seconds * _sampleRate).ceil());

  final Float64List left;
  final Float64List right;

  int get length => left.length;

  void add(int index, double sample, {double pan = 0}) {
    if (index < 0 || index >= length) return;
    final leftGain = sqrt((1 - pan.clamp(-1, 1)) * .5);
    final rightGain = sqrt((1 + pan.clamp(-1, 1)) * .5);
    left[index] += sample * leftGain;
    right[index] += sample * rightGain;
  }

  void addReverb(List<(double, double, double)> taps) {
    final dryLeft = Float64List.fromList(left);
    final dryRight = Float64List.fromList(right);
    for (final (seconds, gain, cross) in taps) {
      final delay = (seconds * _sampleRate).round();
      for (var i = delay; i < length; i++) {
        left[i] += gain *
            (dryLeft[i - delay] * (1 - cross) + dryRight[i - delay] * cross);
        right[i] += gain *
            (dryRight[i - delay] * (1 - cross) + dryLeft[i - delay] * cross);
      }
    }
  }

  void writeWav(String path) {
    var peak = 0.0;
    for (var i = 0; i < length; i++) {
      peak = max(peak, max(left[i].abs(), right[i].abs()));
    }
    final gain = peak == 0 ? 1.0 : .94 / peak;
    final dataBytes = length * 4;
    final bytes = ByteData(44 + dataBytes);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataBytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 2, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 4, Endian.little);
    bytes.setUint16(32, 4, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataBytes, Endian.little);
    for (var i = 0; i < length; i++) {
      final offset = 44 + i * 4;
      bytes.setInt16(
        offset,
        (left[i] * gain * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
      bytes.setInt16(
        offset + 2,
        (right[i] * gain * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    File(path).writeAsBytesSync(bytes.buffer.asUint8List());
  }
}

double _attackRelease(double time, double duration,
    {double attack = .025, double release = .35}) {
  if (time < 0 || time >= duration) return 0;
  final attackGain = min(1.0, time / attack);
  final releaseStart = max(attack, duration - release);
  final releaseGain = time <= releaseStart
      ? 1.0
      : pow(1 - (time - releaseStart) / release, 1.7).toDouble();
  return sin(attackGain * pi / 2) * releaseGain;
}

void _addChime(
  _StereoTrack track, {
  required double start,
  required double frequency,
  required double gain,
  required double pan,
  double duration = 1.45,
}) {
  final first = (start * _sampleRate).round();
  final count = (duration * _sampleRate).round();
  const partials = [(1.0, 1.0), (2.01, .34), (3.98, .16), (6.03, .07)];
  for (var local = 0; local < count; local++) {
    final t = local / _sampleRate;
    final envelope = exp(-3.4 * t / duration) * min(1.0, t / .008);
    var sample = 0.0;
    for (final (ratio, level) in partials) {
      sample += sin(2 * pi * frequency * ratio * t) * level;
    }
    track.add(first + local, sample * envelope * gain, pan: pan);
  }
}

void _addSweep(
  _StereoTrack track, {
  required double start,
  required double duration,
  required double from,
  required double to,
  required double gain,
  double pan = 0,
}) {
  final first = (start * _sampleRate).round();
  final count = (duration * _sampleRate).round();
  for (var local = 0; local < count; local++) {
    final t = local / _sampleRate;
    final progress = t / duration;
    final phase = 2 * pi * (from * t + (to - from) * t * progress / 2);
    final envelope = sin(pi * progress).clamp(0, 1);
    final sparkle = sin(phase) + .22 * sin(phase * 2.003);
    track.add(first + local, sparkle * envelope * gain, pan: pan);
  }
}

void _addNoiseSwell(
  _StereoTrack track, {
  required double start,
  required double duration,
  required double gain,
  required Random random,
}) {
  final first = (start * _sampleRate).round();
  final count = (duration * _sampleRate).round();
  var smooth = 0.0;
  var previous = 0.0;
  for (var local = 0; local < count; local++) {
    final progress = local / count;
    final white = random.nextDouble() * 2 - 1;
    smooth += .075 * (white - smooth);
    final airy = white - previous * .72;
    previous = white;
    final envelope = pow(sin(pi * progress), 1.4).toDouble();
    track.add(first + local, (smooth * .75 + airy * .18) * envelope * gain,
        pan: sin(progress * pi * 3) * .45);
  }
}

_StereoTrack _mythicalChest() {
  final track = _StereoTrack(4.65);
  final random = Random(0xD12A60);
  _addNoiseSwell(track, start: 0, duration: 2.25, gain: .34, random: random);
  _addSweep(track, start: 0, duration: 1.25, from: 62, to: 34, gain: .72);
  _addSweep(track,
      start: .12, duration: 2.45, from: 280, to: 1580, gain: .24, pan: -.2);
  _addSweep(track,
      start: .18, duration: 2.7, from: 360, to: 2240, gain: .18, pan: .25);

  const notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50];
  for (var i = 0; i < notes.length; i++) {
    _addChime(
      track,
      start: .36 + i * .235,
      frequency: notes[i],
      gain: .26 + i * .018,
      pan: i.isEven ? -.48 : .48,
      duration: 1.6,
    );
  }
  for (final (frequency, pan) in const [
    (523.25, -.58),
    (659.25, .58),
    (783.99, -.22),
    (1046.50, .22),
  ]) {
    _addChime(
      track,
      start: 2.10,
      frequency: frequency,
      gain: .31,
      pan: pan,
      duration: 2.25,
    );
  }
  _addSweep(track, start: 2.0, duration: 1.35, from: 900, to: 3300, gain: .15);
  track.addReverb(const [
    (.095, .28, .20),
    (.185, .22, .72),
    (.315, .16, .48),
    (.515, .10, .60),
  ]);
  return track;
}

double _formantWeight(double frequency) {
  double resonance(double center, double width, double gain) =>
      gain * exp(-pow((frequency - center) / width, 2));
  return .05 +
      resonance(720, 210, 1.0) +
      resonance(1120, 270, .68) +
      resonance(2440, 430, .30);
}

void _addLaughSyllable(
  _StereoTrack track,
  Random random, {
  required double start,
  required double duration,
  required double pitch,
  required double pan,
}) {
  final first = (start * _sampleRate).round();
  final count = (duration * _sampleRate).round();
  var phase = 0.0;
  var breath = 0.0;
  for (var local = 0; local < count; local++) {
    final t = local / _sampleRate;
    final progress = t / duration;
    final f0 = pitch * (1.08 - .22 * progress) + sin(t * 2 * pi * 5.1) * 1.8;
    phase += 2 * pi * f0 / _sampleRate;
    var voice = 0.0;
    for (var harmonic = 1; harmonic <= 34; harmonic++) {
      final frequency = harmonic * f0;
      if (frequency >= 6000) break;
      voice += sin(phase * harmonic) *
          _formantWeight(frequency) /
          pow(harmonic, .72);
    }
    final white = random.nextDouble() * 2 - 1;
    breath += .12 * (white - breath);
    final h = t < .105 ? (1 - t / .105) * (white - breath) * .54 : 0.0;
    final pulse = .88 + .12 * sin(t * pi * 2 * 7.2);
    final envelope = _attackRelease(t, duration, attack: .045, release: .30);
    track.add(first + local, (voice * .30 * pulse + h) * envelope * .58,
        pan: pan);
  }
}

_StereoTrack _sinisterChest() {
  final track = _StereoTrack(4.55);
  final random = Random(0xE7111A);
  _addSweep(track, start: 0, duration: .95, from: 82, to: 38, gain: .76);
  _addNoiseSwell(track, start: 0, duration: .72, gain: .42, random: random);
  const syllables = [
    (.30, .58, 94.0, -.30),
    (.91, .62, 88.0, .25),
    (1.58, .68, 82.0, -.18),
    (2.31, 1.05, 75.0, .18),
  ];
  for (final (start, duration, pitch, pan) in syllables) {
    _addLaughSyllable(
      track,
      random,
      start: start,
      duration: duration,
      pitch: pitch,
      pan: pan,
    );
  }
  _addSweep(track, start: 2.45, duration: 1.55, from: 130, to: 42, gain: .25);
  track.addReverb(const [
    (.17, .34, .72),
    (.34, .25, .32),
    (.56, .18, .68),
    (.83, .11, .42),
  ]);
  return track;
}

void main() {
  const raw = 'android/app/src/main/res/raw';
  Directory(raw).createSync(recursive: true);
  _mythicalChest().writeWav('$raw/chest_mythical.wav');
  _sinisterChest().writeWav('$raw/chest_sinister.wav');
  stdout.writeln(
      'Generated original DragonHaven Mythical and Sinister chest audio.');
}
