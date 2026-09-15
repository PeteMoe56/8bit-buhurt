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


## WHICH DIVISION'S STANDARD THIS MAN IS AT, read off his RATING against the
## division doing the signing — not remembered from `_band_step` at generation.
##
## Two reasons it is read and not stored. A man drawn in the band above who came
## out at the bottom of it really is an own-division signing however he was made,
## and the player can only ever judge by the number on the card; a label that
## disagrees with the stars is a label that teaches the player to ignore labels.
## And a stored origin would be a second copy of something the rating already
## says — *a number that has to agree with another number is a number that will
## stop agreeing*.
enum Step { BELOW, OWN, ABOVE }

static func step_of(rating: int, tier: int) -> int:
	var own: Array = League.TIERS[clampi(tier, 0, League.TIERS.size() - 1)]["power"]
	if rating < int(own[0]):
		return Step.BELOW
	if rating > int(own[1]):
		return Step.ABOVE
	return Step.OWN


## AND THE WORD FOR IT, WHICH IS BLANK FOR MOST OF THE LIST ON PURPOSE.
##
## Half the shelf is at your own standard. Stamping "YOUR LEVEL" on three cards
## in six is a label that costs a corner of every card to say nothing; the two
## worth a word are the bargain and the reach, and they want DIFFERENT words
## because they are different decisions. A man below your band is depth — he is
## the fourteenth name, the one who covers an injury. A man above it is the
## signing that changes a season, and he is what you save for.
static func step_word(rating: int, tier: int) -> String:
	match step_of(rating, tier):
		Step.BELOW: return "depth"
		Step.ABOVE: return "step up"
	return ""


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
	for i in SIZE + maxi(0, extra):
		## ONE DIVISION EITHER SIDE, AND NO FURTHER.
		##
		## Pete, 15 Sep 2026: *"tier the free agents. Then there can be ranges for
		## stats. A free agent won't bother being available if they aren't one
		## league above or below the team's standing."*
		##
		## It used to draw every man from the club's own band, widened six points
		## down and two up — one range, and the same range whoever you were. Two
		## things were wrong with that. A club had no reason to look forward to
		## the next division, because the list it would find there was the list it
		## already had; and there was no such thing as a stretch signing, because
		## nobody better than your own band ever appeared.
		##
		## **A market that offers you your own standard is a market with nothing
		## to want in it.** So the list spans the division below, your own, and the
		## one above, weighted to your own — and the man from the league above is
		## the one you save for.
		var step := _band_step(rng)
		var t := clampi(tier + step, 0, League.TIERS.size() - 1)
		var range_: Array = League.TIERS[t]["power"]
		var at: float = rng.randf()
		var target := int(lerpf(float(range_[0]) - 6.0, float(range_[1]) + 2.0, at))
		var slot: int = rng.randi() % 5
		var f := ClubFactory.free_agent(rng, slot, target)
		out.append(f)
	## Best first. A list a player has to sort himself is a list he will misread
	## once and then distrust.
	out.sort_custom(func(a, b): return a.overall() > b.overall())
	return out


## WHICH OF THE THREE DIVISIONS THIS MAN CAME FROM. Half your own, a third from
## below, a sixth from above — so most of the list is men you can carry, there is
## always somebody who would be a bargain, and roughly one man in six is a reach.
##
## THE ODDS ARE NOT SYMMETRIC AND THAT IS THE POINT. A man a division above you
## is a signing that changes a season; a man a division below is depth. If they
## were equally likely the list would be half bargains and the reach would stop
## being a reach.
static func _band_step(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if r < 0.33:
		return -1
	if r < 0.83:
		return 0
	return 1


## Has this man already been signed out of this summer's pool? Matched on name
## and rating rather than on the object, because the pool is REGENERATED and the
## card the club is holding is a different object from the one in the new list.
static func taken_key(f: FighterCard) -> String:
	return "%s/%d/%d" % [f.display_name, f.overall(), int(f.pos)]
