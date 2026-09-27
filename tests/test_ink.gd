extends SceneTree
## THE HALF `test_layout.gd` ADMITS IT CANNOT SEE.
##
##   godot --headless --path . --script res://tests/test_ink.gd
##
## That file opens by saying so:
##
##   > WHAT IT CANNOT SEE: drawn text. `draw_string` leaves no node behind, so a
##   > label running into a number is still only findable by rendering.
##
## Which was fine while every screen drew in `ThemeDB.fallback_font` and nobody
## moved anything. It stopped being fine the moment the real face went in: Buhurt
## Rail is **25 to 55 per cent wider than the fallback at the same size**, so
## turning it on moves every string in the game at once, and not one check in the
## suite could see a single one of them.
##
## `UiKit` writes down what it draws now — see the ledger at the top of `text()`
## — and this reads it back. Two questions, and they are the two a wider face
## actually causes: does anything run off the frame, and does anything run into a
## control.
##
## THE FIGHT USED TO BE THE HOLE HERE, and this header used to say so and leave
## it: *"`melee_scene` draws its fight HUD with raw `draw_string` — forty-nine
## calls that never touch UiKit."* It had grown to sixty-two by the time anybody
## closed it, which is what a named gap does if naming is all that happens to it.
## *A note beside a number is not a check on it.* All sixty-two go through
## `UiKit.raw()` now — `draw_string`'s own arguments in `draw_string`'s own
## order, forwarded verbatim, so the conversion moved no pixels and nine shot
## tools' PNGs proved it byte for byte — and the splash, the fight, the corner
## and the report are swept below.
##
## WHAT THIS COULD NOT SEE UNTIL 15 SEP 2026: panels. They are drawn rects with
## no association to the text sitting on them, so a string could run off the
## right edge of one and nothing would know. This header named that hole from
## the day it was written and naming it was all that ever happened to it.
##
## `UiKit.panel()` writes its rect to the ledger now, and the last check in this
## file pairs the two lists. It found three on its first run — a credits line
## seventeen pixels over the edge, the fighter panel's footnote eighty-eight
## over, and the tournament card's subtitle fifty-three over, clipped mid-
## sentence in the oldest screenshot in `shots/`. Then it caught the first fix
## for the first one, which wrapped the line and pushed the line below it out of
## the bottom of the same panel. That is what a check is for.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

const SCREENS := [
	["res://scenes/Title.tscn", -1],
	["res://scenes/Start.tscn", -1],
	["res://scenes/Settings.tscn", -1],
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
	["res://scenes/Create.tscn", 0],
	["res://scenes/Create.tscn", 1],
	["res://scenes/Bracket.tscn", -1],
]

## The frame, and the gutter the whole game is laid out against — the LIVE one.
##
## This was a flat 960x540, which was true of every frame this suite had ever
## rendered and false of every frame a player will ever see. `stretch/aspect` is
## "expand", so a handset hands the game 1170x540 and a tablet 960x720, and a
## sweep that measures a 1170-wide screen against a 960-wide frame reports
## nothing wrong with a layout that stops three-quarters of the way across.
static func frame() -> Rect2:
	return Rect2(Vector2.ZERO, UiKit.screen())


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the ink ===\n")
	await _test_nothing_is_drawn_off_the_screen()
	await _test_no_text_lands_on_a_control()
	await _test_the_ledger_can_fail()
	await _test_the_report_columns_hold_their_widest_token()
	await _test_the_fight_screens_hold_their_ink()
	await _test_the_card_prints_itself()
	_test_the_purse_stays_in_its_box()
	await _test_no_text_runs_off_its_panel()
	await _test_no_line_we_wrote_loses_its_tail()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE INK HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


## The same thin world the layout sweep uses, for the same reason: a screen only
## draws some of its text in some states, and the empty case is not the case.
## THE WORLD THE SWEEP LOOKS AT, held so it can be put back.
##
## IT WAS BEING DESTROYED BY THE FIRST SCREEN IT VISITED. `Title.tscn` is first
## in `SCREENS`, and its `_ready()` does `Session.season = null` — correctly, and
## for a good reason: coming back to the title means that career is over and a
## stale world must not stay alive behind it. Every screen after it then hit its
## own `if Session.season == null: Session.season = Season.new(..., randi())`
## fallback and swept a RANDOM DEFAULT CLUB.
##
## So the careful fixture below — two captains, a hard regime, a man one XP from
## a level, and now a chalkboard with something saved on it — was being built,
## used for exactly one screen, and thrown away. Nineteen of twenty screens were
## being photographed in a world nobody had set up.
##
## Found on 15 Sep 2026 while trying to make this suite catch a bug it could see
## the shape of and would not report. It is the same lesson as the shape sweep
## and the migration floor: **a fixture that is not re-asserted is a fixture that
## one screen can delete for all the others.**
var world_season: Season = null


