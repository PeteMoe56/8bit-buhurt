# Bake-off #2: balance review (8 Oct 2026, US Central)

**For:** Codex (ChatGPT) and Claude, each working blind. Pete judges.
**Snapshot:** `d5ce8a9` plus the bake-off #2 commit, which adds this folder,
policy switches in `tools/manager.gd`, and extra columns in `tools/probe_level_flow.gd`.
With the switches unset, both behave exactly as they did at `d5ce8a9`.

## The task

Pete: *"Balance this game better."* Using the data in this folder and anything else
in the repo:

1. **Verdict on the current balance.** What the numbers say about pacing, money and
   levels, and how sure you are. Keep measured results separate from hypotheses.
2. **Up to five proposed changes**, each written as `file: NAME old → new`, with:
   - the symptom it fixes, as a number;
   - the measurement that justifies it, which already exists here or which you
     name exactly (probe, args, seeds);
   - what it should move, and what must not move (the C-numbers in
     `docs/CONSTRAINTS.md` and the balance tier, `balance_tier.txt`).
   Claude applies any change Pete approves, runs the balance tier and reports back.
   No proposal without its measurement (AI-TEAM.md §5).
3. **An audit of the instrument.** Anything in these files that is broken,
   misleading or can't see what it claims to. Bake-off #1 shipped a dead column;
   assume this one can have one too.
4. **Design-intent questions for Pete:** where the numbers can't decide and it's
   his call.
5. **One recommended next measurement.**

**Allowed changes:** none to game code. You may add `tools/probe_*.gd` files and run
anything. Put your answer in `docs/bakeoff-2/codex-answer.md`. Claude's answer is
sealed outside the repo, and its SHA-256 is at the bottom of this file. Don't
read `Claude outputs/`.

**Scored on (AI-TEAM.md §7):** correct, usable as-is, turns to done, fits the rules.

## What's here

| file | what |
|---|---|
| `flow_policies.tsv` | `probe_level_flow.gd`: 2 careers × 5 bases × 12 seasons × 8 policies = 960 rows |
| `scores_policies.tsv` | `career_score.gd`: 5 careers × 14 seasons per base, 5 bases × 8 policies = 40 lines |
| `summary_by_policy.tsv` | means of the two files above (`tools/bakeoff2_summary.py`), with no filtering |
| `balance_tier.txt` | `bb.sh test --balance` at this snapshot, policies unset: 5 runs, green |
| `commands.sh` | the exact commands that made every file |
| `../bakeoff-1/` | bake-off #1: the same probe at 1.0.0 (`31ca64d`) vs 1.0.2, baseline policy |

Engine: Godot 4.6.2.stable.official.71f334935, headless, Linux.
Seed bases: 9001 5150 2718 6060 8123. A career's seed is `base + i × 7919`.

## The policies (what the simulated manager does differently)

The manager is `tools/manager.gd` (`ProbeManager`) in every row. The new switches
are set from the environment:

