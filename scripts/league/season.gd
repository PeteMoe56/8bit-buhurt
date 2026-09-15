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

## Create-A-Player's ledger. Create-A-Team needs none — your colours are yours.
var workshop := Workshop.new()

## THE EVENT YOU ARE PUTTING ON, or null. One at a time — a club with two
## tournaments in the diary is not a club with a decision to make.
var booked: ClubEvent = null

## ------------------------------------------------------------------ the grade
## HOW HARD THIS CAREER IS, and it belongs to the career rather than to the
## machine. `Settings` says of itself that it is "the only state in the game that
## is not part of a save slot" — volume is a property of the room you are sitting
## in, and difficulty is a property of the run. A grade you could change at the
## title screen between fixtures would make the table meaningless, and Retro Bowl
## agrees: its own `suppress_difficulty` is read with
## `ini_read_real("savegame", ...)`, out of the save file, not the options.
var grade: int = Grade.DEFAULT
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
		coach.favourite_club_id = int(top[fav_rng.randi() % top.size()])
		if coach.favourite_club_id == world.player_club:
			coach.favourite_club_id = -1

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
		return "You are already there."
	if not Jobs.interested(coach, world, club_id):
		return "They have not offered."
	if world.event > 0:
		return "See the season out first."

	## The club you are leaving goes back to being an ordinary club in the
	## league — it keeps the roster you built, which is what makes meeting them
	## again interesting — and the new one becomes yours, built from its power the
	## same way every CPU club is.
	var old_id := world.player_club
	_clubs.erase(club_id)
	var taken := club_for(club_id)
	_clubs[old_id] = { "club": club, "power": int(world.clubs[old_id]["power"]) }

	world.player_club = club_id
	club = taken
	coach.take_post(club_id, world.season)

	## A NEW DESK, AND IT IS EMPTY. The office is the CLUB's, so the new one has
	## its own: no credits banked, no facilities, no captains, no following. This
	## is the cost of the move and it is deliberately not softened — a coach who
	## carries his arena across town is not changing jobs.
	office = ClubOffice.new()
	office.tier = int(world.clubs[club_id]["tier"])
	office.sync_morale(club)
	board = Chalkboard.new()
	workshop = Workshop.new()
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


## EVERYTHING YOUR CAPTAINS PUT ON THE LINE, in one place.
##
## This was two copies of the same four lines — one in `begin_bout`, one in
## `begin_cup_bout` — and the day the Physio trait needed a second injection
## beside the tiers, only one of them would have got it. That is the fifth time
## this document has recorded the same shape: a rule applied at two call sites is
## a rule with a hole in it. There is now one caller-facing verb, and a cup tie
## and a league fixture are dressed identically by construction rather than by
## somebody remembering.
## EVERYTHING A SIM NEEDS TO KNOW ABOUT THE FIXTURE IT IS ABOUT TO BE, in one
## place, because the two bout paths have now disagreed about the fixture THREE
## TIMES: the injury tick, the grade, and this.
##
## `begin_cup_bout` was a copy of `begin_bout` with the roles block factored out,
## and a copy drifts. It set the corner clock, the occasion and the skills by
## hand and never set `opponent_club_id`, `venue` or `miles` at all — so on a cup
## night GRUDGE could not fire against the club the man was actually fighting,
## HOMESICK could not fire on a trip nobody was at home for, and the splash
## before the charge drew the HOME arena for a tie on neutral ground. Three
## traits and a screen, silently off, on the biggest fixtures in the game.
##
## The roles block is not the shared part. THE FIXTURE is the shared part.
func _dress_sim(sim: MeleeSim, opp_id: int, kind: int, dist: float) -> void:
	## WHO, WHERE, HOW FAR. Handed over rather than looked up, for the same
	## reason `big_occasion` is: the fixture knows, the sim should not have to ask.
	sim.opponent_club_id = opp_id
	sim.venue = kind
	sim.miles = dist
	sim.corner_time = Grade.corner_time(grade)
	sim.big_occasion = int(Session.bout_mood) != UiKit.Mood.NORMAL
	## The opposition is coached to its division, on the six-rung ladder Pete
	## named on 10 Sep 2026. A Backyard club is nobody's idea of well drilled;
	## the National Division is, and Worlds guests are better than that.
	var ot := -1
	if opp_id >= 0 and opp_id < world.clubs.size():
		ot = int(world.clubs[opp_id]["tier"])
	sim.skills[1] = GUEST_TIER if ot < 0 else CPU_TIER[clampi(ot, 0, CPU_TIER.size() - 1)]
	## YOUR CHALKBOARD GOES OUT WITH THEM TOO. The shape is always resolved
	## through the board, so a built-in and a drawn formation reach the list by
	## the same road; the play only goes on if it is still legal for the shape
	## you actually picked, which is what Pete's formation-dependent check mark
	## means at the point it matters.
	sim.set_plan(0, board.spots_for(formation_id).duplicate(), called_play())

	var roles := [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]
	var tiers := {}
	var corner := {}
	for role in roles:
		tiers[role] = office.tier_for(role)
		## PHYSIO. His men come out of the corner with more left in them, which is
		## a trait you feel in the fifth round of a bout you are losing.
		if office.trait_covers(ClubOffice.Trait.PHYSIO, role):
			corner[role] = ClubOffice.TRAIT_PHYSIO
	sim.set_role_skills(0, tiers)
	sim.set_corner_bonus(0, corner)


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


## WHERE THE NEXT BOUT IS. A cup tie is neutral ground whoever is in it; a league
## fixture is home or away as the schedule says.
func venue_kind() -> int:
	## A CUP TIE IS NEUTRAL GROUND, whoever is in it, and `pending_cup` is how the
	## rest of the season already asks that question — a second way of asking it
	## here would be a second answer waiting to disagree.
	if pending_cup() != null:
		return Venue.Kind.NEUTRAL
	return Venue.Kind.HOME if world.player_hosts() else Venue.Kind.AWAY


## Who is hosting, as a club id — the player, or the other lot, or -1 on neutral
## ground where nobody is.
func host_id() -> int:
	match venue_kind():
		Venue.Kind.HOME: return world.player_club
		Venue.Kind.AWAY: return opponent_id()
		_: return -1


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


## Start the next fixture. Returns a MeleeSim ready to tick, or null on a bye or
## at the end of a season.
func begin_bout() -> MeleeSim:
	var opp := opponent_id()
	if opp == -1:
		return null
	opponent = club_for(opp)
	## Seeded off the season and matchday, so replaying a save replays the bout.
	var s := hash("bout:%d:%d:%d" % [seed_value, world.season, world.event])
	var sim := MeleeSim.new(club, opponent, s, opposition_scale(opp))
	## YOUR CAPTAINS AND THE FIXTURE GO OUT WITH THEM. One door, shared with the
	## cup, so the two paths cannot know different things about the same night.
	_dress_sim(sim, opp, venue_kind(), miles_travelled())
	return sim


## The routes the line will open with, or null. A play tied to a formation you
## are not in is not an error and not a warning — it simply is not called.
func called_play():
	if play_index < 0 or play_index >= board.plays.size():
		return null
	var p: Dictionary = board.plays[play_index]
	var f := int(p["formation"])
	if f != Chalkboard.UNIVERSAL and f != formation_id:
		return null
	return p["routes"]


## Post a finished bout to the table and move the matchday on. The four numbers
## are the sim's own — rounds won and the standing differential Pete asked for —
## so a fought fixture and a simulated one reach the table through one shape.
func post_bout(sim: MeleeSim) -> void:
	last_result = [sim.rounds_won[0], sim.rounds_won[1], sim.margin[0], sim.margin[1]]
	var opp := opponent_id()
	## AND WHERE IT WAS PLAYED, captured here with the opponent and for the same
	## reason: everything below this line happens after the week has ticked.
	var was_home: bool = venue_kind() == Venue.Kind.HOME
	var before := _my_row()
	_award_xp(sim)
	world.play_event(last_result)
	_after_event(int(last_result[0]), int(last_result[1]))
	## INJURIES LAND AFTER THE WEEK TICKS, and the order is the whole fix.
	##
	## They used to be applied first, and `_after_event` then decremented every
	## injury on the roster — including the one just written. `INJURY_LENGTH` is
	## [1,1,1,1,2,2,3], so FOUR OF SEVEN KNOCKS COST NOTHING at any Infirmary
	## level, and at `injury_relief() == 2` the floor of 1 was decremented to 0
	## as well: no knock ever kept anybody out, while the Clubhouse went on
	## advertising "-2 events off a knock". The post-bout report said a man was
	## hurt and the squad screen showed him fit.
	##
	## A cup tie took the same knock and cost a week, because `post_cup_bout`
	## does not tick the week — so the identical injury was free in the league
	## and expensive in a cup. Applying after the tick makes both paths agree.
	_apply_bout_injuries(sim)
	_apply_regime()
	_log(opp, before, true, was_home)
	_grade_bout(int(last_result[0]), int(last_result[1]))
	event_played.emit(opp, last_result)


