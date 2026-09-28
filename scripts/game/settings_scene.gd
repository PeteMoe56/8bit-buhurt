extends Node2D
## Settings and credits, and the credits half is not optional.
##
## `menu.ogg` is licensed rather than ours, and that licence makes attribution a
## CONDITION: failure to attribute is "a material breach". So the credits are
## generated from `Audio.LICENSED` — the same dictionary the fallback chain
## walks — rather than typed out here where they could quietly go stale.

const PAD := 24.0
const COL_W := 430.0
const LEFT_X := 24.0
const RIGHT_X := 500.0
const TOP := 96.0
## HOW FAR APART THE THREE VOLUME ROWS SIT. It was 64 and the panel was 262 tall,
## which left the THIS CAREER panel starting at 378 — fine while that panel was a
## two-line signpost and not fine the moment it grew a control, because 378 plus
## a control is 498 and the Back button lives at 470.
##
## Named rather than nudged, and the panel's height is derived from it, so the
## next row added to SOUND cannot silently push the panel under a button again.
const ROW_STEP := 52.0
const SOUND_H := 218.0
## The career panel, and the Back button riding the bottom of whatever shape the
## screen turned out to be rather than a literal 470.
const CAREER_Y := TOP + 238.0
const CAREER_H := 136.0

var font: Font
var ui: CanvasLayer

const ROWS := [
	{"key": "music", "label": "Music"},
	{"key": "sfx", "label": "Effects"},
	{"key": "ui", "label": "Interface"},
]


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	for i in ROWS.size():
		var key := String(ROWS[i]["key"])
		var y := TOP + 56.0 + float(i) * ROW_STEP
		ui.add_child(UiKit.button("-", Vector2(LEFT_X + 214, y),
			Vector2(44, 38), _nudge.bind(key, -1)))
		ui.add_child(UiKit.button("+", Vector2(LEFT_X + COL_W - 68, y),
			Vector2(44, 38), _nudge.bind(key, 1)))
	## ------------------------------------------------------------ difficulty
	## Pete, 15 Sep 2026: *"Difficulty should be changeable."*
	##
	## It was set once, on the club-creation screen, and this panel was a SIGNPOST
	## saying so — which was an answer to item 14 of the 15 Sep playtest (*"Can't
	## find difficulty settings"*) that told the player where it wasn't.
	##
	## The old argument was that a grade you can change between fixtures makes the
	## table meaningless. That assumes the player is cheating the table. The actual
	## player is four events into a losing season, has just been told by his own
	## game that the way out is *"bringing the difficulty down"*, and cannot find
	## the control — and **a difficulty setting you can only choose before you know
	## what it means is not a difficulty setting, it is a quiz question.**
	##
	## The record stays honest because `Season.grade_history` writes down every
	## change with the event it happened on, so a promotion won on FRIENDLY says so.
	##
	## ONE CYCLING BUTTON, like the reserve sort. Five grades is too many for a
	## row of buttons in a 430-pixel panel and a dropdown is a control this game
	## does not otherwise have; the button shows what it will change TO, which is
	## the one thing a cycling control has to do to not be a guess.
	if Session.season != null:
		var order: Array[int] = Grade.ORDER
		var at := order.find(Session.season.grade)
		var next: int = order[(maxi(0, at) + 1) % order.size()]
		ui.add_child(UiKit.button(Grade.name_of(next),
			Vector2(LEFT_X + 18, CAREER_Y + 90.0), Vector2(COL_W - 36.0, 36), func():
				Session.season.set_grade(next)
				Session.autosave()
				Audio.play("tap")
				_build()))

	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(LEFT_X, UiKit.bottom(58.0)),
		Vector2(160, 46), _back))
	queue_redraw()


func _nudge(key: String, dir: int) -> void:
	Settings.nudge(key, dir)
	## The tick you just heard is the volume you just set, which is the only
	## honest way to audition a UI slider.
	Audio.play("tap")
	queue_redraw()