| tag | `RB_LV` | `RB_LV_BOUT` | `RB_HARNESS` | meaning |
|---|---|---|---|---|
| `auto` | auto | 0 | 0 | **The baseline every pacing number since 16 Sep was measured on.** Levels spent at the winter only, through the automatic `Career.level_up` (lowest stat under its peak; stops at the ceiling mid-level). |
| `auto+bout` | auto | 1 | 0 | Same door, but every placeable level is also spent after every event in the season |
| `low` | low | 0 | 0 | `Career.level_into` (the player's door, changed in 1.0.1 by `d4359a6`), into his lowest stat with room. Winter only. |
| `low+bout` | low | 1 | 0 | …and after every event |
| `spec` | spec | 0 | 0 | `level_into` his **highest** stat with room (a specialist build). Winter only. |
| `spec+bout` | spec | 1 | 0 | …and after every event |
| `auto+harness` | auto | 0 | 1 | Baseline levels, plus a harness policy (below) |
| `spec+bout+harness` | spec | 1 | 1 | The "engaged player" combination |

**Harness policy:** each week, before the paid session and the ceiling raises, and
out of everything above the bills (not behind the `KITTY` reserve):
- hire the highest-star armorer from `Armorer.pool` who will come and whose wage is
  covered, because a harness above Rust needs an armorer who can make it
  (`Armorer.cap_of` = stars − 1);
- then buy one rung for the starting man in the worst grade, if affordable.

`harness_cc` counts armorer hire fees plus harness purchases. **It does not count
the armorer's later wages**, which go through the upkeep bill.

## Columns

**`flow_policies.tsv`**, one row per career-season:
`base seed season tier season_pts lv lv_pts unspent cc_in cc_out bank top_in lv_season banked harness_cc power policy`

- `tier`: 0 Backyard … 3 National, at season end.
- `season_pts`: net stat points gained during the season by men on the books at
  both ends.
- `lv`, `lv_pts`: levels taken at the winter, and the stat points they added, by
  men on the books before and after the winter.
- `lv_season`: levels placed during the season (only with `+bout`), by **any** man
  on the roster at the time, including men signed that season.
- `unspent`: **men** (not levels) still holding a placeable level after the winter.
- `banked`: placeable levels after the winter, summed over men
  (`Career.levels_banked`).
- `cc_in`, `cc_out`: the season's closed books. `bank`: credits at season end.
  `top_in`: the three biggest income lines.
- `harness_cc`: as above. `power`: club power at season end. `policy`: the tag.

**`scores_policies.tsv`**: `policy base line`, where `line` is `career_score.gd`'s
`SCORE` line, averaged over 5 careers:
- `title`: season the National Division was first won;
- `t1/t2/t3`: season each rung was first reached;
- `tier`: tier at the end; `power`: club power at the end;
- `cc`: mean end-of-season bank;
- `youth_*`: the same for the "youth" manager.

## What this data can and cannot see (read before concluding)

- **Fights are simmed, never thumbed.** Per `docs/CONSTRAINTS.md` C-3, drawing
  nothing wins about 46% of an even mirror, and C-2 says a good thumb moves an even
  match to about 87%. So every row here is a **floor** for a player who plays the
  fights. Pete reads balance that way: a losing career can be turned around.
- **The manager reads hidden ceilings** (`Read.ORACLE`) when signing.
- **"After every event" is a fixed stand-in for a player,** not a model of one. A
  real player spends levels when the after-action report's "Spend levels (N)" button
  asks (added in 1.0.1), which may be more or less often.
- **`spec` and `low` are two corners, not the space.** Real players mix.
- **The harness policy is harness-first.** It takes money ahead of the paid session
  and the ceilings, so its rows measure "harness instead of those", not harness in
  isolation.
- **`tier` saturates:** most careers reach National (3) by about season 8, so
  `tier_s12` barely separates policies. Use `title`, `t1`–`t3` and `power`.
- **`title` is censored at 15**, meaning not won within 14 seasons
  (`MISSED = years + 1`). A mean that includes 15s understates the gap.
- **`worlds` in the SCORE line is misnamed.** It is the club's `titles` counter at
  the end (`career_score.gd` sets it from `clubs[player]["titles"]`), which counts
  every cup won at any tier, playoffs included (`league_world.gd` `_record_honors`).
  The National playoff champion also gets +1 at the roll-over (`league_world.gd`
  around line 1065), so a National title may count twice. It appears in the summary
  as `score_titles_counter`. Read it as a trophy count, and audit it.
- **Small N:** 10 careers per policy in the flow file, 25 per policy in scores. The
  spread between bases (`scores_policies.tsv`) is a fair guide to the noise.
- **The manager never opens Upgrades** beyond the cap, the arena and federation
  compliance (see `tools/manager.gd`), so camp, infirmary and insurance spending is
  outside this data.

---

Claude's sealed answer, SHA-256 (verify after both are in):
`b090cf5c17f0bb85de8c9a59c9e1db8630efe3baad3c971770d1655b7e0c89ab`
