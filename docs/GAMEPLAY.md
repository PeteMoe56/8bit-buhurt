# Gameplay

**Pete's design. Built and playable — `scenes/Melee.tscn`.**

Items marked **REC** are recommendations he has not signed off on. Everything else came
from him directly.

---

## The line

**Rail · Flanker · Center · Flanker · Rail**

Rail and Flanker sit close together on each side; the Center is between the two pairs, and
the gap either side of him is wider than the gap inside a pair. They hold together unless
split.

ACTM already ships this shape and it is the reference, not something to re-derive:
`groups = {5: [2, 1, 2], 12: [5, 2, 5]}` in `actm_arena/lib/src/roster.dart`.

> **Naming.** Hedge Knight's register 03.15 locked Center / Guard / Flanker as the
> positional axis on the premise that "rail anchor" was invented terminology. Pete,
> 10 Sep 2026: *"Rail is real, rail anchor is your bad invention."* Both are true — the
> coinage was ours and should have gone, but **Rail** is a real position and taking it out
> with the coinage was wrong. HK 03.15 needs re-opening; its "Guard" is probably a
> *function*, not a position. See REGISTER 08.1.

## The control model

> Put your finger on a fighter. Draw a path — to a patch of ground, or onto an opponent.
> He is highlighted and he goes and does it. **When the route is done, the AI takes him
> back.** If the path ended on a man, the options come up at a certain distance.
> **The AI will choose unless you choose.**
> — Pete, 10 Sep 2026

You address **individual fighters**, one at a time, as fast as you care to. Draw for one
man or draw for all five. Two things fall out of that, and both are why it beats what it
replaced:

- **You never hold a fighter.** You hand him an instruction and he returns to autonomy, so
  there is no continuous control to cap and no way for this to drift into an RTS. This is
  what replaced the old two-minute hands-on ceiling, and it is better because it is
  structural rather than a budget.
- **There are no difficulty modes.** Drawing every path and drawing none are the same
  game. Your involvement is just how many decisions you take off the AI.

**Splitting a pair is not a command.** It is what has happened once you draw one of them a
path somewhere his partner is not.

| Drag | Result |
|---|---|
| Onto open ground | A route. He walks it, then the AI has him back. |
| Onto an enemy | He goes and takes that man, and the options come up on the way. |
| A tap on a man already in a clinch | His options, without drawing anything. |

**Only a man you sent asks you a question.** The other nine get on with it. That is the
difference between orchestrating and micromanaging, and it is enforced by a test.

**He holds at prompt range while the options are up.** Without that he crossed from prompt
range to contact in a third of a second and the buttons flashed past unreadably — the
whole prompt layer was decoration. Answering commits him instantly; ignoring it commits
him when the timer runs out. Nothing is lost by not answering, which is what makes
"let him decide" a real way to play rather than a forfeit.

## The rules

**Pete, 10 Sep 2026.** Nobody gets back up — a down is out for the round.

A round ends when either:

- **a side is wiped** — 5-0, 4-0, 3-0, 2-0, 1-0; or
- **a side is on its last man and the other still has three** — 3-1, 4-1, 5-1.

So **2-1 keeps going** and **4-2 keeps going**. The most downs a single 5v5 round can
produce is therefore **nine** — a 1-0, where the winner has lost four and the loser all
five. A tenth would mean the stop rule failed, and the suite counts every round to make
sure it cannot happen.

**45 seconds a round, best of three.** A real 5v5 is capped at five minutes; Retro Bowl
does not use a fifteen-minute NFL quarter either. Take two rounds and the third is not
fought. A round that reaches the clock is scored on who is left standing, and can be drawn.

Measured over 395 rounds: endings run **5-1** (most common), 5-2, 4-2, 3-2, 4-1, 4-3, with
the occasional clock draw at 4-4 or 5-5. Worst round produced 6 downs.

## The three menus

| When | Options |
|---|---|
| Arriving on a free opponent | **Bullrush · Clinch · Hit** |
| Already in a clinch | **Takedown · Hold · Escape** |
| Arriving on an opponent already clinched | **Takedown · Hit · Break** |

**Bullrush** is Pete's word (02.17). The dossier calls it a *check*.

