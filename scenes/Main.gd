extends Control

const CAT_SCENE := preload("res://scenes/CatCharacter.tscn")

@onready var money_label: Label = $MoneyLabel
@onready var cats_label: Label = $CatsLabel
@onready var purchase_cat_button: Button = $PurchaseCatButton
@onready var cat_container: Node2D = $CatContainer
@onready var only_paws_button: Button = $OnlyPawsButton
@onready var only_paws_income_label: Label = $OnlyPawsIncomeLabel
@onready var only_paws_popup: ColorRect = $OnlyPawsPopup
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
@onready var bot_manager_desc_label: Label = $ShopPanel/BotManagerItem/BotManagerDescLabel
@onready var buy_bot_manager_button: Button = $ShopPanel/BotManagerItem/BuyBotManagerButton
@onready var auto_feeder_item: VBoxContainer = $ShopPanel/AutoFeederItem
@onready var auto_feeder_desc_label: Label = $ShopPanel/AutoFeederItem/AutoFeederDescLabel
@onready var buy_auto_feeder_button: Button = $ShopPanel/AutoFeederItem/BuyAutoFeederButton
@onready var happiness_bar: ProgressBar = $HappinessBarContainer/HappinessRow/HappinessBar
@onready var happiness_cramped_popup: ColorRect = $HappinessCrampedPopup
@onready var happiness_riot_popup: ColorRect = $HappinessRiotPopup


var _only_paws_popup_shown: bool = false
var _happiness_cramped_popup_shown: bool = false
var _happiness_riot_popup_shown: bool = false
var _happiness_fill_style: StyleBoxFlat


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)
	# Hero stat: bold + 30% larger than the base metric font size
	var base_size: int = money_label.get_theme_font_size("font_size")
	cats_label.add_theme_font_size_override("font_size", roundi(float(base_size) * 1.3))
	var bold_font := SystemFont.new()
	bold_font.font_weight = 700
	cats_label.add_theme_font_override("font", bold_font)
	# Dynamic fill colour for the happiness bar; updated in _process()
	_happiness_fill_style = StyleBoxFlat.new()
	_happiness_fill_style.bg_color = Color.GREEN
	happiness_bar.add_theme_stylebox_override("fill", _happiness_fill_style)


func _process(_delta: float) -> void:
	money_label.text = "Money: $" + Util.format_number(GameState.money)
	cats_label.text = "Cats: " + Util.format_number(GameState.cats)
	purchase_cat_button.text = "Purchase Cat ($" + Util.format_number(GameState.next_cat_cost) + ")"
	only_paws_income_label.text = "OnlyPaws: $%.2f/sec" % GameState.paws_income_rate

	if GameState.shop_unlocked and not purchase_cat_button.visible:
		purchase_cat_button.visible = true

	# One-way latch — OnlyPaws button and income label appear together
	if GameState.only_paws_unlocked and not only_paws_button.visible:
		only_paws_button.visible = true
		only_paws_income_label.visible = true

	if GameState.only_paws_unlocked and not _only_paws_popup_shown:
		_only_paws_popup_shown = true
		only_paws_popup.visible = true
		get_tree().paused = true

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
		bot_manager_desc_label.visible = false
	else:
		buy_bot_manager_button.disabled = GameState.money < Config.bot_manager_cost
		buy_bot_manager_button.modulate = Color(1.0, 1.0, 1.0)

	# OnlyPaws toggle state — green tint when active, default when inactive
	if GameState.only_paws_active:
		only_paws_button.text = "OnlyPaws: ON"
		only_paws_button.modulate = Color(0.4, 1.0, 0.4)
	else:
		only_paws_button.text = "OnlyPaws: OFF"
		only_paws_button.modulate = Color(1.0, 1.0, 1.0)

	manager_bot_button.text = "OnlyPaws Manager-Bot ($" + Util.format_number(GameState.next_bot_cost) + ")"
	manager_bot_button.disabled = GameState.money < GameState.next_bot_cost
	bots_rate_label.text = "Bots: " + Util.format_number(GameState.manager_bots)

	# Happiness bar: colour transitions smoothly from red (0%) to green (100%)
	var happiness: float = GameState.get_happiness()
	happiness_bar.value = happiness
	var t: float = happiness / 100.0
	_happiness_fill_style.bg_color = Color.RED.lerp(Color.GREEN, t)

	if GameState.happiness_cramped_triggered and not _happiness_cramped_popup_shown:
		_happiness_cramped_popup_shown = true
		happiness_cramped_popup.visible = true
		get_tree().paused = true

	if GameState.happiness_riot_triggered and not _happiness_riot_popup_shown:
		_happiness_riot_popup_shown = true
		happiness_riot_popup.visible = true
		get_tree().paused = true

	# One-way latch — auto feeder shop item appears when unlocked
	if GameState.auto_feeder_unlocked and not auto_feeder_item.visible:
		auto_feeder_item.visible = true

	if GameState.auto_feeder_purchased:
		buy_auto_feeder_button.disabled = true
		buy_auto_feeder_button.modulate = Color(0.4, 1.0, 0.4)
		auto_feeder_desc_label.visible = false
	else:
		buy_auto_feeder_button.disabled = GameState.money < Config.auto_feeder_cost
		buy_auto_feeder_button.modulate = Color(1.0, 1.0, 1.0)


func _on_earn_money_button_pressed() -> void:
	GameState.click()


func _on_purchase_cat_button_pressed() -> void:
	GameState.buy_cat()


# Toggles OnlyPaws passive income on/off. Turning off also deactivates bots.
func _on_only_paws_button_pressed() -> void:
	GameState.only_paws_active = not GameState.only_paws_active
	if not GameState.only_paws_active:
		GameState.bots_active = false
	elif GameState.tokens > 0.0:
		GameState.bots_active = true


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


func _on_only_paws_popup_ok_pressed() -> void:
	only_paws_popup.visible = false
	get_tree().paused = false


func _on_buy_bot_manager_button_pressed() -> void:
	GameState.buy_bot_manager()


func _on_buy_auto_feeder_button_pressed() -> void:
	GameState.buy_auto_feeder()


func _on_happiness_cramped_popup_ok_pressed() -> void:
	happiness_cramped_popup.visible = false
	get_tree().paused = false
	GameState.home_shop_unlocked = true


func _on_happiness_riot_popup_ok_pressed() -> void:
	happiness_riot_popup.visible = false
	get_tree().paused = false


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
