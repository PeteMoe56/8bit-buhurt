extends SceneTree
## THE FINANCES TAB, on a club with a year behind it.
##
##   xvfb-run -a godot --path . --script res://tools/shot_finances.gd
##
## Two frames: a club in its first weeks, where every heading is empty and the
## page has to say so without looking broken, and a club three seasons in with
## a full set of books and a ground it has let go. The empty state is the one
## that ships wrong, because it is the one nobody builds a fixture for.
var n := 0
var stage := 0
var sc: Node = null
var s: Season = null

func _initialize() -> void:
	s = Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	sc = load("res://scenes/Season.tscn").instantiate()
	sc.set("tab", 4)
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	n = 0
	match stage:
		0:
			root.get_texture().get_image().save_png("res://shots/fin_new.png")
			print("wrote fin_new")
			## THREE YEARS ON, with a ground that has been let go and a club that
			## has actually bought things.
			for y in 3:
				var guard := 0
				while not s.ready_to_roll() and guard < 80:
					guard += 1
					if s.bid_open():
						s.decline_bid()
					elif s.cup_pending():
						s.sim_cup_tie()
					else:
						s.skip_event()
				s.roll_over()
			s.office.credits = 90
			s.office.tier = 1
			s.office.arena.level = 3
			s.office.arena.condition = 0.44
			s.office.buy_harness(s.club.roster[0])
			s.office.buy_harness(s.club.roster[1])
			s.office.raise_cap()
			s.office.buy_travel_slot()
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/fin_years.png")
			print("wrote fin_years")
			return true
	stage += 1
	return false
