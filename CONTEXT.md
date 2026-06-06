# Cat Idler — Project Context

> **Living document.** Update this file after every task to reflect new files,
> systems, variables, or features added or changed.

---

## Project Overview

| Field | Value |
|---|---|
| **Game name** | Cat Idler |
| **Engine** | Godot 4.6 |
| **Renderer** | GL Compatibility |
| **Platform target** | Desktop (Windows primary) |
| **Main scene** | `res://scenes/Main.tscn` |

---

## Architecture

### Directory layout

```
cat-idler/
├── autoloads/
│   ├── GameState.gd        # Global state singleton
│   └── Util.gd             # Stateless helper functions (format_number)
├── scenes/
│   ├── CatCharacter.tscn   # Sprite-based cat (instances scripts/CatCharacter.gd; AnimatedSprite2D child)
│   ├── Main.gd             # Root scene script
│   └── Main.tscn           # Root scene
├── scripts/
│   └── CatCharacter.gd     # Cat character root (AnimatedSprite2D configured in editor)
├── Config.gd               # Autoloaded singleton; all static tuning constants
├── CONTEXT.md              # This file
├── ROADMAP.md              # Phase plan and design intent
└── project.godot
```

### Autoloads

| Singleton name | Path | Purpose |
|---|---|---|
| `Util` | `res://autoloads/Util.gd` | Stateless helper functions; no mutable state |
| `Config` | `res://Config.gd` | Static tuning constants; no mutable state; referenced by GameState and Main |
| `GameState` | `res://autoloads/GameState.gd` | Holds all persistent game state; the single source of truth for currency and rates |

### Scene structure

