extends SceneTree
## MOCKUPS: three ways to draw the meeting card, on real data, in the real UiKit.
##
##   xvfb-run -a godot --path . --script res://tools/mock_meeting.gd -- <outdir> <n>
##
## Pete, 14 Sep 2026, with Retro Bowl's roster meeting screen: *"Let's try a few
## more mock ups of that."*
##
## Theirs is one panel per man with four rows — MORALE / CONDITION / XP LEVEL /
## CONTRACT — each a read-out, a button and a price in credits, and arrows to
## page through the squad. Ours currently spreads the same four across the
## fighter screen: three purchases in the strip at `LEVEL_ROW_Y` and the contract
## in the footer.
##
## EVERY NUMBER ON THESE IS THE REAL ONE. `negotiate_cost`, `kit_cost`,
## `Career.level_cost` and `Season.extend_cost` are called for an actual man off
## an actual starting club, so a mock cannot flatter a price the game does not
## charge — which is the mistake the after-action mock made when its column
## widths were invented rather than measured.
const W := 960.0
const H := 540.0

var out_dir := "user://"
var variant := 0
var n := 0
var mock: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = String(args[0])
	if args.size() > 1:
		variant = int(args[1])
	mock = Card.new()
	mock.variant = variant
	mock.build()
	root.add_child(mock)


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("%s/meeting_%d.png" % [out_dir, variant])
	print("wrote meeting_%d.png" % variant)
	quit(0)
	return true


