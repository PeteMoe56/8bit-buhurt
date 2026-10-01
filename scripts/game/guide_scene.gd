extends Node2D
class_name GuideScene
## THE GUIDE (Pete, 1 Oct 2026: "Make a Guide in the Settings/Menu area").
##
## One place that answers "what is this?" so the screens themselves can stay
## clear of explainers (Pete: "the on menu explanations were flooding screens").
## Topics down the left, one page on the right. Every line here is checked
## against the code that does the thing — `docs/` is not the source.
##
## Reached from the club Menu and from Settings. Back returns to where it came from.

const LIST_X := 24.0
const LIST_W := 220.0
const LIST_Y := 24.0
const LIST_STEP := 48.0
const PAGE_X := 264.0
const PAGE_Y := 24.0
const LINE_H := 21.0
const GAP := 12.0
const COACH := preload("res://scripts/game/coach_scene.gd")

var font: Font
var ui: CanvasLayer
var season: Season
## Which topic is open. `tab` so the layout and ink sweeps can open every page.
var tab := 0


static func topics() -> Array:
	return [
		UiKit.t("The season"),
		UiKit.t("The table"),
		UiKit.t("The fight"),
		UiKit.t("Your team"),
		UiKit.t("Training"),
		UiKit.t("Kit & armorer"),
		UiKit.t("Money"),
		UiKit.t("Upgrades"),
		UiKit.t("Your coach"),
	]


static func page(i: int) -> Array:
	match i:
		0: return [
			UiKit.t("Each Saturday is one event: a league day, a cup weekend, a bye week or the playoff."),
			UiKit.t("In the league every club fights every other club once."),
			UiKit.t("The top four go to the playoff. Both finalists go up a division."),
			UiKit.t("The bottom two go down. Nobody goes down from the Backyard Circuit."),
			UiKit.t("To go up, your ground must be big enough for the division above. See Upgrades."),
			UiKit.t("Top three when a cup weekend comes round are invited, if your insurance is high enough."),
			UiKit.t("Backyard, State, Regional, National. Win the National playoff to go to the Worlds."),
		]
		1: return [
			UiKit.t("P played · W won · D drawn · L lost"),
			UiKit.t("RD: rounds won minus rounds lost."),
			UiKit.t("MG: margin. Men left standing when you won a round, minus the same against you."),
			UiKit.t("PTS: 3 for a win, 1 for a draw."),
			UiKit.t("Level on points? MG decides first, then RD."),
			UiKit.t("Green rows go to the playoff. Red rows go down."),
		]
		2: return [
			UiKit.t("Five against five. Best of three rounds, two minutes each."),
			UiKit.t("A man who goes down stays down until the round is over."),
			UiKit.t("A round ends when a side is wiped out, it is three on one, or time runs out. More men standing wins it."),
			UiKit.t("HOLD freezes the fight so you can give one order. You get two a bout."),
			UiKit.t("Drag your man onto an enemy to send him. A wheel opens on contact: lift your thumb to commit."),
			UiKit.t("Between rounds you can swap in up to two men from the bench. Rested men come back fresher."),
			UiKit.t("The chalkboard plan steers your line for the opening seconds of each round."),
		]
		3: return [
			UiKit.t("Five starters, three on the bench, up to four in reserve. Reserves do not travel."),
			UiKit.t("OVR is how good he is now. POT is as good as he can get."),
			UiKit.t("Strength puts men down. Base keeps him up. Skill wins the grapple. Gas is his tank."),
			UiKit.t("Bouts and practice give XP. A full bar is a point to spend on his page."),
			UiKit.t("His deal is $ a year, counted against your salary cap. Extend early and he costs less."),
			UiKit.t("Free agents cost CC to sign, and their wage goes on your books."),
			UiKit.t("Unhappy men turn down new deals and walk. Men start to retire from 33."),
		]
		4: return [
			UiKit.t("Hire up to two captains. Each teaches roles: Rail, Flanker or Center."),
			UiKit.t("A role nobody teaches gets no training over the winter."),
			UiKit.t("Light: less XP, happier men. Normal: steady. Hard: half again the XP, but more knocks and grumbling."),
			UiKit.t("Session: once in a fight week, pay CC for an extra week of practice."),
			UiKit.t("Winter camp: your training ground and captains share out points over the winter."),
			UiKit.t("Prospect: each winter, name one man for +3 POT. Needs training ground 3."),
		]
		5: return [
			UiKit.t("Every man's harness has a metal and a condition. Below the pass mark he cannot fight."),
			UiKit.t("Metals: Rust, Mild, Hardened, Stainless, Titanium. Better metal wears slower."),
			UiKit.t("Your armorer's stars are the best metal he can make and keep up. More stars, more wage."),
			UiKit.t("Every fight wears the kit of the men who fought it. Training does not."),
			UiKit.t("Repair each man once a week, in a fight week."),
			UiKit.t("Worn kit makes a man easier to put down."),
		]
		6: return [
			UiKit.t("CC is club money. Everything you buy costs CC."),
			UiKit.t("$ is a fighter's yearly wage. It never comes out of CC. It only has to fit under your salary cap."),
			UiKit.t("CC comes in from the gate at every event, the bar at home games, wins, draws and where you finish."),
			UiKit.t("Each summer you pay upkeep on your ground, buildings, insurance and armorer. Division dues come at the start of a season."),
			UiKit.t("Cannot pay a bill? That thing drops a level."),
		]
		7: return [
			UiKit.t("Ground: more seats, more gate. Fenced ground for State, Arena for Regional, National Arena for National."),
			UiKit.t("Training ground: more winter camp and practice."),
			UiKit.t("Infirmary: fewer knocks, and injured men come back sooner."),
			UiKit.t("Salary cap: more room for wages."),
			UiKit.t("Insurance: State needs 1, Regional 2, National 3. Without it, no cups and no Worlds."),
			UiKit.t("Everything you build costs upkeep each summer. One job per building per week."),
		]
	var out: Array = [UiKit.t("Wins, finishes, cup runs and promotion give your coach XP. Each level is a skill point.")]
	## THE SAME LINES AS THE "?" ON YOUR COACH PAGE, so the two can never disagree.
	for k in 5:
		out.append(COACH.skill_help(k))
	return out


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	_rebuild()


