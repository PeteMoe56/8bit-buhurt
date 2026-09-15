class_name Juice
extends RefCounted
## THE FEEL LAYER — timing, not pictures.
##
## A pixel font and a limited palette make a game LOOK retro. This is what makes
## it feel like a machine. A NES had no tweening, no easing curves and no
## particle systems, and it still hit harder than most modern UI, because
## everything happened on a frame boundary and nothing was ever half-way.
##
## Every effect in here is individually trivial. What is not trivial, and what
## this file exists to hold, is the three rules that stop them from turning the
## game into confetti:
##
##   * **THE PIXEL-SNAP RULE** — every position this file hands out is rounded
##     before it is used. Shake, rising numbers and wipes are all machines for
##     generating fractional coordinates, and one un-snapped element makes a
##     whole scene look soft. The eye catches it without being able to name it.
##   * **THE FRAME-LADDER RULE** — animation steps on a ladder of frames, not on
##     a continuous curve. If a designer would have had to draw it as cels, step
##     it. This is the actual difference between *retro* and *retro-themed*, and
##     it is almost always what is missing from games that have the pixel art
##     and still feel wrong.
##   * **THE BUDGET RULE** — two juice EVENTS at once, never three.
##
## THE BUDGET COUNTS EVENTS, NOT EFFECTS, and the distinction is the whole
## design. A knockout freezes the sim, shakes the screen and flashes the palette
## — that is one coherent thing happening, not three competing ones, and a
## ceiling that counted effects would silently swallow the flash and leave the
## biggest moment in the game half-played. So a caller announces an *event* with
## a rank, the event applies whatever set of effects it owns, and it is the
## events that are capped. A higher-ranked event evicts a lower-ranked one; an
## equal or lower one is dropped. A knockout can never lose to two taps.
##
## NO AUTOLOAD (constraint 06.5). This is a static holder, like `Session` and
## `Tuning`, and the one node it needs is built lazily and parented to the
## WINDOW — the same trick `Audio` uses, for the same reason: a node under the
## current scene dies on every scene change, and a screen wipe that dies halfway
## through a screen change is worse than no wipe at all.
##
## AND IT IS INERT HEADLESS. Every function here is pure arithmetic over static
## state; nothing touches the tree unless `arm()` is called. The suite drives it
## with a hand-cranked delta and asserts the timings directly.

# --------------------------------------------------------------- the numbers
## RISES 12px OVER 400ms, then holds 200ms, then gone. Not longer. The hold is
## what makes it readable — a number that moves for its whole life is a number
## you have to chase.
const POP_RISE := 12.0
const POP_RISE_S := 0.40
const POP_HOLD_S := 0.20
## SIX STEPS, 2px each. Sub-pixel motion is the single most modern-looking thing
## a retro game can do, and a rising number is the place it would show first.
const POP_STEPS := 6
## Per source, and the cap is the point — see `pop()`.
const POP_QUEUE := 4

## TRAUMA, NOT EVENTS. Keep a float, add to it on impact, decay it every frame,
## and offset by `trauma² × max`. Squaring is what makes a small hit subtle and
## a big one violent without two code paths and without a magic table.
const SHAKE_MAX := 4.0
const TRAUMA_DECAY := 1.6
## The offset is re-rolled every second frame, not every frame. A shake that
## picks a new direction 60 times a second is a blur; one that picks 30 times a
## second is a shake.
const SHAKE_HOLD := 2

## HIT PAUSE — two lines, and the single largest perceived-impact gain
## available. Every fighting game since Street Fighter II does it and almost no
## management game does.
const FREEZE_HIT := 0.08
const FREEZE_BIG := 0.20
const FREEZE_KO := 0.35

## TWO FRAMES. 33ms at 60fps — under conscious perception, and the player feels
## it anyway. Counted in frames rather than seconds on purpose: this is the one
## effect whose whole character is that it is exactly two frames long.
const FLASH_FRAMES := 2

## A COLUMN OF BLOCKS ON THE 8px GRID, eight steps, 130ms each way. No fades —
## a fade is a 32-bit idea. The rule that matters: every transition is under
## 200ms. Anything longer is a load screen wearing a costume.
const WIPE_STEPS := 8
const WIPE_BLOCK := 8.0
const WIPE_S := 0.13

## ONE CHARACTER PER TWO FRAMES, and never on numbers or tables — a roster that
## types itself in is a roster you cannot read.
const TYPE_FRAMES := 2

