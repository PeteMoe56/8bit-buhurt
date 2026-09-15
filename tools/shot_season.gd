extends SceneTree
## Dev tool: render the season screen to PNG, because readability has never once
## been settled by reasoning about it on this project.
##
##   xvfb-run -a godot --path . --script res://tools/shot_season.gd -- <events> <out.png>

var events := 0
var out_path := "user://season.png"
var n := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		events = int(args[0])
	if args.size() > 1:
		out_path = args[1]
	Session.season = Season.new(MeleeRosters.player_club(), 4242)
	## Optional third arg: drop the player into a tier, so the worst case for
	## layout — sixteen clubs in the National Division — can be rendered without
	## playing seven seasons to get there.
	if args.size() > 2:
		## SWAP with a club already in that tier rather than just moving the
		## player into it. Moving him made a seventeen-club National Division,
		## which is a division size the game can never actually produce — so the
		## picture was of a layout problem that does not exist while hiding
		## whether the real one fits.
		var w = Session.season.world
		var me: int = w.player_club
		var there: Array = w.clubs_in(int(args[2]))
		var mine_tier: int = int(w.clubs[me]["tier"])
		w.clubs[int(there[0])]["tier"] = mine_tier
		w.clubs[me]["tier"] = int(args[2])
		w._new_season()
	for i in events:
		if not Session.season.season_complete():
			Session.season.skip_event()
	scene = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if n < 6:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path, " ", img.get_width(), "x", img.get_height())
	quit(0)
	return true
