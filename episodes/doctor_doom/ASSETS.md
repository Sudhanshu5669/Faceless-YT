# Doctor Doom: asset request for the three demo shots (approved 2026-11-24; downloaded: see the notes)

Catalog check (`tf props`): nothing for lab, stage, crowd, armour, mask, throne, microphone.
Existing packs reused: `kenney_castle` (later, Castle Doom), `quaternius_nature` snow trees (Latveria).

## 1. Poly Haven (polyhaven.com), CC0, no credit needed. ≈ 26 models (glTF 2k) + 3 HDRIs (4k) + ~6 textures (2k), ≈ 550–650 MB into `incoming/polyhaven_doom/` (git-ignored)

| Shot | Assets |
|---|---|
| Lab explosion (ESU, 1960s) | standing_chalkboard_01, chemistry_set, bunsen_burner, vintage_microscope, retro_multimeter, vintage_radio_transceiver, old_military_compressor, metal_office_desk, metal_stool_01, caged_hanging_light, hanging_industrial_lamp, modular_electric_cables, power_box_01, steel_frame_shelves_01, binder_notebook, vintage_spacecraft_instrument, mounted_fluorescent_lights |
| Marvel boardroom (Burbank, night) | modern_arm_chair_01, modern_ceiling_lamp_01, projector_screen, office_notepads, stationery_supplies, decorative_book_set_01, side_table_01 |
| Hall H (stage) | flood_lights, portable_searchlight |
| HDRIs | modern_buildings_night (the boardroom window), music_hall_01 (stage reflections), moon_lab (lab reflections) |
| Textures | worn metal plate (machine), concrete floor, painted plaster wall, carpet, dark wood, brushed steel |

## 2. Real references (rule 4; files kept in `library/logos/` with SOURCES.md)

| What | Source | Use |
|---|---|---|
| Fantastic Four #5 cover (1962) | Wikipedia file page (non-free, commentary) | held comic in chapter 2 (approved 2026-11-24) |
| Marvel Studios logo | Wikimedia Commons | Hall H screens, boardroom wall |
| San Diego Comic-Con logo | Wikimedia Commons / comic-con.org | Hall H stage banners |

## 3. Built by us (no download)

- **Doom's mask, hood and cloak**: our own toon design (simplified plates, rivets, green hood), built procedurally
  in `library/gags/doom_suit.gd`. Downloadable Doom models are fan copies of Marvel's design, usually non-commercial
  licences, so they don't qualify.
- **Hall H crowd**: 6,500 seats as MultiMesh toon silhouettes with phone lights (no pack needed).
- **Toon RDJ, Reed (1960s student), Kevin Feige, the Russos**: `library/characters/` JSONs on the toon body.

## Download notes (2026-11-24)

- Poly Haven: in `incoming/polyhaven_doom/` (LICENSE.txt, URLS.txt). `decorative_book_set_01` has no glTF (skipped).
  Seven models reused from `incoming/polyhaven_pokhran/`.
- Logos: `sdcc.svg` and the FF #5 cover are in `library/logos/doom/`; the Marvel Studios logo is still to fetch
  (Wikimedia 429). Sources in `library/logos/SOURCES.md`.
- The standing chalkboard model was replaced by a built slate (its orientation and size didn't suit the shot).
