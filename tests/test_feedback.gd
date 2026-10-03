extends SceneTree
## Pete's beta feedback, 3 Oct 2026, held: what a knock is, the local cups away
## from home, and the end-of-round beat.
##
##   godot --headless --path . --script res://tests/test_feedback.gd

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — beta feedback, 3 Oct ===\n")
	_test_a_knock_has_a_name()
	_test_the_name_survives_a_save()
	_test_a_local_cup_is_not_in_your_town()
	_test_the_round_ends_on_a_beat()
	print("")
	if failures.is_empty():
		print("THE FEEDBACK FIXES HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _test_a_knock_has_a_name() -> void:
	var short := FighterCard.injury_for(1, 7)
	var long := FighterCard.injury_for(5, 7)
	_ok((FighterCard.INJURY_KINDS[0] as Array).has(short), "one event", "a light knock: %s" % short)
	_ok((FighterCard.INJURY_KINDS[2] as Array).has(long), "five events", "a heavy one: %s" % long)
	var f := FighterCard.new()
	_ok(f.injury_word() != "", "old save", "a man with no kind still reads: %s" % f.injury_word())


func _test_the_name_survives_a_save() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var f: FighterCard = s.club.roster[0]
	f.injury = 2
	f.injury_kind = "strained shoulder"
	var back := SaveGame.from_dict(SaveGame.to_dict(s))
	var g: FighterCard = back.club.roster[0]
	_ok(g.injury == 2 and g.injury_kind == "strained shoulder", "save", "%d, %s" % [g.injury, g.injury_kind])


func _test_a_local_cup_is_not_in_your_town() -> void:
	var bad := 0
	var seen := 0
	for seed in [4242, 1, 2, 3, 20260911]:
		var s := Season.new(MeleeRosters.starting_club(), seed)
		var mine := s.world.city_of(s.world.player_club)
		for slot in 2:
			seen += 1
			if s.world.invitational_city(0, slot) == mine:
				bad += 1
	_ok(bad == 0, "local cups", "%d of %d held in the player's own town" % [bad, seen])


func _test_the_round_ends_on_a_beat() -> void:
	var beat: float = (load("res://scripts/melee/melee_scene.gd") as GDScript).get_script_constant_map().get("BEAT", 0.0)
	_ok(beat >= 1.5 and beat <= 4.0, "beat", "%.1f s on the field before the corner" % beat)
