extends SceneTree
## THE OFF-BALANCE BULLRUSH (10 Oct 2026), built on probe_fightskill.
##   bash tools/bb.sh probe brread <bouts> <policy>
## Win % plus every player bullrush split by whether the man was under the
## balance line when it landed, and how each one ended.
## (was: WHAT THE PLAYER'S THUMB IS WORTH IN A FIGHT (from the 28 Sep fresh-eyes audit).
##
##   bash tools/bb.sh probe fightskill <bouts> <mode>
##
## Starting club vs the rival, one policy per line, win % over <bouts>:
##   pol    smart / random / dumb route-drawing
##   busy   busy routes, clinch-menu TAKEDOWN spam (clinch, clinchdumb), tapper
##   cad    clinch spam at two cadences, and with a 12-point-light roster
##   worst  spam in a hopeless matchup vs hands-off
##   scale  grade strength x0.96 / x1.04, hands-off
##   strat  each strategy, hands-off      form  each formation, hands-off
##   help   careful help-sending: none / helpfree / helpslow / helpnoans
##   sent:<edge>:<walks>  the same under decision #10's options (sent:0.15:1)
##   split  the clinch answer: none / aipick / aifresh / tdonly / holdonly
var rnd := RandomNumberGenerator.new()
var cad := 1
var light := false
var worldopp := false
var orders_total := 0
var grabs_total := 0
var sent_total := 0
var trips_total := 0
var flank_total := 0
var front_total := 0
var bouts_total := 0
var pre: Array = []
var tally := {}
var cur: MeleeSim = null
func _on_br(a: int, t: int, kind: int, _dir: Vector2) -> void:
	var m = cur.men[a]
	if m.team != 0 or not m.acting_for_player:
		return
	var key := "under" if float(pre[t]) < Tuning.pread_at else "steady"
	if not tally.has(key):
		tally[key] = [0, 0, 0]
	tally[key][kind] += 1
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 100
	var pol: String = a[1] if a.size() > 1 else "smart"
	var w := wr(n, pol, -1, -1, 1.0)
	print("POLICY %s n %d win%% %.1f" % [pol, n, w])
	for key in ["under", "steady"]:
		var r: Array = tally.get(key, [0, 0, 0])
		var tot: int = r[0] + r[1] + r[2]
		print("BR %-6s %5d  downed %5.1f%%  bump %5.1f%%  thrower fell %5.1f%%  per bout %.2f" % [key, tot,
			100.0 * r[2] / maxf(1, tot), 100.0 * r[1] / maxf(1, tot), 100.0 * r[0] / maxf(1, tot), float(tot) / n])
	quit()

