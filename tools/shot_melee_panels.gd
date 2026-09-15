extends SceneTree
## Dev tool: the fight's three panels, which are three screens in one scene.
##
##   xvfb-run -a godot --path . --script res://tools/shot_melee_panels.gd -- <dir>
var n := 0
var stage := 0
var s: Node
var dir := "user://"

func _initialize() -> void:
	## A FIXED GLOBAL SEED, FIRST — `melee_scene._ready()` opens a standalone
	## exhibition with `_new_bout(randi())` and Godot seeds the global stream
	## randomly at startup, so without this the picture changes every run and the
	## tool cannot answer whether a CHANGE altered the screen. See shot_corner.gd.
	seed(20260914)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		dir = String(a[0])
	s = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(s)

func _process(_d: float) -> bool:
	n += 1
	if n < 4:
		return false
	match stage:
		0:
			_shot("p0_book")
			s.call("_show_strategy_panel")
		1:
			_shot("p1_corner")
			## THE FOUR-ROW BOOK, which is what a season bout renders: the named
			## formations plus the shape the Chalkboard sent. It is the tallest
			## the corner panel ever gets and therefore the only one worth
			## looking at twice.
			var spots: Array = Tuning.FORMATIONS[Tuning.Formation.DEPTH]["spots"].duplicate()
			s.get("sim").set_plan(0, spots, null)
			s.set("drawn_spots", spots)
			s.call("_show_strategy_panel")
		2:
			_shot("p2_corner_drawn")
			s.call("_on_bout_finished", 0)
		3:
			_shot("p3_report")
			print("done")
			quit(0)
			return true
	stage += 1
	n = 0
	return false

func _shot(name_: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [dir, name_])
	print("wrote ", name_)
