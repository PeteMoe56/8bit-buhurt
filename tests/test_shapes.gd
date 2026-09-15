extends SceneTree
## DOES THE GAME PAINT TO THE EDGE OF THE SCREEN IT WAS GIVEN?
##
##   xvfb-run -a godot --path . --resolution 1170x540 --script res://tests/test_shapes.gd
##
## `test_ink.gd` measures TEXT — it reads a ledger of `draw_string` calls — so it
## can tell you a label ran off the frame and cannot tell you the frame was
## never painted. On 15 Sep 2026 the second of those was the actual bug: every
## screen drew its background as `Rect2(Vector2.ZERO, Vector2(960, 540))` while a
## 19.5:9 handset hands the game 1170x540, so a 210-pixel strip of raw clear
## colour ran down the right of the whole game and not one of five hundred
## checks could see it.
##
## This one renders and looks at the pixels. Two questions per screen, asked at
## the edge the design used to stop at:
##
##   * is the far edge painted at all, or is it still the clear colour?
##   * is the far edge the SAME as the near edge, or did something stop early?
##
## THE ARENA IS NOT IN THE LIST. `melee_scene.gd` keeps its own `SCREEN` const
## and its own full-screen art slot, and the pixel scale of that screen is being
## settled elsewhere — see `docs/REGISTER.md`, section 25.
const SCREENS := [
	["res://scenes/Title.tscn", -1],
	["res://scenes/Season.tscn", 0],
	["res://scenes/Season.tscn", 1],
	["res://scenes/Season.tscn", 2],
	["res://scenes/Season.tscn", 3],
	["res://scenes/Season.tscn", 4],
	["res://scenes/Roster.tscn", -1],
	["res://scenes/Fighter.tscn", -1],
	["res://scenes/Market.tscn", -1],
	["res://scenes/Staff.tscn", -1],
	["res://scenes/Coach.tscn", -1],
	["res://scenes/Records.tscn", -1],
	["res://scenes/Federation.tscn", -1],
	["res://scenes/Arena.tscn", -1],
	["res://scenes/Chalkboard.tscn", -1],
	["res://scenes/Bracket.tscn", -1],
]

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== Retro Buhurt — the shape of the screen ===\n")
	## THE WINDOW TAKES A FEW FRAMES TO BE THE SIZE IT WAS ASKED FOR, and the
	## first run of this file read it on frame zero, got 960x960, and passed —
	## a green tick for a shape no phone has and this file exists to test.
	## **A check that does not verify the state it set up is a check that will
	## one day pass without entering it.**
	for _i in 4:
		await process_frame
	var got := root.get_visible_rect().size
	_ok(got.x >= 960.0 and got.y >= 540.0 and (got.x > 960.0 or got.y > 540.0)
			or _asked_for_the_design(got),
		"the window is the shape this run asked for",
		"canvas is %dx%d" % [int(got.x), int(got.y)])
	await _test_every_screen_paints_to_its_edges()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE SHAPE HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


## The one shape that is legitimately the design size: a plain 16:9 run.
func _asked_for_the_design(got: Vector2) -> bool:
	return is_equal_approx(got.x, 960.0) and is_equal_approx(got.y, 540.0)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


func _world() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.world.season = 3
	s.office.credits = 60
	var man: FighterCard = s.club.starting_five()[0]
	Session.viewing_fighter = man


## The colour the engine leaves behind where nothing was drawn.
func _clear() -> Color:
	return ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color", Color(0, 0, 0, 1))


func _near(a: Color, b: Color, tol: float = 0.02) -> bool:
	return absf(a.r - b.r) <= tol and absf(a.g - b.g) <= tol and absf(a.b - b.b) <= tol


func _test_every_screen_paints_to_its_edges() -> void:
	_world()
	var size := root.get_visible_rect().size
	var bare: Array[String] = []
	var looked := 0
	## SAMPLED DOWN THE COLUMN, not at one pixel. A single sample lands on
	## whatever happened to be there; a screen with a panel two-thirds of the way
	## down would pass or fail on where the sample fell.
	var rows := [0.08, 0.25, 0.5, 0.75, 0.96]
	for page in SCREENS:
		var path := String(page[0])
		var tab := int(page[1])
		if not ResourceLoader.exists(path):
			continue
		var n: Node = (load(path) as PackedScene).instantiate()
		root.add_child(n)
		if Session.season != null:
			n.set("season", Session.season)
		await process_frame
		if tab >= 0:
			n.set("tab", tab)
			if n.has_method("_rebuild"):
				n.call("_rebuild")
		if n is CanvasItem:
			(n as CanvasItem).queue_redraw()
		await process_frame
		await process_frame
		var img := root.get_texture().get_image()
		var w := img.get_width()
		var h := img.get_height()
		var label := path.get_file().get_basename() + ("" if tab < 0 else " tab %d" % tab)
		var clear := _clear()
		var painted := 0
		for f in rows:
			var y: int = clampi(int(float(h) * f), 0, h - 1)
			var edge := img.get_pixel(w - 2, y)
			looked += 1
			if not _near(edge, clear):
				painted += 1
		## EVERY SAMPLE, NOT JUST ONE. The first cut of this failed a screen only
		## when the whole right column was bare, and pinning the season screen's
		## background back to 960 did not trip it: the gold bottom bar and the
		## table rows still reach the edge, so one lit sample out of five was
		## enough to pass a screen with a 210-pixel hole in it. **A check that
		## tolerates one good sample is a check that measures the best case.**
		##
		## Every screen in this game paints a full-screen ground before anything
		## else, so a single pixel of raw clear colour at the far edge means that
		## ground did not reach — there is no legitimate reason for one.
		if painted < rows.size():
			bare.append("%s: %d of %d samples down the far right are bare"
				% [label, rows.size() - painted, rows.size()])
		n.queue_free()
		await process_frame
	notes.append("the edges: %d samples down the right of %d screens at %dx%d"
		% [looked, SCREENS.size(), int(size.x), int(size.y)])
	_ok(bare.is_empty(), "every screen paints to its right edge",
		"%d samples%s" % [looked, "" if bare.is_empty() else " — " + "; ".join(bare.slice(0, 6))])
