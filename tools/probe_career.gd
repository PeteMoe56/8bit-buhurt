extends SceneTree
## WHAT DOES A CAREER LOOK LIKE?
##
## The career layer has four peak ages, a rising XP price, a ceiling, and a
## retirement roll, and every one of those numbers was chosen by argument rather
## than measurement. This plays twenty-five seasons and asks the three questions
## that decide whether any of it is worth having:
##
##   1. Does an old fighter become a DIFFERENT fighter rather than a worse one?
##      That is the whole design claim — hard to put down, technically the best
##      man on the field, and empty by the third round. If the four peaks just
##      average out into one slow slide, they are decoration.
##   2. Does a squad turn over at a rate a club can survive and cannot ignore?
##      Nobody retiring is a roster that ossifies; three a winter is a treadmill.
##   3. Does potential ever actually bind? A ceiling that nobody reaches is a
##      number on a screen; one everybody reaches by 24 is a second rating.

const YEARS := 25


func _initialize() -> void:
	print("\n=== Retro Buhurt — a career ===\n")
	_one_man()
	_turnover(0)
	_turnover(1)
	_turnover(2)
	_ceilings()
	print("")
	quit(0)


## A single fighter, aged from 20 to whenever he stops, with nothing else moving.
## Coached, fed an average season's XP, never injured — so what is on the screen
## is the CURVE and not a story about one club.
func _one_man() -> void:
	print("One fighter, coached, an average season's production every year")
	print("age   STR  BASE  SKL  GAS   ovr   pot   retire%")
	var f := FighterCard.new()
	f.age = 20
	f.strength = 58
	f.base = 55
	f.skill = 52
	f.gas = 66
	f.aggression = 55
	f.pos = Tuning.Pos.FLANK_L
	f.potential = 78
	var peak_at := {"str": 0, "base": 0, "skl": 0, "gas": 0}
	var best := {"str": 0, "base": 0, "skl": 0, "gas": 0}
	for _y in YEARS:
		f.xp += 30                      ## roughly a full season on the line
		Career.winter(f, true, 2)
		if f.strength > int(best["str"]):
			best["str"] = f.strength ; peak_at["str"] = f.age
		if f.base > int(best["base"]):
			best["base"] = f.base ; peak_at["base"] = f.age
		if f.skill > int(best["skl"]):
			best["skl"] = f.skill ; peak_at["skl"] = f.age
		if f.gas > int(best["gas"]):
			best["gas"] = f.gas ; peak_at["gas"] = f.age
		if f.age % 2 == 0 or f.age >= Career.RETIRE_FROM:
			print("%3d  %4d  %4d  %4d  %4d  %4d  %4d  %6d%%" % [f.age, f.strength,
				f.base, f.skill, f.gas, f.overall(), f.potential,
				int(round(Career.retire_chance(f) * 100.0))])
	print("\n  highest reached at:  strength %d   base %d   skill %d   gas %d"
		% [peak_at["str"], peak_at["base"], peak_at["skl"], peak_at["gas"]])
	print("  (the design says 28 / 32 / 35 / 24 — training can push a stat past")
	print("   its peak year, so these run late; what matters is the ORDER)\n")


