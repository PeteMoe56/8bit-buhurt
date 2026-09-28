extends SceneTree
## The difficulty grade, the choke point it goes through, and the round skip.
##
##   godot --headless --path . --script res://tests/test_grade.gd
##
## THE TWO CHECKS THAT MATTER ARE THE FIRST AND THE LAST.
##
## The first is a grep. `Man.eff_base` and `eff_skill` carried a comment saying
## every formula reads them "so the penalty cannot be forgotten in one formula
## and applied in another" — and strength, gas and tank were being read straight
## off the card in twelve places the whole time. The comment was true of the two
## stats somebody had thought about and silently false of the other two, which is
## exactly the shape of a rule with a hole in it. A grade that reached two of
## four contest stats would have been a difficulty setting that half worked, and
## nothing in the suite would have said a word. So the choke point is asserted
## rather than described.
##
## The last is determinism. SKIP ROUND is only legitimate if a round you skipped
## and a round you watched are the SAME ROUND. If they diverge, the player has no
## way of knowing which of his results came from which code path, and the honest
## thing would be to delete the button.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the grade ===\n")
	_test_the_choke_point_has_no_holes()
	_test_the_scale_reaches_every_contest_stat()
	_test_your_own_men_are_never_scaled()
	_test_the_table_is_ordered()
	_test_the_hard_list_is_never_softer()
	_test_a_guest_has_no_rung()
	_test_calls_and_the_corner()
	_test_the_tactician_needs_reach()
	_test_matched_moves_on_margin()
	_test_matched_is_gated_on_a_trophy()
	_test_a_v12_save_loads_sanctioned()
	_test_a_skipped_round_is_the_round_you_would_have_watched()
	_test_the_skip_stops_at_the_corner()
	_test_the_grade_moves_the_win_rate()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE GRADE HOLDS (%d checks)\n" % checks)
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


# ------------------------------------------------------------- the choke point
## NOT ONE DIRECT READ LEFT IN THE SIM.
##
## `card.overall()` is exempt and the exemption is in the file: the two places
## that read it are a man sizing up an opponent and deciding whether to commit,
## which is a judgment rather than a contest. Scaling those would make a Full
## Steel side braver as well as better — a second difficulty dial hidden inside
## the first. The exemption is NAMED here so that adding a third raw `overall()`
## read fails this check and has to be argued for.
const BANNED := ["card.fighting_strength()", "card.fighting_gas()", "card.tank()",
	"card.effective_base()", "card.skill"]
## FOUR READS ACROSS TWO LINES — `if tgt.card.overall() > m.card.overall() + 8`
## is two of them. The constant was 2 because that is how many CALL SITES there
## are, and the check counts reads; a check whose number means something other
## than what it counts is a check that fails for the wrong reason and gets
## "corrected" by moving the number.
const ALLOWED_OVERALL := 4
const ALLOWED_OVERALL_LINES := 2


func _test_the_choke_point_has_no_holes() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/melee/melee_sim.gd")
	var bad: Array[String] = []
	var lines := src.split("\n")
	var inside := false
	for i in lines.size():
		var ln := String(lines[i])
		var t := ln.strip_edges()
		## The four accessors are the one place allowed to touch the card, and
		## they live in a block this walk steps over rather than a name it
		## pattern-matches — a skip keyed on the function name would stop working
		## the day somebody renames one, and stop QUIETLY.
		if t.begins_with("func _pen()"):
			inside = true
		elif t.begins_with("func eff_tank()"):
			inside = true
		elif inside and t.begins_with("var ") and not t.begins_with("var opp"):
			inside = false
		if t.begins_with("#") or t.begins_with("##"):
			continue
		for b in BANNED:
			if ln.find(b) != -1 and not inside:
				bad.append("line %d: %s" % [i + 1, t.substr(0, 58)])
				break
		if inside and t.begins_with("func ") and not t.begins_with("func eff_") \
				and not t.begins_with("func _pen"):
			inside = false
	_ok(bad.is_empty(), "no direct card stat read survives in the sim",
		"clean" if bad.is_empty() else "; ".join(bad.slice(0, 3)))

	## COUNTED IN CODE, NOT IN PROSE. The first version counted the string across
	## the whole file and found five, because the note explaining the exemption
	## names `card.overall()` three times — a check that a comment can fail is a
	## check nobody will keep.
	var n := 0
	for ln in lines:
		var t2 := String(ln).strip_edges()
		if t2.begins_with("#"):
			continue
		n += String(ln).count("card.overall()")
	_ok(n == ALLOWED_OVERALL,
		"card.overall() is read exactly %d times" % ALLOWED_OVERALL,
		"%d reads across %d sizing-up lines, and no more"
		% [n, ALLOWED_OVERALL_LINES])


