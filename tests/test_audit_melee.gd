extends SceneTree
## The 27 Sep 2026 audit's bout-layer fixes, each held by a check that fails on
## the old code.
##
##   godot --headless --path . --script res://tests/test_audit_melee.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — audit: the bout ===\n")
	_test_a_down_frees_only_his_own_clinch()
	_test_the_fixture_reaches_the_men()
	_test_cold_hands_thinks_a_tier_worse()
	_test_engine_counts_as_gassed_later()
	_test_slippery_helps_against_a_stronger_man()
	_test_a_sub_brings_his_own_afternoon()
	_test_a_sub_before_the_charge_is_allowed()
	_test_taking_back_an_order_takes_back_its_question()
	_test_two_weapons()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE AUDIT HOLDS (%d checks)\n" % checks)
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


func _sim(seed_v: int = 4242) -> MeleeSim:
	return MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), seed_v)


func _test_a_down_frees_only_his_own_clinch() -> void:
	var s := _sim()
	## L (0) is walking at E (5), who is clinched with F (1).
	var L := s.men[0]
	var E := s.men[5]
	var F := s.men[1]
	E.state = MeleeSim.State.GRAPPLED
	E.target = F.idx
	F.state = MeleeSim.State.GRAPPLED
	F.target = E.idx
	L.target = E.idx
	s._put_down(L, s.men[6])
	_ok(E.state == MeleeSim.State.GRAPPLED and F.state == MeleeSim.State.GRAPPLED,
		"a man going down does not break up somebody else's clinch",
		"L was walking at E; E and F are still locked")
	s._put_down(E, s.men[2])
	_ok(F.state != MeleeSim.State.GRAPPLED,
		"and his own clinch partner is let go",
		"E down; F is %d" % F.state)


func _test_the_fixture_reaches_the_men() -> void:
	var season := Season.new(MeleeRosters.starting_club(), 777)
	var opp := season.opponent_id()
	var man: FighterCard = season.club.starting_five()[0]
	man.trait_id = FighterTrait.T.GRUDGE
	man.grudge_club = opp
	var sim := season.begin_bout()
	var got := 1.0
	for m in sim.men:
		if m.card == man:
			got = m.grudge
	_ok(got > 1.0, "a grudge fires in a real season bout",
		"against club %d: x%.2f (it was always 1.0 — the fixture was set after the men were built)"
			% [opp, got])


func _test_cold_hands_thinks_a_tier_worse() -> void:
	var s := _sim()
	var m := s.men[0]
	var plain: Dictionary = s._skill_of(m)
	m.card.trait_id = FighterTrait.T.COLD_HANDS
	var dim: Dictionary = s._skill_of(m)
	var keys := Tuning.AI_SKILL.values()
	_ok(keys.find(dim) == keys.find(plain) - 1 or keys.find(plain) <= 0,
		"Cold Hands thinks a tier worse than he is coached",
		"%s -> %s" % [String(plain["name"]), String(dim["name"])])


func _test_engine_counts_as_gassed_later() -> void:
	var s := _sim()
	var m := s.men[0]
	m.card.trait_id = FighterTrait.T.ENGINE
	_ok(m.gassed_line() < Tuning.GASSED_BELOW,
		"Engine counts as gassed later than anyone else",
		"line %.2f vs %.2f" % [m.gassed_line(), Tuning.GASSED_BELOW])


func _test_slippery_helps_against_a_stronger_man() -> void:
	## The chance, recomputed the way the sim does it, for a weak man against a
	## strong one. With the old formula the trait made this number smaller.
	var base := Tuning.ESCAPE_BASE + (40.0 - 90.0) * Tuning.ESCAPE_PER_SKL
	var slip := base * FighterTrait.mod(FighterTrait.T.SLIPPERY, "escape", 1.0)
	var old := Tuning.ESCAPE_BASE + (40.0 - 90.0) * Tuning.ESCAPE_PER_SKL \
		* FighterTrait.mod(FighterTrait.T.SLIPPERY, "escape", 1.0)
	_ok(base <= 0.0 or slip > base, "Slippery helps against a stronger man",
		"plain %.3f, slippery %.3f (the old formula gave %.3f)" % [base, slip, old])


