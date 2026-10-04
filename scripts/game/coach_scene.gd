extends Node2D
## YOU — step 1 of a new career, and the page a coach comes back to.
##
## Pete, 1 Oct 2026: *"You're not named. Your career is hidden behind club. You
## don't have any skills. Creating your coach and team should be first when
## starting a new career."* A name, a face (art follows), a background and five
## skills. The old "Your career" page — standing, record, who wants you — is gone.

const SKILL_X := 492.0
const SKILL_Y := 120.0
const SKILL_ROW := 50.0
## The making of a coach, left column (2 Oct 2026 playtest: names up, face bigger).
const NAME_Y := 108.0
const PART_Y := 162.0
const PART_STEP := 58.0
const PART_X := 196.0
const PORTRAIT := Vector2(160.0, 164.0)
const BG_Y := 352.0

var font: Font
var ui: CanvasLayer
var season: Season
var first_edit: LineEdit
var last_edit: LineEdit
var draft_first = null
var draft_last = null
var flash := ""
var help_open := false


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	## CENTRED ON A WIDE PHONE (2 Oct 2026 playtest): see `UiKit.frame`.
	UiKit.frame(self, ui)
	_build()


## TALL SCREENS STRETCH BELOW THE HEADER (3 Oct 2026): a y on the 540 layout,
## moved down by tall_k on a 960x720 tablet so the page fills it. Phones: k = 1.
func _v(y: float) -> float:
	return 72.0 + (y - 72.0) * UiKit.tall_k()


func _coach() -> Coach:
	return season.coach


func go_back() -> bool:
	if help_open:
		help_open = false
		_build()
		return true
	_leave_back()
	return true


func _leave_back() -> void:
	if Session.founding:
		Session.founding = false
		UiKit.trail_reset()
		UiKit.go("res://scenes/Title.tscn")
	else:
		UiKit.go("res://scenes/Season.tscn")


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	first_edit = null
	last_edit = null
	var c := _coach()
	if help_open:
		var r := _help_rect()
		ui.add_child(UiKit.button(UiKit.t("Got it"), Vector2(r.end.x - 184.0, r.end.y - 60.0), Vector2(160, 44), func():
			help_open = false
			_build()))
		queue_redraw()
		return
	var creating := not c.created
	if creating:
		## HIGHER, AND THE FACE BIGGER (Pete, 2 Oct 2026 playtest: "First Name/Last
		## Name can be brought up, the portrait/Face/Kit/Beard can be made larger").
		first_edit = _edit(Vector2(24, _v(NAME_Y)), 200.0, draft_first if draft_first != null else c.first_name,
			UiKit.t("First name"), func(t: String): draft_first = t)
		last_edit = _edit(Vector2(240, _v(NAME_Y)), 220.0, draft_last if draft_last != null else c.last_name,
			UiKit.t("Last name"), func(t: String): draft_last = t)
		## THE FACE, KIT AND BEARD (art to follow): three cycling parts.
		var parts := [[UiKit.t("Face"), "face"], [UiKit.t("Kit"), "kit"], [UiKit.t("Beard"), "beard"]]
		## Each part both ways: < back, the part itself (forward), > forward.
		for i in parts.size():
			var p: Array = parts[i]
			var y := _v(PART_Y) + float(i) * UiKit.tk(PART_STEP)
			var ph := UiKit.tk(48)
			ui.add_child(UiKit.arrow(false, Vector2(PART_X, y), Vector2(48, ph), func(key = String(p[1])):
				c.set(key, (int(c.get(key)) + 5) % 6)
				_build()))
			ui.add_child(UiKit.button("%s %d" % [String(p[0]), int(c.get(String(p[1]))) + 1],
				Vector2(PART_X + 54.0, y), Vector2(150, ph), func(key = String(p[1])):
					c.set(key, (int(c.get(key)) + 1) % 6)
					_build()))
			ui.add_child(UiKit.arrow(true, Vector2(PART_X + 210.0, y), Vector2(48, ph), func(key = String(p[1])):
				c.set(key, (int(c.get(key)) + 1) % 6)
				_build()))
		for b in 3:
			ui.add_child(UiKit.selected(UiKit.button(Coach.background_name(b),
				Vector2(24 + float(b) * 148.0, _v(BG_Y)), Vector2(140, UiKit.tk(40)), func(k = b):
					c.set_background(k)
					_build()), c.background == b))
	## THE SKILLS: + to spend, − to take back while still creating.
	## THE "?" SITS AFTER THE HEADING, measured: "DEINE FÄHIGKEITEN" is twice "YOUR SKILLS".
	var hw := font.get_string_size(UiKit.t("YOUR SKILLS"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, UiKit.tz(14)).x
	var sy := _v(SKILL_Y)
	ui.add_child(UiKit.button("?", Vector2(SKILL_X + 20.0 + hw, sy + UiKit.tk(4.0)), Vector2(32, UiKit.tk(30)), func():
		help_open = true
		_build()))
	for i in 5:
		var y := sy + UiKit.tk(66.0 + float(i) * SKILL_ROW)
		var bh := UiKit.tk(44)
		var plus := UiKit.button("+", Vector2(UiKit.right_edge(76.0), y - UiKit.tk(26.0)), Vector2(46, bh), func(k = i):
			var err := c.spend(k)
			flash = err
			if err == "" and not creating:
				Session.autosave()
			_build())
		plus.disabled = c.points <= 0 or c.skill(i) >= Coach.SKILL_MAX
		ui.add_child(plus)
		if creating:
			var minus := UiKit.button("-", Vector2(UiKit.right_edge(128.0), y - UiKit.tk(26.0)), Vector2(46, bh), func(k = i):
				c.unspend(k)
				_build())
			minus.disabled = c.skill(i) <= (1 if i == int(Coach.BACKGROUND_SKILL[c.background]) else 0)
			ui.add_child(minus)
	## BOTTOM GUTTER, NOT y=486 (3 Oct 2026): on an iPad (1024x768) the fixed
	## row floated at ~540 with a quarter screen of nothing under it. Same line
	## as UiKit.back_button, so Back sits where it does on every other screen.
	var row_y := UiKit.screen().y - 56.0
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(24, row_y), Vector2(150, 44), _leave_back))
	var next := UiKit.t("Next: your team  >") if Session.founding else UiKit.t("Done")
	ui.add_child(UiKit.primary(UiKit.button(next, Vector2(UiKit.right_edge(284.0), row_y), Vector2(260, 44), _next)))
	queue_redraw()


