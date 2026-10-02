extends Node2D
## The melee screen. Draw a path, he goes and does it, the AI takes him back.
##
## [C-5] BROADCAST CAMERA. The whole list, always. This design never wants to go
## over-the-shoulder — you are directing a line, so the constraint and the
## camera finally agree instead of pulling against each other.
##
## Drawn with primitives on purpose. A fighter is a silhouette, a two-color
## surcoat and a mark, because that is what a club badge is engineered to be.
## Sprites drop in later without touching layout, contrast or reading distance.

## LANDSCAPE, 960x540. The list sits left and the roster strip stands up the
## right-hand side, which is the layout the sport wanted all along: a line of
## five is a horizontal thing, and in portrait the camera was always fighting it.
##
## The SIM's list is Tuning.LIST_W x LIST_H (300 x 570 today), drawn rotated so
## its long axis is the screen's width. Changing its shape is a sim change with a
## re-measure attached, not a layout one.
const SCREEN := Vector2(960.0, 540.0)
## Drawn rotated (see _to_screen), so the list is LIST_H wide and LIST_W tall on
## screen. The fighter cards sit in a row along the bottom, which is where the
## width is and where a thumb already is.
## Scaled to the height between the HUD and the card row, and centerd. At 570
## along the charge the list is 701 wide, which leaves about 130 either side —
## and that is deliberate rather than left over. Pete, 10 Sep 2026: *"On the
## sides we can have either team banners or something."* The two clubs stand
## there, which is where a fight's two sides belong.
const LIST_SCALE := 1.23
const LIST_ORIGIN := Vector2(
	(960.0 - Tuning.LIST_H * LIST_SCALE) * 0.5,   ## rotated: LIST_H is the width
	58.0)
const BANNER_W := 106.0
const BANNER_TOP := 58.0

const COL_INK := Color("e8e4d8")
const COL_DIM := Color("a59c8b")
const COL_PANEL := Color("241f1a")
const COL_EDGE := Color("3d352b")
const COL_HOT := Color("e05a3c")
const COL_GOOD := Color("6fbf5e")

## The roster strip: a row along the bottom, one card per man.
const STRIP_X := 24.0
const STRIP_Y := 436.0
const CARD_W := 178.0
const CARD_H := 84.0
const CARD_GAP := 6.0

## ------------------------------------------------------ the corner's controls
## TWO BUTTONS OVER THE GROUND, in the two corners of the list nobody fights in.
##
## The fight screen has no spare band: the top fifty-six pixels are the clock and
## the read-outs, the sides are the two banners all the way down, and the bottom
## eighty-four are the card strip. There is nowhere to PUT a control bar, which is
## how Retro Bowl ends up floating its own skip button over the field rather than
## docking it — and that is the answer here too. They sit low, where the men
## rarely are, and they are the only things on this screen that eat a click
## before `_unhandled_input` sees it.
##
## MOVED TO THE TOP BAR (Pete, 29 Sep 2026, #3 (b)): "HOLD and SKIP ROUND go in
## the top bar beside the clock." Over the ground they sat on lane 5 and covered
## the men fighting there; the clock row has the room either side of the clock.
const CALL_SIZE := Vector2(150.0, 36.0)
const CALL_AT := Vector2(SCREEN.x * 0.5 - 76.0 - 150.0, 4.0)
const SKIP_AT := Vector2(SCREEN.x * 0.5 + 76.0, 4.0)

## HOW LONG A CALL LASTS. Six seconds, or until you have given one order —
## whichever comes first.
##
## The alternative was charging the round clock, which is a two-line change since
## `round_t` is tick-driven. It is the wrong currency: a player cannot see what
## four seconds of a hundred and twenty is worth while he is deciding, so the
## cost would land as a mystery rather than as a trade. "One call, one order" is
## a rule you can hold in your head, and it is self-limiting without arithmetic.
const CALL_WINDOW: float = 6.0

enum Screen { SPLASH, PREFIGHT, FIGHT, CORNER, REPORT }

var sim: MeleeSim
var screen: int = Screen.PREFIGHT
## THE APP WENT AWAY (home button, a call, alt-tab). The fight and the corner
## clock stop until it comes back; nothing is owed on return.
var paused: bool = false
var font: Font
var accum := 0.0
var marshal_text := ""
var marshal_t := 0.0

## live drawing state
var drawing := -1
var draw_path: Array[Vector2] = []
var draw_screen: PackedVector2Array = PackedVector2Array()
var hover_enemy := -1
## THE CONTACT WHEEL (Pete, 29 Sep 2026). The man whose question is up, or -1;
## and where a drag toward an option began, for "circle command" release.
var wheel_man := -1
## THE ONE-TIME COACH MARK on screen, "" for none (Pete, 29 Sep 2026, #5). While
## one is up the fight and the corner clock both wait.
var tip := ""
var tip_layer: CanvasLayer = null
var wheel_drag := false
## SPRINT: seconds the drawing finger has rested, and whether it has rested long
## enough on the endpoint to make this route a run.
var draw_rest := 0.0
var draw_run := false

var ui: CanvasLayer
var panel_box: VBoxContainer
var panel_title: Label
## ---------------------------------------------------------------- the report
## THE MOCK'S LAYOUT — Pete, 14 Sep 2026: *"go with the one we mocked up that
## showed 'After the bout'. That one looked WAY better. At least use the layout
## or format and you can put in the playoff picture or standings and notable
## items."*
##
## Two `RichTextLabel`s of prose went in an hour before this and he is right: a
## bout produces a TABLE — six men, seven figures each — and prose is the wrong
## container for a table. The mock had it laid out on the afternoon it was drawn
## and the engine never got it, which is the same failure as the playbook's
## column headings two passes ago. **A mock everybody signed off is not a
## feature.**
##
## Three regions, on the mock's own numbers:
##   THE AFTERNOON      the men, one row each, right-aligned columns
##   THE CHANGING ROOM  what they think, in their own words, scrolling
##   AFTER ACTION       the club and the men, as cards, scrolling
const REP_PANEL := Rect2(24.0, 18.0, 912.0, 504.0)
const REP_LX := 46.0
const REP_LW := 556.0
const REP_RX := 626.0
const REP_RW := 286.0
## Right-aligned stops for the table, from `REP_LX`.
##
## THE MOCK'S OWN NOTE WARNED ABOUT THIS AND THE MOCK STILL HAD IT. It records
## that the first cut printed "AT HIS CEILING" back through the XP figure, and
## concludes that every cell must be a short token — then leaves `lv` at 530 and
## `next` at 556, which is **36 pixels** for a cell whose widest token is
## "LEVEL UP". Ported straight across, the header row read `LVLNEXT` and the
## LEVEL UP ran back through the level number.
##
## A warning written next to the numbers that cause it is not a fix. Every column
## below is the width of the widest thing it can hold: NEXT gets 90 for
## "LEVEL UP", XP gets 58 for "+12", and the three counters get 36 for a digit.
const REP_COL := {"dn": 260.0, "as": 300.0, "up": 336.0, "off": 372.0,
	"xp": 430.0, "lv": 466.0, "next": 556.0}
const REP_ROW_Y := 154.0
const REP_ROW_H := 25.0
const QUIP_TOP := 120.0
const QUIP_H := 182.0
const NEWS_TOP := 344.0
const NEWS_H := 124.0
const NEWS_COLS := 3
const NEWS_CARD := Vector2(276.0, 54.0)
const NEWS_STEP := Vector2(288.0, 62.0)

## How far each of the two panes is scrolled, in pixels. Wheel-driven; clamped
## against the content every time it is drawn, so a pane that shrinks between
## bouts cannot be left scrolled past its own end.
var quip_scroll: float = 0.0
var news_scroll: float = 0.0
var quip_over: float = 0.0
var news_over: float = 0.0
var again_button: Button
## Which round's corner has already been answered. Without this the corner
## re-opened the frame after you picked — _process saw the sim still in its
## corner phase and put the panel straight back up — and because the sim only
## ticked while the fight screen was showing, the corner timer never counted
## down. The bout deadlocked between rounds one and two, forever.
var corner_done_for_round: int = -1

## ------------------------------------------------------------ calls and skips
var calls_total: int = Grade.PAUSES_BASE
var calls_left: int = Grade.PAUSES_BASE
var held := false
var hold_t := 0.0
## What `orders_issued + prompts_answered` read when the hold started. A call ends
## the moment that number moves, which is what makes it one call, one order.
var hold_mark: int = 0
var call_button: Button
var skip_button: Button

## ------------------------------------------------------------------ the book
## THE SHAPE THE CLUBHOUSE DREW, kept aside for the whole bout.
##
## `Season.begin_bout` hands the sim the Chalkboard's shape as `custom_spots[0]`,
## and `formation_spots` returns custom spots over a named formation whenever it
## has them. So the moment the playbook offers "2-1-2" as a thing you can tap,
## picking it has to CLEAR the drawn shape or the fight quietly keeps running the
## drawn one — the exact ordering trap `set_plan` has a paragraph about. And once
## it is cleared it is gone, so the drawn shape would be a one-way door: pick a
## named formation in round one and your own board is unreachable for the rest of
## the afternoon.
##
## It is stashed here instead, and it is a row in the book like any other.
## WHICH DRAWN SHAPE THE MEN ARE STANDING IN, or -1 for a built-in one.
##
## It was the spots array itself, stashed so that picking a named formation could
## not make the Chalkboard's shape unreachable for the rest of the bout. The book
## reads the whole shape list off the Chalkboard now, so the shape is never lost
## — but the sim only records `custom_spots`, which cannot say WHICH drawn shape
## it is, and the card that should be lit is the one whose id matches. So the id
## is what is kept.
var drawn_shape_id: int = -1


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	_build_ui()
	_fit_width()
	_new_bout(randi())


func _new_bout(seed_value: int) -> void:
	## A bout handed over by the season screen, or the exhibition fixtures if
	## nobody handed one over — which is what running Melee.tscn directly still
	## does, and what this screen did before there was a season at all.
	## The occasion the season screen handed over with the bout — the palette and
	## the music both. `fighting` is what makes an ordinary league bout sound
	## different from the clubhouse it was started from; a cup tie keeps its own
	## arrangement, because the occasion outranks the fact that it is a fight.
	UiKit.set_mood(Session.bout_mood)
	Audio.for_mood(Session.bout_mood, true)
	if Session.bout != null:
		sim = Session.bout
	else:
		sim = MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), seed_value)
	corner_done_for_round = -1
	## THE BUDGET COMES OFF THE GRADE, and off the career rather than the machine.
	## A standalone Melee.tscn has no season, so it fights at the default — which
	## is SANCTIONED, two calls, exactly what this screen did before there was a
	## grade at all.
	var g := Session.season.grade if Session.season != null else Grade.DEFAULT
	var st := Session.season.matched_step if Session.season != null else Grade.STEP_START
	var cg: Dictionary = Session.season.custom_grade if Session.season != null else {}
	calls_total = Grade.pauses_for(g, st, _call_bonus(), cg)
	calls_left = calls_total
	held = false
	hold_t = 0.0
	sim.marshal_called.connect(func(t):
		marshal_text = t
		marshal_t = 1.6
		Audio.play("whistle"))
	## A MAN GOING DOWN is the biggest thing that happens in this game and it had
	## no sound at all. Taken off the sim's own signal rather than polled, so it
	## fires exactly as often as it actually happens.
	##
	## AND IT IS THREE SIZES, because an ordinary down and the one that ends the
	## bout are not the same event wearing different numbers. The whole side
	## flattened is a knockout and gets the works — a third of a second of
	## freeze, a hard shake and two frames of white. One man out of eight is a
	## nudge. `Juice.down` plays the sound itself, so there is one call here and
	## not a sound call that somebody later forgets to keep in step.
	sim.fighter_downed.connect(_on_downed)
	sim.action_resolved.connect(func(i, a, _t, ok):
		if ok and not skipping:
			Audio.play("clash")
		_on_call_resolved(i, a, ok))
	sim.bout_finished.connect(_on_bout_finished)
	screen = Screen.PREFIGHT
	accum = 0.0
	marshal_text = ""
	## THE PANEL ONLY ASKS WHEN THE ANSWER CAN BE USED.
	##
	## In a season bout `Season.begin_bout` has already called `set_plan(0, …)`
	## with the shape drawn on the Chalkboard, and `formation_spots` returns
	## `custom_spots` whenever it is set — so whatever the player tapped here was
	## thrown away, every single time. The game asked a question, ignored the
	## answer, and then printed the shape it was NOT using on the HUD.
	##
	## The clubhouse is where a shape is chosen. This panel belongs to the
	## standalone bout, where nothing has chosen one.
	## THE BOOK COMES UP EVERY BOUT NOW, season or standalone.
	##
	## This used to skip the panel entirely whenever the clubhouse had already set
	## a shape, on the reasoning that the question had been answered upstairs. The
	## question it was asking was "how are we coming out", and that IS answered
	## upstairs. The playbook asks a different one — what are we running, right
	## now — and the answer to that is not a property of the club, it is a
	## property of the next ninety seconds. Pete, 13 Sep 2026: *"Think Madden."*
	## You call a play before the snap whether or not you wrote the playbook.
	## WHICH SHAPE THE CLUBHOUSE SENT. `Season.begin_bout` hands over the spots
	## for `formation_id`, and that id is the one the book has to light up.
	drawn_shape_id = -1
	if Session.season != null and sim.custom_spots[0] != null:
		var fid := int(Session.season.formation_id)
		if not Tuning.FORMATIONS.has(fid):
			drawn_shape_id = fid
	book_shape = 0
	for i in _book_shapes().size():
		if int(_book_shapes()[i]["id"]) == _live_shape_id():
			book_shape = i
			break
	## AND THE FIRST SCREEN IS THE CORNER — Pete, 13 Sep 2026: *"Let's make
	## 'After a round' be the 'Before first round' screen too."* It used to open
	## straight into the book, which asked the player to call a play before he
	## had been shown a single thing about the men who would run it. The corner
	## puts the line in front of him and keeps the book one tap away.
	chosen_shape = {}
	chosen_call = {}
	## THE SPLASH FIRST. Pete, 14 Sep 2026: *"We'll have to make them as splash
	## screens with the logos, team names, Win/Losses, etc. on them."* It is the
	## walk-out, and it is the only place in the game that says where you are.
	_show_splash()


# ------------------------------------------------------------------ the loop
## THE 960-WIDE FIGHT, CENTRED ON WHATEVER CANVAS THE PHONE HANDS US.
##
## The project stretches with aspect "expand", so a 20:9 phone gives a canvas
## about 1200 wide. Everything on this screen is laid out on the 960x540 design
## frame; it was drawn from x=0 and the right ~240px was bare. The frame is now
## centred — the node and its control layer are shifted by `off_x`, the gutters
## are painted with the ground, and input is mapped back into the frame.
var off_x: float = 0.0
var off_y: float = 0.0
var _quips_cache: Array = []
var _news_cache: Array = []


func _fit_width() -> void:
	var want := floorf(maxf(0.0, UiKit.screen().x - SCREEN.x) * 0.5)
	## AND THE HEIGHT (29 Sep 2026). A 4:3 tablet hands us 960x720, and the
	## frame sat at the top with 180 pixels of bare grey under the cards.
	var want_y := floorf(maxf(0.0, UiKit.screen().y - SCREEN.y) * 0.5)
	if is_equal_approx(want, off_x) and is_equal_approx(want_y, off_y) \
			and position == Vector2(off_x, off_y):
		return
	off_x = want
	off_y = want_y
	position = Vector2(off_x, off_y)
	if ui != null:
		ui.offset = Vector2(off_x, off_y)


func _process(delta: float) -> void:
	_fit_width()
	marshal_t = maxf(0.0, marshal_t - delta)
	for k in call_words.keys():
		call_words[k]["t"] = float(call_words[k]["t"]) - delta
		if float(call_words[k]["t"]) <= 0.0 or screen != Screen.FIGHT:
			call_words.erase(k)
	## THE THREE THAT DO NOT TICK. The splash joins the report and the pre-fight
	## panel: the sim must not advance behind a screen the player has not
	## answered, and the corner branch below would otherwise drag him straight
	## out of the walk-out.
	if screen == Screen.REPORT or screen == Screen.PREFIGHT \
			or screen == Screen.SPLASH:
		## AND THE BUTTONS STILL GET ASKED. This returned first, which put the
		## one function that decides whether CALL and SKIP ROUND exist behind a
		## guard that skipped it on exactly the three screens it was written to
		## protect — so the two controls kept whatever visibility the last frame
		## of the fight left them with, and SKIP ROUND sat on top of the
		## after-action report with a clock on it.
		##
		## `_sync_controls`'s own docstring said *"two call sites deciding a
		## control's visibility is how a button ends up live on the report
		## screen."* It was right. It was also unreachable from the report
		## screen, which is worse than two call sites: it is one call site in the
		## wrong place. Pete found it playing the game — #11 of 26, 15 Sep 2026.
		_sync_controls()
		queue_redraw()
		return

	var in_corner: bool = sim.phase == MeleeSim.Phase.CORNER
	if in_corner and screen != Screen.CORNER and corner_done_for_round != sim.round_no:
		screen = Screen.CORNER
		_show_strategy_panel()
	elif not in_corner and screen == Screen.CORNER:
		screen = Screen.FIGHT
		_hide_panel()

	## HIT PAUSE. The sim stops; the screen does not. Two lines, and the single
	## largest perceived-impact gain available — every fighting game since
	## Street Fighter II does this and almost no management game does.
	##
	## It gates the ACCUMULATOR and not the frame, which matters: `accum` keeps
	## whatever it had, so the ticks that were owed are still owed when the
	## freeze lifts and the bout does not quietly lose 80ms of fighting. A
	## freeze that dropped ticks would be a difficulty setting pretending to be
	## a flourish.
	## THE HOLD GATES THE SAME ACCUMULATOR THE HIT-PAUSE DOES, and for the same
	## reason: `accum` keeps whatever it had, so the ticks that were owed are
	## still owed when the fight restarts and nothing is quietly lost. A hold
	## that dropped ticks would be a difficulty setting pretending to be a
	## control.
	if held and not paused:
		hold_t -= delta
		if hold_t <= 0.0 or sim.orders_issued + sim.prompts_answered > hold_mark:
			_release_hold()
	## THE CORNER CLOCK. The sim only ticks on the FIGHT screen, so `corner_t`
	## never moved and the grade's corner time (24 s vs 16 s) did nothing — the
	## corner waited forever. It runs here, on real time, and when it is out the
	## men go back in on whatever was last chosen (or the push they were on).
	_maybe_tip()
	if screen == Screen.CORNER and sim.phase == MeleeSim.Phase.CORNER and not paused and tip == "":
		sim.corner_t -= delta
		if sim.corner_t <= 0.0:
			_corner_time_up()
	## THE WHEEL FREEZES THE FIGHT like the hold does — the accumulator is gated,
	## not emptied, so no fighting is lost while the player chooses.
	wheel_man = _wheel_candidate()
	if drawing != -1 and not draw_screen.is_empty():
		draw_rest += delta
		if draw_rest >= Tuning.SPRINT_HOLD and Tuning.sprint > 1.0:
			draw_run = true
	if skipping and not paused:
		_skip_slice()
	elif screen == Screen.FIGHT and not Juice.frozen() and not held and not paused and wheel_man == -1 \
			and tip == "":
		## NO CATCH-UP AFTER A STALL. A hitch or an app resume handed the loop a
		## huge delta, and the fight fast-forwarded until it caught up.
		accum = minf(accum + delta, 0.25)
		var guard := 8
		while accum >= Tuning.TICK and guard > 0 and not sim.is_over():
			accum -= Tuning.TICK
			guard -= 1
			sim.tick()
	_sync_controls()
	queue_redraw()


# ------------------------------------------------------- calls and the skip
## WHAT THE STAFF ADDS. Read through the office so the trait and the budget meet
## in one place rather than the screen knowing what a Tactician is.
func _call_bonus() -> int:
	if Session.season == null:
		return 0
	return Session.season.office.extra_calls()


## STOP THE FIGHT AND THINK. One order, or six seconds.
func _hold() -> void:
	if held or calls_left <= 0 or screen != Screen.FIGHT or sim.is_over():
		return
	held = true
	calls_left -= 1
	hold_t = CALL_WINDOW
	hold_mark = sim.orders_issued + sim.prompts_answered
	Audio.play("whistle")
	queue_redraw()


func _release_hold() -> void:
	held = false
	hold_t = 0.0
	queue_redraw()


