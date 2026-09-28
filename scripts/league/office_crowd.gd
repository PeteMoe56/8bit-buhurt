class_name OfficeCrowd
extends RefCounted
## Methods of `ClubOffice`, moved out of club_office.gd so that file is not one
## three-thousand-line object. Every function takes the ClubOffice as `o`; `ClubOffice`
## keeps a one-line wrapper for each, so callers did not change.




static func fan_cap(o: ClubOffice) -> float:
	## A QUARTER MORE THAN THE GROUND HOLDS. Pete: *"each level can have 25% over
	## their max upgraded arena… 25% of fans usually never come to events."* So a
	## club at the ceiling sells out and turns people away, which is the top of
	## the whole system and is meant to be reachable.
	return float(o.arena.capacity()) * 1.25




static func draw_scale(o: ClubOffice) -> float:
	var extra := 0.0
	for f in o._draws:
		extra += f
	return clampf(1.0 + extra, 1.0, ClubOffice.DRAW_MAX)




static func set_draws(o: ClubOffice, eight: Array) -> void:
	o._draws.clear()
	for f in eight:
		var d := FighterTrait.mod(f.trait_id, "turnout", 0.0)
		if d > 0.0:
			o._draws.append(d)




## HOW MANY CAME, and it is the number the whole economy now reads.
##
## It used to be a read-out — *"the figure a screen shows when it wants to say
## how full the place looked"* — while `crowd_pay()` was banded off notoriety and
## `gate_income()` off capacity, so the one honest attendance figure in the game
## was the one thing nothing spent.
static func attendance(o: ClubOffice) -> int:
	return int(min(float(o.arena.capacity()), o.fans * o.draw_scale()))




## HOW FULL IT LOOKED, 0 to 1. Not what the gate reads — see `crowd_band()` for
## why — but what a screen says and what the overlay and the commentary want.
static func fill(o: ClubOffice) -> float:
	var c := float(o.arena.capacity())
	return 0.0 if c <= 0.0 else clampf(float(o.attendance()) / c, 0.0, 1.0)




## A RESULT, AND WHAT IT DOES TO THE FOLLOWING. `note_after` in the old money;
## the notoriety half of it is gone and the tier term with it, because a win at
## National is already worth more — it is watched by twelve thousand people
## instead of forty, and `attendance()` says so without a per-tier constant.
static func after_event(o: ClubOffice, won: bool, drew: bool) -> void:
	var gap := o.fan_cap() - o.fans
	if won:
		o.fans += gap * ClubOffice.FANS_WIN_GAP
	elif drew:
		o.fans += gap * ClubOffice.FANS_DRAW_GAP
	else:
		o.fans += o.fans * ClubOffice.FANS_LOSS
	o._clamp_fans()




## Up a division or down one, as a share of the room left.
static func after_move(o: ClubOffice, up: bool) -> void:
	if up:
		o.fans += (o.fan_cap() - o.fans) * ClubOffice.FANS_PROMOTED
	else:
		o.fans += o.fans * ClubOffice.FANS_RELEGATED
	o._clamp_fans()




## A crowd turns up, and afterwards the club is bigger for it.
static func crowd_came(o: ClubOffice, heads: int) -> void:
	## FAN FAVORITE. He is the one they came to see, so the following grows
	## faster while he is here — and Retro Bowl's own wording adds the sting:
	## *"but takes a hit when fired."* See `release()` below; a trait with only an
	## upside is a purchase, not a decision.
	var gain := float(heads) * ClubOffice.FANS_PER_HEAD
	if o.has_trait(ClubOffice.Trait.FAN_FAVORITE):
		gain *= ClubOffice.TRAIT_FANS
	o.fans += gain
	o._clamp_fans()




## The summer. The following sags, which is what makes it something you defend
## rather than something you bank.
static func winter(o: ClubOffice) -> void:
	o.fans = maxf(0.0, o.fans * ClubOffice.FANS_DECAY)
	o._clamp_fans()




static func _clamp_fans(o: ClubOffice) -> void:
	o.fans = clampf(o.fans, 0.0, o.fan_cap())




