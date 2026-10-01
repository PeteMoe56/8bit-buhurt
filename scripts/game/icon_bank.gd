class_name IconBank
extends RefCounted
## THE ICON BANK — every mark a club can wear, and what it costs to wear it.
##
## Pete, 10 Sep 2026: *"Let's change the charge color and charge name to
## something more modern day. We can have an Icon bank that they can buy with
## credits or later asset packs."*
##
## So the heraldry vocabulary is gone. This is not a cosmetic rename: a cross, a
## bend and a saltire are the marks of a system where the shape is a sentence
## about a family, and a buhurt club in 2026 picks a mark the way a fight team
## does — an animal, a tool, a mark that looks good on a gambeson. The only part
## of the old system worth keeping is the reason it worked, which is CONTRAST:
## a mark has to read across a field, through dust, at speed. That rule survives
## as `contrast_ok` and is enforced on every club in the world.
##
## A PACK IS DATA. Every entry carries a `pack`, so a later asset pack is a
## block added to this array and nothing else — no new code path, no new save
## field, no new screen. `PACK_CORE` is free and everybody has it from the first
## save; everything else is bought with credits.
##
## DRAWING LIVES HERE TOO, next to the names. The marks used to be a match
## statement inside UiKit and a second, slightly different match statement
## inside the melee's banner code, which is how a club ended up wearing one mark
## on the table and another on the surcoat. One function, called by both.

const PACK_CORE := "core"
const PACK_STEEL := "steel"
const PACK_BEASTS := "beasts"

## `id` is what the save stores and it must never be renumbered — a save written
## today has to still put the same mark on the same club in a year. New icons go
## on the END of this array with the next free id, whatever pack they belong to.
const ICONS := [
	## The starter set: four flat geometric marks, free with every save, and
	## deliberately the four that read smallest. A club that owns nothing still
	## has something legible to wear.
	{"id": 0, "name": "Bar", "pack": PACK_CORE, "cost": 0},
	{"id": 1, "name": "Band", "pack": PACK_CORE, "cost": 0},
	{"id": 2, "name": "Slash", "pack": PACK_CORE, "cost": 0},
	{"id": 3, "name": "Disc", "pack": PACK_CORE, "cost": 0},

	{"id": 4, "name": "Cross", "pack": PACK_CORE, "cost": 1},
	{"id": 5, "name": "Saltire", "pack": PACK_CORE, "cost": 1},
	{"id": 6, "name": "Chevron", "pack": PACK_CORE, "cost": 1},
	{"id": 7, "name": "Diamond", "pack": PACK_CORE, "cost": 1},
	{"id": 8, "name": "Star", "pack": PACK_CORE, "cost": 2},
	{"id": 9, "name": "Bolt", "pack": PACK_CORE, "cost": 2},

	## Steel: the sport's own furniture.
	{"id": 10, "name": "Axe", "pack": PACK_STEEL, "cost": 3},
	{"id": 11, "name": "Hammer", "pack": PACK_STEEL, "cost": 3},
	{"id": 12, "name": "Helm", "pack": PACK_STEEL, "cost": 3},
	{"id": 13, "name": "Shield", "pack": PACK_STEEL, "cost": 3},
	{"id": 14, "name": "Anvil", "pack": PACK_STEEL, "cost": 4},
	{"id": 15, "name": "Fist", "pack": PACK_STEEL, "cost": 4},

	## Beasts: what a club actually calls itself.
	{"id": 16, "name": "Wolf", "pack": PACK_BEASTS, "cost": 4},
	{"id": 17, "name": "Bear", "pack": PACK_BEASTS, "cost": 4},
	{"id": 18, "name": "Horns", "pack": PACK_BEASTS, "cost": 3},
	{"id": 19, "name": "Skull", "pack": PACK_BEASTS, "cost": 5},
]

const PACK_NAME := {
	PACK_CORE: "Core", PACK_STEEL: "Steel", PACK_BEASTS: "Beasts",
}

