extends SceneTree
## The pyramid, measured over a hundred simulated seasons.
##
##   godot --headless --path . --script res://tests/test_league.gd
##
## A league bug is almost never visible in one season. A division that gains a
## club a year, a fixture list that gives somebody an extra game, a table that
## re-sorts on reload — all of them look fine on a Sunday and are ruinous by
## season nine. So everything here runs long.

const SEASONS := 100

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the pyramid (%d seasons) ===\n" % SEASONS)
	_test_pyramid_balances()
	_test_fixtures_are_a_round_robin()
	_test_table_maths()
	_test_table_is_deterministic()
	_test_divisions_never_leak()
	_test_determinism()
	_test_the_climb_is_possible()
	_test_the_climb_is_earned()
	_test_the_simmed_result_is_not_a_coin_flip()
	_test_a_title_counts_once()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE PYRAMID HOLDS (%d checks)\n" % checks)
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


# ------------------------------------------------------------------ shape
func _test_pyramid_balances() -> void:
	## Whatever a tier promotes, the tier above must relegate. Otherwise the
	## divisions drift in size forever and nothing else here means anything.
	var err := League.pyramid_balances()
	var shape := ""
	for t in League.TIERS.size():
		shape += "%s %d (+%d/-%d)  " % [
			League.TIERS[t]["short"], League.club_count(t),
			League.TIERS[t]["up"], League.TIERS[t]["down"]]
	notes.append("pyramid: " + shape.strip_edges())
	_ok(err == "", "the pyramid balances", "promotions and relegations match" if err == "" else err)


func _test_fixtures_are_a_round_robin() -> void:
	## Everyone plays everyone once, nobody plays twice, nobody plays himself.
	var bad := ""
	for t in League.TIERS.size():
		var ids: Array = []
		for i in League.club_count(t):
			ids.append(i)
		var days := League.fixtures(ids)
		if days.size() != League.events_in_season(t):
			bad = "%s has %d matchdays, expected %d" % [
				League.TIERS[t]["short"], days.size(), League.events_in_season(t)]
			break
		var seen: Dictionary = {}
		var games := {}
		for day in days:
			var today: Dictionary = {}
			for pair in day:
				var a := int(pair[0])
				var b := int(pair[1])
				if a == b:
					bad = "a club drawn against itself"
				if today.has(a) or today.has(b):
					bad = "%s: a club has two fixtures on one matchday" % League.TIERS[t]["short"]
				today[a] = true
				today[b] = true
				var key := "%d-%d" % [mini(a, b), maxi(a, b)]
				if seen.has(key):
					bad = "%s: %s meet twice" % [League.TIERS[t]["short"], key]
				seen[key] = true
				games[a] = int(games.get(a, 0)) + 1
				games[b] = int(games.get(b, 0)) + 1
		var want := League.club_count(t) - 1
		for cid in games:
			if int(games[cid]) != want:
				bad = "%s: club %d plays %d, expected %d" % [
					League.TIERS[t]["short"], cid, games[cid], want]
		if bad != "":
			break
	_ok(bad == "", "fixtures are a single round-robin",
		"every club meets every other exactly once" if bad == "" else bad)


# ------------------------------------------------------------------ table
func _test_table_maths() -> void:
	## Three for a win, one for a draw, and rounds are the goals.
	var row := League.new_row(1)
	League.apply_result(row, 2, 0)      # win
	League.apply_result(row, 1, 2)      # loss
	League.apply_result(row, 1, 1)      # draw
	var right: bool = int(row["played"]) == 3 and int(row["won"]) == 1 \
		and int(row["lost"]) == 1 and int(row["drawn"]) == 1 \
		and int(row["points"]) == League.WIN_POINTS + League.DRAW_POINTS \
		and int(row["rf"]) == 4 and int(row["ra"]) == 3 and League.round_diff(row) == 1
	_ok(right, "table maths",
		"W1 D1 L1 = %d pts, rounds %d-%d" % [row["points"], row["rf"], row["ra"]])


func _test_table_is_deterministic() -> void:
	## Two clubs level on points and round difference must not swap places when
	## the table is rebuilt. A standings screen that reshuffles on reload reads
	## as a bug even when the maths is right.
	var rows: Array = []
	for i in 6:
		var r := League.new_row(i)
		League.apply_result(r, 2, 1)
		rows.append(r)
	var first := League.sort_table(rows)
	var shuffled := rows.duplicate()
	shuffled.reverse()
	var second := League.sort_table(shuffled)
	var same := true
	for i in first.size():
		if int(first[i]["club"]) != int(second[i]["club"]):
			same = false
	_ok(same, "the table is stable", "six clubs level on everything sort identically either way")