## SKIP THE REST OF THE ROUND — Retro Bowl's `btn_skip_time`, which sets its flag
## and then DESTROYS ITS OWN BUTTON so it cannot be pressed twice while a skip is
## running. Ours does not need a flag or a destroy: `MeleeSim.skip_round` returns
## with the sim in CORNER or OVER, and `_sync_controls` only shows this button
## during a live round — so the button takes itself off the screen by the same
## rule that put it there, and comes back when the next round starts.
##
## `accum` is cleared because the owed ticks were just spent. Carrying them over
## would run the first fraction of a second of the NEXT round the instant it
## began, which is the one place in this game where losing a tick is correct.
func _skip_round() -> void:
	if screen != Screen.FIGHT or sim.is_over():
		return
	_release_hold()
	## QUIET WHILE IT RUNS. A skipped round played every down's freeze, shake and
	## sound and every clash in the same frame — a wall of noise for a button
	## that means "I don't need to watch this". One knock at the end instead.
	##
	## AND SPREAD OVER FRAMES. A round is 120 s at 30 ticks a second, and running
	## all of it in the frame the button was pressed froze the screen for half a
	## second on a desktop (tools/probe_perf.gd: 210–290 us a tick on this 2-core
	## box, 29 Sep 2026; the audit measured 400–580 under load) and for seconds
	## on a phone. `_process` now runs it in slices of SKIP_BUDGET_US, so it
	## plays as a fast-forward. The same ticks in the same order: the bout comes
	## out identical, which `tools/probe_fingerprint.gd` holds.
	if skipping:
		return
	skipping = true
	skip_round_no = sim.round_no
	skip_downs = sim.downs[0] + sim.downs[1]
	accum = 0.0
	queue_redraw()


## One slice of a skip. Runs until the round ends or the frame's budget is spent.
func _skip_slice() -> void:
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < SKIP_BUDGET_US and not sim.is_over() \
			and sim.phase != MeleeSim.Phase.CORNER and sim.round_no == skip_round_no:
		sim.tick()
	if sim.is_over() or sim.phase == MeleeSim.Phase.CORNER or sim.round_no != skip_round_no:
		skipping = false
		if sim.downs[0] + sim.downs[1] > skip_downs:
			Audio.play("clash")
		accum = 0.0


const SKIP_BUDGET_US := 10000
var skip_round_no: int = -1
var skip_downs: int = 0


## THE ONE PLACE THE TWO BUTTONS DECIDE WHETHER THEY EXIST. Two call sites
## deciding a control's visibility is how a button ends up live on the report
## screen.
func _sync_controls() -> void:
	if call_button == null or skip_button == null:
		return
	var live: bool = screen == Screen.FIGHT and not sim.is_over() \
		and sim.phase != MeleeSim.Phase.CORNER and not skipping
	## Not while the wheel is up: the fight is frozen and the ring needs the
	## bottom of the list the two buttons sit over.
	call_button.visible = live and not held and calls_left > 0 and wheel_man == -1
	skip_button.visible = live and not held and wheel_man == -1


## THE THREE SIZES OF A MAN GOING DOWN.
##
## Read off the sim rather than counted here, because a count kept in the scene
## is a count that goes wrong the first time somebody reloads a bout mid-fight —
## and this game reloads bouts mid-fight.
var skipping: bool = false


## WHAT A WHEEL CALL CAME TO, over the man who made it (1 Oct novice report,
## Pete approved): first-timers picked a side of the wheel and could not tell
## whether it had worked. A word for about a second — DOWN!, held, missed,
## free, hit — and only for a call the player picked (`acting_for_player`), so
## the nine men nobody sent stay quiet. A later resolve in the same moment (the
## chosen act after its free swing) replaces the earlier word.
const CALL_WORD_S := 1.0
var call_words: Dictionary = {}


static func call_word(act: int, ok: bool) -> String:
	match act:
		Tuning.Act.BULLRUSH, Tuning.Act.TAKEDOWN:
			return UiKit.t("DOWN!") if ok else UiKit.t("missed")
		Tuning.Act.GRAPPLE, Tuning.Act.HOLD:
			return UiKit.t("held") if ok else UiKit.t("missed")
		Tuning.Act.ESCAPE, Tuning.Act.BREAK:
			return UiKit.t("free") if ok else UiKit.t("missed")
		Tuning.Act.HIT:
			return UiKit.t("hit") if ok else UiKit.t("missed")
	return ""


static func call_word_color(act: int, ok: bool) -> Color:
	if not ok:
		return UiKit.DOWN
	if act == Tuning.Act.BULLRUSH or act == Tuning.Act.TAKEDOWN:
		return UiKit.YOU
	return UiKit.UP if act == Tuning.Act.ESCAPE or act == Tuning.Act.BREAK else UiKit.INK


func _on_call_resolved(idx: int, act: int, ok: bool) -> void:
	if skipping or idx < 0 or idx >= sim.men.size() or not sim.men[idx].acting_for_player:
		return
	call_words[idx] = {"text": call_word(act, ok), "col": call_word_color(act, ok), "t": CALL_WORD_S}


func _draw_call_words() -> void:
	for idx in call_words.keys():
		var w: Dictionary = call_words[idx]
		var at := _to_screen(sim.men[int(idx)].pos) + Vector2(-60.0, -30.0)
		UiKit.raw(self, font, at, String(w["text"]), HORIZONTAL_ALIGNMENT_CENTER, 120, 16, w["col"])


func _on_downed(idx: int, _by: int) -> void:
	if skipping:
		return
	var team: int = sim.men[idx].team
	var left := sim.standing_count(team)
	Juice.down(left <= 1, left <= 0)
	## The number that lands. Over the fallen man, in his side's color, so the
	## player reads WHO as well as WHAT without looking at the HUD.
	var col: Color = UiKit.DOWN if team == 0 else UiKit.UP
	## Popped in SCREEN space, not sim space. The popup layer lives above the
	## whole game and does not know this screen has a camera; handing it a sim
	## coordinate would put "DOWN" in the top-left corner of the world.
	Juice.pop("down%d" % idx, "DOWN",
		_to_screen(sim.men[idx].pos) + Vector2(off_x, off_y - 16.0), col)


func _on_bout_finished(_w: int) -> void:
	## THE HOUSE, when the bout is yours. `crowd` was in the catalog with nothing
	## calling it; a win is the one moment the whole game agrees it belongs to.
	if _w == 0:
		Audio.play("crowd")
	## Post it to the table before anything is drawn, so the season screen is
	## already correct by the time the player gets back to it.
	if Session.in_season():
		if Session.bout_is_cup:
			Session.season.post_cup_bout(sim)
		else:
			Session.season.post_bout(sim)
		Session.clear_bout()
		Session.autosave()
		again_button.text = UiKit.t("Back to the club")
		_add_spend_button()
	_quips_cache = []
	_news_cache = []
	screen = Screen.REPORT
	_hide_panel()
	quip_scroll = 0.0
	news_scroll = 0.0
	## AND THE ABSOLUTELY-POSITIONED CONTROLS GO WITH IT. `_hide_panel` only hides
	## `panel_box`; the splash's button and the corner's live on `ui` directly, so
	## the report drew over a still-pressable "OUT INTO THEIR HOUSE". Caught by
	## `test_layout.gd` the first time the sweep drove this page after the splash
	## existed — a live control under a screen, again, which is the second time
	## this scene has done it in three passes.
	_clear_corner()
	## And nothing still rising off the fight. Same call the corner makes, and for
	## the same reason: a "DOWN" from the last round drawn across the report of
	## that round is the fight arguing with its own summary.
	Juice.clear_pops()
	again_button.visible = true


# ------------------------------------------------------------------- input
## THE WHEEL, OVER EITHER PANE. Two scrolling regions on one drawn screen, and
## which one moves is decided by where the pointer is — the same way it is
## decided in every other application, and the only way that needs no extra
## control on a screen that already has one.
func _report_wheel(at: Vector2, up: bool) -> bool:
	return _report_scroll(at, 24.0 * (-1.0 if up else 1.0))


## Scroll whichever report pane is under `at` by `step` pixels. The wheel and a
## finger drag both come here — the panes only answered the wheel, so on a phone
## the "more v" content could never be reached.
func _report_scroll(at: Vector2, step: float) -> bool:
	if screen != Screen.REPORT:
		return false
	if Rect2(REP_RX, QUIP_TOP, REP_RW, QUIP_H).has_point(at):
		quip_scroll = clampf(quip_scroll + step, 0.0, quip_over)
		queue_redraw()
		return true
	if Rect2(REP_LX, NEWS_TOP, 936.0 - REP_LX - 14.0, NEWS_H).has_point(at):
		news_scroll = clampf(news_scroll + step, 0.0, news_over)
		queue_redraw()
		return true
	return false


## THE FINGER THAT IS DRAWING, by touch index. A second finger used to call
## `_press` and hijack the route; lifting the first then gave the second man a
## route ending where the first finger left. Only this finger draws now.
var draw_finger: int = -1


func _unhandled_input(event: InputEvent) -> void:
	## Into the design frame (see `_fit_width`).
	event = make_input_local(event)
	## PAUSED: the next tap resumes, and does nothing else.
	if paused:
		if (event is InputEventScreenTouch and event.pressed) \
				or (event is InputEventMouseButton and event.pressed):
			_set_paused(false)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP \
				or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _report_wheel(mb.position,
					mb.button_index == MOUSE_BUTTON_WHEEL_UP):
				return
	if screen == Screen.REPORT and event is InputEventScreenDrag:
		_report_scroll(event.position, -(event as InputEventScreenDrag).relative.y)
		return
	if screen != Screen.FIGHT:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if drawing != -1:
				return
			draw_finger = st.index
			_press(st.position)
		elif st.index == draw_finger:
			draw_finger = -1
			## A CANCELLED TOUCH IS NOT A RELEASE. The OS taking the gesture away
			## (a notification shade, a palm) must not issue an order.
			if st.canceled:
				drawing = -1
				hover_enemy = -1
				draw_screen.clear()
				return
			_release(st.position)
	elif event is InputEventScreenDrag and wheel_drag and wheel_man != -1:
		## THE SIDE UNDER THE THUMB lights while the drag is on.
		var hot := _wheel_option_at(sim.men[wheel_man], event.position, true)
		if hot != wheel_hot:
			wheel_hot = hot
			queue_redraw()
	elif event is InputEventScreenDrag and drawing != -1 \
			and (event as InputEventScreenDrag).index == draw_finger:
		_extend(event.position)


## BACK, from the app's one back handler (AppLife). In a fight it pauses — it
## used to quit the whole app. On the report it is the report's own way out.
func go_back() -> bool:
	if screen == Screen.REPORT:
		if again_button != null and again_button.visible:
			again_button.pressed.emit()
		return true
	_set_paused(not paused)
	return true


func _set_paused(on: bool) -> void:
	paused = on
	accum = 0.0
	if on:
		drawing = -1
		draw_finger = -1
	queue_redraw()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if screen != Screen.REPORT and screen != Screen.SPLASH:
				_set_paused(true)


func _press(p: Vector2) -> void:
	## Not while a skip is running: a route drawn into a fast-forward is a route
	## the player never saw run.
	if skipping:
		return
	## THE WHEEL OWNS THE SCREEN while it is up: a tap on an option answers it;
	## a press on the man himself starts a drag toward one; anything else waits.
	if wheel_man != -1:
		var wm = sim.men[wheel_man]
		var opt := _wheel_option_at(wm, p)
		if opt != -2:
			_wheel_answer(wm, opt)
		## FROM THE HUB, wherever the hub was drawn (first-timer test, 1 Oct: a
		## drag that started in the middle of the wheel did nothing, because the
		## wheel is pushed off a man near the edge and only the man's own spot
		## started a drag).
		elif _wheel_center(wm).distance_to(p) < WHEEL_RI + 6.0 or _to_screen(wm.pos).distance_to(p) < 30.0:
			wheel_drag = true
		return
	## A prompt is a question with three answers. Answering it beats starting a
	## new route, so it is tested first.
	for m in sim.men:
		if m.prompt == null or m.team != 0:
			continue
		var acts: Array = Tuning.acts_for(m.prompt.menu)
		for i in acts.size():
			## The drawn option is 30 tall; the thumb gets a few pixels more.
			if _prompt_rect(m, i).grow_individual(2, 6, 2, 6).has_point(p):
				sim.answer_prompt(m.idx, acts[i])
				return

	var idx := _fighter_at(p)
	if idx == -1:
		for i in 5:
			if _card_rect(i).has_point(p):
				idx = sim.men[i].idx
				break
	if idx == -1:
		return
	var man := sim.men[idx]
	if man.team != 0 or not man.standing():
		return
	drawing = idx
	draw_path.clear()
	draw_screen = PackedVector2Array([_to_screen(man.pos)])


func _extend(p: Vector2) -> void:
	if draw_screen.is_empty():
		return
	if draw_screen[draw_screen.size() - 1].distance_to(p) < 14.0:
		return
	## Moving again: not resting on the endpoint any more.
	draw_rest = 0.0
	draw_run = false
	draw_screen.append(p)
	draw_path.append(_to_list(p))
	hover_enemy = _enemy_at(p)


func _release(p: Vector2) -> void:
	if wheel_drag:
		wheel_drag = false
		wheel_hot = -2
		if wheel_man != -1:
			var wm = sim.men[wheel_man]
			var opt := _wheel_option_at(wm, p, true)
			if opt != -2:
				_wheel_answer(wm, opt)
		return
	if drawing == -1:
		return
	var idx := drawing
	var man := sim.men[idx]
	drawing = -1
	hover_enemy = -1

	## A tap, not a drag. On a man who is already tied up that means "give me
	## his options" — you should not have to draw a path to a fighter who is
	## standing right where you want him.
	var total := 0.0
	for i in range(1, draw_screen.size()):
		total += draw_screen[i - 1].distance_to(draw_screen[i])
	if total < 16.0:
		if man.state == MeleeSim.State.GRAPPLED:
			sim.request_prompt(idx)
		## AND A TAP ON A MAN WHO IS ON YOUR ROUTE TAKES IT BACK.
		##
		## `MeleeSim.cancel_order()` had been sitting there since the sim was
		## written with nothing in the game that called it: you could send a man
		## somewhere and there was no gesture that meant "no, stay". Drawing a
		## second route over the first was the only way out, which is worse than
		## no gesture — it is a wrong one, because the fix for "I did not mean
		## that" should not be another instruction.
		##
		## It is the tap, because the tap is the gesture that already means
		## "this man, and I am not drawing" — the only other thing it does is ask
		## a clinched man for his options, and a clinched man is not on a route.
		##
		## ONLY A ROUTE YOU DREW. A play's routes arrive through `_run_play` with
		## `from_play` set, and those are the plan the whole line is running: one
		## man tapped out of it is not a cancel, it is a different call, and the
		## screen for that is the corner. `_plan_live` reads the same flag for
		## the same reason.
		##
		## No message is needed and none is drawn. The route line goes, the card
		## border drops back from ROUTE to EDGE, and the card stops saying "on a
		## route" — three things change in the frame the tap lands on, which is
		## what confirmation is supposed to look like.
		elif man.under_orders() and not man.order.from_play:
			sim.cancel_order(idx)
			Audio.play("tap")
		## A TAP ON A FREE MAN PLANTS HIM (Pete, playtest 30 Sep #13): he holds
		## his ground, braced, until you draw him a route — or tap him again.
		elif man.planted:
			man.planted = false
			Audio.play("tap")
		## Not a man running a called play: that is the corner's call.
		elif not man.under_orders() and sim.plant(idx):
			Audio.play("tap")
		draw_path.clear()
		draw_screen = PackedVector2Array()
		return

	var target := _enemy_at(p)
	if target == -1 and not draw_path.is_empty():
		draw_path[draw_path.size() - 1] = _to_list(p)
	elif target != -1 and not draw_path.is_empty():
		## The last leg is the approach; the sim homes on the live man from
		## there, because he will not still be standing where you drew.
		draw_path.remove_at(draw_path.size() - 1)
	sim.give_order(idx, draw_path, target, draw_run)
	draw_run = false
	draw_rest = 0.0
	draw_path.clear()
	draw_screen = PackedVector2Array()


func _fighter_at(p: Vector2) -> int:
	var best := -1
	var best_d := 40.0
	for m in sim.men:
		if m.team != 0 or not m.standing():
			continue
		var d := _to_screen(m.pos).distance_to(p)
		if d < best_d:
			best_d = d
			best = m.idx
	return best


func _enemy_at(p: Vector2) -> int:
	var best := -1
	var best_d := 38.0
	for m in sim.men:
		if m.team != 1 or not m.standing():
			continue
		var d := _to_screen(m.pos).distance_to(p)
		if d < best_d:
			best_d = d
			best = m.idx
	return best


## THE LIST IS DRAWN ROTATED A QUARTER TURN. Pete, 10 Sep 2026: *"Player team on
## left, enemy team on right."*
##
## The sim thinks in a portrait list — the two sides separate along ITS y, and
## the five line positions spread along ITS x — because that is how a line and a
## charge are naturally written down. The screen wants the charge axis
## horizontal, so the transform swaps the axes on the way out and back:
##
##   sim y (the charge, your rail to theirs)  ->  screen x, left to right
##   sim x (along the line, Rail to Rail)     ->  screen y, top to bottom
##
## Nothing in the sim moves. This is a camera, and keeping it a camera is what
## lets the whole melee suite go on measuring the same fight.
## THE MEN STAND INSIDE THE FIELD (item 2: a man on their back rail was drawn
## half under the side panel). Along the list the positions map onto the field
## less a sprite's half-width at each end; across it the lanes already clear.
const LIST_INSET := 16.0
const LIST_SX := LIST_SCALE * (1.0 - 2.0 * LIST_INSET / (Tuning.LIST_H * LIST_SCALE))


func _to_screen(v: Vector2) -> Vector2:
	return LIST_ORIGIN + Vector2(LIST_INSET + v.y * LIST_SX, v.x * LIST_SCALE)


func _to_list(v: Vector2) -> Vector2:
	var d := v - LIST_ORIGIN
	return Vector2(d.y / LIST_SCALE, (d.x - LIST_INSET) / LIST_SX)


