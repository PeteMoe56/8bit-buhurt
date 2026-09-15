extends SceneTree
## Round length and downs for EVERY strategy pairing, in one command.
##
## Written the day the strategy list was cut to three, because the pace check
## measures one pairing — whatever the sim happens to default to — and reports it
## as "the pace". When Rush replaced the old lean zones the round came in a
## second under the floor, and the only way to know whether that was the plan
## being violent or the whole fight getting quicker was to measure all nine.

func _initialize() -> void:
	var keys: Array = Tuning.STRATEGIES.keys()
	print("\npairing                       round_s   downs/bout   clocked")
	for a in keys:
		for b in keys:
			var t := 0.0
			var rounds := 0
			var downs := 0
			var clocked := 0
			var n := 24
			for i in n:
				var sim := _mirror(i + 900000)
				sim.strategies = [a, b]
				sim._set_the_line()
				var acc := [0.0, 0, 0]
				sim.round_finished.connect(func(_rn, _w):
					acc[0] += sim.round_t
					acc[1] += 1
					if sim.round_t >= Tuning.ROUND_TIME - Tuning.TICK * 2.0:
						acc[2] += 1)
				sim.run_to_end()
				t += acc[0]
				rounds += acc[1]
				clocked += acc[2]
				downs += sim.downs[0] + sim.downs[1]
			print("%-28s  %5.1f     %5.1f        %d" % [
				"%s v %s" % [Tuning.STRATEGIES[a]["name"], Tuning.STRATEGIES[b]["name"]],
				t / float(maxi(rounds, 1)), float(downs) / float(n), clocked])
	quit(0)


func _mirror(seed_value: int) -> MeleeSim:
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	return MeleeSim.new(MeleeRosters.player_club(), b, seed_value)
