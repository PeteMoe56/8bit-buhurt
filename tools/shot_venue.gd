extends SceneTree
## THE FIXTURE PANEL WITH A VENUE ON IT, home and away.
##
##   xvfb-run -a godot --path . --script res://tools/shot_venue.gd
##
## Two frames, and they have to be two: the whole point of notating the venue is
## that home and away look different, and one frame of either proves only that
## the line draws. Walks the season until it finds one of each.
var n := 0
var stage := 0
var sc: Node = null
var s: Season = null

func _initialize() -> void:
	s = Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	## A DIVISION UP, so the grounds in the fixture list are not all back fields
	## — the spread between clubs is the thing being photographed.
	s.world.clubs[s.world.player_club]["tier"] = 2
	s.world._new_season()
	s.office.tier = 2
	s.office.arena.level = 3
	s.office.notoriety = 62.0
	_seek(true)
	sc = load("res://scenes/Season.tscn").instantiate()
	root.add_child(sc)


## Walk to the next fixture of the kind we want.
func _seek(home: bool) -> void:
	var guard := 0
	while guard < 40:
		guard += 1
		if s.bid_open():
			s.decline_bid()
			continue
		## A DILEMMA TAKES THE WHOLE SCREEN and would photograph itself instead of
		## the fixture panel — the card is drawn by `_draw_club()` as an early
		## return. **A fixture that stops on a state the check is not about is a
		## check photographing the wrong screen.**
		if s.blocked_by() == "dilemma":
			s.answer_dilemma(0)
			continue
		if s.cup_pending():
			s.sim_cup_tie()
			continue
		if s.world.season_complete():
			s.roll_over()
			s.office.tier = 2
			continue
		if (s.venue_kind() == Venue.Kind.HOME) == home:
			return
		s.skip_event()


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	n = 0
	match stage:
		0:
			root.get_texture().get_image().save_png("res://shots/venue_home.png")
			print("wrote venue_home — %s" % str(s.gate_now()))
			s.skip_event()
			_seek(false)
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/venue_away.png")
			print("wrote venue_away — %s" % str(s.gate_now()))
			return true
	stage += 1
	return false
