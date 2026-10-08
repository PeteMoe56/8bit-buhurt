extends SceneTree
## Paired report-faithful LOW careers; changes purchase order, never game prices.
## -- 5 20 [BASE ...] --out=res://docs/bakeoff-2/harness/full
## No bases => 9001 5150 2718 6060 8123. --dry-run requires 1 seed, <=2 years.
## --dry-run also checks arms 0/1 against the unmodified shared manager.
## Manager season body is pinned/copied because it exposes no purchase-order hook.
## Everything else (winter, market, stat choice, report scope) remains inherited.
const MANAGER_SHA := "f9ebff76677b0f93b7e8c41203fa6a13b136c077ca15bf56cde158a0ece21d48"
const ARMS := ["no_harness", "harness_first", "development_first"]
const BASES := [9001, 5150, 2718, 6060, 8123]
var failed := false

class Ledger extends RefCounted:
	var target: WeakRef
	var file: FileAccess
	var arm := ""
	var base := 0
	var seed_v := 0
	var elapsed := 0
	var seq := 0
	var context := ""
	var ids := {}
	var next_id := 0
	var cash_in := 0
	var cash_out := 0
	var earned_xp := 0
	var failures: Array[String] = []
	var counts := {}
	var costs := {}

	func card(f: FighterCard) -> Dictionary:
		var key := f.get_instance_id()
		if not ids.has(key):
			next_id += 1
			ids[key] = next_id
		return {"id": ids[key], "name": f.display_name, "number": f.number,
			"xp": f.xp, "level": f.level, "strength": f.strength, "base": f.base,
			"skill": f.skill, "gas": f.gas, "potential": f.potential,
			"age": f.age, "active": f.active, "injury": f.injury,
			"grade": Quartermaster.grade_of(f), "condition": f.armor}

	func snapshot() -> Dictionary:
		var s: Season = target.get_ref()
		var roster := {}
		for f in s.club.roster:
			var c := card(f)
			roster[str(c["id"])] = c
		return {"cc": s.office.credits, "power": s.club.power(),
			"tier": s.world.player_tier(), "world_season": s.world.season,
			"week": s.world.week, "roster": roster,
			"armorer": s.office.armorer.duplicate(true)}

	func emit(kind: String, data: Dictionary) -> void:
		if file == null:
			return
		seq += 1
		var s: Season = target.get_ref()
		var row := {"seq": seq, "arm": arm, "base": base, "seed": seed_v,
			"elapsed_season": elapsed, "world_season": s.world.season,
			"week": s.world.week, "kind": kind, "context": context}
		row.merge(data)
		file.store_line(JSON.stringify(row))

	func delta(before: Dictionary, after: Dictionary, mode: String = "") -> Dictionary:
		var changed: Array = []
		var earned := 0
		var spent := 0
		var levels := 0
		var stat_delta := 0
		var arrived_xp := 0
		var departed_xp := 0
		var old: Dictionary = before["roster"]
		var now: Dictionary = after["roster"]
		for id in old:
			if not now.has(id):
				departed_xp += int(old[id]["xp"])
				changed.append({"departure": old[id]})
		for id in now:
			if not old.has(id):
				arrived_xp += int(now[id]["xp"])
				changed.append({"arrival": now[id]})
				continue
			var a: Dictionary = old[id]
			var b: Dictionary = now[id]
			var dx := int(b["xp"]) - int(a["xp"])
			if mode == "earned":
				earned += maxi(0, dx)
				if dx < 0:
					failures.append("XP unexpectedly decreased during earning action")
			elif mode == "spent" or mode == "cashed":
				spent += maxi(0, -dx)
				levels += int(b["level"]) - int(a["level"])
			for st in ["strength", "base", "skill", "gas"]:
				stat_delta += int(b[st]) - int(a[st])
			if a != b:
				changed.append({"before": a, "after": b})
		return {"cc_before": before["cc"], "cc_after": after["cc"],
			"power_before": before["power"], "power_after": after["power"],
			"changed_men": changed, "xp_earned": earned,
			"xp_spent_levels": spent if mode == "spent" else 0,
			"xp_cashed": spent if mode == "cashed" else 0,
			"levels_spent": levels if mode == "spent" else 0,
			"levels_cashed": levels if mode == "cashed" else 0,
			"raw_stat_delta_retained": stat_delta,
			"arrived_xp": arrived_xp, "departed_xp": departed_xp}

	func action(name_: String, callback: Callable, extra: Dictionary = {}, mode: String = "") -> Variant:
		var before := snapshot()
		var parent := context
		context = name_
		var transaction_start := seq
		var earned_before := earned_xp
		var result: Variant = callback.call()
		var row := delta(before, snapshot(), mode)
		# Parent calendar steps may call a traced cup tie. Credit nested earning
		# only once; retain the inclusive value for auditing the hierarchy.
		if mode == "earned":
			row["xp_earned_including_children"] = row["xp_earned"]
			row["xp_earned"] = int(row["xp_earned"]) - (earned_xp - earned_before)
			if int(row["xp_earned"]) < 0:
				failures.append("Nested earning did not reconcile")
			earned_xp += int(row["xp_earned"])
		row.merge(extra)
		var success: bool = result == "" if result is String else true
		row.merge({"action": name_, "called": true, "completed": success,
			"result": result, "transaction_seq_after": transaction_start,
			"transaction_seq_through": seq})
		var c: Dictionary = counts.get(name_, {"attempted": 0, "completed": 0})
		c["attempted"] += 1
		c["completed"] += 1 if success else 0
		counts[name_] = c
		emit("action", row)
		context = parent
		return result

	func skipped(name_: String, reason: String, extra: Dictionary = {}) -> void:
		var s: Season = target.get_ref()
		var row := {"action": name_, "called": false, "completed": false,
			"reason": reason, "cc_before": s.office.credits, "cc_after": s.office.credits}
		row.merge(extra)
		emit("decision", row)

