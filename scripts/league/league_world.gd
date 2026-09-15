class_name LeagueWorld
extends RefCounted
## The living pyramid: every club in the country, which division it is in, the
## fixture list, the tables, and what happens to all of it in the summer.
##
## Deterministic from a seed, no node dependencies, so a hundred seasons run
## headless in a test — which is the only way to catch a pyramid that leaks a
## club a year.
##
## ONLY THE PLAYER'S OWN BOUT IS SIMULATED IN FULL. Every other fixture in every
## division resolves on club rating. That is not a shortcut, it is the same
## division of labour every football manager makes and the one ACTM already
## makes in `meleeOddsBps`: the fight you are standing in gets the whole sim,
## and the other fourteen results are numbers on a page by Sunday night.

signal season_rolled(new_season: int)
signal club_promoted(club_id: int, to_tier: int)
signal club_relegated(club_id: int, to_tier: int)

## THE INVITATIONALS. ACRTW runs two named side-tournaments a season and only
## invites the player when he is National top-3. The shape is stolen whole; the
## gate is not, because this game starts you in the Backyard Circuit and the
## National rule would mean you never see a cup for seven seasons. Here it is
## the top three of YOUR OWN division — so a cup run is something a small club
## in a small league can still have, which is the entire appeal of a cup.
##
## `at` is a matchday: a positive number counts from the start of the season,
## a negative one from the end, so both land sensibly in a 5-event Backyard
## season and a 15-event National one.
##
## Named by Pete, 10 Sep 2026. ACRTW's own ("Apex, Not Apex", "Path of Acclaim")
## are its property and were not taken.
const INVITATIONALS := [
	{ "id": "kings_cup", "name": "Kings Cup", "at": 2 },
	{ "id": "path_of_honor", "name": "Path of Honor", "at": -2 },
]
const INVITATIONAL_FIELD: int = 8
const INVITE_RANK: int = 3              ## top three of your own division

## WORLDS. ACRTW runs 32 countries, eight pools of four, top two into a
## sixteen-club bracket. Sixteen clubs and four pools here — a quarter of the
## size, the same shape, and it fits a season you can finish on a phone.
const WORLDS_FIELD: int = 16
const WORLDS_HOME: int = 2              ## berths from the National Division

const DRAW_ROUND_CHANCE: float = 0.06
const RATING_SCALE: float = 22.0        ## a 22-point gap is about 90/10 on a round

var rng := RandomNumberGenerator.new()
var clubs: Array[Dictionary] = []
var player_club: int = 0
var season: int = 1
var event: int = 0                      ## which matchday of the season
var schedule: Dictionary = {}           ## tier -> Array[matchday] of [a, b] pairs
var tables: Dictionary = {}             ## tier -> { club_id: row }
var history: Array[Dictionary] = []

## Cups. Two Invitationals run inside the season and Worlds runs after it, both
## taken from ACRTW at Pete's instruction (10 Sep 2026). `cups` holds whatever
## is live right now; `honours` is the trophy cabinet.
var cups: Array = []
var worlds: Cup = null
var honours: Array[Dictionary] = []

## THE CLUB'S RECORD BOOK, and it has to live here rather than on a fighter.
##
## A man's book goes home with him when he retires; the club's does not. "Most
## downs in one afternoon" is the club's record whoever set it, and the whole
## point of a record is that it outlives the holder — so it is a name and a
## season written down at the moment it happened, not a live scan of the current
## roster. A scan would quietly lose every record a retired man ever set.
##
## key -> { "value": int, "holder": String, "season": int }
var records: Dictionary = {}

## THE HALL OF FAME, and it is the player's rather than the world's.
##
## `ui_PlayerHallOfFameEmpty`: *"To put players in your Hall of Fame you need to
## tag them in the top-left corner of their profile page."* Retro Bowl's version
## is a deliberate, manual act — you decide, while he is still playing, that this
## man mattered — and that is the whole reason it lands. A hall of fame the game
## fills in for you by rating is a leaderboard.
##
## `records` is the world's: the biggest afternoon anybody ever had, held
## automatically. This is the opposite and they are both worth having.
const HOF_MAX: int = 12
var hall: Array[Dictionary] = []


