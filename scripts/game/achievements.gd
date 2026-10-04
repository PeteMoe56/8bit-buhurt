class_name Achievements
## STEAM ACHIEVEMENTS (4 Oct 2026). Earn-only, like everything on Steam.
##
## No autoload (06.5), so a static holder like Settings. The game calls
## `Achievements.unlock(id)` where the thing happens; this keeps a local record
## (user://achievements.cfg) and, on a Steam build, tells Steam. Steam is reached
## only through the GodotSteam GDExtension's "Steam" singleton, looked up at run
## time — so a phone build, the editor and the test runner, none of which have
## it, compile and run the same code and simply do not report.
##
## THE LIST BELOW IS THE STEAMWORKS LIST. Each id is the API name entered in
## Steamworks > Stats & Achievements; name and text are what the store shows.
## Changing an id here without changing it there means nobody ever gets it.
##
## Unlocks are local first and re-sent to Steam on every launch, so one earned
## offline, or before Steam was up, still lands. THE LOCAL FILE IS WRITTEN ONLY BY
## A DESKTOP BUILD: tests and probes run in the same user folder, and a night of
## probes must not hand the developer every achievement on his next launch.

const APP_ID := 5005040
const PATH := "user://achievements.cfg"
static var path: String = PATH

const LIST := [
	{"id": "FIRST_WIN", "name": "Off the Tailgate", "desc": "Win your first event."},
	{"id": "FLAWLESS", "name": "Not a Scratch", "desc": "Win a bout without one of your men going down."},
	{"id": "CLEAN_ROUND", "name": "Clean Sweep", "desc": "Win a round with all five of yours still standing."},
	{"id": "HAT_TRICK", "name": "Three Down", "desc": "One of your fighters puts three men down in a single event."},
	{"id": "FREIGHT_TRAIN", "name": "Freight Train", "desc": "Call a Bullrush off the wheel and put your man on the floor."},
	{"id": "OFF_THE_RAIL", "name": "Off the Rail", "desc": "Bullrush a man so hard he skids into the rail."},
	{"id": "STATE", "name": "State League", "desc": "Win promotion to the State League."},
	{"id": "REGIONAL", "name": "Regional League", "desc": "Win promotion to the Regional League."},
	{"id": "NATIONAL", "name": "National Division", "desc": "Win promotion to the National Division."},
	{"id": "PLAYOFF", "name": "Division Champions", "desc": "Win a division playoff."},
	{"id": "SILVERWARE", "name": "Silverware", "desc": "Win a cup."},
	{"id": "WORLDS", "name": "World Champions", "desc": "Win the World Championship."},
	{"id": "BREAKING_GROUND", "name": "Breaking Ground", "desc": "Build your first upgrade at the ground."},
	{"id": "NATIONAL_ARENA", "name": "National Arena", "desc": "Build your ground all the way up to a National Arena."},
	{"id": "CAPTAIN", "name": "Captain", "desc": "Hire a captain."},
	{"id": "NEW_BLOOD", "name": "New Blood", "desc": "Sign a free agent."},
	{"id": "BUSINESS", "name": "Just Business", "desc": "Trade a fighter."},
	{"id": "TITANIUM", "name": "Titanium", "desc": "Put a fighter in titanium harness."},
	{"id": "IN_THE_BOOK", "name": "In the Book", "desc": "Set a club record."},
	{"id": "LIFER", "name": "Lifer", "desc": "Finish five seasons."},
]

static var _got: Dictionary = {}
static var _loaded := false
static var _steam: Object = null
static var _steam_tried := false


static func ids() -> Array:
	var out: Array = []
	for a in LIST:
		out.append(String(a["id"]))
	return out


static func has(id: String) -> bool:
	_load()
	return _got.has(id)


## THE ONE CALL. Idempotent: the second time is free, so a hook may fire it
## every time the condition is true rather than tracking "first".
static func unlock(id: String) -> void:
	if not ids().has(id):
		push_error("Achievements: no achievement '%s' — add it to LIST and to Steamworks" % id)
		return
	_load()
	if _got.has(id):
		## Held already, and Steam told at the time (or at the next launch).
		return
	_got[id] = Time.get_unix_time_from_system()
	if Settings.is_desktop():
		_save()
	_tell_steam([id])


## A FOUGHT BOUT, league or cup, read off the sim once it is over.
static func after_bout(sim: MeleeSim) -> void:
	if sim.rounds_won[0] > sim.rounds_won[1] and sim.downs[1] == 0:
		unlock("FLAWLESS")
	if sim.clean_rounds > 0:
		unlock("CLEAN_ROUND")
	for m in sim.fought():
		if m.team == 0 and m.downs_caused >= 3:
			unlock("HAT_TRICK")
	if sim.called_br_downs > 0:
		unlock("FREIGHT_TRAIN")
	if sim.called_br_rail > 0:
		unlock("OFF_THE_RAIL")


