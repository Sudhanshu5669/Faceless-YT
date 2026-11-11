"""Forced alignment: spoken forms of script words and the CTC Viterbi path (no model needed)."""
import sys
import unittest
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pipeline"))

import ctc_align  # noqa: E402


class SpellingTest(unittest.TestCase):
    def test_numbers_have_their_spoken_forms(self):
        self.assertEqual(ctc_align.spellings("2015,")[:2], ["TWENTY FIFTEEN", "TWO THOUSAND FIFTEEN"])
        self.assertEqual(ctc_align.spellings("2002")[0], "TWO THOUSAND TWO")
        self.assertIn("A HUNDRED AND SEVENTY", ctc_align.spellings("170"))
        self.assertEqual(ctc_align.spellings("5.7"), ["FIVE POINT SEVEN"])
        self.assertEqual(ctc_align.spellings("5th,"), ["FIFTH"])
        self.assertEqual(ctc_align.spellings("4G-only"), ["FOUR G ONLY"])

    def test_words_and_unspoken_tokens(self):
        self.assertEqual(ctc_align.spellings("\"Dad,"), ["DAD"])
        self.assertEqual(ctc_align.spellings("don’t."), ["DON'T"])
        self.assertEqual(ctc_align.spellings("—"), [""])
        self.assertEqual(ctc_align.spellings("[whispers]"), [""])


class ViterbiTest(unittest.TestCase):
    def test_path_follows_the_frames(self):
        # Vocab: 0 blank, 1 A, 2 B. Frames: blank x2, A x3, blank x2, B x3.
        frames = [0, 0, 1, 1, 1, 0, 0, 2, 2, 2]
        lp = np.full((len(frames), 3), np.log(0.05), dtype=np.float32)
        for t, k in enumerate(frames):
            lp[t, k] = np.log(0.9)
        total, spans = ctc_align._viterbi(lp, np.array([1, 2]), blank=0)
        self.assertEqual([(a, b) for a, b, _ in spans], [(2, 4), (7, 9)])
        self.assertGreater(spans[0][2], 0.8)

    def test_repeated_letters_need_a_blank(self):
        lp = np.log(np.full((1, 3), 1 / 3, dtype=np.float32))
        with self.assertRaises(ctc_align.AlignError):
            ctc_align._viterbi(lp, np.array([1, 1]), blank=0)


if __name__ == "__main__":
    unittest.main()
