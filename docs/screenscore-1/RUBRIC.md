# Screen Score rubric: LOCKED (8 Oct 2026, 12:35 US Central)

Claude drafted it, Codex amended it (`codex-rubric-proposal.md`, all six amendments
accepted), and Pete agreed it. Both reviewers score against this version.

## Unit of scoring

- **Score every render in `renders/MANIFEST.tsv` separately**, and include every row
  in the results.
- A **logical screen** is one screen in one state, such as `04_season_club`, rendered
  at up to four viewports. Its score is the mean of its viewport scores.
- The **game score** is the mean of the logical-screen scores, so a screen rendered
  at more viewports doesn't get more weight.
- Aggregate unrounded and round only for display. Publish per-viewport means and the
  worst findings beside the game score.
- A viewport the README says wasn't rendered is not a defect.

## Six criteria, 1–5 each, equal weight

**Anchors (every criterion):**
- 1 = severe failure of the criterion;
- 2 = major friction;
- 3 = usable, with a clear weakness;
- 4 = good, with minor issues;
- 5 = meets the criterion.

Every deduction is backed by a finding. Uncertainty alone is not a deduction.

| # | criterion | what is judged |
|---|---|---|
| C1 | **Purpose and next action** | the screen's purpose and the next action are apparent from the render |
| C2 | **Hierarchy and layout** | the primary action is easy to find and appropriately prominent (on a report, the information can rightly dominate); grouping, alignment and spacing are consistent |
| C3 | **Legibility** | readability at the documented canvas and presentation scale: contrast, no clipping, no overlap, no truncation that loses meaning. No claims about physical-device legibility, touch feel or controller use from a still. Tight English can prompt a translation-fit check; an unseen translation failure can't lower the score. |
| C4 | **Useful fit to the viewport** | safe areas respected; readable, reachable content placed well. Purposeful margins can score 5. Unexplained bands cost points only where they create a demonstrable layout weakness or look broken; record the width, region and lost opportunity before suggesting expansion. The list's 1.70:1 ratio and the pixel-art rules stay. |
| C5 | **Consistency** | same components, colours and wording as the rest of the game, inside the 8-bit constraint. Taste calls are labelled. |
| C6 | **Feel** | reads as a buhurt club game: theme, tone, *your* club. Labelled as judgement and tied to the brief's theme and art constraints. |

## Findings

Every finding carries:
- **id:** `S<screen number>-<n>`, for example `S04-2`.
- **evidence:** every affected render, with its region, for example
  `v19x9/24_fight_live.png` top-left HUD. One defect seen in several viewports is
  one finding that cites each of them.
- **tags:**
  - **[seen]** what the render shows;
  - **[judgement]** its impact or a taste call;
  - **[needs validation]** any behavioural claim, such as "players will miss this".
- **severity:**
  - **S1:** essential information is wrong or unreadable, or an essential action is blocked;
  - **S2:** meaningful friction;
  - **S3:** polish.
- **suggestion:** a concrete change, not "improve X".
- **effort:** S, M or L. A rough estimate, not a delivery promise.
- **traced to (optional):** the file and function where it lives.

S1 and S2 counts are listed beside every mean, so a severe failure can't disappear
in an average.

## Deliverable format

```
# Screen Score #1: <reviewer>
Game score: x.x / 5   (S1: n, S2: n, S3: n)
Per viewport: v16x9 x.x · v19x9n x.x · v19x9 x.x · v16x10 x.x

## Priority fixes
(S1 first, then S2, then S3; within each, by impact ÷ effort)
1. <id> S1 — <one line>
...

## Scores
| render | viewport | screen / state | C1 | C2 | C3 | C4 | C5 | C6 | score | S1/S2 | note |
...
(every manifest row)

## Logical-screen means
| screen / state | viewports | mean | worst finding |

## Findings
### <screen number> <screen name>
- S04-1 [seen][judgement] S2: <finding>. Evidence: <files, regions>. Suggestion: <...>. Effort: S.

## Cross-cutting suggestions

## What I could not judge from stills
```
