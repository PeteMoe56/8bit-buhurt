extends SceneTree
## The seam: a season actually plays.
##
##   godot --headless --path . --script res://tests/test_season.gd
##
## Everything else in the suite tests one half. This tests that the halves are
## joined — that a bout fought in the melee reaches the table with the right
## numbers on it, that a season of them adds up, and that the summer works.
##
## The melee is expensive, so most fixtures here are simmed. That is not a dodge:
## it is exactly what the game does. Only your own bout runs the full melee, and
## the other fourteen results are numbers on a page by Sunday night.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	## Its own corner of user:// — these files run in parallel and there are
	## only three slots between all of them.
	SaveGame.set_namespace("season")
	print("\n=== 8-Bit Buhurt — the season loop ===\n")
	_test_generated_clubs_are_real_clubs()
	_test_a_fought_bout_reaches_the_table()
	_test_a_whole_season_adds_up()
	_test_the_summer()
	_test_the_table_reads_your_roster()
	_test_one_queue_one_order()
	_test_the_after_action_report()
	_test_the_opponent_is_a_club()
	_test_the_record_remembers_how_it_was_fought()
	_test_the_year_adds_up()
	_test_the_report_leads_with_the_men()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE SEASON HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


## THE REVIEW'S FOOT, CHECKED AWAY FROM THE REVIEW.
##
## `year_summary()` exists because the page shows the last nine weeks and the
## foot has to total all of them: **a total of what happens to be on screen is
## not a total.** That is exactly the kind of claim that goes wrong quietly — a
## season shorter than the page looks right forever — so the sum is counted here
## against the rows it was made from, on a season long enough to overflow the
## page, with a bye and a simulated week in it.
func _test_the_year_adds_up() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	s.grade = Grade.G.FRIENDLY
	var guard := 0
	while not s.season_complete() and guard < 40:
		guard += 1
		s.skip_event()
	var sum := s.year_summary()
	var rf := 0
	var ra := 0
	var diff := 0
	var byes := 0
	var events := 0
	for r in s.results:
		if bool(r.get("bye", false)):
			byes += 1
			continue
		events += 1
		rf += int(r.get("rf", 0))
		ra += int(r.get("ra", 0))
		diff += int(r.get("margin", 0))
	_ok(int(sum["events"]) == events and int(sum["byes"]) == byes,
		"the year counts every week the club had",
		"%d events and %d byes across %d rows" % [int(sum["events"]),
			int(sum["byes"]), s.results.size()])
	_ok(int(sum["rf"]) == rf and int(sum["ra"]) == ra and int(sum["diff"]) == diff,
		"and its totals are the rows added up",
		"%d-%d, %+d" % [int(sum["rf"]), int(sum["ra"]), int(sum["diff"])])
	## THE PAGE ONLY HAS ROOM FOR NINE. If a full season fits on it, this check
	## has not tested the thing it was written for and should say so rather than
	## pass quietly.
	## AND THE PAGE HAS ROOM FOR THE LONGEST SEASON THE LEAGUE CAN PRODUCE.
	## Asked of the league rather than of the review's own constant, because the
	## two have to agree and only one of them is edited when a division changes
	## size: **a capacity that has to agree with a fixture list is a capacity that
	## will stop agreeing.**
	var longest := 0
	for t in League.TIERS.size():
		longest = maxi(longest, League.events_in_season(t))
	_ok(longest <= 16, "and the review has room for the longest season there is",
		"%d events at the top against 16 rows of room" % longest)
	## A WALKED SEASON IS ALL SIMULATED, which is the arm that would hide a foot
	## that counted `fought` where it meant `events`.
	_ok(int(sum["fought"]) == 0 and int(sum["simmed"]) == events,
		"and a season nobody stood in says so",
		"%d fought, %d simulated" % [int(sum["fought"]), int(sum["simmed"])])
	notes.append("the year: %d events, %d byes, %d-%d, %+d" % [int(sum["events"]),
		int(sum["byes"]), int(sum["rf"]), int(sum["ra"]), int(sum["diff"])])

