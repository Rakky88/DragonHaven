// Original DragonHaven instrumental arrangement and synthesized performance.
// Public-domain melody: J. L. Pierpont, Jingle Bells (1857).
// Source/rights: https://www.loc.gov/item/2023838067/
// No samples, modern arrangement, recording or soundfont are imported.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const rate = 44100;
  const beat = 60 / 112;
  const intro = 4;
  const bars = <List<(int, double)>>[
    [(76, 1), (76, 1), (76, 2)],
    [(76, 1), (76, 1), (76, 2)],
    [(76, 1), (79, 1), (72, 1), (74, 1)],
    [(76, 4)],
    [(77, 1), (77, 1), (77, 1), (77, 1)],
    [(77, 1), (76, 1), (76, 1), (76, 1)],
    [(76, 1), (74, 1), (74, 1), (76, 1)],
    [(74, 2), (79, 2)],
    [(76, 1), (76, 1), (76, 2)],
    [(76, 1), (76, 1), (76, 2)],
    [(76, 1), (79, 1), (72, 1), (74, 1)],
    [(76, 4)],
    [(77, 1), (77, 1), (77, 1), (77, 1)],
    [(77, 1), (76, 1), (76, 1), (76, 1)],
    [(79, 1), (79, 1), (77, 1), (74, 1)],
    [(72, 4)],
  ];
  const harmony = [0, 0, 0, 0, 1, 0, 2, 2, 0, 0, 0, 0, 1, 0, 2, 0];
  const chords = [
    [48, 52, 55],
    [48, 53, 57],
    [47, 50, 55]
  ];
  final duration = (intro + 128) * beat + 2.5;
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
    for (var bar = 0; bar < bars.length; bar++) {
      final startBeat = intro + repeat * 64 + bar * 4;
      var cursor = startBeat.toDouble();
      for (final n in bars[bar]) {
        note(n.$1, cursor * beat, n.$2, .27);
        if (repeat == 1) note(n.$1 + 12, cursor * beat, n.$2, .055);
        cursor += n.$2;
      }
      final chord = chords[harmony[bar]];
      for (final pitch in chord) {
        note(pitch + 12, startBeat * beat, 3.8, .032, pad: true);
      }
      note(chord.first - 12, startBeat * beat, 1.7, .105);
      note(chord.last - 12, (startBeat + 2) * beat, 1.6, .08);
      for (var pulse = 1; pulse < 4; pulse += 2) {
        for (final pitch in chord) {
          note(pitch + 12, (startBeat + pulse) * beat, .55, .042);
        }
      }
      // A quiet sleigh-bell shimmer, synthesized from inharmonic oscillators.
      for (var eighth = 0; eighth < 8; eighth++) {
        final offset = ((startBeat + eighth / 2) * beat * rate).round();
        for (var i = 0;
            i < (rate * .13).round() && offset + i < samples.length;
            i++) {
          final t = i / rate;
          samples[offset + i] +=
              (sin(t * 2 * pi * 6137) + .5 * sin(t * 2 * pi * 8279)) *
                  min(1, t / .002) *
                  exp(-t * 42) *
                  (eighth.isEven ? .012 : .006);
        }
      }
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
  final out = File('android/app/src/main/res/raw/music_event_jingle_bells.wav');
  out.writeAsBytesSync(bytes.buffer.asUint8List());
  stdout.writeln(
      'Original Jingle Bells arrangement: ${duration.toStringAsFixed(2)}s; ${out.lengthSync()} bytes; peak ${(peak * gain).toStringAsFixed(3)}; no clipping.');
}
