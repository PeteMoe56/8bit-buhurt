extends SceneTree
## Probe (30 Sep playtest #12, "people teleported"): run bouts and report any
## tick where a standing man moves further than a man can run in one tick,
## outside the round reset.
func _initialize() -> void:
	var worst := 0.0
	var hits := 0
	var where := ""
	for seed_i in 8:
		var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 900 + seed_i)
		var last := {}
		var last_round := sim.round_no
		for t in 2500:
			if sim.phase == MeleeSim.Phase.CORNER or sim.phase == MeleeSim.Phase.OVER:
				break
			sim.tick()
			if sim.round_no != last_round:
				last_round = sim.round_no
				last.clear()
				continue
			for m in sim.men:
				var k: int = m.idx
				if last.has(k):
					var d: float = (m.pos - last[k]).length()
					if d > worst:
						worst = d
						where = "seed %d t %d man %d state %d" % [900 + seed_i, t, k, m.state]
					if d > 12.0:
						hits += 1
				last[k] = m.pos
	print("WORST %.1f at %s; jumps over 12: %d" % [worst, where, hits])
	quit()
