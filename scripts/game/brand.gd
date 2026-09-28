class_name Brand
## THE GAME'S NAME AND ITS MARK, IN ONE PLACE.
##
## Pete, 15 Sep 2026: *"All around it says Retro Buhurt. We should be
## transitioning everything to '8-Bit Buhurt: Combat Club'"* — and with a logo
## attached. Both halves of that are why this file exists rather than a second
## sweep of string literals.
##
## THE NAME WAS IN SIX PLACES AND THEY HAD ALREADY DRIFTED. `project.godot` said
## "8-Bit Buhurt: Combat Club", the title screen drew "RETRO" and "BUHURT" as two
## separate `text()` calls with hand-placed x offsets, the settings credits line
## said "Retro Buhurt", and `CREDITS.md` said something else again. **A name that
## is written in six places is a name that will be wrong in at least one of
## them**, which is the same rule this project has already applied to colors,
## to the canvas size and to the engine version.
##
## So: the name is read from `project.godot` — the one copy a store listing and
## an APK manifest are also built from — and everything else asks here.
##
## THE MARK IS A FILE, NOT A DRAWING. `UiKit.badge()` still exists and is still
## what a CLUB's crest is drawn with; this is the GAME's mark, which is a piece
## of art with a helmet in it and was never going to be primitives. It loads
## through the same `ResourceLoader.exists` guard as everything in `ArtBank`, so
## a missing file is a quiet fallback to the old wordmark rather than sixty
## engine errors a second.

const DIR := "res://art/brand/"

## CUT TO THE SIZE THEY ARE DRAWN AT. The project runs nearest-neighbor
## filtering, so a texture the engine has to scale is a texture with chewed
## edges — every file here is its own draw size and nothing scales at runtime.
const LOGO := DIR + "logo.png"              ## 192x216 — the front door
const LOGO_SMALL := DIR + "logo_small.png"  ## 117x132 — a screen header
const WATERMARK := DIR + "watermark.png"    ## 462x520 — the faded ground
const CREST := DIR + "crest_192.png"        ## 192x192 — the mark alone
const CREST_SMALL := DIR + "crest_64.png"   ## 64x64 — a header's mark

## HOW FAINT THE WATERMARK IS, and it is deliberately fainter than looks right
## in a screenshot. Pete: *"heavily faded so it doesn't get in the way of words
## or actions."* The menus are dense — a roster is thirteen rows of small type —
## and a watermark a reader can *notice* behind a number is a watermark that has
## already cost them the number.
##
## 0.038, AND THE FILE IS FLATTENED TO ONE VALUE. The first cut was 0.055 on the
## full-color art and you could read "8-BI" through the reserve column: gold and
## white are so much brighter than the ground that 5% of them is still a picture.
## Grayed on disk it becomes texture rather than a logo, which is what a
## watermark is supposed to be.
const WASH := 0.038

static var _cache := {}


## THE NAME, FROM THE ONE PLACE A BUILD ALSO READS IT.
static func name_of() -> String:
	var n := String(ProjectSettings.get_setting("application/config/name", ""))
	return n if n != "" else "8-Bit Buhurt: Combat Club"


## "8-Bit Buhurt" — the half that fits a header when the subtitle does not.
static func short_name() -> String:
	var n := name_of()
	var i := n.find(":")
	return n.substr(0, i) if i > 0 else n


static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	_cache[path] = t
	return t


## THE MARK, TOP-LEFT-ANCHORED, at its own size. Returns false when the art is
## missing so the caller draws the wordmark it used to draw — the same contract
## `ArtBank.draw_slot` has, for the same reason.
static func draw_logo(ci: CanvasItem, path: String, at: Vector2,
		modulate := Color.WHITE) -> bool:
	var t := tex(path)
	if t == null:
		return false
	ci.draw_texture(t, at.floor(), modulate)
	return true


static func draw_wash(ci: CanvasItem, screen: Vector2, strength := WASH) -> void:
	var t := tex(WATERMARK)
	if t == null:
		return
	var s := Vector2(t.get_width(), t.get_height())
	## FURTHER INTO THE CORNER THAN LOOKS RIGHT. At 0.72/0.80 the helmet sat
	## under the reserve column's right-hand numbers; the quiet region of this
	## layout is narrower than it looks, because the right column is a table too.
	var at := Vector2(screen.x - s.x * 0.58, screen.y - s.y * 0.72)
	ci.draw_texture(t, at.floor(), Color(1.0, 1.0, 1.0, strength))
