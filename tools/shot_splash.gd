extends SceneTree
## THE WALK-OUT, in all three of its dressings.
##
##   xvfb-run -a godot --path . --script res://tools/shot_splash.gd
##
## The venue is FORCED rather than played into. Which one comes up is the fixture
## list's business, and a tool that plays a season until it gets an away day is a
## tool nobody runs.
var n := 0
var stage := 0
var s: Node
const KINDS := ["home", "away", "neutral"]


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
	## The first frames build the scene; after that each pass shoots the dressing
	## it was set to and sets up the next.
	if n == 1 and stage < KINDS.size():
		s.set("forced_venue", stage)
		s.call("_show_splash")
		return false
	if n < 5:
		return false
	root.get_texture().get_image().save_png("res://shots/splash_%s.png"
		% KINDS[stage])
	stage += 1
	if stage >= KINDS.size():
		print("done")
		quit(0)
		return true
	n = 0
	return false
