# The pyramid

**Run it like a real football pyramid — Pete, 10 Sep 2026.** Tier names inherited from
ACRTW, which already had this ladder.

Built and tested: `scripts/league/`, `tests/test_league.gd` — eight checks over a hundred
simulated seasons. No UI yet.

---

## The ladder

| | Division | Clubs | Events | Up | Down | Club power |
|---|---|---|---|---|---|---|
| 4 | **National Division** | 16 | 15 | top 2 → **Worlds** | bottom 2 | 64-86 |
| 3 | **Regional League** | 12 | 11 | top 2 | bottom 2 | 52-70 |
| 2 | **State League** | 8 | 7 | top 2 | bottom 1 | 40-58 |
| 1 | **Backyard Circuit** | 6 | 5 | champion | — | 30-46 |

You start in the Backyard Circuit, because the pyramid only means anything if the climb is
the game.

**Whatever a tier promotes, the tier above must relegate**, or the divisions leak clubs a
year at a time — a bug invisible on a Sunday and ruinous by season nine. Asserted every
season of a hundred-season run.

## Why a pyramid instead of ACRTW's playoffs

ACRTW resolves each tier with a top-2 final or a top-4 playoff. Promotion and relegation
suit this game better for one reason: **a bad season has consequences without ending the
run.** You do not get knocked out, you go down — and going down is a story that continues.
That is what a club manager wants and what a bracket cannot give you.

## The table

**Three points for a win, one for a draw.** A bout is best of three rounds and can be
drawn, so football's scoring works unmodified.

**Rounds are this game's goals.** The order is points → **margin** → round difference →
rounds won → **drawn lots**.

**Margin is the standing differential of every round, summed** — Pete, 10 Sep 2026:
*"Points are based on how many up vs how many down. So a 5-1 would be 4 points. A 1-0
would be one point."* It sits where goal difference sits in football, and it is a
better number than rounds won, because two clubs on the same points and the same
rounds are not equally good if one of them keeps winning 5-1 and the other keeps
scraping 1-0.

ACRTW reached the same idea from the other side: its Worlds pool tiebreak is
`fighter_diff`, and its live Worlds scores *"men left standing in rounds won"*. Pete's
version is the better one — **ACRTW's cannot tell a 5-1 from a 5-4**, and knowing how
convincingly you won is the whole job of a tiebreak. The same margin now settles a
league table, a Worlds pool and a level knockout, so one measure runs the entire game.

Lots are a number handed to each club at the start of a season, used only when everything
else is level, and redrawn every year. They exist because the first version broke final
ties on club id — and the player is club 0, so he won every tie in every division and
floated to the top flight on a static rating. Real leagues draw lots for exactly this
reason: **a fixed ordering is never neutral, it just hides who it favours.**

## The fixture list

A **single** round-robin — everyone plays everyone once, so a season is N−1 events.

That is an authenticity call as much as a scope one. Buhurt clubs travel to events; there
is no home ground, and a home-and-away list would borrow a structure the sport does not
have. It also lands every tier inside the direction doc's 10-14 events: **5, 7, 11, 15**,
which gives a fast bottom of the ladder and a grinding top.

## What gets simulated

**Only your own bout runs the full melee.** Every other fixture in every division resolves
on club rating. That is not a shortcut — it is the division of labour every football
manager makes, and the one ACTM already makes in `meleeOddsBps`: the fight you are standing
in gets the whole sim, and the other fourteen results are numbers on a page by Sunday night.

## Measured

| | |
|---|---|
| Divisions held their size | 100 seasons, no leak |
| Fixture list | every club meets every other exactly once |
| Same seed replays identically | yes; a different seed does not |
| A club improving 6 power a season | reached the National Division in **7 seasons** |
| A club that never improves | averages tier **0.3** after 30 seasons, never past the State League |

That last pair is the progression curve in two numbers: **the climb is possible, and the
climb is earned.**

---

# The cups

Taken from ACRTW on Pete's instruction, 10 Sep 2026. `scripts/league/cup.gd`,
`tests/test_cup.gd` — eight checks.

## Two Invitationals a season

Eight clubs, straight knockout — quarter-finals, semi-finals, final. They fall on
matchday 2 and on the second-to-last matchday, so they land sensibly in a five-event
Backyard season and a fifteen-event National one alike.

**You are invited if you are in the top three of your own division at that matchday.**

That gate is the one thing deliberately *not* copied. ACRTW invites on National top-3.
This game starts you in the Backyard Circuit, so the same rule would mean **you never
see a cup for seven seasons**. Top three of your own division makes a cup run something
a small club in a small league can still have, which is the entire appeal of a cup.

The two are the **Kings Cup** (matchday 2) and the **Path of Honor** (second-to-last
matchday). ACRTW's own — "Apex, Not Apex" and "Path of Acclaim" — are its property and
were not taken.

## Worlds

**Sixteen clubs. Four pools of four, top two out of each, then an eight-club bracket
with a third-place match.** ACRTW runs 32 countries and eight pools of four; this is a
quarter of the size and exactly the same shape, and it fits a season you can finish on
a phone.

