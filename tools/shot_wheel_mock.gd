extends SceneTree
## BACKGROUNDS FOR THE WHEEL MOCKUPS (2 Oct 2026). The real fight, a pair at
## contact, with no wheel drawn — so the options can be drawn over it.
##
##   bash tools/bb.sh shot wheel_mock 960x540 <mode> <spot> <out.png>
##   mode: plain (no wheel, no bar) | wheel (today's wheel) | bar (the timed strip over a man on his own)
##         | clinch (a clinched man's Takedown/Hold/Escape strip)
##         | clinch_plain (the clinch, no strip)
##   spot: mid | edge (top rail, near our end) | far (bottom rail, near theirs)
## Prints our man's and his target's screen positions for the overlay.

var mode := "plain"
var spot := "mid"
var out_path := "user://wheel_mock.png"
var n := 0
var scene: Node


func _initialize() -> void:
	Settings.tips_enabled = false
	seed(20260914)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		mode = String(a[0])
	if a.size() > 1:
		spot = String(a[1])
	if a.size() > 2:
		out_path = String(a[2])
	## "wheel": today's contact wheel, at the same spots, for the comparison.
	Tuning.contact_wheel = mode == "wheel"
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if scene != null and bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 6:
		scene.call("_clear_corner")
		scene.set("screen", 2)
		var sim: MeleeSim = scene.sim
		sim.phase = MeleeSim.Phase.LIVE
		## Past the first-order band, so it does not cover the pair.
		sim.orders_issued = 1
		var us = sim.men[2]
		var them = sim.men[7]
		var at := Vector2(Tuning.LIST_W * 0.5, Tuning.LIST_H * 0.45)
		if spot == "edge":
			at = Vector2(22.0, Tuning.LIST_H * 0.22)
		elif spot == "far":
			at = Vector2(Tuning.LIST_W - 22.0, Tuning.LIST_H * 0.78)
		them.pos = at
		them.state = MeleeSim.State.CLOSING
		them.target = us.idx
		us.pos = at + Vector2(0, -26) if spot != "mid" else at + Vector2(-26, 0)
		if mode == "clinch" or mode == "clinch_plain":
			sim._enter_grapple(us, them)
			if mode == "clinch":
				sim._open_prompt(us, Tuning.Menu.GRAPPLED, them.idx)
		elif mode == "wheel":
			var path: Array[Vector2] = []
			sim.give_order(us.idx, path, them.idx)
			sim._open_prompt(us, Tuning.Menu.APPROACH, them.idx)
		elif mode == "bar":
			sim._open_prompt(us, Tuning.Menu.APPROACH, them.idx)
			us.prompt.t = Tuning.PROMPT_TIME * 0.6
	if n == 9:
		var sim: MeleeSim = scene.sim
		## Hold the frame still: no ticking between the setup and the picture.
		scene.set("paused", true)
		var us_p: Vector2 = scene.call("_to_screen", sim.men[2].pos)
		var them_p: Vector2 = scene.call("_to_screen", sim.men[7].pos)
		print("POS us %d %d them %d %d" % [us_p.x, us_p.y, them_p.x, them_p.y])
	if n == 14:
		root.get_texture().get_image().save_png(out_path)
		print("wrote %s" % out_path)
		return true
	return false
