class_name SeasonClubhouseTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




static func _office_row_y(v: SeasonScene, i: int) -> float:
	return SeasonScene.CONTENT_Y + 24.0 + float(i) * 86.0




static func _office_controls(v: SeasonScene) -> void:
	## UPGRADES ONLY (Pete, 29 Sep 2026, round 2). The rooms moved to the Club
	## menu in the header; what is left on this tab is everything the club buys,
	## and every button says what it buys: the number now, an arrow, the number
	## after, and the price.
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
		var b := UiKit.button(upgrade_word(v, kind) + UiKit.t(" · %d CC") % cost,
			Vector2(UPGRADE_X, v._office_row_y(i) + 6.0), Vector2(UPGRADE_W, 34), func():
				var err: String = o.raise_cap() if is_cap else (
					o.buy_travel_slot() if is_travel else o.upgrade(int(kind)))
				v.flash = UiKit.said(err) if err != "" else UiKit.t("Improved.")
				Session.autosave()
				v._rebuild(), "coin")
		## GREY WHEN THE PURSE CANNOT COVER IT (round 8: "a grey state when you
		## can't afford it").
		b.disabled = cost > o.credits
		v.ui.add_child(b)
	## THE ALERT IS A LINK (round 1 #9): a role going out untaught opens the
	## staff room, where the fix is.
	if not o.untaught().is_empty():
		v.ui.add_child(UiKit.button(UiKit.t("Open the staff room"),
			Vector2(SIDE_X + 16.0, SIDE_Y + 104.0), Vector2(side_w() - 32.0, 44), func():
				Session.autosave()
				UiKit.go("res://scenes/Staff.tscn"), "helm"))


## Where the upgrade buttons sit and how wide: wide enough for "Cap $1,250 →
## $1,438 · 10 CC", and the column beside them keeps the coaching summary.
const UPGRADE_X := SeasonScene.BAR_X + SeasonScene.BAR_W + 14.0
const UPGRADE_W := 262.0
const SIDE_X := UPGRADE_X + UPGRADE_W + 18.0
const SIDE_Y := SeasonScene.CONTENT_Y + 24.0


static func side_w() -> float:
	return UiKit.right_edge() - SIDE_X


## BEFORE → AFTER, for the button. What one more step of this buys, measured by
## taking the step on a copy of the number rather than written out a second time.
static func upgrade_word(v: SeasonScene, kind) -> String:
	var o := v.season.office
	if kind is String and kind == "cap":
		var now := o.cap()
		o.cap_level += 1
		var then := o.cap()
		o.cap_level -= 1
		return UiKit.t("Cap %s → %s") % [ClubOffice.money(now), ClubOffice.money(then)]
	if kind is String and kind == "travel":
		return UiKit.t("Places %d → %d") % [o.travel_slots, o.travel_slots + 1]
	var f := int(kind)
	var l := o.level(f)
	if f == ClubOffice.Facility.TRAINING:
		return UiKit.t("Winter points %d → %d") % [l * 3, (l + 1) * 3]
	if f == ClubOffice.Facility.INFIRMARY and floori((l + 1) / 2.0) > floori(l / 2.0):
		return UiKit.t("Knocks -%d → -%d") % [floori(l / 2.0), floori((l + 1) / 2.0)]
	return UiKit.t("Level %d → %d") % [l, l + 1]


## ---------------------------------------------------------------- the Club menu
## How many of the rooms are asking for you: job offers, and a federation bar.
static func club_calls(v: SeasonScene) -> int:
	var n := 0
	if Jobs.offers(v.season.coach, v.season.world).size() > 0:
		n += 1
	if not v.season.office.shortfalls().is_empty():
		n += 1
	return n


