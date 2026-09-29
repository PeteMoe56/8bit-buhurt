extends SceneTree
## WHAT THE PLAYER'S THUMB IS WORTH IN A FIGHT (from the 28 Sep fresh-eyes audit).
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
var bouts_total := 0
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 100
	var t0 := Time.get_ticks_msec()
	var which: String = a[1] if a.size() > 1 else "pol"
	if which == "pol":
		for pol in ["smart", "random", "dumb"]:
			print("POLICY %-7s win%% %.1f" % [pol, wr(n, pol, -1, -1, 1.0)])
	elif which == "busy":
		print("POLICY busy(1.2s) win%% %.1f" % wr(n, "busy", -1, -1, 1.0))
		for pol in ["clinch", "clinchdumb", "tapper"]:
			print("POLICY %s win%% %.1f" % [pol, wr(n, pol, -1, -1, 1.0)])
	elif which == "cad":
		for c in [15, 30]:
			cad = c
			print("CLINCH dumb every %d ticks win%% %.1f (orders? no)" % [c, wr(n, "clinchdumb", -1, -1, 1.0)])
		cad = 15
		light = true
		print("CLINCH dumb every 15 ticks, 12-pt light roster win%% %.1f" % wr(n, "clinchdumb", -1, -1, 1.0))
	elif which == "split":
		## Which "always" answer is the one that beats the AI's own pick?
		for pol in ["none", "aipick", "aifresh", "tdonly", "holdonly"]:
			print("POLICY %-7s win%% %.1f" % [pol, wr(n, pol, -1, -1, 1.0)])
	elif which == "help":
		## Is SENDING HELP worth anything when it is done carefully? (29 Sep)
		## helpfree: only men not already fighting someone, one helper per
		## clinch, every 36 ticks, smart answers. helpslow: the same, but the
		## player answers only after a second (a human thumb). helpnoans: sent,
		## never answered — the prompt times out on the AI's pick.
		for pol in ["none", "helpfree", "helpslow", "helpnoans"]:
			print("POLICY %-9s win%% %.1f" % [pol, wr(n, pol, -1, -1, 1.0)])
	elif which.begins_with("sent"):
		## MORNING DECISION #10 (29 Sep): what a route is worth under each option.
		## sent:<edge>:<walks 0/1>  e.g. sent:0.15:1
		var parts := which.split(":")
		Tuning.sent_edge = float(parts[1]) if parts.size() > 1 else 0.0
		Tuning.sent_walks = parts.size() > 2 and parts[2] == "1"
		print("sent_edge %.2f  sent_walks %s" % [Tuning.sent_edge, Tuning.sent_walks])
		for pol in ["none", "helpfree", "helpslow", "smart"]:
			orders_total = 0; bouts_total = 0
			var w := wr(n, pol, -1, -1, 1.0)
			print("POLICY %-9s win%% %.1f   orders/bout %.1f" % [pol, w, float(orders_total) / maxf(1.0, float(bouts_total))])
	elif which == "gap":
		## Just the two numbers the clinch decision turns on (29 Sep).
		var hn := wr(n, "none", -1, -1, 1.0)
		var td := wr(n, "tdonly", -1, -1, 1.0)
		var th := wr(n, "think", -1, -1, 1.0)
		print("GAP none %.1f  tdonly %.1f  edge %+.1f  think %.1f (%+.1f)" % [hn, td, td - hn, th, th - hn])
	elif which == "worst":
		cad = 30; light = true; worldopp = true
		print("CLINCH dumb every 30 ticks, light roster, x1.08, WORLD-skill opp win%% %.1f" % wr(n, "clinchdumb", -1, -1, 1.08))
		print("NONE same setup win%% %.1f" % wr(n, "none", -1, -1, 1.08))
	elif which == "scale":
		for sc in [0.96, 1.04]:
			print("SCALE %.2f none win%% %.1f" % [sc, wr(n, "none", -1, -1, sc)])
	elif which == "strat":
		for st in 4:
			print("STRAT %d none win%% %.1f" % [st, wr(n, "none", -1, st, 1.0)])
	elif which == "form":
		for f in 3:
			print("FORM %d none win%% %.1f" % [f, wr(n, "none", f, -1, 1.0)])
	print("ms %d" % (Time.get_ticks_msec() - t0))
	quit(0)

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
				if k % 36 == 0:
					send_free(sim)
				if pol == "helpfree":
					answer(sim, "smart")
				elif pol == "helpslow":
					for mm in sim.men:
						if mm.team == 0 and mm.prompt != null and not mm.prompt.by_player \
								and mm.prompt.t < Tuning.PROMPT_TIME - 1.0:
							answer_one(sim, mm)
			elif pol != "none" and (not pol.begins_with("clinch") or k % cad == 0):
				answer(sim, "random" if pol == "tapper" else ("dumb" if pol == "clinchdumb" else pol))
				if (pol == "smart" and k % 5 == 0) or (pol == "busy" and k % 36 == 0):
					send(sim)
			sim.tick()
		orders_total += sim.orders_issued
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
func send_free(sim: MeleeSim) -> void:
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
	sim.give_order(bm, path, bt)
