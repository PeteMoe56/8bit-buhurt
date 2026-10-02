extends SceneTree
## NOVICE BOTS — layer 1 of the novice testing program (Pete, 1 Oct 2026:
## "I don't want the game to handhold, but I want it to be self sufficiently
## able to be learned").
##
## A bot plays the real game through its real screens and presses only buttons
## that are visible and enabled — the same rule `monkey.gd` keeps — but with a
## persona instead of a dice roll, and it writes down what a new player would
## run into: every new screen's words, every refusal, every dead end, and the
## milestones of a career.
##
##   godot --headless --fixed-fps 60 --path . --script res://tools/novice/novice_bot.gd \
##       -- <persona> <seed> <steps> <out.jsonl>
##
## Personas:
##   gold      presses the gold button; failing that, whatever moves the week on
##   wanderer  presses every button it has not pressed on this screen yet
##   simmer    skips, sims and fights; never reads
##   spender   buys whatever it can
##   hoarder   never spends a CC
##
## Fights: bots press only the buttons a fight shows (FIGHT, SKIP ROUND, HOLD,
## the corner, the report). A bot that has watched a round for WATCH frames
## presses SKIP ROUND — a real player who never touches the screen gets the
## same result, the sim is the same either way.

## How long a bot watches a round before it presses SKIP ROUND, in frames. A
## second: the bot learns nothing by watching and the run is long.
const WATCH := 60
const SPEND := ["buy", "hire", "sign", "build", "upgrade", "repair", "raise", "extend",
	"session", "unlock", "bid", "re-sign", "talk to", "tidy", "spend", "+", "cc"]
const MOVE := ["fight", "sim", "next", "continue", "play", "start", "take it", "end the season",
	"carry on", "back to the club", "done", "skip", "resume", "new career", "got it", "ok"]
## Never: these end the run or touch real money.
const NEVER := ["quit", "delete", "buy credits", "store", "credits & licenses"]

var persona := "gold"
var steps_wanted := 20000
var out_path := "user://novice.jsonl"
var rng := RandomNumberGenerator.new()
var out: FileAccess

var step := 0
var presses := 0
var wait := 0
var here := ""
var frames_here := 0
var fight_frames := 0
var state_key := ""
var states_seen := {}
var pressed_on := {}          ## state -> {label: true}
var last_flash := ""
var capture := 0
var capture_key := ""
var no_progress := 0
var progress_key := ""
var _pk_presses := -1

## Milestones.
var first := {}
var results_seen := 0
var last_tier := -1
var seasons_done := 0
var honors_seen := 0
var broke_events := 0
var relegations := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		persona = String(a[0])
	rng.seed = int(a[1]) if a.size() > 1 else 7
	steps_wanted = int(a[2]) if a.size() > 2 else steps_wanted
	out_path = String(a[3]) if a.size() > 3 else out_path
	seed(rng.seed)
	SaveGame.set_namespace("novice_%s_%d" % [persona, rng.seed])
	Settings.path = "user://novice_%s_%d_settings.cfg" % [persona, rng.seed]
	Store.wallet_prefix = "novice_%s_%d_" % [persona, rng.seed]
	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	Settings.tips_enabled = true
	Juice.set_enabled(false)
	out = FileAccess.open(out_path, FileAccess.WRITE)
	_log({"t": "start", "persona": persona, "seed": rng.seed, "steps": steps_wanted})
	change_scene_to_file("res://scenes/Start.tscn")


func _log(d: Dictionary) -> void:
	d["step"] = step
	out.store_line(JSON.stringify(d))


