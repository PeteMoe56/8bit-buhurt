extends SceneTree
## The 27 Sep 2026 audit's season-layer fixes, each held by a check that fails on
## the old code.
##
##   godot --headless --path . --script res://tests/test_audit_season.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — audit: the season ===\n")
	_test_a_card_does_not_pay_a_club_in_debt()
	_test_the_gate_is_paid_on_the_fixture_fought()
	_test_every_cup_is_counted_once()
	_test_a_guest_is_not_a_job()
	_test_the_contract_card_is_the_contract()
	_test_cashing_in_is_capped()
	_test_a_short_line_is_made_whole()
	_test_the_bronze_is_the_players_to_fight()
	_test_a_breakaway_ages()
	_test_rulings()
	_test_the_summer_bill_is_the_summer()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE AUDIT HOLDS (%d checks)\n" % checks)
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


func _season(seed_v: int = 5150) -> Season:
	return Season.new(MeleeRosters.starting_club(), seed_v)


## At -10, a "-6 CC" card used to hand the club +10.
func _test_a_card_does_not_pay_a_club_in_debt() -> void:
	var s := _season()
	s.office.credits = -10
	s.dilemma = {"id": "van", "man": 0}
	var out_before := int(s.office.books_out.get(ClubOffice.LINE_CLUB, 0))
	s.answer_dilemma(0)
	_ok(s.office.credits == -10, "a card does not pay a club in debt",
		"-10 CC, chose the -6 CC option: now %d" % s.office.credits)
	var s2 := _season()
	s2.office.credits = 4
	s2.dilemma = {"id": "van", "man": 0}
	s2.answer_dilemma(0)
	_ok(s2.office.credits == 0 and int(s2.office.books_out.get(ClubOffice.LINE_CLUB, 0)) == out_before + 4,
		"and what it does take is on the books",
		"4 CC, a -6 card takes 4: now %d, books out %d"
			% [s2.office.credits, int(s2.office.books_out.get(ClubOffice.LINE_CLUB, 0))])


## The gate line names the venue; it must name the venue of the fixture just
## fought, all season — the last matchday included.
func _test_the_gate_is_paid_on_the_fixture_fought() -> void:
	var s := _season(4242)
	var wrong: Array[String] = []
	var n := 0
	while not s.season_complete() and n < 30:
		n += 1
		if s.cup_pending():
			s.sim_cup_tie()
			continue
		var where := String(Venue.NAME[s.venue_kind()])
		s.skip_event()
		var paid := ""
		for row in s.office.purse_log:
			if String(row["what"]).begins_with("The gate"):
				paid = String(row["what"])
				break
		if not paid.ends_with(where):
			wrong.append("event %d: fought %s, paid '%s'" % [n, where, paid])
	_ok(wrong.is_empty() and n > 3, "the gate is paid on the fixture fought",
		"%d matchdays checked%s" % [n, "" if wrong.is_empty() else ": " + ", ".join(wrong)])


## Every honour is counted exactly once by the summer that follows it.
func _test_every_cup_is_counted_once() -> void:
	var s := _season(777)
	var seasons := 0
	while seasons < 3:
		var guard := 0
		while not s.season_complete() and guard < 40:
			guard += 1
			if s.cup_pending():
				s.sim_cup_tie()
			else:
				s.skip_event()
		s.roll_over()
		seasons += 1
	var uncounted := 0
	var mine := 0
	for h in s.honors():
		if not bool(h.get("counted", false)):
			uncounted += 1
		if int(h.get("exit", -1)) > 0:
			mine += 1
	_ok(uncounted <= 1, "every cup is counted by the summer after it",
		"%d honours over 3 seasons, %d with you in them, %d not yet counted (a Worlds still being fought may be)"
			% [s.honors().size(), mine, uncounted])


func _test_a_guest_is_not_a_job() -> void:
	var s := _season(99)
	s.coach.reputation = Coach.REP_MAX
	s.world.clubs.append({"id": s.world.clubs.size(), "name": "Guest XI", "short": "GST",
		"tier": -1, "power": 20, "titles": 0, "guest": true})
	var gid: int = s.world.clubs.size() - 1
	_ok(not Jobs.interested(s.coach, s.world, gid), "a Worlds guest never offers a job",
		"guest id %d, coach at max reputation" % gid)


