extends Control

const CAT_SCENE := preload("res://scenes/CatCharacter.tscn")
const CAT_SPACING_RADIUS := 64.0
const UI_SAFE_PADDING := 16.0
const CAT_PLACEMENT_ATTEMPTS := 30


@onready var earn_money_button: Button = $EarnMoneyButton
@onready var money_label: Label = $MoneyLabel
@onready var cats_label: Label = $CatsLabel
@onready var purchase_cat_button: Button = $PurchaseCatButton
@onready var cat_container: Node2D = $CatContainer
@onready var only_paws_button: Button = $OnlyPawsButton
@onready var only_paws_income_label: Label = $OnlyPawsIncomeLabel
@onready var only_paws_popup: ColorRect = $OnlyPawsPopup
@onready var upgrades_tab_popup: ColorRect = $UpgradesTabPopup
@onready var manager_bot_button: Button = $ManagerBotButton
@onready var bots_rate_label: Label = $BotsRateLabel
@onready var shop_panel: VBoxContainer = $ShopPanel
@onready var shop_list: VBoxContainer = $ShopPanel/ShopScroll/ShopList
@onready var housing_button: Button = $ShopPanel/ShopScroll/ShopList/HousingButton
@onready var auto_feeder_button: Button = $ShopPanel/ShopScroll/ShopList/AutoFeederButton
@onready var bot_manager_shop_button: Button = $ShopPanel/ShopScroll/ShopList/BotManagerShopButton
@onready var cat_food_label: Label = $CatFoodLabel
@onready var buy_cat_food_button: Button = $BuyCatFoodButton
@onready var tokens_label: Label = $TokensLabel
@onready var buy_tokens_button: Button = $BuyTokensButton
@onready var happiness_bar_container: VBoxContainer = $HappinessBarContainer
@onready var happiness_bar: ProgressBar = $HappinessBarContainer/HappinessRow/HappinessBar
# Thin red vertical line at the 20% position on the bar; child of HappinessBar so it
# sits above the fill layer and stays anchored at 20% of the bar's width regardless of
# the current fill level. Hidden until cat_crusher_unlocked.
@onready var _cat_loss_marker: ColorRect = $HappinessBarContainer/HappinessRow/HappinessBar/CatLossMarker
@onready var first_cat_popup: ColorRect = $FirstCatPopup
@onready var bot_unlock_popup: ColorRect = $BotUnlockPopup
@onready var bot_manager_unlock_popup: ColorRect = $BotManagerUnlockPopup
@onready var starvation_popup: ColorRect = $StarvationPopup
@onready var starvation_2_popup: ColorRect = $Starvation2Popup
@onready var starvation_recurring_popup: ColorRect = $StarvationRecurringPopup
@onready var starvation_asshole_popup: ColorRect = $StarvationAssholePopup
@onready var game_over_popup: ColorRect = $GameOverPopup
@onready var game_over_2_popup: ColorRect = $GameOver2Popup
@onready var happiness_cramped_popup: ColorRect = $HappinessCrampedPopup
@onready var happiness_riot_popup: ColorRect = $HappinessRiotPopup
@onready var cat_crusher_popup: ColorRect = $CatCrusherPopup


var _only_paws_popup_shown: bool = false
var _starvation_popup_shown: bool = false
var _starvation_2_popup_shown: bool = false
# Tracks the highest starvation_count whose recurring popup sequence was started,
# so each new offense (count >= 3) fires exactly once per unique count value.
var _starvation_handled_count: int = 0
var _happiness_cramped_popup_shown: bool = false
var _happiness_riot_popup_shown: bool = false
var _cat_crusher_popup_shown: bool = false
var _happiness_fill_style: StyleBoxFlat
var _cat_food_button_auto_set: bool = false
var _tokens_button_auto_set: bool = false


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)
	GameState.cat_lost.connect(_on_cat_lost)
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
	# Static shop item costs for sort ordering; dynamic costs updated before each sort
	auto_feeder_button.set_meta("shop_cost", Config.auto_feeder_cost)
	bot_manager_shop_button.set_meta("shop_cost", Config.bot_manager_cost)
	housing_button.set_meta("shop_cost", 0.0)
	auto_feeder_button.text = "Auto-Feeder\n$" + Util.format_number(Config.auto_feeder_cost)
	bot_manager_shop_button.text = "Manager-Bot Manager\n$" + Util.format_number(Config.bot_manager_cost)


