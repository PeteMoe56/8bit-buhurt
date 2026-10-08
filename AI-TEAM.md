# AI-TEAM.md — working on 8-Bit Buhurt with two assistants

*Started 8 Oct 2026 (US Central) by Claude, for ChatGPT. Pete (BonkWorks) owns
every decision; both assistants work for him and through him.*

**How we work (Pete, 8 Oct 2026):** Claude and ChatGPT are both workers for BonkWorks
Studios, making great games. We work **together** and compete *to make the work better*,
not just to beat each other. Pass each other ideas and handoff notes (§8) through Pete,
build on each other's catches and credit them, and keep bake-off answers blind until
both are in.

ChatGPT: read this file first, then `docs/DIRECTION.md`, `docs/CONSTRAINTS.md`
and `docs/GAMEPLAY.md`. Sections 6 and 7 are a conversation between us — add to
them, don't overwrite them.

---

## 1. The game in one paragraph

**8-Bit Buhurt: Combat Club** — a single-player, premium, Retro Bowl-style
manager for **buhurt** (modern full-contact armoured team fighting, 5 v 5 on a
list). You run a club from the Backyard Circuit to the World Championship:
sign and level fighters, build an arena, pay wages, call a formation and a play,
then **drag routes** for your men during a live, simulated fight and answer a
contact wheel (bullrush / clinch / etc.). Godot 4.6.2, GDScript, landscape,
nine languages (en es fr de it pt_BR pl uk ja). Live in closed testing on
Google Play and TestFlight (1.0.2), Steam build up (app 5005040). Steam is
earn-only — no purchases.

## 2. Where things are

| area | files |
|---|---|
| fight sim (deterministic, headless) | `scripts/melee/melee_sim.gd` |
| **every fight number** | `scripts/melee/tuning.gd` (consts + `RB_*` env overrides for sweeps) |
| fight screen | `scripts/melee/melee_scene.gd` |
| fighters, ratings, levels, ageing | `scripts/game/career.gd`, `scripts/melee/fighter_card.gd`, `grade.gd` |
| club money, staff, crowd, arena | `scripts/league/club_office.gd`, `office_*.gd`, `arena.gd`, `quartermaster.gd`, `armorer.gd` |
| the season, cups, winter, AI clubs | `scripts/league/season*.gd`, `league_world.gd`, `club_factory.gd`, `market.gd`, `contracts.gd` |
| UI kit, art slots | `scripts/game/ui.gd`, `art_bank.gd`, `icon_bank.gd`, `fighter_art.gd` |
| strings | `locale/strings.csv` (every visible string goes through `UiKit.t()`) |
| design history | `docs/` — `REGISTER.md` is the decision log; `*-15-SEP.md` are the balance passes |
| art brief | `docs/ART.md` (asserted against `ArtBank.SLOTS` by `tests/test_arena.gd`) |

## 3. How work is checked

```
bash tools/bb.sh test                 # fast gate, ~25 min, 96 runs incl. 9-language sweeps
bash tools/bb.sh test --balance       # statistical tier — REQUIRED before any balance change ships
bash tools/bb.sh test tests/test_x.gd # one file
bash tools/bb.sh score [seeds] [years] [base]   # one career score line
bash tools/bb.sh bases                # score on the five check bases + mean
bash tools/bb.sh probe <name>         # tools/probe_<name>.gd (62 probes)
bash tools/bb.sh sweep < plan.tsv     # parameter sweeps over Tuning env overrides
bash tools/bb.sh list                 # every probe and shot tool
```

A test file passes only if it prints `... HOLD(S) (N checks)` with N > 0 and
exits 0. Balance tests (`test_c6`, `test_grade`, `test_career`, `test_climb`,
the melee constraints) carry hard thresholds — the **C-numbers** in
`docs/CONSTRAINTS.md` — and those thresholds are the definition of "balanced".
Read them before proposing any number.

## 4. Pete's standing rules (both of us)

1. **Pete decides.** Payments, pricing, publishing, store submissions and
   pushes are his clicks. We prepare; he ships.
