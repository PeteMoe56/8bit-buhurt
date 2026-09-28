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
		var label := UiKit.t("Build the %s — %d CC") % [UiKit.t(String(arena.next()["name"])), arena.next_cost()]
		ui.add_child(UiKit.button(label if err == "" else UiKit.t("Locked"),
			Vector2(RIGHT_X, 212), Vector2(340, 40), _build))

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
		ui.add_child(UiKit.button(UiKit.t("Date: %s — %d CC") % [String(o["name"]), int(o["bid"])],
			Vector2(RIGHT_X, 280), Vector2(340, 36), func():
				offer_i = (offer_i + 1) % season.bid_offers.size()
				flash = ""
				_rebuild()))
		ui.add_child(UiKit.button(UiKit.t("Budget: %s — %d CC") % [
				String(ClubEvent.BUDGETS[budget_i]["name"]),
				int(ClubEvent.BUDGETS[budget_i]["cost"])],
			Vector2(RIGHT_X, 322), Vector2(340, 36), func():
				budget_i = (budget_i + 1) % ClubEvent.BUDGETS.size()
				flash = ""
				_rebuild()))
		ui.add_child(UiKit.button(UiKit.t("Take the date"), Vector2(RIGHT_X, 364),
			Vector2(166, 40), _bid))
		ui.add_child(UiKit.button(UiKit.t("Pass this year"), Vector2(RIGHT_X + 174, 364),
			Vector2(166, 40), func():
				season.decline_bid()
				Session.autosave()
				flash = UiKit.t("No tournament this year.")
				_rebuild()))
	elif season.booked == null:
		ui.add_child(UiKit.button(UiKit.t("Run a demo"), Vector2(RIGHT_X, 384),
			Vector2(340, 40), _demo))
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
	UiKit.text(self, font, UiKit.t("%s  ·  %s  ·  %s fans  ·  %d CC") % [
		office.note_word(), _capacity_word(), _fans_word(), office.credits],
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
	UiKit.right(self, font, UiKit.fit_px(font,
		UiKit.t("%s in  ·  %d%% full  ·  %d CC a home fight") % [
			UiKit.crowd_word(office.attendance()),
			int(round(office.fill() * 100.0)), office.crowd_pay()], 13, 420.0),
		Vector2(UiKit.right_edge(120.0), 64), 13, UiKit.DIM, 420.0)
	## THE METER, because a band you cannot see coming is a band you cannot chase.
	## Retro Bowl's whole fan bar is this: the player watches it fill and knows a
	## raise is close. A number alone does not do that — 71 and 74 read the same
	## and one of them is a fight away from paying more.
	_meter(Vector2(520, 76), 320.0)
	## THE TWO AXES, SIDE BY SIDE, because they are the two axes and a player
	## needs to see that they are different things: the level is what the league
	## lets him build and the condition is what he keeps it in.
	##
	## The overlay is the signal and this is the caption. Without the word, a
	## player who sees rubbish on his floor has no way to tell a deliberate
	## mechanic from a rendering fault, and no term to look for when he wants to
	## do something about it. **A state the game draws and does not name is a
	## state the player reads as a bug.**
	UiKit.right(self, font, UiKit.t("Level %d of %d") % [arena.level, Arena.MAX_LEVEL],
		Vector2(UiKit.right_edge(120.0), 40), 14, UiKit.DIM, 200.0)
	UiKit.right(self, font, arena.condition_word(),
		Vector2(UiKit.right_edge(120.0), 22), 13,
		UiKit.DOWN if arena.shabby() else UiKit.DIM, 200.0)

	_draw_ground()
	## Clipped to its own column. The National Arena's blurb is long enough to
	## run under the diary and print through the payout line.
	UiKit.text(self, font, UiKit.clip(UiKit.t(String(arena.here()["blurb"])), 88),
		Vector2(24, GROUND.end.y + 26), 13, UiKit.DIM)
	_draw_diary()
	## THE FLASH MOVED DOWN, because the tidy button now sits at 444 and it used
	## to print at 448. **A scrim cannot cover a Button — and it goes the other
	## way too, and the other way is worse**: a Control is a child of the layer
	## and draws over anything `_draw()` puts under it, so the message would have
	## vanished behind the very button that produced it and the screen would have
	## looked like it had done nothing at all.
	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, UiKit.bottom(18.0)), 14, UiKit.INK)


## A five-segment bar: the bands behind, the band being filled, the bands ahead.
func _meter(at: Vector2, w: float) -> void:
	var n: int = ClubOffice.CROWD_PAY.size()
	var gap: float = 3.0
	var seg: float = (w - gap * float(n - 1)) / float(n)
	var band: int = office.crowd_band()
	var fill: float = office.crowd_meter()
	for i in n:
		var x: float = at.x + float(i) * (seg + gap)
		draw_rect(Rect2(Vector2(x, at.y), Vector2(seg, 5.0)), UiKit.BG.lerp(UiKit.DIM, 0.35))
		var how: float = 1.0 if i < band else (fill if i == band else 0.0)
		if how > 0.0:
			draw_rect(Rect2(Vector2(x, at.y), Vector2(seg * how, 5.0)), UiKit.YOU)


