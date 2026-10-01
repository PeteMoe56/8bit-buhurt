extends SceneTree
## THE CALENDAR AND THE INVITATIONALS BY LEVEL (Pete, 1 Oct 2026).
##
## An American month (Sunday on the left), every day with something on it opens
## a popup, and the invitationals come in three sets — local for the bottom two
## divisions, North American for the Regional, Europe's big cities for the
## National — each invited from its own divisions and filled from abroad.

var failures: Array[String] = []
var checks: int = 0


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _initialize() -> void:
	await process_frame
	SaveGame.set_namespace("calendar")
	print("\n=== 8-Bit Buhurt — the calendar ===\n")
	_test_sunday_first()
	_test_the_sets()
	_test_team_stars()
	await _test_every_week_opens()
	print("")
	if failures.is_empty():
		print("THE CALENDAR HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _test_sunday_first() -> void:
	## 1 March 2027 is a Monday; 1 August 2027 a Sunday.
	_ok(Calendar.first_weekday(2027, 3) == 1 and Calendar.first_weekday(2027, 8) == 0
			and Calendar.weekday_name(0) == UiKit.t("SUN") and Calendar.weekday_name(6) == UiKit.t("SAT"),
		"the month starts on Sunday",
		"1 Mar 2027 in column %d, 1 Aug 2027 in column %d" % [Calendar.first_weekday(2027, 3),
			Calendar.first_weekday(2027, 8)])
	## And every league week is a Saturday.
	var bad := 0
	for i in 20:
		var dt := Calendar.date_of(1, i)
		var t := Time.get_unix_time_from_datetime_dict({"year": dt["year"], "month": dt["month"],
			"day": dt["day"], "hour": 12, "minute": 0, "second": 0})
		if int(Time.get_datetime_dict_from_unix_time(t)["weekday"]) != 6:
			bad += 1
	_ok(bad == 0, "every week's day is a Saturday", "%d of 20 were not" % bad)


func _test_the_sets() -> void:
	var w := LeagueWorld.new(31337, 44)
	## Play to the first cup weekend, then look at every set's field.
	while w.week_kind() != Calendar.Kind.CUP and not w.season_complete():
		w.play_week()
	var report: Array[String] = []
	var bad: Array[String] = []
	for si in LeagueWorld.INVITATIONAL_SETS.size():
		var spec: Dictionary = LeagueWorld.INVITATIONAL_SETS[si]
		var c: Cup = w._live_cup(w.invitational_id(si, 0))
		if c == null:
			bad.append("%s: no cup" % spec["id"])
			continue
		var home := 0
		var guests := 0
		var wrong := 0
		for id in c.entrants:
			var cl: Dictionary = w.clubs[int(id)]
			if bool(cl.get("guest", false)):
				guests += 1
			elif (spec["tiers"] as Array).has(int(cl["tier"])):
				home += 1
			else:
				wrong += 1
		var city := String(c.get_meta("city", ""))
		report.append("%s at %s: %d home, %d from abroad" % [c.cup_name, city, home, guests])
		if c.entrants.size() != LeagueWorld.INVITATIONAL_FIELD or wrong > 0:
			bad.append("%s: %d entrants, %d from the wrong divisions" % [spec["id"], c.entrants.size(), wrong])
		match String(spec["where"]):
			"local":
				if guests > 0:
					bad.append("the local set sent abroad")
			"elite":
				if not LeagueWorld.ELITE_CITIES.has(city) or home > LeagueWorld.INVITE_RANK:
					bad.append("elite at %s with %d home clubs" % [city, home])
			"continental":
				if not LeagueWorld.CONTINENTAL_US.has(city) or home > LeagueWorld.INVITE_RANK:
					bad.append("continental at %s with %d home clubs" % [city, home])
	_ok(bad.is_empty(), "three sets, each from its own divisions and its own map",
		"; ".join(report) if bad.is_empty() else "; ".join(bad))
	var before := w.clubs.size()
	w.play_week()
	var left := 0
	for c in w.clubs:
		if bool(c.get("guest", false)):
			left += 1
	_ok(left == 0, "and the clubs from abroad go home after the weekend",
		"%d clubs before, %d after, %d guests left" % [before, w.clubs.size(), left])
	## A Backyard club is never drawn against the National Division.
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	var mine := LeagueWorld.set_of_tier(s.world.player_tier())
	_ok(String(LeagueWorld.INVITATIONAL_SETS[mine]["id"]) == "local",
		"a Backyard club is asked to the local set",
		String(LeagueWorld.INVITATIONAL_SETS[mine]["id"]))


## EVERY WEEK OF A YEAR OPENS, at both ends of the pyramid, with something on it.
func _test_every_week_opens() -> void:
	var empty: Array[String] = []
	var n := 0
	for nat in [false, true]:
		var s := Season.new(MeleeRosters.starting_club(), 4242)
		if nat:
			var w := s.world
			for c in w.clubs:
				if int(c["tier"]) == League.Tier.NATIONAL:
					c["tier"] = 0
					break
			w.clubs[w.player_club]["tier"] = League.Tier.NATIONAL
			w._new_season()
		Session.season = s
		var scene: Node = load("res://scenes/Calendar.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		for wi in s.world.weeks_this_season():
			var info: Array = scene.call("_info", wi)
			n += 1
			if String(info[0]) == "" or (info[2] as Array).is_empty():
				empty.append("week %d (%d)" % [wi + 1, int(s.world.calendar[wi]["kind"])])
		scene.queue_free()
		await process_frame
	_ok(empty.is_empty() and n > 20, "every week's popup says something",
		"%d weeks opened%s" % [n, "" if empty.is_empty() else "; empty: " + ", ".join(empty)])



## EVERY CLUB, FOUR WAYS (Pete, 1 Oct 2026): the averages of its five, on the
## 1-99 scale the stars read, and a stronger division reads stronger.
func _test_team_stars() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	var mine := TeamCard.ratings(s.club)
	var five: Array = s.club.starting_five()
	var sum := 0
	for f in five:
		sum += int(f.strength)
	var bottom := 0.0
	var top := 0.0
	var nb := 0
	var nt := 0
	for c in s.world.clubs:
		var r := TeamCard.ratings(s.club_for(int(c["id"])))
		var mean := float(r[0] + r[1] + r[2] + r[3]) / 4.0
		if int(c["tier"]) == 0:
			bottom += mean
			nb += 1
		elif int(c["tier"]) == League.Tier.NATIONAL:
			top += mean
			nt += 1
	bottom /= float(maxi(1, nb))
	top /= float(maxi(1, nt))
	_ok(mine[0] == int(round(float(sum) / float(five.size()))) and top > bottom + 15.0,
		"a club's stars are its five's averages, and the National Division reads well above the Backyard",
		"your strength %d; Backyard mean %.0f, National mean %.0f" % [mine[0], bottom, top])
