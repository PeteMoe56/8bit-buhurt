class_name Chalkboard
extends RefCounted
## THE CHALKBOARD — the player's own formations and plays.
##
## Pete, 10 Sep 2026: *"I want the players to be able to create their own
## formations / Plays… You'll have to use credits to unlock up to 4 of each.
## Chalkboard - Formation will let the player position fighters behind the 15%
## line in any formation they want… Chalkboard - Plays will let the player draw
## the routes he wants his fighters to initially take. Plays can be check marked
## to be Formation dependent or universal."*
##
## WHERE THIS SITS ON THE LADDER. Roster beats thumb beats tactics. A drawn play
## is the TACTICS rung: it is worth something, it is worth less than reading the
## fight live, and it is worth much less than having better men. So a play is
## routes and nothing else — no menu, no target, no stat bonus. It sets the men
## walking somewhere clever and then gives them back to the AI. Everything that
## makes thumb play better than a plan — the prompts, the override of a man's
## recovery, the live re-aim — stays thumb-only, deliberately.
##
## IDS, NOT INDICES. A play bound to a formation stores that formation's id. If
## it stored the index, deleting the first formation would silently re-point
## every play after it at the wrong shape — the class of bug you only find when
## a player's saved plan starts doing something else.

## Four of each, which is Pete's number. The fifth slot is not for sale.
const SLOTS: int = 4
## Escalating, so the fourth is a real decision rather than a formality. In the
## same currency and the same order of magnitude as a facility level, because
## the Chalkboard competes with the Clubhouse for the same small pile.
const SLOT_COST := [3, 5, 7, 9]

## The one id space the dropdown, the save file and the sim all speak. Built-in
## shapes keep their Tuning.Formation values; anything drawn starts above them.
const CUSTOM_BASE: int = 100
## A play that runs whatever the line is set up in.
const UNIVERSAL: int = -1

var formation_slots: int = 0
var play_slots: int = 0
var formations: Array[Dictionary] = []    ## {id, name, spots:[5 Vector2]}
var plays: Array[Dictionary] = []         ## {name, routes:[5 Array], formation}
var _next_id: int = CUSTOM_BASE


# ------------------------------------------------------------------ unlocking
func slot_cost(kind_slots: int) -> int:
	return SLOT_COST[kind_slots] if kind_slots < SLOTS else 0


func unlock_formation(office: ClubOffice) -> String:
	return _unlock(office, true)


func unlock_play(office: ClubOffice) -> String:
	return _unlock(office, false)


func _unlock(office: ClubOffice, is_formation: bool) -> String:
	var have: int = formation_slots if is_formation else play_slots
	var what: String = "formation" if is_formation else "play"
	if have >= SLOTS:
		return "You already have all %d %s slots." % [SLOTS, what]
	var cost := slot_cost(have)
	if office.credits < cost:
		return "That costs %d CC and you have %d." % [cost, office.credits]
	office.spend(cost, ClubOffice.LINE_CLUB)
	if is_formation:
		formation_slots += 1
	else:
		play_slots += 1
	return ""


# ---------------------------------------------------------------- formations
## Save a drawn shape. `index` is a slot: an existing one is overwritten, the
## next free one is filled. Legality is Tuning's call, not ours — the same
## function that vets the built-in shapes vets these.
func save_formation(index: int, nm: String, spots: Array) -> String:
	if index < 0 or index >= formation_slots:
		return "That formation slot is not unlocked yet."
	var bad := Tuning.formation_legal(spots)
	if bad != "":
		return bad
	nm = _clean(nm)
	if nm == "":
		return "Give the formation a name."
	var copy: Array = []
	for v in spots:
		copy.append(Vector2(v))
	if index < formations.size():
		formations[index]["name"] = nm
		formations[index]["spots"] = copy
	else:
		formations.append({"id": _next_id, "name": nm, "spots": copy})
		_next_id += 1
	return ""


## Refused while a play is drawn for it. Unbinding the play silently would hand
## the player a plan that no longer means what he drew, and quietly wrong is
## worse than loudly refused.
func delete_formation(index: int) -> String:
	if index < 0 or index >= formations.size():
		return "No such formation."
	var id := int(formations[index]["id"])
	var bound: Array = []
	for p in plays:
		if int(p["formation"]) == id:
			bound.append(String(p["name"]))
	if not bound.is_empty():
		return "%s is what %s %s drawn for." % [
			String(formations[index]["name"]), ", ".join(bound),
			"is" if bound.size() == 1 else "are"]
	formations.remove_at(index)
	return ""


func formation_by_id(id: int) -> Dictionary:
	for f in formations:
		if int(f["id"]) == id:
			return f
	return {}


## The five spots behind any id — a drawn shape or a built-in one. Everything
## that needs a formation goes through here so the two kinds cannot drift.
func spots_for(id: int) -> Array:
	var f := formation_by_id(id)
	if not f.is_empty():
		return f["spots"]
	if Tuning.FORMATIONS.has(id):
		return Tuning.FORMATIONS[id]["spots"]
	return Tuning.FORMATIONS[Tuning.Formation.TWO_ONE_TWO]["spots"]