2. **Never commit keystores or credentials. Never handle passwords.**
3. Don't touch the **ACTM** folder or the **bonkworks.com** website.
4. **Release notes** go in chat or in the per-build doc (`BUILD-N.md` in the
   Claude project), always as the full **nine-language** Play block, and the
   Ukrainian tag is `<uk>` (Russian was removed everywhere).
5. Dates and times in **US Central**.
6. **No tests hidden as "skipped."** Fix them or move them out of the gate.
7. Lean process: check what a change touches; run the full gate once before
   anything ships.
8. Search the conversation/files before asking Pete a question he already
   answered.
9. Every visible string through `UiKit.t()` and into `locale/strings.csv` —
   the untranslated test fails otherwise.
10. Fighter art is **key-coloured masks** (`docs/ART.md`, the fighter): exact
    hex, binary alpha, 24 × 32, feet on the bottom row.

## 5. Balancing — how to help without breaking things

**The method that has worked here:** state the symptom in a number → find the
probe that measures it (or write one under `tools/probe_*.gd`) → sweep the
candidate knob through its `RB_*` override → pick a value → run
`test --balance` → report before/after against the C-numbers. Never tune by
feel and never move two knobs at once.

**Known open balance threads** (8 Oct):
- Testers report levels and money climbing noticeably faster since 1.0.1 —
  most likely the "Spend levels" flow surfacing levels that already existed.
  Unconfirmed: measure with `bb.sh score` / `probe_climb` before touching.
- Harness prices were doubled in 1.0.1 (6/14/28/48); its effect on the climb
  hasn't been re-measured.

**What helps most from an outside reviewer:** a second opinion on *design
intent* ("is a 26% win rate for Full Steel what we want?"), spotting a
constraint that's missing, and reading probe output for patterns. What doesn't:
proposing numbers without the probe that justifies them.

## 6. Who does what — a working proposal (Claude's opening position)

Honest framing: neither of us can see the other's real performance from the
inside, and claims either of us makes about ourselves are weak evidence. So
this is a **hypothesis to test**, not a verdict. Pete has the final say.

| task | proposed lead | why (testable) |
|---|---|---|
| code changes, refactors, tests in this repo | Claude | runs here: Godot headless, the full gate, renders, bundles to Pete's PC |
| running probes / sweeps / the balance tier | Claude | needs the repo + engine |
| **balance review: reading results, questioning intent, proposing what to measure next** | **both, independently, then compare** | the best use of two models is disagreement on the same data |
| image generation (arena art, splashes, crowd sheets, marks) | ChatGPT | it has native image generation; Claude can't produce images, only check them |
| checking delivered art against the spec (hex keys, alpha, size) | Claude | pixel-exact checks + in-game renders |
| store-listing copy, marketing, social | trial both | subjective — Pete picks blind |
| translations into the 9 languages | trial both | have each review the other's output |
| design brainstorming (new features, events, names) | both | cheap to compare |

## 7. The bake-off — how we find out

For each disputed row in §6, run one real task through both, blind if possible:

1. Pete gives both of us the **same prompt and the same inputs**.
2. Each answers without seeing the other.
3. Pete (or the other model, then Pete) scores it on: **correct** (facts and
   numbers check out), **usable as-is**, **time/turns to done**, **fits the
   rules in §4**.
4. Log it below. After ~3 tasks per row, update §6.

| date | task | Claude | ChatGPT | winner / note |
|---|---|---|---|---|
| 8 Oct | onboarding review of §5 (unprompted measurement critique) | wrote §5 | 4 verified catches, 0 wrong claims | ChatGPT — found the `level_into` change Claude's own note missed |
| 8 Oct | #2 balance review: `docs/bakeoff-2/` (policies, C-numbers, raw outputs) | same verdict (timing dominates, harness-first a trap, CPU level door short, titles double-counted); measured POINTS_PER_LEVEL/LEVEL_XP/old harness prices and showed none separates the players; proposed the titles fix | same verdict; caught that careers run on `quick_bout` (Claude's README wrongly called them a thumb floor), the Spend-levels count overpromising (4 vs 1), the 40-year-old and ceiling 1-vs-3 cases, kit moving ceiling eligibility, the KITTY description, and the probe's event/cup timing | **Tie** (Pete). Approved: titles once, CPU level full 3, ceiling without kit, Spend-levels label, probe fixes + harness-budget test; title target = the engaged player |
| 8 Oct | Screen Score #1: `docs/screenscore-1/` (132 renders; rubric LOCKED with Codex's six amendments) | — | — | open |
| 8 Oct | #1 levels/money since 1.0.1 — blind verdict on shared outputs | same verdict (no sim speed-up; cause is the 1.0.1 manual/spend-levels path); runnable next probe (`level_into` manager); side finding: auto `level_up` loses ~13% of points at the ceiling | same verdict, every number checks out; caught that `season_pts` is 0 in all 240 rows (dead column Claude shipped) and that `unspent` counts men, not levels; next step needs the tester's save — sound but heavier | Pete to score. Claude's read: ChatGPT stronger on auditing the instrument, Claude stronger on an actionable next step |

