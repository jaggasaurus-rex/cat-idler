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
const cat_cost_growth_rate: float = 1.3
const only_paws_unlock_cats: int = 3
const only_paws_cats_per_tier: int = 3  # floor(cats / N) = base OnlyPaws income tier
const onlypaws_income_per_cat: float = 0.25  # base $/sec per cat; at unlock (3 cats): 3 * 0.25 = $0.75/sec
const onlypaws_income_per_bot: float = 0.50  # additional $/sec per cat per bot
const bot_shop_unlock_cats: int = 6

# Bots
const bot_cost_base: float = 50.0
const bot_cost_multiplier: float = 1.6

# Mega Manager-Bots — unlocked by the "ai_model_upgrade" research item.
# Double the cost, quadruple the per-cat income, and double the token drain of normal bots.
const MEGA_BOT_COST_BASE: float = 100.0       # double the normal bot_cost_base of 50.0
const MEGA_BOT_INCOME_PER_CAT: float = 2.0    # $2.00/cat/sec per mega bot
const MEGA_BOT_TOKEN_DRAIN: float = 4.0       # double the normal token_drain_per_bot of 2.0

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
# Income multiplier: 0.90 at 0% happiness, rising linearly to 1.00 at 100% happiness.
const happiness_income_floor: float = 0.90
const happiness_income_range: float = 0.10

# Cat count at which the "your cats are cramped" popup fires and the Home tab unlocks.
const HOUSING_UPGRADE_PROMPT_THRESHOLD: int = 8

# Housing upgrade chain — ordered from cheapest to most expensive.
# cost[n]: 0, 500, 3500, 11500, 46000
# max_cats_increase is summed for tiers 1..housing_tier_index and added to base_max_cats.
# Each entry: {id: String, label: String, cost: float, max_cats_increase: int}
const housing_tiers: Array = [
	{"id": "studio_basic",    "label": Strings.HOUSING_LABEL_STUDIO_BASIC,    "cost": 0.0,     "max_cats_increase": 0},
	{"id": "studio_upgraded", "label": Strings.HOUSING_LABEL_STUDIO_UPGRADED, "cost": 500.0,   "max_cats_increase": 10},
	{"id": "bedroom_1",       "label": Strings.HOUSING_LABEL_BEDROOM_1,       "cost": 3500.0,  "max_cats_increase": 10},
	{"id": "bedroom_2",       "label": Strings.HOUSING_LABEL_BEDROOM_2,       "cost": 11500.0, "max_cats_increase": 10},
	{"id": "bedroom_3",       "label": Strings.HOUSING_LABEL_BEDROOM_3,       "cost": 46000.0, "max_cats_increase": 10},
]

# Robo-Shit Sweeper — research-gated upgrade that automates poop cleanup.
const ROBO_SWEEPER_FUND_COST: float = 4000.0
# 2× ai_model_upgrade (1200 pts) = 2400 pts
const ROBO_SWEEPER_POINTS_COST: float = 2400.0
# Base cost of the first sweeper ($10,000). Each additional sweeper costs 3× the previous:
# sweeper 1 = $10,000; sweeper 2 = $30,000; sweeper 3 = $90,000; etc.
const ROBO_SWEEPER_PURCHASE_COST: float = 10000.0
const ROBO_SWEEPER_COST_MULTIPLIER: float = 3.0

# Cyborg Cats — convert a normal cat into a biologically enhanced cat that earns a
# multiplier on the full per-cat income rate and never poops. The multiplier is the
# long-term scaling lever and upgrades in tiers.
const CYBORG_COST_BASE: float = 250.0        # money cost of the first conversion
const CYBORG_COST_GROWTH: float = 1.4         # multiplier applied to cost per conversion
const CYBORG_MULTIPLIERS: Array = [2.0, 4.0, 8.0]   # M by cyborg_multiplier_tier index
const CYBORG_MULTIPLIER_UPGRADE_COSTS: Array = [5000.0, 25000.0]  # cost to go tier 0->1, 1->2