func _edit(at: Vector2, w: float, text: String, hint: String, on_change: Callable) -> LineEdit:
	var e := LineEdit.new()
	UiKit.skin_edit(e)
	e.position = at
	e.size = Vector2(w, UiKit.tk(36))
	e.max_length = 16
	e.placeholder_text = hint
	e.text = text
	e.text_changed.connect(on_change)
	ui.add_child(e)
	return e


func _next() -> void:
	var c := _coach()
	if not c.created:
		var f := String(draft_first if draft_first != null else c.first_name)
		var l := String(draft_last if draft_last != null else c.last_name)
		if (f + l).strip_edges() == "":
			flash = UiKit.t("Give your coach a name.")
			_build()
			return
		c.set_name(f, l)
		c.created = true
	Session.autosave()
	if Session.founding:
		Session.create_tab = 1
		UiKit.go("res://scenes/Create.tscn")
	else:
		UiKit.go("res://scenes/Season.tscn")


func _help_rect() -> Rect2:
	var sz := Vector2(600.0, 330.0)
	return Rect2(Vector2(floorf((UiKit.screen().x - sz.x) * 0.5), 100.0), sz)


static func skill_help(i: int) -> String:
	match i:
		Coach.Skill.TRAINING: return UiKit.t("Training: +5%% XP a star, in practice and in bouts.") % []
		Coach.Skill.MOTIVATION: return UiKit.t("Motivation: a loss hurts the room 10%% less a star.") % []
		Coach.Skill.TACTICS: return UiKit.t("Tactics: one more corner call at three stars, another at five.")
		Coach.Skill.BUSINESS: return UiKit.t("Business: +5%% gate, bar and prize money a star.") % []
	return UiKit.t("Recruiting: free agents cost 5%% less a star.") % []


