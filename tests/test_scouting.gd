extends SceneTree
## THE SCOUTED CEILING IS WORTH READING — Pete, 28 Sep 2026.
##
## A stranger's ceiling is shown as a range a captain narrows (27 Sep). On the old
## shelf that was decoration: a manager who read the true number and one who read
## nothing finished within noise of each other. The shelf now draws ceilings wide
## (`Career.free_agent_potential`), and these hold what that is for:
##
##   fast     the shelf really is wide — finished men and rare prospects both
##            exist; the range always contains the truth; a man with room grows
##            faster from a level than a man without
##   balance  over twenty careers, a manager who reads the range beats the same
##            manager signing on today's rating alone
##
##   godot --headless --path . --script res://tests/test_scouting.gd
##
## RB_TIER: fast runs the shelf; balance runs the careers (~1 minute).

var TIER := OS.get_environment("RB_TIER")
var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

## What the careers must show. Measured 28 Sep: 1.8 seasons and 6.0 power on
## the youth manager; the floors sit well under that so noise cannot trip them,
## and well over the 0.25 / 4.3 of the old shelf.
const MIN_TITLE_EDGE := 0.75
const MIN_POWER_EDGE := 3.0
const BASES := [9001, 5150, 2718, 6060, 8123]


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the scouted ceiling ===\n")
	if TIER != "balance":
		_test_the_shelf_is_wide()
		_test_the_range_holds_the_truth()
		_test_room_is_speed()
		_test_a_better_scout_finds_more()
	if TIER != "fast":
		_test_reading_the_range_pays()
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


func _test_the_range_holds_the_truth() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var outside := 0
	var widths := {}
	var n := 0
	for i in 6:
		for f in s.market():
			n += 1
			var r := s.potential_range(f)
			if f.potential < r.x or f.potential > r.y:
				outside += 1
			widths[r.y - r.x] = true
		s.office.refresh_market()
	_ok(n > 20 and outside == 0 and widths.has(ClubOffice.SCOUT_BLIND),
		"the range a stranger shows always contains his real ceiling",
		"%d men, %d outside their range, widths seen %s" % [n, outside, str(widths.keys())])


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


func _test_reading_the_range_pays() -> void:
	var read := _careers(ProbeManager.Read.MIDPOINT)
	var blind := _careers(ProbeManager.Read.IGNORE)
	var t_edge: float = blind["title"] - read["title"]
	var p_edge: float = read["power"] - blind["power"]
	_ok(t_edge >= MIN_TITLE_EDGE and p_edge >= MIN_POWER_EDGE,
		"a manager who reads the range beats one who signs on today's rating",
		"first title %.2f vs %.2f (%.2f seasons), power at 20 %.1f vs %.1f (%+.1f)"
			% [read["title"], blind["title"], t_edge, read["power"], blind["power"], p_edge])
	notes.append("youth manager, %d careers each: reading the range is worth %.2f seasons and %.1f power"
		% [BASES.size() * 4, t_edge, p_edge])


func _careers(mode: int) -> Dictionary:
	var title := 0.0
	var power := 0.0
	var n := 0.0
	for b in BASES:
		for i in 4:
			var s := Season.new(MeleeRosters.starting_club(), int(b) + i * 7919)
			Session.season = s
			var m := ProbeManager.new()
			m.youth = true
			m.reading = mode
			var won := 21
			for y in 20:
				m.winter(s)
				m.season(s)
				if s.world.player_tier() >= League.TIERS.size() - 1 \
						and s.world.player_position() == 1 and won > 20:
					won = y + 1
				s.roll_over()
			title += float(won)
			power += float(s.club.power())
			n += 1.0
	return {"title": title / n, "power": power / n}


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
