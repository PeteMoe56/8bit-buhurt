extends SceneTree
## THE COUNTER, AND THE THREE WAYS IT COULD COST SOMEBODY MONEY.
##
##   godot --headless --path . --script res://tests/test_store.gd
##
## Nothing in this suite can test Google Play Billing — it is an Android plugin
## that is not in the build. What CAN be tested is everything around it, and
## everything around it is where the expensive mistakes live: a purchase that
## lands in no career, a purchase that a release build mints for free, a wallet
## that a second club erases.
##
## The shape of every check here is "what would this cost a player", not "does
## the function return the right thing".

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the counter ===\n")
	## Its own wallet file: this test zeroes and rewrites the wallet.
	Store.wallet_prefix = "test_store_"
	_test_the_shelf_is_a_real_ladder()
	_test_a_purchase_is_not_attached_to_a_save()
	_test_the_wallet_survives_the_app()
	_test_a_release_build_cannot_mint_credits()
	_test_the_shop_says_why_it_is_shut()
	_test_play_billing_end_to_end()
	_test_app_store_end_to_end()
	_cleanup()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE COUNTER HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


## PETE'S #2 (29 Sep 2026): premium plus three helper packs, through Play
## Billing. Driven through a stand-in client with Play's own signal shapes.
func _test_play_billing_end_to_end() -> void:
	var fake = load("res://tests/fake_billing.gd").new()
	Store.owed = 0
	Store.receipts.clear()
	Store.save_wallet()
	Store.use_client(fake)
	Store.connect_backend()
	var waiting := Store.state == Store.State.CONNECTING
	fake.connected.emit()
	var asked: bool = fake.calls.has("query_purchases") and fake.calls.any(
		func(c): return String(c).begins_with("query_product_details:cc_small,cc_medium,cc_large"))
	_ok(waiting and Store.available() and asked,
		"the shop opens when Play connects, and asks for the packs and anything unfinished",
		"calls: %s" % ", ".join(fake.calls))

	## LOCALIZED PRICES, from the store's own answer.
	fake.query_product_details_response.emit({"response_code": 0, "product_details": [
		{"product_id": "cc_small", "one_time_purchase_offer_details": {"formatted_price": "1,99 €"}},
		{"product_id": "cc_medium", "one_time_purchase_offer_details_list": [{"formatted_price": "3,99 €"}]},
	]})
	_ok(Store.price_word("cc_small") == "1,99 €" and Store.price_word("cc_large") == "$7.99",
		"the shelf shows the store's own price, and the list price until it has one",
		"%s / %s" % [Store.price_word("cc_small"), Store.price_word("cc_large")])

	## A TAP IS A REQUEST, NOT A CREDIT.
	var err := Store.buy("cc_small")
	_ok(err == "" and Store.owed == 0 and fake.calls.has("purchase:cc_small"),
		"a tap starts the purchase and credits nothing yet",
		"err '%s', owed %d" % [err, Store.owed])

	## Play answers: bought. Credited once, then consumed.
	fake.on_purchase_updated.emit({"response_code": 0, "purchases": [fake.bought("cc_small", "tok-1")]})
	var after_buy := Store.owed
	var consumed_once: bool = fake.consumed == ["tok-1"]
	## The consume never landed; next launch Play delivers the same purchase again.
	fake.query_purchases_response.emit({"response_code": 0, "purchases": [fake.bought("cc_small", "tok-1")]})
	_ok(after_buy == 20 and consumed_once and Store.owed == 20 and fake.consumed.size() == 2,
		"a purchase is credited once, and a re-delivered one is consumed again but not credited twice",
		"owed after buy %d, after re-delivery %d; consumed %s" % [after_buy, Store.owed, str(fake.consumed)])

	## THE RECEIPT SURVIVES THE APP.
	Store.load_wallet()
	fake.query_purchases_response.emit({"response_code": 0, "purchases": [fake.bought("cc_small", "tok-1")]})
	_ok(Store.owed == 20 and Store.receipts.has("tok-1"),
		"the claim receipt is in the wallet, so a relaunch cannot pay the same purchase again",
		"owed %d, receipts %s" % [Store.owed, str(Store.receipts)])

	## CANCELED AND PENDING PAY NOTHING.
	fake.on_purchase_updated.emit({"response_code": 1, "purchases": []})
	var canceled := Store.last_error
	fake.on_purchase_updated.emit({"response_code": 0, "purchases": [fake.bought("cc_large", "tok-2", 2)]})
	_ok(Store.owed == 20 and canceled != "" and Store.pending == 1 and not fake.consumed.has("tok-2"),
		"a canceled purchase and a pending one credit nothing and consume nothing",
		"owed %d, canceled '%s', pending %d" % [Store.owed, canceled.left(40), Store.pending])
	## And when the pending one is paid, it lands.
	fake.query_purchases_response.emit({"response_code": 0, "purchases": [fake.bought("cc_large", "tok-2", 1)]})
	_ok(Store.owed == 170 and fake.consumed.has("tok-2") and Store.pending == 0,
		"a pending purchase lands when Play says it is paid",
		"owed %d" % Store.owed)

	## UNDER RELEASE RULES A REAL CLIENT STILL WORKS — the fence is the stub, not the store.
	Store.release_rules = true
	fake.on_purchase_updated.emit({"response_code": 0, "purchases": [fake.bought("cc_medium", "tok-3")]})
	Store.release_rules = false
	_ok(Store.owed == 225, "a release build credits a real store's purchase",
		"owed %d" % Store.owed)

	Store.use_client(null)
	Store.owed = 0
	Store.receipts.clear()
	Store.save_wallet()


