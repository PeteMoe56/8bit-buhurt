class_name OfficeBooks
extends RefCounted
## Methods of `ClubOffice`, moved out of club_office.gd so that file is not one
## three-thousand-line object. Every function takes the ClubOffice as `o`; `ClubOffice`
## keeps a one-line wrapper for each, so callers did not change.




## What each building costs to keep this year. Rounded UP, so no level is ever
## free to hold — a bill of zero is a building that is not really maintained.
static func upkeep_of(build_cost: int) -> int:
	return 0 if build_cost <= 0 else int(ceil(float(build_cost) * ClubOffice.UPKEEP_FRACTION))




static func arena_upkeep(o: ClubOffice) -> int:
	return o.arena.retainer_full() + maxi(1, int(ceil(
		float(Arena.LEVELS[o.arena.level]["cost"]) * ClubOffice.UPKEEP_MARGIN)))




static func facility_upkeep(o: ClubOffice, f: int) -> int:
	var l := o.level(f)
	return 0 if l <= 0 else ClubOffice.upkeep_of(ClubOffice.FACILITY_COST[l - 1])




static func upkeep_bill(o: ClubOffice) -> int:
	var t := o.arena_upkeep()
	for f in o.facilities.keys():
		t += o.facility_upkeep(int(f))
	return t




static func rule_level(o: ClubOffice, r: int) -> int:
	return int(o.compliance.get(r, 0))




static func rule_cost(o: ClubOffice, r: int) -> int:
	return Federation.raise_cost(o.rule_level(r))




static func raise_rule(o: ClubOffice, r: int) -> String:
	if o.rule_level(r) >= Federation.MAX_LEVEL:
		return UiKit.t("%s is already at the top standard.") % UiKit.t(String(Federation.RULE_NAME[r]))
	if o._throttled(ClubOffice.SLOT_RULE):
		return ClubOffice.throttle_word(UiKit.t("the paperwork"))
	var cost := o.rule_cost(r)
	if o.credits < cost:
		return UiKit.t("%s costs %d CC and you have %d.") % [
			UiKit.t(String(Federation.RULE_NAME[r])), cost, o.credits]
	o.spend(cost, ClubOffice.LINE_FEDERATION)
	o.compliance[r] = o.rule_level(r) + 1
	o._mark(ClubOffice.SLOT_RULE)
	return ""




static func compliant(o: ClubOffice) -> bool:
	return Federation.compliant(o.compliance, o.tier)




static func shortfalls(o: ClubOffice) -> Array[String]:
	return Federation.shortfalls(o.compliance, o.tier)




static func federation_upkeep(o: ClubOffice) -> int:
	## Rule by rule, each scaled and rounded on its own — exactly how
	## `pay_upkeep` charges them, so the bill shown is the bill taken.
	var t := 0
	for r in Federation.rules():
		t += o.scaled(int(Federation.UPKEEP[r]) * int(o.compliance.get(r, 0)))
	return t




## MONEY IN, WITH A REASON. Returns the amount so a caller can still read it.
##
## `line` IS THE HEADING IT GOES UNDER and `what` is what actually happened.
## They are different questions: the log wants "Finished 3rd", the books want
## "Prize money", and a screen that groups by the exact wording of an event ends
## up with a ledger of one-line categories nobody can read.
static func take(o: ClubOffice, cc: int, what: String, when_: String = "", line: String = "") -> int:
	if cc == 0:
		return 0
	o.credits += cc
	o.purse_log.push_front({"what": what, "cc": cc, "when": when_})
	while o.purse_log.size() > ClubOffice.PURSE_KEEP:
		o.purse_log.pop_back()
	ClubOffice._book(o.books_in, line if line != "" else what, cc)
	return cc




static func _book(books: Dictionary, line: String, cc: int) -> void:
	books[line] = int(books.get(line, 0)) + cc




## MONEY OUT, WITH A REASON — the mirror of `take()`, and the reason every
## `credits -= x` in this project is now a call.
##
## It does NOT check affordability. Every caller already does, in its own words,
## with its own refusal ("That costs %d CC and you have %d") — and a second check
## here would either duplicate those messages or silently swallow a bug. What
## this does is take the money and write it down.
static func spend(o: ClubOffice, cc: int, line: String) -> int:
	if cc == 0:
		return 0
	o.credits -= cc
	ClubOffice._book(o.books_out, line, cc)
	return cc




