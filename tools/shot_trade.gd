extends SceneTree
## THE SQUAD TAB WITH A MAN PICKED, so the sale price on the Cut button is
## visible. Nothing else in the suite selects a fighter, so nothing else could
## show this button at all — see `Market.trade_value`.
var n := 0
var stage := 0
var sc: Node = null
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	sc = load("res://scenes/Season.tscn").instantiate()
	sc.set("tab", 1)
	root.add_child(sc)

func _process(_d: float) -> bool:
	n += 1
	if n < 9:
		return false
	n = 0
	match stage:
		0:
			## A man with a deal still to run, so he has a price. The one out of
			## contract is the other half of the rule and reads "Cut".
			for f in sc.get("season").club.roster:
				if f.years > 0:
					sc.set("picked", f)
					break
			sc.call("_rebuild")
		1:
			root.get_texture().get_image().save_png("res://shots/trade.png")
			print("wrote trade")
			return true
	stage += 1
	return false
