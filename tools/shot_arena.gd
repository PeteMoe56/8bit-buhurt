extends SceneTree
## Dev tool: the arena screen at a given level and reputation, so the six
## grounds can be looked at side by side rather than argued about.
##
##   xvfb-run -a godot --path . --script res://tools/shot_arena.gd -- <level> <rep> <out.png>

var lvl := 0
var rep := 0.1
var out_path := "user://arena.png"
var n := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		lvl = int(args[0])
	if args.size() > 1:
		rep = float(args[1])
	if args.size() > 2:
		out_path = String(args[2])
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 80
	s.office.arena.level = lvl
	s.office.notoriety = rep * ClubOffice.NOTORIETY_MAX
	s.office.fans = s.office.fan_cap() * minf(1.0, rep + 0.15)
	s.office.tier = mini(3, lvl)
	## Re-offer at the right division. The dates are generated when the season
	## opens, and a constructed state has to say so or the screen shows a
	## Backyard price on a National ground.
	s.world.clubs[s.world.player_club]["tier"] = s.office.tier
	s.world._new_season()
	s.open_bids()
	Session.season = s
	scene = load("res://scenes/Arena.tscn").instantiate()
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
