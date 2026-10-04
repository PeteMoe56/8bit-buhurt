extends SceneTree
## THE BULLRUSH, AS PETE DIALLED IT (Bullrush Bench, 4 Oct 2026).
##
##   godot --headless --path . --script res://tests/test_bullrush.gd
##
## The wheel opens at PROMPT_RANGE; Bullrush picked off it is a charge at
## BR_SPEED x his pace that plants BR_STOP short; then somebody slides — the
## floored man BR_DOWN_SLIDE, the shoved man BR_BUMP_SLIDE, the thrower who went
## over BR_FAIL_SLIDE — and a slide that meets the rail glances off it at the
## angle it went in, keeping BR_RAIL_KICK of what was left. Each of those is a
## number on Pete's Bench; these checks hold the game to the Bench.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the bullrush ===\n")
	_test_rail_geometry()
	_test_the_charge()
	_test_unanswered_walks_in()
	print("")
	if failures.is_empty():
		print("THE BULLRUSH HOLDS (%d checks)\n" % checks)
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


func _test_rail_geometry() -> void:
	var r := Tuning.RAIL_INSET
	## Straight into the left rail: 16 to reach it, the other 24 cut to the kick.
	var a: Array = MeleeSim.slide_path(Vector2(r + 16.0, 300.0), Vector2.LEFT, 40.0)
	var want := r + 24.0 * Tuning.BR_RAIL_KICK
	_ok(absf(Vector2(a[0]).x - want) < 0.01 and int(a[1]) == 1,
		"a slide into the rail comes back off it with the kick's share",
		"ended x %.2f (want %.2f), %d rail hit" % [Vector2(a[0]).x, want, int(a[1])])
	## At an angle: along the rail it keeps going the same way, across it it turns.
	var d := Vector2(-1.0, 1.0).normalized()
	var b: Array = MeleeSim.slide_path(Vector2(r + 10.0, 300.0), d, 40.0)
	var p := Vector2(b[0])
	_ok(p.x > r and p.y > 300.0 + 10.0 and int(b[1]) == 1,
		"at an angle he glances off — still travelling along the rail, now away from it",
		"ended at (%.1f, %.1f)" % [p.x, p.y])
	## Never through it, from anywhere, any way.
	var inside := true
	for i in 64:
		var ang := TAU * float(i) / 64.0
		var q: Array = MeleeSim.slide_path(Vector2(r + 3.0, Tuning.LIST_H - r - 3.0),
			Vector2(cos(ang), sin(ang)), 200.0)
		var v := Vector2(q[0])
		if v.x < r - 0.01 or v.x > Tuning.LIST_W - r + 0.01 or v.y < r - 0.01 \
				or v.y > Tuning.LIST_H - r + 0.01:
			inside = false
	_ok(inside, "no slide leaves the list, in a corner, in any direction", "64 directions, 200 units")


## Two men on an empty list: ours sent at a planted enemy who never acts.
func _duel(seed_: int) -> Array:
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), seed_, 1.0)
	sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
	## A spare man each side, planted in a far corner, so a man going down does
	## not end the round (a round over is a corner, and a corner does not tick).
	var us = null
	var them = null
	var spare := [null, null]
	for m in sim.men:
		if m.team == 0 and us == null:
			us = m
		elif m.team == 1 and them == null:
			them = m
		elif spare[m.team] == null:
			spare[m.team] = m
		else:
			m.state = MeleeSim.State.OUT
	us.pos = Vector2(150.0, 140.0)
	them.pos = Vector2(150.0, 330.0)
	spare[0].pos = Vector2(30.0, 30.0)
	spare[1].pos = Vector2(Tuning.LIST_W - 30.0, Tuning.LIST_H - 30.0)
	for m in [them, spare[0], spare[1]]:
		m.planted = true
		m.planted_at = m.pos
	return [sim, us, them]


