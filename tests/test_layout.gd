extends SceneTree
## Every screen's controls, measured instead of looked at.
##
##   godot --headless --path . --script res://tests/test_layout.gd
##
## PETE, 13 SEP 2026: *"Some of the formatting is bad, the New Names on free
## agents is over another thing. Go through and make sure formatting looks
## good."*
##
## It was not that button. Panels and buttons had just been given a four-pixel
## drop shadow drawn OUTSIDE their own rect, so **every control in the game
## became four pixels wider and taller than the rect its screen asked for** —
## and sixteen screens laid out flush against each other all started overlapping
## by exactly four. One of them happened to be visible enough to notice.
##
## THE POINT OF THIS FILE is that "go through and check" is not a thing a person
## should have to do twice. A button is a real node at a real position, so two of
## them landing on each other is arithmetic, and arithmetic is something a
## machine can be made to care about. `test_roster.gd` already does this for one
## screen's cards; this does it for every screen's controls.
##
## WHAT IT CANNOT SEE: drawn text. `draw_string` leaves no node behind, so a
## label running into a number is still only findable by rendering — which is
## what `nothing on a card runs into anything else` does for the one place that
## has bitten us. This catches the other half.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

## Every screen that builds controls, and what it needs to exist first.
const SCREENS := [
	"res://scenes/Title.tscn",
	"res://scenes/Start.tscn",
	"res://scenes/Settings.tscn",
	"res://scenes/Season.tscn",
	"res://scenes/Roster.tscn",
	"res://scenes/Fighter.tscn",
	"res://scenes/Market.tscn",
	"res://scenes/Staff.tscn",
	"res://scenes/Coach.tscn",
	"res://scenes/Records.tscn",
	"res://scenes/Federation.tscn",
	"res://scenes/Arena.tscn",
	"res://scenes/Chalkboard.tscn",
	"res://scenes/Create.tscn",
	"res://scenes/Bracket.tscn",
	## THE FIGHT ITSELF, which was missing from this list until Pete asked
	## *"I'm not seeing the arena/fighting UI in this"* — and he was right twice
	## over: it was not in the contact sheets and it was not in the audit. It
	## builds three different panels (the formation picker before the bout, the
	## corner between rounds, the report after it) and every one of them is
	## controls nobody had ever measured.
	"res://scenes/Melee.tscn",
]

## The gutter the whole game is laid out against. Nothing important inside it.
const GUTTER := 16.0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the layout ===\n")
	_test_a_control_occupies_the_rect_it_asked_for()
	await _test_no_control_overlaps_another()
	await _test_nothing_leaves_the_screen()
	await _test_every_control_can_be_hit()
	await _test_the_team_sheet_columns_do_not_touch()
	await _test_nothing_stands_on_the_tab_strip()
	await _test_no_button_is_smaller_than_its_label()
	await _test_no_button_clips_its_own_text()
	_test_a_button_runs_what_it_was_given()
	await _test_every_button_is_wired_to_something()
	await _test_the_sub_popup_is_not_a_pile()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE LAYOUT HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


## THE ROOT CAUSE, ASSERTED DIRECTLY. A button asked for 204x46 must paint
## 204x46 including its shadow — not 208x50. Checked against the constant rather
## than against 4, so the day somebody deepens the drop this still means what it
## says.
func _test_a_control_occupies_the_rect_it_asked_for() -> void:
	var asked := Vector2(204, 46)
	var b := UiKit.button("x", Vector2(10, 10), asked, func(): pass)
	var painted := b.size + Vector2(UiKit.DROP_PX, UiKit.DROP_PX)
	_ok(painted == asked, "a button paints the rect it was given",
		"asked %s, control %s, + %dpx drop = %s" % [asked, b.size, int(UiKit.DROP_PX), painted])
	_ok(b.size.y >= 38.0, "and is still big enough to hit",
		"%.0fpx tall — the mobile build wants 48" % b.size.y)
	b.free()