func _test_the_contract_card_is_the_contract() -> void:
	var s := _season(31)
	var f: FighterCard = s.club.roster[0]
	f.years = 0
	f.morale = Contracts.MORALE_REFUSES - 0.05
	var refused := s.resign(f)
	f.morale = 0.7
	f.age = 34
	s.office.cap_level = 20
	var err := s.resign(f)
	_ok(refused != "" and err == "" and f.years == int(Contracts.demand(f)["years"])
		and f.years == 2 and f.wage_agreed == s.resign_cost(f),
		"re-signing does what the card says",
		"unhappy man refused ('%s'); a 34-year-old signed for %d years at the card's price"
			% [refused.left(40), f.years])


func _test_cashing_in_is_capped() -> void:
	var f := FighterCard.new()
	f.age = 30
	f.level = Career.LEVEL_BAR_CAP
	var at_cap := Career.cash_value(f)
	f.level = Career.LEVEL_BAR_CAP + 40
	_ok(Career.cash_value(f) == at_cap, "cashing in stops rising where the bar stops",
		"level %d and level %d both pay %d" % [Career.LEVEL_BAR_CAP, f.level, at_cap])


func _test_a_short_line_is_made_whole() -> void:
	var s := _season(12)
	var n := 0
	for f in s.club.active_eight():
		if n < 5:
			f.injury = 3
		n += 1
	var had := s.club.starting_five().size()
	var did := s.ensure_a_line()
	_ok(had < 5 and s.club.starting_five().size() == 5 and s.club.power() > 0,
		"a club short of fit men still puts five on the list",
		"%d fit in the party -> %d, rating %d: %s" % [had, s.club.starting_five().size(),
			s.club.power(), "; ".join(did)])


func _test_the_bronze_is_the_players_to_fight() -> void:
	var c := Cup.new("Test Cup", [0, 1, 2, 3], 7, 3)
	## Round one: the player (3, bottom seed) meets 0 and loses; 1 beats 2.
	for m in c.current_round():
		var a := int(m["a"])
		c.record(m, 2 if a != 3 else 0, 0 if a != 3 else 2, 3, 0)
	c.advance()
	var m := c.player_match()
	_ok(not m.is_empty() and String(m.get("round", "")) == "Third-place match" and c.player_alive(),
		"the third-place match is offered to the player",
		"after losing the semi: player_match = %s" % String(m.get("round", "(none)")))
	c.settle_third(func(a, b): return [2, 0, 3, 0], true)
	_ok(not bool(c.third_place.get("played", false)), "and the season path does not sim it for him",
		"still unplayed after settle_third(hold)")


func _test_a_breakaway_ages() -> void:
	var s := _season(606)
	var cid := -1
	for id in s.world.clubs_in(s.world.player_tier()):
		if id != s.world.player_club:
			cid = id
			break
	var men: Array[FighterCard] = []
	for i in 6:
		var f := FighterCard.new()
		f.display_name = "Walker%d" % i
		f.pos = i % 5
		f.age = 25
		f.active = true
		men.append(f)
	s.splinter_rosters[cid] = men
	s.world.clubs[cid]["splinter"] = true
	var guard := 0
	while not s.season_complete() and guard < 40:
		guard += 1
		if s.cup_pending():
			s.sim_cup_tie()
		else:
			s.skip_event()
	s.roll_over()
	var aged := 0
	for f in s.splinter_rosters.get(cid, []):
		if String(f.display_name).begins_with("Walker") and f.age == 26:
			aged += 1
	_ok(aged >= 4 and int(s.world.clubs[cid]["power"]) == s.club_for(cid).power(),
		"a breakaway has a winter",
		"%d of 6 founders a year older; power %d is its men's" % [aged,
			int(s.world.clubs[cid]["power"])])


