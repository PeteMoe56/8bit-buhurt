extends SceneTree
## What actually happens to a man's wind across a corner, with and without a
## swap. Measured rather than reasoned about.
func _initialize() -> void:
	for swap in [false, true]:
		var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 77)
		var guard := 0
		while sim.phase != MeleeSim.Phase.CORNER and guard < 200000:
			sim.tick(); guard += 1
		if sim.phase != MeleeSim.Phase.CORNER:
			print("never reached a corner"); quit(1); return
		var line := sim.lineup(0)
		var bench := sim.bench(0)
		print("\n=== swap: %s ===" % ("yes" if swap else "no"))
		print("  corner reached at round %d" % sim.round_no)
		var on = line[2]
		var off = bench[0] if not bench.is_empty() else null
		print("  IN THE CORNER (before recovery):")
		for q in line:
			print("     %-10s %.2f" % [q.display_name, sim.condition_of(q)])
		if off != null:
			print("  bench    %-10s cond %.2f" % [off.display_name, sim.condition_of(off)])
		if swap and off != null:
			print("  swap_in -> %s" % sim.swap_in(0, 2, off))
		## What the game does when the player picks a strategy.
		sim.strategies[0] = Tuning.STRATEGIES.keys()[0]
		sim.leave_corner()
		print("  after leave_corner: phase=%d swaps_used=%d" % [sim.phase, sim.swaps_used[0]])
		print("  line[2] is now %s" % sim.lineup(0)[2].display_name)
		print("  %-10s cond %.2f   %-10s cond %.2f"
			% [on.display_name, sim.condition_of(on),
			   off.display_name if off else "-", sim.condition_of(off) if off else 0.0])
		var g2 := 0
		while sim.round_no < 2 and sim.phase != MeleeSim.Phase.OVER and g2 < 200000:
			sim.tick(); g2 += 1
		print("  round now %d" % sim.round_no)
		print("  AFTER: %-10s cond %.2f   %-10s cond %.2f"
			% [on.display_name, sim.condition_of(on),
			   off.display_name if off else "-", sim.condition_of(off) if off else 0.0])
	quit(0)
