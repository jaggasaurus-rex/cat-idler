extends Node

signal cat_purchased
signal cat_lost

var money: float = 0.0
var cats: int = 0
var cat_food: float = Config.cat_food_start
var next_cat_cost: float = Config.cat_cost_base
var shop_unlocked: bool = false
var only_paws_unlocked: bool = false
var only_paws_active: bool = false
var paws_income_rate: float = 0.0
var manager_bots: int = 0
var next_bot_cost: float = Config.bot_cost_base
var bot_shop_unlocked: bool = false
var shop_unlocked_bots: bool = false
var cat_cost_growth_rate: float = Config.cat_cost_growth_rate
var breeder_purchased: bool = false
# cat_trees_purchased removed — replaced by housing_tier_index >= 1.
# All former reads of cat_trees_purchased were changed to housing_tier_index >= 1:
#   get_happiness() now calls get_max_cats() which sums housing tier increases.
#   Main.gd _process() max_cats line now calls GameState.get_max_cats().
#   Main.gd cat trees @onready vars, button state block, and handler removed.
var housing_tier_index: int = 0
var tokens: float = Config.token_start
var bots_active: bool = true
var tokens_shop_unlocked: bool = false
var bot_manager_unlocked: bool = false
var bot_manager_purchased: bool = false
var food_hit_zero: bool = false
var auto_feeder_unlocked: bool = false
var auto_feeder_purchased: bool = false
var first_cat_popup_shown: bool = false
var starvation_count: int = 0
var starvation_active: bool = false
var starvation_cats_lost: int = 0
var cats_ever_purchased: int = 0
var happiness_cramped_triggered: bool = false
var happiness_riot_triggered: bool = false
var happiness_zero_count: int = 0
var cat_crusher_triggered: bool = false
var cat_crusher_unlocked: bool = false
var _happiness_was_zero: bool = false
var _cat_loss_active: bool = false
var _cat_loss_timer: float = 0.0
var home_shop_unlocked: bool = false
var upgrades_tab_popup_shown: bool = false
var bot_unlock_popup_shown: bool = false


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
	# Starvation: food depleted and player cannot afford a food pack.
	# starvation_active debounces so count only increments once per contiguous window.
	# Resets when cat_food > 0 OR money >= cat_food_pack_cost.
	var _starving: bool = cat_food <= 0.0 and money < Config.cat_food_pack_cost
	if _starving and not starvation_active:
		starvation_active = true
		starvation_count += 1
	elif not _starving and starvation_active:
		starvation_active = false
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
	if not happiness_cramped_triggered and cats >= Config.HOUSING_UPGRADE_PROMPT_THRESHOLD:
		happiness_cramped_triggered = true
	if not happiness_riot_triggered and get_happiness() <= 0.0:
		happiness_riot_triggered = true
	# Count distinct transitions into 0% happiness; second transition triggers Cat Crusher
	var _now_zero: bool = get_happiness() <= 0.0
	if _now_zero and not _happiness_was_zero:
		happiness_zero_count += 1
		if happiness_zero_count >= 2 and not cat_crusher_triggered:
			cat_crusher_triggered = true
	_happiness_was_zero = _now_zero
	# Cat loss drain: starts when cat_crusher_unlocked and happiness <= 20%.
	# Activating immediately loses one cat; further cats lost every 10 seconds.
	# Drain stops when happiness rises above 80% (naturally includes cats == 0,
	# since 0 cats → 100% happiness, which exceeds 80% and deactivates the drain).
	if cat_crusher_unlocked:
		var drain_happiness: float = get_happiness()
		if _cat_loss_active and drain_happiness > 80.0:
			_cat_loss_active = false
			_cat_loss_timer = 0.0
		elif not _cat_loss_active and drain_happiness <= 20.0:
			_cat_loss_active = true
			_lose_cat()
			_cat_loss_timer = 0.0
		if _cat_loss_active:
			_cat_loss_timer += delta
			if _cat_loss_timer >= 10.0:
				_cat_loss_timer -= 10.0
				_lose_cat()
	if only_paws_active and bots_active:
		if cat_food > 0.0:
			var happiness: float = get_happiness()
			# Linear map: 0% happiness → ×0.30, 100% happiness → ×1.00
			var happiness_multiplier: float = 0.30 + (happiness / 100.0) * 0.70
			money += paws_income_rate * happiness_multiplier * delta


