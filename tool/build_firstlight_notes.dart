import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Original synthesized C5/D5/E5/G5 chimes; no recordings or samples.
void main() {
  const rate = 44100;
  const duration = .60;
  const frequencies = [523.251, 587.330, 659.255, 783.991];
  final count = (rate * duration).round();
  for (var lane = 0; lane < frequencies.length; lane++) {
    final data = ByteData(44 + count * 2);
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + count * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, count * 2, Endian.little);
    final f = frequencies[lane];
    for (var i = 0; i < count; i++) {
      final t = i / rate;
      final attack = (t / .005).clamp(0.0, 1.0);
      final release = ((duration - t) / .055).clamp(0.0, 1.0);
      final wave = (sin(2 * pi * f * t) * .34 * exp(-t * 4.5) +
              sin(2 * pi * f * 2 * t) * .10 * exp(-t * 8) +
              sin(2 * pi * f * 3.01 * t) * .04 * exp(-t * 13)) *
          attack *
          release;
      data.setInt16(44 + i * 2, (wave * 32767).round(), Endian.little);
    }
    File('android/app/src/main/res/raw/event_firstlight_note_${lane + 1}.wav')
        .writeAsBytesSync(data.buffer.asUint8List());
  }
}
