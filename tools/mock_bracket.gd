extends SceneTree
## MOCKUPS: four ways to draw a bracket, on real cup data, in the real UiKit.
##
##   xvfb-run -a godot --path . --script res://tools/mock_bracket.gd -- <outdir>
##
## Drawn rather than described, because the whole question is what it looks like
## at 960x540 with fourteen-character club names in it — and that is the third
## thing on this project that could not be reasoned about and had to be rendered.
##
## Retro Bowl's own bracket, read out of its shipped GameMaker build, is 480x270
## with two conference panels, three-letter abbreviations, **no scores, no seeds
## and no connecting lines** — the tree is carried entirely by column position
## and vertical alignment. We have twice the resolution and one bracket instead
## of two conferences, so most of what they left out, we can afford.

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
	mock = MockScreen.new()
	mock.variant = variant
	mock.build()
	root.add_child(mock)


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	var img := root.get_texture().get_image()
	img.save_png("%s/bracket_%d.png" % [out_dir, variant])
	print("wrote bracket_%d.png" % variant)
	quit(0)
	return true


class MockScreen extends Node2D:
	var variant := 0
	var font: Font
	var world: LeagueWorld
	var cup: Cup
	var me: int = 0

	func build() -> void:
		font = ThemeDB.fallback_font
		## A real world and a real cup, played far enough in to have a half-filled
		## bracket — which is the state the screen actually has to survive. An
		## empty bracket looks fine in every layout ever drawn.
		var s := Season.new(MeleeRosters.starting_club(), 90210)
		world = s.world
		me = world.player_club
		var field: Array = []
		var pool: Array = []
		for c in world.clubs:
			pool.append(int(c["id"]))
		field.append(me)
		for id in pool:
			if id != me and field.size() < 8:
				field.append(id)
		if variant == 3:
			## Worlds is sixteen, and a four-pool mock drawn off an eight-club
			## field printed the same two clubs in pools A and C. A mock that
			## repeats itself is a mock that cannot show you a collision.
			field.clear()
			field.append(me)
			for id in pool:
				if id != me and field.size() < 16:
					field.append(id)
			cup = Cup.new("Worlds", field, 4242, me)
		else:
			cup = Cup.new("Kings Cup", field, 4242, me)
		## Play the first round out so the picture has winners, losers and a live
		## tie in it at once.
		## PLAYED FAR ENOUGH IN THAT THE PICTURE HAS EVERY STATE IN IT AT ONCE: a
		## round finished, a round live, a round still empty, and the player
		## somewhere in the middle of it. The first render stopped with the
		## player's own quarter-final outstanding, which is a real state and a
		## useless mock — three quarters of the screen was dashes.
		var r: Callable = world.cup_resolver()
		var g := 0
		while cup.rounds.size() < 2 and g < 8:
			g += 1
			cup.sim_others(r)
			var m := cup.player_match()
			if not m.is_empty():
				cup.record(m, 2, 1, 5, 2)
			if cup.round_complete():
				cup.advance()
		cup.sim_others(r)

	func _name(id: int) -> String:
		if id < 0 or id >= world.clubs.size():
			return "—"
		return String(world.clubs[id]["name"])

	func _short(id: int) -> String:
		if id < 0 or id >= world.clubs.size():
			return "—"
		return String(world.clubs[id]["short"])

	func _power(id: int) -> int:
		return 0 if id < 0 or id >= world.clubs.size() else int(world.clubs[id]["power"])

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), UiKit.BG)
		## Variant 3 writes its own title — drawing the cup's name first put
		## KINGS CUP underneath WORLDS and produced an unreadable smear, which is
		## the fourth time on this project that a layout problem was invisible
		## until it was rendered.
		if variant != 3:
			UiKit.text(self, font, cup.cup_name.to_upper(), Vector2(24, 40), 22, UiKit.YOU)
		match variant:
			0: _classic()
			1: _ladder()
			2: _road()
			3: _pools()

	# ------------------------------------------------------------ variant 0
	## THEIRS, WIDENED. Retro Bowl's idiom — columns converging on a centre
	## column — but with the three things they leave out and we can afford at
	## twice the resolution: full club names, seeds, and the score of a tie that
	## has been fought.
	func _classic() -> void:
		UiKit.text(self, font, "Eight clubs  ·  seeded  ·  one leg",
			Vector2(24, 64), 13, UiKit.DIM)
		var cols := [
			{"x": 24.0, "w": 250.0, "label": "QUARTER-FINALS"},
			{"x": 300.0, "w": 250.0, "label": "SEMI-FINALS"},
			{"x": 576.0, "w": 250.0, "label": "FINAL"},
		]
		for i in cols.size():
			var c: Dictionary = cols[i]
			UiKit.text(self, font, String(c["label"]), Vector2(float(c["x"]), 106), 12, UiKit.DIM)
			var day: Array = cup.rounds[i] if i < cup.rounds.size() else []
			var slots: int = int(pow(2.0, float(cols.size() - 1 - i)))
			var span := 380.0 / float(slots)
			for j in slots:
				var y := 130.0 + span * float(j) + span * 0.5 - 34.0
				var m: Dictionary = day[j] if j < day.size() else {}
				_tie(Vector2(float(c["x"]), y), float(c["w"]), m, i)
		## The trophy, where the two halves would meet in their layout and where
		## ours simply ends — a final on the right with nothing after it reads as
		## a column that got cut off.
		UiKit.panel(self, Rect2(852, 236, 84, 76))
		UiKit.text(self, font, "WINS", Vector2(866, 262), 12, UiKit.DIM)
		UiKit.text(self, font, "THE", Vector2(872, 280), 12, UiKit.DIM)
		UiKit.text(self, font, "CUP", Vector2(872, 298), 12, UiKit.YOU)

	## One tie: two clubs, a seed each, and the score if it has been fought.
	func _tie(at: Vector2, w: float, m: Dictionary, round_i: int) -> void:
		var a: int = int(m.get("a", -1))
		var b: int = int(m.get("b", -1))
		var played: bool = bool(m.get("played", false))
		var live: bool = not played and (a == me or b == me) \
			and round_i == cup.rounds.size() - 1
		if live:
			draw_rect(Rect2(at - Vector2(4, 4), Vector2(w + 8, 76)), UiKit.SELECT)
		_slot(at, w, a, m, true, played, live)
		_slot(at + Vector2(0, 34), w, b, m, false, played, live)

	func _slot(at: Vector2, w: float, id: int, m: Dictionary, is_a: bool,
			played: bool, live: bool) -> void:
		var won: bool = played and int(m.get("winner", -1)) == id
		## A FINISHED TIE MARKS ITS WINNER. Retro Bowl dims both men in a played
		## game and leaves you to infer the winner from the next column — which
		## works on a bracket of abbreviations and would be perverse on one that
		## has the room to just say so.
		var col := UiKit.INK if (won or not played) else UiKit.DIM
		if id == me:
			col = UiKit.YOU
		UiKit.panel(self, Rect2(at.x, at.y, w, 30), false)
		if won:
			draw_rect(Rect2(at.x, at.y, 3, 30), UiKit.UP)
		if id >= 0:
			var seed_i: int = cup.entrants.find(id)
			UiKit.text(self, font, "%d" % (seed_i + 1), Vector2(at.x + 9, at.y + 20), 12, UiKit.DIM)
			UiKit.text(self, font, UiKit.clip(_name(id), 18), Vector2(at.x + 26, at.y + 20), 14, col)
		else:
			UiKit.text(self, font, "—", Vector2(at.x + 26, at.y + 20), 14, UiKit.DIM)
		if played:
			var sc: int = int(m.get("ra", 0)) if is_a else int(m.get("rb", 0))
			UiKit.right(self, font, "%d" % sc, Vector2(at.x + w - 8, at.y + 20), 14,
				UiKit.INK if won else UiKit.DIM, 30)

	# ------------------------------------------------------------ variant 1
	## A LADDER, NOT A TREE. One column, one row per tie, grouped by round — the
	## layout a phone actually wants. It gives up the shape of the draw and buys
	## back full names, scores, ratings and room for sixteen clubs without
	## anything shrinking.
	func _ladder() -> void:
		UiKit.text(self, font, "Every tie, by round  ·  the draw as a list",
			Vector2(24, 64), 13, UiKit.DIM)
		var y := 100.0
		for i in cup.rounds.size():
			var day: Array = cup.rounds[i]
			UiKit.text(self, font, String(day[0]["round"]).to_upper(), Vector2(24, y), 12, UiKit.DIM)
			y += 22.0
			for m in day:
				_row(Vector2(24, y), 460.0, m as Dictionary)
				y += 34.0
			y += 10.0
		## The right half is where a list wins: the thing a bracket can never say
		## is who you would actually meet.
		UiKit.panel(self, Rect2(510, 100, 426, 300))
		UiKit.text(self, font, "YOUR ROAD", Vector2(532, 130), 14, UiKit.YOU)
		var path := cup.player_match()
		var opp: int = -1
		if not path.is_empty():
			opp = int(path["b"]) if int(path["a"]) == me else int(path["a"])
		UiKit.text(self, font, "Next:  %s" % (_name(opp) if opp >= 0 else "—"),
			Vector2(532, 164), 16, UiKit.INK)
		UiKit.text(self, font, "rating %d against your %d" % [_power(opp), _power(me)],
			Vector2(532, 188), 13, UiKit.DIM)
		UiKit.text(self, font, "Win and you meet the winner of", Vector2(532, 226), 13, UiKit.DIM)
		var others: Array = []
		for m in cup.current_round():
			if int(m["a"]) != me and int(m["b"]) != me:
				others.append(m)
		var oy := 250.0
		for m in others:
			UiKit.text(self, font, "%s  or  %s" % [UiKit.clip(_name(int(m["a"])), 14),
				UiKit.clip(_name(int(m["b"])), 14)], Vector2(532, oy), 14, UiKit.INK)
			oy += 24.0
		UiKit.text(self, font, "Three wins from the cup.", Vector2(532, oy + 18), 13, UiKit.DIM)

	func _row(at: Vector2, w: float, m: Dictionary) -> void:
		var a: int = int(m["a"])
		var b: int = int(m["b"])
		var played: bool = bool(m.get("played", false))
		var mine: bool = a == me or b == me
		if mine:
			draw_rect(Rect2(at.x - 4, at.y - 18, w + 8, 30), UiKit.SELECT)
		var acol := UiKit.YOU if a == me else (UiKit.INK if (not played or int(m["winner"]) == a) else UiKit.DIM)
		var bcol := UiKit.YOU if b == me else (UiKit.INK if (not played or int(m["winner"]) == b) else UiKit.DIM)
		UiKit.text(self, font, UiKit.clip(_name(a), 17), Vector2(at.x, at.y), 14, acol)
		UiKit.right(self, font, ("%d" % int(m["ra"])) if played else "", Vector2(at.x + 250, at.y), 14, acol, 30)
		UiKit.text(self, font, "v" if not played else "-", Vector2(at.x + 258, at.y), 12, UiKit.DIM)
		UiKit.text(self, font, ("%d" % int(m["rb"])) if played else "", Vector2(at.x + 272, at.y), 14, bcol)
		UiKit.text(self, font, UiKit.clip(_name(b), 17), Vector2(at.x + 296, at.y), 14, bcol)

	# ------------------------------------------------------------ variant 2
	## THE ROAD. Not a bracket at all — YOUR path, one step per round, with the
	## rest of the draw as a footnote. The most honest layout for a game where
	## you only ever fight one tie at a time, and the only one that fits a cup of
	## sixteen without scrolling.
	func _road() -> void:
		UiKit.text(self, font, "Your road to the cup", Vector2(24, 64), 13, UiKit.DIM)
		var steps := ["Quarter-finals", "Semi-finals", "Final"]
		var x := 40.0
		for i in steps.size():
			var done: bool = i < cup.rounds.size() - 1
			var here: bool = i == cup.rounds.size() - 1
			var col := UiKit.UP if done else (UiKit.YOU if here else UiKit.DIM)
			UiKit.panel(self, Rect2(x, 120, 268, 150), here)
			UiKit.text(self, font, steps[i].to_upper(), Vector2(x + 18, 150), 12, col)
			var m: Dictionary = {}
			if i < cup.rounds.size():
				for cand in cup.rounds[i]:
					if int(cand["a"]) == me or int(cand["b"]) == me:
						m = cand
			if m.is_empty():
				UiKit.text(self, font, "—", Vector2(x + 18, 196), 20, UiKit.DIM)
				UiKit.text(self, font, "not there yet", Vector2(x + 18, 226), 13, UiKit.DIM)
			else:
				var opp: int = int(m["b"]) if int(m["a"]) == me else int(m["a"])
				UiKit.text(self, font, UiKit.clip(_name(opp), 20), Vector2(x + 18, 196), 18, UiKit.INK)
				UiKit.text(self, font, "rating %d" % _power(opp), Vector2(x + 18, 222), 13, UiKit.DIM)
				if bool(m.get("played", false)):
					var mine_r: int = int(m["ra"]) if int(m["a"]) == me else int(m["rb"])
					var his_r: int = int(m["rb"]) if int(m["a"]) == me else int(m["ra"])
					var won: bool = mine_r > his_r
					UiKit.text(self, font, "%s %d-%d" % ["WON" if won else "OUT", mine_r, his_r],
						Vector2(x + 18, 250), 15, UiKit.UP if won else UiKit.DOWN)
				else:
					UiKit.text(self, font, "to fight", Vector2(x + 18, 250), 13, UiKit.YOU)
			if i < steps.size() - 1:
				draw_line(Vector2(x + 276, 195), Vector2(x + 296, 195), UiKit.EDGE, 2.0)
			x += 296.0
		## The rest of the draw, small, underneath — there if you want it and not
		## competing with the thing you came to read.
		UiKit.text(self, font, "THE REST OF THE DRAW", Vector2(40, 320), 12, UiKit.DIM)
		var y := 348.0
		var col_x := 40.0
		for m in cup.current_round():
			if int(m["a"]) == me or int(m["b"]) == me:
				continue
			UiKit.text(self, font, "%s v %s" % [UiKit.clip(_name(int(m["a"])), 16),
				UiKit.clip(_name(int(m["b"])), 16)], Vector2(col_x, y), 13, UiKit.DIM)
			y += 24.0
			if y > 420.0:
				y = 348.0
				col_x += 300.0

	# ------------------------------------------------------------ variant 3
	## WORLDS. Four pools of four, then an eight-club bracket — the one shape
	## none of the above can hold, and the reason the cup screen needs a mode
	## rather than a layout.
	func _pools() -> void:
		UiKit.text(self, font, "WORLDS  ·  GROUP STAGE", Vector2(24, 40), 22, UiKit.YOU)
		UiKit.text(self, font, "Sixteen clubs  ·  four pools  ·  top two go through",
			Vector2(24, 64), 13, UiKit.DIM)
		var names := ["POOL A", "POOL B", "POOL C", "POOL D"]
		for p in 4:
			var px := 24.0 + float(p % 2) * 468.0
			var py := 100.0 + float(p / 2) * 212.0
			UiKit.panel(self, Rect2(px, py, 444, 192))
			UiKit.text(self, font, names[p], Vector2(px + 18, py + 28), 13, UiKit.DIM)
			UiKit.right(self, font, "P   W   D   L   MARGIN", Vector2(px + 426, py + 28),
				12, UiKit.EDGE, 240)
			for i in 4:
				var id: int = cup.entrants[(p * 4 + i) % cup.entrants.size()]
				## Four rows a pool, sixteen clubs, no repeats — asserted by the
				## field above rather than by the modulo, which is only here so a
				## short field degrades instead of crashing.
				var through: bool = i < 2
				var col := UiKit.YOU if id == me else (UiKit.INK if through else UiKit.DIM)
				var ry := py + 62.0 + float(i) * 30.0
				if through:
					draw_rect(Rect2(px + 12, ry - 16, 3, 22), UiKit.UP)
				UiKit.text(self, font, "%d" % (i + 1), Vector2(px + 24, ry), 12, UiKit.DIM)
				UiKit.text(self, font, UiKit.clip(_name(id), 20), Vector2(px + 44, ry), 14, col)
				UiKit.right(self, font, "3   %d   0   %d   %+d" % [2 - i, i, 6 - i * 4],
					Vector2(px + 426, ry), 13, col, 240)
		UiKit.text(self, font, "Top two of each pool make the quarter-finals.",
			Vector2(24, 524), 12, UiKit.DIM)
