extends SceneTree
## THE CLUB SPLITS — the signature system.
##
##   godot --headless --path . --script res://tests/test_split.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the club splits ===\n")
	_test_it_takes_a_bad_room_and_a_bad_season()
	_test_the_men_who_go_are_the_men_you_left_out()
	_test_you_are_always_left_with_a_line()
	_test_the_rival_is_your_own_men()
	_test_the_rival_survives_a_save()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE SPLIT HOLDS (%d checks)\n" % checks)
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


func _test_it_takes_a_bad_room_and_a_bad_season() -> void:
	## BOTH, OR IT IS A PUNISHMENT. A club that is winning does not fracture
	## however unhappy it is, and a sound room does not fracture however badly the
	## year went. That conjunction is the difference between a system the player
	## can steer and a dice roll he resents.
	var bad: Array[String] = []
	var field := 8

	if ClubSplit.fractures(0.05, 8, field, true, 5) == false:
		bad.append("a mutinous room in a relegated club does not fracture")
	if ClubSplit.fractures(0.05, 1, field, false, 5):
		bad.append("a club that WON its division fractured")
	if ClubSplit.fractures(0.95, 8, field, true, 5):
		bad.append("a happy club fractured after a bad season")
	if ClubSplit.fractures(0.05, 8, field, true, 1):
		bad.append("a club fractured in the first season")
	## Mid-table with a mutinous room is a club with a problem, not two clubs.
	if ClubSplit.fractures(0.05, 3, field, false, 5):
		bad.append("finishing third fractured the club")

	## The fuse has to sit in the band the office already calls Mutinous, or the
	## screen is describing one state and the rule is acting on another.
	var o := ClubOffice.new()
	o.morale = ClubSplit.MORALE_FUSE - 0.01
	if o.morale_word() != "Mutinous":
		bad.append("the fuse is at %.2f, which the office calls '%s' rather than Mutinous"
			% [ClubSplit.MORALE_FUSE, o.morale_word()])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("fractures only below %.2f morale AND in the bottom half, never before season %d"
		% [ClubSplit.MORALE_FUSE, ClubSplit.EARLIEST_SEASON])
	_ok(bad.is_empty(), "it takes a bad room and a bad season",
		"winning holds a miserable club together and a sound room survives relegation; it takes both to break")


func _test_the_men_who_go_are_the_men_you_left_out() -> void:
	## THE FAVOURITISM CONDITION, which the direction document names and which is
	## the only one that is purely the player's own doing. A man who has fought
	## every week has a reason to stay when the club is miserable; a man who has
	## not been picked since March does not.
	var bad: Array[String] = []
	var roster: Array = []
	var picked: Array = []
	## Ten men, all equally miserable, five of whom have been playing.
	for i in 10:
		var f := FighterCard.new()
		f.display_name = "Man%d" % i
		f.morale = 0.20
		roster.append(f)
		if i < 5:
			picked.append(f)
	var walked := ClubSplit.who_walks(roster, picked)
	var unpicked_gone := 0
	for f in walked:
		if not picked.has(f):
			unpicked_gone += 1
	if unpicked_gone < walked.size():
		bad.append("a man who was playing walked before a man who was not")

	## And morale still separates men who were treated the same. Two benched men,
	## one content and one bitter: the bitter one goes.
	var pair: Array = []
	var content := FighterCard.new()
	content.display_name = "Content"
	content.morale = 0.95
	var bitter := FighterCard.new()
	bitter.display_name = "Bitter"
	bitter.morale = 0.02
	pair.append(content)
	pair.append(bitter)
	for i in 8:
		var filler := FighterCard.new()
		filler.display_name = "F%d" % i
		filler.morale = 0.90
		pair.append(filler)
	var pair_walked := ClubSplit.who_walks(pair, [])
	if not pair_walked.has(bitter):
		bad.append("the bitter man stayed")
	if pair_walked.has(content):
		bad.append("a content man walked out")

	## A HAPPY SQUAD LOSES NOBODY even if the rule is asked. `who_walks` decides
	## who, not whether — so it must be able to answer "nobody".
	var happy: Array = []
	for i in 10:
		var f2 := FighterCard.new()
		f2.morale = 0.95
		happy.append(f2)
	if not ClubSplit.who_walks(happy, happy).is_empty():
		bad.append("a happy squad still lost men")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("ten equally miserable men, five of them picked: %d walked and every one had been left out"
		% walked.size())
	_ok(bad.is_empty(), "the men who go are the men you left out",
		"being left out of the line is its own grievance, so the squad you lose is the squad you never picked")


