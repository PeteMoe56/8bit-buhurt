class_name Season
extends RefCounted
## THE SEAM. The fight and the world, joined.
##
## Before this there were two halves that both worked and did not touch: a melee
## with twelve checks on it, a pyramid with eight, and no line of code anywhere
## that referenced both. You could fight an exhibition bout forever and you could
## simulate a hundred seasons, and you could not play one.
##
## This owns the world, owns your club, hands the melee the right two clubs for
## whatever fixture is next, and takes the four numbers back out again:
## rounds won and standing margin, which is exactly what the table eats.
##
## No node dependencies, so a whole season runs headless in a test.

## How well drilled a CPU club is, by the division it is in. Worlds guests carry
## no division, so they take the top rung.
const CPU_TIER := [
	Tuning.AiSkill.RUST,          ## Backyard Circuit
	Tuning.AiSkill.EXPERIENCED,   ## State League
	Tuning.AiSkill.HARDENED,      ## Regional League
	Tuning.AiSkill.ELITE,         ## National Division
]
const GUEST_TIER := Tuning.AiSkill.WORLD

signal event_played(opponent: int, rounds: Array)
signal season_finished(position: int, promoted: bool, relegated: bool)

var world: LeagueWorld
var club: MeleeClub                      ## yours, the real one, with a roster
var opponent: MeleeClub = null           ## rebuilt for each fixture
var last_result: Array = []              ## [rounds_a, rounds_b, margin_a, margin_b]
var seed_value: int = 0
var _clubs: Dictionary = {}              ## club id -> MeleeClub, built on demand
## Every event this season, in order. Read off the TABLE rather than out of the
## sim, so a fought fixture and a simmed one produce the same shape of row and
## there is no second source of truth to drift.
var results: Array[Dictionary] = []
## The front office: credits, the cap, the facilities and the captains.
var office := ClubOffice.new()

## YOU. The club is rebuilt every time you take a new job; this is not — see
## `scripts/league/coach.gd`. It is the only object in the game that outlives a
## post, which is what makes twenty seasons a career rather than twenty seasons.
var coach := Coach.new()

## The club's own drawn shapes and plays, and what it is going out in. Kept as
## the chosen ID rather than the chosen spots, so a formation edited on the
## Chalkboard changes the next bout without anything needing to re-point.
var board := Chalkboard.new()
var formation_id: int = Tuning.Formation.TWO_ONE_TWO
var play_index: int = -1

## Create-A-Player's ledger. Create-A-Team needs none — your colors are yours.
var workshop := Workshop.new()

## THE EVENT YOU ARE PUTTING ON, or null. One at a time — a club with two
## tournaments in the diary is not a club with a decision to make.
var booked: ClubEvent = null

## ------------------------------------------------------------------ the grade
## HOW HARD THIS CAREER IS. It belongs to the career rather than to the machine —
## it lives in the save slot, not in `Settings` — and **it can be changed at any
## time.**
##
## THAT SECOND HALF WAS WRONG UNTIL 16 SEP 2026. The note here used to argue that
## a grade you could change between fixtures would make the table meaningless, so
## it was settable only on the club-creation screen and nowhere else. Pete, having
## played it: *"Difficulty should be changeable."*
##
## He is right and the old argument was backwards. It assumed the player is
## cheating the table; the actual player is a man four events into a losing season
## who has just been told by his own game that the way out is *"bringing the
## difficulty down"* — his words, 14 Sep — and who then cannot find the control.
## **A difficulty setting you can only choose before you know what it means is not
## a difficulty setting, it is a quiz question.**
##
## The table stays honest because `grade_history` keeps every change with the
## event it happened on, so a season fought on two grades says so on the record
## rather than pretending it was one. That is the same answer Football Manager
## gives and it costs one array.
var grade: int = Grade.DEFAULT

## EVERY GRADE THIS CAREER HAS BEEN FOUGHT ON: `[{season, event, grade}]`, oldest
## first, with the starting grade as entry zero. The honors screen reads it so a
## promotion won on FRIENDLY is labelled, and `set_grade()` is the only writer.
var grade_history: Array = []


## CHANGE THE GRADE, and write down that it changed.
##
## Returns "" or a sentence, like every other verb here. It refuses nothing today
## — there is no cooldown and no cost — because the first version of a control
## that exists to rescue a struggling player should not itself be a thing he has
## to earn.
## THE CUSTOM GRADE'S DIALS — see `Grade.DIALS`. Kept on the career even while
## a preset is chosen, so switching back to Custom finds them as they were left.
var custom_grade: Dictionary = Grade.CUSTOM_DEFAULT.duplicate()


## Turn one dial. Clamped and stepped by `Grade.clamp_dial`; the change is only
## written into the history when Custom is the grade actually being played.
func set_custom(key: String, v: float) -> String:
	if not Grade.CUSTOM_DEFAULT.has(key):
		return UiKit.t("There is no such setting.")
	var c := Grade.clamp_dial(key, v)
	if key == "pauses":
		custom_grade[key] = int(c)
	elif key == "ceiling":
		custom_grade[key] = c > 0.5
	else:
		custom_grade[key] = c
	if grade == Grade.G.CUSTOM:
		_note_grade()
	sync_power()
	return ""


func set_grade(g: int) -> String:
	if not Grade.ORDER.has(g):
		return UiKit.t("There is no such grade.")
	if g == grade:
		return ""
	grade = g
	## A GRADE CHANGE RESETS MATCHED'S LADDER, the same as it does on the creation
	## screen: switching away and back with the running value intact would let a
	## player park on FRIENDLY, walk the step down, and switch to MATCHED holding
	## a number he never earned.
	matched_step = Grade.STEP_START
	_note_grade()
	sync_power()
	return ""


func _note_grade() -> void:
	var at := {"season": world.season, "event": world.event, "grade": grade}
	if grade == Grade.G.CUSTOM:
		at["custom"] = custom_grade.duplicate()
	## ONE ENTRY PER CHANGE, not one per call. Re-noting the same grade on the
	## same event is the creation screen cycling through the list, which is a
	## player deciding rather than a career happening.
	if not grade_history.is_empty():
		var last: Dictionary = grade_history[grade_history.size() - 1]
		if int(last["season"]) == int(at["season"]) \
				and int(last["event"]) == int(at["event"]):
			grade_history[grade_history.size() - 1] = at
			return
	grade_history.append(at)


## MATCHED's running value. Ignored by every other grade, and carried anyway so
## that switching to MATCHED mid-career does not start you back at the bottom of
## the ladder having already won three divisions.
var matched_step: int = Grade.STEP_START
## The last one that happened, kept for the screen to report.
var last_show: Dictionary = {}

