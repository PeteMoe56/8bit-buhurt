extends SceneTree
## Constraint tests for the new melee.
##
##   godot --headless --path . --script res://tests/test_melee.gd
##
## Not unit tests of arithmetic — these are the rules from docs/CONSTRAINTS.md
## measured over hundreds of simulated bouts, because every one of them is a
## number a balance pass can break in silence.
##
## Nothing here is allowed to be skipped. A test that cannot run gets fixed or
## deleted, never printed as SKIP and left green.

## RB_TIER (exported by tools/run_tests.sh): "fast" runs the structural checks on
## a small sample; "balance" runs only the statistical measures at full size;
## unset (run by hand) runs everything at full size.
var TIER := OS.get_environment("RB_TIER")
var N: int = 10 if TIER == "fast" else 40

## Measured by _test_symmetry over four hundred bouts and read by C-3, which
## used to measure the identical thing over forty and get a different answer.
var mirror_auto := 50.0

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — melee constraints (%d bouts per measure) ===\n" % N)
	var fast := TIER != "balance"
	var stats := TIER != "fast"
	if fast:
		_test_fixtures()
		_test_determinism()
		_test_prompts_are_only_for_men_you_sent()
		_test_stop_rule()
		_test_best_of_three()
		_test_report_blames_the_roster()
		_test_the_corner_pays_the_men_who_sat()
		_test_a_route_can_be_taken_back()
		await _test_the_tap_on_the_screen()
	## THE STATISTICAL MEASURES — balance targets, not invariants. Balance tier.
	if stats:
		_test_symmetry()
		_test_autoplay_competent()
		_test_orchestration_matters_but_roster_matters_more()
		_test_pace()
		_test_the_difficulty_ladder_points_up()
		_test_the_endings_look_like_buhurt()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("ALL CONSTRAINTS HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


## THE TAP, ON THE REAL SCREEN. The rule that only a route the player drew can be
## tapped away lives in the scene, so the scene is what is asked — a thumb's
## press and release on the man, not a read of the source.
func _test_the_tap_on_the_screen() -> void:
	await process_frame
	## Driven through the real screen: a tap on the man, the same gesture a thumb
	## makes. The rule lives in the scene, so the scene is what is asked.
	var tap := _melee_scene()
	var ts: MeleeSim = tap.get("sim")
	var who := -1
	for m in ts.men:
		if m.team == 0 and m.standing():
			who = m.idx
			break
	var at: Vector2 = tap.call("_to_screen", ts.men[who].pos)
	ts.give_order(who, [ts.men[who].pos + Vector2(4, 0)] as Array[Vector2])
	tap.call("_press", at)
	tap.call("_release", at)
	var drawn_gone := not ts.men[who].under_orders()
	ts._order(ts.men[who], [ts.men[who].pos + Vector2(4, 0)], -1, true)
	tap.call("_press", at)
	tap.call("_release", at)
	var play_kept := ts.men[who].under_orders()
	tap.queue_free()
	await process_frame
	## SKIP ROUND RUNS OVER FRAMES, and comes out the same as the sim's own skip.
	var sk := _melee_scene()
	await process_frame
	var ss: MeleeSim = sk.get("sim")
	sk.set("screen", 2)
	ss.phase = MeleeSim.Phase.LIVE
	var twin := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 31)
	twin.phase = MeleeSim.Phase.LIVE
	sk.call("_skip_round")
	var frames := 0
	while bool(sk.get("skipping")) and frames < 2000:
		await process_frame
		frames += 1
	twin.skip_round()
	var same: bool = ss.round_no == twin.round_no and ss.phase == twin.phase \
		and str(ss.downs) == str(twin.downs) and is_equal_approx(ss.round_t, twin.round_t)
	_ok(frames >= 1 and not bool(sk.get("skipping")) and same,
		"skip round plays over frames and ends where the sim's own skip ends",
		"%d frames; round %d/%d, downs %s/%s" % [frames, ss.round_no, twin.round_no,
			str(ss.downs), str(twin.downs)])
	sk.queue_free()
	Session.clear_bout()
	await process_frame
	Session.clear_bout()
	_ok(drawn_gone, "and a tap on the man on the real screen takes his route back",
		"a route you drew, tapped: %s" % ("gone" if drawn_gone else "still on"))
	_ok(play_kept, "and only a route the PLAYER drew can be taken back",
		"a called play's route, tapped: %s" % ("kept" if play_kept else "cancelled"))


