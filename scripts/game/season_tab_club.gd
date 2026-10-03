class_name SeasonClubTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




# ------------------------------------------------------------------ controls
## WHO LEFT. A squad that quietly loses two men over a summer and signs two
## strangers is the single most alarming thing that can happen without a message,
## and the player finds out three screens later when a name he does not know is
## standing at Rail. Retirements are named; the walk-ons are counted, because the
## point about them is that they are interchangeable.
static func _winter_word(v: SeasonScene) -> String:
	var w: Dictionary = v.season.last_winter
	if w.is_empty():
		return ""
	var gone: Array = w.get("retired", [])
	var walked: Array = w.get("walked", [])
	var took: Array = w.get("signed", [])
	if gone.is_empty() and walked.is_empty():
		return ""
	## EVERY PIECE THROUGH THE STRING TABLE (3 Oct 2026): these were spliced into
	## a translated season message as English, and "1 walk-ons" was hand-rolled.
	var s := ""
	if not gone.is_empty():
		var g0 := String(gone[0]).split(" (")[0]
		s += "  " + (UiKit.t("%s retired.") % g0 if gone.size() == 1
			else UiKit.t("%s and %d more retired.") % [g0, gone.size() - 1])
	## A man who WALKED is the more alarming of the two and gets said separately,
	## because the player could have stopped it and a retirement he could not.
	if not walked.is_empty():
		var w0 := String(walked[0]).split(" (")[0]
		s += "  " + (UiKit.t("%s left on a free.") % w0 if walked.size() == 1
			else UiKit.t("%s and %d more left on a free.") % [w0, walked.size() - 1])
	if not took.is_empty():
		s += "  " + UiKit.tn("%d walk-on signed.", "%d walk-ons signed.", took.size()) % took.size()
	return s




## THE CLUB CAME APART, said first and said loudly.
##
## Half a squad walking out to found a rival in your own division is the biggest
## thing that can happen to a save, and it happens in the summer alongside three
## other reports. A player who reads "2 walk-ons signed" and finds out in October
## that the club across town is full of his own men has been told nothing.
static func _split_word(v: SeasonScene) -> String:
	var sp: Dictionary = v.season.last_split
	if sp.is_empty():
		return ""
	var took: Array = sp.get("took", [])
	return UiKit.tn("THE CLUB SPLIT. %d man walked out to found %s, who are in your division this season.",
		"THE CLUB SPLIT. %d men walked out to found %s, who are in your division this season.",
		took.size()) % [took.size(), String(sp.get("club", UiKit.t("a rival")))]




## The summer's bills, said on the same line as the summer's result — because a
## building that fell down and was never mentioned is a bug the player will
## report as one, and because the bill and the finish are the two halves of the
## same sentence: this is the year you had and this is what it cost to keep what
## you own.
static func _upkeep_word(v: SeasonScene) -> String:
	var u: Dictionary = v.season.last_upkeep
	if u.is_empty():
		return ""
	var lost: Array = u.get("lost", [])
	if not lost.is_empty():
		return "  " + UiKit.t("Could not keep the %s — it fell a level.") % String(lost[0]).to_lower()
	var billed: int = int(u.get("billed", 0))
	return "" if billed <= 0 else "  " + UiKit.t("Upkeep %d CC.") % billed




