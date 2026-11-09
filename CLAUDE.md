@AGENTS.md

## Claude-specific

- You can read images: after any visual change, run `python pipeline/tf.py preview-set`
  and Read the resulting `contact_sheet.png` (and single stills when something looks off).
  Judge framing, readability, seams and clipping before reporting success.
- The `manifest.json` written next to the stills lists every named place in a set
  (streets, addresses, house anchors). Use it when planning shots instead of reading layout.json.