## The real fight screen on a real bout, in the tree, without its wipe.
func _melee_scene() -> Node:
	Juice.set_enabled(false)
	Session.season = null
	Session.bout = MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 31)
	var n: Node = (load("res://scenes/Melee.tscn") as PackedScene).instantiate()
	root.add_child(n)
	return n


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


# ----------------------------------------------------------------- fixtures
func _test_fixtures() -> void:
	var err := MeleeRosters.validate()
	_ok(err == "", "fixtures",
		"both fives fill Rail/Flanker/Center/Flanker/Rail and read at a glance" if err == "" else err)


func _test_determinism() -> void:
	var a := _run(4242, "auto")
	var b := _run(4242, "auto")
	var same: bool = (
		str(a["rounds"]) == str(b["rounds"]) and str(a["downs"]) == str(b["downs"])
		and is_equal_approx(float(a["bout_t"]), float(b["bout_t"]))
	)
	_ok(same, "determinism", "the same seed reproduces the bout exactly")


# ----------------------------------------------------------------- symmetry
func _test_symmetry() -> void:
	## A mirror match must be a coin flip. This is a correctness test, not a
	## design one, and on the previous build it caught an 18% edge caused by
	## team 0 getting first refusal on every engagement each tick. That would
	## have surfaced to players as "the AI cheats" and been hunted in the wrong
	## file for a week.
	var w := [0, 0, 0]
	## A wide sample on purpose: at 120 bouts one standard deviation is ~4.6
	## points, so a reading a couple of points off 50 is indistinguishable from
	## noise — which is no use at all for a test whose whole job is to catch a
	## small systematic edge.
	for i in N * 10:
		var sim := _mirror(i + 500000)
		sim.run_to_end()
		var win := sim.bout_winner()
		w[win if win >= 0 else 2] += 1
	var decided: int = w[0] + w[1]
	var edge := 50.0
	if decided > 0:
		edge = float(w[0]) / float(decided) * 100.0
	notes.append("mirror: team0 %d, team1 %d, drawn %d" % w)
	## C-3 asks the same question of the same fights and reads this rather than
	## running its own forty bouts of it. See _test_autoplay_competent.
	mirror_auto = edge
	_ok(absf(edge - 50.0) <= 9.0, "sim symmetry",
		"team 0 takes %.1f%% of decided mirror bouts (50 +/- 9)" % edge)


# ------------------------------------------------- [C-3] auto-play competent
func _test_autoplay_competent() -> void:
	## "The AI will choose unless you choose." Letting it choose every single
	## time has to be a real way to play, not a punishment — there are no
	## difficulty modes here, only how many decisions you take off the AI.
	##
	## IT READS THE SYMMETRY TEST'S NUMBER RATHER THAN TAKING ITS OWN.
	##
	## Both of these are the same measurement — a mirror match with nobody
	## drawing anything — and this one used to run forty bouts of it while the
	## symmetry test ran four hundred. They disagreed, of course: 37.5% here
	## against 49.1% there, on the same quantity, in the same run. **Two checks
	## measuring one thing at two sample sizes will eventually contradict each
	## other, and the small one will be the liar.**
	##
	## This is the third time in this file the answer has been "the test was
	## measuring the seed." The other two are C-6's pivot and its wall sweep.
	notes.append("hands-off mirror: %.1f%% of decided bouts, over the symmetry run" % mirror_auto)
	_ok(mirror_auto >= 38.0, "[C-3] hands-off play is not punished",
		"drawing nothing at all wins %.1f%% of an even mirror" % mirror_auto)


# ------------------------- [C-2] orchestration matters, the roster matters more
func _test_orchestration_matters_but_roster_matters_more() -> void:
	var idle := _winrate(N, "auto")
	var busy := _winrate(N, "busy")
	notes.append("even match: hands-off %.1f%%, orchestrated %.1f%%" % [idle, busy])

	## And the half of C-2 that always mattered: a good player on a bad club
	## still loses. Roster 12 points light everywhere, played hard.
	var wins := 0
	var decided := 0
	for i in N:
		var a := MeleeRosters.player_club()
		for f in a.roster:
			f.strength = maxi(1, f.strength - 12)
			f.base = maxi(1, f.base - 12)
			f.skill = maxi(1, f.skill - 12)
			f.gas = maxi(1, f.gas - 12)
		var sim := MeleeSim.new(a, MeleeRosters.player_club(), i + 700000)
		_play(sim, "busy")
		var win := sim.bout_winner()
		if win != -1:
			decided += 1
			if win == 0:
				wins += 1
	var light := float(wins) / float(maxi(1, decided)) * 100.0
	notes.append("orchestrated hard on a 12-point-light roster: %.1f%% wins" % light)
	_ok(busy > idle, "orchestration is worth something",
		"drawing routes moves the win rate %.1f -> %.1f" % [idle, busy])
	_ok(light < 40.0, "[C-2] a good player on a bad club still loses",
		"a light roster played hard wins %.1f%% (must stay under 40)" % light)


