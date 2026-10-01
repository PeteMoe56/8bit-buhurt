extends Node2D
## THE CALENDAR. Pete, 30 Sep 2026, playtest 2 #14: *"Standings are confusing
## when you're fighting tournament cups… mock up a calendar system and show the
## cups, regular matches, and playoffs."* Then, on the mock: *"How does a full
## 30 day calendar look with this?"* — and he picked the month grid.
##
## A real month: the season opens on the first Saturday of March, and every
## Saturday is one thing — a league day, a cup round, your own show, a playoff
## or Worlds round — or nothing for you. Weekdays are training. The side list is
## the whole year, a row a week, so a month never hides where it sits.

static func w() -> float:
	return UiKit.screen().x
static func h() -> float:
	return UiKit.screen().y

const SIDE_W := 220.0
const GRID_TOP := 96.0
const GAP := 4.0

var font: Font
var ui: CanvasLayer
var s: Season
## The month on screen, as {year, month}.
var year: int = 0
var month: int = 0
var first: Dictionary = {}
var last: Dictionary = {}
## THE DAY TAPPED (Pete, 1 Oct: "have those days clickable with a popup of
## information"): the week it belongs to, or -1 with nothing open.
var pick: int = -1


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	s = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	if s != null:
		var sea := s.world.season
		first = Calendar.date_of(sea, 0)
		last = Calendar.date_of(sea, maxi(0, s.world.weeks_this_season() - 1))
		var now := Calendar.date_of(sea, mini(s.world.week, maxi(0, s.world.weeks_this_season() - 1)))
		year = int(now["year"])
		month = int(now["month"])
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(24, h() - 56), Vector2(150, 44),
		func(): UiKit.back("res://scenes/Season.tscn")))
	if s == null:
		return
	if pick >= 0:
		## THE POPUP OWNS THE SCREEN while it is open, like the shop and the sim
		## confirm: a scrim cannot cover a Button.
		ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Close"),
			Vector2(_pop().position.x + _pop().size.x - 174.0, _pop().end.y - 60.0), Vector2(150, 44), func():
				pick = -1
				_build(), "close")))
		var c := _pick_cup()
		if c != null:
			ui.add_child(UiKit.button(UiKit.t("Cup bracket"),
				Vector2(_pop().position.x + 24.0, _pop().end.y - 60.0), Vector2(200, 44), func():
					Session.viewing_cup = c
					UiKit.go("res://scenes/Bracket.tscn"), "trophy"))
		queue_redraw()
		return
	## EVERY DAY WITH SOMETHING ON IT IS A BUTTON, over its own cell.
	var g := _geom()
	for d in int(g["n"]):
		var wi := _week_of_day(year, month, d + 1)
		if wi < 0:
			continue
		var hit := UiKit.button("", _cell_rect(g, d).position, _cell_rect(g, d).size, func():
			pick = wi
			_build())
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		ui.add_child(hit)
	## A MONTH EITHER SIDE, within the season.
	var gx := _grid_right() - 2.0 * 48.0 - 8.0
	if _month_key(year, month) > _month_key(int(first["year"]), int(first["month"])):
		ui.add_child(UiKit.arrow(false, Vector2(gx, 24), Vector2(48, 40), func(): _step(-1)))
	if _month_key(year, month) < _month_key(int(last["year"]), int(last["month"])):
		ui.add_child(UiKit.arrow(true, Vector2(gx + 56.0, 24), Vector2(48, 40), func(): _step(1)))
	queue_redraw()


func _relayout() -> void:
	_build()


func _step(d: int) -> void:
	month += d
	if month < 1:
		month = 12
		year -= 1
	elif month > 12:
		month = 1
		year += 1
	_build()


static func _month_key(y: int, m: int) -> int:
	return y * 12 + m


func _grid_right() -> float:
	return w() - 24.0 - SIDE_W - 12.0


func _in_season(y: int, m: int, d: int) -> bool:
	var k := y * 10000 + m * 100 + d
	var a := int(first["year"]) * 10000 + int(first["month"]) * 100 + int(first["day"]) - 5
	var b := int(last["year"]) * 10000 + int(last["month"]) * 100 + int(last["day"])
	return k >= a and k <= b