func formation_name(id: int) -> String:
	var f := formation_by_id(id)
	if not f.is_empty():
		return String(f["name"])
	if Tuning.FORMATIONS.has(id):
		return String(Tuning.FORMATIONS[id]["name"])
	return "?"


## What the corner's formation dropdown lists: the three shapes everyone has,
## then whatever this club has drawn.
func formation_choices() -> Array:
	var out: Array = []
	for k in Tuning.FORMATIONS:
		out.append({"id": int(k), "name": String(Tuning.FORMATIONS[k]["name"]), "custom": false})
	for f in formations:
		out.append({"id": int(f["id"]), "name": String(f["name"]), "custom": true})
	return out


# --------------------------------------------------------------------- plays
## `formation` is UNIVERSAL or a formation id. Pete's check mark, stored as the
## thing it points at rather than as a bool plus a separate field.
func save_play(index: int, nm: String, routes: Array, formation: int = UNIVERSAL) -> String:
	if index < 0 or index >= play_slots:
		return "That play slot is not unlocked yet."
	var bad := Tuning.play_legal(routes)
	if bad != "":
		return bad
	nm = _clean(nm)
	if nm == "":
		return "Give the play a name."
	if formation != UNIVERSAL and formation_by_id(formation).is_empty() \
			and not Tuning.FORMATIONS.has(formation):
		return "That play is tied to a formation you no longer have."
	var copy: Array = []
	for r in routes:
		var leg: Array[Vector2] = []
		for v in r:
			leg.append(Vector2(v))
		copy.append(leg)
	if index < plays.size():
		plays[index]["name"] = nm
		plays[index]["routes"] = copy
		plays[index]["formation"] = formation
	else:
		plays.append({"name": nm, "routes": copy, "formation": formation})
	return ""


func delete_play(index: int) -> String:
	if index < 0 or index >= plays.size():
		return "No such play."
	plays.remove_at(index)
	return ""


## Every play you may actually call with this line set up the way it is: the
## universal ones, plus the ones drawn for this exact shape.
func plays_for(formation_id: int) -> Array:
	var out: Array = []
	for i in plays.size():
		var p: Dictionary = plays[i]
		if int(p["formation"]) == UNIVERSAL or int(p["formation"]) == formation_id:
			out.append({"index": i, "name": String(p["name"]),
				"routes": p["routes"], "universal": int(p["formation"]) == UNIVERSAL})
	return out


# ---------------------------------------------------------------- favorites
## THE FOUR ON THE CORNER — Pete, 13 Sep 2026, in the spec for the between-rounds
## screen: *"on the right side you have your four favorited plays."*
##
## The corner has been showing four calls since it was built and nothing let a
## player choose which four; it fell back to whatever came out of the live shape.
## This is the list, and it lives on the board because the board is the thing a
## club owns about how it fights and the thing that already saves.
##
## KEYED BY NAME, NOT BY INDEX, AND THAT IS THE WHOLE DESIGN.
##
## `plays_for` hands out the play's position in `plays`, and `delete_play` uses
## `remove_at`, so every index after a deleted play shifts down by one. A
## favorite holding index 3 would keep working, keep looking fine, and quietly
## be a different play — the worst kind of bug, because nothing ever errors. A
## name can go stale, and a stale favorite resolves to nothing and is dropped,
## which is a failure you can see.
##
## Two plays under one name in one shape is possible and the first wins. That is
## a naming problem the player can see and fix, not a silent substitution.
const MAX_FAVORITES: int = 4

## [{shape: int, kind: "push"|"play", key: String}], in the order they show.
var favorites: Array = []


static func fav_key(kind: String, id: int, name_: String) -> String:
	return str(id) if kind == "push" else name_


func is_favorite(shape_id: int, kind: String, key: String) -> bool:
	for f in favorites:
		if int(f["shape"]) == shape_id and String(f["kind"]) == kind \
				and String(f["key"]) == key:
			return true
	return false


## Star it, or take the star off. Refuses past four rather than silently pushing
## the oldest out — a list that quietly forgets what you put in it is a list you
## stop trusting, and four is a decision the player should have to make.
func toggle_favorite(shape_id: int, kind: String, key: String) -> String:
	for i in favorites.size():
		var f: Dictionary = favorites[i]
		if int(f["shape"]) == shape_id and String(f["kind"]) == kind \
				and String(f["key"]) == key:
			favorites.remove_at(i)
			return ""
	if favorites.size() >= MAX_FAVORITES:
		return "Four favorites is the lot. Take one off first."
	favorites.append({"shape": shape_id, "kind": kind, "key": key})
	return ""


