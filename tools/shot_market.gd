extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260911)
	Session.season = s
	s.office.credits = 30
	var packed: PackedScene = load("res://scenes/Market.tscn")
	root.add_child(packed.instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("res://shots/market.png")
	print("wrote market")
	return true