## THE YEAR'S THREE DATES, offered between seasons and answered before the first
## matchday. Empty once the bid is settled — taken or declined — which is what
## `bid_open()` reads.
var bid_offers: Array = []


func _init(player_club: MeleeClub, seed_v: int = 0,
		region: int = Cities.Region.US) -> void:
	seed_value = seed_v
	club = player_club
	workshop.keep_worn(club)
	office.tier = 0
	world = LeagueWorld.new(seed_v, player_club.power(), region)
	world.clubs[world.player_club]["name"] = player_club.display_name
	world.clubs[world.player_club]["short"] = player_club.short_name
	world.clubs[world.player_club]["city"] = LeagueWorld._city_of(player_club.display_name)
	## AND THE CLUB HAS TO BE ON THE MAP IT IS PLAYING ON. `MeleeRosters` hands
	## over a club with a fixed name, so a European career started from it founded
	## an American club in a European league — one row on the table from a town
	## nobody else could travel to.
	##
	## IT SETS THE TOWN AND DOES NOT RENAME. `set_city` was the first version and
	## it renamed the club, which on a LOADED save is a disaster: `SaveGame` calls
	## this constructor with the saved club before restoring the saved world, so a
	## club the player had named "Bonk Works" was read as being in the town
	## "Bonk", found not to be on the map, relocated, and came back as **"New York
	## Works"** — every single load. Caught by `test_create.gd`, which has
	## asserted that a renamed club survives a save since long before there was a
	## map.
	##
	## Placing a club is all this needs to do. Renaming one is the picker's job.
	if not Cities.names(world.region).has(city()):
		var free := world.free_cities()
		if not free.is_empty():
			world.clubs[world.player_club]["city"] = free[0]
	## Cups the player is alive in wait for him now. Without this the world
	## resolved every bracket on paper before anybody could be asked, which is
	## why `Cup.player_match()` sat with no caller from the day it was written.
	world.hold_player_cups = true

	## YOUR FIRST POST, and the club you grew up on.
	##
	## The boyhood club is drawn from the top of the pyramid, not at random. A
	## dream job in the division you are already standing in is not a dream — the
	## point of the thing is that it is out of reach for years, so it is drawn
	## from the National Division and held back until your third season besides
	## (see `Jobs.DREAM_HELD_UNTIL_SEASON`). It must also not be the club you are
	## already at, or the dream is the desk you are sitting at.
	coach.take_post(world.player_club, world.season)
	var top: Array = world.clubs_in(League.TIERS.size() - 1)
	if not top.is_empty():
		var fav_rng := RandomNumberGenerator.new()
		fav_rng.seed = hash("fav:%d" % seed_v)
		coach.favorite_club_id = int(top[fav_rng.randi() % top.size()])
		if coach.favorite_club_id == world.player_club:
			coach.favorite_club_id = -1

	## The first year's dates are on the table before the first matchday, the
	## same as every year after it.
	open_bids()


## TAKE THE JOB. The one move in this game that changes who you are rather than
## what you own.
##
## Everything the club held stays with the club: the roster, the credits, the
## arena, the captains, the trophy cabinet. You arrive at the new place with a
## reputation and a book and nothing else, which is exactly what a coach takes
## through a door in real life and is the reason the move has weight. A version
## of this that let you bring your best Center is a trade screen, not a career.
##
## Only offered between seasons. Walking out mid-year would leave a half-played
## fixture list owned by nobody, and every table in the world reads
## `world.player_club`.
func take_job(club_id: int) -> String:
	if club_id == world.player_club:
		return UiKit.t("You are already there.")
	if not Jobs.interested(coach, world, club_id):
		return UiKit.t("They have not offered.")
	if world.event > 0:
		return UiKit.t("See the season out first.")

	## The club you are leaving goes back to being an ordinary club in the
	## league — it keeps the roster you built, which is what makes meeting them
	## again interesting — and the new one becomes yours, built from its power the
	## same way every CPU club is.
	var old_id := world.player_club
	_clubs.erase(club_id)
	var taken := club_for(club_id)
	_clubs[old_id] = { "club": club, "power": int(world.clubs[old_id]["power"]) }
	## AND IT KEEPS IT ACROSS A RELOAD (29 Sep 2026). `_clubs` is a cache and is
	## not saved, so the roster "you built" lived only until the next load — or
	## the first time its power drifted — and was then rebuilt from the factory:
	## different men, different results in a reloaded game than a straight one.
	## A stored roster is what `splinter_rosters` is for: saved, wintered like
	## any club (aged, coached, retirements, walk-ons) and its power read off
	## the men. The club you walk INTO stops being one.
	var kept: Array[FighterCard] = []
	for f in club.roster:
		kept.append(f)
	splinter_rosters[old_id] = kept
	splinter_rosters.erase(club_id)

	world.player_club = club_id
	club = taken
	coach.take_post(club_id, world.season)

	## A NEW DESK, AND IT IS EMPTY. The office is the CLUB's, so the new one has
	## its own: no credits banked, no facilities, no captains, no following. This
	## is the cost of the move and it is deliberately not softened — a coach who
	## carries his arena across town is not changing jobs.
	##
	## EXCEPT MONEY THE PLAYER PAID FOR. Credits bought in the store follow the
	## coach — `min(credits, bought)`, so what he takes is never more than he
	## bought or more than he has. Leaving it behind turned a job offer into a
	## way to lose a purchase.
	var carried: int = mini(office.credits, office.bought) if office.bought > 0 else 0
	office = ClubOffice.new()
	office.tier = int(world.clubs[club_id]["tier"])
	if carried > 0:
		office.take(carried, UiKit.t("Bought credits, brought with you"), "move", ClubOffice.LINE_STORE)
		office.bought = carried
	office.sync_morale(club)
	board = Chalkboard.new()
	workshop = Workshop.new()
	workshop.keep_worn(club)
	booked = null
	bid_offers.clear()
	dilemma.clear()
	dilemma_recent.clear()
	market_taken.clear()
	prospect = null
	results.clear()
	sync_power()
	open_bids()
	return ""


## A NIGHT OUT. The only thing in the game that lifts morale on purpose.
##
## It reaches the men who travel — the room, which is what `ClubOffice.morale`
## averages — and not the reserves, because the reserves are not there. That is
## also the honest version: it is a club night, not a payroll adjustment.
func boost_morale() -> String:
	var err := office.take_boost()
	if err != "":
		return err
	for f in club.active_eight():
		f.morale_shift(ClubOffice.BOOST_MORALE)
	office.sync_morale(club)
	return ""