static func _club_menu_controls(v: SeasonScene) -> void:
	var card := v.CLUB_CARD
	var wanted: int = Jobs.offers(v.season.coach, v.season.world).size()
	var barred := not v.season.office.shortfalls().is_empty()
	## TWO COLUMNS WITH A MEANING (round 5: "a mixed bag"): the club's rooms on
	## the left, the plans and the game on the right, Close filling the grid.
	var rooms := [
		[UiKit.t("The staff"), "res://scenes/Staff.tscn", "helm"],
		[UiKit.t("Playbook"), "res://scenes/Chalkboard.tscn", "board"],
		[UiKit.t("Records"), "res://scenes/Records.tscn", "book"],
		[UiKit.t("Create & difficulty"), "res://scenes/Create.tscn", "anvil"],
		[UiKit.t("Your career") + ((UiKit.t("  ·  %d offer") if wanted == 1 else UiKit.t("  ·  %d offers")) % wanted if wanted > 0 else ""), "res://scenes/Coach.tscn", "ladder"],
		[UiKit.t("Settings"), "res://scenes/Settings.tscn", "cog"],
		[UiKit.t("The federation") + (UiKit.t("  ·  BARRED") if barred else ""), "res://scenes/Federation.tscn", "banner"],
	]
	var pad := 24.0
	var bw := (card.size.x - pad * 2.0 - 16.0) * 0.5
	for i in rooms.size():
		var r: Array = rooms[i]
		var at := Vector2(card.position.x + pad + float(i % 2) * (bw + 16.0),
			card.position.y + 72.0 + float(i / 2) * 58.0)
		## THE ODD ONE OUT SITS IN THE MIDDLE, not under a hole.
		if i == rooms.size() - 1 and rooms.size() % 2 == 1:
			at.x = card.get_center().x - bw * 0.5
		v.ui.add_child(UiKit.button(String(r[0]), at, Vector2(bw, 48), func(path = String(r[1])):
			v.club_menu_open = false
			Session.autosave()
			UiKit.go(path), String(r[2])))
	## QUIETER THAN THE ROOMS (round 6: Close looked like a seventh room).
	## AN X IN THE CORNER (round 9: a Close tile in the grid read as a room).
	var close_b := UiKit.button("", Vector2(card.end.x - 56.0, card.position.y + 12.0), Vector2(44, 44), func():
			v.club_menu_open = false
			v._rebuild(), "close")
	close_b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_b.tooltip_text = UiKit.t("Close")
	v.ui.add_child(close_b)


static func _draw_club_menu(v: SeasonScene) -> void:
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, v.CLUB_CARD)
	UiKit.mid(v, v.font, UiKit.t("THE CLUB"),
		Vector2(v.CLUB_CARD.position.x, v.CLUB_CARD.position.y + 38.0), 19, UiKit.INK,
		v.CLUB_CARD.size.x)




## Who is available — one list, in ClubOffice, read by both screens that sell
## captains. It used to be a second copy of the same hash here.
static func _offer(v: SeasonScene, slot: int) -> Dictionary:
	return v.season.staff_offer(slot)




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
			## THE STORE'S OWN PRICE, localized, once Play has answered.
			v.ui.add_child(UiKit.button(UiKit.t("%d  ·  %s") % [int(pk["credits"]), Store.price_word(String(pk["id"]))],
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
							else UiKit.t("Asked the store. Credits land when it answers.")
					v._rebuild()))
		## THE BUTTON A PLAYER WHOSE MONEY WENT MISSING WILL LOOK FOR. For a
		## consumable there is nothing to re-own — the credits were spent — so
		## this asks the store for anything it charged for and never delivered.
		v.ui.add_child(UiKit.button(UiKit.t("Restore a purchase"),
			Vector2(v.SHOP_CARD.position.x + 24.0, y), Vector2(240, 44), func():
				Store.resolve_pending()
				var got := Store.claim(v.season.office, Session.autosave)
				v.flash = (UiKit.t("%d credits.") % got) if got > 0 \
					else UiKit.t("Asked the store for anything outstanding.")
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
		Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 60.0), 14, UiKit.DIM,
		v.SHOP_CARD.size.x)
	UiKit.text(v, v.font, UiKit.t("In hand"), Vector2(v.SHOP_CARD.position.x + 24.0,
		v.SHOP_CARD.position.y + 104.0), 14, UiKit.DIM)
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
	## A PENDING PAYMENT (cash at a shop, a slow bank) is not lost and not
	## credited — say so, or the player buys the pack twice.
	if Store.available() and Store.pending > 0:
		UiKit.text(v, v.font, UiKit.t("A payment is pending. Credits land when it clears."),
			Vector2(v.SHOP_CARD.position.x + 24.0, v.SHOP_CARD.position.y + 128.0), 14, UiKit.DIM)