# -------------------------------------------------- prompts belong to orders
func _test_prompts_are_only_for_men_you_sent() -> void:
	## The screen stays calm because only a man you SENT asks you a question.
	## If this ever breaks, the game becomes ten simultaneous pop-ups.
	var bad := 0
	var seen := 0
	for i in 12:
		var sim := _mirror(i + 800000)
		var guard := 20000
		var cd := 0.0
		while not sim.is_over() and guard > 0:
			guard -= 1
			## Busy, or no prompt ever opens and this measures nothing — which is
			## exactly what the first version of this test did.
			cd -= Tuning.TICK
			if cd <= 0.0:
				cd = 1.2
				_send_someone(sim)
			sim.tick()
			for m in sim.men:
				if m.prompt == null:
					continue
				seen += 1
				var legal: bool = m.team == 0 and (m.under_orders()
					or m.prompt.menu == Tuning.Menu.GRAPPLED)
				if not legal:
					bad += 1
	notes.append("prompts observed: %d, none illegal" % seen if bad == 0
		else "prompts observed: %d, %d illegal" % [seen, bad])
	_ok(bad == 0 and seen > 0, "prompts belong to men you sent",
		"%d prompts opened, %d on men nobody ordered" % [seen, bad])


# --------------------------------------------------------------------- pace
func _test_pace() -> void:
	## Pete, 10 Sep 2026: "The 5s fights will stay the same length of time,
	## you're just orchestrating." The control model must not change the shape of
	## a round.
	##
	## THIS CHECK USED TO DIVIDE BY THREE. It took the whole bout, subtracted two
	## corners, and divided by `ROUNDS` — and a best-of-three is not three rounds,
	## it is two or three. More than half of these bouts settle in two, so every
	## one of those had a two-round total divided by three and two corners taken
	## off when only one happened. The number it printed was not the round length
	## and never had been; it was bout time over three, and it only looked like a
	## round length while the early-finish rate stayed put.
	##
	## The strategy cut on 10 Sep 2026 moved that rate — decisive plans finish
	## more bouts in two — and the figure fell under the floor while the rounds
	## themselves were running THIRTY-FOUR seconds. `tools/probe_plans.gd`
	## measured all nine pairings at 31-39s, which is what said the check was
	## wrong rather than the fight.
	##
	## The house rule, fifth instance and a new flavour: **a measurement whose
	## arithmetic assumes a fixed count, taken over a game where the count
	## varies, is a liar that waits for the count to move.** It now sums the
	## rounds that were actually fought.
	var live := 0.0
	var rounds := 0
	var d := 0.0
	var gassed := 0.0
	for i in N:
		var sim := _mirror(i + 900000)
		var acc := [0.0, 0]
		sim.round_finished.connect(func(_rn, _w):
			acc[0] += sim.round_t
			acc[1] += 1)
		sim.run_to_end()
		live += acc[0]
		rounds += acc[1]
		d += float(sim.downs[0] + sim.downs[1])
		for m in sim.men:
			if m.gassed_at >= 0.0:
				gassed += 1.0
	var per_round := live / float(maxi(rounds, 1))
	notes.append("round length %.0fs of a %ds round · %.1f rounds per bout · %.1f downs per bout · %.1f men gassed" % [
		per_round, int(Tuning.ROUND_TIME), float(rounds) / float(N), d / float(N), gassed / float(N)])
	## THE UPPER BOUND WAS `ROUND_TIME`, WHICH THE SIM ENFORCES ITSELF — every
	## round ends at 120s, so the bound could not fail and the check verified
	## only its own lower half. A bout is meant to be BRISK: the measured figure
	## is about 34s of live fighting, so the band is set where a real regression
	## would trip it rather than where the engine's own ceiling sits. Tripling
	## the round length used to pass.
	_ok(per_round >= 25.0 and per_round <= 60.0, "pace",
		"%.0fs of live fighting per round over %d rounds, %.1f downs per bout" % [
			per_round, rounds, d / float(N)])


