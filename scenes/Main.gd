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
@onready var mega_manager_bot_button: Button = $MegaManagerBotButton
@onready var bots_rate_label: Label = $BotTokenRow/BotsRateLabel
@onready var mega_bots_rate_label: Label = $BotTokenRow/MegaBotsRateLabel
@onready var shop_panel: VBoxContainer = $ShopPanel
@onready var shop_list: VBoxContainer = $ShopPanel/ShopScroll/ShopList
@onready var housing_button: Button = $ShopPanel/ShopScroll/ShopList/HousingButton
@onready var auto_feeder_button: Button = $ShopPanel/ShopScroll/ShopList/AutoFeederButton
@onready var bot_manager_shop_button: Button = $ShopPanel/ShopScroll/ShopList/BotManagerShopButton
@onready var cat_food_label: Label = $CatFoodLabel
@onready var buy_cat_food_button: Button = $BuyCatFoodButton
@onready var tokens_label: Label = $BotTokenRow/TokensLabel
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
@onready var center_column: VBoxContainer = $CenterColumn
@onready var research_active_label: Label = $CenterColumn/ResearchActiveLabel
@onready var research_progress_bar: ProgressBar = $CenterColumn/ResearchProgressBar
@onready var research_slider: HSlider = $CenterColumn/ResearchSlider
@onready var research_cats_label: Label = $CenterColumn/ResearchCatsLabel
@onready var research_item_list: VBoxContainer = $CenterColumn/ResearchItemList


var _pawsco_membership_button: Button
var _ai_enterprise_membership_button: Button
var _cat_intelligence_label: Label
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
var _center_column_shown: bool = false
var _research_slider_shown: bool = false
var _cat_intelligence_shown: bool = false
var _research_panels: Dictionary = {}
var _research_fund_buttons: Dictionary = {}
var _research_progress_labels: Dictionary = {}
var _research_panel_hidden: Dictionary = {}
# id -> bool; one-way latch for housing-gated research panels (min_housing_tier > 0).
# false until GameState.housing_tier_index reaches the item's min_housing_tier; never re-hides.
var _research_panel_unlocked: Dictionary = {}
# Each cat tracks its own randomized cooldown. Keys = instance_id, values = seconds remaining.
# Timers reset to a new random value in [BUBBLE_SPAWN_MIN, BUBBLE_SPAWN_MAX] after each attempt.
var _cat_bubble_timers: Dictionary = {}
# Active bubble dicts: { "node": Button, "timer": float, "type": String, "research_id": String }
var _active_bubbles: Array = []
# Global burst window system: per-cat timers run continuously but only fire during
# an open window. Windows are separated by a randomized global cooldown. Triggers
# that land outside a window are discarded — never queued or cached.
var _burst_window_active: bool = false
var _burst_window_timer: float = 0.0
var _global_cd_timer: float = randf_range(Config.BUBBLE_GLOBAL_CD_MIN, Config.BUBBLE_GLOBAL_CD_MAX)


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)
	GameState.cat_lost.connect(_on_cat_lost)
	GameState.research_completed.connect(_on_research_completed)
	for item: Dictionary in Config.RESEARCH_ITEMS:
		var item_id: String = item["id"]
		var panel: PanelContainer = PanelContainer.new()
		research_item_list.add_child(panel)
		_research_panels[item_id] = panel
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)
		var name_label: Label = Label.new()
		name_label.text = item["name"] + " — " + item["subtitle"]
		vbox.add_child(name_label)
		var desc_label: Label = Label.new()
		desc_label.text = item["description"]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)
		var fund_btn: Button = Button.new()
		fund_btn.text = "Fund Research ($" + Util.format_number(float(item["fund_cost"])) + ")"
		fund_btn.pressed.connect(_on_fund_button_pressed.bind(item_id))
		vbox.add_child(fund_btn)
		_research_fund_buttons[item_id] = fund_btn
		var progress_label: Label = Label.new()
		progress_label.visible = false
		vbox.add_child(progress_label)
		_research_progress_labels[item_id] = progress_label
		_research_panel_hidden[item_id] = false
		_research_panel_unlocked[item_id] = false
		# Housing-gated panels start hidden until the housing tier requirement is met.
		if int(item.get("min_housing_tier", 0)) > 0:
			panel.visible = false
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
	_pawsco_membership_button = Button.new()
	_pawsco_membership_button.text = "PawsCo Membership\nStart buying food in bulk\n$" + Util.format_number(Config.pawsco_membership_cost)
	_pawsco_membership_button.visible = false
	_pawsco_membership_button.set_meta("shop_cost", Config.pawsco_membership_cost)
	_pawsco_membership_button.pressed.connect(_on_buy_pawsco_membership_button_pressed)
	shop_list.add_child(_pawsco_membership_button)
	_ai_enterprise_membership_button = Button.new()
	_ai_enterprise_membership_button.text = "AI Enterprise Membership\nReduce token price\n$" + Util.format_number(Config.ai_enterprise_membership_cost)
	_ai_enterprise_membership_button.visible = false
	_ai_enterprise_membership_button.set_meta("shop_cost", Config.ai_enterprise_membership_cost)
	_ai_enterprise_membership_button.pressed.connect(_on_buy_ai_enterprise_membership_button_pressed)
	shop_list.add_child(_ai_enterprise_membership_button)
	research_slider.visible = false
	_cat_intelligence_label = Label.new()
	_cat_intelligence_label.visible = false
	center_column.add_child(_cat_intelligence_label)
	center_column.move_child(_cat_intelligence_label, 1)


