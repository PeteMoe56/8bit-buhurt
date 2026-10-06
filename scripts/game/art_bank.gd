class_name ArtBank
## EVERY PICTURE THE GAME WILL EVER LOAD, in one table.
##
## Pete, 10 Sep 2026: *"Let's not use your art for any of this, just
## placeholders. I'll get ChatGPT to do that work."* So this file does not draw
## anything and does not contain any art. It is the socket the art plugs into.
##
## THE RULE IS THAT A MISSING FILE IS NORMAL. Every slot has a primitive
## fallback already drawn by its screen, and `ResourceLoader.exists` keeps a
## missing file from printing an engine error sixty times a second. Today every
## slot is empty and the game is complete; drop a file at the expected path and
## it appears with no code touched and nothing rebuilt.
##
## ONE TABLE, NOT SIX LOADERS. The arena grew its own private cache and its own
## private path-builder, and a second screen wanting art would have grown a
## third. `docs/ART.md` is generated from this table, so the spec cannot drift
## from what the code actually looks for — the same reason the credits screen
## reads `Audio.LICENSED`.

const DIR := "res://art/"

## `size` is the box the game draws it into, at 960x540. Anything at the same
## proportion works and looks better on a large screen; anything else is
## letterboxed rather than stretched, because a stretched shield is a shield
## nobody drew.
## Both portrait layers share one canvas — declared above `SLOTS` because the
## dictionary uses it, and this project has already lost an afternoon to a const
## that was resolved later than the thing reading it.
const PORTRAIT_SIZE := Vector2(64, 64)

