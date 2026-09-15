extends SceneTree
## IS A FIGHT BETWEEN EQUALS A FIGHT BETWEEN EQUALS?
##
##   godot --headless --path . --script res://tools/probe_fair.gd
##
## Twenty-season walks say the player's club wins 17.4% of its bouts in a
## six-club division where an average club wins about forty. That has two
## possible causes and they want completely different fixes:
##
##   1. the club DECAYS relative to its rivals over a career, or
##   2. the SIM is not even at equal strength, in which case every career in the
##      game is being fought uphill and no amount of management fixes it.
##
## This asks the second question on its own. Same club on both sides, built from
## one id so the two squads are identical men, and nothing else set: no captains
## either side, no grade, no occasion, opposition scale 1.0. If side 0 does not
## win about half, the fight itself is tilted.
const BOUTS := 60

func _init() -> void:
	print("\n=== two identical clubs, %d bouts ===\n" % BOUTS)
	_run("bare — no coaching either side", false, -1)
	_run("player coached, CPU at Backyard", true, 0)
	_run("player coached, CPU at National", true, 3)
	print("")
	quit()


func _run(label: String, coach_player: bool, cpu_tier: int) -> void:
	var wins := 0
	var draws := 0
	var rounds_for := 0
	var rounds_against := 0
	for i in BOUTS:
		var a := ClubFactory.build(7, "Mirror A", "MRA", 40)
		var b := ClubFactory.build(7, "Mirror B", "MRB", 40)
		var sim := MeleeSim.new(a, b, 1000 + i, 1.0)
		if coach_player:
			var tiers := {}
			for r in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
				tiers[r] = 2
			sim.set_role_skills(0, tiers)
		if cpu_tier >= 0:
			sim.skills[1] = Season.CPU_TIER[clampi(cpu_tier, 0,
				Season.CPU_TIER.size() - 1)]
		sim.run_to_end()
		if sim.bout_winner() == 0:
			wins += 1
		elif sim.bout_winner() == -1:
			draws += 1
		rounds_for += sim.rounds_won[0]
		rounds_against += sim.rounds_won[1]
	print("%-34s  side 0 won %3d, drew %3d, lost %3d  (%5.1f%%)  ·  rounds %d-%d"
		% [label, wins, draws, BOUTS - wins - draws,
			100.0 * float(wins) / float(BOUTS), rounds_for, rounds_against])
