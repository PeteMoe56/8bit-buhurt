class_name MeleeClub
extends Resource
## A club and the five it fields.
##
## A CLUB'S MARK IS LOAD-BEARING, not decoration. It has to be read across a
## field, through dust, at speed — which is the same problem as reading a 5v5 on
## a phone. The heraldry vocabulary this used to carry (charges, tinctures, the
## metal-on-colour rule) was retired on 10 Sep 2026 at Pete's word; what survives
## is the reason it worked, as a measured contrast rule in IconBank.
##
## The mark itself is an id into `IconBank.ICONS`, not an enum, because the bank
## grows with asset packs and an enum does not.

@export var display_name: String = "Club"
@export var short_name: String = "CLB"
@export var kit: Color = Color("2a5caa")
@export var icon_colour: Color = Color("f4f4e8")
@export var icon: int = 4
@export var roster: Array[FighterCard] = []


## The five, ordered Rail · Flanker · Center · Flanker · Rail.
## Roster order is the depth chart: the first available man listed at a slot
## holds it. A slot nobody is listed for is filled by the first available man of
## the same ROLE — a Rail covers the other Rail — and only then by whoever is
## left, which is where the out-of-position cost starts applying.
##
## Without the role fallback a club of eight could not put five men out after
## losing one starter, because the bench carries one man per role and not one
## per slot: drop the right-hand Rail and `starting_five()` quietly returned
## four men, which every caller downstream treats as a legal line.
func starting_five() -> Array:
	var out: Array = []
	var taken: Array = []
	var eight := active_eight()
	for slot in 5:
		var pick: FighterCard = null
		for f in eight:
			if f.fit() and not taken.has(f) and int(f.pos) == slot:
				pick = f
				break
		if pick == null:
			for f in eight:
				if f.fit() and not taken.has(f) and Tuning.covers(int(f.pos), slot):
					pick = f
					break
		if pick == null:
			for f in eight:
				if f.fit() and not taken.has(f):
					pick = f
					break
		if pick == null:
			return out
		taken.append(pick)
		out.append(pick)
	return out


## Does the mark read against the kit? Asked of IconBank rather than answered
## here, so every club in the world is judged by one function.
func contrast_legal() -> bool:
	return IconBank.contrast_ok(kit, icon_colour)


## Every line position filled exactly once, and the badge readable.
func line_legal() -> String:
	var five := starting_five()
	if five.size() != 5:
		return "%s does not have all five line positions filled." % display_name
	if not contrast_legal():
		return "%s's mark does not read against its kit." % display_name
	## AGAINST THE PARTY THIS CLUB CAN TAKE, and against the books — the two rules
	## that are actually rules. The reserve count is whatever is left between them.
	var eight := active_eight()
	if eight.size() != party_size():
		return "%s takes %d fighters to an event; it holds %d places." % [
			display_name, eight.size(), party_size()]
	if roster.size() > SQUAD_MAX:
		return "%s carries %d on the books; the limit is %d." % [
			display_name, roster.size(), SQUAD_MAX]
	return ""


static func build(
	name_: String, short: String, kit_: Color, icon_col: Color, icon_: int,
	cards: Array[FighterCard]
) -> MeleeClub:
	var c := MeleeClub.new()
	c.display_name = name_
	c.short_name = short
	c.kit = kit_
	c.icon_colour = icon_col
	c.icon = icon_
	c.roster = cards
	return c


# ------------------------------------------------------------------- the bench
# --------------------------------------------------------------- the squad
## THE FIGHTING EIGHT AND THE RESERVE — Pete, 10 Sep 2026.
##
## Eight men travel: five on the line and three on the bench, and the bench is
## what you swap from between rounds. Behind them a club may carry **five more
## in reserve**, who never appear at an event at all — *"they will only appear
## outside of the fights/events in the roster menu."* You train them, outfit
## them, sign and cut them, and promote them onto the eight when they are ready.
##
## The split is what makes a roster menu worth opening. A single flat list makes
## every signing an immediate first-team decision; a reserve list lets you carry
## a man who is not ready yet, which is the whole shape of running a club.
##
## Reserves do NOT count toward club power. They are not at the event, so they
## cannot be what the league rates you on — the fighting eight is.
## Five on the line, and it is the floor of everything: you can buy fewer bench
## men than this, you cannot buy fewer fighters than a line.
const LINE_SIZE: int = 5
const ACTIVE_SIZE: int = 8
const BENCH_SIZE: int = ACTIVE_SIZE - 5
const RESERVE_SIZE: int = 5
const SQUAD_MAX: int = ACTIVE_SIZE + RESERVE_SIZE

