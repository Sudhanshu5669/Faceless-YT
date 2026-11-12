# Motion: how things move in a TownForge video

The house animation rules. They come from three installed skills, adapted to an engine that
renders frames as a pure function of time (`disney-animation-rule-skill`: the 12 principles for
procedural motion; `game-feel`: juice, impacts, trauma shake; `animation-principles`: easing,
timing, stagger numbers). Load those skills for depth; this page is what applies here.

The code lives in `godot/scripts/timeline/motion.gd` (`const Motion = preload("res://scripts/timeline/motion.gd")`),
used by reveals, the camera and every gag script.

## The rules

1. **Say the action in one sentence first:** subject, intention, force, destination, feeling.
   "Mukesh hurls the 1 GB cube onto the scale; it slams the pan down; the shopkeeper's jaw drops."
   One primary action per beat; rank everything else beneath it.
2. **Block it as phases before choosing curves.** Rest → **anticipation** → commit → travel →
   **contact** → overshoot → settle. Write a phase table (`Motion.phase(t, t0, table)`), name the
   events (launch, contact) and anchor the contact on the narration word.
3. **Anticipation points opposite the action** and is short: 0.12–0.25 s (a crouch before a jump,
   an arm pulled back before a throw, a cannon dipping before it fires). `Motion.wind_up`, `in_back`.
4. **Ease everything that moves.** Enter/settle = ease-out (`out_cubic`, snappy `out_quint`);
   exit/accelerate away = ease-in (`in_cubic`); move on screen = `in_out`; pops = `out_back`
   (overshoot). **Linear only for loops** (spinners, conveyor belts, a ticking second hand).
5. **Squash & stretch only around force and contact**, never continuously, and keep the volume
   (`Motion.squash(a)`: y stretches, x/z thin). Stretch along fast travel (`speed_stretch`), squash
   on impact (`Motion.impact(dt, strength)`), pivot at the contact point (the base, the hand).
   Impact strength scales with incoming speed: light 0.15, normal 0.3, heavy 0.45.
6. **Arcs, not straight lines.** Thrown and hopping things travel on `Motion.arc(a, b, height, k)`;
   organic objects never slide in a straight line at constant speed.
7. **Follow-through and overlap:** nothing stops all at once. Secondary parts (a tail, an antenna, a
   flag, a label, a hanging sign) sample the primary motion **later in time** (`f(t - 0.06)`), with
   more delay down the hierarchy, and settle after the main body with `Motion.wobble(dt)`.
   Secondary action starts later and settles later than the primary, and never competes with it.
8. **Impacts get a feedback bundle sized to the beat** (game-feel tiers), all fired on the same word:

   | Tier | Camera shake (`shot.shake`) | Squash | Extra | Examples |
   |---|---|---|---|---|
   | small | 0.1–0.2 or none | 0.1–0.15 | `pop`/`tick` | a coin lands, a card flips |
   | medium | 0.3–0.5 | 0.25–0.3 | `thud`, a dust puff | a box drops, a door slams |
   | large | 0.7–1.0 | 0.4–0.45 | flash, `sting`/`cash`, push-in | the cannon fires, the tower falls |

   Shake and flash are the strongest and most abused: keep them for real impacts, at most one
   large hit every few seconds. Large flashes no more than 3 per second.
9. **Timing = weight.** Light things snap (0.15–0.3 s), heavy things take longer and overshoot less
   (0.5–0.9 s). Scale duration with distance (≈ √distance). Hold the payoff pose for at least
   0.4 s so a Shorts viewer can read it, but keep something alive (a blink, a wobble, a bob) during
   holds: never freeze every channel.
10. **Stagger groups**, never all at once: 40–80 ms per item in a list, cap the whole group at about
    0.8 s, in reading order or radiating from the focal point. With 3+ elements, keep at most a third
    moving at once.
11. **Land on the word.** The contact, the counter landing, the face swap and the sound all hit the
    narration word, never between words. Anticipation happens *before* the word.
12. **Exaggerate for a phone screen.** Shorts are watched small: push poses, overshoot and squash
    further than feels natural, but clamp so silhouettes and text stay readable (rigid text and
    counters).
13. **Determinism.** State = f(t, params). No state carried between frames, no `randf()`; seed any
    variation from the gag id. Velocity comes from sampling the pure function (`Motion.velocity`).
14. **Effects never hide a weak pose.** Make the primary motion read with no shake, particles or
    sound first; then add accents. Review a few still frames: can you tell what is happening?

## In the vocabulary today

- **Reveals:** `pop` stretches up as it grows and settles round; `drop` stretches as it falls and
  squashes flat on landing, then springs back (text and counters stay rigid). `moves` with
  `scale` + `pulse` give a squash on a hit or a gulp.
- **Camera shake on a shot:** `"shake": [{"t": {"line": "n9", "word": "fire"}, "amount": 0.8}]`
  (trauma model: decays in about `amount / 1.6` s, offset 7 cm, roll 2.5° at full trauma).
- **Hold a payoff:** a shot's `"hold": 0.7` adds that much silence after its narration (works with the
  single take; later shots shift). Use it for the big joke landings, not every shot.
- **Gags:** use `Motion` in `pose()` for phases, easing, arcs, squash, wobble and follow-through.
  Example pattern:

```gdscript
const Motion = preload("res://scripts/timeline/motion.gd")
const THROW := [["wind", 0.18], ["fly", 0.35], ["land", 0.5]]

func pose(node, g, t, ctx):
	var t_hit: float = g["params"]["hit"]                      # the narration word
	var t0 := t_hit - 0.18 - 0.35                                # wind-up and flight end ON the word
	var ph := Motion.phase(t, t0, THROW)
	var cube := node.get_node("cube") as Node3D
	match ph["name"]:
		"wind":   cube.position = HAND + Vector3(0, 0, -0.15) * sin(Motion.out_cubic(ph["k"]) * PI * 0.5)
		"fly":    cube.position = Motion.arc(HAND, PAN, 0.8, Motion.in_out(ph["k"]))
		"land":   cube.position = PAN
	var sq := Motion.impact(t - t_hit, 0.35) if t >= t_hit else 0.0
	cube.scale = Motion.squash(sq)
```

## Not built yet

- **Hit-stop** (a 2–6 frame freeze on a huge impact): needs a scene-time warp that catches up
  so later word times stay in sync.
- **Character anticipation and poses** (crouch, wind-up, point, shrug, throw): the toon bodies
  play clips; a pose library + procedural overlays (lean, squash on landing) is the next step.
- **Smear frames / motion trails** on very fast moves, and dust-puff particles on contacts.
