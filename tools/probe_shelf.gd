extends SceneTree
## THE FREE-AGENT SHELF, AND WHETHER IT IS THE LADDER.
##
##   godot --headless --path . --script res://tools/probe_shelf.gd
##
## Pete, 15 Sep 2026: *"tier the free agents. Then there can be ranges for stats.
## A free agent won't bother being available if they aren't one league above or
## below the team's standing."* Built the same day. This is the measurement.
##
## THERE ARE THREE TIERINGS ON A FIGHTER AND THEY DO DIFFERENT JOBS, which is
## worth stating because "fighter tiers" could mean any of them:
##
##   THE DIVISION HE CAME FROM   new. `Market.pool` draws across the division
##                               below, your own, and the one above, so the stat
##                               range is `League.TIERS[t]["power"]` — 30-46,
##                               40-58, 52-70, 64-86 up the pyramid.
##   THE FEE BAND                older. Journeyman / Steady / Good / Strong /
##                               Star at 1 / 3 / 6 / 11 / 18 CC, measured against
##                               the division he is being signed INTO. A 61 and a
##                               68 in the same band cost the same, which is the
##                               seam Pete asked for in item 8.
##   HIS HARNESS                 older still. Borrowed / Serviceable / Fitted /
##                               Tournament — a tier on the KIT, not on the man.
##
## PART A asks what is actually on the shelf at each rung. PART B asks the only
## question that matters: **can a club buy its way up the pyramid, and is that a
## better road than training?** `probe_dev.gd` already measured training at +4
## club power for 245 levels; this puts the market next to it under one economy
## and one set of prices.
const SEASONS := 24
const SEEDS: Array[int] = [4242, 90210, 31337, 777, 24601]
const YEARS := 20
## WHAT A LEVEL-BUYING MANAGER KEEPS BACK ON TOP OF THE BILLS. Same figure
## `probe_run.gd` holds, and for the same reason: levels are cheap and always
## available, so a manager with no floor under them buys nothing else, ever.
const LEVEL_FLOAT := 25


func _initialize() -> void:
	_shelf()
	_climb()
	quit(0)


## ---------------------------------------------------------------- PART A
func _shelf() -> void:
	print("\n=== what is on the shelf, %d seasons a division ===\n" % SEASONS)
	print("%-19s %6s %6s %6s %7s %7s %7s %8s" % [
		"division", "best", "worst", "ceiling", "below", "own", "above", "affords"])
	for t in League.TIERS.size():
		var best := 0.0
		var worst := 0.0
		var ceil_ := 0.0
		var origin := [0, 0, 0]
		var carriable := 0
		var seen := 0
		var bands: Dictionary = {}
		var all: Array = []
		for season in range(1, SEASONS + 1):
			var pool: Array = Market.pool(4242, season, t)
			if pool.is_empty():
				continue
			for f in pool:
				all.append(f.overall())
			best += float(pool[0].overall())
			worst += float(pool[pool.size() - 1].overall())
			ceil_ += float(pool[0].potential)
			for f in pool:
				seen += 1
				origin[_origin(f.overall(), t)] += 1
				var bn := Market.band_name(f.overall(), t)
				bands[bn] = int(bands.get(bn, 0)) + 1
				if _can_carry(f, t):
					carriable += 1
		var n := float(SEASONS)
		## THE SPAN, which is what League.TIERS[t]["shelf"] records: the 2nd and
		## 98th percentile of every man the list showed, so one freak does not
		## set the scale.
		all.sort()
		if not all.is_empty():
			print("   span  min %d  p2 %d  p98 %d  max %d   (shelf now %s)" % [all[0],
				all[int(all.size() * 0.02)], all[int(all.size() * 0.98)], all[-1],
				str(League.TIERS[t]["shelf"])])
		print("%-19s %6.1f %6.1f %6.1f %6.0f%% %6.0f%% %6.0f%% %7.0f%%" % [
			League.tier_name(t), best / n, worst / n, ceil_ / n,
			100.0 * float(origin[0]) / float(maxi(1, seen)),
			100.0 * float(origin[1]) / float(maxi(1, seen)),
			100.0 * float(origin[2]) / float(maxi(1, seen)),
			100.0 * float(carriable) / float(maxi(1, seen))])
		var line: Array[String] = []
		for b in Market.BAND_NAME:
			var share := 100.0 * float(bands.get(b, 0)) / float(maxi(1, seen))
			## The Marquee band is meant to be rare and at three rungs of four it
			## is the stretch man rather than the foreigner, so it prints to one
			## decimal — "0%" and "one every four summers" are different answers.
			line.append("%s %.1f%%" % [b, share])
		print("      fee bands: " + "  ·  ".join(line))
	print("")
	print("below/own/above  which division's power band the man was generated in")
	print("affords          his fee fits inside League.TIERS[t][\"slack\"] — what a")
	print("                 season at that rung actually leaves for the squad, as")
	print("                 measured by probe_wallet — AND his wage fits under the")
	print("                 cap beside twelve ordinary men")
	print("")


