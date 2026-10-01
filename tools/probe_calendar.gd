extends SceneTree
## Walks seasons week by week and prints what each Saturday was. The calendar
## rule (30 Sep 2026): one fixture a week, never two.

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), int(OS.get_environment("SEED")) if OS.get_environment("SEED") != "" else 4242)
	if OS.get_environment("NAT") != "":
		## Swap the player's club with a National one, then redraw the year.
		var w := s.world
		for c in w.clubs:
			if int(c["tier"]) == League.Tier.NATIONAL:
				c["tier"] = 0
				break
		w.clubs[w.player_club]["tier"] = League.Tier.NATIONAL
		w._new_season()
	for yr in 3:
		var line := ""
		var guard := 0
		print("season %d  tier %s  weeks %d" % [s.world.season, s.tier_name(), s.world.weeks_this_season()])
		while not s.ready_to_roll() and guard < 80:
			guard += 1
			match s.blocked_by():
				"bid":
					if s.take_bid(1, 0) != "":
						s.decline_bid()
					continue
				"dilemma": s.answer_dilemma(0); continue
				"promotion":
					if s.answer_promotion(true) != "":
						s.answer_promotion(false)
					continue
			var w := s.world.this_week()
			var tag := Calendar.label(w, s.world.events_this_season(), "OWN")
			var pend := s.pending_cup()
			s.skip_event()
			line += "  W%d %s%s\n" % [s.world.week, tag, " *" if pend != null else ""]
		print(line)
		print("  pos %d  promoted? %s  finalists %s  cups open %d" % [s.position(), s.promotion_place(), str(s.world.finalists), s.world.cups.size()])
		if s.blocked_by() == "promotion" and s.answer_promotion(true) != "":
			s.answer_promotion(false)
		s.roll_over()
	quit(0)
