extends SceneTree
## THE ACHIEVEMENTS (Steam, 4 Oct 2026).
##
##   godot --headless --path . --script res://tests/test_achievements.gd
##
## `Achievements.LIST` is the list entered in Steamworks. The ways it breaks are
## quiet ones: an id that nothing in the game ever unlocks, an id Steam would
## refuse, a bout that should have earned one and did not, and a test run that
## writes unlocks to disk for a developer's next launch to hand to Steam.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the achievements ===\n")
	_test_the_list()
	_test_every_id_is_earned_somewhere()
	_test_a_bout()
	_test_nothing_on_disk()
	print("")
	if failures.is_empty():
		print("THE ACHIEVEMENTS HOLD (%d checks)\n" % checks)
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


func _test_the_list() -> void:
	var ids := Achievements.ids()
	var seen := {}
	var bad: Array = []
	var re := RegEx.create_from_string("^[A-Z][A-Z0-9_]{1,62}$")
	for a in Achievements.LIST:
		var id := String(a["id"])
		if seen.has(id) or re.search(id) == null or String(a["name"]) == "" or String(a["desc"]) == "":
			bad.append(id)
		seen[id] = true
	_ok(bad.is_empty() and ids.size() >= 15, "every achievement has a unique Steam API name, a name and a line",
		"%d achievements%s" % [ids.size(), "" if bad.is_empty() else ", bad: " + str(bad)])


## Every id appears, as a quoted string, in game code outside the list itself.
func _test_every_id_is_earned_somewhere() -> void:
	var src := ""
	for dir in ["res://scripts/game", "res://scripts/league", "res://scripts/melee"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") and f != "achievements.gd":
				src += FileAccess.get_file_as_string(dir + "/" + f)
	src += _unlock_lines(FileAccess.get_file_as_string("res://scripts/game/achievements.gd"))
	var orphan: Array = []
	for id in Achievements.ids():
		if src.find("\"%s\"" % id) == -1:
			orphan.append(id)
	_ok(orphan.is_empty(), "every achievement is unlocked somewhere in the game", str(orphan))


## The list's own file counts only where it calls unlock (after_bout).
func _unlock_lines(s: String) -> String:
	var out := ""
	for line in s.split("\n"):
		if line.contains("unlock(\""):
			out += line + "\n"
	return out


func _test_a_bout() -> void:
	Achievements.reset()
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 4040, 1.0)
	sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
	var k := 0
	while not sim.is_over() and k < 60000:
		sim.tick()
		k += 1
	sim.rounds_won = [2, 0]
	sim.downs = [7, 0]
	sim.clean_rounds = 1
	sim.called_br_downs = 1
	sim.called_br_rail = 1
	Achievements.after_bout(sim)
	var want := ["FLAWLESS", "CLEAN_ROUND", "FREIGHT_TRAIN", "OFF_THE_RAIL"]
	var missing: Array = []
	for id in want:
		if not Achievements.has(id):
			missing.append(id)
	_ok(missing.is_empty(), "a flawless bout with a called bullrush into the rail earns its four", str(missing))
	Achievements.reset()
	sim.rounds_won = [1, 2]
	sim.downs = [3, 6]
	sim.clean_rounds = 0
	sim.called_br_downs = 0
	sim.called_br_rail = 0
	Achievements.after_bout(sim)
	_ok(not Achievements.has("FLAWLESS") and not Achievements.has("FREIGHT_TRAIN"),
		"a lost bout earns none of them", "FLAWLESS %s, FREIGHT_TRAIN %s" % [
			Achievements.has("FLAWLESS"), Achievements.has("FREIGHT_TRAIN")])


## Tests and probes share the game's user folder: nothing they unlock is written.
func _test_nothing_on_disk() -> void:
	Achievements.unlock("CAPTAIN")
	_ok(Achievements.has("CAPTAIN") and not FileAccess.file_exists(Achievements.path),
		"a test run unlocks in memory and writes nothing for Steam to pick up",
		"file at %s: %s" % [Achievements.path, FileAccess.file_exists(Achievements.path)])