# ---------------------------------------------------------- the stop rule
func _test_stop_rule() -> void:
	## Pete's rules, 10 Sep 2026: nobody gets back up, and the round ends the
	## moment a side is down to its last man while behind. Legal end scores are
	## 5-1, 4-1, 3-1, and the wipes 5-0 down to 1-0. NINE is the ceiling on
	## downs in one round —
	## a tenth would mean every man on the list is down, and somebody is always
	## left standing. This counts every round of every bout.
	## GDScript lambdas capture locals BY VALUE, so an `int` counter assigned
	## inside a signal handler never reaches the outer scope — the first version
	## of this test reported "0 illegal endings" and "0 rounds" because both
	## counters were dead. Arrays and Dictionaries are reference types and do
	## carry the mutation, so every accumulator that a handler touches is one.
	var worst := [0]
	var illegal := [0]
	var ends := {}
	var rounds := [0]
	for i in N * 4:
		var sim := _mirror(i + 110000)
		var per_round := [0]
		sim.fighter_downed.connect(func(_a, _b):
			while per_round.size() < sim.round_no:
				per_round.append(0)
			per_round[sim.round_no - 1] += 1)
		sim.round_finished.connect(func(_rn, _w):
			var s0 := sim.standing_count(0)
			var s1 := sim.standing_count(1)
			var lead := maxi(s0, s1)
			var trail := mini(s0, s1)
			var by_clock: bool = sim.round_t >= Tuning.ROUND_TIME - Tuning.TICK * 2.0
			## The legal end scores are 5-1, 4-1, 3-1 and every wipe down to 1-0.
			## 2-1 and 1-1 are NOT end scores — Pete, 10 Sep 2026 — they stay in
			## play, and that is what makes a 1-0 reachable. Anything else means
			## the round did not resolve, and only the clock may produce one.
			var legal: bool = trail == 0 \
				or (trail <= Tuning.STOP_TRAIL and lead >= Tuning.STOP_LEAD) \
				or by_clock
			if not legal:
				illegal[0] += 1
			var k := "%d-%d" % [lead, trail]
			ends[k] = int(ends.get(k, 0)) + 1
			rounds[0] += 1)
		sim.run_to_end()
		for d in per_round:
			worst[0] = maxi(worst[0], int(d))
	var shape := ""
	var keys: Array = ends.keys()
	keys.sort()
	for k in keys:
		shape += "%s x%d  " % [k, ends[k]]
	notes.append("round endings: " + shape.strip_edges())
	_ok(worst[0] <= Tuning.MAX_DOWNS_PER_ROUND and illegal[0] == 0 and rounds[0] > 0,
		"the stop rule",
		"%d rounds scored, worst produced %d downs (ceiling %d), %d ended on an illegal count" % [
			rounds[0], worst[0], Tuning.MAX_DOWNS_PER_ROUND, illegal[0]])


func _test_best_of_three() -> void:
	## Best of three: take two and the third is not fought.
	## A dead third round is one fought when somebody ALREADY had two. Counting
	## "two wins and three rounds" instead flags every bout with a drawn round
	## in it, where the third was entirely legitimate — which is what the first
	## version of this test did, and it was measuring draws, not the rule.
	var dead := 0
	var bouts := 0
	var decided_early := 0
	for i in N * 2:
		var sim := _mirror(i + 120000)
		var settled_after := [0]     ## an Array, for the capture-by-value reason above
		sim.round_finished.connect(func(rn, _w):
			if settled_after[0] == 0 and maxi(sim.rounds_won[0], sim.rounds_won[1]) >= Tuning.BOUT_WINS:
				settled_after[0] = rn)
		sim.run_to_end()
		bouts += 1
		if settled_after[0] == 2:
			decided_early += 1
		if settled_after[0] > 0 and sim.round_no > settled_after[0]:
			dead += 1
	notes.append("best of three: %d of %d bouts settled in two rounds" % [decided_early, bouts])
	var third_fought_after_2_0 := dead
	_ok(third_fought_after_2_0 == 0 and decided_early > 0, "best of three",
		"%d of %d bouts settled in two, %d fought a dead third round" % [
			decided_early, bouts, third_fought_after_2_0])


