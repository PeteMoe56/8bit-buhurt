extends Node2D
## YOUR OWN PAGE. Reputation, the book that follows you, and who wants you.
##
## Every other screen in this game is about the club. This is the only one that
## is about the person playing, and it is the only one whose contents survive
## taking another job — which is the entire reason it exists.

const COL_Y := 92.0
const COL_H := 300.0
const COL_W := 292.0
const L_X := 24.0
const M_X := 334.0
const R_X := 644.0

## THE OFFER ROW'S PITCH, and the two offsets inside it, as constants because the
## SCREEN and the BUTTONS are built by two different functions — `_build` places
## the controls and `_draw` paints the names — and the first version had them
## agreeing only by both containing the number 72.
##
## They did not agree for long. At that pitch each "Take it" sat 22px under its
## own club and 14px above the NEXT one, so every button read as belonging to the
## club below it: three offers, and the one you tapped was not the one you meant.
## The fix is the spacing, but the reason it stays fixed is that there is now one
## place to change it.
## Name, then its division, then the button: two offers a column, each with
## room to say where it is (round 3: the name and division cut each other).
const OFFER_PITCH := 104.0
const OFFER_NAME_DY := 50.0
const OFFER_BUTTON_DY := 74.0
const OFFER_BUTTON_H := 36.0
const OFFERS_SHOWN := 2


static func offer_row_y(i: int) -> float:
	return COL_Y + float(i) * OFFER_PITCH

var font: Font
var ui: CanvasLayer
var season: Season
var flash: String = ""
## WHAT KIND OF LINE IT IS. Everything here was drawn in the refusal color, so
## "A week's work in one afternoon." read as an error. 0 a refusal, 1 good news,
## 2 a question (a two-tap confirm).
var flash_tone: int = 0


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if season == null:
		return
	var offers := Jobs.offers(season.coach, season.world)
	## AT MOST THREE ON SCREEN. The list is sorted best-first and a coach at the
	## top of the country out-rates most of the pyramid, so the raw list can be
	## thirty clubs long — which is a scrollbar, and a scrollbar here would turn
	## the best moment in the career into an inventory screen.
	var shown: int = mini(offers.size(), OFFERS_SHOWN)
	for i in shown:
		var cid: int = offers[i]
		## Taking a job leaves this club for good: it is a danger button, and the
		## second tap says so.
		## NEUTRAL UNTIL IT BITES (round 2: a job offer in the Delete style read as
		## destructive). Considering is harmless; the second tap, "Sign and leave
		## it all", is the one that gives something up, and it is red.
		var job := UiKit.button(UiKit.t("Sign and leave it all") if confirm_take == cid else UiKit.t("Consider the job"),
			Vector2(R_X + 16, offer_row_y(i) + OFFER_BUTTON_DY),
			Vector2(COL_W - 32, OFFER_BUTTON_H), _take.bind(cid))
		ui.add_child(UiKit.danger(job) if confirm_take == cid else job)
	if confirm_take >= 0:
		ui.add_child(UiKit.button(UiKit.t("Stay"), Vector2(190, UiKit.screen().y - 56),
			Vector2(150, 44), func():
				confirm_take = -1
				flash = ""
				_build()))
	ui.add_child(UiKit.back_button("res://scenes/Season.tscn"))
	## THE DIFFICULTY LIVES WITH THE CAREER, and Settings can only change it while
	## a career is open — which it never was, because Settings was reachable only
	## from the title screen, where no career is. This is the door from inside.
	## SETTINGS MOVED TO THE CLUB MENU (30 Sep 2026), the door from inside a career.
	queue_redraw()


## TWO TAPS, AND THE SECOND ONE SAYS WHAT IT COSTS. Taking a job hands back the
## whole club — credits, buildings, captains, playbook — and it was one tap with
## no warning, autosaved on the spot.
var confirm_take: int = -1


