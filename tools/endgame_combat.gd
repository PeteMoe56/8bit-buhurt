extends RefCounted
static func _play(sim: MeleeSim, policy: String, team: int = 0) -> void:
	assert(policy != "busy" or team == 0,"Native player orders support team zero only; a swapped thumb is invalid")
	if policy == "busy" and team != 0:return
	var guard := int(20.0 * (Tuning.ROUND_TIME + maxf(0.0,sim.corner_time)) / Tuning.TICK) + 1 if sim.get("knockout_sudden_death") == true else 20000
	var cd := 0.0
	while not sim.is_over() and guard > 0:
		guard -= 1
		if policy == "busy":
			cd -= Tuning.TICK
			if cd <= 0.0:
				cd = 1.2
				_send_someone(sim,team)
			_answer_everything(sim,team)
		sim.tick()

	assert(sim.is_over(), "Fight guard expired; no result may be posted")

## The same engaged player the main suite uses, and deliberately so: this suite
## must measure the design, not a better thumb written specially for it.
static func _send_someone(sim: MeleeSim, team: int = 0) -> void:
	if sim.phase != MeleeSim.Phase.LIVE:
		return
	var best_mover := -1
	var best_target := -1
	var best_d := 110.0
	for m in sim.men:
		if m.team != team or m.under_orders() or m.state == MeleeSim.State.GRAPPLED:
			continue
		if not m.standing():
			continue
		for e in sim.men:
			if e.team == team or e.state != MeleeSim.State.GRAPPLED:
				continue
			if e.target == -1 or sim.men[e.target].team != team:
				continue
			var d := m.pos.distance_to(e.pos)
			if d < best_d:
				best_d = d
				best_mover = m.idx
				best_target = e.idx
	if best_mover == -1:
		return
	var path: Array[Vector2] = []
	sim.give_order(best_mover, path, best_target)


static func _answer_everything(sim: MeleeSim, team: int = 0) -> void:
	for m in sim.men:
		if m.prompt == null or m.team != team:
			continue
		var tgt := sim.men[m.prompt.target]
		match m.prompt.menu:
			Tuning.Menu.APPROACH:
				if tgt.stability < 0.50 or tgt.exposed_t > 0.0:
					sim.answer_prompt(m.idx, Tuning.Act.BULLRUSH)
				elif m.gas_frac() < 0.40:
					sim.answer_prompt(m.idx, Tuning.Act.GRAPPLE)
				else:
					sim.answer_prompt(m.idx, Tuning.Act.HIT)
			Tuning.Menu.THIRD_MAN:
				sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.65
					else Tuning.Act.HIT)
			Tuning.Menu.GRAPPLED:
				sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.60
					else Tuning.Act.HOLD)

static func participant_rows(sim: MeleeSim, starting_ids: Array) -> Array:
	var rows: Array = []
	for m in sim.fought():
		if m.team == 0 and m.card != null:
			rows.append({"id":m.card.career_id,"name":m.card.display_name,"slot":m.slot,"downs":m.downs_caused,"standing":m.rounds_standing,"times_downed":m.times_downed,"started":m.card.career_id in starting_ids,"substituted_out":m.idx == -1,"substituted_in":not m.card.career_id in starting_ids})
	return rows