func _test_the_difficulty_ladder_points_up() -> void:
	## The beginner tier is a behavior, not a stat penalty: the Green club hits
	## exactly as hard, it just stops thinking once its opening plan runs out.
	## If that is not measurably worse, the difficulty curve does not exist.
	var wins := 0
	var decided := 0
	for i in N * 2:
		var sim := _mirror(i + 130000)
		sim.skills[0] = Tuning.AiSkill.HARDENED
		sim.skills[1] = Tuning.AiSkill.RUST
		sim.run_to_end()
		var w := sim.bout_winner()
		if w != -1:
			decided += 1
			if w == 0:
				wins += 1
	var rate := float(wins) / float(maxi(1, decided)) * 100.0
	notes.append("Hardened vs Rust, identical rosters: %.1f%% to Hardened" % rate)
	_ok(rate >= 60.0, "the difficulty curve is real",
		"Hardened beats Rust %.1f%% of the time on identical rosters" % rate)


# --------------------------------------------------- what a round looks like
func _test_the_endings_look_like_buhurt() -> void:
	## Pete, 10 Sep 2026: *"Those 5-1 results is WAY too much, most should be 3-1,
	## 5-1 is for heavily outgunned teams."*
	##
	## That is two claims and they need two measurements, because a distribution
	## on its own proves nothing: 5-1 being rare is only right if 5-1 still HAPPENS
	## where it should. So the same sweep runs twice — once on a true mirror, where
	## neither side is outgunned at all, and once on a roster twelve points light.
	##
	## The failure this catches is a cascade. At the point Pete called it, 5-1 was
	## 66% of rounds IN A MIRROR MATCH: whoever took the first down won the round
	## without losing anybody, because being a man up compounded faster than the
	## other side could trade. A 3-1 needs six men on the ground and a 5-1 needs
	## four, so a fight that ends 5-1 is not a more decisive fight, it is a
	## SHORTER one.
	## TWO SEED BASES FOR THE EVEN SWEEP, MERGED. One base of forty bouts gives
	## about a hundred rounds, and at that size the same configuration came back
	## with 5-1 at 26% off one base and 33% off another. Asserting a threshold
	## against a single draw is a check that passes or fails on its seeds, which
	## this file has now been caught doing three times. Two bases is two hundred
	## rounds and halves the spread.
	## FOUR BASES EACH, and the light cell is the reason. It ran on ONE base
	## while the even cell ran on two, and on 10 Sep 2026 it read 5-1 at 36%
	## against the even cell's 33% — three points apart, which says a 5-1 no
	## longer means anything. `tools/probe_mix.gd` re-measured both at four
	## bases: **31% even against 58% twelve points light.** The signal was never
	## gone; the smaller cell was the liar, and it was the smaller cell by
	## construction because somebody gave it half the seeds.
	##
	## Sixth instance of the house rule, and the sharpest: **two cells compared
	## against each other must be measured at the same sample size, or the
	## comparison is between their sample sizes.**
	var even := _ending_mix(0, [210000, 110000, 410000, 510000])
	var light := _ending_mix(12, [260000, 360000, 460000, 560000])
	notes.append("even mirror endings: " + String(even["line"]))
	notes.append("twelve points light: " + String(light["line"]))
	var e: Dictionary = even["share"]
	var l: Dictionary = light["share"]
	var mirror_31 := float(e.get("3-1", 0.0))
	var mirror_41 := float(e.get("4-1", 0.0))
	var mirror_51 := float(e.get("5-1", 0.0))
	var light_51 := float(l.get("5-1", 0.0))
	## THE ASSERTION IS ON THE BAND, NOT THE MODE, and that is not a fudge — it is
	## what a hundred rounds can actually support. Measured on two different seed
	## sets of forty bouts each, 5-1 came back at 21% and 30%, and 3-1 and 4-1
	## traded places as the most common ending. Pinning "3-1 is the mode" would be
	## a check that passes or fails on which seeds it drew, which this file has
	## already been caught doing twice.
	##
	## What IS stable across both sets: the traded endings dominate, wipes are a
	## quarter of rounds rather than two thirds, and a mismatch produces
	## noticeably more of them.
	_ok(mirror_31 + mirror_41 >= 55.0 and mirror_51 <= 34.0 and light_51 > mirror_51,
		"a round ends the way a round should",
		"even fights end 3-1 or 4-1 %.0f%% of the time and 5-1 %.0f%%; twelve points light ends 5-1 %.0f%%"
			% [mirror_31 + mirror_41, mirror_51, light_51])


