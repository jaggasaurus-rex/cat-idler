extends Control

const CAT_SCENE := preload("res://scenes/CatCharacter.tscn")
const CAT_SPACING_RADIUS := 64.0
const UI_SAFE_PADDING := 16.0
const CAT_PLACEMENT_ATTEMPTS := 30
# Tint applied to a CatCharacter instance once it is converted into a cyborg cat.
const CYBORG_TINT := Color(0.5, 0.85, 1.0)


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
@onready var first_cat_popup: ColorRect = $FirstCatPopup
@onready var cyborg_cats_label: Label = $CyborgCatsLabel
@onready var make_cyborg_button: Button = $MakeCyborgButton
@onready var cyborg_popup: ColorRect = $CyborgPopup
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
@onready var center_column: VBoxContainer = $CenterColumn
@onready var research_active_label: Label = $CenterColumn/ResearchActiveLabel
@onready var research_progress_bar: ProgressBar = $CenterColumn/ResearchProgressBar
@onready var research_slider: HSlider = $CenterColumn/ResearchSlider
@onready var research_cats_label: Label = $CenterColumn/ResearchCatsLabel
@onready var research_item_list: VBoxContainer = $CenterColumn/ResearchItemList


var _pawsco_membership_button: Button
var _ai_enterprise_membership_button: Button
var _robo_sweeper_button: Button
# Cyborg multiplier-upgrade shop button — created in _ready(), added to ShopList.
var _cyborg_multiplier_button: Button
var _cat_intelligence_label: Label
# One-way latch for the cyborg-cats achievement popup (fires once on research completion).
var _cyborg_popup_shown: bool = false
# Tracks which CatContainer children have been converted to cyborgs (instance_id -> true),
# so cyborgs are excluded from the poop loop and normal cat-loss removes a non-cyborg node.
var _cyborg_cat_ids: Dictionary = {}
var _only_paws_popup_shown: bool = false
var _starvation_popup_shown: bool = false
var _starvation_2_popup_shown: bool = false
# Tracks the highest starvation_count whose recurring popup sequence was started,
# so each new offense (count >= 3) fires exactly once per unique count value.
var _starvation_handled_count: int = 0
var _happiness_cramped_popup_shown: bool = false
var _happiness_riot_popup_shown: bool = false
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
# Per-cat poop cooldown timers. Keys = instance_id, values = seconds remaining.
# Same structure as _cat_bubble_timers; initialised on cat purchase, erased on loss.
var _cat_poop_timers: Dictionary = {}
# Active poop dicts: { "node": Button }
var _active_poops: Array = []
# Global burst window system: per-cat timers run continuously but only fire during
# an open window. Windows are separated by a randomized global cooldown. Triggers
# that land outside a window are discarded — never queued or cached.
var _burst_window_active: bool = false
var _burst_window_timer: float = 0.0
var _global_cd_timer: float = randf_range(Config.BUBBLE_GLOBAL_CD_MIN, Config.BUBBLE_GLOBAL_CD_MAX)

# Robo-Shit Sweeper — Node2D visual driven by an inline state machine (no separate scene/script).
var _sweeper_node: Node2D = null
var _sweeper_label: Label = null

# SweeperState no longer contains CHARGING — the sweeper cleans continuously.
enum SweeperState { INACTIVE, MOVING, CLEANING }
var _sweeper_state: SweeperState = SweeperState.INACTIVE
var _sweeper_target_poop: Dictionary = {}   # the poop dict currently targeted
var _sweeper_clean_timer: float = 0.0       # counts down during CLEANING

# Developer debug menu — overlay panel built dynamically in _ready() (never in Main.tscn),
# toggled by the backtick key via _unhandled_key_input so it never blocks existing input.
var _debug_menu_visible: bool = false
var _debug_poop_disabled: bool = false
var _debug_panel: PanelContainer = null
var _debug_poop_check: CheckButton = null


