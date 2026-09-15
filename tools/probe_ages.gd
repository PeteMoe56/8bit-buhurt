extends SceneTree
func _init() -> void:
	var c := MeleeRosters.starting_club()
	var ages: Array[int] = []
	var line := ""
	for f in c.roster:
		ages.append(f.age)
		line += "%s %d/%d  " % [f.display_name.substr(0, 9), f.age, f.overall()]
	ages.sort()
	var t := 0
	for a in ages: t += a
	print("\nSTARTING CLUB: %d men, ages %d-%d, average %.1f, median %d"
		% [ages.size(), ages[0], ages[-1], float(t) / ages.size(), ages[ages.size() / 2]])
	print(line)
	var past := 0
	for a in ages:
		if a > Career.LEARN_PAR: past += 1
	print("past the learning par of %d: %d of %d (%.0f%%)\n"
		% [Career.LEARN_PAR, past, ages.size(), 100.0 * past / ages.size()])
	quit()