func _world() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	world_season = s
	s.world.season = 3
	s.office.credits = 60
	s.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.PHYSIO))
	s.hire_captain(ClubOffice.captain("Ardry", Tuning.Role.CENTER, Tuning.Role.FLANK,
		3, ClubOffice.Trait.MOTIVATOR))
	s.office.set_regime(0, ClubOffice.Regime.HARD)
	var man: FighterCard = s.club.starting_five()[0]
	man.age = 24
	man.potential = 99
	man.level = 4
	man.xp = Career.next_level_at(man) + 1
	Session.viewing_fighter = man

	## A CHALKBOARD WITH SOMETHING ON IT, and this is not decoration.
	##
	## The sweep drove the chalkboard for weeks with **nought slots unlocked**,
	## which is the state a brand-new club is in and the only state the fixture
	## ever built. An owned slot is the only thing on that screen that draws a
	## name and puts a control over it — so the screen with #18 and #19 in it was
	## being photographed with the faulty half switched off.
	##
	## Proved, not assumed: re-flipping `b.flat` to false in `chalkboard_scene`
	## and re-running this suite PASSED, with the slab back over the name.
	## **A state nothing constructs is a state nothing tests**, and the fourth
	## time this project has written that down.
	s.office.credits = 60
	s.board.unlock_formation(s.office)
	s.board.save_formation(0, "Strong Right",
		s.board.spots_for(Tuning.Formation.TWO_ONE_TWO))
	s.board.unlock_play(s.office)
	s.board.save_play(0, "Full Right", s.board.routes_of(0), Chalkboard.UNIVERSAL)


## PUT THE WORLD BACK, before every screen. See the note on `world_season`.
func _restore() -> void:
	if world_season != null:
		Session.season = world_season
		Session.viewing_fighter = world_season.club.starting_five()[0]


## Open a screen, let it settle, then make it draw with the ledger running.
## `queue_redraw` is not enough on its own — the draw happens on the next frame,
## so the ledger has to be open across that frame and closed after it.
func _ink(path: String, tab: int) -> Array:
	if not ResourceLoader.exists(path):
		return []
	_restore()
	var packed: PackedScene = load(path)
	if packed == null:
		return []
	var n: Node = packed.instantiate()
	root.add_child(n)
	if Session.season != null:
		n.set("season", Session.season)
	await process_frame
	if tab >= 0:
		n.set("tab", tab)
		if n.has_method("_rebuild"):
			n.call("_rebuild")
	await process_frame
	UiKit.ledger_start()
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	await process_frame
	await process_frame
	var out := UiKit.ledger_stop()
	n.queue_free()
	await process_frame
	return out


func _label(path: String, tab: int) -> String:
	return String(path).get_file() + ("" if tab < 0 else " tab %d" % tab)


func _test_nothing_is_drawn_off_the_screen() -> void:
	_world()
	var bad: Array[String] = []
	var seen := 0
	for page in SCREENS:
		var ink: Array = await _ink(String(page[0]), int(page[1]))
		seen += ink.size()
		for row in ink:
			var r: Rect2 = row["rect"]
			## A string is off the screen if any of it is. The right edge is the
			## one a wider face pushes, and it is the one nobody can see in a
			## headless run.
			if r.position.x < 0.0 or r.position.y < 0.0 \
					or r.end.x > frame().size.x or r.end.y > frame().size.y:
				bad.append("%s: '%s' at %.0f,%.0f runs to %.0f,%.0f" % [
					_label(String(page[0]), int(page[1])), String(row["text"]),
					r.position.x, r.position.y, r.end.x, r.end.y])
	notes.append("ink: %d strings across %d pages" % [seen, SCREENS.size()])
	_ok(bad.is_empty(), "nothing is drawn off the screen",
		"%d strings measured%s" % [seen,
			"" if bad.is_empty() else " — " + "; ".join(bad.slice(0, 6))])


