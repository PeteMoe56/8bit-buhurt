extends Node2D
## CREATE — Create-A-Player and Create-A-Team, on one screen with two tabs.
##
## FIGHTER writes a man onto your reserve. Four per club, ever, at a rising
## price, and every one of them is capped to your own division — see Workshop
## for why that governor is not optional.
##
## CLUB is your heraldry and your name. Free, and editable whenever you like,
## because it is your club; the credits buy fighters, not colors.
##
## THE CEILING IS ON SCREEN AT ALL TIMES. A creation screen that lets you build
## a man and only then tells you he is illegal has wasted the whole session —
## so the rating bar shows where the cap is while the sliders are moving, and
## the Sign button says what is wrong instead of just refusing.

## A THIRD TAB RATHER THAN A BUTTON IN A GAP, and the gap is the reason.
##
## The grade went on the club tab first, at (24, 310), and the club badge is
## drawn centerd at (116, 372) with a radius of 54 — so it spans y 318 to 426 and
## the button sat straight on top of it. `test_layout.gd` would have caught it;
## looking at the numbers caught it first.
##
## It wants the room anyway. This is the one screen where the player picks how
## hard his whole career is going to be, and five options each need a sentence —
## Retro Bowl gives its difficulty a described setting on an options page rather
## than a toggle in a corner, and the description is the part that keeps the
## setting honest.
enum Tab { FIGHTER, CLUB, GRADE }

const STAT_X := 24.0
const STAT_Y := 150.0
const STAT_ROW := 48.0
const SLIDER_X := 150.0
const SLIDER_W := 300.0
const RIGHT_X := 520.0
## The bank's shelf: four across, two down, which holds the biggest pack with
## room and leaves the badge and the name fields their own half of the screen.
const BANK_X := 470.0
const BANK_R := 34.0
const BANK_GAP := 30.0
const BANK_COLS := 4

var font: Font
var season: Season
var shop: Workshop
var ui: CanvasLayer
var tab: int = Tab.FIGHTER
var flash := ""

var card: FighterCard
var name_edit: LineEdit
var club_name_edit: LineEdit
var club_short_edit: LineEdit
## WHAT HAS BEEN TYPED AND NOT SAVED. Every other button rebuilds the screen,
## and the rebuilt boxes used to be filled from the saved values — so a name
## typed and then followed by a tap on a kit colour was thrown away. The boxes
## write here as they are typed and read from here when rebuilt.
var draft_club_name = null
var draft_club_short = null
var kit_i := 0
var mark_col_i := 0
var icon_i := 0
## Which pack's shelf is showing. One shelf at a time, because twenty marks in
## one grid is a wall and the packs are how the bank is going to grow.
var pack_i := 0
## Who the made man replaces. The club starts full at thirteen, so this is not
## an edge case the screen handles — it is the normal path, and it is a real
## decision the player makes with the rest of them.
var replace_i := 0

## One row per grade down the left, the chosen one's sentence on the right.
const GRADE_Y := 132.0
const GRADE_ROW := 46.0
const GRADE_BTN := Vector2(228.0, 38.0)
const GRADE_TEXT_X := 288.0
const GRADE_TEXT_W := 648.0

const STATS := ["strength", "base", "skill", "gas", "aggression"]
const STAT_LABEL := ["Strength", "Base", "Skill", "Gas", "Aggression"]
const STAT_BLURB := [
	"Puts men down and drives through a line.",
	"Resistance to being put down. Wins the most rounds.",
	"Takedowns, escapes, anything out of a bad position.",
	"The tank. Runs out, and everything else goes with it.",
	"How readily he commits unasked. High is not better.",
]


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	shop = season.workshop
	card = Workshop.blank()
	kit_i = maxi(0, IconBank.KIT_COLORS.find(season.club.kit))
	mark_col_i = maxi(0, IconBank.MARK_COLORS.find(season.club.icon_color))
	icon_i = int(season.club.icon)
	pack_i = maxi(0, IconBank.packs().find(String(IconBank.entry(icon_i)["pack"])))
	ui = CanvasLayer.new()
	add_child(ui)
	_rebuild()


