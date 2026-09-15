extends SceneTree
## WHAT A GRADE IS ACTUALLY WORTH, measured rather than argued.
##
##   godot --headless --path . --script res://tools/probe_grade.gd
##
## Every column runs the SAME SEEDS, so the only difference between them is the
## multiplier. The x1.00 row appears twice on purpose: two identical columns are
## the negative control, and if they ever disagree the harness is measuring
## something other than the thing it names.
##
## This probe is why the shipped numbers are what they are. The first draft was
## x1.08/x0.94, chosen off Total War (x1.10 melee attack on Hard) and Retro Bowl
## (a 24-point catching swing between Easy and Hard). Both are single-stat or
## few-stat knobs. Ours multiplies FOUR contest stats at once and a bout is five
## men over three rounds, so the edges compound: x1.08 measured a 27.5% win rate
## against 44.5% at even, and x1.16 measured 9.5%. A difficulty setting that
## takes a club from winning half its fights to winning one in ten is not a
## setting, it is a different game. The numbers came down.
const N := 150


func _run(scale: float) -> Array:
	var w := 0
	var d := 0
	var l := 0
	for i in N:
		var s := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(),
			hash("wr:%d" % i), scale)
		s.run_to_end()
		var x := s.bout_winner()
		if x == 0:
			w += 1
		elif x == 1:
			l += 1
		else:
			d += 1
	return [w, d, l]


func _init() -> void:
	print("scale   W   D   L    win%%   (N = %d a column, one seed set)" % N)
	for sc in [0.96, 0.97, 0.98, 1.0, 1.0, 1.02, 1.03, 1.04]:
		var r := _run(float(sc))
		print("x%.2f  %3d %3d %3d   %5.1f" % [sc, r[0], r[1], r[2],
			100.0 * float(r[0]) / float(N)])
	quit()