## ----------------------------------------------------------------- the grade
## WHAT THE GRADE IS WORTH AGAINST THIS PARTICULAR CLUB.
##
## One function, called by both bout paths, so a cup tie and a league fixture
## cannot end up on different difficulties — which is the same class of bug as
## `post_cup_bout` not ticking the week, and that one hid for a fortnight.
func opposition_scale(opp_id: int) -> float:
	## `clubs` is an ARRAY indexed by club id, not a dictionary keyed by one.
	## It was guarded with `.has(opp_id)` for a fortnight, which on a typed array
	## is a type error that returns false — so every bout in the game, against
	## every club, was graded against the same invented power-50 tier-0 nobody.
	## A guard that can only fail is no more a guard than one that cannot.
	if opp_id < 0 or opp_id >= world.clubs.size():
		return Grade.scale_for(grade, matched_step, 50, 0)
	var c: Dictionary = world.clubs[opp_id]
	return Grade.scale_for(grade, matched_step, int(c["power"]), int(c["tier"]))


## MATCHED MOVES, and only MATCHED. Read off rounds rather than the result alone,
## because a 2-0 and a 2-1 are not the same afternoon — Retro Bowl reads margin
## the same way, taking a second step off the scale for a win by more than
## fourteen. The trophy gate is theirs too: the top of the ladder stays shut
## until the cabinet has something in it.
func _grade_bout(rounds_for: int, rounds_against: int) -> void:
	if grade != Grade.G.MATCHED:
		return
	matched_step = Grade.matched_next(matched_step, rounds_for, rounds_against,
		not world.honours.is_empty())



## Knocks land here rather than inside the sim: the fight records who went down
## badly, the season decides whose books it lands on. Only your own men carry
## injuries — the other fourteen fixtures are numbers on a page.
## THE REGIME'S OTHER THREE, once a week: what it costs in morale, in armour,
## and in men.
##
## Morale and wear are club-wide sums of per-man effects, because a club running
## two captains on two different regimes is running two different weeks at once
## and the average is the honest answer.
func _apply_regime() -> void:
	## WHO TRAVELLED, for the gate. A DRAW only pulls people in on a day he is
	## actually there — read off the eight rather than the squad, because a man in
	## the reserves sells nobody a ticket.
	office.set_draws(club.active_eight())
	for f in club.active_eight():
		var role := Tuning.role_of(int(f.pos))
		## EVERY MAN FEELS HIS OWN WEEK. The regime belongs to the captain who
		## teaches his role, so two men on the same eight under two captains on
		## two different regimes have two different weeks — which is the whole
		## reason the regime is set per captain rather than per club.
		f.morale_shift(office.regime_morale(role))
		## A captain who teaches nothing still lifts the room.
		f.morale_shift(office.presence())
		## Armour takes the wear whether or not he fought — that is what a hard
		## week means.
		## KIT MINDER and ROUGH ON KIT. `regime_wear` is negative, so a multiplier
		## under one is less damage and over one is more — the sign stays with the
		## regime and the trait only scales it.
		## AND THE HARNESS DECIDES HOW MUCH OF THAT WEEK THE KIT ABSORBS. The
		## regime says how hard it was, the trait scales it, and the grade of
		## harness he is wearing scales it again — tournament plate takes a third
		## less than club spares. That is the actual economy of armour in the
		## sport: good kit pays for itself in repairs it does not need.
		f.armor = clampf(f.armor + office.regime_wear(role)
			* FighterTrait.mod(f.trait_id, "wear", 1.0)
			* Quartermaster.wear_scale(f), 0.0, Quartermaster.ceiling(f))
	office.sync_morale(club)


func _apply_bout_injuries(sim: MeleeSim) -> void:
	var line := sim.lineup(0)
	for k in sim.injuries:
		var i := int(k["idx"])
		if i < 5 and i < line.size():
			var card: FighterCard = line[i]
			## THE REGIME'S SHARPEST EDGE. Retro Bowl lets a knock through 10% of
			## the time on Light, 20% on Normal and ALWAYS on Hard — so Hard is
			## not a bit riskier than Normal, it is five times riskier. That
			## asymmetry is what stops Hard being a free 1.5x on development.
			##
			## The roll is its own stream: an injury that consumed the world's
			## RNG would make a squad decision reshuffle the country, which is a
			## bug this project has already fixed twice.
			var roll := RandomNumberGenerator.new()
			roll.seed = hash("knock:%d:%d:%d:%s" % [world.rng.seed, world.season,
				world.event, card.display_name])
			if roll.randf() > office.regime_injury(Tuning.role_of(int(card.pos))):
				continue
			var was := card.injury
			card.injury = maxi(card.injury,
				maxi(1, int(k["events"]) - office.injury_relief()
					+ int(FighterTrait.mod(card.trait_id, "injury_events", 0.0))))
			if card.injury > was:
				card.knocks += 1
				## Recorded here rather than counted off the roster afterwards:
				## `_apply_bout_injuries` is the only place that knows this knock
				## is new, and a later pass over the squad cannot tell a man hurt
				## today from a man hurt last week.
				_note_change("knock", card.display_name,
					"carried off — out for %d event%s" % [card.injury,
						"" if card.injury == 1 else "s"], -1)


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
## `kind` orders the list and colours it; nothing reads the text but the screen.
var last_changes: Array[Dictionary] = []


func _note_change(kind: String, who: String, text_: String, good: int = 0) -> void:
	last_changes.append({"kind": kind, "who": who, "text": text_, "good": good})


func _award_xp(sim: MeleeSim) -> void:
	last_levels.clear()
	last_changes.clear()
	for m in sim.men:
		if m.team != 0 or m.card == null:
			continue
		if not club.roster.has(m.card):
			continue
		## THE REGIME'S FIRST EFFECT. Hard develops a man half again as fast and
		## Light at three fifths — Retro Bowl's own 1.5 and 0.6, applied to the
		## role he stands in because our captains cover roles.
		var role := Tuning.role_of(int(m.card.pos))
		## SPONGE and PLATEAUED ride on the same multiplier the regime and the
		## captain already use, which is the point of them being multipliers: one
		## man who learns faster is the same shape as a hard winter, at the man.
		m.card.xp += int(round(float(Career.xp_for(m.downs_caused, m.rounds_standing))
			* office.regime_xp(role) * office.specialty_xp(role)
			* FighterTrait.mod(m.card.trait_id, "xp", 1.0)))
		## CEILING RAISER. A three-down afternoon is the best thing a man does all
		## season; on him it moves what he could become, not just what he is.
		if m.downs_caused >= 3 and FighterTrait.flag(m.card.trait_id, "ceiling_on_big"):
			m.card.potential = mini(99, m.card.potential + 1)
			_note_change("trait", m.card.display_name,
				"Ceiling Raiser — a three-down afternoon moved what he could become", 1)
		## AND IF HE HAS EARNED A LEVEL, IT WAITS FOR YOU. It used to be taken here
		## automatically, into whatever stat he was worst at — which quietly made
		## it impossible to build a specialist, because every point a man earned
		## went into his weakness. The report names him; the spending is a
		## decision, and it can be made any time after.
		if Career.levels_waiting(m.card) > 0:
			last_levels.append({"name": m.card.display_name, "waiting": true,
				"level": m.card.level, "overall": m.card.overall()})
			_note_change("level", m.card.display_name,
				"has a level waiting — spend it on his card", 1)
		if int(m.assists) > 0:
			_note_change("work", m.card.display_name,
				"%d assist%s — second man on somebody else's takedown" % [
					int(m.assists), "" if int(m.assists) == 1 else "s"], 1)
		## THE BOOK, kept from the same two numbers the XP is paid on. They were
		## already being counted and already being discarded; writing them down
		## costs nothing and is the difference between a level and a career.
		m.card.bouts += 1
		m.card.downs += int(m.downs_caused)
		m.card.rounds_standing += int(m.rounds_standing)
		m.card.best_downs = maxi(m.card.best_downs, int(m.downs_caused))
		m.card.assists += int(m.assists)
		## AND THE CLUB'S BOOK, written at the moment it happens. A record
		## computed by scanning the roster would lose everything a retired man
		## ever did, which is most of the history of any club worth having one.
		world.note_record("downs_event", int(m.downs_caused),
			m.card.display_name, world.season)
		world.note_record("downs_career", m.card.downs, m.card.display_name, world.season)
		world.note_record("events", m.card.bouts, m.card.display_name, world.season)
		world.note_record("standing", m.card.rounds_standing,
			m.card.display_name, world.season)
		world.note_record("rating", m.card.overall(), m.card.display_name, world.season)

	## ------------------------------------------------------- who sat, and who
	## PRIMA DONNA — *"Sours every event he does not start."*
	##
	## Everybody on the eight who was not one of the five. It runs over the club's
	## own roster and not over `sim.men`, because the men who did not play are
	## exactly the ones `sim.men` has never heard of — a loop over who fought can
	## never find who did not, which is the shape of the bug this trait would
	## otherwise have had.
	var played := {}
	for m in sim.men:
		if m.team == 0 and m.card != null:
			played[m.card] = true
	for f in club.active_eight():
		if played.has(f):
			continue
		var sour := FighterTrait.mod(f.trait_id, "benched_morale", 0.0)
		if sour != 0.0:
			f.morale_shift(sour)
			_note_change("trait", f.display_name,
				"Prima Donna — sat out and did not take it well", -1)

	## TALISMAN — *"Lifts the room while he is here. Guts it when he goes."*
	##
	## The dressing room and not the field. Every in-fight version of this was
	## measured and every one was either enormous or nothing — the figures are in
	## the note on `MeleeSim._rally`. Morale is where a room trait belongs anyway:
	## it is bounded by construction, it already has measured effects all through
	## the club layer, and "lifts the room" is a sentence about a squad rather
	## than about a clinch.
	##
	## AND THE SECOND HALF IS THE POINT OF IT. While he is fit and on the eight,
	## everybody else lifts. While he is on the books and cannot go out, the same
	## men drop by half as much — that is what *guts it when he goes* means on a
	## week a club can actually see.
	for t in club.active_eight():
		var lift := FighterTrait.mod(t.trait_id, "room_morale", 0.0)
		if lift == 0.0:
			continue
		var here: bool = t.fit()
		for f in club.active_eight():
			if f == t:
				continue
			f.morale_shift(lift if here else -lift * 0.5)
		_note_change("trait", t.display_name,
			"Talisman — the room is better for him being out there" if here
			else "Talisman — the room felt him missing", 1 if here else -1)

	## GRUDGE — *"Fights above himself against one named club, forever."*
	##
	## Named by the first club that beats him while he is on your eight, which is
	## a thing that actually happens to people and needs no new screen. Set once
	## and never cleared: a grudge that expires is a preference.
	## WHO HE IS ANGRY AT IS WHO HE JUST FOUGHT, and that is a fact about the
	## BOUT, so the bout is what is asked. It used to ask `opponent_id()`, the
	## next name on the LEAGUE fixture list — correct on a Saturday and wrong on
	## a cup night, when `post_cup_bout` calls this same function: lose a tie to
	## Bristol and your man swore lifelong revenge on whoever you happened to
	## play next, by name, on the report.
	var beat_us := sim.opponent_club_id
	if sim.bout_winner() == 1 and beat_us >= 0 and beat_us < world.clubs.size():
		for m in sim.men:
			if m.team != 0 or m.card == null or m.card.grudge_club >= 0:
				continue
			if FighterTrait.mod(m.card.trait_id, "grudge", 1.0) == 1.0:
				continue
			m.card.grudge_club = beat_us
			_note_change("trait", m.card.display_name,
				"Grudge — he will not forget %s" % String(
					world.clubs[beat_us]["name"]), -1)


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