func _limits() -> Dictionary:
	return Workshop.limits(season.office.tier)


# ------------------------------------------------------------------ controls
func _rebuild() -> void:
	for c in ui.get_children():
		c.queue_free()
	name_edit = null
	club_name_edit = null
	club_short_edit = null

	ui.add_child(UiKit.button(UiKit.t("FIGHTER"), Vector2(24, 72), Vector2(150, 34), func():
		tab = Tab.FIGHTER
		flash = ""
		_rebuild()))
	ui.add_child(UiKit.button(UiKit.t("CLUB"), Vector2(180, 72), Vector2(150, 34), func():
		tab = Tab.CLUB
		flash = ""
		_rebuild()))
	ui.add_child(UiKit.button(UiKit.t("GRADE"), Vector2(336, 72), Vector2(150, 34), func():
		tab = Tab.GRADE
		flash = ""
		_rebuild()))
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(UiKit.right_edge(98.0), 14), Vector2(78, 36), func():
		Session.autosave()
		UiKit.back("res://scenes/Season.tscn")))
	if tab == Tab.FIGHTER:
		_fighter_controls()
	elif tab == Tab.CLUB:
		_club_controls()
	else:
		_grade_controls()
	queue_redraw()


func _fighter_controls() -> void:
	if shop.left() <= 0:
		return
	name_edit = LineEdit.new()
	## 116 AND NOT 108. The tab row ends at 106 including its drop shadow, so at
	## 108 this box sat two pixels under it and the shadow ran along its top edge
	## — the pair read as one control with a line through it. Nothing overlapped,
	## which is why the layout sweep passed it for as long as it has existed.
	name_edit.position = Vector2(STAT_X, 116)
	name_edit.size = Vector2(280, 32)
	name_edit.max_length = 20
	name_edit.placeholder_text = "His name"
	name_edit.text = card.display_name
	## The card is the working copy of the new man, so typing goes straight on it.
	name_edit.text_changed.connect(func(t: String): card.display_name = t)
	ui.add_child(name_edit)

	var lim := _limits()
	for i in STATS.size():
		var y := STAT_Y + float(i) * STAT_ROW
		var key: String = STATS[i]
		var sl := HSlider.new()
		## 28 tall, not 20: the track draws in the middle either way, and the
		## extra height is the part a thumb actually lands on.
		sl.position = Vector2(SLIDER_X, y + 6)
		sl.size = Vector2(SLIDER_W, 28)
		sl.min_value = 1
		sl.max_value = int(lim["stat"])
		sl.step = 1
		sl.value = int(card.get(key))
		sl.value_changed.connect(func(v):
			card.set(key, int(v))
			queue_redraw())
		ui.add_child(sl)

	## Weight is not a stat you spend on — it is a build decision with a cost on
	## both sides, so it sits with the sliders but outside the cap.
	var w := HSlider.new()
	w.position = Vector2(SLIDER_X, STAT_Y + 5.0 * STAT_ROW + 6.0)
	w.size = Vector2(SLIDER_W, 28)
	w.min_value = 130
	w.max_value = 340
	w.step = 1
	w.value = card.weight
	w.value_changed.connect(func(v):
		card.weight = int(v)
		queue_redraw())
	ui.add_child(w)

	ui.add_child(UiKit.button(UiKit.t("Position: %s") % card.pos_name(),
		Vector2(RIGHT_X, 108), Vector2(200, 34), func():
			card.pos = ((int(card.pos) + 1) % 5) as Tuning.Pos
			_rebuild()))
	var out := _cuttable()
	if not out.is_empty():
		var who: FighterCard = out[replace_i % out.size()]
		ui.add_child(UiKit.button(UiKit.t("Replaces: %s (%d)") % [UiKit.clip(who.display_name, 14),
				who.overall()], Vector2(RIGHT_X + 208, 108), Vector2(208, 34), func():
			replace_i = (replace_i + 1) % out.size()
			_rebuild()))
	ui.add_child(UiKit.button(UiKit.t("Sign him — %d CC") % shop.cost(),
		Vector2(STAT_X, 486), Vector2(260, 42), _sign))
	ui.add_child(UiKit.button(UiKit.t("Start over"), Vector2(296, 486), Vector2(160, 42), func():
		card = Workshop.blank()
		flash = ""
		_rebuild()))