# -------------------------------------------------------------------- draw
func _draw() -> void:
	if sim == null:
		return
	## THE GUTTERS. Whatever is wider than the design frame gets the ground.
	if off_x > 0.0 or off_y > 0.0:
		var full := Rect2(Vector2(-off_x, -off_y), UiKit.screen())
		draw_rect(full, UiKit.tint(Tuning.COL_GROUND, 1.0))
	## THE SPLASH IS A WHOLE SCREEN, like the report, so it returns before the
	## fight is drawn rather than after.
	##
	## It used to sit at the BOTTOM of this function: the list, the grid, ten
	## men, every route, the scoreboard, the strip, the hint and the call bank
	## were all drawn in full, every frame, and `_draw_splash` then painted an
	## opaque arena straight over the lot. Invisible, and a whole melee frame's
	## work for nothing.
	##
	## The ink sweep is what found it — it reads what was DRAWN, and could not
	## tell ink under an opaque picture from ink a player can read, so it
	## reported the splash's button sitting on top of five men's position labels.
	## A screen that draws what cannot be seen is a screen no check can measure.
	if screen == Screen.SPLASH:
		_draw_splash()
		return
	if screen == Screen.REPORT:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), UiKit.tint(Tuning.COL_GROUND, 1.0))
		## SIZED TO THE LABEL IT IS BEHIND. This was 500x690 — the portrait
		## rectangle from before 13.1, left behind when every other screen was
		## re-laid-out. On a 540-tall screen it ran 250px off the bottom and
		## stopped at x=520, so the right half of every post-fight report sat on
		## bare ground with no panel under it. Derived from the label now, so it
		## cannot drift again.
		_draw_report()
		return

	_draw_list()
	_draw_routes()
	for m in sim.men:
		if not m.standing():
			_draw_man(m)
	for m in sim.men:
		if m.standing():
			_draw_man(m)
	_draw_drawing()
	_draw_scoreboard()
	_draw_strip()
	_draw_hint()
	_draw_calls()
	_draw_held()
	if screen == Screen.FIGHT:
		_draw_call_words()
	for m in sim.men:
		if m.prompt != null and m.team == 0 and m.idx != wheel_man:
			_draw_prompt(m)
	if wheel_man != -1:
		_draw_wheel(sim.men[wheel_man])
	## THE PANEL NEEDS A FLOOR, NOT JUST A DIMMER.
	##
	## There was a scrim here and nothing else, so the formation picker and the
	## corner were read THROUGH the fight: the grid lines, the men and the route
	## marks all sat behind the words, at 34% of full strength, while a player
	## with a clock running tried to pick a shape. It is the least readable thing
	## in the game and it is on the two screens with a timer on them.
	##
	## A scrim and an opaque panel under the box. The panel is derived from the
	## container's own rect rather than written down, because the corner's height
	## changes with how many men are on the bench — the report panel already
	## learned that lesson the expensive way and this is the same fix.
	if screen == Screen.CORNER or screen == Screen.PREFIGHT:
		draw_rect(Rect2(Vector2(-off_x, -off_y), UiKit.screen()), Color(0, 0, 0, 0.72))
		## EVERYTHING ABOVE IS NOW UNDER THE SCRIM. The fight is drawn in full and
		## then deliberately made unreadable — that is what the scrim is for — so
		## the ink sweep has to be told, or it reports the scoreboard's own
		## headers landing on the corner's buttons: a complaint about pixels
		## nobody can read. Before the panel, so the corner's OWN text still
		## counts. Costs nothing with the ledger down.
		UiKit.ledger_cover()
		if panel_box != null and panel_box.visible and panel_box.size.y > 0.0:
			UiKit.panel(self, Rect2(panel_box.position - Vector2(24.0, 20.0),
				Vector2(maxf(panel_box.size.x, 640.0) + 48.0,
					panel_box.size.y + 44.0)))
		elif not corner_nodes.is_empty():
			_draw_corner()
	## AND THE MARSHAL IS NOT SHOUTING OVER THE CORNER. His call belongs to the
	## round; on a panel that has replaced the round it is forty-pixel text
	## through the middle of five men's numbers.
	if marshal_t > 0.0 and screen == Screen.FIGHT:
		UiKit.raw(self, font, Vector2(0, SCREEN.y * 0.46), marshal_text,
			HORIZONTAL_ALIGNMENT_CENTER, int(SCREEN.x), 40,
			Tuning.COL_MARSHAL * Color(1, 1, 1, clampf(marshal_t / 1.6, 0, 1)))
	if paused:
		var sz := SCREEN
		draw_rect(Rect2(Vector2(-off_x, -off_y), UiKit.screen()), Color(0, 0, 0, 0.6))
		UiKit.raw(self, font, Vector2(0, sz.y * 0.46), UiKit.t("PAUSED"),
			HORIZONTAL_ALIGNMENT_CENTER, int(sz.x), 40, UiKit.YOU)
		UiKit.raw(self, font, Vector2(0, sz.y * 0.46 + 36), UiKit.t("Tap to carry on"),
			HORIZONTAL_ALIGNMENT_CENTER, int(sz.x), 16, COL_DIM)
		## WHAT HAPPENS IF THE PHONE KILLS US NOW (Pete, 29 Sep 2026): the bout
		## is fought again from the walk-out, on the same seed.
		if Session.season != null:
			UiKit.raw(self, font, Vector2(0, sz.y * 0.46 + 64),
				UiKit.t("If the game closes, this bout starts again from the walk-out."),
				HORIZONTAL_ALIGNMENT_CENTER, int(sz.x), 14, COL_DIM)


# ----------------------------------------------------------- the report
## THE WHOLE SCREEN, DRAWN. One button on it and nothing else — a table, two
## scrolling panes and a rule, which is what the mock is and what prose was not.
func _draw_report() -> void:
	UiKit.panel(self, REP_PANEL)
	var us := 0
	var them := 1
	## Three whole sentences, not a verb dropped into one: a language that bends
	## the verb, or puts it last, has to see the sentence it lands in.
	var verdict := UiKit.t("You take it. Rounds %d-%d, %d down across the bout.") \
		if sim.bout_winner() == us else (UiKit.t("You share it. Rounds %d-%d, %d down across the bout.") \
		if sim.bout_winner() == -1 else UiKit.t("You lose it. Rounds %d-%d, %d down across the bout."))
	UiKit.raw(self, font, Vector2(REP_LX, 56), UiKit.t("%s %d - %d %s") % [
		sim.clubs[us].display_name.to_upper(), sim.rounds_won[us],
		sim.rounds_won[them], sim.clubs[them].display_name.to_upper()],
		HORIZONTAL_ALIGNMENT_LEFT, 880, 17, UiKit.YOU)
	UiKit.raw(self, font, Vector2(REP_LX, 78),
		verdict % [
			sim.rounds_won[us], sim.rounds_won[them], sim.downs[us] + sim.downs[them]],
		HORIZONTAL_ALIGNMENT_LEFT, 880, 11, COL_DIM)
	_rule(REP_LX, 94.0, 936.0 - REP_LX * 2.0)

	UiKit.raw(self, font, Vector2(REP_LX, 112), UiKit.t("THE EVENT"),
		HORIZONTAL_ALIGNMENT_LEFT, 300, 10, COL_DIM)
	UiKit.raw(self, font, Vector2(REP_RX, 112), UiKit.t("WHAT THEY SAID"),
		HORIZONTAL_ALIGNMENT_LEFT, 300, 10, COL_DIM)
	_draw_report_table()
	_draw_quips()
	_rule(REP_LX, 314.0, 936.0 - REP_LX * 2.0)
	UiKit.raw(self, font, Vector2(REP_LX, 334), UiKit.t("AFTER ACTION REPORT"),
		HORIZONTAL_ALIGNMENT_LEFT, 300, 12, UiKit.YOU)
	UiKit.raw(self, font, Vector2(REP_LX + 260.0, 334),
		UiKit.t("The men, the room, the gate and the ground."),
		HORIZONTAL_ALIGNMENT_LEFT, 400, 10, COL_DIM)
	_draw_news()


func _rule(x: float, y: float, w: float) -> void:
	draw_line(Vector2(x, y + 0.5), Vector2(x + w, y + 0.5), COL_EDGE, 1.0)


## SIX MEN AND SEVEN FIGURES EACH. The XP is what he earned today, the level is
## what he is on after it, and the last cell says the only three things it can:
## he went up, he is at his ceiling, or how far off he is.
func _draw_report_table() -> void:
	var heads := [[UiKit.t("DOWNS"), "dn"], [UiKit.t("AST"), "as"], [UiKit.t("UP"), "up"],
		[UiKit.t("OFF"), "off"], [UiKit.t("XP"), "xp"], [UiKit.t("LVL"), "lv"],
		[UiKit.t("NEXT"), "next"]]
	for h in heads:
		UiKit.right(self, font, String(h[0]),
			Vector2(REP_LX + float(REP_COL[h[1]]), 130), 9, COL_DIM, 90.0)
	_rule(REP_LX, 136.0, REP_LW)
	## THE KEY FOR THE SHORT HEADINGS (blind review rounds 2 and 3: AST/UP/OFF).
	UiKit.raw(self, font, Vector2(REP_LX + 110.0, 112.0),
		UiKit.fit(font, UiKit.t("AST assists  ·  UP rounds on his feet  ·  OFF carried off"), 12, REP_LW - 110.0),
		HORIZONTAL_ALIGNMENT_RIGHT, int(REP_LW - 110.0), 12, COL_DIM)
	var i := 0
	## EIGHT ROWS WHEN THE BENCH FOUGHT (first-timer test, 1 Oct: the eighth row
	## was drawn over the AFTER ACTION REPORT heading). The rows close up to fit
	## above it rather than running into it.
	var n_rows := 0
	for m in sim.fought():
		if m.team == 0 and m.card != null:
			n_rows += 1
	var rh := minf(REP_ROW_H, (310.0 - REP_ROW_Y) / float(maxi(1, n_rows - 1)))
	for m in sim.fought():
		if m.team != 0 or m.card == null:
			continue
		var y := REP_ROW_Y + float(i) * rh
		if i % 2 == 0:
			draw_rect(Rect2(REP_LX, y - 12.0, REP_LW, rh - 1.0), Color(1, 1, 1, 0.022))
		UiKit.raw(self, font, Vector2(REP_LX + 6.0, y + 4), UiKit.t("#%d %s") % [
			m.card.number, m.card.display_name],
			HORIZONTAL_ALIGNMENT_LEFT, 140, 11, COL_INK)
		UiKit.raw(self, font, Vector2(REP_LX + 150.0, y + 4), m.card.pos_name(),
			HORIZONTAL_ALIGNMENT_LEFT, 140, 9, COL_DIM)
		_cell("%d" % m.downs_caused, "dn", y, 11,
			COL_GOOD if m.downs_caused >= 2 else COL_INK)
		_cell("%d" % int(m.assists), "as", y, 11, COL_INK)
		_cell("%d" % int(m.rounds_standing), "up", y, 11, COL_INK)
		_cell("%d" % int(m.times_downed), "off", y, 11,
			COL_HOT if m.times_downed >= 2 else COL_DIM)
		## WHAT WAS BANKED, not the raw figure: the season multiplies it by the
		## regime, the captain and the man's own trait before it lands.
		var got: int = int(Session.season.last_xp.get(m.card, -1)) \
			if Session.season != null else -1
		if got < 0:
			got = Career.xp_for(m.downs_caused, m.rounds_standing, m.card.overall())
		_cell("+%d" % got, "xp", y, 10, COL_GOOD)
		_cell("%d" % m.card.level, "lv", y, 11,
			UiKit.YOU if Career.can_place(m.card) else COL_INK)
		if Career.at_ceiling(m.card):
			_cell("PEAK", "next", y, 10, COL_DIM)
		elif Career.can_place(m.card):
			## QUIETER THAN A SHOUT PER ROW (item 2): the Spend button carries the
			## count; each row only says his is ready.
			## HOW MANY, not just "ready" (review round 3: "+17 XP" beside "+1
			## ready" read as seventeen points buying one level).
			_cell(UiKit.t("+%d ready") % Career.levels_banked(m.card), "next", y, 12, UiKit.UP)
		else:
			_cell(UiKit.t("%d/%d xp") % [m.card.xp, Career.next_level_at(m.card)],
				"next", y, 10, COL_INK)
		i += 1


func _cell(s: String, col: String, y: float, px: int, c: Color) -> void:
	UiKit.right(self, font, s, Vector2(REP_LX + float(REP_COL[col]), y + 4),
		px, c, 90.0)


## WHAT THEY THINK, in cards sized to their own text. The pane clips by skipping
## anything outside it rather than by a scissor: a card is either drawn or it is
## not, which for uniform-width cards is the same picture and needs no transform
## stack.
func _draw_quips() -> void:
	## Built once per report, not 60 times a second.
	if _quips_cache.is_empty():
		_quips_cache = MeleeReport.quips(sim, _season())
	var rows: Array = _quips_cache
	var y := QUIP_TOP - quip_scroll
	var total := 0.0
	for q in rows:
		var lines := UiKit.wrap(font, q.text, REP_RW - 34.0, 13)
		var h := 26.0 + float(lines.size()) * 17.0 + 8.0
		## WHOLE CARDS ONLY: a card half out of the pane printed over the report
		## under it (blind review round 3). "more" says there is more below.
		if y >= QUIP_TOP - 0.5 and y + h <= QUIP_TOP + QUIP_H + 0.5:
			var box := Rect2(REP_RX, y, REP_RW - 10.0, h)
			draw_rect(box, COL_PANEL.lightened(0.05))
			draw_rect(box, COL_EDGE, false, 1.0)
			draw_rect(Rect2(REP_RX, y, 3.0, h), _tone_color(q.tone))
			UiKit.raw(self, font, Vector2(REP_RX + 12.0, y + 17.0), q.who,
				HORIZONTAL_ALIGNMENT_LEFT, REP_RW - 24, 13, _tone_color(q.tone))
			for k in lines.size():
				UiKit.raw(self, font, Vector2(REP_RX + 12.0, y + 34.0 + float(k) * 17.0),
					String(lines[k]), HORIZONTAL_ALIGNMENT_LEFT, REP_RW - 24, 13, COL_DIM)
		y += h + 6.0
		total += h + 6.0
	quip_over = maxf(0.0, total - 6.0 - QUIP_H)
	quip_scroll = clampf(quip_scroll, 0.0, quip_over)
	if rows.is_empty():
		UiKit.raw(self, font, Vector2(REP_RX, QUIP_TOP + 20.0),
			UiKit.t("Nobody had anything to say."), HORIZONTAL_ALIGNMENT_LEFT,
			int(REP_RW), 10, COL_DIM)


func _tone_color(tone: int) -> Color:
	if tone > 0:
		return COL_GOOD
	return COL_HOT if tone < 0 else COL_INK


## THE CARDS ALONG THE BOTTOM: the table, the gate, the following, and every man
## the afternoon changed. Three columns, two lines of body each, and every line
## above is written to fit two — a card that shows half a message is worse than
## no card, because the player has to go and find out what it said.
## The caption a band carries, and what a band is called. Two bands only; a third
## would want a different layout, not another entry.
const NEWS_BAND := {"club": "THE CLUB", "man": "THE MEN"}
const NEWS_CAP_H := 18.0


## WHERE EACH CARD GOES, worked out once so the drawing and the scroll extent
## cannot disagree about how tall the grid is — which they would the moment one
## of them counted cards and the other counted cards plus captions.
##
## Cards fill left to right; a change of `kind` starts a new line and reserves a
## caption above it. Returns one entry per card plus the captions, in draw order,
## and the total height.
func _news_layout(rows: Array) -> Dictionary:
	var out: Array = []
	var caps: Array = []
	var y := 0.0
	var col := 0
	var last := ""
	for i in rows.size():
		var kind := String(rows[i].kind)
		if kind != last:
			## Close the line the last band was part-way through, then take the
			## caption's height BEFORE placing anything — a caption that is drawn
			## above a row nothing left room for lands on the row.
			if last != "" and col > 0:
				y += NEWS_STEP.y
			caps.append({"y": y, "text": UiKit.t(String(NEWS_BAND.get(kind, "")))})
			y += NEWS_CAP_H
			col = 0
			last = kind
		elif col >= NEWS_COLS:
			col = 0
			y += NEWS_STEP.y
		out.append({"row": rows[i], "x": REP_LX + float(col) * NEWS_STEP.x, "y": y})
		col += 1
	if not rows.is_empty():
		y += NEWS_STEP.y
	return {"cards": out, "caps": caps, "height": y}


func _draw_news() -> void:
	if _news_cache.is_empty():
		_news_cache = MeleeReport.news(_season())
	var rows: Array = _news_cache
	var plan := _news_layout(rows)
	news_over = maxf(0.0, float(plan["height"]) - 8.0 - NEWS_H)
	news_scroll = clampf(news_scroll, 0.0, news_over)
	## AND THE PANE SAYS THERE IS MORE. It has scrolled since it was built and
	## nothing has ever said so — which is the same as not scrolling. Now that it
	## is two bands deep it always has more, so the arrow is not decoration.
	if news_over > 0.5:
		var at_end: bool = news_scroll >= news_over - 0.5
		UiKit.raw(self, font, Vector2(936.0 - REP_LX - 60.0, NEWS_TOP - 10.0),
			UiKit.t("scroll ^") if at_end else UiKit.t("more v"), HORIZONTAL_ALIGNMENT_RIGHT, 60, 14,
			UiKit.YOU)
	for c in plan["caps"]:
		var cy: float = NEWS_TOP + float(c["y"]) - news_scroll
		## A CAPTION WITHOUT ITS CARDS IS A HEADING OVER NOTHING (before/after
		## review: "THE CLUB" sat on the button row with nothing under it).
		if cy <= NEWS_TOP - 4.0 or cy + NEWS_CAP_H + NEWS_CARD.y > NEWS_TOP + NEWS_H:
			continue
		UiKit.raw(self, font, Vector2(REP_LX, cy + 12.0), String(c["text"]),
			HORIZONTAL_ALIGNMENT_LEFT, 300, 9, COL_DIM)
	for e in plan["cards"]:
		var n = e["row"]
		var bx: float = float(e["x"])
		var by: float = NEWS_TOP + float(e["y"]) - news_scroll
		## WHOLE CARDS ONLY. Nothing here clips, so a card straddling the bottom
		## of the pane used to draw its full height anyway — under the button,
		## with its second line of text reading through it. It fitted before
		## because the grid was one row; the two bands make it two.
		if by < NEWS_TOP - 1.0 or by + NEWS_CARD.y > NEWS_TOP + NEWS_H:
			continue
		var box := Rect2(bx, by, NEWS_CARD.x, NEWS_CARD.y)
		draw_rect(box, COL_PANEL.lightened(0.05))
		draw_rect(box, COL_EDGE, false, 1.0)
		draw_rect(Rect2(bx, by, 3.0, NEWS_CARD.y), _tone_color(n.tone))
		UiKit.raw(self, font, Vector2(bx + 12.0, by + 18.0), n.head,
			HORIZONTAL_ALIGNMENT_LEFT, int(NEWS_CARD.x - 24.0), 10, COL_INK)
		var body := UiKit.wrap(font, n.text, NEWS_CARD.x - 24.0, 9)
		for k in mini(2, body.size()):
			UiKit.raw(self, font, Vector2(bx + 12.0, by + 32.0 + float(k) * 13.0),
				String(body[k]), HORIZONTAL_ALIGNMENT_LEFT,
				int(NEWS_CARD.x - 24.0), 9, _tone_color(n.tone))


