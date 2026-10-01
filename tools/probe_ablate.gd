extends SceneTree
## WHAT IS EACH SYSTEM ACTUALLY WORTH?
##
##   godot --headless --path . --script res://tools/probe_ablate.gd
##
## Pete, 14 Sep 2026: *"what exactly all are you testing here, because there's
## still trainings, facilities upgrades, coaching levels and focuses, and
## whatever else we have that can help a team win."*
##
## `tools/soak.gd` answers "does a career work". It cannot answer THIS, and the
## way it fails to is instructive: every time a lever was added to its manager
## the twenty-season result moved, so the walk kept reporting the policy rather
## than the game. Three policies side by side helped and did not fix it.
##
## An ablation does. Run the SAME club, the SAME seed and the SAME policy twenty
## seasons over, once with everything on and then once with each system switched
## off on its own, and the difference is what that system is worth. Nothing is
## being tuned and nothing is being judged — each row is one subtraction.
##
## Read it as: **a big negative number means turning that system off hurts, so
## the system is doing work. A number near zero means it is not.**
const SEASONS := 20

enum L { COACHING, REGIME, FORMATION, QUEUE, STAFF_DEALS, MORALE, MARKET, FACILITIES, TRAVEL }
const L_NAME := {
	## THE ONE THE FIRST LEVER LIST LEFT OUT, and it is the biggest thing in the
	## game. `STAFF_DEALS` ablates EXTENDING a captain's deal, which is nearly the
	## same club as re-hiring one — so every condition in the first table had
	## captains and "coaching" never appeared in it at all. HAVING them is the
	## variable; keeping the same two is a rounding error on it.
	##
	## `tools/probe_fair.gd` measured it directly — two identical clubs, sixty
	## bouts: uncoached against uncoached is 53%, coached against a Backyard-coached
	## CPU is 85%, coached against a National-coached CPU is 37%. A FORTY-EIGHT
	## POINT swing on one control, next to which everything the first ablation
	## ranked was inside the noise because it genuinely is.
	L.COACHING: "captains at all",
	L.REGIME: "training regimes",
	L.FORMATION: "picking a formation",
	L.QUEUE: "answering the card",
	L.STAFF_DEALS: "extending captains",
	L.MORALE: "morale nights",
	L.MARKET: "signing anybody",
	L.FACILITIES: "training + infirmary",
	L.TRAVEL: "travel slots",
}

var off: int = -1


func _on(l: int) -> bool:
	return off != l


func _run(seed_v: int = 31337) -> Array:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	var promotions := 0
	var won := 0
	var fought := 0
	var tier_was := s.world.player_tier()
	for year in SEASONS:
		for f in s.club.roster:
			if f.years <= 0:
				s.resign(f)
			elif f.years == 1 and Contracts.can_extend(f):
				s.extend(f)
		if _on(L.STAFF_DEALS):
			for i in s.office.captains.size():
				s.office.extend_captain(i)
		for pass_ in 3:
			s.office.new_week()
			if _on(L.TRAVEL) and s.office.travel_slots < ClubOffice.TRAVEL_MAX \
					and s.office.buy_travel_slot() == "":
				continue
			s.office.new_week()
			if _on(L.FACILITIES) and s.office.upgrade(ClubOffice.Facility.TRAINING) == "":
				continue
			s.office.new_week()
			if _on(L.FACILITIES) and s.office.upgrade(ClubOffice.Facility.INFIRMARY) == "":
				continue
			s.office.new_week()
			if s.office.build_arena() == "":
				continue
			break
		while _on(L.COACHING) and s.office.captains.size() < ClubOffice.MAX_CAPTAINS:
			var hired := false
			for slot in 3:
				var c := ClubOffice.offer(seed_v, s.world.season, slot, 0)
				if not c.is_empty() and ClubOffice.cost_of(c) <= s.office.credits \
						and s.hire_captain(c) == "":
					hired = true
					break
			if not hired:
				break
		if _on(L.REGIME):
			var fit := 0
			for f in s.club.roster:
				if f.fit():
					fit += 1
			var want: int = ClubOffice.Regime.LIGHT if fit <= MeleeClub.LINE_SIZE + 2 \
				else ClubOffice.Regime.NORMAL
			for i in s.office.captains.size():
				s.office.set_regime(i, want)
		if _on(L.MORALE) and s.office.morale < 0.45:
			s.boost_morale()
		if _on(L.FORMATION):
			var shapes: Array = Tuning.FORMATIONS.keys()
			s.formation_id = int(shapes[s.world.season % shapes.size()])
		if _on(L.MARKET):
			for f in s.market():
				if s.market_fee(f) <= s.office.credits and s.sign_from_market(f) == "":
					break
		var g := 0
		while s.club.active_eight().size() < s.club.party_size() and g < 20:
			g += 1
			var up: FighterCard = null
			for f in s.club.reserves():
				if up == null or f.overall() > up.overall():
					up = f
			if up == null or s.club.set_active(up, true) != "":
				break
		s.sync_power()

		var guard := 0
		while not s.season_complete() and guard < 40:
			guard += 1
			if _on(L.QUEUE):
				var q := 0
				while q < 8:
					q += 1
					match s.blocked_by():
						"bid":
							var took := false
							for i in s.bid_offers.size():
								if s.take_bid(i, 0) == "":
									took = true
									break
							if not took:
								s.decline_bid()
						"sendoff": s.answer_send_off()
						"dilemma":
							var card := s.dilemma_card()
							var opts: Array = card.get("options", [])
							var pick := 0
							for i in opts.size():
								if int((opts[i] as Dictionary).get("fx", {}).get("cc", 0)) >= 0:
									pick = i
									break
							s.answer_dilemma(pick)
						_:
							q = 99
			var sim := s.begin_bout()
			if sim == null:
				s.skip_event()
				continue
			Session.season = s
			Session.bout = sim
			sim.run_to_end()
			fought += 1
			if sim.bout_winner() == 0:
				won += 1
			s.post_bout(sim)
			Session.clear_bout()
			var t := 0
			while s.pending_cup() != null and t < 8:
				t += 1
				s.sim_cup_tie()
		s.roll_over()
		if s.world.player_tier() > tier_was:
			promotions += 1
		tier_was = s.world.player_tier()

	var fit2 := 0
	var armor := 0.0
	var n := 0
	for f in s.club.roster:
		if f.fit():
			fit2 += 1
	for f in s.club.active_eight():
		armor += f.armor
		n += 1
	## THE OUTCOME IS WINS, not the final power reading.
	##
	## The first pass measured club power after twenty seasons and everything —
	## every system, averaged over five seeds — came out inside the noise. Some of
	## that is the systems; a lot of it is the MEASUREMENT. Power at season twenty
	## is ONE number read once at the end of a noisy process, while a career
	## contains a hundred bouts, and Pete's question was *"whatever else we have
	## that can help a team WIN."* So count the wins: a hundred samples per career
	## instead of one, which is worth about a factor of ten in noise on its own.
	return [won, promotions, fought, s.office.credits,
		0.0 if n == 0 else armor / float(n), s.club.power()]


