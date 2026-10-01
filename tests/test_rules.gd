extends SceneTree
## THE RULES, PINNED (29 Sep 2026).
##
##   godot --headless --path . --script res://tests/test_rules.gd
##
## A mutation run by the fresh-eyes audit changed 26 rules one at a time and
## half of them got through the suite: the takedown formula inverted, the round
## tie-break flipped, the three-to-one stop off by one, the table tie-break
## inverted, prize money paid upside down, the physio making knocks LONGER,
## harness prices out of order, the cup's level tie going to the lower seed, the
## ceiling clamp removed, the fee priced off the wrong division. Every one of
## those is a rule a player would notice and no test named. Each is named here,
## as the rule it is — not as the number it happens to produce today.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the rules ===\n")
	_test_takedowns_favour_the_wobbly()
	_test_round_tiebreak_is_downs()
	_test_three_to_one_stops()
	_test_table_order()
	_test_prize_money_falls_with_place()
	_test_physio_shortens_knocks()
	_test_harness_prices_climb()
	_test_cup_level_tie_goes_to_higher_seed()
	_test_ceiling_is_capped()
	_test_fee_is_this_divisions()
	print("")
	if failures.is_empty():
		print("THE RULES HOLD (%d checks)\n" % checks)
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


func _sim() -> MeleeSim:
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 4242, 1.0)
	sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
	return sim


func _team(sim: MeleeSim, t: int) -> Array:
	var out: Array = []
	for m in sim.men:
		if m.team == t:
			out.append(m)
	return out


## A man who is already wobbling is easier to take down and to bullrush.
func _test_takedowns_favour_the_wobbly() -> void:
	var sim := _sim()
	var a = _team(sim, 0)[0]
	var d = _team(sim, 1)[0]
	d.stability = 0.9
	var td_steady: float = sim._takedown_chance(a, d, false)
	var br_steady: float = sim._bullrush_chance(a, d)
	d.stability = 0.2
	var td_wobbly: float = sim._takedown_chance(a, d, false)
	var br_wobbly: float = sim._bullrush_chance(a, d)
	_ok(td_wobbly > td_steady and br_wobbly > br_steady,
		"a wobbling man is easier to take down and to bullrush than a steady one",
		"takedown %.3f → %.3f, bullrush %.3f → %.3f as his stability falls 0.9 → 0.2"
			% [td_steady, td_wobbly, br_steady, br_wobbly])


func _end_round(sim: MeleeSim, standing: Array, downs: Array, at_clock: bool) -> int:
	for t in 2:
		var men := _team(sim, t)
		for i in men.size():
			men[i].state = MeleeSim.State.CLOSING if i < int(standing[t]) else MeleeSim.State.OUT
	sim.round_downs = downs.duplicate()
	sim.rounds_won = [0, 0]
	sim.phase = MeleeSim.Phase.LIVE
	sim.round_t = Tuning.ROUND_TIME if at_clock else 1.0
	sim._check_round_end()
	if sim.rounds_won[0] > 0:
		return 0
	if sim.rounds_won[1] > 0:
		return 1
	return -1 if sim.phase != MeleeSim.Phase.LIVE else -2


## Level on men standing at the bell: the side that put more down takes it.
func _test_round_tiebreak_is_downs() -> void:
	var a := _end_round(_sim(), [3, 3], [4, 2], true)
	var b := _end_round(_sim(), [3, 3], [1, 3], true)
	var c := _end_round(_sim(), [3, 3], [2, 2], true)
	_ok(a == 0 and b == 1 and c == -1,
		"level at the bell, the side with more downs takes the round",
		"3v3 with downs 4-2 → side %d, 1-3 → side %d, 2-2 → %s" % [a, b, "nobody" if c == -1 else str(c)])


## Three standing against one is a stop; two against one fights on.
func _test_three_to_one_stops() -> void:
	var three := _end_round(_sim(), [3, 1], [0, 0], false)
	var two := _end_round(_sim(), [2, 1], [0, 0], false)
	var wipe := _end_round(_sim(), [1, 0], [0, 0], false)
	_ok(three == 0 and two == -2 and wipe == 0,
		"three against one stops the round; two against one fights on",
		"3v1 → %s, 2v1 → %s, 1v0 → %s" % [
			"stopped for side %d" % three if three >= 0 else "still live",
			"still live" if two == -2 else "stopped", "stopped" if wipe == 0 else "still live"])


func _row(club: int, points: int, mf: int, ma: int, rf: int, ra: int) -> Dictionary:
	return {"club": club, "points": points, "mf": mf, "ma": ma, "rf": rf, "ra": ra,
		"played": 1, "won": 0, "drawn": 0, "lost": 0}


## Points, then margin, then rounds — asserted as an order, not as stability.
func _test_table_order() -> void:
	var rows := [
		_row(1, 6, 10, 8, 4, 2),     ## margin +2
		_row(2, 6, 12, 4, 4, 3),     ## margin +8 — above club 1 on margin
		_row(3, 9, 1, 9, 3, 3),      ## most points, awful margin — still top
		_row(4, 6, 10, 8, 5, 1),     ## margin +2 like club 1, more rounds — above it
	]
	var order: Array = []
	for r in League.sort_table(rows):
		order.append(int(r["club"]))
	_ok(order == [3, 2, 4, 1], "the table orders on points, then margin, then rounds",
		"got %s, want [3, 2, 4, 1]" % str(order))


