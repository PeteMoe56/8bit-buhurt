class_name Quartermaster
## THE HARNESS A MAN OWNS, as opposed to the state it is in.
##
## Pete, 15 Sep 2026: *"Rebuild Market, there's a tab within a tab. Market should
## be some type of enhancements like armor polish or something."* And, asked to
## choose a direction: the quartermaster.
##
## ---------------------------------------------------------------------------
## MOST OF THIS ALREADY EXISTED AND HAD NO SCREEN.
##
## `FighterCard.armor` decays every event off the captain's regime, multiplies a
## man's base through `effective_base()`, and gates `passes_inspection()` at
## 0.35 — below that line the marshals will not pass him and he cannot go out at
## all. `ClubOffice.repair_kit()` puts a step back into one harness. Direction §4
## has said since day one: *"The cap isn't money-per-player, it's how many bodies
## you can put on a plane and how many harnesses you own that pass inspection.
## Bench depth is limited by armor, not payroll."*
##
## All of it was reachable one man at a time, from a row on the fighter card,
## behind two taps from a tab. **There was no screen in the game that showed the
## squad's kit together**, so the mechanic Direction calls the cap was invisible.
##
## ---------------------------------------------------------------------------
## WHAT WAS MEASURED BEFORE ANY OF THIS WAS WRITTEN — `tools/probe_kit.gd`.
##
## 1. **An AI club has no kit at all.** It is a `power` integer drawn from its
##    tier's band in `league_world.gd`, not a squad of men. It cannot wear a
##    harness out and cannot repair one. The player is the only club on the
##    ladder paying this tax.
##
## 2. **A simmed event costs no wear.** `_apply_regime()` runs from `post_bout`,
##    not from `skip_event`, so twenty-four simmed events left a squad at exactly
##    the kit it started with. Fighting wears your harness and simming does not,
##    which is a discount for not playing the game.
##
## 3. **And the tax is a rounding error anyway.** `effective_base()` is
##    `base * lerpf(0.78, 1.0, armor)` and base carries 0.24 of a man's rating,
##    so at base 45 the WHOLE legal armor range — 0.35, one notch off failing
##    inspection, to a perfect 1.00 — is worth **1.54 rating points**. The
##    0.90 → 1.00 a repair buys is worth 0.24. Repairing all thirteen men before
##    every event for twenty-four events moved club power by zero.
##
## So the honest position is: **inspection has teeth and the multiplier does
## not.** A harness is a gate you must stay above, not a thing worth improving.
## Whether it SHOULD be worth more is a balance decision with Pete's name on it —
## see `docs/PLAYTEST-15-SEP.md` — and this file deliberately does not make it.
## What it does is give the gate a screen, and add the one thing that was
## genuinely missing: something to spend credits on that a club can be AHEAD in.
##
## ---------------------------------------------------------------------------
## THE TIER IS THE NEW PART, AND IT IS ONE INTEGER PER FIGHTER.
##
## Not three slots with their own condition bars. A per-slot model needs a
## dictionary per man in every save, a migration, three times the UI and three
## times the arithmetic — and it buys nothing the player could not get from one
## number, because the decision is always "is this man's kit good enough". One
## int, one save field, one migration line.
##
## A tier does two things, and both of them run down roads that already exist:
##
##   THE CEILING. A borrowed harness cannot be repaired past `TOP[tier]`. The
##   armorer will tell you so. That makes the tier the only way to reach a full
##   harness at all, which is what makes it worth buying.
##
##   THE WEAR. Better kit takes less damage, so a good harness pays for itself in
##   repairs it does not need. That is the actual economy of armor in the sport
##   and it is the reason anybody buys a real one.
##
## Nothing here touches `rating()`. If armor is to be worth more than 1.54
## points, that is one constant in `fighter_card.gd` and it is not mine to move.

## FOUR RUNGS, named for what they are rather than Poor/Fair/Good/Best. A player
## reads "Borrowed" and knows the story of it.
## FIVE METALS (Pete, 1 Oct 2026): Rust, Mild, Hardened, Stainless, Titanium.
## The first four are the old four renamed — a save's numbers keep meaning the
## same kit — and Titanium is new on the end.
enum Grade { BORROWED, SERVICEABLE, FITTED, TOURNAMENT, TITANIUM }

const GRADE_NAME := {
	Grade.BORROWED: "Rust",
	Grade.SERVICEABLE: "Mild",
	Grade.FITTED: "Hardened",
	Grade.TOURNAMENT: "Stainless",
	Grade.TITANIUM: "Titanium",
}

## WHAT EACH RUNG SAYS, in one line, on the screen.
const GRADE_BLURB := {
	Grade.BORROWED: "Club spares. Never quite fits, never quite clean.",
	Grade.SERVICEABLE: "His own harness. Honest kit that takes a season.",
	Grade.FITTED: "Made to him. Sits right, moves right, lasts.",
	Grade.TOURNAMENT: "Stainless. Hard to beat.",
	Grade.TITANIUM: "Titanium. Nothing on the list is better.",
}

## HOW GOOD A HARNESS AT THIS GRADE CAN EVER BE, and the armorer will not go
## past it. Every rung is comfortably clear of the 0.35 inspection line: a
## starting club is not in danger, it is just never quite right.
##
## NOTHING HERE MAKES TODAY'S GAME WORSE, and that was a deliberate second pass.
##
## The first cut had Borrowed capped at 0.82 and wearing 1.30x — and since every
## fighter in the world defaults to Borrowed, that shipped a 30% wear increase
## and a ceiling cut to every club in the game as a side effect of adding a shop.
## **A feature that nerfs the baseline to make its own upgrades look good is a
## feature charging you to undo it.**
##
## So the bottom rung is roughly where the game already was — 0.90, which costs
## about 0.2 rating points against the old 1.00 and is well inside the noise
## measured below — wear starts at 1.00 and only ever goes DOWN, and the ladder
## is a goal rather than a tax.
const TOP := {
	Grade.BORROWED: 0.90,
	Grade.SERVICEABLE: 0.96,
	Grade.FITTED: 1.00,
	Grade.TOURNAMENT: 1.00,
	Grade.TITANIUM: 1.00,
}

