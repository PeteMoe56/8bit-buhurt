class_name SeasonDesk
extends RefCounted
## Methods of `Season`, moved out of season.gd so that file is not one
## three-thousand-line object. Every function takes the Season as `s`; `Season`
## keeps a one-line wrapper for each, so callers did not change.




## LETTING HIM GO NOW PAYS. Pete, 15 Sep 2026, on the one thread the tier work
## left open: *"let's go with Retro Bowl's answer"* — and then *"let's go with
## Trade instead of sell."* Theirs returns a draft pick in one of three coarse
## buckets; ours returns credits on the same three — see `Market.trade_value` for
## why the buckets are the fee bands collapsed in pairs rather than a second
## scale, and for why the word is theirs.
##
## ONE DOOR AND NOT TWO. Retro Bowl separates cutting a man from trading him, and
## that split does not survive the trip: it only exists because a trade needs a
## partner who wants him, and ours is a league of clubs who always do. A man
## nobody wants is worth the bottom bucket, which at the Backyard Circuit is
## nothing — so "worthless" is expressed as a price rather than as a second
## button that does nearly the same thing, and the label reads "Cut" when there
## is no money in it.
static func release(s: Season, f: FighterCard) -> String:
	var was_toxic: bool = f.toxic()
	var paid := s.trade_value(f)
	var err := s.club.cut(f)
	if err != "":
		return err
	## A man let go is nobody's prospect: the winter would bank a gain on a
	## card that has left the club (29 Sep 2026).
	if s.prospect == f:
		s.prospect = null
	if paid > 0:
		s.office.take(paid, UiKit.t("%s traded") % f.display_name,
			UiKit.t("season %d") % s.world.season, ClubOffice.LINE_TRANSFER)
	for other in s.club.active_eight():
		other.morale_shift(Season.CUT_TOXIC if was_toxic else Season.CUT_LIKED)
	s.office.sync_morale(s.club)
	s.sync_power()
	return ""




## Did the club finish in a promotion place, with somewhere to be promoted to?
static func promotion_place(s: Season) -> bool:
	if not s.season_complete():
		return false
	var t := s.world.player_tier()
	if t >= League.TIERS.size() - 1:
		return false                      ## nothing above the National Division
	var p := s.position()
	return p >= 1 and p <= int(League.TIERS[t]["up"])




static func promotion_offered(s: Season) -> bool:
	return s.promotion_place() and not s.promotion_answered




## WHAT IT WOULD COST TO GO UP, for the screen — the two bills side by side,
## because that is the whole decision and a player should not have to go and find
## the number on another page.
static func promotion_terms(s: Season) -> Dictionary:
	var t := s.world.player_tier()
	var up := mini(t + 1, League.TIERS.size() - 1)
	return {
		"from": League.tier_name(t),
		"to": League.tier_name(up),
		"dues_now": s.office.scaled(League.dues_for(t)),
		"dues_up": s.office.scaled(League.dues_for(up)),
		"in_hand": s.office.credits,
		## THE GROUND THE DIVISION ABOVE WILL PLAY IN (#13).
		"arena_ok": s.office.arena.fit_for(up),
		"arena_need": Arena.arena_name_of(Arena.level_for_tier(up)),
		"arena_have": s.office.arena.arena_name(),
	}




## Take it or leave it. Returns "" like every other verb here.
static func answer_promotion(s: Season, take: bool) -> String:
	if not s.promotion_place():
		return UiKit.t("There is nothing to decide.")
	## No ground, no promotion (#13). The question stays open, so a club can
	## build the ground now and then take the place — or turn it down.
	var up := mini(s.world.player_tier() + 1, League.TIERS.size() - 1)
	if take and not s.office.arena.fit_for(up):
		return UiKit.t("The %s won't fight in a %s. Build a %s first.") % [
			League.tier_name(up), s.office.arena.arena_name(),
			Arena.arena_name_of(Arena.level_for_tier(up))]
	s.promotion_answered = true
	s.world.stay_down = not take
	s.last_promotion_choice = take
	return ""