## Only the reserve. A man on the eight cannot be written over from here — the
## model refuses it, and offering him in the list anyway would be a button whose
## only outcome is an error message.
func _cuttable() -> Array:
	var out: Array = []
	for f in season.club.reserves():
		out.append(f)
	out.sort_custom(func(a, b): return a.rating() < b.rating())
	return out


func _sign() -> void:
	card.display_name = name_edit.text if name_edit != null else ""
	var out := _cuttable()
	var who: FighterCard = null
	if season.club.roster.size() >= MeleeClub.SQUAD_MAX and not out.is_empty():
		who = out[replace_i % out.size()]
	var err := shop.create(season.office, season.club, card, who)
	if err != "":
		flash = err
		_rebuild()
		return
	season.sync_power()
	Session.autosave()
	flash = UiKit.t("%s signed%s. He is on the reserve — promote him in SQUAD.") % [
		card.display_name, "" if who == null else UiKit.t(", %s released") % who.display_name]
	replace_i = 0
	card = Workshop.blank()
	_rebuild()


## FOUR TOWNS THE CLUB IS NOT IN. Offering the town you already live in is a
## button that does nothing, which is the sort of thing a screen should not have.
var town_offers: Array[String] = []


## THE TOWN BLOCK LIVES IN THE RIGHT COLUMN, under the mark bank.
##
## It was on the left at y 306, which put it through the badge at 372 and its
## "HOME TOWN" label through the kit-color button at 258. Nothing in the suite
## could see either: `test_layout.gd` measures controls against controls and says
## in its own header that it cannot see drawn text. `test_ink.gd` — written an
## hour later to read the ledger `UiKit` now keeps — found both on its first run,
## along with four more elsewhere in the game.
## ONE OFFER AT A TIME, IN THE BOTTOM BAND. Four cards and a reroll went through
## the badge on the left and through the mark bank on the right — this tab has no
## free 2x2 anywhere, which is a thing the ledger told me twice before I believed
## it. A relocation is one decision; one town and a "somewhere else" is the
## honest control for it and fits in the band above the Save button.
const TOWN_Y := 440.0
const TOWN_CARD := Vector2(240.0, 34.0)


func _offer_towns() -> void:
	var pool := Cities.names(season.world.region)
	pool.shuffle()
	town_offers.clear()
	var mine := season.city()
	for c in pool:
		if String(c) == mine:
			continue
		town_offers.append(String(c))
		if town_offers.size() >= 4:
			break