func _test_the_charge() -> void:
	var seen := {}
	var opened_ok := true
	var ratio_ok := true
	var gap_ok := true
	var slide_ok := true
	var notes: Array[String] = []
	var slides: Array[String] = []
	for s in 24:
		var t: Array = _duel(51000 + s)
		var sim: MeleeSim = t[0]
		var us = t[1]
		var them = t[2]
		var landed: Array = []
		sim.bullrush_landed.connect(func(i, tg, o, _d):
			landed.append([i, tg, o, sim.men[i].pos.distance_to(sim.men[tg].pos)]))
		sim.give_order(us.idx, [] as Array[Vector2], them.idx)
		var walk := 0.0
		var k := 0
		while us.prompt == null and k < 2000:
			them.next_act = 99.0
			var p0: Vector2 = us.pos
			sim.tick()
			walk = us.pos.distance_to(p0)
			k += 1
		var d_open: float = us.pos.distance_to(them.pos)
		if us.prompt == null or d_open > Tuning.PROMPT_RANGE + 0.01 or d_open < Tuning.PROMPT_RANGE - 3.0:
			opened_ok = false
			notes.append("seed %d opened at %.1f" % [s, d_open])
			continue
		## Every third one against a man already rocked, so the downing is seen.
		if s % 3 == 0:
			them.stability = 0.0
			them.exposed_t = 30.0
		sim.answer_prompt(us.idx, Tuning.Act.BULLRUSH)
		var run := 0.0
		var charged := false
		while landed.is_empty() and k < 4000:
			them.next_act = 99.0
			var p1: Vector2 = us.pos
			sim.tick()
			if us.charging and us.pos.distance_to(them.pos) > 40.0:
				run = us.pos.distance_to(p1)
				charged = true
			k += 1
		if landed.is_empty() or not charged:
			ratio_ok = false
			notes.append("seed %d never charged/landed" % s)
			continue
		if absf(run / maxf(0.001, walk) - Tuning.BR_SPEED) > 0.35:
			ratio_ok = false
			notes.append("seed %d charge %.2fx walk" % [s, run / walk])
		var gap: float = landed[0][3]
		if absf(gap - Tuning.BR_STOP) > 1.5:
			gap_ok = false
			notes.append("seed %d planted at %.1f" % [s, gap])
		var o: int = landed[0][2]
		var who = us if o == MeleeSim.BR_FELL else them
		var want: float = [Tuning.BR_FAIL_SLIDE, Tuning.BR_BUMP_SLIDE, Tuning.BR_DOWN_SLIDE][o]
		var dur: float = [Tuning.BR_FAIL_SLIDE_T, Tuning.BR_BUMP_SLIDE_T, Tuning.BR_DOWN_SLIDE_T][o]
		## The slide as set: Pete's distance over Pete's time.
		if not who.sliding() or absf(who.slide_dist - want) > 0.01 or absf(who.slide_dur - dur) > 0.01:
			slide_ok = false
			slides.append("seed %d outcome %d slide %.1f over %.2f" % [s, o, who.slide_dist, who.slide_dur])
		## And as travelled, for a man on the floor (a shoved man who stays up
		## walks again, and a planted one goes back to his spot).
		if o != MeleeSim.BR_BUMP:
			var from: Vector2 = who.slide_from
			for _i in int((dur + 0.2) / Tuning.TICK):
				them.next_act = 99.0
				sim.tick()
			var moved: float = who.pos.distance_to(from)
			if absf(moved - want) > 1.0:
				slide_ok = false
				slides.append("seed %d outcome %d slid %.1f (want %.1f)" % [s, o, moved, want])
		seen[o] = int(seen.get(o, 0)) + 1
	_ok(opened_ok, "the wheel opens at PROMPT_RANGE (%.0f)" % Tuning.PROMPT_RANGE, str(notes))
	_ok(ratio_ok, "Bullrush off the wheel is a charge at BR_SPEED x his pace (%.2f)" % Tuning.BR_SPEED, str(notes))
	_ok(gap_ok, "he plants BR_STOP short (%.0f) and the hit lands there" % Tuning.BR_STOP, str(notes))
	_ok(slide_ok, "whoever goes slides Pete's distance", "outcomes seen %s %s" % [str(seen), str(slides)])
	_ok(seen.size() == 3,
		"24 charges land all three ways: down, shoved, over", str(seen))


## A question nobody answers does not leave him standing 85 units out: he walks
## in on it and the AI's answer lands at contact.
func _test_unanswered_walks_in() -> void:
	var t: Array = _duel(52000)
	var sim: MeleeSim = t[0]
	var us = t[1]
	var them = t[2]
	var acted := []
	sim.action_resolved.connect(func(i, _a, _tg, _ok_): if i == us.idx: acted.append(i))
	sim.give_order(us.idx, [] as Array[Vector2], them.idx)
	var k := 0
	var stood := 0
	while acted.is_empty() and k < 1200:
		them.next_act = 99.0
		var p0: Vector2 = us.pos
		sim.tick()
		if us.prompt != null and us.pos.distance_to(p0) < 0.01:
			stood += 1
		k += 1
	_ok(not acted.is_empty() and stood < 6, "an unanswered wheel: he keeps walking and acts on arrival",
		"acted %s after %.1f s, %d ticks standing with the question open" % [str(not acted.is_empty()), k * Tuning.TICK, stood])