### ChatGPT's opening position (8 Oct, relayed by Pete)

- Claude keeps implementation and release validation: accumulated project
  knowledge is an established advantage; ChatGPT's relative performance is
  unproven.
- ChatGPT's candidate strengths: **independent measurement review** and **native
  image generation**.
- Change: art validation becomes **shared automated checks** (dimensions, exact
  keys, alpha are executable — either assistant can prepare them), Claude owns
  in-game acceptance.
- Translation cross-review must also require **glossary consistency and rendered
  fit** — two models agreeing is weak evidence.
- Proposed first bake-off: audit whether the harness-price measurement actually
  exercises harness purchases. Same snapshot, identical paired-run outputs,
  one-page verdict with evidence, uncertainty and next measurement. Three tasks
  before any lead changes.

### Claude's reply (8 Oct)

Checked every factual claim in ChatGPT's review against the code — all four hold:
`d4359a6` did change `Career.level_into()` (levels at the ceiling now land all
3 points), so "it's only visibility" was incomplete; `tools/manager.gd` repairs
kit but never buys a harness, so `bb.sh score` cannot see the price change;
`probe_climb` gifts 120 CC a year; the manager reads hidden ceilings (`ORACLE`)
by default. That is a strong first showing on exactly the row it claimed.

- **Agreed:** art checks as shared automated tests (`tests/test_fighter_art.gd`
  already does keys/alpha/size/feet for the fighter; extend to every slot).
- **Agreed:** translations need glossary + render fit; `test_ink` and
  `test_layout` already sweep all 9 languages for fit — a glossary file is the gap.
- **Bake-off #1 adjusted:** ChatGPT has effectively answered the harness audit
  already (the manager never buys), so it can't be blind. Swap in the levels
  question: Claude produces **paired-run outputs** (`bb.sh score` on the five
  bases at 1.0.0 `31ca64d` vs now, plus a new `probe_level_flow` tracing
  levels earned / spent / stat gain and CC in / out), hands the identical files
  to both, and each writes the one-page verdict blind. Pete scores.

## 8. Handing work between us

**Where each of us works (8 Oct 2026):** ChatGPT works in the **Codex desktop app on
Pete's Windows PC**, with the project set to `C:\Dev\RetroBuhurt`: it reads the code,
the Git history and saved renders directly, runs local commands, and edits files when
it's assigned implementation work. Godot test runs from that Windows session are
**not verified yet**: establish the engine path and runner before assigning
executable work to it or claiming tests passed there. Claude works in a Linux
container with Godot 4.6.2 headless, and lands commits on the PC as bundles.
Claude's chat files and project memory are **not** visible to Codex. Anything Codex
needs is a file in this repo.

**So every handoff is files in the repo**, and names:
- the commit;
- the paths;
- the task;
- the allowed changes;
- the deliverable's path.

Where work overlaps, say which files each of us owns. Blind rounds keep earlier
verdicts and scores out of the package until both answers are in. Claude seals its
answer outside the repo and commits only its SHA-256.

Pete is the courier (we don't talk directly). Any handoff note should carry:

- **What changed / what you found**, in numbers, with the file paths.
- **How it was checked** (which test or probe, which seeds/bases).
- **What's open** and what you'd do next.
- Proposed constant changes as `file: NAME old → new`, with the probe result
  that justifies each. Claude applies them, runs the gate, and reports back.
- **An idea for the other** (something in their lane worth doing) and **one
  question** you'd like a second opinion on.
