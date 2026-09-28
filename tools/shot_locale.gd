extends SceneTree
## A SCREEN IN ANOTHER LANGUAGE, for eyeballing a draft.
##
##   bash tools/bb.sh shot locale 960x540 <locale> <scene name> [tab] [out.png]
##   e.g. ... shot locale 960x540 de Season 1 /tmp/de_squad.png
var n := 0
var out := "res://shots/locale.png"
var tab := -1
var scene: Node
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var loc := a[0] if a.size() > 0 else "de"
	var nm := a[1] if a.size() > 1 else "Season"
	tab = int(a[2]) if a.size() > 2 else -1
	if a.size() > 3:
		out = a[3]
	Juice.set_enabled(false)
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	## Load the player's settings FIRST and then override them, so a scene that
	## calls load_once on _ready finds it done and builds its buttons in `loc`.
	Settings.load_once()
	Settings.language = loc
	Settings.apply_language()
	scene = (load("res://scenes/%s.tscn" % nm) as PackedScene).instantiate()
	root.add_child(scene)
func _process(_d: float) -> bool:
	n += 1
	TranslationServer.set_locale(OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "de")
	## A scene that loads Settings on _ready puts the player's own language
	## back; set ours again and have it redrawn, or a screen drawn once keeps English.
	scene.queue_redraw()
	if n == 3 and tab >= 0 and "tab" in scene:
		scene.set("tab", tab)
		scene.call("_rebuild")
	if n < 9:
		return false
	root.get_texture().get_image().save_png(out)
	print("wrote ", out)
	quit(0)
	return true
