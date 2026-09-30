class_name Records
extends Node2D
## THE BOOK — the club's records, and the manager's own record.
##
## NAMED, so another screen can ask for one of its pages by name. The Squad tab
## opens this on HISTORY, and `Session.records_page = 2` would have been a magic
## number that survives exactly until somebody inserts a page before it.
##
## Two things Retro Bowl keeps on one screen behind a tab row, and they belong
## together: one is what your fighters have done and the other is what you have.
##
## The club's records outlive the men who set them, which is why they are stored
## on the world rather than scanned off the roster — see `LeagueWorld.records`.

## FIVE PAGES NOW. HISTORY is the trophy cabinet and the season-by-season, which
## used to be the HONORS tab on the season screen — Pete, 15 Sep 2026: *"Throw
## Honors into Squad and a team history page."*
##
## This is where it belongs and not because the tab was wanted for something
## else. The club's records already live on this screen and the club's honors ARE
## records; what they are not is a DECISION, and a tab on the season screen is
## the most expensive place in the game to keep something a player reads once a
## career. The Squad tab has the button that opens it.
enum Page { YEAR, CLUB, HISTORY, HALL, MINE }

const ROWS := [
	{"key": "downs_event", "label": "Most downs in one event"},
	{"key": "downs_career", "label": "Most downs, a career"},
	{"key": "events", "label": "Most events for the club"},
	{"key": "standing", "label": "Most rounds finished standing"},
	{"key": "rating", "label": "Best rated fighter"},
]

## The tab row, sized from the screen rather than from three literals that
## happened to fit when there were two of them.
##
## FOUR NOW, and the count comes off the enum rather than off a `var n := 3` that
## a fourth tab would have walked straight past — which is precisely what the
## two hand-written x values did when the third arrived. A row that is told how
## many tabs there are cannot be told wrong.
## 140 AND NOT 172. Five tabs at the old width is 5x172 + 4x10 = 900 pixels,
## which leaves 36 of margin on a 960 canvas and puts the first tab under the
## Back button. The row is sized from the count, so this is the one number that
## had to move.
const TAB_W := 140.0
const TAB_GAP := 8.0


static func _tab_x(i: int) -> float:
	var n := Page.size()
	var total := float(n) * TAB_W + float(n - 1) * TAB_GAP
	return UiKit.screen().x - 24.0 - total + float(i) * (TAB_W + TAB_GAP)


var font: Font
var ui: CanvasLayer
var season: Season
var page: int = Page.CLUB


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	## OPENED ON A PARTICULAR PAGE, when somebody asked for one. The Squad tab's
	## "Club record" button wants HISTORY and every other road wants whatever the
	## player was last looking at.
	if Session.records_page >= 0:
		page = clampi(Session.records_page, 0, Page.size() - 1)
		Session.records_page = -1
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	ui.add_child(UiKit.back_button("res://scenes/Season.tscn"))
	## THREE TABS NOW, and they have to fit the row rather than the row being
	## assumed to fit them. The two were placed at a hand-written x of 400 and 610
	## with a width of 200; a third at 820 would have run 84px off a 960 screen.
	var labels := [UiKit.t("This year"), UiKit.t("The club"), UiKit.t("History"), UiKit.t("The Hall"), UiKit.t("Your record")]
	for i in labels.size():
		## TABS AT THE TOP, like every other tabbed screen (blind review, 29 Sep:
		## the page tabs shared the bottom row with Back and looked like buttons).
		ui.add_child(UiKit.selected(UiKit.button(labels[i], Vector2(_tab_x(i), 16.0),
			Vector2(TAB_W, 40), func(p = i): page = p; _build()), i == page))
	queue_redraw()


func _draw() -> void:
	if season == null:
		return
	UiKit.set_mood(season.mood())
	UiKit.ground(self)
	UiKit.text(self, font, UiKit.t("RECORDS"), Vector2(24, 46), 26, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Season %d") % season.world.season,
		Vector2(24, 72), 14, UiKit.DIM)
	match page:
		Page.YEAR: _year()
		Page.CLUB: _club()
		Page.HISTORY: _history()
		Page.HALL: _hall()
		_: _mine()


