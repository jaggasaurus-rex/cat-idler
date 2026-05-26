extends Node

signal cat_purchased

var money: float = 0.0
var cats: int = 0
var next_cat_cost: float = 5.0
var shop_unlocked: bool = false
var onlypaws_unlocked: bool = false
var paws_income_rate: float = 0.0
var manager_bots: int = 0
var next_bot_cost: float = 50.0
var bot_shop_unlocked: bool = false


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
	if not bot_shop_unlocked and cats >= 6:
		bot_shop_unlocked = true
	_update_paws_rate()
	cat_purchased.emit()


## Deducts next_bot_cost, increments manager_bots, doubles the cost,
## and recalculates the paws income rate. Each bot is a full doubling
## of total output, so n bots = 2^n multiplier via pow(2, manager_bots).
func buy_bot() -> void:
	if money < next_bot_cost:
		return
	money -= next_bot_cost
	manager_bots += 1
	next_bot_cost *= 2.0
	_update_paws_rate()


# Base tier: floor(cats / 3) $/sec (0-2 cats=$0, 3-5=$1, 6-8=$2, …).
# Each manager bot doubles the entire output: total = base * 2^manager_bots.
func _update_paws_rate() -> void:
	paws_income_rate = float(cats / 3) * pow(2.0, manager_bots)