## THE YEAR SO FAR, as [{line, cc}] in the order above, biggest headings first
## within the leftovers. `which` is `books_in` or `books_out`.
static func book_rows(books: Dictionary, order: Array[String]) -> Array:
	var out: Array = []
	for line in order:
		if books.has(line) and int(books[line]) != 0:
			out.append({"line": line, "cc": int(books[line])})
	var rest: Array[String] = []
	for k in books.keys():
		if not order.has(String(k)) and int(books[k]) != 0:
			rest.append(String(k))
	rest.sort_custom(func(a, b): return int(books[a]) > int(books[b]))
	for k in rest:
		out.append({"line": k, "cc": int(books[k])})
	return out




static func book_total(books: Dictionary) -> int:
	var t := 0
	for k in books.keys():
		t += int(books[k])
	return t




## CLOSE THE YEAR. Called from the roll-over, once, after every summer payment
## and every summer bill — so `books_last` is a WHOLE season and the open books
## are a season in progress. Two halves of a year in one column would be the
## most misleading table on the screen.
static func close_books(o: ClubOffice) -> void:
	o.books_last = {"in": o.books_in.duplicate(), "out": o.books_out.duplicate()}
	o.books_in = {}
	o.books_out = {}




## What the last event or roll paid, in the club's own words. Empty when nothing
## has been earned yet, which is a true thing to say on day one.
static func purse_lines(o: ClubOffice) -> Array:
	return o.purse_log.duplicate()




static func purse_since(o: ClubOffice, when_: String) -> int:
	var t := 0
	for row in o.purse_log:
		if String(row.get("when", "")) == when_:
			t += int(row["cc"])
	return t




## WHAT THE FEDERATION WANTS TO LET YOU ENTER, billed at the start of a season.
##
## The other direction from what `dues()` used to be. It was members × 1 CC and
## it paid the club — 24.4 credits a season across a career, **58% of all income**
## on the books, which made a standing subscription the biggest earner in a game
## about fighting. Now it is a cost, it scales with the division, and a club can
## go into the red paying it.
static func dues(o: ClubOffice) -> int:
	return o.scaled(League.dues_for(o.tier))




static func boost_cost(o: ClubOffice) -> int:
	return ClubOffice.BOOST_COST




static func can_boost(o: ClubOffice) -> bool:
	return o.credits >= ClubOffice.BOOST_COST and not o.done_this_week(ClubOffice.SLOT_BOOST)




## THE OFFICE HOLDS THE MONEY AND THE THROTTLE; the SEASON holds the men. This
## returns whether the money and the week were there, and `Season.boost_morale`
## does the lifting — same division of labour as the captain's arrival traits.
static func take_boost(o: ClubOffice) -> String:
	if o.done_this_week(ClubOffice.SLOT_BOOST):
		return ClubOffice.throttle_word(UiKit.t("the club"))
	if o.credits < ClubOffice.BOOST_COST:
		return UiKit.t("A night out costs %d CC and you have %d.") % [ClubOffice.BOOST_COST, o.credits]
	o.spend(ClubOffice.BOOST_COST, ClubOffice.LINE_CLUB)
	o._mark(ClubOffice.SLOT_BOOST)
	return ""




static func refresh_staff(o: ClubOffice) -> String:
	if o.credits < ClubOffice.REFRESH_COST:
		return UiKit.t("Putting the word out costs %d CC and you have %d.") % [ClubOffice.REFRESH_COST, o.credits]
	o.spend(ClubOffice.REFRESH_COST, ClubOffice.LINE_CLUB)
	o.staff_refreshes += 1
	return ""




static func refresh_market(o: ClubOffice) -> String:
	if o.credits < ClubOffice.REFRESH_COST:
		return UiKit.t("Putting the word out costs %d CC and you have %d.") % [ClubOffice.REFRESH_COST, o.credits]
	o.spend(ClubOffice.REFRESH_COST, ClubOffice.LINE_CLUB)
	o.market_refreshes += 1
	return ""




static func travel_cost(o: ClubOffice) -> int:
	var step := o.travel_slots - ClubOffice.TRAVEL_START
	if step < 0 or step >= ClubOffice.TRAVEL_COST.size():
		return 0
	return int(ClubOffice.TRAVEL_COST[step])




static func buy_travel_slot(o: ClubOffice) -> String:
	if o.travel_slots >= ClubOffice.TRAVEL_MAX:
		return UiKit.t("You can already take a full eight.")
	if o._throttled(ClubOffice.SLOT_TRAVEL):
		return ClubOffice.throttle_word(UiKit.t("the travel budget"))
	var cost := o.travel_cost()
	if o.credits < cost:
		return UiKit.t("Another place costs %d CC and you have %d.") % [cost, o.credits]
	o.spend(cost, ClubOffice.LINE_TRAVEL)
	o.travel_slots += 1
	o._mark(ClubOffice.SLOT_TRAVEL)
	return ""