## WHICH OF THE THREE BANDS HIS RATING FALLS IN. Read off the rating rather than
## remembered at generation, because that is what a player can see — and because
## a man generated in the band above who came out at the bottom of it really is
## an own-division signing however he was made.
func _origin(rating: int, tier: int) -> int:
	var own: Array = League.TIERS[tier]["power"]
	if rating < int(own[0]):
		return 0
	if rating > int(own[1]):
		return 2
	return 1


## CAN A CLUB AT THIS RUNG ACTUALLY TAKE HIM? Both prices, because the market
## refuses two different ways and a check that only asks about credits is
## measuring half the shelf.
func _can_carry(f: FighterCard, tier: int) -> bool:
	var fee := Market.fee(f.overall(), tier)
	## WHAT THE DIVISION ACTUALLY LEAVES HIM. This was a flat `fee > 20` — "a
	## club has about twenty credits of slack" — which was true of the Backyard
	## Circuit and wrong by a factor of four at National, and it is half the
	## reason `carriable` came back at 97-100% everywhere. `probe_wallet.gd`
	## measured the real figure per rung; it lives in `League.TIERS`.
	if fee > int(League.TIERS[tier]["slack"]):
		return false
	var o := ClubOffice.new()
	o.tier = tier
	## TWELVE ORDINARY MEN OF THAT DIVISION beside him, so the cap question is
	## asked about a real squad rather than about an empty one.
	var mid := int(lerpf(float(League.TIERS[tier]["power"][0]),
		float(League.TIERS[tier]["power"][1]), 0.5))
	var ordinary := FighterCard.new()
	ordinary.strength = mid
	ordinary.base = mid
	ordinary.skill = mid
	ordinary.gas = mid
	ordinary.aggression = mid
	ordinary.age = 26
	var bill := ClubOffice.wage(ordinary) * 12
	return bill + Contracts.offer(ClubOffice.wage(f), f.age) <= o.cap()


## ---------------------------------------------------------------- PART B
## THREE MANAGERS, ONE ECONOMY, TWENTY SEASONS.
##
## The only difference between them is where the money goes. Everything else —
## contracts, kit, the ground, the promotion choice — is identical, so the
## columns are comparable and the difference is the policy rather than the luck.
func _climb() -> void:
	print("=== three managers, %d seasons, spending only what they earn ===\n" % YEARS)
	print("%-10s %6s %7s %7s %7s %7s %7s %7s" % [
		"policy", "TOP", "up", "power", "gap", "signed", "bought", "placed"])
	for policy in ["train", "sign", "both"]:
		_run(String(policy))
	print("")
	print("TOP     highest division reached (0 Backyard, 3 National), mean of %d careers"
		% SEEDS.size())
	print("up      promotions taken across the career")
	print("power   club rating at the end")
	print("gap     that rating minus the division leader's")
	print("signed  men taken off the shelf")
	print("bought  levels PAID for with credits — the only column the policy moves")
	print("placed  levels the squad EARNED by fighting; free, so all three place them")
	print("")


## THE POLICY IS WHERE THE MONEY GOES AND NOTHING ELSE.
##
## The first cut of this function had `sign` and `both` come back BYTE
## IDENTICAL, which under this project's own rule — *a column that matches
## another column exactly is not a result, it is a bug report* — meant the
## fixture and not the finding. The cause: placing a man's EARNED levels is
## free, so every policy did it, and no policy anywhere spent credits on
## `buy_level()`. `both` was `sign` with a longer name.
##
## So the two spends are now named separately and gated separately:
##
##   train   buys levels with credits, never signs
##   sign    signs off the shelf, never buys a level
##   both    does both, market first, levels out of what is left
##
## Placing an EARNED level stays unconditional in all three, because it is free
## and there is no manager who leaves those sitting — it is not a policy, it is
## the floor. `bought` counts only the levels that were PAID for, which is the
## column the three managers can actually differ in.
func _run(policy: String) -> void:
	var tops := 0.0
	var ups := 0.0
	var power := 0.0
	var gaps := 0.0
	var signed := 0.0
	var levels := 0.0
	var bought := 0.0
	for seed_v in SEEDS:
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		Session.season = s
		var top := 0
		var was := s.world.player_tier()
		for y in YEARS:
			## THE WINTER: contracts always, then the policy.
			for f in s.club.roster:
				if Contracts.can_extend(f):
					s.extend(f)
				else:
					s.resign(f)
			for f in s.club.roster:
				levels += float(_place(f))
			if policy != "train":
				signed += float(_market(s))
			## AND PICK THE LINE. Roster order is the depth chart — see
			## `MeleeClub.best_line`. Without this a policy signs better men and
			## never plays them, which is what every earlier run of this probe
			## was measuring.
			s.club.best_line()
			bought += float(_season(s, policy))
			s.roll_over()
			var now := s.world.player_tier()
			if now > was:
				ups += 1.0
			was = now
			top = maxi(top, now)
		tops += float(top)
		power += float(s.club.power())
		gaps += float(_gap(s))
	var n := float(SEEDS.size())
	print("%-10s %6.1f %7.1f %7.1f %7.1f %7.1f %7.1f %7.1f" % [
		policy, tops / n, ups / n, power / n, gaps / n, signed / n,
		bought / n, levels / n])


