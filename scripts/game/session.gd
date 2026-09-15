class_name Session
extends RefCounted
## The handoff between the season screen and the melee screen.
##
## Godot's usual answer is an autoload, and 06.5 rules those out — `Balance` and
## `Tuning` are `class_name` constant holders precisely so they resolve in
## `--script` runs, where autoloads do not exist. Static vars on a `class_name`
## do the same job for mutable state: one place both scenes can see, no
## SceneTree, no singleton registration, and it still works headless.
##
## It holds exactly two things: the season in progress, and the bout the melee
## screen has been asked to fight. Anything more belongs in Season.

static var season: Season = null

## Set by the season screen before it hands over. Null means the melee screen is
## on its own and should put up the exhibition fixtures, which is what it did
## before there was a season at all and what it still does if you run
## Melee.tscn directly.
static var bout: MeleeSim = null

## Which save slot the season in progress belongs to, so an autosave after every
## event does not have to ask. -1 means an unsaved session — the melee screen run
## on its own, or a test.
static var slot: int = -1

## WHICH BOOK THE RESULT GOES IN. A cup tie and a league fixture build the same
## MeleeSim by design, so the melee screen cannot tell them apart on the way
## back — and posting a cup tie to the league table is the sort of bug that
## looks like a scoring error for a fortnight before anybody finds it.
static var bout_is_cup: bool = false

## WHAT THE FIGHT IS DRESSED AS, captured when the bout is handed over.
##
## It cannot be read off the season from inside the melee screen, because the
## first thing that screen does when the bout ends is post the result — which
## resolves the cup tie and makes `season.mood()` go back to NORMAL. The report
## would then be drawn in a different palette from the fight it is reporting on,
## which reads as the game losing its place.
static var bout_mood: int = 0

## WHICH CUP THE DRAW SCREEN IS SHOWING. Normally null, meaning "the one with a
## tie in front of me" — set only when a screen wants to show a cup that is not
## the pending one, which is what makes the bracket reachable from a finished
## cup as well as a live one.
static var viewing_cup: Cup = null

## WHICH MAN THE FIGHTER SCREEN IS SHOWING. Set by the roster on the way in and
## cleared on the way out — the screen pages left and right from here, so it is
## the current selection rather than a one-shot argument.
static var viewing_fighter: FighterCard = null


static func in_season() -> bool:
	return season != null and bout != null


static func clear_bout() -> void:
	bout = null
	bout_is_cup = false
	## The mood is deliberately NOT cleared here — the report screen is still on
	## screen after the bout is posted and is still part of the occasion.


## Write the season back to its own slot. Called after every event and every
## summer, because a manager game that only saves when you press a button is a
## manager game that loses somebody's season to a phone call.
static func autosave() -> bool:
	if season == null or slot < 0:
		return false
	return SaveGame.save(season, slot)
