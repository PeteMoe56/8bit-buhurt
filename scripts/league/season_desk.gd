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
	## THE PLAYOFF DECIDES IT (30 Sep 2026): the two finalists go up, then the
	## table if a division somehow has no playoff.
	var order := s.world.playoff_order(t)
	for i in mini(int(League.TIERS[t]["up"]), order.size()):
		if int(order[i]["club"]) == s.world.player_club:
			return true
	return false




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




## THE GROUND THE NEXT DIVISION NEEDS, AND WHAT IS LEFT TO BUILD (Pete, 1 Oct
## 2026: "make a prompt about mid-season about needing the next arena. Then a
## 'Build Now' prompt at the promotion gate"). Every novice in the 1 Oct test
## won the Backyard and stayed there, because the only word about the ground
## came at the moment promotion was refused. {} when the ground is already fit
## or there is nowhere to go.
static func ground_gap(s: Season) -> Dictionary:
	var t := s.world.player_tier()
	if t >= League.TIERS.size() - 1:
		return {}
	var up := t + 1
	var a := s.office.arena
	if a.fit_for(up):
		return {}
	var need := Arena.level_for_tier(up)
	var steps: Array = []
	var total := 0
	for lv in range(a.level + 1, need + 1):
		steps.append(String(Arena.LEVELS[lv]["name"]))
		total += int(Arena.LEVELS[lv]["cost"])
	return {"to": League.tier_name(up), "have": a.arena_name(), "need": Arena.arena_name_of(need),
		"steps": steps, "total": total, "next": String(Arena.LEVELS[a.level + 1]["name"]),
		"next_cost": int(Arena.LEVELS[a.level + 1]["cost"])}


## SAID ONCE A SEASON, from halfway through the league, to a club in the
## playoff places whose ground the division above would refuse.
static func ground_ask(s: Season) -> Dictionary:
	if s.ground_warned == s.world.season or s.season_complete():
		return {}
	var gap := ground_gap(s)
	if gap.is_empty():
		return {}
	var t := s.world.player_tier()
	var days := int(League.TIERS[t]["clubs"]) - 1
	if int(s.world.days_played.get(t, 0)) * 2 < days:
		return {}
	if s.world.player_position() > PLAYOFF_PLACES:
		return {}
	return gap


const PLAYOFF_PLACES := 4


## ------------------------------------------------------------- the first year up
## THE FREE AGENTS, ASKED FOR AT THE TOP OF A NEW DIVISION (lane B, 2 Oct 2026).
## The gold-button novice won 18,623 CC across 60 seasons, signed nobody and went
## up and down nine times each way: promoted on a Backyard squad, sent straight
## back. The ground was asked for in time (30.67); the men were never asked for.
## Once a season, before its first bout, to a club that has just gone up (or
## every season, with MARKET_ASK_ALWAYS) and can spare the fee and carry the
## wage of a free agent who outrates a man on its eight. {} otherwise.
const MARKET_ASK := true
const MARKET_ASK_ALWAYS := false
## AND TO A HOARD: a club holding `Season.HOARD_SUMMERS` summers' bills, the
## line the hoard note already draws.
## ON (Pete, 2 Oct 2026): the gold bot signed 15 -> 29 (seed 1) and 16 -> 22 (seed 2).
const MARKET_ASK_HOARD := true


## THE SEASON A CLUB FIRST PLAYS IN A DIVISION IT WAS PROMOTED INTO.
static func just_promoted(s: Season) -> bool:
	if s.world.history.is_empty():
		return false
	var h: Dictionary = s.world.history[-1]
	return bool(h.get("promoted", false)) and int(h.get("season", -9)) == s.world.season - 1


## The weakest man on the eight, by rating. null for an empty club.
static func weakest_on_eight(s: Season) -> FighterCard:
	var low: FighterCard = null
	for f in s.club.active_eight():
		if low == null or f.rating() < low.rating():
			low = f
	return low