static func _draw_dilemma(s: Season) -> void:
	if not s.dilemma.is_empty() or s.club.roster.is_empty():
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
	rng.seed = hash("deck:%d:%d:%d" % [s.world.rng.seed, s.world.season, s.world.event])
	if rng.randf() > Season.DILEMMA_CHANCE:
		return
	## THE DECK IS THE COACH'S, and it is weighted.
	##
	## Pete, 15 Sep 2026: *"make Coaches reputation a driving factor on what
	## appears for the conflicts or choices. Better reputations mean better
	## choices, but bad reputations can also mean more choices that have chances
	## for cheating or subversion."* `Dilemma.deck_for` does the filtering; the
	## weighted draw below is what makes the armorer's van rare without a second
	## deck to keep in step.
	var deck: Array = Dilemma.deck_for(s.coach.reputation)
	var options: Array = []
	for c in deck:
		if not s.dilemma_recent.has(String(c["id"])):
			options.append(c)
	if options.is_empty():
		options = deck.duplicate()
	if options.is_empty():
		return
	var total := 0
	for c in options:
		total += Dilemma.weight_of(c)
	var roll := rng.randi() % maxi(1, total)
	var card: Dictionary = options[options.size() - 1]
	for c in options:
		roll -= Dilemma.weight_of(c)
		if roll < 0:
			card = c
			break
	var man := Dilemma.pick(int(card["who"]), s.club.roster, rng)
	s.dilemma = {
		"id": String(card["id"]),
		"man": s.club.roster.find(man),
		## AND HIS NAME, so the card can tell when the index has gone stale
		## (29 Sep 2026): a release, a retirement or a walk-on swap shifts every
		## index behind it, and the card then named — and answered on — whoever
		## had slid into his slot.
		"name": man.display_name if man != null else "",
		"rival": s._last_opponent_name(),
	}
	s.dilemma_recent.append(String(card["id"]))
	while s.dilemma_recent.size() > Season.DILEMMA_MEMORY:
		s.dilemma_recent.remove_at(0)




static func _last_opponent_name(s: Season) -> String:
	if s.results.is_empty():
		return UiKit.t("the other lot")
	var last: Dictionary = s.results[s.results.size() - 1]
	var id: int = int(last.get("opponent", -1))
	if id < 0 or id >= s.world.clubs.size():
		return UiKit.t("the other lot")
	return String(s.world.clubs[id]["name"])




## The card as the screen needs it: the text already filled in, and each option
## with its label and blurb. Empty when there is nothing to answer.
static func dilemma_card(s: Season) -> Dictionary:
	if s.dilemma.is_empty():
		return {}
	var card := Dilemma.by_id(String(s.dilemma["id"]))
	if card.is_empty():
		return {}
	var man := s.dilemma_man()
	var out := card.duplicate(true)
	out["title"] = UiKit.t(String(card.get("title", "")))
	var who := man.display_name if man != null else UiKit.t("somebody")
	var rival := String(s.dilemma.get("rival", UiKit.t("the other lot")))
	out["body"] = Dilemma.fill(String(card["text"]), who, s.club.display_name, rival)
	## AND THE OPTIONS TOO. Only the body was filled, so a card whose ANSWERS
	## named the club printed the token: *"{club} is not an advert."* — caught in
	## a screenshot on 15 Sep 2026, on the one card in the deck whose blurbs use
	## the tokens at all, which is why it had survived.
	##
	## **A substitution applied to some of the strings is a substitution nobody
	## can rely on**, and the cheapest version of that bug is the one where the
	## unfilled field is the one a player is reading when he decides.
	var opts: Array = []
	for o in out.get("options", []):
		var c: Dictionary = (o as Dictionary).duplicate(true)
		c["label"] = Dilemma.fill(String(c.get("label", "")), who,
			s.club.display_name, rival)
		c["blurb"] = Dilemma.fill(String(c.get("blurb", "")), who,
			s.club.display_name, rival)
		opts.append(c)
	out["options"] = opts
	out["man"] = man
	return out