func _back() -> void:
	UiKit.back("res://scenes/Title.tscn")


func _draw() -> void:
	UiKit.set_mood(UiKit.Mood.NORMAL)
	UiKit.ground(self)
	UiKit.text(self, font, UiKit.t("SETTINGS"), Vector2(LEFT_X, 54), 30, UiKit.INK)

	# ---------------------------------------------------------------- volume
	UiKit.panel(self, Rect2(LEFT_X, TOP, COL_W, SOUND_H))
	UiKit.text(self, font, UiKit.t("SOUND"), Vector2(LEFT_X + 18, TOP + 30), 15, UiKit.DIM)
	for i in ROWS.size():
		var key := String(ROWS[i]["key"])
		var y := TOP + 56.0 + float(i) * ROW_STEP
		UiKit.text(self, font, String(ROWS[i]["label"]),
			Vector2(LEFT_X + 18, y + 26), 17, UiKit.INK)
		var lvl := Settings.get_level(key)
		## Eight notches, because eight is countable at a glance and a continuous
		## bar is not — you can see what you set, not just that you set it.
		UiKit.meter(self, Rect2(LEFT_X + 266, y + 10, 90, 18),
			int(round(lvl / Settings.STEP)), 8,
			UiKit.YOU if lvl > 0.0 else UiKit.EDGE)

	## ------------------------------------------------------ where difficulty is
	## Pete, item 14 of the 15 Sep playtest: *"Can't find difficulty settings."*
	##
	## He could not because they are not here, and that is deliberate — the note
	## on `Season.grade` says it plainly: *"volume is a property of the room you
	## are sitting in, and difficulty is a property of the run."* A grade you
	## could change at the title screen between fixtures would make the table
	## meaningless.
	##
	## So this is not a move, it is a signpost, and the grade is the one thing on
	## this screen the player cannot change here. **A setting that is deliberately
	## somewhere else still has to be findable from where people look for it** —
	## an absence with no explanation is indistinguishable from an omission, and
	## that is exactly what it was mistaken for.
	UiKit.text(self, font, UiKit.t("Saved as you set them."),
		Vector2(LEFT_X + 2, TOP + SOUND_H + 12.0), 13, UiKit.EDGE.lightened(0.5))

	## ITS OWN PANEL, because it is its own kind of thing. The first cut put it
	## inside the SOUND box's last six pixels and it landed on "Saved as you set
	## them" — which is what a row added to a panel sized for the rows it already
	## had always does.
	## TALLER, because it holds a control now rather than a sentence explaining
	## that the control is elsewhere. 82 was the height of the signpost.
	var gy := CAREER_Y
	UiKit.panel(self, Rect2(LEFT_X, gy, COL_W, CAREER_H))
	UiKit.text(self, font, UiKit.t("THIS CAREER"), Vector2(LEFT_X + 18, gy + 24), 15, UiKit.DIM)
	if Session.season != null:
		UiKit.pair(self, font, UiKit.t("Difficulty"), Grade.name_of(Session.season.grade),
			Vector2(LEFT_X + 18, gy + 48.0), LEFT_X + COL_W - 18.0, 17, 15,
			UiKit.INK, UiKit.YOU)
		## WHAT THE ONE HE IS ON ACTUALLY DOES, not what the next one does. The
		## button below says where a tap goes; this line says where he is, and a
		## panel where both the label and the blurb describe somewhere else is a
		## panel that reads as already changed.
		## WRAPPED, NOT CUT. `fit_px` records every cut it makes and `test_ink.gd`
		## fails the suite on any of them, for the good reason that a clipped
		## sentence the game wrote itself reads to a player as a broken game — and
		## these blurbs were written for the club-creation screen's wider box, so
		## the first draw here lost four words off "A properly sanctioned fight.
		## Their numbers me." Two lines at 12px is the box being honest about how
		## much room it has.
		var lines := UiKit.wrap(font, Grade.blurb_of(Session.season.grade),
			COL_W - 36.0, 12)
		for li in mini(2, lines.size()):
			UiKit.text(self, font, lines[li],
				Vector2(LEFT_X + 18, gy + 66.0 + float(li) * 15.0), 12, UiKit.DIM)
	else:
		UiKit.text(self, font, UiKit.t("Difficulty"), Vector2(LEFT_X + 18, gy + 48.0),
			17, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("Open it from Clubhouse, Your career."),
			Vector2(LEFT_X + 18, gy + 68.0), 13, UiKit.EDGE)

	# --------------------------------------------------------------- credits
	UiKit.panel(self, Rect2(RIGHT_X, TOP, COL_W + 6, 344))
	UiKit.text(self, font, UiKit.t("CREDITS"), Vector2(RIGHT_X + 18, TOP + 30), 15, UiKit.DIM)
	var y := TOP + 62.0
	UiKit.text(self, font, UiKit.t("MUSIC"), Vector2(RIGHT_X + 18, y), 13, UiKit.YOU)
	y += 26.0
	for c in Settings.credit_lines():
		UiKit.text(self, font, UiKit.clip(String(c["line"]), 42),
			Vector2(RIGHT_X + 18, y), 16, UiKit.INK)
		y += 21.0
		UiKit.text(self, font, UiKit.t("from %s  ·  %s") % [String(c["from"]), String(c["url"])],
			Vector2(RIGHT_X + 18, y), 13, UiKit.DIM)
		y += 19.0
		UiKit.text(self, font, UiKit.t("Used under the %s") % String(c["licence"]),
			Vector2(RIGHT_X + 18, y), 12, UiKit.EDGE.lightened(0.5))
		y += 24.0
	## SHORTER, BECAUSE IT DID NOT FIT. Seventeen pixels over the panel's right
	## edge — invisible to every check until `test_ink.gd` learned to pair a
	## string with the box it was drawn on, and invisible by eye because the
	## overhang is one short word on a dim line. Wrapping it was the first fix
	## and it was worse: the second line pushed everything below it 18 pixels
	## down and ran "Built by BonkWorks." out of the bottom of the same panel,
	## which the same check then caught. One line, made to fit.
	UiKit.text(self, font, UiKit.t("All other audio written for this game."),
		Vector2(RIGHT_X + 18, y), 14, UiKit.DIM)
	y += 28.0
	UiKit.text(self, font, UiKit.t("TYPE"), Vector2(RIGHT_X + 18, y), 13, UiKit.YOU)
	y += 24.0
	var fc := Settings.face_credit()
	## TWO LINES, because the credit is generated and its length is not ours to
	## choose: the face's name and the face it is after are both somebody else's
	## words. On one line at 13px in the real face it ran to x 973 of a 960 frame.
	## A credit that is cut off is a licence condition that is not met.
	UiKit.text(self, font, String(fc["name"]), Vector2(RIGHT_X + 18, y), 13, UiKit.INK)
	y += 17.0
	UiKit.text(self, font, UiKit.t("after %s") % String(fc["from"]),
		Vector2(RIGHT_X + 18, y), 12, UiKit.INK)
	y += 19.0
	UiKit.text(self, font, UiKit.t("%s  ·  %s") % [String(fc["licence"]), String(fc["url"])],
		Vector2(RIGHT_X + 18, y), 12, UiKit.EDGE.lightened(0.5))
	y += 19.0
	UiKit.text(self, font, String(fc["ours"]),
		Vector2(RIGHT_X + 18, y), 12, UiKit.EDGE.lightened(0.5))
	y += 28.0
	UiKit.text(self, font, UiKit.t("GAME"), Vector2(RIGHT_X + 18, y), 13, UiKit.YOU)
	y += 26.0
	UiKit.text(self, font, Brand.short_name(), Vector2(RIGHT_X + 18, y), 16, UiKit.INK)
	y += 21.0
	UiKit.text(self, font, UiKit.t("Built by BonkWorks."), Vector2(RIGHT_X + 18, y), 13, UiKit.DIM)
