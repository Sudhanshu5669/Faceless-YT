# Script and gags

The style was reverse-engineered frame by frame from @afterhourtheories ("How Facebook will win the
AI race?": 155 s, 86 shots, mean shot 1.8 s), then pushed toward realism on true stories
(silkyara_rescue, mumbai_lunch).

## Script formula

Two shapes work. Pick one with the user at the pitch.

**Hypothetical ("Imagine you're…")**
```
HOOK (0–5 s)      "Imagine you're <famous role>, but <you're losing / something is wrong>."
STAKES (5–15 s)   The rivals / the problem in 2 short sentences. Then the hidden advantage:
                  "But they don't know your <secret>."  + one hard number.
ESCALATION        "So you <action>." "Then you <bigger action>." "Now you need <X>, so you <Y>."
(15–120 s)        6–12 steps, each a picture, each with a real fact/number. 2–3 acts.
                  Mid-way, a "the insane part?" turn that raises the stakes.
COMPARISON        "<Rival A> knows <x>. <Rival B> knows <y>. But <you> know <z>."
PUNCHLINE         A pun or twist on the title.
BOOKEND (last 3 s) Back to the opening set, transformed. No outro, so the Short loops.
```

**True story (news, rescue, how-it-works)**
```
HOOK (0–5 s)      The moment of crisis, in the place it happened ("At 5:30 a.m., the tunnel caves in.")
STAKES            Who is trapped / what is at stake, with the real number.
ATTEMPTS          What was tried, each a physical action in its real place; each failure escalates.
TURN              The unexpected people or method that worked.
PAYOFF            The result, counted (41 men out), then the human beat.
CODA              What happened after (the twist of fate), stated plainly with dates.
```

Voice: short declaratives, present tense, rhetorical questions, light irreverence for the
hypotheticals, restraint for real tragedies. 130–170 s for a Short at ~150 words a minute. No
intro, no "in this video", no outro. Read it aloud: every sentence must suggest a picture. Check
every fact and number; credibility comes from real figures.

## The first line decides the views (our own analytics, 2026-11-25)

| Short | Opening line | Stayed to watch | Views |
|---|---|---|---|
| mangalyaan | "A one-kilometre auto ride in Ahmedabad costs about ten rupees. India went to Mars for seven." | 81.4% | 365k |
| pokhran | "India blew up the White House." | 77.1% | 6.1k in day 1 |
| silkyara_rescue | "Before dawn in Uttarakhand." | 71.4% | 11.5k, then the feed stopped (day 2) |
| jio_story | "Imagine you're Mukesh Ambani..." (a long sentence) | 67.8% | 77k (rescued by 79% still watching at 0:30) |

Once people stayed, every Short held about the same (63-69% viewed). The difference was the swipe in second one.
- **Line one is a paradox, a shock or a number that sounds wrong**, said in under 2 s. Never scene-setting
  ("Before dawn in…"), never a date, never the news summary people already know.
- For a known story, open on the part nobody knows (Silkyara's thumbnail had it, "helped save 41, then lost
  his home"; the narration didn't).
- Titles: no spoiler-only titles and no typos ("it's bitter outcome").

## The ten style rules

1. **Show every noun on its word.** A list becomes items arriving one per word (reveals with
   `t: {"line", "word"}`), each *delivered* by someone.
2. **Numbers are counters** that run up and **land exactly on the spoken number**, then flash
   and `ding`.
3. **Make every metaphor literal.** "Losing the race" = rowing a cardboard box past speedboats.
4. **Faces do the acting.** Swap expressions every 0.4–1.5 s (smug → star_eyes → shocked).
5. **One idea per shot**, ~1.8 s per shot.
6. **The camera always moves** (references/cinematics.md).
7. **Reuse sets only for callbacks**; each beat gets its own place.
8. **Escalate.** Each beat is bigger than the last; end lists on the biggest.
9. **Pun or twist at the end, then the bookend.**
10. **Captions** 1–2 words at a time (`"captions": {"max_words": 2, "style": "toon"}`). A bed under
    everything plus about one effect per second.

## Ideation: the gag for each line (before any JSON)

For every line, write 3–5 candidate sight gags, then pick the funniest one with a clear action and
payoff. A good gag is:
- **Literal and physical:** the metaphor happens to objects ("needs energy" → he hauls a nuclear
  plant on a rope; "buys the company" → a cash cannon buries the founder).
- **Caused by someone:** a character acts, the object reacts, the camera lands on the result.
- **Specific:** the real company (logo, office sign, colours), the real person (caricature), the
  real artifact (tweet, headline, receipt), a recognisable Indian place.
- **Escalating** across the episode, with callbacks (the snail returns as a rocket).
- **Readable in 9:16:** cause at the bottom, result on top, or a follow from one to the other.
- **Real objects, never labelled cubes:** "video" is a film reel, "mobile data" is a recharge
  scratch card, a company is its real sign. Text only where text exists in reality.
- **In its own place:** the company's lobby, a post office, a recharge stall, built and dressed.

Then check `tf library`, `tf props <words>` and `library/gags/`. If the vocabulary can't express it,
write a gag script (`episodes/<id>/gags/*.gd`, docs/GAGS_SPEC.md: `build()` + `pose(t)`, pure in
time) and move generic ones to `library/gags/`.

## Beat sheet

Write it in `episodes/<id>/beats.md` before any JSON:

| # | Line (exact words) | Place | Gag / action | On screen, on which word | Faces | Camera | Sound |
|---|---|---|---|---|---|---|---|
| 1 | "Imagine you're a tech billionaire…" | glass tower, night | boss at the window | boss on "billionaire" | smug | crane down the tower into the office | whoosh |
| 2 | "…but you're losing the AI race." | river | boss rows a cardboard box past speedboats | box on "losing", boats on "race" | smug → shocked | dolly alongside | splash |

Every row needs at least one word-anchored action or a face swap. If a row has neither, rewrite it.

## Cast

Use the `toon_*` characters (`tf library`) or add one in `library/characters/` (`toon` block,
docs/TOON_SPEC.md). For real stories, caricature the real people consistently (hair, glasses,
outfit) and use the real companies' logos; recreate real tweets and headlines faithfully.