func _award_sim_xp() -> void:
	for f in club.starting_five():
		f.xp += XP_SIMMED
		## A simmed event is still an event he turned up to. It pays no downs,
		## because nobody watched him cause any.
		f.bouts += 1


## Play the matchday without fighting it — a bye, or the player choosing to sim.
func skip_event() -> void:
	_award_sim_xp()
	var opp := opponent_id()
	var was_home: bool = venue_kind() == Venue.Kind.HOME
	var before := _my_row()
	var was := _my_row()
	world.play_event()
	var now := _my_row()
	_after_event(int(now["rf"]) - int(was["rf"]), int(now["ra"]) - int(was["ra"]))
	## AND THE WEEK STILL HAPPENED.
	##
	## `_apply_regime()` ran from `post_bout` and not from here, so a SIMMED event
	## cost no morale drift and no kit wear at all: `tools/probe_kit.gd` walked
	## twenty-four simmed events and the squad finished on exactly the harness it
	## started with. Fighting your bouts wore your armour out and skipping them
	## did not, which is a discount for not playing the game — and it is the kind
	## of asymmetry a player finds by accident and then never fights again.
	_apply_regime()
	_log(opp, before, false, was_home)
	event_played.emit(opp, [])


## Everything that happens to the club because an event happened: credits for
## the result, morale, and a week off the treatment table.
func _after_event(rf: int, ra: int) -> void:
	## THE CROWD IS PAID FIRST, and it is paid whatever the result. A fight in
	## front of a house that knows who you are is worth money because it was
	## watched, not because it was won — that is the whole point of banding it.
	## The result then pays on top, so a win in a big year is worth a great deal
	## more than the same win was worth in a small one.
	##
	## Note the ORDER: the pay is read BEFORE `note_after` moves notoriety, so
	## the fight pays the band the club had when it walked out. Paying after
	## would let a single win push a club over a gate and then pay the new band
	## for the fight that crossed it, which is a half-band of free money on every
	## crossing and reads as a bug the first time a player notices it.
	## AND THE GATE IS ONLY YOURS AT HOME — Pete, 14 Sep 2026. A club that took
	## its gate on the road is a club with no reason to build an arena, which is
	## the whole of the Arena screen. `Venue.pays_the_gate` is the one place that
	## rule lives, so a second earner added next year cannot quietly disagree
	## with it.
	if Venue.pays_the_gate(venue_kind()):
		office.take(office.crowd_pay(), "The gate", "event")
	if rf > ra:
		office.take(CREDITS_WIN, "Won the event", "event")
		office.morale_after(true, false)
	elif rf == ra:
		office.take(CREDITS_DRAW, "Drew the event", "event")
		office.morale_after(false, true)
	else:
		office.morale_after(false, false)
	## THE RESULT LANDS ON EVERY MAN, and then the difficult ones land on
	## everybody else.
	##
	## Retro Bowl's own tip: *"Toxic players bring down the attitudes of team
	## mates after a loss."* That is what makes a toxic man a decision rather
	## than a bad stat — he is fine while you are winning.
	var won: bool = rf > ra
	var drew: bool = rf == ra
	var swing := ClubOffice.MORALE_WIN if won else (0.0 if drew else ClubOffice.MORALE_LOSS)
	swing += float(office.arena.level) * ClubOffice.MORALE_GROUND
	## THE MOOD, BEFORE AND AFTER, PER MAN. The swing is the same for everybody
	## and the WORD is not — `morale_shift` is a logistic, so the same nudge moves
	## a contented man a little and a struggling one a lot, and the report is
	## about the men who crossed a band rather than about the number.
	var before := {}
	for f in club.active_eight():
		before[f] = f.morale_word()
	for f in club.active_eight():
		f.morale_shift(swing)
	for f in club.active_eight():
		if f.morale_word() != String(before[f]):
			_note_change("mood", f.display_name,
				"%s to %s" % [String(before[f]).to_lower(),
					f.morale_word().to_lower()],
				1 if f.morale > 0.5 else -1)
	if not won and not drew:
		## LIKEABLE. *"Toxic players ($pos) have no negative impact on teammates."*
		## A captain who is good to be around does not fix the difficult man — he
		## still fights angry, he still costs you nothing on a win — he just stops
		## him taking the room down with him. So the trait is read PER TOXIC MAN,
		## against the role that man stands in, rather than as a club-wide switch:
		## your Rail captain cannot cover for a poisonous Center.
		## POISON counts double and THICK SKIN does not count at all — one on each
		## side of the same sum, which is the same shape as Bear against Anchor and
		## for the same reason: a club can field both and have them cancel.
		var poison := 0.0
		for f in club.active_eight():
			if f.toxic() and not office.trait_covers(
					ClubOffice.Trait.LIKEABLE, Tuning.role_of(int(f.pos))):
				poison += FighterTrait.mod(f.trait_id, "toxic_weight", 1.0)
		if poison > 0.0:
			for f in club.active_eight():
				if f.toxic() or FighterTrait.flag(f.trait_id, "immune_toxic"):
					continue
				f.morale_shift(TOXIC_DRAG * poison)
	office.sync_morale(club)
	for f in club.roster:
		if f.injury > 0:
			f.injury -= 1
	## The following moves with the result, and then the show goes on if it is
	## due. In that order, because a tournament is drawn against the standing you
	## have on the day of it.
	office.note_after(rf > ra, rf == ra, world.player_tier())
	## AND IT GOES IN YOUR BOOK TOO. The club's record is the club's; this one
	## follows you out of the door when you take another job, which is the only
	## reason to keep a second copy of the same three numbers.
	coach.note_result(rf > ra, rf == ra)
	if _event_due():
		_settle_event()
	_draw_dilemma()
	## A NEW WEEK. The throttle that lets a club work on each building once per
	## matchday is cleared here, so "a week" means the same thing to the Clubhouse
	## as it does to the fixture list — see ClubOffice.new_week.
	office.new_week()
	_roll_availability()
	sync_power()


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
## 2. IT IS WHY THE BENCH IS WORTH BUYING. A club travelling five has no answer
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


func _roll_availability() -> void:
	## A FRESH STREAM PER WEEK, seeded on the week, rather than a draw from the
	## season-long roster stream.
	##
	## It used `_roster_rng()` at first, which is a stateful stream whose POSITION
	## is not saved — it is rebuilt from the world seed and the season number on
	## demand. The winter drew from it once a year and nothing noticed. Drawing
	## from it every week meant a reloaded save restarted the stream from the
	## beginning, rolled different men unavailable, and the two worlds came apart:
	## `the world continues the same` went red, which is exactly the check that
	## exists to catch a save carrying less state than the game is using.
	##
	## Seeding on (season, event) removes the state instead of saving it. Same
	## answer every time, no position to keep.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("avail:%d:%d:%d" % [world.rng.seed, world.season, world.event])
	var gone := 0
	for f in club.roster:
		## LAST WEEK'S EXCUSE IS OVER. Cleared for everybody first, including the
		## men who were out, so this is a state of one weekend and not a flag that
		## accumulates until the squad is all crosses.
		f.available = true
	for f in club.active_eight():
		if gone >= AVAILABILITY_MAX:
			break
		## A man already out with a knock does not also need the weekend off. The
		## two would read as one problem on the screen and cost twice.
		if f.injury > 0:
			continue
		if rng.randf() < AVAILABILITY_CHANCE:
			f.available = false
			gone += 1


