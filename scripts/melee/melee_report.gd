class_name MeleeReport
extends RefCounted
## The post-fight report. [C-4]
##
## A loss is attributed to the ROSTER, never to the thumb. Every line below is
## generated from state a management decision could have changed — the tank you
## did or did not buy, harness condition, who you fielded where, the formation
## and the strategy. Nothing reads the player's input accuracy, and the test
## greps for reflex-blaming phrasing and fails if any ever appears.
##
## "You missed three prompts" would send a losing player to a practice mode this
## game does not have and must never build. "Vance gassed at 0:40 of round three"
## sends him to the front office, which is the game.

class Line extends RefCounted:
	var severity: int = 0
	var text: String = ""
	func _init(sev: int, t: String) -> void:
		severity = sev
		text = t


## ---------------------------------------------------- what it cost the men
## THE BOTTOM HALF'S VOCABULARY — Pete, 13 Sep 2026: *"we can use the bottom half
## for status/trait changes as well."*
##
## `Season.last_changes` records what the afternoon did to each man, tagged with
## a `kind`; these are the headings those kinds are printed under, and the order
## they are printed in — worst news first, because a player who reads one line
## should read the knock.
##
## THEY LIVE HERE AND NOT ON THE SCREEN. The season writes kinds and the melee
## screen draws them: two files, and the gap between them is where a Scout
## grows — a kind recorded with no heading is a fact the game knows and never
## says. Putting the vocabulary in the report's own file gives `test_season.gd`
## something it can read without the scene, and it fails if the two ever drift.
const CHANGE_ORDER: Array[String] = ["knock", "level", "trait", "work", "mood"]
const CHANGE_HEAD := {
	"knock": "CARRIED OFF",
	"level": "EARNED",
	"trait": "WHO THEY ARE",
	"work": "THE WORK NOBODY WATCHES",
	"mood": "THE ROOM",
}


## ----------------------------------------------------------- the changing room
## WHAT THE MEN THINK — Pete, 13 Sep 2026: *"you'll have more stats with little
## opinions from the fighters, whether they did great, did terrible, haven't
## fought in a few matches, blaming coaches, or other things like funny things."*
##
## EVERY LINE IS EARNED BY SOMETHING THAT HAPPENED. There is no bag of generic
## quips dealt at random: a man says a thing because he put three people down, or
## because he was empty by the second round, or because this is the third bout he
## has watched from a bucket. A report where half the voices are filler teaches
## the player to skim it, which is the same thing as not having it.
##
## Ordered by how much the player can do about it, and capped by the screen —
## `MAX_QUIPS` is what the pane holds without scrolling past the fold on the
## smallest case.
const MAX_QUIPS: int = 6

## `tone`: 1 pleased, 0 flat, -1 unhappy. The screen colors the stripe from it.
class Quip extends RefCounted:
	var who: String
	var text: String
	var tone: int
	func _init(w: String, t: String, tn: int) -> void:
		who = w
		text = t
		tone = tn


static func quips(sim: MeleeSim, season) -> Array:
	var out: Array = []
	## ONE VOICE A MAN. Two lines from the same fighter reads as a transcript
	## rather than a changing room, and the first render had Calder saying he was
	## blowing AND that the shape was wrong, one card above the other.
	var spoke := {}
	var played := {}
	for m in sim.fought():
		if m.team != 0 or m.card == null:
			continue
		played[m.card] = true
		var name := m.card.display_name
		## A BIG AFTERNOON, and he wants you to know it.
		if m.downs_caused >= 3:
			_say(out, spoke, name, UiKit.t("%d down and I never left my feet. Put me back on.")
				% m.downs_caused, 1)
		elif m.downs_caused >= 2:
			_say(out, spoke, name, UiKit.t("Two of theirs on the floor. I could go again now."), 1)
		## EMPTY. He blames the winter, which is the honest read — the tank is a
		## stat the club did or did not buy him.
		if m.gassed_at >= 0.0 and m.gassed_at < 45.0:
			_say(out, spoke, name,
				UiKit.t("I was blowing after the first. That is the winter, not the afternoon."), -1)
		## PUT DOWN REPEATEDLY, and he blames the shape, which is the player's.
		if m.times_downed >= 2:
			_say(out, spoke, name,
				UiKit.t("We were stood in the wrong shape and everyone could see it."), -1)
		## THE WORK NOBODY WATCHES, in his own words.
		if int(m.assists) >= 2 and m.downs_caused == 0:
			_say(out, spoke, name,
				UiKit.t("I held two of them all afternoon. Somebody else got the credit."), 0)
		## HIS FIRST TIME ON THE EIGHT.
		if m.card.bouts <= 1:
			_say(out, spoke, name,
				UiKit.t("First time on the eight. I would like it not to be the last."), 1)
	## AND THE MEN WHO DID NOT PLAY. A bench that never speaks is a bench the
	## player forgets he is paying for, and "restless" is the state that turns
	## into a transfer request.
	if season != null:
		for f in season.club.active_eight():
			if played.has(f) or out.size() >= MAX_QUIPS * 2:
				continue
			if f.morale < 0.45:
				_say(out, spoke, f.display_name,
					UiKit.t("Nice of you to remember me. Another one watched from a bucket."), -1)
	out.sort_custom(func(a, b): return a.tone < b.tone)
	return out.slice(0, mini(MAX_QUIPS, out.size()))


