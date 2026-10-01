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


## Which week of the season lands on this date, or -1.
func _week_on(y: int, m: int, d: int) -> int:
	for i in s.world.weeks_this_season():
		var dt := Calendar.date_of(s.world.season, i)
		if int(dt["year"]) == y and int(dt["month"]) == m and int(dt["day"]) == d:
			return i
	return -1


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


func _grid() -> void:
	var gx := 24.0
	var gw := _grid_right() - gx
	var cw := (gw - 6.0 * GAP) / 7.0
	var lead := Calendar.first_weekday(year, month)
	var n := Calendar.days_in(year, month)
	var rows := int(ceil(float(lead + n) / 7.0))
	var ch := (h() - 70.0 - (GRID_TOP + 20.0) - float(rows - 1) * GAP) / float(rows)
	for i in 7:
		UiKit.mid(self, font, Calendar.weekday_name(i), Vector2(gx + float(i) * (cw + GAP), GRID_TOP + 10.0),
			12, UiKit.YOU if i == 5 else UiKit.DIM, cw)
	var days := s.world.events_this_season()
	## THE DAYS A TOURNAMENT TAKES: a cup or your show Friday to Sunday, the
	## Worlds Monday to Sunday. Keyed by date, so a weekend that crosses into the
	## next month is drawn on both pages.
	var span := {}
	for i in s.world.weeks_this_season():
		var k := int(s.world.calendar[i]["kind"])
		if not Calendar.is_tournament(k):
			continue
		var from := -5 if k == Calendar.Kind.WORLDS else -1
		for sh in range(from, 2):
			if sh == 0:
				continue
			var dt := Calendar.date_of(s.world.season, i, sh)
			span["%d-%d-%d" % [int(dt["year"]), int(dt["month"]), int(dt["day"])]] = i
	for d in n:
		var cell := d + lead
		var col := cell % 7
		var row := cell / 7
		var r := Rect2(gx + float(col) * (cw + GAP), GRID_TOP + 20.0 + float(row) * (ch + GAP), cw, ch)
		draw_rect(r, UiKit.PANEL)
		UiKit.text(self, font, "%d" % (d + 1), r.position + Vector2(5, 15), 12, UiKit.DIM)
		var live := _in_season(year, month, d + 1)
		if live and col < 5:
			## A weekday in season: training, the background hum.
			draw_rect(Rect2(r.position + Vector2(5, ch - 9), Vector2(cw - 10, 3)), UiKit.UP.darkened(0.4))
		var key := "%d-%d-%d" % [year, month, d + 1]
		if span.has(key):
			var ti := int(span[key])
			var tk := int(s.world.calendar[ti]["kind"])
			draw_rect(Rect2(r.position + Vector2(2, 20), Vector2(cw - 4, ch - 23)),
				Calendar.color(tk).darkened(0.65 if ti < s.world.week else 0.45))
			UiKit.text(self, font, UiKit.clip_px(font, _short(s.world.calendar[ti], days), 11, cw - 10.0),
				r.position + Vector2(6, 33), 11, Calendar.color(tk).lightened(0.35))
			if ti == s.world.week:
				draw_rect(r, UiKit.YOU, false, 2.0)
			continue
		var wi := _week_on(year, month, d + 1) if col == 5 else -1
		if wi < 0:
			continue
		var wk: Dictionary = s.world.calendar[wi]
		var kind := int(wk["kind"])
		var c := Calendar.color(kind)
		var past: bool = wi < s.world.week
		var block := Rect2(r.position + Vector2(2, 20), Vector2(cw - 4, ch - 23))
		draw_rect(block, c.darkened(0.55 if past else 0.3))
		var a := _short(wk, days)
		var b := _detail(wi, wk)
		UiKit.text(self, font, UiKit.clip_px(font, a, 11, cw - 10.0), block.position + Vector2(4, 13), 11,
			c.lightened(0.55))
		UiKit.text(self, font, UiKit.clip_px(font, String(b[0]), 12, cw - 10.0), block.position + Vector2(4, 28), 12,
			b[1])
		if wi == s.world.week:
			draw_rect(r, UiKit.YOU, false, 3.0)


## THE CELL'S FIRST LINE: what the Saturday is, short enough for a cell.
func _short(wk: Dictionary, days: int) -> String:
	return Calendar.short_label(wk, days).to_upper()


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
	var c: Cup = s.world.cup_of_week(wk)
	if c == null and wi < s.world.week:
		## OVER: how far you got, from the cabinet.
		var id := "worlds" if kind == Calendar.Kind.WORLDS else (
			"playoff:%d" % s.world.player_tier() if kind == Calendar.Kind.PLAYOFF else String(wk.get("cup", "")))
		for h in s.world.honors:
			if String(h.get("id", "")) == id and int(h.get("season", -1)) == s.world.season:
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