func _ready() -> void:
	# Sets the global fallback so all labels/buttons inherit UI_BASE_FONT_SIZE
	# without per-node overrides. Individual overrides (headers, bubbles) are
	# applied below and will take precedence.
	ThemeDB.fallback_font_size = Config.UI_BASE_FONT_SIZE
	GameState.cat_purchased.connect(_on_cat_purchased)
	GameState.cat_lost.connect(_on_cat_lost)
	GameState.research_completed.connect(_on_research_completed)
	GameState.cyborg_cat_created.connect(_on_cyborg_cat_created)
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
		fund_btn.text = Strings.BTN_FUND_RESEARCH % Util.format_number(float(item["fund_cost"]))
		fund_btn.pressed.connect(_on_fund_button_pressed.bind(item_id))
		vbox.add_child(fund_btn)
		_research_fund_buttons[item_id] = fund_btn
		var progress_label: Label = Label.new()
		progress_label.visible = false
		vbox.add_child(progress_label)
		_research_progress_labels[item_id] = progress_label
		_research_panel_hidden[item_id] = false
		_research_panel_unlocked[item_id] = false
		# Every panel starts hidden; _refresh_research_slots() is the sole authority
		# that reveals eligible panels. This keeps tier-0 items other than
		# cat_power_unite (e.g. robo_shit_sweeper) from showing before the global
		# cat_power_unite gate is satisfied, since the gate only adds visibility.
		panel.visible = false
	# Dynamic fill colour for the happiness bar; updated in _process()
	_happiness_fill_style = StyleBoxFlat.new()
	_happiness_fill_style.bg_color = Color.GREEN
	happiness_bar.add_theme_stylebox_override("fill", _happiness_fill_style)
	# Static shop item costs for sort ordering; dynamic costs updated before each sort
	auto_feeder_button.set_meta("shop_cost", Config.auto_feeder_cost)
	bot_manager_shop_button.set_meta("shop_cost", Config.bot_manager_cost)
	housing_button.set_meta("shop_cost", 0.0)
	auto_feeder_button.text = Strings.BTN_AUTO_FEEDER % Util.format_number(Config.auto_feeder_cost)
	bot_manager_shop_button.text = Strings.BTN_BOT_MANAGER % Util.format_number(Config.bot_manager_cost)
	_pawsco_membership_button = Button.new()
	_pawsco_membership_button.text = Strings.BTN_PAWSCO % Util.format_number(Config.pawsco_membership_cost)
	_pawsco_membership_button.visible = false
	_pawsco_membership_button.set_meta("shop_cost", Config.pawsco_membership_cost)
	_pawsco_membership_button.pressed.connect(_on_buy_pawsco_membership_button_pressed)
	shop_list.add_child(_pawsco_membership_button)
	_ai_enterprise_membership_button = Button.new()
	_ai_enterprise_membership_button.text = Strings.BTN_AI_ENTERPRISE % Util.format_number(Config.ai_enterprise_membership_cost)
	_ai_enterprise_membership_button.visible = false
	_ai_enterprise_membership_button.set_meta("shop_cost", Config.ai_enterprise_membership_cost)
	_ai_enterprise_membership_button.pressed.connect(_on_buy_ai_enterprise_membership_button_pressed)
	shop_list.add_child(_ai_enterprise_membership_button)
	_robo_sweeper_button = Button.new()
	_robo_sweeper_button.text = Strings.BTN_ROBO_SWEEPER % Util.format_number(Config.ROBO_SWEEPER_PURCHASE_COST)
	_robo_sweeper_button.visible = false
	_robo_sweeper_button.set_meta("shop_cost", Config.ROBO_SWEEPER_PURCHASE_COST)
	_robo_sweeper_button.pressed.connect(_on_buy_robo_sweeper_button_pressed)
	shop_list.add_child(_robo_sweeper_button)
	# Cyborg multiplier-upgrade button — hidden until cyborg_cats research completes;
	# label/cost set per frame in _process(); disappears once the top tier is reached.
	_cyborg_multiplier_button = Button.new()
	_cyborg_multiplier_button.visible = false
	_cyborg_multiplier_button.set_meta("shop_cost", Config.CYBORG_MULTIPLIER_UPGRADE_COSTS[0])
	_cyborg_multiplier_button.pressed.connect(_on_buy_cyborg_multiplier_button_pressed)
	shop_list.add_child(_cyborg_multiplier_button)
	# Robo-Shit Sweeper device — built once, shown only after robo_sweeper_purchased.
	_sweeper_node = Node2D.new()
	_sweeper_node.visible = false
	_sweeper_node.z_index = 60
	_sweeper_label = Label.new()
	_sweeper_label.text = Strings.SWEEPER_EMOJI
	_sweeper_label.add_theme_font_size_override("font_size", 40)
	_sweeper_label.position = Vector2(-20.0, -20.0)  # center the emoji on the node origin
	_sweeper_node.add_child(_sweeper_label)
	add_child(_sweeper_node)
	research_slider.visible = false
	_cat_intelligence_label = Label.new()
	_cat_intelligence_label.visible = false
	center_column.add_child(_cat_intelligence_label)
	center_column.move_child(_cat_intelligence_label, 1)
	# Override all static scene-node text from Strings so this script is the single
	# source of truth (Main.tscn text becomes editor placeholder only).
	earn_money_button.text = Strings.BTN_EARN_MONEY
	only_paws_button.text = Strings.BTN_ONLY_PAWS
	_set_popup_text(only_paws_popup, Strings.POPUP_ONLY_PAWS)
	_set_popup_text(first_cat_popup, Strings.POPUP_FIRST_CAT)
	_set_popup_text(happiness_cramped_popup, Strings.POPUP_CRAMPED)
	_set_popup_text(happiness_riot_popup, Strings.POPUP_RIOT)
	_set_popup_text(bot_unlock_popup, Strings.POPUP_BOT_UNLOCK)
	_set_popup_text(bot_manager_unlock_popup, Strings.POPUP_BOT_MANAGER_UNLOCK)
	_set_popup_text(upgrades_tab_popup, Strings.POPUP_UPGRADES_TAB)
	_set_popup_text(starvation_popup, Strings.POPUP_STARVATION_1)
	_set_popup_text(starvation_2_popup, Strings.POPUP_STARVATION_2)
	_set_popup_text(starvation_recurring_popup, Strings.POPUP_STARVATION_RECURRING)
	_set_popup_text(starvation_asshole_popup, Strings.POPUP_STARVATION_ASSHOLE)
	_set_popup_text(game_over_popup, Strings.POPUP_GAME_OVER_1)
	_set_popup_text(game_over_2_popup, Strings.POPUP_GAME_OVER_2)
	_set_popup_text(cyborg_popup, Strings.POPUP_CYBORG)
	# Section headers: larger + bold, applied after the fallback base is set above.
	_style_as_header(cats_label)
	_style_as_header($HappinessBarContainer/HappinessTitleLabel)
	_style_as_header($ShopPanel/ShopLabel)
	# Show any research panels immediately eligible on game start (no first-frame delay).
	_refresh_research_slots()
	# Developer debug menu — code-only overlay above everything, hidden until toggled.
	_debug_panel = PanelContainer.new()
	_debug_panel.visible = false
	_debug_panel.z_index = 200   # above everything
	_debug_panel.set_anchors_preset(Control.PRESET_CENTER)
	var _debug_vbox: VBoxContainer = VBoxContainer.new()
	var _debug_title: Label = Label.new()
	_debug_title.text = Strings.DEBUG_MENU_TITLE
	_debug_vbox.add_child(_debug_title)
	_debug_poop_check = CheckButton.new()
	_debug_poop_check.text = Strings.DEBUG_POOP_OFF_LABEL
	_debug_poop_check.button_pressed = false
	_debug_poop_check.toggled.connect(_on_debug_poop_toggled)
	_debug_vbox.add_child(_debug_poop_check)
	_debug_panel.add_child(_debug_vbox)
	add_child(_debug_panel)