func _draw() -> void:
	UiKit.set_mood(s.mood() if s != null else UiKit.Mood.NORMAL)
	UiKit.ground(self)
	if s == null:
		return
	UiKit.text(self, font, Calendar.month_name(month).to_upper(), Vector2(24, 40), 22, UiKit.YOU)
	UiKit.text_fit(self, font, UiKit.t("%s  ·  Season %d") % [s.tier_name(), s.world.season],
		Vector2(24, 64), 14, UiKit.DIM, _grid_right() - 24.0 - 120.0)
	## THE RULE, beside Back where there is a line's room for it.
	UiKit.text_fit(self, font, UiKit.t("League on Saturdays. Cups Friday to Sunday, the Worlds all week."),
		Vector2(190, h() - 28), 13, UiKit.DIM, w() - 190.0 - 24.0)
	_grid()
	_side()
	if pick >= 0:
		_popup()


## THE GRID'S MEASUREMENTS, read by the drawing and the buttons alike.
func _geom() -> Dictionary:
	var gx := 24.0
	var gw := _grid_right() - gx
	var cw := (gw - 6.0 * GAP) / 7.0
	var lead := Calendar.first_weekday(year, month)
	var n := Calendar.days_in(year, month)
	var rows := int(ceil(float(lead + n) / 7.0))
	var ch := (h() - 70.0 - (GRID_TOP + 20.0) - float(rows - 1) * GAP) / float(rows)
	return {"gx": gx, "cw": cw, "ch": ch, "lead": lead, "n": n}


func _cell_rect(g: Dictionary, d: int) -> Rect2:
	var cell := d + int(g["lead"])
	var cw := float(g["cw"])
	var ch := float(g["ch"])
	return Rect2(float(g["gx"]) + float(cell % 7) * (cw + GAP), GRID_TOP + 20.0 + float(cell / 7) * (ch + GAP), cw, ch)


static func _key(dt: Dictionary) -> String:
	return "%d-%d-%d" % [int(dt["year"]), int(dt["month"]), int(dt["day"])]


## EVERY DAY THAT BELONGS TO A WEEK'S THING: its Saturday, a tournament's other
## days (a cup or your show Friday to Sunday, the Worlds Monday to Sunday), the
## send-off's Monday and Wednesday. date -> [week, label, color, is_saturday].
func _days_map() -> Dictionary:
	var out := {}
	var days := s.world.events_this_season()
	for i in s.world.weeks_this_season():
		var wk: Dictionary = s.world.calendar[i]
		var k := int(wk["kind"])
		out[_key(Calendar.date_of(s.world.season, i))] = [i, _short(wk, days), _color_of(wk), true]
		if _send_off_week(wk):
			var labels := [UiKit.t("CELEBRATION"), UiKit.t("NATIONAL CAMP")]
			for j in 2:
				out[_key(Calendar.date_of(s.world.season, i, int(SendOff.DAY_SHIFT[j])))] = [i, labels[j], SEND_OFF_COLOR, false]
			continue
		if not Calendar.is_tournament(k):
			continue
		var from := -5 if k == Calendar.Kind.WORLDS else -1
		for sh in range(from, 2):
			if sh != 0:
				out[_key(Calendar.date_of(s.world.season, i, sh))] = [i, _short(wk, days), Calendar.color(k), false]
	return out


func _week_of_day(y: int, m: int, d: int) -> int:
	var mp := _days_map()
	var k := "%d-%d-%d" % [y, m, d]
	return int(mp[k][0]) if mp.has(k) else -1


func _color_of(wk: Dictionary) -> Color:
	return SEND_OFF_COLOR if _send_off_week(wk) else Calendar.color(int(wk["kind"]))


