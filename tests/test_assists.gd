extends SceneTree
## ASSISTS — the second-most work on a man who went down at somebody else's hands.
##
##   godot --headless --path . --script res://tests/test_assists.gd
##
## PETE, 13 SEP 2026: *"Assists can be 2nd most damage or effect on enemy."*
##
## The stat did not exist anywhere in the project — not in the sim, not on the
## card, not on a screen — while the corner spec had been asking for it since the
## playbook pass. This file is written first because an assist is the kind of
## number nobody believes: every sport has one, and in most of them it means "was
## nearby". The checks are about what stops it meaning that.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== Retro Buhurt — the assist ===\n")
	_test_the_ledger_records_who_did_the_work()
	_test_the_second_man_gets_it_and_the_first_does_not()
	_test_a_passing_shot_is_not_an_assist()
	_test_the_slate_is_wiped_when_he_goes_down()
	_test_a_bout_produces_some()
	print("")
	## `quit()` REQUESTS AN EXIT, IT DOES NOT RETURN. The first version fell
	## through the success branch into the failure print and the last `quit(1)`
	## won — so this file reported "THE ASSIST HOLDS (11 checks)" and then failed
	## the suite. Every other test file in this project uses if/else for exactly
	## this reason; writing it as an early exit was me not reading them.
	if failures.is_empty():
		print("THE ASSIST HOLDS (%d checks)\n" % checks)
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


func _sim() -> MeleeSim:
	return MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 90210)


## THE FUNNEL DOES BOTH JOBS. `_wear` subtracts stability and files who took it,
## and the reason it is one function is that a wear source which filed nothing
## would be damage the report cannot see. So the first check is that the two
## halves happen together, not that either happens.
func _test_the_ledger_records_who_did_the_work() -> void:
	var sim := _sim()
	var victim: MeleeSim.Man = sim.men[5]
	var attacker: MeleeSim.Man = sim.men[0]
	var before: float = victim.stability
	sim._wear(victim, attacker, 0.20)
	_ok(is_equal_approx(victim.stability, before - 0.20)
		and is_equal_approx(float(victim.wear.get(attacker.idx, 0.0)), 0.20),
		"wearing a man down subtracts and records in one call",
		"stability %.2f to %.2f, ledger holds %.2f" % [before, victim.stability,
			float(victim.wear.get(attacker.idx, 0.0))])
	## A MAN'S OWN SIDE NEVER APPEARS ON HIS LEDGER. The sim does not do this, and
	## a check that only holds while nothing calls it wrongly is the kind that
	## stops holding quietly.
	var mate: MeleeSim.Man = null
	for m in sim.men:
		if m.team == victim.team and m.idx != victim.idx:
			mate = m
			break
	sim._wear(victim, mate, 0.30)
	_ok(not victim.wear.has(mate.idx),
		"and a team-mate's contact is never on the ledger",
		"%d entries, none of them his own side" % victim.wear.size())


func _test_the_second_man_gets_it_and_the_first_does_not() -> void:
	var sim := _sim()
	var victim: MeleeSim.Man = sim.men[5]
	var thrower: MeleeSim.Man = sim.men[0]
	var helper: MeleeSim.Man = sim.men[1]
	sim._wear(victim, helper, 0.60)
	sim._wear(victim, thrower, 0.20)
	sim._put_down(victim, thrower)
	_ok(thrower.downs_caused == 1 and thrower.assists == 0,
		"the man who threw it gets the down and not an assist as well",
		"%d down, %d assists" % [thrower.downs_caused, thrower.assists])
	_ok(helper.assists == 1,
		"and the man who did the most work before it gets the assist",
		"he owned %.0f%% of the wear" % (0.60 / 0.80 * 100.0))
	## THE THROWER IS NOT REMOVED FROM THE TOTAL, so the helper's share is
	## measured against everything done to the victim. A share computed against
	## "everyone but the thrower" would credit the second man in a two-man
	## takedown no matter how little he did, which is the participation count.
	var s2 := _sim()
	var v2: MeleeSim.Man = s2.men[5]
	var big: MeleeSim.Man = s2.men[0]
	var tiny: MeleeSim.Man = s2.men[1]
	s2._wear(v2, big, 0.95)
	s2._wear(v2, tiny, 0.05)
	s2._put_down(v2, big)
	_ok(tiny.assists == 0,
		"a man who did five per cent of it gets nothing when the grinder finishes it",
		"share %.0f%% is under the %.0f%% floor" % [
			0.05 / 1.0 * 100.0, Tuning.ASSIST_SHARE * 100.0])


