// Original DragonHaven instrumental arrangement and synthesized performance.
// Melody: Mildred J. Hill, Good Morning to All (1893), known as Happy Birthday.
// Source: https://www.themorgan.org/music-manuscripts-and-printed-music/113636
// Rights: https://www.wipo.int/wipo_magazine/en/pdf/2016/wipo_pub_121_2016_01.pdf (p.34)
// Instrumental only; no lyrics, soundfonts, samples or third-party recording.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const rate = 44100;
  const beat = 60 / 96;
  const intro = 3;
  // Three-quarter time, with a one-beat pickup before each eight-bar verse.
  const bars = <List<(int, double)>>[
    [(69, 1), (67, 1), (72, 1)],
    [(71, 2), (67, .75), (67, .25)],
    [(69, 1), (67, 1), (74, 1)],
    [(72, 2), (67, .75), (67, .25)],
    [(79, 1), (76, 1), (72, 1)],
    [(71, 1), (69, 1), (77, .75), (77, .25)],
    [(76, 1), (72, 1), (74, 1)],
    [(72, 3)],
  ];
  const harmony = [0, 2, 2, 0, 0, 1, 2, 0];
  const chords = [
    [48, 52, 55],
    [48, 53, 57],
    [47, 50, 55]
  ];
  final duration = (intro + 54) * beat + 2.5;
  final samples = Float64List((duration * rate).ceil());
  void note(int midi, double start, double beats, double gain,
      {bool pad = false}) {
    final frequency = 440 * pow(2, (midi - 69) / 12);
    final length = beats * beat + (pad ? .5 : 1.2);
    final offset = (start * rate).round();
    for (var i = 0;
        i < (length * rate).round() && offset + i < samples.length;
        i++) {
      final t = i / rate;
      final attack = min(1.0, t / (pad ? .13 : .006));
      final release = min(1.0, max(0, (length - t) / (pad ? .45 : .12)));
      final envelope = attack * release * exp(-t * (pad ? .45 : 2.5));
      final phase = 2 * pi * frequency * t;
      final wave = pad
          ? sin(phase) + .18 * sin(phase * 2.001)
          : sin(phase) +
              .34 * sin(phase * 2) * exp(-t * 4) +
              .12 * sin(phase * 3) * exp(-t * 8);
      samples[offset + i] += wave * envelope * gain;
    }
  }

  for (var i = 0; i < 4; i++) {
    note([72, 76, 79, 84][i], i * beat, .75, .10);
  }
  for (var repeat = 0; repeat < 2; repeat++) {
    final phraseStart = intro + repeat * 27.0;
    note(67, phraseStart * beat, .75, .27);
    note(67, (phraseStart + .75) * beat, .25, .27);
    for (var bar = 0; bar < bars.length; bar++) {
      final startBeat = phraseStart + 1 + bar * 3;
      var cursor = startBeat;
      for (final n in bars[bar]) {
        note(n.$1, cursor * beat, n.$2, .27);
        cursor += n.$2;
      }
      final chord = chords[harmony[bar]];
      for (final pitch in chord) {
        note(pitch + 12, startBeat * beat, 2.8, .026, pad: true);
      }
      note(chord.first - 12, startBeat * beat, 1, .085);
      for (var pulse = 1; pulse < 3; pulse++) {
        for (final pitch in chord) {
          note(pitch + 12, (startBeat + pulse) * beat, .6, .037);
        }
      }
    }
    // A delicate original harp cadence fills the breath between verses.
    for (var i = 0; i < 3; i++) {
      note([72, 76, 79][i], (phraseStart + 25 + i * .4) * beat, .8, .055);
    }
  }
  final peak = samples.fold<double>(0, (p, s) => max(p, s.abs()));
  final gain = .83 / max(.83, peak);
  final bytes = ByteData(44 + samples.length * 2);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final fade = min(1.0, (samples.length - i) / (rate * 1.8));
    bytes.setInt16(
        44 + i * 2, (samples[i] * gain * fade * 32767).round(), Endian.little);
  }
  final out =
      File('android/app/src/main/res/raw/music_event_happy_birthday.wav');
  out.writeAsBytesSync(bytes.buffer.asUint8List());
  stdout.writeln(
      'Original Happy Birthday arrangement: ${duration.toStringAsFixed(2)}s; ${out.lengthSync()} bytes; peak ${(peak * gain).toStringAsFixed(3)}; no clipping.');
}