func click() -> void:
	money += 1.0
	if not shop_unlocked and money >= next_cat_cost:
		shop_unlocked = true


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	money -= next_cat_cost
	cats += 1
	cats_ever_purchased += 1
	next_cat_cost *= cat_cost_growth_rate
	if not only_paws_unlocked and cats >= Config.only_paws_unlock_cats:
		only_paws_unlocked = true
		only_paws_active = true
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


## Grants one cat food pack worth of food without charging the player.
## Used for starvation pity rewards.
func grant_cat_food_pack() -> void:
	cat_food += Config.cat_food_pack_amount


## Removes one cat as a starvation penalty: decrements cats (clamped to 0),
## updates income rate, increments starvation_cats_lost, and emits cat_lost
## so Main.gd removes the node and repositions the row.
func starvation_lose_cat() -> void:
	if cats <= 0:
		return
	cats -= 1
	_update_paws_rate()
	starvation_cats_lost += 1
	cat_lost.emit()


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


## Returns the current cat cap: base_max_cats plus max_cats_increase for each
## purchased housing tier (tiers 1..housing_tier_index).
func get_max_cats() -> int:
	var total: int = Config.base_max_cats
	for i: int in range(1, housing_tier_index + 1):
		total += int(Config.housing_tiers[i]["max_cats_increase"])
	return total


## Returns cat happiness as a percentage (0–100).
## At or under max_cats: always 100%.
## Two-segment quadratic ease-in decay above max_cats, breakpoints scaled by housing tier:
##   fifty_break = max_cats + Config.happiness_fifty_break_offset + housing_tier_index  → happiness = 50%
##   zero_break  = max_cats + Config.happiness_zero_break_offset + housing_tier_index * 2  → happiness = 0%
## Segment 1 (max_cats < cats < fifty_break): t^2 ease-in from 100% down to 50%.
## Segment 2 (fifty_break <= cats < zero_break): t^2 ease-in from 50% down to 0%.
func get_happiness() -> float:
	var max_cats: int = get_max_cats()
	if cats <= max_cats:
		return 100.0
	var bp: Array[int] = _happiness_breakpoints(max_cats)
	var fifty_break: int = bp[0]
	var zero_break: int = bp[1]
	if cats >= zero_break:
		return 0.0
	if cats < fifty_break:
		var t: float = float(cats - max_cats) / float(fifty_break - max_cats)
		return 100.0 - t * t * 50.0
	var t: float = float(cats - fifty_break) / float(zero_break - fifty_break)
	return 50.0 - t * t * 50.0


# Returns [fifty_break, zero_break] cat counts for the given max_cats and current housing tier.
# fifty_break: cats count where happiness hits 50%; zero_break: where it hits 0%.
# Both widen as housing_tier_index increases, rewarding housing investment.
func _happiness_breakpoints(max_cats: int) -> Array[int]:
	return [
		max_cats + Config.happiness_fifty_break_offset + housing_tier_index,
		max_cats + Config.happiness_zero_break_offset + housing_tier_index * 2,
	]


## Purchases the next housing tier, increasing the max_cats threshold.
## No-ops if already at the final tier or money is insufficient.
func buy_housing_upgrade() -> void:
	var next_index: int = housing_tier_index + 1
	if next_index >= Config.housing_tiers.size():
		return
	var cost: float = float(Config.housing_tiers[next_index]["cost"])
	if money < cost:
		return
	money -= cost
	housing_tier_index = next_index


# Base rate: cats * onlypaws_income_per_cat (at unlock: 3 * 0.25 = $0.75/sec).
# Each manager bot doubles the entire output: total = base * 2^manager_bots.
func _update_paws_rate() -> void:
	paws_income_rate = float(cats) * Config.onlypaws_income_per_cat * pow(2.0, manager_bots)


# Removes one cat from the count, recalculates paws rate, and signals Main.gd
# to remove the corresponding CatCharacter node from CatContainer.
func _lose_cat() -> void:
	if cats <= 0:
		return
	cats -= 1
	_update_paws_rate()
	cat_lost.emit()
