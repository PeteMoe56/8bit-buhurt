extends SceneTree
## THE SQUAD TAB, and the reserve in two of its four orders.
var n := 0
var stage := 0
var sc: Node = null
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	sc = load("res://scenes/Season.tscn").instantiate()
	sc.set("tab", 1)
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 9: return false
	n = 0
	match stage:
		0:
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/squad_rating.png")
			print("wrote squad_rating")
			sc.set("reserve_sort", 1)
			sc.call("_rebuild")
		2:
			root.get_texture().get_image().save_png("res://shots/squad_age.png")
			print("wrote squad_age")
			return true
	stage += 1
	return false