func _process(_delta: float) -> bool:
	var scene := current_scene
	if scene == null:
		return false
	var name: String = scene.scene_file_path.get_file().get_basename()
	if name != here:
		here = name
		frames_here = 0
		fight_frames = 0
	frames_here += 1
	## A capture in flight: the ledger is open across one redraw.
	if capture > 0:
		capture -= 1
		if capture == 0:
			_finish_capture(scene)
		return false
	if wait > 0:
		wait -= 1
		return false
	step += 1
	## ENGLISH THROUGHOUT: the wanderer found the language arrows in Settings and
	## the run went on in Japanese, where it no longer knew "Quit" when it saw it.
	if Settings.language != "en":
		Settings.set_language("en")
	_milestones(scene)
	if step >= steps_wanted:
		_finish("steps")
		return true
	if bool(first.get("worlds_won", false)) and persona != "wanderer":
		_finish("worlds")
		return true
	var key := _state(scene)
	if key != state_key:
		state_key = key
		if not states_seen.has(key):
			states_seen[key] = step
			_start_capture(scene, key)
			return false
	_refusal(scene)
	if name == "Melee":
		_fight(scene)
	else:
		_menu(scene)
	return false


## A SCREEN STATE is the scene, its tab, and the buttons it offers — so a popup
## opening is a new state, and the same tab with a different week is not.
func _state(scene: Node) -> String:
	var labels: Array = []
	for b in _buttons(scene):
		labels.append(_label(b))
	labels.sort()
	var tab = scene.get("tab")
	var scr = scene.get("screen")
	return "%s|%s|%s|%d" % [here, str(tab), str(scr), hash(",".join(labels))]


func _start_capture(scene: Node, key: String) -> void:
	capture_key = key
	UiKit.ledger_start()
	if scene is CanvasItem:
		(scene as CanvasItem).queue_redraw()
	capture = 2


func _finish_capture(scene: Node) -> void:
	var rows := UiKit.ledger_stop()
	var texts: Array = []
	for r in rows:
		var t := String(r.get("text", "")).strip_edges()
		if t != "" and not texts.has(t):
			texts.append(t)
	var labels: Array = []
	for b in _buttons(scene, true):
		var l := _label(b)
		if l != "" and not labels.has(l):
			labels.append(l)
	_log({"t": "screen", "scene": here, "key": capture_key, "texts": texts, "buttons": labels,
		"season": _season_no(), "event": _event_no()})


## ------------------------------------------------------------------- menus
func _menu(scene: Node) -> void:
	var buttons := _buttons(scene)
	if buttons.is_empty():
		if frames_here > 600:
			_log({"t": "stranded", "scene": here})
			AppLife.back_pressed()
			frames_here = 0
		return
	## A NAME BOX LEFT EMPTY IS FILLED, as a person would: a refusal for an empty
	## name is logged once (it happened on step 7 of the first run) and then the
	## bot types, because no player sits pressing Next forever.
	for e in _edits(scene):
		if String(e.text).strip_edges() == "" and last_flash != "":
			var t: String = ["Sam", "Ridge", "Ironside", "Kane"][rng.randi() % 4]
			e.text = t
			e.text_changed.emit(t)
			_log({"t": "type", "scene": here, "text": t, "hint": e.placeholder_text})
			wait = 1
			return
	var b := _choose(buttons)
	if b == null:
		AppLife.back_pressed()
		_log({"t": "press", "scene": here, "label": "<back>"})
		wait = 2
		return
	_press(b)


func _press(b: Button) -> void:
	var l := _label(b)
	if not pressed_on.has(state_key):
		pressed_on[state_key] = {}
	pressed_on[state_key][l] = true
	presses += 1
	_last_pressed = l
	_log({"t": "press", "scene": here, "label": l, "primary": b.has_meta("primary")})
	if not first.has("first_fight_press") and l.to_lower() == "fight" and here == "Melee":
		first["first_fight_press"] = presses
		_log({"t": "milestone", "kind": "first_fight", "presses": presses})
	b.pressed.emit()
	wait = 1


