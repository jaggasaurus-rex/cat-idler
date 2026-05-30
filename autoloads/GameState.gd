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
var tokens: float = Config.token_start
var bots_active: bool = true
var tokens_shop_unlocked: bool = false
var bot_manager_unlocked: bool = false
var bot_manager_purchased: bool = false
var food_hit_zero: bool = false
var auto_feeder_unlocked: bool = false
var auto_feeder_purchased: bool = false


func _ready() -> void:
	# Must always process so income and attrition tick even when
	# the tree is paused (e.g. during the theft warning popup).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	cat_food = max(0.0, cat_food - float(cats) * Config.cat_food_drain_rate * delta)
	if not food_hit_zero and cat_food <= 0.0:
		food_hit_zero = true
	if not auto_feeder_unlocked:
		if cats >= Config.auto_feeder_unlock_cats or food_hit_zero:
			auto_feeder_unlocked = true
	if auto_feeder_purchased and cat_food <= Config.auto_feeder_food_threshold:
		buy_cat_food_pack(1)
	if bots_active:
		tokens -= float(manager_bots) * Config.token_drain_per_bot * delta
		if tokens <= 0.0:
			tokens = 0.0
			bots_active = false
	if not bot_manager_unlocked:
		if tokens <= 0.0 or manager_bots >= Config.bot_manager_unlock_bots:
			bot_manager_unlocked = true
	if bot_manager_purchased and tokens <= Config.bot_manager_token_threshold:
		buy_tokens(1)
	if onlypaws_active and bots_active:
		if cat_food > 0.0:
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
	if tokens > 0.0:
		bots_active = true


## Purchases the bot manager upgrade: automatically buys token packs when tokens
## fall to or below Config.bot_manager_token_threshold.
func buy_bot_manager() -> void:
	if money < Config.bot_manager_cost or bot_manager_purchased:
		return
	money -= Config.bot_manager_cost
	bot_manager_purchased = true


## Purchases the auto-feeder upgrade: automatically buys cat food packs when
## food falls to or below Config.auto_feeder_food_threshold.
func buy_auto_feeder() -> void:
	if money < Config.auto_feeder_cost or auto_feeder_purchased:
		return
	money -= Config.auto_feeder_cost
	auto_feeder_purchased = true


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
