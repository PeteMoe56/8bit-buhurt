class_name UiKit
extends RefCounted
## The one place the game's colors and text sizes live.
##
## Two screens drawing the same palette from two sets of local constants is how
## a UI drifts: somebody nudges a gray on the season screen, the title screen
## keeps the old one, and the game looks like two games. Same reasoning as
## Tuning — a look pass should be a diff of one file.

## LANDSCAPE, 960x540 — Pete, 10 Sep 2026: *"This is a fully Landscape game just
## like Retro Bowl."* Every screen was built portrait first and every one of them
## was re-laid-out for this, which is the cheap version of the mistake: the
## expensive version is finding out after there is art.
##
## It suits the melee better than portrait ever did. A buhurt list is wider than
## it is deep and a line of five men is a horizontal thing, so the shape of the
## screen and the shape of the sport finally agree.
## THE SHAPE THE GAME WAS DRAWN FOR, and the shape it is actually running in.
## They are different numbers and the difference is a whole class of bug.
##
## `project.godot` is 960x540 with `stretch/aspect = "expand"`, which does not
## put bars on a screen that is not 16:9 — it hands the game a BIGGER canvas.
## Measured on 15 Sep 2026 with `tools/probe_viewport.gd`:
##
##   16:9   960x540      19.5:9  1170x540     20:9  1200x540
##   21:9   1260x540     4:3      960x720
##
## So the design is never squeezed: it always gets at least 960x540 and gains
## the rest in ONE axis — width on a handset, height on a tablet. Which means
## every screen has to be laid out against the canvas it got, not the canvas it
## was drawn for.
##
## This used to be `const SCREEN := Vector2(960, 540)` and every right edge in
## the game was a literal measured off it. On a 19.5:9 handset the background
## itself stopped at x=960 and a 210-pixel bare strip ran down the right of
## every screen, gold bottom bar included — see `shots/aspect_1170x540.png`,
## the first frame this project ever rendered that was not 960 wide.
##
## It is a FUNCTION rather than a variable on purpose. A static var would have
## to be refreshed by somebody, and a screen that forgot would draw last frame's
## shape; making it a call meant the compiler found all hundred-odd sites the
## day the const went away, instead of me finding them one screenshot at a time.
const DESIGN := Vector2(960.0, 540.0)

static var _screen: Vector2 = DESIGN
static var _screen_frame: int = -1


## THE 960 FRAME, CENTRED (Pete, 2 Oct 2026 playtest: "There's a lot of layouts
## that need centered like Team/The Hall"). Most menu screens were laid out for
## 960 wide and drawn from the left, so on a 19.5:9 phone they hugged the left
## edge with 200 empty pixels on the right. A screen that calls `frame()` is
## moved to the middle as a whole — its drawing node and its control layer — and
## while it is up `screen()` answers the 960 it was laid out for, so everything
## it right-aligns lands at the frame's right edge, not the phone's. The ground
## and the watermark still fill the real screen (`real_screen()`).
static var framed := false
static var frame_off := 0.0


static func frame(node: Node2D, layer: CanvasLayer = null) -> void:
	var off := floorf(maxf(0.0, real_screen().x - DESIGN.x) * 0.5)
	framed = off > 0.0
	frame_off = off
	_screen_frame = -1
	node.position.x = off
	if layer != null:
		layer.offset.x = off
	if not node.tree_exiting.is_connected(_unframe):
		node.tree_exiting.connect(_unframe)


static func _unframe() -> void:
	framed = false
	frame_off = 0.0
	_screen_frame = -1


## THE WHOLE SCREEN in a scene's own drawing frame: a dimmer behind a card has
## to reach the real edges of a framed (centred) scene, not just its 960.
static func full_rect() -> Rect2:
	return Rect2(Vector2(-frame_off, 0.0) if framed else Vector2.ZERO, real_screen())


## The whole visible canvas, framed or not: for grounds, veils and anything else
## that must reach the real edges.
static func real_screen() -> Vector2:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var root := (loop as SceneTree).root
		if root != null:
			var sz := root.get_visible_rect().size
			if sz.x > 1.0 and sz.y > 1.0:
				return sz
	return DESIGN


## The live canvas, in the units everything is drawn in. Cached per frame — it
## is read dozens of times a draw and the answer cannot change inside one.
static func screen() -> Vector2:
	if framed:
		return Vector2(DESIGN.x, real_screen().y)
	var f := Engine.get_process_frames()
	if f == _screen_frame:
		return _screen
	_screen_frame = f
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var root := (loop as SceneTree).root
		if root != null:
			var sz := root.get_visible_rect().size
			## A viewport of zero is a viewport that is not up yet, and handing
			## a layout zero width is worse than handing it the design size.
			if sz.x > 1.0 and sz.y > 1.0:
				_screen = sz
	return _screen


## THE THREE MEASUREMENTS EVERY SCREEN IN THIS GAME ACTUALLY TAKES.
##
## Before the canvas could change shape, a right edge was written `936` and a
## full-width panel was written `912`, and those two numbers are the same margin
## — 24 — expressed twice, in different arithmetic, in eleven files. Both had to
## change together and nothing said so. **A number that has to agree with
## another number is a number that will stop agreeing**, and this is the third
## section of the register to say it.
##
## `right_edge(m)` is where a right-aligned thing ends. `span(m)` is how wide a
## thing is that starts at `m` and ends at `right_edge(m)`. `bottom(m)` is the
## same for the other axis, which a tablet needs and a handset never does.
static func right_edge(margin: float = 24.0) -> float:
	return screen().x - margin - safe_right()


## THE RIGHT-HAND SAFE INSET, in canvas units — a punch-hole camera or a rounded
## corner on the right of a landscape phone. Zero on desktop and on any phone
## whose OS already keeps the app out of the cutout. Everything right-aligned
## goes through `right_edge`, so this is the one place that needs to know.
static var _safe_frame: int = -1
static var _safe_r: float = 0.0


static func safe_right() -> float:
	var f := Engine.get_process_frames()
	if f == _safe_frame:
		return _safe_r
	_safe_frame = f
	_safe_r = 0.0
	## Phones only: on a desktop the "safe area" is the monitor minus the
	## taskbar, in monitor coordinates, and means nothing to a window.
	if not OS.has_feature("mobile"):
		return 0.0
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or safe.size.x <= 0:
		return 0.0
	var right_px := float(win.x - safe.end.x)
	if right_px > 0.0:
		_safe_r = right_px * screen().x / float(win.x)
	return _safe_r


static func span(margin: float = 24.0) -> float:
	return screen().x - margin * 2.0


## A CROWD, IN WORDS A PERSON USES. 40, 1.2k, 80k — because "80000" in a
## sentence is a number a reader has to count the digits of, and the crowd is now
## the most-printed figure in the game.
static func crowd_word(heads: int) -> String:
	if heads < 1000:
		return str(heads)
	if heads < 100000:
		return "%.1fk" % (float(heads) / 1000.0)
	return "%dk" % int(round(float(heads) / 1000.0))


static func bottom(margin: float = 24.0) -> float:
	return screen().y - margin


## How much room this screen has beyond the shape it was drawn for. Zero on a
## 16:9 window, 210 wide on a 19.5:9 handset, 180 tall on a tablet. Layouts that
## want to spend the extra ask for it by name rather than subtracting 960 in
## eleven different files.
static func slack() -> Vector2:
	return screen() - DESIGN

# ------------------------------------------------------------------- the type
## TWO FACES, ONE GRID, and ONE PLACE TO GET THEM.
##
## Every scene did `font = UiKit.body()` in its own `_ready()` — sixteen
## copies of the same line, which is sixteen places to change and fifteen chances
## to miss one. They ask here instead, and swapping a face is now a one-line
## edit rather than a sweep.
##
## THE DISPLAY FACE IS A DERIVATIVE OF PRESS START 2P. Pete, 12 Sep 2026, after
## reading three names set in the house faces: *"Merrick looks like Merri-ck,
## Ulme looks like Ul-me, Coyle looks like Coyl-e."* He was right, and the cause
## was that every glyph advanced the full cell whether its ink filled the cell
## or not, so an `i` or an `r` left a hole beside it that the eye read as a word
## break. Press Start 2P does not have that fault — its narrow letters carry
## serifs that fill the cell — but it is monospaced, so it has the opposite one:
## `39 · age 26 · Toxic` came to 152px where it needs to fit beside a portrait.
## So this is Press Start 2P with ink pushed to the left edge of each cell and
## the advance cut to ink-width plus one pixel: same drawing, a fifth off every
## line, and no empty cell left to read as a space.
##
## THE BODY FACE IS OURS. Pete, 12 Sep 2026: *"We can use ours for the smaller
## point fonts so it looks better."* He is right, and the render is why — Press
## Start 2P is drawn with two-pixel stems, which is what gives it its weight and
## is exactly wrong for a dense table: at 8px an all-Plate roster is a wall. Rail
## is a 5×7 face with one-pixel stems, so it sets a table two-thirds the width
## and reads as quieter than the heading above it. The contrast between them is
## a hierarchy we would otherwise have to fake with color.
##
## | role | face | drawn on | for |
## |------|------|----------|-----|
## | body | Rail | 5×7 | table rows, footnotes, anything dense |
## | title | Plate | 7×8 | screen titles, names, headings |
## | number | Plate | 7×8 | scores, purses, ratings — its digits are tabular |
##
## Gorget (6×8) and Maul (8×8) are still in `fonts/` and still build from
## `buhurt-fonts`. Nothing asks for them; the day one earns a role it is a line
## here and no sweep.
const FACE_DIR := "res://fonts/"

## ONE LADDER, BECAUSE THE EM IS THE SAME. A pixel face is crisp only at whole
## multiples of its em, and the four faces are all declared on an **8px em** —
## Rail's seven rows of ink sit inside an eight-row box for exactly this reason.
## Had it stayed on the 7px em it was first built with, the ladder would be
## 7/14/21 for the body and 8/16/24 for everything else, and "the same size"
## would stop being a thing a screen could ask for.
##
## So: **8, 16, 24, 32, and nothing between.** `snap()` is what enforces it.
const GRID: int = 8

## OURS, for anything small and dense.
const FACE_BODY := "BuhurtRail-Regular.ttf"
## THE DERIVATIVE, for anything the player reads as a heading or a name.
const FACE_TITLE := "BuhurtPlate-Regular.ttf"
## Also the derivative — its digits were deliberately left monospaced, and every
## screen in this game that shows a record, a purse or a rating shows it in a
## column.
const FACE_NUMBER := "BuhurtPlate-Regular.ttf"

## THE ATTRIBUTION LIVES WITH THE FACE, for the same reason the music credits
## live in `Audio.LICENSED` rather than typed into the credits screen: a credit
## typed somewhere else is a credit that goes stale the day somebody swaps the
## file. `Settings.face_credit()` reads this.
##
## Only the derivative owes a credit. Rail, Gorget and Maul are ours and owe
## nobody anything.
const FACE_CREDIT := {
	"name": "Buhurt Plate",
	"from": "Press Start 2P by Cody Boisclair",
	"url": "zone38.net",
	"licence": "SIL Open Font License 1.1",
	"note": "Modified: proportional spacing, a clearer percent sign. Renamed as the license requires.",
	"ours": "Buhurt Rail, Gorget and Maul drawn for this game.",
}

static var _faces := {}


