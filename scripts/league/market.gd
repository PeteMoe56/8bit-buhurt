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
## FIVE EVEN FIFTHS OF THE SHELF, AND THE LAST EDGE IS NOT 1.00.
##
## It was [0.25, 0.50, 0.75, 1.00], which made Star fire only at t == 1.0 —
## a band exactly ONE RATING POINT WIDE. It went unnoticed for weeks because
## `clampf` pinned everything above the range to 1.0 and swept it into Star, so
## the band looked 19% wide while its definition was a single number. The moment
## `Marquee` claimed everything over the shelf top, the clamp stopped covering
## for it and `tools/probe_market.gd` printed "Star  52- 52".
##
## **A band held open by a clamp is not a band, it is a rounding artifact.** Four
## edges at fifths give five real bands and leave the top of the scale to mean
## what it says.
const BANDS: Array[float] = [0.20, 0.40, 0.60, 0.80]
const BAND_NAME: Array[String] = ["Journeyman", "Steady", "Good", "Strong", "Star",
	"Marquee"]


## THE FEE IS A FRACTION OF A SEASON, NOT A NUMBER OF CREDITS.
##
## `BAND_FEE` was [1, 3, 6, 11, 18] and it was those credits at EVERY rung of the
## pyramid. `tools/probe_wallet.gd` measured what a season actually leaves a club
## for its squad — 16 / 33 / 37 / 67 credits up the ladder — so an 18-credit Star
## was a whole season's spending money in the Backyard Circuit and a quarter of
## one at National. `probe_shelf` saw the consequence from the other side: 97 to
## 100 per cent of every shelf, at every rung, was inside the club's reach. The
## market never once said no on money.
##
## So the fee is a SHARE of `League.TIERS[t]["slack"]`. The Backyard column comes
## out at the same 1 / 3 / 6 / 11 / 18 it always was — that division was tuned
## and Pete confirmed it plays right — and every rung above it scales:
##
##            BYC   STL   REG   NAT
##   Journey    1     2     2     4
##   Steady     3     6     7    12
##   Good       6    12    14    25
##   Strong    11    22    25    46
##   Star      18    36    41    74
##   Marquee    -     -     -   174
##
## A Star is now about one season's entire squad budget wherever you stand, which
## is what a Star should cost, and what "save up for him" means.
const BAND_SHARE: Array[float] = [0.06, 0.18, 0.37, 0.68, 1.10, 2.60]


## THE FOREIGN MAN, and he exists because the top of the pyramid had nothing to
## want. Pete, 15 Sep 2026: *"a rare foreign man that upfront costs are large can
## show up, but otherwise, nothing above national."*
##
## `probe_shelf` measured the hole: `clampi(tier + step, 0, 3)` sends the
## one-in-six reach draw back into your own band at the top flight, so "above"
## collapsed to 6% and a club arriving at National — with the most money it will
## ever have — found a FLATTER shelf than the one it left. Every rung below had
## a man you saved for and the top rung did not.
##
## He is not a fifth division bolted onto the world. He is one name, rarely, from
## outside it: rated over the National ceiling, carrying a Marquee fee that is two
## and a half seasons of everything a top-flight club has spare. Rare enough that
## a career sees a handful, dear enough that taking one is the year's decision.
const FOREIGN_CHANCE: float = 0.25    ## of the reach draws, at the top rung only
const FOREIGN_TOP: int = 94


## THE SPAN A FEE IS MEASURED AGAINST — the SHELF, not the division.
##
## This was `League.TIERS[tier]["power"]`, which is the standard of the clubs in
## the division and not the standard of the men on offer to them. The pool draws
## a third of its names from the division below, so a third of every shelf sat
## entirely underneath the scale pricing it — and since the bands get wider the
## higher you climb, the mispricing got worse with every promotion. Journeyman
## share ran 30% at Backyard and 59% at National.
##
## `shelf` is measured (see `League.TIERS`) and both this and the odds in
## `_band_step` describe the same list, so the probe that measures one is the
## check on the other.
static func shelf_of(tier: int) -> Array:
	return League.TIERS[clampi(tier, 0, League.TIERS.size() - 1)]["shelf"]


