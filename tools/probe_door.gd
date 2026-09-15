extends SceneTree
## WHO GOES OUT OF THE DOOR, WHY, AND WHAT COMES IN AFTER HIM.
##
##   godot --headless --path . --script res://tools/probe_door.gd
##
## `tools/probe_ledger.gd` established that a career club does not decline
## through ageing — ageing, the training ground and bout XP roughly cancel — it
## declines because men LEAVE and what replaces them is worse. Every season that
## moved the club was a season with a departure in it: -3, -8, -19, -28, -36, and
## -106 the year a breakaway took half the squad.
##
## That is a cause with three sources and they want different answers, so this
## separates them: RETIREMENT, a man out of contract who WALKED, and the SPLIT.
## And for each one it prints what the club got back, because "worse than what
## left" is the claim and a claim wants a number.
const SEASONS := 12

func _init() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	print("\n=== the door, %d seasons ===\n" % SEASONS)
	for year in SEASONS:
		for f in s.club.roster:
			if f.years <= 0:
				s.resign(f)
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
		s.sync_power()
		var g := 0
		while not s.season_complete() and g < 40:
			g += 1
			var sim := s.begin_bout()
			if sim == null:
				s.skip_event(); continue
			Session.season = s
			Session.bout = sim
			sim.run_to_end()
			s.post_bout(sim)
			Session.clear_bout()

		## THE ODDS EVERY OUT-OF-CONTRACT MAN IS ROLLING, before the summer takes
		## them. This is the number the club can do something about, in theory.
		var band_top: int = int(League.TIERS[s.world.player_tier()]["power"][1])
		var risky: Array[String] = []
		for f in s.club.roster:
			if f.years > 0:
				continue
			var p := Contracts.will_wait(f, s.office.notoriety, band_top, s.office.morale)
			risky.append("%s(%d) %.0f%%" % [f.display_name, f.overall(), p * 100.0])

		var before := {}
		for f in s.club.roster:
			before[f] = f.overall()
		s.roll_over()
		var w: Dictionary = s.last_winter
		var out_r := 0
		var out_w := 0
		for f in before:
			if not s.club.roster.has(f):
				## Named in `retired` or not — the winter reports both lists.
				var nm := String(f.display_name)
				var was_retired := false
				for r in w.get("retired", []):
					if String(r).begins_with(nm):
						was_retired = true
						break
				if was_retired:
					out_r += int(before[f])
				else:
					out_w += int(before[f])
		var came := 0
		var arrivals: Array[String] = []
		for f in s.club.roster:
			if not before.has(f):
				came += f.overall()
				arrivals.append("%s(%d)" % [f.display_name, f.overall()])
		print("s%-3d retired %2d men worth %3d · walked %3d · signed back %3d  |  net %+4d  club %2d  note %.0f"
			% [year + 1, w.get("retired", []).size(), out_r, out_w, came,
				came - out_r - out_w, s.club.power(), s.office.notoriety])
		if not risky.is_empty():
			print("      out of contract, odds of staying: %s" % ", ".join(risky))
		if not arrivals.is_empty():
			print("      in: %s" % ", ".join(arrivals))
	print("")
	quit()
