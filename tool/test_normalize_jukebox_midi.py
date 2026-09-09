import unittest
from tool.normalize_jukebox_midi import normalize


def midi(events):
    return bytes.fromhex('4d54686400000006000000010060') + b'MTrk' + len(events).to_bytes(4, 'big') + events


class NormalizedMusicTest(unittest.TestCase):
    def test_only_playback_level_bytes_change(self):
        # Tempo, sustain, notes (including running status and note-off), instrument.
        events = bytes.fromhex('00ff510307a12000c00b00b0407f00903c22603e60603c0000b0077f00b00b1f00803e2000ff2f00')
        expected = bytes.fromhex('00ff510307a12000c00b00b0407f00903c40603e40603c0000b0076400b00b7f00803e2000ff2f00')
        self.assertEqual(normalize(midi(events)), midi(expected))
        self.assertEqual(normalize(midi(expected)), midi(expected))

    def test_meta_and_system_payloads_are_not_treated_as_notes(self):
        events = bytes.fromhex('00ff0104903c227f00f004903c227f00ff2f00')
        self.assertEqual(normalize(midi(events)), midi(events))

    def test_malformed_input_is_rejected_without_writing(self):
        for data in [b'bad', midi(bytes.fromhex('00903c')), midi(bytes.fromhex('008180808000'))]:
            with self.assertRaises(ValueError):
                normalize(data)


if __name__ == '__main__':
    unittest.main()
