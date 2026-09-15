extends SceneTree
## WHERE DOES A CLUB'S MONEY COME FROM, AND IS THERE ANY?
##
##   godot --headless --path . --script res://tools/probe_purse.gd
##
## Pete, item 25 of the 15 Sep playtest: *"No income weekly ever. You're set to
## lose and you'll die out if you don't win, which everyone outguns you
## already."* And item 15: *"Immediately feel outgunned by everyone in Backyard
## Circuit."*
##
## Those are the same complaint from two ends, and the ladder walk already
## measured the far end of it. This measures the near end: what a bottom-division
## club actually earns across its first three seasons, against what the levers on
## the clubhouse screen cost.
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var last := s.office.credits
	print("start: %d CC" % last)
	var season_no := 1
	for ev in 40:
		s.skip_event()
		var now := s.office.credits
		if now != last:
			print("  event %2d: %+d  -> %d CC" % [ev + 1, now - last, now])
			last = now
		if s.season_complete():
			s.roll_over()
			season_no += 1
			now = s.office.credits
			print("  == season %d rolled: %+d -> %d CC ==" % [season_no, now - last, now])
			last = now
			if season_no > 3:
				break
	print("")
	print("what the levers cost:")
	print("  cap raise      %d CC" % s.office.cap_cost())
	print("  a bus place    %d CC" % s.office.travel_cost())
	print("  a facility     %d CC" % s.office.facility_cost(ClubOffice.Facility.TRAINING))
	print("  a serviceable harness  %d CC   (x8 = %d)" % [
		Quartermaster.COST[Quartermaster.Grade.SERVICEABLE],
		Quartermaster.COST[Quartermaster.Grade.SERVICEABLE] * 8])
	quit(0)
