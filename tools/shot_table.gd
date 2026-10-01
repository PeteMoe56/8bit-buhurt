extends SceneTree
## THE TABLE, BANDED, IN A DIVISION THAT HAS BOTH BANDS.
##
##   xvfb-run -a godot --path . --script res://tools/shot_table.gd
##
## The Backyard Circuit promotes one club and relegates nobody, so a shot of it
## proves half the change. This climbs to the second tier — eight clubs, two up
## and two down — which is the shallowest division in the game that has a drop
## zone at all, and the deepest one the player can actually reach: `probe_rich.gd`
## found that a club with an unlimited budget wins the Circuit four times in
## forty seasons and finishes last in the division above every single time.
##
## Reached by WINNING, not by writing a tier number into the world. The first cut
## of the review shot did the latter and threw on every draw.
var n := 0
var ready := false

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	Session.season = s
	var guard := 0
	while s.world.player_tier() < 1 and guard < 30:
		guard += 1
		_year(s)
		s.roll_over()
	if s.world.player_tier() < 1:
		print("never got up — nothing to photograph")
		quit()
		return
	## Half a season in, so the table has results in it: a column of zeroes is a
	## claim that every club is equal, and the bands are about who is where.
	var half := 0
	while not s.season_complete() and half < 4:
		half += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(s.dilemma_card()["options"].size() - 1)
				"cup": s.sim_cup_tie()
		s.skip_event()
	## AND THE QUEUE DRAINED BEFORE THE SHOT. The first run photographed a dilemma
	## card sitting over the whole screen — correctly, since a card blocks the
	## matchday, and the table is what this tool is for.
	var d := 0
	while d < 8 and s.blocked_by() != "":
		d += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"sendoff": s.answer_send_off()
			"cup": s.sim_cup_tie()
	print("photographing tier %d, position %d" % [s.world.player_tier(), s.position()])
	root.add_child(load("res://scenes/Season.tscn").instantiate())
	ready = true

func _year(s: Season) -> void:
	var guard := 0
	while not s.season_complete() and guard < 40:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(s.dilemma_card()["options"].size() - 1)
				"cup": s.sim_cup_tie()
		s.skip_event()
	s.office.credits += 3000
	for _c in 3:
		s.office.raise_cap()
	for f in s.club.roster:
		if Contracts.can_extend(f):
			s.extend(f)
		else:
			s.resign(f)
	var tries := 0
	while s.club.roster.size() < MeleeClub.SQUAD_MAX and tries < 30:
		tries += 1
		var best: FighterCard = null
		for f in s.market():
			if best == null or f.overall() > best.overall():
				best = f
		if best == null or s.sign_from_market(best) != "":
			break

func _process(_d: float) -> bool:
	if not ready:
		return false
	n += 1
	if n < 12:
		return false
	root.get_texture().get_image().save_png("res://shots/table_bands.png")
	print("wrote table_bands")
	return true
