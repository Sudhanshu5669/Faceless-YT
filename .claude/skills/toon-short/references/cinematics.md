# Cinematics: making shots look filmed, not rendered

The camera vocabulary is in `docs/CAMERA_SPEC.md` (anchors, `lens_mm`, `dof`, `roll`, templates)
and `docs/TIMELINE_SPEC.md` (moves `from`/`to`/`ease`, `whip_in`/`whip_out`, `iris_in`/`iris_out`,
`shake`, `hold`). This file is about choosing well.

## 1. The 9:16 frame

- **Think in vertical thirds.** The cause goes low and the result high (a hammer on a chisel at the
  bottom, the face above it; a cannon at the bottom, the cash arcing up). Stack reveals on or above
  a character (`<actor>.head`), never beside them.
- **Safe zones:** the lower third carries captions; the right edge of a Short carries the like and
  comment buttons; the top ~8 % carries the title bar. Keep faces, counters and payoffs in the
  central column, roughly between 15 % and 65 % of the height.
- **Headroom is small and look-room is vertical.** A character looking up toward the result has
  room above them; a falling object has room below.
- **Late reveals must be in the frame at the end of the move.** A push-in tightens the frame:
  place the reveal where the *last* frame still sees it. `tf framing` checks this.
- **Faces fill 15 %+ of the frame** in character beats. A full-body wide is for scale, not acting.

## 2. Shot sizes and lenses

`lens_mm` is full-frame equivalent on the frame's long side.

| Shot | Lens | Use it for |
|---|---|---|
| Extreme wide / establishing | 18–24 mm, high | where we are, scale (the mountain, the city at night). Usually a crane or drone move. |
| Wide | 24–28 mm | a character in their place; action with room around it. |
| Medium | 30–35 mm | the default acting shot: a character doing something to an object. |
| Close-up | 40–50 mm | faces, reactions, a hand on a tool. |
| Insert / detail | 50–85 mm, shallow focus | the watch at 7:05, the chisel tip, a phone screen, a signature. |
| Long-lens watcher | 85–135 mm | compression: crowds stacked up, a line of ambulances into fog, heat haze, a figure seen from far off. |
| Low hero | 18–24 mm, camera at knee height, tilted up | power, scale of a machine, a character arriving (`low_hero` template). |
| Worm's eye / god view | wide, straight up or straight down | absurd scale, overhead geography (`worm_eye`, `god_view`). |
| Dutch | any, `roll` 6–12° | unease. Sparingly. |

Wide lenses close to a subject exaggerate depth and energy. Long lenses flatten and isolate. A
toon's 0.6 m head looks best between 30 and 50 mm; very wide and close distorts it.

**Depth of field** (`dof: {"strength", "focus"}`): 0.2–0.3 for most shots, 0.4–0.5 for inserts and
close-ups. Focus defaults to the `look_at` distance; set `focus` explicitly when the subject is not
where the camera looks. Shallow focus is how you separate a subject from a busy background.

## 3. Camera moves

Every shot moves. Choose the move from what the shot has to say:

| Move | How (`from` → `to`) | Says |
|---|---|---|
| **Push-in** (the default) | same `look_at`, `to` closer, `in_out` | "pay attention to this". Slow: 3–8 % of the distance per second. |
| **Pull-back reveal** | start tight on a detail, end wide | scale, consequence ("41 ambulances"). |
| **Crane up / down** | `orbit` height changes, or `at` rises | arrival at a place, a tally, an ending. Crane up from a beacon to the whole line. |
| **Dolly / truck** | `at` slides sideways along a street or wall anchor | travel, a row of things. Needs a foreground for parallax. |
| **Arc / orbit** | `orbit.angle` changes | a hero moment, a reveal of a machine's shape. |
| **Follow / track** | camera hung off a place, `look_at` the moving actor; or both ends anchored to the actor | following someone through the story. |
| **Rack focus** | `dof.focus` changes between `from` and `to` | shifting attention from a foreground thing to the background. |
| **Whip pan** | `whip_out` on one shot, `whip_in` on the next, with `format.motion_blur` | fast change of place or time, energy. |
| **Iris / POV** | push into binoculars or a lens, `iris_in` on the next shot | a point-of-view cut. |

Rules:
- **Motivate the move.** The camera follows action, discovers something or builds tension; it
  doesn't drift for nothing.
- **Anchor the camera to the place, not the actor**, unless you want it to swing when they turn.
- **Ease in and out** (`in_out`) for repositioning; `out` for a move that arrives on a hit.
- **Shake only on impacts** (`shake`: light 0.15, medium 0.4, heavy 0.8), on the contact word.
- **Don't let a move eat the payoff:** if the payoff lands in the last ~0.4 s, cut instead of
  whipping out, or add a `hold`.
- Nothing within 20 cm of the lens unless it's a deliberate blurred foreground frame.

## 4. Depth: three layers in every frame

A flat frame looks rendered. A layered frame looks filmed.
- **Foreground:** something close and out of focus at the frame's edge (a pipe rim, a railing, a
  rope, a shoulder in an over-the-shoulder, hanging wires). It also gives moves parallax.
- **Midground:** the subject, sharp and brightest.
- **Background:** the place, darker and softer, with points of light (practicals, windows, beacons)
  that bloom into bokeh.
