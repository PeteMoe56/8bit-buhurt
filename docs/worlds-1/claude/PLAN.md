# Worlds #1: Claude's plan (written 09 Oct 2026, 09:19 US Central, before any result)

Pete, 9 Oct 2026: *"World's is the finale tournament, would it be recommended to make it two
weeks long with pools and bracket play with its own shops for more end game excitement? What
options would you recommend? Use imagination and test."* Also: *"What other tests would you
recommend doing to better this game in a balance way?"* Codex has the same assignment.

## Today (read from the code, c9c79c8 / dbd1ef9)
- One week. 16 clubs: the National playoff champion + 15 guests drawn uniformly from the
  National band +4/+8 (68-88), seeded by power. 4 pools of 4 (snake), 3 pool days, top two
  into a quarter-final bracket (A1-D2, B1-C2, C1-B2, D1-A2), semis, final, bronze.
- Bouts resolve by `quick_bout` in careers (Elo on power, RATING_SCALE 22, best of three
  rounds, 6% drawn rounds). Purse 10 CC a tie won at National, podium 40/20/10.
- Guests do not develop. A smoke career on points-4 reached power 94-97 by season 12 and was
  top seed by 6-10 points every year after.

## Instrument
Scratch worktrees w1 (POINTS_PER_LEVEL 4, Codex's recommendation) and w0 (today, 3), plus two
print lines in `_build_worlds` / `_record_honors` (scratch only, no game change): every
season's Worlds field powers, the player's power and tier, the National playoff order, and the
Worlds result. `probe_harness_budget`, 5 careers/base, 3 arms (all engaged), 20 seasons, tune
(9001 5150 2718 6060 8123) and check (17011 29033 43049 67061 91081) sets.

Then a Python model: an exact port of `quick_bout`, `_draw_margin`, pool tables and
tiebreaks, the snake draw and the bracket. **Validation before use:** replaying every logged
field through the ported current format must reproduce the logged title count within binomial
noise (|z| < 2). If it does not, the model is not used.

Career test: Worlds results feed back into the career only through the purse, so each
career's sequence of entries (season, player power) is replayed under each design, 2000 draws
each, giving P(title) per entry and the first-title time (20 if none, non-winners included).
Stated caveat: this ignores the purse's feedback and fought (melee) bouts.

## Designs to test
Formats (W): W0 today; W1 two weeks, 32 clubs, 8 pools of 4, round of 16; W2 two weeks, 16
clubs, a second group stage (8 qualifiers into 2 pools of 4, top two to semis); W3 two weeks,
pools then a double-elimination bracket of 8; W4 two weeks, pools then a best-of-three final;
W5 pool winners choose their quarter-final opponent.
Opposition (G): G0 today's static guests; G1 world level rising with the season; G2 fifteen
persistent rival nations that develop and age (the same names every year, a nemesis);
G3 two or three elite nations at the top of the field; G4 field anchored to the player
(reference only; it punishes progress).
Mechanics (M), modelled as power changes with costs, stated as assumptions: fatigue across a
two-week event; a Worlds village shop between the weeks (physio, scouting film, a loan star
from an eliminated nation, armorer); a rest-or-train choice between the weeks.

## Pass marks (fixed now)
1. **Pacing kept:** engaged first Worlds title 10-12 seasons, at least 20/25 careers by
   season 20, on each seed set.
2. **Contested once ready:** title rate per entry in seasons 15-20 between 35% and 60%
   (a champion should be the favourite, not a certainty).
3. **Bouts that matter:** at most 15% of the player's pool bouts are dead rubbers
   (qualification already settled either way before the bout).
4. **Money:** the Worlds' purse at most 25% of a National season's income.
5. **Shop items are decisions:** under an expected-value policy across the logged banks, no
   item is bought on more than 90% of eligible visits and every item on at least 10%.
A design must pass 1-4 on both sets to be recommended; 5 applies to shop designs.
Fresh set reserved for any confirmation in the real game: 410009 450011 490019 530033 570041.

## Addition, 10:02 CT, before the real-game run
Model results so far favour **E1: one elite nation (power 91-98) in the Worlds field from the
season after the player's first Worlds title.** It is stateless (read from the honors cabinet),
so it can be built in a few lines. Built in scratch worktree w2 (points 4 + E1 + logging) and
run 5 careers/base on tune, check and the fresh set 410009 450011 490019 530033 570041.
**Model predictions, fixed now:** first Worlds title 11.24 (tune) / 11.10 (check); late (15-20)
title rate per entry 0.46 / 0.46. Pass if the real game lands inside the pass marks (10-12;
0.35-0.60) on all three sets; the fresh set is read once.
The dead-rubber definition was corrected before this addition: a bout is dead only if the
player's pool place (1st, 2nd or out) cannot change, since 1st vs 2nd picks the quarter-final.
