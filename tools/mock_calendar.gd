extends SceneTree
## MOCKUPS: the season calendar (Pete, playtest 30 Sep #14: "Standings are
## confusing when you're fighting tournament cups … mock up a calendar system and
## show the cups, regular matches, and playoffs").
##
##   xvfb-run -a godot --path . --script res://tools/mock_calendar.gd -- <outdir> <variant>
##
## Drawn on a real season in the real UiKit. Variant 0 is a season strip (one
## column per event week); variant 1 is a week list with the table beside it.
## Playoffs do not exist in the game; both mocks show where a promotion playoff
## would sit, marked PROPOSED, so the decision can be made on the picture.

var out_dir := "user://"
var variant := 0
var n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = String(args[0])
	if args.size() > 1:
		variant = int(args[1])
	var m := Mock.new()
	m.variant = variant
	root.add_child(m)


func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("%s/calendar_%d.png" % [out_dir, variant])
	print("wrote calendar_%d.png" % variant)
	quit(0)
	return true


class Mock extends Node2D:
	var variant := 0
	var font: Font
	var s: Season
	var weeks: Array = []

	func _ready() -> void:
		font = UiKit.body()
		s = Season.new(MeleeRosters.starting_club(), 90210)
		Session.season = s
		UiKit.set_mood(UiKit.Mood.NORMAL)
		var w := s.world
		var n := w.events_this_season()
		var fx: Array = w.remaining_fixtures(n)
		## Two events played, so the strip has a past, a present and a future.
		for i in n:
			var f: Dictionary = fx[i] if i < fx.size() else {}
			var opp := int(f.get("opponent", -1))
			var wk := {"event": i + 1, "opp": String(w.clubs[opp]["short"]) if opp >= 0 else "BYE",
				"opp_name": String(w.clubs[opp]["name"]) if opp >= 0 else "Bye",
				"home": bool(f.get("home", false)), "cups": [], "state": 0}
			if i < 2:
				wk["state"] = -1
				wk["result"] = "W 2-1" if i == 0 else "L 0-2"
			elif i == 2:
				wk["state"] = 0
			else:
				wk["state"] = 1
			weeks.append(wk)
		## The invitationals, where `LeagueWorld._invitational_event` puts them.
		for spec in LeagueWorld.INVITATIONALS:
			var at := int(spec["at"])
			var e := at if at >= 0 else maxi(1, n + at)
			if e - 1 < weeks.size():
				weeks[e - 1]["cups"].append({"name": String(spec["name"]), "round": "QF"})
		## The tournament the club bid for (the Arena's three dates).
		var mid := int(round(n * 0.5))
		weeks[mid - 1]["cups"].append({"name": "Your tournament", "round": "host", "own": true})
		## A cup tie already lost, so the strip can show what a loss there means.
		weeks[1]["cups"] = [{"name": "Kings Cup", "round": "QF", "lost": true}]

	func _draw() -> void:
		UiKit.ground(self)
		if variant == 0:
			_strip()
		else:
			_list()

	## ------------------------------------------------------------ variant 0
	func _strip() -> void:
		UiKit.text(self, font, "THE SEASON", Vector2(24, 40), 22, UiKit.YOU)
		UiKit.text(self, font, "Backyard Circuit · Season 1 · %d league events" % weeks.size(),
			Vector2(24, 64), 14, UiKit.DIM)
		_legend(Vector2(470, 36))
		var x0 := 24.0
		var cols := weeks.size() + 2
		var cw := (UiKit.screen().x - 48.0 - float(cols - 1) * 6.0) / float(cols)
		var top := 96.0
		for i in weeks.size():
			var wk: Dictionary = weeks[i]
			var x := x0 + float(i) * (cw + 6.0)
			var now: bool = int(wk["state"]) == 0
			var past: bool = int(wk["state"]) < 0
			## The week's frame: gold for this week, dim for the past.
			UiKit.panel(self, Rect2(x, top, cw, 330.0))
			if now:
				draw_rect(Rect2(x, top, cw, 330.0), UiKit.YOU, false, 3.0)
				UiKit.mid(self, font, "THIS WEEK", Vector2(x, top - 6.0), 12, UiKit.YOU, cw)
			UiKit.mid(self, font, "EVENT %d" % int(wk["event"]), Vector2(x, top + 22.0), 13,
				UiKit.DIM if past else UiKit.INK, cw)
			## LEAGUE: the block that counts in the table.
			var ly := top + 36.0
			draw_rect(Rect2(x + 6, ly, cw - 12, 92), Color("2a5caa").darkened(0.35))
			UiKit.mid(self, font, "LEAGUE", Vector2(x + 6, ly + 16), 12, Color("9fc3ff"), cw - 12)
			UiKit.mid(self, font, ("H " if bool(wk["home"]) else "A ") + String(wk["opp"]),
				Vector2(x + 6, ly + 44), 18, UiKit.INK, cw - 12)
			if past:
				var res := String(wk.get("result", ""))
				UiKit.mid(self, font, res, Vector2(x + 6, ly + 72), 15,
					UiKit.UP if res.begins_with("W") else UiKit.DOWN, cw - 12)
			else:
				UiKit.mid(self, font, "counts", Vector2(x + 6, ly + 72), 12, UiKit.DIM, cw - 12)
			## CUPS: a second block under it, a different colour, never in the table.
			var cy := ly + 104.0
			for c in wk["cups"]:
				var own: bool = bool(c.get("own", false))
				var col := Color("c08a1e") if not own else Color("2f7d3b")
				draw_rect(Rect2(x + 6, cy, cw - 12, 92), col.darkened(0.45))
				UiKit.mid(self, font, "CUP" if not own else "YOURS", Vector2(x + 6, cy + 16), 12,
					col.lightened(0.4), cw - 12)
				UiKit.para(self, font, String(c["name"]), Vector2(x + 10, cy + 40), 13, UiKit.INK,
					cw - 20, 15.0, 2)
				if bool(c.get("lost", false)):
					UiKit.mid(self, font, "OUT", Vector2(x + 6, cy + 82), 14, UiKit.DOWN, cw - 12)
				else:
					UiKit.mid(self, font, String(c["round"]), Vector2(x + 6, cy + 82), 12, UiKit.DIM, cw - 12)
				cy += 100.0
		## PROPOSED: the playoff and the promotion, after the last league week.
		var px := x0 + float(weeks.size()) * (cw + 6.0)
		_end_col(Rect2(px, top, cw, 330.0), "PLAYOFF", "PROPOSED", "1st v 2nd\nfor the title", Color("7b3fa0"))
		_end_col(Rect2(px + cw + 6.0, top, cw, 330.0), "SEASON END", "", "Top 2 up\nPromotion offer", UiKit.FRAME)
		UiKit.para(self, font, "Cup results never touch the league table. A lost cup tie says OUT on its own block; the league block beside it is the only thing the standings count.",
			Vector2(24, 452), 14, UiKit.INK, UiKit.span(), 18.0, 2)

	func _end_col(r: Rect2, head: String, tag: String, body: String, col: Color) -> void:
		UiKit.panel(self, r)
		draw_rect(r, col, false, 2.0)
		UiKit.mid(self, font, head, Vector2(r.position.x, r.position.y + 22.0), 12, UiKit.INK, r.size.x)
		if tag != "":
			UiKit.mid(self, font, tag, Vector2(r.position.x, r.position.y + 40.0), 11, Color("c8b0f0"), r.size.x)
		var y := r.position.y + 80.0
		for line in body.split("\n"):
			UiKit.mid(self, font, line, Vector2(r.position.x, y), 12, UiKit.DIM, r.size.x)
			y += 18.0

	func _legend(at: Vector2) -> void:
		var items := [["League — counts in the table", Color("2a5caa")], ["Cup — its own bracket", Color("c08a1e")],
			["Your tournament", Color("2f7d3b")], ["Proposed", Color("7b3fa0")]]
		var y := at.y - 12.0
		for i in items.size():
			var cx := at.x + float(i % 2) * 240.0
			var cyy := y + float(i / 2) * 20.0
			draw_rect(Rect2(cx, cyy - 9.0, 12, 12), Color(items[i][1]))
			UiKit.text(self, font, String(items[i][0]), Vector2(cx + 18, cyy + 2), 12, UiKit.DIM)

	## ------------------------------------------------------------ variant 1
	func _list() -> void:
		UiKit.text(self, font, "THE SEASON", Vector2(24, 40), 22, UiKit.YOU)
		UiKit.text(self, font, "One row a week. League on the left, cups on the right.", Vector2(24, 64), 14, UiKit.DIM)
		var y := 100.0
		UiKit.text(self, font, "WEEK", Vector2(24, y), 12, UiKit.DIM)
		UiKit.text(self, font, "LEAGUE (counts in the table)", Vector2(90, y), 12, Color("9fc3ff"))
		UiKit.text(self, font, "CUPS (their own brackets)", Vector2(400, y), 12, Color("e0b860"))
		y += 12.0
		for wk in weeks:
			var now: bool = int(wk["state"]) == 0
			var past: bool = int(wk["state"]) < 0
			var r := Rect2(16, y, 640, 32)
			draw_rect(r, UiKit.SELECT if now else (UiKit.PANEL if int(wk["event"]) % 2 == 0 else UiKit.BG))
			if now:
				draw_rect(r, UiKit.YOU, false, 2.0)
			UiKit.text(self, font, "%d" % int(wk["event"]), Vector2(30, y + 22), 15, UiKit.YOU if now else UiKit.INK)
			UiKit.text(self, font, ("Home v " if bool(wk["home"]) else "Away at ") + String(wk["opp_name"]),
				Vector2(90, y + 22), 14, UiKit.DIM if past else UiKit.INK)
			if past:
				var res := String(wk.get("result", ""))
				UiKit.right(self, font, res, Vector2(380, y + 22), 14, UiKit.UP if res.begins_with("W") else UiKit.DOWN, 60)
			var cx := 400.0
			for c in wk["cups"]:
				var own: bool = bool(c.get("own", false))
				var label := ("Yours · host" if own else "%s · %s" % [String(c["name"]),
					"OUT" if bool(c.get("lost", false)) else String(c["round"])])
				var colc := Color("2f7d3b") if own else Color("c08a1e")
				var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16.0
				draw_rect(Rect2(cx, y + 6, tw, 22), colc.darkened(0.35))
				UiKit.text(self, font, label, Vector2(cx + 8, y + 22), 13,
					UiKit.DOWN if bool(c.get("lost", false)) else UiKit.INK)
				cx += tw + 6.0
			y += 34.0
		draw_rect(Rect2(16, y, 640, 32), Color("7b3fa0").darkened(0.5))
		UiKit.text(self, font, "PLAYOFF  ·  1st v 2nd for the title  ·  PROPOSED", Vector2(30, y + 22), 13, Color("c8b0f0"))
		y += 34.0
		draw_rect(Rect2(16, y, 640, 32), UiKit.PANEL)
		UiKit.text(self, font, "SEASON END  ·  top 2 offered promotion", Vector2(30, y + 22), 13, UiKit.DIM)
		## The table beside it, to show the two read together.
		UiKit.panel(self, Rect2(676, 96, 260, 260))
		UiKit.text(self, font, "LEAGUE TABLE", Vector2(690, 120), 12, UiKit.DIM)
		var rows := s.table()
		for i in mini(6, rows.size()):
			var cid := int(rows[i]["club"])
			UiKit.text_fit(self, font, "%d  %s" % [i + 1, String(s.world.clubs[cid]["name"])],
				Vector2(690, 148 + i * 24), 13, UiKit.YOU if cid == s.world.player_club else UiKit.INK, 200.0)
		UiKit.para(self, font, "Cup ties never move these rows.", Vector2(690, 310), 12, UiKit.DIM, 232.0, 16.0, 2)