## THE CHECK THAT DID NOT EXIST, and the bug it exists for was the worst one
## this project has had.
##
## `UiKit.button()` ended with:
##
##     skin(b, ...)
##     return b
##     ## EVERY BUTTON IN THE GAME TICKS, from one line.
##     b.pressed.connect(func(): Audio.play("tap"))
##     b.pressed.connect(on_press)
##     return b
##
## The tap-sound block had been pasted in AFTER an existing `return b`. So for
## however long that stood, **not one button in the game was connected to
## anything.** Every screen built its controls, positioned them, sized them,
## skinned them, measured them — and dropped the callable on the floor.
##
## Twenty-eight test files and four hundred checks did not see it, and the
## reason is exact: every one of them measured what a button LOOKS like. The
## layout sweep checks a button's rect, its label, its edges, its overlaps. Not
## one of them ever pressed one. A hundred checks on the appearance of a control
## say nothing at all about whether it works — and "a rule enforced at one call
## site is a rule with a hole in it" has a sibling: **a property nothing asserts
## is a property that is not true.**
##
## Two checks, because there are two ways to be wrong. This one is the unit: a
## button built the normal way, pressed, runs its callable.
func _test_a_button_runs_what_it_was_given() -> void:
	var fired := [0]
	var b := UiKit.button("press me", Vector2(10, 10), Vector2(120, 40),
		func(): fired[0] += 1)
	b.pressed.emit()
	_ok(fired[0] == 1, "a button runs the callable it was built with",
		"pressed once, ran %d time(s)" % fired[0])
	b.free()


## And this one is the sweep: every real button on every real screen has SOMETHING
## listening. The unit check above would pass on a `UiKit.button` that works while
## a screen wired its own `Button.new()` and forgot — and the sweep would pass on
## a suite where `UiKit.button` connects a tap sound and nothing else, which is
## why both are here. Between them, a button with no behavior has nowhere to
## hide.
func _test_every_button_is_wired_to_something() -> void:
	_world()
	var deaf: Array[String] = []
	var seen := 0
	for path in SCREENS:
		var n: Node = await _open(path)
		if n == null:
			continue
		var found: Array = []
		_controls(n, found)
		for c in found:
			if not (c["node"] is Button):
				continue
			seen += 1
			## Both button builders in the game wire exactly one closure that
			## plays the tap and then calls the caller's callable, so "nothing
			## listening" is the whole test. The first version asked for two
			## connections and failed seven playbook cards that were working
			## perfectly — a check whose rule two call sites implement
			## differently is a check that reports on the implementation.
			if (c["node"] as Button).pressed.get_connections().is_empty():
				deaf.append("%s / %s" % [path.get_file(), c["name"]])
		n.queue_free()
		await process_frame
	_ok(deaf.is_empty(), "every button on every screen does something",
		"%d buttons swept, %d listening to nothing: %s" % [
			seen, deaf.size(), ", ".join(deaf.slice(0, 6))])
	_ok(seen > 40, "and the sweep actually found buttons",
		"%d across %d screens" % [seen, SCREENS.size()])


