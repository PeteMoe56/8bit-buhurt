extends SceneTree
## THE THINGS THAT MUST ALWAYS BE TRUE, checked after every matchday of many long
## careers. No rule here is about balance; each is about the world being a world:
##
##   tables     every division's table adds up: rounds for = rounds against,
##              wins = losses, points = the result counts, all clubs played alike
##   pyramid    every club in one division exactly once, divisions keep their size
##   squad      five or more men, no man on two books, every stat in its range
##   money      credits, fans and morale are finite numbers
##   save       a save taken at any point loads into the same world, and the
##              career goes on from the loaded copy (so a divergence compounds)
##
## Careers alternate the two probe managers and fight a share of bouts in the
## real sim rather than simming them, so both doors into the table are walked.
##
##   godot --headless --path . --script res://tests/test_invariants.gd -- [careers] [seasons]
##
## RB_TIER: fast runs 2 careers x 6 seasons; balance and by hand run 6 x 25.

var TIER := OS.get_environment("RB_TIER")
var failures: Array[String] = []
var checks: int = 0
var rng := RandomNumberGenerator.new()
var sizes: Dictionary = {}
var saves := 0
var fought := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var careers: int = 2 if TIER == "fast" else 6
	var seasons: int = 6 if TIER == "fast" else 25
	if args.size() > 0:
		careers = int(args[0])
	if args.size() > 1:
		seasons = int(args[1])
	print("\n=== 8-Bit Buhurt — invariants: %d careers x %d seasons ===\n" % [careers, seasons])
	rng.seed = 2026
	for c in careers:
		_career(1000 + c * 7919, seasons, c % 2 == 1)
		if failures.size() > 20:
			break
	print("")
	print("   %d checks, %d saves round-tripped, %d bouts fought in the sim" % [checks, saves, fought])
	print("")
	if failures.is_empty():
		print("THE INVARIANTS HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 30):
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _bad(where: String, what: String) -> void:
	if failures.size() < 200:
		failures.append("%s: %s" % [where, what])


func _career(seed_v: int, seasons: int, youth: bool) -> void:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var m := ProbeManager.new()
	m.youth = youth
	sizes.clear()
	for t in League.TIERS.size():
		sizes[t] = s.world.clubs_in(t).size()
	for y in seasons:
		m.winter(s)
		_check(s, "seed %d s%d winter" % [seed_v, s.world.season])
		var guard := 0
		while guard < 80:
			guard += 1
			_drain(s)
			if s.season_complete():
				break
			if not s.office.compliant():
				for r in Federation.rules():
					if s.office.rule_level(r) < Federation.required(s.office.tier, r):
						s.office.raise_rule(r)
						break
			## A short line between matchdays is honest (a knock in the week), but
			## the fixture itself must never be played by a club rated zero.
			s.ensure_a_line()
			if s.club.power() <= 0 or int(s.world.clubs[s.world.player_club]["power"]) != s.club.power():
				_bad("seed %d s%d e%d" % [seed_v, s.world.season, s.world.event],
					"walks out rated %d (squad %d, world has %d)" % [s.club.power(),
						s.club.roster.size(), int(s.world.clubs[s.world.player_club]["power"])])
			if rng.randf() < 0.25:
				var sim := s.begin_bout()
				if sim == null:
					s.skip_event()
				else:
					sim.run_to_end()
					s.post_bout(sim)
					Session.clear_bout()
					fought += 1
			else:
				s.skip_event()
			var where := "seed %d s%d e%d" % [seed_v, s.world.season, s.world.event]
			_check(s, where)
			if rng.randf() < 0.08:
				var back := _round_trip(s, where)
				if back != null:
					s = back
					Session.season = s
		_drain(s)
		s.roll_over()
		_check(s, "seed %d after summer into s%d" % [seed_v, s.world.season])
		var back2 := _round_trip(s, "seed %d summer s%d" % [seed_v, s.world.season])
		if back2 != null:
			s = back2
			Session.season = s
	print("  career %d (%s): %d seasons, tier %s, power %d, %d CC" % [seed_v,
		"youth" if youth else "plain", seasons, s.tier_name(), s.club.power(), s.office.credits])


func _drain(s: Season) -> void:
	var q := 0
	while q < 12 and s.blocked_by() != "":
		q += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(rng.randi_range(0, 1))
			"cup": s.sim_cup_tie()
			## No ground, no promotion (#13, 29 Sep): a "yes" can be refused, and
			## the refusal leaves the question open. A player then declines (or
			## builds — test_climb holds that road), so a refused yes is a no.
			"promotion":
				if s.answer_promotion(rng.randf() < 0.7) != "":
					s.answer_promotion(false)
			var other:
				_bad("queue", "unknown blocker '%s'" % other)
				return
	if s.blocked_by() != "":
		_bad("queue", "still blocked by '%s' after 12 answers" % s.blocked_by())


func _round_trip(s: Season, where: String) -> Season:
	checks += 1
	saves += 1
	var d := SaveGame.to_dict(s)
	var a := var_to_str(d)
	var back := SaveGame.from_dict(str_to_var(a))
	if back == null:
		_bad(where, "save did not load back")
		return null
	var diff: Array[String] = []
	_diff(str_to_var(a), SaveGame.to_dict(back), "", diff)
	diff = diff.filter(func(x): return not x.begins_with(".saved "))
	if not diff.is_empty():
		_bad(where, "save round trip differs at " + ", ".join(diff.slice(0, 6)))
		return null
	return back


## Order-blind deep comparison: a Dictionary is the same if it has the same keys
## with the same values, whatever order it was built in.
func _diff(a, b, path: String, out: Array[String]) -> void:
	if out.size() >= 6:
		return
	if typeof(a) != typeof(b):
		if (a is int or a is float) and (b is int or b is float) and float(a) == float(b):
			return
		out.append("%s (%s vs %s)" % [path, type_string(typeof(a)), type_string(typeof(b))])
		return
	if a is Dictionary:
		for k in a:
			if not b.has(k):
				out.append("%s.%s missing after load" % [path, str(k)])
			else:
				_diff(a[k], b[k], "%s.%s" % [path, str(k)], out)
		for k in b:
			if not a.has(k):
				out.append("%s.%s appeared after load" % [path, str(k)])
	elif a is Array:
		if a.size() != b.size():
			out.append("%s size %d vs %d" % [path, a.size(), b.size()])
			return
		for i in a.size():
			_diff(a[i], b[i], "%s[%d]" % [path, i], out)
	elif a is float:
		if not is_equal_approx(a, b) and not (is_nan(a) and is_nan(b)):
			out.append("%s %s vs %s" % [path, str(a), str(b)])
	elif a != b:
		out.append("%s %s vs %s" % [path, str(a).left(40), str(b).left(40)])


func _finite(x: float) -> bool:
	return not is_nan(x) and not is_inf(x)


func _check(s: Season, where: String) -> void:
	checks += 1
	var w := s.world
	## Pyramid.
	var seen := {}
	for i in w.clubs.size():
		var c: Dictionary = w.clubs[i]
		if int(c["id"]) != i:
			_bad(where, "club at %d has id %d" % [i, int(c["id"])])
		var t := int(c["tier"])
		if t >= 0:
			seen[t] = int(seen.get(t, 0)) + 1
		if not _finite(float(c.get("power", 0))) or int(c.get("power", 0)) < 0 \
				or (int(c.get("power", 0)) == 0 and i != w.player_club):
			_bad(where, "club %d power %s" % [i, str(c.get("power"))])
	for t in sizes:
		if int(seen.get(t, 0)) != int(sizes[t]):
			_bad(where, "division %d holds %d clubs, began with %d" % [t, int(seen.get(t, 0)), sizes[t]])
	## Tables.
	for t in w.tables:
		var tbl: Dictionary = w.tables[t]
		var ids := w.clubs_in(t)
		if tbl.size() != ids.size():
			_bad(where, "division %d table has %d rows for %d clubs" % [t, tbl.size(), ids.size()])
		var rf := 0
		var ra := 0
		var mf := 0
		var ma := 0
		var won := 0
		var lost := 0
		var lo := 1 << 30
		var hi := -1
		for cid in tbl:
			var r: Dictionary = tbl[cid]
			if int(w.clubs[int(cid)]["tier"]) != int(t):
				_bad(where, "club %d sits in division %d's table but plays in %d" % [cid, t, int(w.clubs[int(cid)]["tier"])])
			var p := int(r["played"])
			if p != int(r["won"]) + int(r["drawn"]) + int(r["lost"]):
				_bad(where, "club %d played %d but W+D+L is %d" % [cid, p, int(r["won"]) + int(r["drawn"]) + int(r["lost"])])
			var pts := int(r["won"]) * League.WIN_POINTS + int(r["drawn"]) * League.DRAW_POINTS \
				+ int(r["lost"]) * League.LOSS_POINTS
			if pts != int(r["points"]):
				_bad(where, "club %d has %d points, results make %d" % [cid, int(r["points"]), pts])
			rf += int(r["rf"])
			ra += int(r["ra"])
			mf += int(r["mf"])
			ma += int(r["ma"])
			won += int(r["won"])
			lost += int(r["lost"])
			lo = mini(lo, p)
			hi = maxi(hi, p)
		if rf != ra or mf != ma or won != lost:
			_bad(where, "division %d does not balance: rounds %d/%d margins %d/%d W/L %d/%d"
				% [t, rf, ra, mf, ma, won, lost])
		if hi - lo > 1:
			_bad(where, "division %d: one club has played %d, another %d" % [t, hi, lo])
	## Squad.
	var roster := s.club.roster
	if roster.size() < MeleeClub.LINE_SIZE:
		_bad(where, "squad of %d" % roster.size())
	var mine := {}
	for f in roster:
		mine[f.get_instance_id()] = true
		_man(f, where)
	for cid in s.splinter_rosters:
		for f in s.splinter_rosters[cid]:
			if mine.has(f.get_instance_id()):
				_bad(where, "%s is on your books and on breakaway %d's" % [f.display_name, cid])
	for f in s.market():
		if mine.has(f.get_instance_id()):
			_bad(where, "%s is on your books and in the market" % f.display_name)
	## Money.
	var o := s.office
	if not _finite(o.fans) or o.fans < 0.0:
		_bad(where, "fans %s" % str(o.fans))
	if not _finite(o.morale) or o.morale < 0.0 or o.morale > 1.0:
		_bad(where, "club morale %s" % str(o.morale))
	if o.credits < -1000 or o.credits > 10_000_000:
		_bad(where, "credits %d" % o.credits)


func _man(f: FighterCard, where: String) -> void:
	var who := "%s (%s)" % [f.display_name, where]
	for k in ["strength", "base", "skill", "gas", "aggression", "potential"]:
		var v := int(f.get(k))
		if v < 1 or v > 99:
			_bad(who, "%s is %d" % [k, v])
	if not _finite(f.morale) or f.morale < 0.0 or f.morale > 1.0:
		_bad(who, "morale %s" % str(f.morale))
	if not _finite(f.armor) or f.armor < 0.0 or f.armor > 1.0:
		_bad(who, "armor %s" % str(f.armor))
	if f.age < 16 or f.age > 60:
		_bad(who, "age %d" % f.age)
	if f.injury < 0 or f.years < 0 or f.level < 1 or f.xp < 0:
		_bad(who, "injury %d years %d level %d xp %d" % [f.injury, f.years, f.level, f.xp])
