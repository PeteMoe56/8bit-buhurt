class_name Coach
extends RefCounted
## YOU — the coach, created before the club (Pete, 1 Oct 2026: "You're not
## named. Your career is hidden behind club. You don't have any skills.
## Creating your coach and team should be first when starting a new career.").
##
## A name, a background, a level and five skills. The reputation, the job
## offers and the posts are gone with "Your career": the game is about building
## this team, and the coach is the person building it.
##
## LEVELS come from the work: every win and draw, a good finish, a cup run. Each
## level is one point, spent on one of five skills of five stars each.
##
##   Training    +5% XP per star, in practice and in bouts
##   Motivation  -10% of a loss's morale hit per star
##   Tactics     +1 corner call at 3 stars and another at 5
##   Business    +5% gate, bar and prize money per star
##   Recruiting  -5% on a free agent's fee per star

enum Skill { TRAINING, MOTIVATION, TACTICS, BUSINESS, RECRUITING }
const SKILL_NAME := ["Training", "Motivation", "Tactics", "Business", "Recruiting"]
const SKILL_MAX: int = 5
const START_POINTS: int = 2

## The three backgrounds, each a free point in one skill.
enum Background { FIGHTER, PROMOTER, MARSHAL }
const BACKGROUND_NAME := ["Ex-fighter", "Promoter", "Marshal"]
const BACKGROUND_SKILL := [Skill.TRAINING, Skill.BUSINESS, Skill.TACTICS]

## What the work pays, in coach XP.
const XP_WIN: int = 10
const XP_DRAW: int = 4
## By where the club finished: 1st, 2nd, 3rd, 4th.
const XP_BY_PLACE: Array[int] = [60, 40, 25, 15]
## By the round a cup ended in for you, as the field left standing (1 = won it).
const XP_BY_CUP_EXIT := { 1: 40, 2: 25, 4: 15, 8: 8, 16: 4 }
const XP_PROMOTED: int = 30

var first_name: String = ""
var last_name: String = ""
var display_name: String = "Coach"
var background: int = Background.FIGHTER
## Portrait parts — art follows (Pete, 1 Oct 2026).
var face: int = 0
var kit: int = 0
var beard: int = 0
## FALSE for a save from before the coach existed: the season asks for him once.
var created: bool = false

var level: int = 1
var xp: int = 0
var points: int = START_POINTS
var skills: Array[int] = [0, 0, 0, 0, 0]

## THE RECORD, which is what is left of "Your career".
var seasons: int = 0
var wins: int = 0
var draws: int = 0
var losses: int = 0
var cups: int = 0
var promotions: int = 0
var relegations: int = 0


static func skill_name(i: int) -> String:
	match i:
		Skill.TRAINING: return UiKit.t("Training")
		Skill.MOTIVATION: return UiKit.t("Motivation")
		Skill.TACTICS: return UiKit.t("Tactics")
		Skill.BUSINESS: return UiKit.t("Business")
	return UiKit.t("Recruiting")


static func background_name(i: int) -> String:
	match i:
		Background.PROMOTER: return UiKit.t("Promoter")
		Background.MARSHAL: return UiKit.t("Marshal")
	return UiKit.t("Ex-fighter")


## The name, put back together whenever either half changes.
func set_name(first: String, last: String) -> void:
	first_name = first.strip_edges()
	last_name = last.strip_edges()
	display_name = (first_name + " " + last_name).strip_edges()
	if display_name == "":
		display_name = "Coach"


## THE BACKGROUND'S POINT. Chosen at creation; changing it moves the free point.
func set_background(b: int) -> void:
	var was: int = BACKGROUND_SKILL[background]
	if created or skills[was] <= 0:
		background = b
		return
	skills[was] -= 1
	background = clampi(b, 0, BACKGROUND_NAME.size() - 1)
	skills[int(BACKGROUND_SKILL[background])] += 1


## A brand-new coach: the background's point in place, the two to spend.
func start_fresh(b: int = Background.FIGHTER) -> void:
	level = 1
	xp = 0
	points = START_POINTS
	skills = [0, 0, 0, 0, 0]
	background = clampi(b, 0, BACKGROUND_NAME.size() - 1)
	skills[int(BACKGROUND_SKILL[background])] = 1


func skill(i: int) -> int:
	return skills[i] if i >= 0 and i < skills.size() else 0


## SPEND A POINT. "" when it went in.
func spend(i: int) -> String:
	if points <= 0:
		return UiKit.t("No points to spend. They come with levels.")
	if skill(i) >= SKILL_MAX:
		return UiKit.t("%s is already at five stars.") % skill_name(i)
	skills[i] += 1
	points -= 1
	return ""


