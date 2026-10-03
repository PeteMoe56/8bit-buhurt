class_name Dilemma
extends RefCounted
## THE THING THAT HAPPENS BETWEEN FIGHTS.
##
## The last of Pete's eight, and the one that is least about numbers. Retro Bowl
## puts a small scenario in front of you after nearly every game — a player is
## unhappy, somebody has an idea, the press wants something — and you pick one of
## two or three answers. They cost almost nothing individually and they are the
## reason their season has a texture instead of a rhythm.
##
## THE RULE THAT MAKES THEM WORK: **every option has to cost something.** A
## dilemma with a right answer is a quiz, and a player solves a quiz once and then
## stops reading. So there is no free option anywhere in this file — the choice is
## always which currency you would rather spend, and the currencies are
## deliberately different in kind so they cannot be compared with arithmetic:
##
##   CC        the only money there is
##   morale    which decides who waits for you and who retires early
##   the room  the following — who turns up, which is the whole gate
##   a man     his harness, his fitness, his deal, his ceiling
##
## Trading credits for morale is a decision. Trading credits for credits is not.
##
## THEY ARE ABOUT BUHURT, not about sport in general. Every card here is
## something that happens on a real list or in a real club's group chat: harness
## condemned at the gate, somebody fighting for two clubs, a marshal wanting a
## word, a brewery offering to put its name on the rail. The generic version of
## this feature — "a player is unhappy, give him money or don't" — would have been
## half the work and none of the point.

## Tokens a card's text can carry. `{man}` is the fighter this card picked out;
## everything else is context.
##   {man}    a fighter on the books, chosen by the card's own `who`
##   {club}   your club
##   {rival}  the club you just played
enum Who { ANYONE, OLDEST, YOUNGEST, WORST_KIT, A_RESERVE, BEST }


## ------------------------------------------------------ who gets offered what
## YOUR NAME DECIDES WHAT PEOPLE BRING YOU.
##
## Pete, 15 Sep 2026, on where notoriety should go: *"Delete it and make Coaches
## reputation a driving factor on what appears for the conflicts or choices.
## Better reputations mean better choices, but bad reputations can also mean more
## choices that have chances for cheating or subversion."*
##
## THIS IS A BETTER HOME FOR IT THAN THE WALLET EVER WAS. A club's fame banded
## the gate, which made it a second income multiplier sitting beside the ground;
## a COACH's name decides who knocks on his door, which is a thing reputations
## actually do and a thing no other system in this game was modelling.
##
## Three kinds of card, and the middle one is most of the deck:
##
##   CLEAN   the offers a well-regarded man gets. A federation course, a
##           sponsor who wants to be associated with you, a good young fighter
##           who would rather be here.
##   ANY     the ordinary business of a club. Always in the deck.
##   SHADY   what turns up when nobody is watching your name. A cheap harness
##           of uncertain provenance, a marshal who can be spoken to, a man who
##           will fight under another name.
##
## THE SHADY CARDS ARE NOT PUNISHMENT. Several of them are the best deal on the
## page — that is what makes a bad reputation a texture rather than a debuff, and
## what makes climbing out of one a decision rather than an obligation.
enum Tone { ANY, CLEAN, SHADY }

## WHERE THE DOOR OPENS AND SHUTS, on `Coach.reputation`'s 1–20 scale. A coach
## nobody has heard of is a 1 and sits in the shady half by default, which is
## right: he has no name to protect and nobody is bringing him federation work.
const CLEAN_FROM: int = 11
const SHADY_UNDER: int = 9


## WHICH CARDS THIS COACH IS OFFERED. Always the ordinary ones, plus whichever
## end of the deck his name has opened.
##
## THE BANDS OVERLAP DELIBERATELY. Between 9 and 11 a coach gets both halves,
## because a reputation crossing a line and the deck changing completely on the
## same tick would read as a bug rather than as a consequence.
static func deck_for(reputation: int) -> Array:
	var out: Array = []
	for c in CARDS:
		var tone := int(c.get("tone", Tone.ANY))
		if tone == Tone.ANY \
				or (tone == Tone.CLEAN and reputation >= CLEAN_FROM) \
				or (tone == Tone.SHADY and reputation < SHADY_UNDER):
			out.append(c)
	return out


