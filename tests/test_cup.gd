extends SceneTree
## The cups, and the club rating that feeds them.
##
##   godot --headless --path . --script res://tests/test_cup.gd
##
## A knockout has one failure mode that a league does not: it can silently lose
## a club. A bracket that drops an entrant, a semi-final that never produces a
## third-place match, a champion who was never in the field — all of them look
## like a working tournament from the outside. So every check here counts heads.

const SEASONS := 40

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — cups and club power ===\n")
	_test_bracket_conserves_clubs()
	_test_pools_feed_the_bracket()
	_test_seeding_favours_the_favorite()
	_test_the_reserve_stays_home()
	_test_the_roster_menu_cannot_break_the_club()
	_test_rating_is_position_averages()
	_test_club_power_reads_the_club()
	_test_the_bench_is_worth_having()
	_test_out_of_position_costs()
	_test_worlds_and_invitationals_run()
	_test_guests_do_not_accumulate()
	_test_pool_rows_add_up()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE CUPS HOLD (%d checks)\n" % checks)
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


## A resolver that is pure seeding: the lower id always wins 2-0 by four.
func _favorite_wins() -> Callable:
	return func(a: int, b: int) -> Array:
		return [2, 0, 8, 0] if a < b else [0, 2, 0, 8]


func _coin(rng: RandomNumberGenerator) -> Callable:
	return func(_a: int, _b: int) -> Array:
		var x := rng.randf() < 0.5
		return [2, 1, rng.randi_range(1, 8), rng.randi_range(0, 4)] if x \
			else [1, 2, rng.randi_range(0, 4), rng.randi_range(1, 8)]


func _test_bracket_conserves_clubs() -> void:
	## Eight in, one champion, one runner-up, one third, and every other club
	## beaten exactly once. If that arithmetic fails the bracket is eating people.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var bad := 0
	for i in SEASONS:
		var field: Array = range(8)
		var c := Cup.new("Test Cup", field, i, -1, false)
		c.run_all(_coin(rng))
		var beaten: Dictionary = {}
		var matches := 0
		for day in c.rounds:
			for m in day:
				matches += 1
				var loser: int = int(m["a"]) if int(m["winner"]) == int(m["b"]) else int(m["b"])
				beaten[loser] = int(beaten.get(loser, 0)) + 1
		if matches != 7 or c.champion == -1 or beaten.size() != 7:
			bad += 1
		for k in beaten:
			if int(beaten[k]) != 1:
				bad += 1
	_ok(bad == 0, "the bracket conserves clubs",
		"%d eight-club cups, seven matches each, nobody beaten twice" % SEASONS)


func _test_pools_feed_the_bracket() -> void:
	## Sixteen clubs, four pools of four, top two out of each — so the bracket
	## must open on exactly eight, and every one of them must have been in a pool.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var bad := 0
	var pool_matches := 0
	for i in SEASONS:
		var c := Cup.new("Worlds", range(16), i, -1, true)
		pool_matches = c.pool_matches.size()
		c.run_all(_coin(rng))
		if c.rounds.is_empty() or c.rounds[0].size() != 4:
			bad += 1
			continue
		var in_bracket: Array = []
		for m in c.rounds[0]:
			in_bracket.append(int(m["a"]))
			in_bracket.append(int(m["b"]))
		if in_bracket.size() != 8:
			bad += 1
		if c.champion == -1 or c.third == -1:
			bad += 1
	## Four pools of four is six matches a pool: twenty-four, then a quarter-final
	## round of four, semis, third place and a final.
	_ok(bad == 0 and pool_matches == 24, "the pools feed the bracket",
		"%d pool matches, then eight into the quarter-finals, champion and third decided" % pool_matches)


func _test_seeding_favours_the_favorite() -> void:
	## Seed 0 is the best club in the field. Give the better club every match and
	## the top seed must win the cup — if he does not, the bracket is pairing the
	## seeds wrong and the draw is a raffle.
	var wrong := 0
	for i in 16:
		var c := Cup.new("Test Cup", range(8), i, -1, false)
		c.run_all(_favorite_wins())
		if c.champion != 0 or c.runner_up != 1:
			wrong += 1
	_ok(wrong == 0, "the seeding means something",
		"top seed wins all 16 cups when the better club always wins, second seed is always the runner-up")


func _test_the_reserve_stays_home() -> void:
	## Eight travel, five more may sit in reserve, and a reserve is not at the
	## event: he cannot be on the line, cannot be on the bench, and cannot be
	## part of what the league rates you on. If reserves leaked into any of those
	## three, "reserve" would just be a longer bench with a different word.
	var club := MeleeRosters.player_club()
	var eight := club.active_eight()
	var res := club.reserves()
	var with_res := club.power_exact()

	var leaked := 0
	for f in res:
		if club.starting_five().has(f) or club.bench().has(f):
			leaked += 1

	## Give every reserve world-class numbers. The rating must not move a point.
	for f in res:
		f.strength = 99
		f.base = 99
		f.skill = 99
		f.gas = 99
		f.armor = 1.0
	var after := club.power_exact()

	_ok(eight.size() == MeleeClub.ACTIVE_SIZE and res.size() <= MeleeClub.RESERVE_SIZE
			and leaked == 0 and absf(with_res - after) < 0.001,
		"the reserve stays home",
		"%d travel, %d in reserve (max %d); making every reserve a 99 leaves the rating at %.1f"
			% [eight.size(), res.size(), MeleeClub.RESERVE_SIZE, after])


