extends SceneTree
## THE FIGHT ON A PAD (Steam Deck, 4 Oct 2026).
##
##   xvfb-run godot --path . --script res://tests/test_pad_fight.gd
##
## The fight is played with a cursor on a pad: LB/RB put it on your men, A on a
## man and let go holds his ground, A held and steered draws a route, and with
## the wheel up A takes the lit side and B cancels. Each goes through the same
## press / extend / release the touch path uses, so this checks the pad reaches
## them — not the fight itself, which the rest of the suite holds.

var scene: Node
var n := 0
var failures: Array[String] = []
var checks := 0
var stage := 0
var sent := -1


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the fight on a pad ===\n")
	Settings.tips_enabled = false
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child.call_deferred(scene)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


func _btn(b: JoyButton, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = down
	scene._input(e)


func _process(_d: float) -> bool:
	n += 1
	if bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 4:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	if n >= 6:
		scene.set("tip", "")
	if n < 30:
		return false
	var sim: MeleeSim = scene.sim
	match stage:
		0:
			_ok(scene.pad_owns_input(), "the fight takes the pad while it runs", "screen %d" % int(scene.screen))
			## RB onto a man; A down and up on him: he holds his ground.
			scene._pad_jump(1)
			var idx: int = scene._fighter_at(scene.pad_cursor)
			_ok(idx != -1 and sim.men[idx].team == 0, "RB puts the cursor on one of your men", "man %d" % idx)
			_btn(JOY_BUTTON_A, true)
			_btn(JOY_BUTTON_A, false)
			_ok(idx != -1 and (sim.men[idx].planted or sim.men[idx].prompt != null),
				"a tap of A on him holds his ground", "planted %s" % str(sim.men[idx].planted if idx != -1 else false))
			## A held, steered onto the nearest enemy, let go: he is sent.
			scene._pad_jump(1)
			var me: int = scene._fighter_at(scene.pad_cursor)
			var best := -1
			var bd := INF
			for m in sim.men:
				if m.team == 1 and m.standing() and m.pos.distance_to(sim.men[me].pos) < bd:
					bd = m.pos.distance_to(sim.men[me].pos)
					best = m.idx
			_btn(JOY_BUTTON_A, true)
			var from: Vector2 = scene.pad_cursor
			var to: Vector2 = scene._to_screen(sim.men[best].pos)
			for k in 12:
				scene.pad_cursor = from.lerp(to, float(k + 1) / 12.0)
				scene._extend(scene.pad_cursor)
			_btn(JOY_BUTTON_A, false)
			sent = me
			_ok(sim.men[me].under_orders() and sim.men[me].order.target == best,
				"A held and steered onto an enemy sends him at that man",
				"orders %s, target %d (wanted %d)" % [sim.men[me].under_orders(),
					sim.men[me].order.target if sim.men[me].under_orders() else -1, best])
			stage = 1
		1:
			## THE WHEEL, opened on him now rather than waited for (the list is a
			## fight; he may be tied up before he gets there).
			var m = sim.men[sent]
			if not m.standing() or m.state == MeleeSim.State.GRAPPLED:
				_ok(true, "the wheel checks skipped: the man sent is tied up", "state %d" % m.state)
				stage = 2
				return false
			var tgt := -1
			for e in sim.men:
				if e.team == 1 and e.standing():
					tgt = e.idx
					break
			if not m.under_orders():
				sim.give_order(m.idx, [] as Array[Vector2], tgt)
			sim._open_prompt(m, Tuning.Menu.APPROACH, m.order.target)
			scene.wheel_man = scene._wheel_candidate()
			_ok(int(scene.wheel_man) == m.idx, "the wheel is up for him", "wheel_man %d" % int(scene.wheel_man))
			scene.wheel_hot = Tuning.Act.BULLRUSH
			_btn(JOY_BUTTON_A, true)
			_ok(m.prompt != null and m.prompt.by_player and m.prompt.choice == Tuning.Act.BULLRUSH,
				"A takes the lit side", "answered %s" % str(m.prompt != null and m.prompt.by_player))
			## And B: a second question, cancelled.
			sim._close_prompt(m)
			sim._open_prompt(m, Tuning.Menu.APPROACH, m.order.target)
			scene.wheel_man = scene._wheel_candidate()
			_btn(JOY_BUTTON_B, true)
			_ok(not m.under_orders(), "B cancels the send", "orders %s" % m.under_orders())
			stage = 2
		2:
			## A FIRST-TIME TIP lets go of the pad, so focus can land on its
			## "Got it" (audit, 4 Oct 2026: it froze the fight and A drew routes
			## under it, with no way to close it from the pad).
			scene.set("tip", "route")
			_ok(not scene.pad_owns_input(), "a tip up lets go of the pad for its Got it",
				"pad_owns_input %s" % scene.pad_owns_input())
			scene.set("tip", "")
			## START pauses; A carries on.
			_btn(JOY_BUTTON_START, true)
			var was := bool(scene.get("paused"))
			_btn(JOY_BUTTON_A, true)
			_ok(was and not bool(scene.get("paused")), "Start pauses and A carries on",
				"paused after Start %s, after A %s" % [was, scene.get("paused")])
			## Y skips the round when SKIP ROUND is up.
			var sb: Button = scene.get("skip_button")
			scene.call("_sync_controls")
			if sb != null and sb.visible:
				_btn(JOY_BUTTON_Y, true)
				_ok(bool(scene.get("skipping")) or sim.phase != MeleeSim.Phase.LIVE,
					"Y skips the round", "skipping %s" % scene.get("skipping"))
			else:
				_ok(true, "the Y check skipped: SKIP ROUND is not up", "visible %s" % (sb.visible if sb != null else false))
			stage = 3
		3:
			print("")
			if failures.is_empty():
				print("THE FIGHT ON A PAD HOLDS (%d checks)\n" % checks)
				quit(0)
			else:
				for f in failures:
					print("FAIL: " + f)
				print("\n%d FAILED\n" % failures.size())
				quit(1)
			return true
	return false
