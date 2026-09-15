extends SceneTree
## Fast probe: does the difficulty curve still point the right way?
func _initialize() -> void:
	var wins := 0
	var decided := 0
	var n := 40
	for i in n:
		var b := MeleeRosters.player_club()
		b.short_name = "MIR"
		for f in b.roster:
			match f.pos:
				Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
				Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
				Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
				Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
		var sim := MeleeSim.new(MeleeRosters.player_club(), b, i + 130000)
		sim.skills = [Tuning.AiSkill.HARDENED, Tuning.AiSkill.RUST]
		sim.run_to_end()
		var w := sim.bout_winner()
		if w != -1:
			decided += 1
			if w == 0:
				wins += 1
	print("Hardened vs Rust: %.1f%% to Hardened (%d decided)"
		% [100.0 * float(wins) / float(maxi(1, decided)), decided])
	quit(0)