## TEXT ON A BUTTON IS THE OTHER HALF of the same failure. A label that grows
## into the control beside it is not off the screen and is just as unreadable,
## and it is what a 30% wider face does to a row that used to fit.
func _test_no_text_lands_on_a_control() -> void:
	_world()
	var bad: Array[String] = []
	var pairs := 0
	for page in SCREENS:
		var path := String(page[0])
		var tab := int(page[1])
		if not ResourceLoader.exists(path):
			continue
		_restore()
		var n: Node = (load(path) as PackedScene).instantiate()
		root.add_child(n)
		if Session.season != null:
			n.set("season", Session.season)
		await process_frame
		if tab >= 0:
			n.set("tab", tab)
			if n.has_method("_rebuild"):
				n.call("_rebuild")
		await process_frame
		UiKit.ledger_start()
		if n is CanvasItem:
			(n as CanvasItem).queue_redraw()
		await process_frame
		await process_frame
		var ink := UiKit.ledger_stop()
		var controls: Array = []
		_controls(n, controls)
		for row in ink:
			var r: Rect2 = row["rect"]
			for c in controls:
				var cr: Rect2 = c["rect"]
				pairs += 1
				var hit := r.intersection(cr)
				if hit.size.x <= 1.0 or hit.size.y <= 1.0:
					continue
				## THE EXEMPTION THAT USED TO BE HERE WAS THE HOLE.
				##
				## It said: a wordless Button that WHOLLY CONTAINS a string is
				## that string's hit target, not a collision — written for the
				## club-creator's mark bank, where each slot's rect runs 18px past
				## the badge so the caption under it is tappable.
				##
				## It is also the exact signature of the bug Pete found on 15 Sep:
				## *"Saved formation doesn't save or show up in blank slot."* It
				## saved. It drew. And a full-size, empty-labelled, NOT-flat Button
				## on the CanvasLayer above painted a solid slab over the name —
				## wholly containing it, and so wholly excused. Two screens were
				## doing it; the mark bank was the second.
				##
				## The right answer was never an exemption. A hit box over a
				## drawing is `flat`, and `_controls()` already skips flat buttons
				## because they cannot cover anything. Both call sites are flat
				## now, so the exemption has nothing left to protect and its
				## removal turns this check into the one that would have caught
				## the bug. **An exemption written for one screen is a hole for
				## every other one.**
				bad.append("%s: '%s' under '%s'" % [_label(path, tab),
					String(row["text"]), String(c["name"])])
		n.queue_free()
		await process_frame
	_ok(bad.is_empty(), "no drawn text lands on a control",
		"%d text-control pairs checked%s" % [pairs,
			"" if bad.is_empty() else " — " + "; ".join(bad.slice(0, 6))])