func _test_a_sub_brings_his_own_afternoon() -> void:
	var s := _sim(99)
	## Play round one out, then sub slot 0 in the corner.
	var guard := 0
	while s.phase != MeleeSim.Phase.CORNER and not s.is_over() and guard < 20000:
		guard += 1
		s.tick()
	if s.is_over():
		_ok(false, "a sub brings his own afternoon", "the bout ended in round one")
		return
	var out_card = s.men[0].card
	s.men[0].downs_caused = 3
	var bench: Array = s.bench(0)
	if bench.is_empty():
		_ok(false, "a sub brings his own afternoon", "no bench to sub from")
		return
	var sub = bench[0]
	s.swap_in(0, 0, sub)
	s.leave_corner()
	var mine := -1
	var theirs := -1
	for m in s.fought():
		if m.card == out_card:
			mine = m.downs_caused
		if m.card == sub:
			theirs = m.downs_caused
	_ok(mine == 3 and theirs == 0, "a sub brings his own afternoon",
		"the man who came off keeps his 3 downs (%d); the sub starts at %d" % [mine, theirs])


func _test_a_sub_before_the_charge_is_allowed() -> void:
	var s := _sim(7)
	var bench: Array = s.bench(0)
	var ok := not bench.is_empty() and s.swap_in(0, 1, bench[0])
	_ok(ok and s.men[1].card == bench[0], "a sub before the first charge goes through",
		"swap_in before round one: %s" % str(ok))


func _test_taking_back_an_order_takes_back_its_question() -> void:
	var s := _sim(11)
	var m := s.men[0]
	s._open_prompt(m, Tuning.Menu.APPROACH, 5)
	m.target = 5
	s.cancel_order(0)
	_ok(m.prompt == null and m.target == -1, "taking back an order closes its question",
		"prompt %s, target %d" % ["open" if m.prompt != null else "closed", m.target])


## SWORD-AND-SHIELD AND POLEARM: the two classes, what each does, and that the
## weapon is part of the man (saved, copied, generated without moving the stream).
func _test_two_weapons() -> void:
	var s := _sim(5)
	var m := s.men[0]
	m.card.weapon = Tuning.Weapon.SWORD_SHIELD
	var sword_reach := m.contact_range()
	var sword_td := m.tmod("td_for", 0.0)
	m.card.weapon = Tuning.Weapon.POLEARM
	_ok(m.contact_range() > sword_reach and m.tmod("td_for", 0.0) > sword_td
		and m.tmod("br_against", 1.0) < 1.0,
		"a polearm reaches further and hooks better, and has no shield to brace",
		"reach %.1f vs %.1f, takedown %+.2f vs %+.2f" % [m.contact_range(), sword_reach,
			m.tmod("td_for", 0.0), sword_td])
	var f := FighterCard.new()
	f.weapon = Tuning.Weapon.POLEARM
	f.grudge_club = 7
	f.morale = 0.7
	var back := SaveGame.fighter_from_dict(SaveGame.fighter_to_dict(f))
	_ok(back.weapon == Tuning.Weapon.POLEARM and back.grudge_club == 7 and f.copy().weapon == f.weapon,
		"the weapon (and his grudge) survive a save and a copy",
		"weapon %d, grudge %d" % [back.weapon, back.grudge_club])
	var club := MeleeRosters.starting_club()
	var poles := 0
	for c in club.roster:
		if c.weapon == Tuning.Weapon.POLEARM:
			poles += 1
	_ok(poles > 0 and poles < club.roster.size(), "a generated club carries both",
		"%d of %d carry a pole" % [poles, club.roster.size()])
