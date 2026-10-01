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
	var s := ""
	if not gone.is_empty():
		s += "  %s retired" % String(gone[0]).split(" (")[0]
		if gone.size() > 1:
			s += " and %d more" % (gone.size() - 1)
		s += "."
	## A man who WALKED is the more alarming of the two and gets said separately,
	## because the player could have stopped it and a retirement he could not.
	if not walked.is_empty():
		s += "  %s left on a free" % String(walked[0]).split(" (")[0]
		if walked.size() > 1:
			s += " with %d more" % (walked.size() - 1)
		s += "."
	if not took.is_empty():
		s += "  %d walk-on%s signed." % [took.size(), "" if took.size() == 1 else "s"]
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
	return "THE CLUB SPLIT. %d men walked out to found %s, who are in your division this season." % [
		took.size(), String(sp.get("club", "a rival"))]




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
		return "  Could not keep the %s — it fell a level." % String(lost[0]).to_lower()
	var billed: int = int(u.get("billed", 0))
	return "" if billed <= 0 else "  Upkeep %d CC." % billed




static func _club_controls(v: SeasonScene) -> void:
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
	if v.season.viewable_cup() != null:
		v.ui.add_child(UiKit.button(UiKit.t("Cup bracket"), Vector2(24, SeasonScene.action_y() - 52.0),
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
		## AND THE CARD ITSELF IS THE WAY IN (blind review round 3: "looks like a
		## card but doesn't look tappable"). A flat hit box over the drawn card,
		## which draws its own "Choose at the Arena >" as the cue.
		var hit := UiKit.button("", Vector2(24, SeasonScene.CONTENT_Y + 20.0),
			Vector2(SeasonScene.fixture_w(), SeasonScene.FIXTURE_H), func():
				Session.autosave()
				UiKit.go("res://scenes/Arena.tscn"))
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		v.ui.add_child(hit)
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
	v.ui.add_child(UiKit.button(UiKit.t("Sim it"), Vector2(UiKit.right_edge(SeasonScene.NEXT_W + 24.0 + 204.0 + 12.0),
		SeasonScene.action_y()), Vector2(204, 46),
		func():
			v.sim_asking = true
			v._rebuild(), "clock"))




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
	v._fixture()
	v._last_event()
	v._schedule()
	v._table()
	v._tape_draw_ground()




## ------------------------------------------------------------- what is left
## THE SPACE THE FORMATION AND PLAY BUTTONS LEFT. Pete, item 20: *"Maybe the
## schedule, and a couple other things."*
##
## The card said what is happening this week and the table said where everybody
## stands, and nothing anywhere said what is COMING — which is the one thing a
## manager plans against. Five rows, home and away marked, the current one lit.
static func _schedule(v: SeasonScene) -> void:
	var rest: Array = v.season.world.remaining_fixtures(5)
	if rest.is_empty():
		return
	## UNDER THE LAST RESULT, which sits at `CONTENT_Y + 152`. The first cut put
	## this at 150 and the heading printed straight through *"Last: beat Oklahoma
	## City Guard 2-0"* — two blocks in one column, written in two functions,
	## neither of which knew the other's height. Same shape as the clubhouse,
	## twice, today.
	var y := SeasonScene.CONTENT_Y + 186.0
	## SAYS WHICH COMPETITION (round 8: league fixtures under a cup tie read as
	## the cup's).
	UiKit.text(v, v.font, UiKit.t("LEAGUE STILL TO COME"), Vector2(24, y), 14, UiKit.DIM)
	## THE KEY FOR THE TWO COLUMNS NOBODY EXPLAINED (blind review round 3:
	## "A/H prefixes never explained").
	UiKit.right(v, v.font, UiKit.t("H home  ·  A away"),
		Vector2(SeasonScene.fixture_w() + 8.0, y), 12, UiKit.DIM, SeasonScene.fixture_w() - 140.0)
	y += 24.0
	for i in rest.size():
		var r: Dictionary = rest[i]
		var opp := int(r["opponent"])
		var home: bool = bool(r["home"])
		var nm := "a bye" if opp < 0 \
			else String(v.season.world.clubs[opp]["name"])
		## THE CURRENT MATCHDAY IS LIT and the rest are quiet, so the eye finds
		## "now" without reading the numbers.
		var col := UiKit.INK if i == 0 else UiKit.DIM
		## H AND A AS A MARK IN THE MARGIN, not "home" and "away" as words at the
		## end of the row.
		##
		## Pete, 15 Sep 2026: *"Let's have the Home and Away games notated."* They
		## were notated — in twelve-pixel EDGE grey, right-aligned past the club's
		## name, which is where the eye goes last. A one-letter mark in its own
		## column at the left is read at a glance down the list, which is what a
		## fixture list is for: **a fact you have to hunt for on a five-row list
		## is a fact that is not on the list.**
		if opp >= 0:
			UiKit.text(v, v.font, UiKit.t("H") if home else UiKit.t("A"), Vector2(28, y), 14,
				UiKit.YOU if home else UiKit.DIM)
		## AND WHAT THE AFTERNOON IS WORTH, which is the new half. The gate is
		## multiplied by the ground it is fought in, so a trip to somebody's
		## Sports hall pays better than a home tie in a back field — and a fixture
		## list that does not say so is hiding the one thing that now makes an
		## away day interesting.
		##
		## THE GROUND'S NAME AND THE FIGURE, not the figure and an adjective. The
		## first cut printed "1 CC · a thin gate" on all five rows, because in the
		## Backyard Circuit every club really is on a back field and the words
		## were all the same word — **a column that says the same thing on every
		## row is a column carrying no information.** The NAME differs from the
		## first season (a back field, a club gym, somebody's fenced ground) and
		## it teaches the player the map, which is what makes a fixture list worth
		## reading ahead. The adjective lives on the fixture panel, once, where
		## there is room for it to mean something.
		var tail := ""
		if opp >= 0:
			var gr: Dictionary = v.season.ground_of(
				v.season.world.player_club if home else opp)
			tail = "%s  ·  %d CC" % [Arena.arena_name_of(int(gr["level"])),
				v.season.gate_for_fixture(opp, home)]
		## THE NAME TAKES WHAT THE GROUND AND THE GATE LEAVE — measured, so a long
		## club name and a long translated ground never cut each other's tail.
		var tail_w := v.font.get_string_size(tail, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var num := UiKit.t("%d.  %s") % [int(r["event"]), ""]
		var num_w := v.font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var room := SeasonScene.fixture_w() - 16.0 - 46.0 - tail_w - 16.0 - num_w
		UiKit.pair(v, v.font, UiKit.t("%d.  %s") % [int(r["event"]),
			UiKit.clip_px(v.font, nm, 13, clampf(room, 60.0, 240.0))], tail,
			Vector2(46, y), SeasonScene.fixture_w() - 16.0, 13, 12, col, UiKit.DIM)
		y += 20.0




static func _draw_dilemma(v: SeasonScene) -> void:
	var card := v.season.dilemma_card()
	if card.is_empty():
		return
	var y := SeasonScene.CONTENT_Y + 10.0
	UiKit.panel(v, Rect2(24, y, UiKit.span(), 300))
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
	var lines := v._wrap(body, 74)
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
	UiKit.rule(v, UiKit.RULE_GEM, Vector2(48.0, SeasonScene.action_y() - 104.0), UiKit.span(48.0), UiKit.FRAME)
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
		var by := SeasonScene.action_y() - 86.0
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
				fx += v.font.get_string_size(" · ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
			UiKit.text(v, v.font, t, Vector2(fx, by + 2.0), 13,
				UiKit.UP if int(e["dir"]) > 0 else UiKit.DOWN)
			fx += v.font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x




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
	if v.season.season_complete():
		return UiKit.t("SEASON COMPLETE")
	return UiKit.t("EVENT %d OF %d") % [v.season.world.event + 1,
		v.season.world.events_this_season()]




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
				UiKit.t("Needs a %s. You have a %s.") % [String(t["arena_need"]), String(t["arena_have"])],
				Vector2(44, y + 80), 14, UiKit.DOWN, SeasonScene.fixture_w() - 40.0)
		UiKit.pair(v, v.font,
			UiKit.t("%s costs %d a season") % [String(t["to"]), int(t["dues_up"])],
			UiKit.t("you have %d") % int(t["in_hand"]),
			Vector2(44, y + 104), 24.0 + SeasonScene.fixture_w() - 20.0, 12, 12,
			UiKit.DIM,
			UiKit.UP if int(t["in_hand"]) >= int(t["dues_up"]) else UiKit.DOWN)
		return
	if v.season.bid_open():
		UiKit.text(v, v.font, UiKit.t("Three dates on offer"), Vector2(44, y + 52), 22, UiKit.INK)
		## WRAPPED TO THE CARD. This ran 53 pixels past the fixture panel's right
		## edge — it is in the very first screenshot in `shots/`, clipped
		## mid-sentence, and nobody read it as a fault because a sentence that
		## stops at a panel edge looks like a sentence that stops.
		UiKit.text_fit(v, v.font, UiKit.t("Hold your own event this year, or pass."),
			Vector2(44, y + 80), 14, UiKit.DIM, SeasonScene.fixture_w() - 40.0)
		UiKit.right(v, v.font, UiKit.t("Choose at the Arena  >"),
			Vector2(r.end.x - 16.0, y + 104), 14, UiKit.YOU, SeasonScene.fixture_w() - 40.0)
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
		UiKit.text(v, v.font, UiKit.t("The cups and the summer are next."),
			Vector2(44, y + 80), 14, UiKit.DIM)
		return
	var opp := v.season.opponent_id()
	if opp == -1:
		UiKit.text(v, v.font, UiKit.t("Bye"), Vector2(44, y + 52), 22, UiKit.INK)
		return
	var o: Dictionary = v.season.world.clubs[opp]
	UiKit.text(v, v.font, UiKit.clip(UiKit.t(String(o["name"])), 26), Vector2(44, y + 52), 22, UiKit.INK)
	var gap := int(v.season.world.clubs[v.season.world.player_club]["power"]) - int(o["power"])
	## Three whole sentences, not one with an English word dropped into it: a
	## translation cannot agree with a word it never sees.
	var line: String = (UiKit.t("rating %d  ·  an even fight") % int(o["power"])) if absi(gap) <= 2 \
		else ((UiKit.t("rating %d  ·  you are favorites by %d") if gap > 0
			else UiKit.t("rating %d  ·  you are underdogs by %d")) % [int(o["power"]), absi(gap)])
	UiKit.text(v, v.font, line,
		Vector2(44, y + 80), 14,
		UiKit.DIM if absi(gap) <= 2 else (UiKit.UP if gap > 0 else UiKit.DOWN))
	## HOW WELL THEY THINK, which the rating does not tell you.
	##
	## A division's AI tier decides whether the other corner improvises once its
	## plan runs out, hunts a wobbling man, makes the two-on-one or bails a
	## losing hold — Seasoned beats Green 63% on identical rosters. Your own
	## side's tiers are spelled out on the Clubhouse tab and the opponent's were
	## never shown anywhere, so the one number that explains why the same rating
	## feels harder two divisions up was invisible.
	UiKit.right(v, v.font, UiKit.t(String(Tuning.AI_SKILL[v.season.ai_tier()]["name"])).to_upper(),
		Vector2(432, y + 28), 12, UiKit.YOU, 200)

	## ------------------------------------------------- where, and what it pays
	## Pete, 15 Sep 2026: *"Let's have the Home and Away games notated."*
	##
	## THE PANEL THAT SAYS WHO YOU ARE FIGHTING DID NOT SAY WHERE. The schedule
	## underneath it carried a grey "home"/"away" and this — the card the player
	## actually looks at, the one with the rating and the odds on it — said
	## nothing at all about the venue. The one screen where the question is live
	## was the one screen with no answer on it.
	##
	## AND THE GROUND IS ON IT, because the gate now reads the room: a trip to a
	## club with a Sports hall pays better than a home tie in a back field, and
	## *"you may actually look forward to an opponent with a great stadium or roll
	## your eyes from an opponent with a shitty arena"* only works if the screen
	## tells you which one this is before you tap FIGHT.
	var g: Dictionary = v.season.gate_now()
	var kind := int(g["kind"])
	var where := UiKit.t(String(Venue.NAME[kind])).to_upper()
	UiKit.text(v, v.font, where, Vector2(44, y + 28), 12,
		UiKit.YOU if kind == Venue.Kind.HOME else UiKit.DIM)
	UiKit.pair(v, v.font,
		"%s  ·  %s" % [Arena.arena_name_of(int(g["level"])),
			Arena.worth_word(int(g["level"]), float(g["condition"]))],
		"%d CC at the gate" % int(g["cc"]),
		Vector2(44, y + 104), 24.0 + SeasonScene.fixture_w() - 20.0, 12, 12,
		UiKit.DIM,
		UiKit.UP if int(g["cc"]) >= v.season.office.crowd_pay() else UiKit.DIM)




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
	var up := int(League.TIERS[t]["up"])
	var down := int(League.TIERS[t]["down"])
	var top_flight: bool = t == League.TIERS.size() - 1
	## THE STAT BLOCK HANGS OFF THE RIGHT EDGE, not off a fixed offset from the
	## table's left. It is one fixed-width string, so its width is the same every
	## row and on every screen — but where it BELONGS moves with the canvas, and
	## pinned at table_x() + 240 it left the numbers stranded mid-row on a handset
	## with the highlighted row running on past them.
	var stat_w := v.font.get_string_size("P  W  D  L   RD   MG  PTS",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	var stat_x := UiKit.right_edge(24.0) - stat_w
	UiKit.text(v, v.font, UiKit.t("P  W  D  L   RD   MG  PTS"),
		Vector2(stat_x, SeasonScene.TABLE_Y - 6), 12, UiKit.DIM)
	## THE KEY, where there is room for it (blind review, 29 Sep: RD / MG and the
	## colored rows were unexplained). A sixteen-club table has no room and a
	## player there has read it for years.
	var key_y := SeasonScene.TABLE_Y + 22.0 + float(rows.size()) * SeasonScene.ROW_H + 4.0
	if key_y < SeasonScene.action_y() - 16.0:
		## TWO LINES AT 13 (the sentence floor, 29 Sep 2026) where one at 11 was.
		var room := UiKit.screen().x - SeasonScene.table_x() - 32.0
		var colors := ""
		if up > 0 and not top_flight:
			colors = UiKit.t("green goes up")
		if down > 0:
			colors += ("" if colors == "" else UiKit.t("  ·  ")) + UiKit.t("red goes down")
		var lines := [UiKit.t("RD rounds won minus lost"), UiKit.t("MG downs for minus against")]
		if colors != "":
			lines.append(colors)
		for li in lines.size():
			var ly := key_y + float(li) * 17.0
			if ly > SeasonScene.action_y() - 16.0:
				break
			UiKit.text_fit(v, v.font, String(lines[li]), Vector2(SeasonScene.table_x() + 8.0, ly), 14, UiKit.DIM, room)
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
			edge = UiKit.YOU if top_flight else UiKit.UP
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
		UiKit.text(v, v.font, UiKit.clip_px(v.font, String(v.season.world.clubs[cid]["name"]), 13,
			stat_x - (SeasonScene.table_x() + 38) - 10), Vector2(SeasonScene.table_x() + 38, y), 14, col)
		UiKit.text(v, v.font, UiKit.t("%2d %2d %2d %2d  %+3d  %+3d  %2d") % [
			int(r["played"]), int(r["won"]), int(r["drawn"]), int(r["lost"]),
			League.round_diff(r), League.margin_diff(r), int(r["points"])],
			Vector2(stat_x, y), 14, col)
