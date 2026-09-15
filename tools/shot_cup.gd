extends SceneTree
## Dev tool: the Club screen with a cup tie waiting, which is the one state the
## season screenshot could never show before — there was no way to reach it.
##
##   xvfb-run -a godot --path . --script res://tools/shot_cup.gd -- <out.png>

var out_path := "user://cup.png"
var n := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = String(args[0])
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	for i in s.world.clubs.size():
		if i != s.world.player_club:
			s.world.clubs[i]["power"] = maxi(20, int(s.world.clubs[i]["power"]) - 12)
	s.sync_power()
	var g := 0
	while not s.cup_pending() and g < 40:
		g += 1
		if s.season_complete():
			if s.ready_to_roll():
				s.roll_over()
			else:
				break
		else:
			s.skip_event()
	Session.season = s
	scene = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true