# Applies the section-header style (larger size + bold) to a Label node.
func _style_as_header(label: Label) -> void:
	label.add_theme_font_size_override("font_size", Config.UI_HEADER_FONT_SIZE)
	var bold_font := SystemFont.new()
	bold_font.font_weight = 700
	label.add_theme_font_override("font", bold_font)


# Toggles the developer debug menu on the backtick key. Uses _unhandled_key_input so
# it only fires for keys no other control consumed, then marks the event handled to
# keep it from leaking into other systems.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			_debug_menu_visible = not _debug_menu_visible
			_debug_panel.visible = _debug_menu_visible
			get_viewport().set_input_as_handled()


# Debug menu "Poop Off" toggle handler — suppresses poop spawning while pressed.
func _on_debug_poop_toggled(pressed: bool) -> void:
	_debug_poop_disabled = pressed


func _process(delta: float) -> void:
	money_label.text = Strings.HUD_MONEY % Util.format_number(GameState.money)
	var max_cats: int = GameState.get_max_cats()
	# Displayed total counts cyborgs too, so converting a cat does not change the count.
	var total_cats: int = GameState.get_total_cats()
	cats_label.text = Strings.HUD_CATS % [Util.format_number(float(total_cats)), Util.format_number(float(max_cats))]
	cats_label.modulate = Color.RED if total_cats > max_cats else Color.WHITE
	purchase_cat_button.text = Strings.BTN_PURCHASE_CAT % Util.format_number(GameState.next_cat_cost)
	purchase_cat_button.disabled = total_cats >= GameState.get_max_cats()
	# No-bot fallback mirrors GameState's: cyborgs earn M× via the (normal + M*cyborg) population.
	var no_bot_population: float = float(GameState.get_onlypaws_normal_cats()) \
		+ GameState.get_cyborg_multiplier() * float(GameState.get_onlypaws_cyborg_cats())
	var display_rate: float = GameState.paws_income_rate if GameState.bots_active \
		else no_bot_population * Config.onlypaws_income_per_cat
	only_paws_income_label.text = Strings.HUD_ONLY_PAWS_RATE % display_rate

	# Popup queue discipline: only show a popup when the tree is not already paused.
	# The shown-flag is not set until the popup is actually displayed, so if two
	# conditions become true on the same frame, the second defers until the first
	# is dismissed and _process() resumes.
	if GameState.cats >= 1 and not GameState.first_cat_popup_shown:
		if not get_tree().paused:
			GameState.first_cat_popup_shown = true
			first_cat_popup.visible = true
			get_tree().paused = true

	# One-way latch — OnlyPaws button and income label appear together
	if GameState.only_paws_unlocked and not only_paws_button.visible:
		only_paws_button.visible = true
		only_paws_income_label.visible = true

	if GameState.only_paws_unlocked and not _only_paws_popup_shown:
		if not get_tree().paused:
			_only_paws_popup_shown = true
			only_paws_popup.visible = true
			get_tree().paused = true

	# One-way latch — bot button and status label appear together
	if GameState.bot_shop_unlocked and not manager_bot_button.visible:
		manager_bot_button.visible = true
		bots_rate_label.visible = true

	if GameState.bot_shop_unlocked and not GameState.bot_unlock_popup_shown:
		if not get_tree().paused:
			GameState.bot_unlock_popup_shown = true
			bot_unlock_popup.visible = true
			get_tree().paused = true

	# One-way latch — cat food controls appear after the first cat purchase
	if GameState.cats_ever_purchased >= 1 and not cat_food_label.visible:
		cat_food_label.visible = true
		buy_cat_food_button.visible = true
	cat_food_label.text = Strings.HUD_CAT_FOOD % Util.format_number(GameState.cat_food)
	# GameState buy methods guard against insufficient funds; buttons stay enabled.
	# Auto-feeder/auto-token variants append ∞; both read the live (possibly discounted) cost.
	buy_cat_food_button.text = (Strings.BTN_BUY_FOOD_AUTO if GameState.auto_feeder_purchased else Strings.BTN_BUY_FOOD) % Util.format_number(GameState.get_cat_food_pack_cost())

	# One-way latch — tokens label and buy button appear on first bot purchase
	if GameState.tokens_shop_unlocked and not tokens_label.visible:
		tokens_label.visible = true
		buy_tokens_button.visible = true

	tokens_label.text = Strings.HUD_TOKENS % Util.format_number(GameState.tokens)
	buy_tokens_button.text = (Strings.BTN_BUY_TOKENS_AUTO if GameState.bot_manager_purchased else Strings.BTN_BUY_TOKENS) % Util.format_number(GameState.get_token_pack_cost())

	if (GameState.bot_manager_unlocked or GameState.auto_feeder_unlocked) and not GameState.upgrades_tab_popup_shown:
		if not get_tree().paused:
			GameState.upgrades_tab_popup_shown = true
			upgrades_tab_popup.visible = true
			get_tree().paused = true

	if GameState.bot_manager_unlocked and not GameState.bot_manager_unlock_popup_shown:
		if not get_tree().paused:
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

	# Robo-Shit Sweeper button — appears once its research completes, disappears on purchase
	if GameState.research_complete.get("robo_shit_sweeper", false) and not GameState.robo_sweeper_purchased:
		if not _robo_sweeper_button.visible:
			_robo_sweeper_button.visible = true
		_robo_sweeper_button.disabled = GameState.money < Config.ROBO_SWEEPER_PURCHASE_COST
	elif GameState.robo_sweeper_purchased and _robo_sweeper_button.visible:
		_robo_sweeper_button.visible = false

	# OnlyPaws toggle state — green tint when active, default when inactive
	if GameState.only_paws_active:
		only_paws_button.text = Strings.BTN_ONLY_PAWS_ON
		only_paws_button.modulate = Color(0.4, 1.0, 0.4)
	else:
		only_paws_button.text = Strings.BTN_ONLY_PAWS_OFF
		only_paws_button.modulate = Color(1.0, 1.0, 1.0)

	manager_bot_button.text = Strings.BTN_MANAGER_BOT % Util.format_number(GameState.next_bot_cost)
	bots_rate_label.text = Strings.HUD_BOTS % Util.format_number(float(GameState.manager_bots))

	# One-way latch — Mega Manager-Bot button appears once the ai_model_upgrade research completes
	if GameState.research_complete.get("ai_model_upgrade", false) and not mega_manager_bot_button.visible:
		mega_manager_bot_button.visible = true
	if mega_manager_bot_button.visible:
		mega_manager_bot_button.text = Strings.BTN_MEGA_BOT % Util.format_number(GameState.next_mega_bot_cost)
		mega_manager_bot_button.disabled = GameState.money < GameState.next_mega_bot_cost
		# One-way latch — mega bots count label appears with the button
		if not mega_bots_rate_label.visible:
			mega_bots_rate_label.visible = true
		mega_bots_rate_label.text = Strings.HUD_MEGA_BOTS % Util.format_number(float(GameState.mega_bots))

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
		research_active_label.text = Strings.RESEARCH_NO_ACTIVE
		research_progress_bar.value = 0.0
	else:
		research_active_label.text = Strings.RESEARCH_NAMES.get(active_item["id"], active_item["id"])
		research_progress_bar.value = GameState.research_points.get(active_item["id"], 0.0) / float(active_item["points_cost"])
	research_cats_label.text = Strings.HUD_RESEARCH_CATS % str(GameState.get_research_cats())
	_refresh_research_slots()
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
				prog_label.text = Strings.RESEARCH_NEEDS_CATS % str(int(item["min_cats_required"]))
			else:
				prog_label.text = Strings.RESEARCH_IN_PROGRESS
		else:
			fund_btn.visible = true
			fund_btn.disabled = GameState.money < float(item["fund_cost"])
			prog_label.visible = false

	if GameState.starvation_count >= 1 and not _starvation_popup_shown:
		if not get_tree().paused:
			_starvation_popup_shown = true
			starvation_popup.visible = true
			get_tree().paused = true

	if GameState.starvation_count >= 2 and not _starvation_2_popup_shown:
		if not get_tree().paused:
			_starvation_2_popup_shown = true
			starvation_2_popup.visible = true
			get_tree().paused = true

	if GameState.starvation_count >= 3 and GameState.starvation_count > _starvation_handled_count:
		if not get_tree().paused:
			_starvation_handled_count = GameState.starvation_count
			starvation_recurring_popup.visible = true
			get_tree().paused = true

	if GameState.happiness_cramped_triggered and not _happiness_cramped_popup_shown:
		if not get_tree().paused:
			_happiness_cramped_popup_shown = true
			happiness_cramped_popup.visible = true
			get_tree().paused = true

	if GameState.happiness_riot_triggered and not _happiness_riot_popup_shown:
		if not get_tree().paused:
			_happiness_riot_popup_shown = true
			happiness_riot_popup.visible = true
			get_tree().paused = true

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
		_cat_intelligence_label.text = Strings.HUD_CAT_INTELLIGENCE % str(GameState.cat_intelligence)

	# One-way latch — cyborg count label and conversion button appear together once the
	# cyborg_cats research completes; both update from dedicated state vars each frame.
	if GameState.research_complete.get("cyborg_cats", false):
		if not cyborg_cats_label.visible:
			cyborg_cats_label.visible = true
			make_cyborg_button.visible = true
		# Label reads cyborg_cats; button cost reads next_cyborg_cost (no inline math).
		cyborg_cats_label.text = Strings.HUD_CYBORG_CATS % Util.format_number(float(GameState.cyborg_cats))
		make_cyborg_button.text = Strings.BTN_MAKE_CYBORG % Util.format_number(GameState.next_cyborg_cost)
		make_cyborg_button.disabled = GameState.cats < 1 or GameState.money < GameState.next_cyborg_cost

	# Cyborg multiplier-upgrade shop button — revealed by the same research latch,
	# disappears once cyborg_multiplier_tier is maxed; label shows the next tier and cost.
	var cyborg_unlocked: bool = GameState.research_complete.get("cyborg_cats", false)
	var cyborg_tier_maxed: bool = GameState.cyborg_multiplier_tier + 1 >= Config.CYBORG_MULTIPLIERS.size()
	if cyborg_unlocked and not cyborg_tier_maxed:
		var next_mult: float = float(Config.CYBORG_MULTIPLIERS[GameState.cyborg_multiplier_tier + 1])
		var upgrade_cost: float = float(Config.CYBORG_MULTIPLIER_UPGRADE_COSTS[GameState.cyborg_multiplier_tier])
		_cyborg_multiplier_button.text = Strings.BTN_CYBORG_MULTIPLIER % [Util.format_number(next_mult), Util.format_number(upgrade_cost)]
		_cyborg_multiplier_button.set_meta("shop_cost", upgrade_cost)
		if not _cyborg_multiplier_button.visible:
			_cyborg_multiplier_button.visible = true
			_sort_shop_list()
	elif _cyborg_multiplier_button.visible:
		_cyborg_multiplier_button.visible = false
		_sort_shop_list()

	# One-way latch — cyborg achievement popup fires exactly once on research completion.
	if GameState.research_complete.get("cyborg_cats", false) and not _cyborg_popup_shown:
		if not get_tree().paused:
			_cyborg_popup_shown = true
			cyborg_popup.visible = true
			get_tree().paused = true

	# One-way latch — whale popup fires the instant the mechanic unlocks (manager_bots >= 2
	# and the 20s delay elapsed), like every other popup. Decoupled from the spawn pipeline
	# so it no longer waits for a random burst window to coincide with a per-cat timer.
	if GameState.viral_bubbles_unlocked and not GameState.viral_popup_shown:
		if not get_tree().paused:
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

	# Poop timers: no burst window — each cat's timer fires independently
	# and continuously. Poop accumulates on screen until clicked.
	# GameState.poop_count drives get_happiness() which feeds the income multiplier.
	for key: int in _cat_poop_timers.keys():
		_cat_poop_timers[key] -= delta
		if _cat_poop_timers[key] <= 0.0:
			_cat_poop_timers[key] = randf_range(Config.POOP_SPAWN_MIN, Config.POOP_SPAWN_MAX)
			var poop_cat: Node2D = null
			for child: Node in cat_container.get_children():
				if child.get_instance_id() == key:
					poop_cat = child as Node2D
					break
			if poop_cat != null:
				# DEBUG: toggled via debug menu (backtick). Timer still ticks; only spawn is suppressed.
				if not _debug_poop_disabled:
					_spawn_poop(poop_cat)

	_process_sweeper(delta)

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


