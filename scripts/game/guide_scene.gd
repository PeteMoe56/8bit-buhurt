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
const LIST_STEP := 44.0  ## ten topics and Back (10 Oct 2026: The wheel)
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
## The pages, by name, for a button that opens one (`Session.guide_topic`).
enum Topic { SEASON, TABLE, FIGHT, WHEEL, TEAM, TRAINING, KIT, MONEY, UPGRADES, COACH }


static func topics() -> Array:
	return [
		UiKit.t("The season"),
		UiKit.t("The table"),
		UiKit.t("The fight"),
		UiKit.t("The wheel"),
		UiKit.t("Your team"),
		UiKit.t("Training"),
		UiKit.t("Kit & armorer"),
		UiKit.t("Money"),
		UiKit.t("Upgrades"),
		UiKit.t("Your coach"),
	]


## WHAT EACH PAGE SAYS beside its picture (Pete, 10 Oct 2026: "make the guide
## actually show pictures and explanations, those lists are way too cluttered").
## `notes` go with the gold numbers `GuideArt.draw` puts on the picture, in
## order; `tips` sit under them, smaller. Every line here is checked against the
## code that does the thing — `docs/` is not the source.
static func page(i: int) -> Dictionary:
	match i:
		Topic.SEASON: return {
			"notes": [
				UiKit.t("You start here."),
				UiKit.t("The top four go to the playoff. Both finalists go up a division."),
				UiKit.t("The bottom two go down. Nobody goes down from the Backyard Circuit."),
				UiKit.t("Backyard, State, Regional, National. Win the National playoff to go to the Worlds."),
			],
			"tips": [
				UiKit.t("Each Saturday is one event: a league day, a cup weekend, a bye week or the playoff."),
				UiKit.t("Top three when a cup weekend comes around are invited, if your insurance is high enough."),
			],
		}
		Topic.TABLE: return {
			"notes": [
				UiKit.t("RD: rounds won minus rounds lost."),
				UiKit.t("MG: margin. Men left standing when you won a round, minus the same against you."),
				UiKit.t("PTS: 3 for a win, 1 for a draw."),
				UiKit.t("Green rows go to the playoff. Red rows go down."),
			],
			"tips": [
				UiKit.t("Level on points? MG decides first, then RD."),
				UiKit.t("P played · W won · D drawn · L lost"),
			],
		}
		Topic.FIGHT: return {
			"notes": [
				UiKit.t("Five against five. Best of three rounds, two minutes each."),
				UiKit.t("HOLD freezes the fight so you can give one order. You get two a bout."),
				UiKit.t("A round ends when a side is wiped out, it is three on one, or time runs out. More men standing wins it."),
				UiKit.t("Rounds you have won. Two wins the bout."),
				UiKit.t("A man who goes down stays down until the round is over."),
			],
			"tips": [
				UiKit.t("Between rounds you can swap in up to two men from the bench. Rested men come back fresher."),
				UiKit.t("Your Playbook plan steers your line for the opening seconds of each round."),
			],
		}
		Topic.WHEEL: return {
			"notes": [
				UiKit.t("The move."),
				UiKit.t("5%/23%: his chance to put the man down, then the chance he falls instead."),
				UiKit.t("Hit always lands. This is the balance it takes off."),
				UiKit.t("Cancel: back to the fight."),
			],
			"tips": [
				UiKit.t("Drag your man onto an enemy to send him. When he gets there the fight stops and his three choices open in the corner."),
				UiKit.t("Reach a man already tied up with someone and you can bullrush him while he isn't looking."),
			],
		}
		Topic.TEAM: return {
			"notes": [
				UiKit.t("OVR is how good he is now. POT is as good as he can get."),
				UiKit.t("Strength puts men down. Base keeps him up. Skill wins the grapple. Gas is his tank."),
				UiKit.t("Bouts and practice give XP. A full bar is a level: +%d to the stat you pick, on his page.") % Career.POINTS_PER_LEVEL,
				UiKit.t("His deal is $ a year, counted against your salary cap. Extend early and he costs less."),
			],
			"tips": [
				UiKit.t("Five starters, three on the bench, up to four in reserve. Reserves do not travel."),
				UiKit.t("Unhappy men turn down new deals and walk. Men start to retire from 33."),
			],
		}
		Topic.TRAINING: return {
			"notes": [
				UiKit.t("Hire up to two captains. Each teaches roles: Rail, Flanker or Center."),
				UiKit.t("A role nobody teaches gets no training over the winter."),
				UiKit.t("Light: less XP, happier men. Normal: steady. Hard: half again the XP, but more knocks and grumbling."),
				UiKit.t("Session: once in a fight week, pay CC for an extra week of practice."),
			],
			"tips": [
				UiKit.t("Winter camp: your training ground and captains share out points over the winter."),
				UiKit.t("Invest: once a year, tap Invest on a man's page for +3 POT at the winter. Needs training ground 3."),
			],
		}
		Topic.KIT: return {
			"notes": [
				UiKit.t("Your armorer's stars are the best metal he can make and keep up. More stars, more wage."),
				UiKit.t("Metals: Rust, Mild, Hardened, Stainless, Titanium. Better metal wears slower."),
				UiKit.t("Every fight wears the kit of the men who fought it. Training does not."),
				UiKit.t("Every man's harness has a metal and a condition. Below the pass mark he cannot fight."),
			],
			"tips": [
				UiKit.t("Repair each man once a week, in a fight week. Each winter your armorer restores every harness to the best its own metal allows."),
				UiKit.t("Worn kit makes a man easier to put down."),
			],
		}
		Topic.MONEY: return {
			"notes": [
				UiKit.t("CC comes in from the gate at every event, the bar at home games, wins, draws and where you finish."),
				UiKit.t("Each summer you pay upkeep on your ground, buildings, insurance and armorer. Division dues come at the start of a season."),
				UiKit.t("CC is club money. Everything you buy costs CC."),
				UiKit.t("$ is a fighter's yearly wage. It never comes out of CC. It only has to fit under your salary cap."),
			],
			"tips": [UiKit.t("Cannot pay a bill? That thing drops a level.")],
		}
		Topic.UPGRADES: return {
			"notes": [
				UiKit.t("Ground: more seats, more gate. Fenced ground for State, Arena for Regional, National Arena for National."),
				UiKit.t("Training ground: more winter camp and practice."),
				UiKit.t("Infirmary: fewer knocks, and injured men come back sooner."),
				UiKit.t("Insurance: State needs 1, Regional 2, National 3. Without it, no cups and no Worlds."),
			],
			"tips": [
				UiKit.t("Salary cap: more room for wages."),
				UiKit.t("Everything you build costs upkeep each summer. One job per building per week."),
			],
		}
	var notes: Array = [UiKit.t("Wins, finishes, cup runs and promotion give your coach XP. Each level is a skill point.")]
	## THE SAME LINES AS THE "?" ON YOUR COACH PAGE, so the two can never disagree.
	for k in 5:
		notes.append(COACH.skill_help(k))
	return {"notes": notes, "tips": []}


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	season = Session.season
	if Session.guide_topic >= 0:
		tab = clampi(Session.guide_topic, 0, topics().size() - 1)
		Session.guide_topic = -1
	ui = CanvasLayer.new()
	add_child(ui)
	## CENTRED ON A WIDE PHONE (2 Oct 2026 playtest): see `UiKit.frame`.
	UiKit.frame(self, ui)
	_rebuild()


