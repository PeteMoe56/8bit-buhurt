class_name AppleStore
extends RefCounted
## THE APP STORE, SPEAKING PLAY'S LANGUAGE (3 Oct 2026).
##
## `Store` was written against the Google Play Billing plugin's client: its
## signals, its result dictionaries, its "purchase token". This wraps StoreKit 2
## (Miguel de Icaza's GodotApplePlugins, the StoreKit addon, fetched into the
## iOS build by Codemagic; not committed) in exactly that shape, so `Store`
## needs one more line in `_backend()` and no second code path. Everything
## `test_store.gd` proves about credits, receipts and the wallet holds for
## Apple too, because it is the same code deciding.
##
## THE MAPPING:
##   start_connection()        StoreKitManager.start(): the transaction listener,
##                             plus every unfinished transaction, which is how a
##                             consumable paid for while the app was dead comes back
##   query_product_details()   request_products() -> localized `display_price`
##   purchase(id)              purchase(StoreProduct)
##   purchase token            the transaction id, as a string
##   consume_purchase(token)   StoreTransaction.finish() — Apple re-delivers a
##                             transaction until it is finished, the same promise
##                             Play makes for an unconsumed purchase
##   query_purchases()         fetch_unfinished_transactions()
##
## EVERY SIGNAL IS DEFERRED. StoreKit answers from Swift tasks, and an update can
## arrive off the main thread; a deferred connection lands it in the next idle
## frame, where the wallet and the screens can be touched.

signal connected
signal connect_error(code: int, message: String)
signal disconnected
signal query_product_details_response(result: Dictionary)
signal on_purchase_updated(result: Dictionary)
signal query_purchases_response(result: Dictionary)
signal consume_purchase_response(result: Dictionary)

## Play's response codes, the ones `Store` reads.
const RC_OK := 0
const RC_USER_CANCELED := 1
const RC_ITEM_UNAVAILABLE := 4
const RC_ERROR := 6
## StoreKitManager.StoreKitStatus, by value.
const SK_OK := 0
const SK_USER_CANCELLED := 4
const SK_PENDING := 5

var _sk: Object = null
## product_id -> StoreProduct, once the store has answered.
var _products: Dictionary = {}
## token -> StoreTransaction, credited and waiting to be finished.
var _open: Dictionary = {}
## The pack last sent to the sheet, so an Ask to Buy can say which pack is
## pending (3 Oct 2026, audit) — StoreKit's pending answer carries no transaction.
var _buying: String = ""


## Is the StoreKit addon in this build at all?
static func present() -> bool:
	return ClassDB.class_exists("StoreKitManager") and ClassDB.can_instantiate("StoreKitManager")


func start_connection() -> void:
	if _sk == null:
		if not present():
			connect_error.emit.call_deferred(3, "StoreKit is not in this build")
			return
		attach(ClassDB.instantiate("StoreKitManager"))
	connected.emit.call_deferred()


## The manager, wired. Public so a test can hand in a stand-in with the same
## signals and methods.
## (`deferred` false only there: a test has no idle frame to wait for.)
func attach(sk: Object, deferred: bool = true) -> void:
	_sk = sk
	var how := CONNECT_DEFERRED if deferred else 0
	_sk.connect("products_request_completed", _on_products, how)
	_sk.connect("purchase_completed", _on_purchase_completed, how)
	_sk.connect("transaction_updated", _on_transaction, how)
	## UNVERIFIED (3 Oct 2026, audit): paid and refused by StoreKit's own check.
	## Unheard, it was never credited, never finished and never mentioned.
	if _sk.has_signal("unverified_transaction_updated"):
		_sk.connect("unverified_transaction_updated", _on_unverified, how)
	_sk.call("start")


func query_product_details(ids: PackedStringArray, _type: int = 0) -> void:
	if _sk != null:
		_sk.call("request_products", ids)


func _on_products(products: Array, status: int) -> void:
	var details: Array = []
	for p in products:
		if p == null:
			continue
		var id := String(p.get("product_id"))
		_products[id] = p
		details.append({"product_id": id, "formatted_price": String(p.get("display_price"))})
	query_product_details_response.emit({
		"response_code": RC_OK if status == SK_OK else RC_ERROR,
		"product_details": details,
	})


## Play's `purchase()` returns a dictionary at once; so does this.
func purchase(id: String) -> Dictionary:
	if _sk == null or not _products.has(id):
		return {"response_code": RC_ITEM_UNAVAILABLE}
	_buying = id
	_sk.call("purchase", _products[id])
	return {"response_code": RC_OK}


func _on_purchase_completed(transaction, status: int, _message: String) -> void:
	if status == SK_OK and transaction != null:
		_deliver(transaction)
	elif status == SK_USER_CANCELLED:
		on_purchase_updated.emit({"response_code": RC_USER_CANCELED, "purchases": []})
	elif status == SK_PENDING:
		## Ask to Buy, or a payment that has not cleared: it arrives later
		## through `transaction_updated`.
		on_purchase_updated.emit({"response_code": RC_OK,
			"purchases": [{"purchase_state": 2, "purchase_token": "",
				"product_ids": [] if _buying == "" else [_buying]}]})
	else:
		on_purchase_updated.emit({"response_code": RC_ERROR, "purchases": []})


## A transaction that arrived outside a purchase call: an unfinished one at
## start-up, an Ask to Buy approved later, a purchase made on another device.
func _on_transaction(transaction) -> void:
	if transaction != null:
		_deliver(transaction)


## Not credited (Apple's own guidance: never grant on an unverified one) and
## not finished, so a later verified delivery can still pay it. `Store` tells
## the player and gives him the id for support.
func _on_unverified(transaction, _error: int) -> void:
	var token := "?" if transaction == null else str(int(transaction.get("transaction_id")))
	on_purchase_updated.emit({"response_code": RC_ERROR, "unverified": token, "purchases": []})


func _deliver(transaction) -> void:
	var token := str(int(transaction.get("transaction_id")))
	_open[token] = transaction
	on_purchase_updated.emit({"response_code": RC_OK, "purchases": [{
		"purchase_state": 1,
		"purchase_token": token,
		"product_ids": [String(transaction.get("product_id"))],
	}]})


## `Store` calls this once the credits are in the wallet.
func consume_purchase(token: String) -> void:
	var t = _open.get(token)
	if t != null:
		t.call("finish")
		_open.erase(token)
	consume_purchase_response.emit({"response_code": RC_OK, "token": token})


## "Restore a purchase", for a consumable: anything Apple charged for and never
## saw finished. They come back through `transaction_updated`.
func query_purchases(_type: int = 0) -> void:
	## NO EMPTY ANSWER (3 Oct 2026, audit). An immediate "nothing outstanding"
	## told `Store` there was nothing pending, and the Ask to Buy note vanished
	## while the parent still had it. What StoreKit finds arrives through
	## `transaction_updated`.
	if _sk != null:
		_sk.call("fetch_unfinished_transactions")