## THE APP STORE (3 Oct 2026): StoreKit 2 through `AppleStore`, which speaks
## the Play client's language, so the same `Store` code credits and finishes.
## Driven through a stand-in StoreKitManager with the addon's signal shapes.
func _test_app_store_end_to_end() -> void:
	var sk = load("res://tests/fake_storekit.gd").new()
	var apple := AppleStore.new()
	apple.attach(sk, false)
	Store.owed = 0
	Store.receipts.clear()
	Store.save_wallet()
	Store.use_client(apple)
	Store.connect_backend()
	apple.connected.emit()
	_ok(sk.started and Store.available() and Store.price_word("cc_small") == "1,99 €",
		"the App Store opens the shop, starts the listener and prices the packs locally",
		"started %s, price %s" % [sk.started, Store.price_word("cc_small")])

	var err := Store.buy("cc_small")
	_ok(err == "" and Store.owed == 0 and sk.bought == ["cc_small"],
		"a tap asks StoreKit to buy and credits nothing yet", "err '%s', owed %d" % [err, Store.owed])

	var t = sk.answer(0)
	_ok(Store.owed == 20 and sk.finished == [t.transaction_id],
		"a paid transaction is credited once and then finished",
		"owed %d, finished %s" % [Store.owed, str(sk.finished)])

	## Apple re-delivers an unfinished transaction (finish never landed): no second credit.
	sk.transaction_updated.emit(t)
	_ok(Store.owed == 20, "a re-delivered transaction is not paid twice", "owed %d" % Store.owed)

	## Cancelled and pending pay nothing.
	Store.buy("cc_large")
	sk.answer(4)
	var canceled := Store.last_error
	Store.buy("cc_large")
	sk.answer(5)
	_ok(Store.owed == 20 and canceled != "" and Store.pending == 1,
		"a cancelled purchase and an Ask to Buy credit nothing",
		"owed %d, pending %d" % [Store.owed, Store.pending])
	## The approval arrives later, outside any purchase call.
	sk.transaction_updated.emit(sk.tx("cc_large"))
	_ok(Store.owed == 170, "an approved Ask to Buy lands when StoreKit delivers it", "owed %d" % Store.owed)

	## Restore = ask StoreKit for anything unfinished.
	var asked_before: int = sk.unfinished_asked
	Store.resolve_pending()
	_ok(sk.unfinished_asked == asked_before + 1, "Restore a purchase asks StoreKit for unfinished transactions",
		"asked %d" % sk.unfinished_asked)

	## A product the store never priced cannot be bought.
	apple._products.erase("cc_medium")
	var e2 := Store.buy("cc_medium")
	_ok(e2 != "" and not sk.bought.has("cc_medium"), "a pack StoreKit did not return is refused, with a reason",
		"'%s'" % e2)

	Store.use_client(null)
	sk.free()
	Store.owed = 0
	Store.receipts.clear()
	Store.save_wallet()


func _cleanup() -> void:
	Store.owed = 0
	Store.save_wallet()
	Store._stub_purchases.clear()


