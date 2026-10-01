extends SceneTree
## THE CLIMB, AS PETE RULED IT (29 Sep 2026, decisions #8, #9, #12, #13).
##
##   godot --headless --path . --script res://tests/test_climb.gd
##
## One league up at a time, by the table or by a job. The ground comes before
## the division: a club can build one division ahead and cannot go up without
## the ground for it. The cap binds. A club that hoards is told.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the climb ===\n")
	_test_jobs_one_league_up()
	_test_ground_before_division()
	_test_build_one_ahead()
	_test_cap_binds_a_good_squad()
	_test_hoarding_is_said()
	print("")
	if failures.is_empty():
		print("THE CLIMB HOLDS (%d checks)\n" % checks)
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


## A coach at the very top of the reputation scale, running a bottom-division
## club, is offered nothing above the division next door.
func _test_jobs_one_league_up() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.coach.reputation = Coach.REP_MAX
	var here := s.world.player_tier()
	var too_high := 0
	var any := 0
	for season_no in range(3, 9):
		s.world.season = season_no
		for id in Jobs.offers(s.coach, s.world):
			any += 1
			if int(s.world.clubs[id]["tier"]) > here + 1:
				too_high += 1
	_ok(any > 0 and too_high == 0, "a job offer comes from one division up at most",
		"%d offers over six seasons to a top-reputation coach in tier %d; %d from further up"
			% [any, here, too_high])


func _promotable() -> Season:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var guard := 0
	while guard < 200:
		guard += 1
		if s.promotion_offered():
			return s
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"sendoff": s.answer_send_off()
			"cup": s.sim_cup_tie()
			"":
				if s.season_complete():
					s.world.stay_down = false
					s.roll_over()
				else:
					s.skip_event()
	return null


## Finishing in a promotion place with a back field is not enough: the answer
## is refused and the question stays open. Build the ground, and it is taken.
func _test_ground_before_division() -> void:
	var s := _promotable()
	if s == null:
		_ok(false, "no ground, no promotion", "no promotion place came up in 200 steps")
		return
	var up := s.world.player_tier() + 1
	s.office.arena.level = 0
	var refused := s.answer_promotion(true)
	var still_open := s.promotion_offered()
	s.office.arena.level = Arena.level_for_tier(up)
	var taken := s.answer_promotion(true)
	_ok(refused != "" and still_open and taken == "" and not s.promotion_offered(),
		"no ground, no promotion — and building it lets the club go up",
		"with a %s: '%s'; still open %s; with a %s: %s" % [Arena.arena_name_of(0), refused.left(60),
			still_open, Arena.arena_name_of(Arena.level_for_tier(up)), "taken" if taken == "" else taken])


## A club may build the ground for the division above, not two above.
func _test_build_one_ahead() -> void:
	var a := Arena.new()
	a.level = Arena.level_for_tier(1) - 1
	var ok_ahead := a.can_build(0, 999) == ""
	var b := Arena.new()
	b.level = Arena.level_for_tier(2) - 1
	var too_far := b.can_build(0, 999)
	_ok(ok_ahead and too_far != "", "a club builds one division ahead, not two",
		"tier 0 building the %s: %s; tier 0 building the %s: '%s'" % [
			Arena.arena_name_of(Arena.level_for_tier(1)), "allowed" if ok_ahead else "refused",
			Arena.arena_name_of(Arena.level_for_tier(2)), too_far.left(60)])


## The cap is a wall: eight men from the band ABOVE your division — the better
## guys Pete means — bill more than your division's unraised cap, so buying them
## takes cap raises. (The top division is measured against ten points past its
## own band.)
func _test_cap_binds_a_good_squad() -> void:
	var under: Array[String] = []
	var shown: Array[String] = []
	for t in League.TIERS.size():
		var r: int
		if t + 1 < League.TIERS.size():
			r = int((League.TIERS[t + 1]["power"] as Array)[1])
		else:
			r = int((League.TIERS[t]["power"] as Array)[1]) + 10
		var f := FighterCard.new()
		f.strength = r; f.base = r; f.skill = r; f.gas = r
		var bill := ClubOffice.wage(f) * 8
		shown.append("t%d %d vs %d" % [t, bill, int(ClubOffice.TIER_CAP[t])])
		if bill <= int(ClubOffice.TIER_CAP[t]):
			under.append("tier %d" % t)
	_ok(under.is_empty(), "better men than the division holds need cap raises",
		"eight better men's bill vs the unraised cap: %s" % ", ".join(shown))


## Money piling up with nothing spent is said once a season, by one of the men.
func _test_hoarding_is_said() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	## TWO LEAGUE DAYS IN, not two Saturdays: a cup round is a week too now.
	var gs := 0
	while (s.world.event < 2 or s.blocked_by() != "") and gs < 20:
		gs += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"sendoff": s.answer_send_off()
			"cup": s.sim_cup_tie()
			_: s.skip_event()
	s.office.credits = s.office.summer_bill() * Season.HOARD_SUMMERS + 50
	s.office.books_out = {}
	var first := s.hoard_note()
	var again := s.hoard_note()
	var spender := Season.new(MeleeRosters.starting_club(), 4243)
	## TWO LEAGUE DAYS IN, not two Saturdays: a cup round is a week too now.
	var gspender := 0
	while (spender.world.event < 2 or spender.blocked_by() != "") and gspender < 20:
		gspender += 1
		match spender.blocked_by():
			"bid": spender.decline_bid()
			"dilemma": spender.answer_dilemma(0)
			"sendoff": spender.answer_send_off()
			"cup": spender.sim_cup_tie()
			_: spender.skip_event()
	spender.office.credits = spender.office.summer_bill() * Season.HOARD_SUMMERS + 50
	spender.office.books_out = {ClubOffice.LINE_SQUAD: 14}
	var quiet := spender.hoard_note()
	_ok(first != "" and again == "" and quiet == "",
		"a club sitting on its money is told once a season, and a spending club is not",
		"'%s'" % first.left(90))