## HIRE A CAPTAIN, and let him do whatever he does on the day he walks in.
##
## The office holds the money and the captains; the roster is the club's. So the
## arrival traits — the three that fire once — need both, and this is the only
## place that has both. Every screen that hires goes through here rather than
## calling `office.hire` directly, which is what stops a captain being hired
## somewhere his trait never fires.
## THE CAPTAIN IN SLOT `slot` OF THIS SUMMER'S STAFF LIST. One door: the staff
## room and the clubhouse each built this call themselves, and a list read two
## ways is a list that can offer two different men.
func staff_offer(slot: int) -> Dictionary:
	return ClubOffice.offer(seed_value, world.season, slot, office.staff_refreshes)


func hire_captain(c: Dictionary) -> String:
	var err := office.hire(c)
	if err != "":
		return err
	last_arrival = office.arrival_effect(c, club)
	office.sync_morale(club)
	sync_power()
	return ""


## What the last hire did, for the screen to report. A trait that fires silently
## is a trait the player never learns he bought.
var last_arrival: Dictionary = {}
## -> SeasonBouts (season_bouts.gd)
func _dress_sim(sim: MeleeSim, opp_id: int, kind: int, dist: float) -> void:
	SeasonBouts._dress_sim(self, sim, opp_id, kind, dist)




## Your rating is your roster. Call it after anything that changes the squad —
## a signing, a cut, a promotion, a repair — because the league sorts on this
## number and nothing else, and a table that has not heard about your new Center
## is lying to you.
func sync_power() -> void:
	## HOW MANY YOU CAN TAKE, before anything reads the eight. `active_eight()`
	## is what club power averages, what the lineup is drawn from and what the
	## corner offers, so the cap has to be on the club before any of those are
	## asked — which is why it is the first line of the function everything else
	## already calls after touching the squad.
	club.travel_cap = office.travel_slots
	world.set_player_power(club.power())
	## The cap is your DIVISION's rule, so it has to follow you up and down the
	## pyramid. Promotion is a pay rise for the whole club, and relegation is the
	## other thing.
	office.tier = world.player_tier()
	## AND THE FEDERATION'S ANSWER, pushed down to the world rather than the world
	## reaching up for it. `sync_power` is already the one function every path
	## calls after touching the club, and compliance is read against the DIVISION
	## — which this line has just set — so the two have to move together or a
	## promoted club is judged against the standard it has left behind.
	world.cup_entry_barred = not office.compliant()
	## AND WHAT THE GRADE DOES TO THE BILLS, for the same reason: every path
	## that could have changed the grade or its ladder comes through here.
	office.bills_scale = Grade.bills_for(grade, matched_step, custom_grade)
	office.knocks_scale = Grade.knocks_for(grade, matched_step, custom_grade)


func opponent_id() -> int:
	return world.player_opponent()


## RELOCATE, at setup or later. The world does the swap; this keeps the fighting
## club's own name in step with it, because two places holding the club's name is
## two places that can disagree and one of them is on every screen.
func set_city(city: String) -> String:
	var err := world.take_city_for_player(city)
	if err != "":
		return err
	club.display_name = String(world.clubs[world.player_club]["name"])
	club.short_name = String(world.clubs[world.player_club]["short"])
	return ""


func city() -> String:
	return world.city_of(world.player_club)


## HOW FAR THIS AFTERNOON IS FROM HOME. Zero at home and on a bye; the real
## distance to the other club's town on the road. A cup tie is neutral ground and
## has no host, so it is priced as the trip to the opposition — which is the
## honest stand-in until tournaments get a town of their own.
func miles_travelled() -> float:
	var opp := opponent_id()
	if opp < 0:
		return 0.0
	match venue_kind():
		Venue.Kind.HOME: return 0.0
		_: return world.miles_between(world.player_club, opp)
## -> SeasonBouts (season_bouts.gd)
func ground_of(id: int) -> Dictionary:
	return SeasonBouts.ground_of(self, id)


## -> SeasonBouts (season_bouts.gd)
func neutral_ground() -> Dictionary:
	return SeasonBouts.neutral_ground(self)


## -> SeasonBouts (season_bouts.gd)
func fight_ground() -> Dictionary:
	return SeasonBouts.fight_ground(self)


## -> SeasonBouts (season_bouts.gd)
func gate_now() -> Dictionary:
	return SeasonBouts.gate_now(self)


## -> SeasonBouts (season_bouts.gd)
func gate_for_fixture(opp: int, home: bool) -> int:
	return SeasonBouts.gate_for_fixture(self, opp, home)


## -> SeasonBouts (season_bouts.gd)
func venue_kind() -> int:
	return SeasonBouts.venue_kind(self)


## -> SeasonBouts (season_bouts.gd)
func host_id() -> int:
	return SeasonBouts.host_id(self)




## The other club, as eight men rather than as a rating. Built on demand and
## cached, because ClubFactory is deterministic from the id: the club you play in
## October fields the same eight it fielded in March.
func club_for(id: int) -> MeleeClub:
	if id == world.player_club:
		return club
	## A SPLINTER IS NOT REBUILT. Every other CPU club is generated from its id
	## and its power, so the cache can be thrown away and rebuilt at will — that
	## is why no CPU roster is saved. A breakaway is the one exception, because
	## the whole point of it is that it is made of men you used to pick, and a
	## rebuild would hand you strangers with the same name.
	if splinter_rosters.has(id):
		if not _clubs.has(id):
			var men: Array[FighterCard] = []
			for f in splinter_rosters[id]:
				men.append(f)
			_clubs[id] = {
				"club": MeleeClub.build(String(world.clubs[id]["name"]),
					String(world.clubs[id]["short"]),
					Color(0.55, 0.16, 0.16), Color(0.9, 0.85, 0.7), 0, men),
				"power": int(world.clubs[id]["power"]),
			}
		return _clubs[id]["club"]
	if _clubs.has(id) and int(_clubs[id]["power"]) == int(world.clubs[id]["power"]):
		return _clubs[id]["club"]
	var c: Dictionary = world.clubs[id]
	var built := ClubFactory.build(id, String(c["name"]), String(c["short"]), int(c["power"]))
	_clubs[id] = { "club": built, "power": int(c["power"]) }
	return built
## -> SeasonBouts (season_bouts.gd)
func begin_bout() -> MeleeSim:
	return SeasonBouts.begin_bout(self)


## -> SeasonBouts (season_bouts.gd)
func called_play():
	return SeasonBouts.called_play(self)


## -> SeasonBouts (season_bouts.gd)
func post_bout(sim: MeleeSim) -> void:
	bout_live = {}
	SeasonBouts.post_bout(self, sim)


