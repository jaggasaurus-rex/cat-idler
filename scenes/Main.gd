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
@onready var shop_panel: VBoxContainer = $ShopPanel
@onready var cat_food_label: Label = $CatFoodLabel
@onready var buy_cat_food_x1_button: Button = $ShopPanel/CatFoodItem/BuyCatFoodX1Button
@onready var buy_cat_food_x10_button: Button = $ShopPanel/CatFoodItem/BuyCatFoodX10Button
@onready var tokens_label: Label = $TokensLabel
@onready var token_pack_item: VBoxContainer = $ShopPanel/TokenPackItem
@onready var buy_token_x1_button: Button = $ShopPanel/TokenPackItem/BuyTokenX1Button
@onready var buy_token_x10_button: Button = $ShopPanel/TokenPackItem/BuyTokenX10Button
@onready var bot_manager_item: VBoxContainer = $ShopPanel/BotManagerItem
@onready var buy_bot_manager_button: Button = $ShopPanel/BotManagerItem/BuyBotManagerButton


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)


func _process(_delta: float) -> void:
	money_label.text = "Money: $" + Util.format_number(GameState.money)
	cats_label.text = "Cats: " + Util.format_number(GameState.cats)
	purchase_cat_button.text = "Purchase Cat ($" + Util.format_number(GameState.next_cat_cost) + ")"
	onlypaws_income_label.text = "Onlypaws: $%.2f/sec" % GameState.paws_income_rate

	if GameState.shop_unlocked and not purchase_cat_button.visible:
		purchase_cat_button.visible = true

	# One-way latch — Onlypaws button and income label appear together
	if GameState.onlypaws_unlocked and not onlypaws_button.visible:
		onlypaws_button.visible = true
		onlypaws_income_label.visible = true

	# One-way latch — bot button and status label appear together
	if GameState.bot_shop_unlocked and not manager_bot_button.visible:
		manager_bot_button.visible = true
		bots_rate_label.visible = true

	cat_food_label.text = "Cat Food: " + Util.format_number(GameState.cat_food)
	buy_cat_food_x1_button.disabled = GameState.money < Config.cat_food_pack_cost
	buy_cat_food_x10_button.disabled = GameState.money < Config.cat_food_pack_cost

	# One-way latch — tokens label and token shop item appear on first bot purchase
	if GameState.tokens_shop_unlocked and not tokens_label.visible:
		tokens_label.visible = true
		token_pack_item.visible = true

	tokens_label.text = "Tokens: " + Util.format_number(GameState.tokens)
	buy_token_x1_button.disabled = GameState.money < Config.token_pack_cost
	buy_token_x10_button.disabled = GameState.money < Config.token_pack_cost

	# One-way latch — bot manager shop item appears when unlocked
	if GameState.bot_manager_unlocked and not bot_manager_item.visible:
		bot_manager_item.visible = true

	if GameState.bot_manager_purchased:
		buy_bot_manager_button.disabled = true
		buy_bot_manager_button.modulate = Color(0.4, 1.0, 0.4)
	else:
		buy_bot_manager_button.disabled = GameState.money < Config.bot_manager_cost
		buy_bot_manager_button.modulate = Color(1.0, 1.0, 1.0)

	# Onlypaws toggle state — green tint when active, default when inactive
	if GameState.onlypaws_active:
		onlypaws_button.text = "Onlypaws: ON"
		onlypaws_button.modulate = Color(0.4, 1.0, 0.4)
	else:
		onlypaws_button.text = "Onlypaws: OFF"
		onlypaws_button.modulate = Color(1.0, 1.0, 1.0)

	manager_bot_button.text = "Onlypaws Manager-Bot ($" + Util.format_number(GameState.next_bot_cost) + ")"
	manager_bot_button.disabled = GameState.money < GameState.next_bot_cost
	bots_rate_label.text = "Bots: " + Util.format_number(GameState.manager_bots)


func _on_earn_money_button_pressed() -> void:
	GameState.click()


func _on_purchase_cat_button_pressed() -> void:
	GameState.buy_cat()


# Toggles Onlypaws passive income on/off.
func _on_onlypaws_button_pressed() -> void:
	GameState.onlypaws_active = not GameState.onlypaws_active


func _on_manager_bot_button_pressed() -> void:
	GameState.buy_bot()


func _on_buy_cat_food_x1_button_pressed() -> void:
	GameState.buy_cat_food_pack(1)


func _on_buy_cat_food_x10_button_pressed() -> void:
	GameState.buy_cat_food_pack(10)


func _on_buy_token_x1_button_pressed() -> void:
	GameState.buy_tokens(1)


func _on_buy_token_x10_button_pressed() -> void:
	GameState.buy_tokens(10)


func _on_buy_bot_manager_button_pressed() -> void:
	GameState.buy_bot_manager()


func _on_cat_purchased() -> void:
	var cat := CAT_SCENE.instantiate()
	cat.scale = Vector2(0.4, 0.4)
	cat_container.add_child(cat)
	_reposition_cats()


# Keeps all purchased cats evenly spaced and centered around the
# container's origin so the row self-centres as it grows.
func _reposition_cats() -> void:
	var children := cat_container.get_children()
	var count := children.size()
	var spacing := 72.0
	var start_x := -(count - 1) * spacing / 2.0
	for i in count:
		children[i].position = Vector2(start_x + i * spacing, 0.0)