## ---------------------------------------------------------------- the shelf
func _test_the_shelf_is_a_real_ladder() -> void:
	_ok(Store.PRODUCTS.size() >= 3, "there is a shelf",
		"%d packs" % Store.PRODUCTS.size())

	## EVERY STEP IS BETTER VALUE THAN THE ONE ABOVE IT. Direction §8 on Retro
	## Bowl's own ladder: their 250 and 500 tiers are the same unit price —
	## *"a slightly weak ladder worth improving on"*. This is that improvement,
	## checked rather than asserted in a comment.
	var bad: Array[String] = []
	var line: Array[String] = []
	for i in Store.PRODUCTS.size():
		var p: Dictionary = Store.PRODUCTS[i]
		line.append("%d for %s (%.2f¢)" % [int(p["credits"]), String(p["price"]),
			Store.unit_cents(p)])
		if i == 0:
			continue
		var prev: Dictionary = Store.PRODUCTS[i - 1]
		if int(p["credits"]) <= int(prev["credits"]):
			bad.append("%s is not bigger than %s" % [p["id"], prev["id"]])
		if Store.unit_cents(p) >= Store.unit_cents(prev):
			bad.append("%s is not better value than %s" % [p["id"], prev["id"]])
	_ok(bad.is_empty(), "and every step down it is strictly better value",
		"; ".join(line) if bad.is_empty() else "; ".join(bad))

	## THE SMALLEST PACK DOES NOT END THE ECONOMY. A good season pays six to ten
	## credits in prize money; a pack that hands over five seasons at once stops
	## the club being the thing that earns. Held against the prize table itself
	## rather than against a number typed in here.
	## AGAINST THE BACKYARD CHAMPIONS' SHARE, which is the winning season a
	## player has at the point he would first be offered a pack. `CREDITS_BY_POSITION`
	## was a flat table of three and is now a per-division purse, so the figure is
	## asked for rather than indexed — `purse(1, field, 0)` is the same six
	## credits the table's first entry was.
	var season_prize: int = Season.purse(1, League.club_count(0), 0) \
		+ int(Season.CREDITS_PROMOTED)
	var small: int = int(Store.PRODUCTS[0]["credits"])
	_ok(small <= season_prize * 3,
		"and the smallest pack is worth about two good seasons, not ten",
		"%d credits against a winning season's %d" % [small, season_prize])
	notes.append("the shelf: %s" % ", ".join(line))


## -------------------------------------------------- money outlives a career
func _test_a_purchase_is_not_attached_to_a_save() -> void:
	Store.load_wallet()
	Store.owed = 0
	Store.save_wallet()

	## Bought with nothing loaded — the title screen case, which is the one a
	## store that writes into `season.office.credits` loses outright.
	Store.owed = 40
	Store.save_wallet()

	var a := Season.new(MeleeRosters.starting_club(), 11)
	var saved := func() -> bool: return true
	var failed := func() -> bool: return false

	## A CLAIM WHOSE SEASON DID NOT REACH DISK IS UNDONE. The office goes back to
	## what it was and the wallet still holds the money, so a failed save cannot
	## lose a purchase. And a claim with no save at all claims nothing.
	var before0: int = a.office.credits
	var none := Store.claim(a.office, failed)
	var unsaved := Store.claim(a.office)
	_ok(none == 0 and unsaved == 0 and a.office.credits == before0 and Store.owed == 40
		and int(a.office.books_in.get(ClubOffice.LINE_STORE, 0)) == 0,
		"a claim whose season was not saved is undone",
		"office %d -> %d, wallet still owes %d" % [before0, a.office.credits, Store.owed])

	var before: int = a.office.credits
	var moved := Store.claim(a.office, saved)
	_ok(moved == 40 and a.office.credits == before + 40,
		"credits bought with no career land in the next one opened",
		"%d moved, office went %d -> %d" % [moved, before, a.office.credits])

	## AND THEY DO NOT LAND TWICE. A claim empties the wallet; a second club
	## opened afterwards gets nothing, because nothing is owed.
	var b := Season.new(MeleeRosters.starting_club(), 12)
	var second := Store.claim(b.office, saved)
	_ok(second == 0, "and they are not paid out again to the next club",
		"second claim moved %d" % second)

	## AND A CLAIM WITH NOTHING OWED IS NOT AN ERROR — it is the normal case,
	## run every time a career is opened.
	_ok(Store.claim(a.office, saved) == 0 and Store.claim(null, saved) == 0,
		"claiming nothing, or claiming into nothing, is quiet",
		"both return 0 rather than throwing")


