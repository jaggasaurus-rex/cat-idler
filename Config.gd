extends Node

# Cat food
const cat_food_start: float = 1000.0
const cat_food_drain_rate: float = 0.1  # food drained per cat per second

# Cat food pack shop
const cat_food_pack_cost: float = 10.0
const cat_food_pack_amount: float = 100.0

# Tokens
const token_start: float = 1000.0
const token_drain_per_bot: float = 1.0  # tokens drained per bot per second
const token_pack_cost: float = 20.0
const token_pack_amount: float = 100.0

# Cats
const cat_cost_base: float = 5.0
const cat_cost_growth_rate: float = 1.5
const only_paws_unlock_cats: int = 3
const only_paws_cats_per_tier: int = 3  # floor(cats / N) = base OnlyPaws income tier
const onlypaws_income_per_cat: float = 0.25  # base $/sec per cat; at unlock (3 cats): 3 * 0.25 = $0.75/sec
const bot_shop_unlock_cats: int = 6

# Bots
const bot_cost_base: float = 50.0
const bot_cost_multiplier: float = 2.0

# Upgrades
const breeder_contract_cost: float = 2000.0
const breeder_contract_growth_rate: float = 1.25
const bot_manager_cost: float = 1000000.0
const bot_manager_unlock_bots: int = 10
const bot_manager_token_threshold: float = 1.0

# Auto-Feeder upgrade
const auto_feeder_cost: float = 2000000.0
const auto_feeder_unlock_cats: int = 30
const auto_feeder_food_threshold: float = 1.0

# Cat Happiness
const base_max_cats: int = 20  # baseline cat cap before any housing upgrades
# Controls how steeply happiness falls per unit of proportional overage (overage_pct^2 * scale).
# At 100.0 the curve hits 0% when cats exactly double max_cats (overage_pct = 1.0).
const happiness_decay_scale: float = 100.0

# Housing upgrade chain — ordered from cheapest to most expensive.
# cost[n] = sum(cost[0..n-1]) * 3  (verified: 0, 10k, 30k, 120k, 480k)
# max_cats_increase is summed for tiers 1..housing_tier_index and added to base_max_cats.
# Each entry: {id: String, label: String, cost: float, max_cats_increase: int}
const housing_tiers: Array = [
	{"id": "studio_basic",    "label": "Basic Studio",    "cost": 0.0,      "max_cats_increase": 0},
	{"id": "studio_upgraded", "label": "Upgraded Studio", "cost": 10000.0,  "max_cats_increase": 10},
	{"id": "bedroom_1",       "label": "1 Bedroom",       "cost": 30000.0,  "max_cats_increase": 10},
	{"id": "bedroom_2",       "label": "2 Bedroom",       "cost": 120000.0, "max_cats_increase": 10},
	{"id": "bedroom_3",       "label": "3 Bedroom",       "cost": 480000.0, "max_cats_increase": 10},
]