static func _draw_office(v: SeasonScene) -> void:
	var o := v.season.office
	## THE CREST GOES HERE AND ON THREE OTHER SCREENS. The clubhouse is the room
	## the player comes back to, the trophy cabinet, the bracket and the title —
	## four places, out of sixteen. Everywhere would be wallpaper.
	UiKit.ornament(v, UiKit.ORN_CREST, Rect2(SIDE_X, SIDE_Y, side_w(), 164.0), UiKit.FRAME, 24.0)
	## THE TWO CURRENCIES, ON THE PAGE THAT SPENDS BOTH (round 4: the cap is in
	## $ and its price in CC, and the key lived on another tab).
	UiKit.text_fit(v, v.font, UiKit.t("$ = weekly wages"), Vector2(SIDE_X + 4.0, SIDE_Y + 196.0), 14, UiKit.DIM, side_w())
	UiKit.text_fit(v, v.font, UiKit.t("CC = club money, spent here"), Vector2(SIDE_X + 4.0, SIDE_Y + 216.0), 14, UiKit.DIM, side_w())

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
		var label := UiKit.t(String(row["label"]))
		if key == "travel":
			## HOW MANY YOU CAN TAKE, and how many you actually have — two numbers
			## on one row, because a club with six places and five fit men has a
			## different problem from one with five places and nine fit men.
			var fit_men := 0
			for f2 in v.season.club.roster:
				if f2.fit():
					fit_men += 1
			UiKit.pair(v, v.font, label, UiKit.t("%d fit to fight") % fit_men,
				Vector2(SeasonScene.BAR_X, y), SeasonScene.BAR_X + SeasonScene.BAR_W, 13, 12, UiKit.DIM, UiKit.DIM)
			## ONE SEGMENT A SEAT, filled to the seats he has (round 5: "6 of 8"
			## beside a bar a third full read as a contradiction).
			UiKit.meter(v, Rect2(SeasonScene.BAR_X, y + 8, SeasonScene.BAR_W, SeasonScene.BAR_H),
				o.travel_slots, ClubOffice.TRAVEL_MAX, UiKit.YOU)
			UiKit.pair(v, v.font,
				## SAID AS SEATS AND A LIMIT (round 9: "6 of 8" beside "6 → 7" read as
				## two different counts).
				UiKit.t("%d seats") % o.travel_slots,
				"a line and no more" if o.travel_slots <= ClubOffice.TRAVEL_MIN
					## SHORT ENOUGH FOR THE 220px IT IS GIVEN. The first version said
					## "2 swaps in the corner" and the screenshot printed "2 swaps
					## in the corn" — a right-aligned field clips from the right,
					## so the half that gets cut is the half carrying the meaning.
					else ((UiKit.t("%d on the bench · %d swap")
						if mini(o.travel_slots - ClubOffice.TRAVEL_MIN, Tuning.SWAPS_PER_CORNER) == 1
						else UiKit.t("%d on the bench · %d swaps")) % [
						o.travel_slots - ClubOffice.TRAVEL_MIN,
						mini(o.travel_slots - ClubOffice.TRAVEL_MIN, Tuning.SWAPS_PER_CORNER)]),
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
				UiKit.t("%s of %s") % [ClubOffice.money(bill), ClubOffice.money(cap)],
				(UiKit.t("never raised") if o.cap_level <= 0 else UiKit.t("raised %d×") % o.cap_level),
				Vector2(SeasonScene.BAR_X, y + 54), SeasonScene.BAR_X + SeasonScene.BAR_W, 14, 12,
				UiKit.DOWN if bill > cap else UiKit.INK, UiKit.DIM)
			continue
		var f := int(row["kind"])
		## A facility at level nought has no effect, and saying "-0 events off a
		## knock" is worse than saying nothing: it reads like a broken number
		## rather than like a thing you have not built.
		var effect := UiKit.t("not built")
		match f:
			ClubOffice.Facility.TRAINING:
				if o.training_points() > 0:
					effect = UiKit.tn("%d point a winter", "%d points a winter",
						o.training_points()) % o.training_points()
			ClubOffice.Facility.INFIRMARY:
				if o.injury_relief() > 0:
					effect = UiKit.tn("-%d event off a knock", "-%d events off a knock",
						o.injury_relief()) % o.injury_relief()
				elif o.level(f) > 0:
					effect = UiKit.t("one more level to help")
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
		UiKit.text_fit(v, v.font, UiKit.t(String(ClubOffice.FACILITIES[f]["blurb"])),
			Vector2(SeasonScene.BAR_X, y + 54), 14, UiKit.DIM,
			SIDE_X - SeasonScene.BAR_X - 16.0)

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
	var y := SIDE_Y + 40.0
	var x := SIDE_X + 16.0
	var w := side_w() - 32.0
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
	UiKit.text(v, v.font, UiKit.t("COACHING"), Vector2(x, y), 14, UiKit.DIM)
	var bare := o.untaught()
	if bare.is_empty():
		var best := ""
		for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
			best = UiKit.t(String(Tuning.AI_SKILL[o.tier_for(role)]["name"]))
			break
		UiKit.text_fit(v, v.font, UiKit.t("Every role taught."), Vector2(x, y + 24), 14, UiKit.UP, w)
		UiKit.text_fit(v, v.font, UiKit.t("fights at %s level") % best.to_lower(), Vector2(x, y + 46), 14, UiKit.DIM, w)
	else:
		## ONE LINE, and the column is the reason. There are 132 pixels between
		## the foot of the nav list and the action row for two blocks, and a
		## second line of warning put its descenders through the Chalkboard
		## button. The staff room says all of this at length and is one tap away.
		var names := ""
		for r in bare:
			names += ("" if names == "" else UiKit.t(" and ")) + UiKit.t(String(Tuning.ROLE_NAME[r]))
		UiKit.text_fit(v, v.font, UiKit.t("%s untaught") % names, Vector2(x, y + 24), 14, UiKit.DOWN, w)
		UiKit.text_fit(v, v.font, UiKit.t("fights at %s level") % UiKit.t(String(Tuning.AI_SKILL[o.tier_for(bare[0])]["name"])).to_lower(), Vector2(x, y + 46), 14, UiKit.DIM, w)