## ------------------------------------------------------- walking out mid-bout
## A BOUT IN PROGRESS IS WRITTEN DOWN. The season screen marks it just before it
## hands the bout to the melee and saves; posting the result clears it. A save
## that loads with the mark still on it is a bout the app lost — killed in the
## background, a crash, a flat battery.
##
## Pete, 29 Sep 2026 (replacing "forfeit and warn" of 27 Sep): *"Just pause the
## match. If it's a system failure, restart from before the match started."*
## So the mark is cleared and the fixture is still there to be fought, from the
## walk-out, on the same seed — a lost app is not a loss, and it is not a re-roll
## either.
var bout_live: Dictionary = {}
## What the last load restarted, for the season screen to say once. "" if nothing.
var last_interrupted: String = ""


## WHAT THE CLUB CAN SEE OF A MAN'S CEILING, as [low, high]. Exact for your own
## men; a range `office.scout_width()` wide for anybody else, placed so the true
## value sits somewhere inside it — deterministically, per man and per season,
## so reopening the list does not re-roll it. See ClubOffice.scout_width.
func potential_range(f: FighterCard) -> Vector2i:
	if f == null:
		return Vector2i.ZERO
	if club.roster.has(f):
		return Vector2i(f.potential, f.potential)
	return ceiling_range(f, office.scout_width())


## The same read at any width. `width` 0 is the truth.
func ceiling_range(f: FighterCard, w: int) -> Vector2i:
	if w <= 0:
		return Vector2i(f.potential, f.potential)
	var off: int = absi(hash("scout:%s:%d:%d:%d" % [f.display_name, f.age, f.potential,
		world.season])) % (w + 1)
	var lo: int = maxi(f.overall(), f.potential - off)
	var hi: int = mini(Career.POTENTIAL_CEILING, lo + w)
	return Vector2i(lo, hi)



## THE WARNING, late enough to be about THIS summer and early enough to act on:
## two matchdays or fewer left and the purse short of the summer bill. Said once
## a season. "" when there is nothing to say.
var _summer_warned: int = -1


func summer_warning() -> String:
	var left := world.events_this_season() - world.event
	var bill := office.summer_bill()
	if left > 2 or season_complete() or office.credits >= bill or _summer_warned == world.season:
		return ""
	_summer_warned = world.season
	return UiKit.t("The summer bill is %d CC and you hold %d. Whatever goes unpaid falls a level.") % [
		bill, office.credits]


## THE DRESSING ROOM ASKS WHERE THE DUES ARE GOING (Pete, 29 Sep 2026, #12).
##
## A club that only re-signs never leaves the bottom division — 20 careers out of
## 20 in the 4 AM audit — and sits on five hundred credits with nothing ever
## saying so. So once a season, when the bank holds several summers' bills and
## the club has put nothing into the squad or the ground this year, one of the
## men says it, and says what the money is for. "" when there is nothing to say.
const HOARD_SUMMERS: int = 4
var _hoard_said: int = -1


func hoard_note() -> String:
	if _hoard_said == world.season or world.event < 2 or club.roster.is_empty() \
			or blocked_by() != "":
		return ""
	var bill := maxi(1, office.summer_bill())
	if office.credits < bill * HOARD_SUMMERS:
		return ""
	var put_in := int(office.books_out.get(ClubOffice.LINE_SQUAD, 0)) \
		+ int(office.books_out.get(ClubOffice.LINE_FACILITIES, 0)) \
		+ int(office.books_out.get(ClubOffice.LINE_GROUND, 0))
	if put_in > 0:
		return ""
	_hoard_said = world.season
	var who: FighterCard = club.roster[absi(hash("hoard:%d" % world.season)) % club.roster.size()]
	## The hint points at the one thing that moves a club: the next ground if the
	## division above needs it, otherwise the market.
	var up := mini(world.player_tier() + 1, League.TIERS.size() - 1)
	var hint := UiKit.t("The Market has starters.")
	if not office.arena.fit_for(up) and office.arena.can_build(office.tier, office.credits) == "":
		hint = UiKit.t("Build the ground.")
	return UiKit.t("%s: where are the dues going? %d CC banked, nothing new. %s") % [
		who.display_name, office.credits, hint]


## The range in words, for a card: "to 64" when it is known, "to 58-66" when not.
func potential_word(f: FighterCard) -> String:
	var r := potential_range(f)
	return (UiKit.t("to %d") % r.x) if r.x == r.y else (UiKit.t("to %d-%d") % [r.x, r.y])


func mark_bout_live(is_cup: bool) -> void:
	bout_live = {"cup": is_cup, "season": world.season, "event": world.event}


## Called by SaveGame.load_slot. Returns true if a bout was waiting to restart.
func restart_abandoned_bout() -> bool:
	if bout_live.is_empty():
		return false
	var was: Dictionary = bout_live
	bout_live = {}
	if int(was.get("season", -1)) != world.season or int(was.get("event", -1)) != world.event:
		return false
	last_interrupted = UiKit.t("The game closed mid-bout. It starts again from the walk-out.")
	return true


## -> SeasonBouts (season_bouts.gd)
func opposition_scale(opp_id: int) -> float:
	return SeasonBouts.opposition_scale(self, opp_id)


## -> SeasonBouts (season_bouts.gd)
func _grade_bout(rounds_for: int, rounds_against: int) -> void:
	SeasonBouts._grade_bout(self, rounds_for, rounds_against)


## -> SeasonBouts (season_bouts.gd)
func _apply_regime(hosted: bool) -> void:
	SeasonBouts._apply_regime(self, hosted)


## -> SeasonBouts (season_bouts.gd)
func _apply_bout_injuries(sim: MeleeSim) -> void:
	SeasonBouts._apply_bout_injuries(self, sim)




## XP FOR WHAT HE ACTUALLY DID. Harvested straight off the sim's own bookkeeping
## — downs caused and rounds finished standing — so the number a fighter earns is
## computed from the same two figures the post-fight report puts on the screen,
## and the two can never tell the player different stories.
##
## Only the five who fought earn it. A man on the bench who never came on did
## nothing, and paying him for the afternoon would delete the reason a squad has
## a depth chart.
## WHO WENT UP, AND TO WHAT. Cleared at the start of every award so the report
## shows this afternoon's levels and not the season's.
var last_levels: Array[Dictionary] = []

## ---------------------------------------------------------- what it cost him
## WHAT THE AFTERNOON DID TO THE MEN — Pete, 13 Sep 2026: *"After the bout looks
## great. We can use the bottom half for status/trait changes as well."*
##
## The report has always been about the FIGHT: the score, the shape, who gassed.
## Everything that happened to a man afterwards — a level earned, a knock, a
## mood, a trait firing, a grudge named — was applied silently and the player
## found out about it later on a different screen, if he found out at all.
##
## RECORDED WHERE IT HAPPENS, not reconstructed afterwards. A report that
## recomputed "who is unhappy now" would be a second opinion about the club's
## state, and the two would eventually disagree; a line written at the moment the
## morale actually moved cannot. It is the same shape as `UiKit`'s ink ledger and
## as the assist tally in the sim: the thing that does it writes it down.
##
## `kind` orders the list and colors it; nothing reads the text but the screen.
var last_changes: Array[Dictionary] = []
## -> SeasonBouts (season_bouts.gd)
func _note_change(kind: String, who: String, text_: String, good: int = 0) -> void:
	SeasonBouts._note_change(self, kind, who, text_, good)