static func dilemma_man(s: Season) -> FighterCard:
	var i: int = int(s.dilemma.get("man", -1))
	var nm := String(s.dilemma.get("name", ""))
	var at: FighterCard = s.club.roster[i] if i >= 0 and i < s.club.roster.size() else null
	## A card from before the name was kept trusts its index, as it always did.
	if nm == "" or (at != null and at.display_name == nm):
		return at
	## The roster moved under the card: find him by name, or he has gone and the
	## card is about "somebody" rather than about the man who took his place.
	for f in s.club.roster:
		if (f as FighterCard).display_name == nm:
			return f
	return null




## ANSWER IT. Returns what happened, in the club's own words, because a choice
## whose consequence is invisible is a choice the player stops making carefully.
##
## Every effect is applied through the office's own functions rather than by
## writing its fields — `note_shift` clamps, `_clamp_fans` exists for a reason,
## and a card that set `notoriety` directly would be the one place in the game
## that could push it past 125.
static func answer_dilemma(s: Season, option_i: int) -> String:
	var card := Dilemma.by_id(String(s.dilemma.get("id", "")))
	if card.is_empty():
		s.dilemma = {}
		return ""
	var opts: Array = card["options"]
	if option_i < 0 or option_i >= opts.size():
		return UiKit.t("Pick one.")
	var fx: Dictionary = (opts[option_i] as Dictionary).get("fx", {})
	var man := s.dilemma_man()
	var said: Array[String] = []

	if fx.has("cc"):
		var d := int(fx["cc"])
		## A club cannot be taken below nothing by a card. The option stays
		## available and simply takes what there is — refusing the choice because
		## the club is skint would make the dilemma a quiz with the answers
		## grayed out, which is worse than the cost.
		## A CLUB ALREADY IN DEBT PAYS NOTHING MORE, it is not PAID. The old
		## `-mini(-d, credits)` went positive below zero: at -10 a "-6 CC" card
		## handed the club +10. And it goes through the books like every other
		## credit, so the finances page can see it.
		var real: int = d if d >= 0 else -mini(-d, maxi(0, s.office.credits))
		if real > 0:
			s.office.take(real, UiKit.t("The club's decision"), "", ClubOffice.LINE_CLUB)
		elif real < 0:
			s.office.spend(-real, ClubOffice.LINE_CLUB)
		said.append("%+d CC" % real)
	if fx.has("morale"):
		## Through `morale_shift`, not by writing the field — the logistic is the
		## only thing stopping a run of hard choices pinning a club at the floor,
		## and a card that set morale directly would be the one place in the game
		## that could do it.
		s.office.morale_shift(float(fx["morale"]))
		said.append(UiKit.t("morale up") if float(fx["morale"]) > 0.0 else UiKit.t("morale down"))
	## THE DECK'S `note` CURRENCY IS NOW THE FOLLOWING TOO.
	##
	## Fifteen cards were written against five currencies — credits, morale,
	## notoriety, fans and a man — and two of those five were the same population
	## seen twice. Rather than rewrite thirty-eight options, `note` is read as a
	## move on the one number that is left, scaled: the old scale ran to 125 and
	## the cards spend two or three of it, so a point of `note` is a fiftieth of
	## the room left. **A currency that no longer exists is not a currency the
	## deck should keep spending.**
	if fx.has("note"):
		var n := float(fx["note"])
		if n > 0.0:
			s.office.fans += (s.office.fan_cap() - s.office.fans) * (n * 0.02)
		else:
			s.office.fans += s.office.fans * (n * 0.02)
		s.office.crowd_came(0)
		said.append(UiKit.t("talked about more") if n > 0.0 else UiKit.t("talked about less"))
	if fx.has("fans"):
		s.office.crowd_came(int(s.office.fans * float(fx["fans"]) * 2.0))
		said.append(UiKit.t("%d%% more following") % int(round(float(fx["fans"]) * 100.0)))
	if fx.has("kit"):
		for f in s.club.roster:
			f.armor = clampf(f.armor + float(fx["kit"]), 0.0, 1.0)
		said.append(UiKit.t("harness mended across the club") if float(fx["kit"]) > 0.0
			else UiKit.t("harness worse across the club"))
	if man != null:
		if fx.has("armor"):
			man.armor = clampf(man.armor + float(fx["armor"]), 0.0, 1.0)
			said.append((UiKit.t("%s's harness mended") if float(fx["armor"]) > 0.0
				else UiKit.t("%s's harness worse")) % man.display_name)
		if fx.has("injury"):
			man.injury = maxi(man.injury, int(fx["injury"]))
			said.append(UiKit.t("%s out %d") % [man.display_name, int(fx["injury"])])
		if fx.has("xp"):
			man.xp += int(fx["xp"])
		if fx.has("potential"):
			man.potential = clampi(man.potential + int(fx["potential"]), 1,
				Career.POTENTIAL_CEILING)
			said.append(UiKit.t("%s's ceiling up %d") % [man.display_name, int(fx["potential"])])
		if fx.has("years"):
			man.years = clampi(man.years + int(fx["years"]), 0, Contracts.YEARS_MAX)
			said.append(UiKit.tn("%s on %d year", "%s on %d years", man.years) % [man.display_name, man.years])
		if fx.has("wage"):
			man.wage_agreed = maxi(1, int(round(float(ClubOffice.billed(man))
				* float(fx["wage"]))))

	s.dilemma = {}
	s.sync_power()
	return UiKit.t("Done.") if said.is_empty() else "  ".join(said) + "."




