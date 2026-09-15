extends SceneTree
## WHERE THE MONEY GOES, BROKEN OUT.
##
##   godot --headless --path . --script res://tools/probe_purse.gd
##
## The soak can tell you the summer went cash-negative at season eight. It cannot
## tell you WHICH LINE did it, because `roll_over()` lands prize money, the gate,
## the dues and every bill inside one call and the balance simply pins at zero.
## This reads each component off the office before the roll-over and prints the
## ledger a club accountant would keep.
const SEASONS := 20

func _manage(s: Season) -> void:
	for pass_ in 3:
		s.office.new_week()
		if s.office.travel_slots < ClubOffice.TRAVEL_MAX and s.office.buy_travel_slot() == "":
			continue
		s.office.new_week()
		if s.office.upgrade(ClubOffice.Facility.INFIRMARY) == "":
			continue
		s.office.new_week()
		if s.office.upgrade(ClubOffice.Facility.TRAINING) == "":
			continue
		s.office.new_week()
		if s.office.build_arena() == "":
			continue
		s.office.new_week()
		var did := false
		for r in s.office.shortfalls().size():
			if s.office.raise_rule(r) == "":
				did = true
				break
		if did:
			continue
		break
	var guard := 0
	while s.club.active_eight().size() < s.club.party_size() and guard < 20:
		guard += 1
		var up: FighterCard = null
		for f in s.club.reserves():
			if up == null or f.overall() > up.overall():
				up = f
		if up == null or s.club.set_active(up, true) != "":
			break
	s.sync_power()

func _init() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	print("\n=== the purse, %d seasons ===" % SEASONS)
	print("     pos  prize  gate  dues | arena  fac   fed  = net   purse  fans  memb")
	for year in SEASONS:
		_manage(s)
		var g := 0
		while not s.season_complete() and g < 40:
			g += 1
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
		## Read every line BEFORE the roll-over spends them.
		var pos := s.world.player_position()
		var prize := 0
		if pos >= 1 and pos <= Season.CREDITS_BY_POSITION.size():
			prize = Season.CREDITS_BY_POSITION[pos - 1]
		var gate := s.office.gate_income()
		var dues := s.office.dues()
		var arena_up := s.office.arena_upkeep()
		var fac := 0
		for f in ClubOffice.Facility.values():
			fac += s.office.facility_upkeep(int(f))
		var fed := s.office.federation_upkeep()
		var turnout_ := s.office.turnout()
		var note_ := s.office.notoriety
		var att_ := s.office.attendance()
		var cap_ := s.office.arena.capacity()
		var fans := s.office.fans
		var memb := s.office.members
		var before := s.office.credits
		s.roll_over()
		print("s%-3d %2d  %5d %5d %5d | %5d %5d %5d = %+4d  %5d %5.0f %5.1f  turnout %.3f note %.2f att %d cap %d"
			% [year + 1, pos, prize, gate, dues, arena_up, fac, fed,
				s.office.credits - before, s.office.credits, fans, memb,
				turnout_, note_, att_, cap_])
	quit()
