class_name FighterCard
extends Resource
## One fighter, and the line position he is fielded in.
##
## Position is where he stands (Tuning.Pos). It is not a role taxonomy — that
## conflation is what killed the last version's seven "roles", which mixed
## *where you stand* with *what you do* and produced names nobody in the sport
## uses. Rail, Flanker and Center are places on a line.

@export var display_name: String = "Fighter"
@export var number: int = 1
@export var pos: Tuning.Pos = Tuning.Pos.CENTER

## Puts men down and drives through a line.
@export_range(1, 99) var strength: int = 50
## Resistance to being put down. The quietest stat; it wins the most rounds.
@export_range(1, 99) var base: int = 50
## Takedowns, escapes, and getting anything out of a bad position.
@export_range(1, 99) var skill: int = 50
## The gas tank — the sport's own recognised limiter (dossier glossary #110).
@export_range(1, 99) var gas: int = 50
## How readily he commits without being told. Drives the AI's menu choices when
## you don't answer the prompt. High is not better.
@export_range(1, 99) var aggression: int = 50
## POUNDS in harness, not kilograms — Pete, 10 Sep 2026. Decides a bullrush more
## than anything else does. A full harness is 60-80 lb on top of the man, so a
## fighter in kit runs from about 190 to 310.
@export_range(130, 340) var weight: int = 203

## Armor condition, 0-1. Armor is this game's salary cap: rattling harness costs
## Base, and Base is what keeps a man on his feet.
@export_range(0.0, 1.0, 0.01) var armor: float = 1.0
## WHICH HARNESS HE OWNS, as opposed to the state it is in. `armor` is the
## condition; this is the kit. See `Quartermaster` — one integer rather than
## three slots with their own bars, because the decision is always "is this
## man's kit good enough" and one number answers it.
##
## Zero is Borrowed, which is what every fighter in the world starts in and what
## an AI club's men would be in if AI clubs had men.
@export var harness: int = 0

## WHAT IS UNUSUAL ABOUT HIM, or `FighterTrait.T.NONE`, which is most men.
##
## Stored as the int rather than the name: a save that kept the string would
## break the day a trait is renamed, and a save that kept an index into a sorted
## list would break the day one is added. The enum is append-only for the same
## reason — see the header of `fighter_trait.gd`.
@export var trait_id: int = 0

## HIS OWN CURVE. Pete, 15 Sep 2026: *"make sure these guys have varying peaks
## on them. We don't want/need every fighter to have the exactly same stats."*
##
## Every fighter in this game aged to the same schedule: gas at 24, strength at
## 28, base at 32, skill at 35, for everyone, forever. Two traits moved the whole
## set for one man and nothing else varied at all — so a twenty-four-year-old was
## a twenty-four-year-old and a scouting report could only ever say what his
## birthday said.
##
## This is the seed his peak OFFSETS are drawn from — see `Career.peak_for`. One
## integer rather than four, because four fields would be four things a save can
## disagree with itself about, and because they want to be drawn together: a man
## is early or late, he is not independently early at one thing.
##
## ZERO MEANS THE SPORT'S OWN SCHEDULE, which is what a fighter out of a save
## written before this existed actually has — he was generated without a curve of
## his own, so decoding him as average is true rather than a default standing in
## for something missing.
@export var peak_seed: int = 0

## WHAT LEVEL HE IS. Starts at one and climbs whenever his banked XP reaches
## `level * Career.LEVEL_XP` — see the header of `career.gd` for why that stopped
## being a winter-only thing.
@export var level: int = 1

## ON THE FIGHTING EIGHT. Pete, 10 Sep 2026: the eight are who travel — five on
## the line and three on the bench — and a club may carry five more in RESERVE,
## who never appear at an event at all. You train them, outfit them, sign and
## cut them in the roster menu, and promote them onto the eight when they are
## ready. `active` is that line, and it is the only thing that decides whether a
## man is at the event.
@export var active: bool = true

## Fit to fight. Separate from `active` on purpose: an injured man is still on
## your eight and still taking up the place, which is exactly the problem an
## injury is supposed to be.
@export var available: bool = true

## ------------------------------------------------------------------- career
## HOW OLD HE IS, and it is not cosmetic — see scripts/game/career.gd, which
## holds four different peak ages because a buhurt fighter has four. The tank
## goes at 24, strength at 28, not-being-put-down at 32, technique at 35.
@export_range(16, 60) var age: int = 26

## THE CEILING ON `overall()`, and the second number the player reads. Not a cap
## on any single stat: a fighter can rearrange himself under it however his
## training goes, he just cannot exceed it. There is exactly one way to raise it
## — one prospect a winter — because anything buyable in bulk stops being a
## ceiling and becomes a price.
@export_range(1, 99) var potential: int = 70

## THE DEAL HE IS ON, in dollars a week, and how many summers it still has to
## run. Distinct from `ClubOffice.wage()`, which is what he would cost TODAY —
## see scripts/league/contracts.gd. The bill reads this; the market reads that;
## the gap between them is the whole reason a cap is interesting.
##
## Zero means he has never been put on paper — a generated club's men are given
## deals the moment the club is built, so this only shows up on a hand-made card.
@export var wage_agreed: int = 0
## Summers left. At zero he is OUT OF CONTRACT: still on the books, still able to
## be re-signed, and about to walk.
@export_range(0, 6) var years: int = 3

