extends SceneTree
## The feel layer — the three rules, and every effect's clock.
##
##   godot --headless --path . --script res://tests/test_juice.gd
##
## THIS FILE IS WHY THE LOGIC IS PURE. Juice is a static holder over static
## state with one function that takes a delta, so every timing in it can be
## hand-cranked and measured. The alternative — an effect that only exists once
## a node is in a tree — is an effect nobody can check, and the whole history of
## this codebase says that an unmeasured thing drifts.
##
## What is NOT checked here is whether it looks good. Nothing can check that.
## What is checked is that the numbers the brief committed to are the numbers
## the code does: 400ms of rise, 200ms of hold, two frames of flash, eight steps
## of wipe, two events and never three.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

const FRAME := 1.0 / 60.0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the feel layer ===\n")
	_test_the_ladder_is_a_ladder()
	_test_everything_lands_on_whole_pixels()
	_test_the_budget_holds()
	_test_a_knockout_cannot_be_swallowed()
	_test_the_hit_pause_ends()
	_test_the_flash_is_two_frames()
	_test_the_shake_decays_to_nothing()
	_test_a_popup_rises_holds_and_goes()
	_test_one_popup_at_a_time_per_source()
	_test_the_purse_is_watched_not_announced()
	_test_the_typer()
	_test_the_wipe_changes_the_scene_once()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE FEEL HOLDS (%d checks)\n" % checks)
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


## Run the clock forward, in real frames, the way the node does.
func _run(seconds: float) -> void:
	var n := int(round(seconds / FRAME))
	for i in n:
		Juice.tick(FRAME)


# ------------------------------------------------------------------ the rules
## THE FRAME LADDER. Six steps means six values and not six hundred — if this
## ever returns something between them, every effect in the file has quietly
## become smooth and the game has quietly stopped being 8-bit.
func _test_the_ladder_is_a_ladder() -> void:
	var seen := {}
	for i in 101:
		seen[Juice.ladder(float(i) / 100.0, Juice.POP_STEPS)] = true
	_ok(seen.size() <= Juice.POP_STEPS + 1, "the ladder has %d rungs" % Juice.POP_STEPS,
		"%d distinct values over a hundred samples" % seen.size())
	_ok(Juice.ladder(0.0, 6) == 0.0 and Juice.ladder(1.0, 6) == 1.0,
		"and it starts at nothing and reaches the top", "0 -> 0, 1 -> 1")
	_ok(Juice.ladder(1.5, 6) == 1.0 and Juice.ladder(-3.0, 6) == 0.0,
		"and it clamps", "out-of-range progress cannot overshoot")


## THE PIXEL SNAP. Not "usually" whole pixels — a single fractional position in
## a scene makes the whole scene look soft.
func _test_everything_lands_on_whole_pixels() -> void:
	Juice.reset()
	var bad := 0
	var p := Juice.snap(Vector2(12.4, -7.6))
	_ok(p == Vector2(12.0, -8.0), "snap rounds", "12.4,-7.6 -> %s" % p)
	## The shake is the machine for generating fractional positions, so it is
	## the one worth sampling rather than reasoning about.
	Juice.event("t", Juice.Rank.HUGE, {"trauma": 1.0})
	for i in 120:
		var o := Juice.shake_offset()
		if o.x != floorf(o.x) or o.y != floorf(o.y):
			bad += 1
		Juice.tick(FRAME)
	_ok(bad == 0, "and the shake never leaves it", "%d fractional offsets in 120 frames" % bad)
	## A popup rises on the ladder, so its drawn position must be whole too.
	Juice.reset()
	Juice.pop("s", "+2", Vector2(100.0, 100.0), Color.WHITE)
	bad = 0
	for i in 40:
		for d in Juice.popups():
			var at: Vector2 = d["at"]
			if at.x != floorf(at.x) or at.y != floorf(at.y):
				bad += 1
		Juice.tick(FRAME)
	_ok(bad == 0, "and neither does a rising number", "%d fractional positions" % bad)


## THE BUDGET. Two at once, never three.
func _test_the_budget_holds() -> void:
	Juice.reset()
	var a := Juice.event("a", Juice.Rank.HIT, {"hold": 1.0})
	var b := Juice.event("b", Juice.Rank.HIT, {"hold": 1.0})
	var c := Juice.event("c", Juice.Rank.HIT, {"hold": 1.0})
	_ok(a and b and not c, "the third event of equal rank is refused",
		"a=%s b=%s c=%s" % [a, b, c])
	_ok(Juice.live_events() == Juice.BUDGET, "and only two are live",
		"%d live" % Juice.live_events())
	_ok(Juice.dropped() == 1, "and the refusal is counted",
		"%d dropped" % Juice.dropped())
	## Re-announcing something already running is not a third thing.
	var again := Juice.event("a", Juice.Rank.HIT, {"hold": 1.0})
	_ok(again and Juice.live_events() == 2, "re-firing a live event is free",
		"still %d live" % Juice.live_events())
	_run(1.2)
	_ok(Juice.live_events() == 0, "and they clear on their own",
		"%d live after the hold" % Juice.live_events())