## HOW OFTEN A CARD COMES UP AT ALL. Default 10; the armorer's van and the two
## cards like it are 3, which is Pete's *"have it kind of rare for sure"* — about
## one appearance in four of an ordinary card's.
##
## A WEIGHT AND NOT A SEPARATE RARE DECK, because a rare deck is a second draw
## with a second chance to be wrong, and the recent-cards memory already stops a
## card repeating whatever its weight.
static func weight_of(card: Dictionary) -> int:
	return int(card.get("weight", 10))


## What an option does. Absent keys do nothing, so a card only writes what it
## changes and a reader can see the whole cost of an answer in one line.
##   cc         credits, + or -
##   morale     -1..1, added
##   note       the room — how much more (or less) the club is talked about;
##              read as a move on the following, since that is the one population
##   fans       a FRACTION of the current following, added
##   armor      to {man}, added (0-1)
##   kit        to every man on the books, added
##   injury     events {man} sits out
##   xp         to {man}
##   potential  to {man}'s ceiling
##   years      to {man}'s deal
const CARDS: Array[Dictionary] = [
{
	## ------------------------------------------------------ the armorer's van
	## Pete, 15 Sep 2026: *"Have some of the decisions effect armor as well, seems
	## like a good cheap add in where the player could decided to spend less to
	## have an at event armorer sell them new gambesons or repair armor. Have it
	## kind of rare for sure."*
	##
	## Three cards, all `weight: 3`, and they are the cheapest thing in this
	## session: the deck already spends `armor` on one man and `kit` on the whole
	## book, so a card that puts harness back is a data entry rather than a system.
	##
	## AND THEY ARE A REAL DECISION BECAUSE THE ARMORER IS A PRICE LIST. Every
	## other road to a repaired harness — `repair_kit`, `buy_harness` — is one man,
	## one week, at a fixed rate. The van is the whole squad at once, at a discount,
	## once in a while, and the cheap option is cheap for a reason.
	"id": "van",
	"who": Who.WORST_KIT,
	"weight": 3,
	"title": "The armorer's van",
	"text": "An armorer has parked his van at the far end of the lot and is selling gambesons, the padded jackets your fighters wear under their steel. He can refit the whole club before the first bout, or just patch up {man}, whose kit is the worst on the squad.",
	"options": [
		{"label": "Refit the whole club", "blurb": "New padding for everyone. Expensive, but every harness comes back up.",
			"fx": {"cc": -6, "kit": 0.22}},
		{"label": "Just fix {man}", "blurb": "Cheap. Only the worst kit gets better.",
			"fx": {"cc": -2, "armor": 0.28}},
		{"label": "Send him away", "blurb": "No money spent. The squad saw you walk past and is annoyed.",
			"fx": {"morale": -0.05, "kit": -0.02}},
	],
},
{
	"id": "surplus",
	"who": Who.ANYONE,
	"weight": 3,
	"tone": Tone.SHADY,
	"title": "Armor that fell off a truck",
	"text": "A guy who knows a guy has a pallet of armor for sale, dirt cheap. It's good steel, but nobody will say where it came from, and one helmet still has another club's name scratched inside. Buy it and people will talk.",
	"options": [
		{"label": "Buy the whole pallet", "blurb": "Kit for the whole club at a bargain. Word gets around about where it came from.",
			"fx": {"cc": -4, "kit": 0.30, "note": -2.0}},
		{"label": "Only the unmarked pieces", "blurb": "A smaller haul, and nothing anyone can trace.",
			"fx": {"cc": -3, "kit": 0.12}},
		{"label": "Walk away", "blurb": "The squad respects it, but the old kit keeps wearing out.",
			"fx": {"morale": 0.04, "kit": -0.03}},
	],
},
{
	"id": "gambeson",
	"who": Who.WORST_KIT,
	"weight": 3,
	"tone": Tone.CLEAN,
	"title": "Federation kit check",
	"text": "The federation is holding a kit check before today's event: a professional fitter, new padding at cost, and an inspector signing off armor on the spot. It takes the morning you would normally spend warming up.",
	"options": [
		{"label": "Send the whole club", "blurb": "Costs a little and the morning. Every harness is legal and the federation notices.",
			"fx": {"cc": -3, "kit": 0.18, "note": 1.0}},
		{"label": "Just send {man}", "blurb": "His kit is the worst on the squad. He comes back fully fixed.",
			"fx": {"cc": -1, "armor": 0.34}},
		{"label": "Skip it and warm up", "blurb": "The fighters get a proper warm-up. The kit keeps wearing.",
			"fx": {"xp": 8, "kit": -0.02}},
	],
},
{
	"id": "harness",
	"who": Who.WORST_KIT,
	"title": "Failed inspection",
	"text": "At the gate, the marshal inspects {man}'s armor and fails it. He can't fight in it today. A blacksmith in the parking lot can repair it before your bout, for a fee.",
	"options": [
		{"label": "Pay the blacksmith", "blurb": "Fixed properly, and he's back on the list today.",
			"fx": {"cc": -3, "armor": 0.30}},
		{"label": "Lend him the spare", "blurb": "The club's spare set barely fits. He fights in it, unhappy.",
			"fx": {"armor": 0.10, "morale": -0.05}},
		{"label": "He sits this one out", "blurb": "He misses this event and the rest of the squad covers.",
			"fx": {"injury": 1, "morale": -0.03}},
	],
},
{
	"id": "two_clubs",
	"who": Who.ANYONE,
	"title": "Fighting for two clubs",
	"text": "{man} has been fighting for another club on the weekends {club} has no event. It isn't against the rules, but the rest of the squad has noticed and they don't like it.",
	"options": [
		{"label": "Fine him", "blurb": "His contract allows it. The squad thinks it's petty.",
			"fx": {"cc": 2, "morale": -0.09}},
		{"label": "Have a quiet word", "blurb": "He gets the message. Not much changes.",
			"fx": {"morale": -0.02, "xp": 4}},
		{"label": "Let him keep at it", "blurb": "The extra fights make him better, and he might get hurt doing it.",
			"fx": {"morale": 0.06, "xp": 12, "injury": 1}},
	],
},
{
	"id": "brewery",
	"who": Who.ANYONE,
	"title": "A brewery sponsor",
	"text": "A brewery from a nearby town wants to sponsor {club} and hang a big banner along your arena's rail. It's steady money, but some of the fighters don't want to be a beer advert.",
	"options": [
		{"label": "Take the deal", "blurb": "Money in and a bigger name. Some grumbling in the locker room.",
			"fx": {"cc": 6, "note": 1.5, "morale": -0.07}},
		{"label": "Say no", "blurb": "The fighters are proud of it. You give up the money.",
			"fx": {"morale": 0.06, "note": -0.5}},
	],
},
{
	"id": "carpark",
	"who": Who.ANYONE,
	"title": "Parking lot fight",
	"text": "After your bout with {rival}, a fight broke out in the parking lot. {man} was in the middle of it and won't say what happened. The story will be all over the circuit by Tuesday.",
	"options": [
		{"label": "Report it yourself", "blurb": "Honest, and the squad respects it. Your reputation takes the hit.",
			"fx": {"note": -2.0, "morale": 0.08}},
		{"label": "Keep quiet", "blurb": "Nobody can prove anything, but the squad hates the silence.",
			"fx": {"note": 2.5, "morale": -0.10}},
	],
},
{
	"id": "veterans_place",
	"who": Who.OLDEST,
	"title": "The veteran steps aside",
	"text": "{man}, your oldest fighter, has offered to step off the traveling squad so a young fighter can get event experience. He means it, but he is still one of your best.",
	"options": [
		{"label": "Accept his offer", "blurb": "The squad loves it. He takes a year off his contract.",
			"fx": {"morale": 0.10, "years": -1}},
		{"label": "Keep him traveling", "blurb": "You stay stronger now. The youngster waits, and the squad notices.",
			"fx": {"morale": -0.05, "xp": 10}},
	],
},
{
	"id": "film_crew",
	"who": Who.ANYONE,
	"title": "Documentary crew",
	"text": "A film crew making a documentary about armored combat wants to follow {club} for the rest of the season, cameras in the locker room included. Great for your name, hard on the fighters.",
	"options": [
		{"label": "Give them full access", "blurb": "A big boost to your name and your crowd. The fighters hate the cameras.",
			"fx": {"note": 5.0, "fans": 0.05, "morale": -0.12}},
		{"label": "Training sessions only", "blurb": "Some exposure, some annoyance.",
			"fx": {"note": 2.0, "morale": -0.04}},
		{"label": "Turn them down", "blurb": "The fighters are relieved. You lose the publicity.",
			"fx": {"morale": 0.07, "note": -1.0}},
	],
},
{
	"id": "share_venue",
	"who": Who.ANYONE,
	"title": "A rival needs your arena",
	"text": "{rival} lost their arena and want to rent yours for the rest of the year. They will pay, and their fans will come through your gate, but people will say you are propping up a rival.",
	"options": [
		{"label": "Rent it at a fair price", "blurb": "Some rent, and their fans swell your crowd.",
			"fx": {"cc": 5, "fans": 0.08, "note": -1.5}},
		{"label": "Charge them top dollar", "blurb": "Good money. You look greedy and the squad is uneasy.",
			"fx": {"cc": 9, "morale": -0.06, "note": -2.5}},
		{"label": "Say no", "blurb": "Loyal to your own, and you leave money on the table.",
			"fx": {"note": 1.0, "morale": -0.03}},
	],
},
{
	"id": "longer_deal",
	"who": Who.BEST,
	"title": "Contract talk",
	"text": "Two other clubs have been asking about {man}, your best fighter. He wants to know now whether you will extend his contract. If you do, he will want a raise.",
	"options": [
		{"label": "Extend him a year", "blurb": "He stays another season, on about 18% more pay.",
			"fx": {"years": 1, "wage": 1.18, "morale": 0.08}},
		{"label": "Talk after the season", "blurb": "No raise yet, but he and the squad feel brushed off.",
			"fx": {"morale": -0.08}},
	],
},
{
	"id": "marshal",
	"who": Who.ANYONE,
	"title": "The marshal's warning",
	"text": "The head marshal has pulled you aside. {club} has been fighting right at the edge of the rules. Nothing has been penalized yet, but he would rather not have to start.",
	"options": [
		{"label": "Apologize, tone it down", "blurb": "The squad relaxes. Other clubs see you as soft.",
			"fx": {"note": -1.5, "morale": 0.05}},
		{"label": "Back your fighters", "blurb": "The squad loves it and you get a hard reputation. You pay a small fine.",
			"fx": {"cc": -2, "note": 2.0, "morale": 0.09}},
	],
},
{
	"id": "gambesons",
	"who": Who.ANYONE,
	"title": "Worn-out padding",
	"text": "Most of the padding in your kit room is worn thin and older than some of your fighters. A supplier will give you a bulk discount if you order this week.",
	"options": [
		## THE BOOKS HOLD TWELVE, NOT THIRTEEN (3 Oct 2026), so the label says the
		## squad rather than a number that was wrong.
		{"label": "Order for the whole squad", "blurb": "Everybody's padding is new.",
			"fx": {"cc": -7, "kit": 0.16}},
		{"label": "Order for the eight", "blurb": "The traveling squad gets new kit. The reserves feel left out.",
			"fx": {"cc": -4, "kit_eight": 0.08, "morale": -0.05}},
		{"label": "Wait another year", "blurb": "No money spent. The squad is sick of the old kit.",
			"fx": {"morale": -0.08}},
	],
},
{
	"id": "camp_abroad",
	"who": Who.YOUNGEST,
	"title": "Training camp overseas",
	"text": "{man}, your youngest fighter, has been invited to a winter training camp overseas with top international fighters. The club would have to pay for his flights.",
	"options": [
		{"label": "Pay for the trip", "blurb": "He comes back a much better fighter, with a higher ceiling.",
			"fx": {"cc": -5, "potential": 2, "xp": 14}},
		{"label": "Say you can't afford it", "blurb": "He stays home, and the squad thinks you could have paid.",
			"fx": {"morale": -0.10}},
	],
},
{
	"id": "local_paper",
	"who": Who.BEST,
	"title": "The local paper",
	"text": "The local newspaper wants a full-page story on {man}, your best fighter: his day job, his armor, the long drives to events. Good publicity, but rival clubs read the paper too.",
	"options": [
		{"label": "Run the story", "blurb": "Fans come to see him. Rival clubs notice him too, and he may leave sooner.",
			"fx": {"note": 3.0, "fans": 0.04, "years": -1}},
		{"label": "Host them at the club", "blurb": "A friendly day with food laid on. A smaller boost, and it costs a little.",
			"fx": {"cc": -2, "note": 1.5, "fans": 0.02, "morale": 0.05}},
	],
},
{
	"id": "drinking",
	"who": Who.ANYONE,
	"title": "Beer before the bouts",
	"text": "Someone has been bringing a cooler of beer to events, and it's getting opened before the fights, not after. Drinking before you fight in armor is how people get hurt.",
	"options": [
		{"label": "Ban it", "blurb": "A clear rule, enforced. Safer, but the squad is unhappy.",
			"fx": {"morale": -0.11, "kit": 0.04, "note": 1.0}},
		{"label": "Only after the last bout", "blurb": "A compromise everyone can live with.",
			"fx": {"morale": 0.03, "kit": -0.05}},
		{"label": "Leave it alone", "blurb": "The squad is happy. Someone may get hurt.",
			"fx": {"morale": 0.07, "injury": 1}},
	],
},
{
	"id": "charity",
	"who": Who.A_RESERVE,
	"title": "Charity demonstration",
	## REWRITTEN (playtest 30 Sep #8: "makes zero sense for the choices"). Each
	## answer now says what it is and why it costs what it costs.
	"text": "The local hospice wants {club} to put on a fight demonstration at their fundraiser on a free Saturday. Full armor draws a crowd, but it's a long day of real hits.",
	"options": [
		{"label": "Full armored demo", "blurb": "A big crowd and plenty of goodwill. {man} could get hurt.",
			"fx": {"fans": 0.10, "note": 2.0, "injury": 1, "xp": 8}},
		{"label": "Send two to talk", "blurb": "No armor, no risk. Two fighters give up their day off.",
			"fx": {"fans": 0.03, "note": 0.5, "morale": -0.04}},
		{"label": "Decline", "blurb": "The town notices, and the fighters wanted to go.",
			"fx": {"note": -1.5, "morale": -0.04}},
	],
},
{
	"id": "smith_debt",
	"who": Who.WORST_KIT,
	"title": "The unpaid blacksmith",
	"text": "The blacksmith who repairs most of your armor hasn't been paid since spring. He has asked once. He won't ask again; he'll just stop working for you.",
	"options": [
		{"label": "Pay him in full", "blurb": "He starts on your kit room tomorrow.",
			"fx": {"cc": -6, "kit": 0.10, "morale": 0.06}},
		{"label": "Pay half now", "blurb": "It buys some time. He has heard that before.",
			"fx": {"cc": -3, "morale": -0.02}},
		{"label": "Make him wait", "blurb": "He puts his other clubs first. Your kit suffers.",
			"fx": {"morale": -0.09, "kit": -0.05}},
	],
},
{
	## ------------------------------------------------- Beast energy drinks
	## Pete, 3 Oct 2026: three cards about Beast energy drinks — a shipment, a
	## sponsorship, and the argument over the best flavor ("White is the correct
	## answer"). Written in the dilemma-deck doc and loaded from there.
	"id": "beast_shipment",
	"who": Who.ANYONE,
	"weight": 2,
	"tone": Tone.SHADY,
	"title": "A truck full of Beast",
	"text": "A delivery driver has 40 cases of Beast energy drink he says nobody will miss, and he'll leave them at your arena for a handshake. Your fighters would drink them by the gallon. Nobody asks where they came from.",
	"options": [
		{"label": "Stock the locker room", "blurb": "The squad is wired for a month. People wonder how you got them.",
			"fx": {"morale": 0.07, "xp": 6, "note": -1.5}},
		{"label": "Sell them at the gate", "blurb": "Easy money from the crowd. The squad watches it go out the door.",
			"fx": {"cc": 4, "morale": -0.03, "note": -1.0}},
		{"label": "Send the truck away", "blurb": "Clean hands. The squad is crushed.",
			"fx": {"morale": -0.06, "note": 1.0}},
	],
},
{
	"id": "beast_sponsor",
	"who": Who.ANYONE,
	"weight": 2,
	"tone": Tone.CLEAN,
	"title": "Beast wants a sponsor",
	"text": "Beast Energy wants to sponsor {club}: their claw logo on every surcoat, cans at every event, and a cash payment each season. In return they pick your walkout music, and it's loud.",
	"options": [
		{"label": "Sign the full deal", "blurb": "Real money and a big name. The fighters hate the walkout music.",
			"fx": {"cc": 8, "morale": -0.06, "note": 2.0, "fans": 0.05}},
		{"label": "Logo only, no music", "blurb": "Half the money. Some fighters still hate wearing a logo.",
			"fx": {"cc": 4, "morale": -0.02, "note": 1.0}},
		{"label": "Turn them down", "blurb": "The squad keeps its music. You keep drinking your own.",
			"fx": {"morale": 0.03, "note": -1.0}},
	],
},
{
	"id": "beast_flavor",
	"who": Who.ANYONE,
	"weight": 2,
	"title": "The flavor argument",
	"text": "The locker room is split over the best flavor of Beast energy drink. It started as a joke and now two fighters aren't speaking. The squad wants you to settle it, and the club will only stock one.",
	"options": [
		{"label": "White. Obviously.", "blurb": "The correct answer. Peace returns, and white costs a little more.",
			"fx": {"cc": -1, "morale": 0.09}},
		{"label": "Original green", "blurb": "The classic. Half the squad thinks you're wrong.",
			"fx": {"morale": -0.06}},
		{"label": "Let them settle it", "blurb": "They fight it out in sparring. Somebody takes it too far.",
			"fx": {"morale": -0.02, "xp": 6, "injury": 1}},
	],
},
]


