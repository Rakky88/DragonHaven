import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 48000;
const _durationSeconds = 5.4;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
        'Usage: dart run tool/generate_hatch_fanfare.dart <output.wav>');
    exitCode = 64;
    return;
  }
  final sampleCount = (_sampleRate * _durationSeconds).round();
  final left = Float64List(sampleCount);
  final right = Float64List(sampleCount);

  void tone({
    required double start,
    required double duration,
    required double frequency,
    required double amplitude,
    List<double> harmonics = const [1, .32, .15, .07],
    double attack = .025,
    double release = .35,
    double pan = 0,
    double vibrato = 0,
  }) {
    final first = (start * _sampleRate).round();
    final last =
        math.min(sampleCount, ((start + duration) * _sampleRate).round());
    var phase = 0.0;
    for (var index = first; index < last; index++) {
      final time = (index - first) / _sampleRate;
      final fadeIn = (time / attack).clamp(0.0, 1.0);
      final fadeOut = ((duration - time) / release).clamp(0.0, 1.0);
      final envelope = math.pow(fadeIn * fadeOut, .72).toDouble();
      final liveFrequency =
          frequency * (1 + vibrato * math.sin(2 * math.pi * 5.2 * time));
      phase += 2 * math.pi * liveFrequency / _sampleRate;
      var sample = 0.0;
      for (var harmonic = 0; harmonic < harmonics.length; harmonic++) {
        sample += harmonics[harmonic] * math.sin(phase * (harmonic + 1));
      }
      sample *= amplitude * envelope;
      left[index] += sample * (1 - pan) * .5;
      right[index] += sample * (1 + pan) * .5;
    }
  }

  void noiseSwell(double start, double duration, double amplitude) {
    var state = 0x5A17C9;
    final first = (start * _sampleRate).round();
    final last =
        math.min(sampleCount, ((start + duration) * _sampleRate).round());
    var previous = 0.0;
    for (var index = first; index < last; index++) {
      state = (1664525 * state + 1013904223) & 0x7fffffff;
      final raw = state / 0x3fffffff - 1;
      final high = raw - previous * .93;
      previous = raw;
      final progress = (index - first) / math.max(1, last - first);
      final envelope = math.sin(math.pi * progress) * (.25 + .75 * progress);
      final sample = high * amplitude * envelope;
      left[index] += sample * .48;
      right[index] += sample * .52;
    }
  }

  // A bright magical lift into the reveal.
  noiseSwell(0, .9, .16);
  for (final note in const [
    523.25,
    659.25,
    783.99,
    1046.50,
    1318.51,
    1567.98
  ]) {
    final index =
        const [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98].indexOf(note);
    tone(
      start: .06 + index * .13,
      duration: 1.35,
      frequency: note,
      amplitude: .16,
      harmonics: const [1, .48, .18, .08, .04],
      attack: .008,
      release: 1.05,
      pan: index.isEven ? -.28 : .28,
      vibrato: .0015,
    );
  }

  // Four triumphant harmonic steps, ending in a wide major-sixth chord.
  const chords = <(double, List<double>)>[
    (0.00, [130.81, 196.00, 261.63, 329.63]),
    (0.56, [174.61, 261.63, 349.23, 440.00]),
    (1.08, [196.00, 293.66, 392.00, 493.88]),
    (1.58, [261.63, 329.63, 392.00, 523.25, 659.25, 880.00]),
  ];
  for (var chordIndex = 0; chordIndex < chords.length; chordIndex++) {
    final (start, notes) = chords[chordIndex];
    final finalChord = chordIndex == chords.length - 1;
    for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
      tone(
        start: start,
        duration: finalChord ? 3.45 : .8,
        frequency: notes[noteIndex],
        amplitude: finalChord ? .13 : .10,
        harmonics: const [1, .44, .23, .11, .05],
        attack: finalChord ? .045 : .018,
        release: finalChord ? 2.5 : .35,
        pan: -0.42 + noteIndex * (.84 / math.max(1, notes.length - 1)),
        vibrato: finalChord ? .002 : .001,
      );
    }
  }

  // Heroic top-line and a final shower of high starlight.
  const melody = <(double, double, double)>[
    (.12, 783.99, .34),
    (.57, 1046.50, .34),
    (1.03, 1318.51, .38),
    (1.48, 1567.98, .46),
    (1.98, 1318.51, .30),
    (2.30, 2093.00, 2.15),
  ];
  for (var index = 0; index < melody.length; index++) {
    final (start, frequency, duration) = melody[index];
    tone(
      start: start,
      duration: duration,
      frequency: frequency,
      amplitude: index == melody.length - 1 ? .12 : .105,
      harmonics: const [1, .35, .13, .05],
      attack: .006,
      release: duration * .72,
      pan: index.isEven ? -.18 : .18,
      vibrato: .001,
    );
  }

  // Cinematic body without turning the cue dark.
  tone(
    start: 1.48,
    duration: 2.1,
    frequency: 65.41,
    amplitude: .19,
    harmonics: const [1, .58, .3, .12],
    attack: .012,
    release: 1.5,
  );
  noiseSwell(1.47, .34, .24);

  // Short stereo echoes make the cue feel like it rings through the Tower.
  final dryLeft = Float64List.fromList(left);
  final dryRight = Float64List.fromList(right);
  for (final (delaySeconds, gain, cross) in const [
    (.105, .24, .12),
    (.238, .16, .22),
    (.413, .10, .30),
  ]) {
    final delay = (delaySeconds * _sampleRate).round();
    for (var index = delay; index < sampleCount; index++) {
      left[index] += dryLeft[index - delay] * gain +
          dryRight[index - delay] * gain * cross;
      right[index] += dryRight[index - delay] * gain +
          dryLeft[index - delay] * gain * cross;
    }
  }

  var peak = .0001;
  for (var index = 0; index < sampleCount; index++) {
    peak = math.max(peak, left[index].abs());
    peak = math.max(peak, right[index].abs());
  }
  final scale = .92 / peak;
  final pcm = ByteData(sampleCount * 4);
  for (var index = 0; index < sampleCount; index++) {
    pcm.setInt16(
        index * 4, (left[index] * scale * 32767).round(), Endian.little);
    pcm.setInt16(
        index * 4 + 2, (right[index] * scale * 32767).round(), Endian.little);
  }

  final output = BytesBuilder(copy: false);
  final dataSize = pcm.lengthInBytes;
  void ascii(String value) => output.add(value.codeUnits);
  void u16(int value) {
    final bytes = ByteData(2)..setUint16(0, value, Endian.little);
    output.add(bytes.buffer.asUint8List());
  }

  void u32(int value) {
    final bytes = ByteData(4)..setUint32(0, value, Endian.little);
    output.add(bytes.buffer.asUint8List());
  }

  ascii('RIFF');
  u32(36 + dataSize);
  ascii('WAVEfmt ');
  u32(16);
  u16(1);
  u16(2);
  u32(_sampleRate);
  u32(_sampleRate * 4);
  u16(4);
  u16(16);
  ascii('data');
  u32(dataSize);
  output.add(pcm.buffer.asUint8List());

  final file = File(arguments.single);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(output.takeBytes(), flush: true);
  stdout.writeln('${file.path} (${file.lengthSync()} bytes)');
}
