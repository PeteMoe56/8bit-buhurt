extends SceneTree
## THE SCREEN CHECKLIST — pass/fail, the same every run (30 Sep 2026).
##
##   godot --headless --path . --script res://tests/test_checklist.gd
##
## Eleven rounds of blind screenshot review settled at 7.3 ± 0.1 and started
## contradicting themselves: one reviewer wanted a key on one line, the next on
## three. A fresh reviewer each round cannot tell 7.3 from 7.6, so the rules the
## reviews agreed on for three rounds or more are written down here as checks
## that do not drift:
##
##   C1  no drawn text under 12 px
##   C2  drawn text reaches 4.5:1 against its ground (WCAG body text)
##   C3  at most ONE gold primary button per screen, and never a disabled one
##   C4  a button that charges more CC than the purse holds is disabled —
##       checked with a full purse AND an empty one, so both states are seen
##   C5  no empty horizontal band taller than 20% of the frame in the content area
##
## Covered elsewhere and not repeated: nothing cut short (test_ink, "no line we
## wrote loses its tail"), touch targets (test_layout, HIT_MIN), nothing off the
## screen or under a control (test_ink). Still judged by eye: whether a bar or
## tick is labelled — `docs/REGISTER.md` §30.48 lists the ones that are.

var failures: Array[String] = []
var checks: int = 0

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
	["res://scenes/Create.tscn", 2],
	["res://scenes/Bracket.tscn", -1],
]

const MIN_PX := 12
const MIN_CONTRAST := 4.5
const DEAD_FRAC := 0.20
const DESIGN_H := 540.0
## The content area C5 measures: under the header strip, above the action row.
const TOP_Y := 96.0
const BOTTOM_PAD := 64.0

var world_season: Season = null
var world_cup: Cup = null


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the screen checklist ===\n")
	var rich: Array = await _sweep(60)
	var broke: Array = await _sweep(0)
	_c1(rich)
	_c2(rich)
	_c3(rich + broke)
	_c4(rich + broke)
	_c5(rich)
	print("")
	if failures.is_empty():
		print("THE CHECKLIST HOLDS (%d checks)\n" % checks)
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


## The same fixture test_ink photographs, at a chosen purse.
func _world(credits: int) -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.world.season = 3
	s.office.credits = 60
	s.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.PHYSIO))
	s.hire_captain(ClubOffice.captain("Ardry", Tuning.Role.CENTER, Tuning.Role.FLANK,
		3, ClubOffice.Trait.MOTIVATOR))
	var man: FighterCard = s.club.starting_five()[0]
	man.xp = Career.next_level_at(man) + 1
	s.board.unlock_formation(s.office)
	s.board.save_formation(0, "Strong Right", s.board.spots_for(Tuning.Formation.TWO_ONE_TWO))
	## A CUP ON THE CALENDAR, so the Bracket is swept as cup night shows it and
	## not as its never-reached empty state.
	var me := int(s.world.player_club)
	var ids: Array = [me]
	for c in s.world.clubs:
		if int(c["id"]) != me and ids.size() < 8:
			ids.append(int(c["id"]))
	var cup := Cup.new("Kings Cup", ids, 7, me)
	cup.sim_others(func(_a, _b): return [3, 1, 4, 2])
	s.world.cups.append(cup)
	world_cup = cup
	s.office.credits = credits
	world_season = s


func _restore() -> void:
	Session.season = world_season
	Session.viewing_fighter = world_season.club.starting_five()[0]
	Session.viewing_cup = world_cup


## Every page, opened and drawn once: its ink, its panels and its buttons.
func _sweep(credits: int) -> Array:
	_world(credits)
	var out: Array = []
	for page in SCREENS:
		var path := String(page[0])
		var tab := int(page[1])
		if not ResourceLoader.exists(path):
			continue
		_restore()
		var n: Node = (load(path) as PackedScene).instantiate()
		root.add_child(n)
		n.set("season", Session.season)
		await process_frame
		if tab >= 0:
			if path.ends_with("Create.tscn"):
				n.set("page", tab)
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
		var panels := UiKit.ledger_panels()
		panels.append_array(UiKit.ledger_arts())
		var buttons: Array = []
		_buttons(n, buttons)
		out.append({"page": path.get_file() + ("" if tab < 0 else " tab %d" % tab)
			+ " @%d CC" % credits, "ink": ink, "panels": panels, "buttons": buttons,
			"credits": credits})
		n.queue_free()
		await process_frame
	return out


func _buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and (c as Button).is_visible_in_tree():
			var b := c as Button
			out.append({"rect": Rect2(b.get_global_position(), b.size), "text": String(b.text),
				"disabled": b.disabled, "primary": b.has_meta("primary"), "flat": b.flat})
		_buttons(c, out)


func _c1(pages: Array) -> void:
	var bad: Array[String] = []
	var n := 0
	for p in pages:
		for row in p["ink"]:
			n += 1
			if int(row.get("size", MIN_PX)) < MIN_PX:
				bad.append("%s: '%s' at %dpx" % [p["page"], String(row["text"]).left(30), int(row["size"])])
	_ok(bad.is_empty(), "C1 no text under %dpx" % MIN_PX,
		"%d strings%s" % [n, "" if bad.is_empty() else " — " + "; ".join(bad.slice(0, 8))])


