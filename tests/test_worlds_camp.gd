extends SceneTree
## THE WORLDS CAMP (11 Oct 2026): between the pools and the knockout, a camp
## the club pays for per man. Opens once, only when through the pools, charges
## exactly, mends the men who went, and survives a save in between.
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


## A National champion at the Worlds, its pool bouts simmed until the knockout
## opens (or it goes out). Returns null when the seed's club went out in the pools.
func _at_knockout(seed_v: int) -> Season:
	var s := Season.new(MeleeRosters.starting_club_with_reserve(), seed_v)
	s.bid_offers.clear()
	var me := s.world.player_club
	s.world.clubs[me]["tier"] = League.Tier.NATIONAL
	s.office.tier = League.Tier.NATIONAL
	s.office.credits = 100
	s.world.calendar = [Calendar.week(Calendar.Kind.WORLDS)]
	s.world.week = 0
	s.world.worlds = s.world._build_worlds([{"club": me}])
	s.world.worlds.set_meta("season", s.world.season)
	## A FIELD THE CLUB GETS THROUGH: the guests are made weak, so the pools
	## end with the club in the knockout and the camp is what is tested.
	for id in s.world.worlds.entrants:
		if int(id) != me:
			s.world.clubs[int(id)]["power"] = 20
	var guard := 0
	while guard < 12 and s.blocked_by() == "cup" and s.world.worlds.stage == Cup.Stage.POOLS:
		guard += 1
		s.sim_cup_tie()
	return s if s.blocked_by() == "camp" else null


func _run() -> void:
	var opened := 0
	for seed_v in [7001, 7002, 7003, 7004, 7005, 7006]:
		var s := _at_knockout(seed_v)
		if s == null:
			continue
		opened += 1
		## A save between the pools and the camp keeps the camp open.
		var back := SaveGame.from_dict(SaveGame.to_dict(s))
		_ok(back.blocked_by() == "camp", "camp survives a save (seed %d)" % seed_v)
		for f in s.club.active_eight():
			f.armor = 0.3
		var cc := s.office.credits
		var pick := WorldsCamp.Pick.EIGHT if opened % 2 == 1 else WorldsCamp.Pick.SKIP
		var want := WorldsCamp.cost(s, pick)
		s.answer_camp(pick)
		_ok(s.office.credits == cc - want, "camp charges %d CC (seed %d), charged %d" % [want, seed_v, cc - s.office.credits])
		var mended := 0
		for f in s.club.active_eight():
			if f.armor > 0.3:
				mended += 1
		_ok(mended == (8 if pick == WorldsCamp.Pick.EIGHT else 0) or (pick == WorldsCamp.Pick.EIGHT and mended == s.club.active_eight().size()),
			"the men who went are mended (seed %d): %d" % [seed_v, mended])
		_ok(s.blocked_by() == "cup", "after the camp the knockout bout is next (seed %d)" % seed_v)
		_ok(not WorldsCamp.due(s), "the camp opens once (seed %d)" % seed_v)
	_ok(opened >= 2, "the camp opened for a club through the pools (%d of 6)" % opened)
	print("  %s  the Worlds camp opens once, charges per man and mends them, %d checks — %s" % [
		"pass" if bad.is_empty() else "FAIL", checks, "all hold" if bad.is_empty() else ", ".join(bad.slice(0, 6))])
	if bad.is_empty():
		print("\nTHE WORLDS CAMP HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		print("\nFAIL: the Worlds camp\n\n1 FAILED\n")
		quit(1)
