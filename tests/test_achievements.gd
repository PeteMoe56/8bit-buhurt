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
	_test_the_record_book()
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
	## ONE GOOD FIRST BOUT IS NOT FIVE ACHIEVEMENTS (Pete, 4 Oct 2026: "First
	## fight, I got 6"): a clean round, a called Bullrush down and one into the
	## rail are counted towards career totals, not handed out.
	sim.rounds_won = [2, 0]
	sim.downs = [7, 0]
	sim.clean_rounds = 1
	sim.called_br_downs = 1
	sim.called_br_rail = 1
	Achievements.after_bout(sim)
	var early: Array = []
	for id in ["CLEAN_ROUND", "FREIGHT_TRAIN", "OFF_THE_RAIL", "HAT_TRICK"]:
		if Achievements.has(id):
			early.append(id)
	_ok(early.is_empty(), "one good first bout earns none of the counted ones", str(early))
	## A CAREER OF THEM DOES.
	for n in 10:
		Achievements.after_bout(sim)
	var want := ["CLEAN_ROUND", "FREIGHT_TRAIN", "OFF_THE_RAIL"]
	var missing: Array = []
	for id in want:
		if not Achievements.has(id):
			missing.append(id)
	_ok(missing.is_empty(), "and ten bouts' worth reach the counts",
		"%s; clean %d, br %d, rail %d" % [str(missing), Achievements.count("clean_rounds"),
			Achievements.count("br_downs"), Achievements.count("br_rail")])
	## FLAWLESS ONLY AGAINST A BETTER SIDE.
	var better: bool = Achievements._line_rating(sim, 1) > Achievements._line_rating(sim, 0)
	_ok(Achievements.has("FLAWLESS") == better, "a flawless win counts only against a higher-rated line",
		"theirs %.1f, ours %.1f, unlocked %s" % [Achievements._line_rating(sim, 1),
			Achievements._line_rating(sim, 0), Achievements.has("FLAWLESS")])
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


## IN THE BOOK is for breaking a record that stood — another man's, from an
## earlier season — not for the book filling up in a club's first bout (audit,
## 4 Oct 2026: everyone had it by the end of their first event).
func _test_the_record_book() -> void:
	Achievements.reset()
	var w := LeagueWorld.new(77)
	## THE SEEDED BOOK IS HARD (4 Oct 2026): a first season's best is not a record.
	_ok(not w.note_record("rating", 60, "Ames", 1) and not Achievements.has("IN_THE_BOOK"),
		"the book starts with marks set before you", "rating record %d by %s" % [int(w.records["rating"]["value"]), String(w.records["rating"]["holder"])])
	w.records.clear()
	## Season 1, bout 1: five men write and overwrite the empty book.
	w.note_record("rating", 50, "Ames", 1)
	w.note_record("rating", 58, "Brook", 1)
	w.note_record("events", 1, "Ames", 1)
	w.note_record("events", 2, "Ames", 1)
	_ok(not Achievements.has("IN_THE_BOOK"), "the book filling up in season 1 earns nothing",
		"IN_THE_BOOK %s" % Achievements.has("IN_THE_BOOK"))
	## Season 2: his own record, carried on, is not breaking one.
	w.note_record("events", 3, "Ames", 2)
	_ok(not Achievements.has("IN_THE_BOOK"), "a man extending his own record earns nothing",
		"IN_THE_BOOK %s" % Achievements.has("IN_THE_BOOK"))
	## Season 2: another man past last season's mark is.
	w.note_record("rating", 61, "Cole", 2)
	_ok(Achievements.has("IN_THE_BOOK"), "another man past a record from an earlier season earns it",
		"IN_THE_BOOK %s" % Achievements.has("IN_THE_BOOK"))
