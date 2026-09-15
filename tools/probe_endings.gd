extends SceneTree
## How do rounds actually END? Pete, 10 Sep 2026: most should be 3-1, and 5-1 is
## what happens to a badly outgunned side — not what happens in an even fight.
##
## Reads the histogram off mirror matches, where by construction neither side is
## outgunned at all, so anything lopsided here is the sim cascading rather than
## one club being better.
var seed_base := 210000

func _mirror(i: int) -> MeleeSim:
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	return MeleeSim.new(MeleeRosters.player_club(), b, i + seed_base)

func _light(i: int, deficit: int) -> MeleeSim:
	var a := MeleeRosters.player_club()
	for f in a.roster:
		f.strength = maxi(1, f.strength - deficit)
		f.base = maxi(1, f.base - deficit)
		f.skill = maxi(1, f.skill - deficit)
		f.gas = maxi(1, f.gas - deficit)
	return MeleeSim.new(a, MeleeRosters.player_club(), i + seed_base)


func _sweep(label: String, deficit: int) -> void:
	var ends := {}
	## An Array because a lambda captures locals BY VALUE — an int counter
	## assigned inside a signal handler never reaches the outer scope. This is
	## written down in docs/REGISTER.md 06.6 and I wrote it there, and still
	## reached for an int first. It reported "0 rounds" and a percentage of
	## negative nine quintillion, which is at least a loud way to fail.
	var rounds := [0]
	var downs := 0
	var worst := 0
	var secs := [0.0]
	var gassed := 0
	var n := 40
	for i in n:
		var sim := _mirror(i) if deficit == 0 else _light(i, deficit)
		var per := [0]
		sim.fighter_downed.connect(func(_a, _b):
			while per.size() < sim.round_no:
				per.append(0)
			per[sim.round_no - 1] += 1)
		sim.round_finished.connect(func(_rn, _w):
			var s0 := sim.standing_count(0)
			var s1 := sim.standing_count(1)
			var k := "%d-%d" % [maxi(s0, s1), mini(s0, s1)]
			ends[k] = int(ends.get(k, 0)) + 1
			secs[0] += sim.round_t
			rounds[0] += 1)
		sim.run_to_end()
		downs += sim.downs[0] + sim.downs[1]
		for m in sim.men:
			if m.gassed_at >= 0.0:
				gassed += 1
		for d in per:
			worst = maxi(worst, int(d))
	var keys: Array = ends.keys()
	keys.sort()
	var line := ""
	for k in keys:
		line += "%s x%d(%d%%)  " % [k, ends[k], int(round(100.0 * float(ends[k]) / float(rounds[0])))]
	print("\n  %s — %d rounds · %.0fs each · %.1f downs a bout · %.1f a round · %.1f gassed · worst %d"
		% [label, rounds[0], secs[0] / float(rounds[0]), float(downs) / float(n),
		float(downs) / float(rounds[0]), float(gassed) / float(n), worst])
	print("  " + line.strip_edges())


func _initialize() -> void:
	## Pete, 10 Sep 2026: most rounds should be 3-1, and 5-1 is what happens to a
	## badly outgunned side. Two sweeps, because that is two claims: an even fight
	## should sit around 3-1, and a mismatch should be where the wipes live.
	_sweep("even mirror @210k", 0)
	seed_base = 260000
	_sweep("12 light @260k", 12)
	seed_base = 110000
	_sweep("even mirror @110k", 0)
	quit(0)
