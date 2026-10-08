# Screen Score rubric: DRAFT for agreement (8 Oct 2026, US Central)

Proposed by Claude. Codex replies "agree" or with changes, and Pete settles it.
Nobody scores until it's agreed.

## Per screen: six criteria, 1–5 each

Score the screen (one row of `MANIFEST.tsv`, or a group of rows that are the same
screen in different viewports, with per-viewport notes).

| # | criterion | 5 means | 1 means |
|---|---|---|---|
| C1 | **Purpose and next action** | a first-time player can say what this screen is for and what to press next, in under 3 seconds | the purpose or the next step is unclear |
| C2 | **Hierarchy and layout** | the primary action is the most prominent thing; grouping, alignment and spacing are consistent; nothing competes | elements fight for attention, are misaligned, or crowd |
| C3 | **Legibility** | every string reads at the device's real size; contrast is good; no clipping, overlap or truncation that loses meaning | text clips, overlaps, is too small, or loses meaning when truncated |
| C4 | **Fit to the viewport** | uses the space the viewport gives it; safe areas respected; nothing important at the edges; no dead bands that read as a bug | big unexplained empty areas, notch collisions, or content off-canvas |
| C5 | **Consistency** | same components, colours and wording as the rest of the game, inside the 8-bit constraint | one-off styles or wording, or it breaks the 8-bit look |
| C6 | **Feel** | reads as a buhurt club game: theme, tone, and that it's *your* club | generic, flat, or off-tone |

**Screen score** = the mean of C1–C6, to one decimal. **Game score** = the mean of
the screen scores.

## Findings

Every finding carries:
- **id:** `S<screen number>-<n>`, for example `S04-2`.
- **evidence:** the file and region, for example `v19x9/24_fight_live.png`, top-left HUD.
- **severity:**
  - **S1** wrong or missing information, a blocked action, or content off-screen or illegible;
  - **S2** slows or confuses a player;
  - **S3** polish.
- **suggestion:** a concrete change, not "improve X".
- **effort:** S (an hour), M (a day), or L (more).
- **traced to (optional):** the file and function where it lives, if you checked
  the code.

**Measured vs opinion:** mark a finding **[seen]** if the render shows it (a clip,
an overlap, an empty band), or **[judgement]** if it's design taste.

## Deliverable format

```
# Screen Score #1: <reviewer>
Game score: x.x / 5

## Top 10 fixes (ranked by player impact ÷ effort)
1. <id> — <one line>
...

## Scores
| screen | C1 | C2 | C3 | C4 | C5 | C6 | score | note |
...

## Findings
### <screen number> <screen name>
- S04-1 [seen] S2 — <finding>. Evidence: <file, region>. Suggestion: <...>. Effort: S.
...

## Cross-cutting suggestions
(themes that span screens: type scale, button styles, wide-screen use, colour)

## What I could not judge from stills
```