## Take a point back, only while creating the coach.
func unspend(i: int) -> void:
	if created or skill(i) <= 0:
		return
	if i == int(BACKGROUND_SKILL[background]) and skills[i] <= 1:
		return
	skills[i] -= 1
	points += 1


## XP to go from `l` to `l + 1`.
static func need(l: int) -> int:
	return 40 + 10 * l


func add_xp(n: int) -> int:
	var ups := 0
	xp += maxi(0, n)
	while xp >= need(level):
		xp -= need(level)
		level += 1
		points += 1
		ups += 1
	return ups


# ------------------------------------------------------------------ effects
func training_mult() -> float:
	return 1.0 + 0.05 * float(skill(Skill.TRAINING))


func morale_loss_mult() -> float:
	return 1.0 - 0.10 * float(skill(Skill.MOTIVATION))


func extra_calls() -> int:
	return (1 if skill(Skill.TACTICS) >= 3 else 0) + (1 if skill(Skill.TACTICS) >= 5 else 0)


func business_mult() -> float:
	return 1.0 + 0.05 * float(skill(Skill.BUSINESS))


func recruit_mult() -> float:
	return 1.0 - 0.05 * float(skill(Skill.RECRUITING))


## Where the dilemma deck reads its 1-20 scale from, now the reputation is gone.
func standing_scale() -> int:
	return clampi(level, 1, 20)


# ------------------------------------------------------------------- record
func fought() -> int:
	return wins + draws + losses


func win_rate() -> float:
	var n := fought()
	return 0.0 if n == 0 else float(wins) / float(n)


func record_line() -> String:
	return "%d-%d-%d" % [wins, draws, losses]


func note_result(won: bool, drew: bool) -> void:
	if drew:
		draws += 1
		add_xp(XP_DRAW)
	elif won:
		wins += 1
		add_xp(XP_WIN)
	else:
		losses += 1


func after_division(place: int, _tier: int = 0) -> void:
	if place >= 1 and place <= XP_BY_PLACE.size():
		add_xp(XP_BY_PLACE[place - 1])


func after_cup(left_standing: int) -> void:
	if XP_BY_CUP_EXIT.has(left_standing):
		add_xp(int(XP_BY_CUP_EXIT[left_standing]))


func note_season(promoted: bool, relegated: bool, won_cup: bool) -> void:
	seasons += 1
	if promoted:
		promotions += 1
		add_xp(XP_PROMOTED)
	if relegated:
		relegations += 1
	if won_cup:
		cups += 1


func to_dict() -> Dictionary:
	return {
		"first": first_name, "last": last_name, "name": display_name, "bg": background,
		"face": face, "kit": kit, "beard": beard, "created": created,
		"level": level, "xp": xp, "points": points, "skills": skills.duplicate(),
		"seasons": seasons, "w": wins, "d": draws, "l": losses, "cups": cups,
		"up": promotions, "down": relegations,
	}


static func from_dict(d: Dictionary) -> Coach:
	var c := Coach.new()
	c.first_name = String(d.get("first", ""))
	c.last_name = String(d.get("last", ""))
	c.display_name = String(d.get("name", "Coach"))
	c.background = clampi(int(d.get("bg", 0)), 0, BACKGROUND_NAME.size() - 1)
	c.face = int(d.get("face", 0))
	c.kit = int(d.get("kit", 0))
	c.beard = int(d.get("beard", 0))
	## A SAVE FROM BEFORE THE COACH: not created, and the season asks once.
	c.created = bool(d.get("created", false))
	c.level = maxi(1, int(d.get("level", 1)))
	c.xp = maxi(0, int(d.get("xp", 0)))
	c.points = maxi(0, int(d.get("points", START_POINTS)))
	var sk: Array = d.get("skills", [])
	if sk.size() == 5:
		for i in 5:
			c.skills[i] = clampi(int(sk[i]), 0, SKILL_MAX)
	elif not c.created:
		c.start_fresh(c.background)
	## AN OLD SAVE'S RECORD COUNTS: its wins and draws are XP already earned.
	if not d.has("level"):
		c.add_xp(int(d.get("w", 0)) * XP_WIN + int(d.get("d", 0)) * XP_DRAW)
	c.seasons = int(d.get("seasons", 0))
	c.wins = int(d.get("w", 0))
	c.draws = int(d.get("d", 0))
	c.losses = int(d.get("l", 0))
	c.cups = int(d.get("cups", 0))
	c.promotions = int(d.get("up", 0))
	c.relegations = int(d.get("down", 0))
	return c
