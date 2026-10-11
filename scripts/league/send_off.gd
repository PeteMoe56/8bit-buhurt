class_name SendOff
extends RefCounted
## THE SEND-OFF WEEK. Pete, 1 Oct 2026: *"If you win nationals, we can have 2 or
## 3 scheduled events, one as a congratulations, a special training, and a
## 'bestowing' of the Team USA title and Tabard for Worlds."* Then 9 Oct 2026:
## drop the National Camp; the week before the Worlds becomes five days of story
## (the papers, an interview, Team USA, heat on the favourite nations), the
## button reads "Next Event", and one event gives a real boost for the Worlds.
##
## Monday to Friday, one event a day, each a screen the season stops for:
##   MON the parade      fans and morale up
##   TUE the papers      the final on the front page, kept in the club's history
##   WED the interview   CONFIDENT (morale, fans, and a rival takes it personally)
##                       or HUMBLE (more fans, no heat)
##   THU the favorites   the nations to beat, from the returning rivals
##   FRI the tabard      you are Team USA; pick ONE gift for the Worlds
##
## The lines are Claude's picks (11 Oct 2026, Pete: pick for me, swap later).
## Every line is a key in locale/strings.csv, so changing one is a one-line edit.

const STEPS: int = 5
enum Day { PARADE, PAPERS, INTERVIEW, FAVORITES, TABARD }
## Which day of the bye week each falls on, as days off its Saturday.
const DAY_SHIFT := [-5, -4, -3, -2, -1]

## Monday. Renown: the room left in the following, as a share.
const PARADE_FANS: float = 0.10
const PARADE_MORALE: float = 0.15
## Wednesday.
const CONFIDENT_MORALE: float = 0.10
const CONFIDENT_FANS: float = 0.05
const HUMBLE_FANS: float = 0.10
## The rival who heard it comes to the Worlds this much stronger.
const GRUDGE_POWER: int = 3
## Friday's gifts: 0 armorers (all kit to full), 1 sponsor (CC), 2 the nation
## behind you (morale to full).
enum Gift { ARMORERS, SPONSOR, NATION }
const SPONSOR_CC: int = 12

## The captain's line in Tuesday's paper; one is picked by the season's seed.
const QUOTES := [
	"We came here to win it, and we are not done yet.",
	"This one is for everybody who ever held a pad for us.",
	"Enjoy it tonight. Monday we start on the Worlds.",
	"Ask me again after the Worlds.",
]
const HEADLINES := ["NATIONAL CHAMPIONS!", "KINGS OF THE COUNTRY", "NEXT STOP: THE WORLDS"]


## Is an event waiting? Only in the bye before the Worlds, only for the club that
## won the National playoff, and only if it is going (the federation's veto
## still holds).
static func due(s: Season) -> bool:
	var w := s.world.this_week()
	if int(w.get("kind", -1)) != Calendar.Kind.BYE or String(w.get("before", "")) != "worlds":
		return false
	if s.send_off >= STEPS or s.world.cup_entry_barred:
		return false
	return s.world.player_tier() == League.Tier.NATIONAL and s.world.player_champion()


## The country's team. One world, one country (Pete, 9 Oct 2026).
static func team_name(_s: Season) -> String:
	return UiKit.t("Team USA")


static func _pick(s: Season, n: int, salt: String) -> int:
	return absi(hash([s.seed_value, s.world.season, salt])) % maxi(1, n)


## The National final, for the papers: {opponent, score, record, top, top_downs, seasons}.
static func final_facts(s: Season) -> Dictionary:
	var out := {"opponent": "", "score": "", "record": "", "top": "", "top_downs": 0,
		"seasons": s.world.season}
	for i in range(s.world.honors.size() - 1, -1, -1):
		var h: Dictionary = s.world.honors[i]
		if String(h.get("id", "")).begins_with("playoff:") and int(h.get("season", -1)) == s.world.season:
			var ru := int(h.get("runner_up", -1))
			if ru >= 0 and ru < s.world.clubs.size():
				out["opponent"] = String(s.world.clubs[ru]["name"])
			out["score"] = String(h.get("score", ""))
			break
	for r in s.table():
		if int(r["club"]) == s.world.player_club:
			out["record"] = "%d-%d-%d" % [int(r["won"]), int(r["drawn"]), int(r["lost"])]
	var best: FighterCard = null
	for f in s.club.roster:
		if best == null or f.downs > best.downs:
			best = f
	if best != null:
		out["top"] = best.display_name
		out["top_downs"] = best.downs
	return out