## ------------------------------------------------------------------- the news
## THE CARDS ALONG THE BOTTOM — Pete, 14 Sep 2026: *"you can put in the playoff
## picture or standings and notable items."*
##
## Two sources and they are deliberately mixed rather than sectioned: what the
## afternoon did to the MEN (`Season.last_changes`, written where it happens) and
## what it did to the CLUB — where the table now has you, what that means for
## going up or down, the gate, the following. A player reads this once, and
## splitting it into two lists would make him read it twice.
##
## THE CLUB LINES GO FIRST because they are the ones a single result actually
## changed. The men's lines are already on the table above.
class News extends RefCounted:
	var head: String
	var text: String
	var tone: int
	## WHAT THE CARD IS ABOUT: the club, or one man.
	##
	## The report used to hand the screen six identical cards in one grid — the
	## table, the gate, the following and three fighters, side by side and
	## indistinguishable. They are two different readouts: the first three are
	## the club's afternoon and the rest are individual men, and a player
	## scanning for "what happened to my fighters" was reading past two cards
	## about a crowd to find out. **A grid that mixes two kinds of row is a grid
	## the eye has to sort by reading.**
	##
	## NAMED, NOT QUOTED AT THE CALL SITE. `test_icons.gd` scans every script for
	## a quoted lowercase word closing a call — the shape a button's trailing
	## icon takes — so a card constructed with the kind written out as a literal
	## on the end of the line read to it as a request for an icon of that name.
	## It was right to flag it: from the outside the two are identical text. Two
	## constants and the ambiguity is gone for good, which is better than
	## teaching the scanner an exception.
	##
	## (Written without an example on purpose. The first version of this comment
	## quoted the offending shape twice and the scanner flagged the COMMENT —
	## which is fair, and is the same lesson one level up.)
	const CLUB := "club"
	const MAN := "man"
	var kind: String
	func _init(h: String, t: String, tn: int, k: String = CLUB) -> void:
		head = h
		text = t
		tone = tn
		kind = k


## THE MEN FIRST, THEN THE CLUB.
##
## The order used to be table, gate, following, then the fighters — so the three
## cards a player could see without scrolling were a league position he can read
## off the table screen, a gate receipt, and a follower count, and the three he
## had to scroll for were the men he had just watched fight.
##
## That was invisible while the grid was one undivided row of six. Banding it
## made the fold real: the second band starts below the pane, and with the old
## order the pane opened on a heading reading THE MEN with nothing under it.
##
## **What a screen shows before the fold is what the screen is about.** He has
## just come off an afternoon; the men are the afternoon, and the club's three
## lines are the footnotes to it.
static func news(season) -> Array:
	var out: Array = []
	if season == null:
		return out
	for c in season.last_changes:
		out.append(News.new(String(c["who"]), String(c["text"]), int(c["good"]),
			News.MAN))
	var pos: int = season.world.player_position()
	var rows: Array = season.table()
	if pos > 0:
		var up: int = int(League.TIERS[season.world.player_tier()]["up"])
		var down: int = int(League.TIERS[season.world.player_tier()]["down"])
		var line := UiKit.t("%s of %d in the %s.") % [UiKit.ordinal(pos), rows.size(),
			String(League.TIERS[season.world.player_tier()]["name"])]
		var tone := 0
		## THE PLAYOFF PICTURE, in the one sentence that matters: are you going
		## up, are you going down, or is neither of those your problem today.
		if pos <= up:
			line += UiKit.t(" Promotion places.")
			tone = 1
		elif pos > rows.size() - down:
			line += UiKit.t(" Relegation places.")
			tone = -1
		else:
			var gap := pos - up
			line += UiKit.t(" %d off the promotion places.") % gap
		out.append(News.new(UiKit.t("The table"), line, tone))
	## THE GATE, AND ONLY WHEN IT WAS YOURS — an away day has none to report.
	##
	## WHAT THE CLUB WAS PAID, not what the club estimates came. `crowd_came` is
	## for demos and shows; a league fixture never calls it, so an attendance
	## figure here would be `ClubEvent.attendance()` run again after the fact —
	## an estimate of a number, printed as if it were the number. The credits are
	## a fact.
	## THE GATE IS PAID EVERYWHERE NOW, at a share, so the report says so
	## everywhere — and it names the ROOM, because the room is half the figure.
	## It used to print only at home, which meant two thirds of a season's
	## afternoons had a report with no money on it at all.
	var g: Dictionary = season.gate_now()
	## TYPED, because `season` is untyped in this function and `:=` cannot infer
	## through it — the parse gate in `run_tests.sh` caught it, which is the whole
	## reason that gate exists: `--import` swallows the error and the file only
	## fails when somebody opens the screen.
	var room: String = season.office.arena.arena_name()
	if int(g["kind"]) != Venue.Kind.HOME:
		room = Venue.title(int(g["kind"]),
			season.world.city_of(season.host_id()),
			Arena.arena_name_of(int(g["level"])))
	out.append(News.new(UiKit.t("The gate"), UiKit.t("%d CC, %s at %s.") % [
		int(g["cc"]), UiKit.t(String(g["where"])).to_lower(), room], 0))
	out.append(News.new(UiKit.t("The following"), UiKit.t("%d, and the room knows it.")
		% int(season.office.fans), 0))
	return out


