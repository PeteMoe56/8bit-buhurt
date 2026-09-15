extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260911)
	## One difficult man on the line and one on the bench, so the shot shows the
	## stripe at both card sizes — a marker only proved on the big card is a
	## marker that goes missing on the twelve small ones.
	s.club.starting_five()[1].morale = 0.10
	s.club.active_eight()[6].morale = 0.30
	Session.season = s
	var packed: PackedScene = load("res://scenes/Roster.tscn")
	root.add_child(packed.instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("res://shots/roster.png")
	print("wrote roster")
	return true