func _init() -> void:
	print("\n=== what each system is worth: twenty seasons, one thing off at a time ===\n")
	## THE NOISE FLOOR FIRST, and it is the difference between a finding and a
	## coincidence. One career is one sample of a system with a dozen random
	## streams in it; if the same settings swing eight points between seeds then
	## a four-point ablation result is nothing at all. *A note beside a number is
	## not a check on it* — and neither is a number with no error bar.
	off = -1
	var spread: Array[int] = []
	for sv in [31337, 4242, 90210, 1618, 27182]:
		var r := _run(sv)
		spread.append(int(round(100.0 * float(r[0]) / float(maxi(1, int(r[2]))))))
	var lo := spread[0]
	var hi := spread[0]
	var sum := 0
	for v in spread:
		lo = mini(lo, v)
		hi = maxi(hi, v)
		sum += v
	print("  the noise floor: the SAME settings across five seeds won %s of their bouts"
		% str(spread))
	print("  — mean %.1f%%, spread %d points. Any ablation inside that is not a finding.\n"
		% [float(sum) / float(spread.size()), hi - lo])
	## AND EVERY CONDITION IS THE MEAN OF THOSE SAME FIVE SEEDS, for exactly the
	## reason the line above gives. The first version of this tool ran ONE career
	## per condition and produced an eight-row table in which every single row —
	## including the biggest — sat inside that ten-point spread. It read like a
	## finding and it was a coin.
	## AND EVERY ROW IS A PAIRED DIFFERENCE, for the reason `_paired` gives: the
	## world is most of the variance and pairing cancels it.
	print("%-28s %8s  %14s  %s" % ["", "mean", "worst..best", "verdict"])
	var rows: Array = []
	for l in L_NAME:
		rows.append([String(L_NAME[l]), _paired(int(l))])
	rows.sort_custom(func(a, b): return float(a[1][0]) < float(b[1][0]))
	for row in rows:
		var r: Array = row[1]
		var mean: float = float(r[0])
		## THE SIGN TEST, and it is the only honest one at five samples: an effect
		## that is real points the same way in every world it is measured in. One
		## that changes sign between seeds is a coin however big its average is.
		var same_way: bool = (float(r[1]) > 0.0 and float(r[2]) > 0.0) \
			or (float(r[1]) < 0.0 and float(r[2]) < 0.0)
		var verdict := "inside the noise"
		if same_way and mean <= -1.0:
			verdict = "DOES REAL WORK — every world agrees"
		elif same_way and mean >= 1.0:
			verdict = "COSTS YOU — every world agrees"
		elif not same_way:
			verdict = "changes sign between worlds"
		print("without %-20s %+7.1f  %+6.1f..%+6.1f  %s"
			% [String(row[0]), mean, float(r[1]), float(r[2]), verdict])
	print("")
	quit()


## PAIRED, which is the whole method.
##
## Comparing `mean(without X)` against `mean(with everything)` across five seeds
## gives the right center and a useless error bar, because most of the variance
## is not the system at all — it is the WORLD. Five seeds are five different
## countries with five different sets of rivals, and they win between 12% and 26%
## of their bouts with identical settings. A three-point effect cannot be seen
## through a fourteen-point spread.
##
## So each seed is its own experiment: run it with the system and without it, and
## take the DIFFERENCE. The world cancels — same rivals, same fixtures, same
## generated men on both sides of the subtraction — and what is left is the
## system. The mean of the differences is the same number as the difference of
## the means; the SPREAD of the differences is the thing that gets smaller, and
## the spread is what decides whether a row means anything.
func _paired(which: int) -> Array:
	var deltas: Array[float] = []
	for sv in [31337, 4242, 90210, 1618, 27182]:
		off = -1
		var a := _run(sv)
		off = which
		var b := _run(sv)
		var wa := 100.0 * float(a[0]) / float(maxi(1, int(a[2])))
		var wb := 100.0 * float(b[0]) / float(maxi(1, int(b[2])))
		deltas.append(wb - wa)
	var t := 0.0
	var lo := deltas[0]
	var hi := deltas[0]
	for d in deltas:
		t += d
		lo = minf(lo, d)
		hi = maxf(hi, d)
	return [t / float(deltas.size()), lo, hi, deltas]
