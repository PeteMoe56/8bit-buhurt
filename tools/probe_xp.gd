extends SceneTree
func _init() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	var g := 0
	while not s.season_complete() and g < 40:
		g += 1
		var sim := s.begin_bout()
		if sim == null:
			s.skip_event(); continue
		Session.season = s; Session.bout = sim
		sim.run_to_end(); s.post_bout(sim); Session.clear_bout()
	print("\nafter one season — xp, the bar, headroom, and whether a level can be placed\n")
	for f in s.club.roster:
		print("  %-9s age %2d  ov %2d / pot %2d  xp %3d / bar %3d  ceiling %s  can_level %s  raisable %s"
			% [f.display_name, f.age, f.overall(), f.potential, f.xp,
				Career.next_level_at(f), str(Career.at_ceiling(f)),
				str(Career.can_level(f)), str(Career.raisable(f).size())])
	quit()
