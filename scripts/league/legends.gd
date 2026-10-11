class_name Legends
extends RefCounted
## CLUB LEGENDS ON THE STAFF (Pete, 11 Oct 2026: legends as staff, "start them
## as good if not a little better than normal ones, maybe a boost effect with
## them too").
##
## A man who retires from YOUR club as a legend — a cup won on the eight, a place
## in the Hall, or LEGEND_DOWNS men put down — is remembered, and from the next
## summer he is on the staff market as a captain, at the top of the list:
##   * a GRADE as good as the market's best: 4 stars, 5 with three cups or more;
##   * he TEACHES ONE STAR ABOVE HIS GRADE (TEACH_BONUS), so a five-star legend
##     trains like a six — "a little better than normal";
##   * the BOOST: the day he walks in, the whole squad lifts (ARRIVAL_MORALE) and
##     the town turns out to see him (ARRIVAL_FANS of the room left);
##   * the same price as any captain of his grade.
## Codex's Endgame #1 found retired men make uneven teachers when copied as they
## were; these are set to the market's top instead, so none is a trap.

const LEGEND_DOWNS: int = 40
const TEACH_BONUS: int = 1
const ARRIVAL_MORALE: float = 0.08
const ARRIVAL_FANS: float = 0.03
const OFFERED: int = 2


static func is_legend(s: Season, f: FighterCard) -> bool:
	return f.honors >= 1 or f.downs >= LEGEND_DOWNS or s.world.in_hall(f.display_name)


## Called as a man retires from the player's club.
static func note_retired(s: Season, f: FighterCard) -> void:
	if not is_legend(s, f):
		return
	for l in s.world.legends:
		if String(l.get("name", "")) == f.display_name:
			return
	s.world.legends.append({"name": f.display_name, "role": Tuning.role_of(int(f.pos)),
		"honors": f.honors, "downs": f.downs, "season": s.world.season})


## The legends on this summer's market: the most decorated first, never one who
## is already on the staff, and never in the season he retired.
static func offers(s: Season, taken: Dictionary) -> Array:
	var pool: Array = []
	for l in s.world.legends:
		if taken.has(String(l["name"])) or int(l.get("season", 0)) >= s.world.season:
			continue
		pool.append(l)
	pool.sort_custom(func(a, b): return int(a["honors"]) * 100 + int(a["downs"]) > int(b["honors"]) * 100 + int(b["downs"]))
	var out: Array = []
	for l in pool.slice(0, OFFERED):
		out.append(captain_of(l))
	return out


static func captain_of(l: Dictionary) -> Dictionary:
	var role := int(l["role"])
	var grade := 5 if int(l.get("honors", 0)) >= 3 else 4
	## His trait follows what he was: a man with silverware lifts a room, a man
	## who put people down knows what it takes.
	var t: int = ClubOffice.Trait.MOTIVATOR if int(l.get("honors", 0)) >= 1 else ClubOffice.Trait.EXPERIENCE
	var c := ClubOffice.captain(String(l["name"]), role, (role + 1) % 3, grade, t)
	c["legend"] = true
	return c


## The boost, the day he is hired.
static func arrive(s: Season, c: Dictionary) -> void:
	if not bool(c.get("legend", false)):
		return
	for f in s.club.roster:
		f.morale_shift(ARRIVAL_MORALE)
	s.office.fans += (s.office.fan_cap() - s.office.fans) * ARRIVAL_FANS
	s.office.crowd_came(0)
	s.office.sync_morale(s.club)