# ------------------------------------------------------ the scale does something
## THE NEGATIVE CONTROL IS THE POINT. A test that only shows the scaled sim
## differs from the unscaled one proves nothing until you have also shown two
## unscaled sims are identical — otherwise you are measuring the RNG.
func _test_the_scale_reaches_every_contest_stat() -> void:
	var a := _bout(9001, 1.0)
	var b := _bout(9001, 1.0)
	var c := _bout(9001, 1.30)
	_ok(_snap(a) == _snap(b), "two unscaled bouts from one seed are identical",
		"the control holds")
	_ok(_snap(a) != _snap(c), "a scaled bout from the same seed differs",
		"x1.30 moves the fight")

	## AND IT REACHES ALL FOUR, one at a time, so a scale wired into base and
	## skill only — which is where this started — cannot pass.
	var men := c.men
	var one: MeleeSim.Man = men[5]        ## team 1
	var mine: MeleeSim.Man = men[0]       ## team 0
	var moved := 0
	if not is_equal_approx(one.eff_base(), one.card.effective_base()):
		moved += 1
	if not is_equal_approx(one.eff_skill(), float(one.card.skill)):
		moved += 1
	if not is_equal_approx(one.eff_strength(), float(one.card.fighting_strength())):
		moved += 1
	if not is_equal_approx(one.eff_gas(), float(one.card.fighting_gas())):
		moved += 1
	if not is_equal_approx(one.eff_tank(), one.card.tank()):
		moved += 1
	_ok(moved == 5, "the scale reaches all five of their numbers",
		"%d of 5 moved" % moved)
	notes.append("their men: base %.1f skill %.1f str %.1f gas %.1f tank %.2f"
		% [one.eff_base(), one.eff_skill(), one.eff_strength(), one.eff_gas(),
		one.eff_tank()])
	notes.append("yours, at the same grade: base %.1f str %.1f"
		% [mine.eff_base(), mine.eff_strength()])


## FRIENDLY MAKES THEM WORSE. IT DOES NOT MAKE YOU BETTER. Four screens print a
## two-digit overall beside a name and reading them is the whole activity, so a
## grade that moved your own numbers would make the roster screen a liar.
func _test_your_own_men_are_never_scaled() -> void:
	for sc in [0.90, 1.0, 1.25]:
		var s := _bout(4242, sc)
		for m in s.men:
			if m.team == 0 and not is_equal_approx(m.scale, 1.0):
				_ok(false, "your own men are never scaled",
					"#%d carries %.2f at x%.2f" % [m.idx, m.scale, sc])
				return
	_ok(true, "your own men are never scaled", "team 0 is 1.0 at every grade")


func _test_the_table_is_ordered() -> void:
	var f := Grade.scale_for(Grade.G.FRIENDLY, 0, 60, 2)
	var n := Grade.scale_for(Grade.G.SANCTIONED, 0, 60, 2)
	var s := Grade.scale_for(Grade.G.FULL_STEEL, 0, 60, 2)
	_ok(f < n and n < s, "friendly < sanctioned < full steel",
		"x%.2f  x%.2f  x%.2f" % [f, n, s])
	_ok(is_equal_approx(n, 1.0), "sanctioned is exactly even", "x%.2f" % n)


## THE HARD LIST IS FULL STEEL PLUS A RULE, so it can never come out softer.
## It could: the ceiling rule floors at 1.0 for a club already at the top of its
## division, and a Worlds guest rated 90 is ABOVE the National ceiling of 86 — so
## the hardest grade in the game was landing on x1.00 against precisely the clubs
## it exists for.
func _test_the_hard_list_is_never_softer() -> void:
	var bad: Array[String] = []
	for t in [-1, 0, 1, 2, 3]:
		for p in [20, 30, 46, 58, 70, 86, 90, 99]:
			var h := Grade.scale_for(Grade.G.HARD_LIST, 0, p, t)
			var s := Grade.scale_for(Grade.G.FULL_STEEL, 0, p, t)
			if h < s - 0.0001:
				bad.append("tier %d power %d: x%.2f < x%.2f" % [t, p, h, s])
	_ok(bad.is_empty(), "the hard list is never softer than full steel",
		"40 club shapes" if bad.is_empty() else "; ".join(bad.slice(0, 3)))


