extends SceneTree
## MOCKUPS: three ways to draw a real playbook, on real formation and strategy
## data, in the real UiKit.
##
##   xvfb-run -a godot --path . --script res://tools/mock_playbook.gd -- <outdir> <n>
##
## Pete, 13 Sep 2026, with a Backyard Football playbook page: *"I feel like we can
## do a real playbook."*
##
## THE REASON WE CAN IS THAT THE DATA IS ALREADY THERE, and it took looking at
## their screen to notice. A formation is five spots across the line
## (`Tuning.FORMATIONS[f]["spots"]`) and a strategy is a depth profile plus an
## optional lane (`plan_target(strategy, slot, spot_x)` resolves the pair). So a
## play card is not an illustration somebody has to draw and keep in step with
## the sim — it is the sim's own numbers, plotted. Change a push value in
## `tuning.gd` and every card redraws correctly.
##
## Twelve real plays out of three formations and four strategies, sixteen once
## your Chalkboard shape is a formation of its own.
##
## DRAWN LEFT TO RIGHT, like the fight screen. The list is narrow and deep in the
## sim's own frame — 300 across, 570 along the charge — and `melee_scene` renders
## it rotated so the charge runs across the screen. A play card that stood it
## back upright would be the only place in the game where the fight points a
## different way.

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
	mock = Book.new()
	mock.variant = variant
	mock.build()
	root.add_child(mock)


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("%s/playbook_%d.png" % [out_dir, variant])
	print("wrote playbook_%d.png" % variant)
	quit(0)
	return true


