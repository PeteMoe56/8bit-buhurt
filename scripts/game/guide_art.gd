class_name GuideArt
## THE GUIDE'S PICTURES (Pete, 10 Oct 2026: "make the guide actually show
## pictures and explanations", then "why can't it just be created the same as in
## game so it doesn't have to be a screenshot?").
##
## Each page draws a small, real-looking piece of the screen it explains, with
## example numbers, out of the same parts the game draws with (`UiKit.card`,
## `bar`, `meter`, `stars`, the wheel's own `FightCorner.draw_sides`). Every word
## goes through `UiKit.t`, so the picture is in the player's language.
##
## `draw` returns where each gold number goes, keyed by number, in screen space.

const W := 290.0
const H := 330.0


static func draw(ci: CanvasItem, font: Font, topic: int, at: Vector2) -> Dictionary:
	match topic:
		GuideScene.Topic.SEASON: return _season(ci, font, at)
		GuideScene.Topic.TABLE: return _table(ci, font, at)
		GuideScene.Topic.FIGHT: return _fight(ci, font, at)
		GuideScene.Topic.WHEEL: return _wheel(ci, font, at)
		GuideScene.Topic.TEAM: return _team(ci, font, at)
		GuideScene.Topic.TRAINING: return _training(ci, font, at)
		GuideScene.Topic.KIT: return _kit(ci, font, at)
		GuideScene.Topic.MONEY: return _money(ci, font, at)
		GuideScene.Topic.UPGRADES: return _upgrades(ci, font, at)
	return _coach(ci, font, at)