## THE ONE CONTROL GROUP NO SWEEP HAD EVER SEEN.
##
## Every check in this file opens a screen in whatever state it opens in, and the
## corner's sub popup opens in none of them — it needs a tap. So it shipped with
## the last bench button ending on the exact y the cancel began, which Pete saw
## in a screenshot: *"Marsh is falling into nevermind."*
##
## A modal is exactly the kind of thing this sweep exists for and exactly the
## kind of thing it cannot reach on its own, so this one puts the screen INTO the
## state and then measures it. Anything a screen only draws after an interaction
## has to be interacted with, or the sweep is measuring the closed case and
## calling it green — which is the third time this file has written that sentence
## about itself.
func _test_the_sub_popup_is_not_a_pile() -> void:
	_world()
	var n: Node = await _open("res://scenes/Melee.tscn")
	if n == null:
		_ok(false, "the melee scene opens", "it did not")
		return
	n.set("sub_open", 1)
	n.call("_build_corner")
	await process_frame
	var found: Array = []
	_controls(n, found)
	## ONLY THE POPUP'S OWN CONTROLS. With it open the corner builds nothing
	## else, so everything on the layer is the popup — and asserting that is
	## itself worth doing, because a live FIGHT button under a modal is what the
	## first version had.
	var box: Rect2 = n.get("sub_box")
	var outside: Array[String] = []
	for c in found:
		if not box.grow(8.0).encloses(c["rect"]):
			outside.append(String(c["name"]))
	_ok(outside.is_empty() and not found.is_empty(),
		"nothing is pressable outside the sub popup while it is open",
		"%d controls, %d of them loose: %s" % [found.size(), outside.size(),
			", ".join(outside.slice(0, 5))])
	## A GAP, NOT AN ABSENCE OF OVERLAP — and this is the whole reason the bug got
	## out. `Marsh` ended on y 228 and `Never mind` began on y 228: they do not
	## intersect, by any arithmetic. `Rect2.intersects` is false for rectangles
	## that share an edge, so an overlap check could never have failed on it.
	##
	## What the player saw was the drop shadow. Every control in this game paints
	## a 4px shadow down and right INSIDE its own rect, so two controls flush
	## against each other put one's shadow along the other's top edge and the pair
	## reads as one tall box with a line through it. **Zero gap is a collision to
	## the eye even when it is not one to the arithmetic** — so the rule is a
	## clear `DROP_PX` between neighbors, which is the only distance at which the
	## shadow has somewhere to fall.
	var clash: Array[String] = []
	for i in found.size():
		for j in range(i + 1, found.size()):
			var a: Rect2 = found[i]["rect"]
			var b2: Rect2 = found[j]["rect"]
			var pad: float = UiKit.DROP_PX * 0.5 if (not _flat(found[i]["node"])
				and not _flat(found[j]["node"])) else 0.0
			if a.grow(pad).intersects(b2.grow(pad)):
				clash.append("%s / %s" % [found[i]["name"], found[j]["name"]])
	_ok(clash.is_empty(), "and no two of them are closer than the drop shadow",
		"%d controls, %d too close: %s" % [found.size(), clash.size(),
			", ".join(clash.slice(0, 4))])
	n.queue_free()
	await process_frame


## A THIN WORLD CHECKS THIN SCREENS.
##
## The first version opened every screen against a brand-new season, which has
## **no captains hired** — so the staff screen's `_build()` returned before it
## made a single button and the audit reported a clean sweep of a blank page.
## The three regime buttons under each captain were clipping "Normal" to
## "Norma" the whole time, on a screen the check had never actually seen.
##
## Anything a screen only draws in a particular state has to be put into the
## state, or the check is measuring the empty case and calling it green.
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
	## AND THE FIGHTER SCREEN GETS A MAN WITH A LEVEL IN HAND. Its row of `+1`
	## buttons only draws when one is waiting, so the sweep has been measuring
	## that screen with five controls missing — the same blindness as the staff
	## screen with no captains hired, one paragraph up. The first version of that
	## row was 164px into the meeting button beside it and nothing said so.
	var man: FighterCard = s.club.starting_five()[0]
	man.age = 24
	man.potential = 99
	man.level = 4
	man.xp = Career.next_level_at(man) + 1
	Session.viewing_fighter = man


## Build a screen the way the game builds it, let it run its `_ready` and one
## frame so deferred work lands, then look at what it made.
##
## THE FIXTURE IS PUT BACK BEFORE EVERY SCREEN. `Title.tscn` is first in the list
## and its `_ready()` sets `Session.season = null`; without this every later screen
## fell back to `Season.new(..., randi())` — a random, unseeded world — and the
## sweep never saw the fixture built above. And a screen that is missing or will
## not load is a FAILURE, not a quiet `continue`.
func _open(path: String) -> Node:
	if world_season != null:
		Session.season = world_season
		Session.viewing_fighter = world_season.club.starting_five()[0]
	if not ResourceLoader.exists(path):
		_ok(false, "screen exists", path)
		return null
	var packed: PackedScene = load(path)
	if packed == null:
		_ok(false, "screen loads", path)
		return null
	var n: Node = packed.instantiate()
	root.add_child(n)
	if n.has_method("set") and Session.season != null:
		n.set("season", Session.season)
	await process_frame
	await process_frame
	return n


