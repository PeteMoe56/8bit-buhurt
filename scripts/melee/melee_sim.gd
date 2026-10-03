class_name MeleeSim
extends RefCounted
## The melee. Ten men on a Rail/Flanker/Center/Flanker/Rail line.
##
## THE CONTROL MODEL (Pete, 10 Sep 2026, and it is the whole design):
##
##   Put your finger on a fighter. Draw a path — to a patch of ground, or onto
##   an opponent. He is highlighted and he goes and does it. WHEN THE ROUTE IS
##   DONE, THE AI TAKES HIM BACK. If the path ended on a man, the options come
##   up at a certain distance. THE AI WILL CHOOSE UNLESS YOU CHOOSE.
##
## Two things fall out of that, and both are why it is better than what it
## replaced. First, you never hold a fighter — you hand him an instruction and
## he returns to autonomy — so there is no continuous control to cap and no
## danger of this becoming an action game. Second, there are no difficulty
## modes: drawing every path and drawing none are the same game, and your
## involvement is just how many decisions you take off the AI.
##
## No node dependencies. Seeded, fixed-step, deterministic — so the whole thing
## runs headless a thousand times in tests/test_melee.gd.

signal marshal_called(text: String)
signal fighter_downed(idx: int, by_idx: int)
signal prompt_opened(idx: int)
signal prompt_closed(idx: int)
signal action_resolved(idx: int, act: int, target: int, success: bool)
signal round_finished(round_no: int, winner: int)
signal bout_finished(winner: int)

enum State { CLOSING, GRAPPLED, RECOVER, DOWN, OUT }
enum Phase { CHARGE, LIVE, CORNER, OVER }


## A player-drawn instruction. It is consumed, not held: once the waypoints are
## walked and any target is dealt with, it is discarded and the AI resumes.
class Order extends RefCounted:
	var path: Array[Vector2] = []
	var target: int = -1
	## Drawn on the Chalkboard before the round rather than by thumb during it.
	## A play route walks and expires; it does NOT open a menu, does not override
	## a man's recovery and does not count as thumb work. That gap between a plan
	## and a hand on the screen is the ladder, and it is load-bearing.
	var from_play: bool = false
	## The endpoint was held: he runs it (see Tuning.sprint).
	var sprint: bool = false
	## Free enemies he has already passed on this route — each gets one try.
	var passed: Dictionary = {}

	func done() -> bool:
		return path.is_empty() and target == -1


## An open question to the player. It always carries the AI's answer already, so
## letting it time out costs nothing and answering it early costs no time either.
class Prompt extends RefCounted:
	var menu: int = Tuning.Menu.APPROACH
	var target: int = -1
	var t: float = 0.0
	## HOW LONG IT WAS OPENED FOR (3 Oct 2026). READER adds to the clock, and a bar
	## drawn against the bare PROMPT_TIME sat full for his extra 0.8 s.
	var dur: float = Tuning.PROMPT_TIME
	var choice: int = -1        ## what will happen; AI's pick until the player overrides
	var by_player: bool = false
	## He holds at prompt range while this is false. Without it he crossed the
	## ten units from PROMPT_RANGE to CONTACT_RANGE in a third of a second and
	## the options flashed past unreadably — the whole prompt layer was
	## decoration. Answering commits him instantly; ignoring it commits him when
	## the timer runs out. Either way nothing is lost by not answering.
	var committed: bool = false


class Man extends RefCounted:
	var card: FighterCard
	var team: int
	var idx: int
	var slot: int               ## 0-4, index into Tuning.Pos
	var pos: Vector2
	var anchor: Vector2          ## where he wants to be right now
	var plan_zone: Vector2       ## where the opening plan put him
	var state: int = State.CLOSING
	var target: int = -1
	var partner: int = -1
	var lane: int = 1           ## spatial, not positional — see _set_the_line
	## Filling a slot he is not listed for. Only a bench swap can cause it.
	var out_of_pos: bool = false
	var order: Order = null
	## HOLDING HIS GROUND (Pete, playtest 30 Sep #13: "stand still has no real
	## control"). A tap plants him where he stands: he waits for them to come to
	## him and is braced against a bullrush while he does. A drawn route lifts it.
	var planted: bool = false
	var planted_at: Vector2 = Vector2.ZERO
	var prompt: Prompt = null
	var tank: float = 1.0
	var stability: float = 1.0
	var exposed_t: float = 0.0
	## Clinch experiments: whose call this act is, and his run of misses.
	var acting_for_player: bool = false
	var td_misses: int = 0
	var td_miss_on: int = -1
	## Tuning.mate_grip: how long this man stays loosened for the other side's
	## holder, and which side that is.
	var grip_t: float = 0.0
	var grip_team: int = -1
	var hit_cd: float = 0.0
	var next_act: float = 0.0
	var grapple_t: float = 0.0
	var idle_t: float = 0.0     ## time in a clinch with nothing landing
	var timer: float = 0.0
	## bookkeeping for the report
	var downs_caused: int = 0
	var times_downed: int = 0
	## ASSISTS — Pete, 13 Sep 2026: *"Assists can be 2nd most damage or effect on
	## enemy."* Credited on somebody else's takedown, to the man who did the
	## second-most work on the victim. See `_wear` and `_put_down`.
	var assists: int = 0
	## WAS HE PUT DOWN IN THE ROUND JUST FOUGHT? Not `times_downed`, which is the
	## whole bout — the corner is a report on one round and a man who went down in
	## round one should not still be flagged in round three's.
	var downed_round: bool = false
	## WHO HAS BEEN WEARING HIM DOWN, attacker index -> stability taken off him
	## since he was last on the floor. Cleared every time he goes down, because
	## the work that put him down is spent — a downed man is out until the next
	## round, and a takedown then is new work by whoever does it.
	var wear: Dictionary = {}
	## Rounds this man finished on his feet. Counted at the whistle rather than
	## derived from `times_downed`: in buhurt a man who goes down is out for the
	## round and never gets up, so this is the count of rounds he was still
	## standing at the whistle. The career layer reads it for XP.
	var rounds_standing: int = 0
	var gassed_at: float = -1.0
	## WHICH ROUND he first gassed in — the report printed the last round.
	var gassed_round: int = 0
	var orders_given: int = 0

	func gas_frac() -> float:
		return clampf(tank / eff_tank(), 0.0, 1.0)

	func standing() -> bool:
		return state == State.CLOSING or state == State.GRAPPLED or state == State.RECOVER

	func under_orders() -> bool:
		return order != null

	## WHAT THIS MAN'S NUMBERS ARE WORTH IN THIS FIGHT — the out-of-position
	## penalty, and the grade.
	##
	## There were two of these and they carried a comment saying every formula
	## reads them "so the penalty cannot be forgotten in one formula and applied
	## in another". That was true of base and skill and quietly untrue of the
	## other two: strength and gas were read straight off the card in twelve
	## places, which is exactly the hole the comment was written to prevent. The
	## difficulty grade would have landed in two of those twelve and been missing
	## from ten.
	##
	## So there are four now, they are the only way into a fighting number, and
	## `test_grade.gd` greps this file for a direct `card.fighting_strength()`,
	## `card.fighting_gas()`, `card.tank()`, `card.skill` or `card.effective_base()`
	## and fails on one. A choke point nothing enforces is a convention.
	##
	## `scale` is the opposition's difficulty multiplier and is 1.0 for your own
	## men in every grade — see the header of `grade.gd` for why it is never
	## applied to your side.
	var scale: float = 1.0

	## WHAT IS UNUSUAL ABOUT HIM. Read through here rather than off the card at
	## twenty call sites, so a man with no card (there is no such man, but the
	## sim is built so there could be) reads as ordinary rather than crashing.
	func trait_id() -> int:
		return card.trait_id if card != null else FighterTrait.T.NONE

	## HIS TRAIT AND HIS WEAPON, through one door. A weapon mod with a 1.0
	## default multiplies, with a 0.0 default adds — the same reading every
	## caller already gives a trait mod.
	func tmod(key: String, def: float) -> float:
		## CACHED PER CARD. A man's trait and weapon cannot change inside a bout
		## (a sub brings a different CARD, which empties the cache), and this is
		## read dozens of times a tick: three dictionary walks each, 29% of a tick
		## in `tools/probe_perf.gd`. Keyed by the default too, because the
		## default decides whether a weapon mod adds or multiplies.
		var sig := _sig()
		if card != _mc_card or sig != _mc_sig:
			_mc.clear()
			_mc_card = card
			_mc_sig = sig
		var ck := key if def == 1.0 else ("%s@%s" % [key, def])
		var hit = _mc.get(ck)
		if hit != null:
			return hit
		var t := FighterTrait.mod(trait_id(), key, def)
		if card != null:
			var w = Tuning.weapon_mod(card.weapon, key)
			if w != null:
				t = t + float(w) if def == 0.0 else t * float(w)
		_mc[ck] = t
		return t

	var _mc: Dictionary = {}
	var _mc_card: FighterCard = null
	var _mc_sig: int = -1
	var _fc_sig: int = -1

	## What the cache is keyed on besides the card: nothing changes these in a
	## bout, but a test (or a future screen) may, and a stale mod is a wrong fight.
	func _sig() -> int:
		return -1 if card == null else card.trait_id * 64 + card.weapon
	var _fc: Dictionary = {}
	var _fc_card: FighterCard = null

	## How close he has to be for the action to land. A pole reaches further.
	func contact_range() -> float:
		return Tuning.CONTACT_RANGE * tmod("reach", 1.0)

	func tflag(key: String) -> bool:
		var sig := _sig()
		if card != _fc_card or sig != _fc_sig:
			_fc.clear()
			_fc_card = card
			_fc_sig = sig
		var hit = _fc.get(key)
		if hit == null:
			hit = FighterTrait.flag(trait_id(), key)
			_fc[key] = hit
		return hit

	## Set by `_build` off the sim's own flag, so the man carries the day with him
	## rather than every formula asking what day it is.
	var occasion: float = 1.0

	## HOW THE ROOM IS FEELING, and it is a field for the same reason `occasion`
	## is: a man carries the state of his side with him rather than every formula
	## asking the sim to count who is still up. The sim recomputes it whenever
	## somebody goes down or a new round starts — Last Man and Talisman are the two
	## traits that move it, and both of them are about the rest of the line.
	var rally: float = 1.0
	## SECOND WIND, once. Not a cooldown and not a per-round refill: the trait
	## says *once a bout*, so this is the bout's worth of it.
	var wind_used: bool = false
	## GRUDGE — set by `_build` when this man's card names the club across from
	## him. A grudge is a fact about a fixture, so it is decided once and carried,
	## not re-asked every tick.
	var grudge: float = 1.0
	## HOMESICK — 1.0 at home and for everybody without the trait. Set once in
	## `_build`, because where a bout is being fought does not change during it.
	var away: float = 1.0
	## HEAVY HANDS, from the other side. *"Wrecks the other man's harness."*
	##
	## A multiplier on THIS man's base, worn down by whoever is hitting him. It is
	## a field on the man and not a write to `card.armor`, and that is the whole
	## point: the opposition is generated for one afternoon and thrown away, so
	## damage written to their cards would be damage nobody ever sees. Worn in
	## the bout, read in the bout, gone with it.
	var harness: float = 1.0

	func _pen() -> float:
		return (Tuning.OUT_OF_POS if out_of_pos else 1.0) * scale * occasion \
			* rally * grudge * away

	func eff_base() -> float:
		return card.effective_base() * _pen() * harness

	func eff_skill() -> float:
		return float(card.skill) * _pen()

	func eff_strength() -> float:
		return float(card.fighting_strength()) * _pen()

	func eff_gas() -> float:
		return float(card.fighting_gas()) * _pen()

	## The size of the tank. Scaled but NOT penalised for being out of position:
	## standing in the wrong place makes a man worse at his job, it does not make
	## him less fit.
	func eff_tank() -> float:
		return card.tank() * scale * tmod("tank", 1.0)

	## WHERE THIS MAN COUNTS AS GASSED. ENGINE lowers it; every rule that asks
	## "is he gassed" asks here. The grind and the injury risk read the raw
	## constant before, so Engine's "never really gasses" half only reached the
	## report and the trait was pure downside in the fight.
	func gassed_line() -> float:
		return Tuning.GASSED_BELOW * tmod("gassed_below", 1.0)


