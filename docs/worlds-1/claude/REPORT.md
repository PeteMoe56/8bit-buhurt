# Worlds #1: Claude's report (9 Oct 2026, 10:45 US Central)

Plan and its one addition, both timestamped before results: [PLAN.md](PLAN.md).
Game: main `dbd1ef9` plus Codex's `POINTS_PER_LEVEL 3 → 4`, unless marked "today (3)".
Careers: `probe_harness_budget`, three engaged arms, 25 careers per arm per seed set, 20 seasons.

## The finding: the Worlds is short of opposition, not format

The 15 foreign guests are drawn from power 68–88 every year and never improve. An engaged club
reaches 94–97 by about season 12. After that it is the top seed in 86–89% of its Worlds and
wins most of them, every year, on today's game and on points 4 alike:

| Game | Seed set | First Worlds title | Late title rate (seasons 15–20) | Top seed |
|---|---|---|---|---|
| Today (3 points) | tune / check | 12.85 / 12.29 | 0.64 / 0.61 | 87% / 86% |
| Points 4 | tune / check | 11.16 / 10.60 | 0.65 / 0.66 | 89% / 88% |
| Points 4, 30 seasons | tune | — | 0.64 → 0.69 (seasons 21–30) | — |

Club power never declines: the median is still 96–97 at season 30. Aging never catches a dynasty.

## Recommendation 1: one elite nation after your first Worlds title (tested in the real game)

[elite-nation.patch](elite-nation.patch) touches one file: `league_world.gd`. It adds the
constant `ELITE_POWER [91, 98]`, and `_build_worlds` gives one guest that power from the season
after the player's first Worlds title. It reads the honors cabinet, so it adds no new save state
and no new strings. It reproduces the scratch trial season for season.

| Seed set | First Worlds title | Late title rate | Titles per career | Relegations | Bank, season 12+ |
|---|---|---|---|---|---|
| Tune: points 4 → + elite | 11.16 → 11.16 | 0.65 → **0.46** | 6.0 → 4.7 | 0.48 → 0.48 | 205 → 203 |
| Check: points 4 → + elite | 10.60 → 10.60 | 0.66 → **0.45** | 6.7 → 4.8 | 0.57 → 0.57 | 212 → 206 |
| Fresh (410009 …), + elite | 11.15 | **0.43** | 4.3 | 0.51 | 201 |

- **Predictions held:** the model predicted 0.46 / 0.46 before the run.
- **Every pass mark met, all three sets:**
  - first title 10–12 seasons;
  - all 75/75 careers win a Worlds;
  - late title rate 0.35–0.60.
- **First title unchanged:** the elite nation only comes after it.
- **Story hook:** the elite side is a guest drawn fresh each year. Making it a named, recurring
  nemesis needs a saved name and new strings, so that's a design choice for you, not part of
  this patch.
- **Alternatives:** a "hunted" rule (the top two nations +3 per title you win, −2 per year you
  don't) and a world that strengthens after season 12 scored about the same in the model
  (0.47 and 0.44–0.45). Both need saved state or a pacing caveat.

## Recommendation 2: two weeks, as a second group stage, with a pick-one village (model only)

Tested in a Python port of `quick_bout`, the pool tables and the bracket. On 100,000 bouts it
matches the engine's win rates within 0.3 points at every gap. Replaying the logged real Worlds
fields it got 455 vs 450 real titles on tune (z −0.4) and 465 vs 501 on check (z +2.7, which
misses my |z| < 2 mark). Pooled it is within 3% (921 vs 951). It's used here for comparisons
between designs on identical entries, not for absolute rates.

| Format (with the elite nation) | First Worlds title, tune / check | Late title rate | Player bouts |
|---|---|---|---|
| W0 today: pools, quarter-final bracket | 11.24 / 11.10 | 0.46 / 0.46 | 5.5 |
| **W2 two weeks: pools, second group stage of 4, semis, final** | **11.14 / 10.97** | **0.47 / 0.46** | **7.6** |
| W1 two weeks: 32 clubs, 8 pools, round of 16 | 11.91 / 11.69 | 0.43 / 0.42 | 6.2 |
| W5 pool winners pick their quarter-final opponent | 11.26 / 11.05 | 0.45 / 0.45 | 5.6 |
| W3 double elimination (G0 field) | 11.02 / 10.80 | 0.78 / 0.78 | 7.4 |
| W4 best-of-three final (G0 field) | 11.15 / 10.94 | 0.70 / 0.71 | 6.5 |

- **W2 is the two-week Worlds to build.** Two more bouts that matter, same pacing, same contest.
- **No second chances.** Double elimination and a best-of-three final help the favourite (0.70–0.78).
- **The 32-club field** slows the first title by about 0.6 seasons, purely from extra coin-flips.
- **No dead rubbers** in any format: with three pool days the player's place is never fixed
  before his last pool bout. (By qualification alone, 15% were settled; first versus second
  still picks the quarter-final.)
- **Money:** the Worlds pays 14% of a median National season (514 CC) today; W2 pays 17–18%.
  Both are under my 25% mark.

**The Worlds village** opens between the weeks. The late-career bank is about 205 CC (bottom
tenth 131), so any item priced in tens of CC would be bought every year: no decision. It works
as **pick one**:

| Pick | Effect (assumed) | Best pick: G0 field | Best pick: with elite | Mean title gain |
|---|---|---|---|---|
| Physio | clears week-1 fatigue (0.6 power a round fought, 3 back over the rest days) | 30% | 24–32% | +5–7 pts |
| Loan star from a knocked-out nation | +2 power all week 2 | 53–57% | 39–43% | +8 pts |
| Film on the strongest nation left | +4 against that nation only | 13–17% | 29–34% | +3–7 pts |

Every pick is best somewhere and none dominates, which passes my decision mark. It is sensitive:
at fatigue 0.8 the physio wins 56–73% of the time. The fatigue numbers are my assumption, and the model draws each club's rounds fought at 2–3 a
bout rather than reading them from the pool. Build it with the three values as constants and
tune them in the real game.

## Other tests I'd run, in order

1. **Mixed-play careers**, the gap both reports name. Fought bouts pay real XP and cause real
   injuries; every career number so far is quick-bout only.
2. **A dynasty that ages.** Power never falls in 30 seasons. Test retirements and ageing against a
   target: say, a champion's power dips 3–5 points every 6–8 seasons unless rebuilt.
3. **The domestic endgame.** A developed club wins about 95% of its National bouts. The same
   "the world takes notice" idea (one strong rival after your first National title) is cheap to
   try in the league.
4. **Difficulty grades.** Every career run uses the default grade. Pacing on the others is
   unmeasured.
5. **The first three seasons.** How often a new player is relegated or goes broke early.
6. **Fought Worlds.** Play the melee for the player's Worlds bouts, to check that the elite
   nation (91–98) is beatable by hand at the power a champion reaches.

## Questions only Pete can answer

1. Land the elite nation (recommendation 1)? It is small and tested; it can go with Codex's change.
2. Build the two-week Worlds as W2 with a pick-one village? It needs a calendar week, screens and
   strings in 9 languages, so it's a bigger job than the patch.
3. A named nemesis nation that returns every year, or a fresh superpower each time?
4. Should a dynasty age out (test 2), or is staying on top for 30 seasons fine for a phone game?
