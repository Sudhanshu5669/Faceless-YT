# Pokhran-II: beat sheet and shot list

Script: `script.md` (approved 2026-11-22). Every line becomes one or more shots: the place, the gag
(who does what to which object), what lands on which word, faces, camera and sound.
Target: about 58 shots in about 160 s (mean about 2.8 s; hook, the heist list and the lid names faster).

Tone: a heist. Proud and quick, cheeky toward the spies, never jokey about the weapon. The
explosion is shown as the desert lifting and a dust ring, never a mushroom cloud (it was underground).

## Places (each one a gag script in `gags/`, far apart in one stage set `specs/sets/pokhran.json`)

| Gag / bay | Place | Real details that make it read |
|---|---|---|
| `analyst_room` / `desk` | A US imagery analyst's office near Washington, 1998, night | Beige 1990s PCs and two CRT monitors (one shows the greyscale satellite feed with a crosshair and a date/time stamp), a TV on a wall bracket, two beige desk phones with rows of line buttons that blink, venetian blinds with sodium light leaking through, steel filing cabinets, ring binders, a coffee mug, a White House snow globe on the desk, ceiling fluorescent panel half off. Cold blue-green key from the monitors, warm rim from the blinds. |
| `range` | Pokhran field firing range, Thar desert (Jaisalmer district) | Not pure dunes: flat, pale, stony sand with gravel, scattered khejri trees and ker/phog bushes, a few low dunes, heat shimmer. Olive army tents, an olive army truck (Shaktiman-style, canvas canopy), a Gypsy jeep, a steel shaft-head plate with a winch frame and cables, sandbags, a spoil pile, camouflage nets, a windsock on a pole, telegraph-style cable reels. Times: 1995 day; 1998 dusk, night (red torches, a shaded work lamp), dawn, noon and 15:45 on 11 May. |
| `orbit` | A US spy satellite over Earth | Reuse Mangalyaan's Earth (Solar System Scope textures, already downloaded): night side with city lights over India. The satellite is a long silver-gold cylinder with two solar wings and a lens hood at one end (a generic optical reconnaissance satellite, built from primitives). Hard sun, black sky. |
| `office` | Prime Minister's Office, South Block, New Delhi (1995 Rao, 1998 Vajpayee) | High ceiling, cream walls, a big teak desk with a green leather top, white towels on the chair backs (the Indian government office signature), files tied with red tape, a black dial phone and a beige push-button phone, a framed Gandhi portrait, a flag on a desk stand, a ceiling fan turning slowly, sandstone arched window with afternoon light. |
| `bunker` | The firing control bunker at the range | Sandbagged walls, a concrete slit window looking out to the windsock, a steel table with a firing panel (toggle switches, lamps and a key), a wall clock, a field telephone, folding chairs, water bottles, a tube light. |
| `airstrip` | Jaisalmer air force station, dawn | A long concrete runway in flat desert, a low control tower, blast pens, a fuel bowser. An IAF AN-32 twin-turboprop (high wing, grey, roundels) built from primitives; four olive trucks waiting with tailgates down. Long low sun, dust. |
| `village` | Khetolai, the nearest village | Round Bishnoi mud huts (jhumpas) with thatched cone roofs and lime-washed bands, a mud-plastered courtyard wall, a khejri tree, a cot (charpai), a steel water pot (matka/ghada) on a ring, a goat, kids playing. Bishnoi men in white turbans and dhotis, women in red or orange odhnis. |
| `lawn` | The Prime Minister's residence lawn, New Delhi, evening 11 May | A lectern with a bank of microphones, press photographers with 1990s film cameras and flashes, TV cameras on tripods, a white shamiana in the back, garden lamps, dusk sky. |
| `capitol` | Washington: a senator at a press stakeout | A marble corridor or the Capitol steps, a cluster of microphones, reporters with notepads and a 1998 TV camera. |
| `lok_sabha` | Lok Sabha chamber, Parliament House, 27 May 1998 | The horseshoe of green leather benches in tiers, teak panelling, the Speaker's raised chair under a canopy, the national emblem, warm overhead light. |
| `rashtrapati` | Rashtrapati Bhavan, July 2002 | The red-and-cream sandstone facade, the central dome, the broad steps and columns, President's Bodyguard in red, morning light. |
| `school` | A school science fair, 11 May (National Technology Day) | A classroom with a green chalkboard, a printed banner "National Technology Day", desks with models (a cardboard satellite on a string, a volcano), kids in white-and-blue uniforms, a ceiling fan, a window with sun. |

