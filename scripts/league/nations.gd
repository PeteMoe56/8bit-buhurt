class_name Nations
extends RefCounted
## THE WORLDS' FLAGS AND COLOURS (Pete, 11 Oct 2026: "you would still need to
## create all the 32 and 16px country flags and colors"). The flags are drawn
## by `tools/make_flags.py` into art/flags/<code>_16.png and _32.png; the
## colours here are the same table: the darker flag colour the team wears and
## the lighter one on it, each pair passing `IconBank.contrast_ok`.

const COLORS := {
	"USA": ["#3c3b6e", "#ffffff"],
	"UKR": ["#0057b7", "#ffd700"],
	"POL": ["#c8102e", "#ffffff"],
	"FRA": ["#002395", "#ffffff"],
	"GER": ["#1c1c1c", "#ffce00"],
	"ITA": ["#00703c", "#ffffff"],
	"ESP": ["#aa151b", "#f1bf00"],
	"GBR": ["#012169", "#ffffff"],
	"IRL": ["#169b62", "#ffffff"],
	"BEL": ["#1c1c1c", "#fdda24"],
	"NED": ["#e05206", "#ffffff"],
	"DEN": ["#c60c30", "#ffffff"],
	"SWE": ["#006aa7", "#fecc02"],
	"NOR": ["#ba0c2f", "#ffffff"],
	"FIN": ["#002f6c", "#ffffff"],
	"CZE": ["#11457e", "#ffffff"],
	"SVK": ["#0b4ea2", "#ffffff"],
	"HUN": ["#477050", "#ffffff"],
	"AUT": ["#c8102e", "#ffffff"],
	"SUI": ["#da291c", "#ffffff"],
	"POR": ["#006600", "#ffcd00"],
	"ISR": ["#0038b8", "#ffffff"],
	"CAN": ["#d80621", "#ffffff"],
	"MEX": ["#006847", "#ffffff"],
	"ARG": ["#1b4f8a", "#74acdf"],
	"BRA": ["#009739", "#fedd00"],
	"CHI": ["#0039a6", "#ffffff"],
	"AUS": ["#012169", "#ffcd00"],
	"NZL": ["#1c1c1c", "#ffffff"],
	"JPN": ["#bc002d", "#ffffff"],
	"LAT": ["#9e3039", "#ffffff"],
	"LTU": ["#006a44", "#fdb913"],
	"EST": ["#0072ce", "#ffffff"],
	"ROU": ["#002b7f", "#fcd116"],
	"CRO": ["#171796", "#ffffff"],
	"SRB": ["#0c4076", "#ffffff"],
	"GRE": ["#0d5eaf", "#ffffff"]
}

static var _tex := {}


## The nation a Worlds entrant fights for: "USA" for the home berth (the
## National champion, a club on the pyramid), its own code for a guest, "" for
## anybody outside a Worlds.
static func code_for(c: Cup, w: LeagueWorld, id: int) -> String:
	if c == null or w == null or id < 0 or id >= w.clubs.size():
		return ""
	if String(c.get_meta("id", "")) != "worlds" and c.cup_name != "Worlds":
		return ""
	if int(w.clubs[id].get("tier", -1)) >= 0:
		return "USA"
	var code := String(w.clubs[id].get("short", ""))
	return code if COLORS.has(code) else ""


## A flag texture, 16 or 32 tall; null for an unknown code.
static func flag(code: String, big: bool = false) -> Texture2D:
	if code == "" or not COLORS.has(code):
		return null
	var key := "%s_%d" % [code.to_lower(), 32 if big else 16]
	if not _tex.has(key):
		var path := "res://art/flags/%s.png" % key
		_tex[key] = load(path) if ResourceLoader.exists(path) else null
	return _tex[key]


## Draw the flag with its top-left at `at`, `h` tall (3:2). Returns the width
## drawn, 0 when there is no flag, so a caller can move its text along.
static func draw(ci: CanvasItem, at: Vector2, h: float, code: String) -> float:
	var t := flag(code, h > 20.0)
	if t == null:
		return 0.0
	var w := roundf(h * 1.5)
	ci.draw_texture_rect(t, Rect2(at, Vector2(w, h)), false)
	ci.draw_rect(Rect2(at, Vector2(w, h)), Color(0, 0, 0, 0.6), false, 1.0)
	return w


static func kit(code: String) -> Color:
	return Color(String(COLORS[code][0])) if COLORS.has(code) else Color.BLACK


static func mark(code: String) -> Color:
	return Color(String(COLORS[code][1])) if COLORS.has(code) else Color.WHITE