## The kit — the ground the mark sits on. Dark and saturated, the way a club's
## gambeson actually is.
##
## Every kit here clears MIN_CONTRAST against every mark color below, and that
## is asserted rather than eyeballed — a screen that offers a combination and
## then refuses to save it is worse than one that never offered it. The orange
## started at b8541f and failed that check against the gold by three
## thousandths, which is exactly the pairing a player would have picked and then
## squinted at. Darkened rather than the rule being loosened: the rule was right.
## FOURTEEN, not seven (playtest 30 Sep #3). New ones on the END, so an index
## a save or a fixture already holds still means the colour it meant.
const KIT_COLORS: Array[Color] = [
	Color("c0392b"), Color("2a5caa"), Color("2f7d3b"), Color("23232b"),
	Color("7b3fa0"), Color("9c4416"), Color("1f6f78"),
	Color("7a1f3d"), Color("15305e"), Color("4b5a1f"), Color("5b3a29"),
	Color("3b3f8f"), Color("5e6470"), Color("a8341c"),
	## TWENTY-FOUR (Pete, 1 Oct 2026: "More colors"). On the end, as always.
	Color("d4a017"), Color("e67e22"), Color("16a085"), Color("c2185b"), Color("2c3e50"),
	Color("2e86c1"), Color("6d4c41"), Color("1b4f72"), Color("7d6608"), Color("0e6655"),
]
## The mark. Light, because the point of the mark is that you can see it.
## NINE, not three (playtest 30 Sep #3). All light: the contrast rule against
## the kit still decides which pairs are legal.
const MARK_COLORS: Array[Color] = [
	Color("f4f4e8"), Color("f2c14e"), Color("d8dde3"),
	Color("f4a6a0"), Color("9fd8f0"), Color("a8e0a0"), Color("f8b878"),
	Color("c8b0f0"), Color("ffe08a"),
	## SIXTEEN (1 Oct 2026), two of them dark for the bright kits.
	Color("ffffff"), Color("d4af37"), Color("c0c0c0"), Color("f5deb3"), Color("b0e0e6"),
	Color("1c1c1c"), Color("3b2416"),
]


static func count() -> int:
	return ICONS.size()


static func entry(id: int) -> Dictionary:
	for e in ICONS:
		if int(e["id"]) == id:
			return e
	return ICONS[0]


static func icon_name(id: int) -> String:
	return UiKit.t(String(entry(id)["name"]))


static func cost(id: int) -> int:
	return int(entry(id)["cost"])


## Free from the first save. Everything in the starter set, and nothing else —
## `cost == 0` is the definition rather than a second list that can disagree
## with it.
static func is_free(id: int) -> bool:
	return cost(id) <= 0


## Typed, because the caller stores it in an Array[int] and an untyped Array
## will not assign into one.
static func starter() -> Array[int]:
	var out: Array[int] = []
	for e in ICONS:
		if int(e["cost"]) <= 0:
			out.append(int(e["id"]))
	return out


static func packs() -> Array:
	var out: Array = []
	for e in ICONS:
		var p := String(e["pack"])
		if not out.has(p):
			out.append(p)
	return out


static func in_pack(pack: String) -> Array:
	var out: Array = []
	for e in ICONS:
		if String(e["pack"]) == pack:
			out.append(int(e["id"]))
	return out


# ------------------------------------------------------------------ contrast
## THE ONE RULE THE OLD SYSTEM GOT RIGHT. A mark that does not contrast with the
## kit is not a mark, it is a stain — and at the size this game draws a club on
## a league table it disappears entirely. Kept as a measured contrast rather than
## as a metal/color taxonomy, because the taxonomy was a proxy for this all
## along and a proxy stops being right the moment somebody adds a color.
const MIN_CONTRAST: float = 0.34


static func luma(c: Color) -> float:
	return c.r * 0.299 + c.g * 0.587 + c.b * 0.114