## THE YEAR ADDED UP — every week fought, not the handful a screen has room for.
##
## It lives here rather than in the review page because a total computed inside a
## `_draw()` is a total nothing can check, and because the page shows the last
## nine rows: *a total of what happens to be on screen is not a total.* The
## screen slices; the season counts.
func year_summary() -> Dictionary:
	var fought := 0
	var simmed := 0
	var rf := 0
	var ra := 0
	var diff := 0
	var byes := 0
	for r in results:
		if bool(r.get("bye", false)):
			byes += 1
			continue
		if bool(r.get("fought", true)):
			fought += 1
		else:
			simmed += 1
		rf += int(r.get("rf", 0))
		ra += int(r.get("ra", 0))
		diff += int(r.get("margin", 0))
	return {
		"events": fought + simmed, "fought": fought, "simmed": simmed,
		"byes": byes, "rf": rf, "ra": ra, "diff": diff,
	}


func _my_row() -> Dictionary:
	return (world.tables[world.player_tier()][world.player_club] as Dictionary).duplicate()


## `at_home` IS PASSED IN, NOT ASKED FOR, and that is not fussiness.
##
## Both callers run this AFTER `world.play_event()` has ticked the week, so
## `venue_kind()` in here would answer about the NEXT fixture — the club would
## log every away day as a home one whenever the following week happened to be
## at home. It is the identical mistake `post_bout` already carries a note about
## for `opponent_id()`, three lines further up the same function, and it would
## have been invisible until somebody read a season review and wondered why the
## club never travelled.
func _log(opp: int, before: Dictionary, fought: bool, at_home: bool) -> void:
	if opp == -1:
		results.append({ "opponent": -1, "bye": true, "fought": false })
		return
	var now := _my_row()
	results.append({
		"opponent": opp, "bye": false, "fought": fought,
		"rf": int(now["rf"]) - int(before["rf"]),
		"ra": int(now["ra"]) - int(before["ra"]),
		"margin": League.margin_diff(now) - League.margin_diff(before),
		## HOW IT WAS FOUGHT, not just that it was.
		##
		## Pete, 14 Sep 2026, on a losing career: *"which can be turned around by
		## spending CC currency, bringing the difficulty down, or just fighting
		## better/smarter."* He is right, and dropping the grade when a season
		## goes bad is a real lever that should stay — Retro Bowl's own season
		## review carries a `Diff` column on every week for exactly that reason.
		##
		## So the record remembers. A row that says the club won its division
		## while fighting FRIENDLY is a different row from one that says it won
		## the same division on THE HARD LIST, and a cabinet that cannot tell
		## them apart is a cabinet that is not really keeping score.
		##
		## MATCHED carries its step too, because MATCHED is not one difficulty —
		## it is a dial the season moves under the player, and "Matched 7" and
		## "Matched 2" are further apart than two of the fixed grades.
		"grade": grade,
		"step": matched_step,
		"home": at_home,
	})


# ----------------------------------------------------------------- the bid
## Is the federation waiting on you? Answered before the season starts, the same
## way a cup tie is answered before the next matchday — a decision the game
## stops and asks for is a decision the player notices making.
func bid_open() -> bool:
	return not bid_offers.is_empty()


## Put the year's dates on the table. Called at the start of every season,
## including the first, and only when the club has no tournament already running.
func open_bids() -> void:
	if booked != null:
		return
	bid_offers = ClubEvent.offers(world.events_this_season(),
		world.player_tier())


## Take a date. The bid and the budget are both spent NOW, a season before the
## show — which is the whole shape of it. What you do to your ground and your
## following between here and there is what decides whether it comes back.
func take_bid(offer_i: int, budget_i: int) -> String:
	if not bid_open():
		return "There is nothing on the table."
	if offer_i < 0 or offer_i >= bid_offers.size():
		return "No such date."
	var offer: Dictionary = bid_offers[offer_i]
	var b: Dictionary = ClubEvent.BUDGETS[clampi(budget_i, 0, ClubEvent.BUDGETS.size() - 1)]
	var total := int(offer["bid"]) + int(b["cost"])
	if office.credits < total:
		return "The date and the budget come to %d CC and you have %d." % [
			total, office.credits]
	office.credits -= total
	booked = ClubEvent.tournament(offer, office.arena, budget_i)
	bid_offers.clear()
	return ""


## Or pass on the year. Free, and it has to be — a club that cannot afford a
## date must still be able to get on with its season.
func decline_bid() -> void:
	bid_offers.clear()


func bid_preview(offer_i: int, budget_i: int) -> Dictionary:
	if offer_i < 0 or offer_i >= bid_offers.size():
		return {}
	var offer: Dictionary = bid_offers[offer_i]
	return ClubEvent.preview(office.arena.capacity(), office.fans, office.notoriety,
		budget_i, int(offer["bid"]))


# --------------------------------------------------------------------- cups
## THE TIE IN FRONT OF YOU, or null. One at a time and in a fixed order — the
## domestic cups before the Worlds — so a player never has two brackets asking
## him for a result and no way to say which is which.
func pending_cup() -> Cup:
	for c in world.open_cups():
		if not c.player_match().is_empty():
			return c
	return null


## ANY CUP WORTH LOOKING AT, whether or not it is waiting on you.
##
## `pending_cup()` only answers while a tie of yours is unplayed, and the draw
## screen was reachable from nowhere else — so the moment you were knocked out,
## the bracket you had just been knocked out of became unviewable, and the
## CHAMPION line on that screen was code no player could reach. A cup is most
## interesting in the ten seconds after you lose.
##
## Prefers one you are still in, then any running cup, then the last one that
## finished this season.
func viewable_cup() -> Cup:
	var mine := pending_cup()
	if mine != null:
		return mine
	for c in world.open_cups():
		return c
	var best: Cup = null
	for c in world.cups:
		if c.entrants.has(world.player_club):
			best = c
	if best != null:
		return best
	if world.worlds != null and world.worlds.entrants.has(world.player_club):
		return world.worlds
	return null


## Is a bracket waiting on the player? The season cannot roll over while one is,
## and the Club screen shows the tie instead of the league fixture.
func cup_pending() -> bool:
	return pending_cup() != null


func cup_opponent() -> int:
	var c := pending_cup()
	if c == null:
		return -1
	var m := c.player_match()
	return int(m["b"]) if int(m["a"]) == world.player_club else int(m["a"])


## Fight your own cup tie. The same MeleeSim a league fixture builds, with the
## same captains and the same drawn plan — a cup match is a bout, not a special
## case, and the moment it stops being one the two paths start to drift.
func begin_cup_bout() -> MeleeSim:
	var c := pending_cup()
	if c == null:
		return null
	opponent = club_for(cup_opponent())
	var s := hash("cup:%d:%d:%d:%d" % [seed_value, world.season, world.event, cup_opponent()])
	var sim := MeleeSim.new(club, opponent, s, opposition_scale(cup_opponent()))
	## NEUTRAL GROUND AND A REAL TRIP. `venue_kind()` already answers NEUTRAL
	## while a tie is pending, so it is asked rather than re-decided here; the
	## distance is to the club you are actually fighting, which on a cup night is
	## not the one the league has you down for.
	_dress_sim(sim, cup_opponent(), venue_kind(),
		world.miles_between(world.player_club, cup_opponent()))
	return sim


## Post a fought cup tie, then play the rest of the round out around it.
func post_cup_bout(sim: MeleeSim) -> void:
	var c := pending_cup()
	if c == null:
		return
	var m := c.player_match()
	var mine: bool = int(m["a"]) == world.player_club
	last_result = [sim.rounds_won[0], sim.rounds_won[1], sim.margin[0], sim.margin[1]]
	## A CUP TIE IS A FIGHT. It moves MATCHED exactly as a league fixture does —
	## the grade describes how hard the country is fighting you, and the country
	## does not stop on a Tuesday night.
	_grade_bout(int(last_result[0]), int(last_result[1]))
	_apply_injuries(sim)
	_award_xp(sim)
	if mine:
		c.record(m, sim.rounds_won[0], sim.rounds_won[1], sim.margin[0], sim.margin[1])
	else:
		c.record(m, sim.rounds_won[1], sim.rounds_won[0], sim.margin[1], sim.margin[0])
	_finish_cup_round(c, int(m.get("winner", -1)) == world.player_club)


## Or hand it to the AI. Same road afterwards.
func sim_cup_tie() -> void:
	var c := pending_cup()
	if c == null:
		return
	var m := c.player_match()
	var res: Array = world.quick_bout(int(world.clubs[int(m["a"])]["power"]),
		int(world.clubs[int(m["b"])]["power"]))
	c.record(m, int(res[0]), int(res[1]), int(res[2]), int(res[3]))
	_finish_cup_round(c, int(m.get("winner", -1)) == world.player_club)


## Everything that happens once the player's tie is in the book: the rest of the
## round is played around him, the bracket moves on, and a finished cup is
## retired — with the gate settled if it was his own show.
func _finish_cup_round(c: Cup, won: bool) -> void:
	c.sim_others(world.cup_resolver())
	while c.round_complete() and not c.is_over():
		if not c.advance():
			break
		c.sim_others(world.cup_resolver())
	office.morale_after(won, false)
	office.note_after(won, false, world.player_tier())
	## The bronze match, on the path the player actually walks. `run_all` played
	## it; this route never did, so third place did not exist in a cup anybody
	## fought through.
	c.settle_third(world.cup_resolver())
	if c.is_over():
		## YOU WON SOMETHING. The fanfare is played here rather than left to the
		## mood system, because a mood is a state you are in and this is a moment
		## that has just passed — by the time the screen redraws, the tie is
		## resolved and `mood()` has already gone back to normal.
		if c.champion == world.player_club:
			Audio.champion()
			## Everybody who travelled gets the honour, not only the five who
			## were on the line for the final — a cup is won by an eight.
			for f in club.active_eight():
				f.honours += 1
		if booked != null and booked.cup == c:
			_settle_gate(booked, c)
		else:
			world.retire_cup(c)
	sync_power()


