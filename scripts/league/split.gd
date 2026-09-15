class_name ClubSplit
extends RefCounted
## THE CLUB SPLITS.
##
## DIRECTION §4, and the document says it plainly: *"Getting fired -> the club
## splits. The signature system. Buhurt clubs fracture constantly. A bad season,
## a bad captain call, favoritism over who goes to Worlds, and half your roster
## walks out and founds a rival club across town that you now have to fight.
## Better than a pink slip: recoverable, generates a rival with a grudge, and
## populates that rival with your own former fighters. If the game has one system
## people talk about, make it this one."*
##
## It replaces getting fired, and it is better than getting fired for a reason
## worth writing down: being sacked ENDS a thing, and this one starts something.
## You keep your job. What you lose is half your squad, and what you gain is a
## club in your own division made of men who know exactly how you train.
##
## WHY IT IS NOT A RANDOM EVENT. Every condition below is something the player
## did, is told about in advance, and can fix:
##
##   THE ROOM     per-man morale, which the roster screen has shown all season.
##   THE RESULTS  a bad finish. Visible from matchday one.
##   THE FAVOUR   men who never got picked. The lineup is the player's own doing.
##
## A club that is winning does not fracture however unhappy it is, and a club
## that is losing does not fracture if the room is sound. It takes both, which is
## the difference between a system and a punishment.

## The room has to be genuinely bad, not merely unhappy. This is the average of
## the men who travel, and the number is the bottom of the band the office
## already calls **Mutinous** — not a threshold of its own.
##
## It was 0.30 for an afternoon, which is a figure I picked because it sounded
## like a lot of unhappiness. `ClubOffice.morale_word()` calls 0.30 "Restless",
## so the screen would have said the room was restless while the rule quietly
## treated it as ready to walk out — a player watching the only number he is
## given, behaving exactly as told, and still losing half his squad without
## warning. The test that caught it asserts the fuse against the WORD rather than
## against a number, which is the only version of this check that could have.
const MORALE_FUSE: float = 0.20
## And the season has to have been bad. Bottom half of the division, or relegated.
## Finishing fourth of eight with a mutinous room is a club with a problem, not a
## club that is about to be two clubs.
const BAD_HALF: float = 0.5
## Never in the first season. There is no grudge to carry a year in, and a player
## who loses half his squad before he has learned the screens has learned nothing
## except that the game is unfair.
const EARLIEST_SEASON: int = 2

## How much of the squad goes. "Half your roster" — and it is a cap rather than a
## target, because who goes is decided by who is actually disaffected.
const TAKES_AT_MOST: float = 0.5
## A club has to be left with a line. Losing so many that you cannot field five
## is not a rival, it is a game over, and this system exists to NOT be that.
##
## WRITTEN OUT RATHER THAN READ OFF `MeleeClub.LINE_SIZE`, and the honest note
## here is about how I spent the twenty minutes before writing it.
##
## Every call into this file came back "Nonexistent function 'fractures' in base
## 'GDScript'" — from a file whose statics the test file was calling successfully
## two lines earlier. I decided that was a parse-order cycle, moved this const
## off MeleeClub, renamed the class, reimported twice, and it kept failing.
##
## It was a PARSE ERROR one function down: `var grievance := 1.0 - f.morale`, on
## an `f` that comes out of an untyped `Array` and therefore has no type to infer
## from. GDScript reports a file that failed to compile as a plain GDScript
## resource, so every static call on it reads as a missing function — the error
## message names the symptom and says nothing about the cause, and I read it as
## evidence for a theory instead of going and looking.
##
## The lesson is the one this project keeps relearning in new clothes: *a
## measurement that cannot separate the good case from the known bad case is not
## evidence.* "Nonexistent function" cannot tell a load cycle from a syntax error
## one line away, so it was never evidence for either. The fix was to read the
## first error rather than the loudest one.
##
## The literal stays, because it is fine and `tests/test_split.gd` now asserts it
## against `MeleeClub.LINE_SIZE` — state it once, and make the duplicate a
## checked one.
const LEAVES_AT_LEAST: int = 5


## IS THE CLUB ABOUT TO GO? All three conditions, read off state the player has
## been looking at all year.
##
## `place` and `field` are the finishing position and the size of the division —
## passed in rather than read off the world, so the rule can be tested without
## building one and so this file has no opinion about how a league is shaped.
static func fractures(morale: float, place: int, field: int, relegated: bool,
		season_no: int) -> bool:
	if season_no < EARLIEST_SEASON:
		return false
	if morale >= MORALE_FUSE:
		return false
	var bad_season: bool = relegated or float(place) > float(field) * BAD_HALF
	return bad_season


## WHO WALKS.
##
## Sorted by how little reason each man has to stay, and that ordering is the
## whole design: the men who go are the men the player left out and the men he
## let get bitter. A roster that lost its five best is a dice roll; a roster that
## lost the seven men who never got picked is a consequence.
##
## `picked` is the set of men who have actually been fighting — the line and the
## bench. A man who travels every week has a reason to stay even when the club is
## miserable; a man who has not fought since March does not.
static func who_walks(roster: Array, picked: Array) -> Array:
	var candidates: Array = []
	for f in roster:
		## LOYAL DOES NOT WALK. Not "is less likely to" — he is not a candidate at
		## all, because the whole value of the trait is knowing, in the summer the
		## club fractures, exactly who is still going to be there. A probability
		## would give you a man who is probably loyal, which is nobody.
		if FighterTrait.flag(f.trait_id, "no_split"):
			continue
		var grievance: float = 1.0 - f.morale
		## FAVOURITISM, which is the condition the direction document names and
		## the only one that is purely the player's doing. A man who never gets on
		## the line is carrying something no morale number quite captures.
		if not picked.has(f):
			grievance += 0.45
		candidates.append({"man": f, "grievance": grievance})
	candidates.sort_custom(func(a, b): return float(a["grievance"]) > float(b["grievance"]))

	## Only genuinely disaffected men actually go. The cap is half the squad, but
	## a club where only three men are unhappy loses three — the number is an
	## outcome, not a quota.
	var room: int = mini(int(floor(float(roster.size()) * TAKES_AT_MOST)),
		maxi(0, roster.size() - LEAVES_AT_LEAST))
	var out: Array = []
	for c in candidates:
		if out.size() >= room:
			break
		if float(c["grievance"]) < 1.0 - MORALE_FUSE:
			break
		out.append(c["man"])
	return out


## THE NAME OF THE CLUB ACROSS TOWN. Built off the club they left, because that is
## what a breakaway is called — it carries the old name and an argument about who
## the real one is.
const BREAKAWAY_WORDS: Array[String] = [
	"Free Company", "Dissenters", "Old Guard", "Exiles", "Breakaway",
	"Second Company", "Remnant", "Splinters",
]


static func name_for(parent_name: String, rng: RandomNumberGenerator) -> String:
	var first: String = parent_name.split(" ")[0]
	return "%s %s" % [first, BREAKAWAY_WORDS[rng.randi() % BREAKAWAY_WORDS.size()]]


static func short_for(nm: String) -> String:
	var out := ""
	for part in nm.split(" "):
		if part.length() > 0:
			out += part.substr(0, 1).to_upper()
	return out.substr(0, 3)