func in_hall(nm: String) -> bool:
	for h in hall:
		if String(h.get("name", "")) == nm:
			return true
	return false


## TAGGED WHILE HE IS STILL PLAYING. The card is copied rather than referenced,
## because the man goes on ageing, declining and eventually retiring, and the
## point of the hall is what he WAS.
func tag_for_hall(f: FighterCard, at_season: int) -> String:
	if in_hall(f.display_name):
		return "%s is already in it." % f.display_name
	if hall.size() >= HOF_MAX:
		return "There is no room. Take somebody out first."
	hall.append({
		"name": f.display_name, "pos": f.pos_name(), "rating": f.overall(),
		"age": f.age, "season": at_season, "bouts": f.bouts, "downs": f.downs,
		"honours": f.honours,
	})
	return ""


func untag_from_hall(nm: String) -> void:
	for i in hall.size():
		if String(hall[i].get("name", "")) == nm:
			hall.remove_at(i)
			return


## Keep it if it beats what is there. Returns true when the book changed, so a
## screen can say so.
func note_record(key: String, value: int, holder: String, at_season: int) -> bool:
	if value <= 0:
		return false
	var cur: Dictionary = records.get(key, {})
	if not cur.is_empty() and int(cur.get("value", 0)) >= value:
		return false
	records[key] = {"value": value, "holder": holder, "season": at_season}
	return true


func _init(seed_value: int = 0, player_power: int = 42,
		region_: int = Cities.Region.US) -> void:
	rng.seed = seed_value
	## BEFORE THE PYRAMID, because the pyramid names forty-six clubs out of the
	## region's own city list and a region set afterwards would be a world full of
	## American clubs with a European flag on it.
	region = region_
	_build_pyramid(player_power)
	_new_season()


# ------------------------------------------------------------------- setup
## WHERE EVERY CLUB IS — `Cities`, and a region the whole world shares.
##
## This was `FIRST`, forty-six invented place names used as the first word of a
## club's name, and Pete replaced it with the real map: *"Let's go with real US
## cities so they can have a radius with the 'homesick'."* The invented names
## worked and could not carry a distance, which is what turned one trait into a
## road trip.
##
## THE REGION IS A PROPERTY OF THE WORLD, not of the player's club. Picking
## Europe generates a European league — a pyramid whose clubs are four thousand
## miles apart is not a pyramid, it is a travel budget.
var region: int = Cities.Region.US

const SECOND := [
	"Free Company", "Companions", "Guard", "Club", "Fellowship", "Retinue",
	"Household", "Brotherhood", "Company", "Chapter",
]


## Your club, and the reason its first word is reserved below.
## THE DEFAULT, which a player replaces at the picker before he ever sees it —
## it exists for the standalone bout and for a save built without going through
## the title screen.
const PLAYER_NAME := "Detroit Free Company"
const PLAYER_SHORT := "DFC"


func _build_pyramid(player_power: int) -> void:
	clubs.clear()
	var used: Dictionary = {}
	## Reserve your own city BEFORE anybody else is named. Club 0 is renamed
	## after the loop, and the default name is on the city list — so it could
	## and did hand the identical name to another club, which put two rows called
	## "Cross Timbers Free Company" on the National Division table. Invisible to
	## every headless check; obvious the first time the screen was drawn.
	## Match against the city list rather than splitting on a space: the entries
	## list are not all one word — "Cross Timbers" is one of them — so splitting
	## reserved "Cross", matched nothing, and let the duplicate straight through.
	for entry in Cities.names(region):
		if PLAYER_NAME.begins_with(String(entry) + " "):
			used[entry] = true
			break
	var id := 0
	for t in League.TIERS.size():
		var band: Array = League.TIERS[t]["power"]
		for i in League.club_count(t):
			var nm := _unique_name(used)
			clubs.append({
				"id": id,
				"name": nm,
				"short": _short_of(nm),
				## WHERE THEY ARE FROM, stored rather than derived. It is the
				## first word of the name today and it must not be the first word
				## of the name tomorrow: a club that relocates keeps its name, and
				## a name the player types by hand has no city in it at all.
				"city": _city_of(nm),
				"tier": t,
				"power": rng.randi_range(int(band[0]), int(band[1])),
				"titles": 0,
			})
			id += 1
	## You start at the bottom, because the pyramid only means anything if the
	## climb is the game.
	player_club = 0
	clubs[player_club]["name"] = PLAYER_NAME
	clubs[player_club]["short"] = PLAYER_SHORT
	clubs[player_club]["tier"] = League.Tier.BACKYARD
	clubs[player_club]["power"] = player_power
	clubs[player_club]["city"] = _city_of(PLAYER_NAME)


