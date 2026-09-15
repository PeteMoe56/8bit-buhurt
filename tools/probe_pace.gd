extends SceneTree
## Fast pace probe: how long is a round now, and how many end on the clock?
func _initialize() -> void:
	var rounds := 0
	var clocked := 0
	var total := 0.0
	var downs := 0
	var gassed := 0
	var bouts := 14
	for i in bouts:
		var b := MeleeRosters.player_club()
		b.short_name = "MIR"
		for f in b.roster:
			match f.pos:
				Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
				Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
				Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
				Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
		var sim := MeleeSim.new(MeleeRosters.player_club(), b, i + 4000)
		var acc := [0.0, 0]
		sim.round_finished.connect(func(_rn, _w):
			acc[0] += sim.round_t
			acc[1] += 1
			if sim.round_t >= Tuning.ROUND_TIME - Tuning.TICK * 2.0:
				acc.append(1))
		sim.run_to_end()
		total += acc[0]
		rounds += acc[1]
		clocked += acc.size() - 2
		downs += sim.downs[0] + sim.downs[1]
		for m in sim.men:
			if m.gassed_at >= 0.0:
				gassed += 1
	print("rounds %d · %.1fs each · %.1f downs a bout · %.1f gassed a bout · %d%% on the clock" % [
		rounds, total / float(rounds), float(downs) / float(bouts),
		float(gassed) / float(bouts),
		int(round(100.0 * float(clocked) / float(rounds)))])
	quit(0)