func _process(_delta: float) -> void:
	money_label.text = "Money: $" + Util.format_number(GameState.money)
	var max_cats: int = GameState.get_max_cats()
	cats_label.text = "Cats: " + Util.format_number(float(GameState.cats)) + "/" + Util.format_number(float(max_cats))
	cats_label.modulate = Color.RED if GameState.cats > max_cats else Color.WHITE
	purchase_cat_button.text = "Purchase Cat ($" + Util.format_number(GameState.next_cat_cost) + ")"
	only_paws_income_label.text = "OnlyPaws: $%.2f/sec" % GameState.paws_income_rate

	if GameState.shop_unlocked and not purchase_cat_button.visible:
		purchase_cat_button.visible = true

	if GameState.cats >= 1 and not GameState.first_cat_popup_shown:
		GameState.first_cat_popup_shown = true
		first_cat_popup.visible = true
		get_tree().paused = true

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

	if GameState.bot_shop_unlocked and not GameState.bot_unlock_popup_shown:
		GameState.bot_unlock_popup_shown = true
		bot_unlock_popup.visible = true
		get_tree().paused = true

	cat_food_label.text = "Cat Food: " + Util.format_number(GameState.cat_food)
	buy_cat_food_button.disabled = GameState.money < Config.cat_food_pack_cost
	if GameState.auto_feeder_purchased and not _cat_food_button_auto_set:
		_cat_food_button_auto_set = true
		buy_cat_food_button.text = "Buy Food ($10) ∞"

	# One-way latch — tokens label and buy button appear on first bot purchase
	if GameState.tokens_shop_unlocked and not tokens_label.visible:
		tokens_label.visible = true
		buy_tokens_button.visible = true

	tokens_label.text = "Tokens: " + Util.format_number(GameState.tokens)
	buy_tokens_button.disabled = GameState.money < Config.token_pack_cost
	if GameState.bot_manager_purchased and not _tokens_button_auto_set:
		_tokens_button_auto_set = true
		buy_tokens_button.text = "Buy Tokens ($20) ∞"

	if (GameState.bot_manager_unlocked or GameState.auto_feeder_unlocked) and not GameState.upgrades_tab_popup_shown:
		GameState.upgrades_tab_popup_shown = true
		upgrades_tab_popup.visible = true
		get_tree().paused = true

	if GameState.bot_manager_unlocked and not GameState.bot_manager_unlock_popup_shown:
		GameState.bot_manager_unlock_popup_shown = true
		bot_manager_unlock_popup.visible = true
		get_tree().paused = true

	# Bot manager shop button — visible when unlocked, disappears on purchase
	if GameState.bot_manager_unlocked and not GameState.bot_manager_purchased:
		if not bot_manager_shop_button.visible:
			bot_manager_shop_button.visible = true
			_sort_shop_list()
		bot_manager_shop_button.disabled = GameState.money < Config.bot_manager_cost
	elif bot_manager_shop_button.visible:
		bot_manager_shop_button.visible = false
		_sort_shop_list()

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

	if GameState.starvation_count >= 1 and not _starvation_popup_shown:
		_starvation_popup_shown = true
		starvation_popup.visible = true
		get_tree().paused = true

	if GameState.starvation_count >= 2 and not _starvation_2_popup_shown:
		_starvation_2_popup_shown = true
		starvation_2_popup.visible = true
		get_tree().paused = true

	if GameState.starvation_count >= 3 and GameState.starvation_count > _starvation_handled_count:
		_starvation_handled_count = GameState.starvation_count
		starvation_recurring_popup.visible = true
		get_tree().paused = true

	if GameState.happiness_cramped_triggered and not _happiness_cramped_popup_shown:
		_happiness_cramped_popup_shown = true
		happiness_cramped_popup.visible = true
		get_tree().paused = true

	if GameState.happiness_riot_triggered and not _happiness_riot_popup_shown:
		_happiness_riot_popup_shown = true
		happiness_riot_popup.visible = true
		get_tree().paused = true

	if GameState.cat_crusher_triggered and not _cat_crusher_popup_shown:
		_cat_crusher_popup_shown = true
		cat_crusher_popup.visible = true
		get_tree().paused = true

	# One-way latch — show 20% cat-loss threshold marker once Cat Crusher is unlocked
	if GameState.cat_crusher_unlocked and not _cat_loss_marker.visible:
		_cat_loss_marker.visible = true

	# Auto feeder shop button — visible when unlocked, disappears on purchase
	if GameState.auto_feeder_unlocked and not GameState.auto_feeder_purchased:
		if not auto_feeder_button.visible:
			auto_feeder_button.visible = true
			_sort_shop_list()
		auto_feeder_button.disabled = GameState.money < Config.auto_feeder_cost
	elif auto_feeder_button.visible:
		auto_feeder_button.visible = false
		_sort_shop_list()

	# Housing shop button — visible when home_shop_unlocked; updates to next tier, disappears at cap
	if GameState.home_shop_unlocked:
		var is_max_tier: bool = GameState.housing_tier_index >= Config.housing_tiers.size() - 1
		if not is_max_tier:
			if not housing_button.visible:
				housing_button.visible = true
				_sort_shop_list()
			var next_tier: Dictionary = Config.housing_tiers[GameState.housing_tier_index + 1]
			housing_button.text = next_tier["label"] + "\n$" + Util.format_number(float(next_tier["cost"]))
			housing_button.disabled = GameState.money < float(next_tier["cost"])
		elif housing_button.visible:
			housing_button.visible = false
			_sort_shop_list()


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


