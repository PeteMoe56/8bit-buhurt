extends SceneTree
## You: the coach — his levels, his five skills and what each one does, his
## record, and the captains' traits (which belong to the men you hire, not to
## you). Pete, 1 Oct 2026: the reputation and the job offers are gone.
##
##   godot --headless --path . --script res://tests/test_coach.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the coach ===\n")
	_test_levels_come_from_the_work()
	_test_points_and_the_background()
	_test_each_skill_does_its_thing()
	_test_the_coach_survives_a_save()
	_test_an_old_save_asks_for_him()
	_test_traits_reach_only_the_roles_their_man_covers()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE COACH HOLDS (%d checks)\n" % checks)
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


func _test_levels_come_from_the_work() -> void:
	var c := Coach.new()
	c.start_fresh()
	var p0 := c.points
	for _i in 5:
		c.note_result(true, false)
	var after_wins := c.level
	c.after_division(1)
	c.after_cup(1)
	_ok(after_wins == 2 and c.level >= 3 and c.points == p0 + c.level - 1 and c.record_line() == "5-0-0",
		"wins, a title and a cup are levels, and a level is a point",
		"5 wins: level %d; + 1st and a cup: level %d, %d points (started %d)" % [after_wins, c.level, c.points, p0])
	var l := Coach.new()
	l.note_result(false, false)
	_ok(l.xp == 0 and l.losses == 1, "a loss pays nothing", "xp %d" % l.xp)


func _test_points_and_the_background() -> void:
	var c := Coach.new()
	c.created = false
	c.start_fresh(Coach.Background.PROMOTER)
	var ok1 := c.skill(Coach.Skill.BUSINESS) == 1 and c.points == Coach.START_POINTS
	c.set_background(Coach.Background.MARSHAL)
	var ok2 := c.skill(Coach.Skill.BUSINESS) == 0 and c.skill(Coach.Skill.TACTICS) == 1
	c.spend(Coach.Skill.TRAINING)
	c.unspend(Coach.Skill.TRAINING)
	c.unspend(Coach.Skill.TACTICS)
	var ok3 := c.points == Coach.START_POINTS and c.skill(Coach.Skill.TACTICS) == 1
	c.points = 9
	for _i in 7:
		c.spend(Coach.Skill.RECRUITING)
	var ok4 := c.skill(Coach.Skill.RECRUITING) == Coach.SKILL_MAX and c.spend(Coach.Skill.RECRUITING) != ""
	c.created = true
	c.unspend(Coach.Skill.RECRUITING)
	var ok5 := c.skill(Coach.Skill.RECRUITING) == Coach.SKILL_MAX
	_ok(ok1 and ok2 and ok3 and ok4 and ok5,
		"a background is a free point, a skill tops out at five, and a spent point stays spent",
		"%s %s %s %s %s" % [ok1, ok2, ok3, ok4, ok5])


func _test_each_skill_does_its_thing() -> void:
	var bad: Array[String] = []
	## TRAINING: the same practice week, with and without five stars.
	var a := Season.new(MeleeRosters.starting_club(), 4040)
	var b := Season.new(MeleeRosters.starting_club(), 4040)
	b.coach.skills[Coach.Skill.TRAINING] = 5
	var xa := 0
	var xb := 0
	SeasonBouts._practice(a, true)
	SeasonBouts._practice(b, true)
	for f in a.club.roster:
		xa += f.xp
	for f in b.club.roster:
		xb += f.xp
	if xb <= xa:
		bad.append("Training: %d XP at 5 stars vs %d at none" % [xb, xa])
	## BUSINESS: a gate of 10 at four stars pays 12.
	var o := ClubOffice.new()
	var c := Coach.new()
	c.skills[Coach.Skill.BUSINESS] = 4
	o.coach_ref = c
	var before := o.credits
	o.take(10, "gate", "", ClubOffice.LINE_GATE)
	if o.credits - before != 12:
		bad.append("Business: a 10 CC gate paid %d" % (o.credits - before))
	## TACTICS: one call at three, two at five.
	c.skills[Coach.Skill.TACTICS] = 3
	var three := o.extra_calls()
	c.skills[Coach.Skill.TACTICS] = 5
	var five := o.extra_calls()
	if five - three != 1 or three < 1:
		bad.append("Tactics: %d calls at 3 stars, %d at 5" % [three, five])
	## RECRUITING: five stars knock a quarter off a fee.
	var r := Season.new(MeleeRosters.starting_club(), 4040)
	var pool := r.market()
	if not pool.is_empty():
		var full := r.market_fee(pool[0])
		r.coach.skills[Coach.Skill.RECRUITING] = 5
		var cut := r.market_fee(pool[0])
		if full > 1 and cut >= full:
			bad.append("Recruiting: fee %d, then %d" % [full, cut])
	## MOTIVATION: the multiplier on a loss.
	var m := Coach.new()
	m.skills[Coach.Skill.MOTIVATION] = 5
	if not is_equal_approx(m.morale_loss_mult(), 0.5):
		bad.append("Motivation: %.2f at 5 stars" % m.morale_loss_mult())
	_ok(bad.is_empty(), "each of the five skills does what its line says", "; ".join(bad) if not bad.is_empty()
		else "training, business, tactics, recruiting, motivation")