class TraceOffice extends ClubOffice:
	var audit: Ledger
	func take(cc: int, what: String, when_: String = "", line: String = "") -> int:
		var before := credits
		var got := super.take(cc, what, when_, line)
		if audit != null:
			audit.cash_in += credits - before
			audit.emit("transaction", {"direction": "in", "line": line,
				"what": what, "requested_cc": cc, "cc": credits - before,
				"cc_before": before, "cc_after": credits})
		return got
	func spend(cc: int, line: String) -> int:
		var before := credits
		var got := super.spend(cc, line)
		if audit != null:
			audit.cash_out += before - credits
			var category := "armorer_wage" if line == LINE_KIT and audit.context == "upkeep" else audit.context
			audit.costs[category] = int(audit.costs.get(category, 0)) + before - credits
			audit.emit("transaction", {"direction": "out", "line": line,
				"category": category, "cc": before - credits, "cc_before": before, "cc_after": credits})
		return got
	func hire_armorer(a: Dictionary) -> String:
		return audit.action("armorer_hire", func(): return super.hire_armorer(a),
			{"candidate": a, "quoted_fee": Armorer.wage_of(a)})
	func buy_harness(f: FighterCard) -> String:
		return audit.action("harness_upgrade", func(): return super.buy_harness(f),
			{"fighter": audit.card(f), "quoted_cost": Quartermaster.upgrade_cost(f)})
	func raise_ceiling(f: FighterCard) -> String:
		return audit.action("ceiling_raise", func(): return super.raise_ceiling(f),
			{"fighter": audit.card(f), "quoted_cost": Career.raise_cost(f)})
	func repair_kit(f: FighterCard) -> String:
		return audit.action("repair", func(): return super.repair_kit(f), {"fighter": audit.card(f)})
	func raise_rule(r: int) -> String:
		return audit.action("compliance", func(): return super.raise_rule(r), {"rule": r})
	func build_arena() -> String:
		return audit.action("arena", func(): return super.build_arena())
	func raise_cap() -> String:
		return audit.action("cap", func(): return super.raise_cap())
	func tidy_arena() -> String:
		return audit.action("tidy_arena", func(): return super.tidy_arena())
	func refresh_market() -> String:
		return audit.action("market_refresh", func(): return super.refresh_market())
	func hire(c: Dictionary) -> String:
		return audit.action("captain_hire", func(): return super.hire(c), {"candidate": c})
	func pay_upkeep() -> Dictionary:
		var before := int(books_out.get(LINE_KIT, 0))
		var due := armorer_wage()
		var armorer_before := armorer.duplicate(true)
		var result: Dictionary = audit.action("upkeep", func(): return super.pay_upkeep())
		var paid := int(books_out.get(LINE_KIT, 0)) - before
		if paid != 0 and paid != due:
			audit.failures.append("Unexpected kit charge inside pay_upkeep")
		audit.emit("armorer_wage", {"armorer_before": armorer_before,
			"armorer_after": armorer.duplicate(true), "due_cc": due, "paid_cc": paid})
		return result

