extends Node

signal cat_purchased
signal cat_lost
signal research_completed(id: String)

var money: float = 0.0
var cats: int = 0
var cat_food: float = Config.cat_food_start
var next_cat_cost: float = Config.cat_cost_base
var only_paws_unlocked: bool = false
var only_paws_active: bool = false
var paws_income_rate: float = 0.0
var manager_bots: int = 0
var next_bot_cost: float = Config.bot_cost_base
var mega_bots: int = 0
var next_mega_bot_cost: float = Config.MEGA_BOT_COST_BASE
var bot_shop_unlocked: bool = false
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
var pawsco_membership_purchased: bool = false
var ai_enterprise_purchased: bool = false
var robo_sweeper_count: int = 0
var next_robo_sweeper_cost: float = Config.ROBO_SWEEPER_PURCHASE_COST
var first_cat_popup_shown: bool = false
var starvation_count: int = 0
var starvation_active: bool = false
var starvation_cats_lost: int = 0
var cats_ever_purchased: int = 0
var happiness_cramped_triggered: bool = false
var happiness_riot_triggered: bool = false
var poop_count: int = 0
var home_shop_unlocked: bool = false
var upgrades_tab_popup_shown: bool = false
var bot_unlock_popup_shown: bool = false
var bot_manager_unlock_popup_shown: bool = false

# 0.0 = all cats on OnlyPaws; 1.0 = all cats on research
var research_cat_fraction: float = 0.0
# id -> bool; true once player has paid fund_cost
var research_funded: Dictionary = {}
# id -> float; accumulated progress points
var research_points: Dictionary = {}
# id -> bool; true once points_cost reached (named research_complete to avoid clash with signal)
var research_complete: Dictionary = {}
var cat_intelligence: int = 0
var _idle_intel_accumulator: float = 0.0

# Viral bubble unlock: gates on owning two bots, then a 20s delay before bubbles can appear.
var _viral_delay_timer: float = 0.0
var viral_bubbles_unlocked: bool = false
var viral_popup_shown: bool = false
var inspiration_popup_shown: bool = false


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
	var _starving: bool = cat_food <= 0.0 and money < get_cat_food_pack_cost()
	if _starving and not starvation_active:
		starvation_active = true
		starvation_count += 1
	elif not _starving and starvation_active:
		starvation_active = false
	if bots_active:
		tokens -= ((float(manager_bots) * Config.token_drain_per_bot) + (float(mega_bots) * Config.MEGA_BOT_TOKEN_DRAIN)) * delta
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
	var happiness: float = get_happiness()
	if not happiness_riot_triggered and happiness <= 0.0:
		happiness_riot_triggered = true
	if only_paws_active and cat_food > 0.0:
		var happiness_multiplier: float = Config.happiness_income_floor + (happiness / 100.0) * Config.happiness_income_range
		var effective_rate: float = paws_income_rate if bots_active else float(get_onlypaws_cats()) * Config.onlypaws_income_per_cat * get_cyborg_multiplier()
		money += effective_rate * happiness_multiplier * delta
	for item: Dictionary in Config.RESEARCH_ITEMS:
		var item_id: String = item["id"]
		if not research_funded.get(item_id, false):
			continue
		if research_complete.get(item_id, false):
			continue
		var rc: int = get_research_cats()
		if rc < int(item["min_cats_required"]):
			continue
		research_points[item_id] = research_points.get(item_id, 0.0) + float(rc) * get_cyborg_multiplier() * delta
		if research_points[item_id] >= float(item["points_cost"]):
			research_points[item_id] = float(item["points_cost"])
			research_complete[item_id] = true
			cat_intelligence += int(item.get("cat_intelligence_gain", 0))
			update_paws_rate()
			research_completed.emit(item_id)
	# Idle research intelligence: cats assigned to research with no active item
	# slowly raise cat_intelligence. Accumulate fractional points, bank whole ones.
	# blocked until cat_power_unite research_complete — no idle accrual before it.
	if get_active_research_id() == "" and get_research_cats() > 0 and research_complete.get("cat_power_unite", false):
		_idle_intel_accumulator += float(get_research_cats()) * Config.IDLE_RESEARCH_INTEL_RATE * delta
		var whole_points: int = int(floor(_idle_intel_accumulator))
		if whole_points > 0:
			cat_intelligence += whole_points
			_idle_intel_accumulator -= float(whole_points)
	else:
		_idle_intel_accumulator = 0.0
	# Viral bubble unlock: once two bots are owned, count up 20s before enabling bubbles.
	if manager_bots >= 2 and not viral_bubbles_unlocked:
		_viral_delay_timer += delta
		if _viral_delay_timer >= 20.0:
			viral_bubbles_unlocked = true


