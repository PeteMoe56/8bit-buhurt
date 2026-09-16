class_name ProbeManager
extends RefCounted
## THE MANAGER EVERY CAREER PROBE PLAYS, in one place.
##
## Pete, 15 Sep 2026: *"I want... a reusable toolbox to pull from rather than
## ad-hoc effort each round."* This is that for the career probes. It was living
## inside `tools/probe_pace.gd` and `tools/probe_shelf.gd` and `tools/probe_run.gd`
## as three drifting copies of the same policy — and a shared manager matters more
## than usual here, because the balance sweeps compare runs against each other.
## **Two probes with slightly different managers do not produce comparable
## numbers, they produce an argument.**
##
## The policy is the obvious moves in the obvious order, which is what a competent
## player does. Everything it knows was learned the hard way and the comments say
## which measurement taught it:
##
##   the line     `best_line()` every winter, because roster order IS the depth
##                chart and a signing lands at the end of it
##   the shelf    read on `Career.worth` — seasons of a rating, not a rating
##   the staff    two captains, best grade affordable, covering different roles
##   promotion    the summer after going up is not an ordinary summer
##   the week     kit worst-first, the ground when it is visibly going, a paid
##                session, the cap, then ceilings out of the true surplus
## Which manager this is. `false` values a man on what he gives over the next six
## years; `true` values what he will BE and lets the club wait for it. See
## `value()` — the gap between the two lines is what skill is worth in this game.
var youth: bool = false
var was_tier: int = -1
var raised: int = 0
## Named so a sweep can hold the WEEKLY reserves still while it moves something
## else; they were bare numbers in three probes and two of them disagreed.
const KITTY := 20
const LEVEL_FLOAT := 25
func winter(s: Season) -> int:
	var now := s.world.player_tier()
	var went_up: bool = was_tier >= 0 and now > was_tier
	was_tier = now
	for f in s.club.roster:
		if Contracts.can_extend(f):
			s.extend(f)
		else:
			s.resign(f)
	var took := market(s, went_up)
	staff(s)
	for f in s.club.roster:
		place_all(f)
	## AND PUT THE BEST MEN ON THE LINE. Roster order is the depth chart and a
	## signing lands at the END of it, so a manager who does not do this signs
	## better men and never plays them — see `MeleeClub.best_line`.
	s.club.best_line()
	return took



## THE MARKET, THE WAY A PLAYER WITH MONEY WORKS IT.
##
## The pool is six men and it is FIXED for the summer, so a loop that reads it
## five times reads the same six men five times. That is why `probe_pace`
## measured a club sitting on sixty-five credits it never spent: it was not
## refusing to buy, it had nothing on the board worth buying and no way to ask
## for a different board.
##
## `ClubOffice.refresh_market` is three credits. A club with real money turns the
## list over until something on it is a clear upgrade — that is what the button
## is FOR, and a manager who never presses it is a manager whose surplus does
## nothing. Bounded, because a probe that spins is a probe that hangs.
const LOOKS := 14
func market(s: Season, went_up: bool = false) -> int:
	var took := 0
	var guard := 0
	while guard < LOOKS:
		guard += 1
		var pool: Array = s.market()
		if pool.is_empty():
			return took
		pool.sort_custom(func(a, b): return value(a) > value(b))
		var lo := 999
		for c in s.club.starting_five():
			lo = mini(lo, value(c))
		## AND AFTER A PROMOTION THE BAR IS THE NEW DIVISION, not the old squad.
		## A man who beats your weakest starter is an upgrade on a club that has
		## just been outclassed; the question in this summer is whether he can
		## hold a place in the company you have joined.
		if went_up:
			lo = maxi(lo, int(League.TIERS[s.world.player_tier()]["power"][0]))
		var keep := s.office.upkeep_bill() + League.dues_for(s.office.tier) \
			+ (0 if went_up else 8)
		var hit := false
		for f in pool:
			if s.office.credits <= keep + s.market_fee(f):
				continue
			if s.club.roster.size() >= 13 and value(f) <= lo + 1:
				continue
			make_room(s, f)
			if s.sign_from_market(f) != "":
				continue
			took += 1
			hit = true
			break
		if not hit:
			if s.office.credits > keep + ClubOffice.REFRESH_COST * 4 \
					and s.office.refresh_market() == "":
				continue
			return took
		## AND AFTER A SIGNING, LOOK AGAIN — at a NEW list. The man just taken is
		## gone from the old one and the rest of it has already been judged, so
		## re-reading it is the same refusal twice. A club that can still afford a
		## second signing should be shown a second shelf.
		if s.office.credits > keep + ClubOffice.REFRESH_COST * 6:
			s.office.refresh_market()
	return took