static func contrast_ok(kit: Color, mark: Color) -> bool:
	return absf(luma(kit) - luma(mark)) >= MIN_CONTRAST


# ------------------------------------------------------------------- drawing
## Every mark, drawn from primitives at any size. `r` is the half-width of the
## badge it sits in; each shape is expressed as a fraction of it so the same
## call works at 13 pixels on a league table and at 76 on the create screen.
##
## THE KIT COLOR IS PASSED IN because half of these marks need a hole. A skull
## without eye sockets is a bag; a helm without a sight is a doorway. There is no
## third color and there should not be — the hole is the kit showing through,
## which is how a real surcoat does it, and it costs nothing at 13 pixels where a
## third color would turn to mud.
##
## The first sheet of these was rendered before anything used them, and it is the
## only reason this comment exists: Axe read as a flag on a pole, Hammer as a
## letter T, Bear as a cartoon mouse, and Skull's sockets were drawn at alpha
## zero, which paints nothing at all. A mark is only a mark if it READS, and that
## is not a thing anyone settles by looking at the code.
## THE BADGE AS IT IS ACTUALLY PAINTED, at a quality the arena decides.
##
## Pete, 10 Sep 2026: the mark goes *"from really shitty quality to NFL level
## details"* as the ground improves. The four things that make a cheap paint job
## look cheap, and what each of them is worth here:
##
##   OFF-REGISTER   the mark is not quite where the stencil said. A couple of
##                  pixels at the bottom, and it is the single strongest tell.
##   GHOSTING       a shadow of the first, misaligned pass showing through.
##   MUDDY COLOR   thinned paint, so the mark sits closer to the kit than it
##                  should and the contrast the bank guarantees is spent.
##   NO EDGE        a printed mark has a keyline; a painted one has a ragged
##                  border that is only there at all further up.
##
## None of this is a second set of shapes. It is the SAME `draw_icon` the league
## table uses, drawn worse — so a mark added in an asset pack gets the whole
## progression for free and can never be the one that does not have it.
static func draw_badge(ci: CanvasItem, at: Vector2, r: float,
		kit: Color, mark: Color, id: int, quality: float = 1.0) -> void:
	var q := clampf(quality, 0.0, 1.0)
	ci.draw_rect(Rect2(at - Vector2(r, r), Vector2(r * 2, r * 2)), kit)
	## Scaled by r, so a badge at 13 pixels is off by a fraction of one and a
	## badge at 76 is off by three. An absolute offset would be invisible on the
	## league table and cartoonish on the arena screen.
	var slip := r * 0.075 * (1.0 - q)
	## AND THE MARK SHRINKS BY WHAT IT SLIPS. The shapes in this bank already
	## reach 0.86-0.94 of the radius, so sliding one two pixels sideways pushes
	## it straight out through the edge of the badge — a bad paint job that
	## overflows its own shield reads as a rendering bug rather than as cheap
	## paint. Giving the slip somewhere to go costs a couple of pixels of mark
	## and buys the whole effect.
	var rr := r - slip * 2.0
	## The ghost pass, only while the paint is bad enough to have one.
	if q < 0.55:
		draw_icon(ci, at + Vector2(-slip * 1.6, slip * 0.5), rr,
			Color(mark, 0.20 * (1.0 - q)), kit, id)
	## Thinned paint at the bottom end: the mark creeps toward the kit, which
	## spends exactly the contrast the bank works to guarantee. That is the
	## point — a cheap job is hard to read, and it is supposed to bother him.
	var paint := mark.lerp(kit, 0.34 * (1.0 - q))
	draw_icon(ci, at + Vector2(slip * 0.4, slip), rr, paint, kit, id)
	## And the keyline a printed mark has and a painted one does not.
	if q > 0.7:
		var t := (q - 0.7) / 0.3
		ci.draw_rect(Rect2(at - Vector2(r * 0.92, r * 0.92), Vector2(r * 1.84, r * 1.84)),
			Color(mark, 0.30 * t), false, maxf(1.0, r * 0.045))


