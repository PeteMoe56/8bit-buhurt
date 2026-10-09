# Endgame ideas: how to test each one (Claude, 9 Oct 2026)

Inputs: Codex's `IDEAS.md` (8 ideas, endgame diagnostics; in Codex's outputs/endgame folder on
Pete's PC, not in the repo), Claude's Worlds #1 report, Codex's Worlds finale report.
Pete, 9 Oct: keep the agreed order, then brainstorm these ideas and find ways to test them.

## The agreed order (unchanged)

1. **Step 1 candidate**: points 4 + elite nation + cup-XP parity + cross-pool bracket. Running now;
   plan in [STEP1-PLAN.md](STEP1-PLAN.md).
2. **Two-week Worlds** on Codex's phase patch, with a one-pick team camp.
3. **Pete's calls**: tied-knockout rule, whether a dynasty ages out.
4. **Balance tests**: mixed play, aging, late league dominance, difficulty grades, first three seasons.
5. **Endgame features**, below.

## What the measurements already say

- **The field doesn't develop.** A ready club is top seed 86–89% of the time and wins about 65% of
  Worlds (Claude, real careers).
- **The people do turn over, but power doesn't.** About 9–10 retirements per career, and 22–23 of
  25 careers win again with five or more new men (Codex). Yet the club's power is still 96–97 at
  season 30 (Claude). Replacements arrive at full strength, so turnover is real but costs nothing.
- **Names alone add no challenge.** Fifteen persistent rivals inside today's band push the late title
  rate to 0.71. With the superpower being one of those rivals, it's 0.50–0.51. You meet a knockout
  rival from last year again in 62–63% of years, and one nation knocks you out about 2.2 times a
  career (Claude model, `docs/worlds-1/claude/model/rivals.py`).

## Toolbox (every test below uses one or more of these)

| Tool | What it answers | Cost | Exists? |
|---|---|---|---|
| **R: Worlds replay model** (`docs/worlds-1/claude/model`) | Field, format and rival designs on real logged entries | Minutes | Yes, validated to 3% |
| **C: Career runs + logging** (harness probe in a scratch worktree) | Pacing, bank, ladder, title rates in the real game | ~25 min a set | Yes |
| **F: Fixtures** (constructed state, save, reload, compare) | Identity, persistence, no-duplication, ledger unchanged | Small | Codex has the resume harness |
| **M: Mixed-play probe** (the manager fights its own bouts) | Real XP, injuries, wear, who actually stood in a bout | Medium build | **No — the biggest gap** |
| **H: Blind playtest** (two builds, same save, a few players) | Memory, fun, choices people actually make | People's time | Codex's protocol |

M is a prerequisite for anything that rewards *who fought*.

## The ideas, merged, with tests

### A. Returning rivals with a rising superpower (Codex 1 + Claude's elite nation)

**Design:** about six persistent nations (name, crest, record against you), each on its own
generation cycle. The rest of the field stays fresh guests. From the season after your first Worlds
title, whichever rival is strongest that year rises to the elite band (91–98). That nation is drawn
from the field's own cycle, not from your power.

**Hypothesis:** the late title rate is 0.35–0.60, the first title is unchanged, and a nemesis emerges
naturally.

- **R:** sweep rival count (3/6/10), cycle size and elite band. Marks: late rate 0.35–0.60;
  knockout rematch next year at least 40%; a top nemesis beats you at least twice a career in
  about half of careers.
- **C:** build the winner and run tune/check/fresh.
- **F:**
  - names and records survive save/reload;
  - a retired rival champion never returns;
  - no id clash with domestic clubs. Today's guests reuse ids, which is the bug class here.
- **H:** a week later, ask players to name a rival. Pass if most can.

**Cost:** small to medium. Names and records live in the save; the strings are nation names.

### B. A new generation (Codex 2)

**Design:** an optional goal: win a Worlds where at least N of the starting five did not fight the
first title. Shown beside the first championship team.

**Hypothesis:** the goal is reachable but not automatic, and pursuing it costs something real.

- **M** is needed to know who fought.
- **C** with participation logging: the share of careers that complete it by season 20 at N = 3/4/5.
  Mark: 30–80% complete it (Codex's season-end proxy says about 90% at five new men, so N
  probably needs to be higher or count fighters who stood in the final).