## Kept under the old name because the fixtures and the tests read it: the
## number of men who go to an event.
const ROSTER_SIZE: int = ACTIVE_SIZE

## HOW MANY YOU CAN ACTUALLY TAKE.
##
## DIRECTION §4 replaces the salary cap with *"how many bodies you can put on a
## plane and how many harnesses you own that pass inspection"*, and this is the
## first half. A club does not start with a bench — it starts with a line and
## nothing behind it, and every man beyond the fifth is bought.
##
## It defaults to the full eight so that every fixture club, every test and every
## exhibition behaves exactly as it did. Only the player's club has it lowered,
## by `Season.sync_power()`, off `ClubOffice.travel_slots`.
var travel_cap: int = ACTIVE_SIZE


## HOW MANY THIS CLUB CAN ACTUALLY TAKE, clamped once, here.
##
## Every loop that fills a squad used to count against the constant `ACTIVE_SIZE`
## and stop at eight. The moment a club could take fewer than eight, `while
## active_eight().size() < ACTIVE_SIZE` became a loop with no exit: promoting a
## reserve could not move a number the cap was holding down. It hung the whole
## test suite with no output, which is the most expensive kind of infinite loop
## to find.
##
## So the target is a function, and the loops ask the club how many it can take
## rather than asking the constant how many a full club takes.
func party_size() -> int:
	return clampi(travel_cap, LINE_SIZE, ACTIVE_SIZE)


## The men who travel, in roster order — which is the depth chart.
func active_eight() -> Array:
	var cap := party_size()
	var out: Array = []
	for f in roster:
		if f.active:
			out.append(f)
		if out.size() >= cap:
			break
	return out


## Everyone on the books who is not at the event.
func reserves() -> Array:
	var eight := active_eight()
	var out: Array = []
	for f in roster:
		if not eight.has(f):
			out.append(f)
	return out


## THE EIGHT IS ALWAYS EIGHT. Every one of these refuses rather than leaving a
## club that cannot travel or cannot field a line — a roster menu that lets you
## build an illegal squad is a menu that will, and the failure does not surface
## until you are standing at an event two hours later.
##
## The first pass let each verb do the locally reasonable thing, and both of the
## obvious ones were wrong: demoting the Center was allowed because the bench
## Center covers his slot, and cutting him was allowed for the same reason. Both
## left seven men on the travelling list, which is not a club. **A rule about
## the whole squad cannot be enforced one fighter at a time.**


## Promote a reserve onto an eight that is short — after a cut, or on a squad
## that was built incomplete. To CHANGE a full eight, use `swap_squad`.
func set_active(card: FighterCard, on: bool) -> String:
	if not roster.has(card):
		return "%s is not on this club's books." % card.display_name
	if on:
		if card.active:
			return ""
		if active_eight().size() >= ACTIVE_SIZE:
			return "The eight is full. Swap him for somebody already on it."
		card.active = true
		return ""
	if not card.active:
		return ""
	if active_eight().size() <= ACTIVE_SIZE:
		return "The eight is always eight. Swap %s for somebody in the reserve." % card.display_name
	if reserves().size() >= RESERVE_SIZE:
		return "The reserve is full at %d. Cut somebody first." % RESERVE_SIZE
	card.active = false
	return ""


## The one move that changes a full eight: one down, one up, together. Doing it
## as a demote and then a promote cannot work, because the eight is never
## allowed to be seven in between.
func swap_squad(out_card: FighterCard, in_card: FighterCard) -> String:
	if not roster.has(out_card) or not roster.has(in_card):
		return "Both fighters must be on this club's books."
	if not out_card.active or in_card.active:
		return "Take one off the eight and bring one up from the reserve."
	out_card.active = false
	in_card.active = true
	if starting_five().size() != 5:
		out_card.active = true
		in_card.active = false
		return "That leaves the eight unable to fill all five positions."
	return ""


## Sign a man into the reserve.
func sign(card: FighterCard) -> String:
	if roster.size() >= SQUAD_MAX:
		return "The books are full at %d. Cut somebody first." % SQUAD_MAX
	## ONE LIMIT ON THE BOOKS, AND IT IS THE LINE ABOVE.
	##
	## There was a second gate here — "the reserve is full at 5" — and it was a
	## derived fact dressed up as a rule. With a full eight travelling, thirteen on
	## the books means five in reserve and the two statements agree; the day a
	## club's travelling party became a thing it BUYS, they came apart. A club
	## taking six has seven men not travelling, so it was permanently over a
	## reserve limit that no longer described anything, and could not sign a single
	## man from any source at all — the free-agent list refused every signing.
	##
	## `SQUAD_MAX` is the real rule and it is checked above. How those men split
	## between the bus and the clubhouse is a consequence of the cap, not a second
	## thing to enforce.
	##
	## And `active` is decided against what this club can actually TAKE. Against
	## the constant eight, a club with six places marked its seventh and eighth
	## signings as travelling — men flagged for a bus they can never board, which
	## surfaced as a trialist walking straight into a line he was not in.
	card.active = active_eight().size() < party_size()
	roster.append(card)
	return ""