var men: Array[Man] = []
## Probe counters for the flank rule (29 Sep 2026): blows on clinched men.
var passes_grabbed: int = 0
## How many times a man the player SENT reached his target (probe counter).
var sent_contacts: int = 0
## The share of a full blow the HIT being resolved lands (the free swing's).
var _hit_mult: float = 1.0
## THE CONTACT WHEEL'S THREE DIALS FOR THIS BOUT — the grade's (Grade.wheel_for,
## set by SeasonBouts._dress_sim); a bare sim (probes, tests) takes Tuning's.
var swing_share: float = Tuning.first_swing_share
var br_fall: float = Tuning.br_fall
var pass_grab: float = Tuning.pass_grab
var br_read: float = Tuning.br_read
var pass_trip: float = Tuning.pass_trip


## Hand the sim a grade's wheel dials ({"swing", "fall", "pass"}).
func set_wheel(w: Dictionary) -> void:
	swing_share = float(w.get("swing", swing_share))
	br_fall = float(w.get("fall", br_fall))
	pass_grab = float(w.get("pass", pass_grab))
	br_read = float(w.get("read", br_read))
	pass_trip = pass_grab
var passes_tripped: int = 0
var flank_blows: int = 0
var front_blows: int = 0
var clubs: Array = []
var rng := RandomNumberGenerator.new()

var phase: int = Phase.CHARGE
var round_no: int = 1
var round_t: float = 0.0
var bout_t: float = 0.0
var corner_t: float = 0.0
var charge_t: float = 0.0

## THE FIVE ON THE LINE, per team, as FighterCards. Not fixed for the bout:
## between rounds you may swap men in from the bench, so this is re-read every
## time the line is set. Pete, 10 Sep 2026, taken from ACRTW.
var lineups: Array = [[], []]
## Gas carried between rounds, as a fraction of each man's own tank, keyed by
## FighterCard so a man who sat a round out is tracked as carefully as one who
## fought it. This is the whole reason the bench is worth having.
var conditions: Dictionary = {}
var swaps_used := [0, 0]

var rounds_won := [0, 0]
## Standing differential, accumulated over the bout. Pete, 10 Sep 2026: "Points
## are based on how many up vs how many down. So a 5-1 would be 4 points. A 1-0
## would be one point." This is the league's tiebreak, and it is a much better
## one than rounds won because it carries HOW a round was won, not just that it
## was — a club that keeps winning 5-1 is plainly better than one scraping 1-0.
var margin := [0, 0]
var downs := [0, 0]
var round_downs := [0, 0]
var formations := [Tuning.Formation.TWO_ONE_TWO, Tuning.Formation.TWO_ONE_TWO]
## A side may bring a formation the player drew on the Chalkboard instead of one
## of the built-in shapes. Null means "use `formations[team]`".
var custom_spots: Array = [null, null]

## A CALLED PLAY — five routes in that team's own normalised frame, or null.
## Set before the bout (or in the corner) and re-run at the top of every round,
## because a play is an OPENING, and every round has an opening.
var plays: Array = [null, null]
var strategies := [Tuning.Strategy.RUSH_LEFT, Tuning.Strategy.RUSH_RIGHT]
## Who is thinking on each side, as a fallback for a team nobody has set roles
## for. The opposition's tier is the difficulty setting.
var skills := [Tuning.AiSkill.HARDENED, Tuning.AiSkill.HARDENED]

## PER ROLE, not per side. A club's captains cover two roles each, so a Rail can
## be thinking like an Elite while the Center is out there Green — which is the
## whole reason hiring a captain changes anything on the list.
##
## Empty means "use `skills` for everybody", which is what every existing test
## and the exhibition fixtures do, so the default behavior is untouched.
var role_skills: Array = [[], []]

## Dev hook for tools/probe_flags.gd: overrides team 1's skill table wholesale so
## one trait can be varied at a time. Null in every real path.
var patched = null

## Men who took a knock going down, as { "idx": int, "events": int }. The sim
## RECORDS them and changes nothing: whose books they land on is the season's
## business, not the fight's. A sim that reached into the club's roster would
## quietly injure men inside a balance test.
var injuries: Array[Dictionary] = []
## The opening plan, per team: how long it still drives the line.
var plan_t := [Tuning.PLAN_TIME, Tuning.PLAN_TIME]

## measured, never used to change the fight
var orders_issued: int = 0
var prompts_answered: int = 0
var prompts_timed_out: int = 0
var log_lines: Array[Dictionary] = []


## THE GRADE ARRIVES AS AN ARGUMENT, not as a field somebody remembers to set.
##
## It was going to be `sim.opp_scale = ...` after construction, which works right
## up until a call site forgets — and `_build()` fills every man's tank from
## `eff_tank()`, so a scale that arrives one line late produces a sim whose men
## are the right strength and the wrong fitness. There is no correct moment to
## set this except before the line is set, so it is not settable afterwards.
var opp_scale: float = 1.0


## HOW LONG THE CORNER LASTS, as a field rather than as `Tuning.CORNER_TIME`
## read at the point of use.
##
## The grade moves it — FRIENDLY gives you twenty-four seconds and FULL STEEL
## sixteen — and the difference between two swaps and one is the whole point of
## the knob. A constant that used to be a fact becomes a lie the moment the thing
## it described becomes a choice, so the constant is now the DEFAULT and the
## field is the truth.
var corner_time: float = Tuning.CORNER_TIME

## IS THIS ONE OF THE BIG ONES? Set by the season from the bout's mood. The sim is
## TOLD rather than going and reading `Session`, because a sim that reaches into
## the session layer is a sim the tests cannot build — and every balance figure
## in this project comes out of a sim the tests built.
var big_occasion: bool = false
## WHO IS ACROSS FROM YOU, as the world knows them. -1 in a standalone bout, and
## handed over by `Season.begin_bout` the same way the day is — GRUDGE reads it.
var opponent_club_id: int = -1
## WHERE THIS IS BEING FOUGHT — `Venue.Kind`. Handed over by the season the same
## way the day and the opposition are; the sim never looks anything up.
var venue: int = Venue.Kind.HOME
## AND HOW FAR IT IS FROM YOUR OWN TOWN. Homesick reads it; the splash prints it.
## Zero at home, and zero in a standalone bout where there is no map.
var miles: float = 0.0


func _init(club_a, club_b, seed_value: int = 0, opposition_scale: float = 1.0) -> void:
	clubs = [club_a, club_b]
	rng.seed = seed_value
	opp_scale = opposition_scale
	_build()
	_set_the_line()


## WHAT THE FIXTURE DOES TO A MAN: the occasion, a grudge against this club, and
## homesickness at this distance. Read off `big_occasion`, `opponent_club_id`,
## `venue` and `miles`.
##
## THOSE ARE SET AFTER THE CONSTRUCTOR — `Season._dress_sim` hands them over once
## `MeleeSim.new()` has returned — and this used to run only inside `_build()`,
## so in every real season and cup bout all four traits read 1.0. The dressing
## now calls `dress()` when it is done, and a man subbed on is dressed on entry.
func _fixture_mods(m: Man) -> void:
	m.occasion = m.tmod("occasion", 1.0) if big_occasion else 1.0
	## GRUDGE. The card names one club and it is the club across from him or it
	## is not. Team 1's men never carry one: the opposition is generated per bout.
	m.grudge = 1.0
	if m.team == 0 and m.card != null and m.card.grudge_club >= 0 \
			and m.card.grudge_club == opponent_club_id:
		m.grudge = m.tmod("grudge", 1.0)
	## HOMESICK. Your men only.
	m.away = 1.0
	if m.team == 0:
		m.away = Venue.homesick_scale(m.card, venue, miles)


## Re-apply the fixture to every man, after the season has said what the fixture
## is. Before the first tick the tank is refilled too, since it reads the mods.
func dress() -> void:
	for m in men:
		_fixture_mods(m)
		if round_no == 1 and round_t <= 0.0:
			m.tank = m.eff_tank()


func _build() -> void:
	men.clear()
	for team in 2:
		var five: Array = clubs[team].starting_five()
		lineups[team] = five.duplicate()
		for i in five.size():
			var m := Man.new()
			m.card = five[i]
			m.team = team
			## HIS INDEX IS WHERE HE ACTUALLY LANDS, not where a full line would
			## have put him. `team * 5 + i` was a fact right up until
			## `starting_five()` was allowed to return four — and it returns four
			## honestly, when knocks and the work rota have taken the fifth man.
			## From then on every man on team 1 carried an index one past himself:
			## `partner`, `target`, `wear` and the assist ledger are all lookups
			## into `men` by `idx`, so they addressed the wrong fighter, and the
			## last man's index addressed nobody at all and crashed the bout.
			## The only definition that cannot drift is the one the array gives.
			m.idx = men.size()
			## The SLOT is the place on the line, and it is the lineup index — not
			## the card's own listed position. They agree until somebody comes off
			## the bench into a slot he does not play, and after that the slot is
			## what decides where he stands.
			m.slot = i
			m.out_of_pos = _out_of_pos(m.card, i)
			m.scale = opp_scale if team == 1 else 1.0
			_fixture_mods(m)
			m.tank = m.eff_tank()
			men.append(m)
	# partners are line-adjacent, resolved once
	for m in men:
		var p: int = Tuning.POS_PARTNER[m.slot]
		m.partner = -1
		if p >= 0:
			for o in men:
				if o.team == m.team and o.slot == int(p):
					m.partner = o.idx
					break


## IS HE STANDING SOMEWHERE HE DOES NOT BELONG?
##
## LANE_RUNNER is forgiven one slot either side of his own, which is a real
## decision rather than a flat bonus: it lets a club field a five it could not
## otherwise field. Decided here and nowhere else, because `out_of_pos` is read
## by every formula through `_pen()` and a second opinion about it would be a
## man who is penalised in one calculation and not in another.
func _out_of_pos(card, slot: int) -> bool:
	if Tuning.covers(int(card.pos), slot):
		return false
	if not FighterTrait.flag(card.trait_id, "pos_forgiving"):
		return true
	for d in [-1, 1]:
		var near: int = slot + int(d)
		if near >= 0 and near < 5 and Tuning.covers(int(card.pos), near):
			return false
	return true


## The five spots this side is setting up on: its own drawn formation if it has
## one, otherwise the named shape it picked in the corner.
func formation_spots(team: int) -> Array:
	if custom_spots[team] != null:
		return custom_spots[team]
	return Tuning.FORMATIONS[formations[team]]["spots"]


## Hand a side its shape and its opening routes. This RE-SETS THE LINE, because
## the constructor already set it: assigning `custom_spots` after the sim exists
## and expecting the men to move is the ordering trap that put a drawn formation
## in the save, in the dropdown and in the corner screen while the fight itself
## quietly used 2-1-2.
func set_plan(team: int, spots, routes = null) -> void:
	custom_spots[team] = spots
	plays[team] = routes
	if phase == Phase.CHARGE and round_no <= 1:
		## RE-SETTING THE LINE MUST NOT COST RNG. Setting the line rolls each
		## man's first action timer, so running it a second time before the bout
		## starts would pull ten extra numbers out of the stream and move every
		## seeded result in the game — the balance suite, C-6, the ending mix,
		## all of it — depending on whether a caller happened to set a plan.
		## Setup is not simulation, so it rewinds.
		var st := rng.state
		_set_the_line()
		rng.state = st


## How much longer this side holds its shape, because of who is on it.
func _team_plan_bonus(team: int) -> float:
	var best := 0.0
	for m in men:
		if m.team == team:
			best = maxf(best, m.tmod("team_plan_extra", 0.0))
	return best


