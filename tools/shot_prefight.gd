extends SceneTree
## THE WALK-OUT, AND THE SCREEN AFTER IT.
##
##   xvfb-run -a godot --path . --script res://tools/shot_prefight.gd
##
## Two frames, because the fault was a transition: the splash, and then the
## screen the walk-out button leads to. One frame of either proves nothing —
## the bug was that the second one was still drawing the first one.
var n := 0
var stage := 0
var sc: Node = null

func _initialize() -> void:
	Settings.tips_enabled = false
	Session.season = Season.new(MeleeRosters.starting_club(), 20260914)
	Session.bout = null
	sc = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 10:
		return false
	n = 0
	match stage:
		0:
			root.get_texture().get_image().save_png("res://shots/prefight_splash.png")
			print("wrote prefight_splash  screen=%d" % int(sc.get("screen")))
			## THROUGH THE BUTTON'S OWN HANDLER, not by setting `screen`.
			sc.call("_show_strategy_panel")
		1:
			root.get_texture().get_image().save_png("res://shots/prefight_plan.png")
			print("wrote prefight_plan    screen=%d" % int(sc.get("screen")))
			return true
	stage += 1
	return false