## You cut from the reserve. To release a man who is on the eight, swap him down
## for a reserve first — which forces you to name his replacement, and is the
## whole reason you cannot accidentally travel with seven.
func cut(card: FighterCard) -> String:
	var i := roster.find(card)
	if i == -1:
		return "%s is not on this club's books." % card.display_name
	if card.active:
		return "%s is on the eight. Swap him into the reserve first." % card.display_name
	roster.remove_at(i)
	return ""


## Everyone available who is not on the line.
func bench() -> Array:
	var five := starting_five()
	var out: Array = []
	for f in active_eight():
		if f.fit() and not five.has(f):
			out.append(f)
	return out


# ------------------------------------------------------------------- the rating
## CLUB POWER IS THE CLUB, NOT THE STARTER LEVELS. Pete, 10 Sep 2026 — and it is
## worked out the way Madden and FIFA work it out: **each position gets a rating,
## and the club rating is the average of those.** His words: *"it's just an
## average from position averages."*
##
## That is a better model than a flat squad average for the reason every sports
## game already knows — it makes a hole somewhere specific cost you. Five men
## averaging 70 with nobody behind the Center is not the same club as five men
## averaging 70 with a Center who can be spelled, and a flat average cannot tell
## them apart.
##
## A position's rating is its starter, plus whoever actually covers him:
##
##   * a man on the bench listed at the same ROLE covers at full value — a Rail
##     is a Rail whichever side of the list he stands on
##   * otherwise your best bench man covers, at the out-of-position cost, which
##     is the same 6% the sim charges him if you really do put him there
##   * with nobody on the bench at all, cover is the starter at 70% — because
##     "he plays all three rounds and nobody spells him" is the honest reading
##
## Kit rides inside each man's own rating rather than sitting on the outside as
## a club-wide fudge: harness condition already costs him base, so a fighter in
## rattling armor is simply a worse fighter, and it reaches the table by the same
## road as everything else.
const BACKUP_WEIGHT: float = 0.20
const NO_COVER: float = 0.70


## What one place on the line is worth: the starter, and his cover.
func position_rating(slot: int) -> float:
	var five := starting_five()
	if slot < 0 or slot >= five.size():
		return 0.0
	var starter: FighterCard = five[slot]
	var start_r := starter.rating()

	var cover := -1.0
	var best_any := -1.0
	for f in bench():
		var r: float = f.rating()
		if Tuning.covers(int(f.pos), slot) and r > cover:
			cover = r
		if r > best_any:
			best_any = r
	if cover < 0.0:
		cover = best_any * Tuning.OUT_OF_POS if best_any >= 0.0 else start_r * NO_COVER

	return start_r * (1.0 - BACKUP_WEIGHT) + cover * BACKUP_WEIGHT


func power() -> int:
	return int(round(power_exact()))


## The same number before rounding. The league only ever wants the integer, but a
## test that asks whether selling a man costs you anything needs to see a change
## smaller than a whole point — otherwise it reports "no effect" for an effect
## that is simply below the rounding.
func power_exact() -> float:
	var five := starting_five()
	## A club that cannot put five men on the line has no rating. It does not get
	## an average of the four it has — it forfeits.
	if five.size() != 5:
		return 0.0
	var total := 0.0
	for slot in five.size():
		total += position_rating(slot)
	return total / float(five.size())


## The depth chart, for the corner screen: each place on the line, who holds it,
## who covers it, and what the position is worth.
func depth_chart() -> Array:
	var five := starting_five()
	var out: Array = []
	for slot in five.size():
		var cover: FighterCard = null
		var best_any: FighterCard = null
		for f in bench():
			if Tuning.covers(int(f.pos), slot) and (cover == null or f.rating() > cover.rating()):
				cover = f
			if best_any == null or f.rating() > best_any.rating():
				best_any = f
		out.append({
			"slot": slot,
			"position": Tuning.pos_name(slot),
			"starter": five[slot],
			"cover": cover if cover != null else best_any,
			"cover_out_of_position": cover == null and best_any != null,
			"rating": position_rating(slot),
		})
	return out