## THE MEN WHO WOULD MAKE THE EIGHT AND THE CLUB CAN TAKE: fee paid with the
## summer bill still in hand, wage under the cap, a place on the books. Best first.
static func market_upgrades(s: Season) -> Array:
	var out: Array = []
	var low := weakest_on_eight(s)
	if low == null or s.club.roster.size() >= MeleeClub.SQUAD_MAX:
		return out
	var spare := s.office.credits - s.office.summer_bill()
	for f in s.market():
		if f.rating() <= low.rating() or s.market_fee(f) > spare or sign_wall(s, f) != "":
			continue
		out.append(f)
	out.sort_custom(func(a, b): return a.rating() > b.rating())
	return out


static func market_ask(s: Season) -> Dictionary:
	if not MARKET_ASK or s.market_warned == s.world.season or not s.results.is_empty() or s.season_complete() \
			or s.blocked_by() != "":
		return {}
	var hoard: bool = MARKET_ASK_HOARD \
		and s.office.credits >= maxi(1, s.office.summer_bill()) * Season.HOARD_SUMMERS
	if not MARKET_ASK_ALWAYS and not hoard and not just_promoted(s):
		return {}
	var ups := market_upgrades(s)
	if ups.is_empty():
		return {}
	return {"tier": League.tier_name(s.world.player_tier()), "weakest": weakest_on_eight(s).overall(),
		"count": ups.size(), "best": ups[0]}


## BUILD NOW, at the gate: every level still missing, in one go. The one-a-week
## rule is for a season in progress; at the gate the season is over and the
## club is choosing between the ground and another year where it is.
static func build_for_promotion(s: Season) -> String:
	var gap := ground_gap(s)
	if gap.is_empty():
		return ""
	if s.office.credits < int(gap["total"]):
		return UiKit.t("The %s costs %d CC from here and you have %d.") % [
			UiKit.t(String(gap["need"])), int(gap["total"]), s.office.credits]
	var t := s.world.player_tier()
	while not s.office.arena.fit_for(t + 1):
		var err := s.office.arena.can_build(s.office.tier, s.office.credits)
		if err != "":
			return err
		s.office.spend(s.office.arena.next_cost(), ClubOffice.LINE_GROUND)
		s.office.arena.level += 1
		s.office.arena.built()
	s.sync_power()
	return ""


## THE NEXT REAL STEP, when it is not the fight (1 Oct novice report, Pete
## approved): every first-timer pressed the gold button and only the gold
## button, so a starter the marshals would turn away and a ground the division
## above would refuse went unseen until they cost a bout or a promotion.
## "kit" — a man in the first five fails inspection (and Maintenance is open);
## "build" — the ground is short for the division above and the next level can
## be built this week; "" — the fight is the step. Asked only of a week with
## nothing blocking it.
static func gold_step(s: Season) -> String:
	if s.blocked_by() != "" or s.season_complete():
		return ""
	if s.first_bout_done():
		for f in s.club.active_eight().slice(0, MeleeClub.LINE_SIZE):
			if not (f as FighterCard).passes_inspection():
				return "kit"
	## THE GROUND IS NO LONGER A GOLD STEP (Pete, 2 Oct 2026 playtest: "Build
	## Club Gym on main page should be a popup, not take the place of the golden
	## Fight buttons"). It is offered by the ground card instead: `ground_offer`.
	return ""


## THE GROUND CARD, the first week a build can go ahead or from halfway through
## the league (`ground_ask`), once a season either way. {} when not due.
static func ground_offer(s: Season) -> Dictionary:
	var ask := ground_ask(s)
	if not ask.is_empty():
		return ask
	if s.ground_warned == s.world.season or s.season_complete() or s.blocked_by() != "":
		return {}
	## FROM THE SECOND WEEK: a card on the very first look at the hub, before a
	## first-timer has seen a fight, is a card about a thing he has no reason to want.
	if int(s.world.days_played.get(s.world.player_tier(), 0)) < 1:
		return {}
	var gap := ground_gap(s)
	if gap.is_empty():
		return {}
	var o := s.office
	if o.arena.can_build(o.tier, o.credits) != "" or o.done_this_week(ClubOffice.SLOT_ARENA):
		return {}
	return gap


