extends "res://tests/test_c6.gd"
## Harness #2 (Claude, 8 Oct): identical rosters, auto-played, left side in grade L vs right in Rust.
var left_grade := 0
var right_grade := 0

func _initialize() -> void:
	var mirror := {"formation": 0, "strategy": 0, "against_formation": 0, "against_strategy": 0}
	for g in [0, 2, 3, 4]:
		left_grade = g
		for d in [0, 4, 8, 12]:
			var w := 0; var t := 0; var n := 64
			for i in n:
				var sim := _mk(900000 + i, d)
				_play(sim, "auto")
				var win := sim.bout_winner()
				w += int(win == 0); t += int(win == -1)
			print("MELEE grade=%d deficit=%d n=%d wins=%d ties=%d win_pct=%.1f" % [g, d, n, w, t, 100.0 * w / maxi(1, n - t)])
	quit(0)

func _mk(seed_value: int, deficit: int) -> MeleeSim:
	var a := MeleeRosters.player_club()
	for f in a.roster:
		f.harness = left_grade
		f.strength = maxi(1, f.strength - deficit)
		f.base = maxi(1, f.base - deficit)
		f.skill = maxi(1, f.skill - deficit)
		f.gas = maxi(1, f.gas - deficit)
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		f.harness = right_grade
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	var sim := MeleeSim.new(a, b, seed_value)
	sim.formations = [0, 0]
	sim.strategies = [0, 0]
	sim._set_the_line()
	return sim
