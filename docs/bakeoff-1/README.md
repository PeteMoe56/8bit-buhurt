# Bake-off #1 — shared data (8 Oct 2026, US Central)

**Question (from a tester, after updating to 1.0.1/1.0.2):** *"Getting characters
leveled up, money and such I've noticed have jumped a lot, I didn't see any of
that really going before the update."*

**Task for each assistant, blind:** a one-page verdict — what changed, how sure
you are, what the data can and cannot show, and the single next measurement.
Score sheet: verified findings, unsupported claims, usability, turns to done,
rule compliance (AI-TEAM.md §4, §7).

## Builds

| label | commit | what it is |
|---|---|---|
| `1.0.0` | `31ca64d` | "Play bundle 1.0.0 (3)" — the build testers had before the update |
| `now` | `4be2821` + `tools/probe_level_flow.gd` | 1.0.2 code (sim/economy identical to 1.0.2 (6)) |

`changes_since_1.0.0.txt` lists every commit between them that touched
`scripts/league`, `career.gd`, `melee_sim.gd` or `tuning.gd`;
`economy_diff_1.0.0_to_now.diff` is the diff of the economy/career/tuning
files (melee_sim's fight-feel diff left out for size — ask if you need it).

## How the numbers were made

Same commands, same seeds, on both builds, Godot 4.6.2 headless:

```
godot --headless --path . --script res://tools/probe_level_flow.gd -- 2 12
godot --headless --path . --script res://tools/career_score.gd -- 3 14 <base>   # for each base
```

Seed bases: 9001 5150 2718 6060 8123 (the project's five check bases).

- `flow_1.0.0.tsv`, `flow_now.tsv` — 2 careers × 5 bases × 12 seasons = 120
  rows each. Columns: `tier` (0 Backyard … 3 National, at season end),
  `season_pts` (net stat points gained in-season by men on the books all
  season), `lv` (levels taken at the winter), `lv_pts` (stat points those
  levels added), `unspent` (men still holding a level after the winter),
  `cc_in` / `cc_out` (closed books for the season), `bank` (credits at season
  end), `top_in` (three biggest income lines).
  **Known flaw (found by ChatGPT in review):** `season_pts` is 0 in every row
  on both builds: stats only move at the winter, so the column measures nothing.
  `unspent` counts men holding a level, not the number of levels held.
- `scores.tsv` — `career_score.gd` per base: 3 careers × 14 seasons.
  `title` = season the National Division was first won (15 = not within 14);
  `t1/t2/t3` = season each rung first reached; `power` = club power at the end;
  `cc` = mean end-of-season bank; `worlds` = Worlds titles; `youth_*` = the
  same for the stronger "youth" manager.

## What the simulated player does and does not do (read before concluding)

- It is `tools/manager.gd` (`ProbeManager`). It spends every level at the
  winter through the **automatic** `Career.level_up` path — it never calls
  `Career.level_into`, the manual path a real player uses, which 1.0.1 changed
  (`d4359a6`: a level near the ceiling now lands all 3 points).
- It **never buys harness**, so the 1.0.1 harness price change (doubled) is
  invisible here. It repairs kit, builds the arena, raises the cap, runs extra
  sessions and buys ceilings.
- It reads **hidden ceilings** (`ORACLE`) when judging signings.
- It sims every bout; it never sees the post-bout "Spend levels" screen that
  1.0.1 added, so any effect of that screen on a real player is outside this
  data.
- 10 careers per build in the flow file and 15 per build in scores: small N.
  The difference between bases is a fair guide to the noise.
