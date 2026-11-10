@AGENTS.md

## Claude-specific

- You can read images: after any visual change, run `python pipeline/tf.py preview-set`
  and Read the resulting `contact_sheet.png` (and single stills when something looks off).
  Judge framing, readability, seams and clipping before reporting success.
- For episodes: run `python pipeline/tf.py storyboard <id>` and Read
  `episodes/<id>/preview/storyboard.png` (one row per shot: start, middle, end) before rendering.
  After `render`, look at the actual video: `ffmpeg -ss <s> -i <mp4> -vf "fps=4,scale=180:-1,tile=8x2" -frames:v 1 strip.png`.
- The `manifest.json` written next to the stills lists every named place in a set
  (streets, addresses, house anchors). Use it when planning shots instead of reading layout.json.
