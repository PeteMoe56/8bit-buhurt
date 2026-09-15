extends SceneTree
## WHAT DOES A CLUB'S FIRST SEASON ACTUALLY PAY, LINE BY LINE?
##
##   godot --headless --path . --script res://tools/probe_year1.gd
##
## `probe_afford.gd` says the steady state is healthy — a settled Backyard club
## keeps three quarters of its income for growth — and that YEAR ONE is not:
## 22.7 CC in, against about 14 of maintenance and 12 of levels the squad has
## earned. A club that is four credits underwater in its first season and told
## the answer is to buy things is a club whose player says what Pete said.
##
## An average will not fix that, because it is not a magnitude problem, it is a
## shape problem: which LINE is missing in year one and present in year five.
## So this prints the books.
const SEEDS: Array[int] = [4242, 90210, 31337, 777, 12345]
const YEARS := 5


func _initialize() -> void:
	print("\n=== a Backyard club's books, season by season ===\n")
	var totals: Array[Dictionary] = []
	for y in YEARS:
		totals.append({})
	var forced: Array[float] = []
	var earned: Array[float] = []
	for y in YEARS:
		forced.append(0.0)
		earned.append(0.0)
	for seed_v in SEEDS:
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		Session.season = s
		for y in YEARS:
			var guard := 0
			while not s.ready_to_roll() and guard < 80:
				guard += 1
				if s.bid_open():
					s.decline_bid()
				elif s.cup_pending():
					s.sim_cup_tie()
				else:
					s.skip_event()
			forced[y] += float(_forced(s))
			earned[y] += float(_earned(s))
			s.roll_over()
			var got: Dictionary = (s.office.books_last as Dictionary).get("in", {})
			for k in got.keys():
				totals[y][k] = float(totals[y].get(k, 0.0)) + float(got[k])
	var n := float(SEEDS.size())
	var lines: Array[String] = []
	for y in YEARS:
		for k in totals[y].keys():
			if not lines.has(String(k)):
				lines.append(String(k))
	print("%-22s %s" % ["line", " ".join(_head())])
	for k in lines:
		var row: Array[String] = []
		for y in YEARS:
			row.append("%8.1f" % (float(totals[y].get(k, 0.0)) / n))
		print("%-22s %s" % [k, " ".join(row)])
	var inc: Array[String] = []
	var bill: Array[String] = []
	var net: Array[String] = []
	for y in YEARS:
		var t := 0.0
		for k in totals[y].keys():
			t += float(totals[y][k]) / n
		inc.append("%8.1f" % t)
		var b := (forced[y] + earned[y]) / n
		bill.append("%8.1f" % b)
		net.append("%8.1f" % (t - b))
	print("")
	print("%-22s %s" % ["IN", " ".join(inc)])
	print("%-22s %s" % ["maintenance + levels", " ".join(bill)])
	print("%-22s %s" % ["LEFT FOR GROWTH", " ".join(net)])
	print("")
	quit(0)


func _head() -> Array[String]:
	var out: Array[String] = []
	for y in YEARS:
		out.append("%8s" % ("S%d" % (y + 1)))
	return out


func _forced(s: Season) -> int:
	var o: ClubOffice = s.office
	var bill := o.upkeep_bill()
	for c in s.club.roster:
		if not Quartermaster.topped_out(c):
			bill += ClubOffice.kit_cost(c)
	if o.arena.condition < 0.999 and o.arena.level >= Arena.WEARS_FROM_LEVEL:
		bill += o.arena.upkeep_cost()
	return bill


func _earned(s: Season) -> int:
	var bill := 0
	for c in s.club.roster:
		if Career.can_level(c) and not Career.at_ceiling(c):
			bill += Career.level_cost(c)
	return bill
