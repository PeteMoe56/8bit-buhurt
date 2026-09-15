extends SceneTree
## DOES THE MARKET CLOSE THE HOLE THE CAREER PROBE FOUND?
##
## tools/probe_career.gd measured a managed club sliding from 66 to 34 over
## twenty-five seasons, and a control with a simulated inflow climbing to 75. The
## conclusion was that the career arithmetic was sound and the missing piece was
## a market. This is the check on that conclusion, with the real market rather
## than a stand-in — and the honest version of the question, which is: does a
## club that USES the market hold, and does one that ignores it still fall?
##
## If both rows come out the same, the market is a screen rather than a system.
##
## It also measures the two things that decide whether the market is readable:
## whether the coarse fee bands actually create a seam worth finding, and whether
## a signing is affordable often enough to be a decision rather than a taunt.

const YEARS := 25


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the market ===\n")
	_bands()
	_run("ignores the market", false)
	_run("signs the best man it can afford", true)
	print("")
	quit(0)


## THE SEAM. The fee is charged by band, so within a band a better man costs the
## same — this prints how wide each band is in rating points, which is how much
## the seam is actually worth to a player who reads it.
func _bands() -> void:
	print("The signing fee is by BAND, so within a band a better man is free")
	print("division            band          ratings     fee")
	for t in League.TIERS.size():
		var range_: Array = League.TIERS[t]["power"]
		var lo := -1
		var last := -1
		for r in range(int(Market.shelf_of(t)[0]) - 2, Market.FOREIGN_TOP + 2):
			var b := Market.band_of(r, t)
			if b != last:
				if last >= 0:
					print("%-18s  %-12s  %3d-%3d %7d" % [
						String(League.TIERS[t]["name"]) if last == 0 else "",
						Market.BAND_NAME[last], lo, r - 1, Market.fee(lo, t)])
				lo = r
				last = b
		print("%-18s  %-12s  %3d-%3d %7d" % ["", Market.BAND_NAME[last], lo,
			Market.FOREIGN_TOP + 1, Market.fee(lo, t)])
		print("")


func _run(label: String, shops: bool) -> void:
	print("A club that %s, over %d seasons" % [label, YEARS])
	print("season  power  age   walked  signed  on offer  afforded  CC")
	var s := Season.new(MeleeRosters.starting_club(), 8675309)
	s.office.credits = 60
	s.office.facilities[ClubOffice.Facility.TRAINING] = 5
	s.office.hire(ClubOffice.captain("A", Tuning.Role.RAIL, Tuning.Role.FLANK))
	s.office.hire(ClubOffice.captain("B", Tuning.Role.CENTER, Tuning.Role.RAIL))
	var total_signed := 0
	var total_walked := 0
	var total_offered := 0
	var total_afford := 0

	for y in YEARS:
		while not s.ready_to_roll():
			if s.bid_open(): s.decline_bid()
			elif s.cup_pending(): s.sim_cup_tie()
			else: s.skip_event()
		s.roll_over()
		var w: Dictionary = s.last_winter
		total_walked += (w.get("walked", []) as Array).size()

		## RE-SIGN ANYBODY WORTH KEEPING, both rows. Letting the control row lose
		## men it could trivially have kept would make this a probe about forgetting
		## to press a button rather than about the market.
		for f in s.club.roster.duplicate():
			if f.years <= 0:
				s.resign(f)

		## RAISE THE CAP WHEN THERE IS NO ROOM TO SIGN. This is the Retro Bowl loop
		## in three lines — credits into cap, cap into fighters — and the first
		## run of this probe left it out, which is why a club ended a quarter of a
		## century with 1,100 credits it could not spend and a squad it could not
		## improve. The shopper is still crude; it just is not now pretending the
		## cap does not exist.
		if shops:
			var tries := 0
			while tries < 3 and s.office.credits >= s.office.cap_cost() \
					and ClubOffice.wage_bill(s.club) > int(float(s.office.cap()) * 0.82):
				tries += 1
				s.office.new_week()
				s.office.raise_cap()

		var offered := s.market().size()
		var afforded := 0
		var took := 0
		if shops:
			## The dumbest possible shopper: take the best man the club can
			## actually complete, once a summer. If a policy this crude closes the
			## gap, the market is doing the work rather than the policy.
			for f in s.market():
				if s.market_fee(f) <= s.office.credits \
						and ClubOffice.wage_bill(s.club) + s.market_wage(f) <= s.office.cap():
					afforded += 1
			for f in s.market():
				if f.overall() <= s.club.power():
					continue
				if s.sign_from_market(f) == "":
					took += 1
					break
		else:
			for f in s.market():
				if s.market_fee(f) <= s.office.credits \
						and ClubOffice.wage_bill(s.club) + s.market_wage(f) <= s.office.cap():
					afforded += 1
		total_signed += took
		total_offered += offered
		total_afford += afforded

		if y % 4 == 0 or y == YEARS - 1:
			print("%6d %6d %4.1f %8d %7d %9d %9d %4d" % [y + 1, s.club.power(),
				_mean_age(s), (w.get("walked", []) as Array).size(), took,
				offered, afforded, s.office.credits])

	print("\n  ended at power %d, squad of %d, average age %.1f"
		% [s.club.power(), s.club.roster.size(), _mean_age(s)])
	print("  %d walked, %d signed; %d%% of everyone on offer was affordable\n"
		% [total_walked, total_signed,
			int(round(100.0 * float(total_afford) / float(maxi(1, total_offered))))])


static func _mean_age(s: Season) -> float:
	var t := 0.0
	for f in s.club.roster:
		t += float(f.age)
	return t / float(maxi(1, s.club.roster.size()))