class TraceSeason extends Season:
	var audit: Ledger
	var cash_ready := {}
	func answer_dilemma(option_i: int) -> String:
		return audit.action("dilemma", func(): return super.answer_dilemma(option_i),
			{"option": option_i}, "earned")
	func answer_send_off() -> String:
		return audit.action("send_off", func(): return super.answer_send_off(), {}, "earned")
	func answer_promotion(take: bool) -> String:
		return audit.action("promotion_decision", func(): return super.answer_promotion(take), {"take": take})
	func decline_bid() -> void:
		audit.action("decline_bid", func(): super.decline_bid())
	func sign_from_market(f: FighterCard) -> String:
		return audit.action("signing", func(): return super.sign_from_market(f),
			{"candidate": audit.card(f), "quoted_fee": market_fee(f)})
	func release(f: FighterCard) -> String:
		return audit.action("release", func(): return super.release(f), {"fighter": audit.card(f)})
	func extend(f: FighterCard) -> String:
		return audit.action("extend_contract", func(): return super.extend(f), {"fighter": audit.card(f)})
	func resign(f: FighterCard) -> String:
		return audit.action("resign_contract", func(): return super.resign(f), {"fighter": audit.card(f)})
	func run_session() -> String:
		return audit.action("session", func(): return super.run_session(), {}, "earned")
	func skip_event() -> void:
		audit.action("calendar_step", func(): super.skip_event(), {}, "earned")
	func sim_cup_tie() -> void:
		audit.action("cup_tie", func(): super.sim_cup_tie(), {}, "earned")
	func _train() -> void:
		audit.action("winter_training_and_roster", func(): super._train())
		cash_ready = audit.snapshot()
		audit.emit("boundary", {"name": "after_training_before_cash_in", "state": cash_ready})
	func sync_power() -> void:
		# First sync after _train returns is immediately after the cash-in loop.
		# Capture before later contracts/splits can change the roster again.
		super.sync_power()
		if audit != null and not cash_ready.is_empty():
			var row := audit.delta(cash_ready, audit.snapshot(), "cashed")
			row["cash_in_cc"] = last_cashed
			audit.emit("cash_in", row)
			cash_ready = {}

