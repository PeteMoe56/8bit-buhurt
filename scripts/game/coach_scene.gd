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
const OFFER_PITCH := 84.0
const OFFER_NAME_DY := 50.0
const OFFER_BUTTON_DY := 66.0
const OFFER_BUTTON_H := 34.0
const OFFERS_SHOWN := 3


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
		ui.add_child(UiKit.button(UiKit.t("Sign and leave it all") if confirm_take == cid else UiKit.t("Take it"),
			Vector2(R_X + 16, offer_row_y(i) + OFFER_BUTTON_DY),
			Vector2(COL_W - 32, OFFER_BUTTON_H), _take.bind(cid)))
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
	ui.add_child(UiKit.button(UiKit.t("Settings"), Vector2(356, UiKit.screen().y - 56),
		Vector2(150, 44), func():
			Session.autosave()
			UiKit.go("res://scenes/Settings.tscn"), "cog"))
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
	UiKit.text(self, font, c.display_name.to_upper(), Vector2(24, 46), 26, UiKit.INK)
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
	UiKit.text(self, font, c.standing(), Vector2(L_X + 16, COL_Y + 62), 22, UiKit.YOU)
	UiKit.meter(self, Rect2(L_X + 16, COL_Y + 76, COL_W - 32, 16),
		c.reputation, Coach.REP_MAX, UiKit.YOU)
	UiKit.right(self, font, UiKit.t("%d of %d") % [c.reputation, Coach.REP_MAX],
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
	UiKit.text(self, font, UiKit.t("Win your division and this climbs."),
		Vector2(L_X + 16, y), 11, UiKit.EDGE.lightened(0.5))
	UiKit.text(self, font, UiKit.t("Finish outside the top four and it halves."),
		Vector2(L_X + 16, y + 16), 11, UiKit.DOWN)


func _the_book(c: Coach) -> void:
	UiKit.panel(self, Rect2(M_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("HIS RECORD"), Vector2(M_X + 16, COL_Y + 26), 12, UiKit.DIM)
	var rows := [
		[UiKit.t("Seasons"), "%d" % c.seasons],
		[UiKit.t("Record"), c.record_line()],
		[UiKit.t("Win rate"), "%d%%" % int(round(c.win_rate() * 100.0))],
		[UiKit.t("Cups"), "%d" % c.cups],
		[UiKit.t("Promotions"), "%d" % c.promotions],
		[UiKit.t("Relegations"), "%d" % c.relegations],
	]
	var y := COL_Y + 62.0
	for row in rows:
		UiKit.text(self, font, String(row[0]), Vector2(M_X + 16, y), 13, UiKit.DIM)
		UiKit.right(self, font, String(row[1]), Vector2(M_X + COL_W - 16, y), 14,
			UiKit.DOWN if String(row[0]) == UiKit.t("Relegations") and c.relegations > 0 else UiKit.INK, 140)
		y += 30.0
	if c.fought() == 0:
		UiKit.text(self, font, UiKit.t("Nothing in it yet."), Vector2(M_X + 16, y + 8), 12, UiKit.DIM)
	else:
		UiKit.text(self, font, UiKit.t("This follows you. The club does not."),
			Vector2(M_X + 16, COL_Y + COL_H - 14), 11, UiKit.EDGE.lightened(0.5))


func _offers(c: Coach) -> void:
	UiKit.panel(self, Rect2(R_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("WHO WANTS YOU"), Vector2(R_X + 16, COL_Y + 26), 12, UiKit.DIM)
	var offers := Jobs.offers(c, season.world)
	if offers.is_empty():
		UiKit.text(self, font, UiKit.t("Nobody, yet."), Vector2(R_X + 16, COL_Y + 62), 15, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("Clubs come for a coach who"), Vector2(R_X + 16, COL_Y + 92), 11,
			UiKit.EDGE.lightened(0.5))
		UiKit.text(self, font, UiKit.t("out-rates them. Win something."), Vector2(R_X + 16, COL_Y + 108), 11,
			UiKit.EDGE.lightened(0.5))
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
		UiKit.text(self, font, UiKit.clip(String(club["name"]), 18),
			Vector2(R_X + 16, y), 15, UiKit.UP if dream else UiKit.INK)
		UiKit.right(self, font, League.tier_name(int(club["tier"])),
			Vector2(R_X + COL_W - 16, y), 11, UiKit.DIM, 140)
	if offers.size() > shown:
		UiKit.right(self, font, UiKit.t("and %d more want you") % (offers.size() - shown),
			Vector2(R_X + COL_W - 16, COL_Y + COL_H - 14), 11, UiKit.DIM, 160)
	else:
		UiKit.text(self, font, UiKit.clip(c.offer_blurb(), 40),
			Vector2(R_X + 16, COL_Y + COL_H - 14), 11, UiKit.EDGE.lightened(0.5))


func _line(label: String, value: String, y: float) -> void:
	UiKit.text(self, font, UiKit.t(label), Vector2(L_X + 16, y), 13, UiKit.DIM)
	UiKit.right(self, font, UiKit.clip(value, 18), Vector2(L_X + COL_W - 16, y), 13, UiKit.INK, 190)
