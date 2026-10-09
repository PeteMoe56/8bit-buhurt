# Endgame #1: Claude's plan (09 Oct 2026, 12:42 US Central, before results)

My half of [../HANDOFF-CODEX.md](../HANDOFF-CODEX.md): step 1 confirmation (STEP1-PLAN.md),
returning rivals with a rising superpower, dynasty aging, late league dominance, first three
seasons. Marks are those in TESTPLAN.md, restated here and fixed now.

**A. Returning rivals.** Model sweep: K persistent nations in 3/6/10/15, generation-cycle size
3/5/7 power, superpower (91-98) = strongest rival that year, from the season after the first
Worlds title. Marks: first Worlds title unchanged within 0.3 of the elite-nation run; late title
rate 0.35-0.60; a knockout rival met again the next year in at least 40% of years; a nemesis that
knocks you out at least twice in at least 50% of careers. Choose the smallest K that passes, then
build it and run tune/check on the step-1 base.

**C. Dynasty aging.** 30-season careers on the step-1 base: measure each club's power from its
peak onward. Then try at most two levers on how replacements arrive. Marks: first Worlds title
unchanged (±0.3); peak-to-trough dip 3-5 power within 8 seasons of the peak for today's manager;
late Worlds title rate stays inside 0.35-0.60.

**Late league dominance.** Baseline late (15-20) National bout win rate on the step-1 base. One
lever: a domestic rival that rises after the player's first National title. Marks: late National
bout wins 75-90%; first National and first Worlds titles unchanged (±0.3); relegations not up
more than 0.2.

**First three seasons.** 3-season careers, 100 seeds per arm, step-1 base. Report relegation,
negative cash and stuck-in-tier rates. Mark: under 10% relegated or broke in seasons 1-3 for the
engaged manager. Measurement only, no lever unless it fails.

## Additions, 12:49 CT
- **A, chosen before any real-game result:** K = 6, cycle ±5 (model: every K >= 6 passes all four
  marks on both sets; K = 3 sits on the 40% rematch line). Built on the step-1 candidate in w6;
  save fixture 30/30 pass (three seeds: draw, round-trip, continuation, old save without rivals).
  Real-game runs queued on tune and check. Model prediction: first title within 0.3 of the
  elite-only run, late rate about 0.47.
- **Late league dominance, model only:** in a 16-club National table the player (96) sits 25
  points above the median club (71). One rival lifted to 86-92 moves late bout wins 0.960 →
  0.944; three rivals at 84-92 reach 0.915. **The 75-90% mark cannot be reached by rivals alone**;
  lifting the whole league failed Codex's passive/buyer marks (Balance #3 late-compression). No
  real-game lever will be run; this goes to Pete as a design question.
- The first step-1 runs died with the session interruption at 11:34; relaunched unchanged.
- Dynasty aging: roster logging added in scratch w8 (ages, ability, potential of the five and the
  roster at each roll-over), 3 careers/base x 30 seasons, queued after step 1 and rivals.

## A, real-game result and one follow-up (13:19 CT, AFTER results)
K = 6 on the step-1 base: first Worlds title 10.72 / 10.67 (step 1: 11.07 / 10.65; tune is 0.35
faster, mark ±0.3); late rate 0.41 / 0.44 ✔; nemesis 77% / 76% ✔; **same knockout rival next
year 35% / 35% ✗ (mark 40%)**; a rival in the knockout path in 76-77% of Worlds. The model
over-predicted repeats by ~5 points. **Follow-up chosen after seeing this:** K = 10 (model 49-50%),
tune and check, then the fresh set 610031… is already spent on step 1, so a new fresh set for
rivals: **1010009 1050011 1090013 1130027 1170001**. Same marks.

## Note, 13:52 CT
The first ten-rival tune/check runs and the first 30-season aging run were discarded by the probe
("Source changed during run"): Claude edited those scratch copies (nation names, Team USA) while
they ran. Rerun unchanged from the now-final copies. The ten-rival fresh run (1010009…) started
after the edits finished, passed validation, and stays unread until tune/check are in.