```
Main (Control, full-rect)             ← Main.gd
├── TextureRect                       ← full-screen lofi-studio background image (res://assets/lofi-studio.png)
├── CatContainer (Node2D)             ← pos (576, 530); purchased cats added here; placed second so cats render above the background and below all UI
├── CatsLabel (Label)                 ← hero stat; positioned first (top=20); bold + 1.3× font size applied in _ready(); updated every _process() frame; text format "Cats: X/MAX" where MAX = happiness threshold; modulate = RED when cats > MAX, WHITE otherwise
├── MoneyLabel (Label)                ← updated every _process() frame
├── CatFoodLabel (Label)              ← "Cat Food: X" where X = floor(cat_food); updated every frame
├── EarnMoneyButton (Button)          ← pressed → GameState.click()
├── PurchaseCatButton (Button)        ← permanently shown once shop_unlocked; label updates every frame
├── OnlyPawsButton (Button)           ← permanently shown once only_paws_unlocked; toggles only_paws_active;
│                                       label = "OnlyPaws: ON/OFF"; green modulate when active
├── OnlyPawsIncomeLabel (Label)       ← shown with OnlyPawsButton; "OnlyPaws: $X.XX/sec" updates every frame
├── OnlyPawsInfoPanel (PanelContainer)← hidden permanently (legacy node, not wired to button anymore)
│   └── InfoLabel (Label)             ← static info text, autowrap enabled
├── HappinessBarContainer (VBoxContainer) ← always visible; top=20, left=420–760; shows Cat Happiness title + progress bar
│   ├── HappinessTitleLabel (Label "Cat Happiness")
│   └── HappinessRow (HBoxContainer)
│       ├── HappinessMinLabel (Label "0%")
│       ├── HappinessBar (ProgressBar) ← min=0 max=100; fill colour interpolated red→green each frame via _happiness_fill_style StyleBoxFlat
│       │   └── CatLossMarker (ColorRect) ← 2px red vertical line; anchor_left=anchor_right=0.2 positions it at 20% of bar width; hidden until cat_crusher_unlocked; sits above fill layer as a child Control
│       └── HappinessMaxLabel (Label "100%")
├── StarvationPopup (ColorRect)        ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when starvation_count first reaches 1; pauses tree; on dismiss calls GameState.grant_cat_food_pack(); gated by _starvation_popup_shown (Main.gd local)
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Fasting Never Hurt Anyone"
├── Starvation2Popup (ColorRect)       ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when starvation_count reaches 2; pauses tree; on dismiss: grants food, loses cat, checks game-over; gated by _starvation_2_popup_shown (Main.gd local)
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Third-World Dictator"
├── BotUnlockPopup (ColorRect)         ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when bot_shop_unlocked first becomes true; pauses tree; gated by GameState.bot_unlock_popup_shown
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Cat Harem" achievement
├── StarvationRecurringPopup (ColorRect) ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown each time starvation_count advances past a new count >= 3; gated by _starvation_handled_count (Main.gd local int); chains directly to StarvationAssholePopup on dismiss (tree stays paused)
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "You know the drill"
├── StarvationAssholePopup (ColorRect) ← second popup in recurring sequence; on dismiss: unpauses, grants food, loses cat, checks game-over
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Asshole"
├── GameOverPopup (ColorRect)          ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown when cats==0 AND starvation_cats_lost>=1 AND cats_ever_purchased>0 after any starvation cat loss; chains to GameOver2Popup on dismiss
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Literally Hitler" achievement
├── GameOver2Popup (ColorRect)         ← final popup; on dismiss calls get_tree().quit()
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Fuck you"
│   └── DialogPanel (PanelContainer)  ← centered 600×280 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← "NEW ACHIEVEMENT: Fasting Never Hurt Anyone" message, autowrap
│           └── OKButton (Button)     ← hides popup, unpauses tree, grants free food pack
├── FirstCatPopup (ColorRect)          ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when cats first reaches 1; pauses tree; gated by GameState.first_cat_popup_shown
│   └── DialogPanel (PanelContainer)  ← centered 600×260 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← "NEW ACHIEVEMENT: Cat" message, autowrap
│           └── OKButton (Button)     ← hides popup and unpauses tree
├── OnlyPawsPopup (ColorRect)         ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when only_paws_unlocked first triggers; pauses tree; "NEW ACHIEVEMENT: Work It Gurl"
│   └── DialogPanel (PanelContainer)  ← centered 450×180 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← unlock message, autowrap
│           └── OKButton (Button)     ← hides popup and unpauses tree
├── ManagerBotButton (Button)         ← hidden until bot_shop_unlocked; label shows live cost; disabled when unaffordable
├── BotsRateLabel (Label)             ← shown with ManagerBotButton; "Bots: X" updates every frame
├── TokensLabel (Label)               ← hidden until tokens_shop_unlocked; "Tokens: X" updates every frame
├── ShopPanel (VBoxContainer)         ← right-anchored, always visible; offset_left=-380, offset_right=-10 (370px wide)
│   ├── ShopLabel (Label "Shop")
│   ├── TabBar (HBoxContainer)         ← tab buttons; active tab has green modulate
│   │   ├── CurrencyTabButton (Button "Currency") ← switches to Currency tab; green when active
│   │   ├── UpgradesTabButton (Button "Upgrades") ← hidden until bot_manager_unlocked OR auto_feeder_unlocked; switches to Upgrades tab; green when active
│   │   └── HomeTabButton (Button "Home") ← hidden until home_shop_unlocked; switches to Home tab; green when active
│   ├── CurrencyTabContent (VBoxContainer) ← visible when Currency tab active (default)
│   │   ├── CatFoodItem (VBoxContainer)   ← always visible
│   │   │   ├── CatFoodNameLabel (Label "Cat Food Pack")
│   │   │   ├── CatFoodDescLabel (Label "100 cat food — $10", autowrap_mode=3)
│   │   │   ├── BuyCatFoodX1Button (Button "Buy x1 ($10)")  ← calls buy_cat_food_pack(1); disabled when money < 10
│   │   │   └── BuyCatFoodX10Button (Button "Buy x10 ($100)") ← calls buy_cat_food_pack(10); disabled when money < 10
│   │   └── TokenPackItem (VBoxContainer) ← hidden until tokens_shop_unlocked; one-way latch in _process()
│   │       ├── TokenPackNameLabel (Label "Token Pack")
│   │       ├── TokenPackDescLabel (Label "100 tokens — $20", autowrap_mode=3)
│   │       ├── BuyTokenX1Button (Button "Buy x1 ($20)")   ← calls buy_tokens(1); disabled when money < 20
│   │       └── BuyTokenX10Button (Button "Buy x10 ($200)") ← calls buy_tokens(10); disabled when money < 20
│   ├── UpgradesTabContent (VBoxContainer) ← visible when Upgrades tab active; hidden until tab button reveals
│   │   ├── BotManagerItem (VBoxContainer) ← hidden until bot_manager_unlocked; one-way latch in _process()
│   │   │   ├── BotManagerNameLabel (Label "Manager-bot Manager")
│   │   │   ├── BotManagerDescLabel (Label, autowrap_mode=3) ← hidden in _process() when bot_manager_purchased
│   │   │   └── BuyBotManagerButton (Button "Buy ($20,000)") ← calls buy_bot_manager(); disabled when unaffordable; green + disabled when purchased
│   │   └── AutoFeederItem (VBoxContainer) ← hidden until auto_feeder_unlocked; one-way latch in _process()
│   │       ├── AutoFeederNameLabel (Label "Auto-Feeder")
│   │       ├── AutoFeederDescLabel (Label, autowrap_mode=3) ← hidden in _process() when auto_feeder_purchased
│   │       └── BuyAutoFeederButton (Button "Buy ($40,000)") ← calls buy_auto_feeder(); disabled when unaffordable; green + disabled when purchased
│   └── HomeTabContent (VBoxContainer) ← visible when Home tab active; hidden until tab button reveals
│       ├── CurrentHousingItem (VBoxContainer) ← always visible; shows current tier
│       │   └── CurrentHousingLabel (Label) ← "Current: [tier label]"; green modulate; updated every frame
│       ├── NextHousingItem (VBoxContainer) ← visible while not at max tier; shows next upgrade to buy
│       │   ├── NextHousingNameLabel (Label) ← next tier label; updated every frame
│       │   ├── NextHousingCostLabel (Label, autowrap_mode=3) ← "Expand your cats' living space — $X"; updated every frame
│       │   └── BuyHousingButton (Button) ← calls buy_housing_upgrade(); label and disabled state both read from next_tier["cost"] each frame
│       └── MaxTierLabel (Label "Max Upgrade Reached") ← hidden until housing_tier_index == last tier
├── HappinessCrampedPopup (ColorRect) ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when happiness_cramped_triggered first sets (cats>=10); on dismiss sets home_shop_unlocked=true; pauses tree
│   └── DialogPanel (PanelContainer)  ← centered 500×200 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← cramped message, autowrap
│           └── OKButton (Button)     ← hides popup, unpauses, sets home_shop_unlocked=true
├── HappinessRiotPopup (ColorRect)    ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when happiness_riot_triggered first sets; pauses tree
│   └── DialogPanel (PanelContainer)  ← centered 500×200 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← riot message, autowrap
│           └── OKButton (Button)     ← hides popup and unpauses tree
├── UpgradesTabPopup (ColorRect)      ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when bot_manager_unlocked OR auto_feeder_unlocked first becomes true (gated by GameState.upgrades_tab_popup_shown); pauses tree; dismiss unpauses only
│   └── DialogPanel (PanelContainer)  ← centered 600×260 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← "NEW ACHIEVEMENT! ADHD Cat Parent" message, autowrap
│           └── OKButton (Button)     ← hides popup and unpauses tree
├── CatCrusherPopup (ColorRect)       ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when cat_crusher_triggered first sets (happiness hits 0% a second time); pauses tree; on dismiss sets cat_crusher_unlocked=true
│   └── DialogPanel (PanelContainer)  ← centered 600×260 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← "NEW ACHIEVEMENT: Cat Crusher!" message, autowrap
│           └── OKButton (Button)     ← hides popup, unpauses tree, sets cat_crusher_unlocked=true
```

