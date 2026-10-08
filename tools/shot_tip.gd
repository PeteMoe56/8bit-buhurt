extends SceneTree
## THE ONE-TIME COACH MARKS, CAPTURED (29 Sep 2026).
##
##   bash tools/bb.sh shot tip 960x540 route|corner <out.png>
##
## A career bout with a throwaway settings file, so the tip is always due and
## the developer's own settings never learn it was seen.
var which := "route"
var out_path := "user://tip.png"
var n := 0
var scene: Node


func _initialize() -> void:
	seed(20260914)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: which = String(a[0])
	if a.size() > 1: out_path = String(a[1])
	Settings.path = "user://shot_tip_settings.cfg"
	Settings.tips_enabled = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if scene != null and bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 6:
		var sim: MeleeSim = scene.sim
		if which == "corner":
			sim.phase = MeleeSim.Phase.CORNER
			scene.set("screen", 3)
			scene.call("_show_strategy_panel")
		else:
			## OFF THE WALK-OUT FIRST, as FIGHT does: its Back and Walk out live on
			## the shared layer and this tool used to leave them under the live
			## fight (Screen Score #1, S29: a fixture artifact, not the game).
			scene.call("_clear_corner")
			scene.call("_hide_panel")
			sim.phase = MeleeSim.Phase.LIVE
			scene.set("screen", 2)
	if n == 16:
		root.get_texture().get_image().save_png(out_path)
		print("wrote %s (tip '%s')" % [out_path, String(scene.get("tip"))])
		return true
	return false