class BudgetManager extends ProbeManager:
	var audit: Ledger
	var arm_index := 0
	func place(f: FighterCard) -> int:
		var before := audit.snapshot()
		var n := super.place(f)
		if n > 0:
			audit.emit("level_spend", audit.delta(before, audit.snapshot(), "spent"))
		return n
	func report_run(s: Season) -> void:
		var before := report_runs
		var parent := audit.context
		audit.context = "report_level_run"
		super.report_run(s)
		audit.emit("report", {"started": report_runs > before,
			"report_runs": report_runs, "lv_in_season": lv_in_season})
		audit.context = parent
	func _harness(s: Season, keep: int) -> void:
		var o := s.office
		if arm_index == 0:
			audit.skipped("harness_policy", "arm_disables_discretionary_harness", {"keep": keep})
			return
		if o.credits > keep:
			var best_a: Dictionary = {}
			for a in Armorer.pool(s.seed_value, s.world.season, String(o.armorer.get("name", ""))):
				var st := int(a.get("stars", 1))
				if st <= int(o.armorer.get("stars", 1)) or not Armorer.will_come(st, o.tier):
					continue
				if Armorer.wage_of(a) > o.credits - keep:
					audit.skipped("armorer_hire", "reserve", {"candidate": a, "keep": keep})
					continue
				if best_a.is_empty() or st > int(best_a.get("stars", 1)):
					best_a = a
			if not best_a.is_empty() and o.hire_armorer(best_a) == "":
				harness_cc += Armorer.wage_of(best_a)
		else:
			audit.skipped("armorer_hire", "reserve", {"keep": keep})
		if o.fixture_week:
			var five: Array = s.club.starting_five()
			five.sort_custom(func(a, b): return Quartermaster.grade_of(a) < Quartermaster.grade_of(b))
			for f in five:
				var c := Quartermaster.upgrade_cost(f)
				if c <= 0:
					continue
				if o.credits <= keep + c:
					audit.skipped("harness_upgrade", "reserve", {"fighter": audit.card(f), "keep": keep, "cost": c})
					continue
				if o.buy_harness(f) == "":
					harness_cc += c
				break
		else:
			audit.skipped("harness_upgrade", "not_fixture_week")
	func season(s: Season) -> void:
		var guard := 0
		while guard < 60:
			guard += 1
			var q := 0
			while q < 8 and s.blocked_by() != "":
				q += 1
				match s.blocked_by():
					"bid": s.decline_bid()
					"dilemma": s.answer_dilemma(0)
					"sendoff": s.answer_send_off()
					"cup":
						s.sim_cup_tie()
						report_run(s)
					"promotion":
						var terms: Dictionary = s.promotion_terms()
						s.answer_promotion(s.office.credits >= int(terms["dues_up"]) + 12)
			if s.season_complete():
				break
			var o := s.office
			var men: Array = s.club.roster.duplicate()
			men.sort_custom(func(a, b): return a.armor < b.armor)
			for f in men:
				if o.credits < 3:
					break
				o.repair_kit(f)
			if o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
				o.tidy_arena()
			if not o.compliant():
				for r in Federation.rules():
					if o.rule_level(r) < Federation.required(o.tier, r):
						o.raise_rule(r)
						break
			var keep := o.upkeep_bill() + League.dues_for(o.tier) + KITTY
			if o.credits > keep + o.arena.next_cost():
				o.build_arena()
			if o.credits > keep + LEVEL_FLOAT + o.cap_cost():
				o.raise_cap()
			if arm_index == 1:
				_harness(s, keep)
			if o.credits > keep + KITTY:
				s.run_session()
			else:
				audit.skipped("session", "reserve", {"keep": keep, "required_surplus": KITTY})
			if o.credits > keep + KITTY:
				var young: Array = s.club.roster.duplicate()
				young.sort_custom(func(a, b): return a.age < b.age)
				for f in young:
					if o.credits <= keep + KITTY:
						break
					if o.raise_ceiling(f) == "":
						raised += 1
			else:
				audit.skipped("ceiling_raise", "reserve", {"keep": keep, "required_surplus": KITTY})
			if arm_index != 1:
				_harness(s, keep)
			var league_week: bool = s.world.week_kind() == Calendar.Kind.LEAGUE
			if lv_report and not league_week:
				var wk := s.world.week
				var g2 := 0
				while s.cup_pending() and s.world.week == wk and g2 < 16:
					g2 += 1
					s.sim_cup_tie()
					report_run(s)
			s.skip_event()
			if lv_report and league_week:
				report_run(s)
			if lv_after_bout:
				for f in s.club.roster:
					lv_in_season += place(f)


func _initialize() -> void:
	call_deferred("_run")

func _hashes() -> Dictionary:
	var result := {}
	_scan("res://scripts", result)
	for path in ["res://tools/manager.gd", "res://tools/probe_harness_budget.gd", "res://project.godot"]:
		result[path] = _source_hash(path)
	return result

func _source_hash(path: String) -> String:
	# Git checkout line endings differ between Windows and Claude's Linux.
	return FileAccess.get_file_as_string(path).replace("\r\n", "\n").sha256_text()

