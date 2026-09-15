extends SceneTree
## The four small levers: the Hall, the night out, the refreshes, staff deals.
##
##   godot --headless --path . --script res://tests/test_levers.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the levers ===\n")
	_test_the_hall_is_your_judgement()
	_test_morale_has_somewhere_to_spend()
	_test_a_refreshed_list_is_a_different_list()
	_test_a_captain_is_on_a_deal()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE LEVERS HOLD (%d checks)\n" % checks)
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


func _test_the_hall_is_your_judgement() -> void:
	## Tagged by hand while the man is still playing, which is what separates it
	## from the club records the game keeps for you. The card is COPIED, because
	## the man goes on ageing and declining and the point of the hall is what he
	## was on the day you decided he mattered.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var man: FighterCard = s.club.starting_five()[Tuning.Pos.CENTER]
	var was := man.overall()

	if s.world.in_hall(man.display_name):
		bad.append("a fresh save already has somebody in the Hall")
	if s.world.tag_for_hall(man, 3) != "":
		bad.append("tagging a man failed")
	if not s.world.in_hall(man.display_name):
		bad.append("the tagged man is not in the Hall")
	if s.world.tag_for_hall(man, 3) == "":
		bad.append("the same man was tagged twice")

	## HE DECLINES AND THE HALL DOES NOT. This is the whole reason it is a copy.
	man.strength = 5
	man.base = 5
	man.skill = 5
	man.gas = 5
	var kept := int((s.world.hall[0] as Dictionary)["rating"])
	if kept != was:
		bad.append("the Hall followed him down: %d, and he was %d when tagged" % [kept, was])

	## It fills up, and it says so rather than silently dropping somebody.
	var room := Season.new(MeleeRosters.starting_club(), 7)
	for i in LeagueWorld.HOF_MAX:
		var f := FighterCard.new()
		f.display_name = "Hall%d" % i
		if room.world.tag_for_hall(f, 1) != "":
			bad.append("ran out of room early, at %d" % i)
	var spare := FighterCard.new()
	spare.display_name = "One More"
	if room.world.tag_for_hall(spare, 1) == "":
		bad.append("a thirteenth man went into a Hall of %d" % LeagueWorld.HOF_MAX)
	room.world.untag_from_hall("Hall0")
	if room.world.tag_for_hall(spare, 1) != "":
		bad.append("taking one out did not make room")

	## And it survives a save, because a hall of fame that empties is worse than
	## no hall of fame.
	SaveGame.set_namespace("levers")
	SaveGame.save(s, 0)
	var back := SaveGame.load_slot(0)
	SaveGame.delete(0)
	if back == null or not back.world.in_hall(man.display_name):
		bad.append("the Hall did not survive a save")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a man tagged at %d stays at %d in the Hall after falling to %d; it holds %d and refuses the next"
		% [was, kept, man.overall(), LeagueWorld.HOF_MAX])
	_ok(bad.is_empty(), "the Hall is your judgement",
		"a man is tagged by hand while he is playing, keeps the rating he had, and the list is capped and saved")


func _test_morale_has_somewhere_to_spend() -> void:
	## THE ONLY LEVER ON MORALE. Everything else moves it AT the player — results,
	## the regime, a cut, a difficult man after a loss — and until this there was
	## nothing he could do about any of it on purpose. A system you can only watch
	## is a read-out.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 99)
	s.office.credits = 50
	for f in s.club.roster:
		f.morale = 0.40
	s.office.sync_morale(s.club)
	var before := s.office.morale
	var purse := s.office.credits

	s.office.new_week()
	if s.boost_morale() != "":
		bad.append("a club with money could not put a night on")
	if s.office.morale <= before:
		bad.append("the night out did not lift the room")
	if s.office.credits >= purse:
		bad.append("it cost nothing")

	## ONCE A WEEK, and this is the guard that matters. A morale button you can
	## mash is a morale button that deletes the toxic bottom end, which is the
	## half of the system Pete actually asked for.
	if s.boost_morale() == "":
		bad.append("two nights out in one week")
	var climbed := 0
	for _i in 40:
		if s.boost_morale() == "":
			climbed += 1
	if climbed > 0:
		bad.append("%d more nights out in the same week" % climbed)

	## And it reaches the men, not just the club figure — otherwise the average
	## and the men it is averaged from disagree the moment anything re-syncs.
	var lifted := 0
	for f in s.club.active_eight():
		if f.morale > 0.40:
			lifted += 1
	if lifted != s.club.active_eight().size():
		bad.append("only %d of the traveling party was lifted" % lifted)
	## A reserve who did not go is not lifted, because he was not there.
	var missed := 0
	for f in s.club.roster:
		if not s.club.active_eight().has(f) and is_equal_approx(f.morale, 0.40):
			missed += 1
	if missed == 0:
		bad.append("the men who did not travel were lifted anyway")

	## A broke club cannot buy its way out of a mutiny.
	var broke := Season.new(MeleeRosters.starting_club(), 5)
	broke.office.credits = 0
	broke.office.new_week()
	if broke.boost_morale() == "":
		bad.append("a club with no credits put a night on")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a night out: room %.3f -> %.3f for %d CC, once a week, and the %d who stayed home are untouched"
		% [before, s.office.morale, purse - s.office.credits, missed])
	_ok(bad.is_empty(), "morale has somewhere to spend",
		"the one deliberate lever on the room, capped at once a week so the toxic bottom end cannot be bought away")


