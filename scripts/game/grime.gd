class_name Grime
## WHAT A GROUND NOBODY SWEEPS LOOKS LIKE.
##
## Pete, 16 Sep 2026: *"can we use an overlay to make the best arena level look
## shitty? Like an overlay that adds trash outside the fighting area, cracks in
## the wood, and make it really crappy that you'll have to upgrade to clean."*
##
## ---------------------------------------------------------------------------
## THIS IS THE ONE DRAWING IN THE PROJECT THAT IS DELIBERATELY NOT ART, and the
## header of `arena_scene.gd` is the reason it needs saying out loud.
##
## That file says, in Pete's words: *"Let's not use your art for any of this,
## just placeholders. I'll get ChatGPT to do that work."* So the grounds are six
## empty labelled slots waiting for six images. Six images times five states of
## repair is thirty images, which is not a placeholder problem, it is a
## commission — and it would make the condition axis unshippable until every one
## of them existed.
##
## An OVERLAY does not have that problem. It is one layer of rubbish and damage
## drawn on top of whatever is behind it, so it works on the empty slot today and
## on the real artwork the day it lands, and nothing about it is a decision that
## belongs to whoever draws the grounds. If Pete would rather have thirty images
## later, this is a file that gets deleted rather than a system that gets unpicked.
##
## ---------------------------------------------------------------------------
## IT IS DETERMINISTIC AND IT HAS TO BE.
##
## Every mark is placed from a seeded RNG keyed on the ground's level. Placed
## from `randf()` instead, the rubbish would jump to a new place thirty times a
## second — a screen that boils is a screen a player reads as broken, and it
## would also mean no screenshot check could ever assert anything about it.
##
## The KEY is the level and not the condition, which is the part worth getting
## right: as a ground degrades, the marks that are already there stay exactly
## where they are and NEW ones appear between them. Keying on condition as well
## would reshuffle the whole floor every time a week passed, so the player would
## see a different mess rather than a worsening one.
##
## ---------------------------------------------------------------------------
## AND IT LEAVES THE FIGHTING AREA ALONE, mostly.
##
## Pete's words again: *"trash outside the fighting area, cracks in the wood."*
## Those are two different things in two different places, and that is what makes
## the picture read as neglect rather than as damage: nobody fights in a pile of
## rubbish, so the rubbish collects where nobody walks, and the floor itself
## cracks where everybody does.

## THE MARGIN THE RUBBISH COLLECTS IN, as a share of the shorter side. Outside
## the fighting area means outside it — a fifth in from each edge is a band wide
## enough to hold litter without any of it landing where two men are standing.
const MARGIN: float = 0.20

## NOTHING AT ALL UNTIL IT IS ACTUALLY DIRTY. `Arena.condition_word()` calls
## anything above 0.95 "Spotless", and a spotless ground with three crisps
## packets in it is a screen arguing with its own caption.
const CLEAN: float = 0.95

## HOW MUCH THERE IS OF EACH, at the very bottom of the scale. Everything in
## between is this times how far down it has gone, so the first week of neglect
## is one bit of litter and a ruin is covered.
const LITTER_MAX: int = 34
const CRACK_MAX: int = 11
const STAIN_MAX: int = 6

## HOW DARK THE MARKS ARE. Low, and low on purpose: this sits on top of artwork
## nobody has drawn yet, and an overlay that is legible in its own right is an
## overlay that will fight whatever lands underneath it.
const LITTER_A: float = 0.42
const CRACK_A: float = 0.30
const STAIN_A: float = 0.14


## HOW FAR GONE IT IS, 0 at spotless and 1 at a ruin. Its own function because
## three counts and three alphas all read it and a fourth caller is coming.
static func amount(condition: float) -> float:
	if condition >= CLEAN:
		return 0.0
	return clampf((CLEAN - condition) / CLEAN, 0.0, 1.0)


## THE WHOLE LAYER, over a rect. `key` keys the placement — pass the ground's
## level, so each of the six grounds gets its own arrangement and keeps it.
##
## Draws nothing at all above `CLEAN`, which is worth stating because it means
## every screen in the game can call this unconditionally and a well-run club
## never sees a pixel of it.
static func draw_over(ci: CanvasItem, box: Rect2, condition: float,
		key: int = 0) -> void:
	var a := amount(condition)
	if a <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x6B0D5E + key * 7919
	_stains(ci, box, a, rng)
	_cracks(ci, box, a, rng)
	_litter(ci, box, a, rng)