func _test_a_guest_has_no_rung() -> void:
	## tier -1 is a Worlds guest. Clamping that to 0 would hand him the BACKYARD
	## ceiling of 46, which against an eighty-rated side floors at 1.0 and quietly
	## exempts the best clubs in the game from the hardest grade.
	var g := Grade.ceiling_scale(70, -1)
	var b := Grade.ceiling_scale(70, League.Tier.BACKYARD)
	_ok(g > b, "a worlds guest takes the top of the pyramid, not the bottom",
		"guest x%.2f vs backyard x%.2f" % [g, b])


func _test_calls_and_the_corner() -> void:
	var f := Grade.pauses_for(Grade.G.FRIENDLY, 0, 0)
	var n := Grade.pauses_for(Grade.G.SANCTIONED, 0, 0)
	var s := Grade.pauses_for(Grade.G.FULL_STEEL, 0, 0)
	_ok(f == n + 1 and s == n - 1, "calls go +1 / 0 / -1 off the base",
		"%d  %d  %d" % [f, n, s])
	_ok(Grade.pauses_for(Grade.G.FULL_STEEL, 0, 0) >= 0
			and Grade.pauses_for(Grade.G.FULL_STEEL, 0, 0) > 0,
		"full steel still leaves you one", "%d" % s)
	var cf := Grade.corner_time(Grade.G.FRIENDLY)
	var cs := Grade.corner_time(Grade.G.FULL_STEEL)
	_ok(cf > Tuning.CORNER_TIME and cs < Tuning.CORNER_TIME,
		"the corner is longer on friendly and shorter on full steel",
		"%.0fs / %.0fs / %.0fs" % [cf, Tuning.CORNER_TIME, cs])
	## AND THE SIM ACTUALLY USES IT. A field the grade sets and the sim ignores is
	## the same bug as the Scout trait that had a description and no code.
	var sim := _bout(31, 1.0)
	sim.corner_time = 11.0
	while not sim.is_over() and sim.phase != MeleeSim.Phase.CORNER:
		sim.tick()
	_ok(sim.is_over() or is_equal_approx(sim.corner_t, 11.0),
		"the sim corners for as long as the grade says",
		"corner_t %.1f" % sim.corner_t)


## A ONE-STAR TACTICIAN IS WORTH NOTHING, exactly like a one-star Physio. This is
## the clause of the reach rule the trait actually keeps — see the note in
## club_office.gd about where it bends the rest.
func _test_the_tactician_needs_reach() -> void:
	var o := ClubOffice.new()
	o.captains = [ClubOffice.captain("Vane", Tuning.Role.RAIL, Tuning.Role.CENTER, 4,
		ClubOffice.Trait.TACTICIAN)]
	var with := o.extra_calls()
	var o2 := ClubOffice.new()
	o2.captains = [ClubOffice.captain("Orde", Tuning.Role.RAIL, Tuning.Role.CENTER, 1,
		ClubOffice.Trait.TACTICIAN)]
	var without := o2.extra_calls()
	_ok(with == 1 and without == 0, "a tactician needs a specialty to be worth one",
		"four-star %d, one-star %d" % [with, without])
	_ok(Grade.pauses_for(Grade.G.FULL_STEEL, 0, 1)
			== Grade.pauses_for(Grade.G.FULL_STEEL, 0, 0) + 1,
		"and the budget spends it", "full steel with a tactician")

	## HE IS RARE. Not "rarer than average" — counted, over a season's worth of
	## offers, because "rare" was the word in the brief and a trait that turns up
	## on a third of the market is not it.
	var seen := 0
	var total := 0
	for season_no in 20:
		for slot in 3:
			var c := ClubOffice.offer(77, season_no, slot)
			total += 1
			if ClubOffice.trait_of(c) == ClubOffice.Trait.TACTICIAN:
				seen += 1
	var pct := 100.0 * float(seen) / float(total)
	_ok(pct > 0.0 and pct < 20.0, "the tactician is rare on the market",
		"%d of %d offers (%.0f%%)" % [seen, total, pct])