**What each one does**, and the shape is a risk triangle rather than three flavours of damage:

- **Bullrush** — gamble for a result now. Missing it leaves you exposed for a beat and
  costs the most gas. It is the most expensive mistake in the game, deliberately.
- **Clinch** — commit to a contest. No immediate result; ties him up. This is how you
  handle a man better than you: you are not trying to beat him, you are removing him.
- **Hit** — invest in later. No down, low risk, takes his base and his wind down so that
  somebody can put him over in thirty seconds.
- **Takedown** — the attempt. Against a man still square over his base it mostly fails.
- **Hold** — deliberately doing nothing, which is a win against a better man and is what
  runs the marshal's clock toward "Break!".
- **Escape** — leave, at a cost, to go where the numbers are better.
- **Break** — **free your own man.** He gets out; the enemy is left standing but
  disengaged. The counter to their gang. *(Pete, 10 Sep 2026.)*

**The third menu is the most important one in the game.** It is the 2-on-1, it is what
actually decides melees, and it is the payoff for splitting a pair.

## The grind

A clinch costs you your base every second you are in it, and the stronger man grinds
faster. This is the mechanism that makes everything else work, and it was missing from the
first build: stability only fell to a **Hit**, Hit is not in the clinch menu, so two evenly
matched clubs fought four and a half minutes and put **nobody** on the ground. With the
grind in, strength and base matter every second rather than only at the moment of an
attempt, and a gassed man wears down almost twice as fast — which is what makes the
post-fight report's gas line causally true rather than flavour.

## Formation and strategy

**Formation is a positioning tool** — it sets the shape of the 2-1-2 before the fight. The
opposition picks its own and you do not learn which until you see their line.

**A strategy is an opening plan, not a permanent modifier.** Pete, 10 Sep 2026: it is
*"more where the team wants the fight to go, but once those strategies run their course,
the AI tries to make best guess."* So each one is five places to be — a shape the team
takes and drives from — and it **expires** after about eighteen seconds, or sooner if the
side is down to two men and the shape is gone. What happens after it expires is the
difficulty curve.

Picked in the corner, locked for the round (02.14).

| Strategy | Where the fight goes |
|---|---|
| **Left rail push** | Whole line slides left and drives up the rail. Concede the right |
| **Right rail push** | The same thing up the other side |
| **Turtle** | Everyone into one tight group in your own half. Nobody gets flanked; nobody scores either |
| **Strong left** | Line holds, but the Center hovers left — three men on that side when it matters |
| **Strong right** | Mirror |

## Difficulty is a behaviour, not a handicap

> *"For beginner levels of difficulty of this enemy AI, they can just do the strategy and
> try to stick with it, not knowing how to figure out the next steps — like a new kid
> going through a motion, but then once his taught direction stops, he doesn't know what
> to do."* — Pete, 10 Sep 2026

Nobody's numbers change between tiers. A Green club hits exactly as hard as an Elite one.
What changes is whether anyone at home is thinking once the plan runs out:

| | `wear_read` | Hunts wear | Improvises | Gang | Rescues / escapes |
|---|---|---|---|---|---|
| **Green** | 0.40 | no | no | 0.0 | no |
| **Seasoned** | 0.55 | yes | yes | 1.0 | yes |
| **Elite** | 0.70 | yes | yes | 1.35 | yes |

**`wear_read` is the tier.** It is the stability at or below which a side recognises
that a man is ready to be taken — above it he holds and hits, below it he goes for the
down. Green keeps standing on his plan zone forever, takes the nearest man in front of
him, never makes the 2-on-1, never frees a teammate, never bails a losing hold.

### What Green was, and why it needed fixing

`wear_read` was a boolean — `reads_wear` — and Green's was false, which meant **he never
attempted a takedown in a clinch at all.** He held forever, never ganged, and never
finished as third man, so he had almost no route to putting anyone on the ground. He
lost **95%** of bouts. That is not a difficulty tier, that is a bye.

As a threshold the distinction is the one Pete actually described. Green can still
**finish** an obvious opportunity — a man who is nearly gone, right in front of him.
What he cannot do is **set one up**: `hunts_wear` is what sends a fighter across the
list looking for a wobbling opponent, and it stays off for him. A third man arriving on
an occupied opponent finishes off `wear_read + 0.15`, because that shot is freer than
one thrown from inside a bind.

