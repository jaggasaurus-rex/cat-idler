extends Node

signal cat_purchased

var money: float = 0.0
var cats: int = 0
var cat_food: float = 1000.0
var next_cat_cost: float = 5.0
var shop_unlocked: bool = false
var onlypaws_unlocked: bool = false
var onlypaws_active: bool = false
var paws_income_rate: float = 0.0
var manager_bots: int = 0
var next_bot_cost: float = 50.0
var bot_shop_unlocked: bool = false
var shop_unlocked_bots: bool = false
var cat_cost_growth_rate: float = 1.5
var breeder_purchased: bool = false
var cat_trees_purchased: bool = false


func _ready() -> void:
	# Must always process so income and attrition tick even when
	# the tree is paused (e.g. during the theft warning popup).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	cat_food = max(0.0, cat_food - (float(cats) / 10.0) * delta)
	if onlypaws_active:
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
	next_cat_cost *= cat_cost_growth_rate
	if not onlypaws_unlocked and cats >= 3:
		onlypaws_unlocked = true
	if not bot_shop_unlocked and cats >= 6:
		bot_shop_unlocked = true
	_update_paws_rate()
	cat_purchased.emit()


## Deducts next_bot_cost, increments manager_bots, doubles the cost,
## and recalculates income rate.
## Unlocks the attrition-reduction shop (shop_unlocked_bots) at manager_bots == 4.
func buy_bot() -> void:
	if money < next_bot_cost:
		return
	money -= next_bot_cost
	manager_bots += 1
	next_bot_cost *= 2.0
	_update_paws_rate()
	if manager_bots == 4:
		shop_unlocked_bots = true


## Purchases the breeder contract: reduces cat_cost_growth_rate from 1.5 to 1.25
## and retroactively recalculates next_cat_cost as if all cats had been bought
## at the new rate, so the player's current position is fairly preserved.
func buy_breeder_contract() -> void:
	if money < 2000.0 or breeder_purchased:
		return
	money -= 2000.0
	breeder_purchased = true
	cat_cost_growth_rate = 1.25
	next_cat_cost = 5.0 * pow(cat_cost_growth_rate, float(cats))


## Returns how many cat food packs ($10 each) the player can currently afford.
func get_cat_food_packs_affordable() -> int:
	return int(money / 10.0)


## Purchases quantity cat food packs at $10 each, adding 100 cat food per pack.
func buy_cat_food_pack(quantity: int) -> void:
	if money < 10.0 * float(quantity):
		return
	money -= 10.0 * float(quantity)
	cat_food += 100.0 * float(quantity)


## Purchases cat trees upgrade.
func buy_cat_trees() -> void:
	if money < 4000.0 or cat_trees_purchased:
		return
	money -= 4000.0
	cat_trees_purchased = true


# Base tier: floor(cats / 3) $/sec (0-2 cats=$0, 3-5=$1, 6-8=$2, …).
# Each manager bot doubles the entire output: total = base * 2^manager_bots.
func _update_paws_rate() -> void:
	paws_income_rate = float(cats / 3) * pow(2.0, manager_bots)