## THE YEAR, WEEK BY WEEK — the one page this game has never had.
##
## Every number on it was already being written down. `results` has carried the
## opponent, the rounds for and against and the points swing since the league
## went in; since 14 Sep 2026 it carries the venue and the GRADE each bout was
## fought at as well. All that was missing was somewhere to read it, and a season
## you can only see one week at a time is a season you cannot learn anything
## from: the whole point of a review is that the bad run in the middle and the
## three away days it was made of are on the same page.
##
## THE GRADE COLUMN IS THE POINT OF THE PAGE. Pete's note, on a career that lost
## more than it won: *"which can be turned around by spending CC currency,
## bringing the difficulty down, or just fighting better/smarter."* A player who
## drops to FRIENDLY for a month and climbs back out should be able to SEE that
## he did, and a run of wins that quietly coincides with a run of easy grades
## should be legible as what it is. A review that hid it would be flattering him.
## HOW MANY WEEKS THE PAGE HOLDS, and it is not a number that was chosen to look
## right. The top tier is twelve clubs playing a single round-robin, so the
## longest season in the game is fifteen events — `League.events_in_season()`
## says so — and a review that scrolled, paged, or silently dropped the first
## three weeks of a title year would be the wrong shape for the one season a
## player most wants to read.
##
## Two columns of eight hold sixteen. `test_season.gd` checks that number
## against the league rather than against this comment, because **a capacity
## that has to agree with a fixture list is a capacity that will stop agreeing.**
const YEAR_COL_ROWS: int = 8
const YEAR_COLS: int = 2
const YEAR_CAP: int = YEAR_COL_ROWS * YEAR_COLS
const YEAR_GUTTER := 24.0
const YEAR_PITCH := 26.0


## HOW WIDE ONE COLUMN IS, on the canvas the game actually got. Was a flat 424
## — half of the 960-wide design, minus the gutter — which left a 210-pixel
## strip of empty panel down the right of every handset.
static func year_col_w() -> float:
	return (UiKit.span(40.0) - YEAR_GUTTER) / float(YEAR_COLS)


func _year() -> void:
	UiKit.panel(self, Rect2(24, 88, UiKit.span(), 340))
	UiKit.text(self, font, UiKit.t("THE SEASON SO FAR"), Vector2(40, 114), 12, UiKit.DIM)
	var played: Array = []
	for r in season.results:
		if not bool(r.get("bye", false)):
			played.append(r)
	var sum := season.year_summary()
	UiKit.right(self, font, UiKit.t("%d of %d") % [played.size(),
		season.world.events_this_season()],
		Vector2(UiKit.right_edge(48.0), 114), 11, UiKit.EDGE.lightened(0.5), 200)
	if played.is_empty():
		UiKit.text(self, font, UiKit.t("Nothing fought yet."), Vector2(40, 160), 16, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("Every event is written down here, with the grade you fought it at."),
			Vector2(40, 190), 14, UiKit.EDGE.lightened(0.5))
		return
	var hdr := UiKit.EDGE.lightened(0.5)
	for c in YEAR_COLS:
		var cx := 40.0 + float(c) * (year_col_w() + YEAR_GUTTER)
		UiKit.text(self, font, UiKit.t("OPPONENT"), Vector2(cx + 26.0, 140), 11, hdr)
		UiKit.right(self, font, UiKit.t("ROUNDS"), Vector2(cx + year_col_w() - 176.0, 140), 11, hdr, 90)
		UiKit.right(self, font, UiKit.t("DIFF"), Vector2(cx + year_col_w() - 120.0, 140), 11, hdr, 50)
		UiKit.right(self, font, UiKit.t("AT"), Vector2(cx + year_col_w(), 140), 11, hdr, 70)
	## THE LAST SIXTEEN, oldest first, so the page reads the way the season was
	## fought. Only a season longer than the page can lose anything off the front,
	## and by the constant above there is no such season.
	var first: int = maxi(0, played.size() - YEAR_CAP)
	for i in range(first, played.size()):
		var slot := i - first
		var cx := 40.0 + float(slot / YEAR_COL_ROWS) * (year_col_w() + YEAR_GUTTER)
		var y := 168.0 + float(slot % YEAR_COL_ROWS) * YEAR_PITCH
		_year_row(played[i], i + 1, cx, y)
	## THE FOOT. Totals for the WHOLE year, from the season rather than from the
	## rows this page happens to be showing.
	UiKit.rule(self, UiKit.RULE_GEM, Vector2(40, 382), UiKit.span(40.0), UiKit.FRAME)
	var pts_all: int = int(sum["diff"])
	UiKit.text(self, font, UiKit.t("%d fought") % int(sum["fought"])
		+ ("" if int(sum["simmed"]) == 0 else ", %d simulated" % int(sum["simmed"])),
		Vector2(40, 414), 14, UiKit.DIM)
	UiKit.right(self, font, "%d-%d" % [int(sum["rf"]), int(sum["ra"])],
		Vector2(UiKit.right_edge(260.0), 414), 14, UiKit.INK, 120)
	UiKit.right(self, font, "%+d" % pts_all, Vector2(UiKit.right_edge(200.0), 414), 13,
		UiKit.UP if pts_all > 0 else (UiKit.DOWN if pts_all < 0 else UiKit.DIM), 60)
	UiKit.right(self, font, UiKit.t("now at %s") % Grade.short_of(season.grade).to_lower(),
		Vector2(UiKit.right_edge(48.0), 414), 14, UiKit.EDGE.lightened(0.5), 200)


