extends SceneTree
## THE TEAM-FIRST SCREENS (1 Oct 2026): every new popup and step, one picture each.
##
##   bash tools/bb.sh shot restructure 960x540 <out_dir> [locale]
##
## coach_new, create_club, create_kit, create_mark, create_town, create_grade,
## team_picked, training, armorers, kit_help, cap_help, menu, management.

var out := "/tmp/restructure"
var shots: Array = []
var i := 0
var frame := 0
var scene: Node = null


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		Settings.load_once()
		Settings.language = a[1]
		Settings.apply_language()
		TranslationServer.set_locale(a[1])
	DirAccess.make_dir_recursive_absolute(out)
	Juice.set_enabled(false)
	shots = [
		["coach_new", "Coach", func(n): pass, true],
		["create_club", "Create", func(n): pass, true],
		["create_kit", "Create", func(n): n.set("popup", "kit"); n.call("_rebuild"), true],
		["create_mark", "Create", func(n): n.set("popup", "mark"); n.call("_rebuild"), true],
		["create_town", "Create", func(n): n.set("popup", "town"); n.call("_rebuild"), true],
		["create_grade", "Create", func(n): n.set("tab", 2); n.call("_rebuild"), true],
		["team_picked", "Season", func(n): n.set("tab", 1); n.set("picked", Session.season.club.roster[0]); n.call("_rebuild"), false],
		["training", "Season", func(n): n.set("tab", 1); n.set("training_open", true); n.call("_rebuild"), false],
		["armorers", "Season", func(n): n.set("tab", 2); n.set("armorer_open", true); n.call("_rebuild"), false],
		["kit_help", "Season", func(n): n.set("tab", 2); n.set("help_key", "kit"); n.call("_rebuild"), false],
		["cap_help", "Season", func(n): n.set("tab", 3); n.set("help_key", "cap"); n.call("_rebuild"), false],
		["menu", "Season", func(n): n.set("club_menu_open", true); n.call("_rebuild"), false],
		["management", "Season", func(n): n.set("tab", 4); n.call("_rebuild"), false],
		["ground", "Season", func(n): n.set("ground_open", true); n.call("_rebuild"), false],
	]


func _load(idx: int) -> void:
	var sh: Array = shots[idx]
	var founding: bool = sh[3]
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.coach.created = not founding
	if not founding:
		s.coach.set_name("Boris", "Kane")
		s.world.event = 1
		s.results.append({"bye": false, "opponent": 1, "rf": 2, "ra": 1, "margin": 3, "fought": true})
		s.office.captains.append(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5))
	Session.season = s
	Session.founding = founding
	Session.create_tab = 1 if founding else -1
	scene = (load("res://scenes/%s.tscn" % String(sh[1])) as PackedScene).instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	if i >= shots.size():
		quit()
		return true
	if scene == null:
		_load(i)
		frame = 0
		return false
	frame += 1
	if frame == 2:
		(shots[i][2] as Callable).call(scene)
		scene.queue_redraw()
	if frame == 5:
		root.get_texture().get_image().save_png("%s/%s.png" % [out, String(shots[i][0])])
		print("wrote ", shots[i][0])
		scene.queue_free()
		scene = null
		i += 1
	return false