static func _face(file: String) -> Font:
	if _faces.has(file):
		return _faces[file]
	var path := FACE_DIR + file
	var f: Font = load(path) as Font if ResourceLoader.exists(path) else null
	## FALLS BACK, ALWAYS. The game has run on `ThemeDB.fallback_font` since the
	## first screen and has to go on running if a face is ever missing — a
	## project that will not open because a font did not import is a worse
	## problem than a project that opens looking wrong.
	if f == null:
		f = ThemeDB.fallback_font
	## AND BEHIND EVERY FACE, A PIXEL FONT THAT HAS EVERYTHING. The Buhurt faces
	## carry 43-222 glyphs; the dash, "=" and "|" the ENGLISH text already uses
	## were missing from the body face and drew in whatever smooth font the
	## phone had. LanaPixel (OFL, eishiya — fonts/fallback/LanaPixel-OFL.txt) is
	## built for localizing pixel games: Latin, Greek, Cyrillic and Japanese. It
	## draws only what the face in front of it lacks.
	elif f is FontFile and ResourceLoader.exists(FALLBACK_FACE):
		var fb := load(FALLBACK_FACE) as Font
		if fb != null and not (f as FontFile).fallbacks.has(fb):
			var list := (f as FontFile).fallbacks.duplicate()
			list.append(fb)
			(f as FontFile).fallbacks = list
	_faces[file] = f
	return f


const FALLBACK_FACE := "res://fonts/fallback/LanaPixel.ttf"


static func body() -> Font:
	return _face(FACE_BODY)


static func title() -> Font:
	return _face(FACE_TITLE)


static func number() -> Font:
	return _face(FACE_NUMBER)


## THE NEAREST LEGAL SIZE, rounded down so nothing grows into its neighbor.
## Every `text()` call runs its size through this, so a screen written against
## the old fallback font cannot silently ask for 13px and get a smeared row — it
## gets 8px, which is small but sharp, and obviously wrong enough that somebody
## fixes the call rather than shipping the blur.
static func snap(px: int, grid: int = GRID) -> int:
	return maxi(grid, (px / grid) * grid)


# ------------------------------------------------------------------- the mood
## THE SAME MENUS, DRESSED FOR THE OCCASION — Pete, 10 Sep 2026: *"tournaments/
## playoffs be the normal menu, except stylized... slightly more thematic in a
## 'boss battle' sort of way as other 8-Bits do."*
##
## This is a better idea than the one it replaced. I had been designing a
## separate bracket SCREEN, which is a second information architecture to build,
## learn and keep in step. A **skin** is not: the palette below is read by all
## 218 places in this game that draw anything, so swapping it dresses the whole
## shell — team sheet, clubhouse, market, the fight itself — for the price of one
## dictionary. The player does not learn a new screen; he notices the room got
## darker, which is exactly how an 8-bit game tells you the next fight is
## different.
##
## THE ESCALATION IS THE POINT. A mood that is on all season stops being a mood,
## so it is keyed to the thing in front of you and it climbs:
##
##   NORMAL   warm parchment and brown. A club in a hall on a Saturday.
##   CUP      the Kings Cup and the Path of Honor — night blue, colder ink.
##   HOSTED   your own tournament — warmer and brighter than anything else,
##            because it is your show and the lights are yours.
##   WORLDS   violet. Everything about this one should feel further from home.
##   FINAL    near-black with a red cast. The boss.
##
## Only the GROUND and the ink move. `YOU` stays gold in every mood, because it
## is how a player finds his own club on a table at a glance and a highlight that
## changes color is a highlight he has to re-learn five times.
enum Mood { NORMAL, CUP, HOSTED, WORLDS, FINAL }

## PETE'S PALETTE, restored 13 Sep 2026. A Tecmo palette went in for about an
## hour — black grounds, saturated navy panels, NES primaries — and his verdict
## was one line: *"Oh dear god that is an eye sore. Revert that shit and let's
## mess with UI instead of base colors."*
##
## He is right and the useful part is WHY, because the diagnosis that led to it
## was not wrong. Four things made the old screens read as a generic dark
## dashboard: hairline borders, engine-default buttons, tinted selection, and a
## flat palette. Three of those are construction and one is color — and only
## the construction ones needed fixing. Turning the color up to eleven fixed
## nothing that was broken and broke the thing that was not.
##
## So: the grounds are exactly what they were, and everything else in this file
## changed instead.
const PALETTES := {
	Mood.NORMAL: {
		"bg": "2e2a24", "ink": "e8e4d8", "dim": "a59c8b", "panel": "241f1a",
		"edge": "3d352b", "you": "f2d13c", "up": "6fbf5e", "down": "e8664a",
		"select": "4a5f7a", "track": "14110e", "empty": "2a251f",
		"name": "",
	},
	Mood.CUP: {
		"bg": "1b2230", "ink": "dfe7f2", "dim": "8696ad", "panel": "141a26",
		"edge": "2c3a4e", "you": "f2d13c", "up": "6fbf5e", "down": "e0603c",
		"select": "3c5a86", "track": "0d1119", "empty": "222c3c",
		"name": "CUP NIGHT",
	},
	Mood.HOSTED: {
		"bg": "33251a", "ink": "f6ead2", "dim": "b09572", "panel": "281c13",
		"edge": "4a3826", "you": "ffcf4a", "up": "7fca62", "down": "e8683c",
		"select": "6b4a2a", "track": "170f09", "empty": "332618",
		"name": "YOUR SHOW",
	},
	Mood.WORLDS: {
		"bg": "1f182c", "ink": "e8dff5", "dim": "9a8bb5", "panel": "171126",
		"edge": "352a4a", "you": "ffd94f", "up": "74c98a", "down": "e0568c",
		"select": "4d3a7a", "track": "0f0b17", "empty": "281f3a",
		"name": "WORLDS",
	},
	Mood.FINAL: {
		"bg": "2a1315", "ink": "f6dcd6", "dim": "b2837b", "panel": "1d0c0e",
		"edge": "4a2422", "you": "ffd24a", "up": "7fca62", "down": "ff5a44",
		"select": "6e2a2c", "track": "160708", "empty": "331618",
		"name": "THE FINAL",
	},
}


## `static var`, not `const` — that one word is the whole feature. Every call
## site still reads `UiKit.BG`, so nothing else in the game had to change.
static var mood: int = Mood.NORMAL
static var BG := Color("2e2a24")
static var INK := Color("e8e4d8")
static var DIM := Color("a59c8b")
static var PANEL := Color("241f1a")
## TWO JOBS, TWO CONSTANTS. `EDGE` was both **the color a box is drawn in** and
## **the quietest ink on the screen**. Those want opposite things — a rule wants
## to be the brightest thing on a panel, a footnote wants to be the dimmest —
## and while the frame was one pixel wide nobody noticed. Three pixels wide, at
## the same dark brown, and a panel has no edge at all.
##
## DERIVED, NOT DECLARED. `FRAME` is `EDGE` lightened, computed in `set_mood`, so
## **no new color enters the palette** and every mood gets its own frame for
## free. Pete's grounds are untouched; the frame is simply the edge turned up far
## enough to be an edge.
static var FRAME := Color("6e6252")
static var EDGE := Color("3d352b")
static var YOU := Color("f2d13c")
static var UP := Color("6fbf5e")
static var DOWN := Color("e8664a")
static var SELECT := Color("4a5f7a")
## The track a meter sits in, and an unfilled segment. These were hardcoded
## inside `meter` and `bar` — a near-black that looked right on brown and would
## have been the one thing left behind on a violet ground.
static var TRACK := Color("14110e")
static var EMPTY := Color("2a251f")


static func set_mood(m: int) -> void:
	if not PALETTES.has(m):
		m = Mood.NORMAL
	mood = m
	var p: Dictionary = PALETTES[m]
	BG = Color(String(p["bg"]))
	INK = Color(String(p["ink"]))
	DIM = Color(String(p["dim"]))
	PANEL = Color(String(p["panel"]))
	EDGE = Color(String(p["edge"]))
	FRAME = EDGE.lightened(FRAME_LIFT)
	YOU = Color(String(p["you"]))
	UP = Color(String(p["up"]))
	DOWN = Color(String(p["down"]))
	SELECT = Color(String(p["select"]))
	TRACK = Color(String(p["track"]))
	EMPTY = Color(String(p["empty"]))


## PULL A COLOR TOWARDS THE OCCASION. The melee has its own palette in `Tuning`
## — the ground, the list, the rail, the steel — and those are tuned for
## readability at speed, so they are not simply replaced by the mood. They are
## dragged toward it: enough that a Worlds final is visibly not a Tuesday in the
## Backyard Circuit, not so far that a player has to re-learn what a downed man
## looks like.
##
## `amount` is how far. The surround goes most of the way because nothing is read
## off it; the fighting surface barely moves at all.
static func tint(base: Color, amount: float) -> Color:
	return base if mood == Mood.NORMAL else base.lerp(BG, clampf(amount, 0.0, 1.0))


## What the occasion is called, for the banner. Empty on an ordinary matchday,
## which is how a screen knows not to draw one.
static func mood_name() -> String:
	return String((PALETTES[mood] as Dictionary).get("name", ""))

## A filled bar with a stepped track behind it — the shape Retro Bowl's front
## office uses for a cap and a facility, and the right one: a segmented bar says
## "three of five" at a glance where a number needs reading.
static func meter(ci: CanvasItem, r: Rect2, filled: int, total: int, col: Color) -> void:
	ci.draw_rect(r, TRACK)
	var pad := 3.0
	## WHOLE PIXELS, so every segment is the same width (round 11: a wide sixth
	## segment was counted as two).
	var w := floorf((r.size.x - pad * float(total + 1)) / float(total))
	for i in total:
		var seg := Rect2(r.position.x + pad + float(i) * (w + pad), r.position.y + pad,
			w, r.size.y - pad * 2.0)
		ci.draw_rect(seg, col if i < filled else EMPTY)
	ci.draw_rect(r, FRAME, false, 2.0)


## A continuous version, for anything measured rather than levelled.
static func bar(ci: CanvasItem, r: Rect2, frac: float, col: Color) -> void:
	## THE TRACK IS DITHERED, which is what `dither()` was written for and never
	## used for: its own comment says it "belongs on a meter track or a card
	## ground, never on a full screen", and then it sat with no caller while
	## every bar in the game drew a flat `TRACK` rectangle behind its fill.
	##
	## A checkerboard reads as 8-bit in a way a flat fill never does — a real
	## machine could not blend, so it dithered — and the empty half of a bar is
	## the one place in this UI where a texture is free: nothing is written over
	## it, and it is small, which is the condition the comment attaches.
	dither(ci, r, TRACK, EMPTY, 2.0)
	ci.draw_rect(Rect2(r.position + Vector2(3, 3),
		Vector2(maxf(0.0, (r.size.x - 6.0) * clampf(frac, 0.0, 1.0)), r.size.y - 6.0)), col)
	ci.draw_rect(r, FRAME, false, 2.0)


