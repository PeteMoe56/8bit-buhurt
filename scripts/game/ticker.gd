class_name Ticker
## THE LINE ALONG THE BOTTOM, and what goes on it.
##
## Pete, item 20 of the 15 Sep playtest: *"Definitely need a Ticker across the
## bottom full of humor and results."*
##
## ---------------------------------------------------------------------------
## RESULTS FIRST, JOKES SECOND, AND THE RATIO IS THE WHOLE DESIGN.
##
## A ticker of pure jokes is a screensaver — it says nothing, so after two
## minutes the eye stops going there and the space is wasted for the rest of the
## game. A ticker of pure results is a second league table, which the screen
## already has above it in a form that is easier to read.
##
## What makes the device work in the games that use it well is that it carries
## information the player CANNOT get anywhere else, with enough voice to be worth
## reading. So: the other clubs' results this week, who is going up and who is
## going down, what the federation is saying — and between them, the club
## secretary's own remarks about a sport fought in fifty kilos of steel.
##
## ---------------------------------------------------------------------------
## IT IS BUILT ONCE AN EVENT, NOT ONCE A FRAME.
##
## The line is a single string and the screen scrolls it by moving one x. Rebuilt
## every frame it would be thirty string joins a second for a thing that changes
## eight times a season, and a ticker is exactly the kind of decoration that ends
## up costing more than the fight.
##
## `for_season()` is the door. It is keyed on the season and the event number, so
## asking twice in one week gets the same line and asking after a result gets a
## new one.

## HOW MANY OF THE LINES ARE JOKES. One in four — enough that the voice is there
## and not so many that a player learns to skip it. Measured against nothing;
## this is a feel number and it is one constant.
const QUIP_EVERY: int = 4

## THE SEPARATOR, wide enough to read as a gap at speed.
const SEP := "     ·     "

## HOW FAST IT MOVES, in pixels a second. Slow enough to read a whole clause
## without tracking it, which is about the speed of a stadium board and roughly
## half the speed that feels right in an editor.
const SPEED: float = 34.0

## THE SECRETARY'S REMARKS.
##
## About the sport, the weather, the paperwork and the kit — never about the
## player's club by name, because a line that claims to know how your season is
## going and is wrong is worse than no line. The results carry the specifics.
const QUIPS: Array[String] = [
	"Reminder: the marshals will not pass a helm you have repaired with tape.",
	"Lost property at the last meet: two gauntlets, one boot, somebody's dog.",
	"The federation reminds clubs that a poleaxe is not a walking aid.",
	"Weigh-in is at eight. The scales do not care what your harness weighs.",
	"A fighter writes in to ask whether beard length counts as armor. It does not.",
	"Three clubs have now asked about fighting in the rain. You fight in the rain.",
	"The bar at the National Arena has run out of ice for the fourth year running.",
	"Somebody has painted their club's mark on the inside of their visor. Bold.",
	"A reminder that 'it was like that when I bought it' is not an inspection pass.",
	"The medical tent would like it known that they have seen enough thumbs.",
	"Club secretaries are asked to stop entering their dogs in the team photo.",
	"This week's longest bout ran eleven minutes. Both sides blamed the other.",
	"A fighter has asked if he may compete in a harness made of hockey pads. No.",
	"The federation's new rulebook is 94 pages. Page 3 is about parking.",
	"Somebody's mother has written in about the language at the last meet. Fair.",
]


## A TABLE ROW CARRIES A CLUB ID, NOT A NAME — the names live in `world.clubs`,
## which is the same road the table on screen takes. Two places turning an id
## into a name is two places that can disagree about who came second.
static func _club(season, row: Dictionary) -> String:
	var cid := int(row.get("club", -1))
	if cid < 0 or cid >= season.world.clubs.size():
		return UiKit.t("somebody")
	return String(season.world.clubs[cid]["name"])


## ONE LINE FOR THIS WEEK, results and remarks interleaved.
##
## `rows` is the division table as `Season.table()` gives it; `results` is the
## club's own log. Both are read rather than recomputed, so the ticker cannot
## disagree with the table sitting above it — which is the failure mode of every
## second view of the same data this project has built.
static func line_for(season) -> String:
	if season == null:
		return ""
	var parts: Array[String] = []
	var quip_at := 0

	## WHO IS TOP, and by how much. The table says the same thing in a column of
	## numbers; this says it in a sentence, which is the point of having both.
	var rows: Array = season.table()
	if rows.size() >= 2:
		var lead: Dictionary = rows[0]
		var second: Dictionary = rows[1]
		var gap: int = int(lead.get("points", 0)) - int(second.get("points", 0))
		if gap > 0:
			parts.append(UiKit.tn("%s lead the %s by %d point", "%s lead the %s by %d points", gap) % [
				_club(season, lead), season.tier_name(), gap])
		else:
			parts.append(UiKit.t("%s and %s are level at the top of the %s") % [
				_club(season, lead), _club(season, second), season.tier_name()])

	## AND WHO IS BOTTOM, because a player near the drop wants to know who is
	## under him and a player clear of it wants to know he is clear.
	if rows.size() >= 1:
		var last: Dictionary = rows[rows.size() - 1]
		parts.append(UiKit.t("%s prop up the table on %d") % [
			_club(season, last), int(last.get("points", 0))])

	## THE CLUB'S OWN LAST RESULT, told the way a results service would tell it
	## rather than the way the club's own screen does.
	var log_: Array = season.results
	if not log_.is_empty():
		var r: Dictionary = log_[log_.size() - 1]
		if not bool(r.get("bye", false)):
			var rf := int(r.get("rf", 0))
			var ra := int(r.get("ra", 0))
			var them := String(r.get("opponent_name", ""))
			if them == "" and int(r.get("opponent", -1)) >= 0:
				them = String(season.world.clubs[int(r["opponent"])]["name"])
			## Three whole sentences, not a verb dropped into one: the word order
			## around the verb is not English's in half the languages.
			var line := UiKit.t("%s beat %s %d-%d") if rf > ra else (
				UiKit.t("%s drew with %s %d-%d") if rf == ra else UiKit.t("%s lost to %s %d-%d"))
			parts.append(line % [season.club.display_name, them, rf, ra])

	## AND THE ODD REMARK. Deterministic on the season and the event, so the line
	## does not reshuffle itself every time the screen redraws — a ticker whose
	## jokes change while you are reading one is a ticker nobody finishes.
	var out: Array[String] = []
	var n := maxi(1, int(season.world.season) * 97 + log_.size() * 13)
	for i in parts.size():
		out.append(parts[i])
		quip_at += 1
		if quip_at >= QUIP_EVERY - 1:
			quip_at = 0
			out.append(UiKit.t(QUIPS[(n + i * 7) % QUIPS.size()]))
	if out.is_empty():
		out.append(UiKit.t(QUIPS[n % QUIPS.size()]))
	return SEP.join(out)


## WHERE THE LINE SITS THIS FRAME, given how long it is and how long the screen
## has been up. Wraps at the string's own width plus a gap, so it reads as a loop
## rather than as a thing that finishes and starts again.
static func offset(t: float, width: float, span: float) -> float:
	if width <= 0.0:
		return 0.0
	var loop := width + span
	return span - fmod(t * SPEED, loop)