# Drives the Robo-Shit Sweeper's inline state machine: it continuously sweeps to the
# nearest poop and removes it via _on_poop_pressed, with no charging or per-run cap.
# When no poops remain it idles in MOVING until one appears.
func _process_sweeper(delta: float) -> void:
	match _sweeper_state:
		SweeperState.INACTIVE:
			if not GameState.robo_sweeper_purchased:
				return
			# Appear in the middle of the screen and start sweeping immediately.
			_sweeper_node.position = get_viewport_rect().size * 0.5
			_sweeper_node.visible = true
			_sweeper_state = SweeperState.MOVING
		SweeperState.MOVING:
			if _active_poops.is_empty():
				return
			# Target the poop nearest the sweeper's current position.
			var nearest_poop: Dictionary = {}
			var nearest_dist: float = INF
			for poop: Dictionary in _active_poops:
				var d: float = _sweeper_node.position.distance_to((poop.node as Control).position)
				if d < nearest_dist:
					nearest_dist = d
					nearest_poop = poop
			_sweeper_target_poop = nearest_poop
			var target_pos: Vector2 = (_sweeper_target_poop.node as Control).position
			_sweeper_node.position = _sweeper_node.position.move_toward(target_pos, Config.SWEEPER_MOVE_SPEED * delta)
			if _sweeper_node.position.distance_to(target_pos) <= 8.0:
				_sweeper_state = SweeperState.CLEANING
				_sweeper_clean_timer = Config.SWEEPER_CLEAN_DELAY
		SweeperState.CLEANING:
			_sweeper_clean_timer -= delta
			if _sweeper_clean_timer <= 0.0:
				if not _sweeper_target_poop.is_empty() and _active_poops.has(_sweeper_target_poop):
					_on_poop_pressed(_sweeper_target_poop)
				_sweeper_target_poop = {}
				_sweeper_state = SweeperState.MOVING


