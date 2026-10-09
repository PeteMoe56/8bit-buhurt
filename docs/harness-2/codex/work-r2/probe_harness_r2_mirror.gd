extends "res://tests/test_melee.gd"
## Follow up the 96-bout Titanium mirror concern with the existing 400-bout test.
func _initialize() -> void:
	_test_symmetry()
	_test_autoplay_competent()
	for note in notes: print(note)
	print("TITANIUM_MIRROR_CHECKS=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func _mirror(seed_value: int) -> MeleeSim:
	var a := MeleeRosters.player_club()
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in a.roster: f.harness = 4
	for f in b.roster:
		f.harness = 4
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	return MeleeSim.new(a,b,seed_value)
