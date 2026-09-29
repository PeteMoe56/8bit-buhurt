extends SceneTree
## THE CLINCH MENU PLAYS BY THE CLINCH'S CLOCK (29 Sep 2026).
##
##   godot --headless --path . --script res://tests/test_clinch.gd
##
## A fresh-eyes audit found that tapping TAKEDOWN in the clinch menu won 100%
## of bouts: a player's answer landed the instant it was tapped, a missed
## takedown leaves a man still tied up, so every tap was another roll while the
## AI rolled once every ACT_CLINCH seconds. The rules this holds:
##
##   a player's clinch actions come no faster than the AI's (ACT_CLINCH)
##   the menu refuses an answer until its man is ready, and takes it at once when he is
##   an open menu cannot time out into an action the clock has not allowed
##   the highlighted suggestion is what the AI would do now, not when it opened
##
## The statistical side — spam no longer beats hands-off — is measured by
## `bash tools/bb.sh probe fightskill 40 busy`.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the clinch clock ===\n")
	_test_spam_is_paced()
	_test_ready_gate()
	print("")
	if failures.is_empty():
		print("THE CLINCH HOLDS (%d checks)\n" % checks)
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


func _sim(seed_: int) -> MeleeSim:
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), seed_, 1.0)
	sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
	return sim


## Spam the menu every tick for whole bouts and count the actions that land
## against the seconds each man spent tied up.
func _test_spam_is_paced() -> void:
	var landed := 0
	var clinch_s := 0.0
	var clinches := 0
	for b in 6:
		var sim := _sim(9100 + b)
		var k := 0
		while not sim.is_over() and k < 60000:
			k += 1
			for m in sim.men:
				if m.team != 0 or m.state != MeleeSim.State.GRAPPLED:
					continue
				clinch_s += Tuning.TICK
				if m.prompt == null:
					sim.request_prompt(m.idx)
				if m.prompt != null and m.prompt.menu == Tuning.Menu.GRAPPLED \
						and sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN):
					landed += 1
			sim.tick()
	## One action at once, then one per ACT_CLINCH[0] at the very fastest; a
	## clinch is counted per man, so this bounds it from above generously.
	var ceiling := clinch_s / float(Tuning.ACT_CLINCH[0]) + 60.0
	_ok(clinch_s > 30.0 and landed <= ceiling,
		"tapping the clinch menu every tick acts no faster than the clinch clock",
		"%d takedowns landed in %.0f man-seconds of clinch (clock allows at most ~%.0f)"
			% [landed, clinch_s, ceiling])


## One clinched man, driven by hand: refused while not ready, taken at once
## when ready, and the menu does not decide for him before the clock allows.
func _test_ready_gate() -> void:
	var found := false
	for b in 20:
		var sim := _sim(9200 + b)
		var k := 0
		while not sim.is_over() and k < 40000:
			k += 1
			sim.tick()
			for m in sim.men:
				if m.team != 0 or m.state != MeleeSim.State.GRAPPLED or m.prompt != null:
					continue
				if m.next_act < 0.5:
					continue
				## Not ready: open his menu and try to answer.
				sim.request_prompt(m.idx)
				var refused := not sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN)
				var answered_before := sim.prompts_answered
				## Hold the menu open, unanswered, until he is ready. It must still
				## be open — its clock does not run while he is not ready.
				var still_open := true
				var guard := 0
				while m.next_act > 0.0 and guard < 400 and m.state == MeleeSim.State.GRAPPLED:
					guard += 1
					sim.tick()
					if m.prompt == null:
						still_open = false
						break
				if m.state != MeleeSim.State.GRAPPLED or not still_open:
					continue
				var fresh := m.prompt.choice == sim._ai_choose(m, sim.men[m.prompt.target], Tuning.Menu.GRAPPLED)
				var took := sim.answer_prompt(m.idx, Tuning.Act.HOLD)
				var landed_now := m.prompt == null and sim.prompts_answered == answered_before + 1
				_ok(refused and still_open and fresh and took and landed_now and m.next_act > 0.0,
					"the clinch menu waits for its man, then acts at once",
					"refused while not ready: %s; open until ready: %s; suggestion current: %s; taken when ready: %s; landed at once and clock restarted: %s"
						% [refused, still_open, fresh, took, landed_now and m.next_act > 0.0])
				found = true
				break
			if found:
				break
		if found:
			return
	_ok(false, "the clinch menu waits for its man, then acts at once", "no clinch found to drive")