---

## Game Systems

### GameState (`res://autoloads/GameState.gd`)

Central singleton that owns all game variables. Accessed globally as `GameState`.

| Variable | Type | Default | Description |
|---|---|---|---|
| `money` | `float` | `0.0` | Current money (primary currency) |
| `cats` | `int` | `0` | Number of cats purchased |
| `cat_food` | `float` | `Config.cat_food_start` | Cat food supply; drains at `cats * Config.cat_food_drain_rate` per second; never goes below 0 |
| `next_cat_cost` | `float` | `Config.cat_cost_base` | Cost of the next cat; multiplied by `cat_cost_growth_rate` after each purchase |
| `shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `click()` the first time `money >= next_cat_cost` |
| `only_paws_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_cat()` when `cats >= 3` |
| `paws_income_rate` | `float` | `0.0` | Passive $/sec; recalculated by `_update_paws_rate()` after each cat purchase or bot purchase |
| `manager_bots` | `int` | `0` | Number of Manager-Bots purchased; each one doubles total OnlyPaws output |
| `next_bot_cost` | `float` | `Config.bot_cost_base` | Cost of the next bot; multiplied by `Config.bot_cost_multiplier` after every successful purchase |
| `bot_shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_cat()` when `cats >= 6` |
| `shop_unlocked_bots` | `bool` | `false` | One-way latch; set to `true` in `buy_bot()` when `manager_bots == 4`; reveals the attrition-reduction shop |
| `only_paws_active` | `bool` | `false` | Player-toggled; set to `true` once at unlock in `buy_cat()`; income only ticks when `true`; toggling OFF also sets `bots_active = false`; toggling ON re-enables bots if tokens > 0 |
| `cat_cost_growth_rate` | `float` | `Config.cat_cost_growth_rate` | Multiplier applied to `next_cat_cost` each purchase; reduced to `Config.breeder_contract_growth_rate` by breeder contract |
| `breeder_purchased` | `bool` | `false` | One-way latch; set by `buy_breeder_contract()` |
| `housing_tier_index` | `int` | `0` | Current housing upgrade tier (0 = Basic Studio). Incremented by `buy_housing_upgrade()`. Replaces the former `cat_trees_purchased` bool; tier >= 1 is equivalent |
| `tokens` | `float` | `Config.token_start` | Token supply; drains at `manager_bots * Config.token_drain_per_bot` per second while `bots_active`; never below 0 |
| `bots_active` | `bool` | `true` | Set to `false` when tokens reach 0; re-enabled by `buy_tokens()` if tokens > 0 after purchase; gates token drain and bot income |
| `tokens_shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_bot()` when `manager_bots >= 1` |
| `bot_manager_unlocked` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `tokens <= 0` or `manager_bots >= Config.bot_manager_unlock_bots` |
| `bot_manager_purchased` | `bool` | `false` | One-way latch; set by `buy_bot_manager()`; enables auto-token-purchase in `_process()` |
| `food_hit_zero` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `cat_food <= 0`; used as second unlock trigger for Auto-Feeder |
| `auto_feeder_unlocked` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `cats >= 10` or `food_hit_zero` |
| `auto_feeder_purchased` | `bool` | `false` | One-way latch; set by `buy_auto_feeder()`; enables auto-food-purchase in `_process()` |
| `first_cat_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `cats >= 1`; gates the first-cat achievement popup so it fires exactly once |
| `starvation_count` | `int` | `0` | Increments each time the starvation condition transitions from inactive to active (cat_food <= 0 AND money < 10) |
| `starvation_active` | `bool` | `false` | Frame-level debounce; `true` while the starvation condition persists; resets when cat_food > 0 or money >= 10 |
| `starvation_cats_lost` | `int` | `0` | Tracks cats lost specifically via the starvation mechanic; used in game-over condition |
| `cats_ever_purchased` | `int` | `0` | Lifetime cat purchase counter; incremented in `buy_cat()`; used to gate game-over so it only triggers if the player has owned at least one cat |
| `happiness_cramped_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `get_happiness() <= 50.0` (4 over max, e.g. cats = 24 with default max 20); used by Main.gd to show the cramped popup once |
| `happiness_riot_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `get_happiness() <= 0.0` (6 over max, e.g. cats = 26 with default max 20); used by Main.gd to show the riot popup once |
| `happiness_zero_count` | `int` | `0` | Counts distinct edge-transitions into happiness=0% (i.e. increments each time happiness drops from >0 to 0, tracked via `_happiness_was_zero`); used to gate `cat_crusher_triggered` on count >= 2 |
| `cat_crusher_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `happiness_zero_count >= 2`; used by Main.gd to show the Cat Crusher popup once |
| `cat_crusher_unlocked` | `bool` | `false` | Set to `true` in Main.gd when the Cat Crusher popup is dismissed; activates cat loss drain and the HappinessBar 20% marker |
| `_happiness_was_zero` | `bool` | `false` | Private edge-detection helper; holds whether the previous frame had happiness <= 0; used to count distinct transitions for `happiness_zero_count` |
| `_cat_loss_active` | `bool` | `false` | Private; `true` while the cat loss drain is running; set to `true` when `cat_crusher_unlocked AND happiness <= 20%`; cleared when `happiness > 80%` |
| `_cat_loss_timer` | `float` | `0.0` | Private accumulator; seconds elapsed since last cat loss tick; resets on drain start/stop and each 10-second fire |
| `home_shop_unlocked` | `bool` | `false` | Set to `true` in Main.gd when the cramped popup is dismissed; reserved for a future shop section |
| `upgrades_tab_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `bot_manager_unlocked OR auto_feeder_unlocked`; gates the Upgrades tab achievement popup so it fires exactly once |
| `bot_unlock_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `bot_shop_unlocked`; gates the "Cat Harem" achievement popup so it fires exactly once |

| Signal | Description |
|---|---|
| `cat_purchased` | Emitted by `buy_cat()` after a successful purchase |
| `cat_lost` | Emitted by `_lose_cat()` each time a cat is removed by the drain; Main.gd removes the last CatCharacter node from CatContainer |

| Method | Signature | Description |
|---|---|---|
| `_ready` | `() -> void` | Sets `process_mode = PROCESS_MODE_ALWAYS` so income ticks even while tree is paused |
| `_process` | `(delta) -> void` | Always drains `cat_food`; sets `food_hit_zero` the first time food reaches 0; checks and sets `auto_feeder_unlocked`; if `auto_feeder_purchased` and food low: calls `buy_cat_food_pack(1)`; if `bots_active`: drains tokens, sets `bots_active = false` when tokens reach 0; checks and sets `bot_manager_unlocked`; if `bot_manager_purchased` and tokens low: calls `buy_tokens(1)`; sets `happiness_riot_triggered` the first time `get_happiness() <= 0`; tracks `happiness_zero_count` via edge detection and sets `cat_crusher_triggered` on count >= 2; runs cat loss drain when `cat_crusher_unlocked` (activates at happiness ≤ 20%, fires immediately then every 10s, deactivates at happiness > 80%); if `only_paws_active and bots_active and cat_food > 0`: earns `paws_income_rate * happiness_multiplier * delta` where `happiness_multiplier = 0.30 + (happiness / 100.0) * 0.70` |
| `_lose_cat` | `() -> void` | Private; decrements `cats` (clamped, no-ops at 0), calls `_update_paws_rate()`, emits `cat_lost` |
| `click` | `() -> void` | Adds `1.0` to `money`; sets `shop_unlocked = true` the first time `money >= next_cat_cost` |
| `buy_cat` | `() -> void` | Guards `money >= next_cat_cost`, deducts cost, increments `cats`, applies `cat_cost_growth_rate`, sets `only_paws_unlocked` when `cats >= 3`, sets `bot_shop_unlocked` when `cats >= 6`, calls `_update_paws_rate()`, emits `cat_purchased` |
| `buy_bot` | `() -> void` | Guards `money >= next_bot_cost`, deducts cost, increments `manager_bots`, doubles `next_bot_cost`, calls `_update_paws_rate()`, sets `tokens_shop_unlocked = true` when `manager_bots >= 1`, sets `shop_unlocked_bots = true` when `manager_bots == 4` |
| `get_cat_food_packs_affordable` | `() -> int` | Returns `int(money / 10.0)` |
| `grant_cat_food_pack` | `() -> void` | Adds `Config.cat_food_pack_amount` food at no cost; used for starvation pity rewards |
| `starvation_lose_cat` | `() -> void` | Removes one cat as a starvation penalty: decrements `cats` (clamped), calls `_update_paws_rate()`, increments `starvation_cats_lost`, emits `cat_lost` |
| `buy_cat_food_pack` | `(quantity: int) -> void` | Guards `money >= 10.0 * quantity`; deducts cost; adds `100.0 * quantity` to `cat_food` |
| `buy_tokens` | `(quantity: int) -> void` | Guards `money >= Config.token_pack_cost * quantity`; deducts cost; adds `Config.token_pack_amount * quantity` to `tokens`; sets `bots_active = true` if `tokens > 0` |
| `buy_bot_manager` | `() -> void` | Guards `money >= Config.bot_manager_cost and not bot_manager_purchased`; deducts cost; sets `bot_manager_purchased = true` |
| `buy_auto_feeder` | `() -> void` | Guards `money >= Config.auto_feeder_cost and not auto_feeder_purchased`; deducts cost; sets `auto_feeder_purchased = true` |
| `buy_breeder_contract` | `() -> void` | Guards `money >= 2000 and not breeder_purchased`; sets `cat_cost_growth_rate = 1.25`; retroactively recalculates `next_cat_cost = 5.0 * pow(1.25, cats)` |
| `buy_cat_trees` | `() -> void` | Guards `money >= Config.cat_trees_cost (10000) and not cat_trees_purchased`; deducts cost; sets `cat_trees_purchased = true`; happiness recalculates immediately via `get_happiness()` |
| `get_max_cats` | `() -> int` | Returns `Config.base_max_cats` plus the sum of `max_cats_increase` for each purchased housing tier (1..housing_tier_index) |
| `get_happiness` | `() -> float` | Returns happiness as a percentage (0–100). At or under max_cats: 100%. Over max: two-segment quadratic ease-in decay. `fifty_break = max_cats + 5 + housing_tier_index` (happiness = 50%); `zero_break = max_cats + 10 + housing_tier_index * 2` (happiness = 0%). Segment 1 (max_cats < cats < fifty_break): `100 - t^2 * 50` where `t = (cats - max_cats) / (fifty_break - max_cats)`. Segment 2 (fifty_break ≤ cats < zero_break): `50 - t^2 * 50` where `t = (cats - fifty_break) / (zero_break - fifty_break)`. At or above zero_break: 0%. max_cats from `get_max_cats()` |
| `_happiness_breakpoints` | `(max_cats: int) -> Array[int]` | Private helper; returns `[fifty_break, zero_break]` for the given max_cats and current `housing_tier_index`. |
| `buy_housing_upgrade` | `() -> void` | Guards `housing_tier_index + 1 < Config.housing_tiers.size()` and `money >= cost`; deducts cost; increments `housing_tier_index` |
| `_update_paws_rate` | `() -> void` | `paws_income_rate = float(cats) * Config.onlypaws_income_per_cat * pow(2.0, manager_bots)` |

### Config (`res://Config.gd`)

