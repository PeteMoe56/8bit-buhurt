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
## WHEN THEY ARE FOUGHT is `Calendar.CUP_ROUNDS` since 30 Sep 2026 — a round a
## week, on Saturdays of their own. `at` is the old single matchday, kept only as
## a note of where each one used to sit (2 = early, -2 = late).
##
## Named by Pete, 10 Sep 2026. ACRTW's own ("Apex, Not Apex", "Path of Acclaim")
## are its property and were not taken.
const INVITATIONALS := [
	{ "id": "kings_cup", "name": "Kings Cup", "at": 2 },
	{ "id": "path_of_honor", "name": "Path of Honor", "at": -2 },
]

## THREE SETS OF INVITATIONALS, BY LEVEL (Pete, 1 Oct 2026): *"Bottom 2 leagues
## fight at the least competitive invitationals, something in-region. Mid tier
## leagues fighting Mid-Tier invitationals, something in Canada/Mexico/US, and
## Top Tier fighting these current invitationals, and in High profile cities in
## Europe."* It had been one pair for the whole pyramid, filled by rating, so a
## Backyard club good enough to be invited drew the National Division's best
## (register 09.10, a recommendation of mine that was never put to him).
##
## `tiers` are the divisions a set invites from. `where` picks the host city:
## near the player for the local set, North America abroad (or continental
## Europe in a European world) for the middle, Europe's big cities for the top.
## The middle and top fill their field with clubs from abroad, as the Worlds
## does. Two a season each, one early and one late — `slot` 0 and 1.
const INVITATIONAL_SETS := [
	{ "id": "local", "tiers": [0, 1], "where": "local" },
	{ "id": "continental", "tiers": [2], "where": "continental" },
	{ "id": "elite", "tiers": [3], "where": "elite" },
]
## The top set's host cities. Real buhurt country, and somewhere worth the trip.
const ELITE_CITIES := ["Paris", "London", "Rome", "Barcelona", "Prague", "Krakow", "Budapest", "Vienna"]
const CONTINENTAL_US := ["Toronto", "Montreal", "Vancouver", "Mexico City", "Monterrey", "Chicago", "Denver"]
const CONTINENTAL_EU := ["Berlin", "Madrid", "Warsaw", "Milan", "Stockholm", "Brussels", "Lisbon"]
const INVITATIONAL_FIELD: int = 8
const INVITE_RANK: int = 3              ## top three of your own division

## WORLDS. ACRTW runs 32 countries, eight pools of four, top two into a
## sixteen-club bracket. Sixteen clubs and four pools here — a quarter of the
## size, the same shape, and it fits a season you can finish on a phone.
const WORLDS_FIELD: int = 16
## ONE BERTH: the National champion goes as the country's team (Pete, 1 Oct:
## "a 'bestowing' of the Team USA title and Tabard for Worlds"). It was two.
const WORLDS_HOME: int = 1

const DRAW_ROUND_CHANCE: float = 0.06
const RATING_SCALE: float = 22.0        ## a 22-point gap is about 90/10 on a round

var rng := RandomNumberGenerator.new()
var clubs: Array[Dictionary] = []
var player_club: int = 0
var season: int = 1
var event: int = 0                      ## which matchday of the season
var schedule: Dictionary = {}           ## tier -> Array[matchday] of [a, b] pairs
## THE WEEKS (30 Sep 2026) — see `Calendar`. `event` still counts the player's
## league days; `week` counts Saturdays, and a cup round is a Saturday too.
var calendar: Array = []
var week: int = 0
## How many league days each division has played. The player's is `event`; the
## others are paced to it so every table finishes on the same Saturday.
var days_played: Dictionary = {}
## Each division's playoff final, once it is fought: tier -> [champion, runner-up].
var finalists: Dictionary = {}
## THE COUNTRY'S NAME ON THE PLAYER'S CLUB at this year's Worlds, once the
## tabard is handed over ("" otherwise). See `SendOff`.
var team_title: String = ""
var tables: Dictionary = {}             ## tier -> { club_id: row }
var history: Array[Dictionary] = []