func _rebuild() -> void:
	for c in ui.get_children():
		c.queue_free()
	var names := topics()
	for i in names.size():
		ui.add_child(UiKit.selected(UiKit.button(String(names[i]),
			Vector2(LIST_X, LIST_Y + float(i) * LIST_STEP), Vector2(LIST_W, LIST_STEP - 4.0), func(k = i):
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
	_draw_page(r, page(tab))


const MARK_R := 13.0


## THE PICTURE ON THE LEFT, its numbered lines on the right and the tips under
## them. The words step down a pixel at a time until the page fits its panel,
## in every language.
func _draw_page(r: Rect2, pg: Dictionary) -> void:
	var at := r.position + Vector2(30.0, 100.0)
	var marks: Dictionary = GuideArt.draw(self, font, tab, at)
	for k in marks:
		_number(Vector2(marks[k]), int(k))
	var x := at.x + GuideArt.W + 36.0
	var w := r.end.x - 24.0 - x
	var notes: Array = pg["notes"]
	var tips: Array = pg["tips"]
	var px := 16
	while px > 12 and _page_height(notes, tips, w, px) > r.end.y - 20.0 - (at.y - 6.0):
		px -= 1
	var lh := float(px) + 5.0
	var y := at.y + 8.0
	for k in notes.size():
		_number(Vector2(x + MARK_R, y - 5.0), k + 1)
		var n := UiKit.para(self, font, String(notes[k]), Vector2(x + 32.0, y), px, UiKit.INK, w - 32.0, lh, 5)
		y += float(n) * lh + 10.0
	if not tips.is_empty():
		y += 4.0
		draw_rect(Rect2(x, y - 12.0, w, 2.0), UiKit.FRAME)
		y += 10.0
	for t in tips:
		var n2 := UiKit.para(self, font, String(t), Vector2(x, y), px - 1, UiKit.DIM, w, lh - 1.0, 5)
		y += float(n2) * (lh - 1.0) + 8.0


func _page_height(notes: Array, tips: Array, w: float, px: int) -> float:
	var lh := float(px) + 5.0
	var h := 0.0
	for n in notes:
		h += float(mini(5, UiKit.wrap(font, String(n), w - 32.0, px).size())) * lh + 10.0
	if not tips.is_empty():
		h += 14.0
	for t in tips:
		h += float(mini(5, UiKit.wrap(font, String(t), w, px - 1).size())) * (lh - 1.0) + 8.0
	return h


## A gold disc with a dark number, the same on the picture and beside its line.
func _number(p: Vector2, k: int) -> void:
	draw_circle(p, MARK_R + 2.0, UiKit.BG)
	draw_circle(p, MARK_R, UiKit.YOU)
	UiKit.mid(self, font, str(k), p + Vector2(-MARK_R, 5.0), 14, UiKit.BG, MARK_R * 2.0)

