extends SceneTree
## THE PROMOTION OFFER, which is the only screen in the game that asks you
## whether you want the thing you just won.
##
##   xvfb-run -a godot --path . --script res://tools/shot_promotion.gd
##
## Reaching it needs a club that actually finished in a promotion place, so this
## walks a season and then puts the club top of its table rather than setting a
## flag — **a check that reaches a state by a road the game does not have is
## measuring a state the game cannot be in**, and this project has shipped that
## mistake twice.
var n := 0

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	var guard := 0
	while not s.season_complete() and guard < 40:
		guard += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"cup": s.sim_cup_tie()
			_: s.skip_event()
	## TOP OF THE TABLE, by giving the club the points rather than by editing
	## `position()`. The table is what `promotion_place()` reads.
	var row: Dictionary = s.world.tables[s.world.player_tier()][s.world.player_club]
	row["points"] = 999
	row["mf"] = 999
	## AND CLEAR THE QUEUE. `blocked_by()` drains one thing at a time and a card
	## left on the table outranks the promotion — which is correct behaviour and
	## the wrong screen to photograph.
	var g2 := 0
	while s.blocked_by() != "" and s.blocked_by() != "promotion" and g2 < 8:
		g2 += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"cup": s.sim_cup_tie()
	s.office.credits = 21
	Session.season = s
	var sc: Node = load("res://scenes/Season.tscn").instantiate()
	root.add_child(sc)
	print("blocked_by = '%s', offered = %s, place = %d"
		% [s.blocked_by(), str(s.promotion_offered()), s.position()])

func _process(_d: float) -> bool:
	n += 1
	if n < 10:
		return false
	root.get_texture().get_image().save_png("res://shots/promotion.png")
	print("wrote promotion")
	return true
