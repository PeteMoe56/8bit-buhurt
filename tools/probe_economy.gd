extends SceneTree
## WHAT DOES A YEAR PAY, AND WHAT DOES A YEAR COST?
##
## The banding (10 Sep 2026) made notoriety reach the wallet every fight instead
## of once a summer, which is a large change to the only currency in the game. A
## change like that is not something to eyeball: this measures a season's income
## in each division at three standards of club, and puts it next to the two
## things a player is actually saving for.
##
## THE QUESTION IS "HOW MANY SEASONS IS THE NEXT GROUND", not "is the number
## big". The whole arena ladder costs 138 CC and its steps are 6, 12, 22, 38, 60.
## If a division pays for its own next step in one year the sink is decorative;
## if it takes fifteen the climb is the game and nothing else gets bought. Two to
## four is the band worth landing in, and it has to hold at BOTH ends — the
## mid-table club is the one who finds out whether the floor is survivable.
##
## Income is counted by watching the balance rather than by adding up the
## constants, because the constants are exactly what is being questioned.

const YEARS := 12
## THREE SEED BASES, because this probe has already been read once as evidence
## and a one-seed read of a four-year window is exactly the sample size that
## lies. The first run had a mid-table Backyard club out-earning a title-winning
## one, which is not a finding, it is noise.
const BASES: Array[int] = [4242, 90210, 31337]


func _initialize() -> void:
	print("\nWhat a season pays, by division and standard of club")
	print("(held in division, hosting a Proper show every year, %d-year average)\n" % YEARS)
	print("division            club          notoriety band  pay/fight   upkeep   net CC/season   this ground   years")
	for t in League.TIERS.size():
		for standard in [["title-winning", 1.0], ["good", 0.62], ["mid-table", 0.35]]:
			_settle(t, String(standard[0]), float(standard[1]))
		print("")
	print("The ladder: Club gym 6, Fenced ground 12, Sports hall 22, Arena 38, National 60 CC.\n")
	quit(0)


func _settle(tier: int, label: String, standard: float) -> void:
	var pay: Array[float] = []
	var note: Array[float] = []
	var bands: Array[int] = []
	var keep: Array[float] = []
	var ground: int = 0
	for base in BASES:
		var r: Array = _one(tier, standard, base + tier)
		pay.append(float(r[0]))
		note.append(float(r[1]))
		bands.append(int(r[2]))
		ground = int(r[3])
		keep.append(float(r[4]))
	var per_year: float = _mean(pay)
	var years: String = "—" if ground <= 0 or per_year <= 0.0 \
		else "%.1f" % (float(ground) / per_year)
	var b: int = bands[bands.size() / 2]
	print("%-18s  %-12s  %8.1f %4d %9d %8d %15.1f %13s %7s" % [
		String(League.TIERS[tier]["name"]), label, _mean(note), b,
		ClubOffice.CROWD_PAY[b], int(_mean(keep)), per_year, str(ground), years])


static func _mean(a: Array[float]) -> float:
	var t: float = 0.0
	for x in a:
		t += x
	return t / float(maxi(1, a.size()))


func _one(tier: int, standard: float, seed_v: int) -> Array:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	var band: Array = League.TIERS[tier]["power"]
	s.office.tier = tier
	while s.office.arena.can_build(tier, 999) == "":
		s.office.arena.level += 1

	var earned: int = 0
	var years_counted: int = 0
	for year in YEARS:
		_place(s, tier)
		_standard(s, band, standard)
		## A settling period: notoriety and fans start at nothing and the first
		## few years are the climb, not the steady state. Only the back half is
		## counted, which is the same reason probe_notoriety runs twelve.
		var counting: bool = year >= YEARS / 2
		var before: int = s.office.credits
		var topped: int = 0
		var guard := 0
		while not s.ready_to_roll() and guard < 80:
			guard += 1
			if s.bid_open():
				## The bid is a COST, and it has to be counted as one or hosting
				## looks like free money. Topped up first so a poor club can
				## still afford to host — otherwise the mid-table row measures
				## "could not pay the entry fee" rather than "earns this much".
				s.office.credits += 200
				topped += 200
				if s.take_bid(2, 1) != "":
					s.decline_bid()
			elif s.cup_pending():
				s.sim_cup_tie()
			else:
				s.skip_event()
		s.roll_over()
		if counting:
			## Balance at the end, minus where it started, minus the money that
			## was handed over rather than won. Whatever the bid and the budget
			## cost came out of the balance on the way, so they are netted off
			## without being counted twice.
			earned += s.office.credits - before - topped
			years_counted += 1

	_place(s, tier)
	var o := s.office
	var per_year: float = float(earned) / float(maxi(1, years_counted))
	## THE GROUND THIS DIVISION IS SAVING FOR is the one it just built, not the
	## one after it — the next one up is gated behind a promotion, so pricing the
	## division against it would be measuring the wrong wall.
	return [per_year, o.notoriety, o.crowd_band(),
		int(Arena.LEVELS[o.arena.level]["cost"]), float(o.upkeep_bill())]


func _place(s: Season, tier: int) -> void:
	var me: int = s.world.player_club
	if int(s.world.clubs[me]["tier"]) != tier:
		for other in s.world.clubs:
			if int(other["tier"]) == tier and int(other["id"]) != me:
				other["tier"] = int(s.world.clubs[me]["tier"])
				break
		s.world.clubs[me]["tier"] = tier
		s.world._new_season()
	s.office.tier = tier


func _standard(s: Season, band: Array, standard: float) -> void:
	var want := int(lerpf(float(band[0]), float(band[1]), 0.45 + 0.5 * standard))
	var guard := 0
	while s.club.power() < want and guard < 400:
		guard += 1
		for f in s.club.roster:
			f.strength = mini(99, f.strength + 1)
			f.base = mini(99, f.base + 1)
			f.skill = mini(99, f.skill + 1)
			f.gas = mini(99, f.gas + 1)
	s.sync_power()
	for i in s.world.clubs.size():
		if i == s.world.player_club:
			continue
		var b: Array = League.TIERS[int(s.world.clubs[i]["tier"])]["power"]
		s.world.clubs[i]["power"] = int(lerpf(float(b[0]), float(b[1]), 0.5))