func _take(club_id: int) -> void:
	if confirm_take != club_id:
		confirm_take = club_id
		var carry: int = mini(season.office.credits, season.office.bought) if season.office.bought > 0 else 0
		flash_tone = 2
		flash = UiKit.t("You leave the squad, %d CC, the buildings, captains and playbook behind%s. Tap again to sign.") % [
			maxi(0, season.office.credits - carry),
			(UiKit.t(" (your %d bought CC come with you)") % carry) if carry > 0 else ""]
		_build()
		return
	confirm_take = -1
	var err := season.take_job(club_id)
	flash_tone = 0
	flash = UiKit.said(err)
	if err == "":
		Session.autosave()
	_build()


func _draw() -> void:
	if season == null:
		return
	UiKit.set_mood(season.mood())
	UiKit.ground(self)
	var c := season.coach
	## THE BUTTON THAT OPENS THIS SAYS "Your career"; so does the title now
	## (blind review round 3: the menu said one thing and the screen "COACH").
	UiKit.text(self, font, UiKit.t("YOUR CAREER"), Vector2(24, 40), 26, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Your record, your standing and who wants you."),
		Vector2(24, 62), 14, UiKit.DIM)
	UiKit.right(self, font, UiKit.t("Season %d") % season.world.season,
		Vector2(UiKit.screen().x - 24, 46), 16, UiKit.DIM, 220)

	_standing(c)
	_the_book(c)
	_offers(c)

	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, UiKit.screen().y - 70), 13,
			[UiKit.DOWN, UiKit.UP, UiKit.YOU][flash_tone])