## THE SEASON, week by week. Returns how many levels were PAID for, so the
## caller can report the one number the policy actually moves.
func _season(s: Season, policy: String) -> int:
	var bought := 0
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
					var t: Dictionary = s.promotion_terms()
					s.answer_promotion(s.office.credits >= int(t["dues_up"]) + 12)
		if s.season_complete():
			break
		var o := s.office
		## The kit, worst first — a man under the line cannot go out at all, and
		## that is worth more than any other credit on the list.
		var men: Array = s.club.roster.duplicate()
		men.sort_custom(func(a, b): return a.armor < b.armor)
		for f in men:
			if o.credits < 3:
				break
			o.repair_kit(f)
		if o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
			o.tidy_arena()
		var keep := o.upkeep_bill() + League.dues_for(o.tier) + 8
		if o.credits > keep + o.arena.next_cost():
			o.build_arena()
		## AND THE LEVELS, out of what the week did not need. Cheapest man first,
		## because `level_cost` scales with the level he is already on and a
		## manager buying reps buys the affordable ones. The throttle is per week
		## per man, so a five-event season is five chances at each of them.
		##
		## `_place_all` immediately after the buy, and this ordering is not
		## cosmetic: `buy_level()` REFUSES a man who already has a level waiting,
		## so a loop that buys twice without placing loses the second one.
		if policy != "sign" and o.credits > keep + LEVEL_FLOAT:
			var by_cost: Array = s.club.roster.duplicate()
			by_cost.sort_custom(func(a, b):
				return Career.level_cost(a) < Career.level_cost(b))
			for f in by_cost:
				if o.credits <= keep + LEVEL_FLOAT:
					break
				if o.buy_level(f) == "":
					bought += 1
					_place(f)
		s.skip_event()
	return bought


## Spend every point a man has waiting. Free, and nobody leaves them sitting.
static func _place(f: FighterCard) -> int:
	var n := 0
	var guard := 0
	while Career.can_level(f) and not Career.at_ceiling(f) and guard < 6:
		guard += 1
		Career.level_up(f)
		n += 1
	return n


## THE MARKET, the way a player works it: the best man who is better than your
## weakest starter and who the club can both pay for and carry.
func _market(s: Season) -> int:
	var took := 0
	var guard := 0
	while guard < 5:
		guard += 1
		var pool: Array = s.market()
		if pool.is_empty():
			break
		## READ ON WHAT HE WILL BE, NOT WHAT HE IS. Pete, 15 Sep 2026: *"I may
		## have a guy with a power of 55 maxed, but there's a guy for signing
		## that's starting at 54 with a max of 60s."* Sorting the shelf by
		## `overall()` takes the finished man every time, so every career this
		## probe has ever reported was played by a manager making that mistake
		## six times a summer. `Career.worth` is the same comparison a player
		## makes when he reads the two numbers on the card.
		pool.sort_custom(func(a, b): return Career.worth(a) > Career.worth(b))
		var five: Array = s.club.starting_five()
		var lo := 999
		for c in five:
			lo = mini(lo, Career.worth(c))
		var keep := s.office.upkeep_bill() + League.dues_for(s.office.tier) + 8
		var hit := false
		for f in pool:
			if s.office.credits <= keep + s.market_fee(f):
				continue
			if s.club.roster.size() >= 13 and Career.worth(f) <= lo + 1:
				continue
			_make_room(s, f)
			if s.sign_from_market(f) != "":
				continue
			took += 1
			hit = true
			break
		if not hit:
			break
	return took


func _make_room(s: Season, want: FighterCard) -> void:
	var guard := 0
	while guard < 8 and s.club.roster.size() > 6:
		guard += 1
		var over: bool = ClubOffice.wage_bill(s.club) + s.market_wage(want) \
			> s.office.cap()
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
			elif not over and Career.worth(c) < Career.worth(go):
				go = c
		if go == null or s.release(go) != "":
			return


func _gap(s: Season) -> int:
	var tbl: Array = s.world.table(s.world.player_tier())
	if tbl.is_empty():
		return 0
	var top := int(s.world.clubs[int(tbl[0]["club"])]["power"])
	return int(s.world.clubs[s.world.player_club]["power"]) - top