## TWO EVENTS AT ONCE, NEVER THREE.
const BUDGET := 2

## The ranks, so a caller does not invent one. Anything may evict something
## strictly below it and nothing else.
enum Rank {TAP = 1, HIT = 2, BIG = 3, HUGE = 4}


# ---------------------------------------------------------------- the state
static var _frame: int = 0
static var _freeze: float = 0.0
static var _trauma: float = 0.0
static var _flash: int = 0
static var _flash_col := Color(1, 1, 1, 1)
static var _events: Array[Dictionary] = []
static var _pops: Array[Dictionary] = []
static var _queued: Dictionary = {}
static var _typers: Dictionary = {}
static var _wipe: Dictionary = {}
static var _pending_scene: String = ""
static var _dropped: int = 0
static var _enabled: bool = true


## Back to nothing. The suite calls this between checks; so does `arm()`, so a
## wipe left half-finished by a crash cannot black out the next run.
static func reset() -> void:
	_frame = 0
	_freeze = 0.0
	_trauma = 0.0
	_flash = 0
	_events.clear()
	_pops.clear()
	_queued.clear()
	_typers.clear()
	_wipe = {}
	_pending_scene = ""
	_dropped = 0
	_purse = PURSE_UNSEEN


# ----------------------------------------------------------------- the rules
## THE FRAME LADDER. A progress of 0..1 quantised to whole steps. Everything
## that moves in this file goes through here, which is why nothing in it can
## accidentally become smooth.
static func ladder(t01: float, steps: int) -> float:
	if steps <= 0:
		return clampf(t01, 0.0, 1.0)
	var s := floorf(clampf(t01, 0.0, 1.0) * float(steps))
	return minf(s, float(steps)) / float(steps)


## THE PIXEL SNAP. Whole pixels, always, no exceptions and no opinions about
## whether this particular one would have shown.
static func snap(v: Vector2) -> Vector2:
	return Vector2(roundf(v.x), roundf(v.y))


# ---------------------------------------------------------------- the events
## ANNOUNCE AN EVENT and let it apply its own effects.
##
## `spec` may carry `freeze` (seconds), `trauma` (0..1), `flash` (a Color), and
## `sound` (an `Audio.SOUNDS` id). Returns whether it was allowed — callers
## almost never care, but the suite does, and so does `dropped()`.
static func event(name: String, rank: int, spec: Dictionary) -> bool:
	if not _enabled:
		return false
	if not _claim(name, rank, float(spec.get("hold", 0.25))):
		_dropped += 1
		return false
	if spec.has("freeze"):
		_freeze = maxf(_freeze, float(spec["freeze"]))
	if spec.has("trauma"):
		_trauma = clampf(_trauma + float(spec["trauma"]), 0.0, 1.0)
	if spec.has("flash"):
		_flash = FLASH_FRAMES
		_flash_col = spec["flash"]
	if spec.has("sound"):
		Audio.play(String(spec["sound"]))
	return true


## THE CEILING, enforced in one place. A slot is free, or the weakest thing
## running is weaker than what is asking — otherwise the answer is no.
static func _claim(name: String, rank: int, hold: float) -> bool:
	for e in _events:
		if String(e["name"]) == name:
			e["rank"] = maxi(int(e["rank"]), rank)
			e["t"] = 0.0
			e["hold"] = maxf(float(e["hold"]), hold)
			return true
	if _events.size() < BUDGET:
		_events.append({"name": name, "rank": rank, "t": 0.0, "hold": hold})
		return true
	var weakest := 0
	for i in _events.size():
		if int(_events[i]["rank"]) < int(_events[weakest]["rank"]):
			weakest = i
	if rank <= int(_events[weakest]["rank"]):
		return false
	_events.remove_at(weakest)
	_events.append({"name": name, "rank": rank, "t": 0.0, "hold": hold})
	return true


static func live_events() -> int:
	return _events.size()


## How many events the ceiling has refused. The suite asserts this rather than
## asserting that nothing bad looked like it happened.
static func dropped() -> int:
	return _dropped


# --------------------------------------------------------------- the effects
## A MAN GOES DOWN. Scaled by what kind of down it was, because an ordinary one
## and the fifth one are not the same event wearing different numbers.
static func down(fifth: bool = false, knockout: bool = false) -> void:
	if knockout:
		event("down", Rank.HUGE, {"freeze": FREEZE_KO, "trauma": 0.85,
			"flash": Color(1, 1, 1, 1), "sound": "down", "hold": 0.5})
	elif fifth:
		event("down", Rank.BIG, {"freeze": FREEZE_BIG, "trauma": 0.55,
			"sound": "down", "hold": 0.35})
	else:
		event("down", Rank.HIT, {"freeze": FREEZE_HIT, "trauma": 0.35,
			"sound": "down", "hold": 0.2})