func _club_controls() -> void:
	club_name_edit = LineEdit.new()
	club_name_edit.position = Vector2(STAT_X, 150)
	club_name_edit.size = Vector2(380, 36)
	club_name_edit.max_length = 30
	club_name_edit.placeholder_text = "Club name"
	club_name_edit.text = draft_club_name if draft_club_name != null else season.club.display_name
	club_name_edit.text_changed.connect(func(t: String): draft_club_name = t)
	ui.add_child(club_name_edit)

	club_short_edit = LineEdit.new()
	club_short_edit.position = Vector2(STAT_X, 200)
	club_short_edit.size = Vector2(120, 36)
	club_short_edit.max_length = 4
	club_short_edit.placeholder_text = "CLB"
	club_short_edit.text = draft_club_short if draft_club_short != null else season.club.short_name
	club_short_edit.text_changed.connect(func(t: String): draft_club_short = t)
	ui.add_child(club_short_edit)

	## ------------------------------------------------------------ the town
	## PETE, 14 Sep 2026: *"have it for create-a-team screen also."*
	##
	## Four towns and a reroll rather than the title screen's twelve — this is a
	## relocation, not a founding, and a club moving house is a decision you make
	## about one town at a time. The list is the region's own: an American league
	## does not offer you Kraków.
	##
	## THE SWAP IS THE SAME SWAP. `Season.set_city` trades with whoever holds the
	## town, so the map stays full here exactly as it does at setup — there is one
	## relocation in this game and both screens call it.
	if town_offers.is_empty():
		_offer_towns()
	if not town_offers.is_empty():
		var town: String = town_offers[0]
		ui.add_child(UiKit.button(UiKit.t("Move to %s") % Cities.full_name(town),
			Vector2(STAT_X, TOWN_Y), TOWN_CARD, func(t = town):
				if not UiKit.confirm("move:" + t):
					flash = UiKit.t("Tap again to move the club to %s.") % Cities.full_name(t)
					_rebuild()
					return
				var was := season.city()
				var err := season.set_city(t)
				flash = UiKit.said(err) if err != "" \
					else "The club moves from %s to %s." % [was,
						Cities.full_name(t)]
				if err == "":
					Session.autosave()
				_offer_towns()
				_rebuild()))
		ui.add_child(UiKit.button(UiKit.t("Somewhere else"),
			Vector2(STAT_X + TOWN_CARD.x + 8.0, TOWN_Y),
			Vector2(200, TOWN_CARD.y), func():
				_offer_towns()
				_rebuild()))

	ui.add_child(UiKit.button(UiKit.t("Kit color"), Vector2(STAT_X, 258), Vector2(150, 34), func():
		kit_i = (kit_i + 1) % IconBank.KIT_COLORS.size()
		_rebuild()))
	ui.add_child(UiKit.button(UiKit.t("Mark color"), Vector2(STAT_X + 158, 258), Vector2(150, 34), func():
		mark_col_i = (mark_col_i + 1) % IconBank.MARK_COLORS.size()
		_rebuild()))

	## THE BANK, as a shelf you can see rather than a cycle button you have to
	## tap twenty times. A mark you do not own is drawn anyway, dimmed, with its
	## price under it — you cannot want a thing you cannot see.
	var packs := IconBank.packs()
	for i in packs.size():
		var take := i
		ui.add_child(UiKit.button(IconBank.PACK_NAME[packs[i]],
			Vector2(BANK_X + float(i) * 116.0, 150), Vector2(110, 30), func():
				pack_i = take
				flash = ""
				_rebuild()))
	var shelf := IconBank.in_pack(packs[pack_i % packs.size()])
	for i in shelf.size():
		var id: int = shelf[i]
		var at := _bank_slot(i)
		## +24 AND NOT +18. The slot's rect runs past the badge so that tapping the
		## NAME under it picks the mark — and at 18 the caption's descender fell
		## one pixel outside its own hit target. `test_ink.gd` found it by
		## refusing to treat a partly-covered label as a deliberate one, which is
		## the right refusal: the bottom of that word was not clickable.
		## FLAT, LIKE EVERY OTHER HIT BOX OVER A DRAWING. This one was not, and
		## so it painted a themed slab over each badge in the bank — the same
		## fault that hid every saved formation name on the chalkboard. Found by
		## looking for the chalkboard's shape everywhere else rather than fixing
		## the one Pete happened to open.
		var bank_b := UiKit.button("", at - Vector2(BANK_R, BANK_R),
			Vector2(BANK_R * 2.0, BANK_R * 2.0 + 24.0), func():
				if shop.owns(id):
					icon_i = id
					flash = ""
				else:
					var err := shop.buy_icon(season.office, id)
					if err == "":
						icon_i = id
						Session.autosave()
						flash = UiKit.t("%s unlocked.") % IconBank.icon_name(id)
					else:
						flash = err
				_rebuild())
		bank_b.flat = true
		bank_b.focus_mode = Control.FOCUS_NONE
		ui.add_child(bank_b)

	ui.add_child(UiKit.button(UiKit.t("Save the club"), Vector2(STAT_X, 486), Vector2(260, 42),
		_save_club))


## ------------------------------------------------------------------ the grade
## ONE ROW PER GRADE, all five visible, rather than a cycle button. A player
## choosing how hard twenty seasons are going to be should be able to see what he
## is turning down, and five rows cost less screen than the badge shelf does.
func _grade_controls() -> void:
	for i in Grade.ORDER.size():
		var g: int = Grade.ORDER[i]
		ui.add_child(UiKit.button(Grade.short_of(g),
			Vector2(STAT_X, GRADE_Y + float(i) * GRADE_ROW), GRADE_BTN, func():
				## THROUGH THE SEASON'S OWN VERB. This wrote the two fields by
				## hand, and the day the grade became changeable from a second
				## screen that would have been two places resetting MATCHED's
				## ladder — one of which would eventually forget.
				season.set_grade(g)
				Session.autosave()
				_rebuild(),
			"cursor" if g == season.grade else ""))