func _lum(c: Color) -> float:
	var f := func(x: float) -> float:
		return x / 12.92 if x <= 0.03928 else pow((x + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _cr(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Against the better of the two grounds text sits on, as test_ink measures it,
## but at the body-text floor rather than its 3:1.
func _c2(pages: Array) -> void:
	var bad := {}
	var n := 0
	for p in pages:
		for row in p["ink"]:
			var col: Color = row.get("col", Color.WHITE)
			if _lum(Color(col, 1.0)) < _lum(UiKit.BG) or Color(col, 1.0).is_equal_approx(Tuning.COL_GROUND):
				continue
			## DARK INK ON A GOLD BAND (the occasion ribbon, a primary button's
			## label): near the ground's own value and clear against gold. It is
			## read against the gold, so it is measured there.
			if _cr(Color(col, 1.0), UiKit.BG) < 1.5 and _cr(Color(col, 1.0), UiKit.YOU) >= MIN_CONTRAST:
				continue
			n += 1
			var best := maxf(_cr(UiKit.BG.lerp(Color(col, 1.0), col.a), UiKit.BG),
				_cr(UiKit.PANEL.lerp(Color(col, 1.0), col.a), UiKit.PANEL))
			if best < MIN_CONTRAST:
				bad["%s: '%s' %.2f:1" % [p["page"], String(row["text"]).left(30), best]] = true
	var keys := bad.keys()
	_ok(keys.is_empty(), "C2 text reaches %.1f:1" % MIN_CONTRAST,
		"%d strings%s" % [n, "" if keys.is_empty() else " — %d below: " % keys.size() + "; ".join(keys.slice(0, 8))])


func _c3(pages: Array) -> void:
	var bad: Array[String] = []
	for p in pages:
		var gold: Array[String] = []
		for b in p["buttons"]:
			if b["primary"]:
				gold.append(String(b["text"]))
				if b["disabled"]:
					bad.append("%s: '%s' is gold and disabled" % [p["page"], b["text"]])
		if gold.size() > 1:
			bad.append("%s: %d gold (%s)" % [p["page"], gold.size(), ", ".join(gold)])
	_ok(bad.is_empty(), "C3 one gold primary per screen, never a dead one",
		"%d pages%s" % [pages.size(), "" if bad.is_empty() else " — " + "; ".join(bad.slice(0, 8))])


## "12 CC" on a button is a price; "+1 CC" is a payout and is not.
func _c4(pages: Array) -> void:
	var re := RegEx.create_from_string("(?<![+\\d])(\\d+) CC")
	var bad: Array[String] = []
	var priced := 0
	for p in pages:
		for b in p["buttons"]:
			var m := re.search(String(b["text"]))
			## A PICKER ("Proper · 8 CC  >") names an option's price and spends
			## nothing; the button that spends is checked instead.
			if m == null or String(b["text"]).strip_edges().ends_with(">"):
				continue
			priced += 1
			if int(m.get_string(1)) > int(p["credits"]) and not b["disabled"]:
				bad.append("%s: '%s' live" % [p["page"], b["text"]])
	_ok(bad.is_empty() and priced > 0, "C4 a button you cannot afford is grey",
		"%d priced buttons across both purses%s" % [priced,
			"" if bad.is_empty() else " — " + "; ".join(bad.slice(0, 8))])


## The tallest horizontal band in the content area with nothing in it: no ink,
## no panel, no button.
func _c5(pages: Array) -> void:
	var h: float = UiKit.screen().y
	## The screens are laid out for a 540-tall phone; a 4:3 tablet hands the
	## game the extra height as open ground under the layout, so that height is
	## allowed on top of the phone's 20%.
	var limit := DESIGN_H * DEAD_FRAC + maxf(0.0, h - DESIGN_H)
	var bad: Array[String] = []
	var worst := 0.0
	var worst_page := ""
	for p in pages:
		var spans: Array = []
		for row in p["ink"]:
			var r: Rect2 = row["rect"]
			spans.append(Vector2(r.position.y, r.end.y))
		for r in p["panels"]:
			spans.append(Vector2(r.position.y, r.end.y))
		for b in p["buttons"]:
			var r: Rect2 = b["rect"]
			spans.append(Vector2(r.position.y, r.end.y))
		spans.sort_custom(func(a, b): return a.x < b.x)
		var reach := TOP_Y
		var gap := 0.0
		for s in spans:
			if s.x > reach:
				gap = maxf(gap, minf(s.x, h - BOTTOM_PAD) - reach)
			reach = maxf(reach, s.y)
		gap = maxf(gap, h - BOTTOM_PAD - reach)
		if gap > worst:
			worst = gap
			worst_page = String(p["page"])
		if gap > limit:
			bad.append("%s: %.0fpx empty" % [p["page"], gap])
	_ok(bad.is_empty(), "C5 no empty band over %d%% of a phone frame" % int(DEAD_FRAC * 100.0),
		"limit %.0fpx, worst %.0fpx (%s)%s" % [limit, worst, worst_page,
			"" if bad.is_empty() else " — " + "; ".join(bad.slice(0, 8))])