## MOVE ONE UP THE LIST. Returns "" if it moved, a sentence if it could not.
##
## Four slots and no way to order them was the one thing four slots wanted: the
## corner offers them in this order, so the first is the one the player reaches
## for under a clock, and until now that was whichever he happened to star first.
##
## A SWAP RATHER THAN A DRAG. A drag needs a pointer the corner does not have
## time for and a gesture the screen has no room to teach; two taps on a list of
## four is the same job in the same number of seconds, and it works on a phone
## with one thumb.
##
## The list is pruned by `live_favorites()` whenever it is read, so an index
## handed in from a screen is an index into what that screen just drew. This
## takes the index and checks it rather than trusting it, because the screen and
## the model are separated by a frame in which a play could have been deleted.
func promote_favorite(i: int) -> String:
	if i <= 0 or i >= favorites.size():
		return "" if i == 0 else "That one is not on the list."
	var moved: Dictionary = favorites[i]
	favorites[i] = favorites[i - 1]
	favorites[i - 1] = moved
	return ""


## And down, so the list can be worked from either end. A list you can only
## walk one way is a list you have to empty to reorder.
func demote_favorite(i: int) -> String:
	if i < 0 or i >= favorites.size():
		return "That one is not on the list."
	if i == favorites.size() - 1:
		return ""
	var moved: Dictionary = favorites[i]
	favorites[i] = favorites[i + 1]
	favorites[i + 1] = moved
	return ""


## THE ONES THAT STILL POINT AT SOMETHING, pruned in place. A play deleted from
## the board takes its favorite with it, and a drawn formation deleted takes
## everything starred out of it — but only when this is asked, so deleting a
## play does not have to know what a favorite is.
func live_favorites() -> Array:
	var out: Array = []
	var keep: Array = []
	for f in favorites:
		var shape_id := int(f["shape"])
		if String(f["kind"]) == "play":
			var found := false
			for p in plays_for(shape_id):
				if String(p["name"]) == String(f["key"]):
					found = true
					break
			if not found:
				continue
		elif not _shape_exists(shape_id):
			continue
		keep.append(f)
		out.append(f)
	favorites = keep
	return out


func _shape_exists(shape_id: int) -> bool:
	for c in formation_choices():
		if int(c["id"]) == shape_id:
			return true
	return false


func routes_of(index: int) -> Array:
	if index < 0 or index >= plays.size():
		return []
	return plays[index]["routes"]


## An empty route per man, which is what both editors start from.
static func blank_routes() -> Array:
	var out: Array = []
	for _i in 5:
		out.append([] as Array[Vector2])
	return out


static func _clean(nm: String) -> String:
	return nm.strip_edges().substr(0, 18)


# -------------------------------------------------------------------- saving
func to_dict() -> Dictionary:
	## Vector2 survives store_var, but writing floats keeps the save readable and
	## keeps it from depending on how Godot happens to pack a Vector2 this year.
	var fs: Array = []
	for f in formations:
		var pts: Array = []
		for v in f["spots"]:
			pts.append([float(v.x), float(v.y)])
		fs.append({"id": int(f["id"]), "name": String(f["name"]), "spots": pts})
	var ps: Array = []
	for p in plays:
		var rs: Array = []
		for r in p["routes"]:
			var leg: Array = []
			for v in r:
				leg.append([float(v.x), float(v.y)])
			rs.append(leg)
		ps.append({"name": String(p["name"]), "routes": rs,
			"formation": int(p["formation"])})
	return {
		"formation_slots": formation_slots, "play_slots": play_slots,
		"next_id": _next_id, "formations": fs, "plays": ps,
		"favorites": favorites.duplicate(true),
	}


static func from_dict(d: Dictionary) -> Chalkboard:
	var c := Chalkboard.new()
	c.formation_slots = int(d.get("formation_slots", 0))
	c.play_slots = int(d.get("play_slots", 0))
	c._next_id = int(d.get("next_id", CUSTOM_BASE))
	for f in d.get("formations", []):
		var pts: Array = []
		for v in f["spots"]:
			pts.append(Vector2(float(v[0]), float(v[1])))
		c.formations.append({"id": int(f["id"]), "name": String(f["name"]), "spots": pts})
	for p in d.get("plays", []):
		var rs: Array = []
		for r in p["routes"]:
			var leg: Array[Vector2] = []
			for v in r:
				leg.append(Vector2(float(v[0]), float(v[1])))
			rs.append(leg)
		c.plays.append({"name": String(p["name"]), "routes": rs,
			"formation": int(p.get("formation", UNIVERSAL))})
	## A save written before a slot was ever unlocked, or hand-edited, must not
	## leave more drawn shapes than slots to hold them.
	c.formation_slots = maxi(c.formation_slots, c.formations.size())
	c.play_slots = maxi(c.play_slots, c.plays.size())
	## READ DEFENSIVELY. A save from before favorites existed has none, and a
	## hand-edited one could have anything — every field is coerced rather than
	## trusted, and over-long lists are cut to the cap here rather than being
	## allowed in and refused later.
	for f in d.get("favorites", []):
		if c.favorites.size() >= MAX_FAVORITES:
			break
		if not (f is Dictionary) or not f.has("shape") or not f.has("kind"):
			continue
		c.favorites.append({"shape": int(f["shape"]),
			"kind": "push" if String(f["kind"]) == "push" else "play",
			"key": String(f.get("key", ""))})
	return c
