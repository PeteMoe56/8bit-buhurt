extends SceneTree
## THE CORNER — every fight choice in one quarter-wheel under the thumb.
##
##   godot --headless --path . --script res://tests/test_corner.gd
##
## Pete picked option E on 2 Oct 2026, for the wheel and the bar both, with a
## left/right hand setting. A side that answers the wrong act is a fight lost to
## a thumb, and a mirror that only mirrors the drawing is worse.

var failures: Array[String] = []
var checks: int = 0
var n := 0
var scene: Node


func _initialize() -> void:
	SaveGame.set_namespace("corner")
	Settings.load_once()
	Settings.fight_controls = "corner"
	Settings.fight_hand = "right"
	print("\n=== 8-Bit Buhurt — the corner ===\n")
	_test_the_words_fit_their_sides()
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child.call_deferred(scene)


func _process(_d: float) -> bool:
	n += 1
	if scene != null and bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 6:
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
		_wheel_checks()
		_bar_checks()
		_clinch_checks()
		_setting_checks()
		return _finish()
	return false


## The middle of side `i`, in the scene's frame.
func _side(i: int) -> Vector2:
	var s: Vector2 = FightCorner.span(i)
	return FightCorner._pt(FightCorner.point(scene), (FightCorner.RI + FightCorner.RO) * 0.5, (s.x + s.y) * 0.5)


func _hub() -> Vector2:
	var c: Vector2 = FightCorner.point(scene)
	return c + Vector2(-50.0 if FightCorner.right() else 50.0, -40.0)


func _wheel_checks() -> void:
	var wm: int = int(scene.get("wheel_man"))
	_ok(wm != -1, "contact opens the wheel, in the corner", "wheel_man %d" % wm)
	if wm == -1:
		return
	var m = scene.sim.men[wm]
	var opts: Array = scene.call("_wheel_opts", m)
	for hand in ["right", "left"]:
		Settings.fight_hand = hand
		var wrong: Array[String] = []
		for i in 3:
			var got: int = scene.call("_wheel_option_at", m, _side(i))
			if got != int(opts[i]):
				wrong.append("%s side answered %d" % [Tuning.act_name(opts[i]), got])
		if int(scene.call("_wheel_option_at", m, _hub())) != -1:
			wrong.append("the hub is not Cancel")
		if int(scene.call("_wheel_option_at", m, Vector2(480, 240))) != -2:
			wrong.append("the middle of the list answered")
		_ok(wrong.is_empty(), "%s hand: each side its act, the hub Cancel, the list nothing" % hand,
			"3 sides, hub, list" if wrong.is_empty() else ", ".join(wrong))
	## The two hands are mirror images: the same side, the other corner.
	Settings.fight_hand = "right"
	var r0: Vector2 = _side(0)
	Settings.fight_hand = "left"
	var l0: Vector2 = _side(0)
	var w: float = scene.SCREEN.x
	_ok(absf((r0.x - w * 0.5) + (l0.x - w * 0.5)) < 1.0 and absf(r0.y - l0.y) < 1.0,
		"the left hand mirrors the right", "%s vs %s" % [str(r0), str(l0)])
	Settings.fight_hand = "right"
	## Thick enough for a thumb, and every side on the screen.
	_ok(FightCorner.RO - FightCorner.RI >= 88.0, "the sides are two thumbs thick",
		"%d px" % int(FightCorner.RO - FightCorner.RI))
	## A tap on a side commits it and closes the wheel.
	scene.call("_press", _side(2))
	var chose: int = m.prompt.choice if m.prompt != null else -9
	_ok(m.prompt != null and m.prompt.committed and chose == int(opts[2]) and int(scene.get("wheel_man")) != wm,
		"a tap on the top side commits its act and closes the wheel",
		"chose %s" % (Tuning.act_name(chose) if chose >= 0 else str(chose)))


func _bar_checks() -> void:
	var sim: MeleeSim = scene.sim
	## Two men of ours meeting enemies on their own: the fight keeps running.
	for i in [0, 1]:
		var us = sim.men[i]
		us.order = null
		sim._close_prompt(us)
		sim._open_prompt(us, Tuning.Menu.APPROACH, sim.men[5 + i].idx)
	var first: int = FightCorner.bar_man(scene)
	_ok(first == 1, "the corner shows the newest question", "shows man %d" % first)
	scene.call("_press", _hub())
	var second: int = FightCorner.bar_man(scene)
	_ok(second == 0, "a tap on the hub moves to the other man", "shows man %d" % second)
	var m = sim.men[second]
	var acts: Array = Tuning.acts_for(m.prompt.menu)
	scene.call("_press", _side(0))
	_ok(m.prompt != null and m.prompt.by_player and m.prompt.choice == int(acts[0]),
		"a tap on a side overrules his pick", "chose %s" % Tuning.act_name(m.prompt.choice))
	_ok(FightCorner.bar_man(scene) == 1, "an answered man leaves the corner to the next",
		"shows man %d" % FightCorner.bar_man(scene))
	## A tap off the corner is still a tap on the fight.
	_ok(not FightCorner.press_bar(scene, Vector2(300, 200)), "a tap on the list is not the corner's", "300,200")
	for i in [0, 1]:
		sim._close_prompt(sim.men[i])


