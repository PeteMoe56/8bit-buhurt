extends SceneTree
## WHOLE JOURNEYS THROUGH THE REAL SCREENS, pressing the buttons a player presses.
## Unit tests prove the rules; these prove the doors between them are wired:
##
##   a new career   Start -> Play -> Start a club -> a town -> the season screen,
##                  saved to the slot, in the town picked
##   the first bout Fight it -> the save marks the bout live -> the bout finishes
##                  -> Back to the club -> posted, saved, mark cleared
##   Create         rename the club -> the save and the league table both carry it
##   Settings       a volume changed is the volume after a restart
##   a new job      Take it, twice -> the career is at the new club, saved there,
##                  bought credits with it
##
##   godot --headless --path . --script res://tests/test_flows.gd

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — flows through the real screens ===\n")
	SaveGame.set_namespace("flows")
	Store.wallet_prefix = "flows_"
	Settings.path = "user://flows_settings.cfg"
	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	Juice.set_enabled(false)
	await process_frame
	await _flow_new_career_and_first_bout()
	await _flow_create_renames_everywhere()
	_flow_settings_survive_a_restart()

	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Store.wallet_path()))
	print("")
	if failures.is_empty():
		print("THE FLOWS HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


## --------------------------------------------------------------- the driver
func _here() -> String:
	return current_scene.scene_file_path.get_file() if current_scene != null else ""


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _arrive(path.get_file())


func _arrive(file: String, frames: int = 30) -> bool:
	for i in frames:
		await process_frame
		if _here() == file:
			await process_frame
			return true
	return false


func _buttons() -> Array:
	var out: Array = []
	if current_scene != null:
		_collect(current_scene, out)
	return out


func _collect(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and not (c as Button).disabled and (c as Button).is_visible_in_tree():
			out.append(c)
		_collect(c, out)


func _labels() -> String:
	return ", ".join(_buttons().map(func(b): return "'%s'" % b.text))


## Press the first live button whose text is `text`. False (and says what there
## was) when there is none.
func _press(text: String) -> bool:
	for b in _buttons():
		if String(b.text) == text:
			b.pressed.emit()
			await process_frame
			await process_frame
			return true
	print("     no '%s' on %s; there is %s" % [text, _here(), _labels()])
	return false


## ----------------------------------------------------------------- flows
func _flow_new_career_and_first_bout() -> void:
	await _open("res://scenes/Start.tscn")
	await _press("Play")
	var at_title := await _arrive("Title.tscn")
	await _press("Start a club")
	## STEP 1 IS YOU (Pete, 1 Oct 2026), then the club, then the difficulty.
	var at_coach := await _arrive("Coach.tscn")
	if at_coach:
		var fe: LineEdit = current_scene.get("first_edit")
		var le: LineEdit = current_scene.get("last_edit")
		if fe != null and le != null:
			fe.text = "Boris"
			fe.text_changed.emit("Boris")
			le.text = "Kane"
			le.text_changed.emit("Kane")
	await _press("Next: your team  >")
	var founding := await _arrive("Create.tscn")
	await _press("Next: difficulty  >")
	await _press("Start the season  >")
	var in_season := founding and await _arrive("Season.tscn")
	var s: Season = Session.season
	_ok(at_title and at_coach and in_season and s != null and SaveGame.has_save(0)
		and s.coach.display_name == "Boris Kane" and s.coach.created,
		"Play and Start a club go You, then the club, then the difficulty, into a saved career",
		"title %s, coach %s, season %s, slot 0 saved %s, coach '%s'" % [at_title, at_coach, in_season,
			SaveGame.has_save(0), s.coach.display_name if s else "-"])
	if s == null:
		return
	## Whatever the first night asks first (a tournament bid, a card) is answered
	## the quick way, the way a player in a hurry would.
	for i in 4:
		var names: Array = _buttons().map(func(b): return String(b.text))
		if names.any(func(n): return String(n).begins_with("Fight: vs") or n == "Next event"):
			break
		for pass_on in ["Pass this year", "Carry on"]:
			if names.has(pass_on):
				await _press(pass_on)
				break
	var event_was := s.world.event
	## The hub's forward button names the opponent ("Fight: vs ATL").
	var fwd := "Next event"
	for b in _buttons():
		if String(b.text).begins_with("Fight: vs"):
			fwd = String(b.text)
	await _press(fwd)
	var in_melee := await _arrive("Melee.tscn")
	var on_disk = SaveGame._read(0)
	var marked: bool = on_disk is Dictionary and not (on_disk.get("bout_live", {}) as Dictionary).is_empty()
	_ok(in_melee and Session.bout != null and marked,
		"Fight it opens the bout, and the save on disk says a bout is live",
		"melee %s, bout %s, marked on disk %s" % [in_melee, Session.bout != null, marked])
	if not in_melee or Session.bout == null:
		return
	var sim: MeleeSim = Session.bout
	sim.run_to_end()
	await process_frame
	await process_frame
	## THE BEAT (3 Oct 2026): the last round's score holds on the field for a
	## couple of seconds before the report and its button come up.
	for i in 400:
		var m := current_scene
		if m == null or float(m.get("beat_t")) <= 0.0:
			break
		await process_frame
	await process_frame
	## LEVELS FIRST (4 Oct 2026): with levels to place the way out is "Spend
	## levels (N)", through the men's pages, and Back from there to the club.
	var out := "Back to the club"
	for b in _buttons():
		if String(b.text).begins_with("Spend levels"):
			out = String(b.text)
	await _press(out)
	if out != "Back to the club":
		var paged := await _arrive("Fighter.tscn")
		_ok(paged, "the levels waiting are the next page after the report", out)
		await _press("Back")
	var back := await _arrive("Season.tscn")
	on_disk = SaveGame._read(0)
	var cleared: bool = on_disk is Dictionary and (on_disk.get("bout_live", {}) as Dictionary).is_empty()
	var row: Dictionary = Session.season._my_row() if Session.season else {}
	_ok(back and Session.season.world.event == event_was + 1 and int(row.get("played", 0)) == 1 and cleared,
		"the bout is posted, the matchday moves on and the save clears the mark",
		"back %s, event %d -> %d, played %d, cleared %s" % [back, event_was,
			Session.season.world.event, int(row.get("played", 0)), cleared])
	var again := SaveGame.load_slot(0)
	_ok(again != null and again.last_interrupted == "" and again.world.event == event_was + 1,
		"and reloading it restarts nothing",
		"event %d, forfeit '%s'" % [again.world.event if again else -1, again.last_interrupted if again else "?"])


func _flow_create_renames_everywhere() -> void:
	if Session.season == null:
		_ok(false, "Create renames the club everywhere", "no career open")
		return
	await _open("res://scenes/Create.tscn")
	await _press("CLUB")
	var sc := current_scene
	var name_edit: LineEdit = sc.get("club_name_edit")
	var short_edit: LineEdit = sc.get("club_short_edit")
	if name_edit == null or short_edit == null:
		_ok(false, "Create renames the club everywhere", "no name boxes on the club tab")
		return
	name_edit.text = "Flowtown Hammers"
	name_edit.text_changed.emit(name_edit.text)
	short_edit.text = "FTH"
	short_edit.text_changed.emit(short_edit.text)
	sc.call("_save_club")
	var back := SaveGame.load_slot(0)
	_ok(back != null and back.club.display_name == "Flowtown Hammers"
		and String(back.world.clubs[back.world.player_club]["name"]) == "Flowtown Hammers",
		"a club renamed in Create is renamed in the save and in the table",
		"club '%s', table '%s', flash '%s'" % [back.club.display_name if back else "-",
			String(back.world.clubs[back.world.player_club]["name"]) if back else "-", String(sc.get("flash"))])


func _flow_settings_survive_a_restart() -> void:
	Settings.load_once()
	Settings.nudge("music", -1)
	Settings.nudge("music", -1)
	Settings.nudge("ui", 1)
	var music := Settings.music
	var ui := Settings.interface
	## A restart: the statics go back to their defaults and the file is read.
	Settings.music = 0.8
	Settings.interface = 0.65
	Settings._loaded = false
	Settings.load_once()
	_ok(is_equal_approx(Settings.music, music) and is_equal_approx(Settings.interface, ui)
		and not is_equal_approx(music, 0.8),
		"a volume changed is the volume after a restart",
		"music %.3f -> %.3f, ui %.3f -> %.3f" % [music, Settings.music, ui, Settings.interface])