static func _club_controls(v: SeasonScene) -> void:
	## A CLUB'S CARD, OPEN: it owns the tab until it is closed — unless a card
	## that has to be answered has come up, which outranks it.
	if ["dilemma", "sendoff"].has(v.season.blocked_by()):
		v.team_card = -1
	if v.team_card >= 0:
		var cr := _card_rect()
		v.ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Close"),
			Vector2(cr.end.x - 174.0, cr.end.y - 60.0), Vector2(150, 44), func():
				v.team_card = -1
				v._rebuild(), "close")))
		return
	## EVERY ROW OF THE TABLE OPENS THAT CLUB'S CARD (Pete, 1 Oct 2026).
	## ONE PRESS AREA OVER THE WHOLE TABLE, and the row is read from where the
	## finger landed: sixteen rows at 22 cannot each be a 56-pixel button.
	if not ["dilemma", "sendoff"].has(v.season.blocked_by()):
		var rows := v.season.table()
		var top := SeasonScene.TABLE_Y + 7.0
		var hit := UiKit.button("", Vector2(SeasonScene.table_x(), top),
			Vector2(UiKit.screen().x - SeasonScene.table_x() - 24.0, float(rows.size()) * SeasonScene.ROW_H), func():
				var i := int(floor((v.get_local_mouse_position().y - top) / SeasonScene.ROW_H))
				if i >= 0 and i < rows.size():
					v.team_card = int(rows[i]["club"])
					v._rebuild())
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		v.ui.add_child(hit)
	## THE DRAW, WHENEVER THERE IS ONE TO SEE — not only while a tie of yours is
	## unplayed. It used to be built inside the cup-tie branch, so being knocked
	## out took the bracket away at exactly the moment it got interesting, and
	## the champion line on that screen was unreachable code.
	##
	## MOVED TWICE NOW, AND THE SECOND MOVE WAS THE MISTAKE. It began in the
	## action row, where at National the table runs to sixteen clubs and row 16
	## sits at y=477-497 — so it hid the rank and name of a club in a relegation
	## place. It was moved to y=70 on the right, which is **the tab strip**, and
	## it covered the right half of the HONORS tab on every screen that had a
	## cup to look at.
	##
	## THE THIRD MOVE, AND THE SECOND COMMENT THAT WAS WRONG. The note above used
	## to end *"the left column under the fixture card is the one region on this
	## tab that belongs to nothing"*, and put the button at y=276. `_last_event()`
	## draws its line at `CONTENT_Y + 152` — which is 284. So the region belonged
	## to something, the button covered *"Last: beat Milwaukee Free Company 2-0
	## (+6) · simmed"* on every screen with a live cup, and the screenshot of the
	## fixture panel on 16 Sep caught it with half the sentence sticking out.
	##
	## **A comment that describes a region as empty is a comment, not a check.**
	## The genuinely free band is under the schedule and above the action row:
	## five rows of fixtures end at 418 and the action row starts at 476.
	## THE CALENDAR (30 Sep 2026): the whole year as weeks. Not over a full-panel
	## card (a dilemma, the send-off), whose words run down to this band.
	var card_up: bool = ["dilemma", "sendoff"].has(v.season.blocked_by())
	if not card_up:
		v.ui.add_child(UiKit.button(UiKit.t("Calendar"), Vector2(24, SeasonScene.action_y() - 52.0),
			Vector2(200, 44), func():
				Session.autosave()
				UiKit.go("res://scenes/Calendar.tscn"), "clock"))
	if v.season.viewable_cup() != null and not card_up:
		v.ui.add_child(UiKit.button(UiKit.t("Cup bracket"), Vector2(236, SeasonScene.action_y() - 52.0),
			Vector2(200, 44), func():
				Session.viewing_cup = v.season.viewable_cup()
				Session.autosave()
				UiKit.go("res://scenes/Bracket.tscn"), "trophy"))

	## A CUP TIE OUTRANKS EVERYTHING. It is put in front of the player before the
	## league fixture and before the end-of-season button, because a bracket
	## waiting on a result is the only thing on this screen that other clubs are
	## standing around for.
	## THE BID FIRST, before the cup and before the fixture. It is a start-of-year
	## decision and the season does not begin until it is answered.
	## ONE QUEUE, ASKED ONCE. `blocked_by()` is the season's own answer to "what
	## has to be dealt with before you can fight", and this screen used to
	## re-implement its order — bid, dilemma, cup here; bid, cup, dilemma there;
	## dilemma first in the drawing. Three orderings of one rule, and the only
	## thing keeping them agreeing was that nobody had hit the case where they
	## differ. The season is asked now.
	##
	## AND NOW IT REALLY IS (29 Sep 2026). The comment above said so while the
	## code below still asked each question itself — promotion FIRST, where
	## `blocked_by()` puts it LAST — so a season that ended with a cup tie still
	## to fight showed the promotion choice while the season said "cup". Every
	## branch is keyed on the one answer now.
	var block := v.season.blocked_by()
	if block == "promotion":
		var pt: Dictionary = v.season.promotion_terms()
		## SHORT LABELS. "Take the State League" and "Stay in the Backyard Circuit
		## · save 8 CC" are 218 and 280 pixels of text in 240- and 300-pixel
		## buttons, and both spilled over their own edges on the first render. The
		## division names are on the card six lines above; the buttons only have to
		## say which way.
		v.ui.add_child(UiKit.button(UiKit.t("Take it"),
			Vector2(24, SeasonScene.action_y()), Vector2(200, 46), func():
				var perr: String = v.season.answer_promotion(true)
				v.flash = UiKit.said(perr) if perr != "" else UiKit.t("Up to the %s.") % String(pt["to"])
				Session.autosave()
				v._rebuild(), "up"))
		v.ui.add_child(UiKit.button(UiKit.t("Stay down  ·  save %d CC")
				% (int(pt["dues_up"]) - int(pt["dues_now"])),
			Vector2(240, SeasonScene.action_y()), Vector2(260, 46), func():
				if not UiKit.confirm("stay_down"):
					v.flash = UiKit.t("Tap again to turn promotion down for this year.")
					v._rebuild()
					return
				v.season.answer_promotion(false)
				v.flash = UiKit.t("Staying in the %s another year.") % String(pt["from"])
				Session.autosave()
				v._rebuild(), "shield"))
		## BUILD NOW, AT THE GATE (Pete, 1 Oct 2026). The ground the division above
		## needs, every missing level at once, and then the place is taken — the
		## one tap a club that has just won it wants. Gold, because it is the step.
		var gap: Dictionary = v.season.ground_gap()
		if not gap.is_empty():
			v.ui.add_child(UiKit.primary(UiKit.button(UiKit.with_upkeep(UiKit.t("Build now · %d CC") % int(gap["total"]),
					v.season.office.arena_upkeep_at(Arena.level_for_tier(v.season.world.player_tier() + 1))),
				Vector2(UiKit.right_edge(SeasonScene.NEXT_W + 24.0), SeasonScene.action_y()),
				Vector2(SeasonScene.NEXT_W, 46), func():
					var err: String = v.season.build_for_promotion()
					if err != "":
						v.flash = UiKit.said(err)
					else:
						err = v.season.answer_promotion(true)
						v.flash = UiKit.said(err) if err != "" else UiKit.t("%s built. Up to the %s.") % [
							UiKit.t(String(gap["need"])), String(pt["to"])]
					Session.autosave()
					v._rebuild(), "hall")))
		return

	if block == "bid":
		## THE BID IS DECIDED IN ONE PLACE, THE ARENA (Pete, 29 Sep 2026), where the
		## dates, the budgets and what each would earn are in front of you. The
		## Club tab sends you there; taking or passing happens there.
		v.ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Tournament bid"),
			Vector2(UiKit.right_edge(SeasonScene.NEXT_W + 24.0), SeasonScene.action_y()),
			Vector2(SeasonScene.NEXT_W, 46), func():
				Session.autosave()
				UiKit.go("res://scenes/Arena.tscn"), "gate")))
		## AND THE CARD HAS A BUTTON THAT LOOKS LIKE ONE (1 Oct novice report:
		## the gold "Choose at the Arena >" was read as a caption and nobody
		## tapped it). It replaces the flat hit box that lay over the whole card
		## (blind review round 3), which would sit on top of it.
		v.ui.add_child(bid_button(v))
		return
	if block == "cup":
		## THE FIGHT IS WHERE EVERY OTHER TAB'S NEXT STEP IS: bottom right,
		## gold (round 4: the Club tab put its call to action bottom-left).
		v.ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Fight the cup bout"),
			Vector2(UiKit.right_edge(SeasonScene.NEXT_W + 24.0), SeasonScene.action_y()),
			Vector2(SeasonScene.NEXT_W, 46), v._fight_cup, "sword")))
		## THE DRAW, next to the tie. Carried open since section 22: the screen
		## could say who you were fighting and never who else was left, which is
		## the one thing a cup has that a league does not.
		## SIM IT BESIDE THE FIGHT, the quieter of the two (round 6).
		v.ui.add_child(UiKit.button(UiKit.t("Sim it"), Vector2(UiKit.right_edge(SeasonScene.NEXT_W + 24.0) - 150.0, SeasonScene.action_y()), Vector2(140, 46), func():
			## Two taps, like the league's sim: a cup tie simmed is a cup tie gone.
			if not UiKit.confirm("sim_cup"):
				v.flash = UiKit.t("Tap Sim it again to hand the cup bout to the AI.")
				v._rebuild()
				return
			var c := v.season.pending_cup()
			var nm := c.cup_name
			var rnd := c.round_label()
			v.season.sim_cup_tie()
			Session.autosave()
			v.flash = UiKit.t("%s %s simulated.") % [nm, rnd.to_lower()]
			v._rebuild()))
		return
	## THE CARD ON THE TABLE, AFTER THE CUP. It used to be drawn before it, so
	## with a bracket waiting AND a card on the table the two screens disagreed
	## about which one you were being asked to deal with — `blocked_by()` said
	## "cup" and the buttons offered the dilemma. One queue, one order, and
	## `test_season.gd` now asserts the screen and the season agree.
	##
	## It is still the smallest of the three and the one the player is most
	## smallest of the three things that can block a matchday and the one the
	## player is most likely to want to read rather than clear, so it does not go
	## first — but it does go before the fight, because a dilemma you can walk
	## past is a notification.
	if block == "sendoff":
		var so: Dictionary = v.season.send_off_card()
		v.ui.add_child(UiKit.primary(UiKit.button(String(so["button"]),
			Vector2(UiKit.right_edge(300.0 + 24.0), SeasonScene.action_y()), Vector2(300, 46), func():
				v.flash = v.season.answer_send_off()
				Session.autosave()
				v._rebuild(), "trophy")))
		return
	if block == "dilemma":
		var card := v.season.dilemma_card()
		var opts: Array = card.get("options", [])
		var w: float = (UiKit.span(32.0) - float(maxi(0, opts.size() - 1)) * 12.0) / float(maxi(1, opts.size()))
		for i in opts.size():
			var o: Dictionary = opts[i]
			v.ui.add_child(UiKit.button(String(o["label"]),
				Vector2(24 + float(i) * (w + 12.0), SeasonScene.action_y()), Vector2(w, 46), func():
					v.flash = v.season.answer_dilemma(i)
					Session.autosave()
					v._rebuild()))
		return
	if v.season.ready_to_roll():
		v.ui.add_child(UiKit.button(UiKit.t("End the season"), Vector2(24, SeasonScene.action_y()),
			Vector2(424, 46), func():
				var was := v.season.position()
				var tier := v.season.tier_name()
				var tier_before := v.season.tier_name()
				v.season.roll_over()
				Session.autosave()
				## THE PALETTE FLASH, and only here. Two frames of white on a
				## promotion — the cheapest, most 8-bit trick there is, and the
				## whole reason it works is that it is RARE. A flash the player
				## sees twice an hour is an event; one he sees twice a minute is
				## a fault in the screen. A season that ended where it started
				## gets the ordinary confirm and nothing else.
				if v.season.tier_name() != tier_before:
					Juice.fanfare()
				## The split goes FIRST when there is one, because a squad walking
				## out is not a footnote to where you finished.
				var broke := v._split_word()
				v.flash = broke if broke != "" else UiKit.t("%s, finished %s. Now in the %s.%s%s") % [
					tier, UiKit.ordinal(was), v.season.tier_name(),
					v._winter_word(), v._upkeep_word()]
				v._rebuild()))
		return
	## THE TWO DROPDOWNS, next to the button that uses them. Pete asked for the
	## formation to be selectable "via drop down"; on a screen this size a cycle
	## button is the same thing with one fewer tap and no list to mis-hit, and
	## it shows what is selected without being opened.
	## AND IT IS A FORMATION HERE TOO. Pete renamed the playbook's column and the
	## word is the word: a game that calls the same thing a shape on one screen
	## and a formation on the next is asking the player to hold two names for it.
	## The clip drops to 10 so the label is no longer than "Shape:" plus 14 was —
	## `test_layout.gd` measures the outcome either way.
	## ---------------------------------------------- the fixture's action row
	## THE FORMATION AND PLAY SLOTS ARE GONE FROM HERE — Pete, item 20 of the
	## 15 Sep playtest: *"We can find something else to put in the formation and
	## play slot. That should be a pop up for 'Sim it' and Fight should eventually
	## go to the pre-fight screen anyway."*
	##
	## He is describing a redundancy. `Fight it` leads to the walk-out and then to
	## BEFORE THE CHARGE, which is a screen whose entire job is choosing a shape
	## and a play with the men and their condition in front of you. Choosing them
	## HERE, on a card that shows a league table, is the same decision taken
	## earlier with less information — and then taken again ten seconds later.
	##
	## **A decision offered twice is a decision the player makes once and then
	## has to remember he already made.** The pre-fight screen keeps it, because
	## that is where the evidence is.
	## FIGHT IT IS NOW THE HUB'S "NEXT EVENT", bottom right and gold, on every
	## tab (SeasonScene._next_controls) — one way forward, in one place.
	## AND SIM ASKS FIRST. It is the one button on this screen that spends a
	## fixture and cannot be undone — the result is written, the week ticks, kit
	## wears — and it sat one accidental thumb away from the button beside it.
	## NOTHING TO SIM ON A SATURDAY WITH NO FIXTURE.
	if v.season.opponent_id() < 0:
		return
	v.ui.add_child(UiKit.button(UiKit.t("Sim it"), Vector2(UiKit.right_edge(SeasonScene.NEXT_W + 24.0 + 204.0 + 12.0) - v.step_shift(),
		SeasonScene.action_y()), Vector2(204, 46),
		func():
			v.sim_asking = true
			v._rebuild(), "clock"))




