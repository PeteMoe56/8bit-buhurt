extends SceneTree
## A NEW CAREER, ALL THREE STEPS (2 Oct 2026 playtest): the coach, the club,
## the grade, as a first-time player sees them.
##
##   bash tools/bb.sh shot founding 960x540 <out_dir>

var n := 0
var out := "user://founding"
var step := 0
const SCENES := ["res://scenes/Coach.tscn", "res://scenes/Create.tscn", "res://scenes/Create.tscn",
	"res://scenes/Create.tscn"]
var cur: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = String(a[0])
	DirAccess.make_dir_recursive_absolute(out)
	Settings.tips_enabled = false
	Session.season = Season.new(MeleeRosters.starting_club(), 20260912)
	## A coach not yet made: the names, the face and the background are on show.
	Session.season.coach.created = false
	_open()


func _open() -> void:
	if cur != null:
		cur.queue_free()
	Session.founding = true
	Session.create_tab = 1 if step == 1 else 2
	## The fourth picture is step 3 on CUSTOM, every dial out.
	if step == 3:
		Session.season.grade = Grade.G.CUSTOM
	cur = (load(SCENES[step]) as PackedScene).instantiate()
	root.add_child.call_deferred(cur)
	n = 0


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("%s/step_%d.png" % [out, step + 1])
	print("wrote step %d" % (step + 1))
	step += 1
	if step >= SCENES.size():
		return true
	_open()
	return false
