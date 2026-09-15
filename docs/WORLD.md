# What carries over from Hedge Knight

Pete's call, 10 Sep 2026: **merge, but take most story elements out.** Hedge Knight is a
drama rogue-lite. This is a light Retro Bowl–style game that can use its world elements.

That sentence is the whole filter. Everything below is sorted by it.

---

## Carried whole

**The setting rule.** Real countries; fictional federations, clubs, fighters and armourers.
Locked in Hedge Knight, unchanged here.

**Russia is excluded from the game entirely.** Not a country, not on the calendar, not
among clubs, opponents or armourers. This tracks the sport's real present rather than
departing from it. The war and sanctions are never referenced.

**Tone: grounded and warm.** Kept — but see below for what comes off it.

**The source dossier.** `C:\Dev\HedgeKnight\research\buhurt-source-dossier.md` is the
reference for federations, rules, formats, roles, gear, costs, injuries and a ~120-term
glossary. It is the naming authority for this project too. The session protocol's
hardest-won rule applies verbatim: **search the glossary before naming anything.** The
sport has already named it, its name is more authentic, and it is free.

Everything the bout layer names is already in there — list, rail, clinch, third point of
contact, Break!, Stop fight!, threefold advantage, cascade, gas tank, carry, rotation,
agency denial, center, guard, flanker, grappler, striker, punisher, runner. Nothing coined.

**Federation scoring divergence** (the same fighter is worth more or less depending on
whose event he entered) — not built, but it is a real differentiator and it survives the
cut because it is a structure, not a story.

---

## Deliberately left behind

**The storylet layer and the narrative engine.** Hedge Knight's parameterised storylet
templates are a drama system. This game's narrative surface is the post-fight report and
the corner, and both are diagnostic rather than dramatic.

**The player-selectable persona register.** A tone dial belongs to a game with a voice
talking to you. This one has a marshal shouting "Break!" and a report telling you your
#3 gassed.

**The card layer and the roguelite run structure.** Replaced by the verb and the season
cycle. The 180-card budget and the archetype work become roster and role content instead.

**The schism as career-destroying politics.** Hedge Knight softened this to "a month or
two of calendar" — an annoyance you navigate. Here the equivalent is the **club split**
(direction doc §4): a bad season, a bad captain call, favouritism over who goes to Worlds,
and half your roster walks out and founds a rival club across town. That is a management
consequence, not a drama beat, and it is the better version for this game.

---

## Still open

- The three starting archetypes, ages 19/25/32, gender as player choice — inherited but
  unexamined against a manager frame. See REGISTER 03.5.
- Abstract calendar (deliberately unlike ACTM) — inherited, unbuilt. Fictional federations
  leave nothing to anchor to, which keeps the game evergreen and seeded runs stable.
- The opt-in real-fighter programme. Interesting, and a much better fit for a club manager
  than for a roguelite. Not scoped.

---

## From ACTM — the design work, not the code

Flutter does not come along, but the expensive part does: match resolution maths from the
arena package (tuned against 32 simulation runs), the Corner's call seam, the
fatigue/readiness model, the fighter stat model, the heraldry system, 640 generated club
names, and the whole release/l10n/store discipline.

The Corner is worth calling out specifically: **constraint 6 is already prototyped there**.
ACTM's Corner is exactly the orders layer with no hands attached to it, and it is the
strongest evidence available that orders can carry a bout on their own.