## The cup path uses the same rule as the league path, because it was two copies
## of one rule and that is how the two ended up disagreeing about what an injury
## costs.
func _apply_injuries(sim: MeleeSim) -> void:
	_apply_bout_injuries(sim)


# ------------------------------------------------------------------- events
## Book a demo. Instant, unplayed, small and it cannot lose — this is what a
## club with no following and an empty week does.
func run_demo() -> String:
	if booked != null:
		return "You already have %s in the diary." % booked.kind_name().to_lower()
	## ONCE A WEEK, and without this the game has no economy.
	##
	## `run_demo` never set `booked`, and the button's only guard was
	## `booked == null`, so it came back on every rebuild of the screen. Forty
	## taps on a Backyard club is forty credits — both facilities, two captains,
	## the arena and four cap raises, in one sitting, from a button meant to pay
	## one credit for an empty week. Every price in the game was a suggestion.
	##
	## It goes through the same per-week throttle as an upgrade rather than
	## getting its own flag, because a second throttle is a second thing to
	## forget to reset.
	if office.done_this_week("demo"):
		return "You have already put a demo on this week."
	var pay: int = ClubEvent.DEMO_PAY[clampi(office.arena.level, 0, ClubEvent.DEMO_PAY.size() - 1)]
	office.take(pay, "A demo at the ground", "event")
	## A demo keeps you on the calendar. Barely — a quarter of the turnout a real
	## event would pull, and no promotion behind it.
	var heads := int(float(ClubEvent.attendance(office.arena.capacity(), office.fans,
		office.notoriety)) * 0.25)
	office.crowd_came(heads)
	office.mark_this_week("demo")
	last_show = {
		"kind": "Demo", "heads": heads,
		"gate": pay, "cost": 0, "net": pay, "finish": "", "podium": 0,
	}
	return ""


## Does the booked event land on this matchday? Called as the event advances.
func _event_due() -> bool:
	return booked != null and not booked.settled and world.event >= booked.due


## PUT THE SHOW ON. The field is drawn from clubs near your own strength, the
## Cup machinery runs it exactly as it runs an Invitational, and the gate is
## settled against the following you had on the day rather than the one you had
## when you booked it.
## PUT THE SHOW ON. The field is drawn from clubs near your own strength and the
## Cup machinery runs it exactly as it runs an Invitational — and YOU ARE IN IT,
## so the bracket waits for you the same way a King's Cup does. The gate is not
## counted until the cup is finished, because the podium is part of the payout
## and there is no podium until somebody has won it.
func _settle_event() -> void:
	var e := booked
	var field := _invite_field(e)
	e.cup = Cup.new("%s Invitational" % club.short_name, field,
		hash("show:%d:%d" % [seed_value, e.due]), world.player_club, false)
	## AN ID, so a save can find its way back to this cup. Every other cup in
	## the world gets one from `league_world.gd`; the one the player pays for
	## was the only one without, which is why a reload orphaned it.
	e.cup.set_meta("id", "show:%d" % e.due)
	world.cups.append(e.cup)
	## Everything that is not yours in the opening round, so the bracket is
	## ready to ask you for a result the moment the screen opens.
	e.cup.sim_others(world.cup_resolver())
	if not e.cup.player_alive():
		_settle_gate(e, e.cup)


## The money, once the bracket is done. Attendance is read against the
## following you have ON THE DAY rather than the one you had when you booked —
## two matchdays is long enough for that to have moved, and the gamble is the
## whole point of the feature.
func _settle_gate(e: ClubEvent, c: Cup) -> void:
	var heads := ClubEvent.attendance(office.arena.capacity(), office.fans,
		office.notoriety, float(ClubEvent.BUDGETS[e.budget]["draw"]))
	var g := ClubEvent.gate(heads, float(ClubEvent.BUDGETS[e.budget]["take"]))
	var podium := 0
	if c.champion == world.player_club:
		podium = ClubEvent.PODIUM[0]
	elif c.runner_up == world.player_club:
		podium = ClubEvent.PODIUM[1]
	elif c.third == world.player_club:
		podium = ClubEvent.PODIUM[2]
	office.take(g + podium, "The cup", "event")
	## A crowd is the loudest thing that can happen to a club, and everyone who
	## came is half a fan afterwards. An empty house is not punished twice — the
	## lost credits are punishment enough — so this only ever adds.
	office.crowd_came(heads)
	if podium > 0:
		office.note_shift(2.0)
	e.settled = true
	last_show = {
		"kind": e.kind_name(), "heads": heads, "gate": g, "cost": e.cost(),
		"net": g + podium - e.cost(), "finish": c.player_finish, "podium": podium,
	}
	e.report = last_show.duplicate()
	world.retire_cup(c)
	booked = null


## Who turns up. Eight clubs of roughly your own standard, because a tournament
## you cannot place in is not a tournament you would put money into — and a
## bigger budget reaches further up the list for names.
func _invite_field(e: ClubEvent) -> Array:
	var mine: int = int(world.clubs[world.player_club]["power"])
	var reach: int = 4 + e.budget * 7
	var pool: Array = []
	for id in world.clubs.size():
		if id == world.player_club:
			continue
		if absi(int(world.clubs[id]["power"]) - mine) <= reach:
			pool.append(id)
	pool.sort_custom(func(a, b): return int(world.clubs[a]["power"]) > int(world.clubs[b]["power"]))
	var field: Array = [world.player_club]
	for id in pool:
		if field.size() >= ClubEvent.FIELD:
			break
		field.append(id)
	## A thin country still gets a full draw; the weakest clubs make up the
	## numbers rather than the bracket being short.
	var i := 0
	while field.size() < ClubEvent.FIELD and i < world.clubs.size():
		if i != world.player_club and not field.has(i):
			field.append(i)
		i += 1
	field.sort_custom(func(a, b): return int(world.clubs[a]["power"]) > int(world.clubs[b]["power"]))
	return field


## The last event, or {} at the start of a season.
func last_event() -> Dictionary:
	return results[results.size() - 1] if not results.is_empty() else {}


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
func release(f: FighterCard) -> String:
	var was_toxic: bool = f.toxic()
	var err := club.cut(f)
	if err != "":
		return err
	for other in club.active_eight():
		other.morale_shift(CUT_TOXIC if was_toxic else CUT_LIKED)
	office.sync_morale(club)
	sync_power()
	return ""


## Letting a menace go clears the air; letting a good man go does not.
const CUT_TOXIC: float = 0.07
const CUT_LIKED: float = -0.05


func blocked_by() -> String:
	if bid_open():
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
	return ""


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

## The last few ids, so the deck does not deal the armourer's bill three
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

## What the winter did: points gained, points lost to age, who retired, who was
## brought on. Read by the season screen — a squad that quietly loses two men
## over a summer is a bug report waiting to happen.
var last_winter: Dictionary = {}

## What the last summer's bills came to, and anything that fell down because
## they could not be paid. Read by the season screen; empty until a roll-over.
var last_upkeep: Dictionary = {}

const CREDITS_WIN: int = 2
const CREDITS_DRAW: int = 1
const CREDITS_BY_POSITION := [6, 4, 2]
const CREDITS_PROMOTED: int = 4