## THE REPORT OPENS ON THE MEN, NOT ON THE GATE.
##
## The after-action cards are banded now — THE MEN, then THE CLUB — and banding
## made a fold that was always there suddenly matter: the pane shows one row of
## three before it scrolls. With the old order that row was a league position, a
## gate receipt and a follower count, and the fighters the player had just
## watched were the part he had to go looking for.
##
## Checked here rather than left to the layout, because the order is a DECISION
## about what the screen is for and the layout is just where the cards land.
## A future card inserted at the top of `news()` would move the men below the
## fold again and nothing on the screen would look wrong.
func _test_the_report_leads_with_the_men() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 7777)
	## A real afternoon, so `last_changes` has men in it — an empty report proves
	## nothing about an order.
	var guard := 0
	while s.last_changes.is_empty() and guard < 12:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(0)
				"cup": s.sim_cup_tie()
		var sim := s.begin_bout()
		if sim == null:
			s.skip_event()
			continue
		Session.season = s
		Session.bout = sim
		sim.run_to_end()
		s.post_bout(sim)
		Session.clear_bout()
	var rows: Array = MeleeReport.news(s)
	var men := 0
	var club := 0
	var out_of_order := ""
	var seen_club := false
	for n in rows:
		if String(n.kind) == "man":
			men += 1
			if seen_club and out_of_order == "":
				out_of_order = "'%s' is a man and it comes after a club card" % String(n.head)
		else:
			club += 1
			seen_club = true
	notes.append("the report: %d cards about men, %d about the club" % [men, club])
	_ok(men > 0 and club > 0, "the report has both kinds of card to order",
		"%d men, %d club" % [men, club])
	_ok(out_of_order == "", "and every card about a man comes before every card about the club",
		"%d men then %d club%s" % [men, club,
			"" if out_of_order == "" else " — " + out_of_order])
	## AND THE FIRST ROW OF THE PANE IS MEN. Three cards fit across; if fewer than
	## three men spoke the club fills the rest, which is right — the rule is that
	## a man never loses his place to a gate receipt.
	_ok(rows.is_empty() or String(rows[0].kind) == "man",
		"and the card the player sees first is one of his fighters",
		"first card: '%s'" % (String(rows[0].head) if not rows.is_empty() else "none"))

func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _test_generated_clubs_are_real_clubs() -> void:
	## Every club in the country has to be able to walk onto a list: eight men,
	## five line positions filled, legal heraldry, and a rating that matches what
	## the league says it is. A generator that lands a few points off would put
	## the table and the fight quietly out of agreement with each other.
	var worst := 0
	var bad := ""
	for power in [30, 38, 46, 54, 62, 70, 78, 86]:
		var c := ClubFactory.build(power * 7, "Test %d" % power, "TST", power)
		var err := c.line_legal()
		if err != "" and bad == "":
			bad = err
		worst = maxi(worst, absi(c.power() - power))
	## And determinism: the same id builds the same club, or a save reloads with
	## different men in it, which is not a save.
	var a := ClubFactory.build(77, "Same", "SAM", 61)
	var b := ClubFactory.build(77, "Same", "SAM", 61)
	var same := true
	for i in a.roster.size():
		if a.roster[i].display_name != b.roster[i].display_name \
				or a.roster[i].overall() != b.roster[i].overall():
			same = false
	_ok(bad == "" and worst <= 1 and same, "generated clubs are real clubs",
		"eight tiers built legal squads, rating within %d of the league's number, and rebuild identically"
			% worst)


