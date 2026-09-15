extends SceneTree
## A CLUB THAT NEVER WINS, AGAINST ONE THAT DOES.
##
##   godot --headless --path . --script res://tools/probe_purse2.gd
##
## The first purse probe walked a club that picked up a few results and finished
## three seasons on 92 CC — so there IS income, and Pete's *"no income weekly
## ever"* is not literally true. What he is describing is the club that loses,
## which is the club the ladder measurement says he will be: a bottom side that
## finishes outside the top three earns no position money at all.
##
## This runs the two ends against each other. Nothing here is tuned; it is the
## number the tuning decision needs.
func _initialize() -> void:
	for mode in ["as it falls", "forced to finish last"]:
		var s := Season.new(MeleeRosters.starting_club(), 4242)
		var start := s.office.credits
		var seasons := 0
		for ev in 60:
			if mode != "as it falls":
				## A CLUB WITH NOTHING ON THE LINE. Stripping the squad to the
				## five is the honest way to make it lose — it loses because it
				## is worse, which is the case being measured, rather than
				## because a number was written into the table.
				for f in s.club.roster:
					f.armor = maxf(FighterCard.INSPECTION_MIN + 0.01, f.armor - 0.02)
			s.skip_event()
			if s.season_complete():
				s.roll_over()
				seasons += 1
				if seasons >= 3:
					break
		print("%-24s  %2d -> %3d CC over 3 seasons  (%d a season)  finished %s" % [
			mode, start, s.office.credits,
			int(round(float(s.office.credits - start) / 3.0)),
			str(s.position())])
	quit(0)