## THE FLOOR IS THE WHOLE DIFFERENCE between a statistic and a participation
## count, so it is checked at the boundary rather than with a token value.
func _test_a_passing_shot_is_not_an_assist() -> void:
	var sim := _sim()
	var victim: MeleeSim.Man = sim.men[5]
	var thrower: MeleeSim.Man = sim.men[0]
	var under: MeleeSim.Man = sim.men[1]
	## 14% of the total: one point under the floor and nothing else touching it.
	sim._wear(victim, thrower, 0.86)
	sim._wear(victim, under, 0.14)
	sim._put_down(victim, thrower)
	_ok(under.assists == 0, "just under the floor is not an assist",
		"14%% against a floor of %.0f%%" % (Tuning.ASSIST_SHARE * 100.0))

	var s2 := _sim()
	var v2: MeleeSim.Man = s2.men[5]
	var t2: MeleeSim.Man = s2.men[0]
	var over: MeleeSim.Man = s2.men[1]
	s2._wear(v2, t2, 0.84)
	s2._wear(v2, over, 0.16)
	s2._put_down(v2, t2)
	_ok(over.assists == 1, "and just over it is",
		"16% against the same floor")


func _test_the_slate_is_wiped_when_he_goes_down() -> void:
	var sim := _sim()
	var victim: MeleeSim.Man = sim.men[5]
	var thrower: MeleeSim.Man = sim.men[0]
	var early: MeleeSim.Man = sim.men[1]
	sim._wear(victim, early, 0.70)
	sim._wear(victim, thrower, 0.30)
	sim._put_down(victim, thrower)
	_ok(early.assists == 1 and victim.wear.is_empty(),
		"the ledger is cleared when he hits the floor",
		"%d entries left" % victim.wear.size())
	## HE GETS UP, AND THE MAN WHO GROUND HIM DOWN LAST TIME HAS NO CLAIM ON THIS
	## ONE. Without the wipe, one long grapple in round one would be paying
	## assists for the rest of the bout.
	sim._wear(victim, thrower, 0.40)
	sim._put_down(victim, thrower)
	_ok(early.assists == 1,
		"and last time's work does not pay twice",
		"still %d after a second takedown he had no part in" % early.assists)


## AND IT HAPPENS IN A REAL BOUT. Every check above builds the situation by hand,
## which proves the rule and proves nothing about whether the sim ever produces
## one — the same gap as a trait with a table and no call site.
func _test_a_bout_produces_some() -> void:
	var total := 0
	var downs := 0
	for seed_value in [11, 22, 33, 44, 55]:
		var sim := MeleeSim.new(MeleeRosters.player_club(),
			MeleeRosters.rival_club(), seed_value)
		sim.run_to_end()
		for m in sim.men:
			total += m.assists
			downs += m.downs_caused
	_ok(total > 0, "a real bout produces assists",
		"%d across five bouts, against %d downs" % [total, downs])
	## AND NOT ONE PER DOWN. If every takedown paid an assist the number would be
	## a copy of the downs column with a different heading.
	_ok(total < downs, "and not one for every down",
		"%d assists on %d downs — %.0f%%" % [total, downs,
			100.0 * float(total) / maxf(1.0, float(downs))])