func _test_you_are_always_left_with_a_line() -> void:
	## THIS SYSTEM MUST NOT BE A GAME OVER. Losing so many men that you cannot
	## field five is not a rival across town, it is the end of the save — and the
	## whole argument for a split over a sacking is that it is RECOVERABLE.
	var bad: Array[String] = []
	for size in [5, 6, 8, 10, 13]:
		var roster: Array = []
		for i in size:
			var f := FighterCard.new()
			f.display_name = "M%d" % i
			f.morale = 0.01          ## as bad as it can possibly be
			roster.append(f)
		var walked := ClubSplit.who_walks(roster, [])
		var left: int = size - walked.size()
		if left < ClubSplit.LEAVES_AT_LEAST:
			bad.append("a squad of %d was left with %d men" % [size, left])
		if walked.size() > int(floor(float(size) * ClubSplit.TAKES_AT_MOST)):
			bad.append("a squad of %d lost %d, which is more than half" % [size, walked.size()])

	## AND THE FLOOR IS THE LINE. `ClubSplit.LEAVES_AT_LEAST` is written out as a
	## literal rather than read off `MeleeClub.LINE_SIZE` — a const reaching into
	## another class is evaluated mid-parse and cost an afternoon — so the two are
	## checked here instead. Same rule this project applies to the register: state
	## it once, and make the duplicate a checked one.
	if ClubSplit.LEAVES_AT_LEAST != MeleeClub.LINE_SIZE:
		bad.append("the split leaves %d men and a line is %d"
			% [ClubSplit.LEAVES_AT_LEAST, MeleeClub.LINE_SIZE])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("with every man at rock bottom, a squad never falls below %d — half at most, and a line always stays"
		% ClubSplit.LEAVES_AT_LEAST)
	_ok(bad.is_empty(), "you are always left with a line",
		"at most half the squad walks and never so many that the club cannot field five, because this replaces being sacked rather than being one")


func _test_the_rival_is_your_own_men() -> void:
	## THE PAYOFF. *"Generates a rival with a grudge, and populates that rival
	## with your own former fighters."* A breakaway that fields strangers is a
	## rename, not a split.
	var bad: Array[String] = []
	var s := _fracture()
	if s.last_split.is_empty():
		bad.append("the club did not fracture under conditions built to fracture it")
	else:
		var took: Array = s.last_split["took"]
		var rival_id := int(s.last_split["id"])
		var rival := s.club_for(rival_id)
		var found := 0
		for nm in took:
			for f in rival.roster:
				if f.display_name == nm:
					found += 1
					break
		if found < took.size():
			bad.append("%d of the %d men who walked are not in the rival's squad"
				% [took.size() - found, took.size()])
		## AND THEY HAVE TO BE ON ITS LINE, not in its reserve.
		##
		## The first version of this check asked only whether the rival COULD field
		## five, and it could — with walk-ons, while the men who actually walked
		## sat on its bench, because they carried `active = false` out of the squad
		## that had not been picking them. A breakaway fielding strangers is a
		## rename. So the question is now how many of its travelling party are men
		## who left you.
		var travelling: Array = rival.active_eight()
		var ours := 0
		for f in travelling:
			if took.has(f.display_name):
				ours += 1
		if travelling.is_empty():
			bad.append("the breakaway travels nobody at all")
		elif ours < mini(took.size(), travelling.size()):
			bad.append("only %d of the %d men the breakaway travels came from you"
				% [ours, travelling.size()])
		## The rival is in YOUR division, because the point is that you fight them.
		if int(s.world.clubs[rival_id]["tier"]) != s.world.player_tier():
			bad.append("the breakaway is not in your division")
		## And it can field a line, or the fixture is a forfeit.
		if rival.starting_five().has(null):
			bad.append("the breakaway cannot field five")
		## You are still left with one too.
		if s.club.starting_five().has(null):
			bad.append("you cannot field five after the split")
		## The world has to know it is a splinter, or nothing can ever say so.
		if not bool(s.world.clubs[rival_id].get("splinter", false)):
			bad.append("the world does not record the club as a breakaway")
		notes.append("%d men walked to found %s, who travel %d — %d of them yours — and sit in your division"
			% [took.size(), String(s.last_split["club"]), rival.active_eight().size(), ours])
		notes.append("they took: %s" % ", ".join(took))

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the rival is your own men",
		"the breakaway is founded by the exact fighters who walked, sits in your own division, and both clubs can still field a line")


