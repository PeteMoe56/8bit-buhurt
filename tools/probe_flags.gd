extends SceneTree
## Which Green flag is carrying the inversion? Give Green one Seasoned trait at
## a time and see which one hands the fight back.
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

func _run(label: String, patch: Dictionary) -> void:
	var wins := 0
	var decided := 0
	var n := 30
	for i in n:
		var sim := _mirror(i)
		sim.skills = [Tuning.AiSkill.HARDENED, Tuning.AiSkill.RUST]
		## Patch the GREEN side by giving it its own role table built from a
		## copied dictionary — cheapest way to vary one flag at a time.
		if not patch.is_empty():
			var g: Dictionary = Tuning.AI_SKILL[Tuning.AiSkill.RUST].duplicate()
			for k in patch:
				g[k] = patch[k]
			sim.patched = g
		sim.run_to_end()
		var w := sim.bout_winner()
		if w != -1:
			decided += 1
			if w == 0:
				wins += 1
	print("  %-26s %.0f%% to Hardened" % [label, 100.0 * float(wins) / float(maxi(1, decided))])

func _initialize() -> void:
	print("\nSeasoned (wear_read 0.55) vs Rust at various wear_read:")
	for w in [0.12, 0.17, 0.22]:
		_run("Rust wear_read %.2f" % w, {"wear_read": w})
	quit(0)