func _grid() -> void:
	var g := _geom()
	var cw := float(g["cw"])
	var ch := float(g["ch"])
	for i in 7:
		UiKit.mid(self, font, Calendar.weekday_name(i), Vector2(float(g["gx"]) + float(i) * (cw + GAP), GRID_TOP + 10.0),
			12, UiKit.YOU if i == Calendar.SATURDAY_COL else UiKit.DIM, cw)
	var mp := _days_map()
	for d in int(g["n"]):
		var r := _cell_rect(g, d)
		var col := (d + int(g["lead"])) % 7
		draw_rect(r, UiKit.PANEL)
		UiKit.text(self, font, "%d" % (d + 1), r.position + Vector2(5, 15), 12, UiKit.DIM)
		if _in_season(year, month, d + 1) and col != Calendar.SUNDAY_COL and col != Calendar.SATURDAY_COL:
			## A weekday in season: training, the background hum.
			draw_rect(Rect2(r.position + Vector2(5, ch - 9), Vector2(cw - 10, 3)), UiKit.UP.darkened(0.4))
		var key := "%d-%d-%d" % [year, month, d + 1]
		if not mp.has(key):
			continue
		var e: Array = mp[key]
		var wi := int(e[0])
		var c: Color = e[2]
		var past: bool = wi < s.world.week
		var block := Rect2(r.position + Vector2(2, 20), Vector2(cw - 4, ch - 23))
		if not bool(e[3]):
			draw_rect(block, c.darkened(0.65 if past else 0.45))
			UiKit.text(self, font, UiKit.clip_px(font, String(e[1]), 11, cw - 10.0),
				r.position + Vector2(6, 33), 11, c.lightened(0.35))
			if wi == s.world.week:
				draw_rect(r, UiKit.YOU, false, 2.0)
			continue
		var wk: Dictionary = s.world.calendar[wi]
		draw_rect(block, c.darkened(0.55 if past else 0.3))
		var b := _detail(wi, wk)
		UiKit.text(self, font, UiKit.clip_px(font, String(e[1]), 11, cw - 10.0), block.position + Vector2(4, 13), 11,
			c.lightened(0.55))
		UiKit.text(self, font, UiKit.clip_px(font, String(b[0]), 12, cw - 10.0), block.position + Vector2(4, 28), 12,
			b[1])
		if wi == s.world.week:
			draw_rect(r, UiKit.YOU, false, 3.0)


## THE CELL'S FIRST LINE: what the Saturday is, short enough for a cell.
func _short(wk: Dictionary, days: int) -> String:
	if _send_off_week(wk):
		return UiKit.t("THE TABARD")
	return Calendar.short_label(wk, days).to_upper()


const SEND_OFF_COLOR := Color("c9a227")


## The bye before the Worlds, for a club that won the National playoff.
func _send_off_week(wk: Dictionary) -> bool:
	return int(wk["kind"]) == Calendar.Kind.BYE and String(wk.get("before", "")) == "worlds" \
		and s.world.player_tier() == League.Tier.NATIONAL and s.world.player_champion() \
		and not s.world.finalists.is_empty()


## THE CELL'S SECOND LINE and its color: the opponent, or the result once it is
## played; for a cup, whether you are in it.
func _detail(wi: int, wk: Dictionary) -> Array:
	var kind := int(wk["kind"])
	if kind == Calendar.Kind.LEAGUE:
		var d := int(wk["day"])
		if wi < s.world.week and d < s.results.size():
			var e: Dictionary = s.results[d]
			if bool(e.get("bye", false)):
				return [UiKit.t("bye"), UiKit.DIM]
			var rf := int(e["rf"])
			var ra := int(e["ra"])
			var word := UiKit.t("W") if rf > ra else (UiKit.t("D") if rf == ra else UiKit.t("L"))
			return [UiKit.t("%s %d-%d") % [word, rf, ra], UiKit.UP if rf > ra else (UiKit.DIM if rf == ra else UiKit.DOWN)]
		var opp := -1
		var home := false
		var days: Array = s.world.schedule[s.world.player_tier()]
		if d < days.size():
			for pair in days[d]:
				if int(pair[0]) == s.world.player_club or int(pair[1]) == s.world.player_club:
					opp = int(pair[1]) if int(pair[0]) == s.world.player_club else int(pair[0])
					home = League.host_of(pair) == s.world.player_club
		if opp < 0:
			return [UiKit.t("bye"), UiKit.DIM]
		return [(UiKit.t("v %s") if home else UiKit.t("at %s")) % String(s.world.clubs[opp].get("short", "?")),
			UiKit.INK]
	if kind == Calendar.Kind.OWN:
		return [UiKit.t("you host"), UiKit.INK]
	if kind == Calendar.Kind.BYE:
		return [s.world.team_title if _send_off_week(wk) and s.world.team_title != "" else UiKit.t("rest"),
			UiKit.YOU if _send_off_week(wk) else UiKit.DIM]
	var c: Cup = s.world.cup_of_week(wk)
	if c == null and wi < s.world.week:
		## OVER: how far you got, from the cabinet.
		var h := _honor_of(wi, wk)
		if not h.is_empty():
			var f := String(h.get("player", ""))
			if f == "":
				return [UiKit.t("not in it"), UiKit.DIM]
			return [_finish_short(f), UiKit.UP if int(h.get("champion", -1)) == s.world.player_club else UiKit.INK]
		return [UiKit.t("done"), UiKit.DIM]
	if c == null:
		return ["", UiKit.DIM]
	return [UiKit.t("in it") if c.player_alive() else UiKit.t("not in it"),
		UiKit.UP if c.player_alive() else UiKit.DIM]