## Returns the id of the first research item that is funded but not yet complete,
## iterating Config.RESEARCH_ITEMS in order. Returns "" if no such item exists.
func get_active_research_id() -> String:
	for item: Dictionary in Config.RESEARCH_ITEMS:
		var item_id: String = item["id"]
		if research_funded.get(item_id, false) and not research_complete.get(item_id, false):
			return item_id
	return ""


## Returns the number of cats currently assigned to research.
func get_research_cats() -> int:
	return int(floor(float(cats) * research_cat_fraction))


## Returns the number of cats currently on OnlyPaws income.
func get_onlypaws_cats() -> int:
	return cats - get_research_cats()


## Returns the global cyborg income multiplier: 2^(number of completed cyborg research tiers).
## Returns 1.0 when no cyborg research is complete.
func get_cyborg_multiplier() -> float:
	var count: int = 0
	for tier_id: String in ["cyborg_cats", "cyborg_level_2", "cyborg_level_3", "cyborg_level_4"]:
		if research_complete.get(tier_id, false):
			count += 1
	return pow(2.0, float(count))


func click() -> void:
	money += 1.0


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	if cats >= get_max_cats():
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
	update_paws_rate()
	cat_purchased.emit()


## Deducts next_bot_cost, increments manager_bots, doubles the cost,
## and recalculates income rate.
func buy_bot() -> void:
	if money < next_bot_cost:
		return
	money -= next_bot_cost
	manager_bots += 1
	next_bot_cost *= Config.bot_cost_multiplier
	update_paws_rate()
	if not tokens_shop_unlocked and manager_bots >= 1:
		tokens_shop_unlocked = true


## Purchases one Mega Manager-Bot. Deducts money, increments mega_bots,
## multiplies next_mega_bot_cost by Config.bot_cost_multiplier, and
## recalculates income rate.
func buy_mega_bot() -> void:
	if money < next_mega_bot_cost:
		return
	money -= next_mega_bot_cost
	mega_bots += 1
	next_mega_bot_cost *= Config.bot_cost_multiplier
	update_paws_rate()


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


## Returns how many cat food packs the player can currently afford at the current price.
func get_cat_food_packs_affordable() -> int:
	return int(money / get_cat_food_pack_cost())


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
	update_paws_rate()
	starvation_cats_lost += 1
	cat_lost.emit()


## Purchases quantity cat food packs, adding cat_food_pack_amount per pack.
func buy_cat_food_pack(quantity: int) -> void:
	if money < get_cat_food_pack_cost() * float(quantity):
		return
	money -= get_cat_food_pack_cost() * float(quantity)
	cat_food += Config.cat_food_pack_amount * float(quantity)


## Purchases quantity token packs, adding token_pack_amount per pack.
func buy_tokens(quantity: int) -> void:
	if money < get_token_pack_cost() * float(quantity):
		return
	money -= get_token_pack_cost() * float(quantity)
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


## Returns the cat food pack cost; discounted to cat_food_pack_cost_discounted
## when pawsco_membership_purchased, otherwise Config.cat_food_pack_cost.
func get_cat_food_pack_cost() -> float:
	if pawsco_membership_purchased:
		return Config.cat_food_pack_cost_discounted
	return Config.cat_food_pack_cost