## THE PALETTE FLASH on its own, for the things that are big without being hits
## — a cup won, a promotion. Nothing smaller: a flash the player sees twice an
## hour is an event, one he sees twice a minute is a fault in the screen.
static func fanfare() -> void:
	event("fanfare", Rank.HUGE,
		{"flash": Color(1, 1, 1, 1), "sound": "fanfare", "hold": 0.6})


## THE REFUSAL. This game says no constantly — over the cap, one job a week, not
## entered for the cups — and those refusals currently land as a line of red
## text. A hard little nudge makes a refusal feel like a RULE rather than like
## a bug, which is the entire difference.
static func refuse() -> void:
	event("refuse", Rank.TAP, {"trauma": 0.22, "hold": 0.15})


static func frozen() -> bool:
	return _freeze > 0.0


static func flashing() -> bool:
	return _flash > 0


## WHOLE PIXELS, AND ONLY EVERY SECOND FRAME. Squared trauma, re-rolled on the
## ladder, snapped on the way out.
static func shake_offset() -> Vector2:
	if _trauma <= 0.0:
		return Vector2.ZERO
	var amp := _trauma * _trauma * SHAKE_MAX
	var step := int(_frame / SHAKE_HOLD)
	var a := float(_hash(step)) / 4294967295.0 * TAU
	var b := float(_hash(step + 7919)) / 4294967295.0
	return snap(Vector2(cos(a), sin(a)) * amp * (0.5 + 0.5 * b))


static func trauma() -> float:
	return _trauma


static func _hash(n: int) -> int:
	var x := (n * 2654435761) & 0xFFFFFFFF
	x = (x ^ (x >> 15)) & 0xFFFFFFFF
	x = (x * 2246822519) & 0xFFFFFFFF
	x = (x ^ (x >> 13)) & 0xFFFFFFFF
	return x


# ---------------------------------------------------------------- the popups
## A NUMBER THAT LANDS. `+2`, `−4 CC`, `DOWN`, `+1 XP`.
##
## ONE AT A TIME PER SOURCE, and that is not a performance limit — five
## simultaneous popups is confetti, and confetti reads as a mobile F2P game,
## which this is not. A second popup from the same source waits its turn; a
## fifth is dropped, because by then nobody is reading them anyway.
static func pop(source: String, text_: String, at: Vector2, col: Color) -> void:
	if not _enabled or text_ == "":
		return
	var item := {"text": text_, "at": snap(at), "col": col, "t": 0.0}
	for p in _pops:
		if String(p["source"]) == source:
			var q: Array = _queued.get(source, [])
			if q.size() >= POP_QUEUE:
				return
			q.append(item)
			_queued[source] = q
			return
	item["source"] = source
	_pops.append(item)


## The live popups, each as {text, at, col, alpha}, already snapped and already
## on the ladder. A caller draws them; it does not compute them.
## DROP EVERYTHING STILL IN THE AIR. A screen that covers the fight — the corner,
## the report — has overtaken the numbers rising over it: a "DOWN" from the round
## just ended, drawn on top of the panel reporting that round, is the fight
## arguing with its own summary. `reset()` is too big a hammer; this is the one
## thing that needs clearing.
static func clear_pops() -> void:
	_pops.clear()
	_queued.clear()


static func popups() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in _pops:
		var t := float(p["t"])
		var rise := ladder(minf(t / POP_RISE_S, 1.0), POP_STEPS) * POP_RISE
		var col: Color = p["col"]
		## It does not fade. It holds and then it is gone — a fade is a smooth
		## thing and there is nothing smooth in here.
		out.append({
			"text": String(p["text"]),
			"at": snap(Vector2(float(p["at"].x), float(p["at"].y) - rise)),
			"col": col,
		})
	return out


static func live_popups() -> int:
	return _pops.size()