## THE ONE THE CEILING MUST NOT BREAK. A ceiling that counted blindly would
## swallow the biggest moment in the game because two taps happened to be in
## flight, and the bug would be invisible — nothing errors, the knockout is just
## quietly ordinary.
func _test_a_knockout_cannot_be_swallowed() -> void:
	Juice.reset()
	Juice.event("tap1", Juice.Rank.TAP, {"hold": 1.0})
	Juice.event("tap2", Juice.Rank.TAP, {"hold": 1.0})
	var ko := Juice.event("ko", Juice.Rank.HUGE,
		{"freeze": Juice.FREEZE_KO, "trauma": 0.9, "flash": Color.WHITE, "hold": 1.0})
	_ok(ko, "a knockout evicts a tap", "allowed with the ceiling already full")
	_ok(Juice.live_events() == Juice.BUDGET, "and the ceiling still holds",
		"%d live" % Juice.live_events())
	_ok(Juice.frozen() and Juice.flashing() and Juice.trauma() > 0.5,
		"and it applied all three of its effects",
		"one event, three effects — which is the whole point of counting events")
	## The reverse must NOT happen.
	var tap := Juice.event("tap3", Juice.Rank.TAP, {"hold": 1.0})
	_ok(not tap, "and a tap cannot evict a knockout", "refused, as it must be")


func _test_the_hit_pause_ends() -> void:
	Juice.reset()
	Juice.down()
	_ok(Juice.frozen(), "an ordinary down freezes the sim", "%.0fms" % (Juice.FREEZE_HIT * 1000.0))
	_run(Juice.FREEZE_HIT * 0.5)
	_ok(Juice.frozen(), "and is still frozen half way through", "as it should be")
	_run(Juice.FREEZE_HIT)
	_ok(not Juice.frozen(), "and thaws", "a freeze that never ended would hang the bout")
	## THE ONE THAT WOULD HANG IT: the tick must not be gated by the freeze, or
	## the freeze can never count itself down. Proved by freezing and then only
	## ticking — if the tick were gated this would still be frozen.
	Juice.reset()
	Juice.down(false, true)
	var frames := 0
	while Juice.frozen() and frames < 600:
		Juice.tick(FRAME)
		frames += 1
	_ok(frames < 600, "and a knockout's freeze thaws too",
		"%d frames, not the 600-frame guard" % frames)


func _test_the_flash_is_two_frames() -> void:
	Juice.reset()
	Juice.fanfare()
	var lit := 0
	for i in 10:
		if Juice.flashing():
			lit += 1
		Juice.tick(FRAME)
	_ok(lit == Juice.FLASH_FRAMES, "the flash is exactly %d frames" % Juice.FLASH_FRAMES,
		"lit on %d of ten" % lit)
	notes.append("%d frames is %.0fms at 60fps — under conscious perception, felt anyway"
		% [Juice.FLASH_FRAMES, Juice.FLASH_FRAMES / 60.0 * 1000.0])


func _test_the_shake_decays_to_nothing() -> void:
	Juice.reset()
	Juice.event("big", Juice.Rank.HUGE, {"trauma": 1.0})
	var peak := Juice.shake_offset().length()
	_ok(peak <= Juice.SHAKE_MAX + 0.001, "the shake is capped at %dpx" % Juice.SHAKE_MAX,
		"peak %.1fpx" % peak)
	_run(2.0)
	_ok(Juice.shake_offset() == Vector2.ZERO, "and it returns to dead still",
		"a screen that never settles is a screen that looks broken")
	## SQUARED TRAUMA is what makes a small hit subtle without a second code
	## path, so a half-strength hit must be far less than half the shake.
	Juice.reset()
	Juice.event("small", Juice.Rank.HIT, {"trauma": 0.5})
	var small := Juice.shake_offset().length()
	Juice.reset()
	Juice.event("large", Juice.Rank.HUGE, {"trauma": 1.0})
	var large := Juice.shake_offset().length()
	_ok(small < large * 0.5, "and half the trauma is much less than half the shake",
		"%.2fpx against %.2fpx" % [small, large])


func _test_a_popup_rises_holds_and_goes() -> void:
	Juice.reset()
	Juice.pop("credits", "+2 CC", Vector2(400.0, 300.0), Color.WHITE)
	_ok(Juice.live_popups() == 1, "a popup appears", "one live")
	var start: Vector2 = Juice.popups()[0]["at"]
	## One frame PAST the rise window, not exactly on it. The top rung of the
	## ladder is reached when progress passes 1.0, and twenty-four frames of
	## 1/60 add up to 0.39999 — which is the ladder behaving correctly and the
	## check looking a frame early. It found this on its first run.
	_run(Juice.POP_RISE_S + FRAME)
	var risen: Vector2 = Juice.popups()[0]["at"]
	_ok(absf(start.y - risen.y - Juice.POP_RISE) < 0.5,
		"and rises %dpx" % Juice.POP_RISE, "%.0fpx over %.0fms"
		% [start.y - risen.y, Juice.POP_RISE_S * 1000.0])
	_run(Juice.POP_HOLD_S * 0.5)
	_ok(Juice.live_popups() == 1 and Juice.popups()[0]["at"] == risen,
		"then holds still", "it is readable because it stops")
	_run(Juice.POP_HOLD_S)
	_ok(Juice.live_popups() == 0, "then it is gone",
		"total life %.0fms" % ((Juice.POP_RISE_S + Juice.POP_HOLD_S) * 1000.0))


