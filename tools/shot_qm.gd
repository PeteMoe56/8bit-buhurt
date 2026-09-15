extends SceneTree
## THE ARMORER'S TABLE, in the three states that matter.
##
##   xvfb-run -a godot --path . --script res://tools/shot_qm.gd
##
## A squad in good order, a squad in trouble, and one man selected — because the
## screen's whole job is to tell those apart at a glance, and one frame of a
## healthy club proves only that the table draws.
var n := 0
var stage := 0
var sc: Node = null
var s: Season = null

func _initialize() -> void:
	s = Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 40
	Session.season = s
	s.decline_bid()
	sc = load("res://scenes/Season.tscn").instantiate()
	sc.set("tab", 2)
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	n = 0
	match stage:
		0:
			root.get_texture().get_image().save_png("res://shots/qm_fresh.png")
			print("wrote qm_fresh")
			## A CLUB THAT HAS NOT SEEN AN ARMORER IN TWO SEASONS. Two men under
			## the line, two more inside a bad week of it, and a couple upgraded
			## so the grades and the ceiling notches are on the same screen.
			var r := s.club.roster
			for i in r.size():
				r[i].armor = 0.86 - 0.055 * float(i)
			r[2].harness = Quartermaster.Grade.FITTED
			r[2].armor = 1.0
			r[4].harness = Quartermaster.Grade.SERVICEABLE
			r[4].armor = 0.72
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/qm_worn.png")
			print("wrote qm_worn")
			sc.set("qm_pick", s.club.roster[4])
			sc.call("_rebuild")
		2:
			root.get_texture().get_image().save_png("res://shots/qm_picked.png")
			print("wrote qm_picked")
			return true
	stage += 1
	return false
