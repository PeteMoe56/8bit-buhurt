extends SceneTree
## Age, potential, XP and retirement.
##
##   godot --headless --path . --script res://tests/test_career.gd
##
## The claim this layer exists to make is a specific one: **an old fighter is a
## different fighter, not a worse one.** Everything else here — the XP price, the
## ceiling, the retirement roll — is bookkeeping that can be checked by reading
## it. That claim cannot, and the first implementation broke it invisibly: by 32
## a trained fighter read 68 / 68 / 68 / 67, every man in the game had been sanded
## into the same shape, and nothing in the suite noticed. So the shape of a
## career is the first thing asserted here and the reason the file exists.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	SaveGame.set_namespace("career")
	print("\n=== Retro Buhurt — a career ===\n")
	_test_an_old_fighter_is_a_different_fighter()
	_test_you_cannot_train_what_you_are_past()
	_test_a_veteran_holds_but_never_reverses()
	_test_the_ceiling_binds()
	_test_xp_is_earned_by_doing()
	_test_one_prospect_a_winter()
	_test_a_squad_survives_its_retirements()
	_test_the_career_saves()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE CAREER HOLDS (%d checks)\n" % checks)
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


func _man(age: int) -> FighterCard:
	var f := FighterCard.new()
	f.age = age
	f.pos = Tuning.Pos.FLANK_L
	f.strength = 58
	f.base = 55
	f.skill = 52
	f.gas = 66
	f.aggression = 55
	f.potential = 90
	return f


func _test_an_old_fighter_is_a_different_fighter() -> void:
	## THE CLAIM. Run one man from 20 to 38 with an average season's production
	## and the four stats must end up in four different places — high base and
	## skill, spent gas — and the years at which each one peaked must come out in
	## the design's order: gas, strength, base, skill.
	##
	## Asserted as an ORDER rather than as four exact ages, because training can
	## carry a stat a year or two past its own peak before decline outruns it. The
	## order is the design; the exact year is a consequence of the XP price.
	var f := _man(20)
	var peak_year := {}
	var best := {}
	for stat in Career.STATS:
		best[stat] = 0
		peak_year[stat] = 0
	for _y in 18:
		f.xp += 30
		Career.winter(f, true, 2)
		for stat in Career.STATS:
			var v := Career.read_stat(f, stat)
			if v > int(best[stat]):
				best[stat] = v
				peak_year[stat] = f.age

	var order_right: bool = int(peak_year[Career.Stat.GAS]) \
			<= int(peak_year[Career.Stat.STRENGTH]) \
		and int(peak_year[Career.Stat.STRENGTH]) <= int(peak_year[Career.Stat.BASE]) \
		and int(peak_year[Career.Stat.BASE]) <= int(peak_year[Career.Stat.SKILL])
	## And the man at 38 must actually LOOK like a veteran rather than like a
	## slightly smaller version of himself. Skill and base clearly above where he
	## started, gas clearly below.
	var veteran: bool = f.skill > 52 + 15 and f.base > 55 and f.gas < 66 - 15
	var spread: int = maxi(maxi(f.strength, f.base), f.skill) - f.gas

	notes.append("peaks reached at: gas %d, strength %d, base %d, skill %d (design order: 24, 28, 32, 35)"
		% [peak_year[Career.Stat.GAS], peak_year[Career.Stat.STRENGTH],
			peak_year[Career.Stat.BASE], peak_year[Career.Stat.SKILL]])
	notes.append("the same man at %d: %d strength, %d base, %d skill, %d gas"
		% [f.age, f.strength, f.base, f.skill, f.gas])
	_ok(order_right and veteran and spread >= 20,
		"an old fighter is a different fighter",
		"the four peaks arrive in order and leave a %d-point spread between his best stat and his tank"
			% spread)


func _test_you_cannot_train_what_you_are_past() -> void:
	## THE RULE THAT MAKES THE ABOVE TRUE, asserted on its own so a regression
	## says which thing broke. A 30-year-old is past gas (24) and strength (28)
	## and must not gain either, however low they are and however much the ground
	## offers him — the old rule raised the lowest stat regardless and that is
	## exactly how the shape collapsed.
	var f := _man(30)
	f.gas = 12                 ## by far his lowest: the old rule would feed this
	f.strength = 20
	f.potential = 99
	var gas_before := f.gas
	var str_before := f.strength
	f.xp = 500
	Career.winter(f, true, 10)
	notes.append("a 31-year-old offered 10 ground points and 500 XP: gas %d -> %d, strength %d -> %d, skill up %d"
		% [gas_before, f.gas, str_before, f.strength, f.skill - 52])
	_ok(f.gas <= gas_before and f.strength <= str_before and f.skill > 52,
		"you cannot train what you are past",
		"every point went to base and skill; gas and strength were refused even as his lowest numbers")


