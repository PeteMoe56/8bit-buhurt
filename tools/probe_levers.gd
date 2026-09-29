extends SceneTree
## ONE LEVER AT A TIME (from the 29 Sep 4 AM audit's own tool, kept).
##
##   bash tools/bb.sh probe levers <seeds> <years> <base> <variant>...
##
## Careers at the default grade on the ProbeManager, with one lever removed or
## one experiment switched on. Variants: base, nomarket, nostaff, nolevels,
## noline, nosession, dilemma1, and morning decision #11's options:
## fullsession, half, quarter (price x0.5 / x0.25), fullhalf, fullquarter.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var seeds := int(a[0]); var years := int(a[1]); var base := int(a[2])
	for vi in range(3, a.size()):
		var v := String(a[vi])
		Tuning.session_full_week = v == "fullsession" or v.begins_with("fullhalf") or v == "fullquarter"
		Tuning.session_price_scale = 0.5 if v.ends_with("half") else (0.25 if v.ends_with("quarter") else 1.0)
		var titles := []; var reach := []; var endp := 0.0; var cr := 0.0; var lt := 0
		for i in seeds:
			var s := Season.new(MeleeRosters.starting_club(), base + i * 7919)
			Session.season = s
			var m := ProbeManager.new()
			var title := years + 1; var r3 := years + 1
			for y in years:
				_winter(m, s, v)
				_season(m, s, v)
				var t := s.world.player_tier()
				if t >= 3 and r3 > years: r3 = y + 1
				if t >= 3 and s.world.player_position() == 1:
					lt += 1
					if title > years: title = y + 1
				s.roll_over()
			titles.append(title); reach.append(r3); endp += s.club.power(); cr += s.office.credits
		titles.sort(); reach.sort()
		print("V=%-9s n=%d titleMed=%d reachTopMed=%d titles=%s leagueTitles=%.2f endPower=%.1f endCredits=%.0f" % [
			v, seeds, titles[seeds / 2], reach[seeds / 2], str(titles), float(lt) / seeds, endp / seeds, cr / seeds])
	quit(0)


func _winter(m: ProbeManager, s: Season, v: String) -> void:
	for f in s.club.roster:
		if Contracts.can_extend(f): s.extend(f)
		else: s.resign(f)
	if v != "nomarket":
		m.market(s, false)
	if v != "nostaff":
		m.staff(s)
	if v != "nolevels":
		for f in s.club.roster: ProbeManager.place_all(f)
	if v != "noline":
		s.club.best_line()


func _season(m: ProbeManager, s: Season, v: String) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(1 if v == "dilemma1" else 0)
				"cup": s.sim_cup_tie()
				"promotion":
					var terms: Dictionary = s.promotion_terms()
					s.answer_promotion(s.office.credits >= int(terms["dues_up"]) + 12)
		if s.season_complete():
			break
		var o := s.office
		if v != "nokit":
			var men: Array = s.club.roster.duplicate()
			men.sort_custom(func(a, b): return a.armor < b.armor)
			for f in men:
				if o.credits < 3: break
				o.repair_kit(f)
		if v != "noarena" and o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
			o.tidy_arena()
		if not o.compliant():
			for r in Federation.rules():
				if o.rule_level(r) < Federation.required(o.tier, r):
					o.raise_rule(r); break
		var keep := o.upkeep_bill() + League.dues_for(o.tier) + ProbeManager.KITTY
		if v != "noarena" and o.credits > keep + o.arena.next_cost():
			o.build_arena()
		if v != "nocap" and o.credits > keep + ProbeManager.LEVEL_FLOAT + o.cap_cost():
			o.raise_cap()
		if v != "nosession" and o.credits > keep + ProbeManager.KITTY:
			s.run_session()
		if v != "noceiling" and o.credits > keep + ProbeManager.KITTY:
			var young: Array = s.club.roster.duplicate()
			young.sort_custom(func(a, b): return a.age < b.age)
			for f in young:
				if o.credits <= keep + ProbeManager.KITTY: break
				o.raise_ceiling(f)
		s.skip_event()
