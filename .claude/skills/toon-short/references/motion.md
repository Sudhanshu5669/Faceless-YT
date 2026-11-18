# Motion: how every gag moves

The full rules are in `docs/MOTION_SPEC.md`; the helpers in `godot/scripts/timeline/motion.gd`
(preload it in every gag). The reference feels alive because every action has weight. For each
beat, before writing code:

1. **One sentence:** who does what to which object, with what force, ending where, feeling how.
2. **Phase table:** rest → **anticipation** (0.12–0.25 s, opposite the action) → action (eased, on
   an **arc**) → **contact on the narration word** → overshoot → settle (`Motion.wobble`).
3. **Weight on contact:** squash with volume kept (`Motion.squash(Motion.impact(dt, s))`) sized by
   force, and a feedback bundle by tier:

   | Tier | Squash | Shake | Extras | Sound |
   |---|---|---|---|---|
   | small | 0.15 | — | — | `pop` |
   | medium | 0.25 | 0.4 | dust puff | `thud` |
   | large | 0.35 | 0.8 | flash, debris | `sting` / `cash` |

   Shake goes in the shot: `"shake": [{"t": <word>, "amount": …}]`.
4. **Follow-through:** attached parts (labels, flags, tails, signs, hair, ropes) lag the body
   (`f(t - 0.06)`) and settle after it. Secondary action starts and ends later than the primary.
5. **Easing:** ease-out to arrive, ease-in to leave, in-out to reposition, `out_back` to pop.
   Linear only for loops. Light things snap (0.15–0.3 s), heavy things lumber (0.5–0.9 s).
6. **Stagger** groups 40–80 ms apart (≤ 0.8 s total); at most a third of things move at once.
7. **Hold the payoff ≥ 0.4 s**, with something still alive (a wobble, a blink, a bob, dust).
8. **Check stills:** the action reads from 3 frames (start, contact, settle) with no effects.

## Every blow has four parts

Wind-up (ease-out, ~0.24 s) → strike (ease-in, ~0.1 s, contact ON the word) → recoil (the tool
bounces) → consequence (the body jolts, the face swaps to `strain`, chips + dust + a 0.2 shake, the
thing struck moves). Repeated blows escalate: the third one pays off (the stone splits).

## Soft, continuous motion

- No sudden swap of the same object (a cake that vanishes and reappears as halves): move it, split
  it, slide it (`moves`, `settle`).
- Falling props fall on arcs with gravity and bounce once; they don't drop at constant speed.
- Faces swap expressions every 0.4–1.5 s in character beats; bodies keep breathing (idle) in between.

## Procedural bodies

When the action library has no clip, pose the body in code instead of sliding a stiff one:
`godot/scripts/actors/toon_crawl.gd` (`Crawl.pose`, `Crawl.surge`, `Crawl.arm`, `Crawl.leg`,
`Crawl.long_arms`). `opts.tilt` runs from flat (0.17) through hands-and-knees (0.5) to upright
(PI/2), so the same call drops a standing toon onto all fours. See references/realism.md §5.

## Deeper craft

Load the installed skills `disney-animation-rule-skill` (phase blocking, deterministic procedural
motion), `game-feel` (impact tiers, trauma shake) and `animation-principles` (curves, durations,
stagger). Everything stays deterministic: pure functions of time, seeded RNG streams, no wall clock.
