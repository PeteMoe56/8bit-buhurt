extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260911)
	Session.season = s
	## Give the man a book, so the third column is drawn with something in it.
	var f: FighterCard = s.club.starting_five()[2]
	f.bouts = 41
	f.downs = 66
	f.best_downs = 5
	f.rounds_standing = 92
	f.knocks = 3
	f.honours = 1
	## A LEVEL WAITING TO BE SPENT, so the row of +1 buttons is in the shot. A
	## screenshot of the state the screen spends most of its time in is a
	## screenshot of the case that was already working.
	## ...and he must be YOUNG ENOUGH AND SHORT ENOUGH OF HIS CEILING to place
	## it. The first version of this shot took the third man of the starting
	## five as he came — thirty-nine years old and already at his potential — so
	## `levels_waiting` was zero, the row never drew, and the screenshot proved
	## the layout of the empty case. The row it was taken for was 164px into the
	## button beside it.
	## THIRTY, which is past `LEARN_PAR` far enough to read "slow to learn" under
	## the bar. A man at par shows the line blank, which is a picture of the
	## feature switched off.
	f.age = 30
	f.potential = 99
	f.level = 6
	f.xp = Career.next_level_at(f) + 2
	## TOXIC ON PURPOSE. The chip on strength and gas only draws when the mood
	## reaches it, so a contented man in the shot would prove the layout of a
	## screen the player never sees at the moment it matters.
	f.morale = 0.11
	Session.viewing_fighter = f
	var packed: PackedScene = load("res://scenes/Fighter.tscn")
	root.add_child(packed.instantiate())
var stage := 0
var scene: Node


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	match stage:
		0:
			root.get_texture().get_image().save_png("res://shots/fighter.png")
			## AND THE OTHER HALF OF THE SAME BAND.
			##
			## The row of +1 buttons and the two PURCHASED rows — extra reps and
			## the armourer — share the strip at `LEVEL_ROW_Y`, because a level
			## waiting is a state the player clears on sight and the band is free
			## almost always. So one shot can only ever show one of them, and the
			## first version of this tool showed the +1 row and nothing else.
			##
			## This is the third time this project has photographed one arm of a
			## branch and called it the screen. Take both.
			var man: FighterCard = Session.viewing_fighter
			man.xp = 0
			man.armor = 0.42
			for c in root.get_children():
				if c.has_method("_build"):
					c.call("_build")
			stage = 1
			n = 0
			return false
		1:
			root.get_texture().get_image().save_png("res://shots/fighter_meeting.png")
			## AND THE CARD ITSELF, open, which is a third arm of the same branch
			## and the one the whole feature lives in.
			for c in root.get_children():
				if c.has_method("_build"):
					c.set("meeting_open", true)
					c.call("_build")
			stage = 2
			n = 0
			return false
		2:
			root.get_texture().get_image().save_png("res://shots/meeting_card.png")
			## AND THE ROLL, MID-FLIGHT.
			##
			## "You can actually see the effect" is a claim about MOTION, and a
			## screenshot has one frame. So buy something and photograph the card
			## while the numbers are still on their way: a still of a counter
			## halfway up is the only evidence a still can give that it counts.
			Session.season.office.credits = 60
			for c in root.get_children():
				if c.has_method("_buy"):
					c.call("_buy", "kit")
			stage = 3
			n = 6
			return false
		3:
			root.get_texture().get_image().save_png("res://shots/meeting_rolling.png")
			## THE ROLL IS 0.55s AND THIS WAITED FOUR FRAMES, so the "finished"
			## shot was still mid-flight at 50%. A still of the END has to be
			## taken after the end.
			stage = 4
			n = -28
			return false
		_:
			root.get_texture().get_image().save_png("res://shots/meeting_done.png")
			print("wrote fighter, fighter_meeting, meeting_card, meeting_rolling, meeting_done")
			return true
	return false