Autoloaded singleton containing only `const` tuning values. No mutable state. Loaded before `GameState`.

| Constant | Type | Value | Description |
|---|---|---|---|
| `cat_food_start` | `float` | `1000.0` | Initial cat food supply |
| `cat_food_drain_rate` | `float` | `1.0` | Food drained per cat per second |
| `cat_food_pack_cost` | `float` | `10.0` | Cost per cat food pack |
| `cat_food_pack_amount` | `float` | `100.0` | Food added per cat food pack |
| `token_start` | `float` | `1000.0` | Initial token supply |
| `token_drain_per_bot` | `float` | `2.0` | Tokens drained per bot per second |
| `token_pack_cost` | `float` | `20.0` | Cost per token pack |
| `token_pack_amount` | `float` | `100.0` | Tokens added per token pack |
| `cat_cost_base` | `float` | `5.0` | Starting cost of the first cat |
| `cat_cost_growth_rate` | `float` | `1.5` | Default multiplier applied to cat cost after each purchase |
| `only_paws_unlock_cats` | `int` | `3` | Cat count that unlocks OnlyPaws |
| `only_paws_cats_per_tier` | `int` | `3` | Cats per $1/sec OnlyPaws income tier |
| `onlypaws_income_per_cat` | `float` | `0.25` | Base $/sec per cat for OnlyPaws income; at unlock (3 cats) = $0.75/sec |
| `bot_shop_unlock_cats` | `int` | `6` | Cat count that unlocks the bot shop |
| `bot_cost_base` | `float` | `50.0` | Starting cost of the first bot |
| `bot_cost_multiplier` | `float` | `2.0` | Multiplier applied to bot cost after each purchase |
| `breeder_contract_cost` | `float` | `2000.0` | Cost of the breeder contract upgrade |
| `breeder_contract_growth_rate` | `float` | `1.25` | Cat cost growth rate after breeder contract |
| `bot_manager_cost` | `float` | `40000.0` | Cost of the Manager-bot Manager upgrade |
| `bot_manager_unlock_bots` | `int` | `6` | Bot count that unlocks the Manager-bot Manager shop item |
| `bot_manager_token_threshold` | `float` | `1.0` | Token level at or below which the bot manager auto-buys a token pack |
| `auto_feeder_cost` | `float` | `20000.0` | Cost of the Auto-Feeder upgrade |
| `auto_feeder_unlock_cats` | `int` | `10` | Cat count that unlocks the Auto-Feeder shop item |
| `auto_feeder_food_threshold` | `float` | `1.0` | Food level at or below which the auto feeder buys a cat food pack |
| `base_max_cats` | `int` | `20` | Baseline cat cap before any housing upgrades; used by `get_max_cats()` |
| `housing_tiers` | `Array` | 5 entries | Housing upgrade chain; each entry has `id`, `label`, `cost`, `max_cats_increase`; costs: 0 / 10k / 30k / 120k / 480k |