## ------------------------------------------------- what an option will cost
## THE EFFECT, IN THE PLAYER'S HAND BEFORE HE TAPS — Pete, 14 Sep 2026, sending
## Retro Bowl's press interview over: each answer there carries an EFFECT box
## under it showing the face it will produce, so choosing is a decision rather
## than a guess.
##
## Ours drew the option's prose `blurb` and the comment above that code claimed
## it drew *"each answer's PRICE under its button"*. It did not. The blurb
## IMPLIES a cost — "All thirteen, done properly" — and implying is what prose is
## for; a number is what a price is for. Both, now: the sentence tells you what
## you are doing and this tells you what it costs.
##
## DELIBERATELY NOT THE WHOLE TRUTH. A card that printed every field of its `fx`
## would be a spreadsheet, and the deck's own charm is that a choice has a shape
## you can read rather than a total you can optimise. So: the money, the room,
## the kit and the name, in that order, and nothing else. What a card does to one
## man's contract or his ceiling stays in the prose where it belongs.
## `kit_eight` is kit on the travelling eight only (3 Oct 2026) and reads as kit.
const FX_SHOWN: Array[String] = ["cc", "morale", "kit", "kit_eight", "note", "fans"]
const FX_WORD := {
	## PLAIN WORDS (playtest 30 Sep #7: "Why not just have Team Morale? Why
	## name and not renown?"). They needed a legend; now they do not.
	"cc": "CC", "morale": "team morale", "kit": "kit", "kit_eight": "kit", "note": "renown", "fans": "crowd",
}


