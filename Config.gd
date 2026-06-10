extends Node

# Cat food
const cat_food_start: float = 1000.0
const cat_food_drain_rate: float = 1.0  # food drained per cat per second (was 0.2)

# Cat food pack shop
const cat_food_pack_cost: float = 10.0
const cat_food_pack_amount: float = 100.0

# Tokens
const token_start: float = 1000.0
const token_drain_per_bot: float = 2.0  # tokens drained per bot per second (was 1.0)
const token_pack_cost: float = 20.0
const token_pack_amount: float = 100.0

# Cats
const cat_cost_base: float = 5.0
const cat_cost_growth_rate: float = 1.4
const only_paws_unlock_cats: int = 3
const only_paws_cats_per_tier: int = 3  # floor(cats / N) = base OnlyPaws income tier
const onlypaws_income_per_cat: float = 0.25  # base $/sec per cat; at unlock (3 cats): 3 * 0.25 = $0.75/sec
const onlypaws_income_per_bot: float = 0.50  # additional $/sec per cat per bot
const bot_shop_unlock_cats: int = 6

# Bots
const bot_cost_base: float = 50.0
const bot_cost_multiplier: float = 1.6

# Upgrades
const breeder_contract_cost: float = 2000.0
const breeder_contract_growth_rate: float = 1.25
const bot_manager_cost: float = 4000.0
const bot_manager_unlock_bots: int = 6
const bot_manager_token_threshold: float = 1.0

# Auto-Feeder upgrade
const auto_feeder_cost: float = 2000.0
const auto_feeder_unlock_cats: int = 10
const auto_feeder_food_threshold: float = 1.0

# PawsCo Membership upgrade
const pawsco_membership_cost: float = 800.0
const cat_food_pack_cost_discounted: float = 9.0  # active when pawsco_membership_purchased

# AI Enterprise Membership upgrade
const ai_enterprise_membership_cost: float = 1000.0
const token_pack_cost_discounted: float = 15.0  # active when ai_enterprise_purchased

# Cat Happiness
const base_max_cats: int = 10  # baseline cat cap before any housing upgrades
# Base cats-over-max_cats where happiness hits 50% (fifty) and 0% (zero) at housing tier 0.
# Both breakpoints widen with housing tier: fifty adds +tier, zero adds +tier*2.
# This means the 50% point drifts later relative to 0% as tier increases — intentional design.
const happiness_fifty_break_offset: int = 2
const happiness_zero_break_offset: int = 5
# Cat-loss drain hysteresis: drain turns on at/below activate, off above deactivate.
const happiness_cat_loss_activate: float = 20.0
const happiness_cat_loss_deactivate: float = 60.0
# Income multiplier: floor at 0% happiness, plus range added linearly up to 100%.
const happiness_income_floor: float = 0.30
const happiness_income_range: float = 0.70

# Cat count at which the "your cats are cramped" popup fires and the Home tab unlocks.
const HOUSING_UPGRADE_PROMPT_THRESHOLD: int = 8

# Housing upgrade chain — ordered from cheapest to most expensive.
# cost[n]: 0, 500, 3500, 11500, 46000
# max_cats_increase is summed for tiers 1..housing_tier_index and added to base_max_cats.
# Each entry: {id: String, label: String, cost: float, max_cats_increase: int}
const housing_tiers: Array = [
	{"id": "studio_basic",    "label": "Basic Studio",      "cost": 0.0,     "max_cats_increase": 0},
	{"id": "studio_upgraded", "label": "Luxury Cat Trees",  "cost": 500.0,   "max_cats_increase": 10},
	{"id": "bedroom_1",       "label": "1 Bedroom",         "cost": 3500.0,  "max_cats_increase": 10},
	{"id": "bedroom_2",       "label": "2 Bedroom",         "cost": 11500.0, "max_cats_increase": 10},
	{"id": "bedroom_3",       "label": "3 Bedroom",         "cost": 46000.0, "max_cats_increase": 10},
]

# Research items — each entry defines a fundable, cat-powered research project.
const RESEARCH_ITEMS: Array = [
	{
		"id": "cat_power_unite",
		"name": "Cat Power Unite",
		"subtitle": "Cat Intelligence +1",
		"description": "This will make your cats smart enough to research upgrades for you, but they're not exactly tiny geniuses right now. So, it's going to take a LOT of cats to kick it off.",
		"fund_cost": 1000.0,
		"points_cost": 200.0,
		"min_cats_required": 10,
		"cat_intelligence_gain": 1,
	},
]

# Bubble mechanic
const BUBBLE_SPAWN_MIN: float = 5.0           # min seconds of a per-cat bubble cooldown
const BUBBLE_SPAWN_MAX: float = 15.0          # max seconds of a per-cat bubble cooldown
const BUBBLE_LIFETIME: float = 4.5            # seconds before a bubble fades out
const BUBBLE_MAX_ON_SCREEN: int = 4           # cap on simultaneous bubbles
const BUBBLE_VIRAL_MULTIPLIER: float = 4.0    # viral reward = paws_income_rate × this
const BUBBLE_INSPIRATION_SECONDS: float = 3.0 # inspiration reward = research_cats × this many seconds of points