## EVERYTHING ON THE CORNER THAT IS NOT A CONTROL. The five rows, the header,
## and the strip that says what is called.
func _draw_corner() -> void:
	## THE FIGHT BEHIND IS PUT AWAY, not just dimmed (round 4: "R1 1:46" showed
	## through above the corner).
	draw_rect(Rect2(Vector2(-off_x, -off_y), UiKit.screen()), Color(UiKit.BG, 0.94))
	UiKit.panel(self, C_PANEL)
	var line := sim.lineup(0)
	var row_h := _corner_rows()
	var first: bool = sim.round_no <= 1 and sim.phase != MeleeSim.Phase.CORNER

	if first:
		UiKit.raw(self, font, Vector2(C_LX, 60), UiKit.t("BEFORE THE CHARGE"),
			HORIZONTAL_ALIGNMENT_LEFT, 400, 16, UiKit.YOU)
		## WHO YOU ARE PLANNING AGAINST (round 5: "no information about the
		## opponent on the screen where you pick a plan against them").
		## BOTH LINES, side by side (round 9: "show your line's rating too").
		var rated := [0, 0]
		for side in 2:
			var tot := 0
			var n := 0
			for c in sim.lineup(side):
				if c != null:
					tot += c.overall()
					n += 1
			rated[side] = int(round(float(tot) / float(maxi(1, n))))
		UiKit.raw(self, font, Vector2(300, 62), UiKit.fit(font, UiKit.t("your line %d  ·  v %s  ·  their line %d") % [
			rated[0], sim.clubs[1].display_name, rated[1]], 14, 612.0),
			HORIZONTAL_ALIGNMENT_RIGHT, 612, 14, COL_INK)
	else:
		UiKit.raw(self, font, Vector2(C_LX, 60), UiKit.t("END OF ROUND %d") % sim.round_no,
			HORIZONTAL_ALIGNMENT_LEFT, 400, 16, UiKit.YOU)
		var standing := 0
		for m in sim.men:
			if m.team == 0 and m.standing():
				standing += 1
		var head := [
			## "5 OF 5", NOT "5 - 0" (review, 1 Oct 2026: it read as a score).
			[UiKit.t("STILL STANDING"), UiKit.t("%d of %d") % [standing, _line_size(0)],
				COL_GOOD if standing >= 3 else COL_HOT],
			## THE CORNER'S OWN CLOCK (blind review, 29 Sep: "the countdown is not
			## visible"). How long the round took mattered less than how long is left.
			[UiKit.t("BACK IN"), "0:%02d" % int(ceil(maxf(0.0, sim.corner_t))),
				COL_HOT if sim.corner_t < 6.0 else COL_INK],
			[UiKit.t("ROUNDS"), "%d - %d" % [sim.rounds_won[0], sim.rounds_won[1]], COL_INK],
		]
		for i in head.size():
			var hx: float = 440.0 + float(i) * 158.0
			UiKit.raw(self, font, Vector2(hx, 50), String(head[i][0]),
				HORIZONTAL_ALIGNMENT_LEFT, 150, 9, COL_DIM)
			UiKit.raw(self, font, Vector2(hx, 72), String(head[i][1]),
				HORIZONTAL_ALIGNMENT_LEFT, 150, 17, head[i][2])
	draw_line(Vector2(C_LX, 86.5), Vector2(890, 86.5), COL_EDGE, 1.0)

	for i in line.size():
		var m = _man_in_slot(i)
		## A MAN JUST SWAPPED IN IS NOT THE MAN WHO FOUGHT THE ROUND (first-timer
		## test, 1 Oct: a fresh sub wore his predecessor's DOWNED and his downs).
		## The slot's Man is rebuilt when the corner ends; until then, read him
		## only if he is still the card on the line.
		if m != null and m.card != line[i]:
			m = null
		var ry: float = C_LY + float(i) * (row_h + C_ROW_GAP)
		var downed: bool = m != null and m.downed_round
		draw_rect(Rect2(C_LX, ry, C_LW, row_h), COL_PANEL.lightened(0.05))
		draw_rect(Rect2(C_LX, ry, C_LW, row_h), COL_HOT if downed else COL_EDGE,
			false, 2.0 if downed else 1.0)
		var f = line[i]
		UiKit.raw(self, font, Vector2(C_LX + 10, ry + 19), UiKit.t("#%d %s") % [f.number,
			f.display_name], HORIZONTAL_ALIGNMENT_LEFT, 120, 11, COL_INK)
		UiKit.raw(self, font, Vector2(C_LX + 10, ry + 34), f.pos_name(),
			HORIZONTAL_ALIGNMENT_LEFT, 120, 8, COL_DIM)
		if downed:
			UiKit.raw(self, font, Vector2(C_LX + 10, ry + 50), UiKit.t("DOWNED"),
				HORIZONTAL_ALIGNMENT_LEFT, 120, 8, COL_HOT)
		elif FighterTrait.flag(f.trait_id, "no_sub"):
			## SHORT ENOUGH FOR ITS COLUMN (first-timer test, 1 Oct: "WILL NOT COME
			## O…" cut off in all three runs).
			UiKit.raw(self, font, Vector2(C_LX + 10, ry + 50), UiKit.fit(font, UiKit.t("STAYS ON"), 8, 110.0),
				HORIZONTAL_ALIGNMENT_LEFT, 110, 8, COL_DIM)
		## THE TWO NUMBERS THE ROUND PRODUCED. Blank before the charge, because a
		## column of noughts on the pre-fight screen is a report on nothing.
		if not first and m != null:
			## WORDS, NOT TD/AST (blind review rounds 2 and 3).
			UiKit.raw(self, font, Vector2(C_LX + C_STAT_X, ry + 19),
				UiKit.fit(font, UiKit.tn("%d down", "%d downs", m.downs_caused) % m.downs_caused, 12, 76.0),
				HORIZONTAL_ALIGNMENT_LEFT, 76, 12, COL_INK)
			UiKit.raw(self, font, Vector2(C_LX + C_STAT_X, ry + 36),
				UiKit.fit(font, UiKit.tn("%d assist", "%d assists", int(m.assists)) % int(m.assists), 12, 76.0),
				HORIZONTAL_ALIGNMENT_LEFT, 76, 12, COL_DIM)

		## ENERGY NOW AND ENERGY RECOVERED — Pete, 13 Sep 2026. The lighter part
		## of the bar is what the corner is about to give him back, and it comes
		## off `sim.corner_preview` rather than being recomputed here, so the
		## preview cannot promise a number the recovery does not deliver.
		var now_e: float = sim.condition_of(f)
		## BEFORE THE CHARGE EVERY BAR READS 100% (round 4: five identical rows).
		## A fresh man shows what he brings instead: his rating and his weapon.
		if first and now_e >= 0.999:
			UiKit.raw(self, font, Vector2(C_LX + C_BAR_X, ry + 22), UiKit.t("RATING"),
				HORIZONTAL_ALIGNMENT_LEFT, 80, 12, COL_DIM)
			UiKit.raw(self, font, Vector2(C_LX + C_BAR_X, ry + 46), "%d" % f.overall(),
				HORIZONTAL_ALIGNMENT_LEFT, 60, 20, COL_INK)
			## HIS KIT, AND HIS WEAPON ONLY WHEN IT IS NOT THE USUAL ONE (review
			## round 3: "Sword & shield" five times down the page said nothing).
			var gear := UiKit.t("kit %d%%") % int(round(f.armor * 100.0))
			if f.weapon != Tuning.Weapon.SWORD_SHIELD:
				gear = "%s · %s" % [UiKit.t(Tuning.weapon_name(f.weapon)), gear]
			UiKit.raw(self, font, Vector2(C_LX + C_BAR_X + 60.0, ry + 46),
				UiKit.fit(font, gear, 13, C_BAR_W),
				HORIZONTAL_ALIGNMENT_LEFT, int(C_BAR_W), 13, COL_INK)
			continue
		## The preview is the OUTGOING man's recovery; a man just swapped in is
		## shown as he is, not with somebody else's rest added on.
		var back: float = sim.corner_preview(m) \
			if (m != null and not first and m.card == f) else now_e
		UiKit.raw(self, font, Vector2(C_LX + C_BAR_X, ry + 17), UiKit.t("ENERGY"),
			HORIZONTAL_ALIGNMENT_LEFT, 80, 7, COL_DIM)
		draw_rect(Rect2(C_LX + C_BAR_X, ry + 21, C_BAR_W, 8), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(C_LX + C_BAR_X, ry + 21, C_BAR_W * back, 8),
			COL_GOOD.lightened(0.32))
		draw_rect(Rect2(C_LX + C_BAR_X, ry + 21, C_BAR_W * now_e, 8),
			COL_HOT if now_e < Tuning.GASSED_BELOW * FighterTrait.mod(f.trait_id, "gassed_below", 1.0) else COL_GOOD)
		UiKit.raw(self, font, Vector2(C_LX + C_BAR_X, ry + 43),
			"%d%%" % int(round(now_e * 100.0)) if is_equal_approx(back, now_e)
				else "%d%% → %d%%" % [int(round(now_e * 100.0)), int(round(back * 100.0))],
			HORIZONTAL_ALIGNMENT_RIGHT, int(C_BAR_W), 8, COL_DIM)
		UiKit.raw(self, font, Vector2(C_LX + C_BAR_X, ry + 58), UiKit.t("CONDITION"),
			HORIZONTAL_ALIGNMENT_LEFT, 80, 7, COL_DIM)
		var word := Tuning.condition_word(now_e, f.fit())
		## MEASURED, so the label and the word never touch ("CONDITIONHealthy").
		var cw := font.get_string_size(UiKit.t("CONDITION"), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.MIN_PX).x
		UiKit.raw(self, font, Vector2(C_LX + C_BAR_X + cw + 8.0, ry + 59), word,
			HORIZONTAL_ALIGNMENT_LEFT, 90, 9,
			COL_HOT if word == "Injured" or word == "Beat Up" else (UiKit.YOU if word == "Tired" else COL_INK))

	## THE RIGHT COLUMN'S HEADING AND THE CHOSEN STRIP. The strip sits between
	## the book and the fight because that is where the player's eye is going.
	UiKit.raw(self, font, Vector2(C_RX, C_LY - 4), UiKit.t("PLAYBOOK"),
		HORIZONTAL_ALIGNMENT_LEFT, 200, 10, COL_DIM)
	var fw: float = (C_RW - C_FAV_GAP) * 0.5
	var fh: float = fw * (PLAY_CARD.y / PLAY_CARD.x)
	var cy: float = C_LY + 6.0 + fh * 2.0 + C_FAV_GAP + 10.0 + 44.0
	draw_rect(Rect2(C_RX, cy, C_RW - UiKit.DROP_PX, 32.0), COL_PANEL.lightened(0.08))
	draw_rect(Rect2(C_RX, cy, C_RW - UiKit.DROP_PX, 32.0), UiKit.YOU, false, 1.0)
	UiKit.raw(self, font, Vector2(C_RX + 9, cy + 13), UiKit.t("CHOSEN"),
		HORIZONTAL_ALIGNMENT_LEFT, 80, 7, COL_DIM)
	UiKit.raw(self, font, Vector2(C_RX + 9, cy + 26),
		UiKit.fit(font, _chosen_label(), 10, C_RW - 24.0),
		HORIZONTAL_ALIGNMENT_LEFT, int(C_RW - 24.0), 10,
		UiKit.YOU if not chosen_call.is_empty() else COL_DIM)

	## AND THE SUB POPUP'S FLOOR, over everything.
	if sub_open >= 0 and sub_box.size.x > 0.0:
		draw_rect(Rect2(Vector2(-off_x, -off_y), UiKit.screen()), Color(0, 0, 0, 0.7))
		UiKit.panel(self, sub_box)
		## ONE LINE, MEASURED (blind review, 29 Sep: "WHO COMES ON FORILES" — the
		## name sat at a fixed 112 px that the label outgrew).
		var head := UiKit.t("WHO COMES ON FOR")
		var head_w := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		UiKit.raw(self, font, sub_box.position + Vector2(SUB_PAD, 33),
			head, HORIZONTAL_ALIGNMENT_LEFT,
			int(sub_box.size.x - SUB_PAD * 2.0), 12, COL_DIM)
		UiKit.raw(self, font, sub_box.position + Vector2(SUB_PAD + head_w + 10.0, 33),
			sub_for.to_upper(), HORIZONTAL_ALIGNMENT_LEFT,
			int(sub_box.size.x - SUB_PAD * 2.0 - head_w - 10.0), 15, UiKit.YOU)
		## A rule under the head, so the list below it reads as a list and not as
		## three buttons that happen to be under a sentence.
		draw_line(sub_box.position + Vector2(SUB_PAD, 46.0),
			sub_box.position + Vector2(sub_box.size.x - SUB_PAD, 46.0),
			COL_EDGE, 1.0)
		if sim.bench(0).is_empty():
			UiKit.raw(self, font, sub_box.position + Vector2(SUB_PAD, _sub_row_y(0) + 26.0),
				UiKit.t("Nobody left on the bench."), HORIZONTAL_ALIGNMENT_LEFT,
				int(sub_box.size.x - SUB_PAD * 2.0), 14, COL_DIM)


## The sim man standing in a given slot of our line, or null before the men are
## built. `sim.men` is indexed by slot for team 0, but only once a round has been
## set up — the pre-fight screen asks for rows before that is true.
func _man_in_slot(slot: int):
	if slot < 0 or slot >= sim.men.size():
		return null
	var m = sim.men[slot]
	return m if m.team == 0 else null


func _draw_list() -> void:
	## THE FIGHT WEARS IT TOO, and this is where a boss battle actually lands — a
	## menu that changes color is a theme, a LIST that changes color is an
	## occasion. The surround goes all the way to the mood because nothing is read
	## off it; the fighting surface moves barely a third, because a player reads
	## a man's position against it fifty times a round.
	## ART IF THERE IS ANY, PRIMITIVES IF NOT, and the mood tint applies either
	## way — artwork that cannot be tinted would break the one thing the fight
	## screen does that the menus do not, which is change color with the
	## occasion. So the surface art is specified grayscale and gets its color
	## here. See docs/ART.md.
	var surround := UiKit.tint(Tuning.COL_GROUND, 1.0)
	if not ArtBank.draw_slot(self, "list_ground", Rect2(Vector2.ZERO, SCREEN), surround):
		draw_rect(Rect2(Vector2.ZERO, SCREEN), surround)
	var tl := _to_screen(Vector2.ZERO)
	## Rotated, so the list's depth is the screen's width.
	var size := Vector2(Tuning.LIST_H, Tuning.LIST_W) * LIST_SCALE
	if not ArtBank.draw_slot(self, "list_surface", Rect2(tl, size),
			UiKit.tint(Tuning.COL_LIST, 0.30)):
		draw_rect(Rect2(tl, size), UiKit.tint(Tuning.COL_LIST, 0.30))
	draw_rect(Rect2(tl, size), UiKit.tint(Tuning.COL_RAIL, 0.55), false, 6.0)
	## THE FIVE POSITION LANES RUN ALONG THE LINE, Rail to Rail — which is
	## `LIST_W`, and after the quarter-turn that is the screen's HEIGHT.
	##
	## They were drawn at fractions of `size.x`, the CHARGE axis, so four
	## vertical lines cut the charge into fifths and sat among the two set-up
	## lines reading as extra marshal marks. The one thing on the surface that
	## tells you where the five positions are was drawn across the wrong axis.
	for i in 4:
		var y := tl.y + size.y * (float(i) + 1.0) / 5.0
		draw_line(Vector2(tl.x, y), Vector2(tl.x + size.x, y),
			UiKit.tint(Tuning.COL_RAIL, 0.55) * 1.1, 1.0)
	## THE SET-UP LINES. Pete, 10 Sep 2026 — *"you can probably mark it on the
	## field"* — and he is right that it has to be marked: nobody starts past 15%
	## of the way out from his own rail, and a rule the player has to infer from
	## where the men happen to stand is not a rule, it is a surprise.
	for side in 2:
		var f: float = Tuning.SET_UP_LINE if side == 0 else 1.0 - Tuning.SET_UP_LINE
		var x := tl.x + size.x * f
		draw_line(Vector2(x, tl.y), Vector2(x, tl.y + size.y),
			Tuning.COL_MARSHAL * Color(1, 1, 1, 0.30), 2.0)


## A route on screen is the only evidence that an order exists, and it vanishes
## the moment the AI takes him back. That is the design made visible: you can
## see, at a glance, exactly how much of this fight is yours right now.
func _draw_routes() -> void:
	for m in sim.men:
		if m.order == null or not m.standing():
			continue
		var pts := PackedVector2Array([_to_screen(m.pos)])
		for w in m.order.path:
			pts.append(_to_screen(w))
		var hostile := m.order.target != -1
		if hostile and sim.men[m.order.target].standing():
			pts.append(_to_screen(sim.men[m.order.target].pos))
		var col := Tuning.COL_ROUTE_HOSTILE if hostile else Tuning.COL_ROUTE
		if pts.size() >= 2:
			draw_polyline(pts, col * Color(1, 1, 1, 0.75), 3.0)
		for i in range(1, pts.size()):
			draw_circle(pts[i], 3.0, col)


func _draw_drawing() -> void:
	if drawing == -1 or draw_screen.size() < 2:
		return
	## A RUN IS DRAWN HOT, with the word at the finger, so a held endpoint is seen
	## to have done something before it is lifted.
	draw_polyline(draw_screen, COL_HOT if draw_run else Tuning.COL_ROUTE, 4.0 if draw_run else 3.0)
	if draw_run:
		UiKit.raw(self, font, draw_screen[draw_screen.size() - 1] + Vector2(-30, -18),
			UiKit.t("RUN"), HORIZONTAL_ALIGNMENT_CENTER, 60, 14, COL_HOT)
	if hover_enemy != -1:
		var e := _to_screen(sim.men[hover_enemy].pos)
		draw_arc(e, 24.0, 0.0, TAU, 24, Tuning.COL_ROUTE_HOSTILE, 3.0)


func _draw_man(m) -> void:
	var p := _to_screen(m.pos)
	var club = sim.clubs[m.team]
	var w := 24.0
	var h := 32.0

	if m.state == MeleeSim.State.OUT:
		return
	if m.state == MeleeSim.State.DOWN:
		draw_rect(Rect2(p - Vector2(h * 0.5, w * 0.35), Vector2(h, w * 0.7)), Tuning.COL_DOWN)
		draw_rect(Rect2(p - Vector2(h * 0.5, w * 0.35), Vector2(h, w * 0.7)), club.kit, false, 3.0)
		return

	draw_rect(Rect2(p + Vector2(-w * 0.5, h * 0.46), Vector2(w, 5.0)), Color(0, 0, 0, 0.30))
	## PLANTED: a gold bar under his feet, the ground he is holding.
	if m.planted:
		draw_rect(Rect2(p + Vector2(-w * 0.5 - 4.0, h * 0.5 + 3.0), Vector2(w + 8.0, 3.0)), UiKit.YOU)
	## A dark void around every silhouette so two overlapping men never fuse into
	## one shape. This is what keeps a four-man pile readable on a phone.
	draw_rect(Rect2(p - Vector2(w * 0.5 + 2.0, h * 0.5 + 2.0), Vector2(w + 4.0, h + 4.0)),
		Color(0, 0, 0, 0.55))
	draw_rect(Rect2(p - Vector2(w * 0.5, h * 0.5), Vector2(w, h)), Tuning.COL_STEEL_DARK)
	draw_rect(Rect2(p - Vector2(w * 0.5 - 3.0, h * 0.5 - 4.0), Vector2(w - 6.0, h - 8.0)), club.kit)
	_draw_mark(p, club, w - 8.0)
	## HIS SHIRT NUMBER, beside him (blind review rounds 2 and 3): the cards
	## along the bottom say "#3 Kerrigan" and the list had no #3 on it.
	if m.team == 0:
		var np := p + Vector2(-w * 0.5 - 20.0, 5.0)
		UiKit.raw(self, font, np + Vector2(1, 1), "%d" % m.card.number, HORIZONTAL_ALIGNMENT_RIGHT, 16, 13, Color(0, 0, 0, 0.8))
		UiKit.raw(self, font, np, "%d" % m.card.number, HORIZONTAL_ALIGNMENT_RIGHT, 16, 13, COL_INK)
	draw_rect(Rect2(p - Vector2(7.0, h * 0.5 + 7.0), Vector2(14.0, 9.0)), Tuning.COL_STEEL)
	draw_rect(Rect2(p - Vector2(6.0, h * 0.5 + 4.0), Vector2(12.0, 3.0)), Tuning.COL_STEEL_DARK)
	## HIS WEAPON, until the sprites say it: a pole along his side, or a shield
	## square on his arm. Placeholder primitives, like the rest of him.
	var side := 1.0 if m.team == 0 else -1.0
	if m.card != null and m.card.weapon == Tuning.Weapon.POLEARM:
		draw_rect(Rect2(p + Vector2(side * (w * 0.5 + 1.0) - 1.5, -h * 0.5 - 8.0),
			Vector2(3.0, h + 12.0)), Tuning.COL_STEEL)
	else:
		draw_rect(Rect2(p + Vector2(side * (w * 0.5 - 2.0) - 5.0, -6.0),
			Vector2(10.0, 12.0)), Tuning.COL_STEEL_DARK)

	## Two slivers under his feet: gas, then stability. Stability is what a Hit
	## spends, so it has to be visible or Hit is an invisible investment.
	var bw := w + 2.0
	var x0 := p.x - bw * 0.5
	var y0 := p.y + h * 0.5 + 7.0
	draw_rect(Rect2(Vector2(x0, y0), Vector2(bw, 3.0)), Color(0, 0, 0, 0.40))
	draw_rect(Rect2(Vector2(x0, y0), Vector2(bw * m.gas_frac(), 3.0)),
		COL_HOT if m.gas_frac() < m.gassed_line() else COL_GOOD)
	draw_rect(Rect2(Vector2(x0, y0 + 4.0), Vector2(bw, 2.0)), Color(0, 0, 0, 0.40))
	draw_rect(Rect2(Vector2(x0, y0 + 4.0), Vector2(bw * m.stability, 2.0)), Tuning.COL_STEEL)

	if m.exposed_t > 0.0:
		draw_arc(p, 20.0, 0.0, TAU, 20, COL_HOT * Color(1, 1, 1, 0.8), 2.0)
	if m.under_orders():
		draw_rect(Rect2(p - Vector2(w * 0.5 + 4.0, h * 0.5 + 4.0), Vector2(w + 8.0, h + 8.0)),
			Tuning.COL_ROUTE, false, 2.0)


## The club's mark on a surcoat. This used to be a second, slightly different
## match statement from the one in UiKit — which is how a club could wear one
## mark on the league table and another in the fight. One function now.
func _draw_mark(p: Vector2, club, s: float) -> void:
	IconBank.draw_icon(self, p, s * 0.5, club.icon_color, club.kit, club.icon)


# ------------------------------------------------------------ the contact wheel
## WHO IS ASKING. A man YOU sent (not a play's route), at contact — the approach
## or third-man question, not the clinch menu, whose clock is the clinch's own.
func _wheel_candidate() -> int:
	if not Tuning.contact_wheel or screen != Screen.FIGHT or skipping:
		return -1
	for m in sim.men:
		if m.team != 0 or m.prompt == null or m.prompt.by_player or m.prompt.committed:
			continue
		if m.prompt.menu == Tuning.Menu.GRAPPLED:
			continue
		if not m.under_orders() or m.order.from_play:
			continue
		return m.idx
	return -1


## The ring's options: his three acts, then Cancel (-1).
func _wheel_opts(m) -> Array:
	var out: Array = Tuning.acts_for(m.prompt.menu).duplicate()
	out.append(-1)
	return out


## THE GUARD TRIANGLE (Pete, 29 Sep 2026: "Yep, I like yours" — wheel #11).
## For Honor's three-sided guard hugging the man: one thick arc per act, up,
## right and left, with the man visible in the hole; Gameface's gold indicator
## arc rides outside whichever side the thumb is on; Cancel sits in the open
## bottom quarter. Every side carries its own name, chance and effect, so a
## tap never needs a hover to be informed.
const WHEEL_RI := 36.0      ## inner edge of a side — clears the man's own circle
const WHEEL_RO := 80.0      ## outer edge: 44px of thumb, the touch floor
const WHEEL_HALF := 43.0    ## each side spans ±43°, a 4° gap between sides
const WHEEL_LABEL := 110.0  ## where a side's words start, from the centre
const WHEEL_CANCEL := Vector2(96.0, 36.0)
## Direction of each option, degrees clockwise from up: acts 0/1/2, then Cancel.
const WHEEL_DIRS := [0.0, 90.0, 270.0, 180.0]
var wheel_hot := -2