func wr(n: int, pol: String, form: int, strat: int, sc: float) -> float:
	var w := 0
	var d := 0
	for i in n:
		rnd.seed = i * 31 + 7
		var ca := MeleeRosters.player_club()
		if light:
			for f in ca.roster:
				f.strength = maxi(1, f.strength - 12); f.base = maxi(1, f.base - 12)
				f.skill = maxi(1, f.skill - 12); f.gas = maxi(1, f.gas - 12)
		var sim := MeleeSim.new(ca, MeleeRosters.rival_club(), hash("zz:%d" % i), sc)
		sim.strategies[1] = rnd.randi() % 4
		if worldopp: sim.skills[1] = Tuning.AiSkill.WORLD
		if strat >= 0: sim.strategies[0] = strat
		if form >= 0:
			sim.set_plan(0, Tuning.FORMATIONS[form]["spots"].duplicate(), null)
		else:
			sim.set_plan(0, sim.formation_spots(0).duplicate(), null)
		cur = sim
		sim.bullrush_landed.connect(_on_br)
		var k := 0
		var was_corner := false
		while not sim.is_over() and k < 200000:
			k += 1
			if sim.phase == MeleeSim.Phase.CORNER and not was_corner:
				sim.strategies[1] = rnd.randi() % 4
			was_corner = sim.phase == MeleeSim.Phase.CORNER
			if pol in ["clinch", "clinchdumb"] and k % cad == 0:
				for mm in sim.men:
					if mm.team == 0 and mm.state == MeleeSim.State.GRAPPLED and mm.prompt == null:
						sim.request_prompt(mm.idx)
			if pol == "tapper" and k % 36 == 0 and sim.phase == MeleeSim.Phase.LIVE:
				var mine: Array = []; var theirs: Array = []
				for mm in sim.men:
					if not mm.standing(): continue
					if mm.team == 0: mine.append(mm.idx)
					else: theirs.append(mm.idx)
				if not mine.is_empty() and not theirs.is_empty():
					var pth: Array[Vector2] = []
					sim.give_order(mine[rnd.randi() % mine.size()], pth, theirs[rnd.randi() % theirs.size()])
			if pol in ["aipick", "aifresh", "tdonly", "holdonly", "think"]:
				## Open every clinched man's menu (a tap), then answer it — with the
				## AI's own pick (the control), always TAKEDOWN, or always HOLD.
				for mm in sim.men:
					if mm.team == 0 and mm.state == MeleeSim.State.GRAPPLED and mm.prompt == null:
						sim.request_prompt(mm.idx)
					if mm.prompt == null or mm.team != 0 or mm.prompt.by_player \
							or mm.prompt.menu != Tuning.Menu.GRAPPLED:
						continue
					## aifresh: the AI's own pick, but taken at the moment it lands.
					if pol == "aifresh":
						if mm.next_act > Tuning.TICK * 1.5:
							continue
						mm.prompt.choice = sim._ai_choose(mm, sim.men[mm.prompt.target], Tuning.Menu.GRAPPLED)
					var act: int = mm.prompt.choice
					## think: a sensible thumb — throw on a wobbling or open man,
					## hold on a steady one (29 Sep).
					if pol == "think":
						var tg = sim.men[mm.prompt.target]
						act = Tuning.Act.TAKEDOWN if (tg.stability < 0.55 or tg.exposed_t > 0.0) else Tuning.Act.HOLD
					if pol == "tdonly": act = Tuning.Act.TAKEDOWN
					elif pol == "holdonly": act = Tuning.Act.HOLD
					sim.answer_prompt(mm.idx, act)
			elif pol.begins_with("help"):
				## helpbusy: the wheel thumb, running round behind, but looking for
				## a free man three times as often (every 12 ticks).
				if k % (12 if pol == "helpbusy" else 36) == 0:
					send_free(sim, pol == "helpflank" or pol.begins_with("helpwheel") or pol == "helpbusy",
						pol == "helpwheelrun" or pol == "helpbusy")
				if pol == "helpfree" or pol == "helpflank":
					answer(sim, "smart")
				elif pol.begins_with("helpwheel") or pol == "helpbusy":
					answer_wheel(sim)
				elif pol == "helpslow":
					for mm in sim.men:
						if mm.team == 0 and mm.prompt != null and not mm.prompt.by_player \
								and mm.prompt.t < Tuning.PROMPT_TIME - 1.0:
							answer_one(sim, mm)
			elif pol != "none" and (not pol.begins_with("clinch") or k % cad == 0):
				answer(sim, "random" if pol == "tapper" else ("dumb" if pol == "clinchdumb" else pol))
				if (pol == "smart" and k % 5 == 0) or (pol == "busy" and k % 36 == 0):
					send(sim)
			pre.resize(sim.men.size())
			for q in sim.men.size():
				pre[q] = sim.men[q].stability
			sim.tick()
		orders_total += sim.orders_issued
		grabs_total += sim.passes_grabbed
		sent_total += sim.sent_contacts
		trips_total += sim.passes_tripped
		flank_total += sim.flank_blows
		front_total += sim.front_blows
		bouts_total += 1
		var x := sim.bout_winner()
		if x == -1: continue
		d += 1
		if x == 0: w += 1
	return 100.0 * w / maxf(1.0, d)

func answer(sim: MeleeSim, pol: String) -> void:
	for m in sim.men:
		if m.prompt == null or m.team != 0 or m.prompt.by_player:
			continue
		var tgt = sim.men[m.prompt.target]
		var acts: Array = Tuning.acts_for(m.prompt.menu)
		if pol == "random":
			sim.answer_prompt(m.idx, acts[rnd.randi() % acts.size()])
		elif pol == "dumb":
			match m.prompt.menu:
				Tuning.Menu.APPROACH: sim.answer_prompt(m.idx, Tuning.Act.BULLRUSH)
				Tuning.Menu.THIRD_MAN: sim.answer_prompt(m.idx, Tuning.Act.HIT)
				Tuning.Menu.GRAPPLED: sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN)
		else:
			match m.prompt.menu:
				Tuning.Menu.APPROACH:
					if tgt.stability < 0.50 or tgt.exposed_t > 0.0:
						sim.answer_prompt(m.idx, Tuning.Act.BULLRUSH)
					elif m.gas_frac() < 0.40:
						sim.answer_prompt(m.idx, Tuning.Act.GRAPPLE)
					else:
						sim.answer_prompt(m.idx, Tuning.Act.HIT)
				Tuning.Menu.THIRD_MAN:
					sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.65 else Tuning.Act.HIT)
				Tuning.Menu.GRAPPLED:
					sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.60 else Tuning.Act.HOLD)