## The FIRST word has to be unique, not just the whole name. Two clubs called
## "Harrow Brotherhood" and "Harrow Retinue" in a six-club division read as a
## bug on the table screen even though nothing is wrong — a player scanning for
## his own row should never have to read the second word.
func _unique_name(used: Dictionary) -> String:
	for _try in 400:
		var pool := Cities.names(region)
		var first: String = pool[rng.randi() % pool.size()]
		if used.has(first):
			continue
		used[first] = true
		return "%s %s" % [first, SECOND[rng.randi() % SECOND.size()]]
	return "Club %d" % used.size()


## The city out of a generated name — the longest city on either map the name
## begins with. LONGEST, because "Cross Timbers" and "Cross" could both be on the
## list one day and a prefix match that stops at the first hit would put the club
## in the wrong town.
static func _city_of(nm: String) -> String:
	var best := ""
	for r in [Cities.Region.US, Cities.Region.EU]:
		for entry in Cities.names(r):
			var e := String(entry)
			if nm.begins_with(e) and e.length() > best.length():
				best = e
	## EMPTY WHEN THE NAME IS NOT A TOWN'S, and that matters: `_move_club` renames
	## a club only when its name begins with the town it is leaving, and a
	## fallback guess of "Bonk" out of "Bonk Works" made that rule fire on a name
	## the player had chosen. A guess that is indistinguishable from an answer is
	## worse than no answer.
	return best


## WHERE A CLUB PLAYS, for any id. Falls back to the first word for a save that
## predates cities and for a club the player renamed by hand.
func city_of(id: int) -> String:
	if id < 0 or id >= clubs.size():
		return ""
	var c: Dictionary = clubs[id]
	var city := String(c.get("city", ""))
	if city != "":
		return city
	## A save from before cities existed. The name is the only clue, and the first
	## word is the display fallback when it is not a town on either map — better a
	## screen that says "Bonk" than one with a blank where a town goes.
	var guess := _city_of(String(c["name"]))
	return guess if guess != "" else String(c["name"]).split(" ")[0]


## THE PLAYER TAKES A TOWN, and whoever was in it takes his.
##
## A SWAP AND NOT A CLAIM. Forty-six cities and forty-six clubs means every town
## is somebody's, so "pick any city" has to either rename one club out of
## existence or trade. Trading keeps the map full, keeps every generated club
## somewhere real, and costs one line: the club that held Harrow moves to Cross
## Timbers and is renamed to match. Nothing is lost and nothing is duplicated,
## which a claim-and-rename could not promise.
##
## The SECOND word is kept on both sides. A brotherhood that relocates is still a
## brotherhood.
func take_city_for_player(city: String) -> String:
	if city == "" or Cities.find(city).is_empty():
		return "No such town."
	var mine := city_of(player_club)
	if city == mine:
		return ""
	for c in clubs:
		if int(c["id"]) == player_club:
			continue
		if city_of(int(c["id"])) != city:
			continue
		_move_club(int(c["id"]), mine)
		break
	_move_club(player_club, city)
	return ""


## Put a club in a town and rename it to match, keeping whatever it is called
## after the city. A club whose name does not start with its old city — the
## player has typed his own — keeps the name and just changes towns, because
## rewriting a name somebody chose is not a thing a relocation should do.
func _move_club(id: int, city: String) -> void:
	var c: Dictionary = clubs[id]
	var old_city := city_of(id)
	c["city"] = city
	var nm := String(c["name"])
	if old_city != "" and nm.begins_with(old_city):
		c["name"] = city + nm.substr(old_city.length())
		c["short"] = _short_of(String(c["name"]))


## Every city nobody has taken, for the setup screen's picker.
func free_cities() -> Array[String]:
	var taken := {}
	for c in clubs:
		taken[city_of(int(c["id"]))] = true
	var out: Array[String] = []
	for entry in Cities.names(region):
		if not taken.has(String(entry)):
			out.append(String(entry))
	return out