## THE NATIONS TO BEAT, from the returning rivals: [favorite, grudge-or-next,
## dark horse], each {rival, name, code, power, stars, met, won, lost, tag, line}.
static func favorites(s: Season) -> Array:
	var w := s.world
	w._ensure_rivals()
	var won_worlds := false
	for h in w.honors:
		if String(h.get("id", "")) == "worlds" and int(h.get("champion", -1)) == w.player_club:
			won_worlds = true
	var order: Array = []
	for i in w.rivals.size():
		order.append(i)
	order.sort_custom(func(a, b): return w.rival_power(a, w.season) > w.rival_power(b, w.season))
	if order.is_empty():
		return []
	var picks: Array = [order[0]]
	var grudge := w.grudge_rival if w.grudge_rival >= 0 and w.grudge_rival != order[0] else -1
	picks.append(grudge if grudge >= 0 else order[mini(1, order.size() - 1)])
	picks.append(order[order.size() - 1])
	var out: Array = []
	for k in picks.size():
		var i: int = picks[k]
		var rv: Dictionary = w.rivals[i]
		var p := w.rival_power(i, w.season)
		if k == 0 and won_worlds:
			p = LeagueWorld.ELITE_POWER[0]
		var tag := UiKit.t("THE FAVORITE")
		var line := UiKit.t("The strongest side in the field this year. Everybody has to get past them.")
		if k == 0 and int(rv.get("titles", 0)) > 0:
			line = UiKit.t("%d-time world champions. The side everybody has to get past.") % int(rv["titles"])
		if k == 1:
			tag = UiKit.t("GRUDGE") if i == grudge else UiKit.t("CONTENDER")
			line = UiKit.t("They heard what your captain said on Wednesday. They want you in the bracket.") if i == grudge \
				else UiKit.t("A real side with a real chance. Nobody wants them in their pool.")
		if k == 2:
			tag = UiKit.t("DARK HORSE")
			line = UiKit.t("Young team, nothing to lose. Nobody is picking them, which is how they like it.")
		out.append({"rival": i, "name": String(rv["name"]), "code": String(rv.get("short", "")), "power": p,
			"stars": clampi(int(round(float(p - 62) / 7.0)), 1, 5),
			"met": int(rv.get("met", 0)), "won": int(rv.get("lost_to_you", 0)), "lost": int(rv.get("beat_you", 0)),
			"tag": tag, "line": line})
	return out


## The rival the reporter asks about on Wednesday: the strongest, unless one
## has beaten you before (that is the story).
static func reporter_rival(s: Season) -> int:
	var w := s.world
	w._ensure_rivals()
	var best := -1
	for i in w.rivals.size():
		if best == -1 or int(w.rivals[i].get("beat_you", 0)) > int(w.rivals[best].get("beat_you", 0)) \
				or (int(w.rivals[i].get("beat_you", 0)) == int(w.rivals[best].get("beat_you", 0))
					and w.rival_power(i, w.season) > w.rival_power(best, w.season)):
			best = i
	return best


## The event in front of the player: {day, title, body, art, chips, options,
## button}. `options` is empty for a day with one answer; then `button` reads
## "Next event".
static func card(s: Season) -> Dictionary:
	match s.send_off:
		Day.PARADE:
			return {"day": UiKit.t("MONDAY"), "title": UiKit.t("THE PARADE"), "art": "parade",
				"body": UiKit.t("The town shuts Main Street for its National champions. Eight men on a truck, the trophy held high, and the whole town on the curb."),
				"chips": [UiKit.t("FANS +%d%%") % int(PARADE_FANS * 100.0), UiKit.t("MORALE +%d%%") % int(PARADE_MORALE * 100.0)],
				"options": [], "button": UiKit.t("Next event")}
		Day.PAPERS:
			var f := final_facts(s)
			var body := UiKit.t("%s took the National title and go to the Worlds as Team USA.") % s.club.display_name
			if String(f["opponent"]) != "":
				body = UiKit.t("%s beat %s %s in the final to take the National title, and go to the Worlds as Team USA.") \
					% [s.club.display_name, String(f["opponent"]), String(f["score"])] if String(f["score"]) != "" \
					else UiKit.t("%s beat %s in the final to take the National title, and go to the Worlds as Team USA.") \
					% [s.club.display_name, String(f["opponent"])]
			## The man with the most downs speaks for the club.
			var who: String = String(f["top"]) if String(f["top"]) != "" else s.club.display_name
			var q: String = UiKit.t(String(QUOTES[_pick(s, QUOTES.size(), "quote")]))
			return {"day": UiKit.t("TUESDAY"), "title": UiKit.t("THE PAPERS"), "art": "papers",
				"headline": UiKit.t(String(HEADLINES[_pick(s, HEADLINES.size(), "headline")])),
				"body": body, "quote": UiKit.t("\"%s\" said %s.") % [q, who],
				"facts": [[UiKit.t("Season record"), String(f["record"])],
					[UiKit.t("Top fighter"), UiKit.t("%s · %d downs") % [String(f["top"]), int(f["top_downs"])] if int(f["top_downs"]) > 0 else ""],
					[UiKit.t("Seasons to get here"), "%d" % int(f["seasons"])]],
				"chips": [UiKit.t("SAVED TO HISTORY")], "options": [], "button": UiKit.t("Next event")}
		Day.INTERVIEW:
			var ri := reporter_rival(s)
			var rn: String = String(s.world.rivals[ri]["name"]) if ri >= 0 else UiKit.t("The world")
			return {"day": UiKit.t("WEDNESDAY"), "title": UiKit.t("THE INTERVIEW"), "art": "interview",
				"body": UiKit.t("A reporter from the national network leans in: \"%s say Team USA got lucky at Nationals. What do you say to them?\"") % rn,
				"chips": [],
				"options": [
					{"label": UiKit.t("Confident"), "line": UiKit.t("\"Tell them to watch the final. We'll see them in the bracket.\""),
						"fx": UiKit.t("MORALE +%d%%  ·  FANS +%d%%  ·  %s will remember it") % [int(CONFIDENT_MORALE * 100.0), int(CONFIDENT_FANS * 100.0), rn]},
					{"label": UiKit.t("Humble"), "line": UiKit.t("\"They're a great side. We'll have to fight our best to beat them.\""),
						"fx": UiKit.t("FANS +%d%%  ·  no extra heat") % int(HUMBLE_FANS * 100.0)},
				], "button": ""}
		Day.FAVORITES:
			return {"day": UiKit.t("THURSDAY"), "title": UiKit.t("THE FAVORITES"), "art": "favorites",
				"body": UiKit.t("The pundits pick their winners. Most of them aren't picking you. Here's who stands between Team USA and the world title."),
				"nations": favorites(s), "chips": [], "options": [], "button": UiKit.t("Next event")}
	return {"day": UiKit.t("FRIDAY"), "title": UiKit.t("YOU ARE TEAM USA"), "art": "tabard",
		"body": UiKit.t("In front of the federation your captain is handed the tabard. %s fights the Worlds as Team USA. The federation offers one gift. Pick one:") % s.club.display_name,
		"chips": [],
		"options": [
			{"label": UiKit.t("Armorers"), "line": UiKit.t("Every fighter's kit fixed up and back to full."), "fx": UiKit.t("ALL KIT 100%")},
			{"label": UiKit.t("Sponsor"), "line": UiKit.t("A national sponsor signs on. Spend it before the Worlds."), "fx": UiKit.t("+%d CC") % SPONSOR_CC},
			{"label": UiKit.t("Home support"), "line": UiKit.t("Letters and calls from home. The whole team fired up."), "fx": UiKit.t("MORALE 100%")},
		], "button": ""}


