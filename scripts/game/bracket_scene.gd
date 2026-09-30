extends Node2D
## THE DRAW — the oldest open item in this project, carried from section 22.
##
## The cup screen could always tell you who you were fighting and never who else
## was left. That is the one thing a cup has that a league does not, and the
## game was hiding it.
##
## Four layouts were mocked at full size in `tools/mock_bracket.gd` before any
## of this was written, because the whole question is what it looks like at
## 960x540 with fourteen-character club names in it. Pete picked the tree with
## the road panel grafted on, and pools for Worlds.
##
## THE MOCK'S POOL TABLE WAS FAKE — it wrote `2 - i` into the won column and so
## printed a club with MINUS ONE WIN. Nobody noticed for five sections because
## nobody adds up a mockup. This screen reads `cup.pool_table()`, and
## `test_cup.gd` asserts every row reconciles.

## The bracket lays itself out against the canvas, not against the design.
static func w() -> float:
	return UiKit.screen().x
static func h() -> float:
	return UiKit.screen().y
const TREE_X := 24.0
const COL_W := 226.0
const COL_GAP := 12.0
const ROAD_X := 748.0
const ROAD_W := 188.0

var font: Font
var ui: CanvasLayer
var cup: Cup
var me: int = -1


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	cup = Session.viewing_cup
	if cup == null and Session.season != null:
		cup = Session.season.pending_cup()
	me = cup.player_club if cup != null else -1
	ui = CanvasLayer.new()
	add_child(ui)
	## Pools use the whole screen — four tables reach to within a few pixels of
	## the bottom — so Back moves to the top right rather than the tables being
	## squeezed to make room for it.
	var pools_mode: bool = cup != null and cup.has_pools and cup.stage == Cup.Stage.POOLS
	## BOTTOM-LEFT IN BOTH MODES (#14) — it was top-right in pools and
	## bottom-right in the knockout, two places in one scene.
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(24, h() - 56), Vector2(150, 44), _back))
	queue_redraw()


func _back() -> void:
	Session.viewing_cup = null
	UiKit.back("res://scenes/Season.tscn")


func _name(id: int) -> String:
	if Session.season == null or id < 0:
		return "—"
	var c: Dictionary = Session.season.world.club(id)
	return String(c.get("name", "—"))


func _draw() -> void:
	## The draw wears the occasion, like every other screen — a Worlds bracket
	## and a backyard invitational should not look the same.
	UiKit.set_mood(Session.season.mood() if Session.season != null else UiKit.Mood.NORMAL)
	Audio.for_mood(UiKit.mood, false)
	UiKit.ground(self)
	if cup == null:
		UiKit.text(self, font, UiKit.t("NO CUP RUNNING"), Vector2(24, 40), 22, UiKit.YOU)
		## Not reachable from the season screen (its button shows only with a cup
		## to show), but a screen that can be opened says what belongs on it.
		UiKit.para(self, font, UiKit.t("The cups are drawn during the season. A club in good standing with the federation is entered, and the draw appears here with your road through it."),
			Vector2(24, 72), 14, UiKit.DIM, UiKit.span(), 20.0, 3)
		return
	if cup.has_pools and cup.stage == Cup.Stage.POOLS:
		_pools()
		return
	UiKit.text(self, font, cup.cup_name.to_upper(), Vector2(24, 40), 22, UiKit.YOU)
	_tree()
	_road()


## HOW MANY CLUBS ARE IN THE BRACKET, and how many rounds that is.
##
## The tree worked this out one way and the road panel worked it out another,
## and in a Worlds they disagreed: the tree read the qualifiers (8) and the road
## read the entrants (16), so the player's quarter-final was printed under
## ROUND OF 16, his final under SEMI-FINALS, and the FINAL row said "not there
## yet" after he had won it. Two halves of one screen, contradicting each other.
##
## That is the same failure this project has now recorded three times — a rule
## applied at two call sites is a rule with a hole in it — and I shipped it
## today, in the section that says so. One function, called by both.
func _bracket_field() -> int:
	if cup.has_pools and not cup.rounds.is_empty():
		return cup.rounds[0].size() * 2
	if cup.has_pools:
		## Pools drawn, bracket not opened: the qualifiers are known by rule.
		return cup.pools.size() * Cup.POOLS_ADVANCE
	return cup.entrants.size()


func _bracket_rounds() -> int:
	var n := 0
	var left := _bracket_field()
	while left > 1:
		n += 1
		left /= 2
	return maxi(1, n)


