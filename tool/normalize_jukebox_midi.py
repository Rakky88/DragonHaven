"""Keep bundled MIDI background music at a consistent performance level.

Only note-on velocity, channel volume and expression are flattened. Timing,
pitch, note releases, sustain, tempo, instruments and source metadata survive
byte-for-byte. No runtime compressor or automatic gain pumping is introduced.
Run after importing music; --check is a read-only release guard.
"""
from pathlib import Path
import argparse

RAW = Path(__file__).resolve().parents[1] / "android/app/src/main/res/raw"


def normalize(data: bytes) -> bytes:
    out = bytearray(data)
    if data[:4] != b"MThd" or len(data) < 14:
        raise ValueError("Not a standard MIDI file")
    offset = 8 + int.from_bytes(data[4:8], "big")

    def variable(pos: int, end: int) -> tuple[int, int]:
        value = 0
        for _ in range(4):
            if pos >= end:
                raise ValueError("Truncated MIDI delta or length")
            byte = data[pos]
            pos += 1
            value = value * 128 + (byte & 127)
            if byte < 128:
                return value, pos
        raise ValueError("Invalid MIDI variable length")

    while offset < len(data):
        if data[offset:offset + 4] != b"MTrk":
            raise ValueError("Missing MIDI track")
        end = offset + 8 + int.from_bytes(data[offset + 4:offset + 8], "big")
        if end > len(data):
            raise ValueError("Truncated MIDI track")
        pos = offset + 8
        status = 0
        while pos < end:
            _, pos = variable(pos, end)
            if pos >= end:
                raise ValueError("Missing MIDI event")
            if data[pos] >= 128:
                status = data[pos]
                pos += 1
            if status == 255:
                pos += 1  # meta event type
                length, pos = variable(pos, end)
                pos += length
            elif status in (240, 247):
                length, pos = variable(pos, end)
                pos += length
            elif 128 <= status < 240:
                kind = status & 240
                size = 1 if kind in (192, 208) else 2
                if pos + size > end:
                    raise ValueError("Truncated channel event")
                if kind == 144 and data[pos + 1] != 0:
                    out[pos + 1] = 64
                elif kind == 176 and data[pos] in (7, 11):
                    out[pos + 1] = 100 if data[pos] == 7 else 127
                pos += size
            else:
                raise ValueError("Invalid running status")
            if pos > end:
                raise ValueError("Event exceeds MIDI track")
        offset = end
    return bytes(out)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = sorted(RAW.glob("music_*.mid"))
    changed = []
    for path in files:
        original = path.read_bytes()
        result = normalize(original)
        if result != original:
            changed.append(path.name)
            if not args.check:
                path.write_bytes(result)
    if args.check and changed:
        raise SystemExit("Unnormalized background music: " + ", ".join(changed))
    print(f"Checked {len(files)} MIDI tracks; adjusted {len(changed)}.")


if __name__ == "__main__":
    main()
