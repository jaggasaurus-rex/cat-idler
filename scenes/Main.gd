extends Control

const CAT_SCENE := preload("res://scenes/CatCharacter.tscn")

@onready var money_label: Label = $MoneyLabel
@onready var cats_label: Label = $CatsLabel
@onready var purchase_cat_button: Button = $PurchaseCatButton
@onready var cat_container: Node2D = $CatContainer
@onready var onlypaws_button: Button = $OnlypawsButton
@onready var onlypaws_income_label: Label = $OnlypawsIncomeLabel
@onready var manager_bot_button: Button = $ManagerBotButton
@onready var bots_rate_label: Label = $BotsRateLabel
@onready var attrition_label: Label = $AttritionLabel
@onready var theft_warning_layer: CanvasLayer = $TheftWarningLayer
@onready var close_button: Button = $TheftWarningLayer/TheftWarningPanel/VBoxContainer/CloseRow/CloseButton


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)
	GameState.cat_attrition.connect(_on_cat_attrition)
	GameState.first_bot_purchased.connect(_on_first_bot_purchased)


func _process(_delta: float) -> void:
	money_label.text = "Money: $%.2f" % GameState.money
	cats_label.text = "Cats: %d" % GameState.cats
	purchase_cat_button.text = "Purchase Cat ($%.2f)" % GameState.next_cat_cost
	onlypaws_income_label.text = "Onlypaws: $%.2f/sec" % GameState.paws_income_rate

	if GameState.shop_unlocked and not purchase_cat_button.visible:
		purchase_cat_button.visible = true

	# One-way latch — Onlypaws button and income label appear together
	if GameState.onlypaws_unlocked and not onlypaws_button.visible:
		onlypaws_button.visible = true
		onlypaws_income_label.visible = true

	# One-way latch — attrition label appears only once attrition is active (2+ bots)
	if GameState.manager_bots >= 2 and not attrition_label.visible:
		attrition_label.visible = true

	# One-way latch — bot button and status label appear together
	if GameState.bot_shop_unlocked and not manager_bot_button.visible:
		manager_bot_button.visible = true
		bots_rate_label.visible = true

	# Onlypaws toggle state — green tint when active, default when inactive
	if GameState.onlypaws_active:
		onlypaws_button.text = "Onlypaws: ON"
		onlypaws_button.modulate = Color(0.4, 1.0, 0.4)
	else:
		onlypaws_button.text = "Onlypaws: OFF"
		onlypaws_button.modulate = Color(1.0, 1.0, 1.0)

	manager_bot_button.text = "Onlypaws Manager-Bot ($%.2f)" % GameState.next_bot_cost
	manager_bot_button.disabled = GameState.money < GameState.next_bot_cost
	bots_rate_label.text = "Bots: %d | Rate: $%.2f/sec" % [GameState.manager_bots, GameState.paws_income_rate]
	attrition_label.text = "Cat Attrition: %d cats/min" % (GameState.manager_bots - 1)


func _on_earn_money_button_pressed() -> void:
	GameState.click()


func _on_purchase_cat_button_pressed() -> void:
	GameState.buy_cat()


# Toggles Onlypaws passive income on/off.
func _on_onlypaws_button_pressed() -> void:
	GameState.onlypaws_active = not GameState.onlypaws_active


func _on_manager_bot_button_pressed() -> void:
	GameState.buy_bot()


func _on_cat_purchased() -> void:
	var cat := CAT_SCENE.instantiate()
	cat.scale = Vector2(0.4, 0.4)
	cat_container.add_child(cat)
	_reposition_cats()


# Removes the last visual cat when attrition fires in GameState.
func _on_cat_attrition() -> void:
	var children := cat_container.get_children()
	if children.size() > 0:
		children.back().queue_free()
		_reposition_cats()


# Shows the theft warning popup and pauses the scene tree.
# GameState continues ticking because its process_mode is ALWAYS.
func _on_first_bot_purchased() -> void:
	theft_warning_layer.visible = true
	get_tree().paused = true


func _on_theft_warning_close_pressed() -> void:
	theft_warning_layer.visible = false
	get_tree().paused = false


# Keeps all purchased cats evenly spaced and centered around the
# container's origin so the row self-centres as it grows.
func _reposition_cats() -> void:
	var children := cat_container.get_children()
	var count := children.size()
	var spacing := 72.0
	var start_x := -(count - 1) * spacing / 2.0
	for i in count:
		children[i].position = Vector2(start_x + i * spacing, 0.0)
