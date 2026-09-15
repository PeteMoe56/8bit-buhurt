extends SceneTree
## DID THE SPENDING DO ANYTHING AT ALL?
##
## `probe_climb.gd` walked fourteen seasons twice — once buying three levels per
## fighter per year, once buying nothing — and the two lines came back BYTE FOR
## BYTE IDENTICAL, down to the last club power. Two policies that differ by
## forty levels a season cannot produce the same career unless one of them never
## happened. **A column that matches another column exactly is not a result, it
## is a bug report.**
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	Session.season = s
	s.office.credits = 500
	var f: FighterCard = s.club.roster[0]
	print("before: credits=%d level=%d xp=%d power=%d club_power=%d"
		% [s.office.credits, f.level, f.xp, f.overall(), s.club.power()])
	for i in 4:
		var err := s.office.buy_level(f)
		print("  buy %d -> '%s'  credits=%d level=%d xp=%d overall=%d"
			% [i, err, s.office.credits, f.level, f.xp, f.overall()])
	print("club power now %d, world says %d"
		% [s.club.power(), int(s.world.clubs[s.world.player_club]["power"])])
	s.roll_over()
	print("after a summer, world says %d"
		% int(s.world.clubs[s.world.player_club]["power"]))
	quit()