## ONE CARD, THREE SCREENS.
##
## The roster, the free-agent market and the staff room all draw the same thing:
## a colored band with a tag and a number, a name, a rating in stars, a line of
## small print and a bar along the bottom. The roster grew it first and the other
## two were about to grow their own copies — which is how the heraldry ended up
## drawn by two slightly different `match` statements and put a club in one mark
## on the table and another on the surcoat.
##
## `d` carries: tag, number, name, rating, note, right_note, bar (0-1 or -1 for
## none), bar_col, band (Color), dim (bool).
static func card(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary,
		big: bool = true) -> void:
	panel(ci, r)
	var hh: float = r.size.y * float(d.get("head_frac", 0.36 if big else 0.30))
	var head := Rect2(r.position, Vector2(r.size.x, hh))
	ci.draw_rect(head, tint(Color(d.get("band", SELECT)), 0.85))

	## HIS FACE, AT THE LEFT OF THE HEADER BAND — and the label steps aside for it.
	##
	## It went at the RIGHT first, which is where the shirt number is, and the
	## collision was invisible because no portrait art exists yet. That is the
	## trap this whole slot system sets: a layout you cannot see is a layout you
	## cannot check, and it surfaces on the day somebody drops in the real file.
	## Verified here against generated placeholders rather than reasoned about.
	##
	## Only when there is a face to draw. Every card in this game has worked
	## without art since the day it was written and goes on working: `portrait`
	## returns false with nothing drawn, and the label sits where it always did.
	## BIG CARDS ONLY, and that is a layout fact rather than a taste one.
	##
	## The small card is a hundred pixels wide and already carries a position, a
	## number, a name, stars and a condition bar. Adding a face pushed the label
	## right and the render showed "FLANKER" running straight through the shirt
	## number on the two longest ones. Rather than invent abbreviations for a
	## three-position game, the five men on the LINE get faces and the bench does
	## not — which is also a hierarchy worth having: the men who play are the men
	## you look at.
	var face_w := 0.0
	if big and d.has("face"):
		var f: Dictionary = d["face"]
		var side: float = head.size.y
		if ArtBank.portrait(ci, Rect2(head.position.x, head.position.y, side, side),
				int(f.get("rating", 50)), String(f.get("name", "")),
				int(f.get("number", 0))):
			face_w = side
	## FITTED BESIDE THE SHIRT NUMBER (round 4: "FLANKER 10" ran together).
	text_fit(ci, font, String(d.get("tag", "")).to_upper(),
		head.position + Vector2(8 + face_w, 18), 13 if big else 12, INK,
		r.size.x - 16.0 - face_w - (34.0 if d.has("number") and big else 0.0))
	## ON A SMALL CARD THE NUMBER GOES ON THE NAME LINE, where there is room.
	if d.has("number") and not big:
		right(ci, font, "%d" % int(d["number"]), Vector2(r.end.x - 6, r.position.y + hh + 20.0),
			14, INK * Color(1, 1, 1, 0.85), 30)
	elif d.has("number"):
		right(ci, font, "%d" % int(d["number"]),
			Vector2(r.end.x - 8, head.position.y + (30.0 if big else 22.0)),
			22 if big else 15, INK * Color(1, 1, 1, 0.85), 60)
	## THE HEADER'S RIGHT-HAND CORNER, for a card with no shirt number on it.
	##
	## The market is the one screen where a man does not have a number yet, so
	## that corner has been empty since the card was written. It is the right
	## place for a word about WHERE HE CAME FROM, because it sits in the colored
	## band next to the position and reads before anything below the fold.
	elif d.has("head_right"):
		right(ci, font, String(d["head_right"]).to_upper(),
			Vector2(r.end.x - 8, head.position.y + (18.0 if big else 14.0)),
			12 if big else 9, Color(d.get("head_right_col", INK)), 140 if r.size.x > 200.0 else 84)

	var dim_it: bool = bool(d.get("dim", false))
	var y := r.position.y + hh
	text(ci, font, clip(String(d.get("name", "")), 13) if big
			else clip_px(font, String(d.get("name", "")), 12, r.size.x - 16.0 - (24.0 if d.has("number") else 0.0)),
		Vector2(r.position.x + 8, y + (26.0 if big else 20.0)),
		17 if big else 12, DOWN if dim_it else INK)
	if d.has("rating") and big and bool(d.get("rating_word", false)):
		## ONE WAY TO SAY A RATING (round 9: big cards had stars and a grey
		## number, small cards "rated 42" in gold). Squad and market say it this way.
		text(ci, font, UiKit.t("rated %d") % int(d["rating"]), Vector2(r.position.x + 8, y + 47.0), 15, YOU)
	elif d.has("rating") and big:
		stars(ci, Vector2(r.position.x + 8, y + 36.0), int(d["rating"]), YOU, 11.0, 3.0)
	elif d.has("rating"):
		## THE NUMBER, NOT 8 px STARS, on a small card (round 7: half stars at
		## this size cannot be read), and said as a rating.
		text(ci, font, UiKit.t("rated %d") % int(d["rating"]), Vector2(r.position.x + 8, y + 36.0), 13, YOU)

	if big and d.has("note"):
		## `note_col` is optional and defaults to the dim it always was. The
		## market needs it: a card that colors the FEE by whether you can pay it
		## and leaves the WAGE plain lies about half its refusals, which is a
		## sentence already written on that screen about this exact card.
		## Its own width, less the right note's box when that shares the line.
		var nw := r.size.x - 16.0
		if big and d.has("right_note") and not bool(d.get("right_note_up", false)):
			nw -= 90.0
		text_fit(ci, font, String(d["note"]), Vector2(r.position.x + 8, y + 70.0), 12,
			d.get("note_col", DIM), nw)
	if big and d.has("right_note"):
		## `right_note_up` puts it on the star row, whose right side is empty: the
		## market's ceiling range ("to 55-61") ran into the age and wage on the
		## note line once its cards narrowed to six a row.
		var ny: float = y + (47.0 if bool(d.get("right_note_up", false)) else 70.0)
		right(ci, font, String(d["right_note"]), Vector2(r.end.x - 8, ny), 11,
			Color(d.get("right_col", UP)), 90)

	var frac := float(d.get("bar", -1.0))
	if frac >= 0.0:
		bar(ci, Rect2(r.position.x + 6, r.end.y - 18, r.size.x - 12, 12), frac,
			Color(d.get("bar_col", UP)))
	elif d.has("foot"):
		right(ci, font, String(d["foot"]), Vector2(r.end.x - 8, r.end.y - 8),
			13 if big else 11, Color(d.get("foot_col", YOU)), maxf(140.0, r.size.x * 0.6))
	## AND THE FOOT'S LEFT, which is the other half of a price.
	##
	## `Market.BAND_SHARE` charges by BAND and not by rating — a 61 and a 68 in the
	## same band cost the same credits, and reading the pool for the man at the
	## top of a band is the seam Pete asked for in item 8. **The card showed the
	## fee and never the band**, so the one piece of information the seam is made
	## of was the one piece a player could not see. A bucketed price with the
	## bucket hidden is not a seam, it is a surprise.
	if big and d.has("foot_left"):
		text(ci, font, String(d["foot_left"]), Vector2(r.position.x + 8, r.end.y - 8),
			11, Color(d.get("foot_left_col", DIM)))


## STARS, AND A HALF STAR IS NOT A ROUNDING ERROR.
##
## Retro Bowl rates a man out of five in halves, and the half matters: it is the
## difference between "he is a four" and "he is nearly a five", which is exactly
## the gap a player is deciding about when he looks at two men. So the scale is
## in halves and the last one is drawn clipped rather than dimmed — a dimmed
## star reads as a star he has not earned, a half star reads as half a star.
##
## A rating is 1-99 and there are ten halves, so each half is ten points.
static func stars(ci: CanvasItem, at: Vector2, rating: int, col: Color,
		size: float = 11.0, gap: float = 3.0) -> void:
	## EIGHT OR SIXTEEN, PICKED BY WHAT WAS ASKED FOR. Both are on the grid; a
	## star between the two would have a half-pixel point on it.
	var small := size < 13.0
	var px := 8.0 if small else 16.0
	var step := px + gap
	var halves := clampi(int(round(float(rating) / 10.0)), 0, 10)
	for i in 5:
		var p := Vector2(at.x + float(i) * step, at.y)
		var full: bool = halves >= (i + 1) * 2
		var half: bool = not full and halves == i * 2 + 1
		if full:
			UiIcons.draw(ci, "star", p, col, 1, small)
		elif half:
			## THE EMPTY ONE GOES DOWN FIRST and the half sits on top of it.
			##
			## The polygon version painted the right half out with `PANEL`,
			## which is correct on a panel and wrong everywhere else — on the
			## background, on a selected gold row, on a colored card band it
			## drew a dark brown rectangle through the middle of the star. It
			## was invisible because a half star is rare and every screenshot
			## that had one happened to have it on a panel.
			UiIcons.draw(ci, "star", p, FRAME, 1, small)
			UiIcons.draw(ci, "star_half", p, col, 1, small)
		else:
			## THE FRAME, NOT THE EMPTY-WELL COLOR (review, 1 Oct 2026: an unlit
			## star on a panel vanished, so "1 of 5" read as "1").
			UiIcons.draw(ci, "star", p, FRAME, 1, small)


# ------------------------------------------------------------- the ledger
## WHAT WAS DRAWN, AND WHERE — off in the game, on in the suite.
##
## `test_layout.gd` opens with a paragraph admitting what it cannot see:
##
##   > WHAT IT CANNOT SEE: drawn text. `draw_string` leaves no node behind, so a
##   > label running into a number is still only findable by rendering.
##
## That has been true since it was written and it is about to matter. Sixteen
## scenes still draw in `ThemeDB.fallback_font`, the real face is 25 to 55 per
## cent wider at the same size, and switching them over moves every string in the
## game — with no check anywhere that can see a single one of them.
##
## So the drawing records itself. Three functions carry every piece of text in
## every game screen (`melee_scene` draws its HUD raw, and is the exception), and
## a rect written down at the moment it is drawn is a rect a test can read. It is
## a static array behind a flag: nothing allocates and nothing is appended while
## the flag is false, which is always, except in `test_ink.gd`.
static var _ledger_on: bool = false
static var _ledger: Array[Dictionary] = []
## AND THE BOXES THE TEXT SITS IN.
##
## `test_ink.gd` opened by admitting it could not see these: *"panels are drawn
## rects with no association to the text sitting on them. A string can still run
## off the right edge of a panel and this will not know."* That was true for as
## long as the ledger recorded only `draw_string`, and naming it was all that
## ever happened to it.
##
## A panel knows its own rect, so the only thing missing was writing it down.
## `_panels` is that, and `test_ink.gd` pairs the two lists: a string whose box
## starts inside a panel and ends outside it is ink running off the edge of the
## thing it was drawn on, which no reader can see and no other check can catch.
static var _panels: Array[Rect2] = []
## PICTURES DRAWN SINCE THE LEDGER OPENED (30 Sep 2026): a logo or a slot of
## art is content to the screen checklist's empty-band rule, but is not a panel
## text has to stay inside, so it keeps a list of its own.
static var _art: Array[Rect2] = []


## COPY THAT DID NOT FIT THE COLUMN IT WAS WRITTEN FOR — see `fit_px`.
static var _overrun: Array[Dictionary] = []


static func ledger_start() -> void:
	_ledger_on = true
	_ledger.clear()
	_panels.clear()
	_art.clear()
	_overrun.clear()


## Note a drawn picture's rect for the checklist.
static func ledger_art(r: Rect2) -> void:
	if _ledger_on:
		_art.append(r)


static func ledger_arts() -> Array[Rect2]:
	return _art.duplicate()


## The panels drawn since the ledger opened, in draw order.
static func ledger_panels() -> Array[Rect2]:
	return _panels.duplicate()


## Every string this draw had to cut short. NOT cleared by `ledger_cover()`, and
## deliberately: a scrim makes ink unreadable, which is a reason to stop checking
## where it landed, and no reason at all to stop caring that the copy underneath
## was written too long for its column.
static func ledger_overrun() -> Array[Dictionary]:
	return _overrun.duplicate()


## A COVER WIPES THE SLATE. Call this immediately after painting something
## across the whole frame — an opaque ground, or the corner's scrim and panel.
##
## The ledger records what was DRAWN, and the fight screens draw a full melee
## frame and then put a screen on top of it: the corner's scrim is there exactly
## so the list underneath becomes unreadable, which is the point of a scrim. Ink
## recorded before that is ink no player is reading, and treating it as readable
## made the sweep report the scoreboard's own headers colliding with the corner's
## buttons — a complaint about pixels nobody can see.
##
## It is deliberately blunt: everything before the cover, gone. A partial cover
## is not a cover and should not call this.
static func ledger_cover() -> void:
	if _ledger_on:
		_ledger.clear()
		_panels.clear()