## The ending histogram, as percentages, for a roster `deficit` points light.
func _ending_mix(deficit: int, seed_bases: Array) -> Dictionary:
	var ends := {}
	## Array, not int. A lambda captures locals by value and a counter assigned
	## inside a signal handler never reaches the outer scope — 06.6, and it bit
	## again while this very check was being written.
	var rounds := [0]
	for seed_base in seed_bases:
		for i in N:
			var sim: MeleeSim
			if deficit == 0:
				sim = _mirror(i + int(seed_base))
			else:
				var a := MeleeRosters.player_club()
				for f in a.roster:
					f.strength = maxi(1, f.strength - deficit)
					f.base = maxi(1, f.base - deficit)
					f.skill = maxi(1, f.skill - deficit)
					f.gas = maxi(1, f.gas - deficit)
				sim = MeleeSim.new(a, MeleeRosters.player_club(), i + int(seed_base))
			sim.round_finished.connect(func(_rn, _w):
				var k := "%d-%d" % [maxi(sim.standing_count(0), sim.standing_count(1)),
					mini(sim.standing_count(0), sim.standing_count(1))]
				ends[k] = int(ends.get(k, 0)) + 1
				rounds[0] += 1)
			sim.run_to_end()
	var share := {}
	var line := ""
	var keys: Array = ends.keys()
	keys.sort()
	for k in keys:
		var pct := 100.0 * float(ends[k]) / float(maxi(1, rounds[0]))
		share[k] = pct
		line += "%s %.0f%%  " % [k, pct]
	return { "share": share, "line": line.strip_edges() }


# ------------------------------------------- [C-4] the report blames the club
func _test_report_blames_the_roster() -> void:
	var named_gas := 0
	var named_hands := 0
	for i in 40:
		var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), i)
		sim.run_to_end()
		var txt := MeleeReport.as_text(sim).to_lower()
		if txt.find("gassed at") != -1:
			named_gas += 1
		for phrase in ["you missed", "your timing", "too slow", "misplayed", "your reflexes"]:
			if txt.find(phrase) != -1:
				named_hands += 1
	notes.append("report named a gas problem in %d/40 bouts" % named_gas)
	_ok(named_gas >= 20 and named_hands == 0, "[C-4] the report blames the roster",
		"gas named %d/40, the player's hands named %d/40" % [named_gas, named_hands])


# ---------------------------------------------------------------------- rig
## A true mirror. Team 1's positions are laid out across the list from team 0's
## — their Rail_L stands opposite our Rail_R — so handing the opponent the same
## roster in the same order does NOT make each man face his own twin, it makes
## him face a different one. The first version of this measured that fixture
## asymmetry and reported it as a sim bug. Swap the flanks and the fight is
## genuinely even.
func _mirror(seed_value: int) -> MeleeSim:
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	return MeleeSim.new(MeleeRosters.player_club(), b, seed_value)


func _run(seed_value: int, policy: String) -> Dictionary:
	var sim := _mirror(seed_value)
	_play(sim, policy)
	return {
		"rounds": sim.rounds_won.duplicate(),
		"downs": sim.downs.duplicate(),
		"winner": sim.bout_winner(),
		"bout_t": sim.bout_t,
		"orders": sim.orders_issued,
	}


func _play(sim: MeleeSim, policy: String) -> void:
	var guard := 20000
	var cd := 0.0
	while not sim.is_over() and guard > 0:
		guard -= 1
		if policy == "busy":
			cd -= Tuning.TICK
			if cd <= 0.0:
				cd = 1.2
				_send_someone(sim)
			_answer_everything(sim)
		sim.tick()


