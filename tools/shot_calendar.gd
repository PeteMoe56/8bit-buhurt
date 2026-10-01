extends SceneTree
## Dev tool: the Calendar screen and the Club tab, a few weeks into a season.
##
##   xvfb-run -a godot --resolution 960x540 --path . --script res://tools/shot_calendar.gd -- <out_dir> [weeks] [scene]
##   scene: cal (default) | club

var out := "/tmp"
var n := 0
var which := "cal"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = String(args[0])
	var weeks := int(args[1]) if args.size() > 1 else 5
	if args.size() > 2:
		which = String(args[2])
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	if OS.get_environment("NAT") != "":
		## A National year, to see the Worlds week.
		for c in s.world.clubs:
			if int(c["tier"]) == League.Tier.NATIONAL:
				c["tier"] = 0
				break
		s.world.clubs[s.world.player_club]["tier"] = League.Tier.NATIONAL
		s.world._new_season()
	var g := 0
	while s.world.week < weeks and g < 60:
		g += 1
		match s.blocked_by():
			"bid":
				if s.take_bid(1, 0) != "":
					s.decline_bid()
				continue
			"dilemma":
				s.answer_dilemma(0)
				continue
		s.skip_event()
	Session.season = s
	var path := "res://scenes/Calendar.tscn" if which == "cal" else "res://scenes/Season.tscn"
	root.add_child(load(path).instantiate())


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	var p := "%s/%s%s.png" % [out, which, "_nat" if OS.get_environment("NAT") != "" else ""]
	root.get_texture().get_image().save_png(p)
	print("wrote ", p)
	quit(0)
	return true
