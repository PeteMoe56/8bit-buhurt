extends Node2D
## THE ARENA — your ground, and the shows you put on in it.
##
## Two halves. On the left the ground itself; on the right the diary — build the
## next one, or put a show on.
##
## THERE IS NO ARTWORK IN THIS FILE. Pete, 10 Sep 2026: *"Let's not use your art
## for any of this, just placeholders. I'll get ChatGPT to do that work."*
##
## The first version drew each ground from primitives — stands, a crowd, a rope,
## floodlights — which made the levels legible but also made a set of art
## decisions that are not mine to make, and which somebody would then have had
## to argue with real images. So what is here is an empty, labelled SLOT, and a
## loader that fills it the moment a file exists at the expected path.
##
## Drop `art/arena/arena_0.png` … `arena_5.png` into the project and they appear.
## Nothing else changes and no code needs touching. See docs/ART.md for the slot
## list and the sizes.

const GROUND := Rect2(24.0, 96.0, 520.0, 300.0)
const RIGHT_X := 572.0
## The diary's pickers sit right of their labels ("When", "Budget").
const PICK_X := 110.0
const PICK_W := 254.0
## Where the arena images live once they exist. One folder, one file per level,
## named by level — so adding a seventh ground is a data change and a file, not
## a code change.
## Shown on the empty slot so the label says exactly where the file goes.
const ART_DIR := ArtBank.DIR + "arena/"

var font: Font
var season: Season
var office: ClubOffice
var arena: Arena
var ui: CanvasLayer
var flash := ""
## Which budget the player is looking at. Not a commitment until he books.
var budget_i := 1
## Which of the year's three dates is being looked at. Not a commitment until he
## takes it.
var offer_i := 1


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	office = season.office
	arena = office.arena
	ui = CanvasLayer.new()
	add_child(ui)
	_rebuild()


# ------------------------------------------------------------------ controls
func _rebuild() -> void:
	for c in ui.get_children():
		c.queue_free()
	ui.add_child(UiKit.corner_back("res://scenes/Season.tscn"))

	if not arena.at_top():
		var err := arena.can_build(office.tier, office.credits)
		var label := UiKit.t("Build the %s · %d CC") % [UiKit.t(String(arena.next()["name"])), arena.next_cost()]
		ui.add_child(UiKit.button(label if err == "" else UiKit.t("Locked"),
			Vector2(RIGHT_X, 204), Vector2(340, 40), _build))

	## HAVE IT SEEN TO. On the LEFT, under the picture of the mess, rather than
	## in the diary column with the build button — a player who has just looked
	## at rubbish on his floor looks for the control next to the rubbish, not in
	## the list of things the federation is offering him.
	##
	## SHOWN ONLY WHEN THERE IS SOMETHING TO DO. A button that exists to tell you
	## it has nothing to do is a button that trains you to stop reading the
	## screen; a spotless ground simply has no control, and `condition_word()`
	## next to the level already says why.
	if arena.condition < 0.999 and arena.level >= Arena.WEARS_FROM_LEVEL:
		ui.add_child(UiKit.button(UiKit.t("Have it seen to — %d CC") % arena.upkeep_cost(),
			Vector2(24, 444), Vector2(264, 36), _tidy))

	if season.bid_open():
		## THE BID. Two dials on one screen, both spent the moment he takes it —
		## the date and the promotion.
		var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
		## PICKERS SAY THEY ARE PICKERS (blind review, 29 Sep: they read as
		## purchases). A tap moves to the next option; nothing is spent until
		## "Take the date".
		## A LABEL, THEN A PICKER THAT SAYS IT PICKS (blind review round 3: "the
		## diary buttons merge a value and an action"). The word on the left is
		## what is being chosen; the button is the choice, with a › to say a tap
		## moves to the next one.
		ui.add_child(UiKit.button(UiKit.t("%s · %d CC") % [UiKit.t(String(o["name"])), int(o["bid"])] + "  >",
			Vector2(RIGHT_X + PICK_X, 306), Vector2(PICK_W, 38), func():
				offer_i = (offer_i + 1) % season.bid_offers.size()
				flash = ""
				_rebuild()))
		ui.add_child(UiKit.button(UiKit.t("%s · %d CC") % [
				UiKit.t(String(ClubEvent.BUDGETS[budget_i]["name"])),
				int(ClubEvent.BUDGETS[budget_i]["cost"])] + "  >",
			Vector2(RIGHT_X + PICK_X, 350), Vector2(PICK_W, 38), func():
				budget_i = (budget_i + 1) % ClubEvent.BUDGETS.size()
				flash = ""
				_rebuild()))
		ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Take the date"), Vector2(RIGHT_X, 450),
			Vector2(178, 44), _bid)))
		ui.add_child(UiKit.button(UiKit.t("Pass this year"), Vector2(RIGHT_X + 186, 450),
			Vector2(178, 44), func():
				season.decline_bid()
				Session.autosave()
				flash = UiKit.t("No tournament this year.")
				_rebuild()))
	elif season.booked == null:
		var pay: int = ClubEvent.DEMO_PAY[clampi(arena.level, 0, ClubEvent.DEMO_PAY.size() - 1)]
		var b := UiKit.button(UiKit.t("Run a demo · +%d CC") % pay, Vector2(RIGHT_X, 392),
			Vector2(340, 40), _demo)
		## ONCE A WEEK: after it has run, the button says so instead of refusing.
		if office.done_this_week("demo"):
			b.text = UiKit.t("Demo done this week")
			b.disabled = true
		ui.add_child(b)
	queue_redraw()


