// Original DragonHaven compositions, arrangements and synthesized performances.
// No imported melody, sample, soundfont, recording or external service.
// Prepared audio remains outside the native catalog until event intake resolves.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

enum _Voice { pan, harp, flute, bass }

void main() {
  _compose(summer: true);
  _compose(summer: false);
}

void _compose({required bool summer}) {
  const rate = 44100;
  final beat = 60 / (summer ? 112 : 92);
  final meter = summer ? 4 : 3;
  final duration = 32 * meter * beat + 2.0;
  final mix = Float64List((duration * rate).ceil());
  final lead = summer ? _Voice.pan : _Voice.flute;
  final bars = summer
      ? const <List<(int, double)>>[
          [(76, .5), (79, 1), (81, .5), (79, 1), (74, 1)],
          [(72, 1.5), (76, .5), (74, 1), (71, 1)],
          [(69, .5), (72, .5), (76, 1.5), (79, .5), (76, 1)],
          [(74, 1), (72, .5), (71, .5), (67, 2)],
          [(77, .5), (79, .5), (81, 1), (84, 1), (81, 1)],
          [(79, 1.5), (76, .5), (74, .5), (76, .5), (79, 1)],
          [(74, .5), (77, .5), (81, 1), (79, .5), (77, .5), (74, 1)],
          [(76, 1), (74, .5), (71, .5), (72, 2)],
          [(84, 1), (81, .5), (79, .5), (76, 1), (79, 1)],
          [(81, 1.5), (84, .5), (83, 1), (79, 1)],
          [(77, .5), (76, .5), (74, 1), (72, 1), (69, 1)],
          [(71, 1), (74, 1), (79, 1.5), (77, .5)],
          [(76, .5), (79, .5), (84, 1), (83, .5), (81, .5), (79, 1)],
          [(77, 1), (76, .5), (74, .5), (72, 2)],
          [(74, .5), (76, .5), (77, 1), (74, 1), (71, 1)],
          [(72, 3), (67, .5), (71, .5)],
        ]
      : const <List<(int, double)>>[
          [(74, 1), (78, .5), (76, .5), (74, 1)],
          [(71, 1.5), (69, .5), (66, 1)],
          [(67, .5), (71, .5), (74, 1), (76, 1)],
          [(73, 2), (69, .5), (71, .5)],
          [(74, 1), (78, 1), (81, 1)],
          [(79, 1.5), (78, .5), (76, 1)],
          [(74, .5), (71, .5), (73, 1), (76, 1)],
          [(74, 3)],
          [(78, 1), (81, .5), (83, .5), (81, 1)],
          [(79, 1), (78, 1), (74, 1)],
          [(76, .5), (79, .5), (83, 1), (81, 1)],
          [(78, 2), (76, .5), (73, .5)],
          [(74, .5), (78, .5), (81, 1), (78, 1)],
          [(79, 1.5), (76, .5), (74, 1)],
          [(73, 1), (71, .5), (69, .5), (73, 1)],
          [(74, 3)],
        ];
  final chords = summer
      ? const [
          [48, 52, 55],
          [47, 50, 55],
          [45, 48, 52],
          [43, 47, 50],
          [41, 45, 48],
          [48, 52, 55],
          [50, 53, 57],
          [43, 47, 50],
        ]
      : const [
          [50, 54, 57],
          [47, 50, 54],
          [43, 47, 50],
          [45, 49, 52],
          [50, 54, 57],
          [43, 47, 50],
          [45, 49, 52],
          [50, 54, 57],
        ];

  void note(int midi, double atBeat, double beats, double gain, _Voice voice) {
    final frequency = 440 * pow(2, (midi - 69) / 12);
    final held = beats * beat;
    final length = held + (voice == _Voice.flute ? .18 : .65);
    final offset = (atBeat * beat * rate).round();
    for (var i = 0; i < length * rate && offset + i < mix.length; i++) {
      final t = i / rate;
      final phase = 2 * pi * frequency * t;
      final attack = min(1.0, t / (voice == _Voice.flute ? .055 : .008));
      final release = min(1.0, max(0, (length - t) / .18));
      final decay = voice == _Voice.flute
          ? (t < held ? 1.0 : exp(-(t - held) * 14))
          : exp(-t * (voice == _Voice.pan ? 2.6 : 3.3));
      final wave = switch (voice) {
        _Voice.pan => sin(phase) +
            .27 * sin(phase * 2) * exp(-t * 4) +
            .09 * sin(phase * 3) * exp(-t * 8),
        _Voice.harp => sin(phase) +
            .23 * sin(phase * 2) * exp(-t * 5) +
            .11 * sin(phase * 3) * exp(-t * 7),
        _Voice.flute => sin(phase + .035 * sin(2 * pi * 4.8 * t)) +
            .14 * sin(phase * 2) +
            .025 * sin(phase * 3),
        _Voice.bass => sin(phase) + .12 * sin(phase * 2),
      };
      mix[offset + i] += wave * gain * attack * release * decay;
    }
  }

  for (var bar = 0; bar < 32; bar++) {
    final start = (bar * meter).toDouble();
    final melody = bar == 31 && summer
        ? const <(int, double)>[(72, 4)]
        : bars[bar % bars.length];
    assert((melody.fold<double>(0, (s, n) => s + n.$2) - meter).abs() < .001);
    var cursor = start;
    for (final n in melody) {
      // Same per-note level in every verse: no dynamic gain or compression.
      note(n.$1, cursor, n.$2 * .88, summer ? .20 : .13, lead);
      cursor += n.$2;
    }
    final chord = bar == 31 ? chords.first : chords[bar % chords.length];
    note(chord.first - 12, start, 1, .12, _Voice.bass);
    if (summer) note(chord.last - 12, start + 2, 1, .10, _Voice.bass);
    for (var step = 0; step < meter * 2; step++) {
      final index = [0, 2, 1, 2, 0, 1, 2, 1][step];
      note(chord[index] + 12, start + step * .5, .48, summer ? .045 : .037,
          _Voice.harp);
    }
    // A quiet answering upper sparkle belongs to the phrase, not a volume swell.
    if (bar % 4 == 3) {
      note(chord[1] + 24, start + meter - 1, .45, .034, _Voice.harp);
      note(chord[2] + 24, start + meter - .5, .5, .034, _Voice.harp);
    }
  }
  // Fixed short room reflections, never a time-varying compressor.
  final dry = Float64List.fromList(mix);
  for (final echo in const [(.093, .12), (.173, .07)]) {
    final delay = (echo.$1 * rate).round();
    for (var i = delay; i < mix.length; i++) {
      mix[i] += dry[i - delay] * echo.$2;
    }
  }
  final peak = mix.fold<double>(0, (p, sample) => max(p, sample.abs()));
  final activeSamples = (32 * meter * beat * rate).round();
  final rms = sqrt(
      mix.take(activeSamples).fold<double>(0, (sum, s) => sum + s * s) /
          activeSamples);
  final gain = min(.105 / max(rms, .001), .8 / max(peak, .001));
  final bytes = ByteData(44 + mix.length * 2);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, bytes.lengthInBytes - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, mix.length * 2, Endian.little);
  for (var i = 0; i < mix.length; i++) {
    final end = min(1.0, (mix.length - i) / (rate * .9));
    bytes.setInt16(
        44 + i * 2, (mix[i] * gain * end * 32767).round(), Endian.little);
  }
  final name =
      summer ? 'sunwake_sunpearl_serenade' : 'harvestmoon_orchard_waltz';
  final out = File('future_event_art/music/music_event_$name.wav');
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes.buffer.asUint8List());
  stdout.writeln(
      '$name: ${duration.toStringAsFixed(3)}s, ${out.lengthSync()} bytes, '
      'peak ${(peak * gain).toStringAsFixed(3)}, RMS ${(rms * gain).toStringAsFixed(3)}, mono 44.1kHz/16-bit.');
}
