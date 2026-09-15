extends SceneTree
## HOW OFTEN DOES THE PLAYER ACTUALLY HOST?
##
## The arena's wear model solves for "a balanced fixture list averages to
## `Arena.WEAR_SEASON`", and balanced means half the events at home. That is an
## assumption about the schedule, made in a file that cannot see the schedule —
## exactly the kind of thing this project keeps finding out was wrong two
## leagues later. So: ask.
func _initialize() -> void:
	var home := 0
	var away := 0
	var neutral := 0
	var events := 0
	for k in 6:
		var s := Season.new(MeleeRosters.starting_club(), 1000 + k * 37)
		var n := s.world.events_this_season()
		for i in n:
			match s.venue_kind():
				Venue.Kind.HOME: home += 1
				Venue.Kind.AWAY: away += 1
				_: neutral += 1
			s.skip_event()
		events += n
	print("%d events over 6 seasons — home %d (%.1f%%), away %d, neutral %d"
		% [events, home, 100.0 * float(home) / maxf(1.0, float(events)), away, neutral])
	quit(0)
