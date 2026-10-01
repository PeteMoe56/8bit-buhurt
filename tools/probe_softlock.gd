extends SceneTree
## Probe for the 30 Sep soft lock: the five shrank to one man after a swap.
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 777)
	var c := s.club
	var names := []
	for f in c.roster:
		names.append("%s(%s%s%s)" % [f.display_name, Tuning.pos_name(int(f.pos)), "" if f.active else "-res", "" if f.fit() else "-UNFIT"])
	print("ROSTER ", names, " party ", c.party_size())
	print("FIVE ", c.starting_five().map(func(f): return f.display_name))
	var eight := c.active_eight()
	# swap every pair in the eight and every eight/reserve pair, report shrinks
	var bad := 0
	for a in eight:
		for b in c.roster:
			if a == b:
				continue
			var snap: Array = c.roster.duplicate()
			var act := {}
			for f in c.roster:
				act[f] = f.active
			var err := ""
			if a.active and b.active:
				err = c.swap_order(a, b)
			elif a.active and not b.active:
				err = c.swap_squad(a, b)
			if err == "" and c.starting_five().size() != 5:
				bad += 1
				print("SHRINK after %s<->%s: five=%d" % [a.display_name, b.display_name, c.starting_five().size()])
			c.roster = snap
			for f in act:
				f.active = act[f]
	print("bad ", bad)
	quit()
