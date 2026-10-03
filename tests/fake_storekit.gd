extends Object
## A stand-in for GodotApplePlugins' StoreKitManager: its signals, its method
## names, and objects with the same exported fields. `test_store.gd` drives it.

signal products_request_completed(products: Array, status: int)
signal purchase_completed(transaction, status: int, message: String)
signal transaction_updated(transaction)
signal unverified_transaction_updated(transaction, verification_error: int)

var started := false
var unfinished_asked := 0
var bought: Array = []
var finished: Array = []
var next_id := 1000


class FakeProduct extends RefCounted:
	var product_id := ""
	var display_price := ""


class FakeTx extends RefCounted:
	var transaction_id := 0
	var product_id := ""
	var owner_ref: Object = null
	func finish() -> void:
		owner_ref.finished.append(transaction_id)


func start() -> void:
	started = true


func request_products(ids: PackedStringArray) -> void:
	var out: Array = []
	for id in ids:
		var p := FakeProduct.new()
		p.product_id = id
		p.display_price = "1,99 €" if id == "cc_small" else "9,99 €"
		out.append(p)
	products_request_completed.emit(out, 0)


func purchase(product) -> void:
	bought.append(product.product_id)


func fetch_unfinished_transactions() -> void:
	unfinished_asked += 1


## The App Store's answer to the last purchase: 0 OK, 4 user cancelled, 5 pending.
func answer(status: int) -> FakeTx:
	var t: FakeTx = null
	if status == 0:
		t = tx(String(bought.back()))
	purchase_completed.emit(t, status, "")
	return t


func tx(pid: String) -> FakeTx:
	var t := FakeTx.new()
	next_id += 1
	t.transaction_id = next_id
	t.product_id = pid
	t.owner_ref = self
	return t