func _on_buy_token_x1_button_pressed() -> void:
	GameState.buy_tokens(1)


func _on_starvation_popup_ok_pressed() -> void:
	starvation_popup.visible = false
	get_tree().paused = false
	GameState.grant_cat_food_pack()


func _on_starvation_2_popup_ok_pressed() -> void:
	starvation_2_popup.visible = false
	get_tree().paused = false
	GameState.grant_cat_food_pack()
	GameState.starvation_lose_cat()
	if GameState.cats == 0 and GameState.starvation_cats_lost >= 1 and GameState.cats_ever_purchased > 0:
		game_over_popup.visible = true
		get_tree().paused = true


func _on_bot_unlock_popup_ok_pressed() -> void:
	bot_unlock_popup.visible = false
	get_tree().paused = false


func _on_starvation_recurring_ok_pressed() -> void:
	starvation_recurring_popup.visible = false
	# Tree stays paused — chain directly into the second popup
	starvation_asshole_popup.visible = true


func _on_starvation_asshole_ok_pressed() -> void:
	starvation_asshole_popup.visible = false
	get_tree().paused = false
	GameState.grant_cat_food_pack()
	GameState.starvation_lose_cat()
	if GameState.cats == 0 and GameState.starvation_cats_lost >= 1 and GameState.cats_ever_purchased > 0:
		game_over_popup.visible = true
		get_tree().paused = true


func _on_game_over_popup_ok_pressed() -> void:
	game_over_popup.visible = false
	# Tree stays paused — chain directly into the final popup
	game_over_2_popup.visible = true


func _on_game_over_2_popup_ok_pressed() -> void:
	get_tree().quit()


func _on_first_cat_popup_ok_pressed() -> void:
	first_cat_popup.visible = false
	get_tree().paused = false


func _on_only_paws_popup_ok_pressed() -> void:
	only_paws_popup.visible = false
	get_tree().paused = false


func _on_upgrades_tab_popup_ok_pressed() -> void:
	upgrades_tab_popup.visible = false
	get_tree().paused = false


func _on_bot_manager_unlock_popup_ok_pressed() -> void:
	bot_manager_unlock_popup.visible = false
	get_tree().paused = false


func _on_buy_bot_manager_button_pressed() -> void:
	GameState.buy_bot_manager()


func _on_buy_auto_feeder_button_pressed() -> void:
	GameState.buy_auto_feeder()



func _on_buy_housing_button_pressed() -> void:
	GameState.buy_housing_upgrade()


