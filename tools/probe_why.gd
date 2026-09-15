extends SceneTree
## Why is Green beating Seasoned on the wide list? Measure the two sides rather
## than reasoning about them.
func _mirror(i: int) -> MeleeSim:
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	return MeleeSim.new(MeleeRosters.player_club(), b, i + 130000)

func _run(label: String, a: int, b: int) -> void:
	var wins := 0
	var decided := 0
	var downs := [0, 0]
	var gas := [0.0, 0.0]
	var walked := [0.0, 0.0]
	var n := 16
	for i in n:
		var sim := _mirror(i)
		sim.skills = [a, b]
		var last := []
		for m in sim.men:
			last.append(m.pos)
		var guard := 20000
		while not sim.is_over() and guard > 0:
			guard -= 1
			sim.tick()
			for m in sim.men:
				walked[m.team] += m.pos.distance_to(last[m.idx])
				last[m.idx] = m.pos
		downs[0] += sim.downs[0]
		downs[1] += sim.downs[1]
		for m in sim.men:
			gas[m.team] += m.gas_frac()
		var w := sim.bout_winner()
		if w != -1:
			decided += 1
			if w == 0:
				wins += 1
	print("%s  %.0f%% to A · downs %.1f v %.1f · end gas %.2f v %.2f · walked %.0f v %.0f" % [
		label, 100.0 * float(wins) / float(maxi(1, decided)),
		float(downs[0]) / n, float(downs[1]) / n,
		gas[0] / float(n * 5), gas[1] / float(n * 5),
		walked[0] / n, walked[1] / n])

func _initialize() -> void:
	_run("Hardened v Rust ", Tuning.AiSkill.HARDENED, Tuning.AiSkill.RUST)
	_run("Hardened v Hardened", Tuning.AiSkill.HARDENED, Tuning.AiSkill.HARDENED)
	_run("Rust v Rust      ", Tuning.AiSkill.RUST, Tuning.AiSkill.RUST)
	quit(0)
