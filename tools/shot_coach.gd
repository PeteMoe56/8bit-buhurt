extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260912)
	## A coach several seasons in with a real book and a real list, because an
	## empty version of this screen proves only that the panels are the right size.
	s.world.season = 7
	s.coach.display_name = "Aldous Wrenn"
	s.coach.reputation = 15
	for _i in 63: s.coach.note_result(true, false)
	for _i in 11: s.coach.note_result(false, true)
	for _i in 29: s.coach.note_result(false, false)
	s.coach.seasons = 6
	s.coach.cups = 2
	s.coach.promotions = 3
	s.coach.relegations = 1
	s.coach.years_here = 4
	s.coach.posts.append({"club": 4, "season_joined": 4, "season_left": -1})
	Session.season = s
	root.add_child((load("res://scenes/Coach.tscn") as PackedScene).instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8: return false
	root.get_texture().get_image().save_png("res://shots/coach.png")
	print("wrote coach")
	return true