# Shows research panels one at a time in RESEARCH_ITEMS order, subject to:
# housing tier gate, predecessor-complete gate, and RESEARCH_MAX_VISIBLE cap.
# Called from _process() each frame and immediately after any completion.
func _refresh_research_slots() -> void:
	var visible_count: int = 0
	for item: Dictionary in Config.RESEARCH_ITEMS:
		var id: String = item["id"]
		if (_research_panels[id] as PanelContainer).visible and not _research_panel_hidden.get(id, false):
			visible_count += 1

	for i in range(Config.RESEARCH_ITEMS.size()):
		var item: Dictionary = Config.RESEARCH_ITEMS[i]
		var id: String = item["id"]

		# Global gate: no research populates until cat_power_unite is complete.
		# blocked until cat_power_unite research_complete (the cat_power_unite
		# panel itself is exempt so it can be funded and completed).
		if not GameState.research_complete.get("cat_power_unite", false) and id != "cat_power_unite":
			continue

		# Skip if already visible or already completed/hidden
		if (_research_panels[id] as PanelContainer).visible:
			continue
		if _research_panel_hidden.get(id, false):
			continue

		# Housing tier gate (existing rule)
		if GameState.housing_tier_index < int(item.get("min_housing_tier", 0)):
			continue

		# Predecessor gate: all items before index i must be complete
		var predecessors_done: bool = true
		for j in range(i):
			var pred_id: String = Config.RESEARCH_ITEMS[j]["id"]
			if not GameState.research_complete.get(pred_id, false):
				predecessors_done = false
				break
		if not predecessors_done:
			continue

		# OR unlock gate (additive to the predecessor gate): when an item declares
		# unlock_requires_cats and/or unlock_requires_research, it stays hidden until
		# EITHER the cat count threshold OR the named research completion is met.
		var unlock_cats: int = int(item.get("unlock_requires_cats", 0))
		var unlock_research: String = str(item.get("unlock_requires_research", ""))
		if unlock_cats > 0 or unlock_research != "":
			var cats_gate: bool = unlock_cats > 0 and GameState.cats >= unlock_cats
			var research_gate: bool = unlock_research != "" and GameState.research_complete.get(unlock_research, false)
			if not cats_gate and not research_gate:
				continue

		# Slot gate: stop if already at the max
		if visible_count >= Config.RESEARCH_MAX_VISIBLE:
			break

		# All gates passed — show the panel (one-way latch)
		(_research_panels[id] as PanelContainer).visible = true
		_research_panel_unlocked[id] = true
		visible_count += 1


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
	button.text = Strings.BUBBLE_VIRAL if type == "viral" else Strings.BUBBLE_INSPIRATION
	button.add_theme_font_size_override("font_size", roundi(Config.UI_BASE_FONT_SIZE * 2.2))
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


