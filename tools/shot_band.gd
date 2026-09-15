extends SceneTree
## THE SCREENS THIS PASS TOUCHED, in the states that show the change.
var n := 0
var stage := 0
var sc: Node = null
var s: Season = null

func _initialize() -> void:
	s = Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 30
	Session.season = s
	Session.viewing_fighter = s.club.starting_five()[0]
	## A purse with something in it, so the clubhouse ledger has lines to draw.
	s.office.take(3, "The gate", "event")
	s.office.take(2, "Won the event", "event")
	s.office.take(6, "Members' dues", "season")

func _process(_d: float) -> bool:
	n += 1
	if n < 9:
		return false
	n = 0
	if sc != null:
		sc.queue_free()
		sc = null
	match stage:
		0:
			sc = load("res://scenes/Season.tscn").instantiate()
			sc.set("tab", 3)
			root.add_child(sc)
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/band_clubhouse.png")
			print("wrote band_clubhouse")
			sc = load("res://scenes/Fighter.tscn").instantiate()
			root.add_child(sc)
		2:
			root.get_texture().get_image().save_png("res://shots/band_fighter.png")
			print("wrote band_fighter")
			sc = load("res://scenes/Settings.tscn").instantiate()
			root.add_child(sc)
		3:
			root.get_texture().get_image().save_png("res://shots/band_settings.png")
			print("wrote band_settings")
			return true
	stage += 1
	return false