func _draw_grade() -> void:
	var g := season.grade
	## THE PANEL FILLS THE COLUMN. It was 384 wide and the second read-out was
	## printed at x 708, which is 36 pixels PAST its own right edge — the figure
	## was sitting on the background outside the frame that was meant to contain
	## it. Measured now rather than built out of offsets that were true once.
	var box := Rect2(GRADE_TEXT_X, GRADE_Y - 8.0, UiKit.right_edge() - GRADE_TEXT_X, 196.0)
	UiKit.window(self, box, Grade.name_of(g), font)
	var ix := box.position.x + 18.0
	var iw := box.size.x - 36.0
	## `draw_string` does not wrap and `draw_multiline_string` does, which is the
	## whole difference between a blurb and a blurb with its tail off the screen.
	draw_multiline_string(font, Vector2(ix, GRADE_Y + 34.0), Grade.blurb_of(g),
		HORIZONTAL_ALIGNMENT_LEFT, iw, 15, 4, UiKit.INK)

	## WHAT IT IS WORTH, in the two numbers a player can act on, and the
	## multiplier is deliberately printed. This game puts a two-digit overall next
	## to every name on four screens; a setting that quietly changed what those
	## numbers mean without saying so would make the roster screen a liar — which
	## is the XCOM 2 problem, and XCOM at least does not print a stat line.
	var sc := Grade.scale_for(g, season.matched_step, 60, League.Tier.REGIONAL)
	var ry := GRADE_Y + 122.0
	UiKit.text(self, font, UiKit.t("Their numbers, against a middling club"),
		Vector2(ix, ry), 13, UiKit.DIM)
	UiKit.text(self, font, "x%.2f" % sc, Vector2(ix + 300.0, ry), 16,
		UiKit.DOWN if sc > 1.0 else (UiKit.UP if sc < 1.0 else UiKit.INK))
	UiKit.text(self, font, UiKit.t("Calls from the corner"), Vector2(ix, ry + 26.0), 13, UiKit.DIM)
	UiKit.text(self, font, "%d" % Grade.pauses_for(g, season.matched_step,
		season.office.extra_calls()), Vector2(ix + 300.0, ry + 26.0), 16, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Corner, between rounds"), Vector2(ix, ry + 52.0), 13, UiKit.DIM)
	UiKit.text(self, font, "%ds" % int(Grade.corner_time(g)),
		Vector2(ix + 300.0, ry + 52.0), 16, UiKit.INK)

	## THE FOOTER SAYS THE TWO THINGS A PLAYER NEEDS AND THE HEADER SAID NEITHER.
	## Two lines of preamble used to sit at y 108, under a tab strip that runs to
	## 110 with its drop — text drawn behind a button, which is the exact fault
	## the layout sweep exists to catch and which a comment at the top of a screen
	## is always the first to commit.
	UiKit.text(self, font, UiKit.t("It is saved with the club, not with the settings, ")
		+ "and you can change it later.", Vector2(STAT_X, 402.0), 13, UiKit.DIM)


func _save_club() -> void:
	var err := shop.rename(season.club, club_name_edit.text, club_short_edit.text,
		IconBank.KIT_COLORS[kit_i], IconBank.MARK_COLORS[mark_col_i], icon_i)
	if err != "":
		flash = err
		_rebuild()
		return
	draft_club_name = null
	draft_club_short = null
	## The world carries the club's name for the table, so it has to be told.
	season.world.clubs[season.world.player_club]["name"] = season.club.display_name
	Session.autosave()
	flash = UiKit.t("Saved.")
	_rebuild()


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	UiKit.ground(self)
	UiKit.text(self, font, UiKit.t("CREATE"), Vector2(24, 40), 22, UiKit.YOU)
	UiKit.purse(self, font, season.office.credits,
		Vector2(UiKit.right_edge(120.0), 40), 16, UiKit.DIM, 200.0)
	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, 466), 14, UiKit.DIM)
	if tab == Tab.FIGHTER:
		_draw_fighter()
	elif tab == Tab.CLUB:
		_draw_club()
	else:
		_draw_grade()