## Cast (new toon characters in `library/characters/`)

| Id | Who | Look |
|---|---|---|
| `toon_analyst` | US imagery analyst (fictional stand-in for "America's spies") | Pale skin, brown hair receding, rectangular wire glasses, short-sleeved white shirt with a loosened navy tie, ID badge on a clip. |
| `toon_vajpayee` | PM Atal Bihari Vajpayee (caricature) | White hair combed back, a broad face, square glasses, white kurta and dhoti with a tan Nehru jacket (or a shawl). |
| `toon_rao` | PM P. V. Narasimha Rao (caricature, 1995) | Bald crown with white hair at the sides, heavy lower lip, glasses, white kurta and dhoti. |
| `toon_wisner` | US Ambassador Frank Wisner (caricature, 1995) | Tall, grey hair parted, dark suit and tie. |
| `toon_kalam` | A. P. J. Abdul Kalam (caricature) | His iconic long white side-swept hair, kind smile; 1998: baggy army fatigues and a cap, name tape PRITHVIRAJ; 2002: a dark bandhgala. |
| `toon_chidambaram` | R. Chidambaram, AEC chairman (caricature) | Grey hair, glasses, moustache; army fatigues at the range, safari suit in Delhi. |
| `toon_jawan_a..d` | 58 Engineer Regiment soldiers | Olive drab, khaki patka or beret, moustaches, one Sikh jawan with an olive turban; shovels, sandbags. |
| `toon_scientist_a..c` | BARC/DRDO scientists in borrowed fatigues | Fatigues a size too big, one with a cap that slides over his eyes, glasses; one woman scientist. |
| `toon_villager_m`, `toon_villager_f`, kids | Khetolai Bishnoi villagers | White turban, dhoti; red odhni, silver jewellery. |
| `toon_senator` | Sen. Richard Shelby (caricature) | Grey hair swept back, dark suit, red tie. |
| `toon_press_a..c` | Indian press photographers, 1998 | Safari suits and kurtas, film cameras with flashes. |
| `toon_kid_a..c` | School kids | White shirts, blue shorts/skirts, ties, one with a cardboard satellite. |

## Lines and shots

Faces swap every 0.5–1.5 s in character beats. Counters land on the spoken number, then `ding`.

