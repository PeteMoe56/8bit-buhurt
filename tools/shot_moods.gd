extends SceneTree
## Dev tool: the season screen in every mood, side by side.
##
##   xvfb-run -a godot --path . --script res://tools/shot_moods.gd -- <dir> <mood>
##
## The palette is measured for contrast in tests/test_dilemma.gd, which proves it
## can be READ. It cannot prove it looks like anything, and that is the third
## thing on this project that had to be rendered to be judged.

var out_dir := "user://"
var mood := 0
var n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = String(args[0])
	if args.size() > 1:
		mood = int(args[1])
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	## Far enough in that the table has results in it — an empty table judges a
	## palette on nothing but its background.
	for i in 3:
		if not s.season_complete():
			if not s.dilemma.is_empty():
				s.answer_dilemma(0)
			elif s.bid_open():
				s.decline_bid()
			else:
				s.skip_event()
	Session.season = s
	var scene: Node = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)
	## FORCED rather than reached. Getting a real Worlds final out of a fresh
	## save takes a dozen simulated seasons and the picture would be of a
	## different club every time — this is a look at a palette, not a run.
	scene.set_script_mood(mood)


func _process(_d: float) -> bool:
	n += 1
	if n < 10:
		return false
	var img := root.get_texture().get_image()
	img.save_png("%s/mood_%d.png" % [out_dir, mood])
	print("wrote mood_%d.png" % mood)
	quit(0)
	return true