## THE PURSE, WATCHED RATHER THAN HOOKED.
##
## Credits are written in twenty-nine places — the workshop, the chalkboard, the
## market, wages, gate money, a dilemma that costs you. Hooking all of them
## would be twenty-nine chances to miss one, and the one missed would be the
## one that mattered. So this watches the number the player is actually LOOKING
## AT: `UiKit.purse()` draws it and reports it here, and a difference between
## two sightings is a change worth popping. It cannot disagree with the screen,
## because it IS the screen.
##
## FIRST SIGHTING ARMS IT AND POPS NOTHING. Otherwise opening the game would
## announce your entire balance as a gain.
const PURSE_UNSEEN := -2147483648
static var _purse: int = PURSE_UNSEEN


static func purse(now: int, at: Vector2) -> void:
	if _purse == PURSE_UNSEEN:
		_purse = now
		return
	if now == _purse:
		return
	var d := now - _purse
	_purse = now
	if not _enabled:
		return
	pop("purse", ("+%d CC" % d) if d > 0 else ("%d CC" % d), at,
		UiKit.UP if d > 0 else UiKit.DOWN)
	if d > 0:
		Audio.play("coin")


## LOADING A SAVE IS NOT EARNING. The balance jumps because a different career
## is on screen, and announcing that as a gain of four hundred credits would be
## a lie told with a sound effect.
static func forget_purse() -> void:
	_purse = PURSE_UNSEEN


# ----------------------------------------------------------------- the typer
## ONE CHARACTER PER TWO FRAMES. For a dilemma card, a job offer, the summer
## report — never for numbers or tables.
static func type_start(id: String, full: String) -> void:
	_typers[id] = {"full": full, "n": 0.0}


## What to draw this frame.
static func typed(id: String) -> String:
	var t: Dictionary = _typers.get(id, {})
	if t.is_empty():
		return ""
	return String(t["full"]).substr(0, int(t["n"]))


## A TAP SKIPS TO THE END, always. A player who has read it faster than the
## machine can print it must never be made to wait, and every game that has ever
## made him wait has been wrong to.
static func type_skip(id: String) -> void:
	var t: Dictionary = _typers.get(id, {})
	if not t.is_empty():
		t["n"] = float(String(t["full"]).length())


static func type_done(id: String) -> bool:
	var t: Dictionary = _typers.get(id, {})
	if t.is_empty():
		return true
	return int(t["n"]) >= String(t["full"]).length()


# ------------------------------------------------------------ the transition
## LEAVE THIS SCREEN FOR THAT ONE. Blocks sweep across on the 8px grid, the
## scene changes behind them at the midpoint, and they sweep off.
##
## The scene change happens BEHIND the cover, which is the only reason this is
## worth having: a hard cut is always acceptable and is the right default for a
## tab switch, but a cut in the middle of a wipe is a flicker, and a wipe that
## finishes before the scene changes is a load screen wearing a costume.
static func go(path: String) -> void:
	if not _enabled:
		_pending_scene = path
		return
	arm()
	_wipe = {"t": 0.0, "path": path, "taken": false}


static func wiping() -> bool:
	return not _wipe.is_empty()


## 0 while the screen is clear, 1 when it is fully covered. On the ladder, so
## the cover arrives in eight discrete columns and not as a sliding edge.
static func wipe_cover() -> float:
	if _wipe.is_empty():
		return 0.0
	var t := float(_wipe["t"])
	var half := WIPE_S
	if t <= half:
		return ladder(t / half, WIPE_STEPS)
	return 1.0 - ladder((t - half) / half, WIPE_STEPS)


## WHICH SIDE THE COVER IS ANCHORED TO. It builds up from the left and then
## slides OFF to the right, rather than retreating back the way it came — a
## curtain that comes in and goes out on the same side reads as a mistake
## being undone, and a curtain that crosses reads as a move. Same eight steps
## either way; only the anchor changes.
static func wipe_from_right() -> bool:
	if _wipe.is_empty():
		return false
	return float(_wipe["t"]) > WIPE_S


## The scene the wipe has reached the midpoint of, once. Returns "" every other
## time it is asked, so the caller cannot change scene twice.
static func take_pending_scene() -> String:
	var p := _pending_scene
	_pending_scene = ""
	return p


# ------------------------------------------------------------- idle movement
## NOTHING IN A RETRO GAME IS EVER COMPLETELY STILL. One pixel every half
## second is what stops a paused screen looking crashed, and it is the whole
## effect — two pixels is a wobble and a wobble is a bug.
static func breathe(period_frames: int = 30) -> float:
	if period_frames <= 0:
		return 0.0
	return 1.0 if int(_frame / period_frames) % 2 == 1 else 0.0


