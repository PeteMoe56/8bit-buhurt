class_name Federation
extends RefCounted
## THE FEDERATION, AND THE MEMBERS. Two masters, one purse.
##
## DIRECTION §4: *"Owner/fan pressure → members and the federation. Members pay
## dues and walk if you're unserious. The federation gates nationals and Worlds
## on results and compliance — kit standards, marshal certs, insurance. Two
## masters pulling opposite directions."*
##
## THE TENSION IS THE FEATURE, and it took a rewrite to get it pointing the right
## way. The first version had members leaving when the club was non-compliant,
## which made both masters want the same thing and turned the whole pillar into
## one slider called "be good".
##
## They pull opposite ways because they want opposite things out of the SAME
## CREDITS:
##
##   THE FEDERATION wants money spent on certificates, insurance and harness
##   inspection. Every credit of it buys exactly nothing on the field. Fall short
##   and you are not entered for the cups — however well you have played.
##
##   THE MEMBERS pay the dues that fund the club, and they walk when the club
##   stops being worth turning up to: a bad room, a thin squad, a losing year.
##   Everything that keeps them costs the money the federation is asking for.
##
## So the decision is real in both directions and neither answer is safe. A club
## that pays the federation and starves the squad loses its members and then
## cannot pay the federation. A club that spends on the squad wins a division it
## is then not allowed to take a cup out of.

enum Rule { KIT, MARSHALS, INSURANCE }

const RULE_NAME := {
	Rule.KIT: "Kit standards",
	Rule.MARSHALS: "Marshal certs",
	Rule.INSURANCE: "Insurance",
}

const RULE_BLURB := {
	Rule.KIT: "Harnesses inspected and stamped to the current standard.",
	Rule.MARSHALS: "Somebody at your club qualified to run a list.",
	Rule.INSURANCE: "Cover for the men, the ground and the people watching.",
}

## WHAT EACH DIVISION DEMANDS, by tier, as a level 0-3 per rule.
##
## THE BACKYARD CIRCUIT ASKS FOR NOTHING, and that is the whole shape of this
## table. DIRECTION §4 says the federation *"gates nationals and Worlds"* — it
## does not say it gates a field and a rail, and a backyard circuit is by
## definition the level with no paperwork on it.
##
## It asked for a kit certificate for about ten minutes, and the suite said what
## that meant: `test_cupplay.gd` went red with **"no cup came up"** five times
## over. A brand-new club has no certificates, so the gate barred it from every
## Invitational in its first season — the cup run that is most of the early game,
## closed before the player has seen the screen that would have told him why.
##
## Starting at nothing also makes the climb the thing that bites: promotion is
## not only harder opponents, it is a bill for paperwork that does not make you
## better, arriving in the same summer as everything else. A club that goes up
## two divisions in three seasons meets the federation before it meets the
## fixtures.
const DEMANDED := {
	League.Tier.BACKYARD: { Rule.KIT: 0, Rule.MARSHALS: 0, Rule.INSURANCE: 0 },
	League.Tier.STATE:    { Rule.KIT: 1, Rule.MARSHALS: 1, Rule.INSURANCE: 1 },
	League.Tier.REGIONAL: { Rule.KIT: 2, Rule.MARSHALS: 2, Rule.INSURANCE: 1 },
	League.Tier.NATIONAL: { Rule.KIT: 3, Rule.MARSHALS: 2, Rule.INSURANCE: 3 },
}

const MAX_LEVEL: int = 3
## What one level of each costs to hold, per season. Insurance is the dear one
## and the useless one, which is exactly what insurance is.
const UPKEEP := { Rule.KIT: 2, Rule.MARSHALS: 2, Rule.INSURANCE: 3 }
## And what it costs to reach a level in the first place.
const RAISE_COST := [3, 5, 8]


static func required(tier: int, rule: int) -> int:
	var d: Dictionary = DEMANDED.get(clampi(tier, 0, League.TIERS.size() - 1), {})
	return int(d.get(rule, 0))


static func rules() -> Array[int]:
	return [Rule.KIT, Rule.MARSHALS, Rule.INSURANCE]


static func raise_cost(level: int) -> int:
	if level < 0 or level >= RAISE_COST.size():
		return 0
	return int(RAISE_COST[level])


## The annual bill for what a club HOLDS, not for what it needs. A club carrying
## National-grade insurance in the Backyard Circuit pays for it — the federation
## does not refund you for being careful.
static func upkeep_of(held: Dictionary) -> int:
	var total := 0
	for r in rules():
		total += int(UPKEEP[r]) * int(held.get(r, 0))
	return total


## WHAT YOU ARE SHORT, by name, for the screen and for the refusal message. A
## gate that says "no" without saying which rule is a gate the player cannot act
## on.
static func shortfalls(held: Dictionary, tier: int) -> Array[String]:
	var out: Array[String] = []
	for r in rules():
		if int(held.get(r, 0)) < required(tier, r):
			out.append(String(RULE_NAME[r]))
	return out


static func compliant(held: Dictionary, tier: int) -> bool:
	return shortfalls(held, tier).is_empty()


# ------------------------------------------------------------------ members
## DUES, AND WHY THEY ARE NOT THE GATE.
##
## A member is not a fan. Fans turn up when you are winning and go home when you
## are not; `ClubOffice.fans` already models that and feeds the gate. A member
## pays a standing subscription because this is HIS club — he trains there, his
## mates are there, and he keeps paying through a bad season right up until the
## point the place stops being worth belonging to.
##
## Which is what makes the dues the right money to put against the federation's
## bill: it is the income that does not move with results, so spending it on
## paperwork is a decision rather than an accounting entry.
const DUES: int = 1                     ## credits per member per season
const MEMBERS_START: float = 8.0
const MEMBERS_MAX: float = 60.0

## WHAT KEEPS THEM AND WHAT LOSES THEM, per season. Every one of these is
## something the player chose, and not one of them is compliance — see the note
## at the top of this file for why that matters.
const MEM_WIN: float = 0.10             ## a winning season, as a fraction of the gap
const MEM_LOSS: float = -0.09
const MEM_MORALE: float = 0.14          ## a room worth being in
const MEM_THIN_SQUAD: float = -0.12     ## a club that cannot fill its own bus


## The dues a club banks for the year.
static func dues_for(members: float) -> int:
	return int(floor(members * float(DUES)))


## A SEASON OF MEMBERSHIP, as a multiplicative move toward or away from the
## ceiling — the same logistic shape morale and the following already use, and
## for the same reason: a flat accumulator walks into a wall and stays there.
##
## `bench_full` is whether the places on the bus are actually filled with fit
## men, which is the most visible form of "unserious" a club has: turning up
## five-handed.
##
## A fourth term used to sit here — a club nobody in the sport would train with
## lost members too — and it went when goodwill did (Pete, 12 Sep 2026). The
## three that are left are all things the player can see on his own screens.
static func members_after(members: float, won_more: bool, morale: float,
		bench_full: bool) -> float:
	var m := members
	var swing := MEM_WIN if won_more else MEM_LOSS
	if morale >= 0.60:
		swing += MEM_MORALE
	if not bench_full:
		swing += MEM_THIN_SQUAD
	var room: float = (MEMBERS_MAX - m) if swing > 0.0 else m
	return clampf(m + swing * room, 1.0, MEMBERS_MAX)


static func members_word(members: float) -> String:
	if members >= 45.0:
		return "A proper club"
	if members >= 28.0:
		return "Healthy"
	if members >= 14.0:
		return "Ticking over"
	if members >= 6.0:
		return "Thin"
	return "A few mates"
