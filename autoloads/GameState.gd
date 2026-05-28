extends Node

signal cat_purchased

var money: float = 0.0
var cats: int = 0
var cat_food: float = Config.cat_food_start
var next_cat_cost: float = Config.cat_cost_base
var shop_unlocked: bool = false
var onlypaws_unlocked: bool = false
var onlypaws_active: bool = false
var paws_income_rate: float = 0.0
var manager_bots: int = 0
var next_bot_cost: float = Config.bot_cost_base
var bot_shop_unlocked: bool = false
var shop_unlocked_bots: bool = false
var cat_cost_growth_rate: float = Config.cat_cost_growth_rate
var breeder_purchased: bool = false
var cat_trees_purchased: bool = false
var tokens: float = 0.0
var tokens_shop_unlocked: bool = false


func _ready() -> void:
	# Must always process so income and attrition tick even when
	# the tree is paused (e.g. during the theft warning popup).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	cat_food = max(0.0, cat_food - float(cats) * Config.cat_food_drain_rate * delta)
	tokens = max(0.0, tokens - float(manager_bots) * Config.token_drain_per_bot * delta)
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
	if not onlypaws_unlocked and cats >= Config.onlypaws_unlock_cats:
		onlypaws_unlocked = true
	if not bot_shop_unlocked and cats >= Config.bot_shop_unlock_cats:
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
	next_bot_cost *= Config.bot_cost_multiplier
	_update_paws_rate()
	if not tokens_shop_unlocked and manager_bots >= 1:
		tokens_shop_unlocked = true
	if manager_bots == 4:
		shop_unlocked_bots = true


## Purchases the breeder contract: reduces cat_cost_growth_rate from 1.5 to 1.25
## and retroactively recalculates next_cat_cost as if all cats had been bought
## at the new rate, so the player's current position is fairly preserved.
func buy_breeder_contract() -> void:
	if money < Config.breeder_contract_cost or breeder_purchased:
		return
	money -= Config.breeder_contract_cost
	breeder_purchased = true
	cat_cost_growth_rate = Config.breeder_contract_growth_rate
	next_cat_cost = Config.cat_cost_base * pow(cat_cost_growth_rate, float(cats))


## Returns how many cat food packs ($10 each) the player can currently afford.
func get_cat_food_packs_affordable() -> int:
	return int(money / Config.cat_food_pack_cost)


## Purchases quantity cat food packs, adding cat_food_pack_amount per pack.
func buy_cat_food_pack(quantity: int) -> void:
	if money < Config.cat_food_pack_cost * float(quantity):
		return
	money -= Config.cat_food_pack_cost * float(quantity)
	cat_food += Config.cat_food_pack_amount * float(quantity)


## Purchases quantity token packs, adding token_pack_amount per pack.
func buy_tokens(quantity: int) -> void:
	if money < Config.token_pack_cost * float(quantity):
		return
	money -= Config.token_pack_cost * float(quantity)
	tokens += Config.token_pack_amount * float(quantity)


## Purchases cat trees upgrade.
func buy_cat_trees() -> void:
	if money < Config.cat_trees_cost or cat_trees_purchased:
		return
	money -= Config.cat_trees_cost
	cat_trees_purchased = true


# Base tier: floor(cats / 3) $/sec (0-2 cats=$0, 3-5=$1, 6-8=$2, …).
# Each manager bot doubles the entire output: total = base * 2^manager_bots.
func _update_paws_rate() -> void:
	paws_income_rate = float(cats / Config.onlypaws_cats_per_tier) * pow(2.0, manager_bots)
