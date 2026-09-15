extends SceneTree
## IS THERE A RIGHT ANSWER?
##
## The rule the deck is built on is that there is not one: every option has to
## cost something, so the choice is always which currency you would rather spend.
## A card with a free option is a quiz, and a player solves a quiz once and then
## stops reading.
##
## That rule is easy to state and easy to break by accident — a card written in
## one sitting, an effect that reads well and nets out positive, an option whose
## only cost is a number nothing consumes. So this sweeps the whole deck and
## prints what every answer actually costs, then plays two seasons of one policy
## against the other to see whether always taking the money beats always taking
## the room.

func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the deck ===\n")
	_audit()
	_policies()
	print("")
	quit(0)


## WHAT DOES NOTHING? An option with no cost at all is the bug; an option whose
## costs are all in one currency is a weaker version of the same bug, because
## then it is comparable by arithmetic to its neighbours.
func _audit() -> void:
	var free_options: Array[String] = []
	var one_currency: Array[String] = []
	print("card              option                     costs")
	for card in Dilemma.CARDS:
		var opts: Array = card["options"]
		for o in opts:
			var fx: Dictionary = o.get("fx", {})
			var costs: Array[String] = []
			var gains: Array[String] = []
			for k in fx.keys():
				var v: float = float(fx[k])
				## `injury` and `wage` are costs whichever way they point: a man
				## out is a man out, and a raise is money.
				var bad: bool = v < 0.0 or String(k) == "injury" \
					or (String(k) == "wage" and v > 1.0)
				if bad:
					costs.append(String(k))
				else:
					gains.append(String(k))
			print("%-17s %-26s %s" % [String(card["id"]), String(o["label"]),
				("NOTHING" if costs.is_empty() else ", ".join(costs))])
			if costs.is_empty():
				free_options.append("%s / %s" % [card["id"], o["label"]])
			elif costs.size() + gains.size() < 2:
				one_currency.append("%s / %s" % [card["id"], o["label"]])
	print("")
	print("  %d cards, %d options" % [Dilemma.CARDS.size(), _count_options()])
	if free_options.is_empty():
		print("  every option costs something")
	else:
		print("  FREE OPTIONS (each one is a right answer, which is the bug):")
		for f in free_options:
			print("    " + f)
	if not one_currency.is_empty():
		## These are the REFUSALS — "another year", "we cannot", "after the
		## season" — and costing one thing and gaining nothing is exactly right
		## for them. Listed rather than flagged, because a card whose do-nothing
		## option costs nothing IS a bug and this is how you would spot it.
		print("  refusals (cost only, gain nothing — correct for a do-nothing answer):")
		for f in one_currency:
			print("    " + f)
	print("")


static func _count_options() -> int:
	var n := 0
	for c in Dilemma.CARDS:
		n += (c["options"] as Array).size()
	return n


## AND THE SAME QUESTION FROM THE OTHER END. If one blunt policy dominates every
## other over a career, the deck has a right answer even though no single card
## does.
func _policies() -> void:
	print("Three seasons of one blunt policy, ten years each")
	print("policy                  power  morale  notoriety  fans     CC")
	for policy in [["always the money", 0], ["always the room", 1],
			["always the last option", 2]]:
		_play(String(policy[0]), int(policy[1]))


func _play(label: String, mode: int) -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260910)
	s.office.facilities[ClubOffice.Facility.TRAINING] = 3
	s.office.hire(ClubOffice.captain("A", Tuning.Role.RAIL, Tuning.Role.FLANK))
	s.office.hire(ClubOffice.captain("B", Tuning.Role.CENTER, Tuning.Role.RAIL))
	var seen := 0
	for _y in 10:
		var guard := 0
		while not s.ready_to_roll() and guard < 120:
			guard += 1
			if not s.dilemma.is_empty():
				seen += 1
				s.answer_dilemma(_choose(s, mode))
			elif s.bid_open(): s.decline_bid()
			elif s.cup_pending(): s.sim_cup_tie()
			else: s.skip_event()
		for f in s.club.roster.duplicate():
			if f.years <= 0:
				s.resign(f)
		s.roll_over()
	print("%-22s %6d %7.2f %10.1f %6d %6d" % [label, s.club.power(), s.office.morale,
		s.office.notoriety, int(s.office.fans), s.office.credits])


## mode 0: whichever option gains the most credits. 1: whichever gains the most
## morale. 2: the last one, as a control that is not optimising anything.
func _choose(s: Season, mode: int) -> int:
	var card := s.dilemma_card()
	var opts: Array = card.get("options", [])
	if opts.is_empty():
		return 0
	if mode == 2:
		return opts.size() - 1
	var best := 0
	var best_v := -999.0
	for i in opts.size():
		var fx: Dictionary = (opts[i] as Dictionary).get("fx", {})
		var v: float = float(fx.get("cc", 0)) if mode == 0 else float(fx.get("morale", 0.0)) * 100.0
		if v > best_v:
			best_v = v
			best = i
	return best
