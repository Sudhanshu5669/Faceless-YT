# How Mukesh Ambani built Jio: the gag script

The narration stays as recorded (one approved, cached take; the word times are measured). This
rewrites **what we see**: one gag per narration segment (52 shots), in the reference channel's
grammar. Someone causes something, it happens to a real, recognisable thing, and the camera ends on
the result. It's literal, it escalates, and it calls back.

Status: ✅ = approved shot, 🟢 = built (pilot / earlier pass, to be redone in the shot loop),
🆕 = new. **Gag** names the code it needs (library = reusable, `library/gags/`; episode =
`episodes/jio_story/gags/`). Real logos, caricatures and recreated posts and headlines are allowed;
anything marked *verify* must be fact-checked before it's built.

Running characters: **Mukesh** (the protagonist, in every act), **Anil**, **Dhirubhai** (always
respectful: portrait and memory), **Kokilaben** (the mother who brokered the split), **Isha**,
**Akash**, the three **telco bosses** (Airtel red, Vodafone red, Idea yellow-green), the **Infotel
man**, **Zuckerberg** and **Sundar Pichai** (caricatures), and **the customer** (a young guy with a
phone, the audience's stand-in, from 2G misery to 4G joy).

---

## Act 1: the lost dream

| # | Shot | Line | Gag (on which word) | Gag code |
|---|---|---|---|---|
| 1 | open | "Imagine you're Mukesh Ambani." | Night refinery, flare stacks blazing. Crane down to Mukesh on a throne of oil drums, **sipping crude through a straw from a barrel** like a milkshake. His name lands over his head on "Mukesh / Ambani". | episode: straw sip (barrel level drops) |
| 2 | empire_items ✅ | "You run refineries, petrol and plastics." | A refinery, then a petrol pump, then a plastic bottle **drop and stack on his head** as a balancing tower, one per word. Star eyes on "plastics". | built |
| 3 | lost | "But you lost the one business your father dreamed about." | A 4th item, **a phone, tries to land on the stack, bounces off** on "lost", and rolls down the drum mountain and away. The tower wobbles, his face drops, and a "?" hangs over his head. | library: `bounce_roll` (a prop that bounces down steps) |
| 4 | tribute | "In 2002, your father Dhirubhai wanted a phone call to cost less than a postcard." | A 2002 post office counter. **Dhirubhai** (respectful, white shirt) puts a 50-paise postcard on one pan of a brass scale and a mobile phone on the other: the **phone pan crashes down** (too expensive). On "less" he **presses the phone pan up with one finger** and smiles. A 2002 calendar flips on "2002". *(verify: the Reliance Infocomm launch, 28 Dec 2002, and "Kar lo duniya mutthi mein")* | library: `balance_scale` (pans tilt on cues) |
| 5 | split | "Then the family empire splits." | A **tug-of-war over a giant RELIANCE cake**: the brothers pull, the cake tears down the middle on "splits", and both fall back holding a half. **Kokilaben** blows a referee's whistle. *(verify: her role in the 2005 settlement)* | library: `tug_of_war`; the cake halves are built |
| 6 | anil_phone | "Your brother Anil gets the phone company," | Anil's half has the **Reliance Infocomm tower** on top. He tucks it under his arm and **strolls off whistling**, the antenna bobbing, and winks on "company". | actor route + carried reveal |
| 7 | no_telecom | "and you agree to stay out of telecom." | Mukesh signs a giant contract with a quill. A door marked **TELECOM, ANIL ONLY** slams on "telecom" and he **splats flat against it** (squash and stretch), then slides down. | library: `door_slam`, `squash` move |
| 8 | watch | "So you watch." | Mukesh behind a **newspaper with two eye-holes cut out**, peeking (the paper reads ECONOMIC TIMES: TELECOM BOOM). Binoculars poke through the holes; push into the lenses for the POV iris cut. | built: binoculars + iris; new: newspaper card |

## Act 2: India before Jio

| # | Shot | Line | Gag | Gag code |
|---|---|---|---|---|
| 9 | street_2g | "In 2015, most Indians are online on slow 2G." | Through the binoculars: a bazaar where **everyone hunts for signal**: arms up holding phones to the sky, one man **up a coconut tree**, one **standing on a cow**, one on a rickshaw roof. A single "2G" bar flickers over them. | actor poses (arms up) + props (tree, cow) |
| 10 | price | "One gigabyte costs about 250 rupees," | At a recharge stall, the shopkeeper **weighs a tiny 1 GB data packet on a jeweller's scale with tweezers**, like gold. The price counter runs to **₹250** on "250". | library: `balance_scale` (small) |
| 11 | buffer | "and every video buffers forever." | The customer presses play: a spinner. **A snail starts dragging the data packet** across the street to him. On "forever" he has **grown a long white beard down to the floor**, with cobwebs. | library: `grow` move (beard), snail is built |
| 12 | rivals | "Airtel, Vodafone and Idea make their money on voice calls." | Three telco bosses in brand colours (**real Airtel, Vodafone, Idea logos on their desks**). Every "hello" a customer says **drops a coin through a taxi meter into their vault**; on "calls" they **dive into a vault of coins**. | library: `coin_vault` (stream + pile, reuse cash_stream) |
| 13 | luxury | "So data stays a luxury." | DATA in a **museum glass case** behind a velvet rope, a guard with arms folded, the customer **pressing his face on the glass**, fogging it. | built (vitrine) + new guard pose |
| 14 | sees | "But you see something they don't." | Mukesh puts on **X-ray specs**: the night city fills with **glowing data rivers** flowing between buildings, invisible to the bosses. He grins on "don't". | library: `data_river` (flowing glow ribbons) |

## Act 3: the opening

| # | Shot | Line | Gag | Gag code |
|---|---|---|---|---|
| 15 | deal_ends | "In 2010, your deal with Anil ends." | The NO TELECOM contract on the wall: a **fuse lights and burns it to ash** on "ends". Mukesh **blows the ash away** and cracks his knuckles. | library: `fuse_burn` |
| 16 | infotel | "Weeks later, an unknown company called Infotel" | A spotlight finds a **tiny shop the size of a doghouse** with an INFOTEL sign. A tiny man peeks out, and a "WHO?" sign pops on "unknown". | props + spotlight |
| 17 | circles | "wins 4G airwaves in all 22 circles of India." | The Infotel man runs across a **giant India map with a butterfly net, catching glowing radio waves** ("airwaves"), one per circle. Pins pop and the counter lands on **22**. | library: `wave_net` (wave sprites + a net swing) |
| 18 | buy95 🟢 | "Within hours, you buy 95 percent of it." | **Cash cannon** (built pilot): Mukesh fires on "buy" and the Infotel man is buried to the chin. A 95% STAKE flag drops on "95". | built: `cash_cannon` + `cash_stream` |
| 19 | isha | "Then your daughter Isha comes home from Yale and says," | Isha **bursts through the door of Antilia** (the real 27-storey house) in a Yale hoodie, dragging a suitcase, and **tosses her graduation cap** on "Yale". | actor route + toss arc |
| 20 | sucks | "\"Dad, the internet in our house sucks.\"" | Her laptop's upload bar crawls. She slams the desk on "sucks", and the **Wi-Fi router (a hamster on a wheel) faints**. A news card slides in: **"Jio was seeded by daughter Isha in 2011", Business Standard (PTI)**. | library: `news_card` (real headline, outlet, date) |
| 21 | akash | "Your son Akash adds: telecom isn't about calls anymore." | Akash **pulls a giant telephone cord like a bath plug**, and "CALLS" water **drains away** on "anymore". | episode: plug + drain |
| 22 | data_box | "It's about data." | A huge glowing **DATA cube rises behind the house like a sunrise**. The family shield their eyes and put on sunglasses on "data". | built (data box rise) + sunglasses accessory cue |
| 23 | oxygen | "So you decide: data should be like oxygen." | Mukesh takes **one breath from a DATA oxygen mask** and his **chest inflates** like a balloon on "oxygen". | library: `inflate` move |
| 24 | everyone 🟢 | "Cheap enough for everyone." | **Hoses run from a giant DATA tank to a mini tank over every head** in the bazaar, and the customer's spinner turns into a play button. | built |

## Act 4: the bet

| # | Shot | Line | Gag | Gag code |
|---|---|---|---|---|
| 25 | old_towers 🟢 | "You don't fix old towers." | Mukesh **kicks the first rusty 2G tower like a vending machine**, and they **fall like dominoes**. | built (domino) + kick action |
| 26 | build4g | "You build India's first 4G-only network," | Mukesh walks a field with a **watering can, watering seeds**. **4G towers sprout and grow** behind him, one per word, the last towering on "network". | library: `sprout` (grow from the ground with a wobble) |
| 27 | volte | "where even phone calls travel as data." | A "HELLO?" **speech bubble** comes out of a phone, gets **stuffed into a DATA crate** and **shot up a pneumatic tube** to the tower. | built (crate) + library: `speech_bubble`, `tube_shot` |
| 28 | fibre | "You lay three lakh kilometres of fibre." | Mukesh **runs round a spinning globe, unrolling fibre from a giant spool**, winding it 7.5 times like yarn round a ball; the counter lands on 3,00,000 KM. | built (globe + orbits) + runner on the globe |
| 29 | bill | "The bill: one and a half lakh crore rupees." | The receipt **prints out of a desk printer, keeps coming, floods the room and pours out of the window** down the street. ₹1,50,000 CRORE lands on "crore". | library: `ribbon_spool` (an unrolling strip that follows a path) |
| 30 | startup | "You call it the world's biggest startup." | Mukesh in a **hoodie on a beanbag** with a laptop in a STARTUP garage. Pull back: the garage is **the size of a mountain**. | built (giant garage) + hoodie outfit |

## Act 5: the launch and the takeover

| # | Shot | Line | Gag | Gag code |
|---|---|---|---|---|
| 31 | launch | "On September 5th, 2016, you launch Jio." | **Literal launch:** a countdown on a launch pad and a **giant JIO rocket** (real Jio logo) blasting off on "Jio", Mukesh at the plunger. The date lands on "5th". | library: `rocket_launch` (smoke, shake) |
| 32 | free3 | "And everything is free. Calls. Data. Apps." | The rocket **bursts into fireworks over the city, raining down** phones, data cubes and app icons, each with a FREE tag, one per word. The crowd catches them. | library: `firework_burst` (stream variant) |
| 33 | join16 | "Sixteen million people join in 26 days." | A **stampede into a Jio store**; the store **bulges at the seams** (squash), with the counter. *(16 M in 26 days is Jio's own figure)* | crowd route + `squash` |
| 34 | join100 | "A hundred million in 170 days." | Pull back: the **queue snakes round the block, out of the city and round India**. | crowd along a path |
| 35 | seven | "That's seven new customers every second." | A **turnstile spinning so fast it smokes and catches fire**, a clicker counter +7 per tick, and a clock. | library: `spin_fire` |
| 36 | regulator 🟢 | "Your rivals run to the regulator, crying predatory pricing." | The three bosses **run to the TRAI desk as crying babies**: diapers over suits, pacifiers, tear fountains, "WAAAH". | built (run + tears) + diaper/pacifier accessories |
| 37 | dropped | "You say their networks are dropping your calls." | Mukesh holds out a phone: **the call literally drops**. A "HELLO?" bubble falls out of the phone and **shatters on the floor** on "dropping". | `speech_bubble` + shatter |
| 38 | insane | "And the insane part? You even give away the phone." | Mukesh on stage with a **T-shirt cannon firing JioPhones** into the crowd. | built (phone cannon) |
| 39 | zero | "The JioPhone, at an effective price of zero." | A price tag **₹1,500 swings on the phone, then burns away** to "₹0" on "zero". | `fuse_burn` |
| 40 | crash | "Data crashes from 250 rupees a gigabyte to under 20." | The giant **₹250 price sign plunges like a meteor** and **craters the street** on "crashes", leaving "₹18". The snail from #11 is now **riding a rocket**. | library: `meteor` + built rocket |
| 41 | biggest | "India becomes the world's biggest consumer of mobile data." | The **India map at a buffet** with a bib and a fork, **devouring data packets**; a **#1 trophy** lands on "biggest". | episode: map with a face + eating |
| 42 | exits 🟢 | "Telenor exits. Tata exits. Aircel goes bankrupt." | A **JIO bowling ball** knocks down the telco towers one per name (real logos on the plaques). | built |
| 43 | rcom | "Even your brother's company shuts down." | **Anil pulls the shutter down** on the RCOM shop, with a sad trombone face. Mukesh peeks round the corner, awkward. | library: `shutter` |
| 44 | merge | "Vodafone and Idea merge just to survive." | Vodafone and Idea **hug on a tiny life raft** in a sea of Jio users, sweating, **duct-taped together**. | built (tape) + library: `raft` (bobbing) |
| 45 | number1 | "By 2019, Jio is number one." | The Jio tower **climbs to the top of a mountain of rival towers** and puts on a crown on "one". | built (podium/crown) to rework |
| 46 | facebook | "Then Facebook pays 5.7 billion dollars for a slice." | **Zuckerberg** (caricature) pulls up in a **money truck** (real Facebook logo), **cuts a slice of the Jio cake** (callback to #5) and leaves with it. His **real post** (Facebook, 22 Apr 2020) appears on a phone card. *(verify: the post text)* | `news_card`/`post_card`, truck, slice (built) |
| 47 | google | "Google pays 4.5 billion." | **Sundar Pichai** (caricature) arrives on a **Google-coloured scooter**, takes another slice, and gives a thumbs up. The real announcement card (Jio Platforms, 15 Jul 2020). *(verify)* | `post_card`, scooter |
| 48 | today 🟢 | "Today, 524 million Indians are on Jio." | **India made of 524 million (110 toon) people**, seen from above as the counter lands. | built |

## The bookend

| # | Shot | Line | Gag | Gag code |
|---|---|---|---|---|
| 49 | callback | "Your father wanted a phone call cheaper than a postcard." | Back at the 2002 post office counter (#4): the same scale, the postcard and the phone. | `balance_scale` |
| 50 | made_free | "You made it free." | Mukesh puts a JioPhone on the pan and it **floats up like a balloon** with a FREE tag. The scale flips, and **Dhirubhai's portrait smiles** on "free". | `balance_scale`, built portrait |
| 51 | jio_name | "That's why you call it Jio." | Mukesh **garlands his father's portrait** and places the JioPhone below it. | garland (built) |
| 52 | loop | "In Hindi, it means \"live\"." | Sky lanterns rise over the bazaar as every phone in the street lights up; जियो = LIVE. The cut returns to the opening: **Mukesh on his drum throne, sipping through his straw** (the loop). | built |

---

## Gag library to build (in order of how many shots use them)

1. `news_card` / `post_card`: a real headline, tweet or post on a phone or newspaper card, with outlet, date and counters that climb (#8, #20, #46, #47).
2. `balance_scale`: pans that tilt on cues (#4, #10, #49, #50).
3. `speech_bubble` + shatter (#27, #37); `fuse_burn` (#15, #39); `squash` / `inflate` / `grow` moves (#7, #11, #23, #33).
4. `sprout` (#26), `rocket_launch` (#31), `firework_burst` (#32), `meteor` (#40), `spin_fire` (#35).
5. `tug_of_war` (#5), `door_slam` (#7), `shutter` (#43), `raft` (#44), `ribbon_spool` (#29), `wave_net` (#17), `data_river` (#14), `bounce_roll` (#3), `coin_vault` (#12).
6. Accessories/poses for toons: arms up (signal hunting), diapers + pacifiers, a hoodie, sunglasses, a long beard.

## Real-world assets to get (ask the user before downloading; record sources in `library/logos/SOURCES.md`)

Logos: Reliance, Reliance Infocomm (2002), Jio, Airtel, Vodafone, Idea, Telenor, Tata Docomo, Aircel,
RCOM, Facebook (2020 mark), Google, TRAI, Yale. Posts and headlines: the Business Standard/PTI Isha
story, Zuckerberg's 22 Apr 2020 post, the Jio-Google announcement (15 Jul 2020). *Verify each quote
word for word.*