func _test_a_veteran_holds_but_never_reverses() -> void:
	## Past all four peaks there is nothing left to grow, and XP buys back what
	## the winter took — never more. A fighter who ended a winter BETTER than he
	## started it would make age optional, which is the one thing this layer must
	## never allow.
	var f := _man(40)
	f.potential = 99
	f.xp = 9999
	var before: Array[int] = []
	for stat in Career.STATS:
		before.append(Career.read_stat(f, stat))
	var ovr_before := f.overall()
	var r := Career.winter(f, true, 20)
	var ovr_after := f.overall()
	var any_up := false
	for i in Career.STATS.size():
		if Career.read_stat(f, Career.STATS[i]) > before[i]:
			any_up = true
	notes.append("a 41-year-old with unlimited XP: lost %d, held %d back, overall %d -> %d"
		% [r["lost"], r["held"], ovr_before, ovr_after])
	_ok(not any_up and ovr_after <= ovr_before and int(r["held"]) > 0
			and int(r["held"]) <= int(r["lost"]),
		"a veteran holds but never reverses",
		"training slowed the fall by %d of the %d points age took, and moved no stat above where it started"
			% [r["held"], r["lost"]])


func _test_the_ceiling_binds() -> void:
	## A potential that nobody reaches is decoration; one that refuses nothing is
	## a second rating. This proves it refuses: a man AT his ceiling gains nothing
	## from either source, and his XP is not silently eaten paying for it.
	var f := _man(22)
	f.potential = f.overall()
	f.xp = 400
	var xp_before := f.xp
	var ovr := f.overall()
	var r := Career.winter(f, true, 12)

	## And a man under it does climb, so the check is not passing because the
	## winter does nothing at all.
	var g := _man(22)
	g.potential = g.overall() + 10
	g.xp = 400
	Career.winter(g, true, 12)

	notes.append("at the ceiling: overall %d -> %d, %d XP untouched; ten points under it: %d -> %d"
		% [ovr, f.overall(), f.xp, g.potential - 10, g.overall()])
	_ok(f.overall() <= ovr and f.xp == xp_before and int(r["gained"]) == 0
			and g.overall() > ovr,
		"the ceiling binds",
		"a fighter at his potential takes nothing and is charged nothing; one under it climbs")


func _test_xp_is_earned_by_doing() -> void:
	## Production, not attendance. A man who caused three downs must out-earn one
	## who caused none, and a man who never came on must earn nothing at all —
	## that last one is the whole reason a club carries a depth chart.
	var busy := Career.xp_for(3, 3)
	var quiet := Career.xp_for(0, 3)
	var flattened := Career.xp_for(0, 0)

	## And through the real road: fight a bout and check the cards moved.
	var club := MeleeRosters.player_club()
	var s := Season.new(club, 20260910)
	var bench_man: FighterCard = null
	for f in s.club.roster:
		if not s.club.starting_five().has(f):
			bench_man = f
			break
	var bench_xp := bench_man.xp if bench_man != null else -1
	var sim := s.begin_bout()
	sim.run_to_end()
	s.post_bout(sim)
	var line_xp := 0
	for f in s.club.starting_five():
		line_xp += f.xp

	notes.append("a bout: 3 downs and 3 rounds standing pays %d, 0 downs pays %d, never on the field pays %d"
		% [busy, quiet, flattened])
	notes.append("after one fought event the five carried %d XP between them; the bench carried %d"
		% [line_xp, bench_man.xp if bench_man != null else -1])
	_ok(busy > quiet and quiet > flattened and line_xp > 0
			and bench_man != null and bench_man.xp == bench_xp,
		"XP is earned by doing",
		"downs and rounds both pay, and a man who did not come on earned nothing")


func _test_one_prospect_a_winter() -> void:
	## THE ONE SCARCE WAY A CEILING MOVES. One man, once a year, and only with a
	## Training ground built up to take it. If a second route ever appears this
	## check will not catch it — but it will catch the cheap one, which is the
	## prospect quietly surviving the winter and paying out again.
	var s := Season.new(MeleeRosters.player_club(), 4242)
	s.office.facilities[ClubOffice.Facility.TRAINING] = Career.PROSPECT_GROUND
	var man: FighterCard = s.club.roster[0]
	var before := man.potential
	s.prospect = man
	while not s.ready_to_roll():
		if s.bid_open(): s.decline_bid()
		elif s.cup_pending(): s.sim_cup_tie()
		else: s.skip_event()
	s.roll_over()
	var after := man.potential
	var cleared: bool = s.prospect == null

	## Named again with the ground torn down: nothing happens.
	var t := Season.new(MeleeRosters.player_club(), 4242)
	t.office.facilities[ClubOffice.Facility.TRAINING] = Career.PROSPECT_GROUND - 1
	var poor: FighterCard = t.club.roster[0]
	var poor_before := poor.potential
	t.prospect = poor
	while not t.ready_to_roll():
		if t.bid_open(): t.decline_bid()
		elif t.cup_pending(): t.sim_cup_tie()
		else: t.skip_event()
	t.roll_over()

	notes.append("named prospect: ceiling %d -> %d; the same man with a level-%d ground: %d -> %d"
		% [before, after, Career.PROSPECT_GROUND - 1, poor_before, poor.potential])
	_ok(after == before + Career.PROSPECT_GAIN and cleared
			and poor.potential == poor_before,
		"one prospect a winter",
		"the named man gained %d and the slot cleared; a club without the ground gained nothing"
			% Career.PROSPECT_GAIN)