# -------------------------------------------------------------- the seasons
func _test_divisions_never_leak() -> void:
	## The one that actually needs a hundred seasons. Every division must hold
	## its size for the life of a save.
	var world := LeagueWorld.new(4242, 44)
	var bad := ""
	for s in SEASONS:
		while not world.season_complete():
			world.play_event()
		world.roll_over()
		for t in League.TIERS.size():
			var n := world.clubs_in(t).size()
			if n != League.club_count(t):
				bad = "season %d: %s holds %d clubs, should hold %d" % [
					s + 1, League.TIERS[t]["short"], n, League.club_count(t)]
				break
		if bad != "":
			break
	_ok(bad == "", "divisions never leak",
		"every division held its size for %d seasons" % SEASONS if bad == "" else bad)


func _test_determinism() -> void:
	## Godot's Array.shuffle() draws on the GLOBAL RNG, not on ours. Using it in
	## the fixture draw made the whole world unreproducible from its seed — and
	## a save that cannot be replayed is a save that cannot be debugged.
	var a := _run_world(777)
	var b := _run_world(777)
	var c := _run_world(778)
	_ok(a == b and a != c, "the world is reproducible from its seed",
		"same seed replays identically, a different seed does not")


## The fingerprint has to be the whole world, not just where the player
## ended up. The first version returned tier/season/power — and the
## player's power never moves in this run, so two different seeds that
## happened to leave him in the same division produced an identical
## string and the test reported a determinism failure that was really
## just a three-character hash. Every club, every division, every point.
func _run_world(seed_value: int) -> String:
	var world := LeagueWorld.new(seed_value, 44)
	for s in 12:
		while not world.season_complete():
			world.play_event()
		world.roll_over()
	var out := "s%d " % world.season
	for t in League.TIERS.size():
		for row in world.table(t):
			out += "%d:%d:%d:%d:%d|" % [t, int(row["club"]), int(row["points"]),
				League.margin_diff(row), League.round_diff(row)]
	for c in world.clubs:
		out += "%d=%d," % [int(c["id"]), int(c["power"])]
	return out


func _test_the_climb_is_possible() -> void:
	## A club that keeps improving must be able to walk from the Backyard
	## Circuit to the National Division. If it cannot, the pyramid is scenery.
	var world := LeagueWorld.new(9001, 40)
	var reached := 0
	var seasons_taken := 0
	for s in 30:
		while not world.season_complete():
			world.play_event()
		world.roll_over()
		## The roster improves the way a real one does — slowly, and only if the
		## club is being run well. Six points a season is a good decade.
		world.set_player_power(mini(90, int(world.clubs[world.player_club]["power"]) + 6))
		reached = maxi(reached, world.player_tier())
		if reached == League.TIERS.size() - 1 and seasons_taken == 0:
			seasons_taken = s + 1
	notes.append("a steadily improving club reached %s in %d seasons" % [
		League.tier_name(reached), seasons_taken])
	_ok(reached == League.TIERS.size() - 1, "the climb is possible",
		"reached %s" % League.tier_name(reached))


func _test_the_climb_is_earned() -> void:
	## And a club that does NOT improve must not drift upward on luck alone.
	## Promotion has to mean something or the pyramid is a timer.
	var top := 0
	var ended_at: Array = []
	for i in 24:
		var world := LeagueWorld.new(31000 + i, 40)
		for s in 30:
			while not world.season_complete():
				world.play_event()
			world.roll_over()
		ended_at.append(world.player_tier())
		top = maxi(top, world.player_tier())
	var avg := 0.0
	for t in ended_at:
		avg += float(t)
	avg /= float(ended_at.size())
	notes.append("a club that never improves finishes at tier %.1f after 30 seasons (0 = Backyard)" % avg)
	_ok(avg < 1.0, "the climb is earned",
		"a static 40-power club averages tier %.1f, and never got past %s" % [
			avg, League.tier_name(top)])