func roll_over() -> void:
	results.clear()
	last_winter = {"gained": 0, "lost": 0, "retired": [], "prospect": "",
		"walked": [], "signed": []}
	## A NEW SUMMER IS A NEW MARKET. The pool is keyed on the season number, so
	## clearing this is what opens it — and it has to happen before `world.season`
	## advances or the list the player was looking at yesterday stays closed.
	market_taken.clear()
	var before := world.player_tier()
	var finished := position()
	world.roll_over()
	sync_power()
	var after := world.player_tier()
	## The summer: prize money, the gate from hosting, and the winter's training.
	if finished >= 1 and finished <= CREDITS_BY_POSITION.size():
		office.take(CREDITS_BY_POSITION[finished - 1], "Finished %d" % finished, "season")
	if after > before:
		office.take(CREDITS_PROMOTED, "Went up", "season")
		office.note_shift(ClubOffice.NOTE_PROMOTED)
	elif after < before:
		office.note_shift(ClubOffice.NOTE_RELEGATED)
	office.take(office.gate_income(), "A season of gates", "season")
	## THE DUES. Banked before the bills, because that is what they are for — the
	## members' money is the income that does not move with results, and it is
	## the money the federation's bill is actually competing for.
	office.take(office.dues(), "Members' dues", "season")
	## AND THEN THE BILLS. Deliberately after the retainer and the prize money and
	## deliberately before the training: a club should be paid for the year it had
	## and then asked what it costs to keep what it owns, in that order, because
	## that is the order a player reasons about it in. Anything it cannot cover
	## sheds a level — see ClubOffice.pay_upkeep.
	last_upkeep = office.pay_upkeep()
	## The summer: people forget, and a following bleeds if it is not fed.
	office.winter()
	## THE STAFF ARE ON DEALS TOO, and a captain whose contract ran out has gone
	## before the winter's training rather than after it — the roles he taught are
	## untaught for that winter, which is the cost of having let it lapse.
	last_staff_left = office.age_captains()
	_train()
	for f in club.roster:
		f.injury = 0            ## nobody carries a knock across a winter
	sync_power()

	## THE BID IS PART OF THE SUMMER. New division, new calendar, new dates — and
	## a promoted club is offered a longer season with later, dearer slots in it.
	open_bids()

	## WHAT THE YEAR DID TO YOUR NAME. After the club's summer, because a
	## reputation is read off where the club finished and the club has to have
	## finished first.
	##
	## `finished` was taken before `world.roll_over()` — the table is rebuilt in
	## there — so it is the position you actually came, not the one you start the
	## new season in. Getting those two the wrong way round would have paid a
	## promoted club for finishing first in a division it had already left.
	coach.after_division(finished)
	## AND WHAT THE CUPS DID. Every bracket that resolved this year and had you in
	## it pays by how far you went — the size of the round you went out in, which
	## is the key `Coach.REP_BY_CUP_EXIT` is written on.
	for h in honours():
		if int(h.get("season", -1)) != world.season:
			continue
		var exit_size := int(h.get("exit", -1))
		if exit_size > 0:
			coach.after_cup(exit_size)
	coach.note_season(after > before, after < before, _won_a_cup_this_year())

	## AND THEN THE CLUB MAY COME APART. Last, after everything else the summer
	## does, because a squad that is about to lose half its men should still have
	## been paid, trained and aged first — the men who walk take the winter they
	## earned with them, which is what makes the rival dangerous rather than a
	## collection of last year's numbers.
	## WHO STAYED AND WHO WALKED. After the results and after the bills, because a
	## member is deciding whether the place was worth belonging to this year and
	## the answer includes whether the club could keep the lights on.
	##
	## NOT compliance — see the note at the top of `Federation`. Members leaving
	## over paperwork would make both masters want the same thing and collapse the
	## pillar into one slider.
	var bench_full: bool = club.active_eight().size() >= office.travel_slots
	var was_members := office.members
	office.members = Federation.members_after(office.members,
		finished <= int(League.club_count(before) / 2), office.morale, bench_full)
	last_members = {"was": was_members, "now": office.members}

	last_split = _maybe_split(finished, before, after)

	var h: Dictionary = world.history[world.history.size() - 1] if not world.history.is_empty() else {}
	season_finished.emit(int(h.get("position", -1)), after > before, after < before)


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


func _maybe_split(place: int, tier_before: int, tier_after: int) -> Dictionary:
	var field: int = League.club_count(tier_before)
	if not ClubSplit.fractures(office.morale, place, field, tier_after < tier_before,
			world.season):
		return {}

	## WHO THEY TAKE. The men who have actually been fighting are the ones with a
	## reason to stay, so the lineup the player has been picking all season is
	## half of the input — see `ClubSplit.who_walks`.
	var picked: Array = club.active_eight()
	var leaving: Array = ClubSplit.who_walks(club.roster, picked)
	if leaving.is_empty():
		return {}

	## WHERE THEY GO. The pyramid has a fixed number of clubs per division and
	## the fixture list is built off that count, so a breakaway cannot simply be
	## appended — a seventh club in a six-club division breaks every table in the
	## world. They take over the weakest club in your own division instead, which
	## is also what actually happens: a breakaway group does not build a club from
	## nothing, it absorbs one that was already dying.
	##
	## And it has to be YOUR division, because the direction document is specific
	## about the payoff: *"a rival club across town that you now have to fight."*
	var victim := -1
	var worst := 1 << 30
	for cid in world.clubs_in(world.player_tier()):
		if cid == world.player_club:
			continue
		var p := int(world.clubs[cid]["power"])
		if p < worst:
			worst = p
			victim = cid
	if victim < 0:
		return {}

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("split:%d:%d" % [seed_value, world.season])
	var parent := String(world.clubs[world.player_club]["name"])
	var new_name := ClubSplit.name_for(parent, rng)

	## Move the men. `cut` is not used: they are not being released, they are
	## walking, and the morale consequences of a cut would be nonsense here — the
	## room they would lift is the room that just emptied.
	var took: Array[String] = []
	var carried: Array = []
	for f in leaving:
		club.roster.erase(f)
		## THEY ALL TRAVEL NOW. The men who walk are, by construction, the ones who
		## were not being picked — so most of them arrive carrying `active = false`
		## from the squad they just left. Founding the rival without clearing that
		## produced a club whose entire line was WALK-ONS while the five men who
		## actually walked sat in its reserve: a breakaway that fielded strangers,
		## which is the one thing this system exists not to do.
		##
		## It passed every check I had written, because "can the rival field five"
		## was true — it just was not fielding any of them. What caught it was a
		## note printing `active_eight().size()` as 0 next to a sentence saying the
		## club was made of these men.
		f.active = true
		carried.append(f)
		took.append(f.display_name)

	## THE RIVAL IS THOSE MEN. Any slots they cannot fill are walk-ons at the
	## division's floor, so a breakaway of six is a real club and not a forfeit.
	var typed: Array[FighterCard] = []
	for f in carried:
		typed.append(f)
	var rival := MeleeClub.build(new_name, ClubSplit.short_for(new_name),
		Color(0.55, 0.16, 0.16), Color(0.9, 0.85, 0.7), 0, typed)
	rival.travel_cap = MeleeClub.ACTIVE_SIZE
	var guard := 0
	## `starting_five()` does not pad with nulls when it comes up short — it
	## returns a SHORT array and says so by its size. Asking it `.has(null)` is a
	## question it can never answer yes to, so this loop never ran and the
	## breakaway club was whatever the split left it, line or no line.
	while rival.starting_five().size() < MeleeClub.LINE_SIZE and guard < MeleeClub.SQUAD_MAX:
		guard += 1
		var w := ClubFactory.walk_on(rng, _missing_slot(rival), world.player_tier())
		if rival.sign(w) != "":
			break
		w.active = true

	world.clubs[victim]["name"] = new_name
	world.clubs[victim]["short"] = ClubSplit.short_for(new_name)
	world.clubs[victim]["power"] = rival.power()
	world.clubs[victim]["splinter"] = true
	_clubs[victim] = { "club": rival, "power": rival.power() }
	## THE WHOLE CLUB, NOT THE MEN WHO WALKED.
	##
	## `carried` is the breakaway itself — the men who left you — and storing
	## only those was right up until the loop above started running. It fills the
	## line with walk-ons, and those walk-ons are part of the club from that
	## moment on: they are in `rival`, they are in `rival.power()`, and that power
	## is what the whole league table is built on.
	##
	## They were not in the save. So a reloaded career rebuilt the breakaway from
	## the carried men ALONE — and a breakaway of three cannot field five, which
	## made its power zero and handed the player a walkover he had not earned. The
	## bout that decided his season came out 0-2 in a game played straight
	## through and 2-1 in the same game reloaded, and the divergence spread from
	## there through the table, the drift and his own development.
	##
	## What the save has to carry is the CLUB, because the club is what plays.
	var whole: Array[FighterCard] = []
	for f in rival.roster:
		whole.append(f)
	splinter_rosters[victim] = whole

	## And the club you have left has to be able to field five. `_fill_squad`
	## already knows how to sign walk-ons at the position that is actually
	## missing, so the recovery goes through the same road as a bad winter.
	var replacements := _fill_squad()
	sync_power()
	office.sync_morale(club)

	return {
		"club": new_name, "id": victim, "took": took,
		"replacements": replacements, "season": world.season,
	}


## Which line slot a club cannot currently fill. Used when a breakaway is short.
func _missing_slot(c: MeleeClub) -> int:
	var five := c.starting_five()
	for slot in five.size():
		if five[slot] == null:
			return slot
	return Tuning.Pos.CENTER


## Did we lift anything this year? Read off the honours the world already keeps
## rather than counted separately as the cups resolve — one source, so the
## coach's cup count and the trophy cabinet cannot disagree.
func _won_a_cup_this_year() -> bool:
	for h in honours():
		## BOTH HALVES. The cabinet records EVERY cup the world resolved, not only
		## the ones you were in, so a season check alone would have credited you
		## with every trophy anybody lifted that year.
		if int(h.get("season", -1)) == world.season \
				and int(h.get("champion", -1)) == world.player_club:
			return true
	return false


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