## Which band a rating falls in, against the division it is being signed into.
static func band_of(rating: int, tier: int) -> int:
	var shelf: Array = shelf_of(tier)
	var hi := float(shelf[1])
	## ABOVE THE SHELF IS THE MARQUEE BAND, and at the top rung that is the only
	## thing it can be: nothing in the world rates over the National ceiling
	## except the man who came from outside it. Checked before the scale rather
	## than after it, because clamping him into the top of the ordinary range is
	## exactly how he would end up costing Star money.
	if float(rating) > hi:
		return BAND_NAME.size() - 1
	var lo := float(shelf[0])
	var t: float = clampf((float(rating) - lo) / maxf(1.0, hi - lo), 0.0, 1.0)
	var b := 0
	for edge in BANDS:
		if t >= edge:
			b += 1
	return mini(b, BAND_NAME.size() - 2)


## AND THE PRICE IS THAT BAND'S SHARE OF THE DIVISION'S SEASON. One multiply,
## and it is the multiply that makes the fee mean the same thing at every rung.
static func fee(rating: int, tier: int) -> int:
	var slack: int = int(League.TIERS[clampi(tier, 0, League.TIERS.size() - 1)]["slack"])
	return maxi(1, int(round(BAND_SHARE[band_of(rating, tier)] * float(slack))))


static func band_name(rating: int, tier: int) -> String:
	return BAND_NAME[band_of(rating, tier)]


## ------------------------------------------------------------ selling him on
## WHAT ANOTHER CLUB WILL PAY FOR HIM, and this is Retro Bowl's answer rather
## than a new one. Pete, 15 Sep 2026: *"let's go with Retro Bowl's answer."*
##
## Theirs, off the wiki: a traded player returns a future DRAFT PICK, and the
## pick is bucketed into exactly three tiers by his star rating — a third-rounder
## under two stars, a second between two and four, a first at four and above.
## Value is *"calculated according to their star ranking and attributes"*, and
## the buckets are wide enough that a 3.9-star and a 2.0-star fetch the same
## thing. That is the beloved arbitrage: you learn the edges and you sell the man
## at the BOTTOM of a bucket.
##
## TWO THINGS CHANGE IN TRANSLATION AND NEITHER IS A CHOICE. We have no draft —
## `pool()` says why at length, and buhurt clubs do not have one — so the return
## is credits, which is the only currency a club here has. And our star system is
## `BAND_NAME`, six buckets rather than their five-and-a-half stars, so the three
## tiers are made by COLLAPSING PAIRS of it rather than by inventing a second
## scale. A Good man and a Strong man fetch the same money; so do a Journeyman
## and a Steady, and a Star and a Marquee.
##
## Reusing the fee bands is the whole point. The player already reads them when
## he buys, the seam is already coarse, and a second scale for selling would be a
## second thing to learn that says nearly the same thing as the first.
const SALE_TIERS: Array[String] = ["Squad man", "First team", "Marquee man"]


## Which of the three he is in. Read off the SAME `band_of` the fee uses, so the
## two halves of the market cannot drift apart on where an edge sits.
static func sale_tier(rating: int, tier: int) -> int:
	return mini(band_of(rating, tier) / 2, SALE_TIERS.size() - 1)


static func sale_tier_name(rating: int, tier: int) -> String:
	return SALE_TIERS[sale_tier(rating, tier)]


## AND WHAT THE TIER PAYS: a share of what the LOWER band in it costs to sign.
##
## The lower of the pair, and under half of it, and the first cut got the first
## of those backwards. Reading the TOP made the bucket flat in the right way —
## a Good man fetching Strong money is exactly the arbitrage — and it also made
## the top bucket pay **19 against a Star's fee of 18**, because the top of that
## pair is Marquee and a Marquee costs 42. Buy a Star, sell him the same
## afternoon, bank a credit. *A market where a man can be bought and immediately
## sold at a profit is not a market, it is a printer.*
##
## The lower band keeps the flatness and kills the loop: within a bucket every
## man fetches what the CHEAPEST of them costs to sign, times a share under a
## half, so the sale is strictly under the fee at every rating in the game —
## `test_market` asserts exactly that, because a rule this easy to get backwards
## should not be guarded by a comment.
##
## The arbitrage survives intact and is the whole point: a Strong man costs 11 to
## sign and fetches the same 3 as a Good man who cost 6. Read the edges, sell the
## bottom of a bucket, keep the top of it.
##
## **AGE IS IN HERE ALREADY AND THAT IS WHY IT IS NOT A TERM.** A fighter's band
## is read off his CURRENT rating, and a rating falls as he ages — so the man you
## should have sold two seasons ago is in a lower bucket now and fetches less,
## without a line of code about age. Retro Bowl gets the same behaviour the same
## way: their value is by stars, and stars fall.
const SALE_SHARE: float = 0.45


