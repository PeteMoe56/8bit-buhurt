extends SceneTree
## ONE HASH OVER MANY BOUTS AND A FEW SEASONS, for proving a speed-up changed
## nothing. Run before and after; the two lines must match exactly.
##
##   bash tools/bb.sh probe fingerprint [bouts]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 40
	var acc := PackedStringArray()
	for i in n:
		var s := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 700 + i)
		s.run_to_end()
		var line := "%s|%s|%s|%.4f" % [str(s.rounds_won), str(s.margin), str(s.downs), s.bout_t]
		for m in s.men:
			line += "|%d,%d,%.3f,%.3f" % [m.downs_caused, m.times_downed, m.pos.x, m.tank]
		acc.append(line)
	var season := Season.new(MeleeRosters.starting_club(), 99)
	Session.season = season
	var mgr := ProbeManager.new()
	for y in 3:
		mgr.winter(season)
		var g := 0
		while not season.season_complete() and g < 60:
			g += 1
			while season.blocked_by() != "":
				match season.blocked_by():
					"bid": season.decline_bid()
					"dilemma": season.answer_dilemma(0)
					"cup": season.sim_cup_tie()
					"promotion": season.answer_promotion(true)
			if season.season_complete():
				break
			if g % 4 == 0:
				var b := season.begin_bout()
				if b != null:
					b.run_to_end()
					season.post_bout(b)
					continue
			season.skip_event()
		season.roll_over()
	acc.append(var_to_str(SaveGame.to_dict(season)).replace(str(SaveGame.to_dict(season).get("saved", "")), ""))
	print("FINGERPRINT %s" % "\n".join(acc).md5_text())
	quit(0)
