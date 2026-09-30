class_name Contracts
extends RefCounted
## WHAT A MAN IS ON, as distinct from what he is worth.
##
## Taken from Retro Bowl at Pete's instruction (10 Sep 2026) — the re-sign versus
## extend fork and the rookie discount — and it is the change that makes the
## salary cap into a game rather than a subtraction.
##
## Until now `ClubOffice.wage()` read a fighter's rating and billed it, live. That
## is not a contract, it is a price tag: a man who improved got more expensive the
## instant he improved, so developing somebody was self-defeating and the cap
## punished exactly the thing the training ground exists to do. **The whole point
## of a contract is that it fixes a number while the man underneath it moves.**
##
## So a card now carries the deal it signed — `wage_agreed` and `years` — and
## `ClubOffice.wage()` becomes the MARKET RATE: what he would cost today, which
## is what a new deal is priced off and what the roster screen compares against.
## The bill reads the deal. The gap between them is the whole game:
##
##   a young man on a long deal who has improved      cheap, and yours
##   a veteran on a deal signed at his peak           expensive, and declining
##
## THE FORK. Retro Bowl makes you choose between extending early and re-signing
## late, and the tension is real money:
##
##   EXTEND    while the deal still runs. Cheaper the more years are left,
##             because you are taking on the risk that he does not come good.
##   RE-SIGN   when it has run out. Full market rate, no discount, and the
##             player has had a whole season to see what he is getting.
##
## A club that extends everybody early overpays for the ones who stall. A club
## that never extends pays full price for the ones who came good. Neither is
## right, which is what makes it a decision.

## How long a deal runs when it is signed. Short enough that the roster screen
## has something happening on it every year, long enough that an extension is a
## real commitment.
const YEARS_NEW: int = 3
const YEARS_MAX: int = 5

## THE ROOKIE DISCOUNT. A man nobody has seen fight signs cheap, which is what
## makes the reserve worth filling and a walk-on worth more than his rating says.
## Retro Bowl's rookies come in around this and it is the right number: enough to
## matter on the cap, not so much that a squad of children beats a squad of
## fighters.
const ROOKIE_RATE: float = 0.60
## Who counts as one. Not "newly signed" — a 33-year-old free agent is not a
## rookie however new he is to your books — but young enough that the club is
## taking a real gamble on him.
const ROOKIE_AGE: int = 23

## THE EXTENSION CURVE. A discount per year still left to run, so buying out four
## years of a deal is much cheaper per year than buying out one.
##
## Capped well short of free. At 0.10 a year and no cap, a five-year extension
## would land at half price and the correct play would be to extend every man the
## day you sign him — which is not a fork, it is a button.
const EXTEND_PER_YEAR: float = 0.09
const EXTEND_MAX_OFF: float = 0.28


## What a fresh deal costs a week, for this man, signed today.
static func offer(market_rate: int, age: int) -> int:
	var rate := float(market_rate)
	if age <= ROOKIE_AGE:
		rate *= ROOKIE_RATE
	return maxi(1, int(round(rate)))


## What an extension costs a week — the market rate today, discounted by how much
## of the old deal the club is tearing up.
##
## It is priced off the CURRENT market rate rather than off the old wage on
## purpose. Extending a man who has improved costs more than his old deal and
## should: the discount is for taking the risk early, not for pretending he is
## still the fighter he was three years ago.
static func extension(market_rate: int, age: int, years_left: int) -> int:
	var off := minf(EXTEND_PER_YEAR * float(maxi(0, years_left)), EXTEND_MAX_OFF)
	return maxi(1, int(round(float(offer(market_rate, age)) * (1.0 - off))))


## Can this deal be extended at all? A man in the last year of his deal is
## re-signed rather than extended — otherwise "extend" and "re-sign" are the same
## button with two prices and the player picks the cheaper one, which is not a
## decision.
## THE LAST YEAR IS DELIBERATELY NOT EXTENDABLE, and `test_market.gd` says why:
## otherwise extend and re-sign are the same button with two prices and the
## player takes the cheaper one. A man at one year runs his deal out, becomes
## OUT OF CONTRACT — still on the books, still visible, for a whole season — and
## is re-signed then. That is the road, and it works.
##
## It was briefly widened to `>= 1` on 14 Sep 2026, on the strength of a probe
## whose keeper lost a squad anyway: the doors looked like they pointed at each
## other, and the real drain turned out to be retirement with no refill. The
## bound went back. What was genuinely wrong was `Season.resign()`'s REFUSAL,
## which sent that man to a door that would not open — see the note there.
## REVERSED BY PETE, playtest 30 Sep 2026: *"You should be able to extend
## fighters in their last year."* The last year is extendable; re-signing is
## what a man OUT of contract needs. The fork left is extend (under contract,
## the discount) or re-sign (out of it, market rate).
static func can_extend(f: FighterCard) -> bool:
	return f.years >= 1 and f.years < YEARS_MAX


