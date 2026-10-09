# Balance #3: all levers (handoff to Codex, 8 Oct 2026, US Central)

**For:** Codex (ChatGPT), on Pete's PC. Claude applies what Pete picks and runs the gate.
**Base commit:** `95cd1d1` (main on Pete's PC), which includes Harness #2 (REGISTER 31.04).
Claude's REGISTER 31.05 fix lands while you work. It only changes WHICH men a fought
bout pays and wears; simmed careers (`skip_event`, every probe) don't touch it, so your
probe numbers are unaffected. Rebase your worktree onto it when it appears.

## Pete's ask (8 Oct 2026, verbatim)

> "Let's get Codex to do a Full "All levers" balancing with his own ideas and see what
> happens. It'll be a big balancing session with lots of multiples of variables that
> you can think of and that he can think of."

Free rein. This is the biggest balance pass so far. Use your own ideas as well as the list
below, and test combinations, not just one knob at a time.

## What "better balanced" has to mean (agree this first, in your PLAN)

Write your targets in `docs/balance-3/codex/PLAN.md`, with the clock time, **before** you
read any result. Pete's standing targets are below; add your own health metrics on top:

1. **Pacing.** The engaged player wins the first National title in about 10 seasons
   (REGISTER 31.02: report-faithful LOW, `Career.LEVEL_XP` 8, measured 10.44). A passive
   player is slower, but not hopeless.
2. **Every purchase is a decision.** Each lever a player can spend on (sessions, ceiling
   raises, signings, kit, armorer, captains, facilities, arena, cap, insurance, the
   infirmary, camp) should pay off for some plan, and none should dominate. Harness #2
   showed how one shop can quietly be a trap (`docs/harness-2/`).
3. **Money never balloons or starves.** The gold-button bot once banked about 18,000 CC
   (REGISTER 30.84). Pete's oldest complaint was the reverse (15 Sep 2026: *"The income
   is either too low or costs are too high"*). Report the bank curve by season and tier.
4. **The ladder holds.** Little yo-yoing between tiers. The AI clubs stay a real test
   at every tier, and cups and the Worlds matter.
5. **The constraints in `docs/CONSTRAINTS.md` don't move:** C-1 to C-6, mirror
   symmetry at about 50±9, and the roster beating the thumb at a heavy deficit (C-6c,
   under 40%).

## Levers (Claude's list; add yours)

Inventory the current values yourself (`grep -n "^const" <file>`). Don't trust this list
for numbers.

| Family | Where | Examples |
|---|---|---|
| Progression | `scripts/game/career.gd` | LEVEL_XP, points per level, XP per bout, win and loss, paid sessions, ceiling raise cost, potential drift, aging and retirement |
| Income | `club_office.gd`, `season.gd`, `season_cups.gd`, `arena.gd`, `club_event.gd` | gate, counter, CREDITS_WIN, DRAW and PROMOTED, finishing prize, cup purses and podium, demos, transfers, kit sponsors |
| Costs | `club_office.gd`, `arena.gd`, `armorer.gd`, captains, facilities | wages, upkeep, facility and arena levels, federation compliance, travel, cap raises, KITTY, insurance |
| Kit | `quartermaster.gd`, `fighter_card.gd` | WEAR, TOP, COST, SPONSOR_CC, HARNESS_BASE_BONUS (just landed; change them only with a reason) |
| League | `league_world.gd`, `season.gd` | RATING_SCALE, AI power bands per tier, promotion and relegation, opposition_scale (the grade), DRAW_ROUND_CHANCE |
| Staff | captains, regimes, `armorer.gd` | regime gains and injury chance, captain presence, armorer stars and caps |
| Market | free agents, scouting, contracts | asking prices, potential spread, contract lengths, veteran cash-ins |
| Fight | `scripts/melee/tuning.gd` | only with the C-numbers and symmetry checks on every variant |

## Method (suggested; improve it)

1. **Screen** every lever one at a time, low and high, to find which ones move the
   targets. Rank them by effect size.
2. **Combine** the influential ones with a fractional factorial or Latin hypercube, not
   one knob at a time. Pete asked for multiples of variables.
3. **Several kinds of player.** Results must hold for the passive, engaged
   (report-faithful), specialist and sensible-buyer managers, at least. Add a "careless"
   one that doesn't repair or train, if you can.
4. **Three seed sets.** Tune on the default bases (9001 5150 2718 6060 8123). Check on the
   held-out set (17011 29033 43049 67061 91081). Confirm only once, at the end, on a
   new set you name in PLAN.md before any result. You can't reuse 110017 130021 150041
   170047 190027: they confirmed Harness #2.
5. **Fight-side changes** need the melee checks too (`tests/test_c6.gd`,
   `tools/probe_harness_melee.gd`, and your mirror fixture), because careers resolve bouts
   by `LeagueWorld.quick_bout` and never see the fight.
6. You may write new probes. `tools/manager.gd` is pinned by your harness probe's hash,
   so put new player policies in your own copy, as you did with the sensible buyer.

## Deliverable

`docs/balance-3/codex/REPORT.md`:

- the sensitivity table, ranked;
- your recommended set, at most 12 changes, each as `file: NAME old → new`, with the
  measurement that justifies it;
- before and after on every target, for each player type and each seed set, with the
  per-base spread;
- what must not move, and the proof that it didn't;
- anything you'd cut or restructure rather than retune;
- design questions only Pete can answer.

Put a standalone patch of the recommended set next to it, plus patches for any runner-up
sets.

## Rules

- Work in a scratch worktree. No changes to `main`, no commits, no pushes. Pete pushes;
  Claude applies and lands.
- Raw `.jsonl` journals are gitignored; leave them where they land. Keep summaries small.
- Use US Central times off the clock, never estimated.
- Godot: `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`. Don't claim the
  full gate passed; Claude runs it.
- Every visible string goes through `UiKit.t()` and `locale/strings.csv` in 9
  languages. If your change adds text, list the strings; Claude translates them.
- Pete's rulings in `docs/REGISTER.md` stand unless you name the ruling you'd overturn and
  why.
