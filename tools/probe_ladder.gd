extends SceneTree
## WHY DOES NOBODY GO UP?
##
##   godot --headless --path . --script res://tools/probe_ladder.gd
##
## `tools/probe_run.gd` played a hundred career-seasons with a manager who does
## every obvious thing and finished with ONE promotion in five twenty-year
## careers. That is not a difficulty curve, it is a ladder with no rungs, and it
## is the mechanical version of Pete's *"you'll decline"*.
##
## An average cannot say why. This prints the year-by-year: what the club is
## rated, what the division leader is rated, where it finished, what it earned
## and what it managed to buy — so the sentence that comes out of it names a
## cause rather than a symptom.
const YEARS := 14


func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	print("\n=== one career, year by year ===\n")
	print("%3s %5s %5s %5s %4s %6s %6s %6s %6s %5s" % [
		"yr", "tier", "mine", "top", "pos", "income", "spent", "levels", "bank", "men"])
	for y in YEARS:
		var bought := _winter(s)
		bought += _season(s)
		var pos := s.position()
		var tier := s.world.player_tier()
		var mine := int(s.world.clubs[s.world.player_club]["power"])
		var tbl: Array = s.world.table(tier)
		var top := 0 if tbl.is_empty() else int(s.world.clubs[int(tbl[0]["club"])]["power"])
		s.roll_over()
		var last: Dictionary = s.office.books_last
		print("%3d %5d %5d %5d %4d %6d %6d %6d %6d %5s" % [
			y + 1, tier, mine, top, pos,
			ClubOffice.book_total(last.get("in", {})),
			ClubOffice.book_total(last.get("out", {})),
			bought, s.office.credits,
			"%d" % s.club.roster.size()])
	print("")
	## AND WHAT ONE LEVEL IS ACTUALLY WORTH, which is the question the table
	## above is really asking. Club power is a mean across the squad, so a point
	## on one man is a point divided by however many men are counted.
	var before := s.club.power()
	var f: FighterCard = s.club.roster[0]
	Career.level_up(f)
	s.sync_power()
	print("one level on one man moved club power %d -> %d" % [before, s.club.power()])
	print("the squad is %d men; the division drifts +/-3 a year around its band mid"
		% s.club.roster.size())
	print("")
	quit(0)


func _winter(s: Season) -> int:
	var n := 0
	for f in s.club.roster:
		if Contracts.can_extend(f):
			s.extend(f)
		else:
			s.resign(f)
	var guard2 := 0
	while guard2 < 6:
		guard2 += 1
		var pool: Array = s.market()
		if pool.is_empty():
			print("   (market empty)")
			break
		pool.sort_custom(func(a, b): return a.overall() > b.overall())
		var five: Array = s.club.starting_five()
		var lo := 999
		for c in five:
			lo = mini(lo, c.overall())
		var took := false
		for f in pool:
			var why := ""
			if s.office.credits <= s.office.upkeep_bill() + 8 + s.market_fee(f):
				why = "money (%d vs %d+%d)" % [s.office.credits,
					s.office.upkeep_bill() + 8, s.market_fee(f)]
			elif s.club.roster.size() >= 13 and f.overall() <= lo + 1:
				why = "not better (%d vs %d)" % [f.overall(), lo]
			else:
				why = s.sign_from_market(f)
				if why == "":
					print("   signed %s %d/%d for %d CC" % [f.display_name,
						f.overall(), f.potential, s.market_fee(f)])
					if s.club.roster.size() > 13:
						var worst: FighterCard = null
						for c in s.club.roster:
							if worst == null or c.overall() < worst.overall():
								worst = c
						if worst != null:
							s.release(worst)
					took = true
					break
			if f == pool[0]:
				print("   top man %d/%d: %s" % [f.overall(), f.potential, why])
		if not took:
			break
	for f in s.club.roster:
		n += _place_all(f)
		for _i in 3:
			if s.office.buy_level(f) != "":
				break
			n += _place_all(f)
	return n


static func _place_all(f: FighterCard) -> int:
	var n := 0
	var guard := 0
	while Career.can_level(f) and not Career.at_ceiling(f) and guard < 6:
		guard += 1
		Career.level_up(f)
		n += 1
	return n


func _season(s: Season) -> int:
	var n := 0
	var guard := 0
	while not s.season_complete() and guard < 60:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(0)
				"sendoff": s.answer_send_off()
				"cup": s.sim_cup_tie()
		if s.season_complete():
			break
		var o := s.office
		var men: Array = s.club.roster.duplicate()
		men.sort_custom(func(a, b): return a.armor < b.armor)
		for f in men:
			if o.credits < 3:
				break
			o.repair_kit(f)
		for f in s.club.roster:
			n += _place_all(f)
		var keep := o.upkeep_bill() + 8
		var by_cost: Array = s.club.roster.duplicate()
		by_cost.sort_custom(func(a, b): return Career.level_cost(a) < Career.level_cost(b))
		for f in by_cost:
			if o.credits <= keep:
				break
			if o.buy_level(f) == "":
				n += _place_all(f)
		if o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
			o.tidy_arena()
		if o.credits > keep + o.arena.next_cost():
			o.build_arena()
		if o.credits > keep + o.cap_cost():
			o.raise_cap()
		s.skip_event()
	return n