func _build() -> void:
	var err := office.build_arena()
	if err != "":
		flash = err
		_rebuild()
		return
	Session.autosave()
	flash = UiKit.t("Built. %s.") % arena.arena_name()
	_rebuild()


func _tidy() -> void:
	## THE PRICE IS READ BEFORE THE WORK, and that is not a style point. Asking
	## `upkeep_cost()` after `tidy_arena()` asks a ground that is now spotless
	## what it costs to clean, which is the 1 CC floor — the club would be told
	## it had spent one credit whatever it actually spent. **A number read after
	## the thing that changes it is a number about a different world.**
	var cost := office.arena.upkeep_cost()
	var err := office.tidy_arena()
	if err != "":
		flash = err
		_rebuild()
		return
	Session.autosave()
	flash = UiKit.t("Swept, patched and put right. %d CC.") % cost
	_rebuild()


func _bid() -> void:
	var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
	var nm := String(o["name"])
	var err := season.take_bid(offer_i % season.bid_offers.size(), budget_i)
	flash = UiKit.said(err) if err != "" else UiKit.t("%s is yours. The rest of the year is preparation.") % nm
	if err == "":
		Session.autosave()
	_rebuild()


func _demo() -> void:
	var err := season.run_demo()
	flash = UiKit.said(err) if err != "" else UiKit.t("Demo run. %d CC.") % int(season.last_show.get("gate", 0))
	if err == "":
		Session.autosave()
	_rebuild()


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	UiKit.ground(self)
	UiKit.text(self, font, arena.arena_name().to_upper(), Vector2(24, 40), 22, UiKit.YOU)
	## THE PURSE IS TOP RIGHT NOW; the subtitle no longer repeats it (round 7).
	UiKit.text(self, font, UiKit.t("%s  ·  %s  ·  %s fans") % [
		office.note_word(), _capacity_word(), _fans_word()],
		Vector2(24, 64), 14, UiKit.DIM)
	## THE ONE NUMBER, said two ways: how many came, and what share of the room
	## that was. It used to be notoriety and a turnout percentage derived from it
	## — the same quantity printed twice, which is what having three populations
	## did to every screen that tried to describe the crowd.
	## IN A 420 BOX AND NOT A 320 ONE. `UiKit.right` passes its width to
	## `draw_string` as an ALIGNMENT width, which does not clip: at 320 this
	## sentence started at 520 and finished at 977 on a 960 canvas, so "1 CC a
	## fight" — the figure the whole line exists to deliver — was the half that
	## fell off. The left of this row ends around 370, so the box can have the
	## room, and `fit_px` records the cut if it ever needs one anyway.
	## THE CROWD, ALONE IN THE CORNER (round 4: level, condition and crowd were
	## stacked over one bar with two meanings). The ground's level and state
	## moved to THE GROUND's own heading.
	UiKit.right_fit(self, font,
		UiKit.t("CROWD  %s in  ·  %d%% full  ·  %d CC a home fight") % [
			UiKit.crowd_word(office.attendance()),
			int(round(office.fill() * 100.0)), office.crowd_pay()],
		Vector2(UiKit.right_edge(), 58), 14, UiKit.INK, 560.0)
	UiKit.right(self, font, UiKit.t("the bar fills toward the next pay rise"),
		Vector2(UiKit.right_edge(), 94), 12, UiKit.DIM, 440.0)
	## THE PURSE WHERE IT IS ON EVERY OTHER SCREEN (round 6).
	UiKit.purse(self, font, office.credits, Vector2(UiKit.right_edge(), 32), 18, UiKit.YOU, 200)
	## THE METER, because a band you cannot see coming is a band you cannot chase.
	## Retro Bowl's whole fan bar is this: the player watches it fill and knows a
	## raise is close. A number alone does not do that — 71 and 74 read the same
	## and one of them is a fight away from paying more.
	_meter(Vector2(UiKit.right_edge() - 320.0, 68), 320.0)
	## THE TWO AXES, SIDE BY SIDE, because they are the two axes and a player
	## needs to see that they are different things: the level is what the league
	## lets him build and the condition is what he keeps it in.
	##
	## The overlay is the signal and this is the caption. Without the word, a
	## player who sees rubbish on his floor has no way to tell a deliberate
	## mechanic from a rendering fault, and no term to look for when he wants to
	## do something about it. **A state the game draws and does not name is a
	## state the player reads as a bug.**
	UiKit.panel(self, Rect2(RIGHT_X - 14.0, 98.0, UiKit.right_edge() - RIGHT_X + 26.0, 154.0))
	UiKit.panel(self, Rect2(RIGHT_X - 14.0, 258.0, UiKit.right_edge() - RIGHT_X + 26.0, 244.0))
	UiKit.right(self, font, UiKit.t("Level %d of %d") % [arena.level, Arena.MAX_LEVEL] + "  ·  " + arena.condition_word(),
		Vector2(UiKit.right_edge(), 118), 14,
		UiKit.DOWN if arena.shabby() else UiKit.DIM, 240.0)

	_draw_ground()
	## Clipped to its own column. The National Arena's blurb is long enough to
	## run under the diary and print through the payout line.
	UiKit.para(self, font, UiKit.t(String(arena.here()["blurb"])),
		Vector2(24, GROUND.end.y + 24), 14, UiKit.DIM, GROUND.size.x, 18.0)
	_draw_diary()
	## THE FLASH MOVED DOWN, because the tidy button now sits at 444 and it used
	## to print at 448. **A scrim cannot cover a Button — and it goes the other
	## way too, and the other way is worse**: a Control is a child of the layer
	## and draws over anything `_draw()` puts under it, so the message would have
	## vanished behind the very button that produced it and the screen would have
	## looked like it had done nothing at all.
	if flash != "":
		UiKit.text(self, font, flash, Vector2(190, UiKit.bottom(18.0)), 14, UiKit.INK)