## What each man actually banked from the last bout, for the report's XP column.
var last_xp: Dictionary = {}
## -> SeasonBouts (season_bouts.gd)
func _award_xp(sim: MeleeSim) -> void:
	SeasonBouts._award_xp(self, sim)




## What a matchday is worth to a man when nobody fought it — a bye, or the player
## handing the event to the AI.
##
## IT HAS TO PAY SOMETHING. A club that sims its season and develops nobody would
## be carrying a hidden penalty for using a button the game offers it, and the
## player would never work out why his squad stopped improving. It pays a little
## under an average afternoon, so fighting is rewarded without simming being a
## trap.
const XP_SIMMED: int = 8

## WHAT A TOXIC MAN COSTS THE REST OF THEM, per toxic man, after a loss only.
## Small on its own and compounding when there are two of him, which is the
## right shape: one difficult man is a character, three is a dressing room.
const TOXIC_DRAG: float = -0.06
## -> SeasonBouts (season_bouts.gd)
func _practice() -> void:
	SeasonBouts._practice(self)


## -> SeasonBouts (season_bouts.gd)
func run_session() -> String:
	return SeasonBouts.run_session(self)


## -> SeasonBouts (season_bouts.gd)
func _award_sim_xp() -> void:
	SeasonBouts._award_sim_xp(self)


## -> SeasonBouts (season_bouts.gd)
func skip_event() -> void:
	SeasonBouts.skip_event(self)


## -> SeasonBouts (season_bouts.gd)
func _after_event(rf: int, ra: int, gate: Dictionary = {}) -> void:
	SeasonBouts._after_event(self, rf, ra, gate)




## WHO CANNOT MAKE IT THIS WEEKEND, and it is the half of DIRECTION §4 that has
## no equivalent anywhere in the reference.
##
## *"A fighter can be your best and unavailable because he can't get the weekend
## off. This constraint has never been in a sports management game and it is
## completely true to the sport."* Nobody in buhurt is paid. Your Center is a
## welder with a shift, your best Flanker has his sister's wedding, and neither
## is a fitness problem you can train away or a money problem you can buy out.
##
## THREE THINGS MAKE IT A DECISION RATHER THAN A DICE ROLL:
##
## 1. IT IS KNOWN IN ADVANCE. Rolled at the top of the week, so it is on the
##    roster screen before you pick a line. A man who vanishes at kick-off is a
##    punishment; a man who tells you on Monday is a squad-selection problem, and
##    the second one is the game.
## 2. IT IS WHY THE BENCH IS WORTH BUYING. A club traveling five has no answer
##    to it at all. `ClubOffice.travel_slots` is the answer, and this is the
##    question it answers.
## 3. IT CLEARS. A man is unavailable for one weekend, not injured for four —
##    which is what keeps it separate from a knock rather than a second flavour
##    of one.
##
## Deterministic from the season and the matchday, so a reload does not re-roll
## who is working — see `_roster_rng`, the same private stream the market and the
## walk-ons use, kept off the world's so a squad event cannot shift the league.
const AVAILABILITY_CHANCE: float = 0.055
## And never more than one man at once. Two is a coincidence; three is the game
## telling you that you cannot field a line, which is not a decision, it is a
## wall.
const AVAILABILITY_MAX: int = 1
## -> SeasonBouts (season_bouts.gd)
func _roll_availability() -> void:
	SeasonBouts._roll_availability(self)


## -> SeasonBouts (season_bouts.gd)
func year_summary() -> Dictionary:
	return SeasonBouts.year_summary(self)


## -> SeasonBouts (season_bouts.gd)
func _my_row() -> Dictionary:
	return SeasonBouts._my_row(self)


## -> SeasonBouts (season_bouts.gd)
func _log(opp: int, before: Dictionary, fought: bool, at_home: bool) -> void:
	SeasonBouts._log(self, opp, before, fought, at_home)


## -> SeasonCups (season_cups.gd)
func bid_open() -> bool:
	return SeasonCups.bid_open(self)


## -> SeasonCups (season_cups.gd)
func open_bids() -> void:
	SeasonCups.open_bids(self)


## -> SeasonCups (season_cups.gd)
func take_bid(offer_i: int, budget_i: int) -> String:
	return SeasonCups.take_bid(self, offer_i, budget_i)


## -> SeasonCups (season_cups.gd)
func decline_bid() -> void:
	SeasonCups.decline_bid(self)


## -> SeasonCups (season_cups.gd)
func bid_preview(offer_i: int, budget_i: int) -> Dictionary:
	return SeasonCups.bid_preview(self, offer_i, budget_i)


## -> SeasonCups (season_cups.gd)
func pending_cup() -> Cup:
	return SeasonCups.pending_cup(self)


## -> SeasonCups (season_cups.gd)
func viewable_cup() -> Cup:
	return SeasonCups.viewable_cup(self)


## -> SeasonCups (season_cups.gd)
func cup_pending() -> bool:
	return SeasonCups.cup_pending(self)


## -> SeasonCups (season_cups.gd)
func cup_opponent() -> int:
	return SeasonCups.cup_opponent(self)


## -> SeasonCups (season_cups.gd)
func begin_cup_bout() -> MeleeSim:
	return SeasonCups.begin_cup_bout(self)


## -> SeasonCups (season_cups.gd)
func post_cup_bout(sim: MeleeSim) -> void:
	bout_live = {}
	SeasonCups.post_cup_bout(self, sim)


## -> SeasonCups (season_cups.gd)
func sim_cup_tie() -> void:
	SeasonCups.sim_cup_tie(self)


## -> SeasonCups (season_cups.gd)
func _finish_cup_round(c: Cup, won: bool) -> void:
	SeasonCups._finish_cup_round(self, c, won)


## -> SeasonCups (season_cups.gd)
func _apply_injuries(sim: MeleeSim) -> void:
	SeasonCups._apply_injuries(self, sim)


## -> SeasonCups (season_cups.gd)
func run_demo() -> String:
	return SeasonCups.run_demo(self)


## -> SeasonCups (season_cups.gd)
func _event_due() -> bool:
	return SeasonCups._event_due(self)


## -> SeasonCups (season_cups.gd)
func _settle_event() -> void:
	SeasonCups._settle_event(self)


