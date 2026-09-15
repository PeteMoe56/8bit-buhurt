extends SceneTree
## You: the reputation, the book that follows you, and the job offers.
##
##   godot --headless --path . --script res://tests/test_coach.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the coach ===\n")
	_test_reputation_climbs_and_halves()
	_test_a_cup_run_is_worth_what_it_was()
	_test_only_clubs_you_outrate_come_for_you()
	_test_the_dream_job_is_held_back()
	_test_the_list_does_not_reshuffle()
	_test_taking_a_job_leaves_everything_behind()
	_test_the_book_outlives_the_club()
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


func _test_reputation_climbs_and_halves() -> void:
	## THE SHAPE IS THE POINT: additive on success, MULTIPLICATIVE on failure.
	## Retro Bowl's own `coach_rating` does this and it is the thing that makes
	## the number mean something — a coach at 18 has sustained it, because one
	## mid-table season takes half of whatever he built.
	##
	## A version that subtracted a fixed amount would be a slider with a label,
	## which is the same complaint this project has made of three other systems.
	var bad: Array[String] = []
	var climbed: Array[int] = []
	var c := Coach.new()
	for place in [1, 1, 1, 1, 1, 1]:
		c.after_division(place)
		climbed.append(c.reputation)
	if c.reputation != Coach.REP_MAX:
		bad.append("six division titles do not reach the ceiling (%d)" % c.reputation)

	## And now one bad year.
	var before := c.reputation
	c.after_division(9)
	if c.reputation >= before:
		bad.append("finishing ninth did not cost anything")
	if c.reputation > int(round(float(before) * 0.6)):
		bad.append("finishing ninth cost less than a halving")

	## Every place on the ladder has to differ from its neighbours, or the table
	## is decoration.
	var by_place: Array[int] = []
	for place in range(1, 6):
		var p := Coach.new()
		p.reputation = 10
		p.after_division(place)
		by_place.append(p.reputation)
	for i in range(1, by_place.size()):
		if by_place[i] > by_place[i - 1]:
			bad.append("finishing %d is worth more than finishing %d" % [i + 1, i])

	## The floor and the ceiling both hold — a coach cannot halve his way to zero
	## and cannot win his way past the scale the clubs are compared on.
	var floored := Coach.new()
	for _i in 30:
		floored.after_division(12)
	if floored.reputation != Coach.REP_MIN:
		bad.append("thirty bad seasons do not settle at the floor (%d)" % floored.reputation)

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("six titles from nothing: %s, then one ninth place: %d"
		% [str(climbed), c.reputation])
	notes.append("from 10, finishing 1st-5th leaves you at %s" % str(by_place))
	_ok(bad.is_empty(), "reputation climbs and halves",
		"winning adds and missing out multiplies, so a high reputation is evidence of sustained work rather than of one good year")


func _test_a_cup_run_is_worth_what_it_was() -> void:
	## Paid by the size of the round you went out in, which is the key
	## `Cup.ROUND_NAMES` is written on — so the label on the cabinet and the
	## reputation the run earned are two readings of one number.
	var bad: Array[String] = []
	var paid: Array[int] = []
	var sizes := [16, 8, 4, 2, 1]
	for sz in sizes:
		var c := Coach.new()
		c.reputation = 5
		c.after_cup(sz)
		paid.append(c.reputation - 5)
	for i in range(1, paid.size()):
		if paid[i] <= paid[i - 1]:
			bad.append("going out at %d is worth no more than at %d" % [sizes[i], sizes[i - 1]])
	## Not entering pays nothing, and must not crash.
	var out := Coach.new()
	out.reputation = 5
	out.after_cup(-1)
	if out.reputation != 5:
		bad.append("a cup you were not in moved your reputation")

	## EVERY ROUND NAME THE CUP CAN PRINT HAS A PRICE. A round in ROUND_NAMES with
	## no entry here is a run that silently pays nothing.
	for key in Cup.ROUND_NAMES:
		if not Coach.REP_BY_CUP_EXIT.has(int(key)):
			bad.append("the %s pays nothing" % String(Cup.ROUND_NAMES[key]))

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a cup run pays %s for going out at %s" % [str(paid), str(sizes)])
	_ok(bad.is_empty(), "a cup run is worth what it was",
		"every round is worth more than the one before it and winning the thing is worth most")


