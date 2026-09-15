class_name Market
extends RefCounted
## THE PLAYER MARKET — where a club gets better without waiting for a winter.
##
## Phase three of Pete's eight, and the piece tools/probe_career.gd proved was
## missing: a managed club with a maxed training ground and two captains still
## slid from 66 to 34 over twenty-five seasons, because **every man who retired
## was replaced by a walk-on nine points under the division floor.** The same club
## with an inflow that is not replacement level climbed to 75 and held. The career
## arithmetic was never the problem. This is.
##
## NO DRAFT. Retro Bowl's inflow is a draft, and it is the one piece of their
## structure that does not survive the trip: buhurt clubs do not draft, there is
## no college system feeding them, and a fighter picks who he trains with. The
## sport's actual mechanism is that people become available and clubs talk to
## them — which is free agency, so free agency is what this is.
##
## ONE POOL A SUMMER, SEEDED. Generated from the season number and the world seed
## rather than stored, so a save carries WHICH men were taken and not who was on
## offer — the same reasoning the tournament bid dates use, and the same reason:
## a second copy of something already deterministic is a second thing that can
## disagree with the first.

const SIZE: int = 6


## COARSE TIERS, and this is Pete's item 8: *"coarse tiers somewhere, so there is
## a seam to game."*
##
## The signing fee is charged by BAND, not by rating. A 61 and a 68 in the same
## band cost the same credits — so the skill is reading the pool and taking the
## man at the top of a band rather than the one at the bottom of the next. That
## seam is deliberate. Retro Bowl's trade values are bucketed the same way and
## the bucket edges are the first thing a good player learns.
##
## The bands are read against the DIVISION's own power range, so "a good signing"
## means the same thing in the Backyard Circuit as it does at National — and the
## fee is in credits, where every other decision the owner makes already lives.
const BANDS: Array[float] = [0.25, 0.50, 0.75, 1.00]
const BAND_NAME: Array[String] = ["Journeyman", "Steady", "Good", "Strong", "Star"]
const BAND_FEE: Array[int] = [1, 3, 6, 11, 18]


## Which band a rating falls in, against the division it is being signed into.
static func band_of(rating: int, tier: int) -> int:
	var range_: Array = League.TIERS[tier]["power"]
	var lo := float(range_[0])
	var hi := float(range_[1])
	var t: float = clampf((float(rating) - lo) / maxf(1.0, hi - lo), 0.0, 1.0)
	var b := 0
	for edge in BANDS:
		if t >= edge:
			b += 1
	return mini(b, BAND_FEE.size() - 1)


static func fee(rating: int, tier: int) -> int:
	return BAND_FEE[band_of(rating, tier)]


static func band_name(rating: int, tier: int) -> String:
	return BAND_NAME[band_of(rating, tier)]


## THE POOL. Rebuilt from the season and the seed every time it is asked for, so
## it is the same list on both sides of a reload.
##
## It is drawn ACROSS the division's band rather than at the middle of it, and it
## deliberately includes men the club cannot afford and men it should not want.
## A market where everything on offer is an upgrade is a shop, and a shop with
## one currency is just a slow way of spending credits. The reading is the game.
## `refreshes` is how many times the club has PAID to turn this list over. It is
## part of the key rather than an offset applied afterwards, so a refreshed list
## is a genuinely different draw and not the same men in a new order — see
## `ClubOffice.refresh_market`. Defaulted, so every existing caller and test sees
## the list it always saw.
## `extra` is how many more names a Scout captain turns up — see
## `ClubOffice.TRAIT_SCOUT_EXTRA`. Added to the draw rather than filtered in
## afterwards, so the men a scout finds are genuinely additional and not the same
## list with the bottom shown.
static func pool(world_seed: int, season: int, tier: int, refreshes: int = 0,
		extra: int = 0) -> Array:
	var rng := RandomNumberGenerator.new()
	## Mixed rather than added, so season 2 of one save and season 1 of the next
	## do not collide into the same list.
	rng.seed = hash("market:%d:%d:%d:%d" % [world_seed, season, tier, refreshes])
	var out: Array = []
	var range_: Array = League.TIERS[tier]["power"]
	for i in SIZE + maxi(0, extra):
		var at: float = rng.randf()
		var target := int(lerpf(float(range_[0]) - 6.0, float(range_[1]) + 2.0, at))
		var slot: int = rng.randi() % 5
		var f := ClubFactory.free_agent(rng, slot, target)
		out.append(f)
	## Best first. A list a player has to sort himself is a list he will misread
	## once and then distrust.
	out.sort_custom(func(a, b): return a.overall() > b.overall())
	return out


## Has this man already been signed out of this summer's pool? Matched on name
## and rating rather than on the object, because the pool is REGENERATED and the
## card the club is holding is a different object from the one in the new list.
static func taken_key(f: FighterCard) -> String:
	return "%s/%d/%d" % [f.display_name, f.overall(), int(f.pos)]