## -> SeasonCups (season_cups.gd)
func _settle_gate(e: ClubEvent, c: Cup) -> void:
	SeasonCups._settle_gate(self, e, c)


## -> SeasonCups (season_cups.gd)
func _is_guest(id: int) -> bool:
	return SeasonCups._is_guest(self, id)


## -> SeasonCups (season_cups.gd)
func _invite_field(e: ClubEvent) -> Array:
	return SeasonCups._invite_field(self, e)


## -> SeasonCups (season_cups.gd)
func last_event() -> Dictionary:
	return SeasonCups.last_event(self)




func season_complete() -> bool:
	return world.season_complete()


## The season cannot END while a bracket is waiting on you. Without this a
## player could walk away from a Worlds semi-final by pressing the button that
## starts next year, and the cup would quietly resolve itself around him.
func ready_to_roll() -> bool:
	return season_complete() and not cup_pending()


## Everything that has to be dealt with before a matchday can be played. The
## screen shows them one at a time and in this order.
## WHICH AI TIER THE OTHER CORNER IS ON, for this matchday.
##
## Derived from the same `CPU_TIER` table `begin_bout` uses rather than copied,
## because two places deciding how good the opponent is would eventually decide
## differently — and this one is what a screen prints, so the disagreement would
## be visible and wrong rather than merely wrong.
func ai_tier() -> int:
	var opp := opponent_id()
	if opp == -1:
		return CPU_TIER[clampi(world.player_tier(), 0, CPU_TIER.size() - 1)]
	var ot := int(world.clubs[opp]["tier"])
	return GUEST_TIER if ot < 0 else CPU_TIER[clampi(ot, 0, CPU_TIER.size() - 1)]


## CUT HIM, and what the rest of them make of it.
##
## Retro Bowl again, from its own screens: *"Cutting a non-toxic player will
## harm team morale"* and *"Cutting toxic players will improve team morale."*
## That is the pressure valve on the whole mechanic — the difficult man is
## better at the sport AND he is the one man you can let go without the room
## turning on you. Without it he would simply be a stat to keep and never a
## decision.
##
## The screens used to call `club.cut()` directly, which is why this reads as a
## new verb: the rule about what the room thinks had nowhere to live.
## WHAT ANOTHER CLUB WOULD PAY FOR HIM TODAY. Zero for a man out of contract,
## because a club with nothing to sell has nothing to sell — his deal has run out
## and he can walk to whoever he likes in the summer, so nobody is paying you for
## the privilege. That is the sharp end of the re-sign/extend fork the contracts
## layer already has: let a good man run down and you lose his fee as well as
## him.
func trade_value(f: FighterCard) -> int:
	if f.years <= 0:
		return 0
	return Market.trade_value(f.overall(), world.player_tier())


func trade_tier_name(f: FighterCard) -> String:
	return Market.trade_tier_name(f.overall(), world.player_tier())
## -> SeasonDesk (season_desk.gd)
func release(f: FighterCard) -> String:
	return SeasonDesk.release(self, f)




## Letting a menace go clears the air; letting a good man go does not.
const CUT_TOXIC: float = 0.07
const CUT_LIKED: float = -0.05


func blocked_by() -> String:
	## NOT BEFORE THE FIRST BOUT (Pete, 29 Sep 2026, #5): a new club opens on its
	## next fight. The offers wait on the table; they are asked after bout one.
	if bid_open() and first_bout_done():
		return "bid"
	if cup_pending():
		return "cup"
	## THE CARD BLOCKS THE NEXT MATCHDAY, deliberately. A dilemma the player can
	## walk past is a dilemma he walks past, and then the feature is a notification
	## rather than a decision. It joins the bid and the cup in the same queue the
	## season screen already drains one at a time, so there is one rule about what
	## has to be dealt with before you can fight rather than three.
	if not dilemma.is_empty():
		return "dilemma"
	## AND THE LAST GATE OF THE YEAR: go up, or stay where you are.
	if promotion_offered():
		return "promotion"
	return ""


## Has this career fought (or simmed) anything yet? Onboarding (#5) hides the
## tournament bid and the Armorer until it has.
func first_bout_done() -> bool:
	return world.season > 1 or coach.seasons > 0 or not results.is_empty()


# ------------------------------------------------------- take it or stay down
## PROMOTION IS AN OFFER NOW, NOT A FACT.
##
## Pete, 15 Sep 2026: *"If you qualify for the next league, you can choose to
## advance, or stay within your league next season. A player may bust through the
## season but want to stay a season and continue building up their money, train
## players, or whatever they wish, and staying in a cheaper league would be
## beneficial."*
##
## It only means anything because the division now costs money to be in —
## `League.dues_for(tier)` is 6 / 14 / 24 / 38 — so staying down is a real saving
## against a real risk, rather than a button that does nothing but waste a year.
## The two changes are one change and neither works alone.
##
## ANSWERED, NOT DEFAULTED. `promotion_answered` starts false and `blocked_by()`
## holds the season on it, for the same reason the dilemma card blocks the next
## matchday: **a decision the player can walk past is a decision he walks past**,
## and this one is the biggest of the year.
var promotion_answered: bool = false
## -> SeasonDesk (season_desk.gd)
func promotion_place() -> bool:
	return SeasonDesk.promotion_place(self)


## -> SeasonDesk (season_desk.gd)
func promotion_offered() -> bool:
	return SeasonDesk.promotion_offered(self)


## -> SeasonDesk (season_desk.gd)
func promotion_terms() -> Dictionary:
	return SeasonDesk.promotion_terms(self)


## -> SeasonDesk (season_desk.gd)
func answer_promotion(take: bool) -> String:
	return SeasonDesk.answer_promotion(self, take)




## What he said, for the summer report. `true` is went up, `false` is stayed.
var last_promotion_choice := true


## The summer: cups resolve, promotions and relegations settle, a new fixture
## list is drawn. Your rating is re-read off your roster on the way out, because
## a club that improved over the winter should start the year improved.
## What a season is worth. Small integers on purpose — Retro Bowl's credits work
## because you never have enough of them, and a currency you can hoard stops
## being a decision. These numbers are a first pass and want a tuning session of
## their own once somebody has actually played ten seasons.
## THE CARD ON THE TABLE. Empty when there is nothing to answer; otherwise the
## card's id, the roster index of the man it picked, and the club it happened
## after. Stored as an INDEX rather than as the card, for the same reason the
## prospect is: a saved FighterCard decodes into a copy, and an option that
## repairs a copy's harness repairs nobody.
var dilemma: Dictionary = {}

## The last few ids, so the deck does not deal the armorer's bill three
## matchdays running. Short on purpose — a player should see a card again within
## a season, just not immediately.
var dilemma_recent: Array[String] = []
const DILEMMA_MEMORY: int = 5

