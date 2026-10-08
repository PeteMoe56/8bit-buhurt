extends SceneTree
## Bake-off #2: direct rule fixtures and an audit of the winter counters.
## -- [careers=1] [years=12] [base=9001]; honors the ProbeManager RB_* policy.
## Does not modify game code or save a career. Clone-only drains measure the
## number of manual allocations actually possible, rather than trusting a label.

func _initialize() -> void:
	call_deferred("_run")


static func _points(f: FighterCard) -> int:
	return f.strength + f.base + f.skill + f.gas


static func _fixture(age: int, potential: int, stat: int = 50) -> FighterCard:
	var f := FighterCard.new()
	f.age = age
	f.peak_seed = 0
	f.trait_id = -1
	f.strength = stat
	f.base = stat
	f.skill = stat
	f.gas = stat
	f.aggression = 50
	f.armor = 1.0
	f.potential = potential
	f.level = 3
	f.xp = 10000
	return f


static func _manual_capacity(f: FighterCard) -> int:
	var copy := f.duplicate(true) as FighterCard
	var n := 0
	while Career.can_place(copy) and n < 100:
		var room: Array = Career.raisable(copy)
		var pick: int = room[0]
		for st in room:
			if Career.read_stat(copy, st) < Career.read_stat(copy, pick):
				pick = st
		if not bool(Career.level_into(copy, pick).get("levelled", false)):
			break
		n += 1
	return n


func _run() -> void:
	print("ENGINE\t" + str(Engine.get_version_info()))
	print("FIXTURE\tage\tpotential\tauto_points\tmanual_points")
	for item in [[26, 90], [40, 90], [26, 51]]:
		var a := _fixture(item[0], item[1])
		var b := _fixture(item[0], item[1])
		var pa := _points(a)
		var pb := _points(b)
		Career.level_up(a)
		Career.level_into(b, Career.Stat.STRENGTH)
		print("FIXTURE\t%d\t%d\t%d\t%d" % [item[0], item[1], _points(a) - pa, _points(b) - pb])
	var near := _fixture(26, 51)
	print("BANKED_FIXTURE\tlabel=%d\tactual_manual_capacity=%d" % [Career.levels_banked(near), _manual_capacity(near)])
	var edge_auto := _fixture(26, 51)
	edge_auto.strength = 52
	var edge_manual := edge_auto.duplicate(true) as FighterCard
	var edge_points := _points(edge_auto)
	Career.level_up(edge_auto)
	Career.level_into(edge_manual, Career.Stat.STRENGTH)
	print("CEILING_FIXTURE\tauto_points=%d\tmanual_points=%d" % [_points(edge_auto) - edge_points, _points(edge_manual) - edge_points])
	var kit := _fixture(26, 68, 70)
	var intact_overall := kit.overall()
	var intact_placeable := Career.can_place(kit)
	kit.armor = 0.5
	print("KIT_FIXTURE\tintact_overall=%d\tintact_placeable=%s\tworn_overall=%d\tworn_placeable=%s" % [intact_overall, str(intact_placeable), kit.overall(), str(Career.can_place(kit))])
	var capped := _fixture(26, 99, 99)
	print("CAP_FIXTURE\toverall=%d\tcan_level=%s\tcan_place=%s\tbanked=%d" % [capped.overall(), str(Career.can_level(capped)), str(Career.can_place(capped)), Career.levels_banked(capped)])
	var args := OS.get_cmdline_user_args()
	var careers := int(args[0]) if args.size() > 0 else 1
	var years := int(args[1]) if args.size() > 1 else 12
	var base := int(args[2]) if args.size() > 2 else 9001
	print("AUDIT\tpolicy\tseed\tseason\tunspent_like_flow\tactually_placeable_men\tlabel_banked\tactual_manual_capacity\tstat_capped_unspent\tpower_pre_rollover\tpower_post_rollover")
	for i in careers:
		var seed_v := base + i * 7919
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		Session.season = s
		var m := ProbeManager.new()
		for y in years:
			m.winter(s)
			var eligible := 0
			var placeable := 0
			var labels := 0
			var capacity := 0
			for f in s.club.roster:
				if Career.can_level(f):
					eligible += 1
				if Career.can_place(f):
					placeable += 1
				labels += Career.levels_banked(f)
				capacity += _manual_capacity(f)
			m.season(s)
			var pre := s.club.power()
			s.roll_over()
			print("AUDIT\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d" % [m.policy_tag(), seed_v, y + 1, eligible, placeable, labels, capacity, eligible - placeable, pre, s.club.power()])
	quit(0)
