"""Voice-first resolution, captions and sound synthesis, without any network calls."""
import json
import sys
import tempfile
import unittest
import wave
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pipeline"))

import episode_audio  # noqa: E402


def _wav(path: Path, seconds: float) -> Path:
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(24000)
        w.writeframes(b"\x00\x00" * int(seconds * 24000))
    return path


class ResolveTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def _fake_batch(self, texts, voice, style, model, pad=False):
        out = []
        for i, t in enumerate(texts):
            words = t.split()
            ws = [{"w": w, "s": 0.1 + 0.4 * j, "e": 0.1 + 0.4 * j + 0.3} for j, w in enumerate(words)]
            out.append({"wav": str(_wav(self.tmp / f"{voice}_{i}_{len(t)}.wav", 0.4 * len(words) + 0.3)),
                        "dur": 0.4 * len(words) + 0.3, "words": ws})
        return out

    def _resolve(self, ep):
        path = self.tmp / "episode.json"
        path.write_text(json.dumps(ep), encoding="utf-8")
        with mock.patch.object(episode_audio, "speak_batch", self._fake_batch):
            return episode_audio.resolve(path, verbose=False)

    def _episode(self):
        cam = {"at": "town_center", "look_at": "int_0_0"}
        return {
            "id": "t", "set": "specs/sets/blackwood.json",
            "lines": [{"id": "a", "text": "one two three", "shot": "s1", "at": 0.5},
                      {"id": "b", "text": "grab the batteries now", "shot": "s2", "at": 0.2}],
            "shots": [{"name": "s1", "duration": "fit", "camera": cam},
                      {"name": "s2", "duration": {"fit": True, "tail": 1.0}, "skip": 4.0, "camera": cam}],
            "actors": [{"id": "you", "character": "you", "at": "town_center",
                        "cues": [{"t": {"line": "b", "word": "batteries"}, "action": "idle"}],
                        "route": {"via": ["int_0_0"], "start": {"shot": "s1", "at": 1.0},
                                  "arrive": {"line": "b", "edge": "end"}}}],
            "events": [{"t": {"line": "a", "word": 1, "edge": "end"}, "target": "toys", "state": "on"}],
            "sfx": [{"sound": "click", "at": {"line": "b", "word": "batteries"}, "repeat": 2, "every": 0.5}],
        }

    def test_fit_durations_skip_and_references(self):
        res = self._resolve(self._episode())
        s1, s2 = res["shots"]
        self.assertAlmostEqual(s1["duration"], 0.5 + 1.5 + episode_audio.DEFAULT_TAIL, places=3)
        self.assertAlmostEqual(s2["duration"], 0.2 + 1.9 + 1.0, places=3)
        self.assertAlmostEqual(s2["scene_t"], s1["duration"] + 4.0, places=3)   # skip jumps story time
        ep = res["episode"]
        self.assertEqual(ep["shots"][1]["scene_t"], round(s2["scene_t"], 3))
        self.assertNotIn("skip", ep["shots"][1])
        self.assertNotIn("lines", ep)
        # Word "batteries" is word 2 of line b: 0.1 + 0.8 s into the line, in scene time.
        cue_t = ep["actors"][0]["cues"][0]["t"]
        self.assertAlmostEqual(cue_t, s2["scene_t"] + 0.2 + 0.9, places=3)
        self.assertAlmostEqual(ep["actors"][0]["route"]["start"], 1.0, places=3)
        self.assertAlmostEqual(ep["events"][0]["t"], 0.5 + 0.8, places=3)
        # Sounds are placed on the edit timeline (no skip there).
        self.assertAlmostEqual(res["sfx"][0]["t"], s1["duration"] + 0.2 + 0.9, places=3)
        self.assertAlmostEqual(res["sfx"][1]["t"] - res["sfx"][0]["t"], 0.5, places=3)

    def test_reveal_times_and_sounds(self):
        ep = self._episode()
        ep["reveals"] = [{"id": "users", "t": {"line": "a", "word": "two"}, "until": {"line": "b", "edge": "end"},
                          "at": "town_center", "sound": "pop",
                          "counter": {"from": 0, "to": 3.5, "land": {"line": "a", "word": "three"}}}]
        res = self._resolve(ep)
        rv = res["episode"]["reveals"][0]
        s1, s2 = res["shots"]
        self.assertAlmostEqual(rv["t"], 0.5 + 0.5, places=3)               # word "two" of line a
        self.assertAlmostEqual(rv["counter"]["land"], 0.5 + 0.9, places=3)  # word "three"
        self.assertAlmostEqual(rv["until"], s2["scene_t"] + 0.2 + 1.9, places=3)
        self.assertNotIn("sound", rv)                                       # sound keys never reach Godot
        pops = [s for s in res["sfx"] if s["sound"] == "pop"]
        self.assertEqual(len(pops), 1)
        self.assertAlmostEqual(pops[0]["t"], 1.0, places=3)

    def test_errors_are_loud(self):
        ep = self._episode()
        ep["lines"][0]["shot"] = "nope"
        ep["lines"][1]["volume"] = 3
        errs = episode_audio.validate(ep)
        self.assertTrue(any("'shot' must name a shot" in e for e in errs))
        self.assertTrue(any("unknown key 'volume'" in e for e in errs))
        ep = self._episode()
        ep["actors"][0]["cues"][0]["t"] = {"line": "b", "word": "flashlight"}
        with self.assertRaises(SystemExit):
            self._resolve(ep)

    def test_captions_chunk_and_highlight(self):
        res = self._resolve(self._episode())
        res["resolution"] = [1080, 1920]
        out = episode_audio.write_captions(res, self.tmp / "c.ass")
        text = out.read_text(encoding="utf-8")
        dialogue = [l for l in text.splitlines() if l.startswith("Dialogue:")]
        self.assertEqual(len(dialogue), 7)          # one event per spoken word
        self.assertIn("PlayResY: 1920", text)
        self.assertIn(r"{\c&H00D7FF&", dialogue[0])  # the spoken word is highlighted


class SingleTakeTest(unittest.TestCase):
    def test_match_script_tolerates_split_and_misheard_words(self):
        heard = [{"w": w, "s": i * 1.0, "e": i * 1.0 + 0.8} for i, w in
                 enumerate(["You", "built", "the", "4G", "only", "network."])]
        out = episode_audio._match_script(heard, ["You", "build", "the", "4G-only", "network."])
        self.assertEqual([w["w"] for w in out], ["You", "build", "the", "4G-only", "network."])
        self.assertAlmostEqual(out[0]["s"], 0.0)
        self.assertAlmostEqual(out[2]["s"], 2.0)          # matched words keep their times
        self.assertAlmostEqual(out[3]["s"], 3.0)          # "4G-only" spans "4G" + "only"
        self.assertAlmostEqual(out[3]["e"], 4.8)
        self.assertAlmostEqual(out[4]["s"], 5.0)


class SfxTest(unittest.TestCase):
    def test_sounds_are_deterministic_and_bounded(self):
        import numpy as np
        import sfx
        for name in sfx.ONE_SHOTS:
            a, b = sfx.make(name), sfx.make(name)
            self.assertTrue(np.array_equal(a, b), name)
            self.assertLessEqual(float(np.max(np.abs(a))), 1.0, name)
        bed = sfx.make("zombies", dur=2.0)
        self.assertEqual(bed.size, 2 * sfx.SR)
        with self.assertRaises(SystemExit):
            sfx.make("kazoo")


if __name__ == "__main__":
    unittest.main()