## One short token a field, or an empty array when a card asks nothing of you —
## which is a real answer and should read as one rather than as a missing line.
## Each figure a card's answer will move, in reading order, with the direction it
## moves in. One entry per field: `{"text": "room -5", "dir": -1}`.
##
## IT RETURNS A DIRECTION PER FIGURE rather than one verdict for the row. The
## first version handed the whole line to `tone()` and painted it one color, and
## the shot of the gambeson card showed what that costs: "Just the eight" spends
## four credits, annoys the room and BUYS KIT, and the row printed "kit +8" in
## red because the other two fields outvoted it. A mixed answer is the only kind
## worth thinking about, and a readout that cannot show a mix is a readout that
## lies exactly when the player needs it.
static func costs(option: Dictionary) -> Array[Dictionary]:
	var fx: Dictionary = option.get("fx", {})
	var out: Array[Dictionary] = []
	for key in FX_SHOWN:
		if not fx.has(key):
			continue
		var v: float = float(fx[key])
		if is_zero_approx(v):
			continue
		## CREDITS ARE WHOLE AND EVERYTHING ELSE IS A FRACTION OF A 0-1 SCALE, so
		## the fractions are shown as the change a player can feel rather than as
		## a decimal nobody can price: a tenth of the room is "room -10".
		## CROWD IS A FRACTION TOO (3 Oct 2026): "fans": 0.10 rounded to 0 and
		## the figure never showed on any card.
		var n: int = int(round(v)) if key == "cc" or key == "note" \
			else int(round(v * 100.0))
		if n == 0:
			continue
		out.append({
			"text": "%s %+d" % [UiKit.t(String(FX_WORD[key])), n],
			"dir": 1 if n > 0 else -1,
		})
	return out


