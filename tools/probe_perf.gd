extends SceneTree
## WHERE THE TIME GOES: a bout, a tick's parts, a matchday, a summer, a save.
##
##   godot --headless --path . --script res://tools/probe_perf.gd -- [bouts]
##   bash tools/bb.sh probe perf [bouts]
##
## Desktop numbers. A mid-range phone runs GDScript roughly 3-5x slower, so the
## budget line is a sim tick well under a millisecond (a 60 fps frame runs one
## to a few ticks) and a summer well under the length of the wipe that hides it.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 20
	print("\n=== where the time goes (%d bouts) ===\n" % n)
	_bouts(n)
	_tick_parts(n)
	_season()
	quit(0)


func _ms(us: int) -> String:
	return "%.2f ms" % (float(us) / 1000.0)


func _bouts(n: int) -> void:
	var total := 0
	var ticks := 0
	for i in n:
		var s := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 900 + i)
		var t0 := Time.get_ticks_usec()
		var k := 0
		while not s.is_over() and k < 200000:
			s.tick()
			k += 1
		total += Time.get_ticks_usec() - t0
		ticks += k
	print("  a bout, run to the end:   %s each, %d ticks, %.1f us a tick"
		% [_ms(total / n), ticks / n, float(total) / float(ticks)])


## The tick taken apart the way `MeleeSim.tick` runs it, each part timed.
func _tick_parts(n: int) -> void:
	var parts := {"anchors": 0, "timers": 0, "targets": 0, "step": 0, "spread": 0,
		"prompts": 0, "grapples": 0, "round end": 0}
	var ticks := 0
	for i in n:
		var s := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 900 + i)
		var k := 0
		while not s.is_over() and k < 200000:
			k += 1
			if s.phase == MeleeSim.Phase.CORNER or s.phase == MeleeSim.Phase.OVER:
				s.tick()
				continue
			ticks += 1
			s.bout_t += Tuning.TICK
			s.round_t += Tuning.TICK
			if s.phase == MeleeSim.Phase.CHARGE:
				s.charge_t += Tuning.TICK
				if s.charge_t > Tuning.CHARGE_TIME:
					s.phase = MeleeSim.Phase.LIVE
			for t in 2:
				s.plan_t[t] -= Tuning.TICK
			var t0 := Time.get_ticks_usec()
			s._refresh_anchors()
			var t1 := Time.get_ticks_usec()
			for m in s.men:
				s._tick_timers(m)
			var t2 := Time.get_ticks_usec()
			s._choose_targets()
			var t3 := Time.get_ticks_usec()
			for m in s.men:
				s._step(m)
			var t4 := Time.get_ticks_usec()
			s._spread_out()
			var t5 := Time.get_ticks_usec()
			for m in s.men:
				s._tick_prompt(m)
			var t6 := Time.get_ticks_usec()
			s._tick_grapples()
			var t7 := Time.get_ticks_usec()
			s._check_round_end()
			var t8 := Time.get_ticks_usec()
			parts["anchors"] += t1 - t0
			parts["timers"] += t2 - t1
			parts["targets"] += t3 - t2
			parts["step"] += t4 - t3
			parts["spread"] += t5 - t4
			parts["prompts"] += t6 - t5
			parts["grapples"] += t7 - t6
			parts["round end"] += t8 - t7
	var all := 0
	for k in parts:
		all += int(parts[k])
	print("  a live tick, by part (%d ticks, %.1f us a tick):" % [ticks, float(all) / float(ticks)])
	for k in parts:
		print("     %-10s %5.1f us  %4.1f%%" % [k, float(parts[k]) / float(ticks),
			100.0 * float(parts[k]) / float(maxi(1, all))])


func _season() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	var m := ProbeManager.new()
	var ev := 0
	var ev_us := 0
	var sum_us := 0
	var sums := 0
	var save_us := 0
	var load_us := 0
	var saves := 0
	var bytes := 0
	var winter_us := 0
	for y in 6:
		var w0 := Time.get_ticks_usec()
		m.winter(s)
		winter_us += Time.get_ticks_usec() - w0
		var g := 0
		while not s.season_complete() and g < 60:
			g += 1
			while s.blocked_by() != "":
				match s.blocked_by():
					"bid": s.decline_bid()
					"dilemma": s.answer_dilemma(0)
					"sendoff": s.answer_send_off()
					"cup": s.sim_cup_tie()
					"promotion": s.answer_promotion(true)
			if s.season_complete():
				break
			var t0 := Time.get_ticks_usec()
			s.skip_event()
			ev_us += Time.get_ticks_usec() - t0
			ev += 1
			var t1 := Time.get_ticks_usec()
			var body := var_to_bytes(SaveGame.to_dict(s))
			var t2 := Time.get_ticks_usec()
			SaveGame.from_dict(bytes_to_var(body))
			var t3 := Time.get_ticks_usec()
			save_us += t2 - t1
			load_us += t3 - t2
			bytes += body.size()
			saves += 1
		var r0 := Time.get_ticks_usec()
		s.roll_over()
		sum_us += Time.get_ticks_usec() - r0
		sums += 1
	print("  a simmed matchday:        %s (%d of them)" % [_ms(ev_us / maxi(1, ev)), ev])
	print("  a summer (roll_over):     %s (%d of them)" % [_ms(sum_us / maxi(1, sums)), sums])
	print("  the manager's winter:     %s" % _ms(winter_us / 6))
	print("  a save, encoded:          %s, %d KB" % [_ms(save_us / maxi(1, saves)), bytes / maxi(1, saves) / 1024])
	print("  a save, decoded:          %s" % _ms(load_us / maxi(1, saves)))
	var d0 := Time.get_ticks_usec()
	SaveGame.set_namespace("perf")
	SaveGame.save(s, 2)
	var d1 := Time.get_ticks_usec()
	SaveGame.load_slot(2)
	var d2 := Time.get_ticks_usec()
	SaveGame.delete(2)
	print("  a save to disk and back:  %s write, %s read" % [_ms(d1 - d0), _ms(d2 - d1)])
