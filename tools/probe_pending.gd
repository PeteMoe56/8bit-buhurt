extends SceneTree
## WHAT THE EIGHT ARE WORTH, measured in bouts rather than in unit conditions.
##
##   godot --headless --path . --script res://tools/probe_pending.gd
##
## `test_traits.gd` proves each one moves the number it is written to move. That
## is not the same question as whether it changes an afternoon — a trait can be
## arithmetically real and worth nothing, which is the more common failure and
## the one a table cannot show you.
const BOUTS := 90


## `solo` puts it on ONE man instead of five, which is the only way to see a
## trait that works on everybody ELSE. Five Talismans lift nobody — each one is
## excluded from his own room — so the first version of this probe measured
## Talisman at +0.0 and the number was the probe's, not the trait's.
func _run(t: int, solo: bool = false) -> float:
	var won := 0
	for i in BOUTS:
		var a := MeleeRosters.player_club()
		if t != FighterTrait.T.NONE:
			if solo:
				a.starting_five()[2].trait_id = t
			else:
				for f in a.starting_five():
					f.trait_id = t
		var sim := MeleeSim.new(a, MeleeRosters.rival_club(), i * 7717)
		sim.run_to_end()
		if sim.bout_winner() == 0:
			won += 1
	return 100.0 * float(won) / float(BOUTS)


func _init() -> void:
	var base := _run(FighterTrait.T.NONE)
	print("no trait          %5.1f%%" % base)
	for t in [FighterTrait.T.WRESTLER, FighterTrait.T.GRINDER]:
		var w := _run(t)
		print("%-16s  %5.1f%%   %+5.1f   (all five)" % [FighterTrait.name_of(t),
			w, w - base])
	if OS.get_cmdline_user_args().size() > 0:
		pass
	var solo_base := _run(FighterTrait.T.NONE, true)
	for t in [FighterTrait.T.TALISMAN, FighterTrait.T.LAST_MAN]:
		var w := _run(t, true)
		print("%-16s  %5.1f%%   %+5.1f   (one man)" % [FighterTrait.name_of(t),
			w, w - solo_base])
	quit()