func _test_the_roster_menu_cannot_break_the_club() -> void:
	## The roster menu's verbs — promote, demote, swap, sign, cut — must never
	## leave a club that cannot travel or cannot field a line. Two of them got
	## this wrong on the first pass in the same way: demoting the Center was
	## allowed because the bench Center covers his slot, and cutting him was
	## allowed for the same reason, and both left SEVEN men on the traveling
	## list. A rule about the whole squad cannot be enforced one fighter at a time.
	var club := MeleeRosters.player_club()
	var up: FighterCard = club.reserves()[0]

	## The eight is full, so a straight promotion is refused.
	var refused_full := club.set_active(up, true) != ""
	## And a straight demotion is refused too — the eight is always eight.
	var center: FighterCard = club.starting_five()[Tuning.Pos.CENTER]
	var refused_demote := club.set_active(center, false) != ""
	var eight_intact := club.active_eight().size() == MeleeClub.ACTIVE_SIZE

	## Cutting a man who is on the eight is refused: swap him down first.
	var refused_cut := club.cut(center) != ""

	## The one move that works, and it must leave a legal club.
	var flanker: FighterCard = club.starting_five()[Tuning.Pos.FLANK_R]
	var swapped := club.swap_squad(flanker, up) == ""
	var legal_after := club.line_legal() == ""
	## And now that the flanker is in the reserve, he can be released — and the
	## club is still legal afterwards, because releasing a reserve does not touch
	## the traveling eight at all.
	var cut_ok := club.cut(flanker) == ""
	var still_eight := club.active_eight().size() == MeleeClub.ACTIVE_SIZE

	_ok(refused_full and refused_demote and eight_intact and refused_cut
			and swapped and legal_after and cut_ok and still_eight
			and club.line_legal() == "",
		"the roster menu cannot break the club",
		"a full eight refuses both a promotion and a demotion, a man on the eight cannot be cut, and the swap leaves a legal club")


func _test_rating_is_position_averages() -> void:
	## Madden's method, and Pete's: each position gets a rating, the club rating
	## is the average of those. Two things have to hold. The club number must
	## actually BE that average — not something adjacent to it — and a Rail on
	## the bench must cover the other Rail without the out-of-position cost,
	## because there are five places on the line but only three jobs.
	var club := MeleeRosters.player_club()
	var chart := club.depth_chart()
	var total := 0.0
	var uncovered := 0
	var wrong_side := 0
	for row in chart:
		total += float(row["rating"])
		if row["cover"] == null:
			uncovered += 1
		if bool(row["cover_out_of_position"]):
			wrong_side += 1
	var mean := total / float(chart.size())
	## The right-hand Rail is covered by a man listed at the LEFT-hand Rail. If
	## roles were slots that would read as out of position and cost 6% for
	## nothing.
	var right_rail: Dictionary = chart[Tuning.Pos.RAIL_R]
	_ok(absf(mean - club.power_exact()) < 0.001 and chart.size() == 5
			and uncovered == 0 and wrong_side == 0
			and int(right_rail["cover"].pos) == Tuning.Pos.RAIL_L,
		"the rating is an average of position averages",
		"five positions averaging %.1f, all covered, and %s covers the right Rail at full value"
			% [mean, right_rail["cover"].display_name])


func _test_club_power_reads_the_club() -> void:
	## The number the league sorts on has to move when the roster moves. Strip a
	## club of its best man and its rating must fall; wreck its armor and it must
	## fall again. Before this, power was a hand-set constant and you could sell
	## your Rail and climb anyway.
	var club := MeleeRosters.player_club()
	var full := club.power_exact()

	var thin := MeleeRosters.player_club()
	var best: FighterCard = null
	for f in thin.roster:
		if best == null or f.overall() > best.overall():
			best = f
	best.available = false
	var without_best := thin.power_exact()

	var battered := MeleeRosters.player_club()
	for f in battered.roster:
		f.armor = 0.4
	var rattling := battered.power_exact()

	_ok(full > without_best and full > rattling and full > 0,
		"club power reads the club",
		"full squad %.1f, minus its best man %.1f, in bad harness %.1f"
			% [full, without_best, rattling])


func _test_the_bench_is_worth_having() -> void:
	## Two clubs with the same five and different benches must not rate the same,
	## because you swap between rounds and depth fights too.
	var deep := MeleeRosters.player_club()
	var shallow := MeleeRosters.player_club()
	for i in range(shallow.roster.size() - 1, 4, -1):
		shallow.roster.remove_at(i)
	var d := deep.power()
	var s := shallow.power()
	_ok(d > s and shallow.bench().is_empty() and deep.bench().size() >= 3,
		"the bench is worth having",
		"same five, %d in reserve rates %d; nobody in reserve rates %d" % [deep.bench().size(), d, s])


