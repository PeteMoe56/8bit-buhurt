class_name SeasonClubhouseTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




static func _office_row_y(v: SeasonScene, i: int) -> float:
	return SeasonScene.CONTENT_Y + 24.0 + float(i) * 86.0




static func _office_controls(v: SeasonScene) -> void:
	## The staff room and the book, both of which outgrew a tab.
	## THE THREE SCREENS THAT OUTGREW A TAB, in the right column that the captain
	## cards used to fill. They were at y=70, 116 and 162 — straight through the
	## HONORS tab and then through the captain panel underneath it, which a
	## screenshot shows instantly and reasoning about coordinates never does.
	v.ui.add_child(UiKit.button(UiKit.t("The staff"), Vector2(SeasonScene.NAV_X + SeasonScene.NAV_PAD, SeasonScene.CONTENT_Y + 28 + SeasonScene.NAV_ROW * 0),
		Vector2(SeasonScene.NAV_W - SeasonScene.NAV_PAD * 2.0, SeasonScene.NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Staff.tscn"), "helm"))
	v.ui.add_child(UiKit.button(UiKit.t("Records"), Vector2(SeasonScene.NAV_X + SeasonScene.NAV_PAD, SeasonScene.CONTENT_Y + 28 + SeasonScene.NAV_ROW * 1),
		Vector2(SeasonScene.NAV_W - SeasonScene.NAV_PAD * 2.0, SeasonScene.NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Records.tscn"), "book"))
	## YOU. The only screen in the game that is not about the club, and it carries
	## a mark when somebody wants you — a job offer the player never notices is
	## the same as no job offer.
	var wanted: int = Jobs.offers(v.season.coach, v.season.world).size()
	v.ui.add_child(UiKit.button(UiKit.t("Your career%s") % (UiKit.t("  ·  %d") % wanted if wanted > 0 else ""),
		Vector2(SeasonScene.NAV_X + SeasonScene.NAV_PAD, SeasonScene.CONTENT_Y + 28 + SeasonScene.NAV_ROW * 2), Vector2(SeasonScene.NAV_W - SeasonScene.NAV_PAD * 2.0, SeasonScene.NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Coach.tscn"), "ladder"))
	## THE FEDERATION CARRIES ITS OWN WARNING. Being quietly not entered for the
	## cups is the most expensive thing that can happen to a club without a
	## message, and the player earns his place on the table where he can see it.
	var shorts := v.season.office.shortfalls()
	v.ui.add_child(UiKit.button(UiKit.t("The federation%s") % (UiKit.t("  ·  BARRED") if not shorts.is_empty() else ""),
		Vector2(SeasonScene.NAV_X + SeasonScene.NAV_PAD, SeasonScene.CONTENT_Y + 28 + SeasonScene.NAV_ROW * 3), Vector2(SeasonScene.NAV_W - SeasonScene.NAV_PAD * 2.0, SeasonScene.NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Federation.tscn"), "banner"))

	## THE COUNTER MOVED TO FINANCES, and so did the arena button on the action
	## row below. Pete, 15 Sep 2026: *"Clubhouse is too crowded."*
	##
	## He is right and the count says why: this tab carried four progress bars
	## with a price button each, five nav buttons, three action buttons, a purse
	## ledger and a coaching warning — sixteen controls and two readouts on one
	## screen. Both of the ones that left are about MONEY and there is now a page
	## about money; the arena is on it with the numbers that explain it, and the
	## counter belongs next to the balance it adds to rather than next to the
	## buildings.
	##
	## **A hub is defined by what it does not hold.** Everything still here is
	## either a thing this club owns or a room in it.

	var o := v.season.office
	for i in SeasonScene.OFFICE_ROWS.size():
		var row: Dictionary = SeasonScene.OFFICE_ROWS[i]
		var key: String = String(row["kind"]) if row["kind"] is String else ""
		var is_cap: bool = key == "cap"
		var is_travel: bool = key == "travel"
		var cost: int = o.cap_cost() if is_cap else (
			o.travel_cost() if is_travel else o.facility_cost(int(row["kind"])))
		if cost <= 0:
			continue
		var kind = row["kind"]
		v.ui.add_child(UiKit.button(UiKit.t("%d CC") % cost,
			Vector2(SeasonScene.BAR_X + SeasonScene.BAR_W + 14.0, v._office_row_y(i) + 10.0), Vector2(92, 34), func():
				var err: String = o.raise_cap() if is_cap else (
					o.buy_travel_slot() if is_travel else o.upgrade(int(kind)))
				v.flash = UiKit.said(err) if err != "" else UiKit.t("Improved.")
				Session.autosave()
				v._rebuild(), "coin"))

	## THE GROUND GETS ITS OWN SCREEN, because it is not a facility bar — it is a
	## picture of your club with your own badge painted on the floor of it, and a
	## diary. It sat in this list as "HOME GROUND" and was five levels of a
	## progress bar; that is exactly why it needed replacing.
	## THE ONLY LEVER ON MORALE. Everything else moves it at you — results, the
	## regime, a cut, a difficult man after a loss — and until this button there
	## was nothing the player could do about any of it on purpose.
	## AND IT SAYS WHEN IT CANNOT BE PRESSED. `can_boost()` folds the money and
	## the once-a-week throttle into one answer and had no caller — so the button
	## looked live every time and spent a tap to say no.
	## "A NIGHT OUT" IS GONE. Pete, 15 Sep 2026: *"A night out is pretty dumb,
	## take that out."*
	##
	## `Season.boost_morale()` and `ClubOffice.can_boost()` are left alone and
	## still tested — morale is real, it is pushed around by results and regimes
	## and cuts, and a club still wants somewhere to spend on it. What was dumb
	## was THIS: a button on the busiest row in the game whose whole offer was
	## "pay four credits, feel slightly better", competing for a thumb with the
	## chalkboard and the arena.
	##
	## The ones that are left are all places you GO. That is a coherent row.
	var third := (UiKit.span() - 16.0) / 3.0
	v.ui.add_child(UiKit.button(UiKit.t("Playbook"), Vector2(24, SeasonScene.action_y()),
		Vector2(third, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Chalkboard.tscn"), "board"))
	v.ui.add_child(UiKit.button(UiKit.t("Create"), Vector2(24 + third + 8.0, SeasonScene.action_y()),
		Vector2(third, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Create.tscn"), "anvil"))
	## AND THE ARENA IS ON THE FINANCES PAGE NOW — see the note above. Two
	## buttons across the row rather than three, which is `third` being a
	## deliberate width rather than a division: the row keeps its proportions and
	## the space where the arena was is space, which is the point of the exercise.




## Who is available — one list, in ClubOffice, read by both screens that sell
## captains. It used to be a second copy of the same hash here.
static func _offer(v: SeasonScene, slot: int) -> Dictionary:
	return ClubOffice.offer(v.season.seed_value, v.season.world.season, slot,
		v.season.office.staff_refreshes)




## ---------------------------------------------------------------- the shop
## COACHING CREDITS, BOUGHT WITH MONEY. The only thing this game sells.
##
## Direction §8, superseded by Pete on 12 Sep 2026: premium at $4.99 with IAP
## for credits. There is no unlock product — nothing is locked, because the
## price of entry already happened.
##
## `Store` decides whether there is a counter at all; this only draws it. On
## desktop and on any build without the billing plugin the packs are not drawn
## and the reason is, because **a shop that shows a button it cannot honor is a
## shop that takes a tap and does nothing.**
static func _shop_controls(v: SeasonScene) -> void:
	var y := v.SHOP_CARD.position.y + v.SHOP_CARD.size.y - 62.0
	if Store.available():
		var packs := Store.PRODUCTS
		var pad := 24.0
		var pw: float = (v.SHOP_CARD.size.x - pad * 2.0 - 16.0) / float(maxi(1, packs.size()))
		for i in packs.size():
			var pk: Dictionary = packs[i]
			v.ui.add_child(UiKit.button(UiKit.t("%d  ·  %s") % [int(pk["credits"]), String(pk["price"])],
				Vector2(v.SHOP_CARD.position.x + pad + float(i) * (pw + 8.0),
					v.SHOP_CARD.position.y + 150.0), Vector2(pw, 46),
				func(id = String(pk["id"])):
					var err := Store.buy(id)
					if err != "":
						v.flash = UiKit.said(err)
					else:
						## The grant is the store's callback, not this tap — a
						## shop that credits on the REQUEST credits a canceled
						## purchase. What lands now is whatever is already owed.
						var got := Store.claim(v.season.office, Session.autosave)
						v.flash = (UiKit.t("%d credits.") % got) if got > 0 \
							else "Asked the store. Credits land when it answers."
					v._rebuild()))
		## THE BUTTON A PLAYER WHOSE MONEY WENT MISSING WILL LOOK FOR. For a
		## consumable there is nothing to re-own — the credits were spent — so
		## this asks the store for anything it charged for and never delivered.
		v.ui.add_child(UiKit.button(UiKit.t("Restore a purchase"),
			Vector2(v.SHOP_CARD.position.x + 24.0, y), Vector2(240, 44), func():
				Store.resolve_pending()
				var got := Store.claim(v.season.office, Session.autosave)
				v.flash = (UiKit.t("%d credits.") % got) if got > 0 \
					else "Asked the store for anything outstanding."
				v._rebuild()))
	v.ui.add_child(UiKit.button(UiKit.t("Back"),
		Vector2(v.SHOP_CARD.end.x - 184.0, y), Vector2(160, 44), func():
			v.shop_open = false
			v._rebuild()))




static func _draw_shop(v: SeasonScene) -> void:
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, v.SHOP_CARD)
	UiKit.mid(v, v.font, UiKit.t("COACHING CREDITS"),
		Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 34.0), 19, UiKit.INK,
		v.SHOP_CARD.size.x)
	UiKit.mid(v, v.font, UiKit.t("Spent on levels, kit, the cap and the bus."),
		Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 60.0), 12, UiKit.DIM,
		v.SHOP_CARD.size.x)
	UiKit.text(v, v.font, UiKit.t("In hand"), Vector2(v.SHOP_CARD.position.x + 24.0,
		v.SHOP_CARD.position.y + 104.0), 13, UiKit.DIM)
	UiKit.right(v, v.font, UiKit.t("%d CC") % v.season.office.credits,
		Vector2(v.SHOP_CARD.end.x - 24.0, v.SHOP_CARD.position.y + 104.0), 15, UiKit.YOU, 200)
	if not Store.available():
		## The reason, in the middle, where the packs would have been.
		UiKit.mid(v, v.font, Store.closed_word(),
			Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 170.0), 14,
			UiKit.EDGE.lightened(0.5), v.SHOP_CARD.size.x)
	elif Store.owed > 0:
		UiKit.right(v, v.font, UiKit.t("%d waiting") % Store.owed,
			Vector2(v.SHOP_CARD.end.x - 24.0, v.SHOP_CARD.position.y + 128.0), 12,
			UiKit.YOU, 200)




static func _draw_office(v: SeasonScene) -> void:
	var o := v.season.office
	## THE CREST GOES HERE AND ON THREE OTHER SCREENS. The clubhouse is the room
	## the player comes back to, the trophy cabinet, the bracket and the title —
	## four places, out of sixteen. Everywhere would be wallpaper.
	UiKit.ornament(v, UiKit.ORN_CREST,
		Rect2(SeasonScene.NAV_X, SeasonScene.CONTENT_Y, SeasonScene.NAV_W, 28 + SeasonScene.NAV_ROW * float(SeasonScene.NAV_BUTTONS - 1)
			+ SeasonScene.NAV_BTN_H + 2.0), UiKit.FRAME, 24.0)

	## NO HINT BAR, AND THAT IS SETTLED. `UiKit.hints()` was deleted on
	## 15 Sep 2026 — see the note where it used to live in `ui.gd`. It had never
	## been drawn on any screen, and the reason was structural rather than
	## forgetful: this tab's action row already runs to the bottom, so a footer
	## needs 26 pixels RESERVED across every screen that wants one. That is a
	## layout pass, not a call, and the screens have just been re-anchored to a
	## canvas that changes shape.
	for i in SeasonScene.OFFICE_ROWS.size():
		var row: Dictionary = SeasonScene.OFFICE_ROWS[i]
		var y := v._office_row_y(i)
		var key: String = String(row["kind"]) if row["kind"] is String else ""
		var is_cap: bool = key == "cap"
		var label := String(row["label"])
		if key == "travel":
			## HOW MANY YOU CAN TAKE, and how many you actually have — two numbers
			## on one row, because a club with six places and five fit men has a
			## different problem from one with five places and nine fit men.
			var fit_men := 0
			for f2 in v.season.club.roster:
				if f2.fit():
					fit_men += 1
			UiKit.pair(v, v.font, label, UiKit.t("%d fit on books") % fit_men,
				Vector2(SeasonScene.BAR_X, y), SeasonScene.BAR_X + SeasonScene.BAR_W, 13, 12, UiKit.DIM, UiKit.DIM)
			UiKit.meter(v, Rect2(SeasonScene.BAR_X, y + 8, SeasonScene.BAR_W, SeasonScene.BAR_H),
				o.travel_slots - ClubOffice.TRAVEL_MIN,
				ClubOffice.TRAVEL_MAX - ClubOffice.TRAVEL_MIN, UiKit.YOU)
			UiKit.pair(v, v.font,
				"%d of %d" % [o.travel_slots, ClubOffice.TRAVEL_MAX],
				"a line and no more" if o.travel_slots <= ClubOffice.TRAVEL_MIN
					## SHORT ENOUGH FOR THE 220px IT IS GIVEN. The first version said
					## "2 swaps in the corner" and the screenshot printed "2 swaps
					## in the corn" — a right-aligned field clips from the right,
					## so the half that gets cut is the half carrying the meaning.
					else ("%d on the bench · %d swap%s" % [
						o.travel_slots - ClubOffice.TRAVEL_MIN,
						mini(o.travel_slots - ClubOffice.TRAVEL_MIN, Tuning.SWAPS_PER_CORNER),
						"" if mini(o.travel_slots - ClubOffice.TRAVEL_MIN, Tuning.SWAPS_PER_CORNER) == 1 else "s"]),
				Vector2(SeasonScene.BAR_X, y + 54), SeasonScene.BAR_X + SeasonScene.BAR_W, 14, 12, UiKit.INK,
				UiKit.DOWN if o.travel_slots <= ClubOffice.TRAVEL_MIN else UiKit.DIM)
			continue
		if is_cap:
			UiKit.pair(v, v.font, label, UiKit.t("%s rules") % v.season.tier_name(),
				Vector2(SeasonScene.BAR_X, y), SeasonScene.BAR_X + SeasonScene.BAR_W, 13, 12, UiKit.DIM, UiKit.DIM)
			var bill := ClubOffice.wage_bill(v.season.club)
			var cap := o.cap()
			UiKit.bar(v, Rect2(SeasonScene.BAR_X, y + 8, SeasonScene.BAR_W, SeasonScene.BAR_H),
				float(bill) / float(maxi(1, cap)),
				UiKit.DOWN if bill > cap else UiKit.YOU)
			UiKit.pair(v, v.font,
				"%s of %s" % [ClubOffice.money(bill), ClubOffice.money(cap)],
				"%d raises · next %d CC" % [o.cap_level, o.cap_cost()],
				Vector2(SeasonScene.BAR_X, y + 54), SeasonScene.BAR_X + SeasonScene.BAR_W, 14, 12,
				UiKit.DOWN if bill > cap else UiKit.INK, UiKit.DIM)
			continue
		var f := int(row["kind"])
		## A facility at level nought has no effect, and saying "-0 events off a
		## knock" is worse than saying nothing: it reads like a broken number
		## rather than like a thing you have not built.
		var effect := "not built"
		match f:
			ClubOffice.Facility.TRAINING:
				if o.training_points() > 0:
					effect = "%d points a winter" % o.training_points()
			ClubOffice.Facility.INFIRMARY:
				if o.injury_relief() > 0:
					effect = "-%d events off a knock" % o.injury_relief()
				elif o.level(f) > 0:
					effect = "one more level to help"
		## On the LABEL line, not under the bar. Under the bar it landed in the
		## same place as the blurb and the two strings printed through each other
		## — which a screenshot shows instantly and nothing else would.
		UiKit.pair(v, v.font, label, effect, Vector2(SeasonScene.BAR_X, y),
			SeasonScene.BAR_X + SeasonScene.BAR_W, 13, 13, UiKit.DIM, UiKit.INK)
		UiKit.meter(v, Rect2(SeasonScene.BAR_X, y + 8, SeasonScene.BAR_W, SeasonScene.BAR_H), o.level(f), ClubOffice.FACILITY_MAX,
			UiKit.UP if o.level(f) > 0 else UiKit.EDGE)
		## CLIPPED TO THE LEFT COLUMN. "Fighters improve over the winter. Your
		## captains decide who." is 462 pixels at this size and the column ends
		## at NAV_X — so it printed through "ON THE LIST" in the right column,
		## which is text over text and therefore invisible to every check in the
		## suite. A screenshot saw it.
		UiKit.text(v, v.font, UiKit.fit_px(v.font,
			String(ClubOffice.FACILITIES[f]["blurb"]), 13, SeasonScene.NAV_X - SeasonScene.BAR_X - 16.0),
			Vector2(SeasonScene.BAR_X, y + 54), 13, UiKit.DIM)

	# ------------------------------------------------------------ the captains
	## THE CAPTAIN CARDS USED TO BE DRAWN HERE TOO, in full, with their own hire
	## and release buttons — a second copy of the Staff room on the tab next to
	## the link to it. Two screens showing the same two men, and two hire paths
	## that had to be kept in step by hand (they were not: only one of them fired
	## a new captain's arrival trait until this session).
	##
	## What belongs on this tab is the SUMMARY — which roles are going out
	## untaught — because that is the thing that sends you to the staff room. The
	## detail belongs where you act on it. Removing the duplicate is also what
	## made room for the three navigation buttons, which had been sitting on top
	## of the tab row and the captain panels.

	# --------------------------------------------------- what it means on the list
	## The whole justification for the staff screen, spelled out. A role nobody
	## covers goes out Green, which is a measured 63% loss rate — the player
	## should read that here, not work it out from a losing streak.
	## BELOW THE CREST, not through it. The ornament's bottom bracket reaches
	## `CONTENT_Y + 242` and this label sat at 250 — eight pixels of clearance
	## for a 24-pixel corner piece, so the bracket printed through "ON".
	## MEASURED OFF THE NAV LIST rather than written down, so a fifth button moves
	## this with it instead of printing through it.
	##
	## The gap is back to 26 now that the purse ledger has gone to FINANCES: it
	## was cut to 12 because two blocks were fighting for 112 pixels, and with one
	## block left there is room to breathe — which is the whole of Pete's
	## *"Clubhouse is too crowded"* in one number.
	var y := SeasonScene.CONTENT_Y + 28.0 + SeasonScene.NAV_ROW * float(SeasonScene.NAV_BUTTONS - 1) + SeasonScene.NAV_BTN_H + 26.0
	## THE PURSE LEDGER WENT TO THE FINANCES PAGE, and it was already broken here.
	##
	## It was three lines of "what came in" under the nav list — Pete's item 25 of
	## the 15 Sep playtest, *"No income weekly ever"* — and it was, in its own
	## comment, *"the cheapest possible answer"*. Two things have changed since.
	##
	## First, there is a real one now. FINANCES shows every heading of income and
	## every heading of spending, this year against last, which is what item 25
	## actually wanted; and **a summary that repeats the screen it points at is two
	## screens disagreeing about which is the authority.**
	##
	## Second, and worse: the screenshot from 16 Sep shows "WHAT CAME IN / Nothing
	## yet. The gate pays after your first event." drawn UNDERNEATH the five nav
	## buttons, in grey, invisible. The nav list is Controls on the UI layer and
	## this block is `_draw()`; the layer always wins. **A scrim cannot cover a
	## Button — and it goes the other way too, and the other way is worse**,
	## because nothing errors and nobody can see what is missing.
	##
	## So the block is gone rather than moved down, and the space it used to take
	## is the answer to *"Clubhouse is too crowded."*

	## ---------------------------------------------------- ON THE LIST
	## ONE LINE, NOT A TABLE OF THREE.
	##
	## This drew Rail / Flanker / Center each with its coaching tier stacked
	## under it, plus two lines of warning — ninety pixels of a column that had a
	## hundred and thirty for two blocks. Adding the purse ledger above it pushed
	## the tiers straight through the action row.
	##
	## The table was never the point. Everything it said ended in *"go to the
	## staff room"*, and the staff room shows the same three roles in more detail
	## on a screen that is one tap away and is not full. **A summary that repeats
	## the screen it points at is two screens disagreeing about which of them is
	## the authority.** So: the headline, and the sentence that says what to do.
	UiKit.text(v, v.font, UiKit.t("ON THE LIST"), Vector2(SeasonScene.NAV_X, y), 13, UiKit.DIM)
	var bare := o.untaught()
	if bare.is_empty():
		var best := ""
		for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
			best = String(Tuning.AI_SKILL[o.tier_for(role)]["name"])
			break
		UiKit.pair(v, v.font, UiKit.t("Every role taught."), UiKit.t("going out %s") % best.to_lower(),
			Vector2(SeasonScene.NAV_X, y + 20), UiKit.right_edge(), 13, 13, UiKit.UP, UiKit.DIM)
	else:
		## ONE LINE, and the column is the reason. There are 132 pixels between
		## the foot of the nav list and the action row for two blocks, and a
		## second line of warning put its descenders through the Chalkboard
		## button. The staff room says all of this at length and is one tap away.
		var names := ""
		for r in bare:
			names += ("" if names == "" else " and ") + String(Tuning.ROLE_NAME[r])
		UiKit.text(v, v.font, UiKit.fit_px(v.font,
			UiKit.t("%s untaught — see the staff room.") % names,
			13, UiKit.right_edge() - SeasonScene.NAV_X), Vector2(SeasonScene.NAV_X, y + 20), 13, UiKit.DOWN)