static func ledger_stop() -> Array[Dictionary]:
	_ledger_on = false
	var out := _ledger.duplicate()
	_ledger.clear()
	return out


## `at` is a BASELINE, which is what `draw_string` takes. The rect a reader cares
## about is the box the glyphs occupy, so the top is the baseline less the
## ascent — getting that wrong by a line would make every check in `test_ink.gd`
## measure the gap above the text instead of the text.
static func _note(font: Font, s: String, at: Vector2, size: int,
		align: int, width: float, col: Color = Color.WHITE) -> void:
	if not _ledger_on or s == "":
		return
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var x := at.x
	## A WIDTH OF -1 IS "NO BOX", which is what `draw_string` means by it, and an
	## alignment inside no box is a left alignment. Without this the ledger placed
	## a centerd string at `x - (w + 1) * 0.5` and reported ink in the margin.
	if width > 0.0:
		if align == HORIZONTAL_ALIGNMENT_RIGHT:
			x = at.x + width - w
		elif align == HORIZONTAL_ALIGNMENT_CENTER:
			x = at.x + (width - w) * 0.5
	var asc := font.get_ascent(size)
	_ledger.append({
		"rect": Rect2(x, at.y - asc, w, asc + font.get_descent(size)),
		"text": s, "size": size, "col": col,
	})


## ------------------------------------------------------------------- the raw
## `draw_string` WITH THE LEDGER WATCHING, and nothing else changed.
##
## `text()`, `right()` and `mid()` are the kit's own doors and every screen in
## the game goes through them — except `melee_scene`, which drew SIXTY-TWO
## strings straight onto the canvas because the splash, the corner and the
## after-action report are drawn as whole compositions rather than as rows of
## labels. Those three screens were therefore the only ones in the game the ink
## ledger could not see, and they are the three most recently rebuilt.
##
## Converting them to `text()` would have moved every one of them: `draw_string`
## takes a BASELINE and the kit's doors take a top. So this door takes
## `draw_string`'s arguments in `draw_string`'s order and forwards them verbatim.
## The substitution is `draw_string(` -> `UiKit.raw(self, ` and the pixels are
## identical by construction — which is a claim the shot tools can check, and did.
## ------------------------------------------------------------- the words
## EVERY WORD A PLAYER READS GOES THROUGH HERE, so a translation is data, not a
## code change. `t("Sim it")` is the English until a translation for the current
## locale says otherwise. Format templates are translated BEFORE they are filled
## — `UiKit.t("%d credits.") % got` — so the key is the template, not a sentence
## with this afternoon's numbers in it. `tools/extract_strings.py` collects every
## `UiKit.t("...")` into `locale/strings.csv`, the file a translator fills in.
static func t(s: String) -> String:
	## While the ledger runs, every key asked for is written down, so
	## `test_untranslated.gd` can check each one exists in the string table.
	if _ledger_on:
		_t_keys[s] = true
	return TranslationServer.translate(s)


static var _t_keys: Dictionary = {}


## ONE OR MANY (28 Sep 2026). The CSV string table has no plural forms, so a
## count picks between two WHOLE keys and each language words both itself —
## never `"event%s" % "s"`, which only English can read.
static func tn(one: String, many: String, n: int) -> String:
	return t(one if n == 1 else many)


static func ledger_keys() -> Array:
	var k := _t_keys.keys()
	_t_keys.clear()
	return k


## THE SMALLEST TYPE THE GAME DRAWS (Pete, 29 Sep 2026, #15). A phone held in
## landscape shows 960 virtual pixels across a hand's width, and labels at 7-9
## were unreadable there — the corner's ENERGY and CONDITION, the squad legend,
## the difficulty blurb. Every draw below is floored here, once, rather than at
## four hundred call sites; `fit_size` steps down to it and no further, so
## copy that no longer fits is cut and recorded, and `test_ink` names it.
const MIN_PX := 12


static func raw(ci: CanvasItem, font: Font, at: Vector2, s: String,
		align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1,
		size: int = 16, col: Color = Color.WHITE) -> void:
	size = maxi(size, MIN_PX)
	_note(font, s, at, size, align, width, col)
	ci.draw_string(font, at, s, align, int(width), size, col)


static func text(ci: CanvasItem, font: Font, s: String, at: Vector2,
		size: int, col: Color) -> void:
	size = maxi(size, MIN_PX)
	_note(font, s, at, size, HORIZONTAL_ALIGNMENT_LEFT, 0.0, col)
	ci.draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## A MAN'S PLACE, AS A COLOR — Rail, Flanker, Center. One table: the roster and
## the market each kept their own copy, and a man has to be the same color on
## every card he is drawn on.
## POSITION COLORS THAT MEAN NOTHING ELSE (Pete, 29 Sep 2026). Center was the
## alarm red and Flank the button slate, so a Center read as a problem and a
## Flanker as a button. Red is for danger only; slate is for controls only.
const POS_CENTER := Color("9b72cf")
const POS_FLANK := Color("e0913c")


static func pos_color(f: FighterCard) -> Color:
	match int(f.pos):
		Tuning.Pos.CENTER: return POS_CENTER
		Tuning.Pos.FLANK_L, Tuning.Pos.FLANK_R: return POS_FLANK
		_: return UP


## ONE LINE, MADE TO FIT ITS ROOM (29 Sep 2026). `text()` with a width: our
## copy at its size if it fits (English always has), else the type steps down
## as far as FIT_STEP pixels, and only then is the line cut — through `fit_px`,
## so a cut is still recorded and `test_ink.gd` still fails on it. The French
## and German drafts ran sixteen fixed one-liners off their panels.
const FIT_STEP := 3
const FIT_MIN_PX := MIN_PX

static func fit_size(font: Font, s: String, size: int, width: float) -> int:
	var px := maxi(size, MIN_PX)
	var floor_px := maxi(size - FIT_STEP, FIT_MIN_PX)
	while px > floor_px and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, px).x > width:
		px -= 1
	return px


static func text_fit(ci: CanvasItem, font: Font, s: String, at: Vector2,
		size: int, col: Color, width: float) -> void:
	var px := fit_size(font, s, size, width)
	text(ci, font, fit_px(font, s, px, width), at, px, col)


static func right_fit(ci: CanvasItem, font: Font, s: String, at: Vector2,
		size: int, col: Color, width: float) -> void:
	right(ci, font, s, at, size, col, width)


## A SENTENCE OVER UP TO `lines` LINES, wrapped to `width` — for copy that was
## written as two hand-split keys ("A new club starts in the" / "Backyard
## Circuit."), which no other language can translate half by half. Too long
## for its lines at full size, it steps the type down like `text_fit`; still
## too long, the last line is cut and recorded. Returns the lines drawn.
static func para(ci: CanvasItem, font: Font, s: String, at: Vector2, size: int,
		col: Color, width: float, line_h: float, lines: int = 2) -> int:
	size = maxi(size, MIN_PX)
	var px := size
	var floor_px := maxi(size - FIT_STEP, FIT_MIN_PX)
	var ls := UiKit.wrap(font, s, width, px)
	while ls.size() > lines and px > floor_px:
		px -= 1
		ls = UiKit.wrap(font, s, width, px)
	if ls.size() > lines:
		var rest := " ".join(ls.slice(lines - 1))
		ls = ls.slice(0, lines - 1)
		ls.append(rest)
	for i in ls.size():
		text(ci, font, fit_px(font, ls[i], px, width), at + Vector2(0, line_h * i), px, col)
	return ls.size()


static func right(ci: CanvasItem, font: Font, s: String, at: Vector2,
		size: int, col: Color, width: float) -> void:
	size = maxi(size, MIN_PX)
	## A BOX IS A PROMISE (29 Sep 2026). Godot clips a string wider than its
	## box without a word, so "Backyard Circuit limita um lutador c" went out
	## in Portuguese and no check could see it. Too wide, it steps down and is
	## cut through `fit_px`, which records it. English has always fit.
	if width > 0.0 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width:
		size = fit_size(font, s, size, width)
		s = fit_px(font, s, size, width)
	_note(font, s, at - Vector2(width, 0), size, HORIZONTAL_ALIGNMENT_RIGHT, width, col)
	ci.draw_string(font, at - Vector2(width, 0), s, HORIZONTAL_ALIGNMENT_RIGHT,
		width, size, col)


## THE SAME CUT, FOR COPY WE WROTE OURSELVES — and recorded when it happens.
##
## `clip_px` is the right answer for a string whose length is not ours: a club a
## player named, a fighter off the generator. Those can be any length and cutting
## one is the layout working.
##
## A LABEL, A NOTE OR A BLURB IS A DIFFERENT THING. We chose those words and we
## chose the column, so a cut means one of the two is wrong — and a cut sentence
## reads to a player as a broken game, not as a long name. Three of them shipped
## in this screen alone before a screenshot caught them. So this door records the
## cut and `test_ink.gd` fails on it, which turns "somebody looked" into "the
## suite said so".
static func fit_px(font: Font, s: String, px: int, width: float) -> String:
	var out := clip_px(font, s, px, width)
	if _ledger_on and out != s:
		_overrun.append({"text": s, "kept": out, "size": px, "width": width})
	return out


## THE GROUND EVERY SCREEN STANDS ON, plus the mark faded into it.
##
## Fifteen screens opened `_draw()` with the identical line —
## `draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)` — which was fine
## while the ground was one color. It stopped being fine the moment the ground
## gained a second layer: adding the watermark would have been the same edit
## fifteen times, and the sixteenth screen written next month would have been
## the one that forgot.
##
## The front door and the slot picker pass `false`. They already carry the logo
## at full strength, and a mark behind a mark is not a background, it is a
## printing error.
## AND IT STARTS THE MENU MUSIC, which is Pete's item 26: *"Put the music used
## in the settings menu into all the menus outside of fighting."*
##
## THREE SCREENS IN THE WHOLE GAME PLAYED ANYTHING — the front door, the slot
## picker and settings, all asking for the same track. Every other menu, which is
## thirteen of them including the one a player spends most of his time on, ran in
## silence. Not a decision anybody made; nobody had ever added the line.
##
## It belongs here for the same reason the watermark does: this function already
## runs on exactly the set of screens that want it and on none of the ones that
## do not. `melee_scene` paints its own ground and never calls this, so the fight
## keeps its own sound and cannot accidentally be given a menu tune.
##
## `Audio.music()` returns immediately when the track it is asked for is the one
## already playing, so calling it every frame from a draw costs a comparison —
## which is what the three screens that already had it have always done.
static func ground(ci: CanvasItem, wash: bool = true) -> void:
	Audio.music("menu")
	## The REAL screen, from its real left edge: a framed scene is drawn shifted.
	var o := Vector2(-frame_off, 0.0) if framed else Vector2.ZERO
	ci.draw_rect(Rect2(o, real_screen()), BG)
	if wash:
		Brand.draw_wash(ci, real_screen(), Brand.WASH, o)


## A LABEL ON THE LEFT AND A NOTE ON THE RIGHT, ON ONE LINE, THAT CANNOT MEET.
##
## Four rows of the clubhouse were drawn as a `text()` at the left edge and a
## `right()` at the right edge with a width typed in by hand, and three of them
## overlapped: "PLACES ON THE BUS" ran into "13 fit on the books" and printed
## `PLACES ON THE BUS13 fit on the books`. Nothing in the suite could see it —
## the ink sweep finds text off the frame, on a control or outside a panel, and
## text over text is none of those. A screenshot found it, twice, months apart.
##
## So the pair is now ONE call that measures the label and gives the note what
## is left. The note is the half that gets clipped because the label is the half
## that says what the row is; if there is no room at all the note is dropped
## rather than drawn through the label, which is the only other honest answer.
static func pair(ci: CanvasItem, font: Font, label: String, note: String,
		at: Vector2, right_x: float, label_px: int, note_px: int,
		label_col: Color, note_col: Color, gap: float = 12.0) -> void:
	text(ci, font, label, at, label_px, label_col)
	if note.strip_edges() == "":
		return
	var used := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		label_px).x
	var room := right_x - (at.x + used + gap)
	if room <= 0.0:
		return
	right_fit(ci, font, note, Vector2(right_x, at.y), note_px, note_col, room)


