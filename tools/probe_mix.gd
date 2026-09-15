extends SceneTree
## Does a 5-1 still MEAN something?
##
## Pete's rule (10 Sep 2026): *"most should be 3-1, 5-1 is for heavily outgunned
## teams."* That is two claims — 5-1 should be uncommon, and it should be much
## commoner when one side is light. The suite measures both at 24 bouts a cell,
## where the register's own warning applies: nothing is readable to better than
## about five points. When the gap between the two cells FALLS INSIDE that band,
## the suite cannot tell you whether the signal has gone or the sample is small.
##
## This runs the same measurement at four seed bases instead of one, so the
## question gets answered instead of guessed at.

const BASES := [210000, 110000, 410000, 510000]
const PER_BASE := 30


func _initialize() -> void:
	print("\ndeficit   3-1    4-1    5-1   3-1+4-1   wipes   rounds")
	for deficit in [0, 6, 12]:
		var mix := {}
		var rounds := [0]
		for base in BASES:
			for i in PER_BASE:
				var sim := _sim(i + base, deficit)
				sim.round_finished.connect(func(_rn, _w):
					var key := "%d-%d" % [
						maxi(sim.standing_count(0), sim.standing_count(1)),
						mini(sim.standing_count(0), sim.standing_count(1))]
					mix[key] = int(mix.get(key, 0)) + 1
					rounds[0] += 1)
				sim.run_to_end()
		var n := float(maxi(rounds[0], 1))
		var a := float(int(mix.get("3-1", 0))) / n * 100.0
		var b := float(int(mix.get("4-1", 0))) / n * 100.0
		var c := float(int(mix.get("5-1", 0))) / n * 100.0
		var w := 0.0
		for k in mix:
			if String(k).ends_with("-0"):
				w += float(int(mix[k]))
		print("%5d   %4.0f%%  %4.0f%%  %4.0f%%     %4.0f%%   %4.0f%%   %d" % [
			deficit, a, b, c, a + b, w / n * 100.0, rounds[0]])
	print("")
	quit(0)


func _sim(seed_value: int, deficit: int) -> MeleeSim:
	var a := MeleeRosters.player_club()
	if deficit > 0:
		for f in a.roster:
			f.strength = maxi(1, f.strength - deficit)
			f.base = maxi(1, f.base - deficit)
			f.skill = maxi(1, f.skill - deficit)
			f.gas = maxi(1, f.gas - deficit)
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	return MeleeSim.new(a, b, seed_value)
