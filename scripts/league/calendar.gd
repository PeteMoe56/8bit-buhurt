class_name Calendar
extends RefCounted
## THE SEASON AS WEEKS. Pete, 30 Sep 2026: *"that calendar is pretty fucked up
## if there's 3 different events during one week. That would suck."*
##
## THE RULE: ONE THING A WEEK. A week is a league matchday, a cup weekend, your
## own tournament, a playoff round or a Worlds round — never two of them. A club
## with nothing on (knocked out, not invited) trains through it.
##
## A CUP IS ONE WEEKEND, Friday to Sunday (Pete, 30 Sep: "All Cups outside of
## world cups should be Friday-Sunday events. Those events should only be one
## weekend each. You can fight multiple times a day just fine for tournaments.")
## Every round of it is fought that weekend. THE WORLDS IS A WHOLE WEEK, Monday to
## Sunday (Pete, same day: "World Cup should be like a full week long itself
## because it's a big thing") — the pools and the knockout, all in that week.
##
## Decided with Pete the same day: single round robin, a top-four playoff after
## the league, and the playoff's two finalists go up. THE PLAYOFF IS A WEEKEND
## too, semis and final (Pete, 1 Oct), and A BYE WEEK comes before it and before
## the Worlds. A National champion's bye before the Worlds is not empty: it is the
## send-off — a celebration, a national camp and the tabard (`SendOff`).
##
## Built for the PLAYER'S division. The other divisions play their league days
## paced to his (`LeagueWorld._pace_other_tiers`), so every table finishes on
## the same Saturday his does and the national cups draw from tables that are
## the same distance through their year.

enum Kind { LEAGUE, CUP, OWN, PLAYOFF, WORLDS, BYE }

## WHERE EACH CUP WEEKEND FALLS, as a fraction of the league: it goes in after
## league day `round(at * days)`. The Kings Cup is the early one and the Path of
## Honor the late one, as they always were (`INVITATIONALS[].at`).
const CUP_AT := {
	"kings_cup": 0.4,
	"path_of_honor": 0.8,
}
const CUP_ORDER := ["kings_cup", "path_of_honor"]

const PLAYOFF_FIELD: int = 4
## The Worlds' pool days (four clubs a pool, everybody meets everybody), before
## the quarter-finals, semis and final — all in its one week.
const WORLDS_POOL_DAYS: int = 3

## THE FIRST SATURDAY of a season, as a real date, so the calendar screen can be
## a real month. Every season opens on the first Saturday of March; the year is
## only used to find which day of the week the 1st falls on.
const FIRST_YEAR: int = 2027
const OPEN_MONTH: int = 3


static func week(kind: int, extra: Dictionary = {}) -> Dictionary:
	var w := {"kind": kind}
	w.merge(extra)
	return w


## The weeks of a season, in order. `days` is the player's division's league
## days; `national` adds the Worlds at the end.
static func build(days: int, national: bool) -> Array:
	var out: Array = []
	var slots: Array = []          ## [after_day, cup_id], in CUP_ORDER
	for id in CUP_ORDER:
		slots.append([clampi(int(round(float(CUP_AT[id]) * float(days))), 1, days), id])
	var si := 0
	for d in days:
		out.append(week(Kind.LEAGUE, {"day": d}))
		while si < slots.size() and int(slots[si][0]) == d + 1:
			out.append(week(Kind.CUP, {"cup": String(slots[si][1])}))
			si += 1
	out.append(week(Kind.BYE, {"before": "playoff"}))
	out.append(week(Kind.PLAYOFF))
	if national:
		out.append(week(Kind.BYE, {"before": "worlds"}))
		out.append(week(Kind.WORLDS))
	return out


## WHERE YOUR OWN SHOW GOES: the week straight after league day `after_day`
## (1-based, as a bid's `event` is), or the first week after `now` if that has
## already gone by. Returns the index it was inserted at.
static func insert_own(cal: Array, after_day: int, now: int) -> int:
	var at := -1
	for i in cal.size():
		var w: Dictionary = cal[i]
		if int(w["kind"]) == Kind.LEAGUE and int(w["day"]) + 1 == after_day:
			at = i + 1
			break
	if at == -1:
		at = cal.size()
		for i in cal.size():
			if int(cal[i]["kind"]) == Kind.PLAYOFF or int(cal[i]["kind"]) == Kind.BYE:
				at = i
				break
	at = maxi(at, now + 1)
	cal.insert(at, week(Kind.OWN))
	return at


## The week number (1-based) a show bid for after league day `after_day` would
## land on, as `insert_own` would place it.
static func own_week_number(cal: Array, after_day: int) -> int:
	for i in cal.size():
		var w: Dictionary = cal[i]
		if int(w["kind"]) == Kind.LEAGUE and int(w["day"]) + 1 == after_day:
			return i + 2
	return cal.size() + 1


## How many league weeks are left from `from` on.
static func league_weeks_left(cal: Array, from: int) -> int:
	var n := 0
	for i in range(from, cal.size()):
		if int(cal[i]["kind"]) == Kind.LEAGUE:
			n += 1
	return n