func _test_the_wallet_survives_the_app() -> void:
	Store.owed = 0
	Store.save_wallet()
	Store.owed = 25
	Store.save_wallet()
	## The app dies here. `load_wallet()` is what the next launch runs.
	Store.owed = 0
	Store.load_wallet()
	_ok(Store.owed == 25, "a wallet written before the app died is still there",
		"reloaded %d" % Store.owed)

	## AND IT IS NOT IN THE SAVE FILE, which is the whole reason it exists. A
	## save round trip must not carry, restore, or clobber it.
	var s := Season.new(MeleeRosters.starting_club(), 13)
	var d := SaveGame.to_dict(s)
	var carried := JSON.stringify(d).contains("\"owed\"")
	_ok(not carried, "and it is not inside a save file",
		"a save that carried the wallet would duplicate it per slot")
	Store.owed = 0
	Store.save_wallet()


## ------------------------------------------------- the line that must hold
func _test_a_release_build_cannot_mint_credits() -> void:
	## THE STUB GRANTS CREDITS WITH NO PAYMENT. That is what a developer needs
	## and what must never ship, and `OS.is_debug_build()` is the fence — set by
	## the exporter, not by anything in this repo.
	##
	## This suite runs in a debug build, so the fence cannot be crossed from
	## here. What CAN be checked is that both doors ask: `buy` through the stub,
	## and `grant` directly, which is the one an over-helpful future caller would
	## reach for.
	var debug := OS.is_debug_build()
	## RELEASE RULES, ASKED OF THE REAL FUNCTIONS. `Store.release_rules` makes
	## the fence answer as an exported build's would; nothing else changes.
	Store.release_rules = true
	Store.owed = 0
	Store.save_wallet()
	Store.state = Store.State.READY
	var bought := Store.buy("cc_small")
	var granted := Store.grant("cc_small")
	Store.state = Store.State.COLD
	Store.connect_backend()
	var shut := Store.state
	Store.release_rules = false
	var guards := 2 if (bought != "" and granted != "") else 0
	_ok(bought != "" and granted != "" and Store.owed == 0,
		"under release rules neither door creates a credit without a real store",
		"buy: '%s', grant: '%s', wallet %d" % [bought.left(40), granted.left(40), Store.owed])
	_ok(shut != Store.State.READY,
		"and the shop does not open with no store behind it",
		"state %s" % str(shut))

	if debug:
		## In this build the stub works, which is what makes the flow walkable.
		Store.owed = 0
		Store.save_wallet()
		Store.state = Store.State.READY
		var err := Store.buy("cc_small")
		_ok(err == "" and Store.owed == 20,
			"a debug build can walk the whole purchase without a card",
			"bought cc_small, wallet holds %d" % Store.owed)
		Store.owed = 0
		Store.save_wallet()
		Store._stub_purchases.clear()

	## A PACK THAT DOES NOT EXIST IS REFUSED BY BOTH DOORS. An id typed into a
	## screen is an id that can be typed wrong.
	_ok(Store.buy("cc_enormous") != "" and Store.grant("cc_enormous") != "",
		"a pack that is not on the shelf cannot be bought or granted",
		"both refuse with a sentence")
	notes.append("the fence: %d debug guards, stub %s" % [guards,
		"live" if debug else "dead"])


func _test_the_shop_says_why_it_is_shut() -> void:
	## A SHUT SHOP THAT SAYS NOTHING IS A BUTTON THAT EATS A TAP. Every state
	## has to produce a sentence a player can read.
	var said: Array[String] = []
	var blank: Array[String] = []
	for st in [Store.State.COLD, Store.State.CONNECTING, Store.State.UNAVAILABLE]:
		Store.state = st
		var w := Store.closed_word()
		said.append(w)
		if w.strip_edges() == "":
			blank.append(str(st))
	_ok(blank.is_empty(), "every shut state explains itself",
		"; ".join(said) if blank.is_empty() else "blank for states " + ", ".join(blank))

	Store.state = Store.State.READY
	_ok(Store.closed_word() == "" and Store.available(),
		"and an open one says nothing at all",
		"READY is the only state with no sentence")

	## BUYING WHILE SHUT IS REFUSED WITH THAT SAME SENTENCE, so the screen and
	## the refusal cannot drift apart.
	Store.state = Store.State.UNAVAILABLE
	var err := Store.buy("cc_small")
	_ok(err == Store.closed_word() and err != "",
		"and a tap on a shut shop gets the same words the screen shows",
		"'%s'" % err)
	Store.state = Store.State.COLD