## Every deal loses a year at the summer. Returns the men whose deal has now run
## out — they are not gone, they are OUT OF CONTRACT, which is a different and
## much more interesting state: still on your books, still biddable, and about to
## leave if nobody does anything.
static func age_deals(roster: Array) -> Array:
	var expiring: Array = []
	for f in roster:
		f.years = maxi(0, f.years - 1)
		if f.years <= 0:
			expiring.append(f)
	return expiring


## WHETHER HE WAITS. A man out of contract does not sit there forever — he has a
## season to find a club, and the better he is the less patient he is about it.
## This is what stops "out of contract" being a free extra roster slot.
##
## Rolled against the club's standing rather than at random: a fighter will wait
## for a club people have heard of. Notoriety reaching a roster decision is the
## kind of connection that makes two systems into one game.
## AND WHETHER HE IS HAPPY. Morale was a read-out with nothing reading it — a
## number that moved with results, was drawn on the Clubhouse, and reached
## exactly nothing, which is the same "progress bar with a name on it" this
## codebase already threw a facility out for being. The dilemmas (section 28)
## move morale constantly, so it needed a consumer before it could be a lever.
##
## This is the right one: **men leave unhappy clubs.** It costs nothing to
## explain, it is true of the sport, and it means a season of bad choices shows
## up in the one place a player cannot ignore — the team sheet.
## ------------------------------------------------------------ negotiation
## THE RETRO BOWL PHILOSOPHY, AND IT IS NOT A HAGGLE — Pete, 13 Sep 2026:
## *"We'll have to build negotiations off the Retro Bowl philosophy."*
##
## Read out of the decompile, their whole player-contract model is four rules:
##
##   `s_get_new_salary`         salary = rating * a per-position rate. A formula.
##                              There is no offer, no counter-offer, no haggling.
##   attitude <= 45             `msg_CannotSignMoraleLow` — *"$playername is not
##                              interested in signing a new contract. His morale
##                              is low."* A REFUSAL, not a price.
##   `msg_ContractExpired`      *"He wants a $year year contract with a salary of
##                              $salary."* He states terms; you meet them or not.
##   `msg_MeetingExtendContract` extending early costs CREDITS, and freezes the
##                              salary at what he is worth today.
##
## The core of it is worth saying plainly, because it is the opposite of what a
## contract system usually is: **you cannot negotiate money. The price is the
## price.** What you are actually negotiating is whether he wants to be here at
## all — and that was decided over the three seasons before this conversation, by
## how you picked him, paid him and spoke about him.
##
## A probability says "you might get lucky". A refusal with a reason says "you
## did this", and it is the better half of a management game.
##
## Ours in our nouns: a man at or under this will not re-sign for any wage.
## Theirs is 45 of 100; morale here runs 0 to 1 and the bands already in
## `fighter_card.gd` put 0.45 between angry and the flag, which is the same place
## on the scale.
const MORALE_REFUSES: float = 0.45


## WILL HE EVEN TALK TO YOU? Checked before anything about money, because if the
## answer is no then the money never comes up.
static func refuses(f: FighterCard) -> bool:
	return f.morale <= MORALE_REFUSES


## WHY, in his words, for the screen that has to say something. Empty when he is
## willing — the caller can print this straight out.
static func refusal(f: FighterCard) -> String:
	if not refuses(f):
		return ""
	return UiKit.t("%s is not interested in signing again. Look at how his season went.") \
		% f.display_name