func _controls(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and c.visible and (c is Button or c is LineEdit or c is Slider):
			## Flat buttons are invisible hit targets drawn OVER text on purpose —
			## the squad rows are exactly that — so they are not something text
			## can land on.
			if not (c is Button and (c as Button).flat):
				out.append({"rect": Rect2((c as Control).get_global_position(),
					(c as Control).size), "name": _name_of(c)})
		_controls(c, out)


func _name_of(c) -> String:
	if c is Button and String((c as Button).text) != "":
		return String((c as Button).text)
	## "Button" exactly — `_test_no_text_lands_on_a_control` reads this to tell a
	## wordless hit target from a labelled control.
	return "Button" if c is Button else c.get_class()


## THE ONE TABLE THE LEDGER CANNOT SEE.
##
## The post-fight report draws with raw `draw_string` — it is inside
## `melee_scene`, which this file's header names as the exception — so none of
## the sweeps above touch it. It is also the screen most likely to need them: it
## is a seven-column table of right-aligned tokens, and a right-aligned string
## that outgrows its column runs BACKWARDS into the one before it, which is the
## least visible way for a layout to break.
##
## The HTML mock this screen was ported from has a comment warning about exactly
## that, written next to the numbers that cause it — `lv` at 530 and `next` at
## 556 is 36 pixels for a cell whose widest token is "LEVEL UP". The warning did
## not stop the port; this does. **A note beside a number is not a check on it.**
##
## Arithmetic, not rendering: each column's widest possible token, measured in
## the face the screen really uses, against the gap to the stop before it.
const REPORT_TOKENS := {
	"dn": ["9", 11], "as": ["9", 11], "up": ["9", 11], "off": ["9", 11],
	"xp": ["+99", 10], "lv": ["99", 11], "next": ["LEVEL UP", 10],
}
const REPORT_ORDER := ["dn", "as", "up", "off", "xp", "lv", "next"]
## Where the names and positions end — the first column has to clear them too.
const REPORT_NAME_END := 190.0


func _test_the_report_columns_hold_their_widest_token() -> void:
	var scene: Node = (load("res://scenes/Melee.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var stops: Dictionary = scene.get("REP_COL")
	var f := UiKit.body()
	var bad: Array[String] = []
	var prev := REPORT_NAME_END
	for key in REPORT_ORDER:
		var token: String = String(REPORT_TOKENS[key][0])
		var px: int = int(REPORT_TOKENS[key][1])
		var need := f.get_string_size(token, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
		var have := float(stops[key]) - prev
		if need > have:
			bad.append("%s: '%s' needs %.0f in %.0f" % [key, token, need, have])
		prev = float(stops[key])
	_ok(bad.is_empty(), "every report column holds its own widest token",
		"%d columns from %.0f to %.0f%s" % [REPORT_ORDER.size(), REPORT_NAME_END,
			float(stops["next"]), "" if bad.is_empty() else " — " + "; ".join(bad)])
	## AND THE HEADERS, which are shorter than the tokens in every column but one
	## — "DOWNS" is five characters over a single digit, and it is the header row
	## that read `LVLNEXT` on the first port.
	var heads := {"dn": "DOWNS", "as": "AST", "up": "UP", "off": "OFF",
		"xp": "XP", "lv": "LVL", "next": "NEXT"}
	var clash: Array[String] = []
	prev = REPORT_NAME_END
	for key in REPORT_ORDER:
		var need := f.get_string_size(String(heads[key]), HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, 9).x
		if need > float(stops[key]) - prev:
			clash.append("%s: '%s' needs %.0f in %.0f" % [key, String(heads[key]),
				need, float(stops[key]) - prev])
		prev = float(stops[key])
	_ok(clash.is_empty(), "and every header fits over its own column",
		"seven headers%s" % ("" if clash.is_empty() else " — " + "; ".join(clash)))
	scene.queue_free()
	await process_frame


## A CHECK THAT CANNOT FAIL IS NOT A CHECK, and a ledger that records nothing
## passes both sweeps above in perfect silence. So: draw one string that is
## obviously off the screen and prove the instrument notices.
func _test_the_ledger_can_fail() -> void:
	## Drawn inside a real draw pass — called from here the engine refuses the
	## draw (an engine error per call) even though the ledger still records it.
	var probe := Node2D.new()
	var got := {"on": [], "off": true}
	probe.draw.connect(func() -> void:
		UiKit.ledger_start()
		## PLACED RELATIVE TO THE LIVE EDGE, not at 920: at 1170 wide a canary
		## pinned to 920 is comfortably on screen and proves nothing.
		UiKit.text(probe, UiKit.body(), "off the edge entirely",
			Vector2(frame().size.x - 40.0, 60), 16, UiKit.INK)
		got["on"] = UiKit.ledger_stop()
		## And records nothing when it is off, which is how it behaves in the game.
		UiKit.text(probe, UiKit.body(), "not recorded", Vector2(10, 10), 16, UiKit.INK)
		got["off"] = UiKit._ledger.is_empty())
	root.add_child(probe)
	probe.queue_redraw()
	await process_frame
	await process_frame
	var ink: Array = got["on"]
	var caught := false
	for row in ink:
		var r: Rect2 = row["rect"]
		if r.end.x > frame().size.x:
			caught = true
	_ok(ink.size() == 1 and caught,
		"the ledger sees a string that runs off the frame",
		"%d recorded, caught: %s" % [ink.size(), str(caught)])
	_ok(bool(got["off"]), "and records nothing with the flag down",
		"the game pays nothing for it")
	probe.queue_free()


## ---------------------------------------------------- the fight, at last
## THE THREE SCREENS THIS FILE'S OWN HEADER SAID IT COULD NOT SEE.
##
## `melee_scene` drew SIXTY-TWO strings straight onto the canvas — the splash
## before the charge, the corner between rounds and the after-action report,
## which are the three screens most recently rebuilt from Pete's mocks and
## therefore the three most likely to be wrong. Every other screen in the game
## went through `UiKit` and was swept; these did not, and the header named the
## gap rather than closing it. *A note beside a number is not a check on it.*
##
## `UiKit.raw()` closed it: it takes `draw_string`'s own arguments in
## `draw_string`'s own order and forwards them verbatim, so the conversion was a
## textual substitution and the pixels are identical by construction — nine shot
## tools' worth of PNGs compared byte for byte before and after, all identical.
##
## The states are driven the way `tools/shot_corner.gd` drives them, for the
## reason that tool's header gives: **a screenshot of the empty case is the
## mistake this project has now made twice.** A corner over a fight that has not
## started photographs five of seven fields blank; a report before a bout has
## been fought photographs nothing at all.
## THESE NUMBERS ARE CASE LABELS, NOT `Screen` VALUES, and the difference has
## cost an hour. `Screen` is `{SPLASH, PREFIGHT, FIGHT, CORNER, REPORT}` — so
## FIGHT is 2 and CORNER is 3 — while this table's "the fight" is 1 and "the
## corner" is 2. The branches below mostly do not set `screen` from them at all:
## they take the road the game takes and let the scene decide where it lands.
## Writing `n.set("screen", 1)` in a new branch therefore puts the scene in
## PREFIGHT while the code around it says FIGHT, which is exactly the mistake
## that made the first attempt at the report check pass against a live bug.
const FIGHT_STATES := [
	["the splash", 0],
	["the fight", 1],
	["the corner", 2],
	["the report", 4],
]


## Open the melee and drive it into one of its screens, then read the ink.
func _ink_fight(state: int) -> Array:
	seed(20260914)
	Session.season = Season.new(MeleeRosters.starting_club(), 20260914)
	Session.bout = null
	var n: Node = (load("res://scenes/Melee.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	var sim = n.get("sim")
	match state:
		2:
			## A ROUND IN THE BOOK FIRST. `skip_round` is the round the marshal
			## would have run, and without it the corner has no score, no
			## takedowns, no assists, nobody downed and nothing to recover.
			sim.skip_round()
			n.set("screen", 2)
			n.set("corner_done_for_round", -1)
			n.call("_show_strategy_panel")
		4:
			## THROUGH A LIVE FIGHT, not straight to the report.
			##
			## This used to set `screen = 4` on a bout that had never been
			## watched — and CALL and SKIP ROUND are only ever turned ON by
			## `_sync_controls` during a live fight, so they sat in their
			## `visible = false` starting state and the sweep was photographing a
			## report with no fight behind it.
			##
			## Which is exactly why it never saw #11: Pete's SKIP ROUND on top of
			## the after-action report. A button has to be switched on before a
			## check can notice that nothing switched it off.
			##
			## So: answer the plan the way state 1 does, let two frames pass so
			## the controls come up, THEN end the bout. Anything that skips the
			## fight also skips the thing under test.
			var sh = n.call("_shape_of", int(sim.formations[0]))
			n.call("_call_from_book", sh if sh is Dictionary else {},
				{"kind": "push", "id": int(sim.strategies[0]), "name": "hold"})
			await process_frame
			await process_frame
			sim.run_to_end()
			if n.has_method("_show_report"):
				n.call("_show_report")
			await process_frame
		1:
			## INTO THE FIGHT THE WAY A PLAYER GETS THERE, which is by answering
			## the plan — `_apply_chosen()` — and not by writing to `screen`.
			##
			## Two things go wrong when a check lets itself in the side door.
			## Setting `screen` leaves the SPLASH's own button on the tree (it is
			## torn down inside the press handler, not by the screen changing),
			## so the sweep reported the walk-out button sitting over five men's
			## position labels during a live fight. And the sim was still in its
			## corner, so `_process` immediately hauled the screen back to the
			## corner and the sweep then measured a fight that drew nothing.
			##
			## **A check that reaches a state by a road the game does not have is
			## measuring a state the game cannot be in.**
			var shapes = n.call("_shape_of", int(sim.formations[0]))
			n.call("_call_from_book", shapes if shapes is Dictionary else {},
				{"kind": "push", "id": int(sim.strategies[0]), "name": "hold"})
		_:
			n.set("screen", state)
	await process_frame
	UiKit.ledger_start()
	(n as CanvasItem).queue_redraw()
	await process_frame
	await process_frame
	var ink := UiKit.ledger_stop()
	var controls: Array = []
	_controls(n, controls)
	n.queue_free()
	await process_frame
	return [ink, controls]


## THE HEADER'S PURSE, MEASURED AGAINST THE BOX IT SITS IN.
##
## This file's own header names the hole it cannot see: *panels are drawn rects
## with no association to the text sitting on them. A string can still run off
## the right edge of a panel and this will not know.* It happened. A probe handed
## a club three thousand credits a year to find out how far the ladder could be
## climbed, and the season screen came back with `41616 CC` running out of its
## frame and through the mood word beside it.
##
## Naming a gap is not closing it. This closes the one case that matters — the
## readout that appears on every screen in the game and grows without bound —
## by measuring the drawn string at the size it is drawn, against the frame it is
## drawn in, at every magnitude a career can reach. *A note beside a number is
## not a check on it.*
func _test_the_purse_stays_in_its_box() -> void:
	var font := UiKit.body()
	## THE SCREEN'S OWN NUMBERS, not a second copy of them. A check that retypes
	## the box it is checking passes for ever after somebody moves the box.
	var scene: Script = load("res://scripts/game/season_scene.gd")
	## THE SCREEN COMPUTES THESE NOW, because the header group rides the right
	## edge of whatever canvas the game got rather than sitting at a fixed 604.
	## Asked of the screen's own functions, so this still cannot drift from it.
	var box: Rect2 = scene.call("purse_box")
	var at: Vector2 = scene.call("purse_at")
	var size: int = int(scene.get("PURSE_SIZE"))
	var room := box.end.x - at.x - 6.0
	var over: Array[String] = []
	var widest := 0.0
	var worst := ""
	for v in [0, 9, 99, 640, 4096, 9999, 10000, 41616, 99999, 250000, 4200000]:
		var word := UiKit.purse_word(v)
		var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
		if w > widest:
			widest = w
			worst = word
		if w > room:
			over.append("%s is %.0fpx in %.0f" % [word, w, room])
	notes.append("the purse: widest is '%s' at %.0fpx in %.0f of room"
		% [worst, widest, room])
	_ok(over.is_empty(), "the purse never runs out of its frame",
		"%.0fpx of room, widest '%s'%s" % [room, worst,
			"" if over.is_empty() else " — " + "; ".join(over)])
	## AND IT STILL SAYS A NUMBER. A readout that fits because it stopped being
	## informative is not a fix — every shortened form has to name its magnitude.
	_ok(UiKit.purse_word(9999) == "9999 CC" and UiKit.purse_word(41616).ends_with("k CC")
			and UiKit.purse_word(4200000).ends_with("m CC"),
		"and what it says is still the number",
		"9999 -> %s, 41616 -> %s, 4.2m -> %s" % [UiKit.purse_word(9999),
			UiKit.purse_word(41616), UiKit.purse_word(4200000)])

## THE HOLE THIS FILE'S OWN HEADER HAS NAMED SINCE THE DAY IT WAS WRITTEN.
##
## *"Panels are drawn rects with no association to the text sitting on them. A
## string can still run off the right edge of a panel and this will not know."*
## Named, and then named again every time somebody read it, for a month.
##
## `UiKit.panel()` now writes its rect to the ledger alongside the strings, so
## the association exists and the check is a pairing: for every string, find the
## panel it was drawn ON — the innermost one containing its left edge — and ask
## whether it also contains its right edge and its baseline. A string that
## starts inside a box and finishes outside it is ink no reader can see.
##
## INNERMOST, because panels nest: the meeting card sits over the three panels
## it is a decision about, and measuring its text against the panel underneath
## would report every line of it as an overflow.
##
## A string that starts outside every panel is not this check's business — that
## is `nothing is drawn off the screen`, two checks up.
## ONE PIXEL, NOT THREE. The first cut allowed three, and three was enough to
## pass a line of the fighter panel's trait block sitting visibly outside the
## bottom of it in `shots/fighter.png`. A slop that hides a real overflow is not
## tolerance, it is the check declining to answer.
const PANEL_SLOP := 1.0


func _test_no_text_runs_off_its_panel() -> void:
	_world()
	var over: Array[String] = []
	var paired := 0
	var seen := 0
	for page in SCREENS:
		var path := String(page[0])
		var tab := int(page[1])
		if not ResourceLoader.exists(path):
			continue
		var pair: Array = await _ink_and_panels(path, tab)
		var ink: Array = pair[0]
		var panels: Array = pair[1]
		var label := path.get_file().get_basename() + ("" if tab < 0 else " tab %d" % tab)
		seen += ink.size()
		for row in ink:
			var r: Rect2 = row["rect"]
			var found: Array = _innermost(panels, r.position + Vector2(1.0, -1.0))
			if found.is_empty():
				continue
			paired += 1
			var b: Rect2 = found[0]
			if r.end.x > b.end.x + PANEL_SLOP or r.end.y > b.end.y + PANEL_SLOP:
				over.append("%s: '%s' ends at %.0f,%.0f outside a panel ending %.0f,%.0f"
					% [label, String(row["text"]), r.end.x, r.end.y, b.end.x, b.end.y])
	notes.append("the panels: %d strings, %d of them on a panel, across %d screens"
		% [seen, paired, SCREENS.size()])
	_ok(over.is_empty(), "no text runs off the panel it is drawn on",
		"%d strings paired to a panel%s" % [paired,
			"" if over.is_empty() else " — " + "; ".join(over.slice(0, 8))])


## The smallest panel containing a point, or null. Smallest rather than last,
## because draw order and nesting are not the same thing.
## Returns [rect] or [] — an array rather than a nullable Rect2, because Rect2
## is a value type in GDScript and there is no such thing as a null one.
func _innermost(panels: Array, at: Vector2) -> Array:
	var best: Array = []
	var best_area := INF
	for p in panels:
		var r: Rect2 = p
		if not r.has_point(at):
			continue
		var a := r.size.x * r.size.y
		if a < best_area:
			best_area = a
			best = [r]
	return best


func _ink_and_panels(path: String, tab: int) -> Array:
	var n: Node = (load(path) as PackedScene).instantiate()
	root.add_child(n)
	if Session.season != null:
		n.set("season", Session.season)
	await process_frame
	if tab >= 0:
		n.set("tab", tab)
		if n.has_method("_rebuild"):
			n.call("_rebuild")
	await process_frame
	UiKit.ledger_start()
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	await process_frame
	await process_frame
	var panels := UiKit.ledger_panels()
	var ink := UiKit.ledger_stop()
	n.queue_free()
	await process_frame
	return [ink, panels]

## THE ONLY MOVING THING IN THE GAME THAT IS NOT A FIGHT, and the reason this
## check is here rather than in `test_juice.gd`: `Juice` was never the broken
## half. Its typer advanced perfectly — a probe read 115 of the gambeson card's
## 118 characters at frame 420 — while the screen showed a blank panel, because
## `SeasonScene` only ever redrew on `_rebuild()` and nothing was rebuilding.
##
## Every other check in this file hands the screen a `queue_redraw()` and then
## looks, which is exactly the one thing the screen could not do for itself. So
## this one does the opposite: it opens the ledger, lets thirty frames pass
## WITHOUT asking for anything, and reads what the screen drew of its own
## accord. Before `_process()` went in, that was nothing at all.
##
## **A check that supplies the frame cannot see a screen that never asks for
## one.**
func _test_the_card_prints_itself() -> void:
	_world()
	var s: Season = Session.season
	s.decline_bid()
	s.dilemma = {"id": "gambesons", "man": 0, "after": -1}
	var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(n)
	n.set("season", s)
	await process_frame
	n.call("_rebuild")
	await process_frame
	await process_frame
	## FROM HERE ON NOBODY ASKS IT TO DRAW.
	UiKit.ledger_start()
	for i in 30:
		await process_frame
	var ink: Array = UiKit.ledger_stop()
	var body := String(s.dilemma_card().get("body", ""))
	var head := body.substr(0, 12)
	var typed := 0
	for row in ink:
		if String(row["text"]).begins_with(head):
			typed += 1
	n.queue_free()
	await process_frame
	notes.append("the card: %d strings across 30 unasked frames, %d of them the body"
		% [ink.size(), typed])
	_ok(typed >= 2, "a dilemma card prints itself without being asked",
		"%d frames of the body across 30 unasked frames" % typed)

func _test_the_fight_screens_hold_their_ink() -> void:
	var off: Array[String] = []
	var over: Array[String] = []
	var seen := 0
	var pairs := 0
	for st in FIGHT_STATES:
		var label := String(st[0])
		var pair: Array = await _ink_fight(int(st[1]))
		var ink: Array = pair[0]
		var controls: Array = pair[1]
		seen += ink.size()
		if ink.is_empty():
			off.append("%s drew nothing at all" % label)
			continue
		for row in ink:
			var r: Rect2 = row["rect"]
			if r.position.x < 0.0 or r.position.y < 0.0 \
					or r.end.x > frame().size.x or r.end.y > frame().size.y:
				off.append("%s: '%s' at %.0f,%.0f runs to %.0f,%.0f" % [label,
					String(row["text"]), r.position.x, r.position.y,
					r.end.x, r.end.y])
			for c in controls:
				var cr: Rect2 = c["rect"]
				pairs += 1
				var hit := r.intersection(cr)
				if hit.size.x <= 1.0 or hit.size.y <= 1.0:
					continue
				if String(c["name"]) == "Button" and cr.encloses(r):
					continue
				over.append("%s: '%s' over '%s'" % [label, String(row["text"]),
					String(c["name"])])
	## AND NOTHING FROM THE FIGHT IS STILL LIVE ON THE REPORT.
	##
	## The ink sweep above can only see a control that a STRING happens to land
	## on. A live button in a corner of the report with nothing under it is
	## invisible to it and still a control the player can press on a bout that is
	## already scored. So this asks the question directly.
	var live_on_report: Array[String] = []
	var report_pair: Array = await _ink_fight(4)
	for c in report_pair[1]:
		var nm := String(c["name"])
		if nm == "CALL" or nm == "HOLD" or nm == "SKIP ROUND":
			live_on_report.append(nm)
	_ok(live_on_report.is_empty(),
		"and no fight control is still live once the bout is scored",
		"CALL and SKIP ROUND watched%s" % ("" if live_on_report.is_empty()
			else " — STILL UP: " + ", ".join(live_on_report)))

	notes.append("the fight: %d strings across %d states, %d text-control pairs"
		% [seen, FIGHT_STATES.size(), pairs])
	_ok(off.is_empty(), "the fight screens stay inside the frame",
		"%d strings measured%s" % [seen,
			"" if off.is_empty() else " — " + "; ".join(off.slice(0, 6))])
	_ok(over.is_empty(), "and none of their text lands on a control",
		"%d pairs checked%s" % [pairs,
			"" if over.is_empty() else " — " + "; ".join(over.slice(0, 6))])


## --------------------------------------------------- copy against its column
func _test_no_line_we_wrote_loses_its_tail() -> void:
	## A CLIPPED SENTENCE IS INVISIBLE TO EVERY OTHER CHECK IN THIS FILE. It is
	## on the frame, it is not on a control, it is inside its panel — it is
	## perfectly placed and it says `Your captains dec.` instead of what it means.
	## Three of them were on the clubhouse tab at once and a screenshot is the
	## only thing that had ever found one.
	##
	## `UiKit.fit_px()` is the door every string WE wrote goes through — a label,
	## a note, a blurb. Player-supplied names go through `clip_px` and are not
	## recorded, because a name can be any length and cutting one is the layout
	## doing its job. So anything in this list is copy that does not fit a column
	## we chose, which is a thing to fix in the copy or in the column.
	_world()
	var cut: Array[String] = []
	var drawn := 0
	for page in SCREENS:
		var path := String(page[0])
		var tab := int(page[1])
		if not ResourceLoader.exists(path):
			continue
		var ink: Array = await _ink(path, tab)
		drawn += ink.size()
		var label := path.get_file().get_basename() + ("" if tab < 0 else " tab %d" % tab)
		for row in UiKit.ledger_overrun():
			cut.append("%s: '%s' cut to '%s' for %.0fpx at %dpx"
				% [label, String(row["text"]), String(row["kept"]),
					float(row["width"]), int(row["size"])])
	notes.append("the copy: %d strings drawn, %d cut short" % [drawn, cut.size()])
	_ok(cut.is_empty(), "no line the game wrote itself is cut short by its column",
		"%d screens read%s" % [SCREENS.size(),
			"" if cut.is_empty() else " — " + "; ".join(cut.slice(0, 6))])

	## AND THE CHECK CAN FAIL, which is the thing a check like this most often
	## cannot. Same shape as `_test_the_ledger_can_fail` above: set up the exact
	## fault and confirm the recorder sees it, so a future refactor that quietly
	## stops recording is caught here rather than by the next screenshot.
	UiKit.ledger_start()
	var f := UiKit.body()
	var kept := UiKit.fit_px(f, "a sentence far too long for this", 13, 30.0)
	var caught := UiKit.ledger_overrun()
	UiKit.ledger_stop()
	_ok(caught.size() == 1 and kept.ends_with("."),
		"and a line that is cut IS recorded, so the check can fail",
		"cut to '%s', %d recorded" % [kept, caught.size()])