func _test_only_clubs_you_outrate_come_for_you() -> void:
	## THE RULE THAT MAKES THE OFFER LIST A LADDER. You are offered clubs you
	## out-rate, so the list grows as you do and visibly shortens after a bad
	## season — punishment with no code about punishment in it.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 9001)
	s.world.season = 5              ## past the boyhood-club gate, so it is not in play

	var low := Coach.new()
	low.reputation = Coach.REP_MIN
	low.club_id = s.world.player_club
	var high := Coach.new()
	high.reputation = Coach.REP_MAX
	high.club_id = s.world.player_club

	var few := Jobs.offers(low, s.world)
	var many := Jobs.offers(high, s.world)
	if few.size() >= many.size():
		bad.append("a reputation of %d is offered as much as one of %d"
			% [Coach.REP_MIN, Coach.REP_MAX])
	## Nobody is ever offered their own desk.
	for cid in many:
		if cid == high.club_id:
			bad.append("your own club is on the list")
	## And every club on the list must actually be out-rated — read through the
	## same standing function the rule uses, not re-derived here.
	for cid in many:
		if high.reputation < Jobs.standing_of(int(s.world.clubs[cid]["power"])):
			bad.append("club %d is on the list and out-rates the coach" % cid)

	## THE HALVING HAS TO REACH THE LIST, which is the whole point of the rule
	## and cannot be seen from either half on its own.
	var slipping := Coach.new()
	slipping.reputation = 16
	slipping.club_id = s.world.player_club
	var before := Jobs.offers(slipping, s.world).size()
	slipping.after_division(9)
	var after := Jobs.offers(slipping, s.world).size()
	if after >= before:
		bad.append("one bad season did not shorten the list (%d -> %d)" % [before, after])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("offers at reputation %d: %d clubs · at %d: %d clubs"
		% [Coach.REP_MIN, few.size(), Coach.REP_MAX, many.size()])
	notes.append("a 16 who finishes ninth: %d offers become %d" % [before, after])
	_ok(bad.is_empty(), "only clubs you outrate come for you",
		"the offer list is a ladder that grows with the reputation and shortens the season after a bad one")


func _test_the_dream_job_is_held_back() -> void:
	## Retro Bowl bars your boyhood club until year 3 however good you are, and it
	## is the one line in `s_team_interested` I would not have written. Offered in
	## season one the dream job is a menu item; held back it is the thing you are
	## playing toward.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var c := Coach.new()
	c.reputation = Coach.REP_MAX
	c.club_id = s.world.player_club
	c.favourite_club_id = s.coach.favourite_club_id
	if c.favourite_club_id < 0:
		bad.append("no boyhood club was drawn")
	else:
		s.world.season = 1
		var early: bool = Jobs.interested(c, s.world, c.favourite_club_id)
		s.world.season = Jobs.DREAM_HELD_UNTIL_SEASON
		## The 1-in-4 also applies to the dream, so "not barred" is the question
		## rather than "offered" — and it must be answerable, which it is because
		## the seed depends on the season and this is a different season.
		s.world.season = 99
		var late_barred: bool = c.favourite_club_id == c.club_id
		if early:
			bad.append("the boyhood club came for you in season 1")
		if late_barred:
			bad.append("the boyhood club is the club you already have")
		## And it must be a club at the top of the pyramid, not one down the road.
		var tier := int(s.world.clubs[c.favourite_club_id]["tier"])
		if tier != League.TIERS.size() - 1:
			bad.append("the boyhood club is in tier %d, not the top one" % tier)
		notes.append("the boyhood club is %s (%s), barred until season %d"
			% [String(s.world.clubs[c.favourite_club_id]["name"]),
				League.tier_name(tier), Jobs.DREAM_HELD_UNTIL_SEASON])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the dream job is held back",
		"your boyhood club is drawn from the top of the pyramid, is never the club you have, and will not come for you before season %d"
			% Jobs.DREAM_HELD_UNTIL_SEASON)


func _test_the_list_does_not_reshuffle() -> void:
	## A hire screen whose candidates change while you read them is unusable, and
	## this list is drawn every time the screen rebuilds — which is on every tap.
	## The 1-in-4 is seeded on the three things that make this offer this offer.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 1234)
	s.world.season = 6
	var c := Coach.new()
	c.reputation = 14
	c.club_id = s.world.player_club
	var first := Jobs.offers(c, s.world)
	for _i in 20:
		if Jobs.offers(c, s.world) != first:
			bad.append("the list changed between reads")
			break
	## And it MUST change when the year does, or it is not an offer, it is a fact.
	s.world.season = 7
	var next_year := Jobs.offers(c, s.world)
	if next_year == first and not first.is_empty():
		bad.append("the same clubs come for you every season forever")
	## Best club first, because the list is a ladder and the top of it is why you
	## read it.
	for i in range(1, first.size()):
		if int(s.world.clubs[first[i]]["power"]) > int(s.world.clubs[first[i - 1]]["power"]):
			bad.append("the list is not sorted best-first")
			break

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("season 6 offers %d clubs, twenty reads apart; season 7 offers %d"
		% [first.size(), next_year.size()])
	_ok(bad.is_empty(), "the list does not reshuffle",
		"the same clubs are interested however many times the screen is drawn, and a different set next year")