## THE PAINTED RECT, NOT THE CONTROL RECT.
##
## First version compared `Rect2(position, size)` — and with the drop-shadow bug
## deliberately reintroduced it still passed, because the shadow is not part of
## the control's size. A collision check that cannot see the thing that caused
## the collision is decoration. So every rect here is inflated by the drop, which
## is what the player actually sees, and the check now fails on the bug it
## exists for.
func _controls(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and c.visible and (c is Button or c is LineEdit or c is Slider):
			var r := _seen(c, Rect2(_global(c),
				c.size + Vector2(UiKit.DROP_PX, UiKit.DROP_PX)))
			if r.size.x > 0.0 and r.size.y > 0.0:
				out.append({"node": c, "rect": r, "name": _label(c)})
		_controls(c, out)


## Does this control paint a frame and a drop, or is it an invisible hit target?
func _flat(c) -> bool:
	return c is Button and (c as Button).flat


## IS THIS CONTROL SOMEWHERE THE PLAYER COULD ACTUALLY TOUCH IT?
##
## The playbook scrolls, and a scroll pane is the first thing in this game that
## makes "where is the control" and "where is the control drawn" different
## questions. The fifth shape card in a pane that shows three has a global
## position four hundred pixels below the bottom of the screen — and it is not
## off the edge, it is NEXT. Failing on it would be the sweep reporting a list
## for being longer than its window, which is what a window is for.
##
## So a control inside a ScrollContainer is checked against that container's
## visible rect instead of against the frame: outside it, the sweep skips it
## entirely; inside it, every other check applies as normal. A control with no
## scrolling ancestor is unaffected, which is all of them but the book.
## IT RETURNS THE CLIPPED RECT, not a yes or no, and that second version is the
## one that works. Answering "is any of it showing" and then measuring the FULL
## rect still failed the edge check on the half-card the pane is cutting: the
## part below the fold has a global position past the bottom of the frame, which
## is exactly right and exactly not a fault. What the player can see is the
## intersection, so the intersection is what every check gets.
##
## An empty rect comes back for a control scrolled entirely out of view, and
## `_controls` drops those — they are not on the screen to be measured.
func _seen(c: Control, r: Rect2) -> Rect2:
	var p: Node = c.get_parent()
	while p != null and p is Control:
		if p is ScrollContainer:
			var view := Rect2((p as Control).get_global_position(), (p as Control).size)
			return view.intersection(r)
		p = p.get_parent()
	return r


## A CanvasLayer resets the transform, so a control's `global_position` is what
## the player sees only if we ask the control rather than adding up `position`.
func _global(c: Control) -> Vector2:
	return c.get_global_position()


func _label(c: Control) -> String:
	if c is Button and String((c as Button).text) != "":
		return String((c as Button).text)
	return c.get_class()


## Every screen, every tab of the one that has them, and every panel of the
## fight — which is three screens wearing one scene.
##
## A page is [path, tab, call]. `call` is a method to invoke after the scene has
## settled, and it exists for exactly the reason the staff screen taught: a
## panel that is only built in one phase of a bout is a panel the sweep never
## sees. The melee builds the formation picker before the bout, the corner
## between rounds and the report after it, and only the first of the three is up
## when the scene opens.
## AND A FOURTH PAGE, because the book grows a row.
##
## The playbook lists the named formations plus YOUR DRAWN SHAPE when the
## clubhouse sent one — so a season bout renders four rows where a standalone
## renders three, and the corner is already sharing its panel with the line, the
## bench and the swap note. The tallest version of a panel is the one that runs
## off the bottom, and it was the only one the sweep could not see.
const MELEE_PANELS := ["", "_show_strategy_panel", "_on_bout_finished",
	"_drawn_corner"]


func _pages() -> Array:
	var out: Array = []
	for p in SCREENS:
		if String(p).ends_with("Season.tscn"):
			for t in 5:
				out.append([String(p), t, ""])
			## AND THE SQUAD TAB WITH A MAN PICKED, which is a different screen.
			##
			## This file drove every TAB and never a STATE, and picking a fighter
			## on the squad tab adds three buttons to a row that already had
			## three. Two of them landed on top of two that were already there —
			## `Sell` exactly over `Reserve by` at x=24, and the contract fork
			## over `Free agents` at x=544 — so the reserve could not be re-sorted
			## while a man was selected, and the only visible symptom was a single
			## letter "s" sticking out from under the Extend button.
			##
			## It lived through every run of this file because a control that is
			## never built cannot be measured. **Driving a tab is not driving a
			## screen.**
			out.append([String(p), 1, "_pick_a_fighter"])
		elif String(p).ends_with("Melee.tscn"):
			for c in MELEE_PANELS:
				out.append([String(p), -1, String(c)])
		else:
			out.append([String(p), -1, ""])
	return out


## Put a page into the state it is meant to be checked in.
func _drive(s: Node, page: Array) -> void:
	if int(page[1]) >= 0:
		s.set("tab", int(page[1]))
		s.call("_rebuild")
	var c := String(page[2]) if page.size() > 2 else ""
	if c == "_pick_a_fighter":
		## A man with a deal still to run, so the row builds its dearest version:
		## the sale price AND the contract fork, rather than the shorter labels an
		## out-of-contract man gets.
		var season = s.get("season")
		for f in season.club.roster:
			if f.years > 0:
				s.set("picked", f)
				break
		s.call("_rebuild")
		return
	if c == "_on_bout_finished":
		s.call(c, 0)
	elif c == "_drawn_corner":
		## A shape off the Chalkboard, which is what a season bout hands over, and
		## then the corner — the four-row book in the panel that has the least
		## room for it.
		var sim = s.get("sim")
		var spots: Array = Tuning.FORMATIONS[Tuning.Formation.DEPTH]["spots"].duplicate()
		sim.set_plan(0, spots, null)
		s.set("drawn_spots", spots)
		s.call("_show_strategy_panel")
	elif c != "":
		s.call(c)


func _test_no_control_overlaps_another() -> void:
	_world()
	var bad: Array[String] = []
	var counted := 0
	## THE SEASON SCREEN IS FIVE SCREENS. Opening it and looking at the default
	## tab checks a fifth of it, and the CLUBHOUSE tab is the busiest thing in
	## the game — four nav buttons, four facility buys and a four-button action
	## row. Every tab gets driven.
	for path in _pages():
		var s: Node = await _open(String(path[0]))
		if s == null:
			continue
		_drive(s, path)
		await process_frame
		var cs: Array = []
		_controls(s, cs)
		counted += cs.size()
		for i in cs.size():
			for j in range(i + 1, cs.size()):
				var a: Rect2 = cs[i]["rect"]
				var b: Rect2 = cs[j]["rect"]
				## A SHARED EDGE IS NOT AN OVERLAP — AND IT IS STILL A FAULT.
				##
				## This read `intersection` and required real area, which is
				## arithmetically correct and let a real bug out: the corner's
				## sub popup had a bench button ending on y 228 and a cancel
				## beginning on y 228, and Pete saw them as one control —
				## *"Marsh is falling into nevermind."*
				##
				## Every control in this game paints a `DROP_PX` shadow down and
				## right inside its own rect. Two of them flush against each
				## other put one's shadow along the other's edge and the pair
				## reads as one box with a line through it. So the rule is a
				## clear drop between neighbors, which is the only distance at
				## which the shadow has somewhere to fall — and it is checked by
				## growing both rects half a drop, so a flush pair fails and a
				## properly spaced one does not.
				##
				## The whole game was measured before this was turned on: two
				## flush pairs, both on Create, both the tab row two pixels above
				## a text box. A rule you switch on without measuring first is a
				## rule you are about to loosen.
				## A FLAT BUTTON HAS NO SHADOW TO FALL ON ANYTHING.
				##
				## The squad screen's rows are invisible hit targets over drawn
				## text, two pixels apart on purpose — nearly contiguous, so every
				## tap lands on somebody. Holding them to a drop's clearance
				## would be the check asking a control that paints nothing to
				## leave room for the thing it does not paint. The rule is about
				## the shadow, so it applies to the controls that have one; the
				## rest are still held to not overlapping.
				var lit: bool = not _flat(cs[i]["node"]) and not _flat(cs[j]["node"])
				var pad: float = UiKit.DROP_PX * 0.5 if lit else 0.0
				var hit := a.grow(pad).intersection(b.grow(pad))
				if hit.size.x > 0.5 and hit.size.y > 0.5:
					var real := a.intersection(b)
					bad.append("%s%s: '%s' %s '%s' by %.0fx%.0f" % [
						String(path[0]).get_file(),
						"" if int(path[1]) < 0 else " tab %d" % int(path[1]),
						cs[i]["name"],
						"over" if real.size.x > 0.5 and real.size.y > 0.5
							else "flush against",
						cs[j]["name"], hit.size.x, hit.size.y])
		s.queue_free()
		await process_frame
	_ok(bad.is_empty(), "no control sits on or against another",
		"%d controls across %d pages" % [counted, _pages().size()]
			if bad.is_empty() else "\n        " + "\n        ".join(bad.slice(0, 8)))


func _test_nothing_leaves_the_screen() -> void:
	_world()
	var bad: Array[String] = []
	var screen := Rect2(Vector2.ZERO, UiKit.screen())
	for path in _pages():
		var s: Node = await _open(String(path[0]))
		if s == null:
			continue
		_drive(s, path)
		await process_frame
		var cs: Array = []
		_controls(s, cs)
		for c in cs:
			var r: Rect2 = c["rect"]
			if not screen.encloses(r):
				bad.append("%s: '%s' at %.0f,%.0f %.0fx%.0f" % [
					String(path[0]).get_file(), c["name"],
					r.position.x, r.position.y, r.size.x, r.size.y])
		s.queue_free()
		await process_frame
	_ok(bad.is_empty(), "nothing runs off the edge",
		"960x540, every control inside it" if bad.is_empty()
			else "\n        " + "\n        ".join(bad.slice(0, 8)))


## A CONTROL WITH NO SIZE IS A CONTROL NOBODY CAN PRESS, and it looks exactly
## like a control that is simply not there. This has bitten the chalkboard once
## already, where a row of slots built at zero width drew nothing and swallowed
## every tap in the column.
func _test_every_control_can_be_hit() -> void:
	_world()
	var bad: Array[String] = []
	for path in _pages():
		var s: Node = await _open(String(path[0]))
		if s == null:
			continue
		_drive(s, path)
		await process_frame
		var cs: Array = []
		_controls(s, cs)
		for c in cs:
			var r: Rect2 = c["rect"]
			if r.size.x - UiKit.DROP_PX < 24.0 or r.size.y - UiKit.DROP_PX < 18.0:
				bad.append("%s: '%s' is %.0fx%.0f" % [
					String(path[0]).get_file(), c["name"],
					r.size.x - UiKit.DROP_PX, r.size.y - UiKit.DROP_PX])
		s.queue_free()
		await process_frame
	_ok(bad.is_empty(), "every control is big enough to press",
		"nothing under 24x18" if bad.is_empty()
			else "\n        " + "\n        ".join(bad.slice(0, 8)))


## THE HALF THIS FILE CANNOT OTHERWISE SEE.
##
## `draw_string` leaves no node behind, so a label running into a number is
## invisible to a walk of the scene tree. The team sheet had two of them at once
## — a wage right-aligned into a 90-pixel box that ran back through the AGE
## column, and a rating right-aligned into a 60-pixel box that ran back through
## the CONTRACT YEARS — and on screen it read as `$3 2` with a rating printed
## through the middle.
##
## The fix was to make the column stops DATA rather than nine magic numbers
## buried in the drawing, and `squad_columns()` hands them back measured in the
## font the screen is really using, against the widest string each field can
## produce. Nine fields in 446 pixels is tight enough that it will go wrong
## again; this is what will say so.
func _test_the_team_sheet_columns_do_not_touch() -> void:
	_world()
	var s: Node = await _open("res://scenes/Season.tscn")
	if s == null:
		_ok(false, "the team sheet columns", "could not open the season screen")
		return
	var f: Font = s.get("font")
	if f == null:
		f = ThemeDB.fallback_font
	var cols: Array = s.call("squad_columns", f)
	var bad: Array[String] = []
	for i in cols.size():
		for j in range(i + 1, cols.size()):
			var a: Rect2 = cols[i]["rect"]
			var b: Rect2 = cols[j]["rect"]
			var hit := a.intersection(b)
			if hit.size.x > 0.0:
				bad.append("'%s' and '%s' by %.0fpx" % [
					cols[i]["name"], cols[j]["name"], hit.size.x])
	_ok(bad.is_empty(), "no two columns on the team sheet touch",
		"%d fields across %.0fpx" % [cols.size(), s.get("SQUAD_W")]
			if bad.is_empty() else ", ".join(bad))

	## AND NEITHER DO THE HEADINGS, which is a separate question and was a real
	## bug the moment the headings existed.
	##
	## The four fields on the right hold `$3`, `3y`, `40`, `44`, so their rects
	## are narrower than the WORDS that name them and the first screenshot read
	## `WAGEDEALNOWMAX`. The data row clearing itself says nothing at all about
	## whether the labels clear each other — **two tables sharing a set of stops
	## are two tables, and only one of them was being measured.**
	var heads: Array[String] = []
	for i in cols.size():
		for j in range(i + 1, cols.size()):
			if not cols[i].has("head_rect") or not cols[j].has("head_rect"):
				continue
			var a: Rect2 = cols[i]["head_rect"]
			var b: Rect2 = cols[j]["head_rect"]
			var hit := a.intersection(b)
			if hit.size.x > 0.0:
				heads.append("'%s' and '%s' by %.0fpx" % [
					String(cols[i]["head"]), String(cols[j]["head"]),
					hit.size.x])
	_ok(heads.is_empty(), "and neither do the words that name them",
		"%d headings" % cols.size() if heads.is_empty() else ", ".join(heads))
	## AND THE WHOLE ROW HAS TO FIT. A field that clears its neighbors by
	## running off the end of the row is not fixed, it has moved.
	var w: float = float(s.get("SQUAD_W"))
	var over: Array[String] = []
	var tight := 999.0
	for i in cols.size():
		var r: Rect2 = cols[i]["rect"]
		if r.position.x < 0.0 or r.end.x > w:
			over.append("'%s' ends at %.0f" % [cols[i]["name"], r.end.x])
		if i + 1 < cols.size():
			var nxt: Rect2 = cols[i + 1]["rect"]
			tight = minf(tight, nxt.position.x - r.end.x)
	_ok(over.is_empty(), "and the row fits inside itself",
		"%.0fpx wide, tightest gap %.0fpx" % [w, tight]
			if over.is_empty() else ", ".join(over))
	s.queue_free()
	await process_frame


## THE TAB STRIP BELONGS TO THE TABS.
##
## Two buttons have now been parked on it. "Roster" covered the right 112 pixels
## of FINANCES (then HONORS) on the SQUAD tab; "The draw" covered the same region on every
## screen that had a cup to look at — and its comment says it was moved there
## deliberately, out of the action row, to stop it hiding a relegation place.
## It traded a visible fault for an invisible one.
##
## Neither was caught by the overlap sweep alone, because the cup one only
## appears in a game state the sweep does not set up. A REGION is cheaper and
## stronger than a state: the strip is declared off-limits and anything landing
## in it fails, whatever put it there.
func _test_nothing_stands_on_the_tab_strip() -> void:
	_world()
	var bad: Array[String] = []
	for page in _pages():
		if not String(page[0]).ends_with("Season.tscn"):
			continue
		var s: Node = await _open(String(page[0]))
		if s == null:
			continue
		_drive(s, page)
		await process_frame
		var tab_y: float = float(s.get("TAB_Y"))
		var tab_h: float = float(s.get("TAB_H"))
		var tab_w: float = float(s.get("TAB_W"))
		var strip := Rect2(24.0, tab_y, 5.0 * (tab_w + 6.0), tab_h)
		var cs: Array = []
		_controls(s, cs)
		## The five tabs are the five widest things starting on the strip's own
		## row; anything else that touches it is a trespasser.
		for c in cs:
			var r: Rect2 = c["rect"]
			if not strip.intersects(r):
				continue
			var is_tab := absf(r.position.y - tab_y) < 1.0 and absf(r.size.y - tab_h) < 5.0
			if not is_tab:
				bad.append("tab %d: '%s' at %.0f,%.0f" % [
					int(page[1]), c["name"], r.position.x, r.position.y])
		s.queue_free()
		await process_frame
	_ok(bad.is_empty(), "nothing stands on the tab strip",
		"the five tabs and nothing else" if bad.is_empty()
			else "\n        " + "\n        ".join(bad.slice(0, 6)))


## A BUTTON NARROWER THAN ITS LABEL DOES NOT CLIP — IT GROWS.
##
## That is the part worth knowing. `Button.size` is a floor, not a ceiling:
## Godot takes the larger of what the caller asked for and what the contents
## need, so a label that outgrows its box does not truncate, it shoves the box
## outward into whatever is beside it. Adding ten pixels of content padding
## pushed FORMATIONS past its 124-pixel box on the chalkboard and it ran ten
## pixels into PLAYS.
##
## The overlap sweep caught that one because the neighbor happened to be
## another control. This catches it when the neighbor is drawn text, which the
## sweep cannot see — and it names the button rather than the collision, which
## is the difference between a fix and a hunt.
func _test_no_button_is_smaller_than_its_label() -> void:
	_world()
	var bad: Array[String] = []
	var counted := 0
	for page in _pages():
		var s: Node = await _open(String(page[0]))
		if s == null:
			continue
		_drive(s, page)
		await process_frame
		var cs: Array = []
		_controls(s, cs)
		for c in cs:
			var node = c["node"]
			if not (node is Button):
				continue
			counted += 1
			var b := node as Button
			var need := b.get_combined_minimum_size()
			if b.size.x + 0.5 < need.x or b.size.y + 0.5 < need.y:
				bad.append("%s: '%s' is %.0fx%.0f and needs %.0fx%.0f" % [
					String(page[0]).get_file(), c["name"],
					b.size.x, b.size.y, need.x, need.y])
		s.queue_free()
		await process_frame
	_ok(bad.is_empty(), "no button is smaller than what is in it",
		"%d buttons, every one big enough for its own label" % counted
			if bad.is_empty() else "\n        " + "\n        ".join(bad.slice(0, 6)))


## THE HOLE IN THE CHECK ABOVE.
##
## `no button is smaller than what is in it` compares a control against its own
## minimum size — and a button with `clip_text` reports a minimum that does not
## include the text it is about to cut off. So the melee's corner, which sets
## `clip_text` on every man, sailed through that check while printing
## **"Ward 100"** for a man on 100%: a condition figure truncated into a
## different condition figure, on the one screen where that number is the whole
## decision.
##
## A clipping button is a legitimate thing to build — the corner has a clock on
## it and a wrapped paragraph is worse than a short name. What is not legitimate
## is not knowing when it clips. This measures every line of every clipping
## button against the room it actually has.
func _test_no_button_clips_its_own_text() -> void:
	_world()
	var bad: Array[String] = []
	var counted := 0
	for page in _pages():
		var s: Node = await _open(String(page[0]))
		if s == null:
			continue
		_drive(s, page)
		await process_frame
		var cs: Array = []
		_controls(s, cs)
		for c in cs:
			var node = c["node"]
			if not (node is Button):
				continue
			var b := node as Button
			if not b.clip_text:
				continue
			counted += 1
			var f: Font = b.get_theme_font("font")
			var px: int = b.get_theme_font_size("font_size")
			if f == null:
				continue
			var sb: StyleBox = b.get_theme_stylebox("normal")
			var inset := 0.0
			if sb != null:
				inset = sb.content_margin_left + sb.content_margin_right
			var room := b.size.x - inset
			for line in String(b.text).split("\n"):
				var w := f.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT,
					-1.0, px).x
				if w > room + 0.5:
					bad.append("%s: '%s' needs %.0f in %.0f" % [
						String(page[0]).get_file(), String(line), w, room])
		s.queue_free()
		await process_frame
	_ok(bad.is_empty(), "no button clips its own text",
		"%d clipping buttons, every line inside its room" % counted
			if bad.is_empty() else "\n        " + "\n        ".join(bad.slice(0, 6)))