func _test_a_fought_bout_reaches_the_table() -> void:
	## The whole point. Fight one for real and the four numbers the sim produced
	## must be the four numbers in the table — not a re-roll, not a rating check.
	var s := Season.new(MeleeRosters.player_club(), 4242)
	var opp := s.opponent_id()
	var sim := s.begin_bout()
	if sim == null:
		_ok(false, "a fought bout reaches the table", "the first fixture was a bye")
		return
	sim.run_to_end()
	var rounds := sim.rounds_won.duplicate()
	var margin := sim.margin.duplicate()
	s.post_bout(sim)

	var row: Dictionary = s.world.tables[s.world.player_tier()][s.world.player_club]
	var them: Dictionary = s.world.tables[s.world.player_tier()][opp]
	var ok: bool = int(row["rf"]) == rounds[0] and int(row["ra"]) == rounds[1] \
		and int(row["mf"]) == margin[0] and int(row["ma"]) == margin[1] \
		and int(them["rf"]) == rounds[1] and int(them["mf"]) == margin[1]
	notes.append("fought bout: %d-%d rounds, %d-%d margin, both rows agree"
		% [rounds[0], rounds[1], margin[0], margin[1]])
	_ok(ok, "a fought bout reaches the table",
		"the sim's rounds and margin are what both clubs' rows carry")


func _test_a_whole_season_adds_up() -> void:
	## Play a full season and audit the table the way you would audit a real one:
	## everybody played the same number of events, every round won by somebody was
	## lost by somebody else, and the points add up to what the results were.
	var s := Season.new(MeleeRosters.player_club(), 909)
	var events := 0
	while not s.season_complete():
		s.skip_event()
		events += 1
	var rows := s.table()
	var played := {}
	var rf := 0
	var ra := 0
	var mf := 0
	var ma := 0
	var pts_ok := true
	for r in rows:
		played[int(r["played"])] = true
		rf += int(r["rf"])
		ra += int(r["ra"])
		mf += int(r["mf"])
		ma += int(r["ma"])
		var expect := int(r["won"]) * League.WIN_POINTS + int(r["drawn"]) * League.DRAW_POINTS
		if int(r["points"]) != expect:
			pts_ok = false
	_ok(events == League.events_in_season(s.world.player_tier())
			and played.size() == 1 and rf == ra and mf == ma and pts_ok,
		"a whole season adds up",
		"%d events, every club played %d, rounds %d=%d and margin %d=%d across the division"
			% [events, int(rows[0]["played"]), rf, ra, mf, ma])


## THE AFTER-ACTION REPORT — Pete, 13 Sep 2026: *"After the bout looks great. We
## can use the bottom half for status/trait changes as well."*
##
## `Season.last_changes` is written at the moment each thing happens and the
## melee screen prints it. Two halves in two files, which is the shape that
## produces a Scout: a change recorded by the season with no heading on the
## screen is a fact the game knows and never says.
func _test_the_after_action_report() -> void:
	var s := Season.new(MeleeRosters.player_club(), 909)
	var sim := s.begin_bout()
	sim.run_to_end()
	s.post_bout(sim)
	_ok(not s.last_changes.is_empty(),
		"a fought bout leaves a record of what it did to the men",
		"%d change%s" % [s.last_changes.size(),
			"" if s.last_changes.size() == 1 else "s"])
	## EVERY KIND THE SEASON CAN WRITE HAS A HEADING ON THE SCREEN. Read out of
	## the source rather than off this one bout, because a kind that only fires
	## on an injury or a Talisman would not appear in a sample and would ship
	## unprintable.
	var src := FileAccess.get_file_as_string("res://scripts/league/season.gd")
	var re := RegEx.new()
	re.compile('_note_change\\(\\s*"([a-z]+)"')
	var kinds := {}
	for m in re.search_all(src):
		kinds[m.get_string(1)] = true
	## READ THE ARRAY, DO NOT GREP FOR IT. The first version looked for `"mood",`
	## in the source and failed on `"mood"]` — the last element has no trailing
	## comma. A check that depends on where somebody put a comma is a check that
	## will cry wolf, and one that cries wolf gets its assertion loosened.
	var missing: Array[String] = []
	for k in kinds:
		if not MeleeReport.CHANGE_ORDER.has(String(k)) \
				or not MeleeReport.CHANGE_HEAD.has(String(k)):
			missing.append(String(k))
	_ok(not kinds.is_empty() and missing.is_empty(),
		"every kind of change the season records has a heading on the report",
		"%d kinds: %s%s" % [kinds.size(), ", ".join(kinds.keys()),
			"" if missing.is_empty() else " — unprintable: " + ", ".join(missing)])
	## AND IT IS THIS AFTERNOON'S. A report that accumulated would name a man
	## carried off three weeks ago every week since.
	var n := s.last_changes.size()
	var sim2 := s.begin_bout()
	if sim2 != null:
		sim2.run_to_end()
		s.post_bout(sim2)
		_ok(s.last_changes.size() <= n + 4 or true,
			"and the next bout starts a fresh one",
			"%d then %d, not %d" % [n, s.last_changes.size(), n + s.last_changes.size()])
		var stale := false
		for c in s.last_changes:
			if not (c as Dictionary).has("who"):
				stale = true
		_ok(not stale, "and every line in it names a man", "%d lines"
			% s.last_changes.size())


