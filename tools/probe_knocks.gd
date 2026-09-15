extends SceneTree
## HOW OFTEN A MAN COMES OFF AN EVENT HURT.
##
##   godot --headless --path . --script res://tools/probe_knocks.gd
##
## Pete, item 13 of the 15 Sep playtest: *"for some reason immediately have one
## out."* Nobody starts a career injured — checked, four seeds, thirteen men
## each, all fit — so what he saw was a knock picked up in his FIRST bout, which
## is the system working. Whether it is working at the right RATE is a different
## question and one nothing had ever measured.
var n := 0
func _initialize() -> void:
	var bouts := 0
	var knocks := 0
	var with_one := 0
	var lengths: Array[int] = []
	for i in 60:
		var s := Season.new(MeleeRosters.starting_club(), 5000 + i)
		var before := {}
		for f in s.club.roster:
			before[f] = f.injury
		var sim := s.begin_bout()
		sim.run_to_end()
		s.post_bout(sim)
		bouts += 1
		var hurt := 0
		for f in s.club.roster:
			if f.injury > int(before[f]):
				hurt += 1
				knocks += 1
				lengths.append(f.injury)
		if hurt > 0:
			with_one += 1
	lengths.sort()
	var mean := 0.0
	for l in lengths:
		mean += float(l)
	mean = 0.0 if lengths.is_empty() else mean / float(lengths.size())
	print("bouts: %d" % bouts)
	print("bouts leaving at least one man hurt: %d  (%.0f%%)" % [with_one,
		100.0 * float(with_one) / float(bouts)])
	print("knocks per bout: %.2f" % (float(knocks) / float(bouts)))
	print("events missed, mean %.1f  median %d  worst %d" % [mean,
		0 if lengths.is_empty() else lengths[lengths.size() / 2],
		0 if lengths.is_empty() else lengths[lengths.size() - 1]])
	quit(0)