## WHAT THE KIT IS COSTING THE RATING, in whole points (1 Oct novice report, Pete
## approved): a first-timer won, saw the rating fall, and had no idea why. Kit
## wears in fights (register 30.63) and a worn harness takes a man's base down,
## so after a bout the rating dips by exactly this much. The rating with every
## travelling man's harness at the top of his own metal, less the rating now; 0
## when the wear costs less than a point.
static func kit_dip(s: Season) -> int:
	var men := s.club.active_eight()
	var was: Array[float] = []
	var now := s.club.power_exact()
	for f in men:
		was.append((f as FighterCard).armor)
		f.armor = maxf(f.armor, Quartermaster.ceiling(f))
	var whole := s.club.power_exact()
	for i in men.size():
		(men[i] as FighterCard).armor = was[i]
	return maxi(0, int(round(whole)) - int(round(now)))


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
	var deck: Array = Dilemma.deck_for(s.coach.standing_scale())
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
		## ON THE MEN (3 Oct 2026): a shift on the club figure alone was rebuilt
		## away by the next event's `sync_morale`. Not softened by the coach —
		## that is for losses, and a card is a decision.
		SeasonBouts.room_shift(s, float(fx["morale"]), false)
		said.append(UiKit.t("squad mood up") if float(fx["morale"]) > 0.0 else UiKit.t("squad mood down"))
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
			_mend(f, float(fx["kit"]))
		said.append(UiKit.t("harness mended across the club") if float(fx["kit"]) > 0.0
			else UiKit.t("harness worse across the club"))
	## THE EIGHT ONLY (3 Oct 2026): "Order for the eight" mended the reserves too.
	if fx.has("kit_eight"):
		for f in s.club.active_eight():
			_mend(f, float(fx["kit_eight"]))
		said.append(UiKit.t("harness mended for the eight") if float(fx["kit_eight"]) > 0.0
			else UiKit.t("harness worse for the eight"))
	if man != null:
		if fx.has("armor"):
			_mend(man, float(fx["armor"]))
			said.append((UiKit.t("%s's harness mended") if float(fx["armor"]) > 0.0
				else UiKit.t("%s's harness worse")) % man.display_name)
		if fx.has("injury"):
			man.injury = maxi(man.injury, int(fx["injury"]))
			man.injury_kind = FighterCard.injury_for(man.injury, hash(man.display_name + str(s.world.event)))
			said.append(UiKit.t("%s out %d") % [man.display_name, int(fx["injury"])] + " · " + man.injury_word())
		if fx.has("xp"):
			man.xp += int(fx["xp"])
		if fx.has("potential"):
			man.potential = clampi(man.potential + int(fx["potential"]), 1,
				Career.POTENTIAL_CEILING)
			said.append(UiKit.t("%s's ceiling up %d") % [man.display_name, int(fx["potential"])])
		if fx.has("years"):
			man.years = clampi(man.years + int(fx["years"]), 0, Contracts.YEARS_MAX)
			said.append(UiKit.tn("%s has %d year left", "%s has %d years left", man.years) % [man.display_name, man.years])
		## OFF THE DEAL, NOT THE BILL (3 Oct 2026): the bill already carries his
		## CHEAP/LOYAL discount and `billed()` applies it again, so an "18% raise"
		## cut a CHEAP man's bill from 800 to 755.
		if fx.has("wage"):
			var deal := man.wage_agreed if man.wage_agreed > 0 else ClubOffice.wage(man)
			man.wage_agreed = maxi(1, int(round(float(deal) * float(fx["wage"]))))

	s.dilemma = {}
	s.sync_power()
	## JOINED WITH A DOT, and the first letter up (playtest 30 Sep: "morale up
	## Orr on 1 year" read as one broken sentence).
	if said.is_empty():
		return UiKit.t("Done.")
	var line := "  ·  ".join(said)
	return line.left(1).to_upper() + line.substr(1) + "."




