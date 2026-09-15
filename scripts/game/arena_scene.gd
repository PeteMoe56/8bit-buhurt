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
	ui.add_child(UiKit.button("Back", Vector2(UiKit.right_edge(98.0), 14), Vector2(78, 36), func():
		Session.autosave()
		UiKit.back("res://scenes/Season.tscn")))

	if not arena.at_top():
		var err := arena.can_build(office.tier, office.credits)
		var label := "Build the %s — %d CC" % [String(arena.next()["name"]), arena.next_cost()]
		ui.add_child(UiKit.button(label if err == "" else "Locked",
			Vector2(RIGHT_X, 212), Vector2(340, 40), _build))

	if season.bid_open():
		## THE BID. Two dials on one screen, both spent the moment he takes it —
		## the date and the promotion.
		var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
		ui.add_child(UiKit.button("Date: %s — %d CC" % [String(o["name"]), int(o["bid"])],
			Vector2(RIGHT_X, 280), Vector2(340, 36), func():
				offer_i = (offer_i + 1) % season.bid_offers.size()
				flash = ""
				_rebuild()))
		ui.add_child(UiKit.button("Budget: %s — %d CC" % [
				String(ClubEvent.BUDGETS[budget_i]["name"]),
				int(ClubEvent.BUDGETS[budget_i]["cost"])],
			Vector2(RIGHT_X, 322), Vector2(340, 36), func():
				budget_i = (budget_i + 1) % ClubEvent.BUDGETS.size()
				flash = ""
				_rebuild()))
		ui.add_child(UiKit.button("Take the date", Vector2(RIGHT_X, 364),
			Vector2(166, 40), _bid))
		ui.add_child(UiKit.button("Pass this year", Vector2(RIGHT_X + 174, 364),
			Vector2(166, 40), func():
				season.decline_bid()
				Session.autosave()
				flash = "No tournament this year."
				_rebuild()))
	elif season.booked == null:
		ui.add_child(UiKit.button("Run a demo", Vector2(RIGHT_X, 384),
			Vector2(340, 40), _demo))
	queue_redraw()


func _build() -> void:
	var err := office.build_arena()
	if err != "":
		flash = err
		_rebuild()
		return
	Session.autosave()
	flash = "Built. %s." % arena.arena_name()
	_rebuild()


func _bid() -> void:
	var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
	var nm := String(o["name"])
	var err := season.take_bid(offer_i % season.bid_offers.size(), budget_i)
	flash = UiKit.said(err) if err != "" else "%s is yours. The rest of the year is preparation." % nm
	if err == "":
		Session.autosave()
	_rebuild()