# Research items — each entry defines a fundable, cat-powered research project.
const RESEARCH_ITEMS: Array = [
	{
		"id": "cat_power_unite",
		"name": Strings.RESEARCH_CAT_POWER_NAME,
		"subtitle": Strings.RESEARCH_CAT_POWER_SUB,
		"description": Strings.RESEARCH_CAT_POWER_DESC,
		"fund_cost": 1000.0,
		"points_cost": 200.0,
		"min_cats_required": 10,
		"cat_intelligence_gain": 1,
		"min_housing_tier": 0,
	},
	{
		"id": "ai_model_upgrade",
		"name": Strings.RESEARCH_AI_MODEL_NAME,
		"subtitle": Strings.RESEARCH_AI_MODEL_SUB,
		"description": Strings.RESEARCH_AI_MODEL_DESC,
		"fund_cost": 2000.0,
		# 1 cat × 60 sec/min × 20 min = 1200 research points; more cats reduce time linearly.
		"points_cost": 1200.0,
		"min_cats_required": 1,
		"cat_intelligence_gain": 0,
		"min_housing_tier": 1,
	},
	{
		"id": "robo_shit_sweeper",
		"name": Strings.RESEARCH_ROBO_SWEEPER_NAME,
		"subtitle": Strings.RESEARCH_ROBO_SWEEPER_SUB,
		"description": Strings.RESEARCH_ROBO_SWEEPER_DESC,
		"fund_cost": ROBO_SWEEPER_FUND_COST,
		"points_cost": ROBO_SWEEPER_POINTS_COST,
		"min_cats_required": 1,
		"cat_intelligence_gain": 0,
		"min_housing_tier": 0,
		# Unlocked in the research tree when EITHER cats >= 25 OR ai_model_upgrade is complete.
		"unlock_requires_cats": 25,
		"unlock_requires_research": "ai_model_upgrade",
	},
	{
		"id": "cyborg_cats",
		"name": Strings.RESEARCH_CYBORG_NAME,
		"subtitle": Strings.RESEARCH_CYBORG_SUB,
		"description": Strings.RESEARCH_CYBORG_DESC,
		"fund_cost": 3000.0,
		"points_cost": 1800.0,
		"min_cats_required": 1,
		"cat_intelligence_gain": 0,
		"min_housing_tier": 2,
		# Panel appears once cats >= 20 (OR gate, additive to the predecessor-complete gate).
		"unlock_requires_cats": 20,
	},
]

# Passive cat_intelligence accrued while cats are assigned to research but no
# research item is actively in progress (get_active_research_id() == "").
# 10 cats × 600s = 10 cat_intelligence per 10 minutes
# 1 point per cat per 10 minutes = 1/600 ≈ 0.00167 points/cat/sec
const IDLE_RESEARCH_INTEL_RATE: float = 0.00167

# Bubble mechanic
const BUBBLE_SPAWN_MIN: float = 5.0           # min seconds of a per-cat bubble cooldown
const BUBBLE_SPAWN_MAX: float = 15.0          # max seconds of a per-cat bubble cooldown
const BUBBLE_LIFETIME: float = 4.5            # seconds before a bubble fades out
const BUBBLE_MAX_ON_SCREEN: int = 4           # cap on simultaneous bubbles
const BUBBLE_VIRAL_MULTIPLIER: float = 4.0    # viral reward = paws_income_rate × this
const BUBBLE_INSPIRATION_SECONDS: float = 3.0 # inspiration reward = research_cats × this many seconds of points
const BUBBLE_GLOBAL_CD_MIN: float = 20.0      # min seconds between burst windows
const BUBBLE_GLOBAL_CD_MAX: float = 40.0      # max seconds between burst windows
const BUBBLE_BURST_WINDOW_MIN: float = 2.0    # min seconds a burst window stays open
const BUBBLE_BURST_WINDOW_MAX: float = 10.0   # max seconds a burst window stays open

## Poop
# Per-cat cooldown range: each cat independently picks a random interval
# in [POOP_SPAWN_MIN, POOP_SPAWN_MAX] between poops.
const POOP_SPAWN_MIN: float = 30.0
const POOP_SPAWN_MAX: float = 90.0
# Poop-per-cat ratio at which happiness reaches 0%.
# At ratio 1.0: happiness ≈ 89% (moderate annoyance).
# At ratio 2.0: happiness ≈ 56% (becoming a real problem).
# At ratio 3.0: happiness = 0% (fully ignored).
const POOP_MAX_RATIO: float = 3.0

# Robo-Shit Sweeper — autonomous device that removes poop once robo_sweeper_purchased.
const SWEEPER_MOVE_SPEED: float = 80.0
# pixels per second; slow and deliberate so it feels like a helper, not a solution

const SWEEPER_CLEAN_DELAY: float = 1.5
# seconds the sweeper lingers at a poop before removing it

# Cat wandering
const CAT_MOVE_SPEED: float = 40.0     # pixels per second while walking
const CAT_WANDER_MIN: float = 25.0     # minimum seconds between movement decisions
const CAT_WANDER_MAX: float = 60.0     # maximum seconds between movement decisions

## UI
const RESEARCH_MAX_VISIBLE: int = 4
const UI_BASE_FONT_SIZE: int = 22
# Section header labels — slightly larger than base, bold weight
const UI_HEADER_FONT_SIZE: int = 28