## At launch: start Steam if this is a Steam build, and re-send everything held
## locally (Steam ignores one it already has).
static func boot() -> void:
	_load()
	if _steam_obj() != null and not _got.is_empty():
		_tell_steam(_got.keys())
		## Unlocks from a Steam-less run now belong to this account.
		if Settings.is_desktop():
			_save()


## FOR THE TESTS: forget what this run has unlocked (nothing is on disk).
static func reset() -> void:
	_got.clear()
	_loaded = true


## ONE STEAM ACCOUNT'S UNLOCKS, NOT THE COMPUTER'S (audit, 4 Oct 2026). The file
## sits in the OS user's folder, which every Steam account on that PC shares, and
## `boot()` re-sends what it holds — so one flat list handed the first account's
## achievements to the next one to launch. Each account now has its own section
## (its SteamID); unlocks earned with Steam not running go under "got" and are
## claimed by the next account that launches, once.
static func _account() -> String:
	var s := _steam_obj()
	if s == null or not s.has_method("getSteamID"):
		return "got"
	return "acct_%s" % str(s.call("getSteamID"))


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not Settings.is_desktop():
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK or cfg.load(path + ".bak") == OK:
		for sec in ["got", _account()]:
			if cfg.has_section(sec):
				for k in cfg.get_section_keys(sec):
					_got[String(k)] = cfg.get_value(sec, k, 0)


## Written aside and renamed in, as Settings does: a kill mid-write leaves the old
## file, not half of one.
static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)
	var acct := _account()
	if acct != "got" and cfg.has_section("got"):
		cfg.erase_section("got")
	if cfg.has_section(acct):
		cfg.erase_section(acct)
	for k in _got:
		cfg.set_value(acct, k, _got[k])
	var tmp := path + ".tmp"
	if cfg.save(tmp) == OK:
		if FileAccess.file_exists(path):
			DirAccess.rename_absolute(path, path + ".bak")
		DirAccess.rename_absolute(tmp, path)


static func _tell_steam(list: Array) -> void:
	var s := _steam_obj()
	if s == null:
		return
	for id in list:
		s.call("setAchievement", String(id))
	s.call("storeStats")


## Steam, if this is a Steam build and it started; null everywhere else.
static func steam() -> Object:
	return _steam_obj()


## The GodotSteam singleton, started once, or null. Only on a desktop build: a
## Steam singleton in the editor would report a developer's test unlocks.
static func _steam_obj() -> Object:
	if _steam_tried:
		return _steam
	_steam_tried = true
	if not Settings.is_desktop() or not Engine.has_singleton("Steam"):
		return null
	var s: Object = Engine.get_singleton("Steam")
	## steamInitEx has taken (retrieve_stats, app_id, embed_callbacks) and, in
	## later GodotSteam, (app_id, embed_callbacks). Ask it which.
	var n := 2
	for m in s.get_method_list():
		if String(m["name"]) == "steamInitEx":
			n = (m["args"] as Array).size()
	var args: Array = [APP_ID, true] if n <= 2 else [false, APP_ID, true]
	var res = s.callv("steamInitEx", args)
	var ok := false
	if res is Dictionary:
		ok = int(res.get("status", 1)) == 0
	elif res is bool:
		ok = res
	if not ok:
		print("Achievements: Steam did not start (%s); unlocks are kept locally" % str(res))
		return null
	_steam = s
	## STEAM DRAWS ITS OVERLAY AND ITS ACHIEVEMENT POP-UPS ON THE GAME'S FRAMES.
	## Low-processor mode (project.godot) stops drawing frames on a still menu, so
	## a pop-up for an achievement earned on one (Captain, New Blood) would sit
	## frozen until something moved. A Steam build draws every frame.
	OS.low_processor_usage_mode = false
	## THE OVERLAY PAUSES THE FIGHT AND THE CORNER (Deck Verified): Shift+Tab, or
	## the Steam button on a Deck, over a running clock would leave it running.
	if s.has_signal("overlay_toggled"):
		s.connect("overlay_toggled", func(active: bool, _user := false, _app := 0) -> void:
			if not active:
				return
			var tree := Engine.get_main_loop() as SceneTree
			var sc := tree.current_scene if tree != null else null
			if sc != null and sc.has_method("overlay_pause"):
				sc.call("overlay_pause"))
	return _steam