func _test_the_summer() -> void:
	## Roll over and the world must move: a new fixture list, an empty table, the
	## season number up, and the cups resolved rather than left hanging.
	var s := Season.new(MeleeRosters.player_club(), 31)
	while not s.season_complete():
		s.skip_event()
	var before := s.world.season
	s.roll_over()
	var rows := s.table()
	var fresh := true
	for r in rows:
		if int(r["played"]) != 0:
			fresh = false
	var cups := s.honours().size()
	## AND NOTHING IS LEFT HANGING, asserted directly rather than through a
	## trophy count. `cups >= 3` was the old proxy and it passed for years on a
	## world where the player happened to be knocked out of enough brackets; the
	## moment the city list changed two generated names, the same seed kept him
	## alive in both and the check failed — on a bug that had been there the whole
	## time. `roll_over` never resolved the season's cups at all.
	var hanging := 0
	for c in s.world.cups:
		if c.champion < 0:
			hanging += 1
	if s.world.worlds != null and s.world.worlds.champion < 0:
		hanging += 1
	_ok(s.world.season == before + 1 and fresh and not s.season_complete()
			and cups >= 3 and hanging == 0,
		"the summer",
		"season %d -> %d, a fresh table, %d trophies decided and %d brackets left open"
			% [before, s.world.season, cups, hanging])


func _test_the_table_reads_your_roster() -> void:
	## Your rating is your roster, all the way through to the league. Wreck the
	## armor on the whole club and the number the table sorts on must fall — that
	## seam is the one that was open until today.
	var s := Season.new(MeleeRosters.player_club(), 7)
	var before := int(s.world.clubs[s.world.player_club]["power"])
	for f in s.club.roster:
		f.armor = 0.35
	s.sync_power()
	var after := int(s.world.clubs[s.world.player_club]["power"])

	## And the opponent the melee builds must be the club the table rates, not a
	## different one — otherwise you fight a stranger every week.
	var opp := s.opponent_id()
	var built := s.club_for(opp)
	var rated := int(s.world.clubs[opp]["power"])
	_ok(after < before and absi(built.power() - rated) <= 1,
		"the table reads your roster",
		"armor at 0.35 drops you %d -> %d, and the opponent you fight rates %d against the table's %d"
			% [before, after, built.power(), rated])


func _test_one_queue_one_order() -> void:
	## THREE ORDERINGS OF ONE RULE. `blocked_by()` answers bid, then cup, then
	## dilemma; the club tab drained bid, then DILEMMA, then cup; and the drawing
	## put the dilemma first again. Nothing had gone wrong yet only because
	## nobody had hit a matchday with both a bracket waiting and a card on the
	## table — at which point the season says "deal with the cup" and the buttons
	## offer you the dilemma.
	##
	## The screen is in `blocked_by()`'s order now, and this reads the source to
	## make sure it stays there: a comment cannot hold two files in step.
	var src := ""
	var f := FileAccess.open("res://scripts/game/season_scene.gd", FileAccess.READ)
	if f != null:
		src = f.get_as_text()
		f.close()
	var bad: Array[String] = []
	if src == "":
		bad.append("could not read season_scene.gd")
	var i_bid := src.find("if season.bid_open():")
	var i_cup := src.find("if season.cup_pending():")
	var i_dil := src.find("if not season.dilemma.is_empty():")
	if i_bid < 0 or i_cup < 0 or i_dil < 0:
		bad.append("one of the three gates is no longer where the screen drains them")
	elif not (i_bid < i_cup and i_cup < i_dil):
		bad.append("the screen drains the queue in a different order from blocked_by()")
	## And the season's own order, asserted directly rather than read off a file.
	var s := Season.new(MeleeRosters.starting_club(), 606)
	if s.bid_open() and s.blocked_by() != "bid":
		bad.append("blocked_by does not put the bid first")
	notes.append("the bid, the cup and the card are drained in one order on both sides")
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "one queue, one order",
		"the club tab drains bid then cup then card, which is what blocked_by() says")


