extends SceneTree
## THE CLUB TAB'S POPUPS (2 Oct 2026 playtest): the home town picker and the
## mark colours, one picture each.
##
##   bash tools/bb.sh shot popups 960x540 <out_dir>

var n := 0
var out := "user://popups"
var which := ["town", "mark"]
var i := 0
var cur: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = String(a[0])
	DirAccess.make_dir_recursive_absolute(out)
	Settings.tips_enabled = false
	Session.season = Season.new(MeleeRosters.starting_club(), 20260912)
	_open()


func _open() -> void:
	## FREED NOW, NOT QUEUED (Screen Score #1, S40): a queued free left the old
	## Create alive beside the new one for a frame, and the wide-screen frame
	## offset was applied twice — the grey strip and the off-centre popup in
	## v19x9/40_popup_* were this tool, not the game.
	if cur != null:
		cur.free()
	Session.create_tab = 1
	cur = (load("res://scenes/Create.tscn") as PackedScene).instantiate()
	root.add_child.call_deferred(cur)
	n = 0


func _process(_d: float) -> bool:
	n += 1
	if n == 4:
		cur.set("popup", which[i])
		cur.call("_rebuild")
	if n < 9:
		return false
	root.get_texture().get_image().save_png("%s/%s.png" % [out, which[i]])
	print("wrote %s" % which[i])
	i += 1
	if i >= which.size():
		return true
	_open()
	return false
