extends SceneTree
## WHAT THE CLUB RECORD BOOK READS AFTER N SEASONS (4 Oct 2026), for setting
## the seeded legends' marks: hard, not out of reach.
##
##   godot --headless --path . --script res://tools/probe_records.gd -- [seasons] [seeds]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var years := int(a[0]) if a.size() > 0 else 10
	var seeds := int(a[1]) if a.size() > 1 else 3
	for sd in seeds:
		var s := Season.new(MeleeRosters.starting_club(), 7000 + sd)
		s.world.records.clear()
		var line: Array[String] = []
		for y in years:
			var guard := 0
			while not s.season_complete() and guard < 60:
				guard += 1
				var q := 0
				while q < 8 and s.blocked_by() != "":
					q += 1
					match s.blocked_by():
						"bid": s.decline_bid()
						"sendoff": s.answer_send_off()
						"dilemma": s.answer_dilemma(s.dilemma_card()["options"].size() - 1)
						"cup": s.sim_cup_tie()
				s.skip_event()
			var md := 0
			var mb := 0
			var ms := 0
			var mr := 0
			for f in s.club.roster:
				md = maxi(md, f.downs)
				mb = maxi(mb, f.bouts)
				ms = maxi(ms, f.rounds_standing)
				mr = maxi(mr, f.overall())
			line.append("S%d t%d d%d e%d st%d r%d" % [s.world.season, s.world.player_tier(), md, mb, ms, mr])
			for f in s.club.roster:
				if Contracts.can_extend(f):
					s.extend(f)
				else:
					s.resign(f)
			s.roll_over()
		print("seed %d: %s" % [sd, " | ".join(line)])
	quit()