func _year_row(r: Dictionary, week: int, cx: float, y: float) -> void:
	var opp: int = int(r.get("opponent", -1))
	var nm := "—"
	if opp >= 0 and opp < season.world.clubs.size():
		nm = String((season.world.clubs[opp] as Dictionary).get("name", "?"))
	UiKit.text(self, font, "%d" % week, Vector2(cx, y), 11, UiKit.DIM)
	## HOME OR AWAY IN FRONT OF THE NAME. Retro Bowl puts an "@" on an away side
	## and nobody has ever needed it explained.
	var away := not bool(r.get("home", true))
	UiKit.text(self, font, ("@" if away else " ") + UiKit.clip(nm, 17),
		Vector2(cx + 26.0, y), 14, UiKit.DIM if away else UiKit.INK)
	UiKit.right(self, font, "%d-%d" % [int(r.get("rf", 0)), int(r.get("ra", 0))],
		Vector2(cx + year_col_w() - 176.0, y), 14, UiKit.INK, 90)
	var pts: int = int(r.get("margin", 0))
	UiKit.right(self, font, "%+d" % pts, Vector2(cx + year_col_w() - 120.0, y), 13,
		UiKit.UP if pts > 0 else (UiKit.DOWN if pts < 0 else UiKit.DIM), 50)
	## A SIMMED WEEK SAYS SO. The grade it was nominally fought at is true and
	## beside the point — nobody fought it — and printing it beside weeks the
	## player actually stood in would make the column a liar.
	if not bool(r.get("fought", true)):
		UiKit.right(self, font, UiKit.t("sim"), Vector2(cx + year_col_w(), y), 11,
			UiKit.DIM, 70)
		return
	## MATCHED CARRIES ITS STEP. "Matched" alone is four difficulties wearing one
	## word, which is why `_log` writes the step down beside it.
	var g: int = int(r.get("grade", Grade.DEFAULT))
	var word := Grade.short_of(g).to_lower()
	if g == Grade.G.MATCHED:
		word = "matched %+d" % int(r.get("step", Grade.STEP_START))
	UiKit.right(self, font, word, Vector2(cx + year_col_w(), y), 11, UiKit.DIM, 140)


## THE HALL OF FAME. Tagged by hand, on a man's own page, while he was still
## playing — see `LeagueWorld.tag_for_hall`. That is what makes it different from
## the club records on the first tab, which the game keeps for you automatically:
## this one is a list of men YOU decided mattered, and it is worth exactly as
## much as the judgement that put them in it.
func _hall() -> void:
	UiKit.panel(self, Rect2(24, 88, UiKit.span(), 340))
	UiKit.text(self, font, UiKit.t("THE HALL OF FAME"), Vector2(40, 114), 12, UiKit.DIM)
	UiKit.right(self, font, UiKit.t("%d of %d") % [season.world.hall.size(), LeagueWorld.HOF_MAX],
		Vector2(UiKit.right_edge(48.0), 114), 11, UiKit.EDGE.lightened(0.5), 120)
	if season.world.hall.is_empty():
		UiKit.text(self, font, UiKit.t("Nobody in it yet."), Vector2(40, 160), 16, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("Tag a fighter on his own page, while he is still playing."),
			Vector2(40, 190), 14, UiKit.EDGE.lightened(0.5))
		UiKit.text(self, font, UiKit.t("Who belongs in here is your judgment, not the game's."),
			Vector2(40, 210), 14, UiKit.EDGE.lightened(0.5))
		return
	## TWO COLUMNS. Twelve names down one side would run off the panel, and the
	## cap is twelve — so the layout has to hold the maximum rather than the
	## number that happens to be in there today.
	var y0 := 150.0
	for i in season.world.hall.size():
		var h: Dictionary = season.world.hall[i]
		var col := i / 6
		var x := 40.0 + float(col) * (UiKit.span(40.0) * 0.5 + 4.0)
		var y := y0 + float(i % 6) * 42.0
		UiKit.text(self, font, UiKit.clip(String(h.get("name", "?")), 16),
			Vector2(x, y), 16, UiKit.INK)
		## Stored in English (it is saved); translated here, where it is drawn.
		UiKit.text(self, font, UiKit.t(String(h.get("pos", ""))), Vector2(x + 190.0, y), 12, UiKit.DIM)
		UiKit.right(self, font, "%d" % int(h.get("rating", 0)),
			Vector2(x + 330.0, y), 15, UiKit.YOU, 60)
		UiKit.right(self, font, UiKit.t("S%d") % int(h.get("season", 0)),
			Vector2(x + UiKit.span(40.0) * 0.5 - 40.0, y), 12, UiKit.DIM, 70)


