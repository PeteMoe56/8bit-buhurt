class_name Arena
extends RefCounted
## YOUR GROUND, and the thing every other number on the Clubhouse screen
## eventually points at.
##
## Pete, 10 Sep 2026: *"we want to be able to build and upgrade your own
## Arena/Stadium/Gym. Each upgrade unlocked via league advancement. You'll be
## able to run your own events from a demo that may raise a couple dollars all
## the way up to hosting the National Championship."*
##
## THIS REPLACES THE HOME GROUND FACILITY. That facility already said *"Host an
## event each season. Better ground, better gate"* — it was this feature in
## embryo, five levels of a progress bar with nothing behind it. Two systems for
## one idea is worse than either: the player would have had a Home ground level
## AND an arena level, both feeding the gate, and no way to reason about which
## one to spend on. So the facility is gone and the credits go here.
##
## UNLOCKED BY ADVANCEMENT, NOT BY MONEY. Every other purchase in the game is
## "have you got the credits"; this one is "have you earned the right", and that
## is the point of it. A Backyard club cannot buy a national arena at any price,
## which makes promotion worth something beyond a better fixture list.

## Each level: what it is called, the league tier you must have REACHED to build
## it, what it costs in credits, and how many people it holds.
##
## Capacity is the number that does the work. It sets the ceiling on every gate
## in the game AND the ceiling on how many fans a club can carry, and the whole
## event economy is written against it rather than against the level number — so
## adding a level later is data, not a re-balance.
##
## THE JUMP FROM REGIONAL TO NATIONAL IS MEANT TO BE FELT. Pete, 10 Sep 2026:
## the first four grounds stay small and club-sized, then the Arena is twelve
## thousand and the National Arena is eighty. A sport whose biggest room holds a
## thousand people has no top end to climb to; that step is the top end.
const LEVELS := [
	{
		"name": "Back field", "tier": 0, "cost": 0, "capacity": 40,
		"blurb": "A rope, a rail and somebody's truck. It is a place to fight and that is all it is.",
	},
	{
		"name": "Club gym", "tier": 0, "cost": 6, "capacity": 120,
		"blurb": "Mats, a roof and a kettle. Forty people can watch without standing in mud.",
	},
	{
		"name": "Fenced ground", "tier": 1, "cost": 12, "capacity": 400,
		"blurb": "A proper list, hoarding all the way round and a gate you can take money on.",
	},
	{
		"name": "Sports hall", "tier": 1, "cost": 22, "capacity": 1200,
		"blurb": "Seated, lit and warm. Clubs will travel to fight here.",
	},
	{
		"name": "Arena", "tier": 2, "cost": 38, "capacity": 12000,
		"blurb": "Tiered stands, a marshal's box and a screen. This is where a season gets decided.",
	},
	{
		"name": "National Arena", "tier": 3, "cost": 60, "capacity": 80000,
		"blurb": "The federation brings the National Championship here. The whole ambition, built.",
	},
]

const MAX_LEVEL: int = 5

var level: int = 0


func here() -> Dictionary:
	return LEVELS[clampi(level, 0, MAX_LEVEL)]


func arena_name() -> String:
	return String(here()["name"])


func capacity() -> int:
	return int(here()["capacity"])


func at_top() -> bool:
	return level >= MAX_LEVEL


func next() -> Dictionary:
	return LEVELS[level + 1] if not at_top() else {}


func next_cost() -> int:
	return int(next()["cost"]) if not at_top() else 0


## The league tier the NEXT build needs. The Clubhouse screen wants this even
## when the player cannot afford it yet, because "get promoted" is a different
## instruction from "save up" and he needs to know which one he is looking at.
func next_tier() -> int:
	return int(next()["tier"]) if not at_top() else -1


## Everything wrong with building the next one, in the order a player would fix
## it — the league first, because no amount of saving fixes that one.
func can_build(tier: int, credits: int) -> String:
	if at_top():
		return "%s is as far as a club can build." % arena_name()
	var n := next()
	if tier < int(n["tier"]):
		return "The %s is for clubs in the %s. Get promoted first." % [
			String(n["name"]), League.tier_name(int(n["tier"]))]
	if credits < int(n["cost"]):
		return "The %s costs %d CC and you have %d." % [
			String(n["name"]), int(n["cost"]), credits]
	return ""


## THE BADGE GETS BETTER WITH THE GROUND. Pete, 10 Sep 2026: *"each upgrade
## making the logo go from really shitty quality to NFL level details."*
##
## It is the club's OWN mark that improves, not a stock image — the same
## IconBank draw, rendered rough at a back field and crisp at a national arena.
## A player who picked the Wolf watches his wolf get sharper, which is a
## progression he owns; a stock logo getting better is a progression he watches.
##
## 0 is a rough paint job and 1 is a printed one.
func badge_quality() -> float:
	return float(level) / float(MAX_LEVEL)