func _train() -> void:
	_ground_used = 0
	var points := office.training_points()
	var pool: Array = club.roster.duplicate()
	pool.sort_custom(func(a, b): return a.overall() < b.overall())

	## THE PROSPECT, banked during the season and cashed here. One man, once a
	## year, and only with a Training ground built up to take it — the one scarce
	## way a ceiling moves.
	if prospect != null and club.roster.has(prospect) \
			and office.level(ClubOffice.Facility.TRAINING) >= Career.PROSPECT_GROUND:
		prospect.potential = mini(Career.POTENTIAL_CEILING,
			prospect.potential + Career.PROSPECT_GAIN)
		last_winter["prospect"] = prospect.display_name
	prospect = null

	## The ground's points are handed out round-robin from the bottom, and this
	## is the share each man may take out of the pool. Working out the share
	## first rather than looping a shared counter keeps `Career.winter` a pure
	## function of one fighter — it was a shared counter, and a lambda capturing
	## it by value was exactly the kind of bug this codebase has already paid
	## for twice.
	## CAPPED BY HEADROOM, AND THE REMAINDER COMES BACK.
	##
	## This used to hand points round-robin with no regard for how much room a
	## man had left, so a Training ground advertising "15 points a winter" with
	## three eligible men each one point under potential allotted five each,
	## spent three, and SILENTLY BURNED TWELVE — while the winter report said
	## "gained 3" and the Clubhouse went on promising fifteen.
	##
	## A man already at his ceiling is also included now if age is about to take
	## something off him: the decline happens inside `Career.winter`, after this
	## share is worked out, and it opens room that the old filter had already
	## refused him.
	var budget := points
	var eligible: Array = []
	for f in pool:
		if not office.taught(Tuning.role_of(int(f.pos))):
			continue
		if f.overall() < f.potential or Career.will_decline(f):
			eligible.append(f)
	var share := {}
	var i := 0
	var guard := 0
	while points > 0 and not eligible.is_empty() and guard < 4096:
		guard += 1
		var f: FighterCard = eligible[i % eligible.size()]
		i += 1
		var room: int = maxi(0, f.potential - f.overall())
		if Career.will_decline(f):
			room += 1
		if int(share.get(f, 0)) >= room:
			## Everyone full? Stop rather than spin.
			var any := false
			for g in eligible:
				var r2: int = maxi(0, g.potential - g.overall())
				if Career.will_decline(g):
					r2 += 1
				if int(share.get(g, 0)) < r2:
					any = true
					break
			if not any:
				break
			continue
		share[f] = int(share.get(f, 0)) + 1
		points -= 1

	var retired: Array[String] = []
	var gained := 0
	var lost := 0
	for f in club.roster.duplicate():
		var coached := office.taught(Tuning.role_of(int(f.pos)))
		var r := Career.winter(f, coached, int(share.get(f, 0)))
		gained += int(r["gained"])
		lost += int(r["lost"])
		_ground_used += int(r["ground"])
		## RETIREMENT IS ROLLED AFTER THE WINTER, on the man he has become. A
		## fighter who just lost three points to age is likelier to go than the
		## one he was in October, which is the order it happens in real life and
		## the only order in which `retire_chance` can read a current card.
		if _roster_rng().randf() < Career.retire_chance(f, office.morale):
			retired.append("%s (%d)" % [f.display_name, f.age])
			club.roster.erase(f)
	## WHAT THE GROUND DID NOT MANAGE TO SPEND goes round again, among the men
	## still on the books after the retirements — post-decline, so the room the
	## winter just opened is usable.
	var spare := budget - _ground_used
	var pass_guard := 0
	while spare > 0 and pass_guard < 64:
		pass_guard += 1
		var spent_this_pass := 0
		for f in club.roster:
			if spare <= 0:
				break
			if not office.taught(Tuning.role_of(int(f.pos))):
				continue
			var used := Career.train_only(f, 1)
			spare -= used
			spent_this_pass += used
			gained += used
		if spent_this_pass == 0:
			break
	last_winter["points"] = budget
	last_winter["unspent"] = maxi(0, spare)
	last_winter["gained"] = gained
	last_winter["lost"] = lost
	last_winter["retired"] = retired
	last_winter["walked"] = _settle_contracts()
	last_winter["signed"] = _fill_squad()
	sync_power()


## EVERY DEAL LOSES A YEAR, AND THE MEN WHO RAN OUT LAST SUMMER WALK.
##
## The two-stage shape is the whole feature. A deal reaching zero does not remove
## anybody — it puts him OUT OF CONTRACT, which is a state the player can see on
## the team sheet and do something about for a whole season. Only a man who was
## already out of contract, and whom nobody re-signed, actually leaves.
##
## Without that stage the player loses fighters to a number he was never shown
## changing, which is the same class of failure as a squad that quietly shrinks
## over a summer. With it, losing somebody is a decision he made by not making
## one — which is a fair thing for a game to do to you.
##
## WHETHER HE WAITS is rolled rather than certain, and rolled against the club's
## NOTORIETY: a fighter will hang on for a club people have heard of, and a good
## fighter at a club nobody has heard of will not. That is the arena system
## reaching a roster decision, which is the kind of connection that makes two
## features into one game.
func _settle_contracts() -> Array[String]:
	var walked: Array[String] = []
	var band: Array = League.TIERS[world.player_tier()]["power"]
	## Anyone who spent the whole of last season out of contract is decided
	## first, on the deal he had BEFORE this summer's tick — otherwise a man
	## signed in year one would be given a year of grace he never earned.
	for f in club.roster.duplicate():
		if f.years > 0:
			continue
		var wait := Contracts.will_wait(f, office.notoriety, int(band[1]), office.morale)
		if _roster_rng().randf() > wait:
			walked.append("%s (%d)" % [f.display_name, f.overall()])
			club.roster.erase(f)
	Contracts.age_deals(club.roster)
	return walked


## NOBODY TURNS UP TO AN EVENT WITH SEVEN MEN. Retirements land at the winter and
## they can leave the travelling eight short, or — after a bad run of them — leave
## the club unable to cover all five positions at all. That failure would not
## surface until the player was standing at the next event wondering why the
## Fight button was refusing him.
##
## Reserves come up first, because a club promotes from within before it phones
## round. Only when the books themselves are short does a walk-on get signed, and
## he is signed at the position that is actually missing rather than at whatever
## the generator felt like — see ClubFactory.walk_on.
##
## Returns the names taken on, so the summer can say so out loud.
func _fill_squad() -> Array[String]:
	var took: Array[String] = []
	while club.active_eight().size() < club.party_size():
		var up: FighterCard = null
		for f in club.reserves():
			up = f
			break
		if up == null:
			break
		up.active = true

	## THE PARTY GOES BACK TO FULL, not just to a line. The first pass signed
	## walk-ons only while the club could not fill a line, so a squad that
	## retired down to six men kept travelling with six: legal on the day, and a
	## club whose bench was one knock from being unable to fight. A 25-season
	## probe run found it as a roster of FIVE, which is the state that rule
	## allows and nobody would ever choose.
	var guard := 0
	while club.active_eight().size() < club.party_size() and guard < MeleeClub.SQUAD_MAX:
		guard += 1
		var w := ClubFactory.walk_on(_roster_rng(), _uncovered_slot(), world.player_tier())
		if club.sign(w) != "":
			break
		w.active = true
		took.append("%s (%s, %d)" % [w.display_name, w.pos_name(), w.overall()])
	return took


## Which place on the line the eight cannot fill. Counted by who COVERS the slot
## rather than who is listed for it, so a club short of a Center is not handed a
## second Rail on the grounds that the Rail slot has one man in it.
func _uncovered_slot() -> int:
	var eight := club.active_eight()
	var worst := int(Tuning.Pos.CENTER)
	var fewest := 99
	for slot in 5:
		var n := 0
		for f in eight:
			if f.fit() and Tuning.covers(int(f.pos), slot):
				n += 1
		if n < fewest:
			fewest = n
			worst = slot
	return worst


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
	return "%s  ·  %s" % [c.cup_name, c.round_name()]


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


func _draw_dilemma() -> void:
	if not dilemma.is_empty() or club.roster.is_empty():
		return
	## THE DECK HAS ITS OWN STREAM, and this is not a detail.
	##
	## The first version drew from `world.rng`, which is the stream every fixture,
	## every cup draw and every quick bout in the country comes out of. Three
	## draws per matchday — the chance, the card, the man — and the entire world
	## downstream of it shifted: `test_cupplay` went from seven green checks to
	## five failures reading *"no cup came up"*, because the Invitational's draw
	## had been reshuffled by a card about a brewery.
	##
	## A cosmetic system must never move the competitive one. So the deck derives
	## its own generator from the world seed and the matchday, exactly the way the
	## tournament bid dates and the free-agent pool already do: deterministic,
	## identical across a reload, and costing the world's stream nothing.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("deck:%d:%d:%d" % [world.rng.seed, world.season, world.event])
	if rng.randf() > DILEMMA_CHANCE:
		return
	var options: Array = []
	for c in Dilemma.CARDS:
		if not dilemma_recent.has(String(c["id"])):
			options.append(c)
	if options.is_empty():
		options = Dilemma.CARDS.duplicate()
	var card: Dictionary = options[rng.randi() % options.size()]
	var man := Dilemma.pick(int(card["who"]), club.roster, rng)
	dilemma = {
		"id": String(card["id"]),
		"man": club.roster.find(man),
		"rival": _last_opponent_name(),
	}
	dilemma_recent.append(String(card["id"]))
	while dilemma_recent.size() > DILEMMA_MEMORY:
		dilemma_recent.remove_at(0)


func _last_opponent_name() -> String:
	if results.is_empty():
		return "the other lot"
	var last: Dictionary = results[results.size() - 1]
	var id: int = int(last.get("opponent", -1))
	if id < 0 or id >= world.clubs.size():
		return "the other lot"
	return String(world.clubs[id]["name"])


## The card as the screen needs it: the text already filled in, and each option
## with its label and blurb. Empty when there is nothing to answer.
func dilemma_card() -> Dictionary:
	if dilemma.is_empty():
		return {}
	var card := Dilemma.by_id(String(dilemma["id"]))
	if card.is_empty():
		return {}
	var man := dilemma_man()
	var out := card.duplicate(true)
	out["body"] = Dilemma.fill(String(card["text"]),
		man.display_name if man != null else "somebody",
		club.display_name, String(dilemma.get("rival", "the other lot")))
	out["man"] = man
	return out


func dilemma_man() -> FighterCard:
	var i: int = int(dilemma.get("man", -1))
	return club.roster[i] if i >= 0 and i < club.roster.size() else null