func send(sim: MeleeSim) -> void:
	if sim.phase != MeleeSim.Phase.LIVE: return
	var bm := -1; var bt := -1; var bd := 110.0
	for m in sim.men:
		if m.team != 0 or m.under_orders() or m.state == MeleeSim.State.GRAPPLED or not m.standing(): continue
		for e in sim.men:
			if e.team == 0 or e.state != MeleeSim.State.GRAPPLED: continue
			if e.target == -1 or sim.men[e.target].team != 0: continue
			var dd: float = m.pos.distance_to(e.pos)
			if dd < bd: bd = dd; bm = m.idx; bt = e.idx
	if bm == -1: return
	var path: Array[Vector2] = []
	sim.give_order(bm, path, bt)


func answer_one(sim: MeleeSim, m) -> void:
	var tgt = sim.men[m.prompt.target]
	match m.prompt.menu:
		Tuning.Menu.APPROACH:
			sim.answer_prompt(m.idx, Tuning.Act.BULLRUSH if tgt.stability < 0.50 or tgt.exposed_t > 0.0 else Tuning.Act.HIT)
		Tuning.Menu.THIRD_MAN:
			sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.65 else Tuning.Act.HIT)
		Tuning.Menu.GRAPPLED:
			sim.answer_prompt(m.idx, Tuning.Act.TAKEDOWN if tgt.stability < 0.60 else Tuning.Act.HOLD)


## Send ONE free man to the nearest enemy who has one of ours tied up, and only
## if nobody is already on his way to that enemy.
func send_free(sim: MeleeSim, flank: bool = false, run: bool = false) -> void:
	if sim.phase != MeleeSim.Phase.LIVE: return
	var claimed := {}
	for m in sim.men:
		if m.team == 0 and m.under_orders() and m.order.target != -1:
			claimed[m.order.target] = true
	var bm := -1; var bt := -1; var bd := 140.0
	for m in sim.men:
		if m.team != 0 or m.under_orders() or not m.standing() or m.state != MeleeSim.State.CLOSING: continue
		if m.target != -1 and sim.men[m.target].standing() and m.pos.distance_to(sim.men[m.target].pos) < 80.0: continue
		for e in sim.men:
			if e.team == 0 or e.state != MeleeSim.State.GRAPPLED or claimed.has(e.idx): continue
			if e.target == -1 or sim.men[e.target].team != 0: continue
			var dd: float = m.pos.distance_to(e.pos)
			if dd < bd: bd = dd; bm = m.idx; bt = e.idx
	if bm == -1: return
	var path: Array[Vector2] = []
	## FLANK: a waypoint off the held man's side — perpendicular to the way he
	## faces his clinch partner, on whichever side is nearer the man sent.
	if flank:
		var e = sim.men[bt]
		var face: Vector2 = (sim.men[e.target].pos - e.pos).normalized()
		var side := Vector2(-face.y, face.x)
		if (sim.men[bm].pos - e.pos).dot(side) < 0.0:
			side = -side
		## Out to his side, then round behind him — the man sent arrives from
		## the back, the way a thumb would draw it.
		path.append(e.pos + side * 38.0)
		path.append(e.pos + side * 14.0 - face * 34.0)
	sim.give_order(bm, path, bt, run)


## ANSWER LIKE A PLAYER READING THE WHEEL (29 Sep): take the bullrush when it is
## likelier than not and the fall is small, the takedown on a held man when it is
## a fair shot, and otherwise the hit.
func answer_wheel(sim: MeleeSim) -> void:
	for m in sim.men:
		if m.prompt == null or m.team != 0 or m.prompt.by_player:
			continue
		if m.prompt.menu == Tuning.Menu.GRAPPLED:
			continue
		var t: int = m.prompt.target
		var acts: Array = Tuning.acts_for(m.prompt.menu)
		var pick: int = Tuning.Act.HIT
		if acts.has(Tuning.Act.BULLRUSH):
			var br: Dictionary = sim.contact_odds(m.idx, Tuning.Act.BULLRUSH, t)
			if float(br["p"]) >= 0.5 and float(br["fall"]) <= 0.15:
				pick = Tuning.Act.BULLRUSH
		if acts.has(Tuning.Act.TAKEDOWN):
			var td: Dictionary = sim.contact_odds(m.idx, Tuning.Act.TAKEDOWN, t)
			if float(td["p"]) >= 0.35:
				pick = Tuning.Act.TAKEDOWN
		sim.answer_prompt(m.idx, pick)