## ---------------------------------------------------------------------------
## THE FLOOR, DISCOLORING. Drawn first and largest, so it reads as the ground
## itself going off rather than as something lying on it.
##
## POLYGONS AND NOT RECTANGLES, and the first cut got this wrong in a way a
## screenshot made obvious in one look: eight axis-aligned rectangles at 14%
## over a dark panel do not read as dirt, they read as UI. The screen had grown
## six grey boxes and the eye files them with the buttons, because on a screen
## made of rectangles the one thing that cannot be a stain is a rectangle.
##
## PURE BLACK, ALSO FROM THAT SCREENSHOT. The color was `(0.05, 0.04, 0.03)`,
## which is darker than a slate panel in the abstract and LIGHTER than the one
## this actually sits on — so every stain came out as a pale patch, and a ground
## going off looked like a ground someone had started cleaning. Black only ever
## darkens whatever is behind it, which is what a stain does and what makes this
## safe over artwork nobody has drawn yet.
static func _stains(ci: CanvasItem, box: Rect2, a: float,
		rng: RandomNumberGenerator) -> void:
	var n := int(round(float(STAIN_MAX) * a))
	var col := Color(0.0, 0.0, 0.0, STAIN_A * a)
	for i in n:
		var w := box.size.x * rng.randf_range(0.10, 0.28)
		var h := box.size.y * rng.randf_range(0.08, 0.22)
		var mid := Vector2(
			box.position.x + rng.randf_range(w * 0.5, box.size.x - w * 0.5),
			box.position.y + rng.randf_range(h * 0.5, box.size.y - h * 0.5))
		## A RING OF POINTS AT A WOBBLING RADIUS. Seven is enough to stop reading
		## as a polygon and few enough that a ruin's worth of them is still one
		## draw call each.
		var pts := PackedVector2Array()
		var steps := 7
		for k in steps:
			var ang := TAU * float(k) / float(steps)
			var r := rng.randf_range(0.55, 1.0)
			pts.append(mid + Vector2(cos(ang) * w * 0.5, sin(ang) * h * 0.5) * r)
		ci.draw_colored_polygon(pts, col)


## THE CRACKS, ACROSS THE FLOOR AND THROUGH THE MIDDLE OF IT, because that is
## where the boards take the weight. Three or four segments each with a wander
## on them — a straight line reads as a drawn line and a jointed one reads as a
## split.
static func _cracks(ci: CanvasItem, box: Rect2, a: float,
		rng: RandomNumberGenerator) -> void:
	var n := int(round(float(CRACK_MAX) * a))
	var col := Color(0.04, 0.03, 0.03, CRACK_A + 0.35 * a)
	for i in n:
		var p := Vector2(
			box.position.x + rng.randf_range(0.06, 0.94) * box.size.x,
			box.position.y + rng.randf_range(0.10, 0.94) * box.size.y)
		## A HEADING, KEPT, so the crack travels rather than scribbling. It gets
		## nudged each segment and the nudge is what makes it look split rather
		## than drawn.
		var dir := rng.randf_range(0.0, TAU)
		var segs := rng.randi_range(2, 4)
		for k in segs:
			dir += rng.randf_range(-0.7, 0.7)
			var len_ := rng.randf_range(10.0, 40.0)
			var q := p + Vector2(cos(dir), sin(dir)) * len_
			## CLAMPED INSIDE THE BOX, every segment, and not just the start. A
			## crack that wanders out of the ground and across the diary is the
			## same bug as a ticker that is 2003 pixels wide on a 960 canvas.
			q.x = clampf(q.x, box.position.x + 2.0, box.end.x - 2.0)
			q.y = clampf(q.y, box.position.y + 2.0, box.end.y - 2.0)
			ci.draw_line(p, q, col, 1.0)
			p = q


## AND THE RUBBISH, WHICH COLLECTS WHERE NOBODY STANDS. Placed in the margin
## band only — `_edge_point` is what guarantees that, and it is why it is a
## function rather than two more `randf_range` calls.
static func _litter(ci: CanvasItem, box: Rect2, a: float,
		rng: RandomNumberGenerator) -> void:
	var n := int(round(float(LITTER_MAX) * a))
	## THREE COLORS AND NO MORE. Litter is paper, plastic and a can; a palette
	## wider than that starts to look like confetti, which is the opposite of
	## the feeling.
	var cols := [
		Color(0.72, 0.68, 0.58, LITTER_A),   ## paper
		Color(0.42, 0.50, 0.44, LITTER_A),   ## a bottle
		Color(0.55, 0.36, 0.28, LITTER_A),   ## something rusted
	]
	for i in n:
		var at := _edge_point(box, rng)
		var w := rng.randf_range(2.0, 6.0)
		var h := rng.randf_range(1.5, 4.0)
		var c: Color = cols[rng.randi() % cols.size()]
		ci.draw_rect(Rect2(at, Vector2(w, h)), c)


## A POINT IN THE MARGIN BAND, never in the middle. Picks which of the four
## bands first and then a point in it, rather than rejecting samples until one
## lands outside — a rejection loop is a loop with no upper bound, and this runs
## thirty-four times a frame.
static func _edge_point(box: Rect2, rng: RandomNumberGenerator) -> Vector2:
	var m := minf(box.size.x, box.size.y) * MARGIN
	match rng.randi() % 4:
		0:  ## the top band
			return Vector2(box.position.x + rng.randf() * box.size.x,
				box.position.y + rng.randf() * m)
		1:  ## the bottom band
			return Vector2(box.position.x + rng.randf() * box.size.x,
				box.end.y - m + rng.randf() * m)
		2:  ## the left
			return Vector2(box.position.x + rng.randf() * m,
				box.position.y + rng.randf() * box.size.y)
		_:  ## and the right
			return Vector2(box.end.x - m + rng.randf() * m,
				box.position.y + rng.randf() * box.size.y)