# Sets the body text of a scene-built popup. Every popup ColorRect shares the same
# inner path DialogPanel/VBoxContainer/PopupLabel, so the body lives at a fixed offset.
func _set_popup_text(popup: ColorRect, body: String) -> void:
	(popup.get_node("DialogPanel/VBoxContainer/PopupLabel") as Label).text = body


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
	label.text = Strings.POPUP_VIRAL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560.0, 0.0)
	vbox.add_child(label)

	var ok_button: Button = Button.new()
	ok_button.text = Strings.BTN_OK
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
	label.text = Strings.POPUP_AI_OVERLORDS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560.0, 0.0)
	vbox.add_child(label)

	var ok_button: Button = Button.new()
	ok_button.text = Strings.BTN_OK
	vbox.add_child(ok_button)
	ok_button.pressed.connect(func() -> void:
		overlay.queue_free()
		get_tree().paused = false
	)

	get_tree().paused = true


# Builds and shows the one-time inspiration-bubble achievement popup entirely in code,
# mirroring _show_viral_popup(). Gated by GameState.inspiration_popup_shown (set true by
# the caller before this runs) so it fires exactly once, on the first inspiration collect.
func _show_inspiration_popup() -> void:
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
	label.text = Strings.POPUP_INSPIRATION
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560.0, 0.0)
	vbox.add_child(label)

	var ok_button: Button = Button.new()
	ok_button.text = Strings.BTN_OK
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
		# Reward = one cat's $/sec × multiplier (not total income — one cat went viral)
		var per_cat_rate: float = Config.onlypaws_income_per_cat \
			+ Config.onlypaws_income_per_bot * float(GameState.manager_bots) \
			+ Config.MEGA_BOT_INCOME_PER_CAT * float(GameState.mega_bots)
		var reward: float = max(per_cat_rate * Config.BUBBLE_VIRAL_MULTIPLIER, 1.0)
		GameState.money += reward
	elif bubble.type == "inspiration":
		var rid: String = bubble.research_id
		if GameState.research_funded.get(rid, false) and not GameState.research_complete.get(rid, false):
			# Reward = one cat's research contribution × seconds (not all research cats)
			var reward_points: float = max(1.0 * Config.BUBBLE_INSPIRATION_SECONDS, 1.0)
			GameState.research_points[rid] = GameState.research_points.get(rid, 0.0) + reward_points
			for item: Dictionary in Config.RESEARCH_ITEMS:
				if item["id"] == rid:
					GameState.research_points[rid] = min(GameState.research_points[rid], float(item["points_cost"]))
					break
			if not GameState.inspiration_popup_shown:
				GameState.inspiration_popup_shown = true
				_show_inspiration_popup()


