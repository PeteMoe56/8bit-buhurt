extends SceneTree
## RB_TIER: balance-only — every check here is a statistical band.
## C-6, restated and measured.
##
##   godot --headless --path . --script res://tests/test_c6.gd
##
## THE OLD C-6 WAS WRONG. It read *"formation and strategy must outrank the
## thumb"*, and it was the one constraint in the file with no test — which is
## exactly how a wrong rule survives. Pete, 10 Sep 2026:
##
##   *"Player manipulation, when done well, should give an advantage. A great
##   player should be able to thumb-manoeuvre a win out of being out-positioned
##   and out-strategized. Out-powered by a heavy degree along with those things
##   however should result in losses."*
##
## So the hierarchy is not flat, it is a ladder:
##
##   **the roster beats the thumb, and the thumb beats the tactics.**
##
## Which makes C-6 two claims and a boundary, and every one of them is a number:
##
##   1. THE THUMB BEATS THE TACTICS. Hand the player the worst formation and
##      strategy on the board against the best, on an even roster, and a good
##      thumb still wins it.
##   2. THE ROSTER BEATS THE THUMB. Add a heavy power deficit to that same
##      tactical hole and no amount of thumb saves it. (C-2 already tests the
##      easy half of this at 12 points; what was missing is the boundary.)
##   3. WHERE THE WALL IS. The deficit at which orchestration stops paying, swept
##      rather than guessed — because "a heavy degree" is a feeling until it is
##      a number, and a designer cannot balance a feeling.
##
## The worst tactical pairing is MEASURED, not invented. Asserting a counter
## matrix I made up would only test that I can write down what I wrote down.

## Bouts per cell. Every number this suite prints moved several points between
## two runs at 10-24 bouts, so nothing here should be read to better than about
## five points — which is exactly why the assertions are placed at 50% and 40%
## and not at the measured values.
const N := 24
const DEFICITS := [0, 4, 8, 12, 16]
## ONE seed base for every cell in this suite.
##
## C-6a and the wall sweep measured the same thing — a good thumb in the tactical
## hole on an even roster — off two different seed bases, and came back with
## 58.3% and 42%. Sixteen points apart, for an identical configuration, which
## meant the suite could pass one check and fail the other on the same fight.
## Sharing the base makes the deficit-0 cell literally the C-6a number, so the
## two cannot disagree; it does not make either of them more precise, and the
## note about five points still applies.
const SEED_BASE := 30000

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — C-6: the roster, the thumb and the tactics ===\n")
	var hole := _the_hole()
	_test_thumb_beats_tactics(hole)
	_test_the_roster_wall(hole)

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("C-6 HOLDS (%d checks)\n" % checks)
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


# --------------------------------------------------------- the tactical hole
## THE PAIRING IS FIXED AND MEASURED, NOT RE-DERIVED EVERY RUN.
##
## The first version swept all twenty formation/strategy pairings, picked
## whichever lost hardest, and hung every assertion below it on that pick — off
## ten bouts. Re-measured on a different seed base the same sweep produced a
## different answer, which means the suite's own pivot was noise. **A test that
## chooses its own baseline from an under-powered sample is not measuring the
## game, it is measuring the seed.**
##
## So the hole is a constant, measured with tools/diag_c6.gd and written down.
## RE-MEASURE IT WHENEVER THE ARENA CHANGES — this is a balance record, not a
## fact about the sport, and it goes stale the moment the list does. It already
## has: on the 320 list and again on the 760 one the hole was Refused flank +
## Strong left, and on the 570 list that same pairing is a mild ADVANTAGE. The
## check that caught it is the one that asks whether swapping the two setups
## moves anything, which came back at minus twelve points.
##
## 2-1-2 + Strong left wins 36% hands-off against Strong left + Right rail push.
##
## **THIS PAIRING HAS NOW GONE STALE FIVE TIMES** — every arena change and every
## formation rewrite invalidates it, which is every session that touches the
## fight. That is a defect in how this suite is built, not a chore: a baseline
## hard-coded against a moving sim is a baseline that spends most of its life
## wrong, and it fails LOUDLY in a way that looks like a balance regression.
##
## What it should do instead is find its own hole at run time — sweep a handful
## of pairings, take the first one under about 45% hands-off, and assert on the
## RELATIONSHIP (the thumb lifts it, the roster eventually stops it) rather than
## on any particular setup. The sweep is the expensive part and that is the whole
## reason it was hard-coded; doing it properly means budgeting for it. Open.
##
## Re-swept four times, and the last sweep is the one that mattered. The formation
## was Spearhead — Center forward, pairs trailing — and it measured 21-36%
## whatever was bolted to it. I read that as a balance bug and wrote it up as one.
## Pete read it correctly: *"Spearhead is pretty dumb where you expose your center
## first. Centers are opportunists, not frontline."* The sim was right and the
## formation was a bad idea. **A measurement saying a design option is terrible is
## not automatically a bug in the measurement.**
##
## ------------------------------------------------------------------------
## THE HOLE IS SWEPT AT RUN TIME NOW, and this is the sixth time it has had to
## be dealt with, so it is worth saying why plainly.
##
## It used to be two constants — a formation and a strategy I had measured once
## and written down. It went stale FIVE TIMES: every arena change, every
## formation rewrite, every rebalance, and finally the strategy cut on 10 Sep
## 2026, which deleted the enum value it named. Each time the suite reported a
## balance regression that was really a stale constant, and each time it cost an
## hour to work out which.
##
## A hard-coded baseline in a test of a system under active balance is a
## expiring asset. So the suite finds its own hole: it walks every pairing of
## formation and strategy, at THE SAME N THE ASSERTIONS USE, and takes the first
## one where a hands-off player is genuinely losing. Then it asserts the
## RELATIONSHIP — that the thumb climbs out of it, and that roster weight stops
## the thumb — rather than any particular number.
##
## Measuring at the suite's own N is not an optimisation detail, it is the whole
## point: a sweep that ranks at a smaller sample hands the test a baseline the
## test cannot reproduce, which is exactly how `diag_c6` picked a 36% pairing
## the suite then measured at 50%.
## ------------------------------------------------------------------------

