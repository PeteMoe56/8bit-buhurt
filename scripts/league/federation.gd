class_name Federation
extends RefCounted
## THE FEDERATION, AND THE PEOPLE WHO TURN UP. Two masters, one purse.
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
##   THE FOLLOWING is what the club earns off, and it walks when the club
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


# ---------------------------------------------------------------- the season
## WHAT A SEASON DOES TO THE FOLLOWING, over and above the week-to-week results.
##
## THIS WAS `members_after` AND THE MEMBERSHIP ROLL IT MOVED IS GONE. Pete, 15
## Sep 2026: *"I don't like our 3 factors, there should be one."* `members` was
## the third population — behind `notoriety` and `fans` — and the weakest, since
## its only output was a subscription the club no longer collects: the federation
## bills the club now, at `League.dues_for(tier)`.
##
## The SIGNALS were never the problem and they are kept whole. A season in the top
## half, a room worth being in, and a club that can fill its own bus are three
## things the player can see on his own screens and three things he chose. They
## simply move the one population that is left.
##
## `bench_full` is whether the places on the bus are actually filled with fit
## men, which is the most visible form of "unserious" a club has: turning up
## five-handed.
##
## A fourth term used to sit here — a club nobody in the sport would train with
## lost people too — and it went when goodwill did (Pete, 12 Sep 2026).
const FOLLOW_WIN: float = 0.10          ## a winning season, as a fraction of the gap
const FOLLOW_LOSS: float = -0.09
const FOLLOW_MORALE: float = 0.14       ## a room worth being in
const FOLLOW_THIN_SQUAD: float = -0.12  ## a club that cannot fill its own bus


## A multiplicative move toward or away from the ceiling — the same logistic
## shape morale and the following's own week-to-week already use, and for the
## same reason: a flat accumulator walks into a wall and stays there.
##
## `cap` is `ClubOffice.fan_cap()`, passed in rather than reached for, because
## the ceiling is a fact about the ground and this file knows nothing about
## grounds.
static func following_after(fans: float, cap: float, won_more: bool,
		morale: float, bench_full: bool) -> float:
	var swing := FOLLOW_WIN if won_more else FOLLOW_LOSS
	if morale >= 0.60:
		swing += FOLLOW_MORALE
	if not bench_full:
		swing += FOLLOW_THIN_SQUAD
	var room: float = (cap - fans) if swing > 0.0 else fans
	return clampf(fans + swing * room, 0.0, cap)


## HOW BIG THE CLUB READS, off the one population. `members_word` banded a 1–60
## roll; this bands the following against the GROUND, because the following spans
## twelve to a hundred thousand and a constant could not mean the same thing at
## both ends. A packed back field is "a proper club" in exactly the way it should
## be — it is a proper club, it just has a small ground.
static func following_word(fans: float, cap: float) -> String:
	var f: float = 0.0 if cap <= 0.0 else clampf(fans / cap, 0.0, 1.0)
	if f >= 0.85:
		return "A proper club"
	if f >= 0.60:
		return "Healthy"
	if f >= 0.35:
		return "Ticking over"
	if f >= 0.15:
		return "Thin"
	return "A few mates"