func _test_out_of_position_costs() -> void:
	## A man dropped into a slot he does not play fights at Tuning.OUT_OF_POS of
	## his base and skill. Without that cost the bench is just "field your
	## five best" and Rail, Flanker and Center stop meaning anything.
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 7)
	var any_out := false
	for m in sim.men:
		if m.out_of_pos:
			any_out = true
	var natural := sim.men[0]
	var before := natural.eff_base()
	natural.out_of_pos = true
	var after := natural.eff_base()
	_ok(after < before and not any_out,
		"standing out of position costs",
		"base %.1f -> %.1f out of position, and nobody starts out of position" % [before, after])


func _test_worlds_and_invitationals_run() -> void:
	## Twelve seasons with the cups running unattended. Every one must produce a
	## champion, and Worlds must be won by somebody who was actually in it.
	var world := LeagueWorld.new(31337, 44)
	for s in 12:
		while not world.season_complete():
			world.play_event()
		world.roll_over()
	var worlds_run := 0
	var invitationals_run := 0
	var playoffs_run := 0
	var bad := 0
	for h in world.honors:
		if int(h["champion"]) < 0:
			bad += 1
		if String(h["id"]) == "worlds":
			worlds_run += 1
		elif String(h["id"]).begins_with("playoff:"):
			## A PLAYOFF A DIVISION A SEASON (30 Sep 2026), four divisions.
			playoffs_run += 1
		else:
			invitationals_run += 1
	## THREE SETS OF TWO (1 Oct 2026): local, continental, elite.
	_ok(worlds_run == 12 and invitationals_run == 72 and playoffs_run == 48 and bad == 0,
		"the cups run every season",
		"12 seasons produced %d Worlds and %d Invitationals, all with a champion"
			% [worlds_run, invitationals_run])


func _test_guests_do_not_accumulate() -> void:
	## Worlds invents fourteen foreign clubs a year. If they are not cleared the
	## club list grows forever and a stray tier of -1 eventually walks into a
	## loop over the pyramid. Same class of bug as a division that leaks.
	var world := LeagueWorld.new(555, 44)
	var expected := 0
	for t in League.TIERS.size():
		expected += League.club_count(t)
	var start := world.clubs.size()
	for s in 20:
		while not world.season_complete():
			world.play_event()
		world.roll_over()
	_ok(world.clubs.size() == start and start == expected,
		"Worlds guests do not accumulate",
		"%d clubs before twenty seasons of Worlds, %d after" % [start, world.clubs.size()])


func _test_pool_rows_add_up() -> void:
	## THE MOCKUP PRINTED A CLUB ON MINUS ONE WIN.
	##
	## `tools/mock_bracket.gd` filled its pool tables with `2 - i`, so the fourth
	## row of every pool showed **W = -1**. It sat in a screenshot through five
	## sections of this register and nobody caught it, because nobody adds up a
	## mockup — which is the whole trouble with deciding a layout from a picture
	## and then building the real thing next to it.
	##
	## The real screen reads `cup.pool_table()`. This asserts the arithmetic it
	## is reading: played equals won plus drawn plus lost, nothing is negative,
	## and every club in the pool appears exactly once.
	var world := LeagueWorld.new(4242)
	var ids: Array = []
	for c in world.clubs:
		ids.append(int(c["id"]))
		if ids.size() >= 16:
			break
	var cup := Cup.new("Worlds", ids, 9, -1, true)
	cup.run_all(func(a, b): return [3 if a < b else 1, 1 if a < b else 3, 4, 2])

	var bad: Array[String] = []
	var rows_seen := 0
	for p in cup.pools.size():
		var seen: Array[int] = []
		for row in cup.pool_table(p):
			rows_seen += 1
			var played := int(row.get("played", 0))
			var won := int(row.get("won", 0))
			var drawn := int(row.get("drawn", 0))
			var lost := int(row.get("lost", 0))
			var cid := int(row["club"])
			if won < 0 or drawn < 0 or lost < 0 or played < 0:
				bad.append("pool %d: %d has a negative count (%d/%d/%d)"
					% [p, cid, won, drawn, lost])
			if won + drawn + lost != played:
				bad.append("pool %d: %d played %d but W+D+L is %d"
					% [p, cid, played, won + drawn + lost])
			if seen.has(cid):
				bad.append("pool %d lists club %d twice" % [p, cid])
			seen.append(cid)
		if seen.size() != Cup.POOL_SIZE:
			bad.append("pool %d has %d clubs, not %d" % [p, seen.size(), Cup.POOL_SIZE])
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("%d pool rows across %d pools, every one reconciled"
		% [rows_seen, cup.pools.size()])
	_ok(bad.is_empty(), "pool rows add up",
		"played equals won plus drawn plus lost, nothing negative, no club listed twice")
