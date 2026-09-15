extends SceneTree
## WHERE DO THE SOFT GATES ACTUALLY LAND?
##
## Pete, 10 Sep 2026: *"Notoriety has gates also. 25 notoriety at backyard is
## pretty great, 50 at state, 75 at regionals, 125 at Nationals/worlds."* — and
## he chose SOFT gates: nothing refuses to climb, the climb just runs out of
## fuel, because the things that raise notoriety are not available low down.
##
## THE QUESTION IS AN EQUILIBRIUM, NOT A JOURNEY. The first two versions of this
## probe followed a club up the pyramid and both answered "it reaches 125", which
## is true of any club that gets to the National Division and tells you nothing
## about the gates. What "25 at Backyard is pretty great" means is: **a good club
## that STAYS in the Backyard Circuit settles around 25.** So that is what this
## measures — each division held, for twelve seasons, at three standards of club.
##
## Each summer notoriety becomes `(N + G) x DECAY`, so it settles at
## `G x DECAY / (1 - DECAY)`. The numbers in ClubOffice are solved from that; this
## checks the solution against the sim rather than against the algebra.

const YEARS := 12


func _initialize() -> void:
	print("\nWhere notoriety settles, by division and standard of club")
	print("(a club held in its division for %d seasons, hosting every year)\n" % YEARS)
	print("division            club          notoriety   turnout    fans      cap   heads")
	for t in League.TIERS.size():
		for standard in [["title-winning", 1.0], ["good", 0.62], ["mid-table", 0.35]]:
			_settle(t, String(standard[0]), float(standard[1]))
		print("")
	print("Pete's gates: 25 Backyard, 50 State, 75 Regional, 125 National.\n")
	quit(0)


func _settle(tier: int, label: String, standard: float) -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242 + tier)
	var band: Array = League.TIERS[tier]["power"]
	## The ground you would have in that division, built out as far as the league
	## lets you — the arena and the notoriety climb together, so measuring one
	## with the other left at zero measures nothing anybody will ever see.
	s.office.tier = tier
	while s.office.arena.can_build(tier, 999) == "":
		s.office.arena.level += 1

	for year in YEARS:
		## HELD IN THE DIVISION. Promotion is what this probe is controlling for:
		## the question is where a club settles while it stays put.
		_place(s, tier)
		_standard(s, band, standard)
		var guard := 0
		while not s.ready_to_roll() and guard < 80:
			guard += 1
			if s.bid_open():
				s.office.credits += 60
				if s.take_bid(2, 1) != "":
					s.decline_bid()
			elif s.cup_pending():
				s.sim_cup_tie()
			else:
				s.skip_event()
		s.roll_over()

	_place(s, tier)
	var o := s.office
	var heads := ClubEvent.attendance(o.arena.capacity(), o.fans, o.notoriety, 1.0)
	print("%-18s  %-12s  %8.1f   %5d%%  %7d  %7d %7d" % [
		String(League.TIERS[tier]["name"]), label, o.notoriety,
		int(round(o.turnout() * 100.0)), int(o.fans), o.arena.capacity(), heads])


## Put the club back in the division under test and rebuild that year's fixtures
## around it, so a promotion or a relegation does not end the measurement.
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


## Set the club and its rivals so it finishes roughly where `standard` says: 1.0
## wins the division, 0.35 is mid-table.
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