Atmosphere (fog, haze, dust) separates the layers: see references/realism.md.

## 5. Light like a cinematographer

- **Motivated key:** every light comes from a source that exists in the scene (headlamp, flood,
  streetlamp, a window, the lit mouth of a pipe, a phone screen).
- **Rim / back light:** a second source behind the subject draws an edge that separates it from the
  dark background. Coloured rims (cool behind, warm key) are the cheapest way to look cinematic.
- **Faint fill** so blacks keep detail; never flat ambient.
- **Subject brightest**, surroundings darker. If a backdrop competes with the face, darken it.
- **Contrast of colour temperature:** sodium orange vs LED white, warm interior vs blue night, cyan
  dawn vs warm floods. Two or three colours a shot, not a rainbow.
- **Expose for the face.** Toon heads are white and clip first: keep lights within 1 m of a face
  under ~0.4 energy and check it reads grey with shading.
- Use the `toon_drama` look (low ambient, SSAO, bloom, vignette) or a night/dusk look as the base,
  and stage bays with `"mood": "dramatic"`.

## 6. Coverage: cutting a beat into shots

- **A hook is a sequence, not a shot.** For the opening (and any big event), cut 3–5 shots:
  establishing wide → a human close-up (a warning, a face) → the event → the aftermath or reaction.
  The user approved the Silkyara hook as five shots after rejecting one static wide.
- **Vary shot size between cuts** (wide → close → medium). Two cuts of the same size and angle
  read as a jump cut.
- **Cut on action:** end a shot mid-movement and start the next with the movement continuing.
- **Keep screen direction:** if the rescue moves left to right, it keeps moving left to right
  across cuts. Respect the 180° line in a dialogue or face-off.
- **Eyelines match:** a character looking up at something should cut to a shot of that thing from
  below.
- **Match cuts and transitions through objects:** push into a globe, a window, a phone screen or a
  lens and come out in the next place.
- **Continuity:** props, damage, light and time of day carry from shot to shot (the demolished room
  stays demolished).

## 7. Pacing

- Mean shot ≈ 1.8 s (range 0.5–4 s). Faster in hooks and lists, a 3–4 s breather after a run.
- Hold a payoff ≥ 0.4 s with something still alive (a wobble, a blink, dust settling). Shot
  `hold` adds silence after the lines when a payoff needs room.
- Calmer, true-story episodes (Mumbai lunch) can run slower shots with gentle moves; keep the
  cadence consistent within an episode.

## 8. Final quality settings

- `"format": {"resolution": [1080, 1920], "fps": 60, "motion_blur": 2}` for finals (blur 2–3).
- Renders stream frames into ffmpeg; `--draft` gives a half-size 15 fps animatic for quick checks.

## 9. Diagnose before you change

- Look at 8 evenly spaced frames, one frame at full size, then one brightened
  (`ffmpeg … -vf eq=gamma=2.2`): dark areas hide wrong poses.
- When the layout is unclear, render one diagnostic view from far away with `"exposure": 3.5`,
  then restore the real camera.
- Compare against an approved shot of the same episode side by side.

## 10. Make it grand (the user's bar since 2026-11-24)

The Doctor Doom demo (Hall H unmasking, the 1960s lab explosion, the Kang plan board) set it: "this is the level
of grand I am looking for." What made it grand, and how to get it again:

- **Scale you can feel.** Fill the place: a 6,000-seat hall is 6,000 MultiMesh people (body, head, arms, phones;
  `episodes/doctor_doom/gags/hall_h.gd` `_build_crowd`), a cinema is every seat taken. Open a sequence on a high
  wide that shows the size, then go in. Give the room its real height (trusses, ceiling lights far up).
- **Light you can see.** Light in haze: volumetric fog 0.01-0.02 plus additive **beam cones** on the hero lights
  (`BEAM_SHADER` in hall_h.gd / cinema.gd: soft depth-faded edges, fade near the lens). Moving heads that sweep and
  converge on the subject on the beat; a follow spot from the back; a projector beam; moonlight shafts through
  tall windows. Keep beams subtle in close-ups (they wash out contrast) and strong in wides.
- **Cut the subject out.** Backlights behind the figures, aimed at the lens, turn them into silhouettes; the
  subject stays the brightest thing in frame (watch toon faces: the white head blows out under stacked lights;
  drop the stacked energy on the face and give it one warm key).
- **Screens and practicals inside the set.** Giant LED screens with the real logo, a live IMAG close-up of the
  hero (a SubViewport camera on the actor), the TV drawing the chart, glowing tubes, marquee bulbs. They light the
  scene and tell the story.
- **Payoffs that fill the frame.** A portal that swirls, arcs that strike, a fireball with sparks and debris, a
  wall of cards that rains down, a crowd that erupts; camera shake and a held beat after the hit.
- **Contrast is part of grand.** Dark surroundings, a vignette, colour: one dominant hue per place (Doom green,
  warm tungsten, cold moonlight) against its opposite.
- **Gotchas met on the way:** `smoothstep(a, b, x)` needs a < b; `pow(x, y)` with x < 0 is NaN (a white square);
  a gag named like its bay shadows the bay's anchor (camera offsets double); places must sit kilometres apart when
  one of them is huge (the hall bled into the lab).