# ------------------------------------------------------------------ the market
## This summer's free agents, minus anyone already signed out of it.
static func market(s: Season) -> Array:
	var out: Array = []
	for f in Market.pool(s.world.rng.seed, s.world.season, s.world.player_tier(),
			s.office.market_refreshes,
			s.office.scout_names()):
		if not s.market_taken.has(Market.taken_key(f)):
			out.append(f)
	return out




static func market_fee(s: Season, f: FighterCard) -> int:
	return Market.fee(f.overall(), s.world.player_tier())




## What this club would have to put him on. The rookie discount is applied here
## rather than at generation, because it depends on the man's age and not on who
## is selling him.
static func market_wage(s: Season, f: FighterCard) -> int:
	return Contracts.offer(ClubOffice.wage(f), f.age)




## SIGN HIM. Two prices and both have to clear: credits for the fee, and room
## under the cap for the wage — which is the whole reason the cap is worth
## raising and the reason a Star in the list is often not a signing at all.
##
## The refusals are in the order the player would hit them, and each one says the
## number, because "you cannot afford him" without a figure is a screen telling
## you to go and do arithmetic somewhere else.
static func sign_from_market(s: Season, f: FighterCard) -> String:
	var fee := s.market_fee(f)
	if s.office.credits < fee:
		return UiKit.t("%s costs %d CC and you have %d.") % [f.display_name, fee, s.office.credits]
	var wage := s.market_wage(f)
	if ClubOffice.wage_bill(s.club) + wage > s.office.cap():
		return UiKit.t("%s wants %s a week. That puts you %s over the cap.") % [
			f.display_name, ClubOffice.money(wage),
			ClubOffice.money(ClubOffice.wage_bill(s.club) + wage - s.office.cap())]
	var card := f.copy()
	card.years = Contracts.YEARS_NEW
	card.wage_agreed = wage
	## LATE BLOOMER banks a winter's training the day he walks in — the Experience
	## arrival one-shot, at the man rather than at the captain. It fires HERE and
	## nowhere else, so it cannot fire twice: an arrival trait applied wherever a
	## card is touched would pay out again on every re-sign.
	card.xp += int(FighterTrait.mod(card.trait_id, "arrival_xp", 0.0))
	var err := s.club.sign(card)
	if err != "":
		return err
	s.office.spend(fee, ClubOffice.LINE_SQUAD)
	s.market_taken.append(Market.taken_key(f))
	s.sync_power()
	return ""