## ANSWER IT. Returns what happened, in the club's own words, because a choice
## whose consequence is invisible is a choice the player stops making carefully.
##
## Every effect is applied through the office's own functions rather than by
## writing its fields — `note_shift` clamps, `_clamp_fans` exists for a reason,
## and a card that set `notoriety` directly would be the one place in the game
## that could push it past 125.
func answer_dilemma(option_i: int) -> String:
	var card := Dilemma.by_id(String(dilemma.get("id", "")))
	if card.is_empty():
		dilemma = {}
		return ""
	var opts: Array = card["options"]
	if option_i < 0 or option_i >= opts.size():
		return "Pick one."
	var fx: Dictionary = (opts[option_i] as Dictionary).get("fx", {})
	var man := dilemma_man()
	var said: Array[String] = []

	if fx.has("cc"):
		var d := int(fx["cc"])
		## A club cannot be taken below nothing by a card. The option stays
		## available and simply takes what there is — refusing the choice because
		## the club is skint would make the dilemma a quiz with the answers
		## greyed out, which is worse than the cost.
		var real: int = d if d >= 0 else -mini(-d, office.credits)
		office.credits += real
		said.append("%+d CC" % real)
	if fx.has("morale"):
		## Through `morale_shift`, not by writing the field — the logistic is the
		## only thing stopping a run of hard choices pinning a club at the floor,
		## and a card that set morale directly would be the one place in the game
		## that could do it.
		office.morale_shift(float(fx["morale"]))
		said.append("morale %s" % ("up" if float(fx["morale"]) > 0.0 else "down"))
	if fx.has("note"):
		office.note_shift(float(fx["note"]))
		said.append("talked about %s" % ("more" if float(fx["note"]) > 0.0 else "less"))
	if fx.has("fans"):
		office.crowd_came(int(office.fans * float(fx["fans"]) * 2.0))
		said.append("%d%% more following" % int(round(float(fx["fans"]) * 100.0)))
	if fx.has("kit"):
		for f in club.roster:
			f.armor = clampf(f.armor + float(fx["kit"]), 0.0, 1.0)
		said.append("harness %s across the club" % ("mended" if float(fx["kit"]) > 0.0 else "worse"))
	if man != null:
		if fx.has("armor"):
			man.armor = clampf(man.armor + float(fx["armor"]), 0.0, 1.0)
			said.append("%s's harness %s" % [man.display_name,
				"mended" if float(fx["armor"]) > 0.0 else "worse"])
		if fx.has("injury"):
			man.injury = maxi(man.injury, int(fx["injury"]))
			said.append("%s out %d" % [man.display_name, int(fx["injury"])])
		if fx.has("xp"):
			man.xp += int(fx["xp"])
		if fx.has("potential"):
			man.potential = clampi(man.potential + int(fx["potential"]), 1,
				Career.POTENTIAL_CEILING)
			said.append("%s's ceiling up %d" % [man.display_name, int(fx["potential"])])
		if fx.has("years"):
			man.years = clampi(man.years + int(fx["years"]), 0, Contracts.YEARS_MAX)
			said.append("%s on %d year%s" % [man.display_name, man.years,
				"" if man.years == 1 else "s"])
		if fx.has("wage"):
			man.wage_agreed = maxi(1, int(round(float(ClubOffice.billed(man))
				* float(fx["wage"]))))

	dilemma = {}
	sync_power()
	return "Done." if said.is_empty() else "  ".join(said) + "."


# ------------------------------------------------------------------ the market
## This summer's free agents, minus anyone already signed out of it.
func market() -> Array:
	var out: Array = []
	for f in Market.pool(world.rng.seed, world.season, world.player_tier(),
			office.market_refreshes,
			ClubOffice.TRAIT_SCOUT_EXTRA if office.has_trait(ClubOffice.Trait.SCOUT) else 0):
		if not market_taken.has(Market.taken_key(f)):
			out.append(f)
	return out


func market_fee(f: FighterCard) -> int:
	return Market.fee(f.overall(), world.player_tier())


## What this club would have to put him on. The rookie discount is applied here
## rather than at generation, because it depends on the man's age and not on who
## is selling him.
func market_wage(f: FighterCard) -> int:
	return Contracts.offer(ClubOffice.wage(f), f.age)


## SIGN HIM. Two prices and both have to clear: credits for the fee, and room
## under the cap for the wage — which is the whole reason the cap is worth
## raising and the reason a Star in the list is often not a signing at all.
##
## The refusals are in the order the player would hit them, and each one says the
## number, because "you cannot afford him" without a figure is a screen telling
## you to go and do arithmetic somewhere else.
func sign_from_market(f: FighterCard) -> String:
	var fee := market_fee(f)
	if office.credits < fee:
		return "%s costs %d CC and you have %d." % [f.display_name, fee, office.credits]
	var wage := market_wage(f)
	if ClubOffice.wage_bill(club) + wage > office.cap():
		return "%s wants %s a week. That puts you %s over the cap." % [
			f.display_name, ClubOffice.money(wage),
			ClubOffice.money(ClubOffice.wage_bill(club) + wage - office.cap())]
	var card := f.copy()
	card.years = Contracts.YEARS_NEW
	card.wage_agreed = wage
	## LATE BLOOMER banks a winter's training the day he walks in — the Experience
	## arrival one-shot, at the man rather than at the captain. It fires HERE and
	## nowhere else, so it cannot fire twice: an arrival trait applied wherever a
	## card is touched would pay out again on every re-sign.
	card.xp += int(FighterTrait.mod(card.trait_id, "arrival_xp", 0.0))
	var err := club.sign(card)
	if err != "":
		return err
	office.credits -= fee
	market_taken.append(Market.taken_key(f))
	sync_power()
	return ""


# -------------------------------------------------------------- the contracts
## EXTEND. Priced off what he is worth today, discounted by how much of the old
## deal the club is tearing up — so extending a man who has improved costs more
## than his old wage and should. The discount is for taking the risk early, not
## for pretending he is the fighter he was three years ago.
func extend(f: FighterCard) -> String:
	if not club.roster.has(f):
		return "%s is not on this club's books." % f.display_name
	if f.years <= 0:
		return "%s is out of contract. Re-sign him." % f.display_name
	if not Contracts.can_extend(f):
		if f.years >= Contracts.YEARS_MAX:
			return "%s is on the longest deal the club can offer." % f.display_name
		return "%s is in the last year of his deal. Let it run out, then re-sign him." % f.display_name
	var was := ClubOffice.billed(f)
	var wage := extend_cost(f)
	var bill := ClubOffice.wage_bill(club) - was + wage
	if bill > office.cap():
		return "That deal puts you %s over the cap." % ClubOffice.money(bill - office.cap())
	f.wage_agreed = wage
	f.years = Contracts.YEARS_MAX
	return ""


## RE-SIGN. Full market rate, no discount, and it is the only thing that saves a
## man whose deal has run out.
func resign(f: FighterCard) -> String:
	if not club.roster.has(f):
		return "%s is not on this club's books." % f.display_name
	## AND THE ADVICE HAS TO BE TRUE.
	##
	## This said "Extend him instead" to every man still under contract — and
	## `can_extend` refuses the man on his LAST year, on purpose, so the one
	## fighter a manager thinks about most got sent to a door that would not
	## open, and the door he came from sent him back. Neither refusal looked like
	## a fault; they read like advice, and following either one did nothing.
	##
	## **A refusal that names another door is a promise about that door.** The
	## last year has its own sentence now, and it names the thing that actually
	## works: let the deal run out, re-sign him out of contract, which is a state
	## he sits in visibly for a whole season.
	if f.years > 0:
		if f.years == 1:
			return "%s is in his last year. Let it run out, then re-sign him." % f.display_name
		## AND THE OTHER END OF THE SAME FAULT. A man already on the longest deal
		## the club can write cannot be extended either, so "Extend him instead"
		## was a dead end there too — one the check below found the moment it was
		## asked about every length rather than about the one that had gone wrong.
		if f.years >= Contracts.YEARS_MAX:
			return "%s is already on the longest deal the club can offer." % f.display_name
		return "%s has %d years left. Extend him instead." % [f.display_name, f.years]
	var wage := resign_cost(f)
	var bill := ClubOffice.wage_bill(club) - ClubOffice.billed(f) + wage
	if bill > office.cap():
		return "%s wants %s a week. That puts you %s over the cap." % [
			f.display_name, ClubOffice.money(wage),
			ClubOffice.money(bill - office.cap())]
	f.wage_agreed = wage
	f.years = Contracts.YEARS_NEW
	return ""


## WHAT A MAN ASKS FOR, and there is exactly one function per question because
## the screen that PRINTS the number and the code that TAKES it were separate
## before, agreeing only because both happened to call the same helper with the
## same two arguments. The day a trait started discounting one of them, they
## would have stopped agreeing and the button would have quoted a price the club
## did not charge.
##
## NEGOTIATOR. *"His men re-sign for less."* Read against the role the man
## stands in, like every other trait, so the captain who covers the Rail cannot
## talk down a Center.
func _negotiated(f: FighterCard, raw: int) -> int:
	if office.trait_covers(ClubOffice.Trait.NEGOTIATOR, Tuning.role_of(int(f.pos))):
		return maxi(1, int(round(float(raw) * ClubOffice.TRAIT_NEGOTIATOR)))
	return raw


func extend_cost(f: FighterCard) -> int:
	return _negotiated(f, Contracts.extension(ClubOffice.wage(f), f.age, f.years))


func resign_cost(f: FighterCard) -> int:
	return _negotiated(f, Contracts.offer(ClubOffice.wage(f), f.age))


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


func honours() -> Array:
	return world.honours