static func blink(period_frames: int = 24) -> bool:
	if period_frames <= 0:
		return true
	return int(_frame / period_frames) % 2 == 0


## `frame()` used to be here — a public getter for `_frame` that nothing outside
## this file ever asked for. Deleted 15 Sep 2026. Everything that wants to pace
## itself has `blink()` or `breathe()`, which answer the question the caller
## actually has instead of handing out a counter to do arithmetic on.


# -------------------------------------------------------------------- the tick
## ONE CALL, EVERY FRAME, and it is the node below that makes it. Pure
## arithmetic over static state — the suite drives it with a hand-cranked delta
## and asserts the timings directly rather than watching a screen.
##
## THE FREEZE DOES NOT FREEZE THIS. It cannot: a hit pause that paused its own
## timer would never end. Only the SIM asks `frozen()`; everything in here runs
## on real time.
static func tick(delta: float) -> void:
	_frame += 1
	_freeze = maxf(0.0, _freeze - delta)
	_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
	if _flash > 0:
		_flash -= 1

	for i in range(_events.size() - 1, -1, -1):
		_events[i]["t"] = float(_events[i]["t"]) + delta
		if float(_events[i]["t"]) >= float(_events[i]["hold"]):
			_events.remove_at(i)

	for i in range(_pops.size() - 1, -1, -1):
		_pops[i]["t"] = float(_pops[i]["t"]) + delta
		if float(_pops[i]["t"]) >= POP_RISE_S + POP_HOLD_S:
			var src := String(_pops[i]["source"])
			_pops.remove_at(i)
			var q: Array = _queued.get(src, [])
			if not q.is_empty():
				var nxt: Dictionary = q.pop_front()
				nxt["source"] = src
				_queued[src] = q
				_pops.append(nxt)

	for id in _typers:
		var t: Dictionary = _typers[id]
		var full := String(t["full"])
		if int(t["n"]) < full.length():
			t["n"] = minf(float(t["n"]) + 1.0 / float(TYPE_FRAMES), float(full.length()))

	if not _wipe.is_empty():
		_wipe["t"] = float(_wipe["t"]) + delta
		if float(_wipe["t"]) >= WIPE_S and not bool(_wipe["taken"]):
			_wipe["taken"] = true
			_pending_scene = String(_wipe["path"])
		if float(_wipe["t"]) >= WIPE_S * 2.0:
			_wipe = {}


# --------------------------------------------------------------------- the node
static var _node: Node = null


## BUILD THE ONE NODE, LAZILY, PARENTED TO THE WINDOW. Same shape as `Audio`
## and for the same reason — a node under the current scene is freed on every
## scene change, and this one has to outlive exactly that.
##
## Every screen calls this in `_ready()`. Calling it sixteen times is free; the
## alternative is one screen that forgot, where nothing moves and nobody can say
## why.
static func arm() -> Node:
	## NOT "does the variable point at something" — *is it actually in the
	## tree*. A node that was built and never parented answers yes to the first
	## question and draws nothing, which is the bug this comment is standing on
	## the grave of.
	if _node != null and is_instance_valid(_node):
		if _node.is_inside_tree() or _node.get_parent() != null:
			return _node
		_node = null
	var loop := Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return null
	var tree := loop as SceneTree
	if tree.root == null:
		return null
	var layer := CanvasLayer.new()
	layer.name = "JuiceLayer"
	## ABOVE EVERYTHING. A flash that lands under the HUD is not a flash.
	layer.layer = 100
	var art := JuiceArt.new()
	art.name = "JuiceArt"
	layer.add_child(art)
	## DEFERRED, AND THAT IS NOT A STYLE CHOICE.
	##
	## Every screen arms this from its own `_ready()`, which runs *while the
	## root is adding that screen* — and a node that is busy adding a child
	## refuses to add another. The layer was built, the add silently failed, and
	## `_node` was set anyway, so nothing ever retried: the whole feel layer
	## existed, ticked, and was parented to nothing. It cost a rendered contact
	## sheet of six identical screenshots to notice, which is exactly the trap
	## this codebase keeps rediscovering — **a layer you cannot see is a layer
	## you cannot check**.
	tree.root.call_deferred("add_child", layer)
	_node = layer
	return _node


## Off, for the suite and for anybody who wants to see the game naked. The
## timings still run; nothing is applied and nothing is drawn.
static func set_enabled(on: bool) -> void:
	_enabled = on


static func enabled() -> bool:
	return _enabled
