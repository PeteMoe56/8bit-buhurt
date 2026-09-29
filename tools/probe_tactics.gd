extends SceneTree
## HOW MUCH DO TACTICS MATTER? (29 Sep 2026)
##
##   bash tools/bb.sh probe tactics <bouts>      (RB_AI_THROW=x to compare)
##
## Every ordered pair of strategies on the 2-1-2, identical mirrored rosters,
## hands-off. Prints the matrix and its spread: the mean distance from 50% of
## the ordered pairs. If that shrinks, picking a strategy matters less.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 40
	var ns := Tuning.STRATEGIES.size()
	var dev := 0.0
	var cnt := 0
	for us in ns:
		var line := "%-14s" % String(Tuning.STRATEGIES[us]["name"])
		for them in ns:
			if us == them:
				line += "   --  "
				continue
			var w := 0; var d := 0
			for i in n:
				var sim := _sim(40000 + i, us, them)
				sim.run_to_end()
				var x := sim.bout_winner()
				if x == -1: continue
				d += 1
				if x == 0: w += 1
			var r := 100.0 * w / maxf(1.0, d)
			dev += absf(r - 50.0); cnt += 1
			line += " %5.1f " % r
		print(line)
	print("throw %.2f  mean |win%% - 50| over %d ordered pairs: %.1f" % [Tuning.ai_clinch_throw, cnt, dev / cnt])
	quit()


func _sim(seed_value: int, ps: int, os_: int) -> MeleeSim:
	var a := MeleeRosters.player_club()
	var b := MeleeRosters.player_club()
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	var sim := MeleeSim.new(a, b, seed_value)
	sim.formations = [0, 0]
	sim.strategies = [ps, os_]
	sim._set_the_line()
	return sim