func _draw_fighter() -> void:
	var lim := _limits()
	if shop.left() <= 0:
		UiKit.text(self, font, UiKit.t("You have written all four men this club will ever get."),
			Vector2(24, 160), 18, UiKit.DIM)
		return
	UiKit.right(self, font, UiKit.t("%d of %d left") % [shop.left(), Workshop.MAX_FIGHTERS],
		Vector2(UiKit.right_edge(120.0), 64), 14, UiKit.DIM, 200.0)

	for i in STATS.size():
		var y := STAT_Y + float(i) * STAT_ROW
		UiKit.text(self, font, STAT_LABEL[i], Vector2(STAT_X, y + 24), 16, UiKit.INK)
		UiKit.text(self, font, str(int(card.get(STATS[i]))),
			Vector2(SLIDER_X + SLIDER_W + 14, y + 24), 16, UiKit.YOU)
		UiKit.text(self, font, STAT_BLURB[i], Vector2(STAT_X, y + 42), 12, UiKit.DIM)
	var wy := STAT_Y + 5.0 * STAT_ROW
	UiKit.text(self, font, UiKit.t("Weight"), Vector2(STAT_X, wy + 24), 16, UiKit.INK)
	UiKit.text(self, font, UiKit.t("%d lb") % card.weight,
		Vector2(SLIDER_X + SLIDER_W + 14, wy + 24), 16, UiKit.YOU)
	UiKit.text(self, font, UiKit.t("In harness. Decides a bullrush more than anything else."),
		Vector2(STAT_X, wy + 42), 12, UiKit.DIM)

	## THE CEILING, DRAWN. The bar fills to his rating and the marshal's line
	## sits at what the division allows, so the cap is a place on screen rather
	## than a sentence that appears after the fact.
	var r := Rect2(RIGHT_X, 190, 340, 22)
	var ceiling := int(lim["rating"])
	UiKit.text(self, font, UiKit.t("Rating"), Vector2(RIGHT_X, 180), 14, UiKit.DIM)
	var frac := clampf(card.rating() / float(ceiling), 0.0, 1.0)
	var over: bool = card.rating() > float(ceiling)
	UiKit.bar(self, r, frac, UiKit.DOWN if over else UiKit.UP)
	draw_line(Vector2(r.end.x, r.position.y - 4), Vector2(r.end.x, r.end.y + 4),
		Tuning.COL_MARSHAL, 2.0)
	UiKit.text(self, font, "%d" % card.overall(), Vector2(RIGHT_X, 232), 20,
		UiKit.DOWN if over else UiKit.INK)
	UiKit.right(self, font, UiKit.t("%s caps a made man at %d") % [String(lim["tier"]), ceiling],
		Vector2(RIGHT_X + 340, 232), 13, UiKit.DIM, 300.0)

	var wage := ClubOffice.wage(card)
	var cap := season.office.cap()
	## The bill AFTER the whole trade, released man included. Showing the cost of
	## signing him without the saving from cutting somebody would make every
	## replacement look like it breaks the cap.
	var bill := ClubOffice.wage_bill(season.club) + wage
	var out := _cuttable()
	if season.club.roster.size() >= MeleeClub.SQUAD_MAX and not out.is_empty():
		bill -= ClubOffice.billed(out[replace_i % out.size()])
	UiKit.text(self, font, UiKit.t("Wage"), Vector2(RIGHT_X, 282), 14, UiKit.DIM)
	UiKit.text(self, font, ClubOffice.money(wage), Vector2(RIGHT_X, 306), 18, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Bill after the trade"), Vector2(RIGHT_X, 340), 14, UiKit.DIM)
	UiKit.text(self, font, UiKit.t("%s of %s") % [ClubOffice.money(bill), ClubOffice.money(cap)],
		Vector2(RIGHT_X, 364), 18, UiKit.DOWN if bill > cap else UiKit.INK)

	var err := Workshop.fighter_legal(card, season.office.tier)
	if err != "" and card.display_name.strip_edges() != "":
		UiKit.text(self, font, err, Vector2(RIGHT_X, 404), 13, UiKit.DOWN)


func _draw_club() -> void:
	var kit: Color = IconBank.KIT_COLORS[kit_i]
	var mark: Color = IconBank.MARK_COLORS[mark_col_i]
	var short: String = club_short_edit.text if club_short_edit != null else season.club.short_name

	UiKit.text(self, font, UiKit.t("One club per save. The colors are free; the marks are not."),
		Vector2(STAT_X, 126), 14, UiKit.DIM)
	UiKit.text(self, font, UiKit.t("Name"), Vector2(STAT_X + 390, 176), 13, UiKit.EDGE)
	UiKit.text(self, font, UiKit.t("Short"), Vector2(STAT_X + 130, 226), 13, UiKit.EDGE)
	UiKit.text(self, font, UiKit.t("HOME TOWN"), Vector2(STAT_X, TOWN_Y - 12.0), 11, UiKit.DIM)
	UiKit.text(self, font, Cities.full_name(season.city()),
		Vector2(STAT_X + 96.0, TOWN_Y - 11.0), 14, UiKit.YOU)

	## The badge, at the size a badge is looked at, with the club's letters under
	## it — which is the pair that has to work, not either one alone.
	## 352 AND NOT 372. The badge is 108 pixels of decoration and the town row
	## needs the band under it; the badge is the thing that gives way, because it
	## is the only thing on this tab nobody has to read.
	UiKit.badge(self, Vector2(STAT_X + 92, 352), 50, kit, mark, icon_i)
	UiKit.text(self, font, short.to_upper(), Vector2(STAT_X + 168, 348), 26, UiKit.INK)
	UiKit.text(self, font, IconBank.icon_name(icon_i),
		Vector2(STAT_X + 168, 372), 14, UiKit.DIM)

	var bad := Workshop.identity_legal(
		club_name_edit.text if club_name_edit != null else "xxx", short, kit, mark)
	if bad != "":
		UiKit.text(self, font, bad, Vector2(STAT_X + 300.0, UiKit.bottom(28.0)), 13, UiKit.DOWN)

	_draw_bank(kit, mark)


## Every mark on this shelf, owned or not. A locked one is drawn in the club's
## own colors at half strength rather than as a padlock: the question the
## player is answering is "do I want to wear that", and he cannot answer it from
## a padlock.
func _draw_bank(kit: Color, mark: Color) -> void:
	var packs := IconBank.packs()
	var shelf := IconBank.in_pack(packs[pack_i % packs.size()])
	for i in shelf.size():
		var id: int = shelf[i]
		var at := _bank_slot(i)
		var have := shop.owns(id)
		if id == icon_i:
			## The one he is wearing, ringed. Not a tick in a corner — at this
			## size a tick is four pixels and the ring is unmissable.
			draw_rect(Rect2(at - Vector2(BANK_R + 5, BANK_R + 5),
				Vector2(BANK_R * 2 + 10, BANK_R * 2 + 10)), UiKit.YOU, false, 2.0)
		## Darkening BOTH colors made a locked mark unreadable — dark gray on
		## dark red — which defeats the point of drawing it at all. The kit goes
		## back, the mark stays bright and goes translucent instead, so the
		## shape still reads and it still says "not yours".
		var k: Color = kit if have else kit.darkened(0.42)
		var m: Color = mark if have else Color(mark, 0.45)
		UiKit.badge(self, at, BANK_R, k, m, id)
		var label := IconBank.icon_name(id) if have else "%d CC" % IconBank.cost(id)
		UiKit.text(self, font, label, at + Vector2(-BANK_R, BANK_R + 16), 12,
			UiKit.INK if have else UiKit.DIM)


func _bank_slot(i: int) -> Vector2:
	var col := i % BANK_COLS
	var row := int(i / BANK_COLS)
	return Vector2(BANK_X + BANK_R + float(col) * (BANK_R * 2.0 + BANK_GAP),
		198.0 + BANK_R + float(row) * (BANK_R * 2.0 + 34.0))