## WHO HAS BEEN SIGNED OUT OF THIS SUMMER'S MARKET. Keys, not cards — the pool
## is regenerated from the seed rather than stored, so the card a club is holding
## is a different object from the one a fresh list produces.
var market_taken: Array[String] = []

## THE PROSPECT. Named during the season from the roster screen, cashed at the
## winter, cleared either way. Held as the card itself rather than an index
## because a roster re-sorts and an index does not survive a cut.
var prospect: FighterCard = null

## What the veterans at their ceiling turned their XP into this summer.
var last_cashed: int = 0

## What the winter did: points gained, points lost to age, who retired, who was
## brought on. Read by the season screen — a squad that quietly loses two men
## over a summer is a bug report waiting to happen.
var last_winter: Dictionary = {}

## What the last summer's bills came to, and anything that fell down because
## they could not be paid. Read by the season screen; empty until a roll-over.
var last_upkeep: Dictionary = {}

const CREDITS_WIN: int = 2
const CREDITS_DRAW: int = 1
const CREDITS_PROMOTED: int = 4

## ------------------------------------------------------------- the purse
## WHAT THE DIVISION PAYS OUT, AND EVERY CLUB IN IT TAKES A SHARE.
##
## Pete, 15 Sep 2026: *"The income is either too low or costs are too high. 84 in
## one year will not maintain enough, you'll decline."*
##
## This was `CREDITS_BY_POSITION := [6, 4, 2]` — a flat table of three, and both
## halves of that were wrong.
##
## THREE PLACES MEANS MOST CLUBS EARN NOTHING. A Backyard division is six clubs
## and a National one sixteen, so from the moment a career leaves the bottom
## league the majority of the field finishes outside the money EVERY YEAR. A
## club that comes eighth of sixteen has had a whole season and been paid for
## exactly none of it, and "come top three or get nothing" is not a difficulty
## curve, it is a wall with no handholds — which is precisely the word Pete used:
## decline. `tools/probe_afford.gd` puts numbers on it: held mid-table, a club's
## income FELL from 24.7 CC a season in the Backyard Circuit to 13.2 in the
## National Division, while the bills went up.
##
## AND A FLAT TABLE MEANS THE CLIMB PAYS NOTHING EITHER. Winning the National
## Division paid the same six credits as winning the Backyard Circuit, against
## upkeep that had quadrupled. The one number in the game that is supposed to say
## "this division is a bigger deal" said the opposite.
##
## So it is a purse and a share of it. The federation puts up a pot that grows
## with the division, and where you finished decides your cut — last place still
## takes something, because a club that turned up for a whole season did put on
## fifteen shows, and first place takes five or six times as much.
const PURSE_TOP: int = 6

## HOW MUCH BIGGER THE POT IS EACH DIVISION UP. Just over half again, so the
## champions take 6 / 9 / 13 / 16 CC as they climb — which is roughly the shape
## of the upkeep they are climbing into rather than a number that felt right.
const PURSE_TIER_STEP: float = 0.55

## AND WHAT THE BOTTOM CLUB TAKES, as a share of the top. Small enough that the
## table is worth climbing and not zero, because zero is the thing being fixed.
const PURSE_TAIL: float = 0.18


## WHAT FINISHING `place` OF `field` IN THIS DIVISION IS WORTH.
##
## A straight line from the champions to the wooden spoon. Not a curve: a curve
## would need a shape argument and a defence of it, and the one thing a player
## has to be able to do with this number is look at the table and know what one
## more place is worth. A line makes that the same everywhere.
static func purse(place: int, field: int, tier: int) -> int:
	if place < 1 or field < 1:
		return 0
	var top := float(PURSE_TOP) * (1.0 + float(maxi(0, tier)) * PURSE_TIER_STEP)
	var down: float = 0.0 if field <= 1 else \
		float(clampi(place, 1, field) - 1) / float(field - 1)
	return maxi(1, int(round(top * lerpf(1.0, PURSE_TAIL, down))))
## -> SeasonWinter (season_winter.gd)
func roll_over() -> void:
	SeasonWinter.roll_over(self)




## What the fracture did, for the summer report. Empty in a year the club held.
var last_split: Dictionary = {}

## Captains whose contracts ran out this summer.
var last_staff_left: Array[String] = []

## What the membership did over the summer, for the report.
var last_members: Dictionary = {}

## The rosters of clubs that broke away from you, by club id. A CPU club is
## normally rebuilt from its id and power and needs no storage; a splinter is the
## exception, because the entire point of it is that it is made of SPECIFIC men
## you used to pick. Rebuilt from a seed it would be strangers with a grudge,
## which is a different and much worse idea.
var splinter_rosters: Dictionary = {}
## -> SeasonWinter (season_winter.gd)
func _maybe_split(place: int, tier_before: int, tier_after: int) -> Dictionary:
	return SeasonWinter._maybe_split(self, place, tier_before, tier_after)


## -> SeasonWinter (season_winter.gd)
func _missing_slot(c: MeleeClub) -> int:
	return SeasonWinter._missing_slot(self, c)


## -> SeasonWinter (season_winter.gd)
func _thinnest_slot(c: MeleeClub) -> int:
	return SeasonWinter._thinnest_slot(self, c)


## -> SeasonWinter (season_winter.gd)
func _winter_the_splinters() -> void:
	SeasonWinter._winter_the_splinters(self)




## THE WINTER. Everybody gets a year older, the ones who are done go home, and
## the ones who are left train — in that order, because a man who retires should
## not be trained first and a man who trains should not then be aged out of the
## improvement he just bought.
##
## The captain rule from before is unchanged and still gates the improvement
## half only: a role no captain covers does not train. Nobody needs a captain to
## get older.
##
## THE TRAINING GROUND'S POINTS ARE SHARED THE SAME WAY THEY ALWAYS WERE —
## lowest ratings first, so a 55 in the reserve climbs faster than a 78 on the
## line and the reserve is where a club is actually built. What is new is that
## the ceiling now refuses them: points offered to a man who has reached his
## potential go to the next man instead of being spent on nothing.
var _ground_used: int = 0
## -> SeasonWinter (season_winter.gd)
func _train() -> void:
	SeasonWinter._train(self)


## -> SeasonWinter (season_winter.gd)
func _settle_contracts() -> Array[String]:
	return SeasonWinter._settle_contracts(self)


## -> SeasonWinter (season_winter.gd)
func _fill_squad() -> Array[String]:
	return SeasonWinter._fill_squad(self)




