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
##   notoriety which fills the seats
##   fans      the following itself
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


## What an option does. Absent keys do nothing, so a card only writes what it
## changes and a reader can see the whole cost of an answer in one line.
##   cc         credits, + or -
##   morale     -1..1, added
##   note       notoriety, added
##   fans       a FRACTION of the current following, added
##   armor      to {man}, added (0-1)
##   kit        to every man on the books, added
##   injury     events {man} sits out
##   xp         to {man}
##   potential  to {man}'s ceiling
##   years      to {man}'s deal
const CARDS: Array[Dictionary] = [
{
	"id": "harness",
	"who": Who.WORST_KIT,
	"title": "Condemned at the gate",
	"text": "The marshal has looked at {man}'s harness and will not pass it. There is a smith in the car park who will work through the morning for a price.",
	"options": [
		{"label": "Pay the smith", "blurb": "Straight back on the line, at a price.",
			"fx": {"cc": -3, "armor": 0.30}},
		{"label": "Borrow a club spare", "blurb": "It fits nobody. He will fight in it anyway.",
			"fx": {"armor": 0.10, "morale": -0.05}},
		{"label": "He sits out", "blurb": "One event, and the eight covers.",
			"fx": {"injury": 1, "morale": -0.03}},
	],
},
{
	"id": "two_clubs",
	"who": Who.ANYONE,
	"title": "Two shirts",
	"text": "{man} has been fighting for somebody else on the weekends {club} is not out. Nobody has broken a rule. Everybody has noticed.",
	"options": [
		{"label": "Fine him", "blurb": "It is in the agreement he signed.",
			"fx": {"cc": 2, "morale": -0.09}},
		{"label": "Have a word", "blurb": "Quietly, and once.",
			"fx": {"morale": -0.02, "xp": 4}},
		{"label": "Let him get on with it", "blurb": "More mat time is more mat time.",
			"fx": {"morale": 0.06, "xp": 12, "injury": 1}},
	],
},
{
	"id": "brewery",
	"who": Who.ANYONE,
	"title": "A name on the rail",
	"text": "A brewery two towns over will pay to put its name along the rail. It is not a lot of money and it is not a small banner.",
	"options": [
		{"label": "Take the money", "blurb": "It pays for a season of harness repairs.",
			"fx": {"cc": 6, "note": 1.5, "morale": -0.07}},
		{"label": "Turn it down", "blurb": "{club} is not an advert.",
			"fx": {"morale": 0.06, "note": -0.5}},
	],
},
{
	"id": "carpark",
	"who": Who.ANYONE,
	"title": "After the bout",
	"text": "Something happened in the car park after {rival}. {man} was in the middle of it and is not saying much.",
	"options": [
		{"label": "Report it yourself", "blurb": "Before somebody else does.",
			"fx": {"note": -2.0, "morale": 0.08}},
		{"label": "Say nothing", "blurb": "It will be around the circuit by Tuesday either way.",
			"fx": {"note": 2.5, "morale": -0.10}},
	],
},
{
	"id": "veterans_place",
	"who": Who.OLDEST,
	"title": "The old man's place",
	"text": "{man} has asked to come off the eight so one of the young lads can travel. He means it. He is also still one of the better fighters here.",
	"options": [
		{"label": "Take him up on it", "blurb": "The reserve learns more in one event than in a winter.",
			"fx": {"morale": 0.10, "years": -1}},
		{"label": "He is still needed", "blurb": "The young man can wait a year.",
			"fx": {"morale": -0.05, "xp": 10}},
	],
},
{
	"id": "film_crew",
	"who": Who.ANYONE,
	"title": "Somebody with a camera",
	"text": "A crew making something about the sport wants to follow {club} for the rest of the season. They want access to everything, including the bad weeks.",
	"options": [
		{"label": "Let them in", "blurb": "People will hear of us.",
			"fx": {"note": 5.0, "fans": 0.05, "morale": -0.12}},
		{"label": "Training only", "blurb": "A compromise nobody likes.",
			"fx": {"note": 2.0, "morale": -0.04}},
		{"label": "No", "blurb": "The lads have jobs.",
			"fx": {"morale": 0.07, "note": -1.0}},
	],
},
{
	"id": "share_venue",
	"who": Who.ANYONE,
	"title": "Sharing a hall",
	"text": "{rival} have lost their ground and have asked to share yours for the rest of the year. They will pay their way.",
	"options": [
		{"label": "Let them in", "blurb": "Their people will come through your gate.",
			"fx": {"cc": 5, "fans": 0.08, "note": -1.5}},
		{"label": "Charge them properly", "blurb": "Business is business.",
			"fx": {"cc": 9, "morale": -0.06, "note": -2.5}},
		{"label": "No room", "blurb": "It is our hall.",
			"fx": {"note": 1.0, "morale": -0.03}},
	],
},
{
	"id": "longer_deal",
	"who": Who.BEST,
	"title": "A word about the paperwork",
	"text": "{man} has been asked about by two other clubs and would like to know where he stands. He is not asking for much. He is asking now.",
	"options": [
		{"label": "Give him the year", "blurb": "And the raise that comes with it.",
			"fx": {"years": 1, "wage": 1.18, "morale": 0.08}},
		{"label": "After the season", "blurb": "Nothing is decided in October.",
			"fx": {"morale": -0.08}},
	],
},
{
	"id": "marshal",
	"who": Who.ANYONE,
	"title": "The marshal wants a word",
	"text": "About how {club} has been fighting. Nothing has been called, and he would rather not have to call it.",
	"options": [
		{"label": "Apologise and rein it in", "blurb": "Quiet season, quiet club.",
			"fx": {"note": -1.5, "morale": 0.05}},
		{"label": "Stand by the lads", "blurb": "It is a contact sport.",
			"fx": {"cc": -2, "note": 2.0, "morale": 0.09}},
	],
},
{
	"id": "gambesons",
	"who": Who.ANYONE,
	"title": "The gambeson order",
	"text": "Half the padding in the kit room is older than half the club. There is a bulk price if the order goes in this week.",
	"options": [
		{"label": "Kit everybody out", "blurb": "All thirteen, done properly.",
			"fx": {"cc": -7, "kit": 0.16}},
		{"label": "Just the eight", "blurb": "The reserve can wait.",
			"fx": {"cc": -4, "kit": 0.08, "morale": -0.05}},
		{"label": "Another year", "blurb": "It has lasted this long.",
			"fx": {"morale": -0.08}},
	],
},
{
	"id": "camp_abroad",
	"who": Who.YOUNGEST,
	"title": "A winter away",
	"text": "{man} has been invited to train abroad for the winter with people who are much better than anybody here. It would cost {club} his flights.",
	"options": [
		{"label": "Pay his way", "blurb": "He comes back a different fighter.",
			"fx": {"cc": -5, "potential": 2, "xp": 14}},
		{"label": "We cannot", "blurb": "And he knows the club could have.",
			"fx": {"morale": -0.10}},
	],
},
{
	"id": "local_paper",
	"who": Who.BEST,
	"title": "The local paper",
	"text": "They want a full page on {man} — the job, the harness, the drive to events. He is not sure. The photographer is already booked.",
	"options": [
		{"label": "Put him forward", "blurb": "People turn up to watch a name. Other clubs read papers too.",
			"fx": {"note": 3.0, "fans": 0.04, "years": -1}},
		{"label": "Host them at the club", "blurb": "A day off the kit room and a spread laid on.",
			"fx": {"cc": -2, "note": 1.5, "fans": 0.02, "morale": 0.05}},
	],
},
{
	"id": "drinking",
	"who": Who.ANYONE,
	"title": "The back of the van",
	"text": "There is a cool box going to events that is not full of water, and it is going out before the fighting rather than after.",
	"options": [
		{"label": "Stop it", "blurb": "Written down, and enforced.",
			"fx": {"morale": -0.11, "kit": 0.04, "note": 1.0}},
		{"label": "After the last bout only", "blurb": "A line everybody can live with.",
			"fx": {"morale": -0.03}},
		{"label": "Leave it", "blurb": "They are grown men.",
			"fx": {"morale": 0.07, "injury": 1}},
	],
},
{
	"id": "charity",
	"who": Who.A_RESERVE,
	"title": "A show for the hospice",
	"text": "A charity in town wants a demonstration on a Saturday between fixtures. It is free to put on and it is a long day in harness.",
	"options": [
		{"label": "Put a show on", "blurb": "Hard week, full hall.",
			"fx": {"fans": 0.10, "note": 2.0, "injury": 1, "xp": 8}},
		{"label": "Send two lads to talk", "blurb": "No harness, no risk, and everyone knows it.",
			"fx": {"fans": 0.03, "note": 0.5, "morale": -0.04}},
		{"label": "Not this month", "blurb": "The fixture list is the fixture list.",
			"fx": {"note": -1.5, "morale": -0.04}},
	],
},
{
	"id": "smith_debt",
	"who": Who.WORST_KIT,
	"title": "The armourer's bill",
	"text": "The smith who keeps half this club standing up has not been paid since the spring. He has not asked twice. He will not ask a third time.",
	"options": [
		{"label": "Settle it in full", "blurb": "And he starts on the kit room tomorrow.",
			"fx": {"cc": -6, "kit": 0.10, "morale": 0.06}},
		{"label": "Half now", "blurb": "He has heard that before.",
			"fx": {"cc": -3, "morale": -0.02}},
		{"label": "It will have to wait", "blurb": "He works for two other clubs.",
			"fx": {"morale": -0.09, "kit": -0.05}},
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
const FX_SHOWN: Array[String] = ["cc", "morale", "kit", "note", "fans"]
const FX_WORD := {
	"cc": "CC", "morale": "room", "kit": "kit", "note": "name", "fans": "crowd",
}


## One short token a field, or an empty array when a card asks nothing of you —
## which is a real answer and should read as one rather than as a missing line.
## Each figure a card's answer will move, in reading order, with the direction it
## moves in. One entry per field: `{"text": "room -5", "dir": -1}`.
##
## IT RETURNS A DIRECTION PER FIGURE rather than one verdict for the row. The
## first version handed the whole line to `tone()` and painted it one colour, and
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
		var n: int = int(round(v)) if key == "cc" or key == "note" or key == "fans" \
			else int(round(v * 100.0))
		if n == 0:
			continue
		out.append({
			"text": "%s %+d" % [String(FX_WORD[key]), n],
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
## a card about condemned armour landing on the best-kept fighter in the club
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
	return text.replace("{man}", man).replace("{club}", club).replace("{rival}", rival)
