extends SceneTree
## THE AFTER-ACTION REPORT, with a bout actually fought behind it.
##
##   xvfb-run -a godot --path . --script res://tools/shot_aar.gd
##
## The panels tool reaches the report by calling `_on_bout_finished` on a fight
## nobody had, so every man's afternoon is empty and the bottom half has nothing
## to say. This one fights the bout first — which is the only way to photograph
## the half of the screen that exists to report on it.
var n := 0
var stage := 0
var s: Node


func _initialize() -> void:
	## A FIXED GLOBAL SEED, FIRST — `melee_scene._ready()` opens a standalone
	## exhibition with `_new_bout(randi())` and Godot seeds the global stream
	## randomly at startup, so without this the picture changes every run and the
	## tool cannot answer whether a CHANGE altered the screen. See shot_corner.gd.
	seed(20260914)
	Session.season = Season.new(MeleeRosters.starting_club(), 20260914)
	s = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(s)


func _process(_d: float) -> bool:
	n += 1
	if n < 4:
		return false
	match stage:
		0:
			## THROUGH THE SEASON'S OWN DOOR. `_on_bout_finished` only posts the
			## result when `Session.in_season()` — which needs a bout handed over,
			## not just a season set — and without it `post_bout` never runs, so
			## `last_changes` is empty and the bottom half photographs its own
			## empty case. Which is what the first run of this tool did.
			var sim: MeleeSim = Session.season.begin_bout()
			s.set("sim", sim)
			Session.bout = sim
			sim.run_to_end()
			s.call("_on_bout_finished", sim.bout_winner())
		1:
			root.get_texture().get_image().save_png("res://shots/aar.png")
			print("done")
			quit(0)
			return true
	stage += 1
	n = 0
	return false