func _demo() -> void:
	var err := season.run_demo()
	flash = UiKit.said(err) if err != "" else "Demo run. %d CC." % int(season.last_show.get("gate", 0))
	if err == "":
		Session.autosave()
	_rebuild()


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	UiKit.ground(self)
	UiKit.text(self, font, arena.arena_name().to_upper(), Vector2(24, 40), 22, UiKit.YOU)
	UiKit.text(self, font, "%s  ·  %s  ·  %s fans  ·  %d CC" % [
		office.note_word(), _capacity_word(), _fans_word(), office.credits],
		Vector2(24, 64), 14, UiKit.DIM)
	## The two numbers that fill the seats, said plainly. Notoriety is a turnout
	## percentage wearing a different hat, so it is shown as both.
	UiKit.right(self, font, "notoriety %d of %d  ·  %d%% turn out  ·  %d CC a fight" % [
		int(round(office.notoriety)), int(ClubOffice.NOTORIETY_MAX),
		int(round(office.turnout() * 100.0)), office.crowd_pay()],
		Vector2(UiKit.right_edge(120.0), 64), 13, UiKit.DIM, 320.0)
	## THE METER, because a band you cannot see coming is a band you cannot chase.
	## Retro Bowl's whole fan bar is this: the player watches it fill and knows a
	## raise is close. A number alone does not do that — 71 and 74 read the same
	## and one of them is a fight away from paying more.
	_meter(Vector2(520, 76), 320.0)
	UiKit.right(self, font, "Level %d of %d" % [arena.level, Arena.MAX_LEVEL],
		Vector2(UiKit.right_edge(120.0), 40), 14, UiKit.DIM, 200.0)

	_draw_ground()
	## Clipped to its own column. The National Arena's blurb is long enough to
	## run under the diary and print through the payout line.
	UiKit.text(self, font, UiKit.clip(String(arena.here()["blurb"]), 88),
		Vector2(24, GROUND.end.y + 26), 13, UiKit.DIM)
	_draw_diary()
	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, GROUND.end.y + 52), 14, UiKit.INK)


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
		## Fitted to the slot and centred, so an image that is not exactly the
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
		UiKit.text(self, font, "%s  —  artwork to come" % arena.arena_name(),
			g.position + Vector2(18, 30), 15, UiKit.DIM)
		UiKit.text(self, font, ART_DIR + "arena_%d.png" % arena.level,
			g.position + Vector2(18, 52), 12, UiKit.EDGE)
		UiKit.text(self, font, "%d × %d" % [int(g.size.x), int(g.size.y)],
			g.position + Vector2(18, 70), 12, UiKit.EDGE)
		## Corner ticks, so the slot reads as a frame waiting to be filled rather
		## than as a panel that failed to draw.
		for c in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
			var at := g.position + Vector2(g.size.x * c.x, g.size.y * c.y)
			var dx: float = 22.0 if c.x == 0 else -22.0
			var dy: float = 22.0 if c.y == 0 else -22.0
			draw_line(at, at + Vector2(dx, 0), UiKit.FRAME, 2.0)
			draw_line(at, at + Vector2(0, dy), UiKit.FRAME, 2.0)

	## YOUR BADGE, over whatever is behind it, at the quality this ground
	## affords. This one IS the game's own rendering and is meant to be: it is
	## the mark the player picked out of the icon bank, so it cannot live inside
	## a fixed image. Pete asked for it directly — *"Yes, the badge itself gets
	## better"* — and it draws over the artwork when the artwork arrives.
	UiKit.badge(self, Vector2(g.end.x - 76.0, g.end.y - 76.0), 46.0,
		season.club.kit, season.club.icon_colour, season.club.icon, arena.badge_quality())
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
	UiKit.text(self, font, "THE GROUND", Vector2(RIGHT_X, 118), 15, UiKit.INK)
	if arena.at_top():
		UiKit.text(self, font, "Built as far as a club can build.",
			Vector2(RIGHT_X, 146), 13, UiKit.DIM)
	else:
		var n := arena.next()
		UiKit.text(self, font, "Next: %s, holds %d" % [String(n["name"]), int(n["capacity"])],
			Vector2(RIGHT_X, 146), 13, UiKit.DIM)
		## AND WHICH DIVISION IT NEEDS. `arena.next_tier()` was written for this
		## screen — its own comment says so — and then never called, so the one
		## thing the player most needs to know was only ever visible inside a
		## refusal he had to earn by trying. **"Get promoted" is a different
		## instruction from "save up"** and he should be able to tell which one
		## he is looking at before he taps anything.
		var need := arena.next_tier()
		if need > office.tier:
			UiKit.right(self, font, "needs the %s" % League.tier_name(need),
				Vector2(UiKit.right_edge(), 146), 12, UiKit.DOWN, 300)
		var err := arena.can_build(office.tier, office.credits)
		if err != "":
			UiKit.text(self, font, err, Vector2(RIGHT_X, 170), 12,
				UiKit.DOWN if err.find("promoted") != -1 else UiKit.DIM)

	UiKit.text(self, font, "THE DIARY", Vector2(RIGHT_X, 270), 15, UiKit.INK)
	if season.bid_open():
		## The preview is honest and it is the reason the screen exists: the
		## player is choosing between numbers, not adjectives, and the number
		## moves with the ground he has banked into.
		var o: Dictionary = season.bid_offers[offer_i % season.bid_offers.size()]
		var p := season.bid_preview(offer_i % season.bid_offers.size(), budget_i)
		UiKit.text(self, font, String(o["blurb"]), Vector2(RIGHT_X, 424), 12, UiKit.DIM)
		## TWO LINES EACH, because both of these ran off the right of the frame in
		## the real face — 1021 and 976 of a 960 — and both are sentences the
		## player is meant to read before spending credits on a date. Breaking
		## them at the natural clause beats shrinking a figure somebody is about
		## to make a decision on.
		UiKit.text(self, font, "Matchday %d  ·  about %d through the gate" % [
			int(o["event"]) + 1, int(p["heads"])],
			Vector2(RIGHT_X, 442), 13, UiKit.DIM)
		UiKit.text(self, font, "%d CC spent" % int(p["cost"]),
			Vector2(RIGHT_X, 460), 13, UiKit.DIM)
		var net := int(p["net"])
		UiKit.text(self, font, "%+d before the podium," % net,
			Vector2(RIGHT_X, 484), 15, UiKit.UP if net >= 0 else UiKit.DOWN)
		UiKit.text(self, font, "up to %+d if you win it" % int(p["best"]),
			Vector2(RIGHT_X, UiKit.bottom(34.0)), 13, UiKit.UP if net >= 0 else UiKit.DOWN)
		return
	if season.booked != null:
		var away := season.booked.events_away(season.world.event)
		UiKit.text(self, font, "%s, %s" % [season.booked.kind_name(),
			"this matchday" if away == 0 else "in %d matchdays" % away],
			Vector2(RIGHT_X, 304), 13, UiKit.YOU)
		UiKit.text(self, font, "The budget is already spent. Win it and it comes back.",
			Vector2(RIGHT_X, 326), 12, UiKit.DIM)
	else:
		UiKit.text(self, font, "No tournament this year.",
			Vector2(RIGHT_X, 304), 13, UiKit.DIM)
		UiKit.text(self, font, "The federation offers dates between seasons.",
			Vector2(RIGHT_X, 326), 12, UiKit.EDGE)

	if not season.last_show.is_empty():
		var l := season.last_show
		UiKit.text(self, font, "LAST TIME OUT", Vector2(RIGHT_X, 466), 13, UiKit.DIM)
		var f := String(l.get("finish", ""))
		UiKit.text(self, font, "%s · %d in · %+d cr%s" % [
			String(l.get("kind", "?")), int(l.get("heads", 0)), int(l.get("net", 0)),
			"" if f == "" else " · %s" % f],
			Vector2(RIGHT_X, 490), 13,
			UiKit.UP if int(l.get("net", 0)) >= 0 else UiKit.DOWN)