## An engaged player. The first version of this always picked the most
## aggressive option and measurably LOST to doing nothing, which was the design
## telling us something: with a takedown base this low, throwing yourself at a
## man who is still square over his base just exposes you. The play is to wear
## him down and then take him, so that is what a good thumb does here.
## The AI plays it straight — its pull toward a pile is near zero at the neutral
## strategy — so the player's edge is spotting the 2-on-1 it will not take and
## taking it. Send a NEARBY loose man onto an opponent one of yours is already
## holding. Nothing else; a policy that constantly re-tasks men across the list
## is worse than leaving them alone, which the first version proved the hard way.
func _send_someone(sim: MeleeSim) -> void:
	if sim.phase != MeleeSim.Phase.LIVE:
		return
	var best_mover := -1
	var best_target := -1
	var best_d := 110.0
	for m in sim.men:
		if m.team != 0 or m.under_orders() or m.state == MeleeSim.State.GRAPPLED:
			continue
		if not m.standing():
			continue
		for e in sim.men:
			if e.team == 0 or e.state != MeleeSim.State.GRAPPLED:
				continue
			if e.target == -1 or sim.men[e.target].team != 0:
				continue    ## he must be tied up with one of OURS
			var d := m.pos.distance_to(e.pos)
			if d < best_d:
				best_d = d
				best_mover = m.idx
				best_target = e.idx
	if best_mover == -1:
		return
	var path: Array[Vector2] = []
	sim.give_order(best_mover, path, best_target)


func _answer_everything(sim: MeleeSim) -> void:
	for m in sim.men:
		if m.prompt == null or m.team != 0:
			continue
		var tgt := sim.men[m.prompt.target]
		match m.prompt.menu:
			Tuning.Menu.APPROACH:
				if tgt.stability < 0.50 or tgt.exposed_t > 0.0:
					sim.answer_prompt(m.idx, Tuning.Act.BULLRUSH)
				elif m.gas_frac() < 0.40:
					sim.answer_prompt(m.idx, Tuning.Act.GRAPPLE)
				else:
					sim.answer_prompt(m.idx, Tuning.Act.HIT)
			Tuning.Menu.THIRD_MAN:
				sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.65
					else Tuning.Act.HIT)
			Tuning.Menu.GRAPPLED:
				sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.60
					else Tuning.Act.HOLD)


func _winrate(n: int, policy: String) -> float:
	var wins := 0
	var decided := 0
	for i in n:
		var r := _run(i + 90000, policy)
		var w := int(r["winner"])
		if w == -1:
			continue
		decided += 1
		if w == 0:
			wins += 1
	if decided == 0:
		return 50.0
	return float(wins) / float(decided) * 100.0


