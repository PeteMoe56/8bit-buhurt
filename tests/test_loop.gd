extends SceneTree
## THE LOOP, PINNED (29 Sep 2026).
##
##   godot --headless --path . --script res://tests/test_loop.gd
##
## The second fresh-eyes audit designed its own 21 mutations — rules a player
## notices inside a season or two — and 14 got through: the wrong club relegated,
## the knockout margin reversed, the purse shrinking with the division, knocks
## that never heal, sims and practice that build nobody, a man missing every
## week, tired men running faster, the bench losing condition, a level bout going
## to fewer downs, the ground forgetting its state on load, the Toxic band, men
## retiring at 27, and the squad's armour colour reversed. Each is named here as
## the rule it is. `tools/mutants.py` re-breaks every one.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the loop ===\n")
	_test_the_bottom_goes_down()
	_test_knockout_margin()
	_test_purse_rises_with_division()
	_test_knocks_heal()
	_test_a_sim_still_builds()
	_test_practice_builds()
	_test_availability_is_rare()
	_test_tired_men_slow()
	_test_the_bench_recovers()
	_test_level_bout_goes_to_more_downs()
	_test_ground_survives_the_save()
	_test_toxic_band()
	_test_retirement_waits()
	_test_armour_colour()
	_test_paid_session_trains_the_five()
	print("")
	if failures.is_empty():
		print("THE LOOP HOLDS (%d checks)\n" % checks)
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


## Relegation takes the clubs at the very bottom, in order.
func _test_the_bottom_goes_down() -> void:
	var rows: Array = []
	for c in 8:
		rows.append({"club": 100 + c})
	var bad: Array[String] = []
	var checked := 0
	for t in League.TIERS.size():
		var n := int(League.TIERS[t]["down"])
		if n <= 0:
			continue
		checked += 1
		var want: Array = []
		for i in n:
			want.append(107 - i)
		var got := League.relegated(t, rows)
		if got != want:
			bad.append("tier %d: %s, want %s" % [t, str(got), str(want)])
	_ok(checked > 0 and bad.is_empty(), "relegation takes the bottom of the table",
		"%d divisions that relegate%s" % [checked, "" if bad.is_empty() else ": " + "; ".join(bad)])


## Level on rounds in a knockout, the bigger margin goes through.
func _test_knockout_margin() -> void:
	var out: Array[bool] = []
	for flip in [false, true]:
		var cup := Cup.new("Test", [10, 11, 12, 13, 14, 15, 16, 17], 7)
		var m: Dictionary = cup.current_round()[0]
		var ma := 2 if flip else 6
		var mb := 6 if flip else 2
		cup.record(m, 1, 1, ma, mb)
		var bigger: int = int(m["b"]) if flip else int(m["a"])
		out.append(int(m["winner"]) == bigger)
	_ok(out[0] and out[1], "a knockout level on rounds goes to the bigger margin",
		"6-2 on margin for side a: %s; for side b: %s" % [out[0], out[1]])


## The same place pays more the higher the division.
func _test_purse_rises_with_division() -> void:
	var pays: Array[int] = []
	for t in League.TIERS.size():
		pays.append(Season.purse(1, 8, t))
	var rising := true
	for i in range(1, pays.size()):
		rising = rising and pays[i] > pays[i - 1]
	_ok(rising, "the same place pays more in a higher division", "1st of 8 by division: %s" % str(pays))


## A knock counts down one event at a time.
func _test_knocks_heal() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var man: FighterCard = s.club.roster[s.club.roster.size() - 1]
	man.injury = 3
	var guard := 0
	while s.blocked_by() != "" and guard < 10:
		guard += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"sendoff": s.answer_send_off()
			"cup": s.sim_cup_tie()
			"promotion": s.answer_promotion(false)
	s.skip_event()
	_ok(man.injury == 2, "a knock heals by one each event", "3 events out, one event later: %d" % man.injury)


