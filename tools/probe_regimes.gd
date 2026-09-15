extends SceneTree
## WHAT A TRAINING REGIME IS ACTUALLY WORTH OVER A CAREER.
##
##   godot --headless --path . --script res://tools/probe_regimes.gd
##
## `set_regime` was never called by ANY tool in this project. Twenty-season
## career walks, three management policies, and every one of them ran the whole
## career on NORMAL — because `regime_for()` returns NORMAL for a role nobody
## teaches and nothing ever set anything else.
##
## That is not a small omission. The table is a four-way trade:
##
##     XP       Light 0.6   Normal 1.0   Hard 1.5
##     morale  +0.015        0.0        -0.020   a week
##     armour  +0.10         0.0        -0.10    a week
##     knocks   0.10         0.20        1.00    multiplier on a knock landing
##
## Hard is not "a bit riskier than Normal", it is **five times** riskier, and
## Light is the only thing in the game that puts condition BACK into a man's
## armour outside a dilemma card. So the regime is the development decision, the
## injury decision and the kit-maintenance decision, all on one control — and no
## measurement in this project had ever moved it.
const SEASONS := 20

func _run(regime: int) -> Array:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	var armour_first := 0.0
	for year in SEASONS:
		## The thrifty policy, which is the one that climbs: keep, build, staff,
		## then one signing. Trimmed to what matters here.
		for f in s.club.roster:
			if f.years <= 0:
				s.resign(f)
			elif f.years == 1 and Contracts.can_extend(f):
				s.extend(f)
		for pass_ in 3:
			s.office.new_week()
			if s.office.travel_slots < ClubOffice.TRAVEL_MAX and s.office.buy_travel_slot() == "":
				continue
			s.office.new_week()
			if s.office.upgrade(ClubOffice.Facility.TRAINING) == "":
				continue
			s.office.new_week()
			if s.office.upgrade(ClubOffice.Facility.INFIRMARY) == "":
				continue
			break
		while s.office.captains.size() < ClubOffice.MAX_CAPTAINS:
			var hired := false
			for slot in 3:
				var c := ClubOffice.offer(31337, s.world.season, slot, 0)
				if not c.is_empty() and ClubOffice.cost_of(c) <= s.office.credits \
						and s.hire_captain(c) == "":
					hired = true
					break
			if not hired:
				break
		## THE ONE LINE EVERY OTHER TOOL WAS MISSING.
		for i in s.office.captains.size():
			s.office.set_regime(i, regime)
		for f in s.market():
			if s.market_fee(f) <= s.office.credits and s.sign_from_market(f) == "":
				break
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
		if year == 0:
			armour_first = _armour(s)
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
			var t := 0
			while s.pending_cup() != null and t < 8:
				t += 1
				s.sim_cup_tie()
		s.roll_over()
	var knocks := 0
	var best := 0
	for f in s.club.roster:
		knocks += f.knocks
		best = maxi(best, f.overall())
	var fit := 0
	for f in s.club.roster:
		if f.fit():
			fit += 1
	return [s.club.power(), _armour(s), armour_first, knocks, best,
		s.world.player_tier(), s.office.morale, s.club.roster.size(), fit,
		s.club.starting_five().size(), s.office.credits]

func _armour(s: Season) -> float:
	var t := 0.0
	var n := 0
	for f in s.club.active_eight():
		t += f.armor
		n += 1
	return 0.0 if n == 0 else t / float(n)

func _init() -> void:
	print("\n=== twenty seasons on each regime, same club, same seed ===\n")
	print("%-8s  %5s  %7s  %7s  %5s  %9s  %6s  %s"
		% ["regime", "power", "armour", "knocks", "best", "fit/books", "line", "morale"])
	for r in [ClubOffice.Regime.LIGHT, ClubOffice.Regime.NORMAL, ClubOffice.Regime.HARD]:
		var out := _run(r)
		print("%-8s  %5d  %7.2f  %7d  %5d  %9s  %4d/5  %.2f"
			% [ClubOffice.REGIME_NAME[r], int(out[0]), float(out[1]),
				int(out[3]), int(out[4]),
				"%d/%d" % [int(out[8]), int(out[7])], int(out[9]), float(out[6])])
	print("")
	quit()