func _test_the_rival_survives_a_save() -> void:
	## Every other CPU club in this game is rebuilt from its id and its power, so
	## none of them is saved. A splinter is the one exception — rebuilt from a
	## seed it would be strangers wearing the name — which means it is also the
	## one CPU roster that can be lost in a save, silently, and only noticed
	## seasons later when you fight them.
	var bad: Array[String] = []
	var s := _fracture()
	if s.last_split.is_empty():
		bad.append("no split to save")
	else:
		var rival_id := int(s.last_split["id"])
		var before: Array[String] = []
		for f in s.club_for(rival_id).roster:
			before.append(f.display_name)

		SaveGame.set_namespace("split")
		SaveGame.save(s, 0)
		var back := SaveGame.load_slot(0)
		SaveGame.delete(0)
		if back == null:
			bad.append("the save did not come back")
		else:
			var after: Array[String] = []
			for f in back.club_for(rival_id).roster:
				after.append(f.display_name)
			if after != before:
				bad.append("the breakaway came back as a different squad")
			if not back.splinter_rosters.has(rival_id):
				bad.append("the reloaded season does not know the club is a breakaway")
			notes.append("%s round-trips with all %d men" % [
				String(s.last_split["club"]), before.size()])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the rival survives a save",
		"the one CPU roster in the game that is stored rather than generated comes back man for man")


## A club built to come apart: several seasons in, a mutinous room, and a season
## played out from the bottom of the division.
## A club built to come apart: several seasons in, a mutinous room, and a squad
## bad enough to genuinely finish last.
##
## THE FIRST VERSION OF THIS JUST SET MORALE TO 0.03 AND PLAYED THE SEASON, and
## it did not fracture — because `skip_event` SIMULATES the fixture rather than
## forfeiting it, so a normal squad won its share, finished third of six, and
## came out of the year at 0.166 morale rather than 0.03. The premise has to be
## built rather than asserted: a club only finishes last if it is actually the
## worst club in the division.
func _fracture() -> Season:
	var s := Season.new(MeleeRosters.starting_club(), 2468)
	s.world.season = 5
	## Genuinely the worst squad in the country, so the finish is earned.
	for f in s.club.roster:
		f.strength = 12
		f.base = 12
		f.skill = 12
		f.gas = 12
	s.sync_power()
	while not s.season_complete():
		s.skip_event()
		## And a room that never recovers. Morale moving back up over a losing
		## season is correct behaviour — the logistic pulls toward an equilibrium
		## — so holding it down is the fixture, not a workaround.
		for f in s.club.roster:
			f.morale = 0.03
		s.office.sync_morale(s.club)
	s.roll_over()
	return s
