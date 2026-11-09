"""Checks that hand-edited JSON in specs/ and library/ is well formed."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class LibraryJsonTest(unittest.TestCase):
    def test_all_json_parses(self):
        for folder in ("specs", "library"):
            for path in (ROOT / folder).rglob("*.json"):
                with self.subTest(path=str(path.relative_to(ROOT))):
                    json.loads(path.read_text(encoding="utf-8"))

    def test_looks_have_required_sections(self):
        for path in (ROOT / "library" / "looks").glob("*.json"):
            look = json.loads(path.read_text(encoding="utf-8"))
            with self.subTest(look=path.stem):
                self.assertEqual(look.get("id"), path.stem)
                self.assertTrue(look.get("description"), "every saved look needs a description")
                self.assertTrue("time" in look or "base" in look, "a look needs a time or a base")

    def test_shot_templates_have_camera_and_description(self):
        for path in (ROOT / "library" / "shots").glob("*.json"):
            shot = json.loads(path.read_text(encoding="utf-8"))
            with self.subTest(shot=path.stem):
                self.assertEqual(shot.get("id"), path.stem)
                self.assertTrue(shot.get("description"))
                self.assertIn("camera", shot)

    def test_set_specs_reference_existing_looks(self):
        looks = {p.stem for p in (ROOT / "library" / "looks").glob("*.json")}
        for path in (ROOT / "specs" / "sets").glob("*.json"):
            spec = json.loads(path.read_text(encoding="utf-8"))
            with self.subTest(spec=path.name):
                self.assertEqual(spec.get("schema_version"), "0.1")
                look = spec.get("look")
                if isinstance(look, str):
                    self.assertIn(look, looks)


if __name__ == "__main__":
    unittest.main()