## Do the day. `choice` answers Wednesday and Friday (ignored otherwise).
## Returns what happened, for the flash.
static func answer(s: Season, choice: int = 0) -> String:
	if not due(s):
		return ""
	var out := ""
	match s.send_off:
		Day.PARADE:
			_fans(s, PARADE_FANS)
			_morale(s, PARADE_MORALE)
			out = UiKit.t("The town knows your name. Fans and team morale up.")
		Day.PAPERS:
			var f := final_facts(s)
			s.world.clippings.append({"season": s.world.season,
				"headline": String(HEADLINES[_pick(s, HEADLINES.size(), "headline")]),
				"opponent": String(f["opponent"]), "score": String(f["score"]),
				"quote": String(QUOTES[_pick(s, QUOTES.size(), "quote")])})
			out = UiKit.t("The clipping goes in the club's history.")
		Day.INTERVIEW:
			s.send_off_picks["interview"] = choice
			if choice == 0:
				_morale(s, CONFIDENT_MORALE)
				_fans(s, CONFIDENT_FANS)
				s.world.grudge_rival = reporter_rival(s)
				out = UiKit.t("The clip runs all night. Somebody abroad is pinning it to a wall.")
			else:
				_fans(s, HUMBLE_FANS)
				s.world.grudge_rival = -1
				out = UiKit.t("A good answer. The country likes you more for it.")
		Day.FAVORITES:
			out = UiKit.t("Five days to the Worlds.")
		_:
			s.world.team_title = team_name(s)
			for f in s.club.active_eight():
				f.honors += 1
			s.send_off_picks["gift"] = choice
			match choice:
				Gift.ARMORERS:
					for f in s.club.roster:
						f.armor = maxf(f.armor, Quartermaster.ceiling(f))
					out = UiKit.t("The federation's armorers go through every harness. All kit back to full.")
				Gift.SPONSOR:
					s.office.take(SPONSOR_CC, UiKit.t("Team USA sponsor"), "event", ClubOffice.LINE_CUP)
					out = UiKit.t("A national sponsor signs on: +%d CC.") % SPONSOR_CC
				_:
					for f in s.club.roster:
						f.morale = 1.0
					s.office.sync_morale(s.club)
					out = UiKit.t("The whole country is behind you. Team morale is full.")
			out = UiKit.t("You go to the Worlds as %s.") % s.world.team_title + " " + out
	s.send_off += 1
	return out


static func _fans(s: Season, share: float) -> void:
	s.office.fans += (s.office.fan_cap() - s.office.fans) * share
	s.office.crowd_came(0)


static func _morale(s: Season, d: float) -> void:
	for f in s.club.active_eight():
		f.morale_shift(d)
	s.office.sync_morale(s.club)