## HOW BIG A CLUB THIS IS TO A FIGHTER DECIDING WHETHER TO WAIT, 0 to 1.
##
## AND IT IS THE ABSOLUTE SIZE OF THE HOUSE, not the fill — deliberately not the
## same number the gate reads.
##
## The gate asks *"did you fill the place"*, which is a question about this
## season and is the right question to pay on. A fighter deciding whether to wait
## for you is asking something else entirely: **how many people will watch me.**
## A packed back field is forty of them. If this read the band, a sold-out back
## field would out-pull a half-empty National Arena for a man's signature, which
## is the one thing about it nobody would believe.
##
## Log of the crowd against the biggest house in the country, so the climb from
## nobody to somebody is worth a real share of the curve — the property
## `test_office.gd` checks by name and the reason the old version carried a square
## root.
static func pull(o: ClubOffice) -> float:
	return clampf(log(1.0 + float(o.attendance())) / log(1.0 + ClubOffice.BIGGEST_HOUSE),
		0.0, 1.0)




static func note_word(o: ClubOffice) -> String:
	return ClubOffice.CROWD_WORD[o.crowd_band()]




## 0 to 5, and it is the index into both the word and the pay.
static func crowd_band(o: ClubOffice) -> int:
	var f := o.fill()
	var b := 0
	for g in ClubOffice.CROWD_GATES:
		if f >= g:
			b += 1
	return b




## WHAT A FIGHT PAYS FOR BEING WATCHED, before the result is counted.
##
## THE BAND IS YOUR OWN HOUSE AND THE ROOM IS WHOSEVER IT IS. That split is the
## whole model and it is the honest one: the band is how many people you can put
## in a room, and the venue decides whose room it is and what share of the door
## comes back to you. So a big club at a tip takes a tip's share of a big crowd,
## and a small club that draws a National Arena takes more than it has ever seen.
##
## `kind` is the venue, `host_level` and `host_condition` are the GROUND IT IS
## FOUGHT IN — yours at home, theirs away, the federation's on neutral ground.
## Pete, 15 Sep 2026: *"you may actually look forward to an opponent with a great
## stadium or roll your eyes from an opponent with a shitty arena."*
##
## A FLOOR OF ONE, for the same reason band 0 pays at all: **a multiplier that
## can legitimately reach zero annihilates whatever it is applied to**, and this
## project has already lost twenty seasons of gate income to exactly that. A club
## nobody has heard of, away, at a ruin, still comes home with a credit.
static func gate_for(o: ClubOffice, kind: int, host_level: int, host_condition: float) -> int:
	return maxi(1, int(round(float(ClubOffice.CROWD_PAY[o.crowd_band()])
		* Venue.gate_share(kind)
		* Arena.worth(host_level, host_condition))))




## THE OLD DOOR, kept for the screens that want "what is a home fight worth" as a
## headline figure rather than for a particular fixture. It is the club's own
## ground at home, which is the question those screens are actually asking.
static func crowd_pay(o: ClubOffice) -> int:
	return o.gate_for(Venue.Kind.HOME, o.arena.level, o.arena.condition)




## How far along the current band we are, 0 to 1 — the meter itself. The top band
## fills against the ceiling, so a club at 125 reads full rather than reading
## "just started band 5" forever.
static func crowd_meter(o: ClubOffice) -> float:
	var b := o.crowd_band()
	var lo: float = 0.0 if b == 0 else ClubOffice.CROWD_GATES[b - 1]
	var hi: float = ClubOffice.CROWD_TOP if b >= ClubOffice.CROWD_GATES.size() else ClubOffice.CROWD_GATES[b]
	if hi <= lo:
		return 1.0
	return clampf((o.fill() - lo) / (hi - lo), 0.0, 1.0)