## A simmed event still pays every man in the five.
func _test_a_sim_still_builds() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var five: Array = s.club.starting_five()
	var before: Array[int] = []
	for f in five:
		before.append((f as FighterCard).xp)
	SeasonBouts._award_sim_xp(s)
	var gains: Array[int] = []
	for i in five.size():
		gains.append((five[i] as FighterCard).xp - before[i])
	var all_paid := true
	for g in gains:
		all_paid = all_paid and g >= Season.XP_SIMMED and g > 0
	_ok(all_paid, "a simmed event pays the five their XP", "gains %s (XP_SIMMED %d)" % [str(gains), Season.XP_SIMMED])


## A week's practice is worth its base to a man OUTSIDE the five (the five's week
## is mostly Saturday — PRACTICE_STARTER — so their floor is one point).
func _test_practice_builds() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var five: Array = s.club.starting_five()
	var rest: Array = []
	var before := {}
	for f in s.club.roster:
		before[f] = (f as FighterCard).xp
		if not five.has(f):
			rest.append(f)
	## A WHOLE WEEK'S PRACTICE (the paid one, which is not shared out).
	SeasonBouts._practice(s, true)
	var total := 0
	for f in rest:
		total += (f as FighterCard).xp - int(before[f])
	var mean := float(total) / float(maxi(1, rest.size()))
	_ok(not rest.is_empty() and mean >= Career.PRACTICE_BASE - 0.01,
		"practice builds the men outside the five by at least its base",
		"mean gain %.1f XP across %d men outside the five (base %.1f)" % [mean, rest.size(), Career.PRACTICE_BASE])
	## AND THE SATURDAYS SHARE IT OUT (30 Sep 2026): a season of weekly practice
	## is worth what a season of league-day practice was. Forty weeks, on average.
	var before2 := {}
	for f in rest:
		before2[f] = (f as FighterCard).xp
	for wk in 40:
		s.world.week = wk % maxi(1, s.world.weeks_this_season())
		s.world.season = 1 + wk / maxi(1, s.world.weeks_this_season())
		SeasonBouts._practice(s)
	var total2 := 0
	for f in rest:
		total2 += (f as FighterCard).xp - int(before2[f])
	var per := float(total2) / float(maxi(1, rest.size())) / 40.0
	var want := Career.PRACTICE_BASE * s.practice_share()
	_ok(absf(per - want) <= want * 0.2,
		"and a week's practice is the league's share of it",
		"%.2f XP a week against %.2f (base %.1f x share %.2f)" % [per, want, Career.PRACTICE_BASE, s.practice_share()])


## A man missing the weekend is the exception: about one week in three at most.
func _test_availability_is_rare() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var weeks := 60
	var short := 0
	for e in weeks:
		s.world.event = e
		SeasonBouts._roll_availability(s)
		for f in s.club.active_eight():
			if not (f as FighterCard).available:
				short += 1
				break
	## 8 men at 5.5% each is ~36% of weeks with somebody out.
	_ok(short < int(weeks * 0.6), "a man missing the weekend is the exception",
		"%d of %d weeks had somebody out (expected about 36%%)" % [short, weeks])


func _sim() -> MeleeSim:
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 4242, 1.0)
	sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
	return sim


## An empty tank slows a man down.
func _test_tired_men_slow() -> void:
	var sim := _sim()
	sim.phase = MeleeSim.Phase.LIVE
	var m = sim.men[0]
	m.tank = m.eff_tank()
	var fresh: float = sim._speed(m)
	m.tank = 0.0
	var empty: float = sim._speed(m)
	_ok(empty < fresh, "a tired man moves slower than a fresh one",
		"full tank %.1f, empty tank %.1f" % [fresh, empty])


## A man who sat the round out comes back fresher.
func _test_the_bench_recovers() -> void:
	var sim := _sim()
	var on := {}
	for m in sim.men:
		on[m.card] = true
	var bench: FighterCard = null
	for f in sim.clubs[0].roster:
		if not on.has(f):
			bench = f
			break
	if bench == null:
		_ok(false, "the bench recovers in the corner", "the fixture club has no bench")
		return
	sim.conditions[bench] = 0.5
	sim._corner_recovery()
	var after := float(sim.conditions.get(bench, 0.0))
	_ok(after > 0.5, "the bench recovers in the corner", "a benched man at 0.50 comes out at %.2f" % after)


