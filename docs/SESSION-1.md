# Session 1 — 10 Sep 2026

**Brief:** *"Let's start working on this. Throw a file on C:\Dev and we'll build the ground
works using Retro Bowl as structural guidance, fully 8-bit."*

**Decisions taken by Pete this session**

- **01.1 — merge with Hedge Knight, story stripped.** *"Merge but take most story elements
  out. Hedge Knight is a drama rogue-lite, this is a light Retro Bowl style game that can
  use world elements."* Recorded in the register, and `docs/WORLD.md` sorts the inheritance
  by that filter.
- **First week produces the playable bout prototype**, not the design register first.
- **Repo name `RetroBuhurt`**, store title still open (01.2).

**Built**

Milestone 1 from direction doc §13: one 5v5, three rounds, the brace-drag-commit verb, AI
teammates, a sim running around you, placeholder 8-bit art. Plus the corner, the orders
layer, auto-sim, and the post-fight report, because those are three of the six constraints
and building the verb without them measures nothing.

The sport's vocabulary throughout, per the Hedge Knight protocol — every name checked
against the dossier glossary before use. Nothing coined.

---

## What the session found

Recorded in full in `docs/CONSTRAINTS.md`. The four that matter:

**1. A team-order asymmetry that would have read as "the AI cheats."** Clinches were opened
inside the per-fighter step, so team 0 got first refusal on every bind every tick. The
fighters it shut out went and leaned on teammates' binds instead, and the assist bonus
handed team 1 an 18% edge in a mirror match. Found by a symmetry test that was written
after the failure, not before it — which is the argument for keeping it.

**2. A random walk scaled by `dt` instead of `sqrt(dt)`.** Noise vanished as ~dt^1.5, so two
identical fighters could bind for eight seconds and neither would ever break the other's
base. Every bout between evenly matched clubs finished 0-0. This is a modelling error, not
a typo: a random walk's spread grows with the square root of time.

**3. The verb was a trap.** The AI drove at full power *and* committed on a timer, never
paying the offence a brace costs to wind up. The player paid it. Perfect input therefore
measurably *lost* to auto-sim — the exact opposite of what the action layer is for. Both
sides now use the same rhythm, and the only thing a good thumb buys is the read.

**4. Readability could not be reasoned about.** The first render put ten indistinguishable
specks on the list with the heraldry doing no work at all. `tools/shot.gd` exists so the
question is answered with an image. It caught the sprite scale, a four-man pile that fused
into one shape, and the whole melee migrating to one rail over three rounds.

---

## Audit note for session 2

Per the standing instruction, session 2 audits this one first. Three specific things to
look at:

1. **04.3 — orders are still not balanced.** The counter-cycle broke the first dominant
   strategy ("Rotate strong side" at 46% against 0-17%) and produced a second one ("Hold
   the rail" at 73%). "Take the tempo down" wins 4%, because the gas economy is not tight
   enough for a conditioning play to pay for the round it costs. This is the next balance
   session's whole job, and it is a design question, not a tuning one.

2. **02.4 — round length is ASSUMED.** 90 seconds, three rounds, 5v5. The dossier says team
   rounds run up to 8 minutes; BI 5v5 cards run 60-90 seconds. Pete fights and sits on a
   federation board — ask him rather than sourcing it. The gas curve, the clinch budget and
   the down rate all hang off this number, so if it moves, everything in `balance.gd` moves.

3. **04.4 — perfect input wins 92% of an even mirror match.** The roster gate holds, so
   C-2 is satisfied in the way that matters. Flagged anyway because it is high and nobody
   has yet played it with an actual thumb.

The thing this session cannot answer is milestone 1's second question: **is it still fun on
the fifth run?** That needs a person and a phone.