# --------------------------------------------------------------------- tree
func _tree() -> void:
	var first := _bracket_field()
	UiKit.text(self, font, UiKit.t("%d clubs  ·  seeded  ·  one leg") % first,
		Vector2(24, 64), 14, UiKit.DIM)
	## EVERY ROUND THE CUP WILL HAVE, not just the ones it has opened.
	##
	## `cup.rounds` only grows as the cup advances, so deriving the column count
	## from it drew a bracket with ONE column on the first night — which is a
	## fixture list, not a draw. The shape of the tournament is known the moment
	## the field is seeded; the results are what arrive later. Rounds not yet
	## drawn get empty slots, which is also the answer to "who might I meet".
	var n_cols := _bracket_rounds()
	for i in n_cols:
		var x := TREE_X + float(i) * (COL_W + COL_GAP)
		var day: Array = cup.rounds[i] if i < cup.rounds.size() else []
		var ties: int = int(pow(2.0, float(n_cols - 1 - i)))
		var label: String = String(Cup.ROUND_NAMES.get(ties * 2, "Round of %d" % (ties * 2)))
		UiKit.text(self, font, label.to_upper(), Vector2(x, 106), 12, UiKit.DIM)
		var span := 368.0 / float(maxi(1, ties))
		for j in ties:
			var y := 126.0 + span * float(j) + span * 0.5 - 32.0
			_tie(Vector2(x, y), COL_W, day[j] if j < day.size() else {}, i)


func _tie(at: Vector2, w: float, m: Dictionary, round_i: int) -> void:
	var a: int = int(m.get("a", -1))
	var b: int = int(m.get("b", -1))
	var played: bool = bool(m.get("played", false))
	var live: bool = not played and (a == me or b == me) and round_i == cup.rounds.size() - 1
	if live:
		draw_rect(Rect2(at - Vector2(4, 4), Vector2(w + 8, 72)), UiKit.SELECT)
	_slot(at, w, a, m, true, played)
	_slot(at + Vector2(0, 32), w, b, m, false, played)


func _slot(at: Vector2, w: float, id: int, m: Dictionary, is_a: bool, played: bool) -> void:
	var won: bool = played and int(m.get("winner", -1)) == id
	var col := UiKit.INK if (won or not played) else UiKit.DIM
	if id == me:
		col = UiKit.YOU
	UiKit.panel(self, Rect2(at.x, at.y, w, 28), false)
	if won:
		draw_rect(Rect2(at.x, at.y, 3, 28), UiKit.UP)
	if id >= 0:
		UiKit.text(self, font, "%d" % (cup.entrants.find(id) + 1),
			Vector2(at.x + 8, at.y + 19), 12, UiKit.DIM)
		UiKit.text(self, font, UiKit.clip(_name(id), 16),
			Vector2(at.x + 24, at.y + 19), 14, col)
	else:
		UiKit.text(self, font, "—", Vector2(at.x + 24, at.y + 19), 14, UiKit.DIM)
	if played:
		UiKit.right(self, font, "%d" % (int(m.get("ra", 0)) if is_a else int(m.get("rb", 0))),
			Vector2(at.x + w - 8, at.y + 19), 14, UiKit.INK if won else UiKit.DIM, 30)