## A CARD MENDS KIT ONLY AS FAR AS THE METAL GOES (3 Oct 2026). It clamped to
## 1.0, so a borrowed harness with a 0.90 ceiling came back at 1.00 — the rule is
## that better than the metal costs new armor. Never takes a man down, either.
static func _mend(f: FighterCard, d: float) -> void:
	f.armor = clampf(f.armor + d, 0.0, maxf(Quartermaster.ceiling(f), f.armor))


## ------------------------------------------------------- signed this season
## A DEAL SIGNED THIS SEASON CANNOT BE EXTENDED THIS SEASON (3 Oct 2026). Sign
## at the going rate, extend the same afternoon at up to 28% off and five years:
## that is the button `Contracts.EXTEND_MAX_OFF` says the fork must not be. The
## marks ride in `market_taken`, which is saved and cleared every summer.
static func _signed_key(f: FighterCard) -> String:
	return "signed:%s#%d" % [f.display_name, f.number]


static func note_signed(s: Season, f: FighterCard) -> void:
	var k := _signed_key(f)
	if not s.market_taken.has(k):
		s.market_taken.append(k)


static func signed_this_season(s: Season, f: FighterCard) -> bool:
	return s.market_taken.has(_signed_key(f))


# ------------------------------------------------------------------ the market
## This summer's free agents, minus anyone already signed out of it.
static func market(s: Season) -> Array:
	var out: Array = []
	for f in Market.pool(s.world.rng.seed, s.world.season, s.world.player_tier(),
			s.office.market_refreshes,
			s.office.scout_names()):
		if not s.market_taken.has(Market.taken_key(f)):
			out.append(f)
	## NO FREE AGENT SHARES A NAME WITH ONE OF YOUR MEN (blind review round 3:
	## "Mear" on the roster and in the market read as a bug). Renamed from a
	## stream seeded by his drawn name only, so the same man gets the same new
	## name every time the list is rebuilt.
	var have := {}
	for c in s.club.roster:
		have[c.display_name] = true
	for f in out:
		if not have.has(f.display_name):
			have[f.display_name] = true
			continue
		f.set_meta("drawn_name", f.display_name)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("market-name:" + f.display_name)
		var guard := 0
		while have.has(f.display_name) and guard < 64:
			f.display_name = ClubFactory.SURNAMES[rng.randi() % ClubFactory.SURNAMES.size()]
			guard += 1
		have[f.display_name] = true
	return out




static func market_fee(s: Season, f: FighterCard) -> int:
	## THE COACH'S RECRUITING: 5% off a star, never below a credit.
	var fee := Market.fee(f.overall(), s.world.player_tier())
	var mult: float = s.coach.recruit_mult()
	## A CLUB THAT HAS JUST GONE UP IS A DRAW (lane B, 2 Oct 2026): men want the
	## bigger stage, and the first year up is when a club most needs them.
	if just_promoted(s):
		mult *= Market.PROMOTED_FEE_MULT
	return maxi(1, int(round(float(fee) * mult))) if fee > 0 else fee




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
const SIGNING_STARTS := true


## WHICH WALL A SIGNING WOULD HIT, in the order `sign_from_market` checks them:
## "fee", "cap", "full", or "" when it would go through. The market's gold
## button reads this, so it is never gold on a man the signing refuses.
static func sign_wall(s: Season, f: FighterCard) -> String:
	if s.office.credits < s.market_fee(f):
		return "fee"
	if ClubOffice.wage_bill(s.club) + ClubOffice.billed_at(f, s.market_wage(f)) > s.office.cap():
		return "cap"
	if s.club.roster.size() >= MeleeClub.SQUAD_MAX:
		return "full"
	return ""


