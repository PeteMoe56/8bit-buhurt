extends SceneTree
## THE DEVELOPMENT LEDGER: what a season TAKES off a club against what it GIVES.
##
##   godot --headless --path . --script res://tools/probe_ledger.gd
##
## Twenty-season walks say the player's rating falls about half a point to a
## point a season while every CPU club is pulled to its division's midpoint and
## held there. That is the whole reason a career club wins 17.4% of its bouts,
## and `tools/probe_fair.gd` has ruled out the melee — two identical clubs split
## 53/47, so the fight is even and the problem is the club.
##
## This counts the two sides of the ledger separately, per season, so the lever
## is a number rather than a guess: stat points LOST to ageing and to men
## leaving, against stat points GAINED from the training ground, from bout XP
## spent on levels, and from whoever the club signed.
const SEASONS := 12

func _init() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	print("\n=== the development ledger, %d seasons ===\n" % SEASONS)
	print("     age-loss  ground  bout-XP  in-out  |  net  ·  club  eight-age  train")
	for year in SEASONS:
		## Buy what a sensible manager buys, so the ground is actually built.
		for pass_ in 3:
			s.office.new_week()
			if s.office.travel_slots < ClubOffice.TRAVEL_MAX and s.office.buy_travel_slot() == "":
				continue
			s.office.new_week()
			if s.office.upgrade(ClubOffice.Facility.TRAINING) == "":
				continue
			break
		while s.office.captains.size() < ClubOffice.MAX_CAPTAINS:
			var got := false
			for slot in 3:
				var c := ClubOffice.offer(31337, s.world.season, slot, 0)
				if not c.is_empty() and ClubOffice.cost_of(c) <= s.office.credits \
						and s.hire_captain(c) == "":
					got = true
					break
			if not got:
				break
		for f in s.club.roster:
			if f.years <= 0:
				s.resign(f)
		var g := 0
		while s.club.active_eight().size() < s.club.party_size() and g < 20:
			g += 1
			var up: FighterCard = null
			for f in s.club.reserves():
				if up == null or f.overall() > up.overall():
					up = f
			if up == null or s.club.set_active(up, true) != "":
				break
		s.sync_power()

		## A SNAPSHOT OF EVERY MAN BY NAME, so men who leave and men who arrive
		## can be told apart from men who simply got better or worse. A total
		## alone cannot: a club that loses a 45 and signs a 45 looks unchanged.
		var before := {}
		for f in s.club.roster:
			before[f] = f.overall()
		var pre_total := 0
		for f in s.club.roster:
			pre_total += f.overall()

		var xp_before := 0
		for f in s.club.roster:
			xp_before += f.overall()
		var guard := 0
		while not s.season_complete() and guard < 40:
			guard += 1
			var sim := s.begin_bout()
			if sim == null:
				s.skip_event()
				continue
			Session.season = s
			Session.bout = sim
			sim.run_to_end()
			s.post_bout(sim)
			Session.clear_bout()
		## Levels earned DURING the season are the bout-XP channel; the winter's
		## ground allocation lands inside `roll_over`.
		## AND NOW SPEND THEM, which is where the gain actually lands.
		##
		## The first version spent the levels at the TOP of the loop, before the
		## snapshot — so the improvement happened outside the window being
		## measured and the bout-XP column read zero for twelve seasons twice
		## over. The men were levelling; the probe was looking the other way.
		## Calder finished season one with 49 XP against a bar of 10, which is
		## four levels standing unspent, and the column said nothing was there.
		##
		## **A column of zeroes is a claim, and a claim wants checking against the
		## thing it is a claim about.**
		for f in s.club.roster:
			var lg := 0
			while Career.can_place(f) and lg < 10:
				lg += 1
				var opts: Array = Career.raisable(f)
				if opts.is_empty():
					break
				var pick: int = int(opts[0])
				var lowest := 999
				for st in opts:
					var v := Career.read_stat(f, int(st))
					if v < lowest:
						lowest = v
						pick = int(st)
				if not bool(Career.level_into(f, pick).get("levelled", false)):
					break
		var levels_in_season := 0
		for f in s.club.roster:
			levels_in_season += f.overall()
		levels_in_season -= xp_before

		var mid := {}
		for f in s.club.roster:
			mid[f] = f.overall()
		s.roll_over()

		## Now split the change three ways.
		var aged := 0
		var ground := 0
		var left := 0
		var joined := 0
		for f in s.club.roster:
			if mid.has(f):
				var d: int = f.overall() - int(mid[f])
				if d < 0:
					aged += d
				else:
					ground += d
			else:
				joined += f.overall()
		for f in mid:
			if not s.club.roster.has(f):
				left -= int(mid[f])
		var post_total := 0
		for f in s.club.roster:
			post_total += f.overall()
		var eight_age := 0
		var n := 0
		for f in s.club.active_eight():
			eight_age += f.age
			n += 1
		print("s%-3d %8d  %6d  %7d  %6d  | %+4d  ·  %4d  %9.1f  %5d"
			% [year + 1, aged, ground, levels_in_season, joined + left,
				post_total - pre_total, s.club.power(),
				0.0 if n == 0 else float(eight_age) / float(n),
				s.office.training_points()])
	print("")
	quit()
