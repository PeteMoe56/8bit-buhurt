extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260911)
	Session.season = s
	s.office.credits = 60
	## One five-star and one one-star, so the shot carries both ends of the model:
	## a man who teaches two jobs, a man who teaches none and lifts the room, and
	## the overlap between them that becomes the club's specialty.
	print(s.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.PHYSIO)))
	print(s.hire_captain(ClubOffice.captain("Ardry", Tuning.Role.CENTER, Tuning.Role.FLANK,
		3, ClubOffice.Trait.MOTIVATOR)))
	s.office.captains[1]["years"] = 1
	s.office.set_regime(0, ClubOffice.Regime.HARD)
	var packed: PackedScene = load("res://scenes/Staff.tscn")
	root.add_child(packed.instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("res://shots/staff.png")
	print("wrote staff")
	return true