func _club() -> void:
	UiKit.panel(self, Rect2(24, 88, UiKit.span(), 340))
	UiKit.text(self, font, UiKit.t("CLUB RECORDS"), Vector2(40, 114), 12, UiKit.DIM)
	## A HEADING OVER EVERY COLUMN (blind review, 29 Sep: the dashes sat under
	## no heading and read as misaligned).
	UiKit.right(self, font, UiKit.t("RECORD"), Vector2(UiKit.right_edge(360.0), 114), 11, UiKit.EDGE.lightened(0.5), 120)
	UiKit.right(self, font, UiKit.t("HELD BY"), Vector2(UiKit.right_edge(170.0), 114), 11, UiKit.EDGE.lightened(0.5), 180)
	UiKit.right(self, font, UiKit.t("SET"), Vector2(UiKit.right_edge(48.0), 114), 11, UiKit.EDGE.lightened(0.5), 120)
	var y := 152.0
	var any := false
	for row in ROWS:
		var rec: Dictionary = season.world.records.get(String(row["key"]), {})
		UiKit.text(self, font, UiKit.t(String(row["label"])), Vector2(40, y), 15, UiKit.INK)
		if rec.is_empty():
			UiKit.right(self, font, "—", Vector2(UiKit.right_edge(360.0), y), 15, UiKit.DIM, 120)
		else:
			any = true
			UiKit.right(self, font, "%d" % int(rec["value"]), Vector2(UiKit.right_edge(360.0), y), 16, UiKit.YOU, 120)
			UiKit.right(self, font, UiKit.clip(String(rec["holder"]), 18),
				Vector2(UiKit.right_edge(170.0), y), 14, UiKit.INK, 180)
			UiKit.right(self, font, UiKit.t("S%d") % int(rec["season"]),
				Vector2(UiKit.right_edge(48.0), y), 14, UiKit.DIM, 120)
		y += 40.0
	if not any:
		UiKit.text(self, font, UiKit.t("Nothing yet. The record starts at your first event."),
			Vector2(40, y + 14), 14, UiKit.DIM)
	else:
		UiKit.text(self, font, UiKit.t("A record keeps the man's name even after he has gone home."),
			Vector2(40, y + 14), 14, UiKit.EDGE.lightened(0.5))


## THE MANAGER'S OWN RECORD, which is the one number a career-long save is for
## and the game has never shown. Derived from `world.history` and `honors` —
## both already kept, neither ever added up.
func _mine() -> void:
	var h := season.world.history
	var seasons := h.size()
	var promos := 0
	var rels := 0
	var best := 99
	var best_at := 0
	for e in h:
		if bool(e.get("promoted", false)):
			promos += 1
		if bool(e.get("relegated", false)):
			rels += 1
		var pos := int(e.get("position", 99))
		if pos > 0 and pos < best:
			best = pos
			best_at = int(e.get("season", 0))
	var cups := 0
	var finals := 0
	for e in season.world.honors:
		if int(e.get("champion", -1)) == season.world.player_club:
			cups += 1
		elif String(e.get("player", "")) != "":
			finals += 1

	## TWO PANELS THAT SPLIT WHATEVER WIDTH THERE IS, rather than two 448s that
	## split the width there used to be.
	var half := (UiKit.span() - 16.0) * 0.5
	var rx := 24.0 + half + 16.0
	UiKit.panel(self, Rect2(24, 88, half, 340))
	UiKit.text(self, font, UiKit.t("YOUR RECORD"), Vector2(40, 114), 12, UiKit.DIM)
	var y := 152.0
	_stat("Seasons run", "%d" % seasons, y); y += 32.0
	_stat("Promotions", "%d" % promos, y); y += 32.0
	_stat("Relegations", "%d" % rels, y); y += 32.0
	_stat("Best finish", "—" if best == 99 else UiKit.t("%s in season %d")
		% [UiKit.ordinal(best), best_at], y); y += 32.0
	_stat("Cups won", "%d" % cups, y); y += 32.0
	_stat("Cup runs", "%d" % finals, y); y += 32.0
	_stat("Now", season.tier_name(), y)

	UiKit.panel(self, Rect2(rx, 88, half, 340))
	UiKit.text(self, font, UiKit.t("SEASON BY SEASON"), Vector2(rx + 16.0, 114), 12, UiKit.DIM)
	if h.is_empty():
		UiKit.text(self, font, UiKit.t("This is your first."), Vector2(rx + 16.0, 152), 15, UiKit.DIM)
		return
	var ry := 148.0
	for i in range(h.size() - 1, maxi(-1, h.size() - 9), -1):
		var e: Dictionary = h[i]
		var col := UiKit.INK
		var tag := ""
		if bool(e.get("promoted", false)):
			col = UiKit.UP
			tag = UiKit.t("promoted")
		elif bool(e.get("relegated", false)):
			col = UiKit.DOWN
			## Not "down": that key is a man on the floor, and a translator
			## given one word for both has to pick one of them.
			tag = UiKit.t("relegated")
		UiKit.text(self, font, UiKit.t("S%d") % int(e.get("season", 0)), Vector2(rx + 16.0, ry), 14, UiKit.DIM)
		UiKit.text(self, font, League.tier_name(int(e.get("tier", 0))),
			Vector2(rx + 60.0, ry), 14, UiKit.INK)
		UiKit.right(self, font, UiKit.ordinal(int(e.get("position", 0))),
			Vector2(UiKit.right_edge(100.0), ry), 14, col, 120)
		UiKit.right(self, font, tag, Vector2(UiKit.right_edge(40.0), ry), 12, col, 60)
		ry += 30.0


