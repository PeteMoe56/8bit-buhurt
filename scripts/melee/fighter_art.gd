class_name FighterArt
extends RefCounted
## THE FIGHTER SPRITE, IN EVERY CLUB'S COLOURS (6 Oct 2026).
##
## The sprite is a mask in nine key colours (docs/ART.md, the fighter). Each club
## gets its own copy, baked once on the CPU and cached: the sprite is 24 × 32, so
## a bake is 768 pixels and happens once per club per run. A bake rather than the
## kit_replace shader because a whole fight is drawn by ONE CanvasItem, and a
## material belongs to the item, not to a draw call — ten men in two kits would
## need ten nodes to carry two uniforms.
##
## Where the club's two colours go: kit on the surcoat, helm and second tincture
## stays the mark colour, so a club is told apart by the same two colours the
## table, the badge and the coded figure always used. Steel and leather are the
## same for everybody until clubs get a harness finish to choose.

const EPS := 2.5 / 255.0
const K_SURCOAT_A := Color8(255, 0, 255)
const K_SURCOAT_B := Color8(128, 0, 128)
const K_TRIM := Color8(255, 255, 0)
const K_HELM := Color8(255, 0, 0)
const K_STEEL := Color8(128, 128, 255)
const K_STEEL_B := Color8(0, 0, 255)
const K_LEATHER := Color8(0, 255, 0)
const K_LEATHER_B := Color8(0, 128, 0)
const K_MARK := Color8(128, 128, 128)
const K_BLACK := Color8(0, 0, 0)

const STEEL := Color8(160, 165, 175)
const STEEL_B := Color8(98, 102, 114)
const LEATHER := Color8(128, 92, 56)
const LEATHER_B := Color8(84, 60, 38)
const INK := Color8(22, 20, 18)

## On screen: one art pixel is two.
const SCALE := 2.0

static var _cache := {}


static func has_body() -> bool:
	return ArtBank.has("body_idle")


## The slot for a man's weapon: a polearm has its own drawing, everything else
## carries the sword-and-shield one. A missing polearm frame falls back to it.
static func slot_for(polearm: bool) -> String:
	if polearm and ArtBank.has("body_idle_polearm"):
		return "body_idle_polearm"
	return "body_idle"


## The keys and what each becomes for this club.
static func palette(kit: Color, second: Color) -> Array:
	return [
		[K_SURCOAT_A, kit], [K_SURCOAT_B, second], [K_TRIM, second], [K_HELM, kit],
		[K_STEEL, STEEL], [K_STEEL_B, STEEL_B], [K_LEATHER, LEATHER],
		[K_LEATHER_B, LEATHER_B], [K_MARK, second], [K_BLACK, INK],
	]


static func _match(c: Color, k: Color) -> bool:
	return absf(c.r - k.r) <= EPS and absf(c.g - k.g) <= EPS and absf(c.b - k.b) <= EPS


## Recolour a key-coloured image for one club. Opaque pixels only, exactly as the
## shader does; anything that matches no key keeps its own colour.
static func bake(src: Image, kit: Color, second: Color, mirror: bool) -> Image:
	var img := src.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var pal := palette(kit, second)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 1.0:
				continue
			for pair in pal:
				if _match(c, pair[0]):
					img.set_pixel(x, y, Color(pair[1], 1.0))
					break
	if mirror:
		img.flip_x()
	return img


## The idle body in this club's colours, facing right or (mirror) left.
static func body(club, mirror: bool, polearm: bool = false) -> Texture2D:
	var slot := slot_for(polearm)
	var key := "%s|%s|%s|%s" % [slot, club.kit.to_html(), club.icon_color.to_html(), mirror]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var src: Texture2D = ArtBank.get_slot(slot)
	if src != null:
		var img := src.get_image()
		if img != null:
			tex = ImageTexture.create_from_image(bake(img, club.kit, club.icon_color, mirror))
	_cache[key] = tex
	return tex