## HOW FAR ONE CLUB IS FROM ANOTHER, in miles — the figure Homesick reads and the
## splash prints. Asked of the world rather than of `Cities` directly, because
## the world is the thing that knows which town each id is in.
func miles_between(a: int, b: int) -> float:
	return Cities.distance(city_of(a), city_of(b))


func _short_of(nm: String) -> String:
	var parts := nm.split(" ")
	var s := ""
	for p in parts:
		if p.length() > 0:
			s += p.substr(0, 1).to_upper()
	return s.substr(0, 3)


func clubs_in(t: int) -> Array:
	var out: Array = []
	for c in clubs:
		if int(c["tier"]) == t:
			out.append(int(c["id"]))
	return out


func club(id: int) -> Dictionary:
	return clubs[id]


func player_tier() -> int:
	return int(clubs[player_club]["tier"])


# ------------------------------------------------------------------ season
func _new_season() -> void:
	event = 0
	schedule.clear()
	tables.clear()
	for t in League.TIERS.size():
		var ids := clubs_in(t)
		## Array.shuffle() draws on the GLOBAL RNG, which would make the whole
		## world non-reproducible from its seed. Fisher-Yates on our own stream.
		for i in range(ids.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = ids[i]
			ids[i] = ids[j]
			ids[j] = tmp
		schedule[t] = League.fixtures(ids)
		var tbl: Dictionary = {}
		for cid in ids:
			## Lots are drawn fresh every season, so a club that loses a tiebreak
			## in May is not doomed to lose it again next year.
			tbl[cid] = League.new_row(cid, rng.randi_range(0, 1_000_000))
		tables[t] = tbl


func events_this_season() -> int:
	return League.events_in_season(player_tier())


func season_complete() -> bool:
	var days: Array = schedule[player_tier()]
	return event >= days.size()


## Who you are drawn against on the current matchday, or -1 for a bye.
## DOES HE HOST THIS ONE? The pair is `[host, visitor]` — see `League.fixtures`.
## A club with no fixture this matchday is not at home; it is nowhere.
func player_hosts() -> bool:
	var days: Array = schedule[player_tier()]
	if event >= days.size():
		return false
	for pair in days[event]:
		if int(pair[0]) == player_club or int(pair[1]) == player_club:
			return League.host_of(pair) == player_club
	return false


func player_opponent() -> int:
	var days: Array = schedule[player_tier()]
	if event >= days.size():
		return -1
	for pair in days[event]:
		if int(pair[0]) == player_club:
			return int(pair[1])
		if int(pair[1]) == player_club:
			return int(pair[0])
	return -1


## Resolve the whole matchday. `player_rounds` is the real result of the bout you
## just fought; pass null and the player's fixture is resolved on rating like
## everyone else's, which is what the auto-play path and the soak test do.
func play_event(player_rounds = null) -> void:
	for t in League.TIERS.size():
		var days: Array = schedule[t]
		if event >= days.size():
			continue
		for pair in days[event]:
			var a := int(pair[0])
			var b := int(pair[1])
			var res: Array
			if player_rounds != null and (a == player_club or b == player_club):
				## [rounds_a, rounds_b, margin_a, margin_b] — the same four numbers
				## MeleeSim carries out of a real bout, so a fought fixture and a
				## simulated one enter the table through exactly one shape.
				var pr: Array = _four(player_rounds)
				res = pr if a == player_club else [pr[1], pr[0], pr[3], pr[2]]
			else:
				res = quick_bout(int(clubs[a]["power"]), int(clubs[b]["power"]))
			var ma: int = int(res[2]) if res.size() > 2 else 0
			var mb: int = int(res[3]) if res.size() > 3 else 0
			League.apply_result(tables[t][a], res[0], res[1], ma, mb)
			League.apply_result(tables[t][b], res[1], res[0], mb, ma)
	event += 1
	_open_due_invitationals()


## A bout resolved on rating alone: best of three rounds, and a round can be
## drawn because a real one can — the clock runs out with both sides level.
## Returns [rounds_a, rounds_b, margin_a, margin_b].
##
## The margin distribution is lifted from the real sim rather than invented:
## across 393 measured rounds the endings run 5-1 far more than anything else,
## then 4-1, then 3-1, with the tight ones rare. A stronger club also wins
## bigger, so the gap shifts the draw.
const MARGIN_WEIGHTS := [8, 14, 26, 52]     ## margins 1, 2, 3, 4

func quick_bout(pa: int, pb: int) -> Array:
	## Elo, and mind the sign. This read `/ -RATING_SCALE` at first, which inverts
	## it: the stronger club got the LOWER chance, so a 40-power side floated up
	## to the National Division and a 90-power one could not get out of the
	## Backyard Circuit. Both climb tests caught it, from opposite directions.
	var p := 1.0 / (1.0 + pow(10.0, float(pb - pa) / RATING_SCALE))
	var ra := 0
	var rb := 0
	var ma := 0
	var mb := 0
	for _r in 3:
		if ra >= 2 or rb >= 2:
			break
		if rng.randf() < DRAW_ROUND_CHANCE:
			continue                  ## a drawn round scores for nobody
		if rng.randf() < p:
			ra += 1
			ma += _draw_margin(p)
		else:
			rb += 1
			mb += _draw_margin(1.0 - p)
	return [ra, rb, ma, mb]


## How convincingly a round was won. `edge` is the winner's per-round chance, so
## a mismatch produces bigger margins than a coin flip does.
func _draw_margin(edge: float) -> int:
	var w := MARGIN_WEIGHTS.duplicate()
	var tilt := clampf((edge - 0.5) * 2.0, -1.0, 1.0)
	w[3] = int(maxf(1.0, float(w[3]) * (1.0 + tilt * 0.6)))
	w[0] = int(maxf(1.0, float(w[0]) * (1.0 - tilt * 0.6)))
	var total := 0
	for x in w:
		total += int(x)
	var r := rng.randi_range(0, total - 1)
	for i in w.size():
		r -= int(w[i])
		if r < 0:
			return i + 1
	return 4


## ONE CLUB'S LINE, WON-DRAWN-LOST, for any id in any division — the splash
## needs both clubs' records and only one of them is ever the player's.
func record_of(id: int) -> Dictionary:
	if id < 0 or id >= clubs.size():
		return League.new_row(id)
	var t := int(clubs[id]["tier"])
	if t < 0 or not tables.has(t) or not (tables[t] as Dictionary).has(id):
		return League.new_row(id)
	return tables[t][id]


## And the same line as a person would say it.
func record_line(id: int) -> String:
	var r := record_of(id)
	return "%d - %d - %d" % [int(r["won"]), int(r["drawn"]), int(r["lost"])]


func table(t: int) -> Array:
	var rows: Array = []
	for cid in tables[t]:
		rows.append(tables[t][cid])
	return League.sort_table(rows)


func player_position() -> int:
	var rows := table(player_tier())
	for i in rows.size():
		if int(rows[i]["club"]) == player_club:
			return i + 1
	return -1


# ---------------------------------------------------------------- roll over
## The summer. Promotions and relegations resolve top-down, every club's rating
## drifts, and the fixture list is rebuilt.
## Every bracket still open when the year ends, decided and recorded. The hold
## that keeps the player's own ties waiting during a season does not apply —
## there is no next matchday to ask him on.
func _close_the_season_cups() -> void:
	var resolver := cup_resolver()
	for c in cups:
		c.run_all(resolver)
		_record_honours(c)
	cups.clear()
	if worlds != null:
		worlds.run_all(resolver)
		_record_honours(worlds)
		worlds = null


func roll_over() -> void:
	## Snapshot the player's season BEFORE anybody moves. Reading it afterwards
	## looks him up in the table of a division he has just been promoted out of,
	## which is an outright crash the moment he first goes up.
	var finished_tier := player_tier()
	var finished_pos := player_position()
	var finished_row: Dictionary = (tables[finished_tier][player_club] as Dictionary).duplicate()

	## A BRACKET DOES NOT SURVIVE THE SUMMER.
	##
	## `auto_resolve_cups` holds any cup the player is still alive in, which is
	## right during a season — he owes those results and the game asks him for
	## them. It is wrong at the roll over: the season those ties belonged to is
	## gone, and a held bracket carried into the next year is a cup from last
	## season still asking for a fixture.
	##
	## Nothing resolved them. `test_season.gd` has asserted *"the cups resolved
	## rather than left hanging"* since it was written and passed on a world where
	## the player happened to be knocked out of enough of them; the moment the
	## city list changed the generated world by two names, the same seed kept him
	## in both and the check failed. **A check that passes because of what the
	## world happened to do is a check waiting for the world to do something
	## else.**
	##
	## Decided on rating, the player's own ties included. He did not play them and
	## the year is over; that is what a forfeit is.
	_close_the_season_cups()

	## Worlds is fought on the season that has just finished, so it is built
	## from the National table BEFORE anybody is promoted out of it. The line
	## above has already retired last year's.
	worlds = _build_worlds(table(League.Tier.NATIONAL))

	var moves_up: Dictionary = {}
	var moves_down: Dictionary = {}
	for t in League.TIERS.size():
		var rows := table(t)
		for cid in League.promoted(t, rows):
			if t < League.TIERS.size() - 1:
				moves_up[cid] = t + 1
		for cid in League.relegated(t, rows):
			if t > 0:
				moves_down[cid] = t - 1

	for cid in moves_up:
		clubs[cid]["tier"] = int(moves_up[cid])
		club_promoted.emit(int(cid), int(moves_up[cid]))
	for cid in moves_down:
		clubs[cid]["tier"] = int(moves_down[cid])
		club_relegated.emit(int(cid), int(moves_down[cid]))

	## The champion of the top flight gets the title on the board.
	var top := table(League.TIERS.size() - 1)
	if not top.is_empty():
		clubs[int(top[0]["club"])]["titles"] = int(clubs[int(top[0]["club"])]["titles"]) + 1

	history.append({
		"season": season,
		"tier": finished_tier,
		"position": finished_pos,
		"promoted": player_tier() > finished_tier,
		"relegated": player_tier() < finished_tier,
		"row": finished_row,
	})

	## The cups clear before the ratings drift, so a champion is a champion of
	## the season he actually fought, and the Worlds guests go back where
	## they came from.
	auto_resolve_cups()
	_clear_guests()
	_drift_ratings()
	season += 1
	_new_season()
	season_rolled.emit(season)


## Clubs are not statues. A promoted side that does not strengthen goes straight
## back down, which is the most football thing this system does.
func _drift_ratings() -> void:
	for c in clubs:
		if int(c["id"]) == player_club:
			continue          ## yours moves with your roster, not with a die
		var band: Array = League.TIERS[int(c["tier"])]["power"]
		var lo := int(band[0]) - 6
		var hi := int(band[1]) + 6
		var drift := rng.randi_range(-3, 3)
		## A club that has just gone up or come down converges toward its new
		## division rather than snapping to it.
		var mid := float(int(band[0]) + int(band[1])) * 0.5
		var pull := int(round((mid - float(c["power"])) * 0.25))
		c["power"] = clampi(int(c["power"]) + drift + pull, lo, hi)


func set_player_power(p: int) -> void:
	clubs[player_club]["power"] = p


## YOUR RATING IS YOUR CLUB. Pete, 10 Sep 2026: "Club power should be your club
## power, not the starter levels."
##
## `sync_player_power(club)` used to live here and did exactly what
## `Season.sync_power()` does on its own line 297 — read `club.power()` and hand
## it to `set_player_power()`. Two functions, one job, 23 callers on one and
## none on the other. Deleted 15 Sep 2026 rather than left as a second way to
## do the thing: **two functions that must agree are a pair that will stop
## agreeing**, and this one had already been wrong for as long as it existed
## because nothing kept it in step with the travel-cap line the real one runs
## first.


## Accept [ra, rb] or [ra, rb, ma, mb] and always hand back four numbers.
static func _four(r) -> Array:
	var a := int(r[0])
	var b := int(r[1])
	var ma := int(r[2]) if r.size() > 2 else 0
	var mb := int(r[3]) if r.size() > 3 else 0
	return [a, b, ma, mb]


# ------------------------------------------------------------------ the cups
## The matchday an Invitational falls on, resolved against the player's own
## division — a negative `at` counts back from the last event of the season.
func _invitational_event(spec: Dictionary) -> int:
	var n := League.events_in_season(player_tier())
	var at := int(spec["at"])
	return at if at >= 0 else maxi(1, n + at)


## Are you inside the top three of your own division right now?
## THE FEDERATION'S VETO, injected rather than read.
##
## `LeagueWorld` knows about tables, fixtures and brackets. It has never known
## about the club's paperwork and it must not start: the whole reason this file
## can be soak-tested for a hundred seasons is that it has no opinion about the
## player's office. So the Season pushes the answer down here, the same way it
## pushes the player's power and the AI tiers into the melee.
##
## Null means nobody has said — every existing test, probe and soak run leaves it
## that way and behaves exactly as it always did.
var cup_entry_barred: bool = false


## GATED ON RESULTS **AND** COMPLIANCE. DIRECTION §4: *"The federation gates
## nationals and Worlds on results and compliance."* The results half is the
## division position; the compliance half is the club's certificates, and being
## good at the sport does not excuse you from it.
func invited() -> bool:
	if cup_entry_barred:
		return false
	var pos := player_position()
	return pos != -1 and pos <= INVITE_RANK


func _open_due_invitationals() -> void:
	for spec in INVITATIONALS:
		if event != _invitational_event(spec):
			continue
		if _cup_run(String(spec["id"])):
			continue
		var c := _build_invitational(spec)
		cups.append(c)


func _cup_run(id: String) -> bool:
	for c in cups:
		if String(c.get_meta("id", "")) == id:
			return true
	for h in honours:
		if String(h.get("id", "")) == id and int(h.get("season", -1)) == season:
			return true
	return false


## The field: you if you have earned it, then the strongest clubs in the country
## that are also in the top three of their own division. A cup that just invited
## the eight biggest ratings would be the National Division again with a trophy.
func _build_invitational(spec: Dictionary) -> Cup:
	var pool: Array = []
	for t in League.TIERS.size():
		var rows := table(t)
		for i in mini(INVITE_RANK, rows.size()):
			pool.append(int(rows[i]["club"]))
	pool.sort_custom(func(a, b): return int(clubs[a]["power"]) > int(clubs[b]["power"]))

	var field: Array = []
	var me := invited()
	if me:
		field.append(player_club)
	for cid in pool:
		if field.size() >= INVITATIONAL_FIELD:
			break
		if cid != player_club:
			field.append(cid)
	## Seed by power, so the bracket's 1-v-8 means something.
	field.sort_custom(func(a, b): return int(clubs[a]["power"]) > int(clubs[b]["power"]))

	var c := Cup.new(String(spec["name"]), field,
		int(rng.randi()), player_club if me else -1, false)
	c.set_meta("id", String(spec["id"]))
	return c


## WORLDS. The National Division's top two carry the country; the other fourteen
## are invited from abroad and are rated off the top flight's own band, so a
## Worlds berth is not a victory lap.
func _build_worlds(national_rows: Array) -> Cup:
	var field: Array = []
	for i in mini(WORLDS_HOME, national_rows.size()):
		field.append(int(national_rows[i]["club"]))
	## Guests are not clubs on the pyramid — they exist for this tournament only,
	## with ids past the end of the club list, which keeps them out of every
	## table and every promotion in the country.
	var guest_id := clubs.size()
	while field.size() < WORLDS_FIELD:
		var band: Array = League.TIERS[League.Tier.NATIONAL]["power"]
		clubs.append({
			"id": guest_id,
			"name": "%s %s" % [Cities.names(region)[rng.randi() % Cities.names(region).size()],
				SECOND[rng.randi() % SECOND.size()]],
			"short": "GST",
			"tier": -1,                 ## no division; a guest is not in the pyramid
			"power": rng.randi_range(int(band[0]) + 4, int(band[1]) + 8),
			"titles": 0,
			"guest": true,
		})
		field.append(guest_id)
		guest_id += 1
	field.sort_custom(func(a, b): return int(clubs[a]["power"]) > int(clubs[b]["power"]))
	## AND THE SAME VETO ON THE WORLDS. Finishing top four of the National
	## Division earns the place; the federation is what lets you take it. A club
	## barred from entry is dropped from the field and a guest takes the spot,
	## which is what actually happens when a club cannot produce its paperwork.
	if cup_entry_barred and field.has(player_club):
		field.erase(player_club)
		var band2: Array = League.TIERS[League.Tier.NATIONAL]["power"]
		clubs.append({
			"id": clubs.size(), "short": "GST", "tier": -1, "titles": 0, "guest": true,
			"name": "%s %s" % [Cities.names(region)[rng.randi() % Cities.names(region).size()],
				SECOND[rng.randi() % SECOND.size()]],
			"power": rng.randi_range(int(band2[0]) + 4, int(band2[1]) + 8),
		})
		field.append(clubs.size() - 1)
	var me: int = player_club if field.has(player_club) else -1
	var c := Cup.new("Worlds", field, int(rng.randi()), me, true)
	c.set_meta("id", "worlds")
	return c


## WHEN TRUE, a cup the player is still alive in is left alone rather than
## resolved on paper. A real Season sets this; the soak tests and the auto-play
## path leave it false and every cup resolves itself exactly as it always did.
##
## This is the whole reason `Cup.player_match()` sat orphaned from the day the
## cups were built: there was nowhere for it to be called from, because the
## world resolved every bracket before anybody could be asked about it.
var hold_player_cups: bool = false


func cup_resolver() -> Callable:
	return func(a: int, b: int) -> Array:
		return quick_bout(int(clubs[a]["power"]), int(clubs[b]["power"]))


## Resolve every cup match on rating. The game layer holds the player's own and
## calls Cup.sim_others instead; this is the auto-play and soak-test path.
func auto_resolve_cups() -> void:
	var resolver := cup_resolver()
	var held: Array = []
	for c in cups:
		if hold_player_cups and c.player_alive():
			held.append(c)
			continue
		c.run_all(resolver)
		_record_honours(c)
	cups = held
	if worlds != null and not (hold_player_cups and worlds.player_alive()):
		worlds.run_all(resolver)
		_record_honours(worlds)
		worlds = null


## Everything the player still owes a result in, in the order he should be asked
## for them: the domestic cups first, the Worlds last.
func open_cups() -> Array:
	var out: Array = []
	for c in cups:
		if c.player_alive():
			out.append(c)
	if worlds != null and worlds.player_alive():
		out.append(worlds)
	return out


## A cup that is over gets its honours recorded and gets out of the way. Called
## after the player finishes a round rather than on a timer, so a bracket cannot
## sit completed and still be asked for a fixture.
func retire_cup(c: Cup) -> void:
	if not c.is_over():
		return
	_record_honours(c)
	var i := cups.find(c)
	if i != -1:
		cups.remove_at(i)
	if c == worlds:
		worlds = null
		## Held over the summer, so the guests are still here. Now they can go.
		_clear_guests()


func _record_honours(c: Cup) -> void:
	if not c.is_over():
		return
	if c.champion >= 0 and c.champion < clubs.size():
		clubs[c.champion]["titles"] = int(clubs[c.champion]["titles"]) + 1
	honours.append({
		"id": String(c.get_meta("id", "")),
		"name": c.cup_name,
		"season": season,
		"champion": c.champion,
		"runner_up": c.runner_up,
		"player": c.finish_label(),
		## The same run as a number, so the coach's reputation and the label on
		## the cabinet are two readings of one walk rather than two walks.
		"exit": c.player_exit_size(),
	})


## Guests only exist for one Worlds. Leaving them on the books would grow the
## club list by fourteen a year forever, and a stray tier of -1 is exactly the
## kind of thing that survives until somebody iterates the pyramid.
## Send the Worlds guests home. **NOT WHILE A WORLDS IS STILL BEING FOUGHT.**
##
## Once the player could hold a cup over the summer (22), roll-over went on
## clearing the guests while a held Worlds bracket still named them — so the next
## season asked him to fight club 55, which no longer existed, and the whole run
## fell over on an out-of-bounds. The guests now leave when the bracket that
## invited them is finished, which is `retire_cup`.
func _clear_guests() -> void:
	if worlds != null:
		return
	while not clubs.is_empty() and bool(clubs[clubs.size() - 1].get("guest", false)):
		clubs.pop_back()