### Util (`res://autoloads/Util.gd`)

Autoloaded singleton containing stateless helper functions. No mutable state.

| Function | Signature | Description |
|---|---|---|
| `format_number` | `(value: float) -> String` | Returns the integer portion of `value` formatted with comma separators (e.g. `1000.0` → `"1,000"`). Never uses scientific notation. |

---

### CatCharacter (`res://scripts/CatCharacter.gd`)

Sprite-based cat. The script is a bare `extends Node2D` with no code — all animation is handled by the `AnimatedSprite2D` child node configured in the editor.

Scene tree:
```
CatCharacter (Node2D) ← CatCharacter.gd
└── AnimatedSprite2D  ← SpriteFrames and animations set up in editor
```

---

### Main UI (`res://scenes/Main.gd`)

Drives the root scene. No mutable state lives here — reads from and delegates to `GameState`.

| Method | Description |
|---|---|
| `_ready()` | Connects `cat_purchased` → `_on_cat_purchased`; styles `CatsLabel` as hero stat (bold `SystemFont` + `1.3×` font size relative to `MoneyLabel` base) |
| `_process(delta)` | Updates all labels every frame; one-time visibility latches for `shop_unlocked`, `only_paws_unlocked`, `bot_shop_unlocked`, `home_shop_unlocked` (reveals HomeTabButton), and `bot_manager_unlocked OR auto_feeder_unlocked` (reveals UpgradesTabButton); shows `OnlyPawsPopup` and pauses tree the first time `only_paws_unlocked` triggers; updates `CatFoodLabel`; disables cat food buy buttons when `money < 10.0`; sets `OnlyPawsButton` label and modulate; `PurchaseCatButton` and `ManagerBotButton` cost labels use `Util.format_number()`; updates `HappinessBar` value and fill colour (red→green via `Color.lerp`); shows cramped/riot popups when triggered; updates housing chain display (current label green, next tier name/cost/button, or MaxTierLabel when at cap) |
| `_switch_tab` | `(tab: Tab) -> void` | Shows only the content VBox for the given `Tab` enum value; sets green modulate on the active tab button, white on the others |
| `_on_earn_money_button_pressed()` | Calls `GameState.click()` |
| `_on_purchase_cat_button_pressed()` | Calls `GameState.buy_cat()` |
| `_on_only_paws_button_pressed()` | Flips `GameState.only_paws_active`; turning OFF sets `bots_active = false`; turning ON re-enables bots if `tokens > 0` |
| `_on_only_paws_popup_ok_pressed()` | Hides `OnlyPawsPopup` and unpauses tree |
| `_on_manager_bot_button_pressed()` | Calls `GameState.buy_bot()` |
| `_on_cat_purchased()` | Instantiates `CatCharacter` at scale 0.4, adds to `CatContainer`, calls `_place_cat(cat)` |
| `_on_buy_cat_food_x1_button_pressed()` | Calls `GameState.buy_cat_food_pack(1)` |
| `_on_buy_cat_food_x10_button_pressed()` | Calls `GameState.buy_cat_food_pack(10)` |
| `_on_buy_token_x1_button_pressed()` | Calls `GameState.buy_tokens(1)` |
| `_on_buy_token_x10_button_pressed()` | Calls `GameState.buy_tokens(10)` |
| `_on_buy_bot_manager_button_pressed()` | Calls `GameState.buy_bot_manager()` |
| `_place_cat(cat: Node2D)` | Places a newly added cat at a random viewport position. Up to 30 attempts to avoid UI rects (+ 16 px padding) and existing cats (64 px radius). Falls back to ignoring cat spacing, then to unconstrained viewport position. |
| `_overlaps_ui(pos, ui_rects)` | Returns `true` if `pos` falls inside any rect in `ui_rects`. |
| `_too_close_to_cats(pos, existing_positions)` | Returns `true` if `pos` is within `CAT_SPACING_RADIUS` of any element in `existing_positions`. |

