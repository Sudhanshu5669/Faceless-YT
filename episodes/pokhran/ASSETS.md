# Pokhran: downloaded assets (all in git-ignored `incoming/`)

| Folder | What | Source | Licence | Credit |
|---|---|---|---|---|
| `incoming/polyhaven_pokhran/` | 30 models (glTF 2k), 4 HDRIs (4k), 4 ground textures (2k); list and URLs in its `LICENSE.txt` / `URLS.txt` | https://polyhaven.com (downloaded 2026-11-22, user-approved) | CC0 | none needed |
| `incoming/sss_textures/` | Earth day/night/clouds maps (reused from Mangalyaan) | Solar System Scope | CC BY 4.0 | "Planet textures: Solar System Scope (solarsystemscope.com), CC BY 4.0" |

Gags load these at runtime (`Kit.model`, `Kit.texture`), so there is no import step. To rebuild on a
fresh clone, re-download with the URLs in `URLS.txt`.
