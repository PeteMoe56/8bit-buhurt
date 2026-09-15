extends SceneTree
## HOW FAST A FIGHTER ACTUALLY GETS BETTER.
##
##   godot --headless --path . --script res://tools/probe_growth.gd
##
## Every other number in this project rests on this one and nobody has ever
## measured it. `tools/probe_pace.gd` has a competent manager's club climbing
## 0.4 rating points a season while its division's leader sits eight to ten
## clear, and Pete wants a career to reach the top flight in about ten seasons
## rather than never. Three promotions in ten years means roughly FOUR points of
## club rating a season, sustained, and club rating is the average of five men.
##
## So: take one man, fight him every week of every season the way a starter is
## fought, and print what he becomes.
const SEASONS := 12


func _initialize() -> void:
	for age in [20, 24, 28]:
		_one(age)
	quit(0)


func _one(start_age: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("growth:%d" % start_age)
	var f := ClubFactory.free_agent(rng, Tuning.Pos.CENTER, 40)
	f.age = start_age
	f.armor = 1.0
	f.potential = Career.roll_potential(rng, f)
	print("\n=== a fighter signed at %d, rated %d, ceiling %d ==="
		% [start_age, f.overall(), f.potential])
	print("%7s %5s %7s %7s %6s %7s %8s" % [
		"season", "age", "rating", "ceiling", "level", "levels", "gap left"])
	var events := League.events_in_season(0)
	for y in SEASONS:
		## A SEASON'S FIGHTING. `xp_for` is what one event pays a man of his
		## rating; `level_up` spends the bar every time it fills, which is what a
		## club does — nobody leaves an earned point sitting.
		var got := 0
		for _e in events:
			f.xp += Career.xp_for(6, 3, f.overall())
			while Career.can_level(f) and not Career.at_ceiling(f):
				Career.level_up(f)
				got += 1
		Career.winter(f, false, 0)
		print("%7d %5d %7d %7d %6d %7d %8d" % [y + 1, f.age, f.overall(),
			f.potential, f.level, got, maxi(0, f.potential - f.overall())])
	print("")