## First is paid most and last least, and the summer pays what the table says.
func _test_prize_money_falls_with_place() -> void:
	var t := 1
	var p1 := Season.purse(1, 8, t)
	var p4 := Season.purse(4, 8, t)
	var p8 := Season.purse(8, 8, t)
	var s := Season.new(MeleeRosters.starting_club(), 777)
	var guard := 0
	while not s.season_complete() and guard < 60:
		guard += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"sendoff": s.answer_send_off()
			"cup": s.sim_cup_tie()
			"promotion": s.answer_promotion(false)
			_: s.skip_event()
	var pos := s.position()
	var tier := s.world.player_tier()
	var want := Season.purse(pos, League.club_count(tier), tier)
	s.roll_over()
	var paid := -1
	for row in s.office.purse_log:
		if String(row["what"]) == UiKit.t("Finished %s") % UiKit.ordinal(pos):
			paid = int(row["cc"])
	_ok(p1 > p4 and p4 > p8 and paid == want,
		"prize money falls with the place, and the summer pays the place finished",
		"1st %d, 4th %d, 8th %d; finished %s and was paid %d (table says %d)"
			% [p1, p4, p8, UiKit.ordinal(pos), paid, want])


## The same season twice, one with an infirmary: every knock is no longer.
func _test_physio_shortens_knocks() -> void:
	## The same three knocks, handed to `post_bout` in two identical seasons that
	## differ only in the infirmary. Real knocks are rare enough that a season can
	## go without one, so they are handed in; Hard regime captains make the knock
	## roll certain (Retro Bowl's "Hard always lets it through").
	var got: Array[int] = []
	for built in [0, 2]:
		var s := Season.new(MeleeRosters.starting_club(), 9001)
		s.office.facilities[ClubOffice.Facility.INFIRMARY] = built
		for pair in [[Tuning.Role.RAIL, Tuning.Role.CENTER], [Tuning.Role.FLANK, Tuning.Role.CENTER]]:
			var c := ClubOffice.captain("Hard", int(pair[0]), int(pair[1]), 3)
			c["regime"] = ClubOffice.Regime.HARD
			s.office.captains.append(c)
		var sim := s.begin_bout()
		sim.run_to_end()
		var five: Array = s.club.starting_five()
		sim.injuries = []
		for i in 3:
			(five[i] as FighterCard).injury = 0
			sim.injuries.append({"idx": i, "events": 4, "card": five[i]})
		s.post_bout(sim)
		var sum := 0
		for i in 3:
			sum += (five[i] as FighterCard).injury
		got.append(sum)
	_ok(got[0] > 0 and got[1] < got[0],
		"an infirmary makes knocks shorter, never longer",
		"three 4-event knocks cost %d events without an infirmary, %d with level 2"
			% [got[0], got[1]])


func _test_harness_prices_climb() -> void:
	var c: Dictionary = Quartermaster.COST
	var s := int(c[Quartermaster.Grade.SERVICEABLE])
	var f := int(c[Quartermaster.Grade.FITTED])
	var t := int(c[Quartermaster.Grade.TOURNAMENT])
	_ok(s < f and f < t, "each harness grade costs more than the one below it",
		"serviceable %d < fitted %d < tournament %d" % [s, f, t])


## Level on rounds AND margin in a knockout: the higher seed goes through.
func _test_cup_level_tie_goes_to_higher_seed() -> void:
	var cup := Cup.new("Test", [10, 11, 12, 13, 14, 15, 16, 17], 7)
	var day := cup.current_round()
	var m: Dictionary = day[0]
	var hi: int = int(m["a"]) if cup.entrants.find(int(m["a"])) < cup.entrants.find(int(m["b"])) else int(m["b"])
	cup.record(m, 1, 1, 2, 2)
	_ok(int(m["winner"]) == hi, "a knockout tie level on rounds and margin goes to the higher seed",
		"%d v %d level → %d went through (higher seed %d)" % [int(m["a"]), int(m["b"]), int(m["winner"]), hi])


## A banked prospect already near the top cannot be pushed past the ceiling.
func _test_ceiling_is_capped() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	## The ground set directly: what is under test is the clamp, not the price.
	s.office.facilities[ClubOffice.Facility.TRAINING] = Career.PROSPECT_GROUND
	var man: FighterCard = s.club.roster[0]
	man.potential = Career.POTENTIAL_CEILING - 1
	s.prospect = man
	s.roll_over()
	## Banked (so the gain was applied — the note says so) and stopped at 99.
	var banked := String(s.last_winter.get("prospect", "")) == man.display_name
	_ok(banked and man.potential == Career.POTENTIAL_CEILING,
		"a prospect cannot be pushed past the game's ceiling",
		"prospect at %d, +%d banked: %s, now %d (ceiling %d)" % [
			Career.POTENTIAL_CEILING - 1, Career.PROSPECT_GAIN, banked, man.potential,
			Career.POTENTIAL_CEILING])


## The fee is the band's share of THIS division's season, pinned at known
## points — a fee priced off the wrong division moves these.
func _test_fee_is_this_divisions() -> void:
	var bad: Array[String] = []
	for t in League.TIERS.size():
		var slack := int(League.TIERS[t]["slack"])
		for r in [40, 55, 70, 85]:
			var want := maxi(1, int(round(Market.BAND_SHARE[Market.band_of(r, t)] * float(slack))))
			var got := Market.fee(r, t)
			if got != want:
				bad.append("rating %d in tier %d: %d, want %d" % [r, t, got, want])
	_ok(bad.is_empty(), "a fee is the band's share of this division's season",
		"%d divisions x 4 ratings%s" % [League.TIERS.size(),
			"" if bad.is_empty() else ": " + "; ".join(bad.slice(0, 4))])