func _set_the_line() -> void:
	phase = Phase.CHARGE
	charge_t = 0.0
	round_t = 0.0
	round_downs = [0, 0]
	## THE SIDE'S PLAN, AND WHOSE VOICE IS CARRYING IT. A Captain's Voice adds to
	## the whole team's clock — it is the only trait in the game that reaches
	## somebody else's numbers, which is why it is rare.
	plan_t = [Tuning.PLAN_TIME + _team_plan_bonus(0),
		Tuning.PLAN_TIME + _team_plan_bonus(1)]
	for m in men:
		## THE ROUND'S OWN SLATE. `downed_round` is what the corner flags, and it
		## is cleared here rather than at the whistle because this is the one
		## place a round is known to be starting — a flag cleared where the round
		## ENDS is a flag that outlives a skipped round.
		m.downed_round = false
		## `wind_used` is NOT reset here. The trait says once a BOUT, and `_build`
		## makes new men for each bout, so the field's own default is the rule —
		## resetting it per round would have made it once a round with a longer
		## comment.
		## Re-read the line. A corner swap changed nothing until this ran.
		var line: Array = lineups[m.team]
		if m.slot < line.size() and line[m.slot] != null:
			## THE AFTERNOON BELONGS TO THE MAN, NOT THE SLOT. A swap put the new
			## card into the same `Man`, so the sub inherited the other man's
			## downs, assists, XP, worn harness and knock. Now the outgoing man's
			## bout is set aside and the incoming man's (fresh, or his own from
			## earlier) is picked up.
			if line[m.slot] != m.card:
				_stash(m)
				m.card = line[m.slot]
				_unstash(m)
				_fixture_mods(m)
			m.out_of_pos = _out_of_pos(m.card, m.slot)
		m.tank = m.eff_tank() * float(conditions.get(m.card, 1.0))
		## The formation says where every man starts, laterally as well as in depth —
		## a spot, not an offset. Mirrored for team 1 on both axes, so "your left
		## rail" means each side's own.
		var spot: Vector2 = formation_spots(m.team)[m.slot]
		var fx: float = spot.x if m.team == 0 else 1.0 - spot.x
		var fy: float = spot.y if m.team == 0 else 1.0 - spot.y
		var x: float = Tuning.LIST_W * fx
		m.pos = Vector2(x, Tuning.LIST_H * fy)
		## The plan's zone, in that team's own frame: x from their left, y from
		## their own rail toward the enemy. His own formation spot is the default
		## lateral answer — he goes STRAIGHT AHEAD unless the plan moves him.
		var z: Vector2 = Tuning.plan_target(strategies[m.team], m.slot, spot.x)
		var zx: float = z.x if m.team == 0 else 1.0 - z.x
		var zy: float = z.y if m.team == 0 else 1.0 - z.y
		m.plan_zone = Vector2(zx * Tuning.LIST_W, zy * Tuning.LIST_H)
		m.anchor = m.plan_zone
		## Lane is where he actually STANDS, not what his position is called.
		## Team 1's x is mirrored — their Rail_L is on the far side of the list
		## from ours — so deriving lane from the slot matched every man with his
		## opposite number across the whole width and dragged the entire melee
		## into one corner.
		m.lane = 0 if x < Tuning.LIST_W / 3.0 else (1 if x < Tuning.LIST_W * 2.0 / 3.0 else 2)
		m.state = State.CLOSING
		m.target = -1
		m.order = null
		m.planted = false
		m.prompt = null
		m.stability = Tuning.STABILITY_MAX
		m.exposed_t = 0.0
		## THE ROUND'S WORK IS THE ROUND'S (audit, 3 Oct 2026). `wear` is keyed by
		## the attacker's INDEX, and a swap keeps the slot's index — so a sub was
		## credited assists for his predecessor's hits, and round one's blows
		## counted toward a round-three takedown. The takedown-miss run is the
		## same: a sub inherited the other man's misses.
		m.wear.clear()
		m.td_misses = 0
		m.td_miss_on = -1
		m.grip_t = 0.0
		m.hit_cd = 0.0
		m.grapple_t = 0.0
		m.idle_t = 0.0
		m.next_act = rng.randf_range(Tuning.ACT_FIRST[0], Tuning.ACT_FIRST[1])
	## The plan goes on AFTER everyone is placed and cleared, because setting the
	## line wipes orders — running the play first would have drawn it and then
	## rubbed it out, which is exactly the bug shape that hides for a week.
	_run_play(0)
	_run_play(1)
	## And with five on their feet again, the room is what it was. Third of the
	## three places the standing count can change — the other two are a man going
	## down and the corner picking everybody up.
	_rally()


# ------------------------------------------------------------- player input
## Hand a fighter a drawn path. `path` is in list coordinates; `target` is an
## enemy index or -1. Returns false if he cannot be given one right now.
func give_order(idx: int, path: Array[Vector2], target: int = -1, run: bool = false,
		from: Vector2 = Vector2.INF) -> bool:
	if phase == Phase.OVER or idx < 0 or idx >= men.size():
		return false
	var m := men[idx]
	if m.team != 0 or not m.standing():
		return false
	## NOT A MAN IN A CLINCH (audit, 3 Oct 2026). `_order` writes the route's
	## target over `m.target`, which in a clinch is the man he is HOLDING — so he
	## went passive, stopped taking the grind, and his clinch actions landed on
	## whoever the route ended on, from across the list. A tap asks for his
	## options; a route waits until he is free.
	if m.state == State.GRAPPLED:
		return false
	m.planted = false
	if from != Vector2.INF:
		path = join_route(m.pos, from, path)
	path = clamp_route(path)
	_order(m, path, target, false)
	m.order.sprint = run and Tuning.sprint > 1.0
	m.orders_given += 1
	orders_issued += 1
	## A route drawn for one half of a pair IS the split. There is no separate
	## split command and there should not be — the player already expressed it
	## by sending him somewhere his partner is not.
	return true


## THE ROUTE PICKS UP WHERE THE MAN IS NOW (Pete, 3 Oct 2026: "it doesn't take
## into account his current movement, so if I tell it to go forward, depending
## how long I take, it stops/backs up to go from where that draw started").
## The fight keeps running while a finger draws, so by release the man is
## somewhere down the line from `from`, the point the stroke began on him. The
## waypoints he has already passed are dropped: he joins the drawn line at the
## nearest point on it and carries on from the next waypoint ahead, rather than
## walking back to the first one.
static func join_route(now: Vector2, from: Vector2, path: Array[Vector2]) -> Array[Vector2]:
	if path.is_empty():
		return path
	var line: Array[Vector2] = [from]
	line.append_array(path)
	var best := INF
	var seg := 0
	for i in line.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(now, line[i], line[i + 1])
		var d := q.distance_squared_to(now)
		if d < best:
			best = d
			seg = i
	## Segment `seg` runs line[seg] -> line[seg + 1], i.e. into path[seg]: the
	## next waypoint ahead is path[seg], and everything before it is behind him.
	var out: Array[Vector2] = []
	for j in range(seg, path.size()):
		out.append(path[j])
	return out


