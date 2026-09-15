extends SceneTree
## THE CARD ON THE TABLE, WITH ITS PRICES.
##
##   xvfb-run -a godot --path . --script res://tools/shot_dilemma.gd
##
## The deck is the one screen in the game a player reads as a voice rather than
## as a number, and since 14 Sep 2026 it carries figures under each answer as
## well — `Dilemma.costs()`, in the shape Retro Bowl's press interview uses.
##
## A CARD WITH THREE DIFFERENT SHAPES OF ANSWER, chosen rather than taken as it
## came: one that costs money and buys kit, one that costs less and annoys the
## room, and one that costs nothing at all. A shot of three options that all read
## "-4 CC" would prove the line draws and nothing about whether it helps.
var n := 0

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.office.credits = 40
	## Deal the gambeson order by hand — the deck is seeded off the season and
	## waiting for the right card to come up is not a test, it is a queue.
	s.dilemma = {"id": "gambesons", "man": 0, "after": -1}
	## AND CLEAR THE QUEUE AHEAD OF IT. A season one starts with a tournament bid
	## open, and the bid is asked first — the first run of this tool photographed
	## the gambeson card with the BID's two buttons under it, which is how the
	## drawing/queue disagreement below came to light. Declining is the honest
	## way to reach this screen; forcing it would have hidden the same bug again.
	s.decline_bid()
	var scene: Node = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)

func _process(_d: float) -> bool:
	n += 1
	## LONG ENOUGH FOR THE CARD TO FINISH PRINTING. The body types itself in at
	## half a character a frame, so a shot ten frames in photographs five
	## characters of a two-hundred-word card — which is what the first run of
	## this tool did, and the empty panel read as a card with no body at all.
	if n < 420:
		return false
	root.get_texture().get_image().save_png("res://shots/dilemma.png")
	print("wrote dilemma")
	return true
