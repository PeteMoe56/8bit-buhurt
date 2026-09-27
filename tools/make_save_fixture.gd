extends SceneTree
## Writes a golden save of the CURRENT format into tests/fixtures/save_vN.dat.
##
##   godot --headless --path . --script res://tools/make_save_fixture.gd
##
## Run it once, right before SaveGame.VERSION is bumped, and commit the file.
## `test_save` then loads every fixture in that folder through the real migration
## path — a migration proven on a real old file, not on today's dictionary with
## its version number edited.

func _initialize() -> void:
	SaveGame.set_namespace("fixture")
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	for i in 2:
		_season(s)
	## Mid-season, with something bought and a man hurt, so the file carries state.
	s.office.credits += 12
	for i in 2:
		if not s.season_complete():
			s.skip_event()
	if not SaveGame.save(s, 1):
		push_error("could not write the fixture")
		quit(1)
		return
	var src := FileAccess.get_file_as_bytes(SaveGame.path_for(1))
	var out := "res://tests/fixtures/save_v%d.dat" % SaveGame.VERSION
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_buffer(src)
	f.close()
	SaveGame.delete(1)
	var fp := "%s|s%d|e%d|cr%d|%d men" % [s.club.display_name, s.world.season, s.world.event,
		s.office.credits, s.club.roster.size()]
	FileAccess.open(out.replace(".dat", ".txt"), FileAccess.WRITE).store_string(fp + "\n")
	print("wrote %s (%d bytes): %s" % [out, src.size(), fp])
	quit(0)


func _season(s: Season) -> void:
	s.office.credits += 30
	s.office.new_week()
	s.office.upgrade(ClubOffice.Facility.TRAINING)
	s.sync_power()
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
		var ties := 0
		while s.pending_cup() != null and ties < 8:
			ties += 1
			s.sim_cup_tie()
	s.roll_over()