## Returns the token pack cost; discounted to token_pack_cost_discounted
## when ai_enterprise_purchased, otherwise Config.token_pack_cost.
func get_token_pack_cost() -> float:
	if ai_enterprise_purchased:
		return Config.token_pack_cost_discounted
	return Config.token_pack_cost


## Purchases PawsCo Membership: reduces cat food pack cost from $10 to $9.
func buy_pawsco_membership() -> void:
	if money < Config.pawsco_membership_cost or pawsco_membership_purchased:
		return
	money -= Config.pawsco_membership_cost
	pawsco_membership_purchased = true


## Purchases AI Enterprise Membership: reduces token pack cost from $20 to $15.
func buy_ai_enterprise_membership() -> void:
	if money < Config.ai_enterprise_membership_cost or ai_enterprise_purchased:
		return
	money -= Config.ai_enterprise_membership_cost
	ai_enterprise_purchased = true


## Purchases the next Robo-Shit Sweeper once research is complete.
## No-ops if research not complete or insufficient funds. Each purchase costs
## Config.ROBO_SWEEPER_COST_MULTIPLIER (3×) more than the previous one.
## Cost sequence: $10,000 / $30,000 / $90,000 / …
func buy_robo_sweeper() -> void:
	if not research_complete.get("robo_shit_sweeper", false):
		return
	if money < next_robo_sweeper_cost:
		return
	money -= next_robo_sweeper_cost
	robo_sweeper_count += 1
	next_robo_sweeper_cost *= Config.ROBO_SWEEPER_COST_MULTIPLIER


## Returns the current cat cap: base_max_cats plus max_cats_increase for each
## purchased housing tier (tiers 1..housing_tier_index).
func get_max_cats() -> int:
	var total: int = Config.base_max_cats
	for i: int in range(1, housing_tier_index + 1):
		total += int(Config.housing_tiers[i]["max_cats_increase"])
	return total


## Returns cat happiness as a percentage (0–100). Poop-driven model.
## Returns 100.0 when cats <= 0 or poop_count <= 0; otherwise
## 100 * (1 - t*t) where t = clamp((poop_count / cats) / Config.POOP_MAX_RATIO, 0, 1).
## Happiness decays quadratically as the poop-per-cat ratio rises toward
## Config.POOP_MAX_RATIO (the ratio at which happiness reaches 0%):
## ratio 1.0 ≈ 89%, 2.0 ≈ 56%, 3.0 = 0%.
func get_happiness() -> float:
	if cats <= 0 or poop_count <= 0:
		return 100.0
	var ratio: float = float(poop_count) / float(cats)
	var t: float = clamp(ratio / Config.POOP_MAX_RATIO, 0.0, 1.0)
	return 100.0 * (1.0 - t * t)


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


## Pays fund_cost to unlock a research item, enabling point accumulation.
## No-ops if already funded or money is insufficient.
func fund_research(id: String) -> void:
	for item: Dictionary in Config.RESEARCH_ITEMS:
		if item["id"] == id:
			if money >= float(item["fund_cost"]) and not research_funded.get(id, false):
				money -= float(item["fund_cost"])
				research_funded[id] = true
				research_points[id] = 0.0
			return


## Recalculates paws_income_rate from the current cat count, research fraction,
## manager bot count, mega bot count, and the global cyborg multiplier. Call whenever
## any of those values change.
## Income = rate * get_cyborg_multiplier() * get_onlypaws_cats(), where
## rate = base per-cat income + bot contributions.
func update_paws_rate() -> void:
	var rate: float = (
		Config.onlypaws_income_per_cat
		+ Config.onlypaws_income_per_bot * float(manager_bots)
		+ Config.MEGA_BOT_INCOME_PER_CAT * float(mega_bots)
	) * get_cyborg_multiplier()
	var earning_population: float = float(get_onlypaws_cats())
	paws_income_rate = rate * earning_population