func _test_the_coach_survives_a_save() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	s.coach.set_name("Boris", "Kane")
	s.coach.background = Coach.Background.MARSHAL
	for _i in 7:
		s.coach.note_result(true, false)
	s.coach.spend(Coach.Skill.MOTIVATION)
	SaveGame.set_namespace("coach")
	SaveGame.save(s, 0)
	var back := SaveGame.load_slot(0)
	SaveGame.delete(0)
	var ok := back != null and back.coach.display_name == "Boris Kane" and back.coach.level == s.coach.level \
		and back.coach.xp == s.coach.xp and back.coach.skills == s.coach.skills \
		and back.coach.points == s.coach.points and back.coach.record_line() == "7-0-0" \
		and back.coach.created and back.office.coach_ref == back.coach
	_ok(ok, "the coach survives a save", "%s, level %d, %s" % [s.coach.display_name, s.coach.level,
		str(s.coach.skills)])


func _test_an_old_save_asks_for_him() -> void:
	var old := {"name": "Coach", "rep": 9, "w": 12, "d": 2, "l": 5}
	var c := Coach.from_dict(old)
	_ok(not c.created and c.wins == 12 and c.level > 1 and c.skill(int(Coach.BACKGROUND_SKILL[0])) == 1,
		"a coach from before the coach is asked for once, and his wins count",
		"created %s, level %d, record %s" % [str(c.created), c.level, c.record_line()])