func _wheel_center(m) -> Vector2:
	var p := _to_screen(m.pos)
	## Room for the ring and its words on every side, so no option leaves the list.
	## Above: the top side and its three lines. Below: Cancel and the drag hint.
	var lo := LIST_ORIGIN + Vector2(WHEEL_LABEL + 180.0, WHEEL_RO + 70.0)
	var hi := LIST_ORIGIN + Vector2(Tuning.LIST_H, Tuning.LIST_W) * LIST_SCALE \
		- Vector2(WHEEL_LABEL + 180.0, WHEEL_RI + 80.0)
	return Vector2(clampf(p.x, lo.x, minf(hi.x, maxf(lo.x, hi.x))),
		clampf(p.y, lo.y, maxf(lo.y, hi.y)))


static func _dir(deg: float) -> Vector2:
	var a := deg_to_rad(deg - 90.0)
	return Vector2(cos(a), sin(a))


## Cancel's chip, in the open bottom quarter.
func _wheel_cancel_rect(m) -> Rect2:
	var c := _wheel_center(m)
	return Rect2(c + Vector2(-WHEEL_CANCEL.x * 0.5, WHEEL_RI + 30.0), WHEEL_CANCEL)


## Which option is under a point: an act, -1 for Cancel, -2 for none. A tap
## counts anywhere on a side or on its words; with `by_direction`, a drag
## released anywhere past the man's own circle counts as the side it points at.
func _wheel_option_at(m, p: Vector2, by_direction: bool = false) -> int:
	var opts := _wheel_opts(m)
	if _wheel_cancel_rect(m).grow(4.0).has_point(p):
		return -1
	var v := p - _wheel_center(m)
	var d := v.length()
	var reach := WHEEL_LABEL + 60.0
	if d < 26.0 or (not by_direction and (d < WHEEL_RI - 6.0 or d > reach)):
		return -2
	var ang := fposmod(rad_to_deg(atan2(v.y, v.x)) + 90.0, 360.0)
	var best := -1
	var best_off := 999.0
	for i in opts.size():
		var off := absf(angle_difference(deg_to_rad(ang), deg_to_rad(WHEEL_DIRS[i])))
		off = rad_to_deg(off)
		if off < best_off:
			best_off = off
			best = i
	if not by_direction and opts[best] == -1:
		return -2    ## the bottom quarter only answers through its chip
	return opts[best]


func _wheel_answer(m, opt: int) -> void:
	if opt == -1:
		sim.cancel_order(m.idx)
	else:
		sim.answer_prompt(m.idx, opt)
	Audio.play("tap")
	wheel_man = _wheel_candidate()


## GREEN, YELLOW, RED — the chance an option lands.
func _odds_col(p: float) -> Color:
	if p >= 0.6:
		return UiKit.UP
	if p >= 0.35:
		return UiKit.YOU
	## A LONG SHOT IS A RISK, and says so (round 8: 5% in white read as neutral).
	return UiKit.DOWN.lightened(0.2)


func _draw_wheel(m) -> void:
	## The fight stops behind it: a dimmer over the list, the man and his target
	## lit, and a line between them.
	draw_rect(Rect2(Vector2(-off_x, -off_y), UiKit.screen()), Color(0, 0, 0, 0.45))
	var t = sim.men[m.prompt.target]
	var c := _wheel_center(m)
	## WHO IS IN IT, IN THE HUB (review round 3: "the wheel covers the target" —
	## the two men stood in the hole, one sprite over the other). The hub is a
	## plate now, with your man and his target side by side on it; a target far
	## enough out to be seen past the ring keeps the line and circle to him.
	var tp := _to_screen(t.pos)
	if tp.distance_to(c) > WHEEL_RO + 12.0:
		draw_line(c, tp, COL_HOT, 2.0)
		draw_arc(tp, 22.0, 0.0, TAU, 24, COL_HOT, 2.0)
	## RI + 6 under the sides, so the open bottom quarter is covered too.
	draw_circle(c, WHEEL_RI + 6.0, COL_PANEL)
	draw_arc(c, WHEEL_RI + 6.0, 0.0, TAU, 32, COL_EDGE, 2.0)
	var mine := c + Vector2(-14.0, 0.0)
	var his := c + Vector2(14.0, 0.0)
	draw_line(mine, his, COL_HOT, 2.0)
	draw_circle(mine, 11.0, UiKit.YOU)
	UiKit.raw(self, font, mine + Vector2(-11.0, 5.0), "%d" % (m.card.number if m.card != null else m.idx + 1),
		HORIZONTAL_ALIGNMENT_CENTER, 22, 13, UiKit.BG)
	draw_circle(his, 11.0, COL_PANEL)
	draw_arc(his, 11.0, 0.0, TAU, 20, COL_HOT, 3.0)
	var behind: bool = sim.from_behind(m, t)
	if behind:
		UiKit.raw(self, font, c + Vector2(-80, WHEEL_RI + 76.0), UiKit.t("FROM BEHIND"),
			HORIZONTAL_ALIGNMENT_CENTER, 160, 13, UiKit.UP)
	## EVERY SIDE READS THE SAME WAY: the act, its chance, what it does.
	var opts := _wheel_opts(m)
	for i in opts.size():
		var act: int = opts[i]
		var hot: bool = act == wheel_hot
		if act == -1:
			var cr := _wheel_cancel_rect(m)
			draw_rect(cr, UiKit.YOU if hot else COL_PANEL)
			draw_rect(cr, COL_DIM, false, 2.0)
			UiKit.raw(self, font, cr.position + Vector2(0, 24), UiKit.t("Cancel"),
				HORIZONTAL_ALIGNMENT_CENTER, int(cr.size.x), 14, UiKit.BG if hot else COL_INK)
			continue
		var deg: float = WHEEL_DIRS[i]
		## The side: a thick arc as a polygon, ±WHEEL_HALF around its direction.
		var pts := PackedVector2Array()
		var steps := 12
		for k in steps + 1:
			pts.append(c + _dir(deg - WHEEL_HALF + 2.0 * WHEEL_HALF * float(k) / float(steps)) * WHEEL_RO)
		for k in steps + 1:
			pts.append(c + _dir(deg + WHEEL_HALF - 2.0 * WHEEL_HALF * float(k) / float(steps)) * WHEEL_RI)
		draw_colored_polygon(pts, UiKit.YOU if hot else UiKit.SELECT)
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, COL_DIM if not hot else UiKit.YOU.lightened(0.3), 2.0)
		if hot:
			## Gameface's indicator: a gold arc outside the side under the thumb.
			var a0 := deg_to_rad(deg - 90.0 - WHEEL_HALF - 4.0)
			draw_arc(c, WHEEL_RO + 9.0, a0, a0 + deg_to_rad(2.0 * WHEEL_HALF + 8.0), 24, UiKit.YOU, 4.0)
		UiKit.icon(self, _act_mark(act), c + _dir(deg) * ((WHEEL_RI + WHEEL_RO) * 0.5) - Vector2(16, 16),
			UiKit.BG if hot else COL_INK, 2)
		var o: Dictionary = sim.contact_odds(m.idx, act, t.idx)
		var p_land := 1.0
		var effect := ""
		var effect_col := COL_DIM
		match act:
			Tuning.Act.HIT:
				effect = UiKit.t("his balance -%d%%") % int(round(float(o["dent"]) * 100.0))
			Tuning.Act.GRAPPLE:
				effect = UiKit.t("then takedown %d%%") % int(round(float(o["p"]) * 100.0))
			Tuning.Act.BREAK:
				effect = UiKit.t("frees your man")
			Tuning.Act.BULLRUSH:
				p_land = float(o["p"])
				if float(o["fall"]) > 0.0:
					## THE RED ONE (Pete): the bullrush that bounces off and puts HIM down.
					effect = UiKit.t("fall %d%%") % int(round(float(o["fall"]) * 100.0))
					effect_col = UiKit.DOWN
				else:
					effect = UiKit.t("puts him down")
			_:
				p_land = float(o["p"])
				effect = UiKit.t("puts him down")
		## The words sit outside the side: above the top one, beside the others,
		## aligned away from the ring so they never cross it.
		var lw := 176.0
		var at := c + _dir(deg) * WHEEL_LABEL
		var align := HORIZONTAL_ALIGNMENT_CENTER
		var top := at.y - 8.0
		if deg == 0.0:
			## CLEAR OF THE RING (round 10: the labels touched it).
			at = c + Vector2(-lw * 0.5, -WHEEL_RO)
			top = at.y - 66.0
		elif deg == 90.0:
			align = HORIZONTAL_ALIGNMENT_LEFT
			top = at.y - 22.0
		else:
			at.x -= lw
			align = HORIZONTAL_ALIGNMENT_RIGHT
			top = at.y - 22.0
		## A PLATE UNDER THE WORDS, so they read over a sprite or a line.
		var chance_s := UiKit.t("%d%% chance") % int(round(p_land * 100.0))
		var tw := maxf(font.get_string_size(Tuning.act_name(act), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x,
			maxf(font.get_string_size(chance_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x,
				font.get_string_size(effect, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)) + 10.0
		var px0 := at.x + (lw - tw) * 0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else (
			at.x - 5.0 if align == HORIZONTAL_ALIGNMENT_LEFT else at.x + lw - tw + 5.0)
		draw_rect(Rect2(px0, top - 1.0, tw, 52.0), Color(COL_PANEL, 0.82))
		UiKit.raw(self, font, Vector2(at.x, top + 14.0), Tuning.act_name(act), align, int(lw), 16,
			UiKit.YOU if hot else COL_INK)
		UiKit.raw(self, font, Vector2(at.x, top + 31.0), chance_s,
			align, int(lw), 14, _odds_col(p_land))
		UiKit.raw(self, font, Vector2(at.x, top + 47.0), effect, align, int(lw), 14, effect_col)
	if wheel_drag and wheel_hot != -2:
		UiKit.raw(self, font, c + Vector2(-120, WHEEL_RI + (94.0 if behind else 76.0)),
			UiKit.t("Lift to commit") if wheel_hot != -1 else UiKit.t("Lift to cancel"),
			HORIZONTAL_ALIGNMENT_CENTER, 240, 13, COL_DIM)


## The mark on each side of the guard triangle.
static func _act_mark(act: int) -> String:
	match act:
		## EACH MARK READS AS ITS WORD (review round 3: the round shield read as
		## a target, and a padlock as anything but a clinch).
		Tuning.Act.BULLRUSH: return "shield"
		Tuning.Act.GRAPPLE: return "fist"
		Tuning.Act.HIT: return "sword"
		Tuning.Act.TAKEDOWN: return "down"
		Tuning.Act.HOLD: return "lock"
		Tuning.Act.ESCAPE: return "boot"
		Tuning.Act.BREAK: return "gate"
	return "cursor"


# ------------------------------------------------------------------ prompts
func _prompt_rect(m, i: int) -> Rect2:
	var p := _to_screen(m.pos)
	var w := 84.0
	var h := 30.0
	var total := w * 3.0 + 8.0
	## Kept inside the LIST rather than inside the screen: the right-hand third is
	## the roster strip, and a prompt drifting over it would cover the very cards
	## that tell you who you are about to commit.
	var x := clampf(p.x - total * 0.5, LIST_ORIGIN.x,
		LIST_ORIGIN.x + Tuning.LIST_H * LIST_SCALE - total - 6.0)
	var y := clampf(p.y - 46.0, LIST_ORIGIN.y + 4.0,
		LIST_ORIGIN.y + Tuning.LIST_W * LIST_SCALE - h - 6.0)
	return Rect2(Vector2(x + float(i) * (w + 4.0), y), Vector2(w, h))


func _draw_prompt(m) -> void:
	var acts: Array = Tuning.acts_for(m.prompt.menu)
	## A CLINCHED MAN GETTING READY (29 Sep 2026). The sim takes no clinch
	## answer until the clinch clock allows one (`MeleeSim.clinch_ready`), so the
	## menu says so: the buttons are faded and the bar above them fills toward
	## ready instead of running down. A tap on a faded button does nothing,
	## which it must be seen to do.
	var waiting: bool = m.prompt.menu == Tuning.Menu.GRAPPLED and not sim.clinch_ready(m)
	var fade := Color(1, 1, 1, 0.4 if waiting else 1.0)
	for i in acts.size():
		var r := _prompt_rect(m, i)
		var chosen: bool = acts[i] == m.prompt.choice
		## The AI's answer is already in the box, highlighted. Letting the timer
		## run is not a forfeit — it is a delegation, and it should look like one.
		draw_rect(r, COL_PANEL)
		draw_rect(r, (Tuning.COL_ROUTE if chosen else COL_EDGE) * fade, false, 2.0)
		UiKit.raw(self, font, r.position + Vector2(0, 20), Tuning.act_name(acts[i]),
			HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 15,
			(COL_INK if chosen else COL_DIM) * fade)
	var first := _prompt_rect(m, 0)
	var frac := clampf(m.prompt.t / Tuning.PROMPT_TIME, 0.0, 1.0)
	var bar_col := Tuning.COL_ROUTE * Color(1, 1, 1, 0.7)
	if waiting:
		frac = clampf(1.0 - m.next_act / float(Tuning.ACT_CLINCH[1]), 0.0, 1.0)
		bar_col = COL_DIM * Color(1, 1, 1, 0.7)
	draw_rect(Rect2(first.position + Vector2(0, -5.0),
		Vector2((84.0 * 3.0 + 8.0) * frac, 3.0)), bar_col)


## WHAT WE ARE ACTUALLY IN. The HUD read `Tuning.FORMATIONS[sim.formations[0]]`,
## which is the shape the discarded panel picked — so in every season bout it
## named a formation the men were not standing in, and a shape drawn on the
## Chalkboard could never be named at all.
func _our_shape_name() -> String:
	if Session.season != null:
		return Session.season.board.formation_name(Session.season.formation_id)
	return String(Tuning.FORMATIONS[sim.formations[0]]["name"])


# --------------------------------------------------------------------- HUD
func _draw_scoreboard() -> void:
	var us = sim.clubs[0]
	var them = sim.clubs[1]
	var clock: float = maxf(0.0, Tuning.ROUND_TIME - sim.round_t)
	## The score lives on the banners now — a scoreline in the top corners and a
	## club standing down each side was the same fact printed twice.
	UiKit.raw(self, font, Vector2(0, 30), UiKit.t("R%d  %d:%02d") % [sim.round_no, int(clock) / 60, int(clock) % 60],
		HORIZONTAL_ALIGNMENT_CENTER, int(SCREEN.x), 22, COL_INK)
	UiKit.raw(self, font, Vector2(0, 50), UiKit.t("%s   |   %s") % [
		_our_shape_name(),
		Tuning.STRATEGIES[sim.strategies[0]]["name"],
	], HORIZONTAL_ALIGNMENT_CENTER, int(SCREEN.x), 14, COL_DIM)
	_draw_banner(0, 12.0, us)
	_draw_banner(1, SCREEN.x - 12.0 - BANNER_W, them)


## A club standing down its own side of the list: its arms, its name, the rounds
## it has taken, and how many of its men are still on their feet.
##
## The rounds are drawn as pips rather than a number because a best-of-three has
## exactly three of them — a number makes you read it, three lamps make you
## glance at it, and this is a thing you check without looking away from a fight.
func _draw_banner(team: int, x: float, club) -> void:
	var h := (STRIP_Y - 8.0) - BANNER_TOP
	var r := Rect2(x, BANNER_TOP, BANNER_W, h)
	draw_rect(r, COL_PANEL)
	draw_rect(r, club.kit.darkened(0.35), false, 2.0)
	## A band of the club's own color across the top, so the two sides of the
	## screen are told apart by the same thing that tells the men apart.
	draw_rect(Rect2(x, BANNER_TOP, BANNER_W, 5.0), club.kit)

	var cx := x + BANNER_W * 0.5
	## The club's kit, then its mark on top — the same two-color badge the
	## men are wearing, at a size you can read from the other side of a room.
	draw_rect(Rect2(cx - 32.0, BANNER_TOP + 30.0, 64.0, 64.0), club.kit)
	draw_rect(Rect2(cx - 32.0, BANNER_TOP + 30.0, 64.0, 64.0), COL_EDGE, false, 2.0)
	_draw_mark(Vector2(cx, BANNER_TOP + 62.0), club, 46.0)
	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 118.0), club.short_name,
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 26, COL_INK)

	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 152.0), UiKit.t("ROUNDS"),
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 11, COL_DIM)
	for i in Tuning.BOUT_WINS:
		var px := cx - 15.0 + float(i) * 30.0
		var lit: bool = i < sim.rounds_won[team]
		draw_rect(Rect2(px - 9.0, BANNER_TOP + 162.0, 18.0, 18.0),
			Tuning.COL_MARSHAL if lit else Color("221e1a"))
		draw_rect(Rect2(px - 9.0, BANNER_TOP + 162.0, 18.0, 18.0), COL_EDGE, false, 1.0)

	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 216.0), UiKit.t("STANDING"),
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 11, COL_DIM)
	var up := sim.standing_count(team)
	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 250.0), "%d" % up,
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 34,
		COL_INK if up > 1 else COL_HOT)
	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 272.0), UiKit.t("of %d") % _line_size(team),
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 12, COL_DIM)

	## What this side has put down THIS round — the round's actual score, and the
	## number the stop rule is watching. Standing tells you how you are; downs
	## tells you how close it is to over.
	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 316.0), UiKit.t("DOWNS"),
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 11, COL_DIM)
	UiKit.raw(self, font, Vector2(x, BANNER_TOP + 346.0), "%d" % sim.round_downs[team],
		HORIZONTAL_ALIGNMENT_CENTER, int(BANNER_W), 26, COL_GOOD if sim.round_downs[team] > 0 else COL_DIM)


func _card_rect(i: int) -> Rect2:
	return Rect2(Vector2(STRIP_X + float(i) * (CARD_W + CARD_GAP), STRIP_Y),
		Vector2(CARD_W, CARD_H))


## How many men a side actually put on the line (a short line fields four).
func _line_size(team: int) -> int:
	var n := 0
	for mm in sim.men:
		if mm.team == team:
			n += 1
	return n