func _on_happiness_cramped_popup_ok_pressed() -> void:
	happiness_cramped_popup.visible = false
	get_tree().paused = false
	GameState.home_shop_unlocked = true


func _on_happiness_riot_popup_ok_pressed() -> void:
	happiness_riot_popup.visible = false
	get_tree().paused = false


func _on_cat_crusher_popup_ok_pressed() -> void:
	cat_crusher_popup.visible = false
	get_tree().paused = false
	GameState.cat_crusher_unlocked = true


# Sorts visible shop list items ascending by shop_cost meta; invisible items sink to the bottom.
func _sort_shop_list() -> void:
	if not (GameState.housing_tier_index >= Config.housing_tiers.size() - 1):
		var next_tier: Dictionary = Config.housing_tiers[GameState.housing_tier_index + 1]
		housing_button.set_meta("shop_cost", float(next_tier["cost"]))
	var items: Array[Node] = shop_list.get_children()
	items.sort_custom(func(a: Node, b: Node) -> bool:
		if not a.visible:
			return false
		if not b.visible:
			return true
		return float(a.get_meta("shop_cost", 0.0)) < float(b.get_meta("shop_cost", 0.0))
	)
	for i: int in items.size():
		shop_list.move_child(items[i], i)


func _on_cat_purchased() -> void:
	var cat: Node2D = CAT_SCENE.instantiate()
	cat.scale = Vector2(0.4, 0.4)
	cat_container.add_child(cat)
	_place_cat(cat)


func _on_cat_lost() -> void:
	var children: Array[Node] = cat_container.get_children()
	if children.size() > 0:
		children.back().queue_free()


# Places cat at a random viewport position that avoids UI elements and existing cats.
# Falls back to ignoring cat spacing, then to anywhere in the viewport.
func _place_cat(cat: Node2D) -> void:
	var vp_rect: Rect2 = get_viewport_rect()
	var ui_nodes: Array[Control] = [
		shop_panel, happiness_bar_container, money_label, cats_label,
		cat_food_label, buy_cat_food_button, earn_money_button, purchase_cat_button,
		only_paws_button, manager_bot_button, bots_rate_label, tokens_label, buy_tokens_button,
	]
	var ui_rects: Array[Rect2] = []
	for node: Control in ui_nodes:
		ui_rects.append(node.get_global_rect().grow(UI_SAFE_PADDING))

	var existing_positions: Array[Vector2] = []
	for child: Node in cat_container.get_children():
		if child != cat:
			existing_positions.append(cat_container.to_global((child as Node2D).position))

	var chosen_pos: Vector2 = Vector2.ZERO
	var found: bool = false

	for _i: int in CAT_PLACEMENT_ATTEMPTS:
		var candidate := Vector2(
			randf_range(vp_rect.position.x, vp_rect.end.x),
			randf_range(vp_rect.position.y, vp_rect.end.y)
		)
		if _overlaps_ui(candidate, ui_rects) or _too_close_to_cats(candidate, existing_positions):
			continue
		chosen_pos = candidate
		found = true
		break

	if not found:
		for _i: int in CAT_PLACEMENT_ATTEMPTS:
			var candidate := Vector2(
				randf_range(vp_rect.position.x, vp_rect.end.x),
				randf_range(vp_rect.position.y, vp_rect.end.y)
			)
			if _overlaps_ui(candidate, ui_rects):
				continue
			chosen_pos = candidate
			found = true
			break

	if not found:
		chosen_pos = Vector2(
			randf_range(vp_rect.position.x, vp_rect.end.x),
			randf_range(vp_rect.position.y, vp_rect.end.y)
		)

	cat.position = cat_container.to_local(chosen_pos)


func _overlaps_ui(pos: Vector2, ui_rects: Array[Rect2]) -> bool:
	for rect: Rect2 in ui_rects:
		if rect.has_point(pos):
			return true
	return false


func _too_close_to_cats(pos: Vector2, existing_positions: Array[Vector2]) -> bool:
	for existing: Vector2 in existing_positions:
		if pos.distance_to(existing) < CAT_SPACING_RADIUS:
			return true
	return false
