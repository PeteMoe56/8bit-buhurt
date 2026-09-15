extends SceneTree
## WHAT DOES A LEVEL GIVE, AND WHAT DOES A YEAR TAKE?
##
##   godot --headless --path . --script res://tools/probe_dev.gd
##
## `tools/probe_climb.gd` ran fourteen seasons three ways with **120 credits a
## year of free money** and the spender finished on rating 21 against the
## walker's 20. Forty subsidised levels a season, worth one point across a
## career. And all three managers fell from 37 to 20 while the division sat at
## 45.
##
## That is the armor finding again in a different system: a mechanic with a
## screen, a price and a progress bar, moving nothing. So — the two halves,
## measured against each other, because "development is too weak" and "ageing is
## too strong" are the same table read from two ends and the fix is different
## depending on which one it is.
const SEASONS := 12


func _initialize() -> void:
	print("\n=== what a level gives ===\n")
	_one_level()
	print("\n=== what a year takes ===\n")
	_one_year()
	print("\n=== and the two against each other, over a squad ===\n")
	_squad()
	print("")
	quit(0)


## ONE LEVEL, AT EVERY AGE AND RATING A MAN CAN BE AT. `level_up` picks the stat
## itself, so this is the real yield and not the yield of a chosen stat.
func _one_level() -> void:
	print("%5s %7s %9s %9s" % ["age", "before", "after", "gain"])
	for age in [20, 24, 28, 32, 36]:
		var f := FighterCard.new()
		f.age = age
		f.strength = 45
		f.base = 45
		f.skill = 45
		f.gas = 45
		f.potential = 99
		f.xp = 9999
		var before := f.overall()
		Career.level_up(f)
		print("%5d %7d %9d %9+d" % [age, before, f.overall(), f.overall() - before])


## ONE WINTER, coached and on a full training ground — the best case the game
## offers — at every age.
func _one_year() -> void:
	print("%5s %7s %9s %9s" % ["age", "before", "after", "change"])
	for age in [20, 24, 28, 32, 36]:
		var f := FighterCard.new()
		f.age = age
		f.strength = 45
		f.base = 45
		f.skill = 45
		f.gas = 45
		f.potential = 99
		var before := f.overall()
		Career.winter(f, true, 3)
		print("%5d %7d %9d %9+d" % [age, before, f.overall(), f.overall() - before])


## AND THE WHOLE THING: a real squad, aged a dozen winters, with every level the
## club could possibly place, against the same squad left alone.
func _squad() -> void:
	print("%5s %8s %8s %8s %9s" % ["year", "left", "levelled", "gap", "levels"])
	var a := MeleeRosters.starting_club()
	var b := MeleeRosters.starting_club()
	var placed := 0
	for y in SEASONS:
		for f in a.roster:
			Career.winter(f, true, 3)
		for f in b.roster:
			Career.winter(f, true, 3)
			## EVERY LEVEL THE MONEY COULD EVER BUY, with the price and the
			## throttle both removed. This is the CEILING on development — what a
			## club with infinite credits and infinite weeks could do — so if the
			## gap is small here, no amount of balancing the economy can help.
			f.xp = 999999
			for _i in 4:
				var r: Dictionary = Career.level_up(f)
				if not bool(r.get("levelled", false)):
					break
				placed += 1
		print("%5d %8d %8d %8+d %9d" % [y + 1, a.power(), b.power(),
			b.power() - a.power(), placed])
