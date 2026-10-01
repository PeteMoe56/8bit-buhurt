extends SceneTree
## THE GUIDE (1 Oct 2026): Settings and every Guide page, one picture each.
##
##   bash tools/bb.sh shot guide 960x540 <out_dir> [locale]
##

var out := "/tmp/guide"
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
		["settings", "Settings", func(n): pass, false],
		["menu", "Season", func(n): n.set("club_menu_open", true); n.call("_rebuild"), false],
	]
	for k in GuideScene.topics().size():
		shots.append(["guide_%d" % k, "Guide", func(n, t = k): n.set("tab", t); n.call("_rebuild"), false])


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