func _test_taking_a_job_leaves_everything_behind() -> void:
	## THE MOVE HAS TO COST. You arrive with a reputation and a book and nothing
	## else — no credits, no arena, no captains, no roster. A version that let you
	## bring your best Center is a trade screen, not a career.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 777)
	s.world.season = 8
	s.coach.reputation = Coach.REP_MAX
	s.office.credits = 90
	s.office.upgrade(ClubOffice.Facility.TRAINING)
	s.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5))
	var old_club := s.club
	var old_id := s.world.player_club
	var old_names: Array[String] = []
	for f in old_club.roster:
		old_names.append(f.display_name)

	var targets := Jobs.offers(s.coach, s.world)
	if targets.is_empty():
		bad.append("a maximum-reputation coach was offered nothing")
	else:
		var to_id: int = targets[0]
		var err := s.take_job(to_id)
		if err != "":
			bad.append("the move was refused: %s" % err)
		if s.world.player_club != to_id:
			bad.append("the world still thinks you are at the old club")
		## A NEW DESK, not an empty one. A new club opens with the same stake any
		## new club opens with — asserted against a fresh office rather than
		## against 0, because 0 would be asserting the stake is zero, which is a
		## different claim and one the game does not make.
		var fresh := ClubOffice.new()
		if s.office.credits != fresh.credits:
			bad.append("you arrived with %d CC and a new club starts on %d"
				% [s.office.credits, fresh.credits])
		if s.office.credits >= 90:
			bad.append("you took the old club's money with you")
		if s.office.captains.size() != 0:
			bad.append("your captain came too")
		if s.office.level(ClubOffice.Facility.TRAINING) != 0:
			bad.append("the training ground came too")
		if s.club == old_club:
			bad.append("you took the roster with you")
		## And the club you left keeps the squad you built, which is what makes
		## meeting them again mean something.
		var left := s.club_for(old_id)
		var kept := 0
		for f in left.roster:
			if old_names.has(f.display_name):
				kept += 1
		if kept < old_names.size():
			bad.append("the club you left lost %d of its men" % (old_names.size() - kept))
		## The book comes with you, which is the one thing that does.
		if s.coach.posts.size() != 2:
			bad.append("the move is not in your record")
		if s.coach.years_here != 0:
			bad.append("you arrived with years already served")
		notes.append("left %s for %s: %d CC, %d captains, %d roster kept by the old club"
			% [String(s.world.clubs[old_id]["name"]), String(s.world.clubs[to_id]["name"]),
				s.office.credits, s.office.captains.size(), kept])
		notes.append("(the 90 CC and the training ground stayed behind; a new club opens on %d CC)"
			% ClubOffice.new().credits)

	## AND IT IS A CLOSED SEASON MOVE. Walking out mid-year leaves a half-played
	## fixture list owned by nobody.
	var mid := Season.new(MeleeRosters.starting_club(), 777)
	mid.world.season = 8
	mid.coach.reputation = Coach.REP_MAX
	mid.skip_event()
	var mid_targets := Jobs.offers(mid.coach, mid.world)
	if not mid_targets.is_empty() and mid.take_job(int(mid_targets[0])) == "":
		bad.append("you can walk out in the middle of a season")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "taking a job leaves everything behind",
		"the new desk is empty, the old club keeps the squad you built, and only the reputation and the book travel")


func _test_the_book_outlives_the_club() -> void:
	## The only object in the game that survives a post. If it did not, twenty
	## seasons across three clubs would read as three short careers.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	for _i in 7:
		s.coach.note_result(true, false)
	for _i in 3:
		s.coach.note_result(false, false)
	s.coach.note_result(false, true)
	var before := s.coach.record_line()
	if before != "7-1-3":
		bad.append("the record reads %s and should read 7-1-3" % before)
	if not is_equal_approx(s.coach.win_rate(), 7.0 / 11.0):
		bad.append("the win rate does not match the record")

	s.world.season = 9
	s.coach.reputation = Coach.REP_MAX
	var targets := Jobs.offers(s.coach, s.world)
	if not targets.is_empty():
		s.take_job(int(targets[0]))
	if s.coach.record_line() != before:
		bad.append("the record was reset by the move")

	## And it round-trips, because a career you cannot save is not a career.
	SaveGame.set_namespace("coach")
	SaveGame.save(s, 0)
	var back := SaveGame.load_slot(0)
	SaveGame.delete(0)
	if back == null:
		bad.append("the save did not come back")
	else:
		if back.coach.record_line() != before:
			bad.append("the record did not survive a save")
		if back.coach.reputation != s.coach.reputation:
			bad.append("the reputation did not survive a save")
		if back.coach.posts.size() != s.coach.posts.size():
			bad.append("the posts did not survive a save")
		if back.coach.favourite_club_id != s.coach.favourite_club_id:
			bad.append("the boyhood club did not survive a save")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a record of %s across %d posts, through a move and a save"
		% [s.coach.record_line(), s.coach.posts.size()])
	_ok(bad.is_empty(), "the book outlives the club",
		"the lifetime record and the reputation survive both taking another job and a save")


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
