extends SceneTree
## THE CLUB'S RECORD, on the page that used to be a tab.
##
##   xvfb-run -a godot --path . --script res://tools/shot_history.gd
##
## Five seasons deep, so both lists have something in them — an empty history
## page proves only that the tab row fits.
var n := 0
var stage := 0
var sc: Node = null

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	for y in 5:
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
	Session.records_page = Records.Page.HISTORY
	sc = load("res://scenes/Records.tscn").instantiate()
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 10:
		return false
	root.get_texture().get_image().save_png("res://shots/records_history.png")
	print("wrote records_history")
	return true