static func sign_from_market(s: Season, f: FighterCard) -> String:
	var fee := s.market_fee(f)
	if s.office.credits < fee:
		return UiKit.t("%s costs %d CC and you have %d.") % [f.display_name, fee, s.office.credits]
	var wage := s.market_wage(f)
	var bills := ClubOffice.billed_at(f, wage)
	if ClubOffice.wage_bill(s.club) + bills > s.office.cap():
		return UiKit.t("%s wants %s a year. That puts you %s over the cap.") % [
			f.display_name, ClubOffice.money(bills),
			ClubOffice.money(ClubOffice.wage_bill(s.club) + bills - s.office.cap())]
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
	## A SIGNING WHO OUTRATES A MAN ON THE EIGHT TAKES HIS PLACE (lane B, 2 Oct
	## 2026). He landed in the reserve and stayed there until the player swapped
	## him up by hand, so a club that signed and never swapped paid for a man who
	## never fought. The weakest man on the eight steps down for him (one in his
	## own place first), if the five still fill; the line's order is not touched.
	if SIGNING_STARTS and not card.active:
		var low: FighterCard = null
		for m in s.club.active_eight():
			if int(m.pos) == int(card.pos) and m.rating() < card.rating() \
					and (low == null or m.rating() < low.rating()):
				low = m
		if low == null:
			low = weakest_on_eight(s)
		if low != null and card.rating() > low.rating():
			s.club.swap_squad(low, card)
	s.office.spend(fee, ClubOffice.LINE_SQUAD)
	s.market_taken.append(Market.taken_key(f))
	note_signed(s, card)
	Achievements.unlock("NEW_BLOOD")
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
	if signed_this_season(s, f):
		return UiKit.t("%s only signed this season. His deal can be extended from next season.") % f.display_name
	var was := ClubOffice.billed(f)
	var wage := s.extend_cost(f)
	var bill := ClubOffice.wage_bill(s.club) - was + ClubOffice.billed_at(f, wage)
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
		## AND THE OTHER END OF THE SAME FAULT. A man already on the longest deal
		## the club can write cannot be extended either, so "Extend him instead"
		## was a dead end there too — one the check below found the moment it was
		## asked about every length rather than about the one that had gone wrong.
		if f.years >= Contracts.YEARS_MAX:
			return UiKit.t("%s is already on the longest deal the club can offer.") % f.display_name
		## AND NOT TO A DOOR THAT IS SHUT THIS SEASON (3 Oct 2026).
		if signed_this_season(s, f):
			return UiKit.t("%s only signed this season. His deal can be extended from next season.") % f.display_name
		return UiKit.t("%s has %d years left. Extend him instead.") % [f.display_name, f.years]
	## WHAT THE FIGHTER CARD PROMISED IS WHAT HAPPENS. The card reads
	## `Contracts.demand()` — the refusal, the mood-priced wage, two years for a
	## man of 33 — and this used to ignore all three and sign everybody for three
	## years at the unpriced rate.
	if Contracts.refuses(f):
		return Contracts.refusal(f)
	var wage := s.resign_cost(f)
	var bill := ClubOffice.wage_bill(s.club) - ClubOffice.billed(f) + ClubOffice.billed_at(f, wage)
	if bill > s.office.cap():
		return UiKit.t("%s wants %s a year. That puts you %s over the cap.") % [
			f.display_name, ClubOffice.money(ClubOffice.billed_at(f, wage)),
			ClubOffice.money(bill - s.office.cap())]
	f.wage_agreed = wage
	f.years = int(Contracts.demand(f)["years"])
	note_signed(s, f)
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




## HIS MOOD IS ON THIS INVOICE TOO (Pete, playtest 30 Sep: "Wage should
## dictate contracts, CC should dictate their feelings during negotiations").
## The wage is the price; the CC you spend on him (a word, the armorer) moves
## his mood, and his mood moves the wage — the same rate re-signing uses.
static func extend_cost(s: Season, f: FighterCard) -> int:
	var raw := Contracts.extension(ClubOffice.wage(f), f.age, f.years)
	return s._negotiated(f, maxi(1, int(round(float(raw) * Contracts.mood_rate(f.morale)))))




static func resign_cost(s: Season, f: FighterCard) -> int:
	return s._negotiated(f, int(Contracts.demand(f)["wage"]))
