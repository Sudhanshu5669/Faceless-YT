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

## Pirate ship (2026-11-24, approved)

- `incoming/quaternius_ships/sail_ship.glb`: Quaternius LowPoly Ship Pack (OpenGameArt, CC0), converted with Blender. Used for Blackbeard's ship (pirate_chest, pirate_thing).

## Iron Man helmet (2026-11-24, chosen by the user; the user downloaded it)

- `incoming/ironman_helmet/model/scene.gltf`: "Iron-Man Helmet (MK3)" by Ritesh (designpill), Sketchfab,
  CC BY 4.0, commercial use allowed. Loaded by gags/gallery.gd and gags/misc.gd (`helmet_model`); without the file the
  scenes fall back to the built toon helmet.
- **Description credit (required):** This work is based on "Iron-Man Helmet (MK3)"
  (https://sketchfab.com/3d-models/iron-man-helmet-mk3-901d24c9a1714deeb724c98a8cb4649e) by Ritesh
  (https://sketchfab.com/designpill) licensed under CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)

## Doctor Doom bust (2026-11-24, chosen by the user; the user downloaded it)

- `incoming/doom_mask/model/scene.gltf`: "Doctor Doom's Mask" by Nicolas_Laube, Sketchfab, CC BY 4.0, commercial use
  allowed. On the gallery's right plinth (gags/gallery.gd); the toon mask is the fallback.
- **Description credit (required):** This work is based on "Doctor Doom's Mask"
  (https://sketchfab.com/3d-models/doctor-dooms-mask-8db5464072f341a994ad1c729d9080f7) by Nicolas_Laube
  (https://sketchfab.com/Nicolas_Laube) licensed under CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
