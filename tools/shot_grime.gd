extends SceneTree
## THE GROUND AS IT GOES, in the five states the player can be in.
##
##   xvfb-run -a godot --path . --script res://tools/shot_grime.gd
##
## Five frames and not one, because the whole point of the overlay is that it
## reads as a SLIDE — spotless, worn, shabby, a ruin — and a single frame of a
## filthy arena proves only that the drawing code runs. What has to be true is
## that each step looks worse than the last and that none of them looks broken.
##
## The Arena level is set to the Sports hall rather than the back field, because
## a back field does not wear at all (`Arena.WEARS_FROM_LEVEL`) and a screenshot
## of the one ground the feature deliberately skips would be the check reaching
## a state by a road the game does not have.
var n := 0
var stage := 0
var sc: Node = null
var s: Season = null

## The five, in the order they happen to a club that stops paying attention.
## THE FIVE, one comfortably inside each band `Arena.condition_word()` names —
## 0.61 and 0.34 were the first cut and both sat a hair the WRONG side of a
## boundary, so the frame called "worn" printed "Shabby" across the top of
## itself. A fixture chosen near an edge is a fixture that tests the edge and
## labels the wrong thing.
const STEPS := [
	{"c": 1.00, "file": "grime_spotless"},
	{"c": 0.86, "file": "grime_wellkept"},
	{"c": 0.70, "file": "grime_worn"},
	{"c": 0.48, "file": "grime_shabby"},
	{"c": 0.08, "file": "grime_ruin"},
]


func _initialize() -> void:
	s = Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 40
	s.office.arena.level = 3
	s.office.arena.condition = float(STEPS[0]["c"])
	Session.season = s
	s.decline_bid()
	sc = load("res://scenes/Arena.tscn").instantiate()
	root.add_child(sc)


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	n = 0
	if stage >= STEPS.size():
		return true
	var step: Dictionary = STEPS[stage]
	root.get_texture().get_image().save_png("res://shots/%s.png" % String(step["file"]))
	print("wrote %s at condition %.2f — \"%s\", upkeep %d CC" % [
		String(step["file"]), float(step["c"]),
		s.office.arena.condition_word(), s.office.arena.upkeep_cost()])
	stage += 1
	if stage < STEPS.size():
		s.office.arena.condition = float(STEPS[stage]["c"])
		sc.call("_rebuild")
	return false