## Level on rounds, the side that put more men down wins the bout.
func _test_level_bout_goes_to_more_downs() -> void:
	var sim := _sim()
	sim.rounds_won = [1, 1]
	sim.downs = [7, 4]
	var a := sim.bout_winner()
	sim.downs = [3, 5]
	var b := sim.bout_winner()
	sim.downs = [4, 4]
	var c := sim.bout_winner()
	_ok(a == 0 and b == 1 and c == -1, "a bout level on rounds goes to more downs",
		"downs 7-4 → %d, 3-5 → %d, 4-4 → %d" % [a, b, c])


## The ground's wear is kept across a save.
func _test_ground_survives_the_save() -> void:
	var o := ClubOffice.new()
	o.arena.condition = 0.41
	var back := ClubOffice.from_dict(o.to_dict())
	_ok(is_equal_approx(back.arena.condition, 0.41), "the ground's condition survives a save",
		"0.41 saved, %.2f loaded" % back.arena.condition)


## The morale words keep their bands: a man at 0.12 is Toxic, at 0.20 Bad.
func _test_toxic_band() -> void:
	var f := FighterCard.new()
	f.morale = 0.12
	var low := f.morale_word()
	f.morale = 0.20
	var bad := f.morale_word()
	_ok(low == UiKit.t("Toxic") and bad == UiKit.t("Bad"), "morale 0.12 reads Toxic and 0.20 reads Bad",
		"0.12 → %s, 0.20 → %s" % [low, bad])


## Nobody considers retiring before RETIRE_FROM.
func _test_retirement_waits() -> void:
	var f := FighterCard.new()
	var early: Array[String] = []
	for age in range(20, Career.RETIRE_FROM):
		f.age = age
		if Career.retire_chance(f, 0.0) > 0.0:
			early.append(str(age))
	f.age = Career.RETIRE_FROM + 3
	var later := Career.retire_chance(f, 0.0)
	_ok(early.is_empty() and later > 0.0, "nobody retires before %d" % Career.RETIRE_FROM,
		"ages with a chance before then: %s; at %d: %.2f" % [
			"none" if early.is_empty() else ", ".join(early), Career.RETIRE_FROM + 3, later])


## Good kit reads green, worn kit reads red on the squad sheet.
func _test_armour_colour() -> void:
	var good := SeasonSquadTab.armor_col(0.95)
	var mid := SeasonSquadTab.armor_col(0.7)
	var worn := SeasonSquadTab.armor_col(0.4)
	_ok(good == UiKit.UP and mid == UiKit.DIM and worn == UiKit.DOWN,
		"the squad sheet colours kit green when good and red when worn",
		"95%% %s, 70%% %s, 40%% %s" % [
			"UP" if good == UiKit.UP else "other", "DIM" if mid == UiKit.DIM else "other",
			"DOWN" if worn == UiKit.DOWN else "other"])


## A PAID SESSION TRAINS THE FIVE AT THE FULL RATE (Pete, 29 Sep 2026, #11) —
## and what the button promises is what it pays.
func _test_paid_session_trains_the_five() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 999
	s.office.captains.append(ClubOffice.captain("Coach", Tuning.Role.RAIL, Tuning.Role.CENTER, 2))
	var five: Array = s.club.starting_five()
	var before := {}
	for f in five:
		before[f] = (f as FighterCard).xp
	var promised := SeasonBouts.session_xp(s)
	var err := s.run_session()
	var total := 0
	for f in five:
		total += (f as FighterCard).xp - int(before[f])
	var mean := float(total) / float(five.size())
	_ok(err == "" and mean >= Career.PRACTICE_BASE and absf(mean - float(promised)) <= 1.0,
		"a paid session trains the five at the full rate, and pays what its button says",
		"mean %.1f XP per man in the five (button said +%d, base %.1f)" % [mean, promised, Career.PRACTICE_BASE])