const SLOTS := {
	"arena_0": {"path": "arena/arena_0.png", "size": Vector2(520, 300),
		"about": "Back field — 40 people, a rope and a hedge."},
	"arena_1": {"path": "arena/arena_1.png", "size": Vector2(520, 300),
		"about": "Club gym — 120, indoors, mats against the wall."},
	"arena_2": {"path": "arena/arena_2.png", "size": Vector2(520, 300),
		"about": "Fenced ground — 400, proper barriers, some seating."},
	"arena_3": {"path": "arena/arena_3.png", "size": Vector2(520, 300),
		"about": "Sports hall — 1,200, a real roof and real lights."},
	"arena_4": {"path": "arena/arena_4.png", "size": Vector2(520, 300),
		"about": "Arena — 4,000, tiered stands, a scoreboard."},
	"arena_5": {"path": "arena/arena_5.png", "size": Vector2(520, 300),
		"about": "National Arena — 12,000, the biggest room in the game."},

	## WHERE SOMEBODY ELSE PLAYS — Pete, 14 Sep 2026: *"we need to make arenas for
	## home, away, and tournament games."*
	##
	## TWO PIECES AND NOT TWELVE, and that is a budget decision with a reason. The
	## player builds his own ground through six tiers and looks at it all season;
	## he sees the other club's for the length of a splash screen. One away ground
	## and one tournament ground carry every fixture that is not his own, and the
	## club's own colors and badge on top of them are what make an away day at
	## Harrow look different from an away day at Yarrow.
	"venue_away": {"path": "venue/away.png", "size": Vector2(960, 540),
		"about": "Somebody else's ground, from the tunnel mouth. Their banners, "
			+ "their crowd, your five walking in. Read at a glance as NOT YOURS: "
			+ "colder light, the stands on the far side full and the near side "
			+ "backs-to-camera."},
	"venue_neutral": {"path": "venue/neutral.png", "size": Vector2(960, 540),
		"about": "Tournament ground — a cup or the Worlds. Bunting, a federation "
			+ "banner, lists roped off in a row and a marshal's table. Nobody's "
			+ "home: no club colors anywhere in it."},
	## And the home splash is the club's own `arena_0..5` reused at full frame,
	## which is why there is no `venue_home` here — a third piece of art for the
	## ground the player has already bought and already looks at would be the
	## same room drawn twice.

	## THE FIGHTING SURFACE, and the one that matters most — it is under the
	## player's eyes for three rounds of up to two minutes each.
	"list_surface": {"path": "list/surface.png", "size": Vector2(701, 369),
		"about": "The list floor, rail to rail. Seen from directly above."},
	"list_ground": {"path": "list/ground.png", "size": Vector2(960, 540),
		"about": "What surrounds the list — grass, boards, dirt. Tiles or fills."},

	## THE PORTRAIT LAYERS. Four harnesses and sixteen heads, every one on the
	## same 64×64 canvas — see the block under this dictionary for why.
	"harness_0": {"path": "fighter/harness_0.png", "size": PORTRAIT_SIZE,
		"about": "kit-bash brigandine and an open gorget — borrowed, mismatched, does the job."},
	"harness_1": {"path": "fighter/harness_1.png", "size": PORTRAIT_SIZE,
		"about": "Transitional coat-of-plates, mail voiders, rounded pauldrons."},
	"harness_2": {"path": "fighter/harness_2.png", "size": PORTRAIT_SIZE,
		"about": "Gothic plate — fluted, spiked, big asymmetric pauldrons."},
	"harness_3": {"path": "fighter/harness_3.png", "size": PORTRAIT_SIZE,
		"about": "Milanese export plate — smooth, heavy, rounded, large besagews."},
	"head_00": {"path": "fighter/head_00.png", "size": PORTRAIT_SIZE,
		"about": "Head 0 of 16 — one man, no harness."},
	"head_01": {"path": "fighter/head_01.png", "size": PORTRAIT_SIZE,
		"about": "Head 1 of 16 — one man, no harness."},
	"head_02": {"path": "fighter/head_02.png", "size": PORTRAIT_SIZE,
		"about": "Head 2 of 16 — one man, no harness."},
	"head_03": {"path": "fighter/head_03.png", "size": PORTRAIT_SIZE,
		"about": "Head 3 of 16 — one man, no harness."},
	"head_04": {"path": "fighter/head_04.png", "size": PORTRAIT_SIZE,
		"about": "Head 4 of 16 — one man, no harness."},
	"head_05": {"path": "fighter/head_05.png", "size": PORTRAIT_SIZE,
		"about": "Head 5 of 16 — one man, no harness."},
	"head_06": {"path": "fighter/head_06.png", "size": PORTRAIT_SIZE,
		"about": "Head 6 of 16 — one man, no harness."},
	"head_07": {"path": "fighter/head_07.png", "size": PORTRAIT_SIZE,
		"about": "Head 7 of 16 — one man, no harness."},
	"head_08": {"path": "fighter/head_08.png", "size": PORTRAIT_SIZE,
		"about": "Head 8 of 16 — one man, no harness."},
	"head_09": {"path": "fighter/head_09.png", "size": PORTRAIT_SIZE,
		"about": "Head 9 of 16 — one man, no harness."},
	"head_10": {"path": "fighter/head_10.png", "size": PORTRAIT_SIZE,
		"about": "Head 10 of 16 — one man, no harness."},
	"head_11": {"path": "fighter/head_11.png", "size": PORTRAIT_SIZE,
		"about": "Head 11 of 16 — one man, no harness."},
	"head_12": {"path": "fighter/head_12.png", "size": PORTRAIT_SIZE,
		"about": "Head 12 of 16 — one man, no harness."},
	"head_13": {"path": "fighter/head_13.png", "size": PORTRAIT_SIZE,
		"about": "Head 13 of 16 — one man, no harness."},
	"head_14": {"path": "fighter/head_14.png", "size": PORTRAIT_SIZE,
		"about": "Head 14 of 16 — one man, no harness."},
	"head_15": {"path": "fighter/head_15.png", "size": PORTRAIT_SIZE,
		"about": "Head 15 of 16 — one man, no harness."},
	## THE FIGHTER ON THE LIST (6 Oct 2026, the first sprite in). A colour-keyed
	## mask, not finished artwork: `FighterArt` swaps the nine key colours for the
	## club's own kit, so one drawing serves every club. Facing right; the game
	## mirrors it. Drawn at ×2, feet on the bottom row.
	"body_idle": {"path": "fighter/body_idle.png", "size": Vector2(24, 32),
		"about": "The fighter standing, guard up — key colours only, feet on the bottom row."},
	"body_idle_polearm": {"path": "fighter/body_idle_polearm.png", "size": Vector2(24, 32),
		"about": "The same man standing with a polearm — drawn for every POLEARM card."},
}


