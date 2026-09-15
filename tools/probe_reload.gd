extends SceneTree
## PIN A RELOAD DIVERGENCE TO ONE EVENT.
##
##   godot --headless --path . --script res://tools/probe_reload.gd
##
## `test_save.gd` can tell you that a reloaded career stopped matching an
## uninterrupted one. It cannot tell you WHERE, and a fingerprint mismatch
## reported as "diverged at character 464" is a failing check nobody can act on.
##
## This plays five seasons, saves, does the summer moves on both, and then runs
## ONE EVENT at a time on each side until they disagree — printing the bout, the
## RNG state, the room, and the opponent each side actually put on the list. It
## found the splinter bug in three runs: same fixture, same seed, same rng state
## afterwards, and one side fielding five men against the other side's three.
const DEEP := 5

func _season(s: Season) -> void:
	s.office.new_week()
	if s.office.travel_slots < ClubOffice.TRAVEL_MAX:
		s.office.buy_travel_slot()
	s.office.new_week()
	s.office.upgrade(ClubOffice.Facility.TRAINING)
	for f in s.market():
		if s.sign_from_market(f) == "":
			break
	s.sync_power()
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
	s.roll_over()

## One event only, returning a stamp of what it did.
func _one_event(s: Season) -> String:
	if s.season_complete():
		return "complete"
	var opp := s.opponent_id()
	var sim := s.begin_bout()
	if sim == null:
		s.skip_event()
		return "bye"
	Session.season = s
	Session.bout = sim
	sim.run_to_end()
	var res := "v%d %d-%d (%d-%d)" % [opp, sim.rounds_won[0], sim.rounds_won[1],
		sim.margin[0], sim.margin[1]]
	s.post_bout(sim)
	Session.clear_bout()
	var t := 0
	while s.pending_cup() != null and t < 8:
		t += 1
		s.sim_cup_tie()
	res += " | rng %d | me %d | morale %.4f" % [s.world.rng.state, s.club.power(),
		s.office.morale]
	return res

func _club_line(c) -> String:
	if c == null:
		return "<none>"
	var out := "%s pw%d cap%d | " % [c.display_name, c.power(), c.travel_cap]
	for f in c.starting_five():
		out += "%s %d/%d inj%d mor%.2f  " % [f.display_name, f.overall(),
			int(f.pos), f.injury, f.morale]
	return out


func _init() -> void:
	SaveGame.set_namespace("probe_reload2")
	var s := Season.new(MeleeRosters.starting_club(), 99177)
	s.office.credits += 60
	for i in DEEP:
		_season(s)
	SaveGame.save(s, 0)
	var back := SaveGame.load_slot(0)

	## The summer moves, on both, exactly as _season does them.
	for c in [s, back]:
		c.office.new_week()
		if c.office.travel_slots < ClubOffice.TRAVEL_MAX:
			c.office.buy_travel_slot()
		c.office.new_week()
		c.office.upgrade(ClubOffice.Facility.TRAINING)
		for f in c.market():
			if c.sign_from_market(f) == "":
				break
		c.sync_power()
	print("\nafter the summer moves: me %d vs %d, morale %.4f vs %.4f"
		% [s.club.power(), back.club.power(), s.office.morale, back.office.morale])

	for e in 8:
		if s.season_complete() and back.season_complete():
			break
		## THE OPPONENT, AS HE IS ABOUT TO BE FIELDED, before either bout runs.
		var oa := s.club_for(s.opponent_id()) if s.opponent_id() >= 0 else null
		var ob := back.club_for(back.opponent_id()) if back.opponent_id() >= 0 else null
		var sa := _club_line(oa)
		var sb := _club_line(ob)
		var a := _one_event(s)
		var b := _one_event(back)
		print("event %d:  %s" % [e + 1, "same" if a == b else "DIVERGED"])
		if a != b:
			print("   orig  " + a)
			print("   back  " + b)
			print("   the opponent they fielded:")
			print("     orig  " + sa)
			print("     back  " + sb)
			break
	SaveGame.delete(0)
	quit()
