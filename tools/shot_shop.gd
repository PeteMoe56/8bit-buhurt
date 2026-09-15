extends SceneTree
## THE COUNTER, WITH THE COUNTER OPEN.
##
##   xvfb-run -a godot --path . --script res://tools/shot_shop.gd
##
## `Store.available()` is false on this machine and on every build without the
## billing plugin, which is correct and means the shop's buttons never draw. So
## the tool forces the state — the ONE road the game does not have, taken on
## purpose and only here, because the alternative is shipping a screen nobody
## has ever seen. The shut version is photographed too, since that is the one
## every desktop player gets.
var n := 0
var shut := false
var modal := false
var modal_shut := false

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	s.office.credits = 11
	Store.owed = 7
	Store.state = Store.State.READY
	var scene: Node = load("res://scenes/Season.tscn").instantiate()
	scene.set("tab", 3)
	root.add_child(scene)

func _process(_d: float) -> bool:
	n += 1
	if n < 10:
		return false
	if not shut:
		root.get_texture().get_image().save_png("res://shots/clubhouse_shop.png")
		print("wrote clubhouse_shop")
		shut = true
		Store.state = Store.State.UNAVAILABLE
		Store.owed = 0
		for c in root.get_children():
			if c.has_method("_rebuild"):
				c.call("_rebuild")
		n = 0
		return false
	if not modal:
		root.get_texture().get_image().save_png("res://shots/clubhouse_shut.png")
		print("wrote clubhouse_shut")
		## AND THE MODAL ITSELF, which is the screen that takes money and the one
		## no other shot in the repo has ever shown. Opened straight rather than
		## through the nav button: the button is a Control and a tool cannot press
		## one, and photographing the state is the point — how it is reached is
		## `test_season.gd`'s job.
		modal = true
		Store.state = Store.State.READY
		Store.owed = 0
		for c in root.get_children():
			if c.has_method("_rebuild"):
				c.set("shop_open", true)
				c.call("_rebuild")
		n = 0
		return false
	if not modal_shut:
		root.get_texture().get_image().save_png("res://shots/clubhouse_modal.png")
		print("wrote clubhouse_modal")
		## AND THE MODAL WITH THE COUNTER SHUT, which is what every desktop player
		## sees and what `Store.closed_word()` exists to say. A shop that shows
		## three buttons it cannot honour takes a tap and does nothing; this frame
		## is the proof that it does not.
		modal_shut = true
		Store.state = Store.State.UNAVAILABLE
		for c in root.get_children():
			if c.has_method("_rebuild"):
				c.call("_rebuild")
		n = 0
		return false
	root.get_texture().get_image().save_png("res://shots/clubhouse_modal_shut.png")
	print("wrote clubhouse_modal_shut")
	return true