static func draw_icon(ci: CanvasItem, at: Vector2, r: float, col: Color,
		kit: Color, id: int) -> void:
	var t := r * 0.34
	match id:
		0:      ## Bar
			ci.draw_rect(Rect2(at.x - t * 0.7, at.y - r, t * 1.4, r * 2), col)
		1:      ## Band
			ci.draw_rect(Rect2(at.x - r, at.y - t * 0.7, r * 2, t * 1.4), col)
		2:      ## Slash
			var i := r - t * 0.5
			ci.draw_line(at + Vector2(-i, i), at + Vector2(i, -i), col, t)
		3:      ## Disc
			ci.draw_circle(at, r * 0.55, col)
		4:      ## Cross
			ci.draw_rect(Rect2(at.x - t * 0.5, at.y - r, t, r * 2), col)
			ci.draw_rect(Rect2(at.x - r, at.y - t * 0.5, r * 2, t), col)
		5:      ## Saltire
			var j := r - t * 0.4
			ci.draw_line(at + Vector2(-j, -j), at + Vector2(j, j), col, t * 0.8)
			ci.draw_line(at + Vector2(-j, j), at + Vector2(j, -j), col, t * 0.8)
		6:      ## Chevron
			ci.draw_line(at + Vector2(-r * 0.8, r * 0.5), at + Vector2(0, -r * 0.5), col, t)
			ci.draw_line(at + Vector2(0, -r * 0.5), at + Vector2(r * 0.8, r * 0.5), col, t)
		7:      ## Diamond
			_poly(ci, col, [at + Vector2(0, -r * 0.8), at + Vector2(r * 0.7, 0),
				at + Vector2(0, r * 0.8), at + Vector2(-r * 0.7, 0)])
		8:      ## Star — five points, struck from the center.
			var pts: PackedVector2Array = PackedVector2Array()
			for k in 10:
				var ang := -PI * 0.5 + float(k) * PI / 5.0
				var rad: float = r * (0.82 if k % 2 == 0 else 0.34)
				pts.append(at + Vector2(cos(ang), sin(ang)) * rad)
			ci.draw_colored_polygon(pts, col)
		9:      ## Bolt
			_poly(ci, col, [
				at + Vector2(r * 0.18, -r * 0.85), at + Vector2(-r * 0.52, r * 0.10),
				at + Vector2(-r * 0.08, r * 0.10), at + Vector2(-r * 0.18, r * 0.85),
				at + Vector2(r * 0.52, -r * 0.10), at + Vector2(r * 0.08, -r * 0.10)])
		10:     ## Axe. The haft runs down the CENTER and the head sits across
				## it with a lug on the back — a head hanging off one side of an
				## off-center haft is a flag on a pole, which is what the first
				## two versions were. The back lug is the whole tell.
			ci.draw_rect(Rect2(at.x - r * 0.13, at.y - r * 0.86, r * 0.26, r * 1.72), col)
			ci.draw_rect(Rect2(at.x - r * 0.38, at.y - r * 0.60, r * 0.25, r * 0.40), col)
			## A bearded blade: narrow where it meets the haft, fanning out to a
			## bulged cutting edge. A head that is the same width at the haft as
			## at the edge is a rectangle on a pole, i.e. a flag.
			_poly(ci, col, [
				at + Vector2(-r * 0.10, -r * 0.68), at + Vector2(r * 0.34, -r * 0.82),
				at + Vector2(r * 0.68, -r * 0.56), at + Vector2(r * 0.84, -r * 0.16),
				at + Vector2(r * 0.74, r * 0.20), at + Vector2(r * 0.44, r * 0.40),
				at + Vector2(r * 0.06, r * 0.40), at + Vector2(-r * 0.10, r * 0.18)])
		11:     ## Hammer — a WAR hammer, because a block on a stem is a letter T
				## at any size. The spike off the back is what makes it a weapon
				## and not a piece of furniture.
			ci.draw_rect(Rect2(at.x - r * 0.35, at.y - r * 0.26, r * 0.34, r * 1.10), col)
			ci.draw_rect(Rect2(at.x - r * 0.62, at.y - r * 0.82, r * 0.80, r * 0.56), col)
			_poly(ci, col, [
				at + Vector2(r * 0.18, -r * 0.78), at + Vector2(r * 0.92, -r * 0.54),
				at + Vector2(r * 0.18, -r * 0.30)])
		12:     ## Helm — a barbute, and the T of the sight and breath is CUT,
				## not implied. Without the cut it is an archway.
			_poly(ci, col, [
				at + Vector2(-r * 0.60, r * 0.74), at + Vector2(-r * 0.60, -r * 0.26),
				at + Vector2(-r * 0.32, -r * 0.78), at + Vector2(r * 0.32, -r * 0.78),
				at + Vector2(r * 0.60, -r * 0.26), at + Vector2(r * 0.60, r * 0.74)])
			ci.draw_rect(Rect2(at.x - r * 0.46, at.y - r * 0.34, r * 0.92, r * 0.20), kit)
			ci.draw_rect(Rect2(at.x - r * 0.12, at.y - r * 0.34, r * 0.24, r * 0.96), kit)
		13:     ## Shield — a heater with a deep point and shoulders taken off.
				## Square shoulders and a shallow point read as a pentagon; a bar
				## across the middle reads as a letter Y. Neither is a shield.
			_poly(ci, col, [
				at + Vector2(-r * 0.52, -r * 0.82), at + Vector2(r * 0.52, -r * 0.82),
				at + Vector2(r * 0.68, -r * 0.62), at + Vector2(r * 0.62, r * 0.06),
				at + Vector2(0, r * 0.88), at + Vector2(-r * 0.62, r * 0.06),
				at + Vector2(-r * 0.68, -r * 0.62)])
		14:     ## Anvil
			ci.draw_rect(Rect2(at.x - r * 0.52, at.y + r * 0.44, r * 1.04, r * 0.30), col)
			ci.draw_rect(Rect2(at.x - r * 0.22, at.y - r * 0.12, r * 0.44, r * 0.58), col)
			_poly(ci, col, [
				at + Vector2(-r * 0.62, -r * 0.44), at + Vector2(r * 0.46, -r * 0.44),
				at + Vector2(r * 0.86, -r * 0.14), at + Vector2(r * 0.46, -r * 0.10),
				at + Vector2(r * 0.30, -r * 0.10), at + Vector2(-r * 0.62, -r * 0.10)])
		15:     ## Fist — three knuckles, not a comb, and the fingers cut in kit.
			ci.draw_rect(Rect2(at.x - r * 0.58, at.y - r * 0.34, r * 1.04, r * 0.92), col)
			for k in 3:
				ci.draw_circle(at + Vector2(-r * 0.40 + float(k) * r * 0.34, -r * 0.34),
					r * 0.19, col)
			for k in 2:
				ci.draw_rect(Rect2(at.x - r * 0.25 + float(k) * r * 0.34,
					at.y - r * 0.18, r * 0.07, r * 0.52), kit)
			ci.draw_rect(Rect2(at.x + r * 0.40, at.y - r * 0.10, r * 0.26, r * 0.42), col)
		16:     ## Wolf — ears sharp, muzzle long, eyes cut on the slant. The
				## eyes are what stop a beast head reading as a leaf.
			_poly(ci, col, [
				at + Vector2(-r * 0.68, -r * 0.80), at + Vector2(-r * 0.40, -r * 0.16),
				at + Vector2(r * 0.40, -r * 0.16), at + Vector2(r * 0.68, -r * 0.80),
				at + Vector2(r * 0.58, r * 0.14), at + Vector2(r * 0.20, r * 0.36),
				at + Vector2(0, r * 0.86), at + Vector2(-r * 0.20, r * 0.36),
				at + Vector2(-r * 0.58, r * 0.14)])
			_poly(ci, kit, [at + Vector2(-r * 0.44, -r * 0.06),
				at + Vector2(-r * 0.14, r * 0.06), at + Vector2(-r * 0.44, r * 0.16)])
			_poly(ci, kit, [at + Vector2(r * 0.44, -r * 0.06),
				at + Vector2(r * 0.14, r * 0.06), at + Vector2(r * 0.44, r * 0.16)])
		17:     ## Bear — broad head, small ears set WIDE and LOW on the skull.
				## Round ears on top of a round head is a cartoon mouse, which is
				## what the first one was.
			ci.draw_circle(at + Vector2(-r * 0.62, -r * 0.34), r * 0.22, col)
			ci.draw_circle(at + Vector2(r * 0.62, -r * 0.34), r * 0.22, col)
			_poly(ci, col, [
				at + Vector2(-r * 0.56, -r * 0.56), at + Vector2(r * 0.56, -r * 0.56),
				at + Vector2(r * 0.62, r * 0.16), at + Vector2(r * 0.26, r * 0.74),
				at + Vector2(-r * 0.26, r * 0.74), at + Vector2(-r * 0.62, r * 0.16)])
			ci.draw_rect(Rect2(at.x - r * 0.40, at.y - r * 0.24, r * 0.18, r * 0.16), kit)
			ci.draw_rect(Rect2(at.x + r * 0.22, at.y - r * 0.24, r * 0.18, r * 0.16), kit)
			_poly(ci, kit, [at + Vector2(-r * 0.22, r * 0.26),
				at + Vector2(r * 0.22, r * 0.26), at + Vector2(0, r * 0.62)])
		18:     ## Horns — tips turned UP and a boss between them. Without the
				## turned tips it is a crescent, and without the boss a crescent
				## is a cup.
			_poly(ci, col, [
				at + Vector2(-r * 0.94, -r * 0.66), at + Vector2(-r * 0.58, -r * 0.62),
				at + Vector2(-r * 0.24, r * 0.14), at + Vector2(0, r * 0.30),
				at + Vector2(r * 0.24, r * 0.14), at + Vector2(r * 0.58, -r * 0.62),
				at + Vector2(r * 0.94, -r * 0.66), at + Vector2(r * 0.62, r * 0.02),
				at + Vector2(r * 0.26, r * 0.56), at + Vector2(-r * 0.26, r * 0.56),
				at + Vector2(-r * 0.62, r * 0.02)])
			ci.draw_circle(at + Vector2(0, r * 0.18), r * 0.24, col)
		19:     ## Skull — cranium, jaw, and the sockets CUT in kit. Without them
				## it is a bag.
			_poly(ci, col, [
				at + Vector2(-r * 0.64, -r * 0.20), at + Vector2(-r * 0.46, -r * 0.74),
				at + Vector2(r * 0.46, -r * 0.74), at + Vector2(r * 0.64, -r * 0.20),
				at + Vector2(r * 0.42, r * 0.22), at + Vector2(r * 0.36, r * 0.70),
				at + Vector2(-r * 0.36, r * 0.70), at + Vector2(-r * 0.42, r * 0.22)])
			ci.draw_circle(at + Vector2(-r * 0.27, -r * 0.24), r * 0.19, kit)
			ci.draw_circle(at + Vector2(r * 0.27, -r * 0.24), r * 0.19, kit)
			_poly(ci, kit, [at + Vector2(0, -r * 0.02), at + Vector2(r * 0.13, r * 0.22),
				at + Vector2(-r * 0.13, r * 0.22)])
			ci.draw_rect(Rect2(at.x - r * 0.30, at.y + r * 0.38, r * 0.60, r * 0.10), kit)
		_:
			ci.draw_circle(at, r * 0.55, col)


static func _poly(ci: CanvasItem, col: Color, pts: Array) -> void:
	var p := PackedVector2Array()
	for v in pts:
		p.append(v)
	ci.draw_colored_polygon(p, col)