## THE CAPTAINS, WHICH THIS PROBE DID NOT HIRE FOR TWENTY SEASONS.
##
## Pete's practice week — *"the better the coaches, the more you get out of
## practice"* — is a staff investment, and `ClubOffice.coaching()` returns 0 for
## a club with nobody on the payroll. So the first run after the practice was
## built measured a club that develops nobody and reported almost no change: the
## manager was doing none of the one thing the new system is entirely about.
## **A probe that does not use a system is not a measurement of that system.**
##
## Two captains, best grade the club can afford, covering different roles — five
## to seventeen credits each against a season's sixteen at the bottom, so it is a
## real early-career decision and not free.
func staff(s: Season) -> void:
	var o := s.office
	while o.captains.size() < ClubOffice.MAX_CAPTAINS:
		var best: Dictionary = {}
		for slot in 4:
			var c := ClubOffice.offer(s.seed_value, s.world.season, slot)
			if ClubOffice.cost_of(c) > o.credits - League.dues_for(o.tier):
				continue
			## Prefer the man who teaches something nobody here teaches. A second
			## captain doubled onto the first one's roles leaves a third of the
			## squad with no coaching at all, which is the shape of squad this
			## probe spent twenty seasons proving does not develop.
			var fresh := 0
			for r in ClubOffice.specialties_of(c):
				if not o.taught(int(r)):
					fresh += 1
			var score: int = int(c.get("grade", 1)) + fresh * 3
			if best.is_empty() or score > int(best.get("score", -1)):
				best = {"cap": c, "score": score}
		if best.is_empty() or o.hire(Dictionary(best["cap"])) != "":
			return


## WHAT A MAN IS WORTH TO THIS MANAGER. The competent one asks what he gives
## over the next six years; the youth one asks what he will BE and lets the club
## wait for it — which is the whole difference between the two careers below.
func value(f: FighterCard) -> int:
	return Career.projected(f) if youth else Career.worth(f)


func make_room(s: Season, want: FighterCard) -> void:
	var guard := 0
	while guard < 8 and s.club.roster.size() > 6:
		guard += 1
		var over: bool = ClubOffice.wage_bill(s.club) + s.market_wage(want) > s.office.cap()
		var full: bool = s.club.roster.size() >= 13
		if not over and not full:
			return
		var five: Array = s.club.starting_five()
		var go: FighterCard = null
		for c in s.club.roster:
			if five.has(c) and not over:
				continue
			if go == null:
				go = c
			elif over and ClubOffice.billed(c) > ClubOffice.billed(go):
				go = c
			elif not over and value(c) < value(go):
				go = c
		## AND THE SALE FUNDS THE SIGNING. `Season.release` pays now — see
		## `Market.trade_value` — so cutting the man the club has outgrown is part of
		## how it affords the man it wants, which is the whole of Pete's *"if they're
		## holding onto Tier one fighters, they're wrong"*. The order is already
		## right and it matters: room is made BEFORE `sign_from_market` is called, so
		## the credits are in hand when the fee is checked.
		if go == null or s.release(go) != "":
			return


func season(s: Season) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(0)
				"cup": s.sim_cup_tie()
				"promotion":
					var terms: Dictionary = s.promotion_terms()
					s.answer_promotion(s.office.credits >= int(terms["dues_up"]) + 12)
		if s.season_complete():
			break
		var o := s.office
		var men: Array = s.club.roster.duplicate()
		men.sort_custom(func(a, b): return a.armor < b.armor)
		for f in men:
			if o.credits < 3:
				break
			o.repair_kit(f)
		if o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
			o.tidy_arena()
		var keep := o.upkeep_bill() + League.dues_for(o.tier) + KITTY
		if o.credits > keep + o.arena.next_cost():
			o.build_arena()
		if o.credits > keep + LEVEL_FLOAT + o.cap_cost():
			o.raise_cap()
		## AND THE CEILINGS, out of what the week did not need. Youngest first,
		## because a point of ceiling on a man with ten seasons in front of him is
		## ten seasons of it and a point on a thirty-four-year-old is one — the
		## same reasoning `Career.worth` uses on the shelf, applied to the squad
		## already on the books.
		## THE EXTRA SESSION, FIRST OF THE WEEKLY SPENDS. Two to eight credits for
		## a full extra week's work on the whole squad is the best value in the
		## game and it is the one thing here that recurs, so it goes before the
		## ceilings rather than out of what they leave. Still behind the market's
		## reserve — a signing is worth more than any amount of training.
		if o.credits > keep + KITTY:
			s.run_session()

		## OUT OF THE TRUE SURPLUS, AND BEHIND THE MARKET.
		##
		## The first cut spent down to the bills here and the club got WORSE —
		## power slid 36.8 to 33 over twenty seasons, signings halved. This runs
		## every week and the market runs once a winter, so spending to the floor
		## here drained the bank before the shelf was ever looked at. A signing is
		## worth two to three club power and a ceiling point is worth a fifth of
		## one; the cheap thing that runs first eats the money for the dear thing
		## that runs later, every time. Same trap `probe_run` fell into with
		## facilities, same fix: hold the market's money back.
		if o.credits > keep + KITTY:
			var young: Array = s.club.roster.duplicate()
			young.sort_custom(func(a, b): return a.age < b.age)
			for f in young:
				if o.credits <= keep + KITTY:
					break
				if o.raise_ceiling(f) == "":
					raised += 1
		s.skip_event()


## Spend every point he has waiting. Free, and nobody leaves them sitting.
static func place_all(f: FighterCard) -> void:
	var g := 0
	while Career.can_level(f) and not Career.at_ceiling(f) and g < 8:
		g += 1
		Career.level_up(f)