## AND HOW FAST IT GOES. A multiplier on the wear the regime already applies, so
## the regime stays the thing that decides how hard the week was and the harness
## decides how much of that the kit absorbs. Tournament plate takes a third less.
const WEAR := {
	Grade.BORROWED: 1.00,
	Grade.SERVICEABLE: 0.86,
	Grade.FITTED: 0.72,
	Grade.TOURNAMENT: 0.58,
	Grade.TITANIUM: 0.50,
}

## WHAT THE NEXT RUNG COSTS, indexed by the grade you are BUYING. Priced against
## a season: a good season pays 6-10 CC, so outfitting one man to Fitted is most
## of a season and outfitting the whole eight is a project. That is deliberate —
## an upgrade a club can buy for everybody in one afternoon is a menu, not a
## decision.
const COST := {
	Grade.SERVICEABLE: 3,
	Grade.FITTED: 7,
	Grade.TOURNAMENT: 14,
	Grade.TITANIUM: 24,
}


static func grade_of(card: FighterCard) -> int:
	return clampi(card.harness, Grade.BORROWED, Grade.TITANIUM)


static func name_of(card: FighterCard) -> String:
	return UiKit.t(String(GRADE_NAME[grade_of(card)]))


static func ceiling(card: FighterCard) -> float:
	return float(TOP[grade_of(card)])


## WHAT THE CLUB'S ARMORER CAN PUT HIM BACK TO: his own metal's top, or the top
## of the best metal the armorer works in, whichever is lower.
static func repair_top(card: FighterCard, armorer_cap: int) -> float:
	return float(TOP[mini(grade_of(card), armorer_cap)])


static func wear_scale(card: FighterCard) -> float:
	return float(WEAR[grade_of(card)])


## The grade above this man's, or -1 when there is nothing better to buy.
static func next_grade(card: FighterCard) -> int:
	var g := grade_of(card)
	return -1 if g >= Grade.TITANIUM else g + 1


static func upgrade_cost(card: FighterCard) -> int:
	var n := next_grade(card)
	return 0 if n < 0 else int(COST[n])


## HOW WORN A HARNESS HAS TO BE BEFORE THE ARMORER WILL TAKE THE JOB.
##
## This was 0.001 — which is to say, any scratch at all — and that turned out to
## be the largest avoidable cost in the early game.
##
## `ClubOffice.kit_cost` has a FLOOR OF ONE CREDIT, for the good reason that a
## club should never be charged nothing for work. Put the two together across a
## squad of thirteen and a club was paying **thirteen credits a season to fix
## almost nothing**: every man came back from a week a fraction below his
## ceiling, every one of them billed the floor, and `tools/probe_afford.gd` found
## the whole of a first season's maintenance bill was this and nothing else —
## against a first-season income of 23 CC.
##
## Pete, 15 Sep 2026: *"The income is either too low or costs are too high."*
## This is the second one, and it is not a price that needed lowering: it is a
## JOB THAT SHOULD NOT HAVE BEEN SOLD. The arena already has the rule in as many
## words — *"a ground already spotless is refused rather than billed"* — and the
## armorer was the one place in the game that would happily take a credit for
## polishing something that did not need polishing.
##
## 0.08, which is about one hard week. Below that he tells you to come back when
## there is something to do.
const WORTH_DOING: float = 0.08


## IS HIS HARNESS AS GOOD AS IT CAN BE — at his grade, which is not the same
## question as "is it at 1.00". The armorer's refusal has to say which of the
## two it means or a player reads "as good as it gets" as a bug.
static func topped_out(card: FighterCard, cap: int = Grade.TITANIUM) -> bool:
	return card.armor >= repair_top(card, cap) - WORTH_DOING


## ---------------------------------------------------------------- the ledger
## WHAT THE WHOLE SQUAD LOOKS LIKE, in one pass, for the screen and for the
## suite. A screen that computes its own totals and a check that computes them
## again are two answers to one question.
##
## `who` is the list to read — the traveling eight for the bill that matters,
## the whole book for the table.
static func ledger(who: Array, cap: int = Grade.TITANIUM) -> Dictionary:
	var out := {
		"men": who.size(),
		"failing": 0,      ## cannot go out at all
		"at_risk": 0,      ## within one bad week of the line
		"worn": 0,         ## repairable at their grade
		"mean": 0.0,
		"bill": 0,         ## CC to put every repairable harness back to its top
	}
	if who.is_empty():
		return out
	var total := 0.0
	for f in who:
		total += f.armor
		if not f.passes_inspection():
			out["failing"] = int(out["failing"]) + 1
		elif f.inspection_margin() < RISK_MARGIN:
			out["at_risk"] = int(out["at_risk"]) + 1
		if not topped_out(f, cap):
			out["worn"] = int(out["worn"]) + 1
			out["bill"] = int(out["bill"]) + ClubOffice.kit_cost(f, cap)
	out["mean"] = total / float(who.size())
	return out


## HOW CLOSE TO THE LINE COUNTS AS CLOSE. `inspection_margin()` is 1.0 at a full
## harness and 0.0 at the line; a fifth of the way up is about two hard weeks,
## which is the horizon a player can actually act on.
const RISK_MARGIN: float = 0.20