func _scan(path: String, result: Dictionary) -> void:
	var dir := DirAccess.open(path)
	for sub in dir.get_directories():
		_scan(path + "/" + sub, result)
	for name_ in dir.get_files():
		if name_.ends_with(".gd"):
			var f := path + "/" + name_
			result[f] = _source_hash(f)

func _reference(seed_v: int, years: int, harness: bool) -> Dictionary:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var m := ProbeManager.new()
	m.buys_harness = harness
	for y in years:
		m.winter(s)
		m.season(s)
		s.roll_over()
	var result := SaveGame.to_dict(s)
	result.erase("saved") # Wall-clock save timestamp is not simulation state.
	m._s = null
	Session.season = null
	return result

func _instrument(s: TraceSeason, a: Ledger) -> void:
	a.target = weakref(s)
	s.audit = a
	var o := TraceOffice.new()
	# Preserve every base-script property, including constructor-set coach/tier.
	for p in s.office.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			o.set(String(p["name"]), s.office.get(String(p["name"])))
	s.office = o
	o.audit = a

func _button_checks(folder: String) -> Array:
	# Separate instrument checks, NOT career arms: fresh normal 8-CC clubs,
	# real buttons, no injected CC/XP/stats. Exercise successful/failed calls
	# whose weekly budget gates the short career may never reach.
	var checks: Array = []
	for kind in ["session", "ceiling_raise"]:
		var s := TraceSeason.new(MeleeRosters.starting_club(), 9001)
		Session.season = s
		var a := Ledger.new()
		a.arm = "button_check_" + kind
		a.seed_v = 9001
		a.base = 9001
		a.context = "instrument_validation_only"
		a.file = FileAccess.open(folder + "/" + a.arm + ".jsonl", FileAccess.WRITE)
		_instrument(s, a)
		a.emit("boundary", {"name": "check_start", "state": a.snapshot()})
		var first := ""
		var second := ""
		if kind == "session":
			first = s.run_session()
			second = s.run_session()
		else:
			var pick: FighterCard = null
			for f in s.club.roster:
				if Career.can_raise_ceiling(f) and Career.raise_cost(f) <= s.office.credits:
					if pick == null or Career.raise_cost(f) < Career.raise_cost(pick):
						pick = f
			if pick == null:
				first = "No affordable eligible fighter in normal starting club"
			else:
				first = s.office.raise_ceiling(pick)
				second = s.office.raise_ceiling(pick)
		var passed := first == "" and second != "" and s.office.credits == 8 + a.cash_in - a.cash_out
		checks.append({"check": kind, "passed": passed, "first_result": first,
			"repeat_result": second, "counts": a.counts, "injected_resources": false})
		a.emit("boundary", {"name": "check_end", "state": a.snapshot()})
		a.file.flush()
		a.file = null
		Session.season = null
	return checks