class Book extends Node2D:
	var variant := 0
	var font: Font

	## The deepest a card shows. Nothing pushes past 0.66, so plotting the full
	## length of the list would spend a third of every card on empty ground.
	const DEPTH := 0.76
	const DOT := 5.0

	## The shape the Chalkboard sent, as a fourth formation. Invented here so the
	## mock shows the four-row case, which is what a season bout renders.
	var drawn: Array = [
		Vector2(0.14, 0.06), Vector2(0.32, 0.18), Vector2(0.50, 0.20),
		Vector2(0.68, 0.18), Vector2(0.86, 0.06),
	]

	func build() -> void:
		font = UiKit.body()
		UiKit.set_mood(UiKit.Mood.NORMAL)

	# ------------------------------------------------------------------ data
	func rows() -> Array:
		var out: Array = []
		for f in Tuning.FORMATIONS.keys():
			out.append({"name": String(Tuning.FORMATIONS[f]["name"]), "id": f,
				"spots": Tuning.FORMATIONS[f]["spots"],
				"blurb": String(Tuning.FORMATIONS[f]["blurb"])})
		out.append({"name": "Your shape", "id": -1, "spots": drawn,
			"blurb": "The shape you drew on the Chalkboard."})
		return out

	func strategies() -> Array:
		return Tuning.STRATEGIES.keys()

	# ------------------------------------------------------------- the card
	## ONE PLAY, PLOTTED. Five men where the formation stands them, five arrows
	## to where the strategy sends them. This is the whole idea.
	func play_card(r: Rect2, spots: Array, st: int, live: bool, label: String,
			label_px: int = 13, arrows: bool = true) -> void:
		UiKit.panel(self, r)
		var body := Rect2(r.position, r.size - Vector2(UiKit.DROP_PX, UiKit.DROP_PX))
		if live:
			draw_rect(body, UiKit.YOU, false, 3.0)

		var strip := 19.0 if label != "" else 0.0
		var pitch := Rect2(body.position + Vector2(7.0, 6.0),
			body.size - Vector2(14.0, 12.0 + strip))
		## The ground, a shade off the panel so the men have something to stand on.
		draw_rect(pitch, UiKit.BG.lightened(0.05))
		## YOUR RAIL, left. Theirs is off the right edge of the card — the card
		## shows the push, not the whole arena.
		draw_rect(Rect2(pitch.position, Vector2(2.0, pitch.size.y)), UiKit.FRAME)
		## Two lane guides, so a Turtle's shift to a rail reads as a shift.
		for k in 2:
			var gy := pitch.position.y + pitch.size.y * (0.33 + 0.34 * float(k))
			draw_line(Vector2(pitch.position.x, gy),
				Vector2(pitch.end.x, gy), UiKit.EDGE, 1.0)

		for slot in 5:
			var spot: Vector2 = spots[slot]
			var tgt := Tuning.plan_target(st, slot, spot.x)
			var a := _at(pitch, spot.y, spot.x)
			var b := _at(pitch, tgt.y, tgt.x)
			if arrows:
				_arrow(a, b, UiKit.DIM if not live else UiKit.INK)
			## The Center is the man a Turtle wraps, so he is the one worth
			## telling apart at a glance.
			var col: Color = UiKit.YOU if slot == 2 else UiKit.INK
			draw_rect(Rect2(a - Vector2(DOT, DOT), Vector2(DOT * 2.0, DOT * 2.0)), col)
			draw_rect(Rect2(a - Vector2(DOT, DOT), Vector2(DOT * 2.0, DOT * 2.0)),
				UiKit.PANEL, false, 1.0)

		if label != "":
			UiKit.text(self, font, label,
				Vector2(body.position.x + 8.0, body.end.y - 5.0), label_px,
				UiKit.YOU if live else UiKit.INK)

	## push 0..DEPTH runs across the card; lane 0..1 runs down it.
	func _at(pitch: Rect2, push: float, lane: float) -> Vector2:
		return Vector2(pitch.position.x + 4.0
				+ (pitch.size.x - 10.0) * clampf(push / DEPTH, 0.0, 1.0),
			pitch.position.y + 6.0 + (pitch.size.y - 12.0) * clampf(lane, 0.0, 1.0))

	func _arrow(a: Vector2, b: Vector2, col: Color) -> void:
		if a.distance_to(b) < 3.0:
			return
		draw_line(a, b, col, 2.0)
		var d := (b - a).normalized()
		var p := Vector2(-d.y, d.x)
		draw_line(b, b - d * 7.0 + p * 4.0, col, 2.0)
		draw_line(b, b - d * 7.0 - p * 4.0, col, 2.0)

	# ------------------------------------------------------------------ draw
	func _draw() -> void:
		draw_rect(Rect2(0, 0, W, H), UiKit.BG)
		match variant:
			0: _page()
			1: _sheet()
			2: _two_pane()

	## ------------------------------------------------------------ VARIANT 0
	## THE BACKYARD PAGE. Formation tabs across the top, four big cards for the
	## four strategies out of it, and a rail down the right holding the call you
	## are running and what it costs you.
	##
	## It is the closest to the reference and the best card on screen — a 300x160
	## diagram is legible from the other side of a room. It is also three taps in
	## the worst case (tab, card) against the grid's one, which is the argument
	## against it in a corner with a clock.
	func _page() -> void:
		UiKit.text(self, font, "THE BOOK", Vector2(24, 34), 26, UiKit.YOU)
		UiKit.rule(self, UiKit.RULE_GEM, Vector2(24, 46), 620.0, UiKit.FRAME)

		var rs := rows()
		var pick := 1                      ## Depth, for the mock
		for i in rs.size():
			var r := Rect2(24.0 + float(i) * 156.0, 62.0, 148.0, 34.0)
			var on: bool = i == pick
			UiKit.panel(self, r, true)
			if on:
				draw_rect(Rect2(r.position, r.size - Vector2(4, 4)), UiKit.SELECT)
				draw_rect(Rect2(r.position, r.size - Vector2(4, 4)), UiKit.YOU, false, 2.0)
			UiKit.text(self, font, String(rs[i]["name"]),
				Vector2(r.position.x + 12.0, r.position.y + 23.0), 15,
				UiKit.INK if on else UiKit.DIM)

		var sts := strategies()
		for i in sts.size():
			var cx := 24.0 + float(i % 2) * 340.0
			var cy := 112.0 + float(i / 2) * 208.0
			play_card(Rect2(cx, cy, 326.0, 196.0), rs[pick]["spots"], sts[i],
				i == 0, String(Tuning.STRATEGIES[sts[i]]["name"]), 16)

		## THE RAIL. Their side of the page carries the four plays you have
		## equipped; ours carries the one thing you cannot see from the cards —
		## what this call is actually going to cost you.
		var rail := Rect2(716.0, 112.0, 220.0, 404.0)
		UiKit.window(self, rail, "THE CALL", font)
		play_card(Rect2(730.0, 148.0, 192.0, 116.0), rs[pick]["spots"], sts[0],
			true, "", 0)
		UiKit.text(self, font, "Depth", Vector2(732, 292), 18, UiKit.INK)
		UiKit.text(self, font, "Rush left", Vector2(732, 314), 18, UiKit.YOU)
		draw_multiline_string(font, Vector2(732, 340),
			String(Tuning.STRATEGIES[sts[0]]["blurb"]), HORIZONTAL_ALIGNMENT_LEFT,
			186.0, 12, 4, UiKit.DIM)
		UiKit.text(self, font, "Drives for", Vector2(732, 432), 12, UiKit.DIM)
		UiKit.text(self, font, "%ds" % int(Tuning.PLAN_TIME), Vector2(858, 432), 14, UiKit.INK)
		UiKit.text(self, font, "Then they think", Vector2(732, 454), 12, UiKit.DIM)
		UiKit.text(self, font, "Hardened", Vector2(858, 454), 14, UiKit.INK)
		UiKit.text(self, font, "CALL IT", Vector2(732, 496), 18, UiKit.YOU)

	## ------------------------------------------------------------ VARIANT 1
	## THE CONTACT SHEET. Every play in the book on one page, four across by four
	## down, one tap each. No tabs, no paging, nothing hidden.
	##
	## Sixteen diagrams at 216x94 is small — but the thing a player is reading
	## between rounds is which way the arrows lean, and that survives the size.
	## This is the version that fits a corner with twenty seconds on it.
	func _sheet() -> void:
		UiKit.text(self, font, "THE BOOK", Vector2(24, 32), 24, UiKit.YOU)
		UiKit.right(self, font, "one tap calls the shape and the push",
			Vector2(560, 32), 13, UiKit.DIM, 376.0)
		UiKit.rule(self, UiKit.RULE_GEM, Vector2(24, 42), 912.0, UiKit.FRAME)

		var rs := rows()
		var sts := strategies()
		## 126 + 4*196 + 3*8 = 934. The label column was 90 and "Strong left" wants
		## 88 of it at 15px — it rendered "Strong le" and "Your shap", which is the
		## same clip the corner's strategy buttons had and the same lesson.
		for i in sts.size():
			UiKit.text(self, font, String(Tuning.STRATEGIES[sts[i]]["name"]),
				Vector2(126.0 + float(i) * 204.0, 70.0), 14, UiKit.DIM)
		for r in rs.size():
			var y := 78.0 + float(r) * 112.0
			UiKit.text(self, font, String(rs[r]["name"]), Vector2(24, y + 56.0), 13,
				UiKit.YOU if r == 1 else UiKit.INK)
			for c in sts.size():
				play_card(Rect2(126.0 + float(c) * 204.0, y, 196.0, 100.0),
					rs[r]["spots"], sts[c], r == 1 and c == 0, "")

	## ------------------------------------------------------------ VARIANT 2
	## THE SPLIT. The shapes down the left at thumbnail size, the four plays out
	## of the selected one big on the right.
	##
	## It is the two-step done honestly: the left column is a real comparison of
	## the four SHAPES, which the tab strip in variant 0 reduces to four words,
	## and the right side still gets cards you can read.
	func _two_pane() -> void:
		UiKit.text(self, font, "THE BOOK", Vector2(24, 32), 24, UiKit.YOU)
		UiKit.rule(self, UiKit.RULE_GEM, Vector2(24, 42), 912.0, UiKit.FRAME)
		UiKit.text(self, font, "SHAPE", Vector2(24, 68), 12, UiKit.DIM)
		UiKit.text(self, font, "OUT OF IT", Vector2(268, 68), 12, UiKit.DIM)

		var rs := rows()
		var sts := strategies()
		var pick := 1
		## NO ARROWS DOWN THE LEFT. They were drawn with Rush left on every card,
		## which says "these four shapes all run this play" — the exact opposite of
		## what the column is for. It is a shape picker; it shows the shape.
		for i in rs.size():
			var r := Rect2(24.0, 78.0 + float(i) * 110.0, 224.0, 102.0)
			play_card(r, rs[i]["spots"], sts[0], i == pick, String(rs[i]["name"]),
				14, false)

		for i in sts.size():
			var cx := 268.0 + float(i % 2) * 340.0
			var cy := 78.0 + float(i / 2) * 224.0
			play_card(Rect2(cx, cy, 326.0, 212.0), rs[pick]["spots"], sts[i],
				i == 0, String(Tuning.STRATEGIES[sts[i]]["name"]), 16)