## A whole club, played out. How many men leave a winter, and does the squad hold
## its rating while they do?
## mode 0 neglected, 1 managed, 2 managed with a market that does not exist yet.
##
## THE THIRD ROW IS THE POINT. A managed club still slides, and the obvious read
## is that the winter arithmetic is broken. It is not: the club has no way to
## SIGN anybody. Every man who retires is replaced by a walk-on drawn nine points
## under the division floor, because that is the only inflow this game currently
## has — the player market is phase three. Row 3 replaces retirees at the middle
## of the division band instead, which is what a market would make possible, and
## it is the control that says whether the career layer itself is sound.
func _turnover(mode: int) -> void:
	var names: Array[String] = ["NEGLECTED", "MANAGED",
		"MANAGED, with a market (phase 3, simulated)"]
	var label: String = names[mode]
	var managed: bool = mode >= 1
	print("A %s club over %d seasons — who leaves, and does the squad survive it"
		% [label, YEARS])
	print("season  age  power  retired  signed  walk-ons on the eight")
	## `starting_club()`, NOT `player_club()`. The latter is the melee fixture — a
	## hand-written club rating 65 whose job is to make seeded bouts reproduce —
	## and running a career on it means running a Regional-standard squad in a
	## division whose band tops out at 46, on a wage bill forty times its own cap.
	## The relative comparison below survived that; the absolute numbers did not.
	var s := Season.new(MeleeRosters.starting_club(), 8675309)
	if managed:
		## THE OTHER END OF THE SAME QUESTION. The neglected run converges on
		## replacement level, which is correct and is also the least interesting
		## thing the system does — it has no training ground, so `coached` is
		## false, every fighter's XP is never spent, and the club can only fall.
		## This one buys the two things that make a winter happen and then does
		## nothing else, so the difference on screen is the career layer working
		## rather than the player playing well.
		s.office.credits = 400
		s.office.facilities[ClubOffice.Facility.TRAINING] = 5
		## Two captains covering all three jobs, which is the arrangement the
		## staff screen tells the player to aim at.
		s.office.hire(ClubOffice.captain("A", Tuning.Role.RAIL, Tuning.Role.FLANK))
		s.office.hire(ClubOffice.captain("B", Tuning.Role.CENTER, Tuning.Role.RAIL))
	var total_retired := 0
	var total_signed := 0
	for y in YEARS:
		var guard := 0
		while not s.ready_to_roll() and guard < 80:
			guard += 1
			if s.bid_open():
				s.decline_bid()
			elif s.cup_pending():
				s.sim_cup_tie()
			else:
				s.skip_event()
		s.roll_over()
		if mode == 2:
			## Stand in for the market: anybody signed as a walk-on this winter is
			## re-rolled at the middle of the division. Nothing else changes.
			var band: Array = League.TIERS[s.world.player_tier()]["power"]
			var mid := int(lerpf(float(band[0]), float(band[1]), 0.5))
			for f in s.club.roster:
				if f.overall() < int(band[0]) - 4:
					var fresh := ClubFactory.walk_on(s.world.rng, int(f.pos),
						s.world.player_tier())
					var lift := mid - fresh.overall()
					f.strength = clampi(f.strength + lift, 1, 99)
					f.base = clampi(f.base + lift, 1, 99)
					f.skill = clampi(f.skill + lift, 1, 99)
					f.gas = clampi(f.gas + lift, 1, 99)
					f.potential = maxi(f.potential, f.overall() + 4)
			s.sync_power()
		var w: Dictionary = s.last_winter
		var gone: Array = w.get("retired", [])
		var took: Array = w.get("signed", [])
		total_retired += gone.size()
		total_signed += took.size()
		var ages := 0.0
		for f in s.club.roster:
			ages += float(f.age)
		if y % 3 == 0 or not gone.is_empty():
			print("%6d %4.1f %6d %8d %7d  %s" % [y + 1,
				ages / float(maxi(1, s.club.roster.size())), s.club.power(),
				gone.size(), took.size(),
				("" if gone.is_empty() else String(gone[0]))])
	print("\n  %d retired and %d walk-ons signed over %d seasons — %.1f and %.1f a winter"
		% [total_retired, total_signed, YEARS,
			float(total_retired) / float(YEARS), float(total_signed) / float(YEARS)])
	print("  squad of %d, average age %.1f, power %d at the end\n"
		% [s.club.roster.size(), _mean_age(s), s.club.power()])


static func _mean_age(s: Season) -> float:
	var t := 0.0
	for f in s.club.roster:
		t += float(f.age)
	return t / float(maxi(1, s.club.roster.size()))


## Does the ceiling bind? Counted across a generated country rather than one
## club, because the generator is what decides how much room a signing has.
func _ceilings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var at_ceiling := 0
	var room_total := 0
	var n := 0
	var by_age := {}
	for t in League.TIERS.size():
		for i in 12:
			var band: Array = League.TIERS[t]["power"]
			var c := ClubFactory.build(rng.randi(), "X", "X",
				int(lerpf(float(band[0]), float(band[1]), rng.randf())))
			for f in c.roster:
				n += 1
				room_total += f.headroom()
				if f.headroom() == 0:
					at_ceiling += 1
				var decade := int(f.age / 5) * 5
				var e: Array = by_age.get(decade, [0, 0])
				e[0] += 1
				e[1] += f.headroom()
				by_age[decade] = e
	print("Room in front of a generated fighter, by age (%d men across the country)" % n)
	var keys: Array = by_age.keys()
	keys.sort()
	for k in keys:
		var e: Array = by_age[k]
		print("  %d-%d   %4d men   %.1f points of room"
			% [int(k), int(k) + 4, int(e[0]), float(e[1]) / float(maxi(1, int(e[0])))])
	print("\n  %d%% are already at their ceiling; the average man has %.1f points left"
		% [int(round(100.0 * float(at_ceiling) / float(maxi(1, n)))),
			float(room_total) / float(maxi(1, n))])