The National Division's top two carry the country. The other fourteen are foreign
guests, rated a little above the top flight's own band — a Worlds berth is not a
victory lap — and **deleted again the same summer**. A guest that survives the
tournament is a club sitting in the club list with tier −1, waiting for the first loop
that walks the pyramid. Same class of bug as a division that leaks a team a year, and
it has its own check.

Seeding matters: the bracket pairs top seed against bottom seed, and a knockout that
ends level on rounds is settled on margin and then on seed. **A bracket that pairs 1
against 2 in the first round is not a bracket, it is a raffle with extra steps.**

---

## What the league reads off your roster

**Club power is your club, not a number set by hand** — Pete, 10 Sep 2026. Before
this, your table position had nothing to do with the men on your books: you could sell
your best Rail and climb anyway.

It is worked out the way Madden and FIFA work it out — **each position gets a rating,
and the club rating is the average of those.** A position is:

| | |
|---|---|
| its starter | **80%** |
| his cover | **20%** |

Cover is a bench man of the same **role** at full value — a Rail is a Rail whichever
side of the list he stands on. Failing that it is your best bench man at the
out-of-position cost, the same 6% the sim charges him if you really do put him there.
With nobody on the bench at all it is the starter at 70%, because "he plays all three
rounds and nobody spells him" is the honest reading.

Position averages beat a flat squad average for the reason every sports game already
knows: **they make a hole somewhere specific cost you.** Five men averaging 70 with
nobody behind the Center is not the same club as five men averaging 70 with a Center
who can be spelled, and a flat average cannot tell them apart.

Kit rides inside each fighter's own rating rather than sitting outside as a club-wide
fudge. Harness condition already costs him base, and base wins rounds, so a man in
rattling kit is simply a worse fighter — and it reaches the league table by the same
road as everything else.

**Eight travel** — five on the line and three on the bench, one backup per role — and
a club may carry **five more in reserve**, who never appear at an event. A squad is at
most thirteen.

Reserves are not part of the rating. They are not at the event, so they cannot be what
the league rates you on; they exist in the roster menu, where you train them, outfit
them, sign and cut them, and promote them onto the eight when they are ready.

---

# The season loop

**Built 10 Sep 2026.** `scripts/league/season.gd`, `scripts/league/club_factory.gd`,
`scripts/game/season_scene.gd`, `tests/test_season.gd` — five checks.

Before it there were two halves that both worked and did not touch: a melee with twelve
checks on it, a pyramid with eight, and **not one line of code anywhere that referenced
both.** You could fight an exhibition bout forever and you could simulate a hundred
seasons, and you could not play one.

`Season` owns the world and your club, hands the melee the right two clubs for whatever
fixture is next, and takes four numbers back out — rounds won and standing margin, which
is exactly what the table eats. A fought fixture and a simmed one reach the table through
one shape, and there is a check that the sim's own numbers are the numbers in *both*
clubs' rows.

## Where the other clubs come from

The league carries a rating for every club in the country. That is enough to resolve a
fixture on paper and nothing like enough to *fight* one, so `ClubFactory` turns a rating
into eight fighters, five reserves and legal heraldry — Rails the biggest, Flankers the
hardest hitters, Centers light and quick (Pete, 10 Oct 2026), the same silhouette the
hand-written fixture clubs have.

It is seeded off the club's **id alone**, so it needs no save data and the club you play
in October fields the same eight it fielded in March. And it does not try to invert
`MeleeClub.power()` to hit its target — it walks the club to the number and stops, calling
`power()` each step, so it cannot drift out of agreement with the rating formula when that
formula changes. Measured: every tier from 30 to 86 builds a legal squad rating **exactly**
what the league says it rates.

## What was "not built yet" — settled 15 Sep 2026

This section used to list five things as unbuilt. All five had been built, some of them
weeks earlier, and the list stayed on the page — which is worse than no list, because a
reader who trusts it goes and builds something twice or plans around a gap that closed.

- **Saving.** Built. `scripts/game/save_game.gd`, 484 lines, version 12, with a migration
  floor at v11 and `test_save.gd` covering the round trip, a five-season fought career, a
  refused corrupt file and the migration itself.
- **The roster menu.** Built. `scenes/Roster.tscn` and `scenes/Fighter.tscn`, and the
  corner bench swap is wired in `melee_scene.gd`.
- **Playing your own cup matches.** Built. `Cup.player_match()` has a caller; a cup tie of
  yours is offered on the season screen through `blocked_by()` and can be fought or
  simulated, and `test_cupplay.gd` checks both doors dress the same sim.
- **Money, dues and the federation.** Built. `club_office.gd` carries the cap, the wage
  bill, facilities, travel slots, throttles and the boost; `scenes/Federation.tscn` is the
  dues-and-members screen; `arena.gd` is the ground you build.
- **Prize money and reputation.** Built. Season end pays by finish and by cup run, and
  notoriety feeds the gate, the market's pull and whether a man out of contract waits.

**What is actually unbuilt** is not a league matter and lives in one place: the Ship List.
Art, export targets and the IAP unlock. This file is about how the pyramid works, and it
should be corrected rather than extended when that changes.