func _fans_word() -> String:
	var f := int(round(office.fans))
	return str(f) if f < 1000 else "%.1fk" % (float(f) / 1000.0)


func _capacity_word() -> String:
	var c := arena.capacity()
	return "holds %d" % c if c < 1000 else "holds %.1fk" % (float(c) / 1000.0)


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
		UiKit.text(self, font, UiKit.t("%s  —  artwork to come") % arena.arena_name(),
			g.position + Vector2(18, 30), 15, UiKit.DIM)
		UiKit.text(self, font, ART_DIR + "arena_%d.png" % arena.level,
			g.position + Vector2(18, 52), 12, UiKit.EDGE)
		UiKit.text(self, font, UiKit.t("%d × %d") % [int(g.size.x), int(g.size.y)],
			g.position + Vector2(18, 70), 12, UiKit.EDGE)
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
			Vector2(RIGHT_X, 146), 13, UiKit.DIM)
	else:
		var n := arena.next()
		UiKit.text(self, font, UiKit.t("Next: %s, holds %d") % [String(n["name"]), int(n["capacity"])],
			Vector2(RIGHT_X, 146), 13, UiKit.DIM)
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
				Vector2(RIGHT_X, 168), 13, UiKit.DOWN)
		else:
			var err := arena.can_build(office.tier, office.credits)
			if err != "":
				UiKit.text(self, font, UiKit.fit_px(font, err, 12, 340.0),
					Vector2(RIGHT_X, 168), 12, UiKit.DIM)

	UiKit.text(self, font, UiKit.t("THE DIARY"), Vector2(RIGHT_X, 270), 15, UiKit.INK)
	if season.bid_open():
		## The preview is honest and it is the reason the screen exists: the
		## player is choosing between numbers, not adjectives, and the number
		## moves with the ground he has banked into.
		var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
		var p := season.bid_preview(offer_i % season.bid_offers.size(), budget_i)
		UiKit.text(self, font, UiKit.t(String(o["blurb"])), Vector2(RIGHT_X, 424), 12, UiKit.DIM)
		## TWO LINES EACH, because both of these ran off the right of the frame in
		## the real face — 1021 and 976 of a 960 — and both are sentences the
		## player is meant to read before spending credits on a date. Breaking
		## them at the natural clause beats shrinking a figure somebody is about
		## to make a decision on.
		UiKit.text(self, font, UiKit.t("Matchday %d  ·  about %d through the gate") % [
			int(o["event"]) + 1, int(p["heads"])],
			Vector2(RIGHT_X, 442), 13, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("%d CC spent") % int(p["cost"]),
			Vector2(RIGHT_X, 460), 13, UiKit.DIM)
		var net := int(p["net"])
		UiKit.text(self, font, UiKit.t("%+d before the podium,") % net,
			Vector2(RIGHT_X, 484), 15, UiKit.UP if net >= 0 else UiKit.DOWN)
		UiKit.text(self, font, UiKit.t("up to %+d if you win it") % int(p["best"]),
			Vector2(RIGHT_X, UiKit.bottom(34.0)), 13, UiKit.UP if net >= 0 else UiKit.DOWN)
		return
	if season.booked != null:
		var away := season.booked.events_away(season.world.event)
		UiKit.text(self, font, UiKit.t("%s, %s") % [season.booked.kind_name(),
			UiKit.t("this matchday") if away == 0 else UiKit.t("in %d matchdays") % away],
			Vector2(RIGHT_X, 304), 13, UiKit.YOU)
		UiKit.text(self, font, UiKit.t("The budget is already spent. Win it and it comes back."),
			Vector2(RIGHT_X, 326), 12, UiKit.DIM)
	else:
		UiKit.text(self, font, UiKit.t("No tournament this year."),
			Vector2(RIGHT_X, 304), 13, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("The federation offers dates between seasons."),
			Vector2(RIGHT_X, 326), 12, UiKit.EDGE)

	if not season.last_show.is_empty():
		var l := season.last_show
		UiKit.text(self, font, UiKit.t("LAST TIME OUT"), Vector2(RIGHT_X, 466), 13, UiKit.DIM)
		var f := String(l.get("finish", ""))
		UiKit.text(self, font, UiKit.t("%s · %d in · %+d cr%s") % [
			String(l.get("kind", "?")), int(l.get("heads", 0)), int(l.get("net", 0)),
			"" if f == "" else UiKit.t(" · %s") % f],
			Vector2(RIGHT_X, 490), 13,
			UiKit.UP if int(l.get("net", 0)) >= 0 else UiKit.DOWN)
