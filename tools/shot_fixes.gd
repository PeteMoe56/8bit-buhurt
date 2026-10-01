extends SceneTree
## Dev tool: the screens from Pete's 1 Oct playthrough, a few weeks in.
##   xvfb-run -a godot --resolution 960x540 --path . --script res://tools/shot_fixes.gd -- <out_dir> <which>
##   which: squad | finances | staff | arena | card

var out := "/tmp"
var which := "squad"
var n := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = String(args[0])
	if args.size() > 1:
		which = String(args[1])
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	var g := 0
	while s.world.week < 4 and g < 40:
		g += 1
		match s.blocked_by():
			"bid":
				if which == "arena":
					break
				s.decline_bid()
				continue
			"dilemma":
				s.answer_dilemma(0)
				continue
			"sendoff":
				s.answer_send_off()
				continue
		s.skip_event()
	while s.blocked_by() == "dilemma":
		s.answer_dilemma(0)
	Session.season = s
	match which:
		"staff":
			scene = load("res://scenes/Staff.tscn").instantiate()
		"arena":
			scene = load("res://scenes/Arena.tscn").instantiate()
		_:
			scene = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if n == 3:
		match which:
			"squad":
				scene.set("tab", 1)
				scene.call("_rebuild")
			"finances":
				scene.set("tab", 4)
				scene.call("_rebuild")
			"card":
				var ss: Season = Session.season
				scene.set("team_card", int(ss.table()[1]["club"]))
				scene.call("_rebuild")
			"staff":
				scene.set("browsing", true)
				scene.call("_build")
	if n < 8:
		return false
	var p := "%s/fix_%s.png" % [out, which]
	root.get_texture().get_image().save_png(p)
	print("wrote ", p)
	quit(0)
	return true