class Card extends Node2D:
	var variant := 0
	var font: Font
	var season: Season
	var man: FighterCard
	var rows: Array = []

	const NAME := ["A · four rows, their shape", "B · two columns",
		"C · the strip, as built"]

	func build() -> void:
		font = UiKit.body()
		season = Season.new(MeleeRosters.starting_club(), 20260914)
		Session.season = season
		## A MAN WITH SOMETHING WRONG WITH HIM IN EVERY ROW, because a card whose
		## every value is already at its best is a picture of four disabled
		## buttons. Toxic, a battered harness, a level part-way up and a deal
		## running out is the afternoon this screen exists for.
		man = season.club.starting_five()[1]
		man.morale = 0.14
		man.armor = 0.46
		man.age = 29
		man.potential = 99
		man.level = 5
		man.xp = 0
		man.years = 1
		season.office.credits = 46
		rows = [
			{"label": "MORALE", "value": man.morale_word(),
				"verb": "Sit him down", "cc": ClubOffice.negotiate_cost(man),
				"off": false},
			{"label": "CONDITION", "value": "%d%%" % int(round(man.armor * 100.0)),
				"verb": "The armorer", "cc": ClubOffice.kit_cost(man),
				"off": man.armor >= 1.0},
			{"label": "XP LEVEL", "value": str(man.level),
				"verb": "Extra reps", "cc": Career.level_cost(man),
				"off": Career.at_ceiling(man)},
			{"label": "CONTRACT",
				"value": "%s · %dy" % [ClubOffice.money(man.wage_agreed), man.years],
				"verb": "Extend", "cc": season.extend_cost(man), "off": false},
		]
		queue_redraw()

	func _draw() -> void:
		UiKit.set_mood(UiKit.Mood.NORMAL)
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), UiKit.BG)
		UiKit.mid(self, font, NAME[variant], Vector2(0, 30), 15, UiKit.DIM, W)
		UiKit.mid(self, font, man.display_name.to_upper(), Vector2(0, 66), 26,
			UiKit.INK, W)
		UiKit.right(self, font, "%d CC" % season.office.credits,
			Vector2(W - 24, 30), 15, UiKit.YOU, 200)
		match variant:
			0: _four_rows()
			1: _two_columns()
			_: _the_strip()

	## ------------------------------------------------------------------- A
	## THEIR SHAPE, LITERALLY: one row a line, read-out on the left, the verb in
	## the middle, the price in its own box on the right. Four rows down a single
	## panel, the man's name over the top of it.
	func _four_rows() -> void:
		var top := 96.0
		var h := 66.0
		var panel := Rect2(90.0, top - 14.0, W - 180.0, h * 4.0 + 20.0)
		UiKit.panel(self, panel)
		for i in rows.size():
			var r: Dictionary = rows[i]
			var y := top + float(i) * h
			_cell(Rect2(110.0, y, 170.0, 50.0), String(r["label"]),
				String(r["value"]), bool(r["off"]))
			_button(Rect2(296.0, y, 380.0, 50.0), String(r["verb"]),
				bool(r["off"]))
			_price(Rect2(692.0, y, 158.0, 50.0), int(r["cc"]), bool(r["off"]))

	## ------------------------------------------------------------------- B
	## THE SAME FOUR IN TWO COLUMNS, which halves the height and leaves the
	## bottom of the screen for the stat panels the fighter page already has.
	## The price rides ON the button here rather than beside it — one control
	## instead of two, which is what every other button in this game does.
	func _two_columns() -> void:
		var panel := Rect2(60.0, 86.0, W - 120.0, 190.0)
		UiKit.panel(self, panel)
		for i in rows.size():
			var r: Dictionary = rows[i]
			var col := i % 2
			var line := i / 2
			var x := 84.0 + float(col) * 400.0
			var y := 104.0 + float(line) * 84.0
			_cell(Rect2(x, y, 150.0, 46.0), String(r["label"]),
				String(r["value"]), bool(r["off"]))
			_button(Rect2(x + 162.0, y, 214.0, 46.0),
				"%s · %d CC" % [String(r["verb"]), int(r["cc"])], bool(r["off"]))

	## ------------------------------------------------------------------- C
	## WHAT IS ACTUALLY BUILT, drawn here so the three can be compared on one
	## screen rather than one in the game and two on paper. The read-outs live in
	## the left panel of the fighter page and the buttons are a strip along the
	## bottom, which is why the row is four wide and has no prices beside it.
	func _the_strip() -> void:
		var panel := Rect2(60.0, 96.0, 300.0, 200.0)
		UiKit.panel(self, panel)
		var y := 118.0
		for r in rows:
			UiKit.text(self, font, String(r["label"]), Vector2(82.0, y), 13,
				UiKit.DIM)
			UiKit.right(self, font, String(r["value"]), Vector2(338.0, y), 15,
				UiKit.INK, 220.0)
			y += 44.0
		var bw := (W - 120.0 - 3.0 * 10.0) / 4.0
		for i in rows.size():
			var r: Dictionary = rows[i]
			_button(Rect2(60.0 + float(i) * (bw + 10.0), 360.0, bw, 46.0),
				"%s · %d CC" % [String(r["verb"]), int(r["cc"])], bool(r["off"]))

	# ------------------------------------------------------------- the parts
	func _cell(box: Rect2, label: String, value: String, off: bool) -> void:
		draw_rect(box, UiKit.TRACK)
		draw_rect(box, UiKit.FRAME, false, 1.0)
		UiKit.mid(self, font, label, box.position + Vector2(0, 17), 12,
			UiKit.DIM, box.size.x)
		UiKit.mid(self, font, value, box.position + Vector2(0, 38), 17,
			UiKit.DIM if off else UiKit.INK, box.size.x)

	## A DISABLED CONTROL STILL SHOWS ITS PRICE, which is the one UI rule worth
	## taking straight from their screen: Boost Morale at 100% is blacked out and
	## STILL reads 1 CC. The player learns the lever exists before he needs it.
	func _button(box: Rect2, text: String, off: bool) -> void:
		draw_rect(box, UiKit.TRACK if off else UiKit.PANEL)
		draw_rect(box, UiKit.FRAME if off else UiKit.EDGE, false, 2.0)
		UiKit.mid(self, font, text, box.position + Vector2(0, box.size.y * 0.5 + 6.0),
			16, UiKit.DIM if off else UiKit.INK, box.size.x)

	func _price(box: Rect2, cc: int, off: bool) -> void:
		draw_rect(box, UiKit.TRACK if off else UiKit.PANEL)
		draw_rect(box, UiKit.FRAME if off else UiKit.EDGE, false, 2.0)
		UiKit.mid(self, font, "%d CC" % cc,
			box.position + Vector2(0, box.size.y * 0.5 + 6.0), 17,
			UiKit.DIM if off else UiKit.YOU, box.size.x)