## HOW FAR YOU GOT, in a cell's width.
static func _finish_short(f: String) -> String:
	var low := f.to_lower()
	match low:
		"champions": return UiKit.t("Won it")
		"runners-up": return UiKit.t("Lost final")
		"third", "fourth": return Cup.finish_words(f)
		"out in the final": return UiKit.t("Lost final")
		"out in the semi-finals": return UiKit.t("Out: %s") % Calendar.knockout_short(2)
		"out in the quarter-finals": return UiKit.t("Out: %s") % Calendar.knockout_short(3)
		"out in the pools": return UiKit.t("Out: pools")
	return UiKit.t("Out early")


## THE YEAR DOWN THE SIDE, a row a week, scrolled so this week is in view.
func _side() -> void:
	var sx := _grid_right() + 12.0
	var top := GRID_TOP
	var r := Rect2(sx, top, SIDE_W, h() - 70.0 - top)
	UiKit.panel(self, r)
	UiKit.text(self, font, UiKit.t("THE SEASON"), Vector2(sx + 12, top + 22), 12, UiKit.DIM)
	var row_h := 21.0
	var fit := int((r.size.y - 40.0) / row_h)
	var n := s.world.weeks_this_season()
	var start := clampi(s.world.week - fit / 3, 0, maxi(0, n - fit))
	var days := s.world.events_this_season()
	for k in mini(fit, n - start):
		var i := start + k
		var wk: Dictionary = s.world.calendar[i]
		var y := top + 44.0 + float(k) * row_h
		draw_rect(Rect2(sx + 12, y - 10, 10, 11), Calendar.color(int(wk["kind"])))
		var col := UiKit.YOU if i == s.world.week else (UiKit.DIM if i < s.world.week else UiKit.INK)
		UiKit.text(self, font, UiKit.clip_px(font, UiKit.t("%d.  %s") % [i + 1, Calendar.short_label(wk, days)], 12,
			SIDE_W - 40.0), Vector2(sx + 28, y), 12, col)



# ------------------------------------------------------------------- popup
## Centered on whatever canvas this is.
static func _pop() -> Rect2:
	var sz := Vector2(minf(740.0, w() - 48.0), minf(400.0, h() - 60.0))
	return Rect2((UiKit.screen() - sz) * 0.5 + Vector2(0, 10), sz)


## The cup the picked week is about, if it has a bracket to look at.
func _pick_cup() -> Cup:
	if pick < 0:
		return null
	var wk: Dictionary = s.world.calendar[pick]
	if int(wk["kind"]) == Calendar.Kind.OWN:
		return s.booked.cup if s.booked != null else null
	return s.world.cup_of_week(wk)


## WHAT A WEEK IS, IN FULL: [title, sub, lines], each line [text, color].
## A fixture: who, where, how they stand. A tournament: where, who is in it,
## what it pays, how you stand in it.
func _info(wi: int) -> Array:
	var wk: Dictionary = s.world.calendar[wi]
	var kind := int(wk["kind"])
	var days := s.world.events_this_season()
	var dt := Calendar.date_of(s.world.season, wi)
	var when := UiKit.t("%s %d") % [Calendar.month_name(int(dt["month"])), int(dt["day"])]
	var lines: Array = []
	var title := Calendar.label(wk, days, UiKit.t("Your show"))
	var sub := UiKit.t("Week %d  ·  Saturday %s") % [wi + 1, when]
	match kind:
		Calendar.Kind.LEAGUE:
			_league_info(wi, wk, lines)
		Calendar.Kind.BYE:
			if _send_off_week(wk):
				title = UiKit.t("THE SEND-OFF")
				lines.append([UiKit.t("National champions only. Three days before the Worlds:"), UiKit.INK])
				lines.append([UiKit.t("Monday: the club celebrates. Renown and team morale up."), UiKit.DIM])
				lines.append([UiKit.t("Wednesday: the national camp. Two weeks of training in three days."), UiKit.DIM])
				lines.append([UiKit.t("Saturday: the tabard. You go to the Worlds as %s.") % SendOff.team_name(s), UiKit.YOU])
			else:
				lines.append([UiKit.t("No fixture. The squad trains, and knocks get a week to heal."), UiKit.DIM])
		_:
			_tournament_info(wi, wk, lines)
			if kind == Calendar.Kind.WORLDS:
				sub = UiKit.t("Week %d  ·  Monday to Sunday, ending %s") % [wi + 1, when]
			else:
				sub = UiKit.t("Week %d  ·  Friday to Sunday, ending %s") % [wi + 1, when]
	return [title, sub, lines]


