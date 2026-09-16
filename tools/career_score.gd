extends SceneTree
## ONE NUMBER FOR A WHOLE CAREER, so a balance sweep has something to sort by.
##
##   godot --headless --path . --script res://tools/career_score.gd -- [seeds] [years]
##
## Pete, 15 Sep 2026: *"Target is a 10 season Championship for the average
## player."* That sentence has to become a measurement before any sweep means
## anything, and three words in it each needed deciding:
##
##   CHAMPIONSHIP   finishing FIRST in the National Division. Not a Worlds berth
##                  and not a cup: the pyramid is the spine of this game and its
##                  top rung is the thing a career is climbing toward. Worlds is
##                  reported beside it because it is the better story, but the
##                  league title is the target.
##   10 SEASONS     seasons ELAPSED when it first happens, so "season 10" means a
##                  career that ends its tenth year as champion. A club that
##                  never gets there scores one season past the window — see
##                  `MISSED`, which took two attempts to get right.
##   AVERAGE PLAYER `ProbeManager` with `youth` off: the obvious moves in the
##                  obvious order. The youth manager is the good player and gets
##                  its own row, because the gap between them is the headroom a
##                  skilled player has and the target is not supposed to need it.
##
## Everything else this prints is diagnosis for when the score moves and nobody
## knows why.
## WHAT "NEVER" SCORES, and it is the window rather than a big number.
##
## It was 99. A mean over five careers then reads 81.0 when one of them wins in
## season nine and 81.2 when it wins in ten — so a single career moving by one
## season outweighed two other careers ceasing to reach the top division at all,
## and `tools/tune.py` duly took that trade on its first pass. **A "never"
## encoded as a big number does not mean never; it means a number so large it
## drowns everything measured beside it.** One past the window says exactly what
## was observed: it did not happen in the time we watched.
static var MISSED: int = 15


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: int = int(args[0]) if args.size() > 0 else 3
	var years: int = int(args[1]) if args.size() > 1 else 14
	## THE SEED BASE, so the same settings can be scored on a DIFFERENT set of
	## worlds. That is the only way to know what a real effect looks like: run the
	## game unchanged against several bases and the spread between them is the
	## noise floor. Anything a sweep reports that is smaller than that spread is
	## the dice, not the change. See `tools/noise.sh`.
	var base: int = int(args[2]) if args.size() > 2 else 4242
	MISSED = years + 1
	var out := run(seeds, years, false, base)
	var good := run(seeds, years, true, base)
	## ONE LINE, MACHINE-READABLE, because a sweep driver parses this and a human
	## reads the same row. Two formats would be two things to keep in step.
	print("SCORE title=%.1f t1=%.1f t2=%.1f t3=%.1f tier=%.2f power=%.1f cc=%.1f worlds=%.2f youth_title=%.1f youth_t3=%.1f"
		% [out["title"], out["t1"], out["t2"], out["t3"], out["tier"],
			out["power"], out["cc"], out["worlds"], good["title"], good["t3"]])
	quit(0)


static func run(seeds: int, years: int, youth: bool, base: int = 4242) -> Dictionary:
	MISSED = years + 1
	var title := 0.0
	var rung := [0.0, 0.0, 0.0]
	var tier := 0.0
	var power := 0.0
	var cc := 0.0
	var worlds := 0.0
	for i in seeds:
		var r := one(base + i * 7919, years, youth)
		title += float(r["title"])
		for k in 3:
			rung[k] += float(r["rung"][k])
		tier += float(r["tier"])
		power += float(r["power"])
		cc += float(r["cc"])
		worlds += float(r["worlds"])
	var n := float(maxi(1, seeds))
	return {"title": title / n, "t1": rung[0] / n, "t2": rung[1] / n,
		"t3": rung[2] / n, "tier": tier / n, "power": power / n, "cc": cc / n,
		"worlds": worlds / n}


## ONE CAREER. Returns the season it first won the National Division, the season
## it first REACHED it, and where it finished up.
static func one(seed_v: int, years: int, youth: bool) -> Dictionary:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var m := ProbeManager.new()
	m.youth = youth
	var title := MISSED
	## THE SEASON EACH RUNG WAS FIRST REACHED. A career that never sees National
	## scores 99 on the title and says NOTHING about whether it was close — and a
	## sweep with no gradient is a sweep that cannot point anywhere. These three
	## give one: a change that gets a club to the State League a season earlier
	## shows up here long before it shows up in a championship.
	var rung := [MISSED, MISSED, MISSED]
	var worlds := 0
	var bank := 0.0
	for y in years:
		m.winter(s)
		m.season(s)
		var t := s.world.player_tier()
		for k in 3:
			if t >= k + 1 and int(rung[k]) == MISSED:
				rung[k] = y + 1
		## THE TABLE IS READ BEFORE THE ROLL OVER, because `roll_over` promotes
		## everybody out of the division the player just finished in and the row
		## he is being judged on goes with it.
		if t >= League.TIERS.size() - 1 and s.world.player_position() == 1 \
				and title == MISSED:
			title = y + 1
		bank += float(s.office.credits)
		s.roll_over()
		worlds += int(s.world.clubs[s.world.player_club].get("titles", 0)) - worlds
	return {"title": title, "rung": rung, "tier": s.world.player_tier(),
		"power": s.club.power(), "cc": bank / float(maxi(1, years)),
		"worlds": worlds}
