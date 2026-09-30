extends SceneTree
## THE GUARD TRIANGLE — the contact wheel's geometry and its answers.
##
##   godot --headless --path . --script res://tests/test_wheel.gd
##
## Pete picked wheel #11 on 29 Sep 2026: three thick sides hugging the man (up,
## right, left), Cancel in the open bottom quarter, a gold arc on the side under
## a dragging thumb. None of that had a test — the old boxes had none either —
## and a wheel whose sides answer the wrong act is a fight lost to a thumb.

var failures: Array[String] = []
var checks: int = 0
var n := 0
var scene: Node


func _initialize() -> void:
	SaveGame.set_namespace("wheel")
	print("\n=== 8-Bit Buhurt — the guard triangle ===\n")
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child.call_deferred(scene)


func _process(_d: float) -> bool:
	n += 1
	if scene != null and bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 6:
		## The same contact the wheel screenshot opens: our man onto a free enemy.
		scene.call("_clear_corner")
		scene.set("screen", 2)
		var sim: MeleeSim = scene.sim
		sim.phase = MeleeSim.Phase.LIVE
		var us = sim.men[2]
		var them = sim.men[7]
		them.pos = Vector2(Tuning.LIST_W * 0.5, Tuning.LIST_H * 0.45)
		them.state = MeleeSim.State.CLOSING
		them.target = us.idx
		us.pos = them.pos + Vector2(-26, 0)
		var path: Array[Vector2] = []
		sim.give_order(us.idx, path, them.idx)
		sim._open_prompt(us, Tuning.Menu.APPROACH, them.idx)
	if n == 10:
		_checks()
		return _finish()
	return false


func _checks() -> void:
	var wm: int = int(scene.get("wheel_man"))
	_ok(wm != -1, "contact opens the wheel", "wheel_man %d" % wm)
	if wm == -1:
		return
	var m = scene.sim.men[wm]
	var c: Vector2 = scene.call("_wheel_center", m)
	var opts: Array = scene.call("_wheel_opts", m)
	var mid: float = (scene.WHEEL_RI + scene.WHEEL_RO) * 0.5
	var wrong: Array[String] = []
	for i in 3:
		var at: Vector2 = c + scene._dir(scene.WHEEL_DIRS[i]) * mid
		var got: int = scene.call("_wheel_option_at", m, at)
		if got != int(opts[i]):
			wrong.append("%s side answered %d" % [Tuning.act_name(opts[i]), got])
		## Its words count too — a thumb aims at the label as often as the arc.
		var words: Vector2 = c + scene._dir(scene.WHEEL_DIRS[i]) * (scene.WHEEL_LABEL + 20.0)
		if int(scene.call("_wheel_option_at", m, words)) != int(opts[i]):
			wrong.append("%s words missed" % Tuning.act_name(opts[i]))
	_ok(wrong.is_empty(), "every side and its words answer their own act",
		"3 sides, 3 labels" if wrong.is_empty() else ", ".join(wrong))
	var cancel_r: Rect2 = scene.call("_wheel_cancel_rect", m)
	_ok(int(scene.call("_wheel_option_at", m, cancel_r.get_center())) == -1,
		"the chip in the bottom quarter is Cancel", str(cancel_r))
	_ok(int(scene.call("_wheel_option_at", m, c)) == -2,
		"a tap on the man answers nothing", "centre -> -2")
	_ok(int(scene.call("_wheel_option_at", m, c + Vector2(0, scene.WHEEL_RO * 0.6))) == -2,
		"the open bottom quarter answers only through its chip", "below the man, off the chip -> -2")
	## A drag answers by direction once it leaves the man's circle.
	var drag_ok := int(scene.call("_wheel_option_at", m, c + Vector2(-40, 0), true)) == int(opts[2]) \
		and int(scene.call("_wheel_option_at", m, c + Vector2(40, -4), true)) == int(opts[1]) \
		and int(scene.call("_wheel_option_at", m, c + Vector2(3, -40), true)) == int(opts[0]) \
		and int(scene.call("_wheel_option_at", m, c + Vector2(0, 40), true)) == -1 \
		and int(scene.call("_wheel_option_at", m, c + Vector2(10, 5), true)) == -2
	_ok(drag_ok, "a drag answers by direction past the man's circle", "left/right/up/down/inside")
	## The sides clear the man's own circle (26px) and are a thumb thick.
	_ok(scene.WHEEL_RI > 26.0 and scene.WHEEL_RO - scene.WHEEL_RI >= 44.0,
		"the sides clear the man and are a thumb thick",
		"inner %d, thickness %d" % [int(scene.WHEEL_RI), int(scene.WHEEL_RO - scene.WHEEL_RI)])
	## And the whole ring stays on the list.
	var lo: Vector2 = scene.LIST_ORIGIN
	var hi: Vector2 = lo + Vector2(Tuning.LIST_H, Tuning.LIST_W) * scene.LIST_SCALE
	var box := Rect2(c - Vector2(scene.WHEEL_RO, scene.WHEEL_RO), Vector2(scene.WHEEL_RO, scene.WHEEL_RO) * 2.0)
	_ok(Rect2(lo, hi - lo).encloses(box.merge(cancel_r)), "the wheel stays on the list",
		"%s inside %s" % [str(box.merge(cancel_r)), str(Rect2(lo, hi - lo))])
	## THE BULLRUSH READ (Pete, 30 Sep 2026): under half balance, a bullrush
	## gets +0.30 — the wheel's number shows it, because it is the sim's.
	var t = scene.sim.men[m.prompt.target]
	var keep: float = t.stability
	t.stability = 0.55
	var p_hi: float = float(scene.sim.contact_odds(m.idx, Tuning.Act.BULLRUSH, t.idx)["p"])
	t.stability = 0.45
	var p_lo: float = float(scene.sim.contact_odds(m.idx, Tuning.Act.BULLRUSH, t.idx)["p"])
	t.stability = keep
	_ok(p_lo - p_hi >= 0.20, "a bullrush on an unbalanced man jumps",
		"%d%% at 55%% balance, %d%% at 45%%" % [int(round(p_hi * 100.0)), int(round(p_lo * 100.0))])
	## A tap answers the prompt and closes the wheel.
	scene.call("_press", c + scene._dir(scene.WHEEL_DIRS[2]) * mid)
	var chose: int = m.prompt.choice if m.prompt != null else -9
	_ok(m.prompt != null and m.prompt.committed and chose == int(opts[2]) and int(scene.get("wheel_man")) != wm,
		"a tap on the left side commits its act and closes the wheel",
		"chose %s, wheel_man %d" % [Tuning.act_name(chose) if chose >= 0 else str(chose), int(scene.get("wheel_man"))])


func _finish() -> bool:
	print("")
	if failures.is_empty():
		print("THE GUARD TRIANGLE HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)
	return true


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])