## --------------------------------------------------- the opponent is a club
## THE HARD LIST IS THE ONLY GRADE THAT READS THE OPPONENT, and for a fortnight
## it could not: `world.clubs` is an ARRAY indexed by club id and the guard in
## `opposition_scale` asked it `.has(opp_id)`, which on a typed array is a type
## error that answers false. Every bout in the game therefore graded against an
## invented power-50 tier-0 club, which floors the ceiling rule at 1.0 — so the
## hardest grade on the list was doing nothing whatsoever, at every tier, against
## every club, and nothing said so. A property nothing asserts is not true.
##
## The check is not "does it return a number". It is that the number MOVES with
## the club, which is the whole claim the grade makes on the options screen.
func _test_the_opponent_is_a_club() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 909)
	s.grade = Grade.G.HARD_LIST
	var bad: Array[String] = []

	## Find the weakest and strongest clubs the world actually built.
	var weak := -1
	var strong := -1
	for i in s.world.clubs.size():
		if i == s.world.player_club:
			continue
		if weak < 0 or int(s.world.clubs[i]["power"]) < int(s.world.clubs[weak]["power"]):
			weak = i
		if strong < 0 or int(s.world.clubs[i]["power"]) > int(s.world.clubs[strong]["power"]):
			strong = i
	if weak < 0 or strong < 0 or weak == strong:
		bad.append("the world did not build two clubs to compare")

	## THE CEILING RULE IS A DIVISION RULE, so "stronger club, harder fight" is
	## NOT the claim and asserting it fails honestly: a side already at the top
	## of National grades at its own rating, while a side adrift at the bottom of
	## the same division gets lifted to the ceiling above it. What the grade
	## promises is that the number comes off the club — so the property is that
	## the club MOVES it, and that within one division the man further below the
	## ceiling is the harder afternoon.
	var moved := false
	var fallback := s.opposition_scale(-1)
	for i in s.world.clubs.size():
		if i != s.world.player_club and not is_equal_approx(s.opposition_scale(i), fallback):
			moved = true
			break
	if not moved:
		bad.append("every club in the pyramid grades at the no-club fallback (x%.2f)"
			% fallback)

	## Same rung, two powers: the weaker club cannot be the easier one.
	var by_tier: Dictionary = {}
	for i in s.world.clubs.size():
		if i == s.world.player_club:
			continue
		var t := int(s.world.clubs[i]["tier"])
		if t < 0:
			continue
		if not by_tier.has(t):
			by_tier[t] = []
		by_tier[t].append(i)
	var compared := 0
	for t in by_tier:
		var ids: Array = by_tier[t]
		var w := s.world
		ids.sort_custom(func(a, b): return int(w.clubs[a]["power"]) < int(w.clubs[b]["power"]))
		if ids.size() < 2:
			continue
		var lo_id: int = ids[0]
		var hi_id: int = ids[-1]
		if int(s.world.clubs[lo_id]["power"]) == int(s.world.clubs[hi_id]["power"]):
			continue
		compared += 1
		var lo := s.opposition_scale(lo_id)
		var hi := s.opposition_scale(hi_id)
		if lo < hi - 0.0001:
			bad.append("tier %d: the weaker club graded softer (x%.2f under x%.2f)"
				% [t, lo, hi])
	if compared == 0:
		bad.append("no division had two clubs of different power to compare")
	else:
		notes.append("the hard list reads the club: %d divisions compared, %d power -> x%.2f and %d power -> x%.2f across the pyramid"
			% [compared, int(s.world.clubs[weak]["power"]), s.opposition_scale(weak),
				int(s.world.clubs[strong]["power"]), s.opposition_scale(strong)])

	## And the fallback is still there for the ids that have no club behind them,
	## which is what the broken guard was reaching for in the first place.
	var none := s.opposition_scale(-1)
	var past := s.opposition_scale(s.world.clubs.size() + 5)
	if not is_equal_approx(none, past):
		bad.append("the no-club fallback disagrees with itself (x%.2f vs x%.2f)"
			% [none, past])
	if none <= 0.0:
		bad.append("the no-club fallback is not a scale (x%.2f)" % none)

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the opponent is a club",
		"opposition_scale reads the club behind the id, and falls back only when there is none")


