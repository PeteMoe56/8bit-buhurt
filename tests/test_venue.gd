extends SceneTree
## CITIES, HOSTS AND THE THREE KINDS OF AFTERNOON.
##
##   godot --headless --path . --script res://tests/test_venue.gd
##
## PETE, 14 Sep 2026: *"Looks like we just surfaced that we need to add the
## 'City' selectable for your team. And we need to make arenas for home, away,
## and tournament games."*
##
## It surfaced out of HOMESICK, which had sat in the pending list for eight
## passes with the note *"needs a home and an away, and this game has neither"*.
## The fixture list knew who played whom and not where.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== Retro Buhurt — the venue ===\n")
	_test_every_club_is_from_somewhere()
	_test_the_schedule_says_who_hosts()
	_test_hosts_are_shared_out()
	_test_adding_a_host_did_not_move_anybody()
	_test_taking_a_town_is_a_swap()
	_test_homesick_is_a_radius_and_not_a_flag()
	_test_the_map_is_a_real_map()
	_test_a_club_the_player_named_keeps_its_name()
	_test_the_gate_is_only_paid_at_home()
	_test_a_cup_tie_is_neutral_ground()
	print("")
	if failures.is_empty():
		print("THE VENUE HOLDS (%d checks)\n" % checks)
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


func _season() -> Season:
	return Season.new(MeleeRosters.starting_club(), 515151)


func _test_every_club_is_from_somewhere() -> void:
	var s := _season()
	var blank := 0
	var off_list := 0
	for c in s.world.clubs:
		var city := s.world.city_of(int(c["id"]))
		if city == "":
			blank += 1
		elif Cities.find(city).is_empty():
			off_list += 1
	_ok(blank == 0, "every club in the world is from a town",
		"%d clubs, %d with nowhere" % [s.world.clubs.size(), blank])
	_ok(off_list == 0, "and every town is on the map",
		"%d off the list" % off_list)
	## AND A SAVE THAT PREDATES CITIES STILL ANSWERS. `city_of` falls back to the
	## name, so an old world loads into a season where everybody is somewhere
	## rather than one where the splash screen has a blank in it.
	s.world.clubs[3].erase("city")
	_ok(s.world.city_of(3) != "",
		"and a club saved before cities existed still has one",
		"'%s', off its name" % s.world.city_of(3))


func _test_the_schedule_says_who_hosts() -> void:
	var rounds := League.fixtures([0, 1, 2, 3, 4, 5])
	var sized := true
	for day in rounds:
		for pair in day:
			if pair.size() != 3:
				sized = false
	_ok(sized, "every fixture names a host",
		"%d matchdays of [a, b, host]" % rounds.size())
	var legal := true
	for day in rounds:
		for pair in day:
			var h := League.host_of(pair)
			if h != int(pair[0]) and h != int(pair[1]):
				legal = false
	_ok(legal, "and the host is one of the two clubs in it",
		"nobody hosts a fixture they are not in")
	## THE FALLBACK, because an old save's schedule has two-element pairs and a
	## season where nobody is at home is worse than one where the first club is.
	_ok(League.host_of([7, 9]) == 7,
		"and a fixture saved before hosts existed has one anyway",
		"the first club named")


## A SCHEDULING RULE NOBODY MEASURES is a rule that quietly gives one club every
## away day. The parity trick is not trusted; the outcome is read back.
func _test_hosts_are_shared_out() -> void:
	var ids: Array = []
	for i in 10:
		ids.append(i)
	var rounds := League.fixtures(ids)
	var worst := 1.0
	var best := 0.0
	for i in ids.size():
		var share := League.home_share(rounds, int(ids[i]))
		worst = minf(worst, share)
		best = maxf(best, share)
	_ok(worst >= 0.30 and best <= 0.70,
		"nobody spends the season on the road and nobody spends it at home",
		"home share runs %.0f%% to %.0f%% across ten clubs"
		% [worst * 100.0, best * 100.0])


## THE ONE THAT COST A FAILING TEST TO LEARN.
##
## `play_event` passes `pair[0]` and `pair[1]` into `quick_bout` IN THAT ORDER,
## so writing the fixture as `[host, visitor]` redraws every simulated result in
## every division — and a save made yesterday replays into a different season.
## The host is a third element for that reason and this check is why it stays
## one.
func _test_adding_a_host_did_not_move_anybody() -> void:
	var rounds := League.fixtures([0, 1, 2, 3, 4, 5])
	var first_two: Array = []
	for day in rounds:
		for pair in day:
			first_two.append([int(pair[0]), int(pair[1])])
	## The circle method's own output, reproduced here: fix 0, rotate the rest.
	var ids: Array = [0, 1, 2, 3, 4, 5]
	var expect: Array = []
	for _r in 5:
		for i in 3:
			expect.append([int(ids[i]), int(ids[5 - i])])
		var last = ids.pop_back()
		ids.insert(1, last)
	_ok(first_two == expect,
		"the first two ids of every fixture are exactly what they always were",
		"%d fixtures, unchanged — quick_bout draws the same season" % expect.size())