func _choose(buttons: Array) -> Button:
	var safe: Array = buttons.filter(func(b): return not _has(_label(b), NEVER))
	if safe.is_empty():
		return null
	match persona:
		"gold":
			for b in safe:
				if b.has_meta("primary"):
					return b
			return _weighted(safe, {"move": 6.0, "spend": 1.0})
		"wanderer":
			var seen: Dictionary = pressed_on.get(state_key, {})
			var fresh: Array = safe.filter(func(b): return not seen.has(_label(b)))
			## LEAVES BY BACK once a screen is exhausted, half the time — a curious
			## player goes back to look at the next thing.
			if fresh.is_empty():
				if here != "Start" and rng.randf() < 0.5:
					return null
				return _weighted(safe, {"move": 6.0, "spend": 1.0})
			return fresh[rng.randi() % fresh.size()]
		"simmer":
			return _weighted(safe, {"move": 20.0, "spend": 0.2, "skip": 30.0})
		"spender":
			return _weighted(safe, {"move": 3.0, "spend": 8.0})
		"hoarder":
			var keep: Array = safe.filter(func(b): return not _has(_label(b), SPEND) or _has(_label(b), MOVE))
			if keep.is_empty():
				return null
			for b in keep:
				if b.has_meta("primary"):
					return b
			return _weighted(keep, {"move": 6.0, "spend": 0.0})
	return safe[rng.randi() % safe.size()]


func _weighted(buttons: Array, w: Dictionary) -> Button:
	var ws: Array[float] = []
	var total := 0.0
	for b in buttons:
		var l := _label(b).to_lower()
		var x := 1.0
		if _has(l, MOVE):
			x = float(w.get("move", 1.0))
		elif _has(l, SPEND):
			x = float(w.get("spend", 1.0))
		if l.find("skip") != -1 and w.has("skip"):
			x = float(w["skip"])
		if b.has_meta("primary"):
			x *= 2.0
		ws.append(x)
		total += x
	if total <= 0.0:
		return buttons[rng.randi() % buttons.size()]
	var r := rng.randf() * total
	for i in buttons.size():
		r -= ws[i]
		if r <= 0.0:
			return buttons[i]
	return buttons[-1]


## ------------------------------------------------------------------- fights
func _fight(scene: Node) -> void:
	var buttons := _buttons(scene)
	var live := buttons.filter(func(b): return _label(b).to_lower().find("skip") != -1)
	fight_frames += 1
	if not live.is_empty():
		## In a round. Simmers skip at once; everyone else watches a while.
		if persona == "simmer" or fight_frames > WATCH:
			fight_frames = 0
			_press(live[0])
		return
	fight_frames = 0
	if buttons.is_empty():
		return
	var b := _choose(buttons)
	if b != null:
		_press(b)


## ------------------------------------------------------------------- what happened
func _refusal(scene: Node) -> void:
	var f = scene.get("flash")
	var s := String(f) if f != null else ""
	if s != "" and s != last_flash:
		_log({"t": "flash", "scene": here, "text": s, "after": _last_label()})
	last_flash = s


var _last_pressed := ""


func _last_label() -> String:
	return _last_pressed


func _milestones(_scene: Node) -> void:
	var s: Season = Session.season
	if s == null:
		return
	var tier := s.world.player_tier()
	if last_tier == -1:
		last_tier = tier
	if s.results.size() > results_seen:
		for i in range(results_seen, s.results.size()):
			var r: Dictionary = s.results[i]
			if bool(r.get("fought", false)) and int(r.get("rf", 0)) > int(r.get("ra", 0)):
				_first("first_win")
		results_seen = s.results.size()
	if tier > last_tier:
		_first("first_promotion")
		_log({"t": "milestone", "kind": "promoted", "tier": tier, "season": s.world.season})
	elif tier < last_tier:
		relegations += 1
		_log({"t": "milestone", "kind": "relegated", "tier": tier, "season": s.world.season})
	last_tier = tier
	if s.world.history.size() > seasons_done:
		seasons_done = s.world.history.size()
		var h: Dictionary = s.world.history[-1]
		_log({"t": "season_end", "season": int(h.get("season", 0)), "tier": int(h.get("tier", 0)),
			"position": int(h.get("position", 0)), "credits": s.office.credits,
			"roster": s.club.roster.size(), "coach_level": s.coach.level})
		## Results reset each season.
		results_seen = 0
	if s.office.credits < 0:
		broke_events += 1
		if broke_events == 1:
			_log({"t": "milestone", "kind": "broke", "season": s.world.season, "credits": s.office.credits})
	if s.world.honors.size() > honors_seen:
		for i in range(honors_seen, s.world.honors.size()):
			var h2: Dictionary = s.world.honors[i]
			if int(h2.get("champion", -1)) == s.world.player_club:
				var id := String(h2.get("id", ""))
				_log({"t": "milestone", "kind": "trophy", "id": id, "name": String(h2.get("name", "")),
					"season": int(h2.get("season", 0))})
				if id.begins_with("playoff"):
					_first("first_title")
				elif id == "worlds":
					_first("worlds_won")
				else:
					_first("first_cup")
		honors_seen = s.world.honors.size()
	## STUCK: the season has not moved in 400 presses.
	var pk := "%d:%d" % [s.world.season, s.world.event]
	if pk == progress_key:
		if presses != _pk_presses:
			no_progress += 1
			_pk_presses = presses
		if no_progress == 400:
			_log({"t": "stuck", "scene": here, "at": pk})
	else:
		progress_key = pk
		no_progress = 0