func _draw() -> void:
	UiKit.ground(self)
	var c := _coach()
	if Session.founding:
		UiKit.text(self, font, UiKit.t("NEW CAREER"), Vector2(24, 40), 22, UiKit.YOU)
		UiKit.text(self, font, UiKit.t("Step 1 of 3"), Vector2(24, 64), 14, UiKit.DIM)
	else:
		UiKit.text(self, font, UiKit.t("YOUR COACH"), Vector2(24, 40), 22, UiKit.YOU)
	if c.created:
		UiKit.text_fit(self, font, c.display_name, Vector2(24, _v(140)), UiKit.tz(24), UiKit.INK, 440.0)
		UiKit.text_fit(self, font, UiKit.t("%s  ·  level %d  ·  record %s") % [Coach.background_name(c.background),
			c.level, c.record_line()], Vector2(24, _v(168)), UiKit.tz(15), UiKit.DIM, 440.0)
		UiKit.text(self, font, UiKit.t("XP %d of %d to level %d") % [c.xp, Coach.need(c.level), c.level + 1],
			Vector2(24, _v(206)), UiKit.tz(14), UiKit.DIM)
		UiKit.bar(self, Rect2(24, _v(214), 300, UiKit.tk(10)), float(c.xp) / float(Coach.need(c.level)), UiKit.YOU)
		## WHAT THE STARS ARE DOING RIGHT NOW (review, 1 Oct 2026: the left half
		## was empty).
		UiKit.text(self, font, UiKit.t("WHAT YOUR SKILLS DO NOW"), Vector2(24, _v(262)), UiKit.tz(12), UiKit.DIM)
		var now := [
			UiKit.t("Practice and bouts: +%d%% XP") % (c.skill(Coach.Skill.TRAINING) * 5),
			UiKit.t("A loss costs the room %d%% less") % (c.skill(Coach.Skill.MOTIVATION) * 10),
			UiKit.t("Extra corner calls: %d") % c.extra_calls(),
			UiKit.t("Gate, bar and prizes: +%d%%") % (c.skill(Coach.Skill.BUSINESS) * 5),
			UiKit.t("Free agents: %d%% cheaper") % (c.skill(Coach.Skill.RECRUITING) * 5),
		]
		for i in now.size():
			UiKit.text_fit(self, font, String(now[i]), Vector2(24, _v(290) + UiKit.tk(i * 26)), UiKit.tz(15),
				UiKit.INK if c.skill(i) > 0 else UiKit.DIM, 440.0)
	else:
		UiKit.text(self, font, UiKit.t("FIRST NAME"), Vector2(24, _v(NAME_Y) - 8.0), UiKit.tz(12), UiKit.DIM)
		UiKit.text(self, font, UiKit.t("LAST NAME"), Vector2(240, _v(NAME_Y) - 8.0), UiKit.tz(12), UiKit.DIM)
		## TALLER, NOT WIDER, on a tablet: the part buttons sit 12px right of it.
		var ph := UiKit.tk(PORTRAIT.y)
		UiKit.panel(self, Rect2(24, _v(PART_Y), PORTRAIT.x, ph))
		UiKit.mid(self, font, UiKit.t("art to follow"), Vector2(24, _v(PART_Y) + ph * 0.5 + 4.0), UiKit.tz(12), UiKit.DIM, PORTRAIT.x)
		UiKit.text(self, font, UiKit.t("BACKGROUND"), Vector2(24, _v(BG_Y) - 8.0), UiKit.tz(12), UiKit.DIM)
		UiKit.para(self, font, UiKit.t("Each background starts with a point: Training, Business or Tactics."),
			Vector2(24, _v(BG_Y) + UiKit.tk(60.0)), UiKit.tz(13), UiKit.DIM, 440.0, UiKit.tk(16.0), 2)
	# ---- the skills
	var sy := _v(SKILL_Y)
	var r := Rect2(SKILL_X - 8.0, sy - 8.0, UiKit.right_edge() - SKILL_X + 16.0, UiKit.tk(352.0))
	UiKit.panel(self, r)
	UiKit.text(self, font, UiKit.t("YOUR SKILLS"), Vector2(SKILL_X + 8.0, sy + UiKit.tk(26.0)), UiKit.tz(14), UiKit.DIM)
	for i in 5:
		var y := sy + UiKit.tk(66.0 + float(i) * SKILL_ROW)
		UiKit.text_fit(self, font, Coach.skill_name(i), Vector2(SKILL_X + 8.0, y), UiKit.tz(17), UiKit.INK, 140.0)
		UiKit.stars(self, Vector2(SKILL_X + 160.0, y - UiKit.tk(14.0)), c.skill(i) * 20, UiKit.YOU, 14.0, 3.0)
	var pts := UiKit.tn("%d point to spend", "%d points to spend", c.points) % c.points
	draw_line(Vector2(r.position.x + 12.0, r.end.y - 44.0), Vector2(r.end.x - 12.0, r.end.y - 44.0), UiKit.FRAME, 1.0)
	UiKit.mid(self, font, pts, Vector2(r.position.x, r.end.y - 16.0), UiKit.tz(16),
		UiKit.YOU if c.points > 0 else UiKit.DIM, r.size.x)
	if flash != "":
		UiKit.text_fit(self, font, flash, Vector2(196, UiKit.screen().y - 28.0), 14, UiKit.DOWN, 480.0)
	if help_open:
		var hr := _help_rect()
		draw_rect(UiKit.full_rect(), Color(0, 0, 0, 0.74))
		UiKit.panel(self, hr)
		UiKit.text(self, font, UiKit.t("YOUR SKILLS"), hr.position + Vector2(24, 40), 19, UiKit.INK)
		for i in 5:
			UiKit.text_fit(self, font, skill_help(i), hr.position + Vector2(24, 86 + i * 30), 15, UiKit.DIM,
				hr.size.x - 48.0)
		UiKit.text_fit(self, font, UiKit.t("A level is one point. Levels come from wins, finishes and cup runs."),
			hr.position + Vector2(24, 248), 14, UiKit.INK, hr.size.x - 48.0)