func _league_info(wi: int, wk: Dictionary, lines: Array) -> void:
	var d := int(wk["day"])
	var opp := -1
	var home := false
	var sched: Array = s.world.schedule[s.world.player_tier()]
	if d < sched.size():
		for pair in sched[d]:
			if int(pair[0]) == s.world.player_club or int(pair[1]) == s.world.player_club:
				opp = int(pair[1]) if int(pair[0]) == s.world.player_club else int(pair[0])
				home = League.host_of(pair) == s.world.player_club
	if opp < 0:
		lines.append([UiKit.t("A bye: nobody to fight this week."), UiKit.DIM])
		return
	var o: Dictionary = s.world.clubs[opp]
	lines.append([String(o["name"]), UiKit.YOU])
	var host := s.world.player_club if home else opp
	var gr: Dictionary = s.ground_of(host)
	lines.append([UiKit.t("%s  ·  %s  ·  %s") % [UiKit.t("Home") if home else UiKit.t("Away"),
		Arena.arena_name_of(int(gr["level"])), Cities.full_name(s.world.city_of(host))], UiKit.INK])
	var pos := -1
	var rows := s.table()
	for i in rows.size():
		if int(rows[i]["club"]) == opp:
			pos = i + 1
	var r := s.world.record_of(opp)
	lines.append([UiKit.t("Rating %d  ·  %s in the table  ·  won %d, drew %d, lost %d") % [int(o["power"]),
		UiKit.ordinal(pos), int(r["won"]), int(r["drawn"]), int(r["lost"])], UiKit.DIM])
	var me := s.world.record_of(s.world.player_club)
	lines.append([UiKit.t("You: %s in the table  ·  won %d, drew %d, lost %d") % [UiKit.ordinal(s.position()),
		int(me["won"]), int(me["drawn"]), int(me["lost"])], UiKit.DIM])
	if wi < s.world.week and d < s.results.size():
		var e: Dictionary = s.results[d]
		if not bool(e.get("bye", false)):
			var rf := int(e["rf"])
			var ra := int(e["ra"])
			lines.append([UiKit.t("Result: %d-%d") % [rf, ra], UiKit.UP if rf > ra else (UiKit.DIM if rf == ra else UiKit.DOWN)])
	else:
		lines.append([UiKit.t("%d CC at the gate") % s.gate_for_fixture(opp, home), UiKit.DIM])


