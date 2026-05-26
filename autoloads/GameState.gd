extends Node

signal cat_purchased

var money: float = 0.0
var cats: int = 0
var next_cat_cost: float = 5.0
var shop_unlocked: bool = false
var onlypaws_unlocked: bool = false
var paws_income_rate: float = 0.0


func _process(delta: float) -> void:
	if onlypaws_unlocked:
		money += paws_income_rate * delta


func click() -> void:
	money += 1.0
	if not shop_unlocked and money >= next_cat_cost:
		shop_unlocked = true


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	money -= next_cat_cost
	cats += 1
	next_cat_cost *= 1.5
	if not onlypaws_unlocked and cats >= 3:
		onlypaws_unlocked = true
	_update_paws_rate()
	cat_purchased.emit()


# Income tier: 0/sec for 0-2 cats, 1/sec for 3-5, 2/sec for 6-8, etc.
# Uses integer floor division — never fractional or linear.
func _update_paws_rate() -> void:
	paws_income_rate = float(cats / 3)