func _process(delta: float) -> void:
	money_label.text = "Money: $" + Util.format_number(GameState.money)
	var max_cats: int = GameState.get_max_cats()
	cats_label.text = "Cats: " + Util.format_number(float(GameState.cats)) + "/" + Util.format_number(float(max_cats))
	cats_label.modulate = Color.RED if GameState.cats > max_cats else Color.WHITE
	purchase_cat_button.text = "Purchase Cat ($" + Util.format_number(GameState.next_cat_cost) + ")"
	purchase_cat_button.disabled = GameState.get_happiness() <= 0.0
	var display_rate: float = GameState.paws_income_rate if GameState.bots_active \
		else float(GameState.get_onlypaws_cats()) * Config.onlypaws_income_per_cat
	only_paws_income_label.text = "OnlyPaws: $%.2f/sec" % display_rate

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

	# One-way latch — cat food controls appear after the first cat purchase
	if GameState.cats_ever_purchased >= 1 and not cat_food_label.visible:
		cat_food_label.visible = true
		buy_cat_food_button.visible = true
	cat_food_label.text = "Cat Food: " + Util.format_number(GameState.cat_food)
	# GameState buy methods guard against insufficient funds; buttons stay enabled
	if GameState.auto_feeder_purchased:
		buy_cat_food_button.text = "Buy Food ($" + Util.format_number(GameState.get_cat_food_pack_cost()) + ") ∞" # reads GameState.get_cat_food_pack_cost()

	# One-way latch — tokens label and buy button appear on first bot purchase
	if GameState.tokens_shop_unlocked and not tokens_label.visible:
		tokens_label.visible = true
		buy_tokens_button.visible = true

	tokens_label.text = "Tokens: " + Util.format_number(GameState.tokens)
	if GameState.bot_manager_purchased:
		buy_tokens_button.text = "Buy Tokens ($" + Util.format_number(GameState.get_token_pack_cost()) + ") ∞" # reads GameState.get_token_pack_cost()

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
	elif bot_manager_shop_button.visible:
		bot_manager_shop_button.visible = false
		_sort_shop_list()

	# PawsCo membership button — visible when bot_manager_unlocked, disappears on purchase
	if GameState.bot_manager_unlocked and not GameState.pawsco_membership_purchased:
		if not _pawsco_membership_button.visible:
			_pawsco_membership_button.visible = true
			_sort_shop_list()
	elif _pawsco_membership_button.visible:
		_pawsco_membership_button.visible = false
		_sort_shop_list()

	# AI Enterprise membership button — visible when bot_manager_unlocked, disappears on purchase
	if GameState.bot_manager_unlocked and not GameState.ai_enterprise_purchased:
		if not _ai_enterprise_membership_button.visible:
			_ai_enterprise_membership_button.visible = true
			_sort_shop_list()
	elif _ai_enterprise_membership_button.visible:
		_ai_enterprise_membership_button.visible = false
		_sort_shop_list()

	# OnlyPaws toggle state — green tint when active, default when inactive
	if GameState.only_paws_active:
		only_paws_button.text = "OnlyPaws: ON"
		only_paws_button.modulate = Color(0.4, 1.0, 0.4)
	else:
		only_paws_button.text = "OnlyPaws: OFF"
		only_paws_button.modulate = Color(1.0, 1.0, 1.0)

	manager_bot_button.text = "OnlyPaws Manager-Bot ($" + Util.format_number(GameState.next_bot_cost) + ")"
	bots_rate_label.text = "Bots: " + Util.format_number(GameState.manager_bots)

	# One-way latch — Mega Manager-Bot button appears once the ai_model_upgrade research completes
	if GameState.research_complete.get("ai_model_upgrade", false) and not mega_manager_bot_button.visible:
		mega_manager_bot_button.visible = true
	if mega_manager_bot_button.visible:
		mega_manager_bot_button.text = "Mega-Bot ($" + Util.format_number(GameState.next_mega_bot_cost) + ")"
		mega_manager_bot_button.disabled = GameState.money < GameState.next_mega_bot_cost
		# One-way latch — mega bots count label appears with the button
		if not mega_bots_rate_label.visible:
			mega_bots_rate_label.visible = true
		mega_bots_rate_label.text = "Mega-Bots: " + str(GameState.mega_bots)

	# Happiness bar: colour transitions smoothly from red (0%) to green (100%)
	var happiness: float = GameState.get_happiness()
	happiness_bar.value = happiness
	var t: float = happiness / 100.0
	_happiness_fill_style.bg_color = Color.RED.lerp(Color.GREEN, t)

	var active_item: Dictionary = {}
	for item: Dictionary in Config.RESEARCH_ITEMS:
		if GameState.research_funded.get(item["id"], false) and not GameState.research_complete.get(item["id"], false):
			active_item = item
			break
	if active_item.is_empty():
		research_active_label.text = "No Active Research"
		research_progress_bar.value = 0.0
	else:
		research_active_label.text = active_item["name"]
		research_progress_bar.value = GameState.research_points.get(active_item["id"], 0.0) / float(active_item["points_cost"])
	research_cats_label.text = "Cats researching: " + str(GameState.get_research_cats())
	# One-way latch — housing-gated research panels stay hidden until the player's
	# housing tier reaches the item's min_housing_tier, then remain visible thereafter.
	for item: Dictionary in Config.RESEARCH_ITEMS:
		var gate_id: String = item["id"]
		var min_tier: int = int(item.get("min_housing_tier", 0))
		if min_tier > 0 and not _research_panel_unlocked.get(gate_id, false):
			if GameState.housing_tier_index >= min_tier:
				_research_panel_unlocked[gate_id] = true
				if not _research_panel_hidden.get(gate_id, false):
					(_research_panels[gate_id] as PanelContainer).visible = true
	for item: Dictionary in Config.RESEARCH_ITEMS:
		var item_id: String = item["id"]
		if _research_panel_hidden.get(item_id, false):
			continue
		var fund_btn: Button = _research_fund_buttons[item_id]
		var prog_label: Label = _research_progress_labels[item_id]
		if GameState.research_funded.get(item_id, false):
			fund_btn.visible = false
			prog_label.visible = true
			if int(item["min_cats_required"]) > 0 and GameState.get_research_cats() < int(item["min_cats_required"]):
				prog_label.text = "Needs " + str(int(item["min_cats_required"])) + "+ cats assigned to begin"
			else:
				prog_label.text = "In Progress…"
		else:
			fund_btn.visible = true
			fund_btn.disabled = GameState.money < float(item["fund_cost"])
			prog_label.visible = false

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
		elif housing_button.visible:
			housing_button.visible = false
			_sort_shop_list()

	# One-way latch — center research column appears after first housing upgrade
	if GameState.housing_tier_index >= 1 and not _center_column_shown:
		_center_column_shown = true
		center_column.visible = true

	# One-way latch — research slider appears once any item is funded (GameState.research_funded)
	if not _research_slider_shown and GameState.research_funded.size() > 0:
		_research_slider_shown = true
		research_slider.visible = true

	# One-way latch — cat intelligence label appears once cat_power_unite completes (GameState.research_complete)
	if not _cat_intelligence_shown and GameState.research_complete.get("cat_power_unite", false):
		_cat_intelligence_shown = true
		_cat_intelligence_label.visible = true
	if _cat_intelligence_label.visible:
		_cat_intelligence_label.text = "Cat Intelligence: " + str(GameState.cat_intelligence)

	# One-way latch — whale popup fires the instant the mechanic unlocks (manager_bots >= 2
	# and the 20s delay elapsed), like every other popup. Decoupled from the spawn pipeline
	# so it no longer waits for a random burst window to coincide with a per-cat timer.
	if GameState.viral_bubbles_unlocked and not GameState.viral_popup_shown:
		GameState.viral_popup_shown = true
		_show_viral_popup()

	# Global burst window: alternates between an idle cooldown and a brief open window.
	# Per-cat timers below only spawn while a window is open; this runs every frame.
	if not _burst_window_active:
		_global_cd_timer -= delta
		if _global_cd_timer <= 0.0:
			_burst_window_active = true
			_burst_window_timer = randf_range(Config.BUBBLE_BURST_WINDOW_MIN, Config.BUBBLE_BURST_WINDOW_MAX)
	else:
		_burst_window_timer -= delta
		if _burst_window_timer <= 0.0:
			_burst_window_active = false
			_global_cd_timer = randf_range(Config.BUBBLE_GLOBAL_CD_MIN, Config.BUBBLE_GLOBAL_CD_MAX)

	# Per-cat bubble cooldowns — each cat's timer runs continuously and always resets on
	# expiry, but only fires a spawn if the burst window is open at that moment.
	for key: int in _cat_bubble_timers.keys():
		_cat_bubble_timers[key] -= delta
		if _cat_bubble_timers[key] <= 0.0:
			_cat_bubble_timers[key] = randf_range(Config.BUBBLE_SPAWN_MIN, Config.BUBBLE_SPAWN_MAX)
			if _burst_window_active:
				var cat_node: Node2D = null
				for child: Node in cat_container.get_children():
					if child.get_instance_id() == key:
						cat_node = child as Node2D
						break
				if cat_node != null:
					_try_spawn_bubble_for_cat(cat_node)

	# Bubble lifetime & fade — advance timers, fade out, and collect expired bubbles
	var _expired: Array = []
	for bubble: Dictionary in _active_bubbles:
		bubble.timer += delta
		(bubble.node as Button).modulate.a = 1.0 - (bubble.timer / Config.BUBBLE_LIFETIME)
		if bubble.timer >= Config.BUBBLE_LIFETIME:
			(bubble.node as Button).queue_free()
			if is_instance_valid(bubble.cat_node):
				bubble.cat_node.resume_from_bubble()
			_expired.append(bubble)
	for bubble: Dictionary in _expired:
		_active_bubbles.erase(bubble)


