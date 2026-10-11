extends SceneTree
## TEAM USA IN THE FIGHT (11 Oct 2026): the player's club wearing the tabard
## against a guest nation — both banners show flags, names and national kit.
##
##   bash tools/bb.sh shot tabard [WxH]   -> shots/tabard_splash.png, tabard_fight.png
var n := 0
var scene: Node


func _initialize() -> void:
	Settings.tips_enabled = false
	seed(20261011)
	var a := MeleeRosters.starting_club()
	a.wear("USA")
	var b := MeleeRosters.rival_club()
	b.display_name = "Team Ukraine"
	b.short_name = "UKR"
	b.kit = Nations.kit("UKR")
	b.icon_color = Nations.mark("UKR")
	b.flag = "UKR"
	Session.bout = MeleeSim.new(a, b, 4242)
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if n == 8:
		root.get_texture().get_image().save_png("res://shots/tabard_splash.png")
		print("wrote tabard_splash")
	if bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 12:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	if n == 160:
		root.get_texture().get_image().save_png("res://shots/tabard_fight.png")
		print("wrote tabard_fight")
		return true
	return false