| # | Line (key words) | Shot | Place | Gag / action, what lands on which word | Faces | Camera | Sound |
|---|---|---|---|---|---|---|---|
| 1 | "On May 11th, 1998, India **blew up** the White House." | `hook_feed` | analyst_room | Full-frame satellite feed: grainy grey desert, crosshair, stamp "11 MAY 1998 15:45". On **blew up** the ground bulges and a dust ring blooms; the image shakes | — | Locked on the CRT, slow push; shake on **blew up** | low rumble, CRT hum |
|   | "And America only found out when India **announced** it." | `hook_analyst` | analyst_room | Reverse: the analyst asleep with his coffee, the bulge reflected in his glasses; behind him the wall TV flicks on: Vajpayee at microphones on **announced**; he jolts awake | analyst: sleepy → shocked | Push from the TV past his shoulder to his face | TV click, sting |
| 2 | "**Not that** White House." | `snow_globe` | analyst_room | Insert: the White House snow globe on his desk; his elbow knocks it, snow swirls | — | Macro, rack focus | glass clink |
|   | "A shaft in the **Rajasthan desert**," | `range_noon` | range | Whip to the range at noon: a steel shaft plate under a winch frame, heat shimmer, a khejri tree, a jawan walking past | jawan: deadpan | Low wide, slow crane up | wind, whoosh in |
|   | "**two hundred metres** deep," | `shaft_dive` | range | The camera dives down the dark shaft past cable clamps; depth counter 0 → 200 m lands on **two hundred** | — | Straight down, accelerating | whoosh, ding |
|   | "code-named **White House**." | `lid_chalk` | range | A jawan's hand finishes chalking WHITE HOUSE on the plate on **White House** and he steps back, proud | jawan: smug | Top-down insert, slight rotate | chalk scratch |
|   | "With a **hydrogen bomb** inside." | `device_inside` | range | At the bottom: a sealed steel canister in a cage, one work lamp, cables; a drip of water glints | — | Slow push, deep shadow | low drone |
| 3 | "**Rewind** to 1995." | `rewind` | analyst_room | The analyst's feed rewinds like a VHS tape: scan lines, the stamp rolls 1998 → 1995 | — | Locked on the CRT | tape rewind squeal |
|   | "Imagine you're India's nuclear team, getting ready to test **right here**." | `range_1995` | range | Daylight, no cover: engineers and trucks openly at the shaft, a crane lowering a pipe on **right here** | eng: determined | High wide, push | engines, clank |
|   | "But American **spy satellites** are watching." | `sat_turn` | orbit | Over the night Earth (India's lights), the satellite turns its lens toward Rajasthan on **spy satellites**; its shutter clicks | — | Slow arc from behind the satellite | servo whirr, click |
| 4 | "**The New York Times** prints it." | `nyt_slap` | office | A folded newspaper (real NYT wordmark, `library/logos/nyt-wordmark.svg`) slaps onto Rao's desk on **Times** | Rao: nervous | Top-down insert | paper slap |
|   | "The US ambassador shows up with the **photos**." | `wisner_photos` | office | Wisner slides a satellite photo across the desk on **photos**; Rao leans in | Wisner: deadpan; Rao: side_eye | Over Wisner's shoulder | paper slide |
|   | "President Clinton **calls** your Prime Minister." | `rao_phone` | office | The black phone rings and rattles on **calls**; Rao lifts it slowly | Rao: nervous → sad | Medium on Rao, slow push | phone ring |
|   | "Test **cancelled**." | `shovel_back` | range | Engineers shovel the sand back into the hole; a truck drives away in dust on **cancelled** | eng: sad | Wide, static, then truck exits frame | shovels, engine |
| 5 | "Now it's **1998**." | `office_1998` | office | Same office; the wall calendar's pages flip 1995 → 1998; Vajpayee now in the chair | Vajpayee: thinking | Locked wide (matches `rao_phone` framing) | page flutter |
|   | "A new Prime Minister, **Atal Bihari Vajpayee**, gives the order: **do it again**." | `vajpayee_order` | office | Kalam and Chidambaram stand across the desk; Vajpayee looks up and nods once on **do it again**; Kalam grins | Vajpayee: determined; Kalam: grin | Over Kalam's shoulder → push to Vajpayee | thud |
|   | "Same **desert**. Same **satellites**." | `same_desert` | range | Dusk wide: the same plate and tree; the satellite's glint slides across the darkening sky on **satellites** | — | Wide, slow tilt up to the sky | wind |
|   | "But this time, they must see **nothing**." | `team_lookup` | range | Jawans and scientists in a row look up at the moving glint; on **nothing** they look at each other | all: determined → scheming | Low, from behind the row then their faces | sting |
| 6 | "So you work only at **night**." | `night_work` | range | Night: red torches, a shaded lamp, a winch hauling sandbags out of the shaft, a jawan carrying a bag on his shoulder | jawans: effort | Handheld-feel dolly past the workers | winch, shovels |
|   | "And by sunrise, every truck is back in its **exact parking spot**," | `truck_park` | range | Dawn: a truck reverses into its own old tyre marks, a jawan whistles and stops it on **exact**, measures the gap with his fingers | jawan: determined → smug | Low behind the tyre marks | whistle, brakes |
|   | "so the morning photos look **the same**." | `photos_same` | analyst_room | Two printed satellite photos slide onto the analyst's desk, stacked; he compares them, shrugs on **the same**, yawns | analyst: side_eye → sleepy | Top-down insert → his face | paper |
| 7 | "The sand you dig out? Shaped by hand into **dunes**, the way **the wind** would make them." | `dune_shape` | range | Jawans pat and sweep a spoil pile into a crescent dune with shovels and palms, like a beach sandcastle; one blows on it for the final "wind" ripple on **the wind** | jawans: effort → proud | Low, close; ripple macro | sand pats |
|   | "The shafts hide under camouflage **nets**." | `net_drape` | range | Two jawans fling a camouflage net over the shaft head; it billows and settles on **nets** | jawans: effort | Wide, slight crane up | cloth whoosh |
| 8 | "When a satellite passes **overhead**," | `pass_watch` | range | A lookout checks his wristwatch against a handwritten timing list, then raises his fist | lookout: nervous | Close on the watch → his face | tick |
|   | "work **stops**." | `statue` | range | Signature gag: every man freezes mid-motion on **stops** (one mid-shovel with sand on the blade, one on one leg, one mid-sip of chai); the glint crosses the sky above them; then they all unfreeze at once | all: nervous (frozen) → relieved | Wide, 9:16 stacked: men below, satellite glint above | silence, then a whoosh |
|   | "In between, the soldiers play **cricket**," | `cricket` | range | Gully cricket in the sand, stumps from tent pegs; the bowler runs in, the batsman whacks it on **cricket** | jawans: cheer | Low behind the stumps, then follow the ball | bat crack |
|   | "so the pictures show a **bored army camp**." | `cricket_feed` | analyst_room | The analyst's feed from orbit: tiny dots playing cricket; he puts his head on the desk on **bored** | analyst: sleepy | Push in on the CRT → his face | yawn |
| 9 | "Your scientists arrive **dressed as soldiers**." | `jeep_arrive` | range | A Gypsy jeep stops; scientists in baggy fatigues climb out; one cap slides over his eyes on **soldiers**; a jawan quietly swaps a scientist's briefcase for a rifle sling | scientists: nervous; jawan: side_eye | Wide → medium | jeep brakes |
|   | "Even India's missile man, **Abdul Kalam**, gets a fake army name: **Prithviraj**." | `kalam_tape` | range | Kalam steps out last, his hair escaping under the cap (on **Abdul Kalam**); push in on his name tape PRITHVIRAJ on **Prithviraj**; he winks | Kalam: grin → wink | Medium → insert on the tape | sting, ding |
| 10 | "The bombs arrive at dawn: flown in from **Mumbai** on an **air force plane**," | `an32_land` | airstrip | The AN-32 drops out of a pink dawn and touches down in a puff of tyre smoke on **air force plane** | — | Long lens down the runway | turboprop drone, screech |
|   | "then driven into the desert by an **army convoy**." | `convoy` | range | Four olive trucks roll past a khejri tree in a long line of dust on **army convoy** | — | Long-lens watcher from behind the tree | engines |
| 11 | "Three go **down** into the shafts." | `cage_lower` | range | Night: a canister in a cage lowered by a winch into the shaft on **down**; a jawan guides the cable | jawan: effort | Top-down into the shaft | winch |
|   | "Code names: **White House**," | `lid_wh` | range | Plate one: chalked WHITE HOUSE | — | Quick insert, tilt | chalk tick |
|   | "**Taj Mahal**," | `lid_taj` | range | Plate two: TAJ MAHAL; a jawan has drawn a tiny dome next to it | jawan: smug | Quick insert, tilt | chalk tick |
|   | "and **Kumbhkaran**." | `lid_kumbh` | range | Plate three: KUMBHKARAN; the jawan guarding it lets out a huge yawn on **Kumbhkaran** | jawan: sleepy | Medium | yawn |
| 12 | "**May 11th**. Everything is set for **9 a.m.**" | `clock_nine` | bunker | The bunker clock reaches 9:00 on **9 a.m.**; a hand hovers over the firing key | team: determined | Insert clock → hand | tick |
|   | "Then the wind blows **the wrong way**." | `windsock` | range | The windsock swings round and points at a village on the horizon on **wrong way** | — | Low, long lens: sock big, village small | wind gust |
|   | "If anything leaks, it must not drift toward **people**." | `village_far` | village | Khetolai: kids play by a khejri tree, a woman draws water; the windsock in the far foreground on **people** | kids: happy | Wide, slow push | goat, kids |
| 13 | "So the most secret team in India just **waits**." | `wait_row` | bunker | A row of scientists and officers at the slit, chins on fists, staring out | all: deadpan | Slow dolly along the row | silence, clock |
|   | "**Six hours**. Staring at the **wind**." | `wait_clock` | bunker | The clock runs 9:00 → 15:00 (counter lands on **Six**); faces go bored → sleepy; one fans himself with a file | all: sleepy | Locked medium, time-lapse light | ticking fast |
| 14 | "At **3:45 p.m.**, the wind **turns**." | `wind_turns` | range | The windsock swings away from the village on **turns**; clock card 15:45 | — | Low, sock against the sky | gust |
|   | "The key **turns**." | `key_turn` | bunker | Insert: a hand turns the firing key on **turns** | — | Macro | click |
|   | "The desert **jumps**." | `desert_jumps` | range | Wide: the ground heaves into a low dome, a ring of dust rolls outward, the khejri shakes, birds lift on **jumps** | — | Wide, big camera shake | huge thud, rumble |
|   | "In **Khetolai**, the nearest village, people say their walls **cracked**." | `khetolai_crack` | village | A steel water pot ripples; a crack runs up the mud wall on **cracked**; an old villager touches it | villager: surprised → thinking | Close on the pot → tilt up the wall | rumble tail, crack |
| 15 | "Hours later, Vajpayee walks out to the **cameras**:" | `presser_walk` | lawn | Vajpayee walks to the microphones; flashes pop on **cameras** | Vajpayee: determined | Long lens through the photographers | camera flashes |
|   | "Today, at 1545 hours, India conducted three underground nuclear tests in the Pokhran range." | `presser_quote` | lawn | He reads; the verbatim quote card stacks above him | Vajpayee: determined | Slow push, low | flashes |
| 16 | "In Washington, the **phones** start ringing." | `phones_ring` | analyst_room | Every line button on both phones blinks; the analyst jolts awake on **phones** | analyst: panic | Medium, whip in | phone rings |
|   | "America's spies had missed **the whole thing**." | `analyst_feed` | analyst_room | He looks from the TV (Vajpayee) to his feed (calm desert) and back on **whole thing** | analyst: shocked → sad | Over-shoulder, rack TV ↔ feed | sting |
| 17 | "A US senator calls it a '**colossal failure**'." | `senator` | capitol | Shelby at a bank of microphones; flashes on **colossal failure** | senator: angry | Low, slight dutch | flashes |
|   | "The CIA's own review finds it simply **assumed** India would never test." | `review_drop` | analyst_room | A thick bound report thumps onto the analyst's desk on **assumed**; he sinks into his chair | analyst: sad → crying | Top-down → his face | thud |
| 18 | "Two days later, you test **two more**." | `two_more` | range | Two more dust domes on the horizon on **two more** | — | Wide, shake | two thuds |
|   | "On May 27th, Vajpayee tells Parliament: '**India is now a nuclear weapon state.**'" | `lok_sabha` | lok_sabha | Vajpayee stands at his bench and speaks; the benches thump desks; quote card above | Vajpayee: determined; MPs: cheer | Slow crane from the gallery | desk thumps |
| 19 | "Four years later, the scientist with the **fake army name**," | `kalam_cap` | range | Dusk: Kalam takes his army cap off and his hair springs free on **fake army name**; the glint passes overhead unseen | Kalam: happy | Medium, low | sting |
|   | "the one the satellites **never noticed**," | `never_noticed` | analyst_room | The analyst, 2002, still at his feed, dozing; on the TV behind him Kalam appears; he spills his coffee as he wakes on **never noticed** | analyst: sleepy → shocked | Medium, push | splash |
|   | "becomes the **President of India**." | `rashtrapati` | rashtrapati | Kalam in a dark bandhgala walks up the Rashtrapati Bhavan steps between the red-coated bodyguard on **President** | Kalam: grin | Low wide, crane up to the dome | fanfare sting |
| 20 | "And every May 11th, India celebrates **National Technology Day**." | `tech_day` | school | A kid lifts a cardboard satellite on a string under the banner on **National Technology Day** | kids: star_eyes | Push in | ding |
| 21 | "All because of one afternoon in the desert," | `end_range` | range | Afternoon: the plate with WHITE HOUSE chalked on it, the dust long settled | — | Crane up from the plate | wind |
|   | "when India blew up the **White House**." | `end_feed` | analyst_room | Up to the sky, the satellite, and into its feed: the shot becomes `hook_feed`'s framing, so the Short loops | — | Match to `hook_feed` | rumble swell |

## Build order (shot-by-shot approval)

1. `hook_feed` + `hook_analyst` (the analyst room and the Vajpayee TV): the episode's look and the first 3 s.
2. The range at noon (`range_noon`, `shaft_dive`, `lid_chalk`): the main set.
3. Then place by place; the range carries about half the shots.

## Sound (built-in synth + new synthesised effects)

Bed: `beat` at −20 with ducking, a tense heist pulse. New synth effects needed in `pipeline/sfx.py`:
`rumble` (the tests), `ring` (90s desk phone), `shutter` (satellite click), `wind` (desert gust),
`rewind` (tape squeal). No recorded audio, so nothing to license.