## What the ground pays you just for existing: the federation rotates who hosts,
## and a better ground takes a bigger turn.
##
## IT IS MEANT TO BE SMALL AND IT WAS NOT. At `^0.62 x 0.22` a full National
## Arena paid **284 CC every summer for doing nothing** — nearly five times the
## cost of the arena itself, every year, forever. tools/probe_economy.gd found it
## the first time anybody put a season's income next to a season's prices: a
## National club earned 394 a year against a 60-credit ground, so every sink in
## the game was decorative above the State League and the crowd banding that was
## just added was 19% of an income it was supposed to drive.
##
## The exponent is the whole bug. At 0.62 this grows nearly as fast as the crowd
## does, so it is really "attendance, paid twice" — once here and once through
## the event gate, where it belongs. At **0.30** it grows like the LOG of the
## crowd: 2 CC at a back field, 6 at a sports hall, 11 at an arena, 22 at a full
## National Arena. A tenth of what it was at the top and almost unchanged at the
## bottom, which is the right shape for a retainer.
##
## The events are where the arena earns. That sentence was already in this
## comment and the code disagreed with it.
##
## ---------------------------------------------------------------------------
## AND IT DISAGREED WITH IT AGAIN, in the other direction, and paid NOTHING.
##
## Every figure in the paragraph above is a CAPACITY. 40 at a back field gives
## `40^0.30 x 0.72 = 2`; a sports hall's 1,200 gives 6; an arena's 12,000 gives
## 11; a National Arena's 80,000 gives 22. Those are the four numbers written
## down, and they are the four numbers the ground's own size produces.
##
## The function was reading `attendance()` — capacity multiplied by `turnout()`,
## which is `notoriety / 125`. A club that has not made a name yet sits at the
## notoriety FLOOR of 1.0, so its turnout is 0.008, and 12 followers times 0.008
## is 0.096, and `int()` of that is ZERO. Not a small gate: no gate, and no gate
## for as long as the club is unknown, which at the bottom of the pyramid is
## forever.
##
## A twenty-season walk found it as a column of noughts. Every other line in the
## summer ledger was doing something; this one paid 0 in all twenty years, and
## the club's entire income was its members' dues, which fall as it loses.
##
## **A multiplier that can legitimately reach zero annihilates whatever it is
## applied to.** That is the same shape as the sentinel that was a legal value
## and the guard that could only fail: the fault is never the number, it is that
## nothing downstream can tell "very small" from "not there".
##
## A RETAINER IS NOT A GATE. It is what the federation pays for the ground
## existing and being available to host — *"the federation rotates who hosts, and
## a better ground takes a bigger turn."* It is a fact about the GROUND. What the
## crowd is worth is `gate_for()`, paid at every fixture off the ATTENDANCE band
## and the venue's share, and that one already reads the crowd correctly, floors
## at 1 for a club nobody has heard of, and says in its own comment why: *"a club
## nobody has heard of is the club that most needs a trickle."*
## THE TWO CONSTANTS MOVED TO `Arena`, with the condition that scales them —
## `Arena.RETAINER_POW` and `Arena.RETAINER_K`. What a ground is worth is a fact
## about the ground, and this file had it because this file happened to be where
## the arithmetic was written. Everything below still forwards.


## THE RETAINER THE GROUND PAYS ACROSS A SEASON, and what state it is in now
## decides how much of it arrives.
##
## `arena.gate_scale()` is 1.0 at a spotless ground and 0.45 at a ruin, so a club
## that lets its ground go is earning a little over half what it built. That is
## the whole of Pete's *"it raises your income but costs to maintain as it
## degrades"* — the raise is the level, the cost is the upkeep, and the slide
## between them is this multiplier.
static func gate_income(o: ClubOffice) -> int:
	return o.arena.retainer()




## AND WHAT IT WOULD BE IF THE GROUND WERE KEPT. The finances screen shows both,
## because "you are losing four credits a season to rubbish" is an argument and
## "you earn eleven" is a number.
static func gate_income_full(o: ClubOffice) -> int:
	return o.arena.retainer_full()




## PUT THE GROUND RIGHT. One visit a week, like the armorer, and for the same
## reason: without a throttle a club with credits walks a ruin back to new in an
## afternoon and the whole axis becomes a vending machine.
static func tidy_arena(o: ClubOffice) -> String:
	if o.arena.condition >= 0.999:
		return "The ground is already spotless."
	if o._throttled(ClubOffice.SLOT_TIDY):
		return "The ground has already been seen to this week."
	var cost := o.arena.upkeep_cost()
	if o.credits < cost:
		return "That costs %d CC and you have %d." % [cost, o.credits]
	o.spend(cost, ClubOffice.LINE_GROUND)
	o.arena.condition = 1.0
	o._mark(ClubOffice.SLOT_TIDY)
	return ""




static func training_points(o: ClubOffice) -> int:
	return o.level(ClubOffice.Facility.TRAINING) * 3




static func practice_ground(o: ClubOffice) -> float:
	return 1.0 + ClubOffice.GROUND_PRACTICE * float(o.level(ClubOffice.Facility.TRAINING))
