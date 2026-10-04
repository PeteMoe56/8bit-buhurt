extends SceneTree
## A ROUTE ENDING ON AN ENEMY FOLLOWS HIM (Pete, 4 Oct 2026).
##
##   godot --headless --path . --script res://tests/test_route_follow.gd
##
## "When you make the route, it works until you realize the enemy moves, then
## it ends up running past them and only following them after the route is run
## in its entirety instead of following the enemy." A route drawn onto a man is
## bent by where that man has gone since, and a sent man who is already on top
## of his target goes for him rather than finishing the line behind him. A bend
## that swings wide (a flank) is still walked.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — routes follow the man they end on ===\n")
	_test_he_comes_to_meet_you()
	_test_he_steps_aside()
	_test_a_flank_is_still_walked()
	_test_a_plain_route_is_untouched()
	print("")
	if failures.is_empty():
		print("ROUTES ONTO A MAN HOLD (%d checks)\n" % checks)
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


## One of ours, one of theirs, a spare each side parked in a corner.
func _duel(seed_: int, us_at: Vector2, them_at: Vector2) -> Array:
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), seed_, 1.0)
	sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
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
	us.pos = us_at
	them.pos = them_at
	spare[0].pos = Vector2(30.0, 30.0)
	spare[1].pos = Vector2(Tuning.LIST_W - 30.0, Tuning.LIST_H - 30.0)
	for m in [them, spare[0], spare[1]]:
		m.planted = true
		m.planted_at = m.pos
	return [sim, us, them]


## Tick until his options open (the moment he has reached his man), at most n.
func _run(sim: MeleeSim, us, them, n: int, each: Callable = Callable()) -> int:
	var k := 0
	while us.prompt == null and k < n:
		them.next_act = 99.0
		if each.is_valid():
			each.call(k)
		sim.tick()
		k += 1
	return k


## Drawn down the list onto him; he walks up to meet it. The old route ran to
## where he had been — past him — and only then turned round.
func _test_he_comes_to_meet_you() -> void:
	var t := _duel(61000, Vector2(150, 100), Vector2(150, 470))
	var sim: MeleeSim = t[0]
	var us = t[1]
	var them = t[2]
	var path: Array[Vector2] = [Vector2(150, 300), Vector2(150, 470)]
	sim.give_order(us.idx, path, them.idx)
	## He comes 220 up the list toward us, the way an enemy does.
	them.pos = Vector2(150, 250)
	them.planted_at = them.pos
	## In an array: a lambda takes a local by value.
	var deepest := [0.0]
	var k := _run(sim, us, them, 2000, func(_k): deepest[0] = maxf(deepest[0], us.pos.y))
	_ok(us.prompt != null, "sent at a man who comes to meet him, his options open", "after %.1f s" % (k * Tuning.TICK))
	_ok(deepest[0] < them.pos.y, "and he never ran past him", "deepest %.0f, enemy at %.0f" % [deepest[0], them.pos.y])
	_ok(us.pos.distance_to(them.pos) <= Tuning.PROMPT_RANGE + 0.5, "he opened at the man, not at the old end of the line",
		"%.0f from him" % us.pos.distance_to(them.pos))


## The enemy drifts sideways while ours is on his way: the end of the line goes
## with him, so ours is closing on him the whole way, not on empty ground.
func _test_he_steps_aside() -> void:
	var t := _duel(61001, Vector2(150, 100), Vector2(150, 420))
	var sim: MeleeSim = t[0]
	var us = t[1]
	var them = t[2]
	var path: Array[Vector2] = [Vector2(150, 260), Vector2(150, 420)]
	sim.give_order(us.idx, path, them.idx)
	var drift := func(_k: int) -> void:
		them.pos.x = minf(260.0, them.pos.x + 1.2)
		them.planted_at = them.pos
	var k := _run(sim, us, them, 2000, drift)
	_ok(us.prompt != null and us.prompt.target == them.idx, "he follows a man who steps aside and gets to him",
		"after %.1f s, enemy at x %.0f, ours at x %.0f" % [k * Tuning.TICK, them.pos.x, us.pos.x])
	## The route as drawn now ends where the man is, not where he was.
	var t2 := _duel(61002, Vector2(150, 100), Vector2(150, 420))
	var sim2: MeleeSim = t2[0]
	var us2 = t2[1]
	var them2 = t2[2]
	sim2.give_order(us2.idx, [Vector2(150, 260), Vector2(150, 420)] as Array[Vector2], them2.idx)
	them2.pos = Vector2(240, 420)
	var end: Vector2 = sim2.route_point(us2, us2.order.path.size() - 1)
	var mid: Vector2 = sim2.route_point(us2, 0)
	_ok(end.distance_to(them2.pos) < 1.0, "the end of the line sits on him", "end %s, him %s" % [end, them2.pos])
	_ok(mid.x > 150.0 and mid.x < 240.0, "and the bend before it moves part of the way", "bend %s" % mid)


## Out wide and in from the side: the bend is off to the side of him, so it is
## walked, not cut.
func _test_a_flank_is_still_walked() -> void:
	var t := _duel(61003, Vector2(150, 100), Vector2(150, 400))
	var sim: MeleeSim = t[0]
	var us = t[1]
	var them = t[2]
	var path: Array[Vector2] = [Vector2(40, 250), Vector2(40, 400), Vector2(150, 400)]
	sim.give_order(us.idx, path, them.idx)
	var widest := [150.0]
	_run(sim, us, them, 3000, func(_k): widest[0] = minf(widest[0], us.pos.x))
	_ok(widest[0] < 60.0, "a flank drawn wide is still run wide", "widest x %.0f (drawn to 40)" % widest[0])
	_ok(us.prompt != null, "and he gets to his man at the end of it", "")


## No enemy at the end: nothing bends.
func _test_a_plain_route_is_untouched() -> void:
	var t := _duel(61004, Vector2(150, 100), Vector2(150, 470))
	var sim: MeleeSim = t[0]
	var us = t[1]
	var them = t[2]
	sim.give_order(us.idx, [Vector2(100, 200), Vector2(200, 300)] as Array[Vector2], -1)
	them.pos = Vector2(250, 300)
	_ok(sim.route_point(us, 1) == Vector2(200, 300), "a route to open ground does not move", str(sim.route_point(us, 1)))