# Viral spawn gates: viral_bubbles_unlocked (manager_bots >= 2 AND 20s elapsed),
# only_paws_active, below BUBBLE_MAX_ON_SCREEN. Called per-cat when that cat's cooldown expires.
# Type: "viral" when no active research. When research active:
#   "inspiration" with probability = research_cat_fraction, else "viral".
# First viral spawn fires the whale popup instead of a bubble; bubbles begin after dismiss.
func _try_spawn_bubble_for_cat(cat_node: Node2D) -> void:
	if not GameState.viral_bubbles_unlocked:
		return
	if not GameState.only_paws_active:
		return
	if _active_bubbles.size() >= Config.BUBBLE_MAX_ON_SCREEN:
		return
	_spawn_bubble(cat_node)


func _spawn_bubble(cat_node: Node2D, force_type: String = "") -> void:
	var active_research_id: String = GameState.get_active_research_id()
	var type: String
	if force_type != "":
		type = force_type
	elif active_research_id == "":
		type = "viral"
	else:
		type = "inspiration" if randf() < GameState.research_cat_fraction else "viral"

	var offset := Vector2(randf_range(-30.0, 30.0), randf_range(-50.0, -20.0))
	var spawn_pos: Vector2 = cat_node.global_position + offset

	var button: Button = Button.new()
	button.text = "💡" if type == "inspiration" else "💰"
	button.add_theme_font_size_override("font_size", 48)
	button.custom_minimum_size = Vector2(80, 80)
	button.position = spawn_pos
	button.z_index = 100
	add_child(button)

	var bubble: Dictionary = {
		"node": button,
		"timer": 0.0,
		"type": type,
		"research_id": active_research_id,
		"cat_node": cat_node,
	}
	# gui_input used instead of pressed so we can read cursor position and
	# collect any additional bubbles stacked at the same screen location.
	button.gui_input.connect(_on_bubble_gui_input.bind(bubble))
	_active_bubbles.append(bubble)
	# Only viral bubbles freeze the cat under them while the bubble is live.
	if type == "viral" and is_instance_valid(cat_node):
		cat_node.pause_for_bubble()


