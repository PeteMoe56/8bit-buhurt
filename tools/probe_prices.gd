extends SceneTree
## WHAT THE MEETING CHARGES, ACROSS THE RANGE.
##
##   godot --headless --path . --script res://tools/probe_prices.gd
##
## Pete, 14 Sep 2026: *"those CCs are variable on Retro Bowl, you may need to
## deep dive the mechanism through that."* He is right, and the decompile is
## already in our own register at REGISTER.md:5834 —
## `s_get_meeting_cost_levelup` at **`xp_level * 4` credits**, which the
## screenshot confirms exactly: XP LEVEL 5, Level Up, 20 CC.
##
## So the question is not what theirs does. It is whether ours does the same
## SHAPE, and this prints every ladder so the answer is a table rather than a
## reading of the source.
func _init() -> void:
	print("\n=== the meeting's four prices, across the range ===\n")

	print("XP LEVEL — theirs is level x 4 unbounded; ours is level x %d x learn_rate."
		% Career.LEVEL_COST_PER)
	print("  The BAR still caps at 24 on purpose (flat XP income); the PRICE no")
	print("  longer reads through that cap, which is what it used to do.")
	print("  %-6s %-10s %-12s %-10s %s" % ["level", "our bar", "ours (CC)", "theirs", "note"])
	for lv in [1, 2, 3, 4, 5, 6, 8, 10, 12, 15]:
		var f := FighterCard.new()
		f.display_name = "L%d" % lv
		f.pos = Tuning.Pos.CENTER
		f.age = 26
		f.strength = 40; f.base = 40; f.skill = 40; f.gas = 40; f.aggression = 40
		f.potential = 99
		f.level = lv
		print("  %-6d %-10d %-12d %-10d %s" % [lv, Career.next_level_at(f),
			Career.level_cost(f), lv * 4,
			"bar capped" if Career.next_level_at(f) >= 24 else ""])

	print("\nAND OURS MOVES WITH AGE, which theirs has no equivalent for —")
	print("  a level costs more for a man who is slow to learn.")
	print("  %-6s %-10s %s" % ["age", "bar", "CC"])
	for age in [20, 26, 32, 38]:
		var f := FighterCard.new()
		f.display_name = "A%d" % age
		f.pos = Tuning.Pos.CENTER
		f.age = age
		f.strength = 40; f.base = 40; f.skill = 40; f.gas = 40; f.aggression = 40
		f.potential = 99
		f.level = 5
		print("  %-6d %-10d %d" % [age, Career.next_level_at(f), Career.level_cost(f)])

	print("\nCONDITION — priced off the damage. 1 at a scratch, %d at a wreck."
		% ClubOffice.KIT_COST_FULL)
	print("  %-10s %s" % ["armor", "CC"])
	for a in [0.95, 0.80, 0.60, 0.40, 0.20, 0.0]:
		var f := FighterCard.new()
		f.display_name = "K"
		f.pos = Tuning.Pos.CENTER
		f.armor = a
		print("  %-10.2f %d" % [a, ClubOffice.kit_cost(f)])

	print("\nMORALE — priced off his mood, not his rating.")
	var line := "  "
	for w in ClubOffice.NEGOTIATE_COST:
		line += "%s %d   " % [String(w), int(ClubOffice.NEGOTIATE_COST[w])]
	print(line)

	print("\nCONTRACT — priced off the wage and the years left, through the season.")
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	print("  %-10s %-6s %-8s %-8s %s" % ["man", "ov", "wage", "years", "extend/re-sign"])
	for f in s.club.roster:
		var cost: int = s.resign_cost(f) if f.years <= 0 else s.extend_cost(f)
		print("  %-10s %-6d %-8s %-8d %d" % [f.display_name.substr(0, 9),
			f.overall(), ClubOffice.money(f.wage_agreed), f.years, cost])
	print("")
	quit()