## EVERY WAYPOINT ON GROUND HE CAN STAND ON (audit, 3 Oct 2026). A man is held
## RAIL_INSET inside the rail and a waypoint counts at WAYPOINT_HIT, so a point
## drawn within six units of the edge — or off the list altogether, which is
## where a drag from a fighter CARD starts — could never be reached: he walked
## into the rail and stood there with the order live for the rest of the round.
static func clamp_route(path: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for v in path:
		out.append(Vector2(
			clampf(v.x, Tuning.RAIL_INSET, Tuning.LIST_W - Tuning.RAIL_INSET),
			clampf(v.y, Tuning.RAIL_INSET, Tuning.LIST_H - Tuning.RAIL_INSET)))
	return out


func _order(m: Man, path: Array, target: int, from_play: bool) -> void:
	var o := Order.new()
	o.path.clear()
	for v in path:
		o.path.append(Vector2(v))
	o.target = target
	o.from_play = from_play
	m.order = o
	m.target = target


## Put the called play on the line. Normalised, own-frame coordinates, mirrored
## for team 1 exactly like a formation spot — so a club's play is the same play
## whichever end of the list it is fought from.
func _run_play(team: int) -> void:
	var routes = plays[team]
	if routes == null:
		return
	for m in men:
		if m.team != team or not m.standing():
			continue
		if m.slot >= routes.size():
			continue
		var leg: Array = routes[m.slot]
		if leg.is_empty():
			continue
		var path: Array[Vector2] = []
		for v in leg:
			var fx: float = v.x if team == 0 else 1.0 - v.x
			var fy: float = v.y if team == 0 else 1.0 - v.y
			path.append(Vector2(Tuning.LIST_W * fx, Tuning.LIST_H * fy))
		_order(m, path, -1, true)


## Open the clinch menu for a man already tied up, without drawing anything.
func request_prompt(idx: int) -> bool:
	var m := men[idx]
	if m.team != 0 or m.state != State.GRAPPLED or m.prompt != null:
		return false
	_open_prompt(m, Tuning.Menu.GRAPPLED, m.target)
	return true


## The player answering. Overrides the AI's standing pick.
func answer_prompt(idx: int, act: int) -> bool:
	var m := men[idx]
	if m.prompt == null:
		return false
	if not Tuning.acts_for(m.prompt.menu).has(act):
		return false
	if m.prompt.menu == Tuning.Menu.GRAPPLED and not clinch_ready(m):
		return false
	if Tuning.td_gate > 0.0 and act == Tuning.Act.TAKEDOWN and m.prompt.menu == Tuning.Menu.GRAPPLED \
			and men[m.prompt.target].stability > Tuning.td_gate:
		return false
	m.prompt.choice = act
	m.prompt.by_player = true
	m.prompt.committed = true
	prompts_answered += 1
	## A CLINCH ACTION LANDS ON THE CLINCH'S OWN CLOCK (29 Sep 2026). It used to
	## land the instant it was tapped, and a failed takedown leaves a man still
	## tied up — so tapping TAKEDOWN twice a second rolled it five to seven times
	## for every roll the AI got on its ACT_CLINCH timer, and won 100% of bouts
	## whatever the numbers. The player chooses WHAT his man does; `next_act`
	## decides WHEN, exactly as it does for the man across from him: the menu
	## takes no answer until he is ready (`clinch_ready`), and a ready answer
	## lands at once. A first cut queued early answers to land later, and a
	## choice made up to three seconds before it landed was a stale one — taking
	## the AI's own suggestion that way won 22% against 57% for leaving it alone.
	if m.prompt.menu == Tuning.Menu.GRAPPLED:
		_clinch_act(m)
	return true


## Can this clinched man act now? The fight screen dims the menu until he can.
func clinch_ready(m: Man) -> bool:
	return m.next_act <= 0.0


## One clinch action from an answered prompt, then the clinch's clock restarts.
func _clinch_act(m: Man) -> void:
	var p: Prompt = m.prompt
	m.next_act = rng.randf_range(Tuning.ACT_CLINCH[0], Tuning.ACT_CLINCH[1])
	m.acting_for_player = p.by_player
	_resolve(m, p.choice, p.target)
	m.acting_for_player = false
	_close_prompt(m)


# --------------------------------------------------------------------- bench
## WHO YOU CAN ACTUALLY BRING ON, and it was wrong in two ways at once.
##
## It read `clubs[team].roster` — the whole squad of thirteen — so a RESERVE who
## never left the clubhouse could be swapped onto the line in the corner of a
## National fixture. And it read `f.available` alone rather than `f.fit()`, so a
## man with a broken arm was on that list too.
##
## Both were invisible because the corner screen only ever showed three names and
## three was usually right. The traveling party is the eight (or fewer — see
## `MeleeClub.travel_cap`), and a man on it has to be fit to step on.
func bench(team: int) -> Array:
	var out: Array = []
	for f in clubs[team].active_eight():
		if f.fit() and not lineups[team].has(f):
			out.append(f)
	return out


## How worn a man is, 0-1, whether he is on the line or sitting.
##
## A MAN ON THE LINE IS READ OFF HIS TANK, not off `conditions`. `conditions` is
## only written at a corner recovery, so during a round — and during the corner
## that follows it, before the recovery runs — it still holds what he had at the
## START of the round. The corner screen asks this question of five men who have
## just fought two minutes, and it was answering 100% for all of them.
##
## That is the number the whole swap decision turns on. A blown Center reading
## as fresh is the corner telling you not to bother.
func condition_of(card) -> float:
	for m in men:
		if m.card == card:
			return m.gas_frac()
	return float(conditions.get(card, 1.0))


## SWAP A MAN IN. Only in the corner, only from the bench, and only twice a
## corner. The swap does not take effect until the line is set for the next
## round — nothing about the round just fought is rewritten.
##
## The cost is in Tuning.OUT_OF_POS: a Center dropped into a Rail slot fights
## at 94% of his base and skill. Without that the bench is just "field your
## five best every round" and the line positions stop meaning anything.
func swap_in(team: int, slot: int, card) -> bool:
	## THE CORNER, OR BEFORE THE FIRST CHARGE. The pre-fight screen has the same
	## SUB boxes, and they refused every tap with no word as to why.
	var before_first := round_no == 1 and round_t <= 0.0 and phase == Phase.CHARGE
	if phase != Phase.CORNER and not before_first:
		return false
	if slot < 0 or slot >= 5 or card == null:
		return false
	## THE CORNER'S TWO SWAPS ARE THE CORNER'S. A change before the first charge
	## is the line being picked, not a substitution, so it does not spend them
	## (first-timer test, 1 Oct: two pre-fight swaps left every SUB grey after
	## round one, because the count only reset when the first corner ended).
	if not before_first and swaps_used[team] >= Tuning.SWAPS_PER_CORNER:
		return false
	if not bench(team).has(card):
		return false
	lineups[team][slot] = card
	if not before_first:
		swaps_used[team] += 1
	## Before the charge there is no corner to leave, so the line is re-read now.
	if before_first:
		_set_the_line()
	return true


## ---------------------------------------------------- the per-man ledger
## What a man did this bout, kept against his CARD when he leaves the line.
const BOUT_STATS := {"downs_caused": 0, "assists": 0, "times_downed": 0,
	"rounds_standing": 0, "harness": 1.0, "wind_used": false, "gassed_at": -1.0,
	"gassed_round": 0, "orders_given": 0}
var _ledger: Dictionary = {}


func _stash(m: Man) -> void:
	if m.card == null:
		return
	## NOT BEFORE THE FIRST CHARGE (audit, 3 Oct 2026). A pre-fight swap is the
	## line being picked: the man taken out never fought, and stashing him put
	## him in `fought()` — a bout on his book, XP for sitting, a report row, and
	## no Prima Donna for being left out.
	if bout_t <= 0.0:
		return
	var d := {"team": m.team, "slot": m.slot}
	for k in BOUT_STATS:
		d[k] = m.get(k)
	_ledger[m.card] = d


func _unstash(m: Man) -> void:
	var d: Dictionary = _ledger.get(m.card, {})
	for k in BOUT_STATS:
		m.set(k, d.get(k, BOUT_STATS[k]))
	_ledger.erase(m.card)


## EVERYONE WHO FOUGHT, the men on the line now AND the men subbed off, each
## carrying his own afternoon. Anything that pays a man for the bout (XP, the
## book, the report) reads this rather than `men`, which only knows who is on
## the line at the end.
func fought() -> Array[Man]:
	var out: Array[Man] = []
	out.append_array(men)
	for card in _ledger:
		var d: Dictionary = _ledger[card]
		var m := Man.new()
		m.card = card
		m.team = int(d["team"])
		m.slot = int(d["slot"])
		m.idx = -1
		for k in BOUT_STATS:
			m.set(k, d[k])
		out.append(m)
	return out


## Who is on the line, as cards, in Rail/Flanker/Center/Flanker/Rail order.
func lineup(team: int) -> Array:
	return lineups[team].duplicate()


## TAKE BACK A ROUTE. Called by a tap on a man who is already on one — see
## `melee_scene._release()`, which is also where the one rule about it lives: a
## route the PLAYER drew can be taken back, a route the called PLAY put on him
## cannot, because that is the plan the line is running.
##
## He becomes the AI's again rather than reverting to the play, which is the same
## thing that happens when a drawn route runs out on its own.
## PLANT HIM. Your man only, on his feet and not tied up; any route he was on
## goes. Returns whether it took.
func plant(idx: int) -> bool:
	if idx < 0 or idx >= men.size():
		return false
	var m := men[idx]
	if m.team != 0 or not m.standing() or m.state == State.GRAPPLED:
		return false
	cancel_order(idx)
	m.planted = true
	m.planted_at = m.pos
	return true


func cancel_order(idx: int) -> void:
	var m := men[idx]
	m.order = null
	## And the question that order raised. A prompt left open after the order
	## was taken back was answered against whoever the AI picked next — a
	## THIRD_MAN act landing on a different man from the one it was asked about.
	_close_prompt(m)
	if m.state != State.GRAPPLED:
		m.target = -1


# -------------------------------------------------------------------- clock
func tick() -> void:
	if phase == Phase.OVER:
		return
	bout_t += Tuning.TICK
	if phase == Phase.CORNER:
		corner_t -= Tuning.TICK
		if corner_t <= 0.0:
			leave_corner()
		return

	round_t += Tuning.TICK
	if phase == Phase.CHARGE:
		charge_t += Tuning.TICK
		if charge_t > Tuning.CHARGE_TIME:
			phase = Phase.LIVE

	for t in 2:
		## THE PLAN CLOCK IS ALLOWED TO GO NEGATIVE NOW, and that is the whole
		## mechanism behind ROUTE RUNNER. It used to floor at zero, which threw
		## away the one number a man who holds his route longer needs: HOW LONG
		## AGO the side stopped following it. `_plan_live` reads `> 0.0` either
		## way, so nothing else notices.
		plan_t[t] -= Tuning.TICK
	_refresh_anchors()
	for m in men:
		_tick_timers(m)
	_choose_targets()
	for m in men:
		_step(m)
	_spread_out()
	for m in men:
		_tick_prompt(m)
	_tick_grapples()
	_check_round_end()


func _tick_timers(m: Man) -> void:
	m.exposed_t = maxf(0.0, m.exposed_t - Tuning.TICK)
	m.grip_t = maxf(0.0, m.grip_t - Tuning.TICK)
	m.hit_cd = maxf(0.0, m.hit_cd - Tuning.TICK)
	m.timer = maxf(0.0, m.timer - Tuning.TICK)
	m.next_act = maxf(0.0, m.next_act - Tuning.TICK)
	if m.state == State.CLOSING and m.stability < Tuning.STABILITY_MAX:
		m.stability = minf(Tuning.STABILITY_MAX, m.stability
			+ Tuning.STABILITY_RECOVER * m.tmod("stability_recover", 1.0) * Tuning.TICK)
	## The tank's size once, not three times: it is a chain of five calls and
	## nothing in this function changes it.
	var cap := m.eff_tank()
	if m.state == State.CLOSING or m.state == State.RECOVER:
		var rec := Tuning.GAS_RECOVER * (m.eff_gas() / Tuning.GAS_STAT_DIV)
		m.tank = minf(cap, m.tank + rec
			* (1.0 if m.state == State.RECOVER else Tuning.WALK_RECOVER) * Tuning.TICK)
	var frac := clampf(m.tank / cap, 0.0, 1.0)
	if m.gassed_at < 0.0 and frac < m.gassed_line():
		m.gassed_at = round_t
		m.gassed_round = round_no
		log_lines.append({"t": round_t, "round": round_no, "kind": "gassed", "who": m.idx})
	## SECOND WIND — *"Once a bout, refills to half the moment he empties."*
	##
	## It reads EMPTY, not gassed. `gassed_at` fires at `GASSED_BELOW`, which is
	## the band where a man is struggling; this is the bottom of the tank, and
	## keeping them apart is the difference between a trait that fires once late
	## and a trait that fires the first time anybody breathes hard.
	##
	## Here rather than at every place that drains a tank, because there are
	## seven of those and a trait wired at six of them is the hole this codebase
	## keeps finding.
	if not m.wind_used and m.standing() \
			and frac <= Tuning.SECOND_WIND_AT \
			and m.tflag("second_wind"):
		m.wind_used = true
		m.tank = cap * Tuning.SECOND_WIND_TO
		log_lines.append({"t": round_t, "round": round_no, "kind": "second_wind",
			"who": m.idx})


## The corner. Everyone on the books recovers, not just the five who fought —
## and the men who sat get far more back, which is what makes a swap worth
## making. Stability is a per-round thing and resets outright.
## THE CORNER'S RECOVERY, CREDITED TO WHO FOUGHT — not to who is about to.
##
## It used to decide the bench bonus by asking whether a man is in `lineups`,
## which is the line for the round AHEAD. After a swap that is the wrong set in
## both directions: the man coming OFF is no longer in it, so he took the
## fighter's 30% AND the bench's 62% on top; the man coming ON is in it, so he
## took nothing at all — losing the very rest he was brought on for.
##
## `men` is who actually fought the round just ended, because `_set_the_line`
## has not run yet. That is the honest question.
## WHAT THE CORNER WILL GIVE THIS MAN BACK, as a fraction of his tank.
##
## Pulled out of `_corner_recovery` so the screen can show it. Pete asked for
## *"an energy now and energy recovered"*, and a screen that previews a number by
## recomputing the rule beside the rule is a screen that will one day preview a
## number the sim does not deliver. There is one lift and both callers read it.
func corner_lift(m: Man) -> float:
	return (Tuning.GAS_CORNER + float(
		(corner_bonus[m.team] as Dictionary).get(Tuning.role_of(m.slot), 0.0))) \
		* m.tmod("corner_recovery", 1.0)


## And where he lands, which is the figure the corner row prints on the right.
func corner_preview(m: Man) -> float:
	return clampf(m.gas_frac() + corner_lift(m), 0.0, 1.0)


## WHERE ANY CARD LANDS after the corner (audit, 3 Oct 2026). A man just swapped
## in was shown at his bench figure, but `_corner_recovery` gives him the bench's
## rest — the row said 70% and he walked out at 100%.
func corner_preview_card(card) -> float:
	for m in men:
		if m.card == card:
			return corner_preview(m)
	return clampf(float(conditions.get(card, 1.0)) + Tuning.BENCH_RECOVER, 0.0, 1.0)


func _corner_recovery() -> void:
	var fought := {}
	for m in men:
		fought[m.card] = true
	for m in men:
		m.state = State.CLOSING
		m.stability = Tuning.STABILITY_MAX
		conditions[m.card] = corner_preview(m)
	_rally()
	for team in 2:
		for f in clubs[team].roster:
			if fought.has(f):
				continue
			conditions[f] = clampf(float(conditions.get(f, 1.0)) + Tuning.BENCH_RECOVER, 0.0, 1.0)
	swaps_used = [0, 0]


## LEAVE THE CORNER EARLY, the way the clock would have.
##
## The screen used to end the corner by reaching in and calling `_set_the_line()`
## itself — which sets `phase = CHARGE`, so `tick()` never took the corner branch
## again and **`_corner_recovery()` never ran at all.** A player who chose a
## strategy got no recovery for anybody, all bout.
##
## The 30/62 split is the entire argument for carrying eight men. It fired only
## when the player sat on his hands and let the clock expire — which is also the
## only path the suite takes, because `run_to_end` never picks a strategy. The
## tested path and the played path were different paths, and the mechanic lived
## on the tested one.
func leave_corner() -> void:
	if phase != Phase.CORNER:
		return
	round_no += 1
	_corner_recovery()
	_set_the_line()


# ----------------------------------------------------------------- targeting
## Who is coaching THIS man. Falls back to the team's tier when no captain map
## has been set.
func _skill_of(m: Man) -> Dictionary:
	if patched != null and m.team == 1:
		return _dim(m, patched)
	var r: Array = role_skills[m.team]
	if r.is_empty():
		return _dim(m, Tuning.AI_SKILL[skills[m.team]])
	return _dim(m, Tuning.AI_SKILL[r[Tuning.role_of(m.slot)]])


## COLD HANDS thinks a tier worse than he is coached. It drops the TIER rather
## than nudging a number, because the tiers are already the game's model of "how
## well does this man decide" — a flaw that invented a second scale for the same
## question would be two models of one thing, and one of them would rot.
##
## It costs him nothing while you are answering his prompts yourself. That is the
## whole trade: he is a man you have to watch.
func _dim(m: Man, row: Dictionary) -> Dictionary:
	if not m.tflag("ai_tier_down"):
		return row
	## VALUES, not keys. `keys().find(row)` looked for a Dictionary among the int
	## keys, always got -1, and handed the row back unchanged — the flaw was inert.
	var tier: int = Tuning.AI_SKILL.values().find(row)
	if tier <= 0:
		return row
	return Tuning.AI_SKILL[Tuning.AI_SKILL.keys()[tier - 1]]


## Set a side's tiers from a captain map: role -> AiSkill.
func set_role_skills(team: int, by_role: Dictionary) -> void:
	var out: Array = []
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		out.append(int(by_role.get(role, skills[team])))
	role_skills[team] = out


## WHAT THE CORNER IS WORTH TO EACH ROLE, above the flat recovery everybody gets.
##
## The Physio trait lives on a captain and the sim has never heard of a captain —
## it takes two clubs, a seed and a clock. So it is injected the same way the
## tiers are: a map the season fills in and the sim reads, rather than the sim
## reaching up into the office for it. That direction is the whole reason this
## file can be tested on its own.
var corner_bonus: Array = [{}, {}]


func set_corner_bonus(team: int, by_role: Dictionary) -> void:
	corner_bonus[team] = by_role.duplicate()


## Is the opening plan still driving this side's line?
func _plan_live(team: int) -> bool:
	return plan_t[team] > 0.0 and standing_count(team) >= Tuning.PLAN_MIN_STANDING


## Where a man wants to stand when nobody is in front of him. While the plan is
## live that is his plan zone. After it expires it depends on whether anyone at
## home is thinking: a Seasoned side falls back into a line and re-reads the
## fight, and a Green one just keeps standing where he was told to stand.
func _refresh_anchors() -> void:
	for t in 2:
		if _plan_live(t):
			continue
		for m in men:
			if m.team != t:
				continue
			## WANDERER never re-forms. Per man, not per side: a coached Rail re-forms while an
			## uncoached Center is still standing where the plan left him.
			if not bool(_skill_of(m)["improvises"]):
				continue
			## WANDERER never re-forms whatever his coaching. The flaw is the
			## absence of the thing the tier buys, which is the cheapest kind of
			## flaw to write and the meanest to own.
			if m.tflag("no_reform"):
				continue
			## ROUTE RUNNER is still running his when the rest have given up on it.
			## Measured off how far past zero the side's clock has gone, which is
			## why that clock is no longer floored.
			if plan_t[t] + m.tmod("plan_extra", 0.0) > 0.0:
				continue
			var lane_x: float = Tuning.LIST_W * float(Tuning.POS_X[m.slot])
			if m.team == 1:
				lane_x = Tuning.LIST_W - lane_x
			## A fixed setback from the center line — see Tuning.REFORM_SETBACK.
			m.anchor = Vector2(lane_x, Tuning.LIST_H * 0.5
				+ (-Tuning.REFORM_SETBACK if t == 0 else Tuning.REFORM_SETBACK))


func _choose_targets() -> void:
	for m in men:
		if not m.standing() or m.state == State.GRAPPLED:
			continue
		if m.under_orders():
			continue          ## a drawn route outranks anything the AI wants
		m.target = _ai_pick_target(m)


## Is this loose enemy closing on a fight one of ours is already in? That is the
## man the Center exists to intercept — ACRTW calls it screening, and it is the
## defensive half of the two-on-one economy that decides melees.
func _about_to_help(e: Man) -> bool:
	for ours in men:
		if ours.team == e.team or ours.state != State.GRAPPLED:
			continue
		if e.pos.distance_to(ours.pos) <= Tuning.HELP_RANGE:
			return true
	return false


func _ai_pick_target(m: Man) -> int:
	var sk := _skill_of(m)
	var best := -1
	var best_score := -1.0e9
	var lane: int = m.lane
	for e in men:
		if e.team == m.team or not e.standing():
			continue
		var d := m.pos.distance_to(e.pos)
		var score := -d
		if e.lane == lane:
			score += Tuning.AI_SAME_LANE
		## Lane discipline. Without it every man chases the nearest fight
		## wherever it is, the whole melee slides into one corner of the list
		## and two thirds of the screen is empty ground — which is both
		## unreadable and nothing like a real line.
		score -= absf(e.pos.x - m.anchor.x) * Tuning.AI_LANE_DRIFT
		## A plan that leans a side wants the fight over there. While it is live
		## that pull is the plan zone doing the work, not a target preference.
		## The 2-on-1. Going to a man who is already tied up is how melees are
		## actually won — but if EVERYONE does it by default the line collapses
		## in one cascade and nothing else in the game gets to happen. So the
		## pull is near zero at the neutral setting and the strategy dial is what
		## turns it on: "Gang the Center" seeks piles, "Split and stretch" runs
		## from them and goes looking for five separate fights.
		if e.state == State.GRAPPLED:
			score += Tuning.GANG_PULL * float(sk["gang"]) - Tuning.GANG_FLOOR
		## Going looking for a worn man is what SETTING UP a down means, and
		## it is the thing a Green side cannot do. He will still take one that
		## is handed to him; he just never crosses the list to find it.
		if e.stability < Tuning.AI_WORN_BELOW and bool(sk["hunts_wear"]):
			score += Tuning.AI_HUNT_WORN
		## THE CENTER PLAYS FREE SAFETY — see the role notes in Tuning. He takes
		## the loose man rather than the busy one, and above all the loose man who
		## is about to make it two-on-one against somebody of ours.
		if Tuning.role_of(m.slot) == Tuning.Role.CENTER:
			if e.state == State.GRAPPLED:
				score -= Tuning.CENTER_AVOIDS_CLASH
			else:
				score += Tuning.CENTER_SEEKS_LOOSE
				if _about_to_help(e):
					score += Tuning.CENTER_DENIES_HELP
		## Rail and Flanker hold together unless the player has split them.
		if m.partner != -1:
			var p := men[m.partner]
			if p.standing() and not p.under_orders():
				var stretch := p.pos.distance_to(e.pos)
				var leash: float = Tuning.PAIR_LEASH
				score -= maxf(0.0, stretch - leash) * Tuning.AI_LEASH_PULL
		if score > best_score:
			best_score = score
			best = e.idx
	return best


# ------------------------------------------------------------------ movement
func _speed(m: Man) -> float:
	var v := Tuning.SPEED_BASE + (m.eff_gas() - 50.0) * Tuning.SPEED_PER_GAS
	v *= m.tmod("speed", 1.0)
	if phase == Phase.CHARGE:
		v *= m.tmod("charge_speed", 1.0)
	v *= lerpf(Tuning.SPEED_EMPTY_FLOOR, 1.0, m.gas_frac())
	## A man under orders moves at least as fast as one the AI is running. He
	## used to lose the strategy's aggression multiplier the moment you drew him
	## a path, so giving an order literally slowed him down.
	v *= float(_skill_of(m)["pace"])
	if phase == Phase.CHARGE:
		v *= 1.3
	if m.under_orders() and m.order.sprint:
		v *= Tuning.sprint
	return v


func _step(m: Man) -> void:
	match m.state:
		State.OUT:
			return
		State.DOWN:
			if m.timer <= 0.0:
				m.state = State.OUT
			return
		State.GRAPPLED:
			return
		State.RECOVER:
			## Giving ground and getting his wind back. A THUMB-drawn route
			## overrides it immediately — the player's call always outranks the
			## AI's. A play does not: a plan drawn last week does not get to
			## decide that a man who has just been put on his heels is fine.
			if m.under_orders() and not m.order.from_play:
				m.state = State.CLOSING
				_step_closing(m)
				return
			var back := m.anchor - m.pos
			if back.length() > 2.0:
				m.pos += back.normalized() * _speed(m) * Tuning.RECOVER_STEP * Tuning.TICK
			m.stability = minf(Tuning.STABILITY_MAX,
				m.stability + Tuning.RECOVER_STABILITY * Tuning.TICK)
			if m.timer <= 0.0:
				m.state = State.CLOSING
		State.CLOSING:
			_step_closing(m)


func _step_closing(m: Man) -> void:
	var goal := m.anchor
	var homing := false

	if m.under_orders():
		var o := m.order
		if not o.path.is_empty():
			goal = o.path[0]
			if m.pos.distance_to(goal) <= Tuning.WAYPOINT_HIT:
				o.path.remove_at(0)
		elif o.target != -1 and men[o.target].standing():
			goal = men[o.target].pos
			homing = true
		else:
			## Route walked, nothing left to do. He goes back to the AI — this
			## is the line that keeps the whole design from being an RTS.
			m.order = null
			m.target = -1
			return
	elif m.planted:
		## He does not go looking; whoever comes to him is fought where he stands.
		goal = m.planted_at
	elif m.target != -1 and men[m.target].standing():
		goal = men[m.target].pos
		homing = true

	## Holding at the range the options came up at, waiting for an answer.
	var waiting: bool = m.prompt != null and not m.prompt.committed \
		and m.prompt.menu != Tuning.Menu.GRAPPLED
	var to_goal := goal - m.pos
	if to_goal.length() > 1.0 and (not waiting or Tuning.sent_walks):
		var step := _speed(m) * Tuning.TICK
		m.pos += to_goal.normalized() * step
		## Charged by the METRE. See Tuning.GAS_MOVE — per second, this went to
		## nothing the moment the list got longer and the men got quicker.
		m.tank = maxf(0.0, m.tank - Tuning.GAS_MOVE * step)
		if m.under_orders() and m.order.sprint:
			m.tank = maxf(0.0, m.tank - Tuning.sprint_gas * m.eff_tank() * Tuning.TICK)
		## RUNNING PAST A FREE MAN (Pete: "Blood Bowl rules where that opponent,
		## if free, can try to grab or try to trip you at a percentage").
		if m.under_orders() and (pass_grab > 0.0 or pass_trip > 0.0):
			if _pass_by(m):
				return

	if not homing:
		return
	var tgt := men[m.target if not m.under_orders() else m.order.target]
	var d := m.pos.distance_to(tgt.pos)
	var menu: int = Tuning.Menu.THIRD_MAN if tgt.state == State.GRAPPLED else Tuning.Menu.APPROACH
	## Only a man you SENT asks you a question. The other nine get on with it —
	## that is the difference between orchestrating and micromanaging, and it is
	## the whole reason this reads as a manager rather than an RTS.
	if m.prompt == null and m.team == 0 and m.under_orders() \
			and not m.order.from_play and d <= Tuning.PROMPT_RANGE:
		_open_prompt(m, menu, tgt.idx)
		## A PROMPT JUST OPENED IS A QUESTION, NOT AN ANSWER. `waiting` was worked
		## out above, before the prompt existed — so a man sent onto somebody
		## already inside contact range opened his options and resolved them with
		## the AI's pick in the same tick, and it counted as timed out.
		if m.prompt != null and m.prompt.menu != Tuning.Menu.GRAPPLED:
			return
	if waiting:
		return
	if d <= m.contact_range() and m.next_act <= 0.0:
		m.next_act = rng.randf_range(Tuning.ACT_AFTER[0], Tuning.ACT_AFTER[1])
		var act: int = m.prompt.choice if m.prompt != null else _ai_choose(m, tgt, menu)
		m.acting_for_player = m.prompt != null and m.prompt.by_player
		## #10's extras belong to a man the PLAYER sent, not to a play.
		if m.under_orders() and not m.order.from_play:
			sent_contacts += 1
			if Tuning.mate_grip > 0.0 and tgt.state == State.GRAPPLED and tgt.target != -1 \
					and men[tgt.target].team == m.team:
				tgt.grip_t = Tuning.MATE_GRIP_T
				tgt.grip_team = m.team
			## THE FREE FIRST SWING (Pete, #10). If you picked HIT, that hit IS the
			## free swing: it lands now, whatever his cooldown, at full weight.
			## Anything else gets `swing_share` of a blow first. (29 Sep: a swing
			## before a chosen Hit either doubled it — a thumb won C-6's worst
			## setup 100% — or, with the cooldown kept, ate it.)
			if swing_share > 0.0:
				if act == Tuning.Act.HIT:
					m.hit_cd = 0.0
				else:
					_hit_mult = swing_share
					m.hit_cd = 0.0
					_resolve(m, Tuning.Act.HIT, tgt.idx)
					_hit_mult = 1.0
		if tgt.standing():
			_resolve(m, act, tgt.idx)
		m.acting_for_player = false
		if m.prompt != null:
			_close_prompt(m)
		if m.under_orders():
			m.order = null      ## the instruction is spent; he is the AI's again


func _spread_out() -> void:
	for i in men.size():
		var a := men[i]
		if not a.standing():
			continue
		for j in range(i + 1, men.size()):
			var b := men[j]
			if not b.standing():
				continue
			if a.state == State.GRAPPLED and a.target == b.idx:
				continue    ## a bound pair is held apart below, not shoved apart here
			var d := a.pos - b.pos
			var dist := d.length()
			if dist > 0.01 and dist < Tuning.BODY_RADIUS:
				var push := d.normalized() * (Tuning.BODY_RADIUS - dist) * 0.5
				a.pos += push
				b.pos -= push
	## A clinched pair settles to a fixed gap so it reads as two men, not a blob.
	for m in men:
		if m.state != State.GRAPPLED or m.target < m.idx:
			continue
		var o := men[m.target]
		if o.state != State.GRAPPLED:
			continue
		var mid := (m.pos + o.pos) * 0.5
		var axis := o.pos - m.pos
		axis = Vector2.DOWN if axis.length() < 0.01 else axis.normalized()
		## SETTLED, NOT SNAPPED (playtest 30 Sep #12, "people teleported"): a
		## pair that binds from further apart than the gap — a grab in passing, a
		## third man joining a clinch — slides together a little each tick
		## instead of jumping to the midpoint in one frame.
		m.pos = m.pos.move_toward(mid - axis * Tuning.GRAPPLE_GAP * 0.5, GRAPPLE_SETTLE)
		o.pos = o.pos.move_toward(mid + axis * Tuning.GRAPPLE_GAP * 0.5, GRAPPLE_SETTLE)
	for m in men:
		m.pos.x = clampf(m.pos.x, Tuning.RAIL_INSET, Tuning.LIST_W - Tuning.RAIL_INSET)
		m.pos.y = clampf(m.pos.y, Tuning.RAIL_INSET, Tuning.LIST_H - Tuning.RAIL_INSET)


## What bracing takes off a bullrush against a planted man.
const PLANT_BRACE := 0.10
## How far a clinched man may be pulled toward his partner in one tick.
const GRAPPLE_SETTLE := 2.5


# ------------------------------------------------------------------- prompts
## READER gets longer on the clock. It is the one trait that buys the PLAYER
## something rather than the man — which is why it is worth having on a fighter
## you actually watch.
func _open_prompt(m: Man, menu: int, target: int) -> void:
	var p := Prompt.new()
	p.menu = menu
	p.target = target
	p.t = Tuning.PROMPT_TIME + m.tmod("prompt_time", 0.0)
	p.dur = p.t
	## The AI's answer is filled in the moment the prompt opens. That is what
	## makes ignoring it free: nothing waits on the player, and the fighter
	## keeps closing while the buttons are up.
	p.choice = _ai_choose(m, men[target], menu)
	m.prompt = p
	prompt_opened.emit(m.idx)


func _close_prompt(m: Man) -> void:
	if m.prompt == null:
		return
	if not m.prompt.by_player:
		prompts_timed_out += 1
	m.prompt = null
	prompt_closed.emit(m.idx)


func _tick_prompt(m: Man) -> void:
	if m.prompt == null:
		return
	m.prompt.t -= Tuning.TICK
	if not men[m.prompt.target].standing():
		_close_prompt(m)
		return
	## AN OPEN CLINCH MENU WAITS FOR ITS MAN. Its clock only runs once he is
	## ready to act, so it cannot time out into an action the clinch timer has
	## not allowed; and until it is answered its suggestion is kept current, so
	## the highlighted option is what he would do NOW, not when it opened.
	if m.prompt.menu == Tuning.Menu.GRAPPLED:
		if not clinch_ready(m):
			m.prompt.t += Tuning.TICK
		elif not m.prompt.by_player:
			m.prompt.choice = _ai_choose(m, men[m.prompt.target], Tuning.Menu.GRAPPLED)
	if m.prompt.t <= 0.0:
		m.prompt.committed = true
		if m.prompt.menu == Tuning.Menu.GRAPPLED:
			_clinch_act(m)


## What this man would do if left alone. Deliberately competent — auto-play must
## not be a punishment, and a player who never draws a path is playing the same
## game with fewer of the decisions taken off the AI.
## THE TWO `card.overall()` READS BELOW ARE NOT A HOLE IN THE CHOKE POINT, and
## this is the note that says so before somebody "fixes" them.
##
## Every fighting number goes through `Man.eff_*` so the grade reaches all of
## them. These two do not, on purpose: they are a man SIZING UP an opponent and
## deciding whether to commit — a judgment, not a contest. Scaling them would
## make a Full Steel side braver as well as better, which is a second difficulty
## dial hidden inside the first, and it is the thing Civ VI gets criticised for
## (the AI at Deity does not play better, it just has more). Same reason
## `_bullrush_chance` reads `card.weight` raw: mass is a fact about a man, not a
## rating he is judged on.
func _ai_choose(m: Man, tgt: Man, menu: int) -> int:
	var agg := float(m.card.aggression) / 99.0
	var sk := _skill_of(m)
	match menu:
		Tuning.Menu.APPROACH:
			if tgt.exposed_t > 0.0 or tgt.stability < Tuning.AI_RUSH_WOBBLY:
				return Tuning.Act.BULLRUSH
			if m.gas_frac() < Tuning.AI_TIRED_GRAPPLE:
				return Tuning.Act.GRAPPLE
			if agg > Tuning.AI_RUSH_AGG and float(m.card.weight) > float(tgt.card.weight) + Tuning.AI_RUSH_WEIGHT:
				return Tuning.Act.BULLRUSH
			if tgt.card.overall() > m.card.overall() + Tuning.AI_TIE_UP_BETTER:
				return Tuning.Act.GRAPPLE    ## agency denial: tie up a better man
			return Tuning.Act.HIT if agg < Tuning.AI_HIT_BELOW_AGG else Tuning.Act.GRAPPLE
		Tuning.Menu.THIRD_MAN:
			if tgt.team != m.team:
				## Arriving on a man who is tied up is a free shot, not a free
				## down. Taking the shot is what wears him out; taking him is
				## what you do once somebody already has. `agg > 0.4` here meant
				## every third man went straight for the takedown, which made one
				## loose fighter next to a clinch into a takedown machine.
				if tgt.exposed_t > 0.0:
					return Tuning.Act.TAKEDOWN
				var third_gate: float = float(sk["wear_read"]) + Tuning.THIRD_MAN_BONUS
				return Tuning.Act.TAKEDOWN if tgt.stability < third_gate else Tuning.Act.HIT
			return Tuning.Act.BREAK if bool(sk["rescues"]) else Tuning.Act.HIT
		Tuning.Menu.GRAPPLED:
			## You do not beat a man you are tied up with — you hold him until he
			## is worn or until somebody helps. Throwing a takedown at a man who
			## is still square over his base just exposes you, and the AI used to
			## do it on nearly every action (81 attempts a bout) because
			## `aggression > 50` was enough to trigger it. That single line was
			## what put a 90-second round away in twenty.
			## Only bail when the tank is genuinely gone, and never while you are
			## the one winning the hold — at 0.25 the whole field spent the third
			## round escaping and re-engaging, which burns more gas than it saves.
			if bool(sk["escapes"]) and m.gas_frac() < Tuning.AI_ESCAPE_GAS and m.stability <= tgt.stability:
				return Tuning.Act.ESCAPE
			if m.exposed_t > 0.0:
				return Tuning.Act.HOLD
			if tgt.exposed_t > 0.0:
				return Tuning.Act.TAKEDOWN
			if tgt.card.overall() > m.card.overall() + Tuning.AI_HOLD_BETTER:
				return Tuning.Act.HOLD
			## The tier, in one line. A Green man needs the opponent almost gone
			## before he recognises the moment; an Elite one takes him while he is
			## still on his feet.
			if tgt.stability < float(sk["wear_read"]) + Tuning.ai_clinch_throw \
					+ (Tuning.throw_mine if m.team == 0 else 0.0):
				return Tuning.Act.TAKEDOWN
			if agg > Tuning.AI_TD_AGG and tgt.stability < Tuning.AI_TD_WOBBLY:
				return Tuning.Act.TAKEDOWN
			return Tuning.Act.HOLD
	return Tuning.Act.HIT


# ------------------------------------------------------------------ clinches
func _tick_grapples() -> void:
	for m in men:
		if m.state != State.GRAPPLED:
			continue
		m.grapple_t += Tuning.TICK
		m.idle_t += Tuning.TICK
		m.tank = maxf(0.0, m.tank - Tuning.GAS_GRAPPLE
			* (Tuning.GAS_STAT_DIV / maxf(1.0, m.eff_gas()))
			* m.tmod("gas_grapple", 1.0) * Tuning.TICK)
		## The grind. This is where a grapple actually goes somewhere.
		if m.target != -1:
			var foe := men[m.target]
			var grind := Tuning.GRAPPLE_GRIND * foe.tmod("grapple_grind", 1.0) * (
				0.6 + 0.8 * foe.eff_strength() / maxf(1.0, m.eff_base()))
			if m.gas_frac() < m.gassed_line():
				grind *= Tuning.GRAPPLE_GRIND_GASSED
			_wear(m, foe, grind * Tuning.TICK)
		## Ready with the menu open: he waits for the player (the menu's own clock
		## decides for him if nobody answers), so the timer is not restarted.
		if m.next_act <= 0.0 and m.prompt == null:
			m.next_act = rng.randf_range(Tuning.ACT_CLINCH[0], Tuning.ACT_CLINCH[1])
			var tgt := men[m.target]
			if tgt.standing():
				_resolve(m, _ai_choose(m, tgt, Tuning.Menu.GRAPPLED), m.target)
		## "Break!" — the marshal ends an inactive clinch past ten seconds.
		if m.grapple_t >= Tuning.GRAPPLE_MIN and m.idle_t >= Tuning.BREAK_INACTIVE:
			var o := men[m.target] if m.target != -1 else null
			marshal_called.emit(UiKit.t("Break!"))
			_ungrapple(m)
			if o != null:
				_ungrapple(o)


## WHO GETS THE ASSIST — the second-most work on this man, and nobody if the
## second man did not do enough of it to have earned the word.
##
## The taker-down is excluded because he already has the down; he is not removed
## from the TOTAL, though, so a man who was ground flat by one opponent and then
## tipped over by another gives the tipper an assist only if the tipper's own
## contribution clears the share. That is the right way round: the share asks
## "was this man part of it", and the man who threw it obviously was.
##
## `ASSIST_SHARE` is why this is not just `max of the rest`. A glancing hit at
## 0:12 is not an assist on a takedown at 1:40, and a rule that credits one
## turns the number into a participation count — which is what the stat is for
## everybody who has ever looked at one and not believed it.
func _assist_on(loser: Man, winner: Man) -> Man:
	var total := 0.0
	for v in loser.wear.values():
		total += float(v)
	if total <= 0.0:
		return null
	var best: Man = null
	var most := 0.0
	for idx in loser.wear:
		if int(idx) == winner.idx:
			continue
		var amount := float(loser.wear[idx])
		if amount > most:
			most = amount
			best = men[int(idx)]
	if best == null or most / total < Tuning.ASSIST_SHARE:
		return null
	return best


## THE ONLY WAY STABILITY COMES OFF A MAN AT AN OPPONENT'S HANDS.
##
## It subtracts AND it records, in one call, and that is the whole point of it
## existing: an assist is credited off this ledger, so a wear source that
## forgot to file would be a man doing damage the report cannot see. Writing it
## as "subtract here, remember to also log there" is the two-call-sites rule
## this codebase keeps paying for — so there is one call and it does both.
##
## A man wearing down his own team-mate is not a thing the sim does, but it is
## also not a thing this should quietly credit, so the ledger only takes
## opponents.
func _wear(victim: Man, by: Man, amount: float) -> void:
	if amount <= 0.0:
		return
	victim.stability = maxf(0.0, victim.stability - amount)
	if by.team == victim.team:
		return
	victim.wear[by.idx] = float(victim.wear.get(by.idx, 0.0)) + amount


func _enter_grapple(a: Man, b: Man) -> void:
	## WRESTLER — *"Enters a grapple on his terms; opens it already ahead."*
	##
	## The opening is real wear and goes through `_wear`, so it counts toward an
	## assist like every other thing done to a man. A trait that took stability
	## off directly would be a wrestler who grinds men down invisibly, which is
	## the one thing the assist ledger exists to prevent.
	##
	## Both ways round: whoever closed and whoever was closed on, because a
	## wrestler dragged into a clinch is still a wrestler.
	var open_a := a.tmod("grapple_open", 0.0)
	if open_a > 0.0:
		_wear(b, a, open_a)
	var open_b := b.tmod("grapple_open", 0.0)
	if open_b > 0.0:
		_wear(a, b, open_b)
	## A QUESTION ABOUT THE APPROACH IS OVER ONCE HE IS HELD (audit, 3 Oct 2026).
	## A sent man grabbed before he reached his man kept his approach prompt open,
	## and the clinch only acts for a man with no prompt — so he stood in it doing
	## nothing for ten seconds while the other man ground him down.
	for x in [a, b]:
		if x.prompt != null and x.prompt.menu != Tuning.Menu.GRAPPLED:
			_close_prompt(x)
	a.state = State.GRAPPLED
	b.state = State.GRAPPLED
	a.target = b.idx
	b.target = a.idx
	a.grapple_t = 0.0
	b.grapple_t = 0.0
	a.idle_t = 0.0
	b.idle_t = 0.0
	a.next_act = rng.randf_range(Tuning.ACT_BIND[0], Tuning.ACT_BIND[1])
	b.next_act = rng.randf_range(Tuning.ACT_BIND[0], Tuning.ACT_BIND[1])


func _ungrapple(m: Man) -> void:
	if m.state == State.GRAPPLED:
		m.state = State.RECOVER
		m.timer = Tuning.RECOVER_TIME
		m.next_act = maxf(m.next_act, Tuning.RECOVER_TIME * 0.6)
	m.target = -1
	m.grapple_t = 0.0
	m.idle_t = 0.0
	_close_prompt(m)


# ---------------------------------------------------------------- resolution
func _takedown_chance(a: Man, d: Man, gang: bool) -> float:
	var c := Tuning.TD_BASE
	## BEAR pushes, ANCHOR holds. Both land on the same number from opposite
	## sides, which is the honest place for them: a Bear against an Anchor is a
	## wash, and that is the fight you would want to watch.
	c += a.tmod("td_for", 0.0) + d.tmod("td_against", 0.0)
	c += (a.eff_strength() - d.eff_base()) * Tuning.TD_PER_STR
	c += (a.eff_skill() - 50.0) * Tuning.TD_PER_SKL
	c += (1.0 - d.stability) * Tuning.TD_STABILITY_W
	if gang:
		c += Tuning.TD_GANG * a.tmod("td_gang", 1.0)
	if d.exposed_t > 0.0:
		c += Tuning.EXPOSED_BONUS * d.tmod("exposed_against", 1.0)
	c += _sent_edge(a)
	if d.grip_t > 0.0 and d.grip_team == a.team and d.target == a.idx:
		c += Tuning.mate_grip
	if Tuning.pread > 0.0 and a.acting_for_player and d.stability < Tuning.pread_at:
		c += Tuning.pread
	if Tuning.td_repeat > 0.0 and a.td_miss_on == d.idx:
		c -= Tuning.td_repeat * float(a.td_misses)
	if Tuning.td_steady > 0.0:
		c *= lerpf(1.0 - Tuning.td_steady, 1.0, clampf(1.0 - d.stability, 0.0, 1.0))
	c *= lerpf(Tuning.TD_EMPTY_TANK, 1.0, a.gas_frac())
	return clampf(c, Tuning.TD_MIN, Tuning.TD_MAX)


## WHERE THE BLOW COMES FROM, on a man tied up in a clinch: 1 from the side or
## behind (outside his front arc, facing the man he holds), -1 from the front,
## 0 if he is not in a clinch at all.
func _clinch_side(a: Man, d: Man) -> int:
	if d.state != State.GRAPPLED or d.target < 0 or d.target == a.idx:
		return 0
	var face := men[d.target].pos - d.pos
	var to_a := a.pos - d.pos
	if face.length() < 0.01 or to_a.length() < 0.01:
		return 0
	var ang := rad_to_deg(face.angle_to(to_a))
	## THE WHEEL ASKS THIS EVERY FRAME (audit, 3 Oct 2026); only a real blow counts.
	if absf(ang) > Tuning.flank_arc * 0.5:
		if not _previewing:
			flank_blows += 1
		return 1
	if not _previewing:
		front_blows += 1
	return -1


## True while `contact_odds` is asking, so the probe counters see only real blows.
var _previewing := false


## WHICH WAY A MAN FACES: at the man he is clinched with or closing on, else the
## way his route runs, else up the list toward the other end.
func _facing(d: Man) -> Vector2:
	if d.target >= 0 and d.target < men.size() and (d.state == State.GRAPPLED or d.state == State.CLOSING):
		var v := men[d.target].pos - d.pos
		if v.length() > 0.01:
			return v.normalized()
	if d.under_orders() and not d.order.path.is_empty():
		var w := d.order.path[0] - d.pos
		if w.length() > 0.01:
			return w.normalized()
	return Vector2(1, 0) if d.team == 0 else Vector2(-1, 0)


## ONE TRY PER FREE ENEMY PER ROUTE. A free man is on his feet and not tied up;
## the man the route is aimed at does not count — reaching him is the point.
## Returns true if the runner's route ended here.
func _pass_by(m: Man) -> bool:
	for e in men:
		if e.team == m.team or e.state != State.CLOSING or e.idx == m.order.target:
			continue
		if m.order.passed.has(e.idx) or m.pos.distance_to(e.pos) > Tuning.pass_range:
			continue
		m.order.passed[e.idx] = true
		var odds := pass_odds(m, e)
		var roll := rng.randf()
		if roll < float(odds["grab"]):
			m.order = null
			_close_prompt(m)
			_enter_grapple(e, m)
			passes_grabbed += 1
			return true
		if roll < float(odds["grab"]) + float(odds["trip"]):
			passes_tripped += 1
			_wear(m, e, Tuning.PASS_TRIP_HIT)
			if m.stability < Tuning.PASS_TRIP_FLOOR:
				_put_down(m, e)
				return true
	return false


## What a free man's reach costs a runner, as {grab, trip} — skill against
## skill, and a sprinter is harder to lay hands on and easier to put off his feet.
func pass_odds(m: Man, e: Man) -> Dictionary:
	var edge := clampf((e.eff_skill() - m.eff_skill()) * 0.006, -0.12, 0.12)
	var run := m.under_orders() and m.order.sprint
	var grab := clampf((pass_grab + edge) * (0.7 if run else 1.0), 0.0, 0.8)
	var trip := clampf((pass_trip + edge) * (1.4 if run else 1.0), 0.0, 0.8)
	return {"grab": grab, "trip": trip}


## HOW OFTEN A FAILED BULLRUSH PUTS THE MAN WHO THREW IT DOWN — more when he is
## already rocking, and when he threw himself at someone heavier.
func bullrush_fall_chance(a: Man, d: Man) -> float:
	var c := br_fall
	c += (1.0 - a.stability) * 0.25
	c += clampf(float(d.card.weight - a.card.weight) * 0.004, -0.10, 0.15)
	return clampf(c, 0.0, 0.6)


## THE WHEEL'S NUMBERS, for one act by a man on a target, as the player would
## choose it: "p" the chance it lands, "fall" (bullrush) the chance he ends up on
## the floor himself, "dent" (hit) the share of balance it knocks off.
func contact_odds(idx: int, act: int, target: int) -> Dictionary:
	var m := men[idx]
	var t := men[target]
	var was := m.acting_for_player
	m.acting_for_player = true
	_previewing = true
	var out := {"p": 1.0, "fall": 0.0, "dent": 0.0}
	## THE FREE FIRST SWING lands before the act he picks, so the odds shown are
	## the odds after it — otherwise the wheel undersells every choice on it.
	var t_stab := t.stability
	var swing := 0.0
	if swing_share > 0.0 and act != Tuning.Act.HIT and m.under_orders() and not m.order.from_play:
		swing = minf(_hit_amount(m, t) * swing_share, t.stability)
		t.stability -= swing
	match act:
		Tuning.Act.BULLRUSH:
			var p := _bullrush_chance(m, t)
			out["p"] = p
			out["fall"] = (1.0 - p) * (bullrush_fall_chance(m, t) if br_fall > 0.0 else 0.0)
		Tuning.Act.TAKEDOWN:
			out["p"] = _takedown_chance(m, t, t.state == State.GRAPPLED and t.target != m.idx)
		Tuning.Act.HIT:
			out["dent"] = swing + minf(_hit_amount(m, t), t.stability)
		Tuning.Act.GRAPPLE:
			## Tying up always lands; what it is worth is his takedown once in.
			out["p"] = _takedown_chance(m, t, false)
	t.stability = t_stab
	m.acting_for_player = was
	_previewing = false
	return out


## The balance one blow from `a` knocks off `d` (before the floor at his
## remaining balance), with the from-behind bonus. The wheel's number.
func _hit_amount(a: Man, d: Man) -> float:
	var amount := Tuning.HIT_STABILITY * d.tmod("hit_stability_against", 1.0) * (
		0.7 + 0.6 * a.eff_strength() / 99.0)
	if Tuning.back_hit > 1.0 and a.acting_for_player and from_behind(a, d):
		amount *= 1.0 + (Tuning.back_hit - 1.0) * _back_scale(a, d)
	return amount


## Is this blow from behind him (Tuning.back_arc)?
func from_behind(a: Man, d: Man) -> bool:
	var to_a := a.pos - d.pos
	if to_a.length() < 0.01:
		return false
	return absf(rad_to_deg(_facing(d).angle_to(to_a))) > Tuning.back_arc


## The multiplier a blow from behind earns on this man, 1.0 if it is not one.
func _back_scale(a: Man, d: Man) -> float:
	if not from_behind(a, d):
		return 1.0
	return Tuning.back_held if d.state == State.GRAPPLED else 1.0


func _bullrush_chance(a: Man, d: Man) -> float:
	var c := Tuning.BR_BASE
	if Tuning.back_br > 0.0 and a.acting_for_player and from_behind(a, d):
		c += Tuning.back_br * _back_scale(a, d)
	if Tuning.flank_br > 0.0 or Tuning.front_pen > 0.0:
		match _clinch_side(a, d):
			1: c += Tuning.flank_br
			-1: c -= Tuning.front_pen
	c += (float(a.card.weight) + a.tmod("weight_bonus", 0.0)
		- float(d.card.weight)) * Tuning.BR_PER_LB
	c -= d.eff_base() * Tuning.BR_PER_BASE * d.tmod("br_against", 1.0)
	## A PLANTED MAN IS BRACED for it.
	if d.planted:
		c -= PLANT_BRACE
	c += (1.0 - d.stability) * Tuning.BR_STABILITY_W
	if br_read > 0.0 and (a.acting_for_player or Tuning.br_read_ai) \
			and d.stability < Tuning.pread_at:
		c += br_read
	if d.exposed_t > 0.0:
		## HEAD DOWN is exposed to a bullrush the same as to a takedown.
		c += Tuning.EXPOSED_BONUS * d.tmod("exposed_against", 1.0)
	c += _sent_edge(a)
	c *= lerpf(Tuning.BR_EMPTY_TANK, 1.0, a.gas_frac())
	return clampf(c, Tuning.BR_MIN, Tuning.BR_MAX)


## Morning decision #10's option (a): off (0.0) unless a probe sets it.
func _sent_edge(a: Man) -> float:
	if Tuning.sent_edge == 0.0 or not a.under_orders() or a.order.from_play:
		return 0.0
	return Tuning.sent_edge


func _resolve(m: Man, act: int, target: int) -> void:
	if target < 0 or target >= men.size():
		return
	var t := men[target]
	if not t.standing() or not m.standing():
		return
	var ok := false

	match act:
		Tuning.Act.BULLRUSH:
			m.tank = maxf(0.0, m.tank - Tuning.BR_GAS * m.eff_tank())
			if rng.randf() < _bullrush_chance(m, t):
				_put_down(t, m)
				ok = true
			else:
				## Missing one is the most expensive mistake in the game, and it
				## should be — it is the price that makes Bullrush a gamble
				## rather than a strictly better Hit.
				m.exposed_t = Tuning.BR_FAIL_EXPOSE
				m.stability = maxf(0.0, m.stability - 0.10)
				## AND SOMETIMES HE BOUNCES OFF AND GOES OVER (Pete: "there SHOULD
				## be a red chance in Bullrush where you run into them and fall").
				## The PLAYER'S bullrush only (grid W2, 29 Sep): the AI bullrushes
				## far more often than a thumb does, so a fall on everyone's lowered
				## hands-off play 5 points and brought takedown spam back. The
				## wheel is where the risk is shown, so the wheel is where it lives.
				if br_fall > 0.0 and m.acting_for_player \
						and rng.randf() < bullrush_fall_chance(m, t):
					_put_down(m, t)

		Tuning.Act.GRAPPLE:
			if t.state == State.GRAPPLED:
				_resolve(m, Tuning.Act.HIT, target)
				return
			_enter_grapple(m, t)
			ok = true

		Tuning.Act.HIT:
			if m.hit_cd > 0.0:
				return
			m.hit_cd = Tuning.HIT_COOLDOWN
			var amount := Tuning.HIT_STABILITY * t.tmod("hit_stability_against", 1.0) * (
				0.7 + 0.6 * m.eff_strength() / 99.0)
			## The PLAYER'S blow only (29 Sep): on everyone it erased C-6's
			## tactical hole (worst setup 25% -> 54% hands-off).
			if Tuning.back_hit > 1.0 and m.acting_for_player and from_behind(m, t):
				amount *= 1.0 + (Tuning.back_hit - 1.0) * _back_scale(m, t)
			if Tuning.flank_hit > 0.0 or Tuning.front_pen > 0.0:
				match _clinch_side(m, t):
					1: amount *= maxf(1.0, Tuning.flank_hit)
					-1: amount *= 1.0 - Tuning.front_pen
			_wear(t, m, amount * _hit_mult)
			## AND THE HARNESS, if the man throwing it is Heavy Handed. Floored,
			## because a trait that can take a man to nothing is a trait that
			## decides a bout on its own.
			var wreck := m.tmod("harness", 0.0)
			if wreck > 0.0:
				t.harness = maxf(Tuning.HARNESS_FLOOR, t.harness - wreck)
			t.tank = maxf(0.0, t.tank - Tuning.HIT_GAS * t.eff_tank())
			m.idle_t = 0.0
			t.idle_t = 0.0
			ok = true

		Tuning.Act.TAKEDOWN:
			var gang := t.state == State.GRAPPLED and t.target != m.idx
			if rng.randf() < _takedown_chance(m, t, gang):
				_put_down(t, m)
				if m.state == State.GRAPPLED:
					_ungrapple(m)
				ok = true
				m.td_misses = 0
				m.td_miss_on = -1
			else:
				m.exposed_t = Tuning.TD_FAIL_EXPOSE
				if m.td_miss_on != t.idx:
					m.td_misses = 0
					m.td_miss_on = t.idx
				m.td_misses += 1
				if Tuning.td_brace > 0.0:
					t.stability = minf(Tuning.STABILITY_MAX, t.stability + Tuning.td_brace)
				if m.acting_for_player:
					if Tuning.pmiss_expose > 0.0:
						m.exposed_t = maxf(m.exposed_t, Tuning.pmiss_expose)
					if Tuning.pmiss_gas > 0.0:
						m.tank = maxf(0.0, m.tank - Tuning.pmiss_gas * m.eff_tank())
			m.idle_t = 0.0
			t.idle_t = 0.0

		Tuning.Act.HOLD:
			## Deliberately doing nothing. It is a win against a better man, and
			## it is what runs the marshal's clock — idle_t is not reset here.
			m.stability = minf(Tuning.STABILITY_MAX, m.stability + 0.04)
			ok = true

		Tuning.Act.ESCAPE:
			m.tank = maxf(0.0, m.tank - Tuning.ESCAPE_GAS * m.eff_tank())
			## SLIPPERY SCALES THE WHOLE CHANCE. It multiplied only the skill-vs-
			## strength term, which is negative against a stronger man — so the
			## trait made a slippery man EASIER to hold exactly when it mattered.
			var c := (Tuning.ESCAPE_BASE + (m.eff_skill()
				- t.eff_strength()) * Tuning.ESCAPE_PER_SKL) * m.tmod("escape", 1.0)
			if rng.randf() < clampf(c, Tuning.ESCAPE_MIN, Tuning.ESCAPE_MAX):
				_ungrapple(t)
				_ungrapple(m)
				ok = true
			else:
				m.idle_t = 0.0

		Tuning.Act.BREAK:
			## Free your own man. Pete, 10 Sep 2026 — the counter to their gang.
			var mate := men[t.target] if t.target != -1 else null
			if mate != null and mate.team == m.team:
				_ungrapple(mate)
				_ungrapple(t)
				t.exposed_t = maxf(t.exposed_t, 0.6)
				ok = true
			else:
				_resolve(m, Tuning.Act.HIT, target)
				return

	action_resolved.emit(m.idx, act, target, ok)


## HOW A SIDE IS FIGHTING WITH MEN ON THE FLOOR — Last Man, and only Last Man.
##
## TALISMAN WAS HERE TOO AND IS NOT ANY MORE, and the reason is three
## measurements rather than a preference. As a multiplier on everything it
## measured **+12.2 points of win rate from one man**, four times Last Man at the
## same rarity; dropped from x1.05 to x1.02 it measured **+11.1** — it does not
## scale down, because this sim is sharp around parity and a room trait pays its
## multiplier four times over. Moved to stability recovery it measured **+0.0**:
## in a busy melee men are grappled, not recovering. Moved to the corner it
## measured **-2.2**, inside the noise, because the corner lift is clamped at a
## full tank and most men are near it after one round.
##
## THE FINDING IS THE USEFUL PART: a room-wide effect in this fight is either
## enormous or nothing, with no readable middle. So Talisman stopped being a
## fight trait — see `Season._award_xp`, where it is morale, which is bounded by
## construction and already measured.
##
## IT RECOMPUTES FROM SCRATCH every time, rather than nudging a running figure up
## and down as men fall and rise. A multiplier accumulated by events drifts the
## moment one event is missed, and a man who goes down twice in a round is an
## event happening twice.
func _rally() -> void:
	for team in 2:
		var down := 0
		for m in men:
			if m.team != team:
				continue
			if not m.standing():
				down += 1
		for m in men:
			if m.team != team:
				continue
			var r := 1.0
			## His own, scaled by how thin it has got. Full effect with four of
			## his side on the floor; nothing at all while the five are up.
			var alone := m.tmod("alone", 1.0)
			if alone != 1.0 and m.standing():
				r *= 1.0 + (alone - 1.0) * (float(down) / 4.0)
			m.rally = r


func _put_down(loser: Man, winner: Man) -> void:
	loser.state = State.DOWN
	loser.timer = Tuning.DOWN_HOLD
	loser.times_downed += 1
	loser.downed_round = true
	winner.downs_caused += 1
	var helper := _assist_on(loser, winner)
	if helper != null:
		helper.assists += 1
	downs[winner.team] += 1
	round_downs[winner.team] += 1
	## THE SLATE IS WIPED WHEN HE HITS THE FLOOR. Everything on it was spent
	## putting him there; a second down thirty seconds later is a second piece
	## of work, by whoever does it then.
	loser.wear.clear()
	_rally()
	_close_prompt(loser)
	## RELEASE ONLY HIS OWN CLINCH. This let go of whoever his TARGET was, clinch
	## partner or not — a man walking toward E, who was clinched with F, went down
	## and freed E while F stayed locked onto him and kept grinding and taking
	## him down from across the list. Now: anyone clinched with HIM is let go.
	for o in men:
		if o != loser and o.state == State.GRAPPLED and o.target == loser.idx:
			_ungrapple(o)
	loser.target = -1
	loser.order = null
	## A knock, occasionally, and much more often to a man with nothing left —
	## which is the sport's own folklore and the only part of this the player can
	## do something about.
	var risk := Tuning.INJURY_CHANCE
	if loser.gas_frac() < loser.gassed_line():
		risk *= Tuning.INJURY_GASSED
	if rng.randf() < risk:
		var n: int = Tuning.INJURY_LENGTH[rng.randi() % Tuning.INJURY_LENGTH.size()]
		## THE CARD, not just the index: the index is a slot, and by the time the
		## season reads this a sub may be standing in it.
		injuries.append({ "idx": loser.idx, "events": n, "card": loser.card })
		log_lines.append({ "t": round_t, "round": round_no, "kind": "injury",
			"who": loser.idx, "events": n })
	log_lines.append({
		"t": round_t, "round": round_no, "kind": "down",
		"who": loser.idx, "by": winner.idx, "gas": loser.gas_frac(),
	})
	fighter_downed.emit(loser.idx, winner.idx)


# ----------------------------------------------------------------- round end
func standing_count(team: int) -> int:
	var n := 0
	for m in men:
		if m.team == team and m.standing():
			n += 1
	return n


func _check_round_end() -> void:
	var s0 := standing_count(0)
	var s1 := standing_count(1)
	var over := false
	var reason := ""
	## A wipe, or three-to-one. 2-1 and 1-1 stay in play, which is exactly what
	## makes a 1-0 — and therefore a nine-down round — reachable at all.
	var lead := maxi(s0, s1)
	var trail := mini(s0, s1)
	if trail == 0:
		over = true
		reason = UiKit.t("Stop fight!")
	elif trail <= Tuning.STOP_TRAIL and lead >= Tuning.STOP_LEAD:
		over = true
		reason = UiKit.t("Three to one — stop fight!")
	elif round_t >= Tuning.ROUND_TIME:
		over = true
		reason = UiKit.t("Stop fight!")
	if not over:
		return

	marshal_called.emit(reason)
	var winner := -1
	if s0 > s1:
		winner = 0
	elif s1 > s0:
		winner = 1
	elif round_downs[0] != round_downs[1]:
		winner = 0 if round_downs[0] > round_downs[1] else 1
	if winner != -1:
		rounds_won[winner] += 1
		margin[winner] += absi(s0 - s1)
	for m in men:
		if m.standing():
			m.rounds_standing += 1
		_close_prompt(m)
		m.order = null
	round_finished.emit(round_no, winner)

	## Best of three. Take two and the third is not fought — Pete, 10 Sep 2026.
	if round_no >= Tuning.ROUNDS \
			or rounds_won[0] >= Tuning.BOUT_WINS or rounds_won[1] >= Tuning.BOUT_WINS:
		phase = Phase.OVER
		bout_finished.emit(bout_winner())
	else:
		phase = Phase.CORNER
		corner_t = corner_time


func bout_winner() -> int:
	if rounds_won[0] != rounds_won[1]:
		return 0 if rounds_won[0] > rounds_won[1] else 1
	if downs[0] != downs[1]:
		return 0 if downs[0] > downs[1] else 1
	return -1


func is_over() -> bool:
	return phase == Phase.OVER


## Play it out with nobody drawing anything. [C-3] — the same code path, and it
## has to be able to win.
func run_to_end(max_seconds: float = 600.0) -> void:
	var guard := int(max_seconds / Tuning.TICK)
	while not is_over() and guard > 0:
		tick()
		guard -= 1


## ------------------------------------------------------------- the skip
## SKIP THE REST OF THIS ROUND — Pete, 13 Sep 2026: *"you should be able to speed
## skip a round at a time if you want just like Retro Bowl speed skips quarters."*
##
## Retro Bowl's `btn_skip_time` sets a `skip_half` flag, pushes the commentary
## along with `comm_proceed`, and DESTROYS ITS OWN BUTTON; `s_check_skip_time_button`
## then refuses to re-create it while a skip is running. The screen does the same
## two things — see `melee_scene._skip_round()` — and this is the half that runs
## the fight.
##
## IT IS THE SAME TICK LOOP AS `run_to_end`, and that is the entire design. A skip
## that fast-forwarded through a cheaper code path would be a different fight from
## the one you would have watched, and the player would have no way of knowing
## which of his results came from which. `test_grade.gd` runs a bout twice from
## one seed — once watched, once skipped — and asserts every man's state,
## stability, tank and the round clock come back identical.
##
## Stops at the end of the round rather than the end of the bout: CORNER is a
## decision point and skipping past it would spend your swaps for you.
func skip_round() -> void:
	if is_over() or phase == Phase.CORNER:
		return
	var start := round_no
	var guard := int(Tuning.ROUND_TIME / Tuning.TICK) + 1
	while guard > 0 and not is_over() and phase != Phase.CORNER and round_no == start:
		tick()
		guard -= 1