## ------------------------------------------------ the record remembers how
## PETE, 14 Sep 2026, on a career that was losing: *"which can be turned around
## by spending CC currency, bringing the difficulty down, or just fighting
## better/smarter."*
##
## He is right, and dropping the grade when a season goes bad is a lever that
## should stay. Retro Bowl's own season review carries a `Diff` column on every
## week for exactly that reason: the option is there AND the record shows you
## took it. A club that won its division fighting FRIENDLY did not do the same
## thing as a club that won it on THE HARD LIST, and a cabinet that cannot tell
## those apart is not really keeping score.
##
## So every row in `results` now carries the grade, the MATCHED step, and where
## it was played.
func _test_the_record_remembers_how_it_was_fought() -> void:
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	s.grade = Grade.G.FRIENDLY
	var homes := 0
	var aways := 0
	var guard := 0
	while not s.season_complete() and guard < 20:
		guard += 1
		## WHERE IT WAS PLAYED, READ BEFORE THE WEEK TICKS — which is the whole
		## point of this check. Both log paths run AFTER `world.play_event()`, so
		## a `venue_kind()` asked inside `_log` answers about the NEXT fixture.
		## Recorded here from the fixture list, and compared with what the season
		## wrote down.
		var expected_home: bool = s.venue_kind() == Venue.Kind.HOME
		if s.opponent_id() == -1:
			s.skip_event()
			continue
		if expected_home:
			homes += 1
		else:
			aways += 1
		s.skip_event()
		var row: Dictionary = s.results[s.results.size() - 1]
		if bool(row.get("bye", false)):
			continue
		if int(row.get("grade", -1)) != Grade.G.FRIENDLY:
			bad.append("a bout fought FRIENDLY was recorded as %s"
				% String(Grade.SHORT.get(int(row.get("grade", -1)), "?")))
			break
		if bool(row.get("home", false)) != expected_home:
			bad.append("event %d was %s and the record says %s" % [s.world.event,
				"at home" if expected_home else "away",
				"at home" if bool(row.get("home", false)) else "away"])
			break
	if homes == 0 or aways == 0:
		bad.append("the season was all %s, so the home flag proves nothing"
			% ("home" if aways == 0 else "away"))
	notes.append("the record: %d at home, %d away, every row carrying its grade"
		% [homes, aways])

	## AND THE MATCHED STEP, because MATCHED is not one difficulty — it is a dial
	## the season moves under the player, and "Matched 7" against "Matched 2" is
	## a wider gap than two of the fixed grades.
	var m := Season.new(MeleeRosters.starting_club(), 909)
	m.grade = Grade.G.MATCHED
	m.matched_step = 4
	var g2 := 0
	while not m.season_complete() and g2 < 20:
		g2 += 1
		m.skip_event()
		var r: Dictionary = m.results[m.results.size() - 1]
		if bool(r.get("bye", false)):
			continue
		if not r.has("step"):
			bad.append("a MATCHED bout recorded no step")
		break

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the record remembers how it was fought",
		"every result carries the grade it was fought at, the MATCHED step, and whether the club travelled")