## A five-segment bar: the bands behind, the band being filled, the bands ahead.
func _meter(at: Vector2, w: float) -> void:
	var n: int = ClubOffice.CROWD_PAY.size()
	var gap: float = 3.0
	var seg: float = (w - gap * float(n - 1)) / float(n)
	var band: int = office.crowd_band()
	var fill: float = office.crowd_meter()
	for i in n:
		var x: float = at.x + float(i) * (seg + gap)
		draw_rect(Rect2(Vector2(x, at.y), Vector2(seg, 8.0)), UiKit.BG.lerp(UiKit.DIM, 0.35))
		var how: float = 1.0 if i < band else (fill if i == band else 0.0)
		if how > 0.0:
			draw_rect(Rect2(Vector2(x, at.y), Vector2(seg * how, 8.0)), UiKit.YOU)


func _fans_word() -> String:
	var f := int(round(office.fans))
	return str(f) if f < 1000 else "%.1fk" % (float(f) / 1000.0)


func _capacity_word() -> String:
	var c := arena.capacity()
	return UiKit.t("holds %s") % (str(c) if c < 1000 else "%.1fk" % (float(c) / 1000.0))


## THE GROUND. An image if one has been dropped in for this level, and an empty
## labelled slot if not — never a drawing of my own. See the file header.
func _draw_ground() -> void:
	var g := GROUND
	var art := _art_for(arena.level)
	if art != null:
		## Fitted to the slot and centerd, so an image that is not exactly the
		## slot's proportions is letterboxed rather than stretched. A squashed
		## arena is worse than no arena.
		var sc: float = minf(g.size.x / float(art.get_width()), g.size.y / float(art.get_height()))
		var w := float(art.get_width()) * sc
		var h := float(art.get_height()) * sc
		draw_rect(g, UiKit.PANEL)
		draw_texture_rect(art, Rect2(g.get_center() - Vector2(w, h) * 0.5, Vector2(w, h)), false)
	else:
		draw_rect(g, UiKit.PANEL)
		## A slot says what it is waiting for. A blank box says the screen is
		## broken.
		## THE GROUND AS A TITLED CARD until its picture lands (round 8: "artwork to
		## come" read as an unfinished screen). Its name and the two numbers that
		## describe it, centered; the picture replaces all of it.
		var gc := g.get_center()
		UiKit.mid(self, font, arena.arena_name().to_upper(), Vector2(g.position.x + 20.0, gc.y - 18.0), 22, UiKit.INK, g.size.x - 40.0)
		UiKit.mid(self, font, UiKit.t("Level %d  ·  %s") % [arena.level, _capacity_word()],
			Vector2(g.position.x + 20.0, gc.y + 12.0), 14, UiKit.DIM, g.size.x - 40.0)
		## The file path and the pixel size that used to follow were notes for
		## whoever draws the art, printed to the player (29 Sep 2026). They are
		## in docs/ART.md; the slot only says what it is waiting for.
		## Corner ticks, so the slot reads as a frame waiting to be filled rather
		## than as a panel that failed to draw.
		for c in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
			var at := g.position + Vector2(g.size.x * c.x, g.size.y * c.y)
			var dx: float = 22.0 if c.x == 0 else -22.0
			var dy: float = 22.0 if c.y == 0 else -22.0
			draw_line(at, at + Vector2(dx, 0), UiKit.FRAME, 2.0)
			draw_line(at, at + Vector2(0, dy), UiKit.FRAME, 2.0)

	## AND WHAT NOBODY HAS SWEPT, over whatever is behind it — the empty slot
	## today and the real artwork the day it lands. Keyed on the LEVEL, so the
	## rubbish that is already there stays where it is as the ground gets worse
	## and new rubbish appears between it. See `scripts/game/grime.gd` for why
	## this one drawing is allowed to exist in a project whose art is somebody
	## else's job.
	##
	## BEFORE THE BADGE AND BEFORE THE FRAME, deliberately. The club's own mark
	## is the one thing on this screen that should stay crisp however far the
	## ground has gone — it is the thing the player picked.
	Grime.draw_over(self, g, arena.condition, arena.level)

	## YOUR BADGE, over whatever is behind it, at the quality this ground
	## affords. This one IS the game's own rendering and is meant to be: it is
	## the mark the player picked out of the icon bank, so it cannot live inside
	## a fixed image. Pete asked for it directly — *"Yes, the badge itself gets
	## better"* — and it draws over the artwork when the artwork arrives.
	UiKit.badge(self, Vector2(g.end.x - 76.0, g.end.y - 76.0), 46.0,
		season.club.kit, season.club.icon_color, season.club.icon, arena.badge_quality())
	draw_rect(g, UiKit.FRAME, false, 2.0)