func _test_a_squad_survives_its_retirements() -> void:
	## NOBODY TURNS UP TO AN EVENT WITH SEVEN MEN. Play thirty seasons and the
	## travelling eight must be eight, and able to fill all five places, at the
	## end of every single one of them.
	##
	## The first version of the refill signed walk-ons only while the club could
	## not fill a LINE, so a squad that retired down to six kept travelling with
	## six — legal on the day and one knock from being unable to fight. A probe
	## run found it as a roster of five. This is the check that would have.
	var s := Season.new(MeleeRosters.player_club(), 99881)
	var worst_eight := 99
	var worst_five := 99
	var retired := 0
	var signed := 0
	for _y in 30:
		while not s.ready_to_roll():
			if not s.dilemma.is_empty(): s.answer_dilemma(0)
			elif s.bid_open(): s.decline_bid()
			elif s.cup_pending(): s.sim_cup_tie()
			else: s.skip_event()
		s.roll_over()
		## THE CLUB RE-SIGNS ITS MEN, and it has to for this check to mean
		## anything. Left alone it kept nobody long enough to get old: thirty
		## seasons produced **no retirements at all** and forty-eight walk-ons,
		## because every man walked out of contract in his twenties and the squad
		## was permanently a fresh intake. That is a true consequence of doing
		## nothing and it is not what this check is about — a club that never
		## keeps anybody cannot demonstrate that retirements are survivable.
		for f in s.club.roster.duplicate():
			if f.years <= 0:
				s.resign(f)
		retired += (s.last_winter.get("retired", []) as Array).size()
		signed += (s.last_winter.get("signed", []) as Array).size()
		worst_eight = mini(worst_eight, s.club.active_eight().size())
		worst_five = mini(worst_five, s.club.starting_five().size())
	## MEASURED AGAINST WHAT THE CLUB CAN TAKE, not against the constant eight.
	##
	## This asserted `ACTIVE_SIZE` — a full party — and went red the day a club's
	## travelling party became a thing it buys (`ClubOffice.travel_slots`): the
	## club in this fixture never buys a place, so it correctly travels six for
	## thirty seasons and the check called that a failure to survive its
	## retirements. What it is actually about is whether the squad refills, and
	## "full" is now a question with a club-specific answer.
	var want: int = s.club.party_size()
	notes.append("30 seasons: %d retired, %d walk-ons signed, smallest travelling squad %d of a possible %d"
		% [retired, signed, worst_eight, want])
	_ok(worst_eight == want and worst_five == 5 and retired > 0,
		"a squad survives its retirements",
		"men retired every few winters and the club never once travelled with fewer than the %d places it holds"
			% want)


func _test_the_career_saves() -> void:
	## Age, ceiling and banked XP all round-trip — and the PROSPECT comes back as
	## the man on the roster rather than as a copy of him. A saved prospect that
	## decoded into a duplicate would raise a ceiling on a fighter nobody fields
	## and leave the real one untouched, which is invisible until somebody asks
	## why the number never moved.
	const SLOT := 1
	SaveGame.delete(SLOT)
	var s := Season.new(MeleeRosters.player_club(), 5150)
	s.club.roster[2].age = 37
	s.club.roster[2].potential = 81
	s.club.roster[2].xp = 137
	s.prospect = s.club.roster[4]
	SaveGame.save(s, SLOT)
	var back := SaveGame.load_slot(SLOT)
	SaveGame.delete(SLOT)

	var same: bool = back != null \
		and back.club.roster[2].age == 37 \
		and back.club.roster[2].potential == 81 \
		and back.club.roster[2].xp == 137
	## The identity check: the loaded prospect must BE a card on the loaded
	## roster, not merely equal to one.
	var identity: bool = back != null and back.prospect != null \
		and back.club.roster.has(back.prospect) \
		and back.prospect.display_name == s.prospect.display_name
	notes.append("saved a 37-year-old with a ceiling of 81 and 137 XP banked, and a named prospect")
	_ok(same and identity, "the career saves",
		"age, ceiling and XP all come back, and the prospect is the man on the roster rather than a copy")