# -------------------------------------------------------------- the contracts
## EXTEND. Priced off what he is worth today, discounted by how much of the old
## deal the club is tearing up — so extending a man who has improved costs more
## than his old wage and should. The discount is for taking the risk early, not
## for pretending he is the fighter he was three years ago.
static func extend(s: Season, f: FighterCard) -> String:
	if not s.club.roster.has(f):
		return UiKit.t("%s is not on this club's books.") % f.display_name
	if f.years <= 0:
		return UiKit.t("%s is out of contract. Re-sign him.") % f.display_name
	if not Contracts.can_extend(f):
		if f.years >= Contracts.YEARS_MAX:
			return UiKit.t("%s is on the longest deal the club can offer.") % f.display_name
		return UiKit.t("%s is in the last year of his deal. Let it run out, then re-sign him.") % f.display_name
	var was := ClubOffice.billed(f)
	var wage := s.extend_cost(f)
	var bill := ClubOffice.wage_bill(s.club) - was + wage
	if bill > s.office.cap():
		return UiKit.t("That deal puts you %s over the cap.") % ClubOffice.money(bill - s.office.cap())
	f.wage_agreed = wage
	f.years = Contracts.YEARS_MAX
	return ""




## RE-SIGN. Full market rate, no discount, and it is the only thing that saves a
## man whose deal has run out.
static func resign(s: Season, f: FighterCard) -> String:
	if not s.club.roster.has(f):
		return UiKit.t("%s is not on this club's books.") % f.display_name
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
			return UiKit.t("%s is in his last year. Let it run out, then re-sign him.") % f.display_name
		## AND THE OTHER END OF THE SAME FAULT. A man already on the longest deal
		## the club can write cannot be extended either, so "Extend him instead"
		## was a dead end there too — one the check below found the moment it was
		## asked about every length rather than about the one that had gone wrong.
		if f.years >= Contracts.YEARS_MAX:
			return UiKit.t("%s is already on the longest deal the club can offer.") % f.display_name
		return UiKit.t("%s has %d years left. Extend him instead.") % [f.display_name, f.years]
	## WHAT THE FIGHTER CARD PROMISED IS WHAT HAPPENS. The card reads
	## `Contracts.demand()` — the refusal, the mood-priced wage, two years for a
	## man of 33 — and this used to ignore all three and sign everybody for three
	## years at the unpriced rate.
	if Contracts.refuses(f):
		return Contracts.refusal(f)
	var wage := s.resign_cost(f)
	var bill := ClubOffice.wage_bill(s.club) - ClubOffice.billed(f) + wage
	if bill > s.office.cap():
		return UiKit.t("%s wants %s a week. That puts you %s over the cap.") % [
			f.display_name, ClubOffice.money(wage),
			ClubOffice.money(bill - s.office.cap())]
	f.wage_agreed = wage
	f.years = int(Contracts.demand(f)["years"])
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
static func _negotiated(s: Season, f: FighterCard, raw: int) -> int:
	if s.office.trait_covers(ClubOffice.Trait.NEGOTIATOR, Tuning.role_of(int(f.pos))):
		return maxi(1, int(round(float(raw) * ClubOffice.TRAIT_NEGOTIATOR)))
	return raw




static func extend_cost(s: Season, f: FighterCard) -> int:
	return s._negotiated(f, Contracts.extension(ClubOffice.wage(f), f.age, f.years))




static func resign_cost(s: Season, f: FighterCard) -> int:
	return s._negotiated(f, int(Contracts.demand(f)["wage"]))