## THE LADDER: four divisions and the Worlds, you at the bottom.
static func _season(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var names := [UiKit.t("Worlds"), UiKit.t("National Division"), UiKit.t("Regional League"),
		UiKit.t("State League"), UiKit.t("Backyard Circuit")]
	var marks := {}
	var bw := W - 70.0
	for i in names.size():
		var y := at.y + 8.0 + float(i) * 62.0
		## A staircase climbing to the right: the Backyard at the bottom left.
		var x := at.x + float(names.size() - 1 - i) * 10.0
		var r := Rect2(x, y, bw, 46.0)
		UiKit.panel(ci, r)
		var col: Color = UiKit.YOU if i == 0 or i == names.size() - 1 else UiKit.INK
		if i == names.size() - 1:
			ci.draw_rect(r, UiKit.YOU, false, 2.0)
		UiKit.text_fit(ci, font, String(names[i]), r.position + Vector2(12, 29), 15, col, r.size.x - 50.0)
		if i == 0:
			UiKit.icon(ci, "trophy", Vector2(r.end.x - 30.0, r.position.y + 7.0), UiKit.YOU, 2)
		## The way up and the way down, to the right of every division below.
		if i > 0:
			_tri(ci, Vector2(r.end.x + 16.0, y + 14.0), true, UiKit.UP)
		if i > 0 and i < names.size() - 1:
			_tri(ci, Vector2(r.end.x + 16.0, y + 34.0), false, UiKit.DOWN)
		if i == names.size() - 1:
			marks[1] = r.position + Vector2(-2.0, 2.0)
		if i == 3:
			marks[2] = Vector2(r.end.x + 36.0, y + 12.0)
			marks[3] = Vector2(r.end.x + 36.0, y + 38.0)
		if i == 0:
			marks[4] = r.position + Vector2(-2.0, 2.0)
	return marks


static func _tri(ci: CanvasItem, c: Vector2, up: bool, col: Color) -> void:
	var s := 7.0
	var pts := PackedVector2Array([c + Vector2(-s, s * 0.6), c + Vector2(s, s * 0.6), c + Vector2(0, -s * 0.8)]) if up \
		else PackedVector2Array([c + Vector2(-s, -s * 0.6), c + Vector2(s, -s * 0.6), c + Vector2(0, s * 0.8)])
	ci.draw_colored_polygon(pts, col)


## THE TABLE: six clubs, the top four green and the bottom two red.
static func _table(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var rows := [
		["Detroit", 5, 4, 0, 1, 5, 9, 12],
		["Fresno", 5, 3, 1, 1, 3, 6, 10],
		["Atlanta", 5, 3, 0, 2, 2, 3, 9],
		["Tulsa", 5, 2, 1, 2, 0, -1, 7],
		["Omaha", 5, 1, 0, 4, -4, -7, 3],
		["Toledo", 5, 0, 0, 5, -6, -10, 0],
	]
	var cols := [118.0, 140.0, 162.0, 184.0, 214.0, 248.0, 284.0]
	var heads := [UiKit.t("P"), UiKit.t("W"), UiKit.t("D"), UiKit.t("L"), UiKit.t("RD"), UiKit.t("MG"), UiKit.t("PTS")]
	UiKit.panel(ci, Rect2(at, Vector2(W, 254.0)))
	for k in heads.size():
		UiKit.right(ci, font, String(heads[k]), Vector2(at.x + float(cols[k]), at.y + 28.0), 12,
			UiKit.YOU if k >= 4 else UiKit.DIM, 30.0)
	for i in rows.size():
		var y := at.y + 40.0 + float(i) * 34.0
		var strip: Color = UiKit.UP if i < 4 else UiKit.DOWN
		ci.draw_rect(Rect2(at.x + 8.0, y + 4.0, 5.0, 24.0), strip)
		var r: Array = rows[i]
		var ink: Color = UiKit.YOU if i == 0 else UiKit.INK
		UiKit.text_fit(ci, font, String(r[0]), Vector2(at.x + 20.0, y + 22.0), 13, ink, 78.0)
		for k in 7:
			var v: int = int(r[k + 1])
			var s := ("%+d" % v) if (k == 4 or k == 5) and v != 0 else "%d" % v
			UiKit.right(ci, font, s, Vector2(at.x + float(cols[k]), y + 22.0), 13, ink, 30.0)
	return {1: Vector2(at.x + float(cols[4]) - 10.0, at.y - 4.0), 2: Vector2(at.x + float(cols[5]) - 10.0, at.y - 4.0),
		3: Vector2(at.x + float(cols[6]) - 10.0, at.y - 4.0), 4: Vector2(at.x - 4.0, at.y + 58.0)}


## THE FIGHT: the clock and HOLD across the top, your side's panel, and a small
## field with one of theirs on the floor.
static func _fight(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	## HOLD and the clock.
	var hold := Rect2(at, Vector2(118.0, 36.0))
	UiKit.panel(ci, hold)
	UiKit.icon(ci, "pause", hold.position + Vector2(8, 10), UiKit.INK, 1)
	UiKit.text(ci, font, UiKit.t("HOLD"), hold.position + Vector2(28, 24), 14, UiKit.INK)
	for k in 2:
		ci.draw_rect(Rect2(hold.position.x + 84.0 + float(k) * 14.0, hold.position.y + 12.0, 10, 12), UiKit.YOU)
	UiKit.mid(ci, font, "R2  1:12", Vector2(at.x + 130.0, at.y + 28.0), 24, UiKit.INK, W - 130.0)
	## Your side: rounds, standing, downs.
	var side := Rect2(at.x, at.y + 52.0, 104.0, 270.0)
	UiKit.panel(ci, side)
	ci.draw_rect(Rect2(side.position.x, side.position.y, side.size.x, 4.0), UiKit.DOWN)
	UiKit.mid(ci, font, UiKit.t("ROUNDS"), side.position + Vector2(0, 30), 12, UiKit.DIM, side.size.x)
	for k in 2:
		var b := Rect2(side.position.x + 28.0 + float(k) * 26.0, side.position.y + 40.0, 20, 20)
		ci.draw_rect(b, UiKit.YOU if k == 0 else UiKit.TRACK)
		ci.draw_rect(b, UiKit.FRAME, false, 2.0)
	UiKit.mid(ci, font, UiKit.t("STANDING"), side.position + Vector2(0, 100), 12, UiKit.DIM, side.size.x)
	UiKit.mid(ci, font, "4", side.position + Vector2(0, 146), 40, UiKit.INK, side.size.x)
	UiKit.mid(ci, font, UiKit.t("of %d") % 5, side.position + Vector2(0, 168), 13, UiKit.DIM, side.size.x)
	UiKit.mid(ci, font, UiKit.t("DOWNS"), side.position + Vector2(0, 210), 12, UiKit.DIM, side.size.x)
	UiKit.mid(ci, font, "2", side.position + Vector2(0, 244), 26, UiKit.INK, side.size.x)
	## The field: five of yours, five of theirs, one of theirs down.
	var f := Rect2(at.x + 116.0, at.y + 52.0, W - 116.0, 270.0)
	ci.draw_rect(f, Color("4a4232"))
	ci.draw_rect(f, UiKit.FRAME, false, 2.0)
	var downed := Vector2.ZERO
	for k in 5:
		var y := f.position.y + 30.0 + float(k) * 50.0
		ci.draw_circle(Vector2(f.position.x + 44.0 + (24.0 if k == 2 else 0.0), y), 9.0, UiKit.DOWN)
		var them := Vector2(f.end.x - 40.0 - (30.0 if k == 1 else 0.0), y)
		if k == 3:
			## Down: on his back, greyed, a cross over him.
			ci.draw_rect(Rect2(them + Vector2(-14, -5), Vector2(28, 10)), UiKit.DIM)
			ci.draw_line(them + Vector2(-8, -8), them + Vector2(8, 8), UiKit.BG, 3.0)
			ci.draw_line(them + Vector2(8, -8), them + Vector2(-8, 8), UiKit.BG, 3.0)
			downed = them
		else:
			ci.draw_circle(them, 9.0, UiKit.YOU)
	return {1: Vector2(at.x + W + 2.0, at.y + 4.0), 2: Vector2(at.x - 4.0, at.y - 4.0),
		3: side.position + Vector2(-4.0, 94.0), 4: side.position + Vector2(-4.0, 24.0),
		5: downed + Vector2(-26.0, -18.0)}


## THE WHEEL, drawn by the fight's own code: a man sent at a free enemy.
static func _wheel(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var c := at + Vector2(W + 20.0, FightCorner.RO + 14.0)
	var rows := [
		{"act": Tuning.Act.BULLRUSH, "p": 0.05, "fall": 0.23, "sub": "", "sub_col": UiKit.INK, "inner": ""},
		{"act": Tuning.Act.GRAPPLE, "p": 1.0, "fall": -1.0, "sub": UiKit.t("takedown %d%%") % 14,
			"sub_col": UiKit.INK, "inner": ""},
		{"act": Tuning.Act.HIT, "p": 1.0, "fall": -1.0, "sub": UiKit.t("-%d%% balance") % 9,
			"sub_col": UiKit.INK, "inner": ""},
	]
	FightCorner.draw_sides(ci, c, rows, true, UiKit.SELECT, FightCorner.DIM, false, -99, -99)
	ci.draw_colored_polygon(FightCorner._ring(c, 0.0, FightCorner.RI - 6.0, 270.0, 360.0), UiKit.BG)
	UiKit.mid(ci, font, UiKit.t("Cancel"), Vector2(c.x - 106.0, c.y - 34.0), 15, UiKit.INK, 100.0)
	return {1: FightCorner._pt(c, FightCorner.RO + 18.0, 280.0), 2: FightCorner._pt(c, FightCorner.RI - 18.0, 302.0),
		3: FightCorner._pt(c, FightCorner.RO + 18.0, 352.0), 4: FightCorner._pt(c, FightCorner.RI - 30.0, 335.0)}


## A FIGHTER: his card, his four stats with room to grow, his XP and his deal.
static func _team(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var top := Rect2(at, Vector2(W, 64.0))
	UiKit.panel(ci, top)
	UiKit.text(ci, font, "Calder", top.position + Vector2(12, 26), 17, UiKit.INK)
	UiKit.text(ci, font, UiKit.t("Rail"), top.position + Vector2(12, 48), 13, UiKit.DIM)
	_boxed(ci, font, Rect2(top.end.x - 128.0, top.position.y + 10.0, 54.0, 44.0), UiKit.t("OVR"), "52", UiKit.INK)
	_boxed(ci, font, Rect2(top.end.x - 66.0, top.position.y + 10.0, 54.0, 44.0), UiKit.t("POT"), "68", UiKit.UP)
	var stats := [[UiKit.t("Strength"), 60, 77], [UiKit.t("Base"), 59, 72], [UiKit.t("Skill"), 46, 63], [UiKit.t("Gas"), 47, 64]]
	var box := Rect2(at.x, at.y + 76.0, W, 152.0)
	UiKit.panel(ci, box)
	for k in stats.size():
		var y := box.position.y + 14.0 + float(k) * 34.0
		var s: Array = stats[k]
		UiKit.text_fit(ci, font, String(s[0]), Vector2(box.position.x + 12.0, y + 16.0), 13, UiKit.INK, 84.0)
		var br := Rect2(box.position.x + 100.0, y + 3.0, box.size.x - 150.0, 16.0)
		UiKit.bar(ci, br, float(s[1]) / 99.0, UiKit.YOU)
		## The green room to grow, to his ceiling in this stat.
		var x0 := br.position.x + 3.0 + (br.size.x - 6.0) * float(s[1]) / 99.0
		var x1 := br.position.x + 3.0 + (br.size.x - 6.0) * float(s[2]) / 99.0
		ci.draw_rect(Rect2(x0, br.position.y + 3.0, x1 - x0, br.size.y - 6.0), Color(UiKit.UP, 0.45))
		UiKit.right(ci, font, "%d" % int(s[1]), Vector2(box.end.x - 10.0, y + 16.0), 13, UiKit.INK, 36.0)
	var xp := Rect2(at.x, at.y + 240.0, W, 40.0)
	UiKit.panel(ci, xp)
	UiKit.text(ci, font, UiKit.t("XP"), xp.position + Vector2(12, 26), 13, UiKit.DIM)
	UiKit.bar(ci, Rect2(xp.position.x + 44.0, xp.position.y + 12.0, xp.size.x - 56.0, 16.0), 0.65, UiKit.SELECT.lightened(0.3))
	var deal := Rect2(at.x, at.y + 292.0, W, 36.0)
	UiKit.panel(ci, deal)
	UiKit.text(ci, font, UiKit.t("DEAL"), deal.position + Vector2(12, 23), 12, UiKit.DIM)
	UiKit.right(ci, font, UiKit.t("%s/yr · %dy") % ["$30", 2], Vector2(deal.end.x - 12.0, deal.position.y + 23.0), 14, UiKit.INK, 160.0)
	return {1: Vector2(top.end.x - 132.0, top.position.y + 4.0), 2: Vector2(box.position.x - 4.0, box.position.y + 2.0),
		3: Vector2(xp.position.x - 4.0, xp.position.y + 2.0), 4: Vector2(deal.position.x - 4.0, deal.position.y + 2.0)}


static func _boxed(ci: CanvasItem, font: Font, r: Rect2, label: String, value: String, col: Color) -> void:
	ci.draw_rect(r, UiKit.TRACK)
	ci.draw_rect(r, UiKit.FRAME, false, 2.0)
	UiKit.mid(ci, font, label, r.position + Vector2(0, 15), 12, UiKit.DIM, r.size.x)
	UiKit.mid(ci, font, value, r.position + Vector2(0, 38), 20, col, r.size.x)


## TRAINING: two captains, the role nobody teaches, and how hard you train.
static func _training(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var cw := (W - 12.0) * 0.5
	UiKit.card(ci, font, Rect2(at, Vector2(cw, 104.0)),
		{"tag": UiKit.t("Rail") + " + " + UiKit.t("Center"), "name": "Vaughn", "rating": 80, "band": UiKit.SELECT}, true)
	UiKit.card(ci, font, Rect2(at + Vector2(cw + 12.0, 0), Vector2(cw, 104.0)),
		{"tag": UiKit.t("Center"), "name": "Pike", "rating": 60, "band": UiKit.SELECT}, true)
	var roles := Rect2(at.x, at.y + 116.0, W, 82.0)
	UiKit.panel(ci, roles)
	var names := [UiKit.t("Rail"), UiKit.t("Flanker"), UiKit.t("Center")]
	for k in 3:
		var y := roles.position.y + 24.0 + float(k) * 22.0
		var taught := k != 1
		var col: Color = UiKit.INK if taught else UiKit.DOWN
		UiKit.text_fit(ci, font, String(names[k]), Vector2(roles.position.x + 12.0, y), 14, col, 96.0)
		UiKit.text_fit(ci, font, UiKit.t("Normal") if taught else UiKit.t("nobody teaches it"),
			Vector2(roles.position.x + 112.0, y), 13, UiKit.DIM if taught else UiKit.DOWN, W - 124.0)
	var load := Rect2(at.x, at.y + 210.0, W, 56.0)
	UiKit.panel(ci, load)
	var loads := [UiKit.t("Light"), UiKit.t("Normal"), UiKit.t("Hard")]
	var bw := (W - 32.0) / 3.0
	for k in 3:
		var b := Rect2(load.position.x + 8.0 + float(k) * (bw + 8.0), load.position.y + 10.0, bw, 36.0)
		ci.draw_rect(b, UiKit.YOU if k == 1 else UiKit.SELECT)
		ci.draw_rect(b, UiKit.FRAME, false, 2.0)
		UiKit.mid(ci, font, String(loads[k]), b.position + Vector2(0, 24), 14, UiKit.BG if k == 1 else UiKit.INK, b.size.x)
	var sess := Rect2(at.x, at.y + 278.0, W, 46.0)
	UiKit.panel(ci, sess)
	UiKit.text_fit(ci, font, UiKit.t("Session"), sess.position + Vector2(12, 29), 15, UiKit.INK, W - 110.0)
	UiKit.right(ci, font, UiKit.t("%d CC") % 4, Vector2(sess.end.x - 12.0, sess.position.y + 29.0), 14, UiKit.YOU, 80.0)
	return {1: at + Vector2(-4.0, -4.0), 2: Vector2(roles.position.x - 4.0, roles.position.y + 46.0),
		3: Vector2(load.position.x - 4.0, load.position.y + 2.0), 4: Vector2(sess.position.x - 4.0, sess.position.y + 2.0)}


## KIT: your armorer, and four harnesses against the pass mark.
static func _kit(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var arm := Rect2(at, Vector2(W, 64.0))
	UiKit.panel(ci, arm)
	UiKit.text(ci, font, UiKit.t("ARMORER"), arm.position + Vector2(12, 24), 12, UiKit.DIM)
	UiKit.text(ci, font, "Hal Brenner", arm.position + Vector2(12, 48), 16, UiKit.INK)
	UiKit.stars(ci, Vector2(arm.end.x - 96.0, arm.position.y + 36.0), 80, UiKit.YOU, 11.0, 3.0)
	var men := [["Calder", UiKit.t("Stainless"), 0.84], ["Wren", UiKit.t("Hardened"), 0.62],
		["Nolan", UiKit.t("Mild"), 0.48], ["Merrick", UiKit.t("Rust"), 0.22]]
	var box := Rect2(at.x, at.y + 76.0, W, 244.0)
	UiKit.panel(ci, box)
	var pass_f := 0.35
	var bx := box.position.x + 122.0
	var bw := box.size.x - 134.0
	for k in men.size():
		var m: Array = men[k]
		var y := box.position.y + 16.0 + float(k) * 56.0
		var bad: bool = float(m[2]) < pass_f
		UiKit.text(ci, font, String(m[0]), Vector2(box.position.x + 12.0, y + 16.0), 14, UiKit.DOWN if bad else UiKit.INK)
		UiKit.text_fit(ci, font, String(m[1]), Vector2(box.position.x + 12.0, y + 36.0), 12, UiKit.DIM, 106.0)
		UiKit.bar(ci, Rect2(bx, y + 6.0, bw, 18.0), float(m[2]), UiKit.DOWN if bad else UiKit.UP)
		## The pass mark: a white tick across the bar.
		var tx := bx + 3.0 + (bw - 6.0) * pass_f
		ci.draw_rect(Rect2(tx - 1.0, y + 2.0, 3.0, 26.0), UiKit.INK)
	return {1: Vector2(arm.end.x - 104.0, arm.position.y + 4.0), 2: Vector2(box.position.x - 4.0, box.position.y + 46.0),
		3: Vector2(bx + bw - 14.0, box.position.y + 6.0), 4: Vector2(bx + (bw - 6.0) * pass_f - 10.0, box.position.y + 196.0)}


## MONEY: the year so far in CC, and wages under the cap in $.
static func _money(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var fin := Rect2(at, Vector2(W, 176.0))
	UiKit.panel(ci, fin)
	var lines := [[UiKit.t("In"), "48 CC", UiKit.UP], [UiKit.t("Out"), "39 CC", UiKit.DOWN], [UiKit.t("Total"), "+9 CC", UiKit.YOU]]
	for k in lines.size():
		var l: Array = lines[k]
		var y := fin.position.y + 40.0 + float(k) * 48.0
		if k == 2:
			ci.draw_rect(Rect2(fin.position.x + 12.0, y - 30.0, W - 24.0, 2.0), UiKit.FRAME)
		UiKit.text(ci, font, String(l[0]), Vector2(fin.position.x + 16.0, y), 18, UiKit.INK)
		UiKit.right(ci, font, String(l[1]), Vector2(fin.end.x - 16.0, y), 20, Color(l[2]), 140.0)
	var cap := Rect2(at.x, at.y + 192.0, W, 90.0)
	UiKit.panel(ci, cap)
	UiKit.text(ci, font, UiKit.t("SALARY CAP"), cap.position + Vector2(12, 26), 12, UiKit.DIM)
	UiKit.right(ci, font, "$150 / $250", Vector2(cap.end.x - 12.0, cap.position.y + 26.0), 14, UiKit.INK, 160.0)
	UiKit.bar(ci, Rect2(cap.position.x + 12.0, cap.position.y + 44.0, W - 24.0, 22.0), 0.6, UiKit.YOU)
	return {1: Vector2(fin.position.x - 4.0, fin.position.y + 22.0), 2: Vector2(fin.position.x - 4.0, fin.position.y + 70.0),
		3: Vector2(fin.position.x - 4.0, fin.position.y + 118.0), 4: Vector2(cap.position.x - 4.0, cap.position.y + 2.0)}


## UPGRADES: four buildings and their levels.
static func _upgrades(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var rows := [[UiKit.t("Back field"), 1, 5], [UiKit.t("Training ground"), 2, 5], [UiKit.t("Infirmary"), 0, 5],
		[UiKit.t("Insurance"), 1, 3]]
	var marks := {}
	for k in rows.size():
		var r: Array = rows[k]
		var box := Rect2(at.x, at.y + float(k) * 82.0, W, 70.0)
		UiKit.panel(ci, box)
		UiKit.text_fit(ci, font, String(r[0]), box.position + Vector2(12, 24), 15, UiKit.INK, W - 24.0)
		UiKit.meter(ci, Rect2(box.position.x + 12.0, box.position.y + 36.0, (W - 24.0) * float(r[2]) / 5.0, 22.0),
			int(r[1]), int(r[2]), UiKit.YOU)
		marks[k + 1] = Vector2(box.position.x - 4.0, box.position.y + 2.0)
	return marks


## YOUR COACH: his XP, his five skills and the points to spend.
static func _coach(ci: CanvasItem, font: Font, at: Vector2) -> Dictionary:
	var xp := Rect2(at, Vector2(W, 52.0))
	UiKit.panel(ci, xp)
	UiKit.text(ci, font, UiKit.t("XP"), xp.position + Vector2(12, 32), 13, UiKit.DIM)
	UiKit.bar(ci, Rect2(xp.position.x + 44.0, xp.position.y + 17.0, W - 56.0, 18.0), 0.4, UiKit.SELECT.lightened(0.3))
	var names := [UiKit.t("Training"), UiKit.t("Motivation"), UiKit.t("Tactics"), UiKit.t("Business"), UiKit.t("Recruiting")]
	var ratings := [40, 20, 0, 20, 0]
	var box := Rect2(at.x, at.y + 64.0, W, 214.0)
	UiKit.panel(ci, box)
	var marks := {1: Vector2(xp.position.x - 4.0, xp.position.y + 2.0)}
	for k in names.size():
		var y := box.position.y + 12.0 + float(k) * 40.0
		UiKit.text_fit(ci, font, String(names[k]), Vector2(box.position.x + 14.0, y + 22.0), 14, UiKit.INK, 110.0)
		UiKit.stars(ci, Vector2(box.position.x + 132.0, y + 8.0), int(ratings[k]), UiKit.YOU, 11.0, 3.0)
		var plus := Rect2(box.end.x - 40.0, y + 2.0, 28.0, 28.0)
		ci.draw_rect(plus, UiKit.SELECT)
		ci.draw_rect(plus, UiKit.FRAME, false, 2.0)
		UiKit.mid(ci, font, "+", plus.position + Vector2(0, 21), 18, UiKit.INK, plus.size.x)
		marks[k + 2] = Vector2(box.position.x - 4.0, y + 4.0)
	var pts := Rect2(at.x, at.y + 290.0, W, 40.0)
	UiKit.panel(ci, pts)
	UiKit.mid(ci, font, UiKit.t("%d points to spend") % 2, pts.position + Vector2(0, 26), 15, UiKit.YOU, W)
	return marks