## EARNED BY DOING. Downs caused and rounds finished standing, off the same
## numbers the post-fight report already shows. A man who is not on the eight
## earns none, which is the entire reason a squad is a squad.
@export var xp: int = 0

## Events still to sit out. A knock does not stop him being on the eight — it
## stops him fighting, and the eight has to cover for him, which is the entire
## point of carrying a bench and a reserve.
@export var injury: int = 0


## Can he go out this weekend? Everything that picks a line asks this rather
## than reading `available` directly, so a man cannot be injured in one place
## and fit in another.
## ------------------------------------------------------------- how he is
## HIS OWN MORALE, not the club's.
##
## The club carried one float and every man in it felt the same way about
## everything. Retro Bowl keeps it per player on a seven-step scale — Toxic,
## Bad, Poor, Ok, Good, Great, Exceptional — and the bottom of that scale is not
## a personality type, it is a man who has had enough.
##
## THE TOXIC END IS NOT ONLY A PENALTY, and that is what makes it a decision.
## Their own tip screen says it out loud: *"Players receive a +1 strength buff
## if their morale is angry or toxic"* and *"Toxic players receive a +1 stamina
## buff."* The difficult man is BETTER at the sport. He drags the eight down
## after a loss and nobody will take him off your hands, and he is also the
## hardest man on your line. That is why you keep him, and why keeping him
## costs something.
@export_range(0.0, 1.0, 0.01) var morale: float = 0.70


## Toxic is the bottom band, and it is a state rather than a trait — a man
## arrives here, and he can be talked back out of it.
func toxic() -> bool:
	return morale < 0.18


## Angry is the band above it: unhappy enough to hit harder, not yet a problem.
func angry() -> bool:
	return morale < 0.34


## The seven words, anchored the way the club's five are — on where morale
## actually sits rather than on an even split of the range.
func morale_word() -> String:
	if morale >= 0.86:
		return "Exceptional"
	if morale >= 0.70:
		return "Great"
	if morale >= 0.54:
		return "Good"
	if morale >= 0.38:
		return "Ok"
	if morale >= 0.26:
		return "Poor"
	if morale >= 0.18:
		return "Bad"
	return "Toxic"


## THE MOOD AS A CARD-SIZED FLAG, or nothing at all.
##
## A roster card has room for a five-character word beside the rating and the
## age, and the seven words are not all five characters — "Exceptional" ran
## straight through the ceiling note on the card next to it the first time this
## was drawn. It also does not need saying: a contented man is the default, and a
## card that comments on every mood comments on none of them.
##
## So the flag appears only when the mood is something to act on, which is also
## where the words happen to be short.
const FLAG_BELOW: float = 0.54


func morale_flag() -> String:
	return morale_word() if morale < FLAG_BELOW else ""


## THE COLOR OF A MOOD, so every screen that prints the word prints it the same
## color. Three screens were deciding this independently the first afternoon.
func morale_color() -> Color:
	if toxic():
		return UiKit.DOWN
	if angry():
		return UiKit.YOU
	if morale >= 0.70:
		return UiKit.UP
	return UiKit.INK


## WHAT BEING UNHAPPY IS WORTH IN THE LIST. Proportional rather than Retro
## Bowl's flat +1, because their stats read 1-10 and ours read 1-99 — a flat
## point here would be a rounding error rather than the trade it is meant to be.
const CHIP_STRENGTH := 6
const CHIP_GAS := 6


func fighting_strength() -> int:
	var chip := int(FighterTrait.mod(trait_id, "chip_strength", float(CHIP_STRENGTH)))
	return clampi(strength + (chip if angry() else 0), 1, 99)


func fighting_gas() -> int:
	return clampi(gas + (CHIP_GAS if toxic() else 0), 1, 99)


## Move him, through a logistic so nothing walks him into a wall — the same
## shape the club's own morale uses and for the same reason.
func morale_shift(d: float) -> void:
	var room: float = (1.0 - morale) if d > 0.0 else morale
	## STEADY does not sulk. The floor is his, not the club's, so a bad run can
	## still cost you the room — it just cannot cost you him.
	var floor_ := FighterTrait.mod(trait_id, "morale_floor", 0.02)
	morale = clampf(morale + d * room, floor_, 0.99)