---

## Current Features

- [x] **"Work at McPawnalds" button** — manual click adds $1.0 to `money`
- [x] **Money counter** — label refreshes every frame, displayed to 2 decimal places (`$X.XX`)
- [x] **Cats counter** — label refreshes every frame showing `X/MAX` (e.g. `0/20`); MAX from `GameState.get_max_cats()` = `base_max_cats` + 10 per purchased housing tier; turns red when cats exceed MAX
- [x] **GameState singleton** — autoloaded; holds `money`, `cats`, `next_cat_cost`, `shop_unlocked`, `only_paws_unlocked`, `paws_income_rate`; emits `cat_purchased`
- [x] **Purchase Cat button** — permanently revealed (one-way latch via `shop_unlocked`) the first time `money >= next_cat_cost`; label shows live cost to 2 decimal places; cost starts at $5.00 and multiplies by `cat_cost_growth_rate` each purchase (default 1.5, reduced to 1.25 by breeder contract)
- [x] **OnlyPaws passive income** — unlocks at 3 cats; base rate `cats * 0.25` $/sec (e.g. $0.75/sec at unlock); each Manager-Bot doubles total output via `pow(2, manager_bots)`
- [x] **OnlyPaws button + income label** — revealed together when `only_paws_unlocked`; first reveal shows modal popup (pauses tree) explaining the feature
- [x] **OnlyPaws info panel** — PanelContainer with static description text (legacy node, permanently hidden)
- [x] **OnlyPaws unlock popup** — modal overlay shown once when `only_paws_unlocked` first triggers; pauses game loop; dismissed with OK button
- [x] **Cat spawning** — each purchase instances `CatCharacter` at scale 0.4 into `CatContainer`; placed at a random viewport position avoiding UI elements (16 px padding) and other cats (64 px radius); cats keep their position when new ones are added or one is lost
- [x] **Sprite-based cat character** — `CatCharacter` scene contains an `AnimatedSprite2D` child; animations configured in the Godot editor
- [x] **OnlyPaws Manager-Bot** — unlocks at 6 cats; costs $50 (doubles each purchase); each bot doubles total OnlyPaws income rate; button shows live cost, disabled when unaffordable; `BotsRateLabel` shows bot count and current rate
- [x] **OnlyPaws ON/OFF toggle** — `OnlyPawsButton` flips `only_paws_active`; income only runs while active; toggling OFF also sets `bots_active = false` stopping token drain; toggling ON re-enables bots if tokens > 0; button label and green modulate reflect state
- [x] **Upgrade stubs (GameState only)** — `buy_breeder_contract()` exists in GameState but is not wired to any UI
- [x] **Tabbed shop** — ShopPanel has three tabs in order: Currency | Upgrades | Home; active tab has green modulate; defaults to Currency on load; Upgrades tab hidden until `bot_manager_unlocked OR auto_feeder_unlocked`; Home tab hidden until `home_shop_unlocked`; tab switching via `Tab` enum in `Main.gd`
- [x] **Housing upgrade chain** — in Home tab; 4 purchasable tiers (Basic Studio is free starting state); each tier costs 3× all previous tiers combined (10k / 30k / 120k / 480k); each purchased tier adds 10 to max_cats (20 → 30 → 40 → 50 → 60); UI shows current tier (green label) + next tier (name, cost, buy button), or "Max Upgrade Reached" at cap; sliding window: always exactly one current + one next visible
- [x] **Shop panel always visible** — `ShopPanel` is shown from game start; no unlock gate
- [x] **Cat food** — `cat_food` starts at 1000; drains at `cats / 10` per second (always, not gated); clamped to 0; `CatFoodLabel` shows `floor(cat_food)` in the HUD
- [x] **Cat Food Pack shop item** — buy x1 ($10, +100 food) or x10 ($100, +1000 food); both buttons disabled when `money < 10`
- [x] **Token system** — `tokens` drains at `manager_bots * token_drain_per_bot` per second (clamped to 0); `TokensLabel` shows `floor(tokens)` in HUD; unlocks alongside Token Pack shop item on first bot purchase
- [x] **Token Pack shop item** — hidden until `tokens_shop_unlocked`; buy x1 ($20, +100 tokens) or x10 ($200, +1000 tokens); both buttons disabled when `money < 20`
- [x] **Manager-bot Manager upgrade** — hidden until `bot_manager_unlocked` (tokens hit 0 or 6 bots owned); one-time $40,000 purchase; after purchase auto-calls `buy_tokens(1)` each frame tokens fall to ≤ 1; button turns green and disables on purchase
- [x] **Auto-Feeder upgrade** — hidden until `auto_feeder_unlocked` (10+ cats or food has ever hit 0); one-time $20,000 purchase; after purchase auto-calls `buy_cat_food_pack(1)` each frame food falls to ≤ 1; button turns green and disables on purchase; description hides on purchase
- [x] **Cat Happiness** — reactive value 0–100%; 100% while cats ≤ max_cats; above max: two-segment quadratic ease-in decay scaled by housing tier. `fifty_break = max_cats + 5 + housing_tier_index` (happiness = 50%); `zero_break = max_cats + 10 + housing_tier_index * 2` (happiness = 0%). Drops from 100%→50% on segment 1 then 50%→0% on segment 2, each using `t^2` (slow start, accelerating end); always-visible progress bar at top-centre; fill colour transitions red→green via lerp; applies OnlyPaws income debuff (×0.80 below 50%, ×0.50 below 10%); riot popup appears once when happiness first hits 0%, sets `happiness_riot_triggered`
- [x] **Cramped popup** — shown once when happiness first drops to ≤ 50% (4 over max, cats = 24 with default max 20); pauses game loop; on dismiss sets `home_shop_unlocked = true`

