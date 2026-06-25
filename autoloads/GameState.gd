extends Node

signal cat_purchased
signal cat_lost
signal research_completed(id: String)
signal cyborg_cat_created
signal cyborg_leveled(old_level: int, new_level: int)

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
# Cyborg cats: separate population from `cats`. Each earns Config.CYBORG_MULTIPLIERS[level-1]
# times the full per-cat income rate and never poops. Conversion costs 1 normal cat +
# next_cyborg_cost. Per-cat levels (1/2/3) are stored in cyborg_levels; leveling is
# gated on cyborg_level_2 / cyborg_level_3 research completion (no money cost).
var cyborg_cats: int = 0
var next_cyborg_cost: float = Config.CYBORG_COST_BASE
var cyborg_levels: Array[int] = []
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
		# No-bot fallback mirrors update_paws_rate() but with only the base per-cat rate.
		var no_bot_population: float = float(get_onlypaws_normal_cats()) \
			+ get_onlypaws_cyborg_earning_units()
		var effective_rate: float = paws_income_rate if bots_active else no_bot_population * Config.onlypaws_income_per_cat
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
		research_points[item_id] = research_points.get(item_id, 0.0) + float(rc) * delta
		if research_points[item_id] >= float(item["points_cost"]):
			research_points[item_id] = float(item["points_cost"])
			research_complete[item_id] = true
			# Increments cat_intelligence by item["cat_intelligence_gain"] from Config.RESEARCH_ITEMS
			cat_intelligence += int(item.get("cat_intelligence_gain", 0))
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
	return get_research_cats_for(cats)


## Returns the number of cats currently on OnlyPaws income.
func get_onlypaws_cats() -> int:
	return cats - get_research_cats()


## Returns how many of a given population pool are assigned to research, applying the
## same floor(pool * research_cat_fraction) split used by get_research_cats(). Used to
## split the normal-cat and cyborg-cat pools proportionally for income.
## pool: the population count to split (e.g. cats or cyborg_cats).
## Returns the integer number of that pool assigned to research.
func get_research_cats_for(pool: int) -> int:
	return int(floor(float(pool) * research_cat_fraction))


## Returns the number of normal cats currently earning OnlyPaws income (not on research).
func get_onlypaws_normal_cats() -> int:
	return cats - get_research_cats_for(cats)


## Returns the number of cyborg cats currently earning OnlyPaws income (not on research).
func get_onlypaws_cyborg_cats() -> int:
	return cyborg_cats - get_research_cats_for(cyborg_cats)


## Returns the research-split, multiplier-weighted cyborg earning contribution.
## Of cyborg_levels.size() cyborgs, get_research_cats_for(cyborg_cats) are assigned to
## research and skipped; the remaining earn Config.CYBORG_MULTIPLIERS[level-1] each.
## The skip is applied to the first N entries in cyborg_levels (deterministic ordering
## to avoid frame-to-frame jitter when the split changes).
func get_onlypaws_cyborg_earning_units() -> float:
	var total: int = cyborg_levels.size()
	if total == 0:
		return 0.0
	var on_research: int = get_research_cats_for(total)
	var units: float = 0.0
	for i: int in range(on_research, total):
		units += float(Config.CYBORG_MULTIPLIERS[cyborg_levels[i] - 1])
	return units


## Returns the number of cyborg cats eligible to be leveled up: counts V1 cyborgs when
## cyborg_level_2 research is complete, and V2 cyborgs when cyborg_level_3 is complete.
func count_cyborgs_eligible_to_level() -> int:
	var count: int = 0
	var l2_done: bool = research_complete.get("cyborg_level_2", false)
	var l3_done: bool = research_complete.get("cyborg_level_3", false)
	for level: int in cyborg_levels:
		if level == 1 and l2_done:
			count += 1
		elif level == 2 and l3_done:
			count += 1
	return count