func _on_earn_money_button_pressed() -> void:
	GameState.click()


func _on_purchase_cat_button_pressed() -> void:
	GameState.buy_cat()


func _on_make_cyborg_button_pressed() -> void:
	GameState.buy_cyborg_cat()


func _on_buy_cyborg_multiplier_button_pressed() -> void:
	GameState.buy_cyborg_multiplier_upgrade()


func _on_cyborg_popup_ok_pressed() -> void:
	cyborg_popup.visible = false
	get_tree().paused = false


# Converts one existing normal CatCharacter into a cyborg in response to cyborg_cat_created:
# tints it, removes it from the poop loop (cyborgs never poop), and records its id so the
# normal cat-loss path won't remove it. GameState already adjusted cats/cyborg_cats counts.
func _on_cyborg_cat_created() -> void:
	for child: Node in cat_container.get_children():
		var id: int = child.get_instance_id()
		if _cyborg_cat_ids.has(id):
			continue
		_cyborg_cat_ids[id] = true
		(child as Node2D).modulate = CYBORG_TINT
		_cat_poop_timers.erase(id)
		return


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


func _on_buy_robo_sweeper_button_pressed() -> void:
	GameState.buy_robo_sweeper()


func _on_buy_housing_button_pressed() -> void:
	GameState.buy_housing_upgrade()


