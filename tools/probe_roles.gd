extends SceneTree
## WHAT EACH ROLE DOES IN A FIGHT (10 Oct 2026, Pete: "centers are still the most
## effective bullrushers, but it's because of angles and fighters not paying
## attention. The flanker is actually the heaviest hitting. Rails can destroy
## people like a defensive lineman.")
##
##   bash tools/bb.sh probe roles <bouts> [power]
##
## Two generated clubs of the same rating, both run by the AI, a fresh pair of
## club ids every bout. Per role: bullrushes thrown and how they ended, men put
## down by any means, blows landed, weight and stats as generated.
var by_role := {}
var cur: MeleeSim = null


func _row(role: int) -> Dictionary:
	if not by_role.has(role):
		by_role[role] = {"br": 0, "br_down": 0, "br_bump": 0, "br_fell": 0, "blind": 0, "blind_down": 0,
			"hits": 0, "downs": 0, "men": 0, "lb": 0.0, "str": 0.0, "base": 0.0, "skl": 0.0, "gas": 0.0}
	return by_role[role]


func _on_br(a: int, t: int, kind: int, _dir: Vector2) -> void:
	var m = cur.men[a]
	var r := _row(Tuning.role_of(m.card.pos))
	r["br"] += 1
	r[["br_fell", "br_bump", "br_down"][kind]] += 1


func _on_act(idx: int, act: int, _target: int, success: bool) -> void:
	if act == Tuning.Act.HIT and success:
		_row(Tuning.role_of(cur.men[idx].card.pos))["hits"] += 1


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 100
	var power: int = int(a[1]) if a.size() > 1 else 60
	var bouts := 0
	for i in n:
		var ca := ClubFactory.build(1000 + 2 * i, "A", "A", power)
		var cb := ClubFactory.build(1001 + 2 * i, "B", "B", power)
		var sim := MeleeSim.new(ca, cb, hash("roles:%d" % i), 1.0)
		sim.strategies[0] = i % 4
		sim.strategies[1] = (i / 4) % 4
		sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
		cur = sim
		sim.bullrush_landed.connect(_on_br)
		sim.action_resolved.connect(_on_act)
		var k := 0
		while not sim.is_over() and k < 200000:
			k += 1
			sim.tick()
		for m in sim.men:
			var r := _row(Tuning.role_of(m.card.pos))
			r["downs"] += m.downs_caused
			r["men"] += 1
			r["lb"] += float(m.card.weight)
			r["str"] += float(m.card.strength)
			r["base"] += float(m.card.base)
			r["skl"] += float(m.card.skill)
			r["gas"] += float(m.card.gas)
		bouts += 1
	print("bouts %d  power %d" % [bouts, power])
	print("role    lb   str base skl gas | bullrush/man/bout  floored  bounced  thrower-fell | downs/man/bout  blows/man/bout")
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		var r := _row(role)
		var men := maxf(1.0, float(r["men"]))
		var br := maxf(1.0, float(r["br"]))
		print("%-6s %4.0f %4.0f %4.0f %3.0f %3.0f | %6.2f  %5.1f%%  %5.1f%%  %5.1f%% | %6.2f  %6.2f" % [
			["RAIL", "FLANK", "CENTER"][role], r["lb"] / men, r["str"] / men, r["base"] / men,
			r["skl"] / men, r["gas"] / men, r["br"] / men,
			100.0 * r["br_down"] / br, 100.0 * r["br_bump"] / br, 100.0 * r["br_fell"] / br,
			r["downs"] / men, r["hits"] / men])
	quit()