## REPUTATION, drawn as a meter out of twenty rather than as a number, because
## the number only means something against the ceiling and against the clubs it
## is about to be compared with.
func _standing(c: Coach) -> void:
	UiKit.panel(self, Rect2(L_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("YOUR STANDING"), Vector2(L_X + 16, COL_Y + 26), 12, UiKit.DIM)
	## A RANK, SAID AS ONE (round 6: "Unknown" in big gold read as missing data).
	var rw := font.get_string_size(UiKit.t("Rank:"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	UiKit.text(self, font, UiKit.t("Rank:"), Vector2(L_X + 16, COL_Y + 60), 14, UiKit.DIM)
	UiKit.text(self, font, c.standing(), Vector2(L_X + 24 + rw, COL_Y + 62), 22, UiKit.YOU)
	UiKit.meter(self, Rect2(L_X + 16, COL_Y + 76, COL_W - 32, 16),
		c.reputation, Coach.REP_MAX, UiKit.YOU)
	UiKit.right(self, font, UiKit.t("reputation %d of %d") % [c.reputation, Coach.REP_MAX],
		Vector2(L_X + COL_W - 16, COL_Y + 112), 12, UiKit.DIM, 160)

	var y := COL_Y + 146.0
	_line("At", season.world.clubs[c.club_id]["name"] if c.club_id >= 0 else "—", y)
	y += 24.0
	_line("Years here", "%d" % c.years_here, y)
	y += 24.0
	_line("Posts", "%d" % c.posts.size(), y)
	y += 34.0
	## WHAT IT COSTS TO HAVE A BAD YEAR, said out loud on the screen that owns the
	## number. Reputation is additive up and multiplicative down, and a player who
	## does not know that reads a halving as a bug.
	UiKit.text_fit(self, font, UiKit.t("Win your division and this climbs."),
		Vector2(L_X + 16, y), 14, UiKit.EDGE.lightened(0.5), COL_W - 32.0)
	UiKit.text_fit(self, font, UiKit.t("Outside the top four, it halves."),
		Vector2(L_X + 16, y + 16), 14, UiKit.DOWN, COL_W - 32.0)


func _the_book(c: Coach) -> void:
	UiKit.panel(self, Rect2(M_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("YOUR RECORD"), Vector2(M_X + 16, COL_Y + 26), 12, UiKit.DIM)
	var rows := [
		[UiKit.t("Seasons finished"), "%d" % c.seasons],
		[UiKit.t("Record"), c.record_line()],
		[UiKit.t("Win rate"), "%d%%" % int(round(c.win_rate() * 100.0))],
		[UiKit.t("Cups"), "%d" % c.cups],
		[UiKit.t("Promotions"), "%d" % c.promotions],
		[UiKit.t("Relegations"), "%d" % c.relegations],
	]
	var y := COL_Y + 62.0
	for row in rows:
		UiKit.text(self, font, String(row[0]), Vector2(M_X + 16, y), 14, UiKit.DIM)
		UiKit.right(self, font, String(row[1]), Vector2(M_X + COL_W - 16, y), 14,
			UiKit.DOWN if String(row[0]) == UiKit.t("Relegations") and c.relegations > 0 else UiKit.INK, 140)
		y += 30.0
	if c.fought() == 0:
		UiKit.para(self, font, UiKit.t("It fills in when your first season ends."), Vector2(M_X + 16, y + 8), 14, UiKit.DIM, COL_W - 32.0, 17.0)
	else:
		UiKit.text_fit(self, font, UiKit.t("It follows you, not the club."),
			Vector2(M_X + 16, COL_Y + COL_H - 14), 14, UiKit.EDGE.lightened(0.5), COL_W - 32.0)


func _offers(c: Coach) -> void:
	UiKit.panel(self, Rect2(R_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("WHO WANTS YOU"), Vector2(R_X + 16, COL_Y + 26), 12, UiKit.DIM)
	var offers := Jobs.offers(c, season.world)
	if offers.is_empty():
		UiKit.text(self, font, UiKit.t("Nobody, yet."), Vector2(R_X + 16, COL_Y + 62), 15, UiKit.DIM)
		UiKit.para(self, font, UiKit.t("Clubs come for a coach who out-rates them. Win something."),
			Vector2(R_X + 16, COL_Y + 92), 14, UiKit.EDGE.lightened(0.5), COL_W - 32.0, 16.0)
		return
	var shown: int = mini(offers.size(), OFFERS_SHOWN)
	for i in shown:
		var cid: int = offers[i]
		var club: Dictionary = season.world.clubs[cid]
		var y := offer_row_y(i) + OFFER_NAME_DY
		var dream: bool = cid == c.favorite_club_id
		## A hairline above every row but the first, so three offers read as three
		## rows rather than as a column of names and a column of buttons.
		if i > 0:
			draw_rect(Rect2(R_X + 16, y - 22.0, COL_W - 32, 1.0), UiKit.EDGE)
		## THE NAME GETS THE ROOM THE DIVISION DOES NOT USE (blind review, 29 Sep:
		## "Milwaukee Free Co." ran into "Backyard Circuit"). Measured, not counted.
		var tier_word := League.tier_name(int(club["tier"]))
		UiKit.text(self, font, UiKit.clip_px(font, String(club["name"]), 16, COL_W - 32.0),
			Vector2(R_X + 16, y), 16, UiKit.UP if dream else UiKit.INK)
		UiKit.text_fit(self, font, UiKit.t("%s  ·  rated %d") % [tier_word, int(club.get("power", 0))],
			Vector2(R_X + 16, y + 17.0), 13, UiKit.DIM, COL_W - 32.0)
	if offers.size() > shown:
		UiKit.right(self, font, UiKit.t("and %d more want you") % (offers.size() - shown),
			Vector2(R_X + COL_W - 16, COL_Y + COL_H - 14), 14, UiKit.DIM, 160)
	else:
		## TWO LINES. It was clipped at forty characters in English too — "A few
		## clubs are interested in taki..." — which nobody could see was a cut.
		UiKit.para(self, font, c.offer_blurb(),
			Vector2(R_X + 16, COL_Y + COL_H - 34), 14, UiKit.EDGE.lightened(0.5), COL_W - 32.0, 17.0)


func _line(label: String, value: String, y: float) -> void:
	UiKit.text(self, font, UiKit.t(label), Vector2(L_X + 16, y), 14, UiKit.DIM)
	UiKit.right(self, font, UiKit.clip(value, 18), Vector2(L_X + COL_W - 16, y), 14, UiKit.INK, 190)