func _clinch_checks() -> void:
	var sim: MeleeSim = scene.sim
	var us = sim.men[3]
	var them = sim.men[8]
	them.pos = us.pos + Vector2(0, 20)
	sim._enter_grapple(us, them)
	us.next_act = 1.5
	sim._open_prompt(us, Tuning.Menu.GRAPPLED, them.idx)
	_ok(FightCorner.bar_man(scene) == 3, "a clinched man's question comes to the corner", "man %d" % FightCorner.bar_man(scene))
	scene.call("_press", _side(1))
	_ok(us.prompt != null and not us.prompt.by_player, "while he gets ready, a tap is refused",
		"by_player %s" % str(us.prompt.by_player if us.prompt != null else null))
	## Ready, the answer lands at once (`_clinch_act`) and the question closes.
	us.next_act = 0.0
	var before: int = sim.prompts_answered
	scene.call("_press", _side(1))
	_ok(sim.prompts_answered == before + 1 and us.prompt == null,
		"ready, a tap on a side acts at once", "answered %d -> %d" % [before, sim.prompts_answered])


func _setting_checks() -> void:
	var keep := Settings.path
	Settings.path = "user://corner_test_settings.cfg"
	Settings.set_fight_controls("classic")
	Settings.set_fight_hand("left")
	Settings.fight_controls = "corner"
	Settings.fight_hand = "right"
	Settings._loaded = false
	Settings.load_once()
	_ok(Settings.fight_controls == "classic" and Settings.fight_hand == "left",
		"both fight settings survive a restart", "%s, %s" % [Settings.fight_controls, Settings.fight_hand])
	Settings.set_fight_controls("sideways")
	_ok(Settings.fight_controls == "classic", "a value that is not a choice is refused", Settings.fight_controls)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = keep
	Settings.fight_controls = "corner"
	Settings.fight_hand = "right"


func _finish() -> bool:
	print("")
	if failures.is_empty():
		print("THE CORNER HOLDS (%d checks)\n" % checks)
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


## EVERY SIDE'S WORDS FIT THEIR ARC, in every language, at or above the floor
## sizes (Pete, 3 Oct 2026: bigger, but no clipping through and no wrapping).
func _test_the_words_fit_their_sides() -> void:
	var f: Font = UiKit.body()
	var effects := ["puts him down", "balance -%d%%", "takedown %d%%", "frees your man", "keeps him tied",
		"breaks free", "fall %d%%", "he holds firm"]
	var bad: Array[String] = []
	var was := TranslationServer.get_locale()
	for loc in ["en", "es", "fr", "de", "it", "pt_BR", "pl", "ru", "ja"]:
		TranslationServer.set_locale(loc)
		for a in Tuning.ACT_NAME.size():
			var s: String = Tuning.act_name(a)
			if FightCorner.arc_px(f, s, FightCorner.NAME_R, FightCorner.NAME_PX) < FightCorner.NAME_MIN:
				bad.append("%s %s" % [loc, s])
		var cs := UiKit.t("%d%% chance") % 100
		if FightCorner.arc_px(f, cs, FightCorner.CHANCE_R, FightCorner.CHANCE_PX) < FightCorner.CHANCE_MIN:
			bad.append("%s %s" % [loc, cs])
		for e in effects:
			var s2: String = UiKit.t(e)
			if s2.contains("%d"):
				s2 = s2 % 100
			if FightCorner.arc_px(f, s2, FightCorner.EFFECT_R, FightCorner.EFFECT_PX) < FightCorner.EFFECT_MIN:
				bad.append("%s %s" % [loc, s2])
	TranslationServer.set_locale(was)
	_ok(bad.is_empty(), "the wheel's words fit their sides",
		"9 languages, name >= %d px, chance >= %d, effect >= %d; too long: %s" % [FightCorner.NAME_MIN,
			FightCorner.CHANCE_MIN, FightCorner.EFFECT_MIN, ", ".join(bad) if not bad.is_empty() else "none"])
