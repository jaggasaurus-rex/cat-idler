extends Node

signal cat_purchased
signal cat_attrition
signal first_bot_purchased

var money: float = 0.0
var cats: int = 0
var next_cat_cost: float = 5.0
var shop_unlocked: bool = false
var onlypaws_unlocked: bool = false
var onlypaws_active: bool = false
var paws_income_rate: float = 0.0
var manager_bots: int = 0
var next_bot_cost: float = 50.0
var bot_shop_unlocked: bool = false
var attrition_threshold: float = 5000.0
var attrition_tracker: float = 0.0
var attrition_rate_per_min: float = 0.0


func _ready() -> void:
	# Must always process so income and attrition tick even when
	# the tree is paused (e.g. during the theft warning popup).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if onlypaws_active:
		var earned: float = paws_income_rate * delta
		money += earned
		attrition_tracker += earned
		while attrition_tracker >= attrition_threshold:
			attrition_tracker -= attrition_threshold
			cats = max(0, cats - 1)
			_update_paws_rate()
			cat_attrition.emit()


func click() -> void:
	money += 1.0
	if not shop_unlocked and money >= next_cat_cost:
		shop_unlocked = true


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	money -= next_cat_cost
	cats += 1
	next_cat_cost *= 1.5
	if not onlypaws_unlocked and cats >= 3:
		onlypaws_unlocked = true
	if not bot_shop_unlocked and cats >= 6:
		bot_shop_unlocked = true
	_update_paws_rate()
	cat_purchased.emit()


## Deducts next_bot_cost, increments manager_bots, doubles the cost,
## and recalculates the paws income rate. Each bot is a full doubling
## of total output, so n bots = 2^n multiplier via pow(2, manager_bots).
## Emits first_bot_purchased on the very first bot purchase.
func buy_bot() -> void:
	if money < next_bot_cost:
		return
	money -= next_bot_cost
	manager_bots += 1
	next_bot_cost *= 2.0
	_update_paws_rate()
	if manager_bots == 1:
		first_bot_purchased.emit()


# Base tier: floor(cats / 3) $/sec (0-2 cats=$0, 3-5=$1, 6-8=$2, …).
# Each manager bot doubles the entire output: total = base * 2^manager_bots.
func _update_paws_rate() -> void:
	paws_income_rate = float(cats / 3) * pow(2.0, manager_bots)
	_update_attrition_display()


# Recalculates attrition_rate_per_min for display purposes only.
# Represents how many cats per minute are lost at the current income rate.
func _update_attrition_display() -> void:
	if attrition_threshold <= 0.0:
		attrition_rate_per_min = 0.0
	else:
		attrition_rate_per_min = (paws_income_rate * 60.0) / attrition_threshold
