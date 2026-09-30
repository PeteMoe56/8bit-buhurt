extends SceneTree
## EVERY MENU SCREEN, ONE PICTURE EACH (29 Sep 2026) — for a blind review.
##
##   bash tools/bb.sh shot all 960x540 <out_dir>
##
## The same lived-in world the ink sweep uses (season 3, captains, a saved
## chalkboard), re-asserted before every screen because Title clears it. The
## fight's screens have their own tools (shot_prefight, shot_melee, shot_wheel,
## shot_corner, shot_aar, shot_splash).

const SCREENS := [
	["01_start", "res://scenes/Start.tscn", -1],
	["02_title_slots", "res://scenes/Title.tscn", -1],
	["03_settings", "res://scenes/Settings.tscn", -1],
	["04_season_club", "res://scenes/Season.tscn", 0],
	["05_season_squad", "res://scenes/Season.tscn", 1],
	["06_season_armorer", "res://scenes/Season.tscn", 2],
	["07_season_clubhouse", "res://scenes/Season.tscn", 3],
	["08_season_finances", "res://scenes/Season.tscn", 4],
	["09_roster", "res://scenes/Roster.tscn", -1],
	["10_fighter", "res://scenes/Fighter.tscn", -1],
	["11_market", "res://scenes/Market.tscn", -1],
	["12_staff", "res://scenes/Staff.tscn", -1],
	["13_coach", "res://scenes/Coach.tscn", -1],
	["14_records", "res://scenes/Records.tscn", -1],
	["15_federation", "res://scenes/Federation.tscn", -1],
	["16_arena", "res://scenes/Arena.tscn", -1],
	["17_chalkboard", "res://scenes/Chalkboard.tscn", -1],
	["18_create_fighter", "res://scenes/Create.tscn", 0],
	["19_create_club", "res://scenes/Create.tscn", 1],
	["20_create_grade", "res://scenes/Create.tscn", 2],
	["21_bracket", "res://scenes/Bracket.tscn", -1],
]

var out_dir := "user://all"
var world: Season
var i := 0
var n := 0
var node: Node = null


func _initialize() -> void:
	seed(20260914)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = String(a[0])
	DirAccess.make_dir_recursive_absolute(out_dir)
	Settings.tips_enabled = false
	world = Season.new(MeleeRosters.starting_club(), 4242)
	world.world.season = 3
	world.office.credits = 60
	world.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.PHYSIO))
	world.hire_captain(ClubOffice.captain("Ardry", Tuning.Role.CENTER, Tuning.Role.FLANK,
		3, ClubOffice.Trait.MOTIVATOR))
	world.board.unlock_formation(world.office)
	world.board.save_formation(0, "Strong Right",
		world.board.spots_for(Tuning.Formation.TWO_ONE_TWO))
	## A few results on the table, so the club tab is mid-season, not day one.
	for k in 3:
		if world.blocked_by() == "":
			world.skip_event()


func _restore() -> void:
	Session.season = world
	Session.viewing_fighter = world.club.starting_five()[0]


func _process(_d: float) -> bool:
	if i >= SCREENS.size():
		print("wrote %d screens to %s" % [SCREENS.size(), out_dir])
		return true
	var row: Array = SCREENS[i]
	n += 1
	if n == 1:
		_restore()
		node = (load(String(row[1])) as PackedScene).instantiate()
		root.add_child(node)
		if Session.season != null:
			node.set("season", Session.season)
	elif n == 3 and int(row[2]) >= 0:
		node.set("tab", int(row[2]))
		if node.has_method("_rebuild"):
			node.call("_rebuild")
	elif n == 7:
		root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, String(row[0])])
		node.queue_free()
		node = null
	elif n == 9:
		n = 0
		i += 1
	return false