---

## Planned Features

### Phase 1 — Core Click Loop *(in progress)*
- [x] "Work at McPawnalds" button with money counter
- [x] Purchase Cat button (gated at $100) with cat spawning
- [x] Idle/passive income (OnlyPaws: `floor(cats/3)` $/sec, unlocks at 3 cats)
- [ ] Basic UI polish (centered layout, styled labels & buttons)

### Phase 1 — Core Click Loop (continued)
- [x] OnlyPaws Manager-Bot (doubling multiplier, unlocks at 6 cats)

### Phase 2 — Upgrades
- [ ] Upgrade: increase click value (e.g. "Better Petting Technique")
- [ ] Upgrade: increase `income_per_second` (e.g. "Autonomous Purring")
- [ ] Upgrade cost system (deduct fish on purchase, disable button if unaffordable)
- [ ] Upgrade panel scene (`res://scenes/UpgradePanel.tscn`)

### Phase 3 — Generators / Passive Income
- [ ] Cat generator objects (each produces fish/sec passively)
- [ ] Generator data resource (`res://resources/GeneratorData.gd`)
- [ ] Generator list UI

### Phase 4 — Persistence
- [ ] Save/load game state to disk (`user://save.json` or binary)
- [ ] Auto-save on a timer
- [ ] Offline earnings calculation on load

### Phase 5 — Polish
- [x] Sprite-based cat character (AnimatedSprite2D)
- [ ] Click reaction animation on cat (squash/stretch or color flash)
- [ ] Fish count formatted with suffixes (K, M, B…)
- [ ] Sound effects (click, purchase)
- [ ] Settings menu (mute, reset save)