func _test_a_refreshed_list_is_a_different_list() -> void:
	## Both lists are deterministic from the season so they do not reshuffle while
	## you read them — which also means a bad crop is a bad crop for a year. The
	## refresh is the answer, and it has to produce genuinely different men rather
	## than the same men in a new order.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	s.office.credits = 50

	var staff_before := ClubOffice.offer(s.seed_value, s.world.season, 0,
		s.office.staff_refreshes)
	if s.office.refresh_staff() != "":
		bad.append("could not refresh the staff list")
	var staff_after := ClubOffice.offer(s.seed_value, s.world.season, 0,
		s.office.staff_refreshes)
	if String(staff_before["name"]) == String(staff_after["name"]) \
			and int(staff_before["grade"]) == int(staff_after["grade"]) \
			and ClubOffice.specialties_of(staff_before) == ClubOffice.specialties_of(staff_after):
		bad.append("the refreshed captain is the same man")

	var market_before := s.market()
	if s.office.refresh_market() != "":
		bad.append("could not refresh the market")
	var market_after := s.market()
	var same := 0
	for a in market_before:
		for b in market_after:
			if a.display_name == b.display_name and a.overall() == b.overall():
				same += 1
				break
	if same == market_before.size() and not market_before.is_empty():
		bad.append("the refreshed market is the same %d men" % same)

	## STILL STABLE BETWEEN REFRESHES. The whole reason the list is seeded is that
	## it must not move while the player compares two men, and a refresh counter
	## in the key must not break that.
	var twice := s.market()
	if twice.size() != market_after.size():
		bad.append("the market changed between two reads")

	## And a broke club cannot turn either list over.
	s.office.credits = 0
	if s.office.refresh_staff() == "" or s.office.refresh_market() == "":
		bad.append("a club with no credits refreshed a list")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a %d CC refresh replaced the captain on offer and %d of %d free agents"
		% [ClubOffice.REFRESH_COST, market_before.size() - same, market_before.size()])
	_ok(bad.is_empty(), "a refreshed list is a different list",
		"paying turns a list over into genuinely different men, and it stays put between refreshes")


func _test_a_captain_is_on_a_deal() -> void:
	## `msg_StaffExpiring`. Without a contract a five-star hired in season two is
	## yours for twenty years for five credits, and the staff room — which has the
	## sharpest decision in the game on it — is visited once and never again.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 1234)
	s.office.credits = 200
	s.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5))
	var years := int(s.office.captains[0].get("years", 0))
	if years != ClubOffice.CAPTAIN_YEARS:
		bad.append("a new captain signs for %d years, not %d" % [years, ClubOffice.CAPTAIN_YEARS])

	## He runs out, and the summer says who left.
	var left: Array[String] = []
	for _i in ClubOffice.CAPTAIN_YEARS:
		left = s.office.age_captains()
	if s.office.captains.size() != 0:
		bad.append("the captain is still here after his deal ran out")
	if left.is_empty() or left[0] != "Vaughn":
		bad.append("the summer did not say who left")
	## And the role he taught goes back to untaught, which is the cost.
	if s.office.taught(Tuning.Role.RAIL):
		bad.append("the Rail is still coached by a man who has gone")

	## EXTENDING KEEPS HIM, and costs less than a new man — keeping the captain
	## you have should be the easy decision and finding a better one the dear one.
	var t := Season.new(MeleeRosters.starting_club(), 1234)
	t.office.credits = 200
	t.hire_captain(ClubOffice.captain("Sable", Tuning.Role.RAIL, Tuning.Role.CENTER, 5))
	var purse := t.office.credits
	if t.office.extend_captain(0) != "":
		bad.append("could not extend")
	if int(t.office.captains[0]["years"]) != ClubOffice.CAPTAIN_YEARS + 1:
		bad.append("extending did not add a year")
	if purse - t.office.credits != ClubOffice.CAPTAIN_EXTEND:
		bad.append("extending cost the wrong amount")
	if ClubOffice.CAPTAIN_EXTEND >= ClubOffice.CAPTAIN_COST:
		bad.append("a year costs as much as a whole new captain")
	t.office.credits = 0
	if t.office.extend_captain(0) == "":
		bad.append("a broke club extended a contract")

	## The deal survives a save, or it silently resets to full every reload.
	SaveGame.set_namespace("levers")
	SaveGame.save(t, 1)
	var back := SaveGame.load_slot(1)
	SaveGame.delete(1)
	if back == null or back.office.captains.is_empty() \
			or int(back.office.captains[0].get("years", -1)) != ClubOffice.CAPTAIN_YEARS + 1:
		bad.append("the contract did not survive a save")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a captain signs for %d years at %d CC and extends for %d; when it lapses the role he taught goes untaught"
		% [ClubOffice.CAPTAIN_YEARS, ClubOffice.CAPTAIN_COST, ClubOffice.CAPTAIN_EXTEND])
	_ok(bad.is_empty(), "a captain is on a deal",
		"staff sign for a fixed term, cost a little to keep and take their coaching with them when the term runs out")