## What counts as "out-positioned and out-strategized": a hands-off player in
## this pairing is losing clearly, not coin-flipping. Set below the 50% the
## assertion uses so a hole found here has room to still be a hole when the
## thumb check re-measures it.
const HOLE_CEILING := 45.0
## How many pairings to try before giving up and reporting the worst seen. A
## board with no hole in it is a real finding — it would mean formation and
## strategy are decoration — so this fails loudly rather than sweeping forever.
const HOLE_BUDGET := 14


func _setups() -> Array:
	var out: Array = []
	for f in Tuning.FORMATIONS.keys():
		for st in Tuning.STRATEGIES.keys():
			out.append([int(f), int(st)])
	return out


func _the_hole() -> Dictionary:
	var setups := _setups()
	var worst := {}
	var worst_rate := 101.0
	var tried := 0
	for them in setups:
		for us in setups:
			if us[0] == them[0] and us[1] == them[1]:
				continue
			if tried >= HOLE_BUDGET:
				break
			tried += 1
			var rate := _winrate(N, "auto", us[0], us[1], them[0], them[1], 0, SEED_BASE)
			if rate < worst_rate:
				worst_rate = rate
				worst = {
					"formation": us[0], "strategy": us[1],
					"against_formation": them[0], "against_strategy": them[1],
					"rate": rate, "tried": tried,
				}
			if rate <= HOLE_CEILING:
				return worst
		if tried >= HOLE_BUDGET:
			break
	return worst


func _setup_name(f: int, st: int) -> String:
	return "%s / %s" % [Tuning.FORMATIONS[f]["name"], Tuning.STRATEGIES[st]["name"]]


# ------------------------------------------------- 1. the thumb beats tactics
func _test_thumb_beats_tactics(hole: Dictionary) -> void:
	## The player takes the worst setup on the board. The opposition takes the
	## best. Identical rosters. Hands off he should be losing; played hard he
	## must win it — that is Pete's *"thumb-manoeuvre a win out of being
	## out-positioned and out-strategized."*
	notes.append("the hole, swept at run time: %s against %s — found in %d pairings"
		% [_setup_name(int(hole["formation"]), int(hole["strategy"])),
			_setup_name(int(hole["against_formation"]), int(hole["against_strategy"])),
			int(hole["tried"])])
	## The sweep already measured this cell, at this N, off this seed base. Doing
	## it again would be the same number at twice the cost — and if it were NOT
	## the same number, the suite would be non-deterministic and that is a bigger
	## problem than C-6.
	var idle: float = float(hole["rate"])
	var busy := _winrate(N, "busy", int(hole["formation"]), int(hole["strategy"]),
		int(hole["against_formation"]), int(hole["against_strategy"]), 0, SEED_BASE)
	## The mirror of it: the same club with the BEST setup instead of the worst.
	## If those two land on top of each other, formation and strategy are
	## decoration and there is no hole for the thumb to climb out of.
	var good := _winrate(N, "auto", int(hole["against_formation"]), int(hole["against_strategy"]),
		int(hole["formation"]), int(hole["strategy"]), 0, SEED_BASE)
	notes.append("out-positioned and out-strategized, even roster: hands-off %.1f%%, thumb %.1f%%"
		% [idle, busy])
	notes.append("the same club with the setups swapped: %.1f%% hands-off" % good)
	_ok(good - idle >= 8.0, "formation and strategy are worth picking",
		"swapping the setups on an identical roster moves it %.1f points (needs 8)" % (good - idle))
	_ok(idle <= HOLE_CEILING, "the tactical hole is a real hole",
		"the worst pairing found leaves a hands-off player on %.1f%% (needs %.0f or under)"
			% [idle, HOLE_CEILING])
	_ok(busy > 50.0, "[C-6a] the thumb beats the tactics",
		"out-positioned and out-strategized, a good thumb still wins %.1f%% (was %.1f%% hands-off)"
			% [busy, idle])


