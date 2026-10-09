class_name SendOff
extends RefCounted
## THE SEND-OFF. Pete, 1 Oct 2026: *"If you win nationals, we can have 2 or 3
## scheduled events, one as a congratulations, a special training, and a
## 'bestowing' of the Team USA title and Tabard for Worlds. Art will follow of
## course."*
##
## The National champion's bye week before the Worlds is not a week off. Three
## things happen in it, on their own days, each a card the season stops for:
## Monday the club celebrates, Wednesday the federation's national camp, and
## Saturday the tabard — the club goes to the Worlds as the country's team.
## Each card has one answer, because none of them is a decision: they are the
## reward, and the game says so out loud before the biggest week of the year.

const STEPS: int = 3
## Which day of the bye week each falls on, as days off its Saturday.
const DAY_SHIFT := [-5, -3, 0]

## Renown: the room left in the following, as a share.
const CELEBRATE_FANS: float = 0.10
const CELEBRATE_MORALE: float = 0.15
## The camp: this many full weeks of practice for the whole squad.
const CAMP_WEEKS: int = 2


## Is a card waiting? Only in the bye before the Worlds, only for the club that
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
static func team_name(s: Season) -> String:
	return UiKit.t("Team USA")


## The card in front of the player: {day, title, body, button}.
static func card(s: Season) -> Dictionary:
	match s.send_off:
		0:
			return {"day": UiKit.t("MONDAY"), "title": UiKit.t("NATIONAL CHAMPIONS"),
				"body": UiKit.t("The hall is full by noon and the phone does not stop. Every man in the eight is a name in town tonight, and the whole room knows what comes next."),
				"button": UiKit.t("Raise a glass")}
		1:
			return {"day": UiKit.t("WEDNESDAY"), "title": UiKit.t("THE NATIONAL CAMP"),
				"body": UiKit.t("The federation opens its training center to you for three days: its coaches, its mats, its film of every club you will meet at the Worlds."),
				"button": UiKit.t("Train with the federation")}
	return {"day": UiKit.t("SATURDAY"), "title": UiKit.t("THE TABARD"),
		"body": UiKit.t("In front of the federation your captain is handed the tabard. At the Worlds you are not a club any more. You are %s.") % team_name(s),
		"button": UiKit.t("Take the tabard")}


## Do the day. Returns what happened, for the flash.
static func answer(s: Season) -> String:
	if not due(s):
		return ""
	var out := ""
	match s.send_off:
		0:
			s.office.fans += (s.office.fan_cap() - s.office.fans) * CELEBRATE_FANS
			s.office.crowd_came(0)
			for f in s.club.active_eight():
				f.morale_shift(CELEBRATE_MORALE)
			s.office.sync_morale(s.club)
			out = UiKit.t("The town knows your name. Renown and team morale up.")
		1:
			var before := 0
			for f in s.club.roster:
				before += f.xp
			for _i in CAMP_WEEKS:
				SeasonBouts._practice(s, true)
			var after := 0
			for f in s.club.roster:
				after += f.xp
			out = UiKit.t("Three days with the federation: %d XP across the squad.") % (after - before)
		_:
			s.world.team_title = team_name(s)
			for f in s.club.active_eight():
				f.honors += 1
			out = UiKit.t("You go to the Worlds as %s.") % s.world.team_title
	s.send_off += 1
	return out