# Builds and shows the one-time "Whale Hunting" achievement popup entirely in code,
# mirroring the project's popup pattern (full-screen overlay + centered dialog, pauses tree).
func _show_viral_popup() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	overlay.z_index = 20
	add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var dialog: PanelContainer = PanelContainer.new()
	center.add_child(dialog)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	dialog.add_child(vbox)

	var label: Label = Label.new()
	label.text = "NEW ACHIEVEMENT: Whale Hunting Baby!\n\nOne of your furry little charaltan's has caught the eye of a particularly \"giving\" patron. Snatch that money before they change their mind!\n\nREWARD: Dirty Filthy Disgusting Money\nEver so often one of your cats will go viral. When they do, a bubble will pop up over their head. Click the bubble before it goes away to get a small burst of money."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560.0, 0.0)
	vbox.add_child(label)

	var ok_button: Button = Button.new()
	ok_button.text = "OK"
	vbox.add_child(ok_button)
	ok_button.pressed.connect(func() -> void:
		overlay.queue_free()
		get_tree().paused = false
		_force_first_viral_bubble()
	)

	get_tree().paused = true


# Builds and shows the one-time "AI Overlords" achievement popup entirely in code,
# mirroring _show_viral_popup(): full-screen overlay + centered 600×360 dialog, pauses tree.
func _show_ai_overlords_popup() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	overlay.z_index = 20
	add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var dialog: PanelContainer = PanelContainer.new()
	dialog.custom_minimum_size = Vector2(600.0, 360.0)
	center.add_child(dialog)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	dialog.add_child(vbox)

	var label: Label = Label.new()
	label.text = "NEW ACHIEVEMENT: AI Overlords\n\nLooks like your cute little guy figured out how to upgrade your manager bots to a better model. This totally won't have any negative consequences later down the line.\n\nREWARD: Mega Manager-Bots\n\nJon Meowremy rejoices as your cats usher a new age of truly heinous manager practices to the forefront of capitalism. These mega-bots provide double the benefits of the puny little normal bots, but also at double the price."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560.0, 0.0)
	vbox.add_child(label)

	var ok_button: Button = Button.new()
	ok_button.text = "OK"
	vbox.add_child(ok_button)
	ok_button.pressed.connect(func() -> void:
		overlay.queue_free()
		get_tree().paused = false
	)

	get_tree().paused = true