func _career(base: int, seed_v: int, years: int, arm: int, folder: String, summary: FileAccess, careers: FileAccess, dry: bool) -> Dictionary:
	var s := TraceSeason.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var a := Ledger.new()
	a.arm = ARMS[arm]
	a.base = base
	a.seed_v = seed_v
	a.file = FileAccess.open(folder + "/%s-%d.jsonl" % [a.arm, seed_v], FileAccess.WRITE)
	if a.file == null:
		return {"error": "Cannot open ledger"}
	_instrument(s, a)
	var o: TraceOffice = s.office
	var m := BudgetManager.new()
	m.audit = a
	m.arm_index = arm
	m.buys_harness = arm > 0
	var first_title := 0
	var initial_cc := o.credits
	a.emit("boundary", {"name": "career_start", "state": a.snapshot()})
	for y in years:
		a.elapsed = y + 1
		var opening_cc := o.credits
		var in0 := a.cash_in
		var out0 := a.cash_out
		a.context = "winter_manager"
		m.winter(s)
		a.context = "season_manager"
		m.season(s)
		if not s.season_complete():
			a.failures.append("Manager ended with unfinished season")
		var pre := a.snapshot()
		a.emit("boundary", {"name": "pre_rollover", "state": pre})
		if first_title == 0 and s.world.player_tier() == League.TIERS.size() - 1 and s.world.player_champion():
			first_title = y + 1
		a.context = "rollover"
		s.roll_over()
		var post := a.snapshot()
		a.emit("boundary", {"name": "post_rollover", "state": post,
			"books_last": o.books_last.duplicate(true), "winter": s.last_winter.duplicate(true)})
		var cin := a.cash_in - in0
		var cout := a.cash_out - out0
		var bin := 0
		var bout := 0
		for n in Dictionary(o.books_last.get("in", {})).values():
			bin += int(n)
		for n in Dictionary(o.books_last.get("out", {})).values():
			bout += int(n)
		if opening_cc + cin - cout != o.credits or cin != bin or cout != bout:
			a.failures.append("Cash/closed-books reconciliation failed")
		summary.store_line("%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d" % [
			a.arm, base, seed_v, y + 1, opening_cc, cin, cout, pre["cc"], post["cc"],
			pre["power"], post["power"], pre["tier"], post["tier"]])
	var saved := SaveGame.to_dict(s)
	saved.erase("saved")
	var parity := "not_run"
	if dry and arm < 2:
		parity = "pass" if saved == _reference(seed_v, years, arm == 1) else "FAIL"
		if parity != "pass":
			a.failures.append("Shared-manager parity failed")
	careers.store_line("%s\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s" % [
		a.arm, base, seed_v, years, str(first_title) if first_title > 0 else "",
		int(first_title == 0), initial_cc, a.cash_in, a.cash_out, o.credits,
		m.report_runs, m.lv_in_season, parity])
	a.emit("validation", {"failures": a.failures, "counts": a.counts,
		"shared_manager_parity": parity})
	a.file.flush()
	a.file = null
	m._s = null
	Session.season = null
	return {"arm": a.arm, "base": base, "seed": seed_v, "counts": a.counts,
		"rows": a.seq, "failures": a.failures, "shared_manager_parity": parity,
		"costs_cc": a.costs, "first_title_season": first_title,
		"right_censored": first_title == 0, "window": years,
		"final_cc": o.credits, "final_power": s.club.power()}