func _test_the_simmed_result_is_not_a_coin_flip() -> void:
	## `quick_bout` RESOLVES FOURTEEN OF EVERY FIFTEEN FIXTURES and had no test
	## of its own.
	##
	## Everything the league believes about who is good comes out of this one
	## function, and the only thing behind it was the climb tests — downstream,
	## slow, and one of them a single seed. Its own comment records that the Elo
	## sign was once INVERTED, so a 40-power club floated to the National
	## Division; that is exactly what a direct check catches in a second.
	##
	## THE FIRST VERSION OF THIS CHECK ASKED THE WRONG QUESTION. It measured
	## 80 v 45 and expected "decisive but not certain" — and got 99.2%, which is
	## correct: `RATING_SCALE` is 22, so a 35-point gap is four Elo doublings and
	## a foregone conclusion. But 80 v 45 is not a league fixture. Divisions are
	## 16 to 22 points wide, so the widest gap two clubs in one table can have is
	## about a band, and THAT is the number the season is made of.
	var w := LeagueWorld.new(31337)
	var N := 1200

	var even_a := 0
	var decided := 0
	for i in N:
		var r: Array = w.quick_bout(60, 60)
		if int(r[0]) == int(r[1]):
			continue
		decided += 1
		if int(r[0]) > int(r[1]):
			even_a += 1
	var even_rate := 100.0 * float(even_a) / float(maxi(1, decided))

	## Top of the Backyard band against the bottom of it — the widest mismatch
	## the fixture list can actually produce.
	var band: Array = League.TIERS[0]["power"]
	var top_wins := 0
	var margin_band := 0
	var margin_even := 0
	for i in N:
		var r: Array = w.quick_bout(int(band[1]), int(band[0]))
		if int(r[0]) > int(r[1]):
			top_wins += 1
		margin_band += int(r[2]) - int(r[3])
		var e: Array = w.quick_bout(60, 60)
		margin_even += absi(int(e[2]) - int(e[3]))
	var band_rate := 100.0 * float(top_wins) / float(N)

	## And a gap no division allows, to pin the direction. If the sign ever
	## flips again this is the check that screams.
	var cross := 0
	for i in N:
		var r: Array = w.quick_bout(80, 45)
		if int(r[0]) > int(r[1]):
			cross += 1
	var cross_rate := 100.0 * float(cross) / float(N)

	var gap_margin := float(margin_band) / float(N)
	var even_margin := float(margin_even) / float(N)
	notes.append("quick_bout, %d each: even 60v60 -> %.1f%% (50 +/- 5); %d v %d, the Backyard band -> %.1f%%; 80v45 -> %.1f%%"
		% [N, even_rate, int(band[1]), int(band[0]), band_rate, cross_rate])
	notes.append("  mean margin: across a band %+.2f, even %.2f either way"
		% [gap_margin, even_margin])

	var fair: bool = absf(even_rate - 50.0) <= 5.0
	## A season needs the better club to usually win and sometimes not. Across a
	## whole division that is high — but it must leave room for an upset, or the
	## table is decided in August.
	var decisive: bool = band_rate >= 70.0 and band_rate <= 96.0
	var directed: bool = cross_rate >= 95.0
	var margins_move: bool = gap_margin > even_margin
	_ok(fair and decisive and directed and margins_move,
		"the simmed result is not a coin flip",
		"even sides split evenly, a division's width is decisive but not certain, a gap no division allows is, and margins widen with the gap")


func _test_a_title_counts_once() -> void:
	## A CLUB'S "N TITLES" IS ITS SEEDED PAST PLUS EVERY CUP IT HAS WON, ONCE
	## (bake-off #2, 8 Oct 2026, both assistants). The National playoff is a cup
	## and `_record_honors` credits it; the roll-over credited the top flight's
	## champion a second time, so every National title counted twice on the team
	## card. Checked over twelve seasons on every club that is not a guest.
	var world := LeagueWorld.new(7311, 44)
	var start: Dictionary = {}
	for c in world.clubs:
		if int(c["tier"]) >= 0:
			start[int(c["id"])] = int(c["titles"])
	var national := 0
	for s in 12:
		while not world.season_complete():
			world.play_event()
		world.roll_over()
	var won: Dictionary = {}
	for h in world.honors:
		var cid := int(h.get("champion", -1))
		if start.has(cid) and String(h.get("champion_name", "")) == String(world.clubs[cid]["name"]):
			won[cid] = int(won.get(cid, 0)) + 1
			if String(h.get("id", "")) == "playoff:%d" % (League.TIERS.size() - 1):
				national += 1
	var off: Array = []
	for cid in start:
		var want: int = int(start[cid]) + int(won.get(cid, 0))
		if int(world.clubs[cid]["titles"]) != want:
			off.append("%s %d≠%d" % [String(world.clubs[cid]["short"]), int(world.clubs[cid]["titles"]), want])
	_ok(off.is_empty() and national > 0, "a title counts once",
		"%d National playoffs decided; clubs off: %s" % [national, ", ".join(off) if not off.is_empty() else "none"])
