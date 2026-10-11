class_name WorldsCamp
extends RefCounted
## THE WORLDS CAMP. Pete, 9 Oct 2026: a midpoint Worlds camp "could cost money
## per fighter attending". It replaces the free national camp the send-off used
## to give (dropped the same day).
##
## Between the pools and the knockout, if the club is through, the federation's
## camp is open for one night. The player chooses who goes, at a price per man:
##   0  the starting five       CAMP_FEE x 5
##   1  the whole eight         CAMP_FEE x 8
##   2  nobody                  free
## Each man who goes comes back with his kit at full, morale up and some XP.
## It is a real money decision: the price is about a cup tie's purse a man.

const FEE: int = 2
const MORALE: float = 0.10
const XP: int = 4
enum Pick { FIVE, EIGHT, SKIP }


## Is the camp open? The Worlds is waiting on the player, the pools are done,
## and he has not fought a knockout bout yet this Worlds.
static func due(s: Season) -> bool:
	if s.worlds_camp == s.world.season:
		return false
	var c := s.pending_cup()
	if c == null or c != s.world.worlds or not c.has_pools or c.stage != Cup.Stage.KNOCKOUT:
		return false
	for rd in c.rounds:
		for m in rd:
			if bool(m.get("played", false)) and (int(m["a"]) == c.player_club or int(m["b"]) == c.player_club):
				return false
	return true


static func men(s: Season, pick: int) -> Array:
	match pick:
		Pick.FIVE: return s.club.starting_five()
		Pick.EIGHT: return s.club.active_eight()
	return []


static func cost(s: Season, pick: int) -> int:
	return FEE * men(s, pick).size()


static func card(s: Season) -> Dictionary:
	return {"title": UiKit.t("THE WORLDS CAMP"),
		"body": UiKit.t("You are through the pools. The federation's camp is open tonight: its armorers, its physios, its film room. It costs %d CC a man. Who goes?") % FEE,
		"options": [
			{"label": UiKit.t("Starting five"), "fx": UiKit.t("%d CC  ·  kit full, morale up, +%d XP each") % [cost(s, Pick.FIVE), XP]},
			{"label": UiKit.t("Whole eight"), "fx": UiKit.t("%d CC  ·  kit full, morale up, +%d XP each") % [cost(s, Pick.EIGHT), XP]},
			{"label": UiKit.t("Nobody"), "fx": UiKit.t("Free  ·  rest at the hotel")},
		]}


## Answer it. A pick the club cannot pay for sends nobody.
static func answer(s: Season, pick: int) -> String:
	if not due(s):
		return ""
	s.worlds_camp = s.world.season
	var going := men(s, pick)
	var fee := FEE * going.size()
	if going.is_empty():
		return UiKit.t("Nobody goes to camp. The squad rests at the hotel.")
	if s.office.credits < fee:
		return UiKit.t("Not enough CC for the camp (%d needed). Nobody goes.") % fee
	s.office.spend(fee, ClubOffice.LINE_SQUAD)
	for f in going:
		f.armor = maxf(f.armor, Quartermaster.ceiling(f))
		f.morale_shift(MORALE)
		f.xp += XP
	s.office.sync_morale(s.club)
	return UiKit.t("%d men at the federation's camp for %d CC: kit full, morale up, +%d XP each.") % [going.size(), fee, XP]