## Cups. Two Invitationals run inside the season and Worlds runs after it, both
## taken from ACRTW at Pete's instruction (10 Sep 2026). `cups` holds whatever
## is live right now; `honors` is the trophy cabinet.
var cups: Array = []
var worlds: Cup = null
var honors: Array[Dictionary] = []

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
		return UiKit.t("%s is already in it.") % f.display_name
	if hall.size() >= HOF_MAX:
		return UiKit.t("There is no room. Take somebody out first.")
	hall.append({
		"name": f.display_name, "pos": String(Tuning.POS_NAME[f.pos]), "rating": f.overall(),
		"age": f.age, "season": at_season, "bouts": f.bouts, "downs": f.downs,
		"honors": f.honors,
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

## TWENTY-EIGHT, not ten (playtest 30 Sep: "Everyone is Free Company"). Ten
## words over a hundred-odd clubs put each one on a dozen of them; the real
## sport's clubs are called after animals, metal and oaths as often as after
## companies, so the pool is too.
const SECOND := [
	"Free Company", "Companions", "Guard", "Club", "Fellowship", "Retinue",
	"Household", "Brotherhood", "Company", "Chapter",
	"Wolves", "Bears", "Boars", "Stags", "Ravens", "Griffins", "Lions", "Hounds",
	"Knights", "Wardens", "Vanguard", "Legion", "Banner", "Shieldwall",
	"Ironclad", "Hammers", "Steel", "Order",
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
		var pool := Cities.league_names(region)
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


## ------------------------------------------------------------ their grounds
## EVERY CLUB HAS A GROUND NOW, and until 15 Sep 2026 exactly one did.
##
## Pete, 15 Sep 2026: *"Money from matches is manipulated by condition of arena,
## so you may actually look forward to an opponent with a great stadium or roll
## your eyes from an opponent with a shitty arena."*
##
## That sentence needs the other fifteen clubs in your division to HAVE arenas,
## and they did not: a CPU club is a name, a town, a tier and a `power` integer.
## `tools/probe_kit.gd` found the same hole about harnesses in September — the
## player was the only club in the world paying the wear tax — and this is the
## same shape, one system over.
##
## ---------------------------------------------------------------------------
## DERIVED, NOT STORED, AND THAT IS THE WHOLE TRICK.
##
## Storing a level and a condition on sixteen clubs a division across four
## divisions means fifty-six more numbers in every save, a migration, and a
## per-club upkeep economy nobody will ever see. Deriving them from the club's id
## costs nothing, cannot go stale, and is stable the way a real ground is stable:
## the club in Holt has the ground it has, and you learn it.
##
##   LEVEL is keyed on the id and the club's CURRENT tier, so a club that gets
##   promoted arrives with a better ground — which is the same rule the player
##   lives under, and it means the fixture list gets richer as you climb rather
##   than the away days all looking the same.
##
##   CONDITION is keyed on the id and the SEASON, so it drifts year to year. A
##   club that was a tip last year may have cleaned up. This is the part that
##   makes an away day worth reading about instead of a coin flip you cannot see.
##
## THE PLAYER'S OWN CLUB IS THE EXCEPTION and has to be: his ground is a thing he
## bought and keeps, not a hash. `Season.ground_of()` is the door that knows
## that; this function answers for everybody else and says so.
const GROUND_SALT: int = 0x51C3B7


## A CPU CLUB'S GROUND: `{"level": int, "condition": float}`.
##
## THE SPREAD WITHIN A TIER IS THE POINT. A division where every club has the
## same ground is a division where the mechanic is a constant, so a tier's clubs
## are spread across the levels that tier can hold — a Regional division has
## clubs still in a fenced ground and clubs in a full arena, and the fixture list
## is worth reading because of it.
func ground_of(id: int) -> Dictionary:
	if id < 0 or id >= clubs.size():
		return {"level": 0, "condition": 1.0}
	var c: Dictionary = clubs[id]
	var tier := int(c.get("tier", 0))
	## THE BEST GROUND THIS TIER CAN HOLD, off the arena's own table rather than
	## off a second ladder here — `Arena.LEVELS` says which tier each level needs
	## and a copy of that mapping is a copy that will disagree.
	var top := 0
	for lv in Arena.LEVELS.size():
		if int(Arena.LEVELS[lv]["tier"]) <= tier:
			top = lv
	## AND HOW FAR DOWN FROM IT THIS CLUB IS. Two rungs of spread, weighted so
	## most clubs are near the top of what their division allows: a division is
	## mostly clubs that belong there, with a couple who came up and have not
	## built yet.
	var h := _hash2(id * 31 + tier * 7, GROUND_SALT)
	var drop: int = 0 if h % 100 < 55 else (1 if h % 100 < 88 else 2)
	var level := clampi(top - drop, 0, Arena.MAX_LEVEL)

	## THE STATE OF IT, this year. Spread across the whole band a player can be
	## in, so "their place is a tip" and "their place is immaculate" are both
	## things the fixture list can say — and a back field is always spotless for
	## the same reason the player's is (`Arena.WEARS_FROM_LEVEL`): there is
	## nothing there to keep.
	if level < Arena.WEARS_FROM_LEVEL:
		return {"level": level, "condition": 1.0}
	var h2 := _hash2(id * 131 + season * 17, GROUND_SALT + 977)
	return {"level": level, "condition": 0.30 + 0.70 * (float(h2 % 1000) / 999.0)}


## A SMALL INTEGER HASH, kept private and kept boring. Not `randi()` and not the
## world's RNG: reading a club's ground must not consume a draw, or a screen
## that shows the fixture list would reshuffle the country.
static func _hash2(a: int, b: int) -> int:
	var x := (a * 2654435761) ^ (b * 40503)
	x = (x ^ (x >> 13)) * 1274126177
	return absi(x ^ (x >> 16))


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
		return UiKit.t("No such town.")
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
	## The local invitationals are held near you, so a move renames them.
	name_cup_weeks()
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
	week = 0
	team_title = ""
	days_played.clear()
	finalists.clear()
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
		days_played[t] = 0
	calendar = Calendar.build(League.events_in_season(player_tier()),
		player_tier() == League.Tier.NATIONAL)
	name_cup_weeks()
	_enter_week()


## THE PLAYER'S INVITATIONALS BY NAME AND TOWN on his calendar's cup weeks, so a
## screen can say where the weekend is before the field is drawn.
func name_cup_weeks() -> void:
	var si := set_of_tier(player_tier())
	for w in calendar:
		if int(w["kind"]) == Calendar.Kind.CUP:
			w["name"] = invitational_name(si, Calendar.slot_of(w))
			w["city"] = invitational_city(si, Calendar.slot_of(w))


# ------------------------------------------------------------------- weeks
func this_week() -> Dictionary:
	return calendar[week] if week < calendar.size() else {}


func week_kind() -> int:
	return int(this_week().get("kind", -1))


func weeks_this_season() -> int:
	return calendar.size()


## The league is done (the player's division has played every day of it). The
## SEASON is not done until the playoffs — and at National, the Worlds — are.
func league_complete() -> bool:
	return event >= (schedule[player_tier()] as Array).size()


## The cup a week is for, or null — a live Invitational, a division's playoff
## (the player's own when `t` is -1), or the Worlds.
func cup_of_week(w: Dictionary, t: int = -1) -> Cup:
	match int(w.get("kind", -1)):
		Calendar.Kind.CUP:
			return _live_cup(invitational_id(set_of_tier(player_tier() if t < 0 else t), Calendar.slot_of(w)))
		Calendar.Kind.PLAYOFF:
			return _live_cup("playoff:%d" % (player_tier() if t < 0 else t))
		Calendar.Kind.WORLDS:
			return worlds
	return null


func _live_cup(id: String) -> Cup:
	for c in cups:
		if String(c.get_meta("id", "")) == id:
			return c
	return null


## A NEW SATURDAY. Opens whatever starts on it — an Invitational's first round,
## the playoffs, the Worlds — so the bracket exists before anybody is asked to
## fight in it.
func _enter_week() -> void:
	var w := this_week()
	if w.is_empty() or int(w.get("round", 0)) != 0:
		return
	match int(w["kind"]):
		Calendar.Kind.CUP:
			## EVERY SET'S INVITATIONAL, the same weekend.
			var slot := Calendar.slot_of(w)
			for si in INVITATIONAL_SETS.size():
				if not _cup_run(invitational_id(si, slot)):
					cups.append(_build_set_invitational(si, slot))
		Calendar.Kind.PLAYOFF:
			for t in League.TIERS.size():
				if _cup_run("playoff:%d" % t):
					continue
				var field: Array = []
				var rows := table(t)
				for i in mini(Calendar.PLAYOFF_FIELD, rows.size()):
					field.append(int(rows[i]["club"]))
				if field.size() < 2:
					continue
				var c := Cup.new("%s Playoff" % String(League.TIERS[t]["name"]), field,
					int(rng.randi()), player_club if field.has(player_club) else -1, false)
				c.no_third = true
				c.set_meta("id", "playoff:%d" % t)
				cups.append(c)
		Calendar.Kind.WORLDS:
			if worlds == null:
				worlds = _build_worlds(playoff_order(League.Tier.NATIONAL))
				if worlds != null:
					worlds.set_meta("season", season)


## PLAY THE WEEK, for everybody. A league week plays the matchday (the player's
## own result passed in when he fought it); a playoff week plays the round; a
## cup or Worlds week plays the whole tournament out. Then the week moves on.
func play_week(player_rounds = null) -> void:
	var w := this_week()
	if w.is_empty():
		return
	match int(w["kind"]):
		Calendar.Kind.LEAGUE:
			_play_league_day(player_rounds)
		Calendar.Kind.CUP:
			## EVERY SET'S INVITATIONAL, fought out; then the clubs from abroad
			## go home.
			for si in INVITATIONAL_SETS.size():
				var c := _live_cup(invitational_id(si, Calendar.slot_of(w)))
				if c != null:
					c.run_all(cup_resolver())
					retire_cup(c)
			_clear_guests()
		Calendar.Kind.WORLDS:
			## A TOURNAMENT WEEK: whatever is left of it is fought out now. The
			## player's own ties are already in the book when the season holds
			## them; on the auto path they are decided with everybody else's.
			var c := cup_of_week(w)
			if c != null:
				c.run_all(cup_resolver())
				retire_cup(c)
		Calendar.Kind.PLAYOFF:
			## EVERY DIVISION'S PLAYOFF, the same weekend.
			for t in League.TIERS.size():
				var c := cup_of_week(w, t)
				if c != null:
					c.run_all(cup_resolver())
					retire_cup(c)
	week += 1
	_enter_week()


## THE OLD STEP, for the code that drives a world with nobody holding a cup —
## the soak tests and the auto-play probes: play through to the next league day
## and play it, and once the league is done, play out the rest of the year.
func play_event(player_rounds = null) -> void:
	while week < calendar.size() and week_kind() != Calendar.Kind.LEAGUE:
		play_week()
	if week < calendar.size():
		play_week(player_rounds)
	if Calendar.league_weeks_left(calendar, week) == 0:
		while week < calendar.size():
			play_week()


## THE REST OF THE SEASON, as [{event, opponent, home}] from the current matchday
## on. Empty at the end of a season, which reads correctly as "nothing left".
##
## FOR THE FIXTURE CARD's empty half. Pete, item 20 of the 15 Sep playtest, on
## what should replace the formation and play buttons: *"Maybe the schedule, and
## a couple other things."*
##
## It reads the same `schedule` the matchday reads, so the card and the fixture
## it is about cannot disagree — the alternative is a second walk of the same
## array, which in this project has a track record.
## NOW EVERY WEEK, not only the league's (30 Sep 2026): a cup round is on the
## list as what it is, so the table never moves without the list saying why.
## Each row: {week, kind, event (league day, 1-based, or 0), opponent, home,
## cup (id, or "")}.
func remaining_fixtures(limit: int = 6) -> Array:
	var out: Array = []
	var days: Array = schedule[player_tier()]
	for wi in range(week, calendar.size()):
		if out.size() >= limit:
			break
		var w: Dictionary = calendar[wi]
		var row := {"week": wi + 1, "kind": int(w["kind"]), "event": 0, "opponent": -1,
			"home": false, "cup": String(w.get("cup", "")), "round": int(w.get("round", 0))}
		if int(w["kind"]) == Calendar.Kind.LEAGUE:
			var d := int(w["day"])
			row["event"] = d + 1
			if d < days.size():
				for pair in days[d]:
					if int(pair[0]) == player_club or int(pair[1]) == player_club:
						row["opponent"] = int(pair[1]) if int(pair[0]) == player_club else int(pair[0])
						row["home"] = League.host_of(pair) == player_club
						break
		out.append(row)
	return out


func events_this_season() -> int:
	return League.events_in_season(player_tier())


## THE YEAR IS OVER when the last Saturday has been played — the playoffs and
## the Worlds included, not only the league.
func season_complete() -> bool:
	return week >= calendar.size()


## Who you are drawn against on the current matchday, or -1 for a bye.
## DOES HE HOST THIS ONE? The pair is `[host, visitor]` — see `League.fixtures`.
## A club with no fixture this matchday is not at home; it is nowhere.
func player_hosts() -> bool:
	var days: Array = schedule[player_tier()]
	if event >= days.size() or week_kind() != Calendar.Kind.LEAGUE:
		return false
	for pair in days[event]:
		if int(pair[0]) == player_club or int(pair[1]) == player_club:
			return League.host_of(pair) == player_club
	return false


func player_opponent() -> int:
	var days: Array = schedule[player_tier()]
	if event >= days.size() or week_kind() != Calendar.Kind.LEAGUE:
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
## WHAT THE PLAYER'S OPPOSITION IS MULTIPLIED BY when his fixture is simmed.
##
## Set by `Season` from `opposition_scale()` immediately before the call and
## reset after, rather than passed as an argument, because `play_event` is called
## from five places and four of them have no opinion about it — an argument would
## be four call sites each restating a default they do not care about.
##
## 1.0 means "as rated", which is what every other club in the world gets and
## what a save from before this existed will read.
var player_scale: float = 1.0


## IS THE PLAYER TURNING PROMOTION DOWN THIS SUMMER? Set by `Season` from the
## player's answer and cleared by the roll-over that consumes it.
##
## Pete, 15 Sep 2026: *"If you qualify for the next league, you can choose to
## advance, or stay within your league next season. A player may bust through the
## season but want to stay a season and continue building up their money, train
## players, or whatever they wish, and staying in a cheaper league would be
## beneficial."*
##
## THIS IS THE YO-YO ANSWER AND IT IS BETTER THAN THE ONE I PROPOSED. Part 3 of
## the teardown suggested copying Retro Bowl's stadium — a thing you buy that
## narrows the swing — so that a promoted club could survive a bad first season
## up. Pete's version does not damp the bounce, it **lets the player decline the
## bounce**: you go up when your squad is ready rather than when the table says
## so, and the cheaper division you stayed in is the year you spent getting ready.
## No new currency, no new screen, one boolean.
var stay_down: bool = false


## The division's table with the player taken out of it, so the promotion places
## fall through to the clubs behind him.
##
## A COPY, not a filter in place: `table()` hands back rows the tables dictionary
## still owns, and removing the player from that would delete him from the
## division rather than from the shortlist.
func _without_player(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		if int(r["club"]) != player_club:
			out.append(r)
	return out


func _play_league_day(player_rounds = null) -> void:
	var mine := player_tier()
	var n_mine := maxi(1, (schedule[mine] as Array).size())
	for t in League.TIERS.size():
		var days: Array = schedule[t]
		## THE OTHER DIVISIONS KEEP PACE: by the player's last league day every
		## table has played all of its own. (They used to stop when his did, so a
		## Backyard career saw a National table five days into fifteen.)
		var want: int = event + 1 if t == mine \
			else mini(days.size(), int(ceil(float((event + 1) * days.size()) / float(n_mine))))
		while int(days_played.get(t, 0)) < want:
			_play_day(t, int(days_played.get(t, 0)), player_rounds)
			days_played[t] = int(days_played.get(t, 0)) + 1
	event += 1


func _play_day(t: int, d: int, player_rounds) -> void:
	var days: Array = schedule[t]
	if d >= days.size():
		return
	for pair in days[d]:
		var a := int(pair[0])
		var b := int(pair[1])
		var res: Array
		if player_rounds != null and (a == player_club or b == player_club):
			## [rounds_a, rounds_b, margin_a, margin_b] — the same four numbers
			## MeleeSim carries out of a real bout, so a fought fixture and a
			## simulated one enter the table through exactly one shape.
			var pr: Array = _four(player_rounds)
			res = pr if a == player_club else [pr[1], pr[0], pr[3], pr[2]]
		elif a == player_club or b == player_club:
			## A SIMMED FIXTURE OF THE PLAYER'S STILL HAPPENS AT HIS GRADE.
			##
			## It did not, and that is the third time this project has found
			## the same shape: simmed events cost no kit wear until 15 Sep,
			## they cost no arena wear until 16 Sep, and they were fought at
			## no difficulty at all until now. `opposition_scale()` — the
			## whole of `Grade` — was read in exactly two places, both of them
			## `MeleeSim.new`, so **the difficulty setting applied only to
			## fights you chose to play**, and the SIM IT button on every
			## fixture was a button that turned it off.
			##
			## `tools/probe_run.gd` found it by accident and could not have
			## missed it: twenty-season careers at all five grades came back
			## byte for byte identical. **A column that matches another column
			## exactly is not a result, it is a bug report** — this suite has
			## said so since `probe_spend.gd` and it was right again.
			var scaled := int(round(float(clubs[b if a == player_club else a]
				["power"]) * player_scale))
			res = quick_bout(int(clubs[a]["power"]), scaled) if a == player_club \
				else quick_bout(scaled, int(clubs[b]["power"]))
		else:
			res = quick_bout(int(clubs[a]["power"]), int(clubs[b]["power"]))
		var ma: int = int(res[2]) if res.size() > 2 else 0
		var mb: int = int(res[3]) if res.size() > 3 else 0
		League.apply_result(tables[t][a], res[0], res[1], ma, mb)
		League.apply_result(tables[t][b], res[1], res[0], mb, ma)


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
		_record_honors(c)
		var cid := String(c.get_meta("id", ""))
		if cid.begins_with("playoff:"):
			finalists[int(cid.substr(8))] = [c.champion, c.runner_up]
	cups.clear()
	if worlds != null:
		worlds.run_all(resolver)
		_record_honors(worlds)
		worlds = null
		## The finished Worlds' guests go home before the next field is invited,
		## or they piled up behind it year on year.
		_clear_guests()


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

	## THE WORLDS, when nobody fought it. A National club plays it on its own
	## calendar, the last six Saturdays of the year; for everybody else it is
	## decided here, on paper, from the National playoff BEFORE anybody is
	## promoted out of the division.
	if not _ran_this_season("worlds"):
		var wc := _build_worlds(playoff_order(League.Tier.NATIONAL))
		if wc != null:
			wc.set_meta("season", season)
			wc.run_all(cup_resolver())
			_record_honors(wc)
		worlds = null
		_clear_guests()

	var moves_up: Dictionary = {}
	var moves_down: Dictionary = {}
	for t in League.TIERS.size():
		## THE PLAYOFF FINALISTS GO UP (Pete, 30 Sep 2026), then the table.
		var rows := playoff_order(t)
		## THE PLAYER MAY TURN PROMOTION DOWN, and if he does the club under him
		## goes instead. See `stay_down`.
		if stay_down and t == player_tier():
			rows = _without_player(rows)
		for cid in League.promoted(t, rows):
			if t < League.TIERS.size() - 1:
				moves_up[cid] = t + 1
		for cid in League.relegated(t, table(t)):
			if t > 0:
				moves_down[cid] = t - 1

	for cid in moves_up:
		clubs[cid]["tier"] = int(moves_up[cid])
		club_promoted.emit(int(cid), int(moves_up[cid]))
	for cid in moves_down:
		clubs[cid]["tier"] = int(moves_down[cid])
		club_relegated.emit(int(cid), int(moves_down[cid]))

	## The champion of the top flight gets the title on the board — the playoff
	## winner, now there is a playoff.
	var top := playoff_order(League.TIERS.size() - 1)
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
		## A BREAKAWAY'S POWER IS ITS MEN, set by the season's winter for them.
		## The draw above still happens so the stream is the same with or without
		## one in the world.
		if bool(c.get("splinter", false)) or bool(c.get("guest", false)):
			continue
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


## THE DIVISION IN THE ORDER IT GOES UP: the playoff champion, the runner-up,
## then the table. Before the playoff has been fought it is just the table.
func playoff_order(t: int) -> Array:
	var rows := table(t)
	var f: Array = finalists.get(t, [])
	if f.is_empty():
		return rows
	var out: Array = []
	for cid in f:
		for r in rows:
			if int(r["club"]) == int(cid):
				out.append(r)
	for r in rows:
		if not f.has(int(r["club"])):
			out.append(r)
	return out


## DID THE PLAYER WIN HIS DIVISION THIS YEAR? The playoff champion since
## 30 Sep 2026; the top of the table before the playoff has been fought.
func player_champion() -> bool:
	var f: Array = finalists.get(player_tier(), [])
	if not f.is_empty():
		return int(f[0]) == player_club
	return player_position() == 1


## Was a cup of this id fought (or is one running) this season?
func _ran_this_season(id: String) -> bool:
	if worlds != null and id == "worlds":
		return true
	return _cup_run(id)


func _cup_run(id: String) -> bool:
	for c in cups:
		if String(c.get_meta("id", "")) == id:
			return true
	for h in honors:
		if String(h.get("id", "")) == id and int(h.get("season", -1)) == season:
			return true
	return false


## The set a division's clubs are invited to: 0 local, 1 continental, 2 elite.
static func set_of_tier(t: int) -> int:
	for i in INVITATIONAL_SETS.size():
		if (INVITATIONAL_SETS[i]["tiers"] as Array).has(t):
			return i
	return 0


func invitational_id(set_i: int, slot: int) -> String:
	return "inv:%s:%d" % [String(INVITATIONAL_SETS[set_i]["id"]), slot]


## A stable draw for this season's set and slot — not the world's stream, so a
## screen can ask where a cup will be before it is drawn and get the answer the
## draw will give.
func _inv_hash(set_i: int, slot: int, salt: int = 0) -> int:
	return absi(hash("inv:%d:%d:%d:%d:%d" % [rng.seed, season, set_i, slot, salt]))


## WHERE IT IS HELD. Local: one of the three cities nearest the player among
## the clubs of the bottom two divisions. Continental and elite: from their lists.
func invitational_city(set_i: int, slot: int) -> String:
	var h := _inv_hash(set_i, slot)
	match String(INVITATIONAL_SETS[set_i]["where"]):
		"elite":
			return String(ELITE_CITIES[h % ELITE_CITIES.size()])
		"continental":
			var l: Array = CONTINENTAL_EU if region == Cities.Region.EU else CONTINENTAL_US
			return String(l[h % l.size()])
	var mine := city_of(player_club)
	var near: Array = []
	for c in clubs:
		var t := int(c.get("tier", -1))
		if t < 0 or not (INVITATIONAL_SETS[set_i]["tiers"] as Array).has(t):
			continue
		var ct := city_of(int(c["id"]))
		if ct != "" and not near.has(ct):
			near.append(ct)
	near.sort_custom(func(a, b): return Cities.distance(mine, a) < Cities.distance(mine, b))
	if near.is_empty():
		return mine
	return String(near[h % mini(3, near.size())])


## ITS NAME. The top pair are Pete's (10 Sep); the others are plain, and the
## local ones carry the town.
func invitational_name(set_i: int, slot: int) -> String:
	match String(INVITATIONAL_SETS[set_i]["id"]):
		"elite":
			return "Kings Cup" if slot == 0 else "Path of Honor"
		"continental":
			if region == Cities.Region.EU:
				return "European Open" if slot == 0 else "Continental Cup"
			return "North American Open" if slot == 0 else "Continental Cup"
	var city := invitational_city(set_i, slot)
	return ("%s Open" if slot == 0 else "%s Classic") % city


## THE FIELD: the top three of each division the set invites from — you among
## them if you have earned it — then the next best of those divisions, and for
## the two upper sets, clubs from abroad, rated off the set's own division.
func _build_set_invitational(set_i: int, slot: int) -> Cup:
	var spec: Dictionary = INVITATIONAL_SETS[set_i]
	var tiers: Array = spec["tiers"]
	var me := invited() and tiers.has(player_tier())
	var field: Array = []
	if me:
		field.append(player_club)
	var depth := INVITE_RANK
	var abroad := String(spec["where"]) != "local"
	while field.size() < INVITATIONAL_FIELD:
		var added := false
		for t in tiers:
			var rows := table(int(t))
			for i in mini(depth, rows.size()):
				var cid := int(rows[i]["club"])
				if cid != player_club and not field.has(cid) and field.size() < INVITATIONAL_FIELD:
					field.append(cid)
					added = true
		## The local set reaches further down its own divisions; the others
		## stop at the top three and send for clubs from abroad.
		if abroad or depth >= 16:
			break
		depth += 1
	var g := 0
	var band: Array = League.TIERS[int(tiers[tiers.size() - 1])]["power"]
	var pool: Array = (Cities.EU.map(func(c): return String(c["name"])) if String(spec["where"]) == "elite" \
		and region != Cities.Region.EU else (Cities.ABROAD.map(func(c): return String(c["name"])) \
		if region != Cities.Region.EU else Cities.US.map(func(c): return String(c["name"]))))
	while field.size() < INVITATIONAL_FIELD:
		var h := _inv_hash(set_i, slot, 100 + g)
		var city := String(pool[h % pool.size()])
		var lo := int(band[0]) + (4 if String(spec["where"]) == "elite" else 0)
		var hi := int(band[1]) + (8 if String(spec["where"]) == "elite" else 2)
		clubs.append({
			"id": clubs.size(),
			"name": "%s %s" % [city, SECOND[(h / 7) % SECOND.size()]],
			"short": "GST", "tier": -1, "titles": 0, "guest": true, "city": city,
			"power": lo + (h / 13) % maxi(1, hi - lo + 1),
		})
		field.append(clubs.size() - 1)
		g += 1
	## Seed by power, so the bracket's 1-v-8 means something.
	field.sort_custom(func(a, b): return int(clubs[a]["power"]) > int(clubs[b]["power"]))
	var c := Cup.new(invitational_name(set_i, slot), field,
		int(rng.randi()), player_club if me else -1, false)
	c.set_meta("id", invitational_id(set_i, slot))
	c.set_meta("city", invitational_city(set_i, slot))
	return c


## WORLDS. The National playoff champion carries the country (one berth, Pete
## 1 Oct 2026; this note used to say top two); the other fourteen
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
	## AND THE SAME VETO ON THE WORLDS. Winning the National playoff earns the
	## place; the federation is what lets you take it. A club
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
		_record_honors(c)
	cups = held
	if worlds != null and not (hold_player_cups and worlds.player_alive()):
		worlds.run_all(resolver)
		_record_honors(worlds)
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


## A cup that is over gets its honors recorded and gets out of the way. Called
## after the player finishes a round rather than on a timer, so a bracket cannot
## sit completed and still be asked for a fixture.
func retire_cup(c: Cup) -> void:
	if not c.is_over():
		return
	_record_honors(c)
	var cid := String(c.get_meta("id", ""))
	if cid.begins_with("playoff:"):
		finalists[int(cid.substr(8))] = [c.champion, c.runner_up]
	var i := cups.find(c)
	if i != -1:
		cups.remove_at(i)
	if c == worlds:
		worlds = null
		## Held over the summer, so the guests are still here. Now they can go.
		_clear_guests()


func _record_honors(c: Cup) -> void:
	if not c.is_over():
		return
	if c.champion >= 0 and c.champion < clubs.size():
		clubs[c.champion]["titles"] = int(clubs[c.champion]["titles"]) + 1
	honors.append({
		"id": String(c.get_meta("id", "")),
		"name": c.cup_name,
		"season": int(c.get_meta("season", season)),
		"champion": c.champion,
		## THE NAME TOO: a champion from abroad is a guest whose id is reused
		## once he goes home.
		"champion_name": String(clubs[c.champion]["name"]) if c.champion >= 0 and c.champion < clubs.size() else "",
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
