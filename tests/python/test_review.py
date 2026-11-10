"""Approval board logic: gate locks, stale approvals, notes (no rendering)."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "pipeline"))

import review  # noqa: E402


class ReviewTest(unittest.TestCase):
    def setUp(self):
        self.rd = Path(tempfile.mkdtemp())
        (self.rd / "a.png").write_bytes(b"one")
        (self.rd / "b.png").write_bytes(b"two")
        items_env = [{"id": "env:a", "title": "A", "media": [{"type": "image", "src": "a.png"}], "details": {}, "suggestions": []}]
        items_cast = [{"id": "cast:x", "title": "X", "media": [{"type": "image", "src": "b.png"}], "details": {},
                       "suggestions": [{"id": "auto:dark", "source": "auto", "text": "dark"}]}]
        for it in items_env + items_cast:
            it["fingerprint"] = review._fingerprint(self.rd, it)
        board = {"episode": "t", "gates": [{"id": "env", "title": "Environment", "description": "", "items": items_env},
                                           {"id": "cast", "title": "Characters", "description": "", "items": items_cast}]}
        (self.rd / "board.json").write_text(json.dumps(board), encoding="utf-8")
        (self.rd / "suggestions.json").write_text(json.dumps({"cast:x": [{"id": "c1", "text": "brighter"}]}), encoding="utf-8")

    def test_gates_unlock_in_order(self):
        b = review.merged(self.rd)
        self.assertTrue(b["gates"][0]["open"])
        self.assertFalse(b["gates"][1]["open"])
        fp = b["gates"][0]["items"][0]["fingerprint"]
        review.decide(self.rd, "env:a", "approved", "", [], fp)
        b = review.merged(self.rd)
        self.assertTrue(b["gates"][0]["complete"])
        self.assertTrue(b["gates"][1]["open"])
        self.assertFalse(b["all_approved"])

    def test_claude_suggestions_merge(self):
        it = review.merged(self.rd)["gates"][1]["items"][0]
        self.assertEqual([s["source"] for s in it["suggestions"]], ["auto", "claude"])

    def test_change_after_approval_is_stale(self):
        fp = review.merged(self.rd)["gates"][0]["items"][0]["fingerprint"]
        review.decide(self.rd, "env:a", "approved", "", [], fp)
        (self.rd / "a.png").write_bytes(b"one, re-rendered")
        board = json.loads((self.rd / "board.json").read_text(encoding="utf-8"))
        it = board["gates"][0]["items"][0]
        it["fingerprint"] = review._fingerprint(self.rd, it)
        (self.rd / "board.json").write_text(json.dumps(board), encoding="utf-8")
        d = review.merged(self.rd)["gates"][0]["items"][0]["decision"]
        self.assertEqual(d["status"], "pending")
        self.assertTrue(d["stale"])

    def test_notes_list_requests_and_accepted_suggestions(self):
        b = review.merged(self.rd)
        review.decide(self.rd, "env:a", "approved", "", [], b["gates"][0]["items"][0]["fingerprint"])
        review.decide(self.rd, "cast:x", "changes", "make him taller", ["c1"], b["gates"][1]["items"][0]["fingerprint"])
        ep = self.rd / "ep" / "episode.json"
        ep.parent.mkdir()
        orig = review.review_dir
        review.review_dir = lambda p: self.rd
        try:
            text = review.notes(ep)
            missing = review.unapproved(ep)
        finally:
            review.review_dir = orig
        self.assertIn("make him taller", text)
        self.assertIn("do: brighter", text)
        self.assertNotIn("env:a", text)  # plain approvals are not noise
        self.assertEqual(len(missing), 1)

    def test_bad_status_rejected(self):
        with self.assertRaises(ValueError):
            review.decide(self.rd, "env:a", "maybe", "", [], "x")


if __name__ == "__main__":
    unittest.main()