func _stat(label: String, value: String, y: float) -> void:
	UiKit.text(self, font, UiKit.t(label), Vector2(40, y), 14, UiKit.DIM)
	UiKit.right(self, font, value, Vector2(24.0 + (UiKit.span() - 16.0) * 0.5 - 16.0, y), 15, UiKit.INK, 300)


## ----------------------------------------------------------------- HISTORY
## WHAT THE CLUB HAS WON, AND EVERY SEASON IT HAS HAD.
##
## Lifted whole from `season_scene._draw_honors()`, which was a whole tab of the
## season screen. Nothing about the two lists changed; what changed is that they
## are no longer occupying a slot next to the fixture list and the team sheet.
##
## THE TROPHIES ARE FILTERED AND THE SEASONS ARE NOT, and that asymmetry is
## deliberate. A cup the club did not enter and did not win is not this club's
## history; a season it played and came eleventh in is.
func _history() -> void:
	var h: Array = season.honors()
	var y := 100.0
	UiKit.text(self, font, UiKit.t("TROPHIES"), Vector2(24, y), 14, UiKit.DIM)
	y += 30.0
	var any := false
	for i in range(h.size() - 1, maxi(-1, h.size() - 11), -1):
		var e: Dictionary = h[i]
		var won: bool = int(e["champion"]) == season.world.player_club
		var mine := String(e["player"]) != ""
		if not mine and not won:
			continue
		any = true
		UiKit.text(self, font, UiKit.t("S%d  %s") % [int(e["season"]),
			UiKit.clip(String(e["name"]), 22)], Vector2(40, y), 15, UiKit.INK)
		UiKit.right(self, font, UiKit.t("Champions") if won else Cup.finish_words(String(e["player"])),
			Vector2(440, y), 15, UiKit.YOU if won else UiKit.DIM, 200)
		y += 26.0
	if not any:
		UiKit.text(self, font, UiKit.t("Nothing yet."), Vector2(40, y), 15, UiKit.DIM)

	y = 100.0
	UiKit.text(self, font, UiKit.t("SEASONS"), Vector2(500, y), 14, UiKit.DIM)
	y += 30.0
	if season.world.history.is_empty():
		UiKit.text(self, font, UiKit.t("This is your first."), Vector2(516, y), 15, UiKit.DIM)
		return
	for i in range(season.world.history.size() - 1,
			maxi(-1, season.world.history.size() - 13), -1):
		var e: Dictionary = season.world.history[i]
		var fin := UiKit.ordinal(int(e["position"]))
		var col := UiKit.INK
		if bool(e.get("promoted", false)):
			fin = UiKit.t("%s, promoted") % fin
			col = UiKit.UP
		elif bool(e.get("relegated", false)):
			fin = UiKit.t("%s, relegated") % fin
			col = UiKit.DOWN
		UiKit.text(self, font, UiKit.t("S%d  %s") % [int(e["season"]),
			League.tier_name(int(e["tier"]))], Vector2(516, y), 15, UiKit.DIM)
		UiKit.right(self, font, fin,
			Vector2(UiKit.right_edge(), y), 15, col, 220)
		y += 26.0
