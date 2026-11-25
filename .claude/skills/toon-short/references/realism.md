# Realism: toon actors in a world that looks real

The user rejected shots as "not realistic", "moving like statues" and "horrible" until these rules
were followed. Every rule below comes from a verdict (mostly silkyara_rescue, 2026-11). Add new
lessons here when you learn them.

## 1. Research the place before you build it

- **Find out what the place really looks like:** geography, terrain, vegetation, weather, the
  period (2023 is not 1990), building materials, vehicles, signage language, what people wear and
  carry there. A Himalayan tunnel portal, a Delhi lane, a Jaintia Hills coal pit and a Mumbai
  station each have their own colours and clutter.
- **Write the place down** in the beat sheet: 5–10 concrete details (wet orange mud with ruts,
  bamboo ladder, tin shed, coal heaps, mist on green hills).
- **Dress people for the place:** hard hats, hi-vis vests, gumboots and headlamps on a site; office
  clothes in an office; the real uniform of an official. Vary them; no clones.
- Reference images may be viewed on the web for study. Downloading or using any file needs the
  user's permission (references/assets.md).

## 2. Facts are part of realism

- Dates, counts, distances, names and the order of events must match reliable reporting. Keep the
  sources (episode notes, HANDOFF, `library/logos/SOURCES.md`).
- **Don't show what isn't reported.** If reports say a person was away when something happened,
  don't show them watching it.
- **When a shot and the sources disagree** (a two-storey facade, a house reported as single-storey),
  tell the user rather than silently picking one.
- Official paperwork, signs and screens carry only text that really exists. No invented quotes.

## 3. Build places at real scale, with wear

- **Real dimensions:** a 900 mm escape pipe, a 12 m road, a 3 m storey. Use the catalog's measured
  sizes (`tf props`) and kits that normalise scale.
- **Everything has wear:** mud lines, drag tracks, stains, chipped paint, puddles, tyre ruts, dust
  on horizontal surfaces, cables and hoses running somewhere.
- **Add the features a real one has:** the spiral weld seam and butt welds on a steel pipe; track
  shoes, a glazed cab with a seated operator and hydraulic rams on an excavator; a kelly bar,
  casing and spoil on a drilling rig.
- **A catalog model that reads as a toy when big in frame** (the Kenney ambulance) needs detail
  added, a longer lens and distance, or a better model.
- **India-first:** bazaar walls, haveli rooms, marble, Hindi signage, autos, wires and fairy lights.
  Never the plain blue grid or tile.

## 4. Busy means activity, not headcount

A crowd of identical idle toons reads as dead ("it just added the numbers but it didn't feel busy").
- Give people **distinct jobs with props and motion:** carrying, welding, pushing a barrow, hauling
  a rope, pointing, sipping tea, talking on a phone.
- **Layer** foreground, midground and background activity.
- **Moving machines and practical lights** (a spinning beacon, a swinging crane hook, a flickering
  tube light) bring a place alive more than people do.
- Stagger motion so no more than a third of things move in unison.

## 5. Bodies that act, not statues that slide

- **Never film a stiff body being slid.** If there's no clip (crawl, haul, dig), pose it
  procedurally: plant hands and knees in the world and pull the body past them
  (`godot/scripts/actors/toon_crawl.gd`: `Crawl.pose`, `Crawl.surge`, `Crawl.arm`, `Crawl.leg`).
  Speed pulses (pull, rest), shoulders roll, the head stays up and nods.
- A lying person is the `get_up` action frozen at 0, not an upright idle rotated onto its back. If
  a lying pose looks wrong, use a seated or slumped pose instead.
- **Grips are visible:** a held prop sits in the hand (`at: "<actor>.hand"`), lifts with weight,
  and the body leans against heavy things.
- **A toon's head is 38 % of its height and its arms are short.** Hands can't work in front of the
  face. Work happens below the chin; raise the camera until the tools drop under the chin line, or
  lengthen the arms (`Crawl.long_arms(actor, 1.45)`). Never shoot a toon from behind and above:
  you get a helmet and no acting.
- **Stage for the lens:** decide what must read, then find the angle that shows it in profile. A
  tool pointing at the lens is a dot. Faces want a 3/4 front view.
- **One hero prop, exaggerated about 1.3×.** True-to-life tools vanish next to a 0.6 m head.

## 6. Light that exists in the world

- **Three depths:** a key from a practical in the scene, a rim/back light from another practical
  behind the subject, a faint fill so blacks keep detail. Subject brightest, surroundings dark.
- A headlamp's *lens* glows (emissive + bloom); its *beam* is a separate spot aimed at the work,
  never into the lens.
- Night exteriors: sodium streetlamps, floods on masts, beacons, window spill. Wet ground reflects
  them; that's half the look.
- Interiors: a window or a lamp as the key, darkness in the corners.
- Lights within 1 m of a white toon face stay under about 0.4 energy.

## 7. Air: atmosphere makes depth

- Volumetric fog at 0.015–0.02 so beams show; heavier for mist and distance.
- Dust motes in beams: **additive** only (shaded motes read as dirt specks on the wall).
- A soft puff of dust on every impact; grit pouring on danger; steam, smoke or exhaust from machines.
- Haze lets lights bloom and pushes the background back.

## 8. Materials that survive a close-up

- **No `metallic` in enclosed dark sets.** With nothing to reflect, metal renders black and noise
  masks become black blotches. Use a dielectric with low roughness and high `SPECULAR`, so the
  lamps' highlights say "steel".
- **Noise at the right scale:** large smooth masks (rust, stains) at 0.3–2 cycles/m, stretched along
  the object's grain; fine grain at 150+ cycles/m at ±8 %. Mid frequencies (5–40 /m) read as
  camouflage.
- Thin curved shells don't cast shadows (`cast_shadow` off): they only make acne.
- Never flip `NORMAL` in `vertex()` together with `cull_front`: the wall then lights only from outside.
- Rounded, bevelled edges on hero props; hard flat primitives look like placeholders.

## 9. Find faults fast

- Look at 8 evenly spaced frames, then one at full size, then one brightened (`eq=gamma=2.2`).
- **Isolate before guessing:** swap a suspect material for a flat colour for one render. It tells
  you in 30 s whether a defect is texture, shadow or geometry.
- Compare against an approved shot of the same episode side by side. If yours has less depth, less
  contrast or less motion, it is not done.
- After a power cut or restart, check that JSON and Python still parse before continuing.

## Far bays z-fight: keep layers centimetres apart (2026-11-25, doctor_doom)

Gag bays placed tens of kilometres out (z 40 000 to 220 000) lose float precision: a 32-bit float resolves ~4 mm at
40 km and ~16 mm at 200 km. A poster 1.5 mm in front of its backing board flickered to black on random frames. Keep any
layered decal (poster on board, label on card, cover on comic) at least 2 cm proud at 40 km and 6 cm at 200 km, or drop
the backing (back-face-culled quads back to back never fight). Check flicker by sampling a clip at 6 fps, not from
three storyboard stills.