func _on_research_slider_value_changed(value: float) -> void:
	# research_cat_fraction affects get_onlypaws_cats(), which is read by
	# update_paws_rate(). Must call immediately so paws_income_rate stays current.
	GameState.research_cat_fraction = value
	GameState.update_paws_rate()


func _on_research_completed(id: String) -> void:
	if _research_panels.has(id):
		(_research_panels[id] as PanelContainer).visible = false
		_research_panel_hidden[id] = true
	_refresh_research_slots()
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
	_cat_poop_timers[cat.get_instance_id()] = randf_range(Config.POOP_SPAWN_MIN, Config.POOP_SPAWN_MAX)


func _on_cat_lost() -> void:
	var children: Array[Node] = cat_container.get_children()
	if children.size() > 0:
		# cat_lost only decrements the normal `cats` count, so remove the last NON-cyborg
		# node; fall back to the last child only if every remaining node is a cyborg.
		var node: Node = children.back()
		for i: int in range(children.size() - 1, -1, -1):
			if not _cyborg_cat_ids.has(children[i].get_instance_id()):
				node = children[i]
				break
		_cat_bubble_timers.erase(node.get_instance_id())
		_cat_poop_timers.erase(node.get_instance_id())
		_cyborg_cat_ids.erase(node.get_instance_id())
		node.queue_free()
	# If the sweeper was cleaning the last poop and it's now gone, return to MOVING
	# instead of stalling on a target that no longer exists.
	if _sweeper_state == SweeperState.CLEANING and _active_poops.is_empty():
		_sweeper_target_poop = {}
		_sweeper_state = SweeperState.MOVING


# Spawns a poop button near cat_node. Poop accumulates until clicked;
# it does not expire automatically.
func _spawn_poop(cat_node: Node2D) -> void:
	var offset := Vector2(randf_range(-40.0, 40.0), randf_range(10.0, 30.0))
	var spawn_pos: Vector2 = cat_node.global_position + offset

	var button: Button = Button.new()
	button.text = Strings.POOP_EMOJI
	button.add_theme_font_size_override("font_size", 36)
	button.custom_minimum_size = Vector2(64.0, 64.0)
	button.position = spawn_pos
	button.z_index = 50
	add_child(button)

	var poop: Dictionary = {"node": button}
	button.pressed.connect(_on_poop_pressed.bind(poop))
	_active_poops.append(poop)
	GameState.poop_count += 1


# Removes a poop from the screen and decrements the global count.
func _on_poop_pressed(poop: Dictionary) -> void:
	_active_poops.erase(poop)
	(poop.node as Button).queue_free()
	GameState.poop_count = max(0, GameState.poop_count - 1)


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