func _test_taking_a_town_is_a_swap() -> void:
	var s := _season()
	var mine := s.city()
	## Somebody else's town, whoever has it.
	var theirs := ""
	var them := -1
	for c in s.world.clubs:
		if int(c["id"]) == s.world.player_club:
			continue
		theirs = s.world.city_of(int(c["id"]))
		them = int(c["id"])
		break
	_ok(s.set_city(theirs) == "" and s.city() == theirs,
		"you can take any town on the map",
		"'%s' to '%s'" % [mine, theirs])
	_ok(s.world.city_of(them) == mine,
		"and whoever was in it moves into yours — a swap, not a claim",
		"they are in '%s' now" % s.world.city_of(them))
	_ok(s.club.display_name.begins_with(theirs),
		"the club is renamed to match, and the fighting club agrees with the world",
		"'%s'" % s.club.display_name)
	## NOBODY IS IN TWO PLACES AND NO TOWN HAS TWO CLUBS.
	var seen := {}
	var dupes := 0
	for c in s.world.clubs:
		var city := s.world.city_of(int(c["id"]))
		if seen.has(city):
			dupes += 1
		seen[city] = true
	_ok(dupes == 0, "and the map still has one club to a town",
		"%d towns, %d doubled" % [seen.size(), dupes])


## THE RADIUS — Pete, 14 Sep 2026: *"real US cities so they can have a radius
## with the 'homesick'."*
func _test_homesick_is_a_radius_and_not_a_flag() -> void:
	var f := FighterCard.new()
	f.trait_id = FighterTrait.T.HOMESICK
	var near := Venue.homesick_scale(f, Venue.Kind.AWAY, 60.0)
	var mid := Venue.homesick_scale(f, Venue.Kind.AWAY, 800.0)
	var far := Venue.homesick_scale(f, Venue.Kind.AWAY, 2400.0)
	_ok(is_equal_approx(near, 1.0),
		"ninety miles down the road is not being away from home",
		"x%.3f at 60 miles" % near)
	_ok(mid < 1.0 and mid > far,
		"and it comes on with the distance",
		"x%.3f at 800, x%.3f at 2,400" % [mid, far])
	_ok(is_equal_approx(far, FighterTrait.mod(FighterTrait.T.HOMESICK, "away", 1.0)),
		"and stops at the trait's own figure rather than running away with it",
		"x%.3f, capped at %.0f miles" % [far, Venue.FAR_MILES])
	var ordinary := FighterCard.new()
	_ok(is_equal_approx(Venue.homesick_scale(ordinary, Venue.Kind.AWAY, 2400.0), 1.0),
		"and a man without the trait never notices the miles", "x1.000")