# ------------------------------------------------------------------- MATCHED
## IT READS MARGIN, not just the result — a 2-0 and a 2-1 are not the same
## afternoon. Retro Bowl takes a second step for a win by more than fourteen.
func _test_matched_moves_on_margin() -> void:
	var start := 0
	var narrow := Grade.matched_next(start, 2, 1, true)
	var sweep := Grade.matched_next(start, 2, 0, true)
	var loss := Grade.matched_next(start, 0, 2, true)
	var drawn := Grade.matched_next(start, 1, 1, true)
	_ok(sweep > narrow and narrow > start, "a sweep hardens it twice as fast",
		"2-1 -> %d, 2-0 -> %d" % [narrow, sweep])
	_ok(loss < start, "a loss eases it", "%d" % loss)
	_ok(drawn == start, "a draw leaves it alone", "%d" % drawn)


## THE TROPHY GATE. Retro Bowl will not drop its scale below -1 until you have
## won a title; ours will not climb past its unproven cap until the cabinet has
## something in it. A game should not grade you up to its hardest band on the
## strength of a good November.
func _test_matched_is_gated_on_a_trophy() -> void:
	var s := 0
	for i in 20:
		s = Grade.matched_next(s, 2, 0, false)
	_ok(s == Grade.STEP_MAX_UNPROVEN, "matched stops short without a trophy",
		"twenty sweeps reach step %d of %d" % [s, Grade.STEP_MAX])
	var t := 0
	for i in 20:
		t = Grade.matched_next(t, 2, 0, true)
	_ok(t == Grade.STEP_MAX, "and goes all the way with one", "step %d" % t)
	_ok(Grade.matched_scale(Grade.STEP_START) < 1.0,
		"matched starts on the easy side of even",
		"x%.2f" % Grade.matched_scale(Grade.STEP_START))


## A SAVE FROM BEFORE THE GRADE IS A SANCTIONED CAREER, by construction — that is
## the whole argument for not bumping VERSION, so it is asserted rather than
## assumed.
func _test_a_v12_save_loads_sanctioned() -> void:
	SaveGame.set_namespace("grade")
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.grade = Grade.G.HARD_LIST
	s.matched_step = Grade.STEP_MAX
	_ok(SaveGame.save(s, 1), "a graded career saves", "slot 1")
	var back := SaveGame.load_slot(1)
	_ok(back != null and back.grade == Grade.G.HARD_LIST and back.matched_step == Grade.STEP_MAX,
		"and comes back on the same grade",
		"%s, step %d" % [Grade.name_of(back.grade), back.matched_step] if back != null
		else "nothing came back")
	## AND THE ONE THE VERSION ARGUMENT RESTS ON: a file with no grade key at all
	## is a career fought at SANCTIONED, which is what a version 12 file IS.
	var old := {"seed": 1, "formation_id": Tuning.Formation.TWO_ONE_TWO}
	_ok(int(old.get("grade", Grade.DEFAULT)) == Grade.G.SANCTIONED,
		"a file with no grade key reads as sanctioned",
		"default is %s" % Grade.name_of(Grade.DEFAULT))
	SaveGame.delete(1)
	SaveGame.set_namespace("")


# ---------------------------------------------------------------- the skip
## THE ONE THAT DECIDES WHETHER THE BUTTON IS ALLOWED TO EXIST.
##
## A skipped round and a watched round must be the same round, down to every
## man's tank and stability and the position he is standing in. They are, because
## `skip_round` is the same `tick()` loop the screen runs and not a cheaper one —
## and the moment somebody optimises it into a cheaper one, this fails.
func _test_a_skipped_round_is_the_round_you_would_have_watched() -> void:
	var mismatched := 0
	for seed_value in [7777, 1234, 999, 24601, 8]:
		var watched := _bout(seed_value, 1.0)
		var skipped := _bout(seed_value, 1.0)
		while watched.phase != MeleeSim.Phase.CORNER and not watched.is_over():
			watched.tick()
		skipped.skip_round()
		if _snap(watched) != _snap(skipped):
			mismatched += 1
	_ok(mismatched == 0, "a skipped round is the round you would have watched",
		"five seeds, every man's state identical")