## THE BID CARD'S WAY IN: a framed button in the card's bottom-right corner.
static func bid_button(_v: SeasonScene) -> Button:
	var w := minf(240.0, SeasonScene.fixture_w() * 0.55)
	var card := Rect2(24, SeasonScene.CONTENT_Y + 20.0, SeasonScene.fixture_w(), SeasonScene.FIXTURE_H)
	var b := UiKit.button(UiKit.t("Choose at the Arena"),
		Vector2(card.end.x - 12.0 - w, card.end.y - 8.0 - 32.0), Vector2(w, 32), func():
			Session.autosave()
			UiKit.go("res://scenes/Arena.tscn"), "gate")
	b.set_meta("bid_card", true)
	return b


static func _draw_club(v: SeasonScene) -> void:
	## THE CARD TAKES THE WHOLE SCREEN when there is one, rather than sitting in
	## a corner of the fixture page. It is two hundred words of somebody's week
	## and three answers with real prices on them; squeezing it into a panel
	## beside the league table would say it is trivia, and then the player would
	## treat it as trivia.
	##
	## IT ASKS THE SEASON WHICH SCREEN THIS IS, rather than asking whether a card
	## exists. Those are not the same question and on 14 Sep 2026 they gave
	## different answers: the buttons were moved onto `blocked_by()` in section
	## 22 and the DRAWING was left reading `dilemma.is_empty()`, so a season that
	## opened with a bid AND a card on the table printed the card, its three
	## answers and their prices — over the tournament bid's two buttons. The
	## first shot of the priced options caught it, which is the whole reason to
	## take one: *a branch has two arms and a screenshot has one frame*, and this
	## frame was the arm nobody had looked at.
	if v.season.blocked_by() == "dilemma":
		v._draw_dilemma()
		return
	if v.season.blocked_by() == "sendoff":
		_draw_send_off(v)
		return
	v._fixture()
	v._last_event()
	v._schedule()
	v._table()
	v._tape_draw_ground()
	if v.team_card >= 0:
		v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.55))
		TeamCard.draw(v, v.font, _card_rect(), v.season, v.team_card)


static func _card_rect() -> Rect2:
	var sz := Vector2(minf(560.0, UiKit.screen().x - 48.0), 236.0)
	return Rect2(Vector2((UiKit.screen().x - sz.x) * 0.5, 120.0), sz)




