extends SceneTree

func _initialize() -> void:
	var acts := {}
	var downs_by := {}
	var rounds := 0
	var live := 0.0
	var n := 30
	for i in n:
		var b := MeleeRosters.player_club()
		b.short_name = "MIR"
		var sim := MeleeSim.new(MeleeRosters.player_club(), b, i + 900000)
		sim.action_resolved.connect(func(_i, act, _t, ok):
			var k: String = Tuning.act_name(act)
			acts[k] = int(acts.get(k, 0)) + 1
			if ok and (act == Tuning.Act.TAKEDOWN or act == Tuning.Act.BULLRUSH):
				downs_by[k] = int(downs_by.get(k, 0)) + 1)
		sim.run_to_end()
		live += sim.bout_t - Tuning.CORNER_TIME * float(Tuning.ROUNDS - 1)
		rounds += Tuning.ROUNDS
	print("live seconds per round: %.1f" % (live / float(rounds)))
	print("actions attempted per bout:")
	for k in acts:
		print("   %-10s %6.1f" % [k, float(acts[k]) / float(n)])
	print("downs per bout by action:")
	for k in downs_by:
		print("   %-10s %6.1f" % [k, float(downs_by[k]) / float(n)])
	quit(0)
