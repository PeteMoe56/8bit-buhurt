# Endgame #1: work split, handoff to Codex (9 Oct 2026, US Central)

> **Update, 9 Oct 2026 (Claude):** main is now `84ceeea`. The European world is removed
> (REGISTER 31.06, Pete's ruling): one region, and the National champion is always Team USA.
> `step1-candidate.patch` still applies cleanly; step 1 is confirmed on all three sets and its
> full gate is green (100/100). Rebase onto `84ceeea` when convenient; nothing else changes.

**For:** Codex, on Pete's PC. **From:** Claude. Pete, 9 Oct: *"split this work with Codex, split it
up nicely and give it a ton to do."*

Read first:
- Claude's merged test plan: `docs/endgame-1/claude/TESTPLAN.md`;
- Claude's Worlds report: `docs/worlds-1/claude/REPORT.md`;
- your own `worlds-finale/REPORT.md` and `endgame/IDEAS.md`.

## The split in one line

**Codex builds the big new systems and the fought-play instrument. Claude finishes the balance
candidate, the opposition and the aging work, and runs the full gate.** No item is on both lists.

| Codex (this handoff) | Claude |
|---|---|
| C1 Mixed-play probe (the manager fights its own bouts) | Step 1 candidate, confirming now (points 4 + elite + your parity-cross) |
| C2 Mixed-play balance test, using C1 | Returning rivals with a rising superpower (TESTPLAN A) |
| C3 Two-week Worlds, built properly, with the one-pick team camp | Dynasty aging, 30-season careers (TESTPLAN C) |
| C4 Tied-knockout rule: sudden-death prototype for Pete's call | Late league dominance: a domestic rival after the first National title |
| C5 "A new generation" goal, needs C1's participation record | First three seasons: early crash rate |
| C6 Championship archive and era exhibitions | Landing: applying what Pete picks, the full gate, the REGISTER, the 9-language strings |
| C7 Difficulty grades: career pacing on every grade | Comparing both reports when they land |
| C8 Legends as staff, hosted prestige invitational, season challenges: design + ROI tests | |

Order inside your list: **C1 first** (C2 and C5 need it), then **C3**, then the rest in any order.
If time runs short, deliver C1–C4 complete rather than everything half-done.

## Base and seeds

- **Base:** main `cae721d` (game code identical to `dbd1ef9`) **plus `docs/endgame-1/step1-candidate.patch`**:
  points per level 4, the elite nation, and your parity-cross. Build on the candidate so our results
  compose.
  - If Claude's step-1 confirmation fails, Claude will write it at the top of this file. Then
    rebase onto what Pete picks.
- **Tune** 9001 5150 2718 6060 8123, **check** 17011 29033 43049 67061 91081, five seeds a base
  (base + i × 7919).
- **Your fresh set:** **810019 850009 890011 930011 970003**. Read once, at the end.
- **Do not use:**
  - Claude's fresh sets 410009 450011 490019 530033 570041 and 610031 650011 690029 730021 770027;
  - Balance #3's 230003…;
  - Harness #2's 110017….

## The work

### C1. Mixed-play probe (the biggest gap in both reports)

A career probe in which the manager **fights** some or all of its bouts through the real
`MeleeSim`, unattended, instead of `quick_bout`. At least these input policies:
- hands-off;
- the existing good-thumb script;
- a fixed fought/quick mixture chosen before results (say every league bout fought, cups simmed,
  and the reverse).

Log per bout:
- who stood in the line, who was substituted, downs and standing;
- XP by source;
- injuries (incidence, severity, weeks out) and kit wear;
- money.

The **participation record** (who actually stood in each Worlds bout) is a deliverable on its own:
C5 and Claude's rival work both read it. Validate it: a quick-only run through the new probe must
reproduce `probe_harness_budget`'s careers exactly on the same seeds.

### C2. Mixed-play balance test

Engaged, passive and sensible-buyer managers on tune and check, each under quick-only, fought-only
and the mixture.

**Questions:**
1. Does a fought career reach its first Worlds title in 10–12 seasons too?
2. Where does the XP gap come from?
3. What do injuries and the infirmary actually cost and save per season?
4. Does the elite nation stay beatable in real fights? A champion's men against a 91–98 side,
   win rate per bout.

**Marks:** engaged first Worlds title 10–12 in every mode, or a clear statement of which mode
misses and by how much. Keep C-1 to C-6 and the mirror at 41–59.

### C3. Two-week Worlds, built properly

Your phase patch, finished:
- **Week one** pools, **week two** the knockout, one tournament, one title, one podium payment.
- **The team camp:** one pick between the weeks, from three services. Your workshop (restore
  Worlds damage), medical tent (a minor Worlds knock) and lineup review are the starting set. No
  CC price, no raw power.
- **State** stored explicitly in the save (your finding: Cup metadata doesn't serialize).
- **Week-two screen** showing the bracket and opponent history.

**Tests:**
- **Abuse matrix:**
  - save/reload at every boundary;
  - forfeit, out in the pools, out in the quarter-final, bronze, champion;
  - no entry at all.
- **Balance (Claude's mark):** under C1's fought play, each camp pick is the best one in 10–90% of
  situations.
- **Pacing:** career pacing paired against the candidate.

Old one-week saves must load and finish their season.

### C4. Tied-knockout rule (for Pete's decision)

Prototype sudden death for an exactly tied knockout bout, with save-stable randomness. Rerun your
40,000 equal-field position audit: seed 1 against seed 16 under today's rule and the prototype.
Deliver both so Pete can choose; land neither.

### C5. "A new generation" goal

Using C1's participation record: win a Worlds where at least N of the line did not stand in the
first title's final. Measure completion by season 20 for N = 3, 4, 5 under each manager. **Mark:**
pick the N where 30–80% complete it.

**It must change a decision.** Compare today's manager with a "plan succession" variant (signs and
develops a young reserve from the first title on). If completion barely moves between them, say so.

**Fixtures:**
- a signing after the final doesn't count;
- a substituted injured man counts correctly;
- a same-name recruit isn't confused with the original.

Cosmetic reward only.

### C6. Championship archive and era exhibitions

Freeze squad, kit, ages, coach and opponent path at each Worlds title. An exhibition plays an
archived team against today's team, or against another archived team, in the real melee.

**Fixtures:**
- the snapshot reloads exactly;
- an exhibition changes no XP, CC, wear, honors or achievements (compare the save before and
  after, byte for byte apart from the exhibition log);
- leaving mid-match returns to the same save;
- mirror order between identical archives gives 41–59%.

### C7. Difficulty grades

Career pacing on every grade preset, engaged and passive, tune set. **Mark:** easier grades are
faster and harder ones slower, and every grade's engaged player wins a Worlds by season 20. If a
grade breaks that, report by how much; don't retune.

### C8. Three smaller endgame features: design + ROI only

Design and test, but don't build UI:
- **Legends as staff:** the teaching return of a retired legend against the best ordinary hire at
  the same wage. Mark ±15%. No duplicate fighter/staff identity after release or reload.
- **Hosted prestige invitational:** never, sometimes and always hosting policies. Marks:
  - "always" is not best for both bank and titles;
  - net income positive in at least 50% of shows and negative in at least 10%;
  - no reload re-roll.
- **Seasonal challenges:** three challenges, completion 20–80% under each manager, and the
  negative controls in TESTPLAN G.

## Rules (same as every round)

- Scratch worktrees only. No changes to `main`, no commits, no pushes. Pete pushes; Claude lands.
- Write `docs/endgame-1/codex/PLAN.md` with the clock time **before** reading any result. Add to it
  with a time stamp; never edit an earlier mark.
- US Central times off the clock. Godot `C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe`.
- Raw `.jsonl` journals stay where they land. Keep summaries small.
- Visible text goes through `UiKit.t()`. List every new string; Claude translates it into 9
  languages.
- Don't claim the full gate passed; Claude runs it.
- Pete's rulings in `docs/REGISTER.md` stand unless you name the one you'd overturn and why.

## Deliverable

`docs/endgame-1/codex/REPORT.md`:
- each of C1–C8 with its result against its mark;
- a standalone patch for each built piece (C1 probe, C3, C4, C5, C6);
- per-base results;
- save and abuse test logs;
- the strings list;
- the questions only Pete can answer.

Claude's matching report will be `docs/endgame-1/claude/REPORT.md`.
