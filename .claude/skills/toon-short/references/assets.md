# Assets: find what exists, then ask before you download

You may (and should) **ask the user to download assets** when a shot needs something the project
doesn't have. Never download on your own, never use generative image/video services, and never use
a file whose licence doesn't allow commercial video. The mechanics of importing are in
`docs/ASSET_PIPELINE.md`.

## 1. Search what already exists

```bash
python pipeline/tf.py props <words>      # the imported model catalog (library/catalog.json)
python pipeline/tf.py library            # looks, shot templates, kits, characters
ls library/gags/                         # reusable gag scripts (cash_stream, door, balloon, …)
```

Use a catalog model when it fits the **meaning** (a wooden barrel is not an oil drum; a toy-scale
car is not an ambulance in a close-up). Check its thumbnail (`library/thumbs/…`) before deciding.

## 2. Decide what is missing

For each missing thing, note: what it is, which shot needs it, how big it is on screen, and whether
building it from primitives in a gag script would look real enough. Build it yourself only when
it's simple and a hero-sized model wouldn't add realism.

## 3. Find candidates (licence first)

| Need | Where to look | Licence to accept |
|---|---|---|
| 3D models, kits | Kenney (kenney.nl), Quaternius (quaternius.com), Poly Pizza (CC0 items only), Fab (fab.com) | CC0; Fab Standard or CC BY 4.0 when free under that licence, glTF/GLB/FBX/OBJ (not UE-only) |
| Textures, HDRI skies | Poly Haven, ambientCG | CC0 |
| Systems (water, buoyancy, ropes, particles, crowds) | Godot Asset Library, GitHub | MIT / CC0 |
| Sound effects, ambiences | Kenney audio, Freesound (CC0 filter), OpenGameArt | CC0 (CC BY only with a credit line) |
| Fonts | Google Fonts | OFL |
| Company logos | the company's official media / press kit | the user's standing approval for news commentary |

Avoid: "personal use only", NC (non-commercial), ND when you need to modify, Unreal-only
licences, anything with no stated licence.

## 4. Ask the user (one batched request)

Collect every missing asset for the episode (or the next few shots) and ask once. Use
AskUserQuestion (or a clear message) with a table:

| # | Asset | For (shot / beat) | Source (URL) | Author | Licence | Size | Format |
|---|---|---|---|---|---|---|---|
| 1 | Ultimate Animated Animals | `cow_field` (line 9) | quaternius.com/… | Quaternius | CC0 | 48 MB | glTF |

Also say what you'll do without it (the fallback), so the user can decline cheaply. Wait for an
explicit yes per item; approval for one asset isn't approval for others.

## 5. Download and register (after the yes)

1. **The download goes into `incoming/`.** Direct links: download with the user's approval. Sites
   that need a login or a click (Fab, itch.io): open the page in the user's Chrome
   (claude-in-chrome), trigger the download, and the user saves it into `incoming/`.
2. **Name it** `<source>_<what>_<author>.zip` (wrap a bare `.glb` in a zip with its licence).
3. **Keep the licence:** add a `LICENSE.txt` to the zip if it has none (title, author, listing URL,
   licence, credit line).
4. **Register it** in `pipeline/asset_packs.json` (id, zip glob, files, `license`, `source`, and a
   `"credit"` line for CC BY).
5. **Import:** `python pipeline/tf.py assets import` (or `assets catalog --pack <id>`), then
   **look at** `library/thumbs/_sheets/<pack>_N.png`. Fix categories in `godot/tools/catalog.gd`
   if needed and add the models to a kit by role.
6. **Logos** go in `library/logos/` with an entry in `library/logos/SOURCES.md` (where it came
   from). **Sounds** go in `episodes/<id>/audio/` with `audio/SOURCES.md`.
7. **Credits:** every CC-BY item that appears on screen gets its credit line in the video
   description.

`incoming/` and `godot/assets/` are git-ignored; `pipeline/asset_packs.json`, `library/catalog.json`
and the kits are tracked, so a fresh clone rebuilds everything from the same downloads.
