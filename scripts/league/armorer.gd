class_name Armorer
extends RefCounted
## THE ARMORER, HIRED (Pete, 1 Oct 2026: "Make Armorer hire-able with star
## ranks. Each star is which kit they can create/maintain up to Titanium.").
##
## One at a time. His stars are the best metal he can make and keep:
##
##   1 star Rust · 2 Mild · 3 Hardened · 4 Stainless · 5 Titanium
##
## A man in better metal than his can still fight; the armorer only fixes him up
## to what he can do himself. A new club starts with a one-star hand for nothing.
## The wage is paid each summer with the rest of the bills; a club that cannot
## pay it is left with the one-star hand again.

const MAX_STARS: int = 5
## CC a season, by stars.
## The one-star hand is free (Pete, 1 Oct 2026: a new club starts with him for nothing).
const WAGE := [0, 0, 1, 1, 2, 3]  ## cut 8 Oct 2026, Harness #2 (were 0,0,2,4,9,18)
## The lowest division each grade of man will work in.
const MIN_TIER := [0, 0, 0, 0, 1, 3]
const POOL_SIZE: int = 5

const FIRST := ["Hal", "Joaquin", "Mags", "Ivar", "Anton", "Bram", "Dora", "Emil", "Fenna", "Gus",
	"Hester", "Ike", "Jory", "Kasia", "Lev", "Moss", "Nell", "Otto", "Pia", "Rufus"]
const LAST := ["Brenner", "Reyes", "Dolan", "Holm", "Vasko", "Kettle", "Marsh", "Anvil", "Stroud", "Pike",
	"Rook", "Tallow", "Quill", "Varga", "Wick", "Yates", "Zeller", "Hobb", "Crane", "Ostrow"]


static func make(stars: int, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	return {"name": "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]],
		"stars": clampi(stars, 1, MAX_STARS)}


## The best grade (Quartermaster.Grade) he can make and keep.
static func cap_of(a: Dictionary) -> int:
	return clampi(int(a.get("stars", 1)) - 1, 0, MAX_STARS - 1)


static func wage_of(a: Dictionary) -> int:
	return int(WAGE[clampi(int(a.get("stars", 1)), 1, MAX_STARS)])


## WHO IS LOOKING FOR WORK this season: one man of each grade, the same list all
## season (a reload rolls the same faces).
## FIVE DIFFERENT PEOPLE (review, 1 Oct 2026: "Hester Yates" and "Hester
## Brenner" beside your "Hal Brenner"): no first or last name used twice, and
## none of yours.
static func pool(seed_v: int, season_no: int, mine: String = "") -> Array:
	var out: Array = []
	var used_f := {}
	var used_l := {}
	var parts := mine.split(" ")
	if parts.size() == 2:
		used_f[parts[0]] = true
		used_l[parts[1]] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("armorers:%d:%d" % [seed_v, season_no])
	for st in range(1, MAX_STARS + 1):
		var f: String = FIRST[rng.randi() % FIRST.size()]
		while used_f.has(f):
			f = FIRST[(FIRST.find(f) + 1) % FIRST.size()]
		var l: String = LAST[rng.randi() % LAST.size()]
		while used_l.has(l):
			l = LAST[(LAST.find(l) + 1) % LAST.size()]
		used_f[f] = true
		used_l[l] = true
		out.append({"name": "%s %s" % [f, l], "stars": st})
	return out


## Whether a man of these stars will come to a club in this division.
static func will_come(stars: int, tier: int) -> bool:
	return tier >= int(MIN_TIER[clampi(stars, 1, MAX_STARS)])


static func metal_name(grade: int) -> String:
	return UiKit.t(String(Quartermaster.GRADE_NAME[clampi(grade, 0, MAX_STARS - 1)]))