func _test_traits_reach_only_the_roles_their_man_covers() -> void:
	## I BUILT THESE ON THE WRONG OBJECT FIRST. "Coach trait" reads like a perk
	## belonging to the player; every one of them in the shipped build is read off
	## `staff_hire` and scoped — *"Instant morale boost for $pos players"*. They
	## belong to the captain you hire and reach the roles he teaches.
	##
	## Which makes the scope the thing to assert: a one-star teaches nothing, so
	## his trait must reach nobody, or the grade ladder has a hole straight
	## through it.
	var bad: Array[String] = []

	var five := Season.new(MeleeRosters.starting_club(), 55)
	five.office.credits = 100
	five.hire_captain(ClubOffice.captain("Mott", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.POSITIVE))
	if not five.office.trait_covers(ClubOffice.Trait.POSITIVE, Tuning.Role.RAIL):
		bad.append("a five-star's trait does not reach a role he teaches")
	if five.office.trait_covers(ClubOffice.Trait.POSITIVE, Tuning.Role.FLANK):
		bad.append("his trait reaches a role he does not teach")
	if five.office.specialty_xp(Tuning.Role.RAIL) <= 1.0:
		bad.append("Positive does not reach the training multiplier")

	var one := Season.new(MeleeRosters.starting_club(), 55)
	one.office.credits = 100
	one.hire_captain(ClubOffice.captain("Ardry", Tuning.Role.RAIL, Tuning.Role.CENTER,
		1, ClubOffice.Trait.POSITIVE))
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		if one.office.trait_covers(ClubOffice.Trait.POSITIVE, role):
			bad.append("a one-star's trait reaches %s" % Tuning.ROLE_NAME[role])

	## THE ARRIVAL TRAITS FIRE ONCE, ON THE MEN HE COVERS. Measured against an
	## identical club that hired the same captain without the trait, so this
	## cannot pass on something every hire does.
	var with_ := Season.new(MeleeRosters.starting_club(), 88)
	var without := Season.new(MeleeRosters.starting_club(), 88)
	with_.office.credits = 100
	without.office.credits = 100
	with_.hire_captain(ClubOffice.captain("Mott", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.EXPERIENCE))
	without.hire_captain(ClubOffice.captain("Mott", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.NONE))
	var lifted := 0
	var untouched := 0
	for i in with_.club.roster.size():
		var a: FighterCard = with_.club.roster[i]
		var b: FighterCard = without.club.roster[i]
		var covered: bool = Tuning.role_of(int(a.pos)) != Tuning.Role.FLANK
		if covered and a.xp > b.xp:
			lifted += 1
		elif not covered and a.xp == b.xp:
			untouched += 1
		elif not covered:
			bad.append("%s plays Flanker and the Rail/Center captain banked him XP" % a.display_name)
	if lifted == 0:
		bad.append("Experience banked nobody any XP")

	## LIKEABLE covers the toxic drag, and only for the role its man teaches.
	var room := Season.new(MeleeRosters.starting_club(), 99)
	room.office.credits = 100
	for f in room.club.active_eight():
		f.morale = 0.70
	## Put the difficult man at Center and hire a captain who covers it.
	var poison: FighterCard = room.club.starting_five()[Tuning.Pos.CENTER]
	poison.morale = 0.05
	room.hire_captain(ClubOffice.captain("Kell", Tuning.Role.CENTER, Tuning.Role.RAIL,
		5, ClubOffice.Trait.LIKEABLE))
	var bare := Season.new(MeleeRosters.starting_club(), 99)
	for f in bare.club.active_eight():
		f.morale = 0.70
	bare.club.starting_five()[Tuning.Pos.CENTER].morale = 0.05
	room._after_event(0, 3)
	bare._after_event(0, 3)
	var covered_avg := 0.0
	var bare_avg := 0.0
	var n := 0
	for i in room.club.active_eight().size():
		var a: FighterCard = room.club.active_eight()[i]
		var b: FighterCard = bare.club.active_eight()[i]
		if a.toxic() or b.toxic():
			continue
		covered_avg += a.morale
		bare_avg += b.morale
		n += 1
	covered_avg /= float(maxi(1, n))
	bare_avg /= float(maxi(1, n))
	if covered_avg <= bare_avg:
		bad.append("Likeable did not spare the room (%.3f vs %.3f)" % [covered_avg, bare_avg])

	## EVERY TRAIT HAS TO DO SOMETHING, and this check used to assert only that
	## each had a DESCRIPTION — which is not the same claim at all, and Scout
	## proved it: its blurb said "More men at the trials" and no code anywhere
	## read the trait. When trials were cut (register §46) it was still passing.
	##
	## So Scout is now measured against the thing it claims to move.
	var unread: Array[String] = []
	for t in ClubOffice.TRAIT_NAME:
		if int(t) == ClubOffice.Trait.NONE:
			continue
		if not ClubOffice.TRAIT_BLURB.has(t):
			unread.append(String(ClubOffice.TRAIT_NAME[t]))
	if not unread.is_empty():
		bad.append("traits with no description: " + ", ".join(unread))

	var plain := Season.new(MeleeRosters.starting_club(), 606)
	var scouted := Season.new(MeleeRosters.starting_club(), 606)
	scouted.office.credits = 100
	scouted.hire_captain(ClubOffice.captain("Orde", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.SCOUT))
	if scouted.market().size() <= plain.market().size():
		bad.append("a Scout captain turns up no extra names (%d vs %d)"
			% [scouted.market().size(), plain.market().size()])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("Experience banked XP for %d of his men and left %d alone; a one-star's trait reached nobody"
		% [lifted, untouched])
	notes.append("Likeable, after a loss with a toxic Center: room at %.3f against %.3f without it"
		% [covered_avg, bare_avg])
	_ok(bad.is_empty(), "traits reach only the roles their man covers",
		"a captain's trait is scoped to the jobs he teaches, so a one-star's trait reaches nobody and the stars stay the thing you are buying")


## MONEY THE PLAYER PAID FOR IS NOT PART OF THE CLUB. Everything else stays
## behind; `min(credits, bought)` comes with the coach, so a job change can never
## be the thing that makes a purchase vanish.