## FIVE SIMULTANEOUS POPUPS IS CONFETTI, and confetti reads as a mobile F2P
## game, which this is not.
func _test_one_popup_at_a_time_per_source() -> void:
	Juice.reset()
	for i in 6:
		Juice.pop("credits", "+%d" % i, Vector2(400.0, 300.0), Color.WHITE)
	_ok(Juice.live_popups() == 1, "six from one source draw one",
		"%d live" % Juice.live_popups())
	## The queued ones are not lost — they take their turn, up to the cap.
	var seen := 1
	for i in 12:
		_run(Juice.POP_RISE_S + Juice.POP_HOLD_S)
		if Juice.live_popups() > 0:
			seen += 1
	_ok(seen > 1 and seen <= Juice.POP_QUEUE + 1, "and the rest queue, up to %d"
		% Juice.POP_QUEUE, "%d shown of six offered" % seen)
	## Two different sources are two different things and both may show.
	Juice.reset()
	Juice.pop("credits", "+2", Vector2.ZERO, Color.WHITE)
	Juice.pop("down3", "DOWN", Vector2.ZERO, Color.WHITE)
	_ok(Juice.live_popups() == 2, "but two sources are two popups",
		"the limit is per source, not global")


## LOADING A SAVE IS NOT EARNING.
func _test_the_purse_is_watched_not_announced() -> void:
	Juice.reset()
	Juice.purse(120, Vector2.ZERO)
	_ok(Juice.live_popups() == 0, "the first sighting of the purse is silent",
		"opening the game must not announce your balance as a gain")
	Juice.purse(126, Vector2.ZERO)
	_ok(Juice.live_popups() == 1, "a change pops", "120 -> 126")
	_run(1.0)
	Juice.purse(126, Vector2.ZERO)
	_ok(Juice.live_popups() == 0, "an unchanged purse does nothing",
		"six screens draw this every frame — it must be free")
	Juice.forget_purse()
	Juice.purse(4000, Vector2.ZERO)
	_ok(Juice.live_popups() == 0, "and a loaded save is silent",
		"the balance jumped because a different career is on screen")


func _test_the_typer() -> void:
	Juice.reset()
	var full := "The quartermaster wants a word."
	Juice.type_start("d", full)
	_ok(Juice.typed("d") == "", "it starts empty", "nothing has arrived yet")
	_ok(not Juice.type_done("d"), "and knows it is not finished", "")
	_run(float(full.length() * Juice.TYPE_FRAMES) * FRAME)
	_ok(Juice.typed("d") == full, "and arrives in full",
		"%d characters at one per %d frames" % [full.length(), Juice.TYPE_FRAMES])
	_ok(Juice.type_done("d"), "and knows it is finished", "")
	## A TAP SKIPS TO THE END, always. A player who reads faster than the
	## machine prints must never be made to wait.
	Juice.reset()
	Juice.type_start("e", full)
	_run(0.1)
	Juice.type_skip("e")
	_ok(Juice.typed("e") == full and Juice.type_done("e"), "and a tap skips it",
		"straight to the end")
	_ok(Juice.typed("nobody") == "" and Juice.type_done("nobody"),
		"and an unknown id is finished and empty",
		"a screen asking about a card it never started must not stall")


## A CUT IN THE MIDDLE OF A WIPE IS A FLICKER, and a wipe that finishes before
## the scene changes is a load screen wearing a costume. So the change happens
## at the midpoint, behind full cover, exactly once.
func _test_the_wipe_changes_the_scene_once() -> void:
	Juice.reset()
	Juice.set_enabled(false)
	Juice.go("res://scenes/Season.tscn")
	_ok(Juice.take_pending_scene() == "res://scenes/Season.tscn",
		"with the juice off, a screen change is a hard cut",
		"no wipe, no delay, and the game still works")
	Juice.set_enabled(true)

	Juice.reset()
	Juice._wipe = {"t": 0.0, "path": "res://scenes/Melee.tscn", "taken": false}
	_ok(Juice.wipe_cover() == 0.0, "the wipe starts clear", "nothing covered")
	var taken := 0
	var covered_when_taken := -1.0
	for i in 60:
		Juice.tick(FRAME)
		if Juice.take_pending_scene() != "":
			taken += 1
			covered_when_taken = Juice.wipe_cover()
	_ok(taken == 1, "and changes the scene exactly once", "%d times" % taken)
	_ok(covered_when_taken >= 0.99, "and does it behind full cover",
		"%.0f%% covered at the change" % (covered_when_taken * 100.0))
	_ok(not Juice.wiping(), "and clears itself",
		"%.0fms end to end" % (Juice.WIPE_S * 2.0 * 1000.0))
	notes.append("every transition is %.0fms — the brief's ceiling is 200ms each way"
		% (Juice.WIPE_S * 1000.0))
