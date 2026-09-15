extends SceneTree
## THE FIXTURE CARD, the ticker, and the sim confirm.
var n := 0
var stage := 0
var sc: Node = null
var s: Season = null
func _initialize() -> void:
	s = Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	## A RESULT IN THE BOOK, so the tape has something to say about this club
	## and not only about the table.
	s.skip_event()
	## AND ANSWER WHATEVER CAME UP. A dilemma blocks the fixture card, and a
	## shot of the card taken through a dilemma is a shot of the dilemma.
	if not s.dilemma_card().is_empty():
		s.answer_dilemma(0)
	sc = load("res://scenes/Season.tscn").instantiate()
	sc.set("tab", 0)
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 30: return false
	n = 0
	match stage:
		0:
			root.get_texture().get_image().save_png("res://shots/fixture_tape.png")
			print("wrote fixture_tape")
			sc.set("sim_asking", true)
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/fixture_sim.png")
			print("wrote fixture_sim")
			return true
	stage += 1
	return false