# ---------------------------------------------------------------- portraits
## A FACE FOR EVERY MAN, FROM TWENTY PICTURES.
##
## A roster of thirteen, thirteen clubs in a division and eight divisions is
## somewhere over a thousand fighters in a save. Nobody is drawing a thousand
## portraits, and a game that draws the same one on all of them has not added a
## portrait, it has added a decoration.
##
## So a portrait is TWO LAYERS on one canvas: a harness and a head. Sixteen heads
## against four harnesses is sixty-four men from twenty images, and the twenty
## are a weekend of prompting rather than a commission.
##
## BOTH LAYERS ARE THE SAME 64×64 CANVAS, which is the decision that makes this
## survivable. The alternative — a head drawn at its own size and positioned
## against an anchor point — means every generated head has to agree with every
## generated harness about where a neck is, and an image model will not do that
## reliably twice in a row. One canvas, drawn in the right place, composited with
## a straight overlay and no arithmetic at all.
const HARNESS_COUNT: int = 4
const HEAD_COUNT: int = 16

## THE HARNESS IS NOT RANDOM — it is read off how good the man is.
##
## Constraint 05.1 is that the art is *load-bearing rather than decorative*, and
## this is where a portrait earns that: the four harnesses are four real historical
## grades of kit, in the order a club can afford them, so a scruffy man in a
## kit-bash brigandine LOOKS like a Backyard fighter and a man in Milanese plate
## looks like he belongs at Worlds. The player reads a squad's quality off the
## cards before he reads a single number.
const HARNESS_BANDS: Array[int] = [45, 58, 72]


static func harness_for(rating: int) -> int:
	var i := 0
	for edge in HARNESS_BANDS:
		if rating >= edge:
			i += 1
	return mini(i, HARNESS_COUNT - 1)


## THE HEAD IS the man, and has to be stable for his whole career — he ages,
## retires and turns up in the Hall of Fame, and a face that changes when he is
## re-signed is not a face. Hashed off the name and number, which together are
## unique on a roster and never change.
static func head_for(nm: String, number: int) -> int:
	return absi(hash("%s#%d" % [nm, number])) % HEAD_COUNT


static func portrait_slots(rating: int, nm: String, number: int) -> Array[String]:
	return [
		"harness_%d" % harness_for(rating),
		"head_%02d" % head_for(nm, number),
	]


## DRAW ONE, and say whether anything was actually drawn — every caller has a
## primitive fallback and none of them should draw it under a real portrait.
##
## The harness goes down first and the head on top, which is the order a person
## is assembled in and also the order that lets a great helm hide a face.
static func portrait(ci: CanvasItem, box: Rect2, rating: int, nm: String,
		number: int) -> bool:
	var drew := false
	for id in portrait_slots(rating, nm, number):
		var tex := get_slot(id)
		if tex == null:
			continue
		ci.draw_texture_rect(tex, fit(tex, box), false)
		drew = true
	return drew


## Loaded once and kept. A texture that is absent stays absent for the session,
## which is correct: art does not appear while the game is running.
static var _cache := {}


static func get_slot(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var tex: Texture2D = null
	var d: Dictionary = SLOTS.get(id, {})
	var rel := String(d.get("path", ""))
	if rel != "":
		var path := DIR + rel
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
	_cache[id] = tex
	return tex


static func has(id: String) -> bool:
	return get_slot(id) != null


## FIT, NEVER STRETCH. Returns the rect to draw a texture into so it fills the
## box on its long side and centers on the other — a picture at the wrong
## proportion gets bars, not a squash.
static func fit(tex: Texture2D, box: Rect2) -> Rect2:
	if tex == null:
		return box
	var ts := Vector2(tex.get_width(), tex.get_height())
	if ts.x <= 0.0 or ts.y <= 0.0:
		return box
	var scale := minf(box.size.x / ts.x, box.size.y / ts.y)
	var out := ts * scale
	return Rect2(box.position + (box.size - out) * 0.5, out)


## Draw a slot into a box, or return false so the caller draws its own
## primitives. Every screen's art path is this one line and an `if`.
static func draw_slot(ci: CanvasItem, id: String, box: Rect2,
		modulate := Color.WHITE) -> bool:
	var tex := get_slot(id)
	if tex == null:
		return false
	ci.draw_texture_rect(tex, fit(tex, box), false, modulate)
	return true


## What is present and what is not — printed by the suite, the same way the
## audio catalog takes stock of itself, so an empty art folder is a number
## somebody sees rather than a thing nobody mentions.
static func stocktake() -> Dictionary:
	var have := 0
	var missing: Array[String] = []
	for id in SLOTS:
		if has(String(id)):
			have += 1
		else:
			missing.append(String(id))
	return {"have": have, "want": SLOTS.size(), "missing": missing}