func _comparisons(folder: String, checks: Array) -> void:
	var categories := ["session", "ceiling_raise", "signing", "armorer_hire", "armorer_wage", "harness_upgrade", "repair"]
	var p := FileAccess.open(folder + "/paired.tsv", FileAccess.WRITE)
	var head: Array[String] = ["base", "seed", "reference", "treatment", "reference_first_title", "treatment_first_title", "reference_censored", "treatment_censored", "title_delta_both_observed_only", "final_cc_delta", "final_power_delta"]
	for c in categories:
		head.append(c + "_cc_delta")
	p.store_line("\t".join(head))
	for ref in checks:
		var ref_index := ARMS.find(ref.get("arm", ""))
		if ref_index < 0:
			continue
		for treatment in checks:
			if treatment.get("base", -1) != ref["base"] or treatment.get("seed", -1) != ref["seed"] or ARMS.find(treatment.get("arm", "")) <= ref_index:
				continue
			var row: Array[String] = [str(ref["base"]), str(ref["seed"]), ref["arm"], treatment["arm"],
				str(ref["first_title_season"]) if not ref["right_censored"] else "",
				str(treatment["first_title_season"]) if not treatment["right_censored"] else "",
				str(int(ref["right_censored"])), str(int(treatment["right_censored"])),
				str(int(treatment["first_title_season"]) - int(ref["first_title_season"])) if not ref["right_censored"] and not treatment["right_censored"] else "",
				str(int(treatment["final_cc"]) - int(ref["final_cc"])),
				str(int(treatment["final_power"]) - int(ref["final_power"]))]
			for c in categories:
				row.append(str(int(treatment["costs_cc"].get(c, 0)) - int(ref["costs_cc"].get(c, 0))))
			p.store_line("\t".join(row))
	var q := FileAccess.open(folder + "/attainment.tsv", FileAccess.WRITE)
	q.store_line("arm\tcareers\twindow\ttitles_observed\tright_censored\tattainment_fraction")
	for arm in ARMS:
		var n := 0
		var wins := 0
		var window := 0
		for r in checks:
			if r.get("arm", "") == arm:
				n += 1
				wins += 0 if r["right_censored"] else 1
				window = int(r["window"])
		q.store_line("%s\t%d\t%d\t%d\t%d\t%.6f" % [arm, n, window, wins, n - wins, float(wins) / maxi(1, n)])

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var positional: Array[String] = []
	var folder := "res://docs/bakeoff-2/harness/full"
	var dry := false
	for arg in args:
		if arg == "--dry-run":
			dry = true
		elif arg.begins_with("--out="):
			folder = arg.trim_prefix("--out=")
		else:
			positional.append(arg)
	var n := int(positional[0]) if positional.size() > 0 else 5
	var years := int(positional[1]) if positional.size() > 1 else 20
	var bases: Array = BASES.duplicate()
	if positional.size() > 2:
		bases.clear()
		for i in range(2, positional.size()):
			bases.append(int(positional[i]))
	if n < 1 or years < 1 or (dry and (n != 1 or years > 2)) or not folder.begins_with("res://docs/bakeoff-2/harness/"):
		push_error("Invalid size/dry-run/output arguments")
		quit(1)
		return
	if DirAccess.dir_exists_absolute(folder):
		push_error("Output directory already exists; choose a fresh --out path")
		quit(1)
		return
	if _source_hash("res://tools/manager.gd") != MANAGER_SHA:
		push_error("Shared manager changed: review pinned season copy before running")
		quit(1)
		return
	OS.set_environment("RB_LV", "low")
	OS.set_environment("RB_LV_REPORT", "1")
	OS.set_environment("RB_LV_BOUT", "0")
	OS.set_environment("RB_HARNESS", "0")
	DirAccess.make_dir_recursive_absolute(folder)
	var hashes := _hashes()
	var meta := {"diagnostic_only": dry, "seeds_per_base": n, "years": years,
		"bases": bases, "arms": ARMS, "seed_formula": "base + i * 7919",
		"engine": Engine.get_version_info(), "source_sha256": hashes,
		"source_hash_encoding": "UTF-8, CRLF normalized to LF",
		"policy": "manual LOW, report triggered active-eight gate, whole-roster scope",
		"rule_fixes_status": "Read accompanying run note; dry run is not balance evidence"}
	var seasons := FileAccess.open(folder + "/seasons.tsv", FileAccess.WRITE)
	var careers := FileAccess.open(folder + "/careers.tsv", FileAccess.WRITE)
	if seasons == null or careers == null:
		push_error("Cannot open summary files")
		quit(1)
		return
	seasons.store_line("arm\tbase\tseed\telapsed_season\topening_cc\tcc_in\tcc_out\tcc_pre_rollover\tcc_post_rollover\tpower_pre_rollover\tpower_post_rollover\ttier_pre_rollover\ttier_post_rollover")
	careers.store_line("arm\tbase\tseed\twindow\tfirst_title_season\tright_censored\tinitial_cc\tcc_in\tcc_out\tfinal_cc\treport_runs\tlevels_spent_in_season\tshared_manager_parity")
	var checks: Array = []
	if dry:
		meta["button_checks"] = _button_checks(folder)
		for c in meta["button_checks"]:
			if not bool(c["passed"]):
				failed = true
	for base in bases:
		for i in n:
			for arm in 3:
				if _hashes() != hashes:
					failed = true
					push_error("Source changed during run; discard partial experiment")
					break
				var r := _career(int(base), int(base) + i * 7919, years, arm, folder, seasons, careers, dry)
				checks.append(r)
				if r.has("error") or not Array(r.get("failures", [])).is_empty():
					failed = true
			if failed:
				break
		if failed:
			break
	if _hashes() != hashes:
		failed = true
	meta["checks"] = checks
	meta["validation_passed"] = not failed
	if not failed:
		_comparisons(folder, checks)
	var mf := FileAccess.open(folder + "/metadata.json", FileAccess.WRITE)
	mf.store_string(JSON.stringify(meta, "\t"))
	seasons.flush()
	careers.flush()
	print("HARNESS_BUDGET diagnostic_only=%s careers=%d validation_passed=%s" % [str(dry), checks.size(), str(not failed)])
	quit(1 if failed else 0)
