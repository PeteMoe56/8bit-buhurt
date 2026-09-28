extends SceneTree
## The free-agent list. `-- [out.png] [scout grade]`: with a Scout of that grade
## on the staff, so the fullest shelf (a five-star Scout, twelve names) is drawn.
var n := 0
var out := "res://shots/market.png"
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var s := Season.new(MeleeRosters.starting_club(), 20260911)
	Session.season = s
	s.office.credits = 30
	if args.size() > 1:
		var c := ClubOffice.captain("Eyes", Tuning.Role.RAIL, Tuning.Role.CENTER, int(args[1]))
		c["trait"] = ClubOffice.Trait.SCOUT
		s.office.captains.append(c)
	var packed: PackedScene = load("res://scenes/Market.tscn")
	root.add_child(packed.instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png(out)
	print("wrote ", out)
	quit(0)
	return true
