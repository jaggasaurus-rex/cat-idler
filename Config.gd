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
const onlypaws_unlock_cats: int = 3
const onlypaws_cats_per_tier: int = 3  # floor(cats / N) = base Onlypaws income tier
const bot_shop_unlock_cats: int = 6

# Bots
const bot_cost_base: float = 50.0
const bot_cost_multiplier: float = 2.0

# Upgrades
const breeder_contract_cost: float = 2000.0
const breeder_contract_growth_rate: float = 1.25
const cat_trees_cost: float = 4000.0
const bot_manager_cost: float = 1000000.0
const bot_manager_unlock_bots: int = 10
const bot_manager_token_threshold: float = 1.0
