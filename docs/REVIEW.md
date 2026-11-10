# Review: approve everything before the final render

Every episode passes four gates, in order. A gate unlocks when everything before it is approved,
and `tf render` (final) refuses until every item is approved (`--draft` is always allowed,
`--force` skips the check).

| Gate | Items | What you see |
|---|---|---|
| **Environment** | one per key angle of the set | stills of the set and look, no people |
| **Characters** | one per character in the episode | turnaround (front, ¾, side, back) + one pose per action they perform |
| **Script & voice** | the script, then every line | script text; each line as it will be heard (speed and toy effects applied) |
| **Shots** | one per shot | draft clip with sound + start / middle / end stills, its narration, camera |

```bash
python pipeline/tf.py review prepare <id> [--gate env,cast,voice,shots]   # render the board (~1.5 min for a Short)
python pipeline/tf.py review serve <id>                                   # opens http://127.0.0.1:8765/
python pipeline/tf.py review notes <id>                                   # what was approved / asked for
```

## The page

Click a card to review it: media on the left, details, suggestions and your decision on the right.
**Approve** (`A`) or **Request changes** (`R`: write a note or tick a suggestion). `←`/`→` move between
items, `Esc` closes. Notes and ticks save as you type. "Approve N remaining" approves every
undecided item in an open gate.

**Suggestions** come from two places:
- *Automatic checks* (from `prepare`): very dark frames, narration pace outside ~1.7–3.3 words/s,
  shots shorter than 1.2 s or long static shots.
- *Claude*: written into `review/suggestions.json` after Claude has looked at the media.
  Ticking one means "do this".

When you're done, tell Claude **"review done"**.

## Files (episodes/&lt;id&gt;/review/)

| File | Written by | In git |
|---|---|---|
| `board.json` + media folders | `tf review prepare` | no (regenerated) |
| `suggestions.json` | Claude: `{item_id: [{"id": "c1", "text": "..."}]}` | yes |
| `decisions.json` | the page: status, note, accepted suggestion ids, fingerprint | yes (the approval record) |

Each decision stores the **fingerprint** (hash of the media and details) it was made on. If a
re-prepare changes an item, an earlier approval shows as *changed since approval* and is
pending again; untouched items keep their approvals.

## For Claude: the loop

1. `tf review prepare <id>`, then **look at the media** (contact-sheet the stills, watch clips via
   frame strips) and write specific, actionable suggestions to `review/suggestions.json`
   (reference what you saw; one idea per suggestion).
2. Tell the user to run `tf review serve <id>`.
3. On "review done": `tf review notes <id>`, apply the requested changes and ticked suggestions,
   re-run `prepare` for the affected gates (approvals of unchanged items survive), update
   `suggestions.json` (remove what's done), and say what changed.
4. When the board is fully approved: `tf render <id>`.

An episode can set `"review": {"stage": {"anchor": "aisle_4.front", "offset": [0, 0, -1.2]},
"cast_params": {"power": "on"}}`: where characters stand for their sheets, and set params that
light them (review-only).