## ------------------------------------------------------------------ the book
## WHAT HE HAS ACTUALLY DONE, and until now the game kept none of it.
##
## The sim counts downs caused and rounds finished standing every bout — it has
## to, because that is what XP is paid on — and then threw both away the moment
## the XP was banked. So a fighter had a level and no record: no way to know
## whether the man on your Center had put three hundred people down or had a
## quiet four years. A career mode whose careers leave no trace is a stat
## screen's worth of work away from being one that does.
@export var bouts: int = 0
@export var downs: int = 0
@export var rounds_standing: int = 0
## The best single afternoon, kept separately because a total says what a man
## has done and a peak says what he is capable of.
@export var best_downs: int = 0
## THE WORK NOBODY WATCHES. Second-most damage on a man who then went down at
## somebody else's hands — the Rail who holds two of them while the Center walks
## through, and who by every other number on this card had a quiet afternoon.
@export var assists: int = 0
## THE CLUB HE WILL NOT FORGIVE, as the world knows it, or -1. Set once, by the
## first club that beats him while he is on your eight, and never cleared —
## *"Fights above himself against one named club, forever."* A trait about a
## career has to leave something on the card or it is a trait about an afternoon.
@export var grudge_club: int = -1
@export var knocks: int = 0            ## times he has been carried off
@export var honors: int = 0           ## cups won while on the eight


## Downs per bout, which is the number a scout would actually ask for. Returns
## 0.0 rather than dividing by nothing for a man who has not fought.
func downs_per_bout() -> float:
	return 0.0 if bouts <= 0 else float(downs) / float(bouts)


## KIT INSPECTION. The marshal looks at your harness before you step on, and a
## harness below the line does not step on.
##
## DIRECTION §4: *"The cap isn't money-per-player, it's how many bodies you can
## put on a plane and how many harnesses you own that pass inspection. Bench
## depth is limited by armor, not payroll."* That paragraph has been in the
## document since the first day and the game shipped the thing it replaces — a
## money cap, the literal Retro Bowl mechanic — while `armor` sat as a soft
## multiplier on a man's base and nothing else.
##
## This is the line that makes armor a GATE. A man at 0.30 is not a slightly
## worse fighter, he is a man the marshals will not pass, and the Workshop that
## repairs him stops being a place to spend spare credits and becomes the thing
## that decides whether you can field five.
const INSPECTION_MIN: float = 0.35


func passes_inspection() -> bool:
	return armor >= INSPECTION_MIN


## How close to being failed. 1.0 at a full harness, 0.0 at the line.
func inspection_margin() -> float:
	return clampf((armor - INSPECTION_MIN) / maxf(0.01, 1.0 - INSPECTION_MIN), 0.0, 1.0)


## CAN HE GO OUT AT ALL. Three separate reasons he might not, and every one of
## them is read through here so no screen and no lineup can check two of the
## three and miss the one that matters this weekend.
func fit() -> bool:
	return available and injury <= 0 and passes_inspection()


## WHY NOT, in a word, for the screens. Ordered by what a player can do about it
## soonest: a harness is fixable this week, a knock is not, and a man who cannot
## get the weekend off is not a problem you solve with money.
func unfit_reason() -> String:
	if injury > 0:
		return "out %d" % injury
	if not passes_inspection():
		return "kit failed"
	if not available:
		return "unavailable"
	return ""


## How much room is left before the ceiling. Negative is impossible by
## construction on a fresh card and possible on an old one only if a potential
## was hand-written low — `headroom` clamps rather than showing a fighter as
## being beyond himself.
func headroom() -> int:
	return maxi(0, potential - overall())


## Past his peaks and falling away from what he could have been. The roster
## screen says so, because "he is 37 and eight off his ceiling" is the whole
## argument for replacing him and the player should not have to do the
## subtraction himself.
func fading() -> bool:
	return age > Career.PEAK_BASE and potential - overall() >= 4


func overall() -> int:
	return int(round(rating()))


## The same figure unrounded, and with harness condition already in it. Kit is
## this game's salary cap: a man in rattling harness loses base, and base wins
## rounds, so he is simply a worse fighter — not a good fighter with an asterisk
## applied somewhere else. Club power averages these, so armor reaches the league
## table by the same road as everything else.
func rating() -> float:
	return float(strength) * 0.22 + effective_base() * 0.24 + float(skill) * 0.24 \
		+ float(gas) * 0.22 + float(aggression) * 0.08


## The size of the tank reads the CHIPPED gas, so a toxic man genuinely lasts
## longer rather than only appearing to on a screen.
func tank() -> float:
	return 0.70 + (float(fighting_gas()) / 99.0) * 0.60


func effective_base() -> float:
	return float(base) * lerpf(0.78, 1.0, armor)


func pos_name() -> String:
	return Tuning.pos_name(pos)


func copy() -> FighterCard:
	var c := FighterCard.new()
	c.display_name = display_name
	c.number = number
	c.pos = pos
	c.strength = strength
	c.base = base
	c.skill = skill
	c.gas = gas
	c.aggression = aggression
	c.weight = weight
	c.armor = armor
	c.harness = harness
	c.trait_id = trait_id
	c.peak_seed = peak_seed
	c.level = level
	c.active = active
	c.available = available
	c.injury = injury
	c.age = age
	c.potential = potential
	c.xp = xp
	c.wage_agreed = wage_agreed
	c.years = years
	c.bouts = bouts
	c.downs = downs
	c.rounds_standing = rounds_standing
	c.best_downs = best_downs
	c.assists = assists
	c.grudge_club = grudge_club
	c.knocks = knocks
	c.honors = honors
	c.morale = morale
	return c