# Called once on viral popup dismiss. Bypasses all spawn guards to guarantee
# the player sees their first bubble immediately after the achievement fires.
# Normal burst-window scheduling takes over from this point.
func _force_first_viral_bubble() -> void:
	var children: Array[Node] = cat_container.get_children()
	if children.is_empty():
		return
	var cat_node: Node2D = children[randi() % children.size()] as Node2D
	_spawn_bubble(cat_node, "viral")


# Handles a left-click on a bubble: collects the clicked bubble, then collects any other
# active bubbles whose rect also contains the cursor (stacked bubbles share one click).
func _on_bubble_gui_input(event: InputEvent, bubble: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	# a. Collect the directly-clicked bubble first.
	_on_bubble_pressed(bubble)
	# b. Cursor position in viewport space.
	var click_pos: Vector2 = get_viewport().get_mouse_position()
	# c. Find any remaining bubbles stacked under the same point.
	var stacked: Array = []
	for other: Dictionary in _active_bubbles:
		if (other.node as Button).get_global_rect().has_point(click_pos):
			stacked.append(other)
	# d. Collect each stacked bubble too.
	for other: Dictionary in stacked:
		_on_bubble_pressed(other)


# Collects a bubble: removes it from the active list, frees its node, and grants the reward.
func _on_bubble_pressed(bubble: Dictionary) -> void:
	_active_bubbles.erase(bubble)
	if is_instance_valid(bubble.cat_node):
		bubble.cat_node.resume_from_bubble()
	(bubble.node as Button).queue_free()

	if bubble.type == "viral":
		var reward: float = GameState.paws_income_rate * Config.BUBBLE_VIRAL_MULTIPLIER
		reward = max(reward, 1.0)
		GameState.money += reward
	elif bubble.type == "inspiration":
		var rid: String = bubble.research_id
		if GameState.research_funded.get(rid, false) and not GameState.research_complete.get(rid, false):
			var reward_points: float = float(GameState.get_research_cats()) * Config.BUBBLE_INSPIRATION_SECONDS
			reward_points = max(reward_points, 1.0)
			GameState.research_points[rid] = GameState.research_points.get(rid, 0.0) + reward_points
			for item: Dictionary in Config.RESEARCH_ITEMS:
				if item["id"] == rid:
					GameState.research_points[rid] = min(GameState.research_points[rid], float(item["points_cost"]))
					break


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


func _on_mega_manager_bot_button_pressed() -> void:
	GameState.buy_mega_bot()


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


func _on_buy_pawsco_membership_button_pressed() -> void:
	GameState.buy_pawsco_membership()


func _on_buy_ai_enterprise_membership_button_pressed() -> void:
	GameState.buy_ai_enterprise_membership()


func _on_buy_housing_button_pressed() -> void:
	GameState.buy_housing_upgrade()


func _on_research_slider_value_changed(value: float) -> void:
	GameState.research_cat_fraction = value


func _on_research_completed(id: String) -> void:
	if _research_panels.has(id):
		(_research_panels[id] as PanelContainer).visible = false
		_research_panel_hidden[id] = true
	if id == "ai_model_upgrade":
		_show_ai_overlords_popup()


func _on_fund_button_pressed(item_id: String) -> void:
	GameState.fund_research(item_id)


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
	_cat_bubble_timers[cat.get_instance_id()] = randf_range(Config.BUBBLE_SPAWN_MIN, Config.BUBBLE_SPAWN_MAX)


func _on_cat_lost() -> void:
	var children: Array[Node] = cat_container.get_children()
	if children.size() > 0:
		var node: Node = children.back()
		_cat_bubble_timers.erase(node.get_instance_id())
		node.queue_free()


# Places cat at a random viewport position that avoids UI elements and existing cats.
# Falls back to ignoring cat spacing, then to anywhere in the viewport.
func _place_cat(cat: Node2D) -> void:
	# Safe zone: 40px inset from all edges, top 10% of screen excluded so
	# bubbles spawned above cats don't render off the top of the viewport.
	var vp_size: Vector2 = get_viewport_rect().size
	var padding: float = 40.0
	var min_x: float = padding
	var max_x: float = vp_size.x - padding
	var min_y: float = vp_size.y * 0.10 + padding
	var max_y: float = vp_size.y - padding
	var ui_nodes: Array[Control] = [
		shop_panel, happiness_bar_container, money_label, cats_label,
		cat_food_label, buy_cat_food_button, earn_money_button, purchase_cat_button,
		only_paws_button, manager_bot_button, bots_rate_label, tokens_label, buy_tokens_button,
	]
	if center_column.visible:
		ui_nodes.append(center_column)
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
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		if _overlaps_ui(candidate, ui_rects) or _too_close_to_cats(candidate, existing_positions):
			continue
		chosen_pos = candidate
		found = true
		break

	if not found:
		for _i: int in CAT_PLACEMENT_ATTEMPTS:
			var candidate := Vector2(
				randf_range(min_x, max_x),
				randf_range(min_y, max_y)
			)
			if _overlaps_ui(candidate, ui_rects):
				continue
			chosen_pos = candidate
			found = true
			break

	if not found:
		chosen_pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
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