func _tournament_info(wi: int, wk: Dictionary, lines: Array) -> void:
	var kind := int(wk["kind"])
	var c: Cup = null
	if kind == Calendar.Kind.OWN:
		c = s.booked.cup if s.booked != null else null
	else:
		c = s.world.cup_of_week(wk)
	## WHERE.
	var city := ""
	match kind:
		Calendar.Kind.CUP:
			city = String(wk.get("city", ""))
		Calendar.Kind.OWN:
			city = s.world.city_of(s.world.player_club)
	if city != "":
		lines.append([UiKit.t("In %s") % Cities.full_name(city), UiKit.INK])
	## WHO IS ASKED.
	match kind:
		Calendar.Kind.CUP:
			var tiers: Array = LeagueWorld.INVITATIONAL_SETS[LeagueWorld.set_of_tier(s.world.player_tier())]["tiers"]
			var names: Array = []
			for t in tiers:
				names.append(League.tier_name(int(t)))
			lines.append([UiKit.t("Invited: the top three of the %s, eight clubs in all") % UiKit.t(" and ").join(names), UiKit.DIM])
		Calendar.Kind.PLAYOFF:
			lines.append([UiKit.t("The top four of the %s. Semi-finals and final, one weekend.") % s.tier_name(), UiKit.DIM])
		Calendar.Kind.WORLDS:
			lines.append([UiKit.t("Sixteen clubs: pools of four, then a knockout."), UiKit.DIM])
		Calendar.Kind.OWN:
			lines.append([UiKit.t("Your own show: eight clubs near your standard."), UiKit.DIM])
	## WHAT IT PAYS.
	match kind:
		Calendar.Kind.PLAYOFF:
			if s.world.player_tier() == League.Tier.NATIONAL:
				lines.append([UiKit.t("The champion goes to the Worlds as %s.") % SendOff.team_name(s), UiKit.YOU])
			else:
				lines.append([UiKit.t("Both finalists go up. The winner takes the title."), UiKit.YOU])
		Calendar.Kind.OWN:
			lines.append([UiKit.t("The gate is yours, and %d / %d / %d CC for a podium.") % ClubEvent.PODIUM, UiKit.YOU])
		_:
			lines.append([UiKit.t("Every win: renown and team morale. Champions: an honor for each of the eight."), UiKit.YOU])
	## AND HOW YOU STAND, and who is in it.
	if c == null:
		var h := _honor_of(wi, wk)
		if not h.is_empty():
			var f := String(h.get("player", ""))
			lines.append([UiKit.t("Won by %s") % String(h.get("champion_name", "")), UiKit.INK])
			lines.append([UiKit.t("You: %s") % (Cup.finish_words(f) if f != "" else UiKit.t("not in it")), UiKit.DIM])
		else:
			lines.append([UiKit.t("The field is drawn the week it starts."), UiKit.DIM])
		return
	lines.append([UiKit.t("You: %s") % (UiKit.t("in it") if c.player_alive() else (Cup.finish_words(c.player_finish)
		if c.player_finish != "" else UiKit.t("not in it"))), UiKit.UP if c.player_alive() else UiKit.DIM])
	var field: Array = c.entrants.duplicate()
	var shown: Array = []
	for id in field.slice(0, 8):
		shown.append(UiKit.t("%s (%d)") % [String(s.world.clubs[int(id)]["name"]) if int(id) != s.world.player_club
			or s.world.team_title == "" or c != s.world.worlds else s.world.team_title, int(s.world.clubs[int(id)]["power"])])
	lines.append([UiKit.t("Field: %s") % UiKit.t(", ").join(shown) + ("" if field.size() <= 8 else UiKit.t(" and %d more") % (field.size() - 8)), UiKit.DIM])


func _opponent_of(wk: Dictionary) -> int:
	var d := int(wk["day"])
	var sched: Array = s.world.schedule[s.world.player_tier()]
	if d < sched.size():
		for pair in sched[d]:
			if int(pair[0]) == s.world.player_club:
				return int(pair[1])
			if int(pair[1]) == s.world.player_club:
				return int(pair[0])
	return -1


func _honor_of(wi: int, wk: Dictionary) -> Dictionary:
	if wi >= s.world.week:
		return {}
	var kind := int(wk["kind"])
	var id := "worlds" if kind == Calendar.Kind.WORLDS else (
		"playoff:%d" % s.world.player_tier() if kind == Calendar.Kind.PLAYOFF else
		s.world.invitational_id(LeagueWorld.set_of_tier(s.world.player_tier()), Calendar.slot_of(wk)))
	for h in s.world.honors:
		if String(h.get("id", "")) == id and int(h.get("season", -1)) == s.world.season:
			return h
	return {}


func _popup() -> void:
	draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.55))
	UiKit.panel(self, _pop())
	var info := _info(pick)
	var wk: Dictionary = s.world.calendar[pick]
	draw_rect(Rect2(_pop().position + Vector2(2, 2), Vector2(8, _pop().size.y - 4)), _color_of(wk))
	UiKit.text_fit(self, font, String(info[0]).to_upper(), _pop().position + Vector2(28, 38), 20, UiKit.YOU, _pop().size.x - 56.0)
	UiKit.text_fit(self, font, String(info[1]), _pop().position + Vector2(28, 62), 13, UiKit.DIM, _pop().size.x - 56.0)
	## THE OPPONENT'S FOUR, at the foot of a fixture (1 Oct 2026).
	if int(wk["kind"]) == Calendar.Kind.LEAGUE:
		var opp := _opponent_of(wk)
		if opp >= 0:
			TeamCard.draw_stars(self, font, Vector2(_pop().position.x + 28.0, _pop().end.y - 112.0),
				s.club_for(opp), 2, 260.0, 14)
	var y := _pop().position.y + 96.0
	for l in info[2]:
		for line in UiKit.wrap(font, String(l[0]), _pop().size.x - 56.0, 14):
			if y > _pop().end.y - (128.0 if int(wk["kind"]) == Calendar.Kind.LEAGUE else 76.0):
				return
			UiKit.text(self, font, line, Vector2(_pop().position.x + 28.0, y), 14, l[1])
			y += 20.0
		y += 4.0