## A CLUB THAT CANNOT FIELD FIVE MID-SEASON IS NOT LEFT TO FORFEIT ITS YEAR.
##
## A club under five fit men in the travelling party is rated 0 — every sim a
## loss — and walk-ons only arrived in the winter. Two injuries and one man out,
## with no money for the market (the dues can put a club in the red), was a
## season of forfeits with no way out. So before any bout or sim:
##   1. a fit man in the reserve travels in place of an injured one;
##   2. if that is still not five, a free walk-on is signed (room permitting).
## Returns what it did, for the status line; empty when the line was already whole.
var last_emergency: Array[String] = []
## -> SeasonWinter (season_winter.gd)
func ensure_a_line() -> Array[String]:
	return SeasonWinter.ensure_a_line(self)


## -> SeasonWinter (season_winter.gd)
func _uncovered_slot() -> int:
	return SeasonWinter._uncovered_slot(self)




# ------------------------------------------------------------------- the mood
## WHAT OCCASION THE SHELL SHOULD BE DRESSED FOR — Pete, 10 Sep 2026. The whole
## game reads one palette (see UiKit.set_mood), so this one function decides
## whether the player is looking at an ordinary Saturday or at a boss.
##
## KEYED TO THE FIGHT IN FRONT OF HIM, not to the calendar. A mood that is on for
## a whole season stops being a mood — it has to be the thing he opens the game
## and finds waiting, which in this game is exactly `cup_pending()`: one matchday
## at a time, a handful of times a year.
##
## And it CLIMBS. A Kings Cup tie is not a Worlds tie and neither is a final, so
## the ladder runs cup → your own tournament → Worlds → the final of whichever
## one he is in. The last of those is checked first, because a Worlds final is a
## final before it is a Worlds.
func mood() -> int:
	var c := pending_cup()
	if c == null:
		return UiKit.Mood.NORMAL
	## A final is a final whatever competition it belongs to.
	if c.round_name() == "Final":
		return UiKit.Mood.FINAL
	if c.cup_name == "Worlds":
		return UiKit.Mood.WORLDS
	## Your own show: the hosted tournament is the one cup whose name is the
	## club's own, and the one the player paid for.
	## Your own show. Matched on the SHORT name because that is what names the
	## hosted bracket — `"%s Invitational" % club.short_name` — and matching the
	## display name would have quietly never fired.
	if c.cup_name == "%s Invitational" % club.short_name:
		return UiKit.Mood.HOSTED
	return UiKit.Mood.CUP


## The line under the banner: which cup, which round, and who is standing in
## front of you. Empty when there is nothing on.
func occasion() -> String:
	var c := pending_cup()
	if c == null:
		return ""
	return "%s  ·  %s" % [c.cup_name, c.round_label()]


# ---------------------------------------------------------------- the dilemma
## ONE CARD A MATCHDAY, MOST MATCHDAYS. Not every one: a card after literally
## every fight becomes a rhythm the player taps through, and the point of the
## deck is that it interrupts. Two in three is often enough to feel constant and
## rare enough that the screen coming up still means something.
const DILEMMA_CHANCE: float = 0.66


## THE ROSTER'S OWN STREAM, for the same reason the deck has one.
##
## Retirement rolls, contract patience and walk-on generation all drew from
## `world.rng` — the stream every fixture, every cup draw and every quick bout
## in the country comes out of. The NUMBER of draws depends on how many men are
## on your books, so cutting one reserve in March moved every other club's
## rating drift, every simulated result and every cup draw for the rest of the
## save. Your squad decisions silently reshuffled the country.
##
## Exactly the bug the deck already had and was already fixed for, in a second
## place nobody looked. Same cure: derive a generator from the world seed and
## the season, so it is deterministic, identical across a reload, and costs the
## world's stream nothing.
func _roster_rng() -> RandomNumberGenerator:
	## Re-derived when the season turns. Caching it across a roll-over would
	## carry one winter's stream into the next, which is the same "deterministic
	## but wrong" the seed is here to avoid.
	if _roster_stream == null or _roster_season != world.season:
		_roster_stream = RandomNumberGenerator.new()
		_roster_stream.seed = hash("roster:%d:%d" % [world.rng.seed, world.season])
		_roster_season = world.season
	return _roster_stream
var _roster_stream: RandomNumberGenerator = null
var _roster_season: int = -1
## -> SeasonDesk (season_desk.gd)
func _draw_dilemma() -> void:
	SeasonDesk._draw_dilemma(self)


## -> SeasonDesk (season_desk.gd)
func _last_opponent_name() -> String:
	return SeasonDesk._last_opponent_name(self)


## -> SeasonDesk (season_desk.gd)
func dilemma_card() -> Dictionary:
	return SeasonDesk.dilemma_card(self)


## -> SeasonDesk (season_desk.gd)
func dilemma_man() -> FighterCard:
	return SeasonDesk.dilemma_man(self)


## -> SeasonDesk (season_desk.gd)
func answer_dilemma(option_i: int) -> String:
	return SeasonDesk.answer_dilemma(self, option_i)


## -> SeasonDesk (season_desk.gd)
func market() -> Array:
	return SeasonDesk.market(self)


## -> SeasonDesk (season_desk.gd)
func market_fee(f: FighterCard) -> int:
	return SeasonDesk.market_fee(self, f)


## -> SeasonDesk (season_desk.gd)
func market_wage(f: FighterCard) -> int:
	return SeasonDesk.market_wage(self, f)


## -> SeasonDesk (season_desk.gd)
func sign_from_market(f: FighterCard) -> String:
	return SeasonDesk.sign_from_market(self, f)


## -> SeasonDesk (season_desk.gd)
func extend(f: FighterCard) -> String:
	return SeasonDesk.extend(self, f)


## -> SeasonDesk (season_desk.gd)
func resign(f: FighterCard) -> String:
	return SeasonDesk.resign(self, f)


## -> SeasonDesk (season_desk.gd)
func _negotiated(f: FighterCard, raw: int) -> int:
	return SeasonDesk._negotiated(self, f, raw)


## -> SeasonDesk (season_desk.gd)
func extend_cost(f: FighterCard) -> int:
	return SeasonDesk.extend_cost(self, f)


## -> SeasonDesk (season_desk.gd)
func resign_cost(f: FighterCard) -> int:
	return SeasonDesk.resign_cost(self, f)




# ----------------------------------------------------------------- read-outs
func table() -> Array:
	return world.table(world.player_tier())


func position() -> int:
	return world.player_position()


func tier_name() -> String:
	return League.tier_name(world.player_tier())


## `events_left()` used to be here. Nothing called it, and the reason is that
## the screen says it better: the fixture card reads "EVENT 4 OF 5", which is
## the same two numbers arranged so the player can see both the distance and the
## whole rather than a remainder. Deleted 15 Sep 2026 — `world.events_this_season()`
## and `world.event` are the pair, and there is now exactly one way to say it.


func honors() -> Array:
	return world.honors
