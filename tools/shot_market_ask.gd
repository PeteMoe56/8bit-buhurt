extends SceneTree
## THE FREE-AGENT PROMPT, the first week up (lane B, 2 Oct 2026): the hub card
## and the list it opens with its man picked.
##
##   bash tools/bb.sh shot market_ask 960x540 <out_dir> [locale]

var out := "/tmp/market_ask"
var i := 0
var frame := 0
var scene: Node = null
const SHOTS := ["Season", "Market"]


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


func _load() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.coach.created = true
	s.coach.set_name("Boris", "Kane")
	s.coach.seasons = 1
	s.world.history.append({"season": s.world.season - 1, "promoted": true, "tier": 0})
	s.office.credits = 400
	if s.bid_open():
		s.decline_bid()
	while s.office.cap_level < 40:
		s.office.cap_level += 1
	Session.season = s
	if SHOTS[i] == "Market":
		var ask := s.market_ask()
		Session.market_pick = Market.taken_key(ask["best"]) if not ask.is_empty() else ""
	scene = (load("res://scenes/%s.tscn" % SHOTS[i]) as PackedScene).instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	if i >= SHOTS.size():
		quit()
		return true
	if scene == null:
		_load()
		frame = 0
		return false
	frame += 1
	if frame == 5:
		var nm: String = "market_ask" if SHOTS[i] == "Season" else "market_picked"
		root.get_texture().get_image().save_png("%s/%s.png" % [out, nm])
		print("wrote ", nm)
		scene.queue_free()
		scene = null
		i += 1
	return false
