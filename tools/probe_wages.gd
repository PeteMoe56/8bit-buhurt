extends SceneTree
## WHERE THE WAGE BILL SITS AGAINST THE CAP (29 Sep 2026, decision #13).
##
##   bash tools/bb.sh probe wages <careers> <years> <base>
##
## ProbeManager careers at the default grade. For each division: the median wage
## bill, the cap, the bill as a share of the unraised division cap, and the most
## expensive man on the market that year against the room left under the cap.
## If the bill sits far below the cap, the cap is decoration.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 8
	var years: int = int(a[1]) if a.size() > 1 else 20
	var base: int = int(a[2]) if a.size() > 2 else 4242
	var by_tier := {}
	var inc := {}
	for i in n:
		var s := Season.new(MeleeRosters.starting_club(), base + i * 7919)
		Session.season = s
		var m := ProbeManager.new()
		for y in years:
			m.winter(s)
			var t := s.world.player_tier()
			var bill := ClubOffice.wage_bill(s.club)
			var top := 0
			for f in s.market():
				top = maxi(top, ClubOffice.wage(f))
			if not by_tier.has(t):
				by_tier[t] = []
			by_tier[t].append([bill, s.office.cap(), int(ClubOffice.TIER_CAP[t]), top])
			m.season(s)
			if not inc.has(t):
				inc[t] = {"_n": 0, "_lvl": 0}
			inc[t]["_n"] += 1
			inc[t]["_lvl"] += s.office.arena.level
			for k in s.office.books_in:
				inc[t][k] = int(inc[t].get(k, 0)) + int(s.office.books_in[k])
			s.roll_over()
	for t in by_tier.keys():
		var rows: Array = by_tier[t]
		var bills: Array = []
		var shares: Array = []
		for r in rows:
			bills.append(r[0]); shares.append(float(r[0]) / float(r[2]))
		bills.sort(); shares.sort()
		print("tier %d  n=%3d  bill median %6d  p90 %6d  unraised cap %7d  bill/cap median %.2f p90 %.2f  top market wage (last) %d"
			% [t, rows.size(), bills[bills.size() / 2], bills[int(bills.size() * 0.9)],
				int(ClubOffice.TIER_CAP[t]), shares[shares.size() / 2], shares[int(shares.size() * 0.9)], int(rows[-1][3])])
	for t in inc.keys():
		var d: Dictionary = inc[t]
		var n2 := float(d["_n"])
		var parts: Array[String] = []
		var total := 0.0
		for k in d:
			if not String(k).begins_with("_"):
				total += float(d[k])
		for k in d:
			if not String(k).begins_with("_"):
				parts.append("%s %.0f (%.0f%%)" % [k, float(d[k]) / n2, 100.0 * float(d[k]) / maxf(1.0, total)])
		print("tier %d income/season %.0f  arena lvl %.1f  | %s" % [t, total / n2, float(d["_lvl"]) / n2, ", ".join(parts)])
	quit()
