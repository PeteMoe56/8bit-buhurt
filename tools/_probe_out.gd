extends SceneTree
func _initialize() -> void:
	for seed_ in [4242, 909, 1, 77]:
		var s := Season.new(MeleeRosters.starting_club(), seed_)
		var out: Array = []
		for f in s.club.roster:
			if f.injury > 0 or not f.available or not f.passes_inspection():
				out.append("%s inj=%d avail=%s kit=%s" % [f.display_name, f.injury,
					str(f.available), str(f.passes_inspection())])
		print("seed %d: %d men, unfit: %s" % [seed_, s.club.roster.size(),
			"none" if out.is_empty() else str(out)])
	quit(0)
