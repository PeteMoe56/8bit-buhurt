class_name Splash
extends Control
## THE FIRST-TIME SPLASH (Pete, 9 Oct 2026: every new system needs a splash
## screen because "the player won't know what the fuck is happening"). Shown
## once per device, the first time a system turns up, over whatever screen it
## turned up on. Kept with the tips (`Settings.tip_due`), so the test runner's
## RB_NO_TIPS keeps it off the sweeps.

var key := ""
var title_ := ""
var lines: Array = []
var font: Font


## The splash this season is due, if any: [key, title, lines]. First match wins.
static func due_for(s: Season) -> Array:
	var c := s.pending_cup()
	var cand: Array = []
	if s.blocked_by() == "sendoff":
		cand.append(["sendoff", UiKit.t("THE SEND-OFF WEEK"), [
			UiKit.t("You won Nationals. Before the Worlds, the country gives you a week."),
			UiKit.t("No fights this week: one event a day, Monday to Friday. Next event moves you on."),
			UiKit.t("Wednesday you choose how your captain talks to the press. Friday you become Team USA and pick one gift for the Worlds."),
		]])
	if c != null and c == s.world.worlds:
		cand.append(["worlds", UiKit.t("THE WORLDS"), [
			UiKit.t("Sixteen nations, four pools of four. The top two of each pool go into the knockout."),
			UiKit.t("You fight as Team USA under the US flag until the season ends."),
			UiKit.t("A tied knockout bout goes to sudden death: extra rounds, first round won goes through."),
		]])
	if s.blocked_by() == "camp":
		cand.append(["camp", UiKit.t("THE WORLDS CAMP"), [
			UiKit.t("You are through the pools. Before the knockout, the federation's camp is open for one night."),
			UiKit.t("It costs CC for every man you send. Each one comes back with his kit at full, his morale up and some XP."),
			UiKit.t("Send the five, the whole eight, or nobody."),
		]])
	if c != null and c.player_on_bronze():
		cand.append(["bronze", UiKit.t("THE BRONZE MATCH"), [
			UiKit.t("You lost the semi-final, but you are not done."),
			UiKit.t("The two beaten semi-finalists fight for third place and the bronze medal."),
			UiKit.t("Medals go in your club's History: Squad, then Records."),
		]])
	if bool(s.last_show.get("unread", false)):
		cand.append(["hostevent", UiKit.t("YOUR SHOW'S WEEKEND"), [
			UiKit.t("Something always happens at a show you host: rain, a marshal who does not turn up, a full house, a sponsor, the local TV."),
			UiKit.t("Some weekends cost you, some pay more than the budget said. That is the gamble of hosting."),
		]])
	if not Legends.offers(s, {}).is_empty():
		cand.append(["legend", UiKit.t("A CLUB LEGEND IS BACK"), [
			UiKit.t("A man who retired from your club a legend wants to coach."),
			UiKit.t("He is at the top of the captains for hire: he teaches a star above his grade, and the whole squad lifts the day he walks in."),
		]])
	for k in cand:
		if Settings.tip_due("splash:" + String(k[0])):
			return k
	return []


## Put one over `parent` if one is due. Returns true if it did.
static func offer(parent: Node, s: Season) -> bool:
	var d := due_for(s)
	if d.is_empty():
		return false
	var layer := CanvasLayer.new()
	layer.layer = 40
	parent.add_child(layer)
	var sp := Splash.new()
	sp.key = String(d[0])
	sp.title_ = String(d[1])
	sp.lines = d[2]
	sp.font = UiKit.body()
	sp.position = UiKit.full_rect().position
	sp.size = UiKit.full_rect().size
	sp.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(sp)
	var r := sp.panel_rect()
	var b := UiKit.primary(UiKit.button(UiKit.t("Got it"),
		Vector2(r.end.x - 200.0, r.end.y - 62.0) - sp.position, Vector2(180, 46), func():
			Settings.tip_done("splash:" + sp.key)
			layer.queue_free()
			## The screen under it may have another waiting.
			if "splash_up" in parent:
				parent.set("splash_up", false)
				if parent.has_method("_rebuild"):
					parent.call("_rebuild")))
	sp.add_child(b)
	return true


func panel_rect() -> Rect2:
	var sc := UiKit.screen()
	var w := minf(640.0, sc.x - 48.0)
	var h := 330.0
	return Rect2((sc.x - w) * 0.5, (sc.y - h) * 0.5, w, h)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var r := panel_rect()
	r.position -= position
	UiKit.panel(self, r)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), UiKit.YOU)
	UiKit.text(self, font, UiKit.t("NEW"), r.position + Vector2(24, 36), 12, UiKit.DIM)
	UiKit.text_fit(self, font, title_, r.position + Vector2(24, 68), 24, UiKit.YOU, r.size.x - 48.0)
	var y := r.position.y + 104.0
	for l in lines:
		var n := UiKit.para(self, font, String(l), Vector2(r.position.x + 24, y), 15, UiKit.INK, r.size.x - 48.0, 20.0, 3)
		y += 20.0 * float(n) + 12.0