## Loaded on demand and cached. A missing file is the normal case right now, so
## it must not print an engine error every frame — `ResourceLoader.exists` is
## the check that keeps the log clean.
## Now one line into `ArtBank`. This screen used to own a private cache and a
## private path-builder, and the melee wanting art would have grown a second
## pair — which is how the spec and the code drift apart.
func _art_for(level: int) -> Texture2D:
	return ArtBank.get_slot("arena_%d" % level)


func _draw_diary() -> void:
	UiKit.text(self, font, UiKit.t("THE GROUND"), Vector2(RIGHT_X, 118), 15, UiKit.INK)
	if arena.at_top():
		UiKit.text(self, font, UiKit.t("Built as far as a club can build."),
			Vector2(RIGHT_X, 146), 14, UiKit.DIM)
	else:
		var n := arena.next()
		UiKit.text(self, font, UiKit.t("Next: %s, holds %d") % [String(n["name"]), int(n["capacity"])],
			Vector2(RIGHT_X, 146), 14, UiKit.DIM)
		## AND WHICH DIVISION IT NEEDS. `arena.next_tier()` was written for this
		## screen — its own comment says so — and then never called, so the one
		## thing the player most needs to know was only ever visible inside a
		## refusal he had to earn by trying. **"Get promoted" is a different
		## instruction from "save up"** and he should be able to tell which one
		## he is looking at before he taps anything.
		##
		## ON ITS OWN LINE AND ONLY ONCE. It used to be right-aligned on the SAME
		## row as "Next: Arena, holds 12000", and at 13px that row is 300 pixels
		## of text in a 388-pixel column: the two printed through each other and
		## the screenshot read "Next: Arena, holds 1needs the Regional League".
		## And the refusal underneath it then said the identical thing in a longer
		## sentence that ran off the right of the frame — **a fact stated twice in
		## two lengths is a screen arguing with itself**, so the refusal is now
		## shown only when it is telling him something the line above did not.
		var need := arena.next_tier()
		var locked := need > office.tier
		if locked:
			UiKit.text(self, font, UiKit.t("Needs the %s") % League.tier_name(need),
				Vector2(RIGHT_X, 168), 14, UiKit.DOWN)
		else:
			var err := arena.can_build(office.tier, office.credits)
			if err != "":
				UiKit.text_fit(self, font, err, Vector2(RIGHT_X, 168), 14, UiKit.DIM, 340.0)

	## TWO FRAMED GROUPS (round 9: the right column "floated"): the ground,
	## and the diary.
	UiKit.text(self, font, UiKit.t("THE DIARY"), Vector2(RIGHT_X, 282), 15, UiKit.INK)
	if season.bid_open():
		## The preview is honest and it is the reason the screen exists: the
		## player is choosing between numbers, not adjectives, and the number
		## moves with the ground he has banked into.
		var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
		var p := season.bid_preview(offer_i % season.bid_offers.size(), budget_i)
		UiKit.text_fit(self, font, UiKit.t(String(o["blurb"])), Vector2(RIGHT_X, 302), 14, UiKit.DIM,
			UiKit.screen().x - 24.0 - RIGHT_X)
		UiKit.text_fit(self, font, UiKit.t("When"), Vector2(RIGHT_X, 330), 14, UiKit.INK, PICK_X - 8.0)
		UiKit.text_fit(self, font, UiKit.t("Budget"), Vector2(RIGHT_X, 374), 14, UiKit.INK, PICK_X - 8.0)
		## TWO LINES EACH, because both of these ran off the right of the frame in
		## the real face — 1021 and 976 of a 960 — and both are sentences the
		## player is meant to read before spending credits on a date. Breaking
		## them at the natural clause beats shrinking a figure somebody is about
		## to make a decision on.
		## THE SUM, ABOVE THE BUTTON IT DECIDES (blind review round 3: the
		## "Expected" line sat under the button it was about).
		UiKit.text_fit(self, font, UiKit.t("Event %d  ·  about %d through the gate") % [
			int(o["event"]) + 1, int(p["heads"])],
			Vector2(RIGHT_X, 412), 14, UiKit.DIM, UiKit.screen().x - 24.0 - RIGHT_X)
		var net := int(p["net"])
		UiKit.text_fit(self, font, UiKit.t("Expected: %+d CC  ·  %+d CC if you win it") % [net, int(p["best"])],
			Vector2(RIGHT_X, 434), 15, UiKit.UP if net >= 0 else UiKit.DOWN, UiKit.screen().x - 24.0 - RIGHT_X)
		return
	if season.booked == null and not season.bid_open():
		## WHAT THE DEMO IS (round 4: "Run a demo" unexplained).
		UiKit.para(self, font, UiKit.t("A small home show, once a week. It cannot lose money."),
			Vector2(RIGHT_X, 456), 14, UiKit.DIM, UiKit.screen().x - 24.0 - RIGHT_X, 18.0)
	if season.booked != null:
		var away := season.booked.events_away(season.world.event)
		UiKit.text(self, font, UiKit.t("%s, %s") % [season.booked.kind_name(),
			UiKit.t("this event") if away == 0 else UiKit.t("in %d events") % away],
			Vector2(RIGHT_X, 312), 14, UiKit.YOU)
		UiKit.para(self, font, UiKit.t("The budget is already spent. Win it and it comes back."),
			Vector2(RIGHT_X, 334), 14, UiKit.DIM, UiKit.screen().x - 24.0 - RIGHT_X, 18.0)
	else:
		UiKit.text(self, font, UiKit.t("No tournament this year."),
			Vector2(RIGHT_X, 312), 14, UiKit.DIM)
		UiKit.para(self, font, UiKit.t("The federation offers dates between seasons."),
			Vector2(RIGHT_X, 334), 14, UiKit.DIM, UiKit.screen().x - 24.0 - RIGHT_X, 18.0)

	if not season.last_show.is_empty():
		var l := season.last_show
		UiKit.text(self, font, UiKit.t("LAST TIME OUT"), Vector2(RIGHT_X, 466), 14, UiKit.DIM)
		var f := Cup.finish_words(String(l.get("finish", "")))
		UiKit.text(self, font, UiKit.t("%s · %d in · %+d cr%s") % [
			String(l.get("kind", "?")), int(l.get("heads", 0)), int(l.get("net", 0)),
			"" if f == "" else UiKit.t(" · %s") % f],
			Vector2(RIGHT_X, 490), 13,
			UiKit.UP if int(l.get("net", 0)) >= 0 else UiKit.DOWN)