# ------------------------------------------------------------------- dates
## The unix time of the season's first Saturday.
static func opening_unix(season: int) -> int:
	var y := FIRST_YEAR + maxi(0, season - 1)
	var t := Time.get_unix_time_from_datetime_dict({"year": y, "month": OPEN_MONTH, "day": 1,
		"hour": 12, "minute": 0, "second": 0})
	var wd := int(Time.get_datetime_dict_from_unix_time(t)["weekday"])   ## 0 = Sunday
	return t + ((6 - wd + 7) % 7) * 86400


## The date of week `i` (its Saturday) as {year, month, day}; `shift` days off it
## (-1 the Friday a cup weekend opens on, +1 its Sunday).
static func date_of(season: int, i: int, shift: int = 0) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(opening_unix(season) + i * 7 * 86400 + shift * 86400)


## A weekend tournament: a cup or your own show, Friday to Sunday.
static func is_weekend(kind: int) -> bool:
	return kind == Kind.CUP or kind == Kind.OWN or kind == Kind.PLAYOFF


## A TOURNAMENT WEEK: every round fought inside it, several bouts a day if that
## is what it takes. The cups, your show and the Worlds; not the league or the
## playoff, which are a fixture a week.
static func is_tournament(kind: int) -> bool:
	return kind == Kind.CUP or kind == Kind.OWN or kind == Kind.WORLDS or kind == Kind.PLAYOFF


## The weekday the 1st of a month falls on, Monday = 0.
static func first_weekday(year: int, month: int) -> int:
	var t := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": 1,
		"hour": 12, "minute": 0, "second": 0})
	return (int(Time.get_datetime_dict_from_unix_time(t)["weekday"]) + 6) % 7


static func days_in(year: int, month: int) -> int:
	if month == 2:
		return 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28
	return 30 if [4, 6, 9, 11].has(month) else 31


## One literal per key, so the string extractor sees every one of them.
static func month_name(m: int) -> String:
	match m:
		1: return UiKit.t("January")
		2: return UiKit.t("February")
		3: return UiKit.t("March")
		4: return UiKit.t("April")
		5: return UiKit.t("May")
		6: return UiKit.t("June")
		7: return UiKit.t("July")
		8: return UiKit.t("August")
		9: return UiKit.t("September")
		10: return UiKit.t("October")
		11: return UiKit.t("November")
	return UiKit.t("December")


static func weekday_name(i: int) -> String:
	match i:
		0: return UiKit.t("MON")
		1: return UiKit.t("TUE")
		2: return UiKit.t("WED")
		3: return UiKit.t("THU")
		4: return UiKit.t("FRI")
		5: return UiKit.t("SAT")
	return UiKit.t("SUN")


# ------------------------------------------------------------------ words
## WHAT A WEEK IS CALLED, for a screen: "Kings Cup", "Playoff", "League 3 of 5".
## `own` names your show.
static func label(w: Dictionary, league_days: int, own: String = "") -> String:
	match int(w.get("kind", -1)):
		Kind.LEAGUE:
			return UiKit.t("League %d of %d") % [int(w["day"]) + 1, league_days]
		Kind.CUP:
			return UiKit.t("Kings Cup") if String(w["cup"]) == "kings_cup" else UiKit.t("Path of Honor")
		Kind.PLAYOFF:
			return UiKit.t("Playoff")
		Kind.BYE:
			return UiKit.t("Bye week")
		Kind.WORLDS:
			return UiKit.t("Worlds")
		Kind.OWN:
			return own if own != "" else UiKit.t("Your show")
	return ""


## THE SAME WEEK, SHORT, for a list or a calendar cell: "League 3/5".
static func short_label(w: Dictionary, league_days: int) -> String:
	match int(w.get("kind", -1)):
		Kind.LEAGUE:
			return UiKit.t("League %d/%d") % [int(w["day"]) + 1, league_days]
		Kind.CUP:
			return UiKit.t("Kings Cup") if String(w["cup"]) == "kings_cup" else UiKit.t("Path of Honor")
		Kind.PLAYOFF:
			return UiKit.t("Playoff")
		Kind.BYE:
			return UiKit.t("Bye week")
		Kind.WORLDS:
			return UiKit.t("Worlds")
		Kind.OWN:
			return UiKit.t("Your show")
	return ""


static func knockout_short(left: int) -> String:
	match left:
		1: return UiKit.t("F")
		2: return UiKit.t("SF")
		3: return UiKit.t("QF")
	return ""


## A knockout round by how many rounds are left including it: 1 is the final.
static func knockout_word(left: int) -> String:
	match left:
		1: return UiKit.t("Final")
		2: return UiKit.t("Semi-finals")
		3: return UiKit.t("Quarter-finals")
	return UiKit.t("Round of %d") % int(pow(2, left))


## The color a week is drawn in, everywhere it is drawn: league blue, cup gold,
## your own show green, playoff and Worlds purple.
static func color(kind: int) -> Color:
	match kind:
		Kind.LEAGUE: return Color("2a5caa")
		Kind.CUP: return Color("c08a1e")
		Kind.OWN: return Color("2f7d3b")
		Kind.PLAYOFF, Kind.WORLDS: return Color("7b3fa0")
		Kind.BYE: return Color("5a5a5a")
	return Color("4a4a4a")
