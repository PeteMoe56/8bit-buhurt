extends SceneTree
## THE SHELF AND THE SCOUT — what is left of scouting after Pete's ruling of
## 1 Oct 2026: *"Remove scouting and just give each team a 4 category 5star
## system."* A stranger's ceiling is no longer a range to be read; it is shown,
## exact, like your own men's. What stays: the shelf is wide (finished men and
## rare prospects both exist), a man with room grows faster from a level, every
## ceiling on the shelf is the truth, and a Scout captain still finds more names.
##
## The balance check that a manager reading the range beats one who does not is
## gone with the range: there is nothing left to read.
##
##   godot --headless --path . --script res://tests/test_scouting.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []



func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the shelf ===\n")
	_test_the_shelf_is_wide()
	_test_every_ceiling_is_shown()
	_test_room_is_speed()
	_test_a_better_scout_finds_more()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE SCOUTING HOLDS (%d checks)\n" % checks)
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


func _shelves() -> Array:
	var men: Array = []
	for season in range(1, 41):
		for tier in League.TIERS.size():
			men.append_array(Market.pool(777, season, tier))
	return men


## Measured 28 Sep on 40 seasons x 4 divisions of shelves: of men 24 or under,
## 15% sit within 3 of their ceiling and 27% have 20+ room. The old roll gave
## the young 0..room evenly, so nobody had more than about 20.
func _test_the_shelf_is_wide() -> void:
	var young := 0
	var finished := 0
	var prospects := 0
	var over_old := 0
	for f in _shelves():
		if f.age > 24:
			continue
		young += 1
		var room := Career.potential_room(f.age)
		var gap: int = f.potential - f.overall()
		if gap <= 3:
			finished += 1
		if gap >= 20:
			prospects += 1
		if gap > room + Career.STANDARD_ROOM:
			over_old += 1
	var pf := 100.0 * float(finished) / float(maxi(1, young))
	var pp := 100.0 * float(prospects) / float(maxi(1, young))
	_ok(young > 200 and pf >= 10.0 and pp >= 10.0 and over_old > 0,
		"the shelf holds finished men and rare prospects both",
		"%d men 24 or under: %.0f%% within 3 of their ceiling, %.0f%% with 20+ room, %d past what the old roll could give"
			% [young, pf, pp, over_old])


func _test_every_ceiling_is_shown() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var wrong := 0
	var n := 0
	for i in 6:
		for f in s.market():
			n += 1
			var r := s.potential_range(f)
			if r.x != f.potential or r.y != f.potential:
				wrong += 1
		s.office.refresh_market()
	_ok(n > 20 and wrong == 0, "every ceiling on the shelf is shown exactly",
		"%d men, %d shown as anything but their real ceiling" % [n, wrong])


func _test_room_is_speed() -> void:
	var a := FighterCard.new()
	a.age = 21
	var b := a.copy()
	a.potential = a.overall() + 24
	b.potential = b.overall() + 2
	var ga := 0
	var gb := 0
	for i in 3:
		var a0 := a.overall()
		var b0 := b.overall()
		Career.level_up(a)
		Career.level_up(b)
		ga += a.overall() - a0
		gb += b.overall() - b0
	_ok(ga >= gb * 2 and ga > 0,
		"a man with room takes more from a level than a man near his ceiling",
		"three levels: %d points with 24 room, %d with 2" % [ga, gb])


## A BETTER SCOUT FINDS MORE (28 Sep 2026): the Scout trait's extra names are
## one a star plus one, and they really are on the shelf.
func _test_a_better_scout_finds_more() -> void:
	var sizes: Array[int] = []
	var names: Array[int] = []
	var s := Season.new(MeleeRosters.starting_club(), 6262)
	s.office.captains.clear()
	names.append(s.office.scout_names())
	sizes.append(s.market().size())
	for g in [2, 3, 5]:
		s.office.captains.clear()
		var c := ClubOffice.captain("Eyes", Tuning.Role.RAIL, Tuning.Role.CENTER, g)
		c["trait"] = ClubOffice.Trait.SCOUT
		s.office.captains.append(c)
		names.append(s.office.scout_names())
		sizes.append(s.market().size())
	_ok(names == [0, 3, 4, 6] and sizes[1] == sizes[0] + 3 and sizes[3] == sizes[0] + 6,
		"a better scout puts more names on the shelf",
		"extra names by grade (none, 2, 3, 5 stars): %s; shelf %s" % [str(names), str(sizes)])
