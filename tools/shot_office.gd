extends SceneTree
## The Clubhouse tab, with the two caps — money and places on the bus.
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.player_club(), 4242)
	s.office.credits = 46
	s.office.new_week(); s.office.buy_travel_slot()
	s.office.new_week(); s.office.upgrade(ClubOffice.Facility.TRAINING)
	s.office.new_week(); s.office.upgrade(ClubOffice.Facility.INFIRMARY)
	s.world.season = 4
	s.sync_power()
	Session.season = s
	var sc: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(sc)
	sc.call_deferred("set", "tab", 3)
func _process(_d: float) -> bool:
	n += 1
	if n == 3:
		for c in root.get_children():
			if c.has_method("_rebuild"):
				c.set("tab", 3)
				c.call("_rebuild")
	if n < 9: return false
	root.get_texture().get_image().save_png("res://shots/office.png")
	print("wrote office")
	return true
