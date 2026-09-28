extends SceneTree
## Dev tool: render the Create screen. Both tabs, because the fighter one is
## the one with the cap drawn on it and the club one is the one with the crest.
##
##   xvfb-run -a godot --path . --script res://tools/shot_create.gd -- <tab> <out.png>

var which := "fighter"
var out_path := "user://create.png"
var n := 0
var scene: Node
var s2: Season


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		which = String(args[0])
	if args.size() > 1:
		out_path = String(args[1])
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 40
	Session.season = s
	s2 = s
	scene = load("res://scenes/Create.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if n == 2:
		if which == "grade":
			scene.tab = 2
			s2.grade = Grade.G.HARD_LIST
		elif which == "custom":
			scene.tab = 2
			s2.grade = Grade.G.CUSTOM
			s2.set_custom("bills", 0.7)
			s2.set_custom("scale", 1.06)
		elif which == "club":
			scene.tab = 1
			scene.shop.buy_icon(s2.office, 12)
			scene.icon_i = 12
			scene.pack_i = 1
		else:
			scene.card.display_name = "Hollis Vane"
			scene.card.strength = 58
			scene.card.base = 51
			scene.card.skill = 44
			scene.card.gas = 47
			scene.card.aggression = 40
			scene.card.weight = 246
			scene.card.pos = Tuning.Pos.CENTER
		scene._rebuild()
	if n < 8:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true
