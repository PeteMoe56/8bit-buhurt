extends SceneTree
## PLAN, READY, 3-2-1, FIGHT (Pete, 4 Oct 2026).
##
##   godot --headless --fixed-fps 60 --path . --script res://tests/test_planning.gd
##
## The line is set and frozen until READY: a route drawn now is an order given
## before the whistle. READY starts a three-second count, and the sim does not
## move until it is out. Between rounds there is no waiting for READY — ten
## seconds and it goes by itself.

var scene: Node
var n := 0
var stage := 0
var failures: Array[String] = []
var checks := 0
var mark := 0.0
var t := 0.0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the planning stage ===\n")
	seed(20260914)
	Settings.tips_enabled = false
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child.call_deferred(scene)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


## SECONDS, NOT FRAMES: the suite runs headless with no fixed frame rate, and
## the planning clock runs on the frame's own delta.
func _process(_d: float) -> bool:
	n += 1
	t += _d
	if n < 10:
		return false
	if bool(scene.get("paused")):
		scene.call("_set_paused", false)
	var sim: MeleeSim = scene.get("sim")
	match stage:
		0:
			scene.call("_show_strategy_panel")
			scene.call("_apply_chosen")
			_ok(bool(scene.get("planning")) and float(scene.get("plan_left")) < 0.0,
				"FIGHT puts the first round into planning, with no clock",
				"planning %s, clock %.1f" % [scene.get("planning"), float(scene.get("plan_left"))])
			var rb: Button = scene.get("ready_button")
			scene.call("_sync_controls")
			_ok(rb != null and rb.visible, "and READY is up", "visible %s" % (rb.visible if rb != null else false))
			## A route drawn now is an order given before the whistle.
			var mine := -1
			for m in sim.men:
				if m.team == 0:
					mine = m.idx
					break
			var ok := sim.give_order(mine, [sim.men[mine].pos + Vector2(0, 60)] as Array[Vector2])
			_ok(ok and sim.men[mine].under_orders(), "a route drawn while planning is taken", "order %s" % ok)
			mark = t
			stage = 1
		1:
			if t - mark < 2.0:
				return false
			_ok(sim.round_t == 0.0, "two seconds of planning and the sim has not moved", "round_t %.2f" % sim.round_t)
			scene.call("_ready_up")
			_ok(not bool(scene.get("planning")) and float(scene.get("count_t")) > 2.9,
				"READY starts the count from three", "count %.2f" % float(scene.get("count_t")))
			mark = t
			stage = 2
		2:
			if t - mark < 1.5:
				return false
			_ok(sim.round_t == 0.0, "and the sim waits out the count", "round_t %.2f at %.1f s" % [sim.round_t, t - mark])
			mark = t
			stage = 3
		3:
			if t - mark < 2.0:
				return false
			_ok(sim.round_t > 0.0, "then the round runs", "round_t %.2f" % sim.round_t)
			## BETWEEN ROUNDS: ten seconds and it goes by itself.
			sim.round_no = 2
			scene.call("_apply_chosen")
			_ok(bool(scene.get("planning")) and absf(float(scene.get("plan_left")) - 10.0) < 0.01,
				"between rounds the plan has ten seconds on it", "clock %.1f" % float(scene.get("plan_left")))
			mark = t
			stage = 4
		4:
			if t - mark < 10.4:
				return false
			_ok(not bool(scene.get("planning")), "and after ten it counts in by itself",
				"planning %s, count %.2f" % [scene.get("planning"), float(scene.get("count_t"))])
			print("")
			if failures.is_empty():
				print("THE PLANNING HOLDS (%d checks)\n" % checks)
				quit(0)
			else:
				for f in failures:
					print("FAIL: " + f)
				print("\n%d FAILED\n" % failures.size())
				quit(1)
			return true
	return false
