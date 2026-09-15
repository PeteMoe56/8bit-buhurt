extends SceneTree
## WHAT THE GAME LOOKS LIKE ON A PHONE.
##
##   xvfb-run -a godot --path . --resolution 1170x540 --script res://tools/shot_aspect.gd
##
## The project is 960x540 with `stretch/aspect = "expand"`, which means the
## viewport GROWS rather than getting bars: a 19.5:9 handset hands the game a
## 1170x540 canvas. Every screen in this project is laid out against
## `UiKit.screen()`, a hard-coded Vector2(960, 540), and against literals — 936,
## 912 — measured off it.
##
## So this takes the same screen at three shapes and looks at what the extra
## width does. **A layout you cannot see is a layout you cannot check**, and no
## check in the suite has ever rendered a frame that was not 960 wide.
var n := 0

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	var g := 0
	while not s.season_complete() and g < 3:
		g += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(0)
				"cup": s.sim_cup_tie()
		s.skip_event()
	var q2 := 0
	while q2 < 8 and s.blocked_by() != "":
		q2 += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"cup": s.sim_cup_tie()
	root.add_child(load("res://scenes/Season.tscn").instantiate())

func _process(_d: float) -> bool:
	n += 1
	if n < 14:
		return false
	var img := root.get_texture().get_image()
	var nm := "res://shots/aspect_%dx%d.png" % [img.get_width(), img.get_height()]
	img.save_png(nm)
	print("wrote %s  viewport=%s window=%s" % [nm, str(root.size), str(DisplayServer.window_get_size())])
	return true