## Levels up one eligible cyborg cat (lowest eligible index in cyborg_levels).
## A V1 cyborg is eligible when cyborg_level_2 research is complete; a V2 when
## cyborg_level_3 is complete. On success: increments the level, recalculates income,
## and emits cyborg_leveled(old_level, new_level). Returns the new level (2 or 3),
## or 0 if no eligible cyborg exists.
func level_up_cyborg() -> int:
	var l2_done: bool = research_complete.get("cyborg_level_2", false)
	var l3_done: bool = research_complete.get("cyborg_level_3", false)
	for i: int in cyborg_levels.size():
		var level: int = cyborg_levels[i]
		if level == 1 and l2_done:
			cyborg_levels[i] = 2
			update_paws_rate()
			cyborg_leveled.emit(1, 2)
			return 2
		elif level == 2 and l3_done:
			cyborg_levels[i] = 3
			update_paws_rate()
			cyborg_leveled.emit(2, 3)
			return 3
	return 0


## Returns the total cat population (normal + cyborg). Cyborgs are still cats for the
## purposes of the displayed count and the housing cap, so converting a cat keeps the
## total unchanged. Distinct from `cats`, which counts only un-converted normal cats.
func get_total_cats() -> int:
	return cats + cyborg_cats


func click() -> void:
	money += 1.0


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	# Hard cap: player cannot exceed the current housing tier's cat limit. Cyborgs still
	# occupy a slot, so the cap is measured against the total (normal + cyborg) population.
	if get_total_cats() >= get_max_cats():
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


## Converts one normal cat into a cyborg cat. Requires the cyborg_cats research to be
## complete, at least one normal cat, and enough money for next_cyborg_cost. On success:
## deducts the money, removes one normal cat, adds one cyborg cat, escalates the next
## cost by Config.CYBORG_COST_GROWTH, recalculates income, and emits cyborg_cat_created.
func buy_cyborg_cat() -> void:
	if not research_complete.get("cyborg_cats", false):
		return
	if cats < 1 or money < next_cyborg_cost:
		return
	money -= next_cyborg_cost
	cats -= 1
	cyborg_cats += 1
	cyborg_levels.append(1)
	assert(cyborg_levels.size() == cyborg_cats, "cyborg_levels must stay in sync with cyborg_cats")
	next_cyborg_cost *= Config.CYBORG_COST_GROWTH
	update_paws_rate()
	cyborg_cat_created.emit()



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
## Returns 100.0 when total cats (cats + cyborg_cats) <= 0 or poop_count <= 0; otherwise
## 100 * (1 - t*t) where t = clamp((poop_count / total) / Config.POOP_MAX_RATIO, 0, 1).
## Happiness decays quadratically as the poop-per-cat ratio rises toward
## Config.POOP_MAX_RATIO (the ratio at which happiness reaches 0%):
## ratio 1.0 ≈ 89%, 2.0 ≈ 56%, 3.0 = 0%.
func get_happiness() -> float:
	# Happiness is driven by accumulated poop relative to the TOTAL cat population
	# (normal + cyborg). Cyborgs never poop but still share the litter pressure, so
	# converting cats to cyborgs lowers the poop-per-cat ratio and raises happiness.
	# ratio = poop_count / total; happiness decays quadratically as ratio rises toward
	# Config.POOP_MAX_RATIO (the point of total degradation).
	var total: int = cats + cyborg_cats
	if total <= 0 or poop_count <= 0:
		return 100.0
	var ratio: float = float(poop_count) / float(total)
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
## manager bot count, mega bot count, and per-cat cyborg levels. Call whenever
## any of those values change.
## Income = rate * (onlypaws_normal + get_onlypaws_cyborg_earning_units()), where
## cyborg earning units = sum of Config.CYBORG_MULTIPLIERS[level-1] for each earning cyborg.
## Worked example — 20 normal cats + 10 cyborg cats (all V2, M=4), 10 bots, 5 mega-bots,
## research_cat_fraction = 0.0, and a per-mega-bot rate of 1.0:
##   rate = 0.25 + 0.50*10 + 1.0*5 = 10.25;
##   cyborg_units = 10 * 4.0 = 40.0;
##   income = 10.25 * (20 + 40) = 10.25 * 60 = 615.0/sec.
func update_paws_rate() -> void:
	var rate: float = (
		Config.onlypaws_income_per_cat
		+ Config.onlypaws_income_per_bot * float(manager_bots)
		+ Config.MEGA_BOT_INCOME_PER_CAT * float(mega_bots)
	)
	var earning_population: float = float(get_onlypaws_normal_cats()) \
		+ get_onlypaws_cyborg_earning_units()
	paws_income_rate = rate * earning_population