# --------------------------------------------------------------------- road
## THE PANEL THAT MAKES IT YOURS. A tree answers "who is left"; it does not
## answer "who do I fight next", which is the question the player actually came
## with. Both, on one screen, is why this variant was chosen over either alone.
func _road() -> void:
	UiKit.panel(self, Rect2(ROAD_X, 96, ROAD_W, 366))
	if me < 0:
		UiKit.text(self, font, UiKit.t("NOT YOUR CUP"), Vector2(ROAD_X + 16, 126), 12, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("You were not"), Vector2(ROAD_X + 16, 160), 14, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("invited this year."), Vector2(ROAD_X + 16, 180), 14, UiKit.DIM)
		return
	UiKit.text(self, font, UiKit.t("YOUR ROAD"), Vector2(ROAD_X + 16, 126), 12, UiKit.YOU)
	var y := 152.0
	var done := false   ## set the moment a tie of yours is lost
	var total := _bracket_rounds()
	for i in total:
		var m: Dictionary = {}
		if i < cup.rounds.size():
			for cand in cup.rounds[i]:
				if int(cand["a"]) == me or int(cand["b"]) == me:
					m = cand
		var ties: int = int(pow(2.0, float(total - 1 - i)))
		var label: String = String(Cup.ROUND_NAMES.get(ties * 2, "Round of %d" % (ties * 2)))
		UiKit.text(self, font, label.to_upper(), Vector2(ROAD_X + 16, y), 11, UiKit.DIM)
		if m.is_empty():
			## ONE "OUT", NOT THREE. Losing in the quarter-finals used to print
			## OUT against the semi-final and the final as well, which reads as
			## being knocked out of rounds you were never in. The round you
			## actually lost says so, with the score; everything after it is
			## simply not your business any more.
			UiKit.text(self, font, "—" if done else UiKit.t("not there yet"),
				Vector2(ROAD_X + 16, y + 24), 14, UiKit.EDGE.lightened(0.4))
			y += 64.0
			continue
		var opp: int = int(m["b"]) if int(m["a"]) == me else int(m["a"])
		UiKit.text(self, font, UiKit.clip_px(font, _name(opp), 14, ROAD_W - 32.0),
			Vector2(ROAD_X + 16, y + 24), 14, UiKit.INK)
		if bool(m.get("played", false)):
			var mine: int = int(m["ra"]) if int(m["a"]) == me else int(m["rb"])
			var his: int = int(m["rb"]) if int(m["a"]) == me else int(m["ra"])
			var won: bool = int(m.get("winner", -1)) == me
			UiKit.text(self, font, UiKit.t("%s  %d-%d") % [UiKit.t("WON") if won else UiKit.t("OUT"), mine, his],
				Vector2(ROAD_X + 16, y + 44), 14, UiKit.UP if won else UiKit.DOWN)
			if not won:
				done = true
		else:
			UiKit.text(self, font, UiKit.t("to fight"), Vector2(ROAD_X + 16, y + 44), 14, UiKit.YOU)
		y += 64.0
	if cup.champion >= 0:
		UiKit.text(self, font, UiKit.t("CHAMPION"), Vector2(ROAD_X + 16, 430), 11, UiKit.DIM)
		UiKit.text(self, font, UiKit.clip(_name(cup.champion), 17),
			Vector2(ROAD_X + 16, 452), 15,
			UiKit.YOU if cup.champion == me else UiKit.INK)


# -------------------------------------------------------------------- pools
## WORLDS. Sixteen clubs is the one shape a tree cannot hold on this screen, so
## the group stage gets a mode rather than a layout.
func _pools() -> void:
	UiKit.text(self, font, UiKit.t("%s  ·  GROUP STAGE") % cup.cup_name.to_upper(),
		Vector2(24, 40), 22, UiKit.YOU)
	UiKit.text(self, font, UiKit.t("%d clubs  ·  %d pools  ·  top %d go through")
		% [cup.entrants.size(), cup.pools.size(), Cup.POOLS_ADVANCE],
		Vector2(24, 64), 14, UiKit.DIM)
	for p in cup.pools.size():
		var px := 24.0 + float(p % 2) * 468.0
		## 176 tall at 184 apart (was 192 at 212): the pools end at 460 now, above
		## the bottom-left Back that every screen shares (#14).
		var py := 92.0 + float(p / 2) * 184.0
		UiKit.panel(self, Rect2(px, py, 444, 176))
		UiKit.text(self, font, UiKit.t("POOL %s") % char(65 + p), Vector2(px + 18, py + 28), 14, UiKit.DIM)
		UiKit.right(self, font, UiKit.t("P   W   D   L   MARGIN"), Vector2(px + 426, py + 28),
			12, UiKit.DIM, 240)
		## REAL ROWS. The mockup made these up and printed a club on minus one
		## win; these come off the cup's own table.
		var rows := cup.pool_table(p)
		for i in rows.size():
			var row: Dictionary = rows[i]
			var id := int(row["club"])
			var through: bool = i < Cup.POOLS_ADVANCE
			var col := UiKit.YOU if id == me else (UiKit.INK if through else UiKit.DIM)
			var ry := py + 62.0 + float(i) * 30.0
			if through:
				draw_rect(Rect2(px + 12, ry - 16, 3, 22), UiKit.UP)
			UiKit.text(self, font, "%d" % (i + 1), Vector2(px + 24, ry), 12, UiKit.DIM)
			UiKit.text(self, font, UiKit.clip(_name(id), 20), Vector2(px + 44, ry), 14, col)
			UiKit.right(self, font, UiKit.t("%d   %d   %d   %d   %+d")
				% [int(row.get("played", 0)), int(row.get("won", 0)),
					int(row.get("drawn", 0)), int(row.get("lost", 0)),
					## Margin is kept as for/against, like the league table —
					## there is no "margin" field and asking for one silently
					## returned zero for every club in every pool.
					int(row.get("mf", 0)) - int(row.get("ma", 0))],
				Vector2(px + 426, ry), 14, col, 240)
	UiKit.text(self, font, UiKit.t("Top %d of each pool make the knockout.") % Cup.POOLS_ADVANCE,
		Vector2(194, UiKit.bottom(16.0)), 14, UiKit.DIM)
