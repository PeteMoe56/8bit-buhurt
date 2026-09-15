extends SceneTree
## Dev tool: the feel layer, caught in the act.
##
## Every effect in `Juice` is two frames long or a tenth of a second, which is
## the whole point of them and also the reason none of them can be checked by
## playing the game — by the time you have seen it, it is over. This freezes
## each one at the frame it matters and writes it out.
##
##   xvfb-run -a godot --path . --script res://tools/shot_juice.gd -- <dir>

var out_dir := "user://"
var stage := 0
var n := 0
var scene: Node = null


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = String(args[0])
	Session.season = Season.new(MeleeRosters.player_club(), 4242)
	var packed: PackedScene = load("res://scenes/Season.tscn")
	scene = packed.instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	## THE FLASH IS TWO FRAMES and the wipe is eight steps in 130ms, so the
	## settle this tool allows itself before each shot has to be shorter than
	## the thing it is trying to photograph. Four frames is fine for a popup
	## and is twice as long as a flash exists for.
	var settle := 1 if stage == 5 else 4
	if n < settle:
		return false
	match stage:
		0:
			_shot("00_clean")
			## A purse change, popped where the player is looking.
			Juice.reset()
			Juice.pop("purse", "+18 CC", Vector2(660.0, 32.0), UiKit.UP)
			Juice.pop("wage", "-6 CC", Vector2(300.0, 200.0), UiKit.DOWN)
			Juice.pop("xp", "+1 XP", Vector2(120.0, 320.0), UiKit.YOU)
			for i in 20:
				Juice.tick(1.0 / 60.0)
		1:
			_shot("01_popups")
			Juice.reset()
			Juice.event("shake", Juice.Rank.HUGE, {"trauma": 1.0})
		2:
			_shot("02_shake")
			Juice.reset()
			Juice._wipe = {"t": Juice.WIPE_S * 0.4, "path": "", "taken": true}
		3:
			_shot("03_wipe_covering")
			Juice.reset()
			Juice._wipe = {"t": Juice.WIPE_S * 1.5, "path": "", "taken": true}
		4:
			_shot("04_wipe_lifting")
			Juice.reset()
			Juice._flash = 2
			Juice._flash_col = Color(1, 1, 1, 1)
		5:
			_shot("05_flash")
			print("done")
			quit(0)
			return true
	stage += 1
	n = 0
	return false


func _shot(name_: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name_])
	print("wrote ", name_)