- **The goal must make someone choose:** compare a "rebuild early" policy against today's. If the
  goal never changes a decision, it's decoration (Codex's own rule).
- **F:** a signing after the final doesn't count, an injured man swapped out counts correctly, and
  a same-name recruit isn't confused with the original.

**Cost:** medium. Most of it is the participation record that M also needs.

### C. Dynasty aging (Claude's finding; feeds B)

**Design:** replacements arrive slightly under the men they replace, so a champion who doesn't
plan dips.

**Hypothesis:** without planning, a champion's power falls 3–5 points within 6–8 seasons of its
peak; with planning it holds.

- **C,** 30 seasons: measure the power peak-to-trough today (it's flat now), then try two levers:
  scouting a younger potential spread, and a slower peak for signings over a certain age. Marks:
  first title unchanged; late title rate inside 0.35–0.60 *with* the elite nation; a "plans
  succession" policy keeps its power while a "never plans" policy dips.
- **R:** the dips feed the replay model's title rates directly.

**Cost:** small constants, but they touch pacing, so a full run on all three sets.

### D. Championship archive and era exhibitions (Codex 3)

**Design:** freeze the squad, kit, ages and path at each Worlds title. An exhibition match pits the
first champions against today's team.

**Hypothesis:** zero effect on the career, real effect on attachment.

- **F:**
  - the snapshot reloads exactly;
  - an exhibition changes no XP, CC, wear or honors (ledger compared byte for byte before and
    after);
  - leaving mid-match returns to the same save;
  - mirror order gives about 50% between identical archives.
- **H:** can players say which generation was stronger, and do they replay it?

**Cost:** medium (snapshot, a screen, the fight entry point). No balance risk, so no career runs.

### E. Legends return as staff (Codex 4)

**Hypothesis:** a legend is a choice, not an auto-hire.

- **C** paired: a legend-hiring policy against normal hires at the same wage. Mark: the legend's
  teaching return is within ±15% of the best ordinary hire. Familiarity is flavour, not a bonus.
- **F:** no duplicate fighter/staff identity after release, reload or retirement.

**Cost:** small to medium.

### F. A prestige invitational you host (Codex 5)

**Hypothesis:** worth hosting sometimes, never always.

- **C** with three host policies (never, sometimes, always). Marks: "always" isn't the best for
  bank *and* titles; net income per show is positive in at least 50% and negative in at least 10%.
- **F:** reload can't re-roll attendance, and a show can't be double-booked into the Worlds week.

**Cost:** medium. It reuses own-show code.

### G. Seasonal club challenges (Codex 6)

**Hypothesis:** at least one challenge changes what a player does.

- **C** for completion rates under each policy (marks 20–80%).
- **F** negative controls: sign then cancel, change grade mid-season, reload after failing.
- **H:** do players pick one, and does it change a decision?

**Cost:** small per challenge. Cosmetic rewards only, so no pacing run needed.

### H. Heritage visuals (Codex 7)

No balance test needed. **F** for ownership surviving retirement, transfer and reload, plus the
usual text-fit and readability checks in 9 languages.

### I. Champion challenger circuit (Codex 8)

Last. **C** for calendar and income cost. It must not delay the first title (it starts after it).
**H** decides whether it's wanted at all.

## Balance tests (step 4), ready to run

| Test | Tool | Question | Mark |
|---|---|---|---|
| Mixed play | M | Do fought careers pace like simmed ones? | Engaged first Worlds title 10–12 in both; the XP gap explained |
| Aging | C, 30 seasons | Does a dynasty ever dip? | See C above |
| Late league dominance | C | Can "a strong domestic rival after your first National title" bring 95% down? | 75–90% late National bout wins; National first-title pacing unchanged |
| Difficulty grades | C on each grade | Is pacing ordered sensibly? | Easier is faster, harder slower, all still win a Worlds by 20 |
| First three seasons | C, 3 seasons, many seeds | How often does a new player crash? | Relegated or broke in season 1–3 under 10% for engaged |

## What I'd build first after step 2

**A, then C, then B.** A gives the endgame its opposition; C makes turnover matter; B gives the
player a reason to manage it. D (the archive) can be built alongside, because it carries no balance
risk. Before B, build **M**: it's needed for B, for the mixed-play test and for any "who fought"
reward.
