extends "res://tests/test_c6.gd"
## Targeted additional fixture, not the full balance gate. All armor starts at 1.
var left_grade := 0
var right_grade := 0

func _initialize() -> void:
	var hole := _the_hole()
	print("Frozen Rust tactical hole: ", JSON.stringify(hole))
	_test_thumb_beats_tactics(hole)
	_test_the_roster_wall(hole)
	for g in 5:
		var f := MeleeRosters.player_club().roster[0]
		var raw := f.ability()
		var ceiling := f.potential
		f.harness = g
		print("GRADE ", g, " effective_base=", f.effective_base(), " rating=", f.rating(), " raw=", f.ability())
		assert(raw == f.ability() and ceiling == f.potential)
	for g in [0, 4]:
		left_grade = g
		right_grade = 0
		for d in [0, 12, 16]:
			for base_seed in [30000, 61000]:
				var rate := _counts(48, "busy", hole, d, base_seed)
				print("CELL ", JSON.stringify({"left_grade": g, "right_grade": 0, "deficit": d, "seed_base": base_seed, "n": 48, "result": rate}))
				if d == 16:
					_ok(float(rate["win_pct"]) < 40.0, "heavy roster deficit survives the best harness", "grade %d base %d: %s" % [g, base_seed, str(rate)])
	for g in [0, 4]:
		left_grade = g
		right_grade = g
		var mirror := {"formation": 0, "strategy": 0, "against_formation": 0, "against_strategy": 0}
		print("MIRROR ", JSON.stringify({"both_grade": g, "n": 96, "seed_base": 700000, "result": _counts(96, "auto", mirror, 0, 700000)}))
	print("TARGETED_CHECK_FAILURES=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _counts(n: int, policy: String, hole: Dictionary, deficit: int, seed_base: int) -> Dictionary:
	var wins := 0
	var ties := 0
	for i in n:
		var sim := _sim(seed_base+i, int(hole["formation"]), int(hole["strategy"]), int(hole["against_formation"]), int(hole["against_strategy"]), deficit)
		_play(sim, policy)
		var winner := sim.bout_winner()
		wins += int(winner == 0)
		ties += int(winner == -1)
	return {"wins": wins, "losses": n-wins-ties, "ties": ties, "win_pct": 100.0*wins/maxi(1,n-ties)}

func _sim(seed_value: int, pf: int, ps: int, of_: int, os_: int, deficit: int) -> MeleeSim:
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
	sim.formations = [pf, of_]
	sim.strategies = [ps, os_]
	sim._set_the_line()
	return sim