func _draw_strip() -> void:
	## YOUR MEN ONLY, however many there are. A short line of four made card five
	## the opposition's first fighter.
	var mine: Array[MeleeSim.Man] = []
	for mm in sim.men:
		if mm.team == 0:
			mine.append(mm)
	for i in mini(5, mine.size()):
		var m: MeleeSim.Man = mine[i]
		var r := _card_rect(i)
		var live: bool = m.standing()
		draw_rect(r, COL_PANEL if live else Color("1a1714"))
		draw_rect(r, Tuning.COL_ROUTE if m.under_orders() else COL_EDGE, false,
			2.0 if m.under_orders() else 1.0)
		var ink := COL_INK if live else Color("5a5148")
		UiKit.raw(self, font, r.position + Vector2(10, 22), UiKit.t("#%d %s") % [m.card.number, m.card.display_name],
			HORIZONTAL_ALIGNMENT_LEFT, int(CARD_W - 16), 15, ink)
		UiKit.raw(self, font, r.position + Vector2(10, 42), m.card.pos_name(),
			HORIZONTAL_ALIGNMENT_LEFT, int(CARD_W - 16), 14, COL_DIM)
		## HIS AFTERNOON SO FAR, right-aligned onto the position line — which
		## carries one short word and has had the rest of its width doing nothing
		## since the strip was built. Silent at nought and nought, because a card
		## that says "0 down · 0 assists" on every man for the first ninety
		## seconds is five lines of chrome telling you nothing has happened yet.
		var tally := _tally(m)
		if tally != "":
			## CLEAR OF THE POSITION WORD (first-timer test, 1 Oct: "Center" and
			## "1 down · 1 assist" printed over each other).
			var room := CARD_W - 20.0 - font.get_string_size(m.card.pos_name(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x - 8.0
			if font.get_string_size(tally, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > room:
				## The downs first: they are the number the stop rule watches.
				tally = UiKit.fit(font, tally.split(" · ")[0], 13, room)
			UiKit.raw(self, font, r.position + Vector2(10, 42), tally,
				HORIZONTAL_ALIGNMENT_RIGHT, int(CARD_W - 20), 13,
				COL_GOOD if live else Color("5a5148"))
		var s := UiKit.t("down")
		if m.state == MeleeSim.State.GRAPPLED:
			s = UiKit.t("clinched")
		elif m.under_orders():
			s = UiKit.t("on a route")
		elif m.state == MeleeSim.State.RECOVER:
			s = UiKit.t("breathing")
		elif m.planted:
			s = UiKit.t("holding ground")
		elif live:
			s = UiKit.t("on his own")
		UiKit.raw(self, font, r.position + Vector2(10, 60), s, HORIZONTAL_ALIGNMENT_LEFT,
			int(CARD_W - 16), 13,
			Tuning.COL_ROUTE if m.under_orders() else COL_DIM)
		var g := m.gas_frac()
		draw_rect(Rect2(r.position + Vector2(10, 68), Vector2(CARD_W - 20, 7)), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(r.position + Vector2(10, 68), Vector2((CARD_W - 20) * g, 7)),
			(COL_HOT if g < m.gassed_line() else COL_GOOD) if live else Color("3a3630"))


## WHAT HE HAS DONE, IN AS FEW WORDS AS IT TAKES.
##
## Assists exist because Pete asked for them — *"Assists can be 2nd most damage
## or effect on enemy"* — and an assist that is counted, banked to the card and
## never shown on the screen where it happens is a number the player has to be
## told about rather than one he watches arrive.
func _tally(m) -> String:
	var bits: Array[String] = []
	if m.downs_caused > 0:
		bits.append(UiKit.t("%d down") % m.downs_caused)
	if m.assists > 0:
		bits.append(UiKit.tn("%d assist", "%d assists", m.assists) % m.assists)
	return " · ".join(bits)


## The gutters either side of the list. They exist because the list is square in
## a 16:9 frame, so rather than leave them empty they carry the two things a
## player reads without looking away from the fight: what he can do, and what he
## has done.
## What you can do, and what you have done. Both ride on the HUD's second line,
## in the space either side of the centerd fixture text — the gutters they used
## to live in are gone now that the list fills the frame, and that is the trade
## worth making: the fight gets the screen and the chrome gets the margins.
## THE BIG FIRST-ORDER HINT IS FOR THE FIRST BOUT ONLY (playtest 30 Sep: "no
## longer useful after the first fight"). A career that has fought has read it.
func _veteran() -> bool:
	return _season() != null and _season().first_bout_done()


func _draw_hint() -> void:
	var open := 0
	for m in sim.men:
		if m.prompt != null:
			open += 1
	## SHORTER, so it is never cut (first-timer test, 1 Oct: "Tap him to." lost
	## its last two words).
	var msg := UiKit.t("Drag a man to send him. Tap to hold ground.")
	if drawing != -1:
		msg = UiKit.t("Release on ground, or on a man.")
	elif open > 0:
		msg = UiKit.t("Options are up — pick, or let him.")
	## 340, not 260: "Options are up — pick, or let him." lost its last word. The
	## fixture text in the middle starts at about 390.
	## NOT TWICE (round 9): while the big first-order band is up, it is the
	## instruction, and the corner line waits.
	var band_up: bool = sim.orders_issued == 0 and sim.round_no == 1 and drawing == -1 \
		and wheel_man == -1 and not held and not _veteran()
	if not band_up:
		UiKit.raw(self, font, Vector2(24, 50), UiKit.fit(font, msg, 14, 340.0), HORIZONTAL_ALIGNMENT_LEFT, 340, 14, COL_INK)
	## SAID IN WORDS (blind review round 3: "0 routes · 0 of 0 calls" unexplained).
	## NOTHING UNTIL THERE IS SOMETHING TO COUNT (round 8: "Routes 0 · choices
	## 0/0" was cryptic before the first order).
	var calls: int = sim.prompts_answered + sim.prompts_timed_out
	if sim.orders_issued > 0 or calls > 0:
		## The calls half only once there has been a call (round 9: "0 of 0").
		var said: String = UiKit.t("%d sent") % sim.orders_issued if calls == 0 \
			else UiKit.t("%d sent  ·  %d of %d choices picked") % [sim.orders_issued, sim.prompts_answered, calls]
		UiKit.raw(self, font, Vector2(SCREEN.x - 304, 50), UiKit.fit(font, said, 14, 280.0),
			HORIZONTAL_ALIGNMENT_RIGHT, 280, 14, COL_DIM)
	## THE FIRST THING TO DO, big, in the empty middle of the list until he has
	## done it once (blind review round 3: the key instruction was 10 px grey in
	## a corner).
	if sim.orders_issued == 0 and sim.round_no == 1 and drawing == -1 and wheel_man == -1 and not held and not _veteran():
		var band := Rect2(LIST_ORIGIN.x + 140.0, 190.0, Tuning.LIST_H * LIST_SCALE - 280.0, 74.0)
		draw_rect(band, Color(0, 0, 0, 0.55))
		draw_rect(band, Tuning.COL_MARSHAL, false, 2.0)
		UiKit.raw(self, font, band.position + Vector2(0, 32), UiKit.fit(font, UiKit.t("Drag from one of your fighters"), 18, band.size.x - 16.0),
			HORIZONTAL_ALIGNMENT_CENTER, int(band.size.x), 18, Tuning.COL_MARSHAL)
		UiKit.raw(self, font, band.position + Vector2(0, 56), UiKit.fit(font, UiKit.t("End on an enemy to go for him."), 14, band.size.x - 20.0),
			HORIZONTAL_ALIGNMENT_CENTER, int(band.size.x), 14, COL_INK)


## WHAT YOU HAVE LEFT, drawn as boxes rather than printed as a number, because it
## is the same question the ROUNDS pips answer on the banners and a player should
## not have to read two shapes for one kind of fact.
##
## They sit above the HOLD button whether or not the button is showing: a budget
## that vanishes when it hits zero leaves you wondering whether you had any.
func _draw_calls() -> void:
	if screen != Screen.FIGHT or calls_total <= 0:
		return
	## Left of HOLD in the top bar, right-aligned against it.
	var y := CALL_AT.y + 12.0
	## NAMED (blind review round 3: two yellow squares with no word).
	UiKit.raw(self, font, Vector2(CALL_AT.x - 12.0 - float(calls_total) * 20.0 - 130.0, y + 11.0),
		UiKit.fit(font, UiKit.t("%d HOLDS LEFT") % calls_left, 12, 126.0), HORIZONTAL_ALIGNMENT_RIGHT, 126, 12, COL_INK)
	for i in calls_total:
		var r := Rect2(CALL_AT.x - 8.0 - float(calls_total - i) * 20.0, y - 2.0, 16.0, 16.0)
		draw_rect(r, Tuning.COL_MARSHAL if i < calls_left else Color("221e1a"))
		draw_rect(r, COL_EDGE, false, 1.0)


## THE FIGHT IS STOPPED, and the screen has to say so loudly enough that nobody
## thinks the game has hung. A band across the list, the word, and the seconds
## running out of it.
func _draw_held() -> void:
	if not held:
		return
	var band := Rect2(LIST_ORIGIN.x, 196.0, Tuning.LIST_H * LIST_SCALE, 62.0)
	draw_rect(band, Color(0, 0, 0, 0.62))
	draw_rect(band, Tuning.COL_MARSHAL, false, 2.0)
	UiKit.raw(self, font, Vector2(band.position.x, band.position.y + 30.0), UiKit.t("HOLD"),
		HORIZONTAL_ALIGNMENT_CENTER, int(band.size.x), 26, Tuning.COL_MARSHAL)
	UiKit.raw(self, font, Vector2(band.position.x, band.position.y + 52.0),
		UiKit.t("give one man an order · %.1fs") % maxf(0.0, hold_t),
		HORIZONTAL_ALIGNMENT_CENTER, int(band.size.x), 14, COL_INK)


# ------------------------------------------------------------ coach marks
## TWO, AND ONCE EACH (Pete, 29 Sep 2026, #5: "Draw a route" and "The corner").
## Only in a career bout — a standalone exhibition never stops for one, and the
## test runner turns them off (`Settings.tips_enabled`).
## Literal `t()` calls, so the string extractor sees them.
static func _tip_words(key: String) -> Array[String]:
	## THE WHEEL, the first time it opens (1 Oct novice report, Pete approved):
	## first-timers did not know the sides were choices, that the timer picks
	## for them, or what "N of M choices picked" was counting.
	if key == "wheel":
		return [UiKit.t("A choice"),
			UiKit.t("Your man has reached an enemy. Tap a side of the wheel to choose what he does; each side shows its chance. Leave it and he chooses himself. HOLD stops the fight so you can give an order. \"N of M choices picked\" counts the choices you made.")]
	if key == "corner":
		return [UiKit.t("The corner"),
			UiKit.t("Swap a tired man for one from the bench and change the plan. When the clock runs out they go back in.")]
	return [UiKit.t("Send a fighter"),
		UiKit.t("Drag from one of your men to an enemy, or to open ground. He goes; the rest fight on their own.")]


func _maybe_tip() -> void:
	if tip != "" or Session.season == null:
		return
	var key := ""
	if screen == Screen.FIGHT and wheel_man != -1 and Settings.tip_due("wheel"):
		key = "wheel"
	elif screen == Screen.FIGHT and sim.phase == MeleeSim.Phase.LIVE:
		key = "route"
	elif screen == Screen.CORNER and sim.phase == MeleeSim.Phase.CORNER:
		key = "corner"
	if key == "" or not Settings.tip_due(key):
		return
	_show_tip(key)


func _show_tip(key: String) -> void:
	tip = key
	tip_layer = CanvasLayer.new()
	tip_layer.layer = 20
	add_child(tip_layer)
	## The wheel's card has five lines to say, the others three.
	var tall := 76.0 if key == "wheel" else 0.0
	var box := Rect2(SCREEN.x * 0.5 - 250.0 + off_x, 140.0 - tall * 0.5 + off_y, 500.0, 196.0 + tall)
	## A full-screen catch, so a tap meant for the tip never lands on the fight.
	var veil := Control.new()
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.size = UiKit.screen()
	veil.draw.connect(func() -> void:
		veil.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.55))
		UiKit.panel(veil, box)
		var words := _tip_words(key)
		UiKit.text(veil, font, words[0], box.position + Vector2(24, 40), 20, UiKit.YOU)
		UiKit.para(veil, font, words[1], box.position + Vector2(24, 72), 14,
			UiKit.INK, box.size.x - 48.0, 20.0, 3 if tall <= 0.0 else 6))
	tip_layer.add_child(veil)
	tip_layer.add_child(UiKit.button(UiKit.t("Got it"),
		box.position + Vector2(box.size.x - 24.0 - 150.0, box.size.y - 58.0), Vector2(150, 44),
		_close_tip))


func _close_tip() -> void:
	if tip != "":
		Settings.tip_done(tip)
	tip = ""
	if tip_layer != null:
		tip_layer.queue_free()
		tip_layer = null


# ---------------------------------------------------------------------- UI
func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	## THE TWO OVER THE GROUND. Built through `UiKit.button` like every other
	## control in the game, so they carry the same frame, the same drop and the
	## same adaptive padding — a bespoke button on one screen is how a UI starts
	## looking like two UIs.
	## MARKS FROM THE BANK, not two new ones drawn for this screen. `speaker` is a
	## shout from the corner, which is exactly what a call is; `clock` is the
	## round time the skip is spending. `test_icons.gd` scans for a mark a screen
	## asks for and cannot find, so a made-up name fails the suite rather than
	## rendering a button with a hole in it.
	call_button = UiKit.button(UiKit.t("HOLD"), CALL_AT, CALL_SIZE, _hold, "pause")
	skip_button = UiKit.button(UiKit.t("SKIP ROUND"), SKIP_AT, CALL_SIZE, _skip_round, "clock")
	call_button.visible = false
	skip_button.visible = false
	ui.add_child(call_button)
	ui.add_child(skip_button)

	panel_box = VBoxContainer.new()
	panel_box.position = Vector2(PANEL_X, 132)
	panel_box.custom_minimum_size = Vector2(PANEL_W, 0)
	panel_box.add_theme_constant_override("separation", 10)
	ui.add_child(panel_box)

	panel_title = Label.new()
	panel_box.add_child(panel_title)


	again_button = _panel_button(
		UiKit.t("Back to the club") if Session.season != null else UiKit.t("Next bout"),
		Vector2(260, 48), func():
			if Session.season != null:
				UiKit.back("res://scenes/Season.tscn")
			else:
				_new_bout(randi()))
	## Inside the report's frame (29 Sep 2026): at 476 its 48 px ran across the
	## frame's bottom edge at 522.
	again_button.position = Vector2(350, REP_PANEL.end.y - 48.0 - 14.0)
	again_button.visible = false
	ui.add_child(again_button)


## LEVELS WAITING GET A BUTTON (blind review, 29 Sep: "LEVEL UP" four times and
## no way from here to spend one). It opens the first man with one to place;
## his card has the rest.
var spend_button: Button = null


func _add_spend_button() -> void:
	if spend_button != null:
		spend_button.queue_free()
		spend_button = null
	if Session.season == null:
		return
	var waiting: Array[FighterCard] = []
	for f in Session.season.club.active_eight():
		if Career.can_place(f):
			waiting.append(f)
	if waiting.is_empty():
		UiKit.primary(again_button)
		return
	## THE POINTS, NOT THE MEN: the same count the rows add up to.
	var pts := 0
	for f in waiting:
		pts += Career.levels_banked(f)
	spend_button = UiKit.primary(UiKit.button(UiKit.t("Spend points (%d)") % pts,
		Vector2(REP_PANEL.position.x + 24.0, again_button.position.y), Vector2(260, 48), func():
			Session.viewing_fighter = waiting[0]
			Session.level_run = true
			Session.autosave()
			UiKit.go_back_to("res://scenes/Fighter.tscn", "res://scenes/Season.tscn"), "up"))
	ui.add_child(spend_button)


## EVERY BUTTON IN THE FIGHT, SKINNED LIKE EVERY OTHER BUTTON IN THE GAME.
##
## The melee built five raw `Button.new()`s and never touched them, so the
## formation picker, the corner and the report wore **Godot's default theme** —
## gray rounded rectangles with a soft gradient — while every other screen wore
## the game's. It also meant no tap sound in the one place a player taps under
## time pressure.
##
## These live inside `VBoxContainer`s and `GridContainer`s, so `UiKit.button()`
## is the wrong door — it sets an absolute position and size that a container
## then fights. `skin()` is the part that matters and it takes a bare button.
func _panel_button(text_: String, min_size: Vector2, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text_
	b.custom_minimum_size = min_size
	b.pressed.connect(func() -> void: Audio.play("tap"))
	b.pressed.connect(on_press)
	UiKit.skin(b)
	## TWO LINES NEED A GAP BETWEEN THEM. Rail sets a 14-pixel line at 16, and
	## stacked with no leading the second line's ascenders touch the first
	## line's descenders — "Rail / Ward 100%" came out as one smeared block.
	b.add_theme_constant_override("line_spacing", 4)
	return b


func _clear_panel() -> void:
	for c in panel_box.get_children():
		if c != panel_title:
			c.queue_free()


func _hide_panel() -> void:
	panel_box.visible = false


## ------------------------------------------------------------------ the book
## THE PLAYBOOK — Pete, 13 Sep 2026: *"The 'How are we coming out' should just be
## a formation and strategy playbook. Think Madden."* Then, on the mockups:
## *"Playbook 2, and make it scrollable for the custom formations and plays."*
##
## Two panes. SHAPES down the left, the plays out of the selected shape on the
## right, every one of them a real diagram rather than a word — see
## `playbook.gd` for why we can draw them at all.
##
## BOTH PANES SCROLL, and they have to, because both lists are unbounded from the
## club's side. `Chalkboard` sells four formation slots and four play slots, so a
## club that has bought them all brings seven shapes and eight calls to this
## screen; a fixed grid would be a screen that silently stops showing you things
## you paid for.
const SHAPE_COL_W := 216.0
const SHAPE_CARD := Vector2(208.0, 96.0)
const PLAY_CARD := Vector2(232.0, 128.0)
const BOOK_GAP := 8.0

## Which shape's plays the right pane is showing. It is NOT the shape you are
## running — you can leaf through the book without calling anything, which is
## what a book is for.
var book_shape: int = 0


## THE SHAPES. The three everyone has, then whatever this club has drawn. Read
## off the Chalkboard so the book and the clubhouse cannot disagree about what
## the club owns; a standalone bout has no season and gets the built-ins.
func _book_shapes() -> Array:
	var out: Array = []
	if Session.season != null:
		for c in Session.season.board.formation_choices():
			out.append({"id": int(c["id"]), "name": String(c["name"]),
				"spots": Session.season.board.spots_for(int(c["id"]))})
	else:
		for f in Tuning.FORMATIONS.keys():
			out.append({"id": int(f), "name": String(Tuning.FORMATIONS[f]["name"]),
				"spots": Tuning.FORMATIONS[f]["spots"]})
	return out


## THE CALLS OUT OF A SHAPE, in two sections, because they are two different
## things wearing the same card.
##
## A PUSH is a depth profile: it says how far up the list each man drives and it
## runs for the whole round. A PLAY is five drawn routes that fire at the charge
## and expire after `PLAN_TIME`, after which the push is what the anchors read.
## They are not alternatives in the sim — `set_plan` takes spots AND routes, and
## `strategies[team]` is live either way — so calling a play keeps the push you
## are already on rather than replacing it. The sections say so.
func _book_calls(shape_id: int) -> Array:
	var out: Array = []
	for st in Tuning.STRATEGIES.keys():
		out.append({"kind": "push", "id": int(st),
			"name": UiKit.t(String(Tuning.STRATEGIES[st]["name"])),
			"blurb": UiKit.t(String(Tuning.STRATEGIES[st]["blurb"]))})
	if Session.season != null:
		for p in Session.season.board.plays_for(shape_id):
			out.append({"kind": "play", "id": int(p["index"]), "name": String(p["name"]),
				"routes": p["routes"], "universal": bool(p["universal"])})
	return out


func _live_shape_id() -> int:
	if sim.custom_spots[0] != null and drawn_shape_id >= 0:
		return drawn_shape_id
	return sim.formations[0]


## A scroll pane with a column in it, placed inside the page.
##
## IT GOES ON A PAGE AND NOT STRAIGHT INTO `panel_box`, and that is not tidiness.
## `panel_box` is a VBoxContainer: it OWNS the position of every child it has, so
## a pane with a position set on it is a pane the container moves somewhere else
## on the next layout pass. The page is one child the VBox can place, and inside
## it the two panes sit exactly where they are put.
func _scroll_column(page: Control, at: Vector2, box: Vector2,
		sep: int = 8) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.position = at
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	## CLIP, AND SIZE AFTER THE CONTENT IS IN.
	##
	## Both of these were missing and the corner ran off the bottom of the screen.
	## A ScrollContainer recomputes its minimum size when a child arrives, so a
	## size set BEFORE the column went in was immediately overridden by the
	## column's own height — the pane grew to fit its contents, which is the one
	## thing a scroll pane must never do. And a plain Control does not clip, so
	## the cards that no longer fitted drew straight through the panel floor and
	## out the bottom of the frame.
	sc.clip_contents = true
	page.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", sep)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sc.add_child(col)
	sc.custom_minimum_size = box
	sc.size = box
	return col


## The page. `box` is the room it has; the corner gives it less than the charge
## does and the cards do not change size — the scroll takes the difference,
## which is the point of having one.
func _build_book(box: Vector2) -> void:
	var shapes := _book_shapes()
	book_shape = clampi(book_shape, 0, maxi(0, shapes.size() - 1))
	var live_shape := _live_shape_id()

	var page := Control.new()
	page.custom_minimum_size = box
	page.size = box
	page.clip_contents = true
	panel_box.add_child(page)

	## PETE, 13 SEP 2026: *"Shape - change to Formations. Out of it - Change to
	## Plays."* Done in the HTML mock the same afternoon and never carried into
	## the engine, which is the failure mode a mock has: it is the version
	## everybody looked at and not the version anybody ships.
	_col_head(page, Vector2(2.0, 0.0), "FORMATIONS")
	_col_head(page, Vector2(SHAPE_COL_W + BOOK_GAP + 2.0, 0.0), "PLAYS")
	var top := 17.0
	var inner := Vector2(box.x, box.y - top)

	## ---- the shapes
	var left := _scroll_column(page, Vector2(0.0, top), Vector2(SHAPE_COL_W, inner.y))
	for i in shapes.size():
		var sh: Dictionary = shapes[i]
		var take := i
		## NO ARROWS DOWN THE LEFT. Drawing one push on every shape card says
		## "these all run this play", which is the opposite of what the column is
		## for. It is a shape picker, so it shows the shape.
		var b := Playbook.card_button(SHAPE_CARD, sh["spots"], Playbook.Mode.SHAPE,
			null, int(sh["id"]) == live_shape, String(sh["name"]),
			func(): book_shape = take; _rebuild_book())
		left.add_child(b)

	## ---- what you can run out of it
	var calls := _book_calls(int(shapes[book_shape]["id"]))
	var right := _scroll_column(page, Vector2(SHAPE_COL_W + BOOK_GAP, top),
		Vector2(inner.x - SHAPE_COL_W - BOOK_GAP, inner.y))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(BOOK_GAP))
	grid.add_theme_constant_override("v_separation", int(BOOK_GAP))
	right.add_child(grid)
	var spots: Array = shapes[book_shape]["spots"]
	var shape_id := int(shapes[book_shape]["id"])
	var board: Chalkboard = Session.season.board if Session.season != null else null
	for c in calls:
		var call_: Dictionary = c
		var is_push: bool = String(call_["kind"]) == "push"
		var key := Chalkboard.fav_key(String(call_["kind"]), int(call_["id"]),
			String(call_["name"]))
		var starred: bool = board != null and board.is_favorite(shape_id,
			String(call_["kind"]), key)
		## IN STAR MODE THE LIT CARD IS THE STARRED ONE, not the live one. The
		## highlight means "this is the one you mean" in both modes; what it means
		## you mean is what changed.
		var on: bool = starred if starring else (shape_id == live_shape and is_push
			and sim.strategies[0] == int(call_["id"]))
		var b := Playbook.card_button(PLAY_CARD, spots,
			Playbook.Mode.STRATEGY if is_push else Playbook.Mode.PLAY,
			int(call_["id"]) if is_push else call_["routes"], on,
			## THE GAME'S OWN MARK, not an asterisk. The fighter screen tags a man
			## for the Hall with the same glyph, and two symbols for "this one is
			## picked out" is two vocabularies.
			("\u2605 " if starred else "") + String(call_["name"]),
			func(): _tap_call(shapes[book_shape], call_, key))
		b.tooltip_text = String(call_.get("blurb", UiKit.t("A play you drew.")))
		grid.add_child(b)


## ONE TAP, TWO MEANINGS, decided by the mode the book is in. Splitting it into
## two callables built at two call sites is how the grid ends up with cards that
## disagree about which mode they are in after a rebuild.
func _tap_call(shape: Dictionary, call_: Dictionary, key: String) -> void:
	if not starring:
		_choose(shape, call_)
		return
	var board: Chalkboard = Session.season.board if Session.season != null else null
	if board == null:
		return
	var err := board.toggle_favorite(int(shape["id"]), String(call_["kind"]), key)
	if err != "":
		book_note = err
		Audio.play("refuse")
	else:
		book_note = ""
		Audio.play("tap")
		Session.autosave()
	_show_playbook()


func _col_head(page: Control, at: Vector2, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.position = at
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", UiKit.DIM)
	page.add_child(l)


## Rebuild in place, keeping the panel where it is. Leafing through shapes must
## not move the page under the thumb that is doing the leafing.
func _rebuild_book() -> void:
	if screen == Screen.CORNER:
		_build_corner()
	else:
		_show_playbook()


## Time is up in the corner: go back in on what was chosen, or on the push the
## side was already running if nothing was.
func _corner_time_up() -> void:
	if chosen_call.is_empty():
		corner_done_for_round = sim.round_no
		sim.leave_corner()
		screen = Screen.FIGHT
		sub_open = -1
		_clear_corner()
		_hide_panel()
		Audio.play("confirm")
		return
	_apply_chosen()


## CHOOSE AND CALL IN ONE, which is what a tool or a probe driving the screen
## from outside wants — `tools/shot_melee.gd`, the balance probes and
## `test_book.gd` all pick a play and expect the fight to start. A player gets
## the two steps; a script gets both at once, through the same code.
func _call_from_book(shape: Dictionary, call_: Dictionary) -> void:
	chosen_shape = shape
	chosen_call = call_
	_apply_chosen()


## THE ONE PLACE THE SIM IS TOUCHED, and it lands whole — a shape and a call
## together, or the sim spends a moment holding half a decision.
##
## Every card in the game used to do this on the tap. Now the cards choose and
## FIGHT applies, which is the order Pete asked for and is also the only order in
## which a player can look at his line before committing to a plan for it.
func _apply_chosen() -> void:
	if chosen_call.is_empty():
		Audio.play("refuse")
		return
	var shape: Dictionary = chosen_shape
	var call_: Dictionary = chosen_call
	var id := int(shape["id"])
	## A BUILT-IN SHAPE CLEARS THE DRAWN SPOTS; a drawn one sets them. Either way
	## it goes THROUGH the sim rather than assigning `custom_spots` behind it —
	## `formation_spots` prefers custom spots over the named formation, so a
	## half-applied shape is a fight that quietly runs the previous one.
	var custom: bool = not Tuning.FORMATIONS.has(id)
	drawn_shape_id = id if custom else -1
	var routes = call_["routes"] if String(call_["kind"]) == "play" else null
	sim.set_plan(0, shape["spots"] if custom else null, routes)
	if not custom:
		sim.formations[0] = id
	## A PLAY DOES NOT REPLACE THE PUSH. Routes drive the charge and expire after
	## PLAN_TIME; the push is what the anchors read for the rest of the round, and
	## the sim reads `strategies[0]` either way. Calling a play on top of the push
	## you are already on is the honest behavior and what the sections promise.
	if String(call_["kind"]) == "push":
		sim.strategies[0] = int(call_["id"])
	## The opposition picks its own and you do not get told which until you see
	## the line. Formation is the one decision made blind.
	##
	## SEEDED, off the bout's own seed and the round. It was the global `randi()`,
	## so the same save gave different opposition every time FIGHT was pressed.
	var opp := RandomNumberGenerator.new()
	opp.seed = hash("opp-plan:%d:%d" % [sim.rng.seed, sim.round_no])
	sim.formations[1] = Tuning.FORMATIONS.keys()[opp.randi() % Tuning.FORMATIONS.size()]
	sim.strategies[1] = Tuning.STRATEGIES.keys()[opp.randi() % Tuning.STRATEGIES.size()]

	if sim.phase == MeleeSim.Phase.CORNER:
		corner_done_for_round = sim.round_no
		## THROUGH THE SIM, NOT AROUND IT. Calling `_set_the_line()` here would end
		## the corner without running the recovery — so calling a play would
		## silently cost every man on both sides his rest.
		sim.leave_corner()
	else:
		sim._set_the_line()
	screen = Screen.FIGHT
	sub_open = -1
	_clear_corner()
	_hide_panel()
	Audio.play("confirm")


## BEFORE THE CHARGE: the book and nothing else. The old panel chained into the
## corner, which meant a swap screen before a round that has not been fought yet
## — the line is set in the clubhouse, and a corner is for what the last round
## did to it.
func _show_playbook() -> void:
	## THE CORNER'S CONTROLS GO WITH IT. They are absolutely positioned on the
	## shared `ui` layer, so a book opened over them would be a book with five SUB
	## buttons and a FIGHT through it.
	_clear_corner()
	_clear_panel()
	var board: Chalkboard = Session.season.board if Session.season != null else null
	var starred: int = board.live_favorites().size() if board != null else 0
	panel_title.text = UiKit.t("THE PLAYBOOK — %s") % (UiKit.t("tap to star, %d of %d") % [starred,
		Chalkboard.MAX_FAVORITES] if starring else UiKit.t("pick one"))
	if book_note != "":
		panel_title.text += "   ·   " + book_note
	panel_box.visible = true
	again_button.visible = false
	## THE STRIP IS PAID FOR BY THE BOOK, not added to the panel.
	##
	## `panel_box` grows downward from a fixed y and `_draw` frames whatever
	## height it ends up with, so anything added to it comes off the bottom of a
	## 540-pixel screen rather than out of the panel — the first cut of the strip
	## pushed "Done picking favorites" half off the frame. The page scrolls; the
	## panel does not. So the page gives back exactly what the strip takes.
	_build_book(Vector2(PANEL_W, BOOK_H - (FAV_STRIP_H if starring else 0.0)))
	## THE MODE SWITCH, and it is a switch rather than a star on every card
	## because the cards sit in a GridContainer that owns their positions — an
	## overlay would be a second positioning system on the one screen that
	## already scrolls. One control, one meaning for a tap at a time.
	## THE TWO OF THEM SIDE BY SIDE. Stacked they cost eighty pixels and the panel
	## does not have eighty pixels; they are also peers — one changes what a tap
	## means, one leaves — so a row is what they are.
	if starring:
		_build_fav_strip(board)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel_box.add_child(row)
	var half := (PANEL_W - 8.0) * 0.5
	row.add_child(_panel_button(UiKit.t("Done picking favorites") if starring
		else UiKit.t("Pick favorites for the corner"), Vector2(half, 40), func():
			starring = not starring
			book_note = ""
			_show_playbook()))
	row.add_child(_panel_button(UiKit.t("Back to the corner"), Vector2(half, 40), func():
		starring = false
		book_note = ""
		_clear_panel()
		_build_corner()))



## ------------------------------------------------- the four, in corner order
## WHICH OF YOUR FOUR SITS WHERE. The corner lays the favorites out two by two
## in list order — slot 1 top-left, 2 top-right, 3 bottom-left, 4 bottom-right —
## so the list's order IS the thumb-reach order on the screen with the clock on
## it. Until now nothing could change it: a favorite landed wherever starring it
## happened to put it. `Chalkboard.promote_favorite` and `demote_favorite` were
## written and tested for this and had no caller.
##
## NOT IN THE CORNER, and that is a decision against the hand-off note, which
## suggested a pair of up/down taps beside each card there. Two reasons. The
## corner runs on `corner_t` — it is the one screen in the game with a clock on
## the player — and a control that costs seconds of the round to tidy a list is a
## control that punishes being used. And a two-by-two grid has no up and down; it
## has four positions, so arrows on it would be arrows against a direction that
## is not on the screen.
##
## Here there is no clock, the mode is already called "picking favorites", and
## the strip reads left to right in exactly the order the corner reads. One tap
## moves a card one place towards the front; the front one has nowhere to go and
## says so by being dead rather than by being absent. Four items reorder in at
## most six taps and there is no drag, which was Pete's own call on this control.
func _build_fav_strip(board: Chalkboard) -> void:
	if board == null:
		return
	var favs := board.live_favorites()
	## ONE FAVORITE HAS NO ORDER. A strip with a single dead chip on it is a
	## control that has never worked, and a player cannot tell that from one that
	## is broken.
	if favs.size() < 2:
		return
	var head := Label.new()
	head.text = UiKit.t("IN THE CORNER, IN THIS ORDER — tap to move one left")
	head.add_theme_color_override("font_color", UiKit.DIM)
	head.add_theme_font_size_override("font_size", 12)
	panel_box.add_child(head)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	panel_box.add_child(strip)
	var w := _fit(Chalkboard.MAX_FAVORITES)
	var f := UiKit.body()
	for i in favs.size():
		var take := i
		var name_ := _fav_name(favs[i])
		## THE NUMBER IS THE SLOT, and it is drawn whether or not the chip can
		## move, because the number is what the player is reading the strip for.
		var b := _panel_button("%s%d  %s" % ["\u25c0 " if i > 0 else "   ", i + 1,
			UiKit.clip_px(f, name_, 13, w - 52.0)], Vector2(w, 34.0),
			func():
				var err := board.promote_favorite(take)
				if err != "":
					book_note = err
					Audio.play("refuse")
				_show_playbook())
		b.disabled = i == 0
		strip.add_child(b)


## A favorite is `{shape, kind, key}` on the board; the name a player knows it
## by lives on the call it resolves to. `_fav_calls` already does that resolution
## for the corner, so this asks it rather than repeating the lookup — two places
## turning a favorite into a name is two places that can disagree about which
## one slot 3 is.
func _fav_name(f: Dictionary) -> String:
	var c := _fav_call(f)
	return String(c["name"]) if not c.is_empty() else String(f["key"])


## THE ONE RESOLUTION of a favorite to the call it names, or {} if the book no
## longer has it. `_fav_name` said it asked `_fav_calls` for this and then did
## the lookup again itself; both ask here now (29 Sep 2026).
func _fav_call(f: Dictionary) -> Dictionary:
	for c in _book_calls(int(f["shape"])):
		if String(c["kind"]) != String(f["kind"]):
			continue
		if Chalkboard.fav_key(String(c["kind"]), int(c["id"]),
				String(c["name"])) == String(f["key"]):
			return c
	return {}


## WHICH SLOT'S SUB BOX IS OPEN, or -1. Tap SUB beside a man, pick from the
## bench in the popup, and they change places.
var sub_open: int = -1
## The popup's own rect, so `_draw` can put a floor under it. Empty when shut.
var sub_box: Rect2 = Rect2()
var sub_for: String = ""
## THE CONTROLS THE CORNER OWNS. They are positioned absolutely on `ui` rather
## than flowed in `panel_box`, because the between-rounds screen is a two-column
## layout and a VBoxContainer owns the position of everything it holds. Kept in
## a list so leaving the corner can take all of them with it — a screen that
## builds controls onto a shared layer and does not remember which ones were its
## own leaves them on top of the next screen.
var corner_nodes: Array[Node] = []
## THE PLAY THAT IS CHOSEN AND NOT YET CALLED.
var chosen_shape: Dictionary = {}
var chosen_call: Dictionary = {}
## IS THE BOOK PICKING A PLAY OR PICKING FAVORITES? One grid, two jobs, because
## the alternative was a star control floated over every card — and the cards
## live in a GridContainer, which owns the position of everything in it, so an
## overlay would have been a second positioning system on the one screen that
## already scrolls.
var starring: bool = false
## What the book has to say back — a refusal, mostly.
var book_note: String = ""

## The corner panel is a fixed box and everything in it has to fit inside it.
## The first version let an eight-man bench size itself and it ran off the right
## of the screen into the scoreboard.
## WIDER THAN IT WAS, because the buttons in it now carry the game's own face.
## At 620 the five line buttons were 119 each and "Ward 100%" clipped to
## "Ward 100" — a condition figure truncated into a different condition figure,
## on the screen where the whole decision turns on it. The corner has a clock on
## it; there is no room for a number that lies.
const PANEL_W := 720.0
const PANEL_X := 120.0
## The book's row height inside the corner. 44 before the charge, where the page
## has the panel to itself.
## How tall the page is in each place. The corner is sharing the panel with the
## line, the bench and the swap note, so it gets less — and scrolls more.
## 268 AND NOT 300. The playbook gained two buttons under it — the favorites
## switch and the way back to the corner — and at 300 the panel ran to y 566 of a
## 540 frame with "Back to the corner" off the bottom of the screen. The page is
## what gives way, because the buttons are the part you cannot scroll to.
const BOOK_H := 268.0
## 176 and not 196. At 196 the panel ran to y 530 of a 540 frame — inside the
## edge, so the sweep passed it, and close enough to it that the half-card the
## scroll was cutting read as the screen running out rather than as a list
## continuing. A cut card wants somewhere to be cut.
const BOOK_H_CORNER := 176.0
## WHAT THE FAVORITE STRIP COSTS the page above it: its heading, its row of
## chips, and the two `separation` gaps the VBox puts around them. Written once
## and subtracted once — the pair of numbers this replaces would have been the
## strip's real height and the book's guess at it, which is the shape of bug
## section 19 of the register is about.
const FAV_STRIP_H := 68.0


func _fit(n: int) -> float:
	return (PANEL_W - float(maxi(0, n - 1)) * 6.0) / float(maxi(1, n))


## THE CORNER, AND THE HALF OF IT THAT DID NOT EXIST.
##
## `MeleeSim.swap_in` has been written, commented and correct since the sim was
## built — and had **no caller anywhere in the project**. Decision 10.3a is
## locked, in Pete's own words: *"You should be able to swap fighters between
## rounds from the bench anyway. We'll be taking that from ACRTW."* The rule was
## in the design doc, the code was in the sim, and the two were never introduced.
##
## It is also not a small feature. The reason to swap is WIND: a man who fought
## the round recovers 30% of his tank in the corner and a man who sat it out
## recovers 62%. That gap is the whole argument for carrying eight men, and
## without a way to spend it the bench was decoration for the entire life of
## this game.
func _show_strategy_panel() -> void:
	_clear_panel()
	_clear_corner()
	sub_open = -1
	## AND IT SAYS WHICH SCREEN THIS IS. It did not, and that is #9 and #10 of
	## Pete's 15 Sep playtest in one line.
	##
	## The walk-out button called this and nothing else. So the controls became
	## the pre-fight's — five SUB boxes, four play cards, FULL PLAYBOOK, FIGHT —
	## while `screen` was still `SPLASH`, and `_draw` went on painting the two
	## crests, the records and *"Your crowd."* underneath them. Pete's shot shows
	## exactly that: a playbook floating over a walk-out.
	##
	## It came right on the next thing he touched, because `_choose()` sets the
	## screen — which is why he wrote *"I clicked and the rest of the playbook
	## appeared"* and guessed it was a redraw bug. It was a screen that had never
	## been told it had changed.
	##
	## Same expression `_choose` uses, and that is the point: two places deciding
	## which of these two screens this is were always going to disagree, and for
	## a while only one of them was deciding at all.
	screen = Screen.CORNER if sim.phase == MeleeSim.Phase.CORNER else Screen.PREFIGHT
	## The round is over and the panel covers the list; anything still rising off
	## it is a number that has been overtaken by the screen reporting on it.
	Juice.clear_pops()
	_build_corner()


# ------------------------------------------------------------------ splash
## THE WALK-OUT, and the one screen that says where this is being fought.
##
## Three dressings of one screen: your own arena at the level you have built it
## to, somebody else's ground, or a tournament ground. Both badges, both names,
## both records, the venue under them, and a button that says what the
## afternoon is.
##
## It reads `season` where there is one and degrades to the two clubs' own names
## where there is not, because `Melee.tscn` run on its own is still a thing this
## screen supports and a splash that crashed the standalone bout would be a
## screen that only works inside the game it is part of.
const SPLASH_GO := Vector2(330.0, 462.0)
const SPLASH_GO_SIZE := Vector2(300.0, 52.0)


## -1 for "ask the season", or a `Venue.Kind` to force. Only `shot_splash.gd`
## sets it: which venue comes up is the fixture list's business, and a tool that
## plays a season until it gets an away day is a tool nobody runs.
var forced_venue: int = -1


## This scene has never had a `season` field — it reads `Session.season`, and it
## has to keep working when there is none, because `Melee.tscn` on its own is
## still a supported way to run a bout.
func _season() -> Season:
	return Session.season


func _venue_kind() -> int:
	if forced_venue >= 0:
		return forced_venue
	return _season().venue_kind() if _season() != null else Venue.Kind.HOME


func _show_splash() -> void:
	screen = Screen.SPLASH
	_clear_panel()
	_clear_corner()
	_hide_panel()
	again_button.visible = false
	var kind := _venue_kind()
	## A LITERAL BUTTON (Pete, 29 Sep 2026): the afternoon's words stay on the
	## splash itself (`_splash_word`), the button says what it does.
	var b := UiKit.primary(UiKit.button(UiKit.t("Walk out"), SPLASH_GO, SPLASH_GO_SIZE, func():
		Audio.play("confirm")
		_clear_corner()
		_show_strategy_panel()))
	corner_nodes.append(b)
	ui.add_child(b)
	queue_redraw()


## WHAT THE BUTTON SAYS, and it is three different sentences because they are
## three different afternoons. A button reading "Continue" on all three would be
## the screen telling you where you are and then forgetting.
func _splash_word(kind: int) -> String:
	match kind:
		Venue.Kind.HOME: return UiKit.t("OUT TO YOUR OWN CROWD")
		Venue.Kind.NEUTRAL: return UiKit.t("OUT TO THE TOURNAMENT")
		_: return UiKit.t("OUT INTO THEIR HOUSE")


## WHO IS HOSTING, ASKED ONCE. `Season.host_id()` answers the same question by
## re-deriving the venue from the fixture list — so the screen would be drawing
## one venue's dressing while naming another venue's town, which is exactly what
## the first render did. The screen has already decided what kind of afternoon
## this is; the host follows from that and from nothing else.
func _splash_host() -> int:
	if _season() == null:
		return -1
	match _venue_kind():
		Venue.Kind.HOME: return _season().world.player_club
		Venue.Kind.AWAY: return _season().opponent_id()
		_: return -1


## AND THE DISTANCE, FROM THE SCREEN'S OWN VENUE. `Season.miles_travelled()`
## asks `venue_kind()` again — the same re-derivation that had this screen
## drawing one ground and naming another's town, and it printed "at home" across
## an away splash the first time it ran. The screen decided what kind of
## afternoon this is; everything on it follows from that.
func _splash_miles() -> float:
	if _season() == null or _venue_kind() == Venue.Kind.HOME:
		return 0.0
	var opp := _season().opponent_id()
	if opp < 0:
		return 0.0
	return _season().world.miles_between(_season().world.player_club, opp)


func _draw_splash() -> void:
	var kind := _venue_kind()
	## THE GROUND. Home reuses the club's own arena at the level it has been
	## built to — the picture the player has been paying for all season — and the
	## other two are their own pieces. `draw_slot` returns false when the art is
	## not in yet, and then the screen paints its own ground rather than a hole.
	var box := Rect2(Vector2.ZERO, SCREEN)
	var slot := String(Venue.ART[kind])
	if kind == Venue.Kind.HOME and _season() != null:
		slot = "arena_%d" % clampi(_season().office.arena.level, 0, 5)
	if not ArtBank.draw_slot(self, slot, box, Color(0.62, 0.62, 0.62)):
		draw_rect(box, UiKit.tint(Tuning.COL_GROUND, 1.0).darkened(0.35))
	## A floor under the middle band, because the names and the records sit
	## across it and there is no panel behind this one.
	draw_rect(Rect2(0.0, 150.0, SCREEN.x, 296.0), Color(0, 0, 0, 0.62))

	var home_id := _splash_host()
	var city := _season().world.city_of(home_id) if (_season() != null and home_id >= 0) else ""
	UiKit.raw(self, font, Vector2(0, 74), UiKit.t(String(Venue.NAME[kind])).to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, int(SCREEN.x), 14, COL_DIM)
	var ground := UiKit.t("Their ground")
	if kind == Venue.Kind.HOME:
		## A standalone bout has no arena to name, and used to fall through to
		## "Their ground" under a HOME heading.
		ground = _season().office.arena.arena_name() if _season() != null else UiKit.t("Home ground")
	elif kind == Venue.Kind.NEUTRAL:
		ground = UiKit.t("Tournament ground")
	UiKit.raw(self, font, Vector2(0, 104), Venue.title(kind,
		Cities.full_name(city) if city != "" else "", ground),
		HORIZONTAL_ALIGNMENT_CENTER, int(SCREEN.x), 22, UiKit.YOU)
	## AND HOW FAR IT IS, which is the whole reason the map is real. On the road
	## it is the number a Homesick man is feeling; at home the heading already
	## says HOME (round 9: "HOME" and "at home" said it twice). The crowd's line
	## rides with it, under the venue, instead of floating under the band.
	## THE MEN WALKING OUT, not the league's fixture: on a cup weekend the league
	## has nobody for you, and this read club 0.
	var them: String = sim.clubs[1].display_name
	var under := Venue.mood_line(kind, String(them).split(" ")[0])
	if _season() != null and kind != Venue.Kind.HOME:
		under = Venue.trip_word(_splash_miles()) + "  ·  " + under
	UiKit.raw(self, font, Vector2(0, 132), under,
		HORIZONTAL_ALIGNMENT_CENTER, int(SCREEN.x), 14, COL_INK)

	## THE TWO CLUBS, badge over name over record, either side of the middle.
	_splash_club(sim.clubs[0], 0, 236.0)
	_splash_club(sim.clubs[1], 1, 724.0)
	## A "V" YOU CAN SEE (round 9: "the v is tiny").
	UiKit.raw(self, font, Vector2(0, 232), "V", HORIZONTAL_ALIGNMENT_CENTER,
		int(SCREEN.x), 40, UiKit.YOU)


func _splash_club(club, side: int, cx: float) -> void:
	## ON ITS KIT, the way the fight's banner draws it (29 Sep 2026). The bare
	## mark sat on the black band, and a navy mark on black is no mark at all.
	var plate := Rect2(cx - 50.0, 162.0, 100.0, 100.0)
	draw_rect(plate, club.kit)
	draw_rect(plate, COL_EDGE, false, 2.0)
	_draw_mark(Vector2(cx, 212.0), club, 76.0)
	UiKit.raw(self, font, Vector2(cx - 220.0, 286.0), club.display_name,
		HORIZONTAL_ALIGNMENT_CENTER, 440, 17, COL_INK)
	## THE RECORD, which only the season knows. Blank in a standalone bout rather
	## than a made-up nought — a scoreboard with invented numbers on it is worse
	## than a scoreboard with none.
	## THE FOUR, OUT OF FIVE STARS (Pete, 1 Oct 2026: "prior to fights, fight
	## cards, you'll see info like the star ratings, overalls and W/L"). Read off
	## the men actually walking out, so it needs no season.
	TeamCard.draw_stars(self, font, Vector2(cx - 196.0, 398.0), club, 2, 200.0, 12)
	if _season() == null:
		return
	## A CUP TIE'S OPPONENT IS THE CUP'S, not the league's — the league has
	## nobody for you on a cup weekend, and the record went blank.
	var them_id: int = _season().cup_opponent() if Session.bout_is_cup else _season().opponent_id()
	var id: int = _season().world.player_club if side == 0 else them_id
	if id < 0:
		return
	UiKit.raw(self, font, Vector2(cx - 220.0, 316.0), UiKit.t("W - D - L"),
		HORIZONTAL_ALIGNMENT_CENTER, 440, 9, COL_DIM)
	UiKit.raw(self, font, Vector2(cx - 220.0, 340.0), _season().world.record_line(id),
		HORIZONTAL_ALIGNMENT_CENTER, 440, 15, COL_INK)
	## THE MATCHUP IN ONE NUMBER (blind review, 29 Sep: "no rating comparison").
	UiKit.raw(self, font, Vector2(cx - 220.0, 366.0), UiKit.t("rating %d") % club.power(),
		HORIZONTAL_ALIGNMENT_CENTER, 440, 15, UiKit.YOU)


## ------------------------------------------------------------- the corner
## PETE, 13 SEP 2026: *"Drop P1 corner completely, we're going with the between
## rounds one."*
##
## What was here was five buttons across, the bench permanently underneath as a
## second row, a sentence about out-of-position, and the whole book below that.
## It answered "who comes off" and nothing else. The spec it replaces has been
## written down since the playbook pass and was built in the HTML mock the same
## afternoon: *"the 5 starters lined up top to bottom on left side with a (sub)
## box next to each... minimum stats (Takedowns/Assists) and if they were downed
## ... their health/stamina... on the right side you have your four favorited
## plays."*
##
## THE LAYOUT AND THE STATS WERE ONE JOB, not two. Five across leaves about
## twelve characters a man, which is why the old screen had no room for a single
## number about the round it exists to report on. A row leaves 496 pixels.
##
## AND IT IS THE SAME SCREEN BEFORE ROUND ONE — Pete again: *"Let's make 'After
## a round' be the 'Before first round' screen too."* The only difference is the
## header: a fixture instead of a score, because before the charge there is
## nothing to report.
const C_PANEL := Rect2(24.0, 24.0, 912.0, 492.0)
const C_LX := 46.0
const C_LW := 496.0
const C_LY := 100.0
const C_ROW_H := 64.0
const C_ROW_GAP := 6.0
const C_SUB := Vector2(78.0, 34.0)
## The right column: four favorites over the full book, the chosen strip, Fight.
const C_RX := 570.0
const C_RW := 344.0
const C_FAV_GAP := 8.0
const C_BAR_X := 206.0
const C_BAR_W := 148.0
const C_STAT_X := 126.0


func _corner_rows() -> float:
	var n: int = maxi(1, sim.lineup(0).size())
	return minf(C_ROW_H, (396.0 - float(n - 1) * C_ROW_GAP) / float(n))


## THE FOUR ON THE RIGHT, as the player starred them.
##
## Each favorite is a `{shape, kind, key}` on the board and has to be turned
## back into the call dictionary the card wants — routes and all — which is what
## `_book_calls` already produces. A favorite that resolves to nothing has been
## pruned by `live_favorites` before we get here.
##
## AND THE FALLBACK IS STILL THERE, for a club that has starred nothing: the
## calls out of the shape his men are standing in. An empty right-hand column on
## a screen with a clock is worse than a sensible default, and every club begins
## with no favorites.
func _fav_calls() -> Array:
	var out: Array = []
	if Session.season != null:
		for f in Session.season.board.live_favorites():
			var c := _fav_call(f)
			if not c.is_empty():
				var row: Dictionary = c.duplicate()
				row["shape"] = int(f["shape"])
				out.append(row)
	if out.is_empty():
		for c in _book_calls(_live_shape_id()):
			var row: Dictionary = c.duplicate()
			row["shape"] = _live_shape_id()
			out.append(row)
	return out.slice(0, mini(Chalkboard.MAX_FAVORITES, out.size()))


## The shape dictionary a favorite belongs to, since a favorite may be starred
## out of a formation the men are not currently standing in — which is the point
## of having four of them.
func _shape_of(shape_id: int) -> Dictionary:
	var shapes := _book_shapes()
	for sh in shapes:
		if int(sh["id"]) == shape_id:
			return sh
	return shapes[0] if not shapes.is_empty() else {}


## WHAT IS ALREADY CALLED, when nothing has been chosen on this screen yet.
##
## The corner opens with the shape the men are standing in and the push they are
## already on, because that is what the sim will run if the player taps FIGHT
## without touching anything — so an empty CHOSEN strip and a dead button would
## be the screen lying about a fight it is perfectly able to start. The
## clubhouse sent a shape; the corner's job is to let you change it, not to
## pretend there is none.
func _seed_chosen() -> void:
	if not chosen_call.is_empty():
		return
	var shapes := _book_shapes()
	var live := _live_shape_id()
	for sh in shapes:
		if int(sh["id"]) == live:
			chosen_shape = sh
			break
	if chosen_shape.is_empty():
		chosen_shape = shapes[0]
	for c in _book_calls(int(chosen_shape["id"])):
		if String(c["kind"]) == "push" and int(c["id"]) == sim.strategies[0]:
			chosen_call = c
			return
	var all := _book_calls(int(chosen_shape["id"]))
	if not all.is_empty():
		chosen_call = all[0]


func _leave_before_charge() -> void:
	if Session.season != null:
		Session.season.bout_live = {}
	Session.bout = null
	Session.autosave()
	UiKit.back("res://scenes/Season.tscn")


func _build_corner() -> void:
	_clear_corner()
	_seed_chosen()
	_hide_panel()
	again_button.visible = false
	var line := sim.lineup(0)
	var row_h := _corner_rows()
	var left: int = Tuning.SWAPS_PER_CORNER - sim.swaps_used[0]

	## THE POPUP TAKES THE SCREEN, and it takes it by being the only thing with
	## controls on it. A scrim drawn in `_draw` cannot cover a Button — the
	## controls live on a CanvasLayer above the Node2D — so a dimmer alone left
	## FIGHT bright and pressable through a dialog asking who comes on. Not a
	## cosmetic problem: it is a live control under a modal.
	if sub_open >= 0:
		_build_sub_popup(line)
		queue_redraw()
		return

	## ONE SUB BOX A MAN, and it is disabled rather than absent when the swaps are
	## gone — a control that vanishes when it stops working teaches the player
	## that the screen is different this round, which it is not.
	for i in line.size():
		var ry: float = C_LY + float(i) * (row_h + C_ROW_GAP)
		## PROUD — *"Refuses the corner - never asks to come off."* A refusal the
		## screen has to honor, so his box is dead and the row says why. It is
		## the only trait in the game whose whole effect is that a control does
		## not work, which is why it is a flag and not a number.
		var proud: bool = FighterTrait.flag(line[i].trait_id, "no_sub")
		var b := UiKit.button(UiKit.t("SUB"),
			Vector2(C_LX + C_LW - C_SUB.x - 6.0, ry + (row_h - C_SUB.y) * 0.5),
			C_SUB, func(k = i): sub_open = -1 if sub_open == k else k; _build_corner())
		b.disabled = proud or left <= 0 or sim.bench(0).is_empty()
		corner_nodes.append(b)
		ui.add_child(b)

	## THE FOUR FAVORITES, two by two, at the width the column gives them.
	var fav := _fav_calls()
	var fw: float = (C_RW - C_FAV_GAP) * 0.5
	var fh: float = fw * (PLAY_CARD.y / PLAY_CARD.x)
	for i in fav.size():
		var call_: Dictionary = fav[i]
		var shape: Dictionary = _shape_of(int(call_["shape"]))
		if shape.is_empty():
			continue
		var is_push: bool = String(call_["kind"]) == "push"
		var on: bool = chosen_call.get("name", "") == call_["name"] \
			and chosen_shape.get("id", -99) == shape.get("id", -98)
		var fb := Playbook.card_button(Vector2(fw, fh), shape["spots"],
			Playbook.Mode.STRATEGY if is_push else Playbook.Mode.PLAY,
			int(call_["id"]) if is_push else call_["routes"], on,
			String(call_["name"]),
			func(sh = shape, c = call_): _choose(sh, c), 10)
		fb.position = Vector2(C_RX + float(i % 2) * (fw + C_FAV_GAP),
			C_LY + 6.0 + floorf(float(i) / 2.0) * (fh + C_FAV_GAP))
		corner_nodes.append(fb)
		ui.add_child(fb)

	var y: float = C_LY + 6.0 + fh * 2.0 + C_FAV_GAP + 10.0
	var full := UiKit.button(UiKit.t("FULL PLAYBOOK"), Vector2(C_RX, y), Vector2(C_RW, 34.0),
		_show_playbook)
	corner_nodes.append(full)
	ui.add_child(full)

	## THE FIGHT BUTTON SITS AT THE BOTTOM OF WHICHEVER COLUMN IS TALLER, so the
	## two halves of the screen end together however many men are on the line.
	var lbot: float = C_LY + float(line.size()) * (row_h + C_ROW_GAP)
	var fy: float = maxf(y + 44.0 + 42.0, lbot - 56.0)
	var fight := UiKit.button(UiKit.t("FIGHT"), Vector2(C_RX, fy), Vector2(C_RW, 56.0),
		_apply_chosen)
	## NOTHING CALLED IS NOTHING TO FIGHT WITH. Before round one the clubhouse
	## has already sent a shape, so the corner opens with it chosen and the
	## button live; it can only be empty if the player cancels out of the book.
	fight.disabled = chosen_call.is_empty()
	if not fight.disabled:
		UiKit.primary(fight)
	corner_nodes.append(fight)
	ui.add_child(fight)

	## A WAY OUT BEFORE THE FIRST CHARGE (review round 3: "no Back"). Nothing has
	## been fought, so leaving is what Pete ruled for a lost app (29 Sep): the
	## fixture stays, on the same seed, from the walk-out.
	if sim.round_no <= 1 and sim.phase != MeleeSim.Phase.CORNER:
		var out := UiKit.button(UiKit.t("Back"), Vector2(C_LX, lbot + 8.0), Vector2(150, 44), _leave_before_charge)
		corner_nodes.append(out)
		ui.add_child(out)

	queue_redraw()


## WHO COMES ON. A popup over the corner rather than a second row that is on
## screen whether or not anybody is subbing — the bench is a list you consult
## once, and it was taking sixty-eight pixels off the book every round.
##
## EVERY MEASUREMENT HERE IS DERIVED FROM THE LIST. The first version wrote
## `64 + shown * 54 + 46` and put the cancel at `box.y - 54`, which is two
## expressions that have to agree about where the list ends — and they did not:
## the last bench button ended on the exact y the cancel began, and with the drop
## shadow the two read as one control. Pete, 13 Sep 2026: *"Marsh is falling into
## nevermind."*
##
## So there is one ladder. `_sub_rows()` says where row `i` sits, everything else
## counts off it, and the box is whatever the ladder needs. Two numbers that must
## agree are one number written twice.
const SUB_W := 440.0
const SUB_PAD := 20.0
const SUB_HEAD := 64.0
const SUB_ROW := Vector2(400.0, 48.0)
const SUB_GAP := 10.0
## THE CANCEL IS NOT A FOURTH MAN. At one row-gap plus eight it sat in the same
## rhythm as the bench buttons and read as another name in the list, which is the
## one thing it must not read as — so it gets a clear break above it and is
## knocked back a shade.
const SUB_TAIL := 26.0
const SUB_QUIET := 0.82
const SUB_CANCEL := Vector2(400.0, 44.0)


func _sub_row_y(i: int) -> float:
	return SUB_HEAD + float(i) * (SUB_ROW.y + SUB_GAP)


func _sub_box(n: int) -> Rect2:
	var h: float = _sub_row_y(n) - SUB_GAP + SUB_TAIL + SUB_CANCEL.y + SUB_PAD
	var size := Vector2(SUB_W, h)
	return Rect2(((SCREEN - size) * 0.5).floor(), size)


func _build_sub_popup(line: Array) -> void:
	var bench := sim.bench(0)
	## NO CAP. The old one drew at most four and hid the rest with `visible`,
	## which on a roster the player is allowed to resize is a bench with men on it
	## that nothing can reach. The box grows instead.
	var box := _sub_box(maxi(1, bench.size()))
	sub_box = box
	sub_for = String(line[sub_open].display_name) if sub_open < line.size() else ""
	for i in bench.size():
		var f = bench[i]
		## THE LIKE-FOR-LIKE MAN IS THE OBVIOUS PICK, and says so (blind review
		## round 3: "a position mismatch is not flagged"). Same role: gold, and
		## "same role"; otherwise the role he would be playing out of.
		var out_card = line[sub_open] if sub_open < line.size() else null
		var same: bool = out_card != null and f.pos_name() == out_card.pos_name()
		var b := UiKit.button(UiKit.t("%s  ·  %s  ·  %d%%") % [f.display_name, f.pos_name(),
				int(round(sim.condition_of(f) * 100.0))] + (UiKit.t("  ·  same role") if same else ""),
			box.position + Vector2(SUB_PAD, _sub_row_y(i)), SUB_ROW,
			func(m = f): _do_swap(m))
		corner_nodes.append(b)
		ui.add_child(UiKit.primary(b) if same else b)
	## FULL WIDTH, LIKE THE ROWS ABOVE IT. A 160-wide cancel under a column of
	## 400-wide buttons is a different kind of control by its shape, and it is
	## not — it is the last item in the same list.
	var cancel := UiKit.button(UiKit.t("Never mind"),
		box.position + Vector2(SUB_PAD,
			_sub_row_y(maxi(1, bench.size())) - SUB_GAP + SUB_TAIL),
		SUB_CANCEL, func(): sub_open = -1; _build_corner())
	cancel.modulate = Color(SUB_QUIET, SUB_QUIET, SUB_QUIET)
	corner_nodes.append(cancel)
	ui.add_child(cancel)


## A PLAY IS CHOSEN, NOT CALLED — Pete: *"Click Formation - Click Play - Click
## either Confirm or Cancel (That play will now show as (Chosen - 2-1-2 Rush
## left)) between 'Full Playbook' and 'Fight'."*
##
## This used to apply the plan to the sim and leave the corner in the same tap,
## which made the book's cards a fire-and-forget control on a screen whose whole
## point is that you look at the line first. It stores the pair; `_apply_chosen`
## is the only thing that touches the sim.
func _choose(shape: Dictionary, call_: Dictionary) -> void:
	chosen_shape = shape
	chosen_call = call_
	Audio.play("tap")
	screen = Screen.CORNER if sim.phase == MeleeSim.Phase.CORNER else Screen.PREFIGHT
	_build_corner()


func _chosen_label() -> String:
	if chosen_call.is_empty():
		return UiKit.t("nothing called")
	return "%s · %s" % [String(chosen_shape.get("name", "?")),
		String(chosen_call.get("name", "?"))]


func _clear_corner() -> void:
	for n in corner_nodes:
		if is_instance_valid(n):
			n.queue_free()
	corner_nodes.clear()
	sub_box = Rect2()


func _do_swap(card) -> void:
	if sub_open == -1:
		return
	if sim.swap_in(0, sub_open, card):
		Audio.play("confirm")
	else:
		Audio.play("refuse")
	sub_open = -1
	_clear_corner()
	_build_corner()


## KEPT AS A NAMED ENTRY POINT because `tools/shot_melee.gd` and the balance
## probes drive the screen through it, and a screenshot tool that has to know
## about the book's shape dictionaries is a tool that breaks every time the book
## changes shape. It calls the push asked for, out of whatever shape is live.
func _pick_strategy(st: int) -> void:
	var shapes := _book_shapes()
	var live := _live_shape_id()
	var pick: Dictionary = shapes[0]
	for sh in shapes:
		if int(sh["id"]) == live:
			pick = sh
			break
	_call_from_book(pick, {"kind": "push", "id": st,
		"name": String(Tuning.STRATEGIES[st]["name"])})
