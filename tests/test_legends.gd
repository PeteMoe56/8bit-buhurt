extends SceneTree
## CLUB LEGENDS ON THE STAFF (11 Oct 2026): a decorated man who retires comes
## back on the market next summer, at the top of the list, as good as the best
## captain on it, teaching a star above his grade, and lifts the room the day he
## is hired. Survives a save.
var checks := 0
var bad: Array[String] = []


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		bad.append(what)


func _initialize() -> void:
	Achievements._steam_tried = true
	Achievements._steam = null
	call_deferred("_run")


func _run() -> void:
	var s := Season.new(MeleeRosters.starting_club_with_reserve(), 9090)
	s.office.credits = 200
	var f: FighterCard = s.club.roster[0]
	f.honors = 3
	var role := Tuning.role_of(int(f.pos))
	var plain := FighterCard.new()
	plain.display_name = "Nobody Special"
	Legends.note_retired(s, f)
	Legends.note_retired(s, plain)
	Legends.note_retired(s, f)
	_ok(s.world.legends.size() == 1, "one legend remembered, once (%d)" % s.world.legends.size())
	_ok(Legends.offers(s, {}).is_empty(), "not offered in the season he retired")
	s.world.season += 1
	var pool := s.staff_pool()
	_ok(not pool.is_empty() and bool(pool[0].get("legend", false)) and String(pool[0]["name"]) == f.display_name,
		"the legend heads the staff list")
	_ok(pool.size() == Season.STAFF_POOL, "the list is still %d long (%d)" % [Season.STAFF_POOL, pool.size()])
	_ok(int(pool[0]["grade"]) == 5, "three cups make a five-star legend (%d)" % int(pool[0]["grade"]))
	var back := SaveGame.from_dict(SaveGame.to_dict(s))
	_ok(back.world.legends.size() == 1, "legends survive a save")
	var morale := 0.0
	for m in s.club.roster:
		morale += m.morale
	var fans := s.office.fans
	var err := s.hire_captain(pool[0])
	_ok(err == "", "hired (%s)" % err)
	var morale2 := 0.0
	for m in s.club.roster:
		morale2 += m.morale
	_ok(morale2 > morale and s.office.fans > fans, "the room lifts and the town comes out")
	_ok(s.office.coaching(role) == 5 + Legends.TEACH_BONUS, "he teaches a star above his grade (%d)" % s.office.coaching(role))
	_ok(not bool(s.staff_pool()[0].get("legend", false)), "a hired legend leaves the list")
	var back2 := SaveGame.from_dict(SaveGame.to_dict(s))
	_ok(back2.office.coaching(role) == 5 + Legends.TEACH_BONUS, "a hired legend is still a legend after a save")
	print("  %s  club legends come back as better captains, %d checks — %s" % [
		"pass" if bad.is_empty() else "FAIL", checks, "all hold" if bad.is_empty() else ", ".join(bad.slice(0, 6))])
	if bad.is_empty():
		print("\nLEGENDS HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		print("\nFAIL: legends\n\n1 FAILED\n")
		quit(1)