## PETE'S RULINGS OF 27 SEP (after the audit).
func _test_rulings() -> void:
	## Pete, 29 Sep 2026: a bout the app lost starts again from before the match
	## — no forfeit, no result posted, the mark cleared, said once.
	SaveGame.set_namespace("audit")
	var s := Season.new(MeleeRosters.starting_club(), 4040)
	var before: Dictionary = s._my_row()
	s.mark_bout_live(false)
	SaveGame.save(s, 1)
	var back := SaveGame.load_slot(1)
	var row: Dictionary = back._my_row() if back != null else {}
	_ok(back != null and back.world.event == 0 and int(row.get("ra", 0)) == int(before.get("ra", 0))
		and int(row.get("played", 0)) == int(before.get("played", 0))
		and back.last_interrupted != "" and back.bout_live.is_empty() and back.opponent_id() == s.opponent_id(),
		"a bout the app lost starts again from before the match",
		"event %d, rounds against %d -> %d, same opponent %s: '%s'" % [back.world.event if back else -1,
			int(before.get("ra", 0)), int(row.get("ra", 0)),
			back.opponent_id() == s.opponent_id() if back else false, back.last_interrupted.left(50) if back else ""])
	var again := SaveGame.load_slot(1)
	_ok(again != null and again.world.event == 0 and again.last_interrupted == "",
		"and it is said once, not again on the next load",
		"second load: event %d" % (again.world.event if again else -1))
	SaveGame.delete(1)
	## A posted bout clears the mark.
	var p := Season.new(MeleeRosters.starting_club(), 4041)
	p.mark_bout_live(false)
	var sim := p.begin_bout()
	sim.run_to_end()
	p.post_bout(sim)
	_ok(p.bout_live.is_empty(), "a bout that finishes clears the mark", "posted, mark empty")

	## Potential as a range the staff narrow.
	var m := Season.new(MeleeRosters.starting_club(), 777)
	var f: FighterCard = m.market()[0]
	var blind: Vector2i = m.potential_range(f)
	m.office.credits = 200
	m.hire_captain(ClubOffice.captain("Scout", Tuning.Role.RAIL, Tuning.Role.CENTER, 5))
	var sharp: Vector2i = m.potential_range(f)
	var own: Vector2i = m.potential_range(m.club.roster[0])
	_ok(blind.x <= f.potential and f.potential <= blind.y and blind.y - blind.x >= 6
		and sharp.x == sharp.y and sharp.x == f.potential
		and own.x == own.y and own.x == m.club.roster[0].potential,
		"a stranger's ceiling is a range; a five-star captain reads it exactly; your own men are exact",
		"no staff %d-%d (true %d); five-star %d-%d" % [blind.x, blind.y, f.potential, sharp.x, sharp.y])


## THE SUMMER BILL SHOWN IS THE SUMMER CHARGED (28 Sep 2026). A club holding
## exactly `summer_bill()` pays its dues and every bill and ends on zero with
## nothing lost; one credit short and something falls. The warning comes once,
## in the last two matchdays, and only to a club that is short.
func _test_the_summer_bill_is_the_summer() -> void:
	var s := _season(2024)
	var o := s.office
	if o.credits >= o.arena.next_cost():
		o.build_arena()
	for r in Federation.rules():
		o.compliance[r] = maxi(1, Federation.required(o.tier, r))
	var bill := o.summer_bill()
	o.credits = bill
	o.spend(League.dues_for(o.tier), ClubOffice.LINE_FEDERATION)
	var paid := o.pay_upkeep()
	var clean: bool = (paid["lost"] as Array).is_empty() and (paid["lapsed"] as Array).is_empty()
	var s2 := _season(2024)
	for r in Federation.rules():
		s2.office.compliance[r] = maxi(1, Federation.required(s2.office.tier, r))
	s2.office.credits = s2.office.summer_bill() - 1
	s2.office.spend(League.dues_for(s2.office.tier), ClubOffice.LINE_FEDERATION)
	var p2 := s2.office.pay_upkeep()
	var fell: int = (p2["lost"] as Array).size() + (p2["lapsed"] as Array).size()
	_ok(bill > 0 and clean and o.credits == 0 and fell > 0,
		"the summer bill shown is exactly what the summer charges",
		"bill %d: holding it ends on %d with nothing lost; one short loses %d" % [bill, o.credits, fell])

	var w := _season(2025)
	w.office.credits = 0
	var early := w.summer_warning()
	var guard := 0
	while w.world.events_this_season() - w.world.event > 2 and guard < 40:
		guard += 1
		if w.cup_pending():
			w.sim_cup_tie()
		else:
			w.skip_event()
	w.office.credits = 0
	var late := w.summer_warning()
	var again := w.summer_warning()
	w.office.credits = w.office.summer_bill() + 50
	w._summer_warned = -1
	var flush := w.summer_warning()
	_ok(early == "" and late != "" and again == "" and flush == "",
		"a short club is warned once, in the last two matchdays",
		"early '%s', late '%s', again '%s', with money '%s'" % [early, late.left(40), again, flush])