## Append, unless he has already said something. The FIRST reason wins, and the
## reasons are written worst-first inside the loop for that: a man who gassed and
## was put down twice says the thing about the tank, which is the one the club
## can do something about.
static func _say(out: Array, spoke: Dictionary, who: String, what: String,
		tone: int) -> void:
	if spoke.has(who):
		return
	## ONE MAN SAYS A LINE (blind review, 29 Sep: two men, the same sentence,
	## word for word). The second man with the same complaint keeps quiet.
	if spoke.has("line:" + what):
		return
	spoke[who] = true
	spoke["line:" + what] = true
	out.append(Quip.new(who, what, tone))


static func build(sim: MeleeSim) -> Array:
	var out: Array = []
	var us := 0
	var them := 1
	var won := sim.bout_winner() == us
	var verb := "Won" if won else ("Drew" if sim.bout_winner() == -1 else "Lost")

	out.append(Line.new(0, UiKit.t("%s %d-%d on rounds, %d-%d on the ground. %s vs %s.") % [
		verb, sim.rounds_won[us], sim.rounds_won[them], sim.downs[us], sim.downs[them],
		sim.clubs[us].short_name, sim.clubs[them].short_name,
	]))

	out.append(Line.new(0, UiKit.t("You fought it in %s on \"%s\". They came out in %s.") % [
		Tuning.FORMATIONS[sim.formations[us]]["name"],
		Tuning.STRATEGIES[sim.strategies[us]]["name"],
		Tuning.FORMATIONS[sim.formations[them]]["name"],
	]))

	# --- the tank
	var gassed: Array = []
	for m in sim.fought():
		if m.team == us and m.gassed_at >= 0.0:
			gassed.append(m)
	gassed.sort_custom(func(a, b): return a.gassed_at < b.gassed_at)
	for m in gassed:
		out.append(Line.new(2 if not won else 1,
			UiKit.t("%s (#%d, %s) gassed at %d:%02d of round %d. He went in with %d gas against a %d-second round — the tank is a stat, and it is the one you did not buy.") % [
				m.card.display_name, m.card.number, m.card.pos_name(),
				int(m.gassed_at) / 60, int(m.gassed_at) % 60, maxi(1, m.gassed_round),
				m.card.gas, int(Tuning.ROUND_TIME),
			]))

	# --- harness
	for m in sim.fought():
		if m.team != us:
			continue
		if m.card.armor < 0.9 and m.times_downed >= 2:
			out.append(Line.new(1,
				UiKit.t("%s went down %d times in harness at %d%%. Rattling armor reads as %d base instead of %d — that is a commission, not a coaching problem.") % [
					m.card.display_name, m.times_downed, int(m.card.armor * 100.0),
					int(m.card.effective_base()), m.card.base,
				]))

	# --- the line: which position lost you the round
	var worst = null
	for m in sim.fought():
		if m.team != us:
			continue
		if worst == null or m.times_downed > worst.times_downed:
			worst = m
	if worst != null and worst.times_downed >= 2:
		out.append(Line.new(1,
			UiKit.t("Your %s went down %d times. That side of the line is where the round went.") % [
				worst.card.pos_name().to_lower(), worst.times_downed,
			]))

	# --- who did the work
	var top = null
	for m in sim.fought():
		if m.team != us:
			continue
		if top == null or m.downs_caused > top.downs_caused:
			top = m
	if top != null and top.downs_caused > 0:
		out.append(Line.new(0, UiKit.t("%s put %d on the ground.") % [
			top.card.display_name, top.downs_caused]))

	# --- and the small, honest note about how much you actually touched it
	out.append(Line.new(0,
		UiKit.t("You drew %d routes and answered %d of %d prompts. The rest of it was the club.") % [
			sim.orders_issued, sim.prompts_answered,
			sim.prompts_answered + sim.prompts_timed_out,
		]))
	return out


static func as_text(sim: MeleeSim) -> String:
	var parts: PackedStringArray = []
	for l in build(sim):
		parts.append(("! " if l.severity == 2 else ("- " if l.severity == 1 else "  ")) + l.text)
	return "\n".join(parts)
