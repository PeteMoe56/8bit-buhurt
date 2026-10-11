class_name HostEvents
extends RefCounted
## THINGS THAT HAPPEN AT YOUR OWN SHOW (Pete, 9 Oct 2026: hosting your own
## shows "should carry randomized events (risk)"). Codex's Endgame #1 found
## every hosted show turned a profit, so hosting was never a gamble. One roll
## per show, when the money is counted: about four shows in ten are ordinary,
## the rest go better or worse than the budget said.

## {id, weight, title, line, gate (multiplier), cc, fans (share of the room left)}
const TABLE := [
	{"id": "", "w": 40, "title": "", "line": "", "gate": 1.0, "cc": 0, "fans": 0.0},
	{"id": "rain", "w": 14, "title": "Rain all weekend",
		"line": "It rained from Friday to Sunday. Half the walk-up stayed home.", "gate": 0.6, "cc": 0, "fans": 0.0},
	{"id": "marshal", "w": 10, "title": "A marshal did not show",
		"line": "A marshal pulled out on Friday night. The stand-in cost you.", "gate": 1.0, "cc": -4, "fans": 0.0},
	{"id": "fence", "w": 8, "title": "The rail came down",
		"line": "A bullrush took out a section of the rail. Repairs before the final.", "gate": 1.0, "cc": -3, "fans": 0.0},
	{"id": "buzz", "w": 12, "title": "Word got round",
		"line": "Word got round town and the stands filled up on Sunday.", "gate": 1.35, "cc": 0, "fans": 0.0},
	{"id": "sponsor", "w": 8, "title": "A sponsor for the trophy",
		"line": "A local business put its name on the trophy and paid for the privilege.", "gate": 1.0, "cc": 5, "fans": 0.0},
	{"id": "tv", "w": 8, "title": "Local TV came",
		"line": "Local TV filmed the final. The town is talking about your club.", "gate": 1.0, "cc": 0, "fans": 0.05},
]


## The show's roll, the same every time it is asked for this show.
static func roll(s: Season, e: ClubEvent) -> Dictionary:
	var total := 0
	for r in TABLE:
		total += int(r["w"])
	var pick := absi(hash([s.seed_value, e.due, "host-event"])) % total
	for r in TABLE:
		pick -= int(r["w"])
		if pick < 0:
			return r
	return TABLE[0]


## The words, translated. Literal keys so the string sweep sees each one.
static func words(id: String) -> Array:
	match id:
		"rain": return [UiKit.t("Rain all weekend"), UiKit.t("It rained from Friday to Sunday. Half the walk-up stayed home.")]
		"marshal": return [UiKit.t("A marshal did not show"), UiKit.t("A marshal pulled out on Friday night. The stand-in cost you.")]
		"fence": return [UiKit.t("The rail came down"), UiKit.t("A bullrush took out a section of the rail. Repairs before the final.")]
		"buzz": return [UiKit.t("Word got round"), UiKit.t("Word got round town and the stands filled up on Sunday.")]
		"sponsor": return [UiKit.t("A sponsor for the trophy"), UiKit.t("A local business put its name on the trophy and paid for the privilege.")]
		"tv": return [UiKit.t("Local TV came"), UiKit.t("Local TV filmed the final. The town is talking about your club.")]
	return ["", ""]
