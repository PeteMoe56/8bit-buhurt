extends SceneTree
## A CONTROLLER REACHES EVERY BUTTON (Steam Deck, 4 Oct 2026).
##
##   godot --headless --path . --script res://tests/test_pad.gd
##
## Every menu screen, built in the same lived-in world the shot tools use. From
## where a pad lands (`Pad.pick`), walk the d-pad in all four directions as far as
## it goes; every enabled button on the screen has to be in that walk. A button the
## d-pad cannot reach is a button a Steam Deck player cannot press. Also: A and B
## are bound, and a drawn row's hit box is in the focus chain.

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
	["15_guide", "res://scenes/Guide.tscn", 1],
	["16_arena", "res://scenes/Arena.tscn", -1],
	["17_chalkboard", "res://scenes/Chalkboard.tscn", -1],
	["18_create_fighter", "res://scenes/Create.tscn", 0],
	["19_create_club", "res://scenes/Create.tscn", 1],
	["20_create_grade", "res://scenes/Create.tscn", 2],
	["21_bracket", "res://scenes/Bracket.tscn", -1],
	## 100 + tab: that tab with the Club menu open over it.
	["22_club_menu", "res://scenes/Season.tscn", 103],
]

var world: Season
var i := 0
var n := 0
var node: Node = null
var failures: Array[String] = []
var checks := 0
var lines: Array[String] = []


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — a controller in the menus ===\n")
	Pad.setup()
	var a_ok := false
	var b_ok := false
	for e in InputMap.action_get_events("ui_accept"):
		a_ok = a_ok or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A)
	for e in InputMap.action_get_events("ui_cancel"):
		b_ok = b_ok or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
	_ok(a_ok and b_ok, "A presses, B goes back", "ui_accept has A: %s, ui_cancel has B: %s" % [a_ok, b_ok])
	seed(20260914)
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
		## DRAWN STRONG ON THE RIGHT (review round 3: the fixture saved a 2-1-2
		## under that name, and the reviewers read a symmetric "Strong Right").
		[Vector2(0.11, 0.04), Vector2(0.26, 0.04), Vector2(0.50, 0.09), Vector2(0.75, 0.15), Vector2(0.89, 0.15)])
	## A few results on the table, so the club tab is mid-season, not day one.
	## The start-of-year bid would block every event, so it is passed first.
	if world.bid_open():
		world.decline_bid()
	for k in 3:
		if world.blocked_by() == "":
			world.skip_event()




func _restore() -> void:
	Session.season = world
	Session.viewing_fighter = world.club.starting_five()[0]


## Everything the d-pad reaches from `from`.
func _walk(from: Control, all: Array[Control]) -> Dictionary:
	var seen := {from: true}
	var todo: Array = [from]
	while not todo.is_empty():
		var c: Control = todo.pop_back()
		for dir in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]:
			var nb: Control = Pad.neighbor(c, dir, all)
			if nb != null and not seen.has(nb):
				seen[nb] = true
				todo.append(nb)
	return seen


func _process(_d: float) -> bool:
	if i >= SCREENS.size():
		print("")
		for l in lines:
			print(l)
		print("")
		if failures.is_empty():
			print("THE PAD HOLDS (%d checks)\n" % checks)
			quit(0)
		else:
			for f in failures:
				print("FAIL: " + f)
			print("\n%d FAILED\n" % failures.size())
			quit(1)
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
		node.set("tab", int(row[2]) % 100)
		if int(row[2]) >= 100:
			node.set("club_menu_open", true)
		if node.has_method("_rebuild"):
			node.call("_rebuild")
	elif n == 5:
		var all := Pad.candidates(node)
		var start := Pad.pick(node, "", Vector2.INF)
		var missed: Array[String] = []
		if start != null:
			var seen := _walk(start, all)
			for c in all:
				if not seen.has(c):
					missed.append((c as Button).text if c is Button and (c as Button).text != "" else "[%s @%d,%d]" % [c.get_class(), int(c.global_position.x), int(c.global_position.y)])
		var label := String(row[0])
		lines.append("  %-22s %3d buttons, start '%s', unreachable %d %s" % [label, all.size(),
			(start as Button).text if start is Button else "-", missed.size(), "" if missed.is_empty() else str(missed)])
		_ok(all.is_empty() or (start != null and missed.is_empty()),
			"every button on %s is reachable with the d-pad" % label, "%d of %d unreachable %s" % [missed.size(), all.size(), str(missed)])
		if OS.get_environment("RB_PAD_SHOT") != "" and start != null:
			var nb := Pad.neighbor(start, Vector2.DOWN, all)
			(nb if nb != null else start).grab_focus()
	elif n == 6:
		if OS.get_environment("RB_PAD_SHOT") != "":
			root.get_texture().get_image().save_png("%s/%s.png" % [OS.get_environment("RB_PAD_SHOT"), String(SCREENS[i][0])])
		node.queue_free()
		node = null
	elif n == 7:
		n = 0
		i += 1
	return false