static func sale_value(rating: int, tier: int) -> int:
	var low := mini(sale_tier(rating, tier) * 2, BAND_SHARE.size() - 1)
	var slack: int = int(League.TIERS[clampi(tier, 0,
		League.TIERS.size() - 1)]["slack"])
	var paid := int(round(SALE_SHARE * BAND_SHARE[low] * float(slack)))
	## AND NEVER AS MUCH AS HE COSTS, GUARANTEED HERE RATHER THAN TUNED.
	##
	## The share alone very nearly does it, and "very nearly" is how the first cut
	## shipped a printer. It also leaves the bottom band tied: `fee` floors at one
	## credit and so did this, so the cheapest man on any shelf could be bought
	## and sold for the same coin forever. **A rule that holds because two numbers
	## happen to land the right way round is a rule waiting for one of them to
	## move** — and both of these are tuning figures that will move.
	##
	## Floored at zero rather than one, which is the honest reading: nobody pays
	## for a man you could replace off the shelf for a single credit.
	return clampi(paid, 0, maxi(0, fee(rating, tier) - 1))


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
		## "STEP UP" IS A LIE AT THE TOP OF THE PYRAMID. There is no division above
		## National, so a man over its ceiling did not come from one — he came from
		## outside the world, and the card should say so. Derived from where he
		## stands rather than flagged on the object, so a foreign man who fades under
		## the ceiling stops reading as one, which is correct.
		Step.ABOVE:
			return "foreign" if tier >= League.TIERS.size() - 1 else "step up"
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
		var top_rung: bool = tier >= League.TIERS.size() - 1
		var target := 0
		if step > 0 and top_rung and rng.randf() < FOREIGN_CHANCE:
			## THE FOREIGN MAN. Drawn off the top of the National band rather than
			## out of a fifth division, because there is no fifth division — see
			## `FOREIGN_CHANCE`. One in four of the reach draws at the top rung, which
			## is roughly one name every three or four summers.
			target = int(lerpf(float(League.TIERS[tier]["power"][1]) + 1.0,
				float(FOREIGN_TOP), rng.randf()))
		else:
			var t := clampi(tier + step, 0, League.TIERS.size() - 1)
			var range_: Array = League.TIERS[t]["power"]
			target = int(lerpf(float(range_[0]) - 6.0, float(range_[1]) + 2.0,
				rng.randf()))
		var slot: int = rng.randi() % 5
		## AND THE STANDARD HE WAS REARED AGAINST, which is the top of the band he
		## was drawn FROM and not the one he is being sold into. This is the half of
		## the tiering that was missing: `roll_potential` read his AGE and nothing
		## else, so a raw twenty-two year old off a National shelf had exactly the
		## prospects of a raw twenty-two year old off a back field. The cheap man
		## from up the pyramid who becomes something your own division cannot produce
		## is the whole reason the pool reaches outside your band at all — see
		## `Career.STANDARD_ROOM`.
		var reared := int(League.TIERS[clampi(tier + step, 0,
			League.TIERS.size() - 1)]["power"][1])
		if step > 0 and top_rung:
			reared = FOREIGN_TOP
		var f := ClubFactory.free_agent(rng, slot, target, reared)
		out.append(f)
	## BEST FIRST, AND "BEST" IS WHAT HE WILL BE. A list a player has to sort
	## himself is a list he will misread once and then distrust — and a list
	## sorted on today's rating puts the finished 55 above the 54 who becomes a
	## 62, which is the misreading Pete named on 15 Sep. The card shows both
	## numbers; the ORDER should agree with the one that decides. See
	## `Career.worth`.
	out.sort_custom(func(a, b): return Career.worth(a) > Career.worth(b))
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
