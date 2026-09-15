extends SceneTree
## How steep should the echelon be?
##
## Pete's rule (10 Sep 2026): *"Those 5-1 results is WAY too much, most should be
## 3-1, 5-1 is for heavily outgunned teams."* A steep echelon gives the leading
## side a local numbers advantage that then rolls up the rest of the line, so the
## stagger and the ending mix are the same dial seen twice. This sweeps the
## stagger and prints the mix at each setting, on an EVEN mirror — where 5-1
## should be rarest of all.

const SPREADS := [0.36, 0.28, 0.20, 0.12]
const MID := 0.48


func _initialize() -> void:
	print("\nspread   mean push        3-1    4-1    5-1   wipes   rounds")
	for sp in SPREADS:
		var push: Array = []
		for k in 5:
			push.append(MID + sp * (0.5 - float(k) / 4.0))
		var mirror: Array = []
		for k in 5:
			mirror.append(push[4 - k])
		var mix := {}
		var rounds := [0]
		for base in [210000, 110000]:
			for i in 50:
				var sim := _mirror(i + base)
				## The STRATEGIES table is a const, so the push profile is applied
				## straight onto the men after the line is set — which is all the
				## strategy does anyway. Same arithmetic as `_set_the_line`,
				## deliberately spelled out so the probe cannot drift from it.
				for m in sim.men:
					var own: Array = push if m.team == 0 else mirror
					var spot: Vector2 = sim.formation_spots(m.team)[m.slot]
					var zx: float = spot.x if m.team == 0 else 1.0 - spot.x
					var zy: float = float(own[m.slot]) if m.team == 0 else 1.0 - float(own[m.slot])
					m.plan_zone = Vector2(zx * Tuning.LIST_W, zy * Tuning.LIST_H)
					m.anchor = m.plan_zone
				## STANDING COUNTS, exactly as tests/test_melee.gd reads them.
				## The first version of this probe read `round_downs`, which is
				## reset as the next round is set up, and reported 0% for both
				## 3-1 and 5-1 — a probe disagreeing with the suite about a
				## quantity they both measure is the suite's oldest bug wearing
				## a new hat, and the answer is to read it the same way.
				sim.round_finished.connect(func(_rn, _w):
					var key := "%d-%d" % [
						maxi(sim.standing_count(0), sim.standing_count(1)),
						mini(sim.standing_count(0), sim.standing_count(1))]
					mix[key] = int(mix.get(key, 0)) + 1
					rounds[0] += 1)
				sim.run_to_end()
		var n := float(maxi(rounds[0], 1))
		print("%.2f     %s   %4.0f%%  %4.0f%%  %4.0f%%  %4.0f%%   %d" % [
			sp, _fmt(push),
			float(int(mix.get("3-1", 0))) / n * 100.0,
			float(int(mix.get("4-1", 0))) / n * 100.0,
			float(int(mix.get("5-1", 0))) / n * 100.0,
			_wipes(mix) / n * 100.0, rounds[0]])
	quit(0)


func _wipes(mix: Dictionary) -> float:
	var w := 0.0
	for k in mix:
		if String(k).ends_with("-0"):
			w += float(int(mix[k]))
	return w


func _fmt(a: Array) -> String:
	var s := ""
	for v in a:
		s += "%.2f " % float(v)
	return s.strip_edges()


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
