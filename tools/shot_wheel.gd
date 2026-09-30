extends SceneTree
## THE CONTACT WHEEL, CAPTURED (29 Sep 2026).
##
##   bash tools/bb.sh shot wheel 960x540 <mode> <out.png>
##   mode: approach (a man sent at a free enemy) | behind (from his back)
##         | third (onto an enemy already in a clinch) | hot (approach, thumb on Hit)
##
## Puts one of our men beside an enemy, gives him a route onto that man, opens
## the question the sim would open at contact, and draws the frame.

var mode := "approach"
var out_path := "user://wheel.png"
var n := 0
var scene: Node


func _initialize() -> void:
	Settings.tips_enabled = false
	seed(20260914)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		mode = String(a[0])
	if a.size() > 1:
		out_path = String(a[1])
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if scene != null and bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 6:
		## Off the walk-out properly: its button is a corner node.
		scene.call("_clear_corner")
		scene.set("screen", 2)
		var sim: MeleeSim = scene.sim
		sim.phase = MeleeSim.Phase.LIVE
		var us = sim.men[2]
		var them = sim.men[7]
		## The middle of the list (x runs along the charge, y rail to rail).
		var mid := Vector2(Tuning.LIST_W * 0.5, Tuning.LIST_H * 0.45)
		them.pos = mid
		them.state = MeleeSim.State.CLOSING
		if mode == "third":
			var mate = sim.men[3]
			mate.pos = mid + Vector2(-22, 0)
			sim._enter_grapple(mate, them)
			us.pos = mid + Vector2(24, 8)
		elif mode == "behind":
			them.target = sim.men[4].idx
			sim.men[4].pos = mid + Vector2(-60, 0)
			us.pos = mid + Vector2(24, 4)
		else:
			them.target = us.idx
			us.pos = mid + Vector2(-26, 0)
		var path: Array[Vector2] = []
		sim.give_order(us.idx, path, them.idx)
		var menu: int = Tuning.Menu.THIRD_MAN if them.state == MeleeSim.State.GRAPPLED else Tuning.Menu.APPROACH
		sim._open_prompt(us, menu, them.idx)
	## "hot": the approach wheel mid-drag, the thumb on Hit.
	if n == 10 and mode == "hot":
		scene.set("wheel_drag", true)
		scene.set("wheel_hot", Tuning.Act.HIT)
		scene.queue_redraw()
	if n == 14:
		var img := root.get_texture().get_image()
		img.save_png(out_path)
		print("wrote %s (wheel_man %d) screen %s" % [out_path, int(scene.get("wheel_man")), str(UiKit.screen())])
		return true
	return false