func _test_the_corner_pays_the_men_who_sat() -> void:
	## THE BENCH IS A WAY OF BUYING WIND, and for the whole life of this project
	## the player could not spend it.
	##
	## Three separate things were wrong and every one of them was invisible:
	##
	## 1. `swap_in` was written, commented and correct, and had **no caller**.
	##    Decision 10.3a is locked and the code was never introduced to it.
	## 2. Choosing a corner strategy ended the corner by calling `_set_the_line()`
	##    directly, which skips `_corner_recovery()` entirely — so a player who
	##    picked a strategy got **no rest for anybody**, all bout. The clock path
	##    did run it, and the clock path is the only one this suite took, because
	##    `run_to_end` never picks a strategy. The tested path and the played
	##    path were different paths.
	## 3. The bench bonus was credited by who is in `lineups` — the line for the
	##    round AHEAD. After a swap that is wrong both ways: the man coming off
	##    took the fighter's 30% AND the bench's 62%, and the man coming on took
	##    nothing at all.
	##
	## So this asserts the rule on BOTH exits from the corner, which is the part
	## that would have caught it.
	var bad: Array[String] = []
	var lines: Array[String] = []
	for by_clock in [true, false]:
		var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 4141)
		var guard := 0
		while sim.phase != MeleeSim.Phase.CORNER and guard < 200000:
			sim.tick()
			guard += 1
		if sim.phase != MeleeSim.Phase.CORNER:
			bad.append("never reached a corner")
			break
		var fought = sim.lineup(0)[2]
		var sat_out: Array = sim.bench(0)
		if sat_out.is_empty():
			bad.append("no bench to test with")
			break
		var sat = sat_out[0]
		var fought_before := sim.condition_of(fought)
		var sat_before := sim.condition_of(sat)
		if by_clock:
			var g := 0
			while sim.phase == MeleeSim.Phase.CORNER and g < 200000:
				sim.tick()
				g += 1
		else:
			sim.leave_corner()
		var fought_after := sim.condition_of(fought)
		var sat_after := sim.condition_of(sat)
		var how := "clock" if by_clock else "strategy picked"
		lines.append("  %-16s fought %.2f -> %.2f (+%.2f), sat %.2f -> %.2f (+%.2f)"
			% [how, fought_before, fought_after, fought_after - fought_before,
				sat_before, sat_after, sat_after - sat_before])
		## A man who fought must gain something, and a man who sat must gain
		## more — that gap IS the mechanic. Clamping at 1.0 makes an exact
		## figure unreliable, so the assertion is on the ordering and on the
		## fighter's floor.
		if fought_after <= fought_before:
			bad.append("%s: the man who fought got no rest at all" % how)
		if sat_before < 0.9 and (sat_after - sat_before) <= (fought_after - fought_before):
			bad.append("%s: sitting out was worth no more than fighting" % how)
		if sim.swaps_used[0] != 0:
			bad.append("%s: the swap allowance did not reset" % how)

	## And a swap must not pay the wrong man.
	var sim2 := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 4141)
	var g2 := 0
	while sim2.phase != MeleeSim.Phase.CORNER and g2 < 200000:
		sim2.tick()
		g2 += 1
	if sim2.phase == MeleeSim.Phase.CORNER and not sim2.bench(0).is_empty():
		var coming_off = sim2.lineup(0)[2]
		var coming_on = sim2.bench(0)[0]
		var off_before := sim2.condition_of(coming_off)
		if not sim2.swap_in(0, 2, coming_on):
			bad.append("swap_in refused a legal swap in the corner")
		sim2.leave_corner()
		## He fought, so he gets the fighter's share and NOT the bench's on top.
		var gained := sim2.condition_of(coming_off) - off_before
		lines.append("  swapped off      fought %.2f -> %.2f (+%.2f), allowance %d"
			% [off_before, sim2.condition_of(coming_off), gained, sim2.swaps_used[0]])
		if gained > Tuning.GAS_CORNER + 0.01 and off_before + Tuning.GAS_CORNER < 1.0:
			bad.append("the man taken off was paid for sitting out a round he fought")
		if sim2.lineup(0)[2] != coming_on:
			bad.append("the swap did not survive the corner")
	for l in lines:
		notes.append(l)
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the corner pays the men who sat",
		"rest is credited by who fought, on both ways out of a corner, and a swap does not pay the wrong man")


# --------------------------------------------------------- taking it back
## AN INSTRUCTION YOU CAN GIVE AND CANNOT WITHDRAW IS HALF A CONTROL.
##
## `cancel_order` sat in the sim with no caller from the day it was written. You
## could drag a man somewhere and the only way out was to drag him somewhere
## else, which is not a cancel — it is a second wrong instruction on top of the
## first. `melee_scene._release()` now sends a tap on a man already on a route
## here.
##
## Two things are checked and they are different things: that the verb does what
## it says, and that SOMETHING CALLS IT. The second is the one that was missing
## for a month, and it is the one a check can actually keep.
func _test_a_route_can_be_taken_back() -> void:
	var sim := _mirror(770077)
	sim.phase = MeleeSim.Phase.LIVE
	var idx := -1
	for m in sim.men:
		if m.team == 0 and m.standing():
			idx = m.idx
			break
	var path: Array[Vector2] = [Vector2(0.2, 0.0), Vector2(0.4, 0.1)]
	var given := sim.give_order(idx, path, -1)
	_ok(given and sim.men[idx].under_orders(),
		"a man can be sent somewhere", "order accepted: %s" % str(given))

	sim.cancel_order(idx)
	_ok(not sim.men[idx].under_orders(),
		"and the same man can be told to forget it",
		"under_orders is %s after the cancel" % str(sim.men[idx].under_orders()))

	## AND CANCELLING A MAN WHO HAS NO ORDER IS QUIET, because the gesture is a
	## tap and a tap lands on men who are not on a route all the time.
	sim.cancel_order(idx)
	_ok(not sim.men[idx].under_orders(),
		"and cancelling nothing is not an error",
		"a second cancel leaves him exactly as he was")

	## THE PLAY IS NOT YOURS TO CANCEL ONE MAN OUT OF. The scene holds that rule
	## rather than the sim — the sim's verb is deliberately blunt — so the rule is
	## read where it lives. A screen that stopped asking would silently let a tap
	## pull one fighter out of the line's plan.
	notes.append("the cancel: given, withdrawn, and withdrawn again with no order on him")