func _rebuild() -> void:
	for c in ui.get_children():
		c.queue_free()
	var names := topics()
	for i in names.size():
		ui.add_child(UiKit.selected(UiKit.button(String(names[i]),
			Vector2(LIST_X, LIST_Y + float(i) * LIST_STEP), Vector2(LIST_W, 44), func(k = i):
				tab = k
				Audio.play("tap")
				_rebuild()), i == tab))
	ui.add_child(UiKit.back_button("res://scenes/Start.tscn"))
	queue_redraw()


func page_rect() -> Rect2:
	return Rect2(PAGE_X, PAGE_Y, UiKit.right_edge() - PAGE_X, UiKit.bottom(24.0) - PAGE_Y)


func _draw() -> void:
	UiKit.set_mood(UiKit.Mood.NORMAL)
	UiKit.ground(self)
	var r := page_rect()
	UiKit.panel(self, r)
	UiKit.text(self, font, UiKit.t("GUIDE"), r.position + Vector2(24, 34), 12, UiKit.DIM)
	UiKit.text_fit(self, font, String(topics()[tab]), r.position + Vector2(24, 62), 22, UiKit.INK,
		r.size.x - 48.0)
	var w := r.size.x - 64.0
	## THE PAGE FITS ITS PANEL IN EVERY LANGUAGE: a longer translation steps the
	## whole page down a pixel at a time rather than running off the bottom.
	var px := 16
	var lh := LINE_H
	while px > 13 and _height(page(tab), w, px, lh) > r.end.y - 16.0 - (r.position.y + 100.0):
		px -= 1
		lh -= 1.0
	var y := r.position.y + 100.0
	for line in page(tab):
		draw_rect(Rect2(r.position.x + 26.0, y - 10.0, 6, 6), UiKit.YOU)
		var n := UiKit.para(self, font, String(line), Vector2(r.position.x + 44.0, y), px, UiKit.INK,
			w, lh, 3)
		y += float(n) * lh + GAP


func _height(lines: Array, w: float, px: int, lh: float) -> float:
	var h := 0.0
	for line in lines:
		h += float(mini(3, UiKit.wrap(font, String(line), w, px).size())) * lh + GAP
	return h