## Centerd in a box that starts at `at` and runs `width` wide — for a caption
## under a button, which is the only thing in the game that wants it.
static func mid(ci: CanvasItem, font: Font, s: String, at: Vector2,
		size: int, col: Color, width: float) -> void:
	size = maxi(size, MIN_PX)
	if width > 0.0 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width:
		size = fit_size(font, s, size, width)
		s = fit_px(font, s, size, width)
	_note(font, s, at, size, HORIZONTAL_ALIGNMENT_CENTER, width, col)
	ci.draw_string(font, at, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


## THE PURSE — drawn and watched in one call.
##
## Six screens show the balance and every one of them used to draw it with a
## bare `text()` or `right()`, which meant the number could change between two
## screens with nothing to mark it. Now the drawing and the noticing are the
## same call, so a screen cannot show a change without announcing it, and a
## screen added next year gets it by using the same helper everything else uses.
## AND THE NUMBER CANNOT OUTGROW ITS BOX.
##
## The header draws the purse inside a framed box sized for the figures a club
## actually carries. A probe that handed a club three thousand credits a year to
## see how far the ladder could be climbed put `41616 CC` in it, and the string
## ran straight out of the frame and through the mood word beside it. The
## `test_ink.gd` sweep cannot see that — its own header says so: *panels are
## drawn rects with no association to the text sitting on them* — so it was
## found by looking at a screenshot taken for an unrelated reason.
##
## A player will not bank forty thousand. He will absolutely bank four figures,
## and four figures already crowd the frame. Thousands print as `4.2k`, which is
## shorter than the four digits it replaces and reads as money at a glance.
static func purse_word(value: int) -> String:
	if absi(value) < 10000:
		return "%d CC" % value
	## One decimal up to a hundred thousand, none above it — "412k CC" is a
	## number; "412.3k CC" is a spreadsheet, and by then the tenth of a thousand
	## is noise. The branch is taken on the ROUNDED figure rather than the raw
	## one, or 99,999 prints as "100.0k" — the longest string this function can
	## produce, from the one value that was supposed to avoid it.
	if absi(value) < 1000000:
		var k := float(value) / 1000.0
		return "%.1fk CC" % k if absf(k) < 99.95 else "%dk CC" % int(round(k))
	return "%.1fm CC" % (float(value) / 1000000.0)


static func purse(ci: CanvasItem, font: Font, value: int, at: Vector2,
		size: int, col: Color, width: float = 0.0) -> void:
	var s := purse_word(value)
	if width > 0.0:
		right(ci, font, s, at, size, col, width)
		Juice.purse(value, at - Vector2(width * 0.5, 6.0))
	else:
		text(ci, font, s, at, size, col)
		Juice.purse(value, at + Vector2(0.0, -6.0))


## A PANEL IS AN OBJECT, NOT A REGION.
##
## This drew a one-pixel outline, which is a CSS idea: a hairline has no
## thickness, so at 960x540 it reads as a division of space rather than as a
## thing sitting on the screen, and the whole shell became regions instead of
## objects. That single line was most of why the game looked like a dashboard.
##
## Three pixels of white and four pixels of hard black behind it. No radius, no
## blur, no gradient — a real machine could not have drawn any of the three, and
## each one of them is a tell.
##
## Retro Bowl does not draw its panels at all; it stamps **seventeen pre-drawn
## box sprites**, sixteen of which are exact multiples of 8. We do not need the
## art: a chunky frame drawn by code is indistinguishable from a chunky frame
## drawn by hand. What we needed was the chunk.
const FRAME_PX := 3.0
const DROP_PX := 4.0
## HOW FAR THE EDGE IS TURNED UP to become a frame. One number, and it is the
## only dial in the whole look — lower and the panels dissolve back into the
## ground, higher and it starts down the road Pete already rejected.
const FRAME_LIFT := 0.34
## How far a button's contents sit inside its own frame. One number, because the
## day it looks wrong it should look wrong everywhere at once.
const ICON_PAD := 10.0
## The smallest a button's label is drawn before it is allowed to push.
const BUTTON_MIN_PX := 10


## AN UNFILLED PANEL IS NOT AN OBJECT. `filled = false` is asked for by the
## bracket's match slots and the chalkboard's rows — groups drawn ON a panel, not
## panels themselves — and giving those a drop shadow put a solid black block
## behind every one of them. They also cannot carry a three-pixel frame: a 28px
## slot framed in 3px of white is 21% white by area and reads as a white brick,
## which is exactly what the bracket turned into. So an unfilled panel gets the
## thinner rule and no drop, and the two cases stop pretending to be one.
## THE SHADOW LIVES INSIDE THE RECT IT WAS GIVEN.
##
## The first version drew the drop OUTSIDE the panel, which quietly made every
## panel and every button in the game **four pixels wider and four taller than
## the rect its screen asked for**. Sixteen screens were laid out flush against
## each other years of decisions ago, so every one of them started overlapping
## by exactly four pixels — Pete found it as *"the New Names on free agents is
## over another thing"*, and it was not that button: it was all of them.
##
## Two ways out. Add four pixels of gap to every layout in the game, by hand,
## sixteen screens — or make the drop fit in the space already allocated. The
## second is one edit and it is also the correct model: **the rect you ask for
## is the space you occupy**, which is how a sprite behaves and is what every
## caller already assumed.
##
## So the body shrinks by the drop and the drop fills what it gave up. Total
## footprint is exactly `r`, and no layout moved.
static func panel(ci: CanvasItem, r: Rect2, filled := true) -> void:
	if _ledger_on:
		_panels.append(r)
	if not filled:
		ci.draw_rect(r, FRAME, false, 1.0)
		return
	var body := Rect2(r.position, r.size - Vector2(DROP_PX, DROP_PX))
	ci.draw_rect(Rect2(body.position + Vector2(DROP_PX, DROP_PX), body.size),
		Color(0, 0, 0, 1))
	ci.draw_rect(body, PANEL)
	ci.draw_rect(body, FRAME, false, FRAME_PX)


## `mark` is optional and is an `UiIcons` name. A button that carries its own
## mark is read at a glance rather than parsed, which on a phone is the whole
## difference — and it goes through `UiIcons.texture()` because `Button.icon`
## wants a `Texture2D` and will not take a draw call.
static func button(text_: String, at: Vector2, size: Vector2, on_press: Callable,
		mark: String = "") -> Button:
	var b := Button.new()
	b.text = text_
	if mark != "" and UiIcons.has(mark):
		b.icon = UiIcons.texture(mark, INK, 1)
		b.set_meta("mark", mark)
		b.add_theme_constant_override("h_separation", 10)
		b.expand_icon = false
	b.position = at
	## SAME RULE AS THE PANEL. The `StyleBoxFlat` shadow draws outside the
	## control's own rect, so a button asked for 204x46 was painting 208x50 and
	## walking into whatever sat beside it. The control shrinks by the drop; the
	## caller's rect is still exactly what the button occupies on screen.
	##
	## Four pixels off the hit box is nothing — the touch target was 46 tall and
	## is now 42, still inside the 48 the mobile build wants raising it to
	## anyway.
	var inner := size - Vector2(DROP_PX, DROP_PX)
	b.custom_minimum_size = inner
	b.size = inner
	## THE PADDING GIVES WAY BEFORE THE LABEL DOES.
	##
	## Ten pixels each side is right for a button with room for it and wrong for
	## the three regime buttons on a captain's card, which are a third of a card
	## wide: at full padding "Normal" came out as "Norma". A fixed inset is a
	## promise the narrow buttons in this game cannot keep.
	##
	## So it is a MAXIMUM, not a constant. Every button gets the full inset if
	## its label leaves room for it and as much as it can afford otherwise, which
	## means a label is never clipped to make space for its own margin — and
	## `test_layout.gd` asserts the outcome rather than the rule.
	var room := inner.x - FRAME_PX * 2.0
	var need := body().get_string_size(text_, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		GRID * 2).x
	if mark != "" and UiIcons.has(mark):
		need += float(UiIcons.GRID) + 10.0
	skin(b, clampf((room - need) * 0.5, 2.0, ICON_PAD))
	## THEN THE TYPE GIVES WAY (29 Sep 2026). A Godot button grows to fit its
	## label, so a French "Candidature tournoi" pushed 20 px into the button
	## beside it. Past the smallest inset the label steps down a pixel at a time,
	## to BUTTON_MIN_PX, rather than moving the button's edge.
	if need > room - 4.0:
		var extra := need - body().get_string_size(text_, HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, GRID * 2).x
		var px := GRID * 2
		while px > BUTTON_MIN_PX and body().get_string_size(text_,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x + extra > room - 4.0:
			px -= 1
		b.add_theme_font_size_override("font_size", px)
	## A Control grows to its contents but never shrinks back, and before it is
	## in the tree it measures its label in the default theme, not the one it
	## will draw in (a Japanese ノーマル asked 62 and was sized 74). Put it back
	## to the rect it was asked for once it is in the tree — deferred, because an
	## immediate reset is clamped to that stale minimum.
	b.set_deferred("size", inner)
	## EVERY BUTTON IN THE GAME TICKS, from one line. Wiring a tap sound at each
	## call site would mean finding all of them, and then finding the one that
	## got added last week — the same "a rule enforced at one call site is a rule
	## with a hole in it" this codebase has now said three times. The sound is
	## silent until somebody records `tap.ogg`, so this costs nothing until it
	## costs nothing.
	##
	## ONE CONNECTION, NOT TWO, and that is load-bearing: `test_layout.gd` asks
	## every button on every screen whether anything is listening, and a rule
	## that means "one connection here, two connections there" is a rule that
	## cannot be checked. `Playbook.card_button` wires the same single closure.
	b.pressed.connect(func() -> void:
		Audio.play("tap")
		on_press.call())
	_add_slop(b, inner)
	return b


## A THUMB IS BIGGER THAN A 34-PIXEL BUTTON. On a 6" phone one design pixel is
## about an eighth of a millimetre, so the 30-36 px buttons this game is full of
## were 4-5 mm tall — well under the ~7 mm a finger wants. Redrawing every screen
## bigger would re-open every layout in the game; instead a short button gets
## invisible strips above and below it (up to `SLOP_MAX` each) that count as a tap
## on it. Only strips, never over the button itself, so hover and pressed states
## still come from the button. Where two buttons' strips meet in a gap, the one
## added later wins it, which is the nearer-drawn one.
##
## 56, NOT 44 (Pete, 29 Sep 2026, #4): "56 px minimum hit height; the hit box
## padded beyond the visible button." So the strips grow to 12 each — and a strip
## that big would reach into the next button in a stacked column, so once the
## button is on screen each strip is cut back to half the gap to any button above
## or below it (`_fit_slop`). A gap is shared, never taken.
const HIT_MIN: float = 56.0
const SLOP_MAX: float = 12.0
const BTN_GROUP := "uikit_button"


## A PAGE ARROW: the chevron drawn as an icon, because the face's "<" is a
## six-pixel glyph (round 8: "the arrows are about 6px").
static func arrow(right_: bool, at: Vector2, size: Vector2, on_press: Callable) -> Button:
	var b := button("", at, size, on_press, "right" if right_ else "left")
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


static func _add_slop(b: Button, inner: Vector2) -> void:
	b.add_to_group(BTN_GROUP)
	var slop := clampf((HIT_MIN - inner.y) * 0.5, 0.0, SLOP_MAX)
	if slop <= 0.0:
		return
	b.ready.connect(func() -> void: _fit_slop.call_deferred(b))
	b.visibility_changed.connect(func() -> void:
		if b.is_inside_tree() and b.visible:
			_fit_slop.call_deferred(b))
	for top in [true, false]:
		var strip := Control.new()
		strip.name = "HitSlopTop" if top else "HitSlopBottom"
		strip.mouse_filter = Control.MOUSE_FILTER_STOP
		strip.position = Vector2(0.0, -slop if top else inner.y)
		strip.size = Vector2(inner.x, slop)
		strip.gui_input.connect(func(ev: InputEvent) -> void:
			if b.disabled or not b.is_visible_in_tree():
				return
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT \
					and not ev.pressed:
				b.pressed.emit())
		b.add_child(strip)
		strip.set_meta("slop", slop)


## Cut each strip back so it never covers another visible button: at most half
## the gap to the nearest button above (top strip) or below (bottom strip) that
## shares any of its width.
static func _fit_slop(b: Button) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	var me := b.get_global_rect()
	for c in b.get_children():
		var nm := String(c.name)
		if not nm.begins_with("HitSlop"):
			continue
		var top := nm == "HitSlopTop"
		var want: float = float(c.get_meta("slop", SLOP_MAX))
		for o in b.get_tree().get_nodes_in_group(BTN_GROUP):
			if o == b or not (o as Control).is_visible_in_tree():
				continue
			var r := (o as Control).get_global_rect()
			if r.end.x <= me.position.x or r.position.x >= me.end.x:
				continue
			if top and r.end.y <= me.position.y:
				want = minf(want, (me.position.y - r.end.y) * 0.5)
			elif not top and r.position.y >= me.end.y:
				want = minf(want, (r.position.y - me.end.y) * 0.5)
		want = maxf(0.0, want)
		(c as Control).size = Vector2(me.size.x, want)
		(c as Control).position = Vector2(0.0, -want if top else me.size.y)


## A TEXT FIELD IN THE GAME'S OWN TYPE (29 Sep 2026). The name fields on
## Create and the Chalkboard were Godot's stock LineEdit — a smooth sans in a
## rounded grey box, the one control on those screens that was not pixel type.
static func skin_edit(e: LineEdit, px: int = 16) -> void:
	e.add_theme_font_override("font", body())
	e.add_theme_font_size_override("font_size", px)
	e.add_theme_color_override("font_color", INK)
	e.add_theme_color_override("font_placeholder_color", DIM)
	e.add_theme_color_override("caret_color", YOU)
	for state in ["normal", "focus", "read_only"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = BG.darkened(0.25)
		sb.border_color = YOU if state == "focus" else FRAME
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(0)
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		e.add_theme_stylebox_override(state, sb)


## GODOT'S DEFAULT BUTTON IS THE LOUDEST TELL ON THE SCREEN.
##
## A gray rounded rectangle with a soft vertical gradient. It is the one element
## no amount of pixel font covers, because the player has seen it in a hundred
## engine demos. Everything here is about removing what the default adds:
## `corner_radius` to zero, no gradient, a 3px border the same white as a panel
## frame, and a flat fill.
##
## THE PRESSED STATE MOVES THE BUTTON, it does not tint it. The shadow goes away
## and the box shifts down and right into where the shadow was, which is how a
## physical key behaves and how every 8-bit button that was worth pressing
## behaved. A hover tint is a mouse idea and this game is played with a thumb.
static func skin(b: Button, pad: float = ICON_PAD) -> void:
	b.add_theme_font_override("font", body())
	b.add_theme_font_size_override("font_size", GRID * 2)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK if touch_ui() else BG)
	b.add_theme_color_override("font_pressed_color", BG)
	b.add_theme_color_override("font_focus_color", INK)
	## A disabled button still says what it is (round 5: "almost invisible").
	b.add_theme_color_override("font_disabled_color", DIM.darkened(0.15))
	b.add_theme_constant_override("outline_size", 0)
	## THREE VALUES, AND THAT IS THE WHOLE HIERARCHY. First pass painted the
	## ground, the panels and the buttons all one navy, and the sixteen-screen
	## contact sheet came back as a wall — everything framed in white, nothing
	## nearer than anything else. A control has to be a different VALUE from the
	## surface it sits on, not just a different shape.
	##
	##   black ground  ->  navy panel  ->  bright blue control  ->  gold, pressed
	##
	## Gold only ever means "this is happening", which is the same job it does on
	## a league table and the reason it is the one color the mood swap never
	## touches.
	b.add_theme_stylebox_override("normal", _sb(SELECT, FRAME, DROP_PX, pad))
	## NO HOVER ON A THUMB. A tap leaves the emulated mouse sitting on the
	## button, so on a phone the last thing tapped stayed gold — "this is
	## happening" — until something else was touched.
	b.add_theme_stylebox_override("hover", _sb(SELECT if touch_ui() else YOU, FRAME, DROP_PX, pad))
	b.add_theme_stylebox_override("pressed", _sb(YOU, FRAME, 0.0, pad))
	b.add_theme_stylebox_override("focus", _sb(SELECT, YOU, DROP_PX, pad))
	## A DISABLED BUTTON IS STILL A BUTTON (round 10: the dark, flat box read
	## as a text field): the same shape and drop, the colour drained out of it.
	b.add_theme_stylebox_override("disabled", _sb(SELECT.lerp(PANEL, 0.7), EDGE, DROP_PX, pad))


## BUTTON KINDS (29 Sep 2026, blind review #4: "one button style does every
## job"). A button is made with `button()` as always, then marked:
##
##   primary   gold fill, dark type — THE thing to do on this screen, one per screen
##   danger    dark fill, red frame and type — destroys or gives something up;
##             pair it with `UiKit.confirm` so it takes two taps
##   selected  the chosen tab / option / regime: gold frame, filled lighter, so a
##             selection is a shape, not a 2 px line
##
## Anything unmarked is secondary, the slate it always was.
## A SLIDER A THUMB CAN HOLD (round 4: the engine's 12 px handle). A 22x30
## gold block on a 10 px track, the fill in the dim gold of a bar.
static var _grab: ImageTexture = null
static func skin_slider(s: Slider) -> Slider:
	if _grab == null:
		var img := Image.create(22, 24, false, Image.FORMAT_RGBA8)
		img.fill(FRAME)
		img.fill_rect(Rect2i(2, 2, 18, 20), YOU)
		img.fill_rect(Rect2i(9, 6, 1, 12), YOU.darkened(0.35))
		img.fill_rect(Rect2i(12, 6, 1, 12), YOU.darkened(0.35))
		_grab = ImageTexture.create_from_image(img)
	s.add_theme_icon_override("grabber", _grab)
	s.add_theme_icon_override("grabber_highlight", _grab)
	var track := StyleBoxFlat.new()
	track.bg_color = TRACK
	track.border_color = EDGE
	track.set_border_width_all(1)
	track.content_margin_top = 5.0
	track.content_margin_bottom = 5.0
	s.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = YOU.darkened(0.3)
	fill.content_margin_top = 5.0
	fill.content_margin_bottom = 5.0
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	return s


static func primary(b: Button) -> Button:
	## Marked, so a test can ask which button on a screen is THE one.
	b.set_meta("primary", true)
	var pad := float(b.get_theme_stylebox("normal").content_margin_left)
	b.add_theme_stylebox_override("normal", _sb(YOU, FRAME, DROP_PX, pad))
	b.add_theme_stylebox_override("hover", _sb(YOU if touch_ui() else YOU.lightened(0.15), FRAME, DROP_PX, pad))
	b.add_theme_stylebox_override("focus", _sb(YOU, INK, DROP_PX, pad))
	b.add_theme_stylebox_override("pressed", _sb(YOU.darkened(0.2), FRAME, 0.0, pad))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(c, BG)
	if b.icon != null and b.has_meta("mark"):
		b.icon = UiIcons.texture(String(b.get_meta("mark")), BG, 1)
	return b


static func danger(b: Button) -> Button:
	var pad := float(b.get_theme_stylebox("normal").content_margin_left)
	b.add_theme_stylebox_override("normal", _sb(PANEL, DOWN, DROP_PX, pad))
	b.add_theme_stylebox_override("hover", _sb(PANEL, DOWN, DROP_PX, pad))
	b.add_theme_stylebox_override("focus", _sb(PANEL, DOWN.lightened(0.2), DROP_PX, pad))
	b.add_theme_stylebox_override("pressed", _sb(DOWN, FRAME, 0.0, pad))
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(c, DOWN)
	b.add_theme_color_override("font_pressed_color", BG)
	if b.icon != null and b.has_meta("mark"):
		b.icon = UiIcons.texture(String(b.get_meta("mark")), DOWN, 1)
	return b


static func selected(b: Button, on: bool = true) -> Button:
	if not on:
		return b
	var pad := float(b.get_theme_stylebox("normal").content_margin_left)
	var fill := SELECT.lightened(0.28)
	b.add_theme_stylebox_override("normal", _sb(fill, YOU, DROP_PX, pad))
	b.add_theme_stylebox_override("hover", _sb(fill, YOU, DROP_PX, pad))
	b.add_theme_stylebox_override("focus", _sb(fill, YOU, DROP_PX, pad))
	return b


## THE TWO PLACES BACK LIVES, and only two.
##
##   back_button   bottom left, 150 x 44 — every list and office screen
##   corner_back   top right, 78 x 36, where the season screen's Menu sits —
##                 the canvas editors (arena, chalkboard, create), whose bottom
##                 edge is the work surface; it saves on the way out
##
## A thumb learns where Back is. Named here so a new screen picks one of the two
## rather than inventing a third.
static func back_button(fallback: String) -> Button:
	return button(t("Back"), Vector2(24, screen().y - 56), Vector2(150, 44), func():
		back(fallback))


## BOTTOM-LEFT LIKE EVERY OTHER BACK (Pete, 29 Sep 2026, #14). This was a small
## button in the top-right corner — one of six places Back lived. The name is
## kept because it still differs in one way: it saves before it leaves.
static func corner_back(fallback: String) -> Button:
	return button(t("Back"), Vector2(24, screen().y - 56), Vector2(150, 44), func():
		Session.autosave()
		back(fallback))


## A phone or a tablet: no pointer to hover with.
static func touch_ui() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


static func _sb(fill: Color, line: Color, drop: float, pad: float = ICON_PAD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_border_width_all(int(FRAME_PX))
	sb.border_color = line
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	## The drop is a real shadow with zero softness, and the offset is what makes
	## the pressed state look like the key went down rather than changed color.
	sb.shadow_size = int(drop)
	sb.shadow_color = Color(0, 0, 0, 1)
	sb.shadow_offset = Vector2(drop, drop)
	## THE CONTENT SITS OFF THE FRAME.
	##
	## Pete, 13 Sep 2026: *"Bring the icons right a little bit, you can see
	## they're all on the left line of every button and things."* He is right and
	## the cause is that these style boxes never set a content margin at all, so
	## Godot used none: the icon was placed at the left edge of the content box,
	## which is the inside of the three-pixel frame, which is touching it.
	##
	## A mark hard against a rule reads as part of the rule. Ten pixels is enough
	## to make it an object sitting on the button rather than a notch cut out of
	## the border, and it costs the label nothing — the text is centerd, so the
	## margin takes the same bite from each side.
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	## Zero drop means pressed: shove the box into where the shadow was, so the
	## label and the mark move with it.
	if drop == 0.0:
		sb.content_margin_left = pad + DROP_PX
		sb.content_margin_right = maxf(0.0, pad - DROP_PX)
		sb.content_margin_top = 2.0 + DROP_PX
		sb.content_margin_bottom = maxf(0.0, 2.0 - DROP_PX)
	return sb


## ---------------------------------------------------------------- the marks
## ONE LINE TO PUT A MARK ANYWHERE. `UiIcons` holds the grids; this is the door
## every screen comes through, so a screen never has to know the icon system
## exists beyond a name.
static func icon(ci: CanvasItem, name: String, at: Vector2, col: Color,
		scale: int = 1) -> void:
	UiIcons.draw(ci, name, at, col, scale)


## A PANEL WITH ITS NAME CUT INTO THE TOP RULE.
##
## The oldest menu trick there is, and it turns a rectangle into a labelled
## window for the price of one extra rect: draw the frame, then knock a notch
## out of the top edge and put the title in the gap. Every 8-bit menu worth
## remembering did this, and it is the single change that made the mockups stop
## looking like a web layout with a pixel font on it.
##
## The title is drawn in the SMALL face at grid size — a window label is
## furniture, not content, and a big one competes with what is inside the window.
static func window(ci: CanvasItem, r: Rect2, title: String, font: Font) -> void:
	panel(ci, r)
	if title == "":
		return
	## 13 px, NOT THE 8 px GRID (round 5: "KINGS CUP · QUARTER-FINALS" and the
	## grade panel's title read as 7 px). A tab on the top rule now.
	var px := 13
	var t := title.to_upper()
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	## The notch is cut in PANEL, not in BG — the frame sits on the panel's own
	## ground, so filling with the background color would punch a hole through
	## to whatever is behind the window.
	ci.draw_rect(Rect2(r.position.x + 14.0, r.position.y - 9.0,
		w + 16.0, 18.0), PANEL)
	ci.draw_rect(Rect2(r.position.x + 14.0, r.position.y - 9.0,
		w + 16.0, 18.0), FRAME, false, 1.0)
	## In the ledger like every other drawn string — the titles were the one
	## piece of text on a panel that the string and ink sweeps could not see.
	_note(font, t, r.position + Vector2(22.0, 5.0), px, HORIZONTAL_ALIGNMENT_LEFT, -1.0, YOU)
	ci.draw_string(font, r.position + Vector2(22.0, 5.0), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, YOU)


## THE HINT BAR IS GONE, and that is the decision rather than a deferral.
##
## `hints()` was fourteen lines that had never been drawn on any screen since
## the day they were written. Wiring it was never a call — it needed 26 pixels
## reserved at the foot of every screen that wanted one, which is a layout pass
## across sixteen scenes, and the screens have just been re-anchored to a canvas
## that changes shape. Adding a fixed 26px band to all of them now would undo
## half of that.
##
## The third option was to leave it sitting there untested, and that is the one
## that rots: an unused function reads as a feature somebody half-built, and the
## next person to open this file spends ten minutes working out whether it is
## safe to touch. **A function with no caller is not a feature, it is a
## question nobody answered.** Deleted 15 Sep 2026; the git history has it if
## the bar ever earns its 26 pixels.
## ----------------------------------------------------------- the ornaments
## SIX FILES, NOT TWO HUNDRED AND EIGHTY.
##
## Kenney's *Fantasy UI Borders* is CC0 and Pete had already imported and
## curated it into ACRTW fourteen months ago, with his own `KENNEY_PICKS.md`
## mapping seven categories. The pack is white line-art on transparent, which
## means it **multiply-tints to any color** — so one file serves all five moods
## and there is nothing to re-author when the palette moves.
##
## THE REASON IT SURVIVES ON A PIXEL GRID is that the artwork is geometric —
## Greek-key, stepped and square corners, drawn on axis with hard edges. A
## rounded or hand-drawn ornament downsampled to this screen is mush; these
## stay crisp because there was never a curve in them.
##
## ORNAMENT IS HIERARCHY, NOT WALLPAPER. Six files are here and they belong on
## four screens — the clubhouse menu, the trophy cabinet, the cup bracket and
## the title. A crest on every panel in the game is a crest on nothing.
##
## `art/ui/KENNEY-LICENSE.txt` ships beside them. CC0 requires no attribution,
## which is exactly why the licence text has to travel with the files: the thing
## that proves we owe nobody anything is the file that says so.
const ORNAMENT_DIR := "res://art/ui/"
const ORN_CREST := "crest_ornate_a__double_border.png"
const ORN_PANEL := "content_stepped__default_border.png"
const ORN_TROPHY := "trophy_filigree__double_border.png"
const ORN_BANNER := "banner_double_rule__double_border.png"
const RULE_GEM := "heading_rule_gem.png"
const RULE_BRACKET := "heading_rule_bracket.png"

static var _orn := {}


static func _ornament(file: String) -> Texture2D:
	if _orn.has(file):
		return _orn[file]
	var path := ORNAMENT_DIR + file
	var t: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	## MISSING IS SILENT, same rule as the faces and the audio. An ornament is
	## decoration; a project that will not draw because a decoration is absent is
	## a worse problem than a plain rectangle.
	_orn[file] = t
	return t


## NINE-SLICE, WITH THE CORNERS LEFT ALONE.
##
## The four corners are drawn at 1:1 and never scaled — a scaled corner is the
## one place a 9-slice gives itself away. The four edges are stretched along
## their own axis only, which for line-art that is constant along that axis is
## lossless.
static func ornament(ci: CanvasItem, file: String, r: Rect2, col: Color,
		m: float = 24.0) -> void:
	var t := _ornament(file)
	if t == null:
		return
	var ts := t.get_size()
	if r.size.x < m * 2.0 or r.size.y < m * 2.0:
		return
	var src := func(x: float, y: float, w: float, h: float) -> Rect2:
		return Rect2(x, y, w, h)
	var iw := ts.x - m * 2.0
	var ih := ts.y - m * 2.0
	## corners
	ci.draw_texture_rect_region(t, Rect2(r.position, Vector2(m, m)),
		src.call(0.0, 0.0, m, m), col)
	ci.draw_texture_rect_region(t, Rect2(r.position + Vector2(r.size.x - m, 0.0), Vector2(m, m)),
		src.call(ts.x - m, 0.0, m, m), col)
	ci.draw_texture_rect_region(t, Rect2(r.position + Vector2(0.0, r.size.y - m), Vector2(m, m)),
		src.call(0.0, ts.y - m, m, m), col)
	ci.draw_texture_rect_region(t,
		Rect2(r.position + Vector2(r.size.x - m, r.size.y - m), Vector2(m, m)),
		src.call(ts.x - m, ts.y - m, m, m), col)
	## edges
	var mid_w := r.size.x - m * 2.0
	var mid_h := r.size.y - m * 2.0
	ci.draw_texture_rect_region(t, Rect2(r.position + Vector2(m, 0.0), Vector2(mid_w, m)),
		src.call(m, 0.0, iw, m), col)
	ci.draw_texture_rect_region(t,
		Rect2(r.position + Vector2(m, r.size.y - m), Vector2(mid_w, m)),
		src.call(m, ts.y - m, iw, m), col)
	ci.draw_texture_rect_region(t, Rect2(r.position + Vector2(0.0, m), Vector2(m, mid_h)),
		src.call(0.0, m, m, ih), col)
	ci.draw_texture_rect_region(t,
		Rect2(r.position + Vector2(r.size.x - m, m), Vector2(m, mid_h)),
		src.call(ts.x - m, m, m, ih), col)


## A SECTION RULE, WITH A TERMINAL AT EACH END.
##
## READ THE ASSET BEFORE USING IT. My first version stretched the whole 96px
## strip across the width and sampled its "plain" ends from the outer quarters —
## which produced a broken, dashed-looking bar, because the strip is not
## symmetrical. It is a **plain double line for 78 pixels and an ornament in the
## last 18**: a heading rule that terminates on the right, meant to be mirrored
## for the left. Dumping the pixels out and looking at them took a minute and
## would have saved the wrong version entirely.
##
## So: the line is stretched from a four-pixel slice of the plain run, and the
## terminal is drawn at 1:1 at each end — the right one as authored, the left
## one mirrored by giving the destination rect a negative width.
const RULE_TERMINAL := 18.0


static func rule(ci: CanvasItem, file: String, at: Vector2, width: float,
		col: Color) -> void:
	var t := _ornament(file)
	if t == null:
		## No file, no ornament, still a rule. Same fallback rule as the faces.
		ci.draw_rect(Rect2(at + Vector2(0.0, 6.0), Vector2(width, 2.0)), col)
		return
	var ts := t.get_size()
	var orn := minf(RULE_TERMINAL, width * 0.5)
	## Four pixels out of the plain run, stretched. Constant along x, so this is
	## lossless however wide it goes.
	ci.draw_texture_rect_region(t, Rect2(at, Vector2(width, ts.y)),
		Rect2(20.0, 0.0, 4.0, ts.y), col)
	var src := Rect2(ts.x - RULE_TERMINAL, 0.0, RULE_TERMINAL, ts.y)
	ci.draw_texture_rect_region(t,
		Rect2(at + Vector2(width - orn, 0.0), Vector2(orn, ts.y)), src, col)
	## Mirrored: a negative destination width flips it, which is cheaper than
	## authoring a second file and cannot drift out of step with the first.
	ci.draw_texture_rect_region(t,
		Rect2(at + Vector2(orn, 0.0), Vector2(-orn, ts.y)), src, col)


## A SELECTED ROW INVERTS. It does not tint.
##
## A slightly different background color is how a table highlights a row on the
## web; it is not how a machine with four colors per tile did it, and it is not
## how anything the player grew up with did it. The bar fills and the ink flips,
## and the caller draws its text in the color this hands back.
static func row(ci: CanvasItem, r: Rect2, on: bool, tint: Color = YOU) -> Color:
	if not on:
		return INK
	ci.draw_rect(r, tint)
	## AND THE CURSOR SITS IN IT. A filled bar says which row; a cursor says
	## that the row is a thing you are pointing AT rather than a thing that
	## happens to be colored. Both, because a bar alone reads as a status and
	## a cursor alone is too quiet on a dense table.
	UiIcons.draw(ci, "cursor", Vector2(r.position.x + 4.0,
		r.position.y + (r.size.y - 16.0) * 0.5), BG, 1)
	return BG


## TWO COLORS, 2x2, ON THE GRID. A real machine could not blend, so it
## dithered, and a checkerboard is legible as 8-bit in a way a flat fill never
## is. Cheap only on small rects — this is a draw call per cell, so it belongs
## on a meter track or a card ground, never on a full screen.
static func dither(ci: CanvasItem, r: Rect2, a: Color, b: Color, cell: float = 2.0) -> void:
	ci.draw_rect(r, a)
	var n := 0
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x + (cell if n % 2 == 1 else 0.0)
		while x < r.end.x:
			ci.draw_rect(Rect2(Vector2(x, y),
				Vector2(minf(cell, r.end.x - x), minf(cell, r.end.y - y))), b)
			x += cell * 2.0
		y += cell
		n += 1


## SAY YES OR NO. Every verb in this game returns "" on success and a sentence
## on refusal, so one helper covers the lot and the screens do not each have to
## remember which sound means what.
##
## THE REFUSAL IS THE IMPORTANT ONE. This game says no constantly — over the
## cap, one job a week, not entered for the cups, cannot afford it — and every
## one of those refusals used to land as a line of red text and nothing else. A
## sound and a hard little nudge make a refusal read as a RULE rather than as a
## bug, which is the entire difference between a game that is strict and a game
## that seems broken.
## A BUY BUTTON THAT CREATES UPKEEP SAYS SO (1 Oct novice report): "Build Club
## gym · 6 CC · 4/yr". `per_year` is what the thing will cost to keep a year
## once it is bought; nothing is added when it is nothing.
static func with_upkeep(label: String, per_year: int) -> String:
	return label if per_year <= 0 else UiKit.t("%s · %d CC/yr") % [label, per_year]


static func said(err: String) -> String:
	if err == "":
		Audio.play("confirm")
	else:
		Audio.play("refuse")
		Juice.refuse()
	return err


## GO SOMEWHERE, and go there behind a wipe.
##
## THE ONE PLACE A SCREEN CHANGES. There were thirty-three bare
## `get_tree().change_scene_to_file` calls in this codebase and no two screens
## had to agree on anything, which is exactly the shape of "a rule applied at
## thirty-three call sites is a rule with thirty-three holes in it". Now there
## is one, and the day somebody wants an iris instead of a wipe it is one edit.
##
## The wipe covers the screen, the scene changes BEHIND the cover, and the wipe
## comes off — 260ms end to end, which is inside the 200ms-per-transition budget
## twice over because the player only ever waits for half of it before the new
## screen is already there.
## TWO TAPS FOR ANYTHING YOU CANNOT TAKE BACK. `confirm(key)` is false the first
## time a key is asked for (and arms it) and true if the same key is asked again
## within four seconds. Changing screen, or tapping a different armed button,
## disarms it. The call site says what the first tap means in its status line.
static var _armed: String = ""
static var _armed_at: int = 0


static func confirm(key: String) -> bool:
	var now := Time.get_ticks_msec()
	if _armed == key and now - _armed_at <= 4000:
		_armed = ""
		return true
	_armed = key
	_armed_at = now
	return false


static func disarm() -> void:
	_armed = ""


static func go(path: String) -> void:
	## One screen change at a time. A second tap during the wipe restarted it and
	## pushed the trail twice.
	if Juice.wiping():
		return
	disarm()
	Audio.play("wipe")
	_push_here()
	Juice.go(path)


## WHERE BACK GOES, and until 15 Sep 2026 the answer was "wherever the screen's
## author typed", which is why Pete's playtest said *"Pressing back in any popup
## brings you all the way to the main club instead of the previous screen."*
##
## Fifteen screens each carried a literal destination. It is right for most of
## them most of the time and wrong the moment a screen has TWO ways in: the
## fighter card returns to the roster whether you opened it from the roster, the
## market's free-agent grid, or the staff room, and two of those three throw the
## player back to the clubhouse having lost their place.
##
## **A screen cannot know where it was opened from, so it must not be the thing
## that decides where Back goes.** The trail does. `go()` writes down the screen
## it is leaving; `back()` reads the last one off.
##
## THE ARGUMENT IS NOW A FALLBACK, not a destination — so every existing call
## site is still correct and still says something true: it is where this screen
## goes when nothing brought you here, which happens on a fresh load and after a
## save is opened. A deep-linked screen with an empty trail behaves exactly as it
## did yesterday.
static var _trail: PackedStringArray = PackedStringArray()

## HOW DEEP THE TRAIL GOES. Six is more than any real path through this game
## (clubhouse → squad → roster → fighter → meeting is four) and it is capped at
## all because a trail that only grows is a slow leak in a save-less object that
## lives for the whole run.
const TRAIL_MAX := 6


static func _here() -> String:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var cur := (loop as SceneTree).current_scene
		if cur != null:
			return cur.scene_file_path
	return ""


## THE LOGIC AND THE LOOKUP ARE SEPARATE FUNCTIONS, and that is not tidiness.
##
## They were one, reading `_here()` off a live `SceneTree` — so the only way to
## exercise the trail was to change scenes for real, which a headless check
## cannot do. `test_nav.gd`'s first cut worked around it by appending to the
## array itself, and in doing so walked straight past the cap: it reported a
## depth of 30 against a cap of 6 and was right, because the capping code had
## never been on the path it was driving. **A rule enforced in a function
## nothing can call is a rule nothing is checking.**
static func _push(path: String) -> void:
	if path == "":
		return
	## NO IMMEDIATE REPEAT. A screen that reloads itself — the season screen
	## does, on a tab change — must not stack six copies of itself and make Back
	## take six presses to leave.
	if _trail.size() > 0 and _trail[_trail.size() - 1] == path:
		return
	_trail.append(path)
	while _trail.size() > TRAIL_MAX:
		_trail.remove_at(0)


static func _push_here() -> void:
	_push(_here())


## THE WAY BACK, which is a different sound from the way forward. `back` is
## `tap` transposed down a fifth — the same sound, the other direction, which is
## a thing a player understands the first time he hears it without being told.
static func back(fallback: String) -> void:
	if Juice.wiping():
		return
	disarm()
	Audio.play("back")
	var to := fallback
	if _trail.size() > 0:
		to = _trail[_trail.size() - 1]
		_trail.remove_at(_trail.size() - 1)
		## A TRAIL POINTING AT THE SCREEN YOU ARE ON is a Back button that does
		## nothing. It cannot happen through `go()` — which pushes before the
		## change — but it can through a scene loaded any other way, and a dead
		## Back button is the worst possible outcome of a fix for Back buttons.
		if to == _here():
			to = fallback
	Juice.go(to)


## THE TRAIL IS CUT WHEN A CAREER OPENS OR CLOSES. Going back into the title
## screen from inside a club, or into a club from the title, is not a step in a
## path — it is a different session, and a trail that survives it would send Back
## from the front door into somebody's half-finished season.
static func trail_reset() -> void:
	_trail.clear()


## GO SOMEWHERE WHOSE BACK IS NOT HERE. The fight report sends the player to a
## fighter's card; Back from that card must land in the clubhouse, never in the
## finished bout (which would start it again).
static func go_back_to(path: String, back_to: String) -> void:
	if Juice.wiping():
		return
	disarm()
	Audio.play("wipe")
	_trail.clear()
	_trail.append(back_to)
	Juice.go(path)


## For the suite: how deep the trail is, without handing out the trail itself.
static func trail_depth() -> int:
	return _trail.size()


## Clip a name so it stops before the numbers do. A long club or fighter name
## running into a column reads as broken rather than as long.
static func clip(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, n - 1) + "."


## CLIP BY PIXELS, NOT BY CHARACTERS.
##
## `clip()` above cuts at a character count, which is the right tool for a
## monospaced face and meaningless for a proportional one — "Wexley" and
## "MMMMMM" are the same six characters and forty pixels apart. The team sheet
## clipped names at 13 characters into a 138-pixel column, so most names fitted
## and a wide one walked into the POSITION column. Same shape of mistake as the
## font that advanced every glyph the full cell.
##
## This measures. It takes the width it is allowed and hands back the longest
## prefix that fits inside it, ellipsis included.
##
## THE COMMENT ABOVE WAS HERE AND THE FUNCTION WAS NOT — for how long, nothing
## records; it ran straight into `wrap`'s own note, and a doc block with no
## function under it reads as a function until you look. Found on 15 Sep 2026 by
## the panel sweep, which caught "Detroit Free Company" seven pixels outside its
## save-slot card on the title screen: twenty characters, clipped at twenty
## characters, into a three-hundred-pixel box. The exact mistake this missing
## function was written to prevent, described in its own absent docstring.
## A CLUB'S NAME IN THE ROOM THERE IS, never cut mid-word (review, 1 Oct 2026:
## "Oklahoma City Free Compa."). Whole words come off the end; if one word still
## does not fit, the short name.
static func fit_name(font: Font, full: String, short: String, px: int, width: float) -> String:
	var w := func(s: String) -> float: return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	if float(w.call(full)) <= width:
		return full
	var words := full.split(" ")
	while words.size() > 1:
		words.remove_at(words.size() - 1)
		var cut := " ".join(words)
		if float(w.call(cut)) <= width:
			return cut
	return short if short != "" and float(w.call(short)) <= width else clip_px(font, full, px, width)


static func clip_px(font: Font, s: String, px: int, width: float) -> String:
	if width <= 0.0:
		return ""
	if font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x <= width:
		return s
	## Trim a character at a time from the end. Strings on this screen are names
	## and labels — tens of characters, not thousands — so a measured walk is
	## cheaper to read than a bisection and costs nothing anybody can feel.
	var out := s
	while out.length() > 1:
		out = out.substr(0, out.length() - 1)
		if font.get_string_size(out + ".", HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x <= width:
			return out + "."
	return "."


## WRAP TO A WIDTH, RETURNING THE LINES — not a string with newlines in it, and
## not a truncation.
##
## The HTML mock learned this one the expensive way: its first version measured
## words into a fixed box and DISCARDED the overflow, so half the report's cards
## showed half a message. Pete's words, 13 Sep 2026: *"a lot of the notifications
## either missing half the message"*. A caller that gets the lines back can size
## its card to them, or take the first two and know it is taking the first two.
static func wrap(font: Font, s: String, width: float, px: int) -> Array[String]:
	## THE SAME FLOOR THE DRAW USES (29 Sep 2026). Callers asked to wrap at 9 or
	## 10 px and `raw`/`text` then drew at MIN_PX 11, so every wrapped line was
	## wider than the width it was wrapped to and lost its tail ("That is t
	## winter" in the fight report). Wrap at the size it will actually be drawn.
	px = maxi(px, MIN_PX)
	var out: Array[String] = []
	var line := ""
	for w in s.split(" "):
		var t: String = w if line == "" else line + " " + w
		if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x <= width:
			line = t
			continue
		if line != "":
			out.append(line)
			line = ""
		## A "WORD" WIDER THAN THE LINE (29 Sep 2026). Japanese writes a whole
		## sentence without a space, so splitting on spaces handed the drawer
		## one unbreakable word and it ran off the panel. It breaks between
		## characters instead — which is also where Japanese breaks.
		for ch in w:
			var t2: String = line + ch
			if line != "" and font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT,
					-1.0, px).x > width:
				out.append(line)
				line = ch
			else:
				line = t2
	if line != "":
		out.append(line)
	return out


static func fit(font: Font, s: String, px: int, width: float) -> String:
	if font == null or s == "":
		return s
	if font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x <= width:
		return s
	var dot := "."
	var n := s.length()
	while n > 1:
		n -= 1
		var t := s.substr(0, n) + dot
		if font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x <= width:
			return t
	return dot


static func ordinal(n: int) -> String:
	if n <= 0:
		return "—"
	## Each English suffix is a key, so a language words its own: "%d." in
	## German, "%dº" in Spanish, "%der" / "%de" in French.
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: return UiKit.t("%dst") % n
			2: return UiKit.t("%dnd") % n
			3: return UiKit.t("%drd") % n
	return UiKit.t("%dth") % n


## A club's badge — the same mark the melee puts on a surcoat, so a club is
## recognisable on the table before you ever fight it.
##
## The mark itself lives in IconBank, not here. It used to be a match statement
## in this file and a second, slightly different one in the melee's banner code,
## which is how a club could wear one mark on the table and another on the
## surcoat. One function, called by both.
##
## `quality` is how well it is PAINTED, 0 to 1, and it comes from the arena.
## Pete, 10 Sep 2026: *"each upgrade making the logo go from really shitty
## quality to NFL level details."* Everywhere that draws a club at its own ground
## passes the arena's number; everywhere else leaves it at 1, because a rival's
## badge on a league table is not a progression bar.
static func badge(ci: CanvasItem, at: Vector2, r: float,
		kit: Color, mark: Color, icon: int, quality: float = 1.0) -> void:
	IconBank.draw_badge(ci, at, r, kit, mark, icon, quality)
	ci.draw_rect(Rect2(at - Vector2(r, r), Vector2(r * 2, r * 2)), FRAME, false, 2.0)