A difficulty that cheats with multipliers reads as unfair. One that is simply worse at
deciding reads as an opponent. **Measured: Seasoned beats Green 63.3% of the time on
identical rosters, down from 94.9%.**

## The corner: two swaps

> *"You should be able to swap fighters between rounds from the bench anyway. We'll be
> taking that from ACRTW."* — Pete, 10 Sep 2026

**Eight fighters travel** — five on the line and three on the bench, one backup per
role. Behind them a club carries up to **five in reserve**, who never appear at an
event: they live in the roster menu, where you train them, outfit them, sign and cut
them, and promote them onto the eight when they are ready. A squad is at most thirteen,
and only the eight count toward the club's rating.

Between rounds you may bring **two men in from the bench**, into any slot on the line.

The reason to do it is wind. A man who **fought** the round recovers 30% of his tank in
the corner; a man who **sat it out** recovers 62%. That gap is the whole mechanic — the
bench is a way of buying gas, and a club is more than five men because a best-of-three
is longer than one man's tank.

The reason not to do it freely is position. A man filling a slot he is not listed for
fights at **94% of his base and technique**. Without that cost the bench is just "field
your five best every round" and Rail, Flanker and Center stop meaning anything.

**Role, not slot.** There are five places on the line but only three jobs, so a Rail
covers the other Rail at full value. That is why a three-man bench can cover a five-man
line — and why losing a starter does not leave you unable to field one.

| Formation | Costs you |
|---|---|
| **Line** | Nothing given away, nothing gained |
| **Spearhead** | Your flanks. The sport's own word (glossary #64) |
| **Refused flank** | You choose which side is strong, and which is not |
| **Rail-heavy** | Cedes the middle; nobody gets behind you |

| Strategy | What the line does |
|---|---|
| **Hold the rail** | Anchor, don't chase |
| **Take the strong side** | Collapse onto whichever flank is winning |
| **Gang the Center** | Everyone onto their Center. Agency denial |
| **Split and stretch** | Break the pairs, force five separate fights |

Ganging is a **strategy, not a default**. At the neutral setting a man barely prefers an
opponent who is already tied up; "Gang the Center" turns that on and "Split and stretch"
actively runs from piles. At +70 — the first pass — the entire line converged on one man
every round and a 90-second round was over in ten.

---

## Where it stands

`godot --headless --path . --script res://tests/test_melee.gd` — twelve checks, all passing.
`tests/test_league.gd` — eight. `tests/test_cup.gd` — eleven.

| | |
|---|---|
| Round length | 31 s of a 60 s round |
| Downs per bout | 10.2 |
| Men gassed per bout | 3.8 |
| Worst round | 8 downs, against a ceiling of 9 |
| Illegal round endings | 0 in 393 rounds |
| Bouts settled in two rounds | 47 of 80 |
| Mirror match is a coin flip | 50.5% |
| Hands-off wins | 57.5% of an even mirror |
| Drawing routes | moves the win rate 48.7% → 87.5% |
| A good player on a 12-point-light roster | wins 0% |
| Seasoned vs Green | 63.3% |
| The report names a gas problem | 40 of 40 bouts; never the player's hands |

## Still open

- **Roughly one round in six still ends on the clock** — a 5-2 or a 4-4, which is a round
  that did not resolve. Pete set the clock to 60 s so it would "encapsulate most if not
  all fights", and 84% is most, not all.
- **The corner swap has no UI.** `MeleeSim.swap_in()` works and is tested; nothing on the
  corner screen calls it yet.
- **A drawn round is possible** (clock expiry at equal standing, ~5% of rounds) and a drawn
  bout follows from it. Tiebreak is currently rounds → total downs → draw.
- **Nothing spends gas outside a clinch, a bullrush and an escape.** The tank is not yet the
  constraint the direction doc wants it to be.
- **Prompt buttons overlap the fighters** in a tight pile. Readable, not pretty.
- **The plan expires on a fixed 18-second timer.** "Runs its course" might better mean
  *reached its zones and made contact* than *a clock ran out*.