func _test_the_skip_stops_at_the_corner() -> void:
	var s := _bout(4242, 1.0)
	s.skip_round()
	_ok(s.phase == MeleeSim.Phase.CORNER or s.is_over(),
		"the skip stops at the corner, not at the end of the bout",
		"phase %d, round %d" % [s.phase, s.round_no])
	## AND IT IS NOT A FREE WIN. Skipping hands your clinch calls to the AI, so
	## the skip must not be answering prompts on your behalf as though you had.
	_ok(s.prompts_answered == 0, "a skipped round answers nothing for you",
		"%d answered, %d timed out" % [s.prompts_answered, s.prompts_timed_out])


# ------------------------------------------------------------- the measurement
## DOES THE NUMBER ACTUALLY DO ANYTHING. A threshold written down goes stale, so
## this asserts the ORDER and a floor on the gap rather than a target win rate —
## the tuning can move without the test becoming a lie, but the grade going
## inert, or backwards, still fails.
##
## `tools/probe_grade.gd` is the full sweep and the reason the shipped numbers
## are what they are. This is the cheap version that runs in the suite.
## IT MEASURES THE ENDS AND NOT THE MIDDLE, and the first draft of this test is
## why. It asserted friendly > sanctioned > full steel over forty bouts and
## failed on a run where full steel came out SEVEN POINTS ABOVE sanctioned —
## which is not a bug in the grade, it is forty samples trying to resolve an
## eight-point effect with an eleven-point standard error. The probe at N=150
## shows x0.97 and x0.98 swapping places for the same reason.
##
## A test that fails on noise is worse than no test: it gets re-run until it
## passes, and then it is decoration. The ORDER OF THE SCALES is asserted exactly
## in `_test_the_table_is_ordered`, where it is arithmetic and deterministic.
## What this one is for is the thing arithmetic cannot tell you — that the
## multiplier reaches the fight at all, in the right direction, by an amount
## worth putting on a menu. So it measures the two ends, where the gap is large
## enough to clear the noise by a distance.
const MEASURE_N := 80
const MIN_GAP := 10.0


func _test_the_grade_moves_the_win_rate() -> void:
	var easy := _win_rate(Grade.EASE)
	var even := _win_rate(1.0)
	var even2 := _win_rate(1.0)
	var hard := _win_rate(Grade.STEEL)
	_ok(is_equal_approx(even, even2), "the control holds",
		"two even columns both %.1f%%" % even)
	_ok(easy > hard, "friendly wins more than full steel",
		"%.1f%% against %.1f%%" % [easy, hard])
	_ok(easy - hard >= MIN_GAP, "and the gap is worth having a setting for",
		"%.1f points between the ends, floor %.0f" % [easy - hard, MIN_GAP])
	notes.append("win rate over %d seeded bouts: friendly %.1f%%, sanctioned %.1f%%, "
		% [MEASURE_N, easy, even] + "full steel %.1f%%" % hard)


func _win_rate(scale: float) -> float:
	var w := 0
	for i in MEASURE_N:
		var s := _bout(hash("m:%d" % i), scale)
		s.run_to_end()
		if s.bout_winner() == 0:
			w += 1
	return 100.0 * float(w) / float(MEASURE_N)


# ------------------------------------------------------------------- helpers
func _bout(seed_value: int, scale: float) -> MeleeSim:
	return MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(),
		seed_value, scale)


## EVERYTHING A ROUND LEAVES BEHIND. Positions are snapped rather than compared
## raw because a float that differs in its last bit is a difference this test
## should not be reporting — and one that differs anywhere else is.
func _snap(s: MeleeSim) -> Array:
	var out: Array = [s.round_no, snappedf(s.round_t, 0.0001), s.rounds_won.duplicate(),
		s.phase, s.downs.duplicate(), s.round_downs.duplicate(), s.margin.duplicate()]
	for m in s.men:
		out.append([m.idx, m.state, m.team, snappedf(m.tank, 0.00001),
			snappedf(m.stability, 0.00001), snappedf(m.pos.x, 0.00001),
			snappedf(m.pos.y, 0.00001), m.downs_caused, m.times_downed,
			m.rounds_standing])
	return out