static func by_id(id: String) -> Dictionary:
	for c in CARDS:
		if String(c["id"]) == id:
			return c
	return {}


## WHO THE CARD IS ABOUT. Picked by rule rather than at random wherever a rule
## reads better: the harness card should find the man in the worst kit, because
## a card about condemned armor landing on the best-kept fighter in the club
## reads as a game shuffling cards rather than as something happening.
static func pick(who: int, roster: Array, rng: RandomNumberGenerator) -> FighterCard:
	if roster.is_empty():
		return null
	var pool: Array = roster.duplicate()
	match who:
		Who.OLDEST:
			pool.sort_custom(func(a, b): return a.age > b.age)
			return pool[0]
		Who.YOUNGEST:
			pool.sort_custom(func(a, b): return a.age < b.age)
			return pool[0]
		Who.BEST:
			pool.sort_custom(func(a, b): return a.overall() > b.overall())
			return pool[0]
		Who.WORST_KIT:
			pool.sort_custom(func(a, b): return a.armor < b.armor)
			return pool[0]
		Who.A_RESERVE:
			var res: Array = []
			for f in pool:
				if not f.active:
					res.append(f)
			if not res.is_empty():
				return res[rng.randi() % res.size()]
	return pool[rng.randi() % pool.size()]


static func fill(text: String, man: String, club: String, rival: String) -> String:
	## TRANSLATED BEFORE IT IS FILLED, so the key is the card's own text with its
	## {tokens} still in it — every card line reaches the screen through here.
	return UiKit.t(text).replace("{man}", man).replace("{club}", club).replace("{rival}", rival)
