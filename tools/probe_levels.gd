extends SceneTree
## WHAT A LEVEL CURVE IS ACTUALLY WORTH, measured against the winter it replaces.
##
##   godot --headless --path . --script res://tools/probe_levels.gd
##
## The threshold is `level * LEVEL_XP`, Retro Bowl's shape. The question is what
## LEVEL_XP has to be so that a career climbs at the rate the old winter climbed
## at — because the rework was meant to move WHEN a man levels, not how far.
const SEASONS := 8
const EVENTS := 13


func _fresh() -> FighterCard:
	var f := FighterCard.new()
	f.strength = 50
	f.base = 50
	f.skill = 50
	f.gas = 50
	f.aggression = 50
	f.age = 22
	f.potential = 72
	f.level = 1
	f.xp = 0
	f.morale = 0.5
	return f


## The model that used to run: bank all season, spend at the winter on a rising
## cost of 8, 12, 18, 26, 40.
func _old() -> Array:
	var f := _fresh()
	var pts := 0
	for s in SEASONS:
		for e in EVENTS:
			f.xp += Career.xp_for(2, 3)
		var taken := 0
		while f.xp >= Career.xp_cost(taken) and f.overall() < f.potential and taken < 24:
			var cost := Career.xp_cost(taken)
			if not Career._raise_one(f, {}, {"lost": 0, "gained": 0, "spent": 0,
					"ground": 0, "held": 0}):
				break
			f.xp -= cost
			taken += 1
			pts += 1
	return [pts, f.overall()]


## THEIR SHAPE, WITH OUR CAP. `xp_cost` was [8, 12, 18, 26, 40] and then FLAT —
## the rise stops. Retro Bowl's `level * 100` never stops, which works for them
## because their XP income grows with production and ours does not: `xp_for` pays
## the same for a good afternoon in season ten as in season one. Ported literally
## it walls a career at three points of overall.
##
## Remainder KEPT, and at most one level a bout instead — same intent as their
## `xp = 1` (a monstrous afternoon must not buy two levels) without binning a
## quarter of everything a man earns.
func _new2(step: int, cap: int) -> Array:
	var f := _fresh()
	var lv := 0
	var per: Array[int] = []
	for s in SEASONS:
		var got := 0
		for e in EVENTS:
			f.xp += Career.xp_for(2, 3)
			var bar: int = mini(f.level, cap) * step
			if f.xp >= bar and not Career.at_ceiling(f):
				if Career._raise_one(f, {}, {"lost": 0, "gained": 0, "spent": 0,
						"ground": 0, "held": 0}):
					f.xp -= bar
					f.level += 1
					got += 1
		per.append(got)
		lv += got
	return [lv, f.overall(), per]


func _new(step: int) -> Array:
	var f := _fresh()
	var lv := 0
	var per: Array[int] = []
	for s in SEASONS:
		var got := 0
		for e in EVENTS:
			f.xp += Career.xp_for(2, 3)
			var n: int = 0
			var guard := 12
			while f.xp >= f.level * step and not Career.at_ceiling(f) and guard > 0:
				if not Career._raise_one(f, {}, {"lost": 0, "gained": 0, "spent": 0,
						"ground": 0, "held": 0}):
					break
				f.xp = 0
				f.level += 1
				n += 1
				guard -= 1
			got += n
		per.append(got)
		lv += got
	return [lv, f.overall(), per]


## THE RULE THE GAME ACTUALLY RUNS, with the man getting a year older each time.
##
## Every row above hand-rolls `mini(level, cap) * step`, which was the whole rule
## when they were written and is now half of it — `next_level_at` carries an age
## term since Pete asked for *"slower at leveling his main level"*. A probe that
## reproduces the formula instead of calling it measures the model it remembers,
## which is how a constant that used to be a fact becomes a lie.
##
## So this one calls the live function and ages the fighter, and it is the only
## row here that can answer whether the age term broke the curve.
func _live(start_age: int) -> Array:
	var f := _fresh()
	f.age = start_age
	var lv := 0
	var per: Array[int] = []
	for s in SEASONS:
		var got := 0
		for e in EVENTS:
			f.xp += Career.xp_for(2, 3)
			## THE PLAYER'S DOOR, not the winter's. `_raise_one` — which every
			## row above uses — refuses a stat the man is past the peak of, and
			## past 36 that is all four, so an automatic career reads `0, 0, 0`
			## for reasons that have nothing to do with the bar being measured.
			## `level_into` is what a managed club actually presses, and it has
			## no peak rule: *"leave the ability to gain all stats still."*
			if f.xp >= Career.next_level_at(f) and Career.can_place(f):
				var low := -1
				for stat in Career.raisable(f):
					if low < 0 or Career.read_stat(f, stat) < Career.read_stat(f, low):
						low = stat
				if bool(Career.level_into(f, low).get("levelled", false)):
					got += 1
		per.append(got)
		lv += got
		f.age += 1
	return [lv, f.overall(), per, f.age]


func _init() -> void:
	var o := _old()
	print("the winter it replaces: %d points over %d seasons, overall 50 -> %d"
		% [o[0], SEASONS, o[1]])
	print("")
	for step in [10, 20, 40]:
		var r := _new(step)
		print("uncapped %2d: %2d levels, overall 50 -> %d, per season %s"
			% [step, r[0], r[1], str(r[2])])
	print("")
	for row in [[8, 3], [8, 4], [6, 4], [10, 3], [6, 3], [10, 4]]:
		var r := _new2(int(row[0]), int(row[1]))
		print("step %2d cap %d: %2d levels, overall 50 -> %d, per season %s"
			% [row[0], row[1], r[0], r[1], str(r[2])])
	print("")
	print("LIVE next_level_at, ageing one year a season:")
	for start in [19, 22, 26, 30, 34]:
		var r := _live(start)
		print("  from %d to %d: %2d levels, overall 50 -> %d, per season %s"
			% [start, int(r[3]), r[0], r[1], str(r[2])])
	quit()