# --------------------------------------------------- 2 & 3. the roster wall
func _test_the_roster_wall(hole: Dictionary) -> void:
	## The same tactical hole, now with the roster getting lighter. Somewhere on
	## this sweep the thumb stops being able to pay for it, and that crossing IS
	## "a heavy degree" — stated as a number instead of a feeling.
	var line := ""
	var wall := -1
	var last := 100.0
	for d in DEFICITS:
		var rate := _winrate(N, "busy", int(hole["formation"]), int(hole["strategy"]),
			int(hole["against_formation"]), int(hole["against_strategy"]), int(d), SEED_BASE)
		line += "%d:%.0f%%  " % [d, rate]
		## The wall is where the curve goes under and STAYS under, not the first
		## cell that dips. At two dozen bouts a cell, a single dip is as likely to
		## be the seed as the roster.
		if rate < 50.0:
			if wall == -1:
				wall = int(d)
		else:
			wall = -1
		last = rate
	notes.append("thumb win rate by roster deficit — " + line.strip_edges())
	notes.append("the wall: the thumb stops paying for the tactics at about %d points light"
		% wall if wall >= 0 else "the wall: never reached inside %d points" % DEFICITS[-1])

	## The two things that must be true whatever the curve looks like: there IS a
	## wall inside the sweep, and past it a good thumb is still losing. A game
	## where the thumb never runs out is an action game with a league attached.
	_ok(wall > 0, "[C-6b] the roster beats the thumb",
		"a good thumb carries the tactical hole until about %d points of roster deficit, then stops"
			% wall)
	_ok(last < 40.0, "[C-6c] out-powered by a heavy degree is a loss",
		"%d points light on top of the worst setup on the board wins %.1f%% (must stay under 40)"
			% [int(DEFICITS[-1]), last])


# ------------------------------------------------------------------ machinery
## `deficit` is points taken off every stat of every man on the player's club.
func _sim(seed_value: int, pf: int, ps: int, of_: int, os_: int, deficit: int) -> MeleeSim:
	var a := MeleeRosters.player_club()
	if deficit > 0:
		for f in a.roster:
			f.strength = maxi(1, f.strength - deficit)
			f.base = maxi(1, f.base - deficit)
			f.skill = maxi(1, f.skill - deficit)
			f.gas = maxi(1, f.gas - deficit)
	## A true mirror, so the ONLY differences in play are the tactics, the thumb
	## and the deficit. Positions are flipped because team 1's x is mirrored.
	var b := MeleeRosters.player_club()
	b.short_name = "MIR"
	for f in b.roster:
		match f.pos:
			Tuning.Pos.RAIL_L: f.pos = Tuning.Pos.RAIL_R
			Tuning.Pos.RAIL_R: f.pos = Tuning.Pos.RAIL_L
			Tuning.Pos.FLANK_L: f.pos = Tuning.Pos.FLANK_R
			Tuning.Pos.FLANK_R: f.pos = Tuning.Pos.FLANK_L
	var sim := MeleeSim.new(a, b, seed_value)
	sim.formations = [pf, of_]
	sim.strategies = [ps, os_]
	sim._set_the_line()
	return sim


func _winrate(n: int, policy: String, pf: int, ps: int, of_: int, os_: int,
		deficit: int, seed_base: int) -> float:
	var wins := 0
	var decided := 0
	for i in n:
		var sim := _sim(seed_base + i, pf, ps, of_, os_, deficit)
		_play(sim, policy)
		var w := sim.bout_winner()
		if w == -1:
			continue
		decided += 1
		if w == 0:
			wins += 1
	if decided == 0:
		return 50.0
	return float(wins) / float(decided) * 100.0


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


## The same engaged player the main suite uses, and deliberately so: this suite
## must measure the design, not a better thumb written specially for it.
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
				continue
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
