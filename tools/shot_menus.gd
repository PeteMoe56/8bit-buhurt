extends SceneTree
## Render the shell: title, clubhouse tabs. Same reason as always — readability
## has never once been settled by reasoning about it on this project.
##
##   xvfb-run -a godot --path . --script res://tools/shot_menus.gd -- <what> <out.png>
##   what: title | club | squad | honors
var what := "title"
var out_path := "user://menu.png"
var n := 0
var scene: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		what = args[0]
	if args.size() > 1:
		out_path = args[1]

	if what == "title":
		## One used slot and one empty, so both states are in the same picture.
		var s := Season.new(MeleeRosters.player_club(), 4242)
		for i in 3:
			s.skip_event()
		SaveGame.save(s, 0)
		SaveGame.delete(1)
		var t := Season.new(MeleeRosters.player_club(), 99)
		for i in 4:
			t.skip_event()
		t.roll_over()
		SaveGame.save(t, 2)
		scene = load("res://scenes/Title.tscn").instantiate()
	else:
		var s := Season.new(MeleeRosters.player_club(), 4242)
		for i in 12:
			if s.season_complete():
				s.roll_over()
			s.skip_event()
		Session.season = s
		Session.slot = -1
		scene = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)

func _process(_d: float) -> bool:
	n += 1
	if n == 3 and what != "title":
		match what:
			"squad": scene.tab = 1
			"office": scene.tab = 2
			"honors": scene.tab = 3
		if what == "office":
			## A club a few seasons in, so the screen is showing something.
			scene.season.office.credits = 30
			scene.season.office.cap_level = 1
			scene.season.office.upgrade(ClubOffice.Facility.TRAINING)
			scene.season.office.upgrade(ClubOffice.Facility.TRAINING)
			## HOME_GROUND WAS A FACILITY AND IS NOW THE ARENA. This tool has
			## not run since that move — a parse error, not a bad shot, so it
			## failed loudly every time and nobody ran it. The ground is built
			## through `office.arena` now; the infirmary is the second facility.
			scene.season.office.upgrade(ClubOffice.Facility.INFIRMARY)
			scene.season.office.hire(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER))
			scene.season.office.credits = 12
		scene._rebuild()
	if n < 8:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true
