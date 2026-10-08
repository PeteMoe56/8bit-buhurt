# Harness #2: make harness worth buying (8 Oct 2026, 15:20 US Central)

**For:** Codex (ChatGPT) and Claude, each working blind. Pete judges, then we compare.
**Base commit:** `1dfea31` plus the commit that adds this folder. No game code differs from `1dfea31`.

## Pete's ruling (8 Oct 2026, verbatim)

> "Make it worth buying, make better gear break down slower, play with increases and
> decreases between gear lower gear breaking quicker, and higher gear more resilient."

He wants a **full array** of tests from the two of us. Each designs and runs its own
variants against the same question, blind. Then we swap results and find the best answer.

## Why this exists

Your harness verdict at `27367d2` (`docs/bakeoff-2/harness/VERDICT.md`, still untracked
on the PC) found that buying harness **hurts** a career. Claude reproduced the headline:

| arm | titles in 20 seasons | mean capped wait |
|---|---|---|
| no_harness | 25/25 | 10.88 |
| harness_first | 7/25 | 19.36 |
| development_first | 5/25 | 18.60 |

## The mechanics as they stand (read the code, don't trust this summary)

- `scripts/league/quartermaster.gd` holds three values per grade (Rust, Mild, Hardened, Stainless, Titanium):
  - `TOP` (condition ceiling): 0.90, 0.96, 1.00, 1.00, 1.00.
  - `WEAR` (multiplier): 1.00, 0.86, 0.72, 0.58, 0.50.
  - `COST` (to buy the rung): —, 6, 14, 28, 48 CC.
- Wear happens in `scripts/league/season_bouts.gd` `bout_wear`: each bout, every man in
  the starting five loses `BOUT_WEAR` (0.06) × trait × `wear_scale`. Simmed bouts wear
  the same. Training doesn't wear.
- Condition reaches rating only through `FighterCard.effective_base() = base *
  lerpf(0.78, 1.0, armor)`. Base carries 0.24 of rating, so condition's whole range is
  worth about 1.5 rating points.
- Repairs (`ClubOffice.repair_kit`, `kit_cost`) add `KIT_STEP` 0.16 once a week, on
  fixture weeks only. Below a gap of about 0.2 they cost 0 CC. Repairs are refused
  within `WORTH_DOING` of the ceiling. The winter (`season_winter.gd`) repairs up to
  `repair_top`.
- An armorer makes metal up to `Armorer.cap_of = stars − 1`. Wages are [0, 0, 2, 4, 9, 18].
- `FighterCard.passes_inspection`: below 0.35 a man can't fight.
- **AI clubs have no kit.** They are a power number, so wear changes touch only the player.
- Careers are resolved by `LeagueWorld.quick_bout` (Elo on club power), not the melee sim.
  The melee sim's own harness (`Tuning.HARNESS_FLOOR`, `melee_sim.gd` ~2135) isn't
  exercised by career probes.
- `tests/test_quartermaster.gd` forbids any rung wearing faster than 1.00 ("not a nerf").
  **Pete's ruling overrides that test.** Lower grades may now wear faster than 1.00.
  Note it if your variant does.

## The task

1. **Design your own variants:** at least 2, at most 5. Use any knob family you can
   justify, including `WEAR`, `TOP`, `COST`, `BOUT_WEAR`, `KIT_STEP` and `kit_cost`, armorer
   cap and wages, the condition weight in `effective_base`, or something new.
   - Each variant must honour Pete's ruling: lower grades wear quicker, higher grades
     slower, with uneven steps between grades.
   - Write each change as `file: NAME old → new`.
   - Prefer one knob family per variant where you can, so the effects separate.
2. **Measure every variant** with your own `tools/probe_harness_budget.gd`, unchanged:
   `-- 5 20 --out=res://docs/bakeoff-2/harness/codex-<variant>`. Use the default bases
   9001 5150 2718 6060 8123.
   - Apply each variant in a scratch worktree or a stash-free copy, never on `main`.
   - If you think `harness_first` is an unfair stand-in for a sensible buyer, you may add
     a fourth arm. Report it separately, and keep the original three arms comparable.
3. **Report per variant:**
   - titles/25 and mean capped wait for each arm;
   - mean income per season;
   - harness CC spent;
   - how much the no_harness arm moved from 10.88, which is the cost to a player who
     never buys;
   - anything that broke (validation_passed, inspection failures, men unable to field).
4. **Recommend one variant**, or a combination, with the measurement behind it. Say what
   must not move: the C-numbers in `docs/CONSTRAINTS.md` and the engaged-player pacing
   of about 10.4 seasons to the first title (`Career.LEVEL_XP` 8, REGISTER 31.02).
5. **Name one design question for Pete** that the numbers can't settle.

## Rules

- **Allowed changes:** none committed to game code.
  - Put your variant patches (`git diff` output) and results in
    `docs/harness-2/codex/`, with your report in `docs/harness-2/codex/REPORT.md`.
  - Probe output goes under `docs/bakeoff-2/harness/codex-*`; the probe requires that
    prefix.
  - Don't commit or push. Pete pushes; Claude lands and commits.
- **Blind:** don't read `Claude outputs/` or `docs/bakeoff-2/harness/claude-*`. Claude's
  plan is sealed, and its SHA-256 is below. Claude also won't read your folder until you're
  done.
- **Times:** US Central, from the clock, never estimated.
- **Godot:** `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`, headless. Probe runs
  are verified on your machine. The full test gate on Windows isn't. Don't claim the
  gate passed; Claude runs the balance tier and the gate on whatever Pete picks.
- `tools/manager.gd` is pinned by your probe's hash. Don't edit it.

## After both are in

Claude unseals its plan, both reports sit side by side in this folder, and each of us
reviews the other's numbers (same seeds, so runs should be reproducible across
machines). Pete picks. Claude applies the pick, runs the balance tier and the full gate,
and lands it.

---

Claude's sealed variant plan (written 8 Oct, 15:17 CT, before any result was read), SHA-256:
`1950a0f9d0ec36ceb9791f70a5c4a37f78c93561dab06dc5e39de115ed7fe99f`