## ------------------------------------------------------------- what is left
## THE SPACE THE FORMATION AND PLAY BUTTONS LEFT. Pete, item 20: *"Maybe the
## schedule, and a couple other things."*
##
## The card said what is happening this week and the table said where everybody
## stands, and nothing anywhere said what is COMING — which is the one thing a
## manager plans against. Five rows, home and away marked, the current one lit.
static func _schedule(v: SeasonScene) -> void:
	## FOUR, NOT FIVE: the fifth row sat under the Calendar button.
	var rest: Array = v.season.world.remaining_fixtures(4)
	if rest.is_empty():
		return
	## UNDER THE LAST RESULT, which sits at `CONTENT_Y + 152`.
	var y := SeasonScene.CONTENT_Y + 186.0
	## EVERY SATURDAY, NOT ONLY THE LEAGUE'S (30 Sep 2026, playtest 2 #14: "the
	## standings are confusing when you're fighting cups"). A cup round is on the
	## list as a cup round, in the cup's color, so the table never moves — or
	## fails to — without the list saying why.
	UiKit.text(v, v.font, UiKit.t("COMING UP"), Vector2(24, y), 14, UiKit.DIM)
	## THE WEEKDAYS, SAID (Pete, 2 Oct 2026): every week has them before its
	## event, and the work done in them is open whatever the weekend holds.
	var cw := v.font.get_string_size(UiKit.t("COMING UP"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	UiKit.text_fit(v, v.font, UiKit.t("weekdays now: repair, train, sign"), Vector2(24 + cw + 14.0, y), 13,
		UiKit.YOU, SeasonScene.fixture_w() - cw - 14.0)
	y += 24.0
	var days := v.season.world.events_this_season()
	for i in rest.size():
		var r: Dictionary = rest[i]
		var kind := int(r["kind"])
		var col := UiKit.INK if i == 0 else UiKit.DIM
		## THE WEEK'S COLOR, as a block in the margin: blue league, gold cup,
		## green your show, purple playoff and Worlds — the calendar's key.
		v.draw_rect(Rect2(24, y - 11, 8, 12), Calendar.color(kind))
		## THE WEEK AND WHO, NOTHING ELSE (Pete, 1 Oct: "Just Home/Away, no need
		## for naming their arena or prize for the Coming up").
		if kind != Calendar.Kind.LEAGUE:
			var w: Dictionary = v.season.world.calendar[int(r["week"]) - 1]
			UiKit.text_fit(v, v.font, Calendar.label(w, days, _own_name(v)), Vector2(40, y), 13,
				UiKit.YOU if i == 0 else Calendar.color(kind).lightened(0.35), SeasonScene.fixture_w() - 20.0)
			y += 20.0
			continue
		var opp := int(r["opponent"])
		var home: bool = bool(r["home"])
		if opp < 0:
			UiKit.text(v, v.font, UiKit.t("Bye"), Vector2(40, y), 13, col)
		else:
			UiKit.text_fit(v, v.font, (UiKit.t("Home  ·  %s") if home else UiKit.t("Away  ·  %s"))
				% String(v.season.world.clubs[opp]["name"]), Vector2(40, y), 13, col,
				SeasonScene.fixture_w() - 20.0)
		y += 20.0




## THE SEND-OFF CARD, the whole panel like a dilemma's: the day, the title, the
## words. One answer, on the button. Art follows (Pete, 1 Oct).
static func _draw_send_off(v: SeasonScene) -> void:
	var card: Dictionary = v.season.send_off_card()
	var y := SeasonScene.CONTENT_Y + 10.0
	UiKit.panel(v, Rect2(24, y, UiKit.span(), 300))
	UiKit.text(v, v.font, UiKit.t("THE SEND-OFF  ·  %s  ·  %d OF %d") % [String(card["day"]),
		v.season.send_off + 1, SendOff.STEPS], Vector2(48, y + 30), 13, UiKit.DIM)
	UiKit.text(v, v.font, String(card["title"]), Vector2(48, y + 62), 22, UiKit.YOU)
	var line_y := y + 104.0
	for line in UiKit.wrap(v.font, String(card["body"]), UiKit.span(48.0), 16):
		UiKit.text(v, v.font, line, Vector2(48, line_y), 16, UiKit.INK)
		line_y += 26.0


static func _draw_dilemma(v: SeasonScene) -> void:
	var card := v.season.dilemma_card()
	if card.is_empty():
		return
	var y := SeasonScene.CONTENT_Y + 10.0
	## THE PANEL RUNS DOWN TO THE BUTTONS on every screen shape, and the rule and
	## the answers hang off ITS bottom (Pete, 3 Oct 2026: "the dilemma choices are
	## all too high and are clipped into the lines"). It was a fixed 300 tall
	## with the answers placed off the button row, so the first line of each
	## answer sat on the rule, and on an iPad the answers fell out of the panel.
	var bottom := SeasonScene.action_y() - 14.0
	UiKit.panel(v, Rect2(24, y, UiKit.span(), bottom - y))
	## THE RULE SITS AS HIGH AS THE TALLEST ANSWER NEEDS (3 Oct 2026, the deck
	## rewrite): a fixed 98 held two-line answers, and the rewritten charity card's
	## three lines of prose plus a wrapped row of figures printed "crowd +3" on
	## the panel's edge. Measured with the same wrap the drawing below uses.
	var opts0: Array = card.get("options", [])
	var w0: float = (UiKit.span(32.0) - float(maxi(0, opts0.size() - 1)) * 12.0) / float(maxi(1, opts0.size()))
	var need := 98.0
	for o0 in opts0:
		var nb := UiKit.wrap(v.font, UiKit.t(String(o0["blurb"])), w0 - 20.0, 14).size()
		var rows := _cost_rows(v, Dilemma.costs(o0), w0)
		need = maxf(need, 34.0 + float(nb) * 18.0 + float(rows - 1) * 17.0 + 14.0)
	var rule_y := bottom - need
	UiKit.text(v, v.font, String(card["title"]).to_upper(), Vector2(48, y + 36), 20, UiKit.YOU)
	## The body wraps by hand rather than by a Label, because everything else on
	## this screen is drawn and a single themed Label in the middle of it reads
	## like a different program.
	## IT TYPES ITSELF IN, one character every second frame.
	##
	## This is the most era-correct thing on the whole juice list and it costs
	## nothing — but it is allowed HERE and nowhere else. A dilemma is the one
	## place in this game the player is reading a voice rather than a number,
	## and a roster or a league table that typed itself in would be a table you
	## cannot read. The rule is written down in JUICE.md as *never on numbers or
	## tables*, and this is the only screen that qualifies.
	##
	## Keyed on the card's own title, so a new dilemma types again and a redraw
	## of the same one carries on from where it was rather than restarting every
	## frame — which is what it did the first time I wired it, and what it
	## looked like was a stutter.
	var key := "dilemma:" + String(card["title"])
	if v._typing_key != key:
		v._typing_key = key
		Juice.type_start(key, String(card["body"]))
	var body := Juice.typed(key)
	## WRAPPED BY PIXELS, AND STOPPED ABOVE THE RULE (3 Oct 2026). 74 characters
	## of a 12-pixel face is 888px from x=48, past the panel's inner edge at
	## 960, and nothing kept a long body off the answers' block below the rule.
	var lines := UiKit.wrap(v.font, body, UiKit.span(48.0) - 24.0, 16)
	var fit_n := maxi(1, int(floor((rule_y - 12.0 - (y + 78.0)) / 26.0)) + 1)
	if lines.size() > fit_n:
		lines = lines.slice(0, fit_n)
		lines[fit_n - 1] = UiKit.fit_px(v.font, lines[fit_n - 1] + "...", 16, UiKit.span(48.0) - 24.0)
	var line_y := y + 78.0
	for line in lines:
		UiKit.text(v, v.font, line, Vector2(48, line_y), 16, UiKit.INK)
		line_y += 26.0
	## The cursor, blinking, at the end of what has arrived. Nothing in a retro
	## game is ever completely still, and a card that is still printing needs to
	## look like it is still printing rather than like it has stopped short.
	if not Juice.type_done(key) and not lines.is_empty():
		var last := String(lines[lines.size() - 1])
		var w := v.font.get_string_size(last, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
		if Juice.blink(18):
			UiKit.text(v, v.font, "_", Vector2(48.0 + w, line_y - 26.0), 16, UiKit.YOU)

	## Each answer's PRICE under its button, in the club's own words — and, since
	## 14 Sep 2026, in figures as well.
	##
	## THE COMMENT ABOVE THIS USED TO BE A CLAIM RATHER THAN A DESCRIPTION. It
	## said "each answer's PRICE" and the code drew the `blurb`, which is prose:
	## "All thirteen, done properly" implies a cost the way prose implies things,
	## and a player deciding between three cards was pricing them by tone.
	##
	## Pete sent Retro Bowl's press interview over, where every answer carries an
	## EFFECT box under it showing the face it will produce. Same idea, same
	## reason: *a dilemma whose costs are hidden until after the tap is a coin
	## flip with extra steps* — and that sentence was already sitting here.
	##
	## The sentence stays and the figures go under it. `Dilemma.costs()` decides
	## both what is shown and which way each figure moves, off one read of one
	## dictionary, so the words and the colors can never disagree.
	var opts: Array = card.get("options", [])
	var w: float = (UiKit.span(32.0) - float(maxi(0, opts.size() - 1)) * 12.0) / float(maxi(1, opts.size()))
	## A RULE BETWEEN THE VOICE AND THE PRICES. The body is somebody talking and
	## the block underneath is three columns of figures, and with nothing between
	## them a short card left a hundred and fifty pixels of nothing in the middle
	## of the panel and the answers read as though they had come loose from it.
	## The line says the bottom of this panel is a different kind of thing, which
	## is true — it is the only structure on the card that encodes something.
	UiKit.rule(v, UiKit.RULE_GEM, Vector2(48.0, rule_y), UiKit.span(48.0), UiKit.FRAME)
	## AND A KEY TO THE TWO WORDS NOBODY CAN GUESS.
	##
	## Pete, item 16 of the 15 Sep playtest: *"No idea what room or name mean."*
	## They are the squad's morale and the club's notoriety, and the card has been
	## printing `room -5` and `name +3` since the deck was written without either
	## word appearing anywhere else in the game. `kit`, `CC` and `crowd` explain
	## themselves; these two do not.
	##
	## On the rule rather than under the figures, because it is a legend and not
	## a fourth column — and read out of `Dilemma.FX_WORD` so that renaming a
	## currency renames its own key instead of leaving a caption behind.
	## SHORT ENOUGH FOR THE RULE IT SITS ON. The first wording ran to 440 pixels
	## in the 420 it was given and printed "how well you are kn" — a legend that
	## needs its own legend.
	## (The "room = … · name = …" legend is gone: the figures say "team morale"
	## and "renown" in full now — playtest 30 Sep #7.)
	for i in opts.size():
		var o: Dictionary = opts[i]
		var x := 24.0 + float(i) * (w + 12.0)
		## TWENTY HIGHER, so a two-line answer keeps its figures inside the panel
		## (playtest 30 Sep: "room -4 · name +1" printed on the panel's edge).
		var by := rule_y + 34.0
		## Inset to the same ten pixels a button pads its own label by, so a
		## column of prose sits over its button rather than over the gap, and the
		## leftmost one stops touching the edge of the panel.
		## WRAPPED BY PIXELS, not by a guessed character width (playtest 30 Sep:
		## "tomorrow" ran into the next column's "He has heard that before").
		for line in UiKit.wrap(v.font, UiKit.t(String(o["blurb"])), w - 20.0, 14):
			UiKit.text(v, v.font, line, Vector2(x + 10.0, by), 14, UiKit.DIM)
			by += 18.0
		var bill: Array[Dictionary] = Dilemma.costs(o)
		## AN OPTION THAT ASKS NOTHING SAYS SO. A blank where the other two cards
		## have figures reads as a card the game forgot to price, which is the
		## opposite of what a free choice should feel like.
		if bill.is_empty():
			UiKit.text(v, v.font, UiKit.t("costs nothing"), Vector2(x + 10.0, by + 2.0), 14, UiKit.DIM)
			continue
		## EACH FIGURE IN ITS OWN COLOR, laid out by measuring what has already
		## been drawn rather than by joining a string — a single color for the
		## row would have to pick one, and the answers worth thinking about are
		## the mixed ones.
		var fx := x + 10.0
		for j in bill.size():
			var e: Dictionary = bill[j]
			var t := String(e["text"])
			## A FIGURE THAT WOULD CROSS INTO THE NEXT ANSWER starts a new line.
			var tw := v.font.get_string_size(" · " + t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
			if j > 0 and fx + tw > x + w - 4.0:
				fx = x + 10.0
				by += 17.0
			elif j > 0:
				UiKit.text(v, v.font, " · ", Vector2(fx, by + 2.0), 14, UiKit.DIM)
				fx += v.font.get_string_size(" · ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
			## RED ONLY FOR A PRICE THE CLUB CANNOT PAY (3 Oct 2026). A cost you can
			## meet is a cost, not a danger; it reads in the quiet ink.
			UiKit.text(v, v.font, t, Vector2(fx, by + 2.0), 13,
				UiKit.UP if int(e["dir"]) > 0 else (UiKit.DOWN if _cant_pay(v, o, t) else UiKit.DIM))
			fx += v.font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x


## THE ONE FIGURE THAT CAN BE UNAFFORDABLE is the money: a CC cost above what
## the club holds (3 Oct 2026).
static func _cant_pay(v: SeasonScene, o: Dictionary, text: String) -> bool:
	if not text.begins_with(UiKit.t(String(Dilemma.FX_WORD["cc"])) + " "):
		return false
	var cc := float((o.get("fx", {}) as Dictionary).get("cc", 0.0))
	return cc < 0.0 and int(round(-cc)) > v.season.office.credits


## How many rows an answer's figures take in a column `w` wide — the same
## breaking rule as the drawing loop above, without drawing.
static func _cost_rows(v, bill: Array, w: float) -> int:
	if bill.is_empty():
		return 1
	var rows := 1
	var fx := 10.0
	for j in bill.size():
		var t := String(bill[j]["text"])
		var tw: float = v.font.get_string_size(" · " + t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
		if j > 0 and fx + tw > w - 4.0:
			fx = 10.0
			rows += 1
		elif j > 0:
			fx += v.font.get_string_size(" · ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
		fx += v.font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	return rows




## WHAT THE FIXTURE PANEL IS CALLED. One function, because the notch and the
## body are drawn in two places and a heading computed twice is a heading that
## eventually says two different things.
static func _fixture_title(v: SeasonScene) -> String:
	## THE HEAD OF THE QUEUE NAMES THE PANEL (29 Sep 2026). This asked its own
	## questions, promotion first, where `blocked_by()` puts promotion last — the
	## same fault the action row had — so with a dilemma and a promotion offer
	## both pending the panel said PROMOTION over the dilemma's buttons. And it
	## was English in every language: `UiKit.window` drew titles outside the
	## ledger, so the string sweep never saw them.
	match v.season.blocked_by():
		"promotion":
			return UiKit.t("PROMOTION")
		"bid":
			return UiKit.t("TOURNAMENT BID")
		"cup":
			var cup := v.season.pending_cup()
			return "%s  ·  %s" % [cup.cup_name.to_upper(), cup.round_label().to_upper()]
		"dilemma":
			return UiKit.t("A DECISION")
		"sendoff":
			return UiKit.t("THE SEND-OFF")
	if v.season.season_complete():
		return UiKit.t("SEASON COMPLETE")
	## THE WEEK, AND WHAT IT IS (30 Sep 2026). One fixture a Saturday, so the
	## panel names the Saturday: league day, cup round, or nothing for you.
	var w: Dictionary = v.season.world.this_week()
	return UiKit.t("WEEK %d  ·  %s") % [v.season.world.week + 1,
		Calendar.label(w, v.season.world.events_this_season(), _own_name(v)).to_upper()]


static func _own_name(_v: SeasonScene) -> String:
	return ""




static func _fixture(v: SeasonScene) -> void:
	var y := SeasonScene.CONTENT_Y + 20.0
	## 118 AND NOT 104. The card grew a line — where the fight is, in what ground,
	## and what the gate is worth — and the first cut drew it at `y + 98` inside a
	## 104-tall box, so the sentence sat ON the bottom rule. A line added to a
	## panel sized for the lines it already had is the same bug this project has
	## now shipped on the clubhouse, the settings screen and here.
	var r := Rect2(24, y, SeasonScene.fixture_w(), SeasonScene.FIXTURE_H)
	## THE HEADING GOES IN THE FRAME.
	##
	## It used to be the first line INSIDE the panel, which cost a line of the
	## panel's height to say something the panel already was. Cut into the top
	## rule it is furniture rather than content, the body starts higher, and a
	## rectangle becomes a labelled window — which is the single change that
	## stops an 8-bit menu reading like a web layout with a pixel font on it.
	UiKit.window(v, r, v._fixture_title(), v.font)
	if v.season.promotion_offered():
		## GO UP, OR STAY WHERE YOU ARE.
		##
		## Pete, 15 Sep 2026: *"If you qualify for the next league, you can choose
		## to advance, or stay within your league next season. A player may bust
		## through the season but want to stay a season and continue building up
		## their money, train players, or whatever they wish, and staying in a
		## cheaper league would be beneficial."*
		##
		## BOTH BILLS ON THE CARD, because that is the whole decision and a player
		## should not have to go and find the second number on another page. The
		## division is a thing you pay to be in now, so "stay down" is a saving
		## with a figure on it rather than a button that wastes a year.
		var t: Dictionary = v.season.promotion_terms()
		UiKit.text(v, v.font, UiKit.t("Up to the %s") % String(t["to"]),
			Vector2(44, y + 52), 22, UiKit.UP)
		## FITTED TO THE CARD. "You finished 1st. The place is yours if you want
		## it." is 430 pixels at 14px against a 436-pixel panel, and the first
		## render lost the last two words — copy the game wrote itself is not
		## allowed to lose its tail.
		## THE GROUND, WHEN IT IS THE THING IN THE WAY (#13). The division above
		## will not fight in a lesser arena, and that outranks the pleasantry:
		## the card has three lines and this one is the one the player must act on.
		if bool(t["arena_ok"]):
			UiKit.text_fit(v, v.font,
				UiKit.t("Finished %s. The place is yours if you want it.")
					% UiKit.ordinal(v.season.position()),
				Vector2(44, y + 80), 14, UiKit.DIM, SeasonScene.fixture_w() - 40.0)
		else:
			UiKit.text_fit(v, v.font,
				UiKit.t("Needs: %s. Yours: %s.") % [String(t["arena_need"]), String(t["arena_have"])],
				Vector2(44, y + 80), 14, UiKit.DOWN, SeasonScene.fixture_w() - 40.0)
		UiKit.pair(v, v.font,
			UiKit.t("%s costs %d a season") % [String(t["to"]), int(t["dues_up"])],
			UiKit.t("you have %d") % int(t["in_hand"]),
			Vector2(44, y + 104), 24.0 + SeasonScene.fixture_w() - 20.0, 12, 12,
			UiKit.DIM,
			UiKit.UP if int(t["in_hand"]) >= int(t["dues_up"]) else UiKit.DOWN)
		return
	if v.season.bid_open():
		UiKit.text(v, v.font, UiKit.t("Three dates on offer"), Vector2(44, y + 48), 22, UiKit.INK)
		## WRAPPED TO THE CARD. This ran 53 pixels past the fixture panel's right
		## edge — it is in the very first screenshot in `shots/`, clipped
		## mid-sentence, and nobody read it as a fault because a sentence that
		## stops at a panel edge looks like a sentence that stops.
		UiKit.text_fit(v, v.font, UiKit.t("Hold your own event this year, or pass."),
			Vector2(44, y + 70), 14, UiKit.DIM, SeasonScene.fixture_w() - 40.0)
		## "Choose at the Arena" is a real button now, in the card's corner
		## (`bid_button`): drawn as gold words it read as a caption.
		return
	var cup := v.season.pending_cup()
	if cup != null:
		var opp := v.season.cup_opponent()
		var o: Dictionary = v.season.world.clubs[opp]
		UiKit.text(v, v.font, UiKit.clip(UiKit.t(String(o["name"])), 26),
			Vector2(44, y + 52), 22, UiKit.INK)
		var gap := int(v.season.world.clubs[v.season.world.player_club]["power"]) - int(o["power"])
		UiKit.text(v, v.font, UiKit.t("rating %d  ·  win or you are out") % int(o["power"]),
			Vector2(44, y + 80), 14, UiKit.UP if gap > 0 else UiKit.DOWN)
		return
	if v.season.season_complete():
		UiKit.text(v, v.font, UiKit.t("Finished %s of %d in the %s.") % [
			UiKit.ordinal(v.season.position()), v.season.table().size(), v.season.tier_name()],
			Vector2(44, y + 52), 15, UiKit.DIM)
		UiKit.text(v, v.font, UiKit.t("The summer is next."),
			Vector2(44, y + 80), 14, UiKit.DIM)
		return
	var opp := v.season.opponent_id()
	if opp == -1:
		## A SATURDAY WITH NOTHING ON FOR YOU: a cup you are not in, a playoff
		## you missed. It says so, and says what the week is for instead.
		var league_week: bool = v.season.world.week_kind() == Calendar.Kind.LEAGUE
		UiKit.text(v, v.font, UiKit.t("Bye") if league_week else UiKit.t("No fixture for you"),
			Vector2(44, y + 52), 22, UiKit.INK)
		## TWO LINES (3 Oct 2026): 501px of sentence in 381px of card was cut to
		## "Knocks get a week t." at 960 wide.
		UiKit.para(v, v.font, UiKit.t("The squad trains through it. Knocks get a week to heal."),
			Vector2(44, y + 78), 14, UiKit.DIM, SeasonScene.fixture_w() - 40.0, 18.0, 2)
		return
	var o: Dictionary = v.season.world.clubs[opp]
	UiKit.text(v, v.font, UiKit.clip(UiKit.t(String(o["name"])), 26), Vector2(44, y + 52), 22, UiKit.INK)
	var gap := int(v.season.world.clubs[v.season.world.player_club]["power"]) - int(o["power"])
	## Three whole sentences, not one with an English word dropped into it: a
	## translation cannot agree with a word it never sees.
	var line: String = (UiKit.t("rating %d  ·  an even fight") % int(o["power"])) if absi(gap) <= 2 \
		else ((UiKit.t("rating %d  ·  you are favorites by %d") if gap > 0
			else UiKit.t("rating %d  ·  you are underdogs by %d")) % [int(o["power"]), absi(gap)])
	var g: Dictionary = v.season.gate_now()
	## RATING, THE ODDS AND THE GATE — and nothing else (Pete, 1 Oct: "Just have
	## Rating, 'even fight', and 5CC on there"). The ground's name and its state
	## are on the Arena screen.
	UiKit.pair(v, v.font, line, UiKit.t("%d CC") % int(g["cc"]),
		Vector2(44, y + 80), 24.0 + SeasonScene.fixture_w() - 20.0, 15, 15,
		UiKit.DIM if absi(gap) <= 2 else (UiKit.UP if gap > 0 else UiKit.DOWN),
		UiKit.UP if int(g["cc"]) >= v.season.office.crowd_pay() else UiKit.DIM)
	## HOW WELL THEY THINK, which the rating does not tell you.
	##
	## A division's AI tier decides whether the other corner improvises once its
	## plan runs out, hunts a wobbling man, makes the two-on-one or bails a
	## losing hold — Seasoned beats Green 63% on identical rosters. Your own
	## side's tiers are spelled out on the Clubhouse tab and the opponent's were
	## never shown anywhere, so the one number that explains why the same rating
	## feels harder two divisions up was invisible.
	UiKit.right(v, v.font, UiKit.t(String(Tuning.AI_SKILL[v.season.ai_tier()]["name"])).to_upper(),
		## OFF THE CARD'S OWN RIGHT EDGE (3 Oct 2026): pinned at x=432 it floated
		## mid-card on a phone, where the card runs on to 545 or 586.
		Vector2(24.0 + SeasonScene.fixture_w() - 14.0, y + 28), 12, UiKit.YOU, 200)

	var kind := int(g["kind"])
	UiKit.text(v, v.font, UiKit.t(String(Venue.NAME[kind])).to_upper(), Vector2(44, y + 28), 12,
		UiKit.YOU if kind == Venue.Kind.HOME else UiKit.DIM)




static func _last_event(v: SeasonScene) -> void:
	var e := v.season.last_event()
	if e.is_empty():
		return
	var y := SeasonScene.CONTENT_Y + 152.0
	if bool(e.get("bye", false)):
		UiKit.text(v, v.font, UiKit.t("Last event: bye"), Vector2(28, y), 14, UiKit.DIM)
		return
	var rf := int(e["rf"])
	var ra := int(e["ra"])
	## Three whole sentences, not an English verb dropped into one (29 Sep 2026).
	var line := UiKit.t("Last: beat %s %d-%d (%+d)%s") if rf > ra \
		else (UiKit.t("Last: lost to %s %d-%d (%+d)%s") if rf < ra \
		else UiKit.t("Last: drew with %s %d-%d (%+d)%s"))
	var col := UiKit.UP if rf > ra else (UiKit.DOWN if rf < ra else UiKit.DIM)
	## FITTED TO ITS COLUMN: it ran into the table's key (blind review round 3).
	UiKit.text_fit(v, v.font, line % [
		UiKit.clip(String(v.season.world.clubs[int(e["opponent"])]["name"]), 22), rf, ra,
		int(e["margin"]), "" if bool(e["fought"]) else UiKit.t("  ·  simmed")],
		Vector2(28, y), 14, col, SeasonScene.fixture_w() - 8.0)




static func _table(v: SeasonScene) -> void:
	var rows := v.season.table()
	var t := v.season.world.player_tier()
	## THE TOP FOUR GO TO THE PLAYOFF (30 Sep 2026), and the two finalists go
	## up — so the band that matters in the table is the playoff, not the old
	## promotion places.
	var up := Calendar.PLAYOFF_FIELD
	var down := int(League.TIERS[t]["down"])
	## THE STAT BLOCK HANGS OFF THE RIGHT EDGE, not off a fixed offset from the
	## table's left. It is one fixed-width string, so its width is the same every
	## row and on every screen — but where it BELONGS moves with the canvas, and
	## pinned at table_x() + 240 it left the numbers stranded mid-row on a handset
	## with the highlighted row running on past them.
	## SEVEN RIGHT-ALIGNED COLUMNS, NOT ONE STRING (3 Oct 2026). The block was
	## measured as the 13px header and drawn as 14px rows of "%2d" whose spaces are
	## narrower than its digits, so by week ten "+10 +30 21" ended at x=952 on a
	## 960 screen and the heads sat over the wrong figures. Each column now ends at
	## its own right edge, sized for the widest figure it can hold.
	var cols := _table_cols(v)
	var stat_x: float = float(cols[0]["x"]) - float(cols[0]["w"])
	## ONE KEY PER HEAD, since each is drawn on its own over its column.
	var heads := [UiKit.t("P"), UiKit.t("W"), UiKit.t("D"), UiKit.t("L"),
		UiKit.t("RD"), UiKit.t("MG"), UiKit.t("PTS")]
	for c in cols.size():
		UiKit.right(v, v.font, heads[c], Vector2(float(cols[c]["x"]), SeasonScene.TABLE_Y - 6),
			12, UiKit.DIM, float(cols[c]["w"]) + 8.0)
	v.draw_rect(Rect2(SeasonScene.table_x(), SeasonScene.TABLE_Y, UiKit.screen().x - SeasonScene.table_x() - 24, 1), UiKit.EDGE)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var cid := int(r["club"])
		var y := SeasonScene.TABLE_Y + 22.0 + float(i) * SeasonScene.ROW_H
		var mine: bool = cid == v.season.world.player_club
		if mine:
			v.draw_rect(Rect2(SeasonScene.table_x(), y - 15, UiKit.screen().x - SeasonScene.table_x() - 24, SeasonScene.ROW_H - 2), UiKit.PANEL)
		var edge := Color.TRANSPARENT
		if i < up:
			## The top flight promotes nobody — those two places are Worlds
			## berths, and coloring them green would promise a division above
			## the National that does not exist.
			edge = UiKit.UP
		elif down > 0 and i >= rows.size() - down:
			edge = UiKit.DOWN
		if edge != Color.TRANSPARENT:
			## THE WHOLE ROW, FAINTLY, AND THEN THE STRIPE.
			##
			## A four-pixel stripe marks a row; it does not group one. Sixteen
			## clubs in the National read as a ladder you count down, when what
			## the player is actually asking is which of three things his club is
			## in the middle of — going up, going down, or neither. Retro Bowl
			## bands its standings for the same reason.
			##
			## It has to cost NO HEIGHT: sixteen rows at 22 already end at 514 on
			## a 540 screen, so captions or gaps between the bands would push the
			## bottom club off the bottom of the division. A wash behind the rows
			## groups them for nothing, and the stripe stays for the exact edge.
			##
			## Drawn BEFORE the player's own highlight would be wrong — his row is
			## the one row that must read as his first and as a promotion place
			## second — so the wash goes down first and `mine` paints over it.
			if not mine:
				v.draw_rect(Rect2(SeasonScene.table_x(), y - 15, UiKit.screen().x - SeasonScene.table_x() - 24,
					SeasonScene.ROW_H - 2), Color(edge.r, edge.g, edge.b, 0.10))
			v.draw_rect(Rect2(SeasonScene.table_x(), y - 15, 4, SeasonScene.ROW_H - 2), edge)
		var col := UiKit.YOU if mine else UiKit.INK
		UiKit.text(v, v.font, "%2d" % (i + 1), Vector2(SeasonScene.table_x() + 12, y), 14, UiKit.DIM)
		## Clipped to the room there is, not to 24 characters: at 24 "Oklahoma
		## City Gunslingers" lost its last word with a hundred pixels to spare
		## before the numbers (29 Sep 2026).
		## CLIPPED AT THE SIZE IT IS DRAWN (review, 1 Oct: "Company2" ran into P).
		UiKit.text(v, v.font, UiKit.fit_name(v.font, String(v.season.world.clubs[cid]["name"]),
			String(v.season.world.clubs[cid].get("short", "")), 14,
			stat_x - (SeasonScene.table_x() + 38) - 12), Vector2(SeasonScene.table_x() + 38, y), 14, col)
		var vals := ["%d" % int(r["played"]), "%d" % int(r["won"]), "%d" % int(r["drawn"]),
			"%d" % int(r["lost"]), "%+d" % League.round_diff(r), "%+d" % League.margin_diff(r),
			"%d" % int(r["points"])]
		for c in cols.size():
			UiKit.right(v, v.font, vals[c], Vector2(float(cols[c]["x"]), y), 14, col, float(cols[c]["w"]))


## The table's figure columns, right to left from the right edge: each one as
## wide as the widest figure it holds at the size the rows are drawn (3 Oct 2026).
static func _table_cols(v: SeasonScene) -> Array:
	var widest := ["99", "99", "99", "99", "-99", "-999", "99"]
	var heads_en := [UiKit.t("P"), UiKit.t("W"), UiKit.t("D"), UiKit.t("L"),
		UiKit.t("RD"), UiKit.t("MG"), UiKit.t("PTS")]
	var gap := 8.0
	var out: Array = []
	var x := UiKit.right_edge(24.0)
	for c in range(widest.size() - 1, -1, -1):
		## AS WIDE AS ITS HEAD TOO: "PTS" is wider than "99", and the heads ran
		## together as "MGPTS".
		var w := maxf(v.font.get_string_size(widest[c], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x,
			v.font.get_string_size(heads_en[c], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12).x)
		out.push_front({"x": x, "w": w})
		x -= w + gap
	return out


## ------------------------------------------------------------ the ground
## MID-SEASON, THE GROUND THE NEXT DIVISION NEEDS (Pete, 1 Oct 2026: "make a
## prompt about mid-season about needing the next arena"). Once a season, from
## halfway, to a club in the playoff places on a ground the division above
## would refuse. A build button for the next step (one a week, as ever) and
## Later. Built all the way, it closes itself.
## THE PROMOTION GATE, AS A CARD THAT HAS TO BE ANSWERED (Pete, 2 Oct 2026:
## "Agree" — a player who only ever presses Fight was promoted, could not go up
## on his ground, and nothing in front of him said so). When the place is won
## and the ground is short, the hub shows this and nothing else until it is
## answered: build what the division needs and go up, or stay down.
static func gate_due(v: SeasonScene) -> bool:
	return v.season.blocked_by() == "promotion" and not v.season.ground_gap().is_empty()


static func _gate_controls(v: SeasonScene) -> void:
	var card := _ground_card()
	var gap: Dictionary = v.season.ground_gap()
	var pt: Dictionary = v.season.promotion_terms()
	var o := v.season.office
	var build := UiKit.button(UiKit.with_upkeep(UiKit.t("Build now · %d CC") % int(gap["total"]),
			o.arena_upkeep_at(Arena.level_for_tier(v.season.world.player_tier() + 1))),
		Vector2(card.end.x - 24.0 - 300.0, card.end.y - 62.0), Vector2(300, 44), func():
			var err: String = v.season.build_for_promotion()
			if err != "":
				v.flash = UiKit.said(err)
			else:
				err = v.season.answer_promotion(true)
				v.flash = UiKit.said(err) if err != "" else UiKit.t("%s built. Up to the %s.") % [
					UiKit.t(String(gap["need"])), String(pt["to"])]
			Session.autosave()
			v._rebuild(), "hall")
	build.disabled = o.credits < int(gap["total"])
	v.ui.add_child(UiKit.primary(build) if not build.disabled else build)
	v.ui.add_child(UiKit.button(UiKit.t("Stay down"), Vector2(card.position.x + 24.0, card.end.y - 62.0),
		Vector2(170, 44), func():
			v.season.answer_promotion(false)
			v.flash = UiKit.t("Staying in the %s another year.") % String(pt["from"])
			Session.autosave()
			v._rebuild(), "shield"))


static func _draw_gate(v: SeasonScene) -> void:
	var card := _ground_card()
	var gap: Dictionary = v.season.ground_gap()
	var pt: Dictionary = v.season.promotion_terms()
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, card)
	var w := card.size.x - 48.0
	UiKit.text_fit(v, v.font, UiKit.t("PROMOTED, IF YOU CAN HOST IT"), card.position + Vector2(24, 40), 18, UiKit.YOU, w)
	UiKit.para(v, v.font, UiKit.t("You have won a place in the %s, and it won't fight in your %s.") % [
		String(pt["to"]), UiKit.t(String(gap["have"]))], card.position + Vector2(24, 76), 15, UiKit.INK, w, 20.0, 2)
	var parts: Array = []
	for st in gap["steps"]:
		parts.append(UiKit.t(String(st)))
	UiKit.para(v, v.font, UiKit.t("To go up: %s. %d CC in all.") % [" → ".join(parts), int(gap["total"])],
		card.position + Vector2(24, 132), 15, UiKit.DIM, w, 20.0, 2)
	var short := int(gap["total"]) - v.season.office.credits
	UiKit.text_fit(v, v.font, (UiKit.t("You hold %d CC.") % v.season.office.credits) if short <= 0
		else UiKit.t("You hold %d CC: %d short. Stay down and build next year.") % [v.season.office.credits, short],
		card.position + Vector2(24, 188), 15, UiKit.UP if short <= 0 else UiKit.DOWN, w)


static func _ground_card() -> Rect2:
	var sz := Vector2(560.0, 300.0)
	return Rect2(Vector2(floorf((UiKit.screen().x - sz.x) * 0.5), 120.0), sz)


static func close_ground(v: SeasonScene) -> void:
	v.ground_open = false
	v.season.ground_warned = v.season.world.season
	Session.autosave()
	v._rebuild()


static func _ground_controls(v: SeasonScene) -> void:
	var card := _ground_card()
	var gap: Dictionary = v.season.ground_gap()
	if gap.is_empty():
		close_ground(v)
		return
	var o := v.season.office
	var b := UiKit.button(UiKit.with_upkeep(UiKit.t("Build %s · %d CC") % [UiKit.t(String(gap["next"])),
			int(gap["next_cost"])], o.arena_upkeep_next()),
		Vector2(card.end.x - 24.0 - 300.0, card.end.y - 62.0), Vector2(300, 44), func():
			var err := o.build_arena()
			v.flash = UiKit.said(err) if err != "" else UiKit.t("Built. %s.") % o.arena.arena_name()
			Session.autosave()
			if v.season.ground_gap().is_empty():
				close_ground(v)
			else:
				v._rebuild(), "hall")
	v.ui.add_child(UiKit.primary(b) if ground_block(v.season) == "" else b)
	v.ui.add_child(UiKit.button(UiKit.t("Later"), Vector2(card.position.x + 24.0, card.end.y - 62.0),
		Vector2(150, 44), func(): close_ground(v)))


## WHY THE BUILD CANNOT GO AHEAD THIS WEEK, or "" when it can. Said on the card:
## the flash bar is under the card's veil (novice report 2: a gym built from the
## card, then "Build Fenced ground" tapped and nothing seemed to happen).
static func ground_block(s: Season) -> String:
	var o := s.office
	if o.done_this_week(ClubOffice.SLOT_ARENA):
		return ClubOffice.throttle_word(UiKit.t("ground"))
	return o.arena.can_build(o.tier, o.credits)


static func _draw_ground(v: SeasonScene) -> void:
	var card := _ground_card()
	var gap: Dictionary = v.season.ground_gap()
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, card)
	if gap.is_empty():
		return
	var w := card.size.x - 48.0
	## NO ARTICLE BEFORE A NAME (3 Oct 2026): "NEEDS A ARENA", and "fight in a
	## Arena" on the lines below — so a colon here and "your" there.
	UiKit.text_fit(v, v.font, UiKit.t("THE %s NEEDS: %s") % [String(gap["to"]).to_upper(),
		UiKit.t(String(gap["need"])).to_upper()], card.position + Vector2(24, 40), 18, UiKit.YOU, w)
	## IN THE PLAYOFF PLACES, OR NOT YET: the card now also comes the first week
	## a build is affordable (2 Oct 2026), before the table says anything.
	var in_places: bool = v.season.world.player_position() <= SeasonDesk.PLAYOFF_PLACES
	UiKit.para(v, v.font, (UiKit.t("You are in the playoff places. If you go up, the %s won't fight in your %s.") if in_places
		else UiKit.t("You can build now. If you go up, the %s won't fight in your %s.")) % [
		String(gap["to"]), UiKit.t(String(gap["have"]))], card.position + Vector2(24, 76), 15, UiKit.INK, w, 20.0, 2)
	var parts: Array = []
	for st in gap["steps"]:
		parts.append(UiKit.t(String(st)))
	UiKit.para(v, v.font, UiKit.t("Still to build: %s. %d CC in all, one build a week.") % [
		" → ".join(parts), int(gap["total"])], card.position + Vector2(24, 132), 15, UiKit.DIM, w, 20.0, 2)
	UiKit.text_fit(v, v.font, UiKit.t("You hold %d CC.") % v.season.office.credits,
		card.position + Vector2(24, 188), 15,
		UiKit.UP if v.season.office.credits >= int(gap["next_cost"]) else UiKit.DOWN, w)
	var why := ground_block(v.season)
	if why != "":
		UiKit.para(v, v.font, why, card.position + Vector2(24, 210), 13, UiKit.DOWN, w, 17.0, 2)


## ------------------------------------------------------------ the free agents
## THE FIRST WEEK UP, THE MEN THE NEW DIVISION NEEDS (lane B, 2 Oct 2026). Once
## a season, before its first bout, to a club just promoted that can take a free
## agent who outrates a man on its eight. Free agents opens the list with him
## picked; Later closes it for the season.
static func close_market(v: SeasonScene) -> void:
	v.market_open = false
	v.season.market_warned = v.season.world.season
	Session.autosave()
	v._rebuild()


static func _market_ask_controls(v: SeasonScene) -> void:
	var card := _ground_card()
	var ask: Dictionary = v.season.market_ask()
	if ask.is_empty():
		close_market(v)
		return
	var best: FighterCard = ask["best"]
	v.ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Free agents"),
		Vector2(card.end.x - 24.0 - 300.0, card.end.y - 62.0), Vector2(300, 44), func():
			v.season.market_warned = v.season.world.season
			v.market_open = false
			Session.market_pick = Market.taken_key(best)
			Session.autosave()
			UiKit.go("res://scenes/Market.tscn"), "coin")))
	v.ui.add_child(UiKit.button(UiKit.t("Later"), Vector2(card.position.x + 24.0, card.end.y - 62.0),
		Vector2(150, 44), func(): close_market(v)))


static func _draw_market_ask(v: SeasonScene) -> void:
	var card := _ground_card()
	var ask: Dictionary = v.season.market_ask()
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, card)
	if ask.is_empty():
		return
	var w := card.size.x - 48.0
	var best: FighterCard = ask["best"]
	UiKit.text_fit(v, v.font, UiKit.t("THE %s HITS HARDER") % String(ask["tier"]).to_upper(),
		card.position + Vector2(24, 40), 18, UiKit.YOU, w)
	UiKit.para(v, v.font, UiKit.t("The weakest man on your eight rates %d. %d free agents rate higher, and you can pay for them.") % [
		int(ask["weakest"]), int(ask["count"])], card.position + Vector2(24, 76), 15, UiKit.INK, w, 20.0, 2)
	UiKit.para(v, v.font, UiKit.t("Best of them: %s, %d, %d CC.") % [best.display_name, best.overall(),
		v.season.market_fee(best)], card.position + Vector2(24, 132), 15, UiKit.DIM, w, 20.0, 2)
	UiKit.text_fit(v, v.font, UiKit.t("You hold %d CC.") % v.season.office.credits,
		card.position + Vector2(24, 188), 15, UiKit.UP, w)