func _first(kind: String) -> void:
	if first.has(kind):
		return
	first[kind] = true
	var s: Season = Session.season
	_log({"t": "milestone", "kind": kind, "presses": presses,
		"season": s.world.season if s != null else 0})


func _season_no() -> int:
	return Session.season.world.season if Session.season != null else 0


func _event_no() -> int:
	return Session.season.world.event if Session.season != null else 0


func _finish(why: String) -> void:
	var s: Season = Session.season
	_log({"t": "end", "why": why, "presses": presses, "states": states_seen.size(),
		"season": s.world.season if s != null else 0,
		"tier": s.world.player_tier() if s != null else -1,
		"credits": s.office.credits if s != null else 0,
		"relegations": relegations, "first": first})
	out.close()
	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Store.wallet_path()))
	print("novice %s %d: %s after %d steps, %d presses, season %d" % [persona, rng.seed, why,
		step, presses, s.world.season if s != null else 0])
	quit(0)


## ------------------------------------------------------------------- buttons
func _label(b: Button) -> String:
	var t := String(b.text).strip_edges()
	if t == "" and b.has_meta("mark"):
		t = "[%s]" % String(b.get_meta("mark"))
	if t == "" and b.tooltip_text != "":
		t = b.tooltip_text
	return t


static func _has(l: String, words: Array) -> bool:
	var low := l.to_lower()
	for w in words:
		if low.find(String(w)) != -1:
			return true
	return false


func _edits(n: Node) -> Array:
	var outv: Array = []
	_collect_edits(n, outv)
	return outv


func _collect_edits(n: Node, outv: Array) -> void:
	for c in n.get_children():
		if c is LineEdit and (c as LineEdit).is_visible_in_tree():
			outv.append(c)
		_collect_edits(c, outv)


func _buttons(n: Node, include_disabled := false) -> Array:
	var outv: Array = []
	_collect(n, outv, include_disabled)
	var veil := modal_layer(n)
	return outv.filter(func(b): return layer_of(b) >= veil)


func _collect(n: Node, outv: Array, include_disabled: bool) -> void:
	for c in n.get_children():
		if c is Button:
			var b := c as Button
			if b.is_visible_in_tree() and (include_disabled or not b.disabled):
				outv.append(b)
		_collect(c, outv, include_disabled)


## A BUTTON UNDER A MODAL VEIL IS NOT THERE FOR A FINGER. The fight's tutorial
## card is a full-screen catch on a higher CanvasLayer; a tester pressing by
## number reached HOLD through it, which no thumb can (first-timer test, 1 Oct).
static func layer_of(n: Node) -> int:
	var p := n.get_parent()
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


static func modal_layer(root_n: Node) -> int:
	var best := -1000000
	var stack: Array = [root_n]
	var screen := UiKit.screen()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is Control and not (c is Button):
				var ctl := c as Control
				if ctl.is_visible_in_tree() and ctl.mouse_filter == Control.MOUSE_FILTER_STOP \
						and ctl.size.x >= screen.x * 0.9 and ctl.size.y >= screen.y * 0.9:
					best = maxi(best, layer_of(ctl))
	return best