## THE MAP ITSELF. Made-up towns could not carry a distance; real ones can, and
## the figures have to be right because a player from that city will know.
func _test_the_map_is_a_real_map() -> void:
	_ok(Cities.US.size() >= 46 and Cities.EU.size() >= 46,
		"both maps hold more towns than the pyramid has clubs",
		"%d in the States, %d in Europe" % [Cities.US.size(), Cities.EU.size()])
	var dupes := 0
	for r in [Cities.Region.US, Cities.Region.EU]:
		var seen := {}
		for c in Cities.table(r):
			if seen.has(String(c["name"])):
				dupes += 1
			seen[String(c["name"])] = true
	_ok(dupes == 0, "and no town is on a map twice", "%d repeats" % dupes)
	var blank := 0
	for r in [Cities.Region.US, Cities.Region.EU]:
		for c in Cities.table(r):
			if String(c.get("area", "")) == "" or not c.has("lat") or not c.has("lon"):
				blank += 1
	_ok(blank == 0, "and every one has a state or a country and a place on the globe",
		"%d incomplete" % blank)
	## KNOWN DISTANCES, checked against what they actually are. A haversine with
	## a sign error still returns plausible-looking numbers, and the only way to
	## know the map is right is to measure something you already know.
	var checks := [
		["Detroit", "Cleveland", 90.0, 25.0],
		["New York", "Los Angeles", 2445.0, 60.0],
		["Dallas", "Houston", 225.0, 30.0],
		["London", "Manchester", 162.0, 25.0],
		["Warsaw", "Krakow", 157.0, 25.0],
	]
	var wrong: Array[String] = []
	for c in checks:
		var got := Cities.distance(String(c[0]), String(c[1]))
		if absf(got - float(c[2])) > float(c[3]):
			wrong.append("%s-%s %.0f not %.0f" % [c[0], c[1], got, c[2]])
	_ok(wrong.is_empty(), "and the distances are the real ones",
		"five known pairs, all inside tolerance" if wrong.is_empty()
		else ", ".join(wrong))
	_ok(is_equal_approx(Cities.distance("Detroit", "Detroit"), 0.0),
		"a club is no distance from itself", "0 miles")
	## AND A EUROPEAN WORLD IS A EUROPEAN WORLD, not an American one with one
	## foreign club in it.
	var eu := Season.new(MeleeRosters.starting_club(), 6060, Cities.Region.EU)
	var stray := 0
	for c in eu.world.clubs:
		if not Cities.names(Cities.Region.EU).has(eu.world.city_of(int(c["id"]))):
			stray += 1
	_ok(stray == 0, "and picking Europe builds a European league",
		"%d clubs, %d of them somewhere else" % [eu.world.clubs.size(), stray])


## THE ONE THAT ATE A CLUB'S NAME.
##
## `SaveGame` builds a Season with the saved club and THEN restores the saved
## world, so the constructor's map-safety ran against a fresh world. Its first
## version called `set_city`, which renames — and a club the player had called
## "Bonk Works" was read as being in the town "Bonk", found off the map,
## relocated, and came back **"New York Works"**. Every load.
##
## `test_create.gd` caught it because it has asserted a renamed club survives a
## save since long before there was a map. This asserts the rule directly, in the
## file that owns it, so the next person to reach for `set_city` in a constructor
## sees why not.
func _test_a_club_the_player_named_keeps_its_name() -> void:
	var s := _season()
	s.club.display_name = "Bonk Works"
	s.club.short_name = "BNK"
	s.world.clubs[s.world.player_club]["name"] = "Bonk Works"
	var rebuilt := Season.new(s.club, 515151)
	_ok(rebuilt.club.display_name == "Bonk Works",
		"a club whose name is not a town keeps its name through a rebuild",
		"'%s'" % rebuilt.club.display_name)
	_ok(Cities.names(rebuilt.world.region).has(rebuilt.city()),
		"and is still put somewhere on the map it plays on",
		"'%s'" % rebuilt.city())
	## AND THE HALF-MATCH THAT CAUSED IT. "Bonk" is not a town, so nothing should
	## think it is one.
	_ok(LeagueWorld._city_of("Bonk Works") == "",
		"a name that is not a town's answers with nothing, not with a guess",
		"'Bonk Works' -> ''")
	_ok(LeagueWorld._city_of("Detroit Free Company") == "Detroit",
		"and a name that is a town's still answers",
		"'Detroit Free Company' -> 'Detroit'")


func _test_the_gate_is_only_paid_at_home() -> void:
	_ok(Venue.pays_the_gate(Venue.Kind.HOME)
		and not Venue.pays_the_gate(Venue.Kind.AWAY)
		and not Venue.pays_the_gate(Venue.Kind.NEUTRAL),
		"the gate is yours at home and nowhere else",
		"a club that took its gate on the road would never build an arena")


func _test_a_cup_tie_is_neutral_ground() -> void:
	var s := _season()
	var kind := s.venue_kind()
	_ok(kind == Venue.Kind.HOME or kind == Venue.Kind.AWAY,
		"a league fixture is home or away", Venue.NAME[kind])
	_ok(s.host_id() == s.world.player_club or s.host_id() == s.opponent_id(),
		"and somebody is hosting it",
		"club %d" % s.host_id())
	## THE SPLASH HAS SOMETHING TO SAY IN ALL THREE, which is the check that the
	## screen cannot draw a blank banner.
	for k in [Venue.Kind.HOME, Venue.Kind.AWAY, Venue.Kind.NEUTRAL]:
		_ok(Venue.title(k, "Harrow", "Sports hall") != ""
			and Venue.mood_line(k, "Iron Crown") != "",
			"the %s splash has a name and a mood" % String(Venue.NAME[k]).to_lower(),
			"'%s' — %s" % [Venue.title(k, "Harrow", "Sports hall"),
				Venue.mood_line(k, "Iron Crown")])