## ------------------------------------------------- what his mood costs you
## A MAN WHO LIKES IT HERE SIGNS FOR LESS — Pete, 13 Sep 2026: *"If someone likes
## it there and doesnt want to leave, they are more willing to take a lower
## price. If someone is great but hates it, you'll have to pay more."*
##
## This is the half of a wage that is not about how good he is, and it is the
## half that makes the three seasons before the conversation worth playing. His
## rating sets the going rate; his mood decides whether he gives you a discount
## for the privilege of staying or charges you for the inconvenience.
##
## Centerd on 0.70, which is where a club starts and where `will_wait` is also
## centerd — a club that never thinks about morale is neither rewarded nor
## punished, and one that does is doing it for a reason it can see on the wage
## bill.
##
## The floor and ceiling matter as much as the slope. Without the floor a club
## with a delighted squad pays nothing; without the ceiling, a man one point above
## refusing outright would ask for a number no club could meet, which is a refusal
## wearing a price tag and is worse than the refusal because it wastes your time.
const MOOD_SLOPE: float = 0.9
const MOOD_CHEAPEST: float = 0.80
const MOOD_DEAREST: float = 1.25


static func mood_rate(morale: float) -> float:
	return clampf(1.0 + (0.70 - clampf(morale, 0.0, 1.0)) * MOOD_SLOPE,
		MOOD_CHEAPEST, MOOD_DEAREST)


## WHAT HE IS ASKING FOR, stated rather than offered. Years and a wage, off what
## he is worth TODAY — which is the whole reason a levelled-up fighter is a bill
## you have not paid yet, and Pete's rule for the economy:
##
##   *"The overalls and salary costs won't matter until you re-sign the players.
##   So you may run up a player's level, but you have to make sure you can pay
##   them."*
##
## `ClubOffice.billed` reads `wage_agreed` while he is under contract, so every
## level he takes is free until this function runs. `test_traits.gd` asserts it,
## because that freeze is now load-bearing for the entire levelling economy: if
## a level ever raised his bill on the spot, levelling would become something a
## club could not afford to do.
static func demand(f: FighterCard) -> Dictionary:
	var rate := ClubOffice.wage(f)
	var years := YEARS_NEW
	## An older man wants the security and will take fewer years to get it; a
	## young one wants to get back to the table while he is still rising.
	if f.age >= 33:
		years = 2
	elif f.age <= ROOKIE_AGE:
		years = YEARS_NEW
	## HIS MOOD IS ON THE INVOICE. `offer` prices the fighter; this prices the
	## relationship, and they are deliberately two different multiplications so a
	## screen can show a player which half of the number he is looking at.
	var mood := mood_rate(f.morale)
	var asked := maxi(1, int(round(float(offer(rate, f.age)) * mood)))
	return {"wage": asked, "years": years, "rate": rate, "mood": mood,
		"refuses": refuses(f), "why": refusal(f)}


static func will_wait(f: FighterCard, pull_: float, band_top: int,
		morale: float = 0.7) -> float:
	var quality := clampf(float(f.overall()) / float(maxi(1, band_top)), 0.0, 1.4)
	## PULLING POWER IS THE SIZE OF THE HOUSE NOW, and it arrives already curved.
	##
	## It was `sqrt(notoriety / 125)`, and the square root was there for a good
	## reason recorded at length: a straight line collected **seven per cent** of
	## a thirty-point lever for a new club, because a club climbing from 1 to 10
	## on a 125 scale is climbing the part of the scale where reputations are
	## actually made and being paid a tenth for it.
	##
	## `ClubOffice.pull()` is the crowd band as a fraction — 0 for a club nobody
	## comes to and 1 for a full National Arena — and the bands are already spaced
	## like the log of the crowd (25 / 90 / 300 / 1,000 / 6,000 heads). So the
	## curve the square root was providing is in the quantity itself, and applying
	## another one on top would compress it twice. **A curve applied to an
	## already-curved number is a curve nobody can reason about.**
	var pull := clampf(pull_, 0.0, 1.0)
	## Centerd on 0.7, which is where a club starts, so a club that never thinks
	## about morale is neither rewarded nor punished for it.
	var mood := clampf(morale, 0.0, 1.0) - 0.7
	## AND A FLOOR UNDER ALL OF IT. Above the line the old maths still decides —
	## a good man at a small club is still a risk. Below it there is nothing to
	## decide: he is gone, and the club knows exactly why.
	if refuses(f):
		return 0.0
	return clampf(0.86 - quality * 0.45 + pull * 0.30 + mood * 0.35, 0.05, 0.97)
