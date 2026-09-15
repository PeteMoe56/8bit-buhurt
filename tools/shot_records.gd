extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260911)
	Session.season = s
	s.world.note_record("downs_event", 6, "Ellis", 2)
	s.world.note_record("downs_career", 91, "Calder", 3)
	s.world.note_record("events", 57, "Calder", 3)
	s.world.note_record("standing", 130, "Croft", 3)
	s.world.note_record("rating", 61, "Salt", 3)
	s.world.history.append({"season": 1, "tier": 0, "position": 4, "promoted": false, "relegated": false, "row": {}})
	s.world.history.append({"season": 2, "tier": 0, "position": 1, "promoted": true, "relegated": false, "row": {}})
	s.world.history.append({"season": 3, "tier": 1, "position": 9, "promoted": false, "relegated": false, "row": {}})
	var packed: PackedScene = load("res://scenes/Records.tscn")
	root.add_child(packed.instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("res://shots/records.png")
	print("wrote records")
	return true
