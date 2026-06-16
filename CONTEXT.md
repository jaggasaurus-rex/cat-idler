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
├── .claude/
│   ├── agents/             # Five-stage sub-agent pipeline (see Agent Pipeline below)
│   └── skills/             # run-cat-idler skill (build/run/screenshot harness)
├── autoloads/
│   ├── GameState.gd        # Global state singleton
│   └── Util.gd             # Stateless helper functions (format_number)
├── scenes/
│   ├── CatCharacter.tscn   # Sprite-based cat (instances scripts/CatCharacter.gd; AnimatedSprite2D child)
│   ├── Main.gd             # Root scene script
│   └── Main.tscn           # Root scene
├── scripts/
│   └── CatCharacter.gd     # Cat character root (AnimatedSprite2D configured in editor)
├── CLAUDE.md               # Project instructions + Agent Pipeline workflow
├── Config.gd               # Autoloaded singleton; all static tuning constants
├── Strings.gd              # Autoloaded singleton; all user-visible text as named string consts
├── CONTEXT.md              # This file
├── DEPRECATION_AUDIT.md    # Read-only dead-code audit (orphaned nodes, inert flags)
├── ROADMAP.md              # Phase plan and design intent
└── project.godot
```

### Agent Pipeline

Five sub-agents in `.claude/agents/` run at defined points in every task (see CLAUDE.md):
`context-validator` and `pre-task-scaffolder` before starting; `gdscript-reviewer` and
`strings-guardian` after implementation, before committing; `commit-auditor` after committing.

### Autoloads

| Singleton name | Path | Purpose |
|---|---|---|
| `Util` | `res://autoloads/Util.gd` | Stateless helper functions; no mutable state |
| `Config` | `res://Config.gd` | Static tuning constants; no mutable state; referenced by GameState and Main |
| `Strings` | `res://Strings.gd` | All user-visible text as named string consts (54 of them); registered after Config, before GameState; `Config.RESEARCH_ITEMS` references its research-name consts and Main.gd pulls every label/popup/button string from here |
| `GameState` | `res://autoloads/GameState.gd` | Holds all persistent game state; the single source of truth for currency and rates |

### Scene structure

```
Main (Control, full-rect)             ← Main.gd
├── TextureRect                       ← full-screen lofi-studio background image (res://assets/lofi-studio.png)
├── CatContainer (Node2D)             ← pos (576, 530); purchased cats added here; placed second so cats render above the background and below all UI
├── CatsLabel (Label)                 ← section header; positioned first (top=20); styled via _style_as_header() in _ready() (UI_HEADER_FONT_SIZE 28 + bold); updated every _process() frame; text format "Cats: X/MAX" where MAX = happiness threshold; modulate = RED when cats > MAX, WHITE otherwise
├── MoneyLabel (Label)                ← updated every _process() frame
├── EarnMoneyButton (Button)          ← directly below MoneyLabel (offset_top=95); pressed → GameState.click()
├── PurchaseCatButton (Button)        ← directly below EarnMoneyButton (offset_top=130); always visible from game start; label updates every frame
├── OnlyPawsButton (Button)           ← permanently shown once only_paws_unlocked; toggles only_paws_active;
│                                       label = "OnlyPaws: ON/OFF"; green modulate when active
├── OnlyPawsIncomeLabel (Label)       ← shown with OnlyPawsButton; "OnlyPaws: $X.XX/sec" updates every frame
├── CatFoodLabel (Label)              ← directly below PurchaseCatButton (offset_top=165); hidden until cats_ever_purchased >= 1 (one-way latch); "Cat Food: X" where X = floor(cat_food); updated every frame
├── BuyCatFoodButton (Button "Buy Food ($N)") ← directly below CatFoodLabel (offset_top=197); revealed with CatFoodLabel; calls buy_cat_food_pack(1); when auto_feeder_purchased, label reads live cost each frame via GameState.get_cat_food_pack_cost() with ∞ suffix
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
├── ManagerBotButton (Button)         ← hidden until bot_shop_unlocked; label shows live cost
├── MegaManagerBotButton (Button)     ← at offset_top=380; hidden until research_complete["ai_model_upgrade"]; "Mega-Bot ($X)" label, disabled when unaffordable; pressed → buy_mega_bot()
├── BotTokenRow (HBoxContainer)       ← layout_mode=0 at offset_top=350; always visible; contains BotsRateLabel, TokensLabel, and MegaBotsRateLabel side by side with 16px separation
│   ├── BotsRateLabel (Label)         ← hidden until bot_shop_unlocked; "Bots: X" updates every frame
│   ├── TokensLabel (Label)           ← hidden until tokens_shop_unlocked; "Tokens: X" updates every frame
│   └── MegaBotsRateLabel (Label)     ← hidden until MegaManagerBotButton is visible; "Mega-Bots: X" updates every frame
├── BuyTokensButton (Button "Buy Tokens ($N)") ← hidden until tokens_shop_unlocked; calls buy_tokens(1); when bot_manager_purchased, label reads live cost each frame via GameState.get_token_pack_cost() with ∞ suffix
├── CenterColumn (VBoxContainer)      ← fixed pos offset_left=430, offset_top=110, offset_right=830, offset_bottom=600; hidden until housing_tier_index >= 1 (one-way latch in Main.gd._process()); contains research UI
│   ├── ResearchTitle (Label)         ← static "Research" heading
│   ├── ResearchActiveLabel (Label)   ← "No Active Research" or active item name; updated every frame
│   ├── ResearchProgressBar (ProgressBar) ← min=0 max=1; value = points / points_cost of active funded item; 0.0 when none; updated every frame
│   ├── CatIntelligenceLabel (Label)  ← created programmatically in _ready(), inserted at index 1 (after ResearchTitle); hidden until one-way latch fires when GameState.research_complete["cat_power_unite"] is true; text = "Cat Intelligence: X" updated each frame while visible
│   ├── ResearchSlider (HSlider)      ← min=0 max=1 step=0.01; hidden in _ready(); revealed by one-way latch when GameState.research_funded.size() > 0; value_changed → GameState.research_cat_fraction
│   ├── SliderLabels (HBoxContainer)  ← static orientation hints
│   │   ├── OnlyPawsHint (Label "OnlyPaws") ← left side hint
│   │   └── ResearchHint (Label "Research") ← right-aligned hint
│   ├── ResearchCatsLabel (Label)     ← "Cats researching: X"; updated every frame from GameState.get_research_cats()
│   └── ResearchItemList (VBoxContainer) ← children built dynamically in Main.gd _ready() from Config.RESEARCH_ITEMS; each child is a PanelContainer → VBoxContainer → NameLabel + DescriptionLabel (autowrap) + FundButton + ProgressLabel (hidden until funded); refs stored in _research_panels/_research_fund_buttons/_research_progress_labels dicts keyed by item id. Panel visibility is governed by `_refresh_research_slots()` (a **queued slot system**, not per-item latches): panels appear one at a time in RESEARCH_ITEMS order, subject first to a **global gate** — until `research_complete["cat_power_unite"]` is true, every item except `cat_power_unite` is skipped regardless of its other gates, so the first research item must be fully completed before any other panel can populate (the `cat_power_unite` panel itself stays exempt so it can be funded and completed). Beyond that gate each item is gated by housing tier (`min_housing_tier`), a predecessor-complete gate (every lower-index item must be in `research_complete`), an optional OR unlock gate (when an item declares `unlock_requires_cats` and/or `unlock_requires_research`, it stays hidden until EITHER `GameState.cats >= unlock_requires_cats` OR `research_complete[unlock_requires_research]` — additive to, not a replacement for, the predecessor gate), and a `Config.RESEARCH_MAX_VISIBLE` (4) cap on simultaneously visible panels. The first item is eligible from start; later items only become eligible once all predecessors finish. Showing a panel is a one-way latch (sets `_research_panel_unlocked[id]`); completion hides the panel (`_research_panel_hidden[id] = true`) and immediately frees a slot. Called every frame from `_process()`, at the end of `_ready()`, and right after each completion in `_on_research_completed()`
├── ShopPanel (VBoxContainer)         ← right-anchored, always visible; offset_left=-380, offset_right=-10 (370px wide)
│   ├── ShopLabel (Label "Shop")
│   └── ShopScroll (ScrollContainer) ← fills remaining ShopPanel height; size_flags_vertical=3
│       └── ShopList (VBoxContainer) ← single item list; size_flags_horizontal=3; separation=8; sorted ascending by cost each time visibility changes
│           ├── HousingButton (Button) ← hidden until home_shop_unlocked; text = next tier name + cost; disappears when max tier reached; calls buy_housing_upgrade()
│           ├── AutoFeederButton (Button) ← hidden until auto_feeder_unlocked; disappears on purchase; calls buy_auto_feeder()
│           ├── BotManagerShopButton (Button) ← hidden until bot_manager_unlocked; disappears on purchase; calls buy_bot_manager()
│           ├── (dynamic) _pawsco_membership_button / _ai_enterprise_membership_button (Button) ← created in _ready() and added to ShopList; hidden until bot_manager_unlocked; disappear on purchase
│           └── (dynamic) _robo_sweeper_button (Button) ← created in _ready() and added to ShopList; hidden until research_complete["robo_shit_sweeper"]; disappears when robo_sweeper_purchased; text = BTN_ROBO_SWEEPER; calls buy_robo_sweeper()
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
├── BotManagerUnlockPopup (ColorRect) ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when bot_manager_unlocked first becomes true (gated by GameState.bot_manager_unlock_popup_shown); placeholder text "New upgrade available: Manager-Bot Manager."; pauses tree; dismiss unpauses only
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
| `only_paws_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_cat()` when `cats >= 3` |
| `paws_income_rate` | `float` | `0.0` | Cached passive $/sec; recalculated by `update_paws_rate()` after each cat/bot/mega-bot purchase, cat loss, **and whenever the research slider moves** (the slider changes `research_cat_fraction` → `get_onlypaws_cats()`, so the rate must be refreshed or it goes stale) |
| `manager_bots` | `int` | `0` | Number of Manager-Bots purchased; each one adds `Config.onlypaws_income_per_bot` ($0.50) to the per-cat income rate; formula: `cats * (0.25 + 0.50 * manager_bots)` |
| `next_bot_cost` | `float` | `Config.bot_cost_base` | Cost of the next bot; multiplied by `Config.bot_cost_multiplier` after every successful purchase |
| `mega_bots` | `int` | `0` | Number of Mega Manager-Bots purchased (unlocked by the `ai_model_upgrade` research); each adds `Config.MEGA_BOT_INCOME_PER_CAT` ($1.00) to the per-cat income rate and drains `Config.MEGA_BOT_TOKEN_DRAIN` (4.0) tokens/sec |
| `next_mega_bot_cost` | `float` | `Config.MEGA_BOT_COST_BASE` | Cost of the next mega bot ($100 base); multiplied by `Config.bot_cost_multiplier` after every successful purchase |
| `bot_shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_cat()` when `cats >= 6` |
| `only_paws_active` | `bool` | `false` | Player-toggled; set to `true` once at unlock in `buy_cat()`; income only ticks when `true` and `cat_food > 0`; toggling OFF also sets `bots_active = false`; toggling ON re-enables bots if tokens > 0 |
| `cat_cost_growth_rate` | `float` | `Config.cat_cost_growth_rate` | Multiplier applied to `next_cat_cost` each purchase; reduced to `Config.breeder_contract_growth_rate` by breeder contract |
| `breeder_purchased` | `bool` | `false` | One-way latch; set by `buy_breeder_contract()` |
| `housing_tier_index` | `int` | `0` | Current housing upgrade tier (0 = Basic Studio). Incremented by `buy_housing_upgrade()`. Replaces the former `cat_trees_purchased` bool; tier >= 1 is equivalent |
| `tokens` | `float` | `Config.token_start` | Token supply; drains at `(manager_bots * Config.token_drain_per_bot) + (mega_bots * Config.MEGA_BOT_TOKEN_DRAIN)` per second while `bots_active`; never below 0 |
| `bots_active` | `bool` | `true` | Set to `false` when tokens reach 0; re-enabled by `buy_tokens()` if tokens > 0 after purchase; gates token drain; when `false` income falls back to no-bot base rate (`get_onlypaws_cats() * onlypaws_income_per_cat`) rather than stopping entirely |
| `tokens_shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_bot()` when `manager_bots >= 1` |
| `bot_manager_unlocked` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `tokens <= 0` or `manager_bots >= Config.bot_manager_unlock_bots` |
| `bot_manager_purchased` | `bool` | `false` | One-way latch; set by `buy_bot_manager()`; enables auto-token-purchase in `_process()` |
| `food_hit_zero` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `cat_food <= 0`; used as second unlock trigger for Auto-Feeder |
| `auto_feeder_unlocked` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `cats >= 10` or `food_hit_zero` |
| `auto_feeder_purchased` | `bool` | `false` | One-way latch; set by `buy_auto_feeder()`; enables auto-food-purchase in `_process()` |
| `pawsco_membership_purchased` | `bool` | `false` | One-way latch; set by `buy_pawsco_membership()`; activates discounted cat food pack price |
| `ai_enterprise_purchased` | `bool` | `false` | One-way latch; set by `buy_ai_enterprise_membership()`; activates discounted token pack price |
| `robo_sweeper_purchased` | `bool` | `false` | One-way latch; set by `buy_robo_sweeper()` once `research_complete["robo_shit_sweeper"]` is true and the player can afford `Config.ROBO_SWEEPER_PURCHASE_COST`. When true, Main.gd's `_process_sweeper()` activates the Robo-Shit Sweeper device (a Node2D that autonomously moves to and removes poops); also gates the shop button's disappearance |
| `first_cat_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `cats >= 1`; gates the first-cat achievement popup so it fires exactly once |
| `starvation_count` | `int` | `0` | Increments each time the starvation condition transitions from inactive to active (cat_food <= 0 AND money < 10) |
| `starvation_active` | `bool` | `false` | Frame-level debounce; `true` while the starvation condition persists; resets when cat_food > 0 or money >= 10 |
| `starvation_cats_lost` | `int` | `0` | Tracks cats lost specifically via the starvation mechanic; used in game-over condition |
| `cats_ever_purchased` | `int` | `0` | Lifetime cat purchase counter; incremented in `buy_cat()`; used to gate game-over so it only triggers if the player has owned at least one cat |
| `happiness_cramped_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `cats >= Config.HOUSING_UPGRADE_PROMPT_THRESHOLD` (8 cats); used by Main.gd to show the cramped popup once |
| `happiness_riot_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `get_happiness() <= 0.0` (6 over max, e.g. cats = 26 with default max 20); used by Main.gd to show the riot popup once |
| `happiness_zero_count` | `int` | `0` | Counts distinct edge-transitions into happiness=0% (i.e. increments each time happiness drops from >0 to 0, tracked via `_happiness_was_zero`); used to gate `cat_crusher_triggered` on count >= 2 |
| `cat_crusher_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `happiness_zero_count >= 2`; used by Main.gd to show the Cat Crusher popup once |
| `cat_crusher_unlocked` | `bool` | `false` | Set to `true` in Main.gd when the Cat Crusher popup is dismissed; activates cat loss drain and the HappinessBar 20% marker |
| `poop_count` | `int` | `0` | Number of uncleaned poops currently on screen. Incremented by Main.gd `_spawn_poop()` each time a cat poops, decremented (clamped at 0) by `_on_poop_pressed()` when the player clicks a poop. Drives `get_happiness()`: happiness decays quadratically with the `poop_count / cats` ratio toward `Config.POOP_MAX_RATIO`. |
| `_happiness_was_zero` | `bool` | `false` | Private edge-detection helper; holds whether the previous frame had happiness <= 0; used to count distinct transitions for `happiness_zero_count` |
| `_cat_loss_active` | `bool` | `false` | Private; `true` while the cat loss drain is running; set to `true` when `cat_crusher_unlocked AND happiness <= 20%`; cleared when `happiness > 60%` (`Config.happiness_cat_loss_deactivate`) |
| `_cat_loss_timer` | `float` | `0.0` | Private accumulator; seconds elapsed since last cat loss tick; resets on drain start/stop and each 10-second fire |
| `home_shop_unlocked` | `bool` | `false` | Set to `true` in Main.gd when the cramped popup is dismissed; no longer gates Home tab visibility (tab now uses `HOUSING_UPGRADE_PROMPT_THRESHOLD` directly) |
| `upgrades_tab_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `bot_manager_unlocked OR auto_feeder_unlocked`; gates the Upgrades tab achievement popup so it fires exactly once |
| `bot_unlock_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `bot_shop_unlocked`; gates the "Cat Harem" achievement popup so it fires exactly once |
| `bot_manager_unlock_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `bot_manager_unlocked`; gates the Manager-Bot Manager unlock popup so it fires exactly once |
| `research_cat_fraction` | `float` | `0.0` | 0.0 = all cats on OnlyPaws; 1.0 = all cats on research; drives `get_research_cats()` and `get_onlypaws_cats()` |
| `research_funded` | `Dictionary` | `{}` | id → bool; true once `fund_research()` has been paid for that item |
| `research_points` | `Dictionary` | `{}` | id → float; accumulated research-cat-seconds for each funded item |
| `research_complete` | `Dictionary` | `{}` | id → bool; true once an item's `points_cost` has been reached (named `research_complete` rather than `research_completed` to avoid clash with the signal) |
| `cat_intelligence` | `int` | `0` | Incremented at research completion by each item's `cat_intelligence_gain` field from `Config.RESEARCH_ITEMS`; currently +1 when `cat_power_unite` finishes. Also gains passively while cats are assigned to research with no active research item — see `_idle_intel_accumulator` |
| `_idle_intel_accumulator` | `float` | `0.0` | Fractional accumulator for passive idle-research intelligence. Each `_process` tick, when `get_active_research_id() == "" and get_research_cats() > 0 and research_complete["cat_power_unite"]` (gated on the first research item being complete), adds `get_research_cats() * Config.IDLE_RESEARCH_INTEL_RATE * delta` (1/600 pt/cat/sec = 1 pt per cat per 10 min); whole points are banked into `cat_intelligence` and subtracted off. Resets to 0 whenever a research item is active or no cats are researching |
| `_viral_delay_timer` | `float` | `0.0` | Private accumulator; counts up in `_process()` once `manager_bots >= 2` toward the 20s viral-bubble unlock delay |
| `viral_bubbles_unlocked` | `bool` | `false` | One-way latch; set to `true` in `_process()` when `manager_bots >= 2` and `_viral_delay_timer >= 20.0`; gates all bubble spawning in Main.gd `_try_spawn_bubble_for_cat()` |
| `viral_popup_shown` | `bool` | `false` | One-way latch; set to `true` by the Main.gd `_process()` popup latch the instant `viral_bubbles_unlocked` flips, which shows the whale popup |
| `inspiration_popup_shown` | `bool` | `false` | One-way latch; set to `true` by Main.gd `_on_bubble_pressed()` the first time an inspiration (💡) bubble is collected, which shows the one-time inspiration popup |

| Signal | Description |
|---|---|
| `cat_purchased` | Emitted by `buy_cat()` after a successful purchase |
| `cat_lost` | Emitted by `_lose_cat()` each time a cat is removed by the drain; Main.gd removes the last CatCharacter node from CatContainer |
| `research_completed(id: String)` | Emitted by `_process()` the frame a research item finishes accumulating its required points |

| Method | Signature | Description |
|---|---|---|
| `_ready` | `() -> void` | Sets `process_mode = PROCESS_MODE_ALWAYS` so income ticks even while tree is paused |
| `_process` | `(delta) -> void` | Always drains `cat_food`; sets `food_hit_zero` the first time food reaches 0; checks and sets `auto_feeder_unlocked`; if `auto_feeder_purchased` and food low: calls `buy_cat_food_pack(1)`; if `bots_active`: drains tokens, sets `bots_active = false` when tokens reach 0; checks and sets `bot_manager_unlocked`; if `bot_manager_purchased` and tokens low: calls `buy_tokens(1)`; sets `happiness_riot_triggered` the first time `get_happiness() <= 0`; tracks `happiness_zero_count` via edge detection and sets `cat_crusher_triggered` on count >= 2; caches `get_happiness()` once per tick into a local `happiness` reused by all happiness checks below; runs cat loss drain when `cat_crusher_unlocked` (activates at happiness ≤ `Config.happiness_cat_loss_activate`, fires immediately then every 10s, deactivates at happiness > `Config.happiness_cat_loss_deactivate`); if `only_paws_active and cat_food > 0.0`: earns `effective_rate * happiness_multiplier * delta` where `happiness_multiplier = Config.happiness_income_floor + (happiness / 100.0) * Config.happiness_income_range` and `effective_rate = paws_income_rate` when `bots_active`, else `float(get_onlypaws_cats()) * Config.onlypaws_income_per_cat` (no-bot base rate); income stops when food reaches 0; income continues at the no-bot rate when tokens run out — bots only affect token drain and the multiplier, not the income gate; research tick: for each funded, incomplete item in `Config.RESEARCH_ITEMS`, adds `get_research_cats() * delta` to `research_points[id]` (skips items with `min_cats_required > get_research_cats()`); clamps and completes when `points_cost` is reached, emits `research_completed(id)`; idle-research intelligence: after the research tick, when `get_active_research_id() == "" and get_research_cats() > 0 and research_complete["cat_power_unite"]` (gated until the first research item completes), accumulates `get_research_cats() * Config.IDLE_RESEARCH_INTEL_RATE * delta` into `_idle_intel_accumulator`, banking whole points into `cat_intelligence` (resets the accumulator to 0 otherwise); viral unlock: once `manager_bots >= 2`, accumulates `_viral_delay_timer` and sets `viral_bubbles_unlocked = true` after 20s |
| `_lose_cat` | `() -> void` | Private; decrements `cats` (clamped, no-ops at 0), calls `update_paws_rate()`, emits `cat_lost` |
| `click` | `() -> void` | Adds `1.0` to `money` |
| `buy_cat` | `() -> void` | Guards `money >= next_cat_cost`, then a **hard cap guard** (`cats >= get_max_cats()` → no-op) so the player can never exceed the current housing tier's cat limit; deducts cost, increments `cats`, applies `cat_cost_growth_rate`, sets `only_paws_unlocked` when `cats >= 3`, sets `bot_shop_unlocked` when `cats >= 6`, calls `update_paws_rate()`, emits `cat_purchased`. (The former `get_happiness() <= 0.0` purchase guard was removed in favor of the hard cat cap above.) |
| `buy_bot` | `() -> void` | Guards `money >= next_bot_cost`, deducts cost, increments `manager_bots`, multiplies `next_bot_cost` by `Config.bot_cost_multiplier` (1.6×), calls `update_paws_rate()`, sets `tokens_shop_unlocked = true` when `manager_bots >= 1` |
| `buy_mega_bot` | `() -> void` | Guards `money >= next_mega_bot_cost`, deducts cost, increments `mega_bots`, multiplies `next_mega_bot_cost` by `Config.bot_cost_multiplier` (1.6×), calls `update_paws_rate()` |
| `get_cat_food_packs_affordable` | `() -> int` | Returns `int(money / 10.0)` |
| `grant_cat_food_pack` | `() -> void` | Adds `Config.cat_food_pack_amount` food at no cost; used for starvation pity rewards |
| `starvation_lose_cat` | `() -> void` | Removes one cat as a starvation penalty: decrements `cats` (clamped), calls `update_paws_rate()`, increments `starvation_cats_lost`, emits `cat_lost` |
| `buy_cat_food_pack` | `(quantity: int) -> void` | Guards `money >= 10.0 * quantity`; deducts cost; adds `100.0 * quantity` to `cat_food` |
| `buy_tokens` | `(quantity: int) -> void` | Guards `money >= Config.token_pack_cost * quantity`; deducts cost; adds `Config.token_pack_amount * quantity` to `tokens`; sets `bots_active = true` if `tokens > 0` |
| `buy_bot_manager` | `() -> void` | Guards `money >= Config.bot_manager_cost and not bot_manager_purchased`; deducts cost; sets `bot_manager_purchased = true` |
| `buy_auto_feeder` | `() -> void` | Guards `money >= Config.auto_feeder_cost and not auto_feeder_purchased`; deducts cost; sets `auto_feeder_purchased = true` |
| `get_cat_food_pack_cost` | `() -> float` | Returns `Config.cat_food_pack_cost_discounted` if `pawsco_membership_purchased`, else `Config.cat_food_pack_cost`; used by `buy_cat_food_pack`, starvation check, `get_cat_food_packs_affordable` |
| `get_token_pack_cost` | `() -> float` | Returns `Config.token_pack_cost_discounted` if `ai_enterprise_purchased`, else `Config.token_pack_cost`; used by `buy_tokens` |
| `buy_pawsco_membership` | `() -> void` | Guards `money >= Config.pawsco_membership_cost and not pawsco_membership_purchased`; deducts cost; sets `pawsco_membership_purchased = true` |
| `buy_ai_enterprise_membership` | `() -> void` | Guards `money >= Config.ai_enterprise_membership_cost and not ai_enterprise_purchased`; deducts cost; sets `ai_enterprise_purchased = true` |
| `buy_robo_sweeper` | `() -> void` | No-ops if already purchased, `research_complete["robo_shit_sweeper"]` is false, or `money < Config.ROBO_SWEEPER_PURCHASE_COST`; otherwise deducts the cost and sets `robo_sweeper_purchased = true` |
| `buy_breeder_contract` | `() -> void` | Guards `money >= 2000 and not breeder_purchased`; sets `cat_cost_growth_rate = 1.25`; retroactively recalculates `next_cat_cost = 5.0 * pow(1.25, cats)` |
| `get_max_cats` | `() -> int` | Returns `Config.base_max_cats` plus the sum of `max_cats_increase` for each purchased housing tier (1..housing_tier_index) |
| `get_happiness` | `() -> float` | **Poop-driven happiness.** Returns `100.0` if `cats <= 0` or `poop_count <= 0`; otherwise `100 * (1 - t^2)` where `t = clamp((poop_count / cats) / Config.POOP_MAX_RATIO, 0, 1)`. Happiness falls quadratically as the poop-per-cat ratio rises toward `Config.POOP_MAX_RATIO` (3.0 = 0% happiness). Scales to any cat count: 1 poop/cat ≈ 89%, 2/cat ≈ 56%, 3/cat = 0%. Feeds the income multiplier in `_process()` and the happiness bar in Main.gd. (Replaced the earlier flat-100 stub; the original over-max two-segment quadratic decay remains removed.) The hard cat cap in `buy_cat()` (`cats >= get_max_cats()`) is still in place. Because happiness can reach 0% (poop-per-cat ratio ≥ `Config.POOP_MAX_RATIO`), the dependent systems — `happiness_riot_triggered`, `cat_crusher_triggered`, and the cat-loss drain — are reachable and active. |
| `_happiness_breakpoints` | `(max_cats: int) -> Array[int]` | Private helper; returns `[fifty_break, zero_break]` for the given max_cats and current `housing_tier_index`. **Currently unused** — kept in place for when the happiness mechanic is redesigned. |
| `buy_housing_upgrade` | `() -> void` | Guards `housing_tier_index + 1 < Config.housing_tiers.size()` and `money >= cost`; deducts cost; increments `housing_tier_index` |
| `get_active_research_id` | `() -> String` | Iterates `Config.RESEARCH_ITEMS` in order; returns the id of the first item that is funded but not complete, or `""` if none. Used by Main.gd bubble spawning to pick bubble type |
| `get_research_cats` | `() -> int` | Returns `floor(cats * research_cat_fraction)`; number of cats assigned to research |
| `get_onlypaws_cats` | `() -> int` | Returns `cats - get_research_cats()`; number of cats contributing to OnlyPaws income |
| `fund_research` | `(id: String) -> void` | Finds item in `Config.RESEARCH_ITEMS` by id; if `money >= fund_cost` and not yet funded: deducts cost, sets `research_funded[id] = true`, initialises `research_points[id] = 0.0` |
| `update_paws_rate` | `() -> void` | Public (renamed from `_update_paws_rate`). `paws_income_rate = float(get_onlypaws_cats()) * (onlypaws_income_per_cat + onlypaws_income_per_bot * manager_bots + MEGA_BOT_INCOME_PER_CAT * mega_bots)` — base $0.25/cat/sec plus $0.50/cat/sec per normal bot plus $1.00/cat/sec per mega bot; 10 cats: 0 bots=$2.50/s, 1 bot=$7.50/s, 2 bots=$12.50/s; 10 cats / 1 normal / 1 mega = $17.50/s. Must be called by any caller that changes cat count, bot/mega-bot count, or `research_cat_fraction` (e.g. Main's `_on_research_slider_value_changed`) |

### Config (`res://Config.gd`)

Autoloaded singleton containing only `const` tuning values. No mutable state. Loaded before `GameState`.

| Constant | Type | Value | Description |
|---|---|---|---|
| `RESEARCH_ITEMS` | `Array` | 3 entries | Research item definitions. Each entry: `{id, name, subtitle, description, fund_cost: float, points_cost: float, min_cats_required: int, cat_intelligence_gain: int, min_housing_tier: int}`; some entries add optional `unlock_requires_cats: int` / `unlock_requires_research: String` keys (see below). `min_housing_tier` is one of the gates on panel visibility in Main.gd's `_refresh_research_slots()` queued slot system (housing-tier gate + predecessor-complete gate + optional OR unlock gate + `Config.RESEARCH_MAX_VISIBLE` cap); see the ResearchItemList note above. Items: `cat_power_unite` ($1,000 fund, 200 pts, 10 cats, +1 cat_intelligence, min_housing_tier 0); `ai_model_upgrade` ($2,000 fund, 1,200 pts, 1 cat, +0 cat_intelligence, min_housing_tier 1; unlocks Mega Manager-Bots, fires the "AI Overlords" popup on completion); and `robo_shit_sweeper` ($4,000 fund / `ROBO_SWEEPER_FUND_COST`, 2,400 pts / `ROBO_SWEEPER_POINTS_COST`, 1 cat, +0 cat_intelligence, min_housing_tier 0). `robo_shit_sweeper` carries `unlock_requires_cats: 25` and `unlock_requires_research: "ai_model_upgrade"`, meaning its panel only appears once EITHER `GameState.cats >= 25` OR `research_complete["ai_model_upgrade"]` (OR, not AND); completing it gates the Robo-Shit Sweeper shop button (purchase cost `ROBO_SWEEPER_PURCHASE_COST` $10,000). The `name`/`subtitle`/`description` values reference `Strings.RESEARCH_*` consts rather than inline literals. |
| `cat_food_start` | `float` | `1000.0` | Initial cat food supply |
| `cat_food_drain_rate` | `float` | `1.0` | Food drained per cat per second |
| `cat_food_pack_cost` | `float` | `10.0` | Cost per cat food pack |
| `cat_food_pack_amount` | `float` | `100.0` | Food added per cat food pack |
| `token_start` | `float` | `1000.0` | Initial token supply |
| `token_drain_per_bot` | `float` | `2.0` | Tokens drained per bot per second |
| `MEGA_BOT_COST_BASE` | `float` | `100.0` | Base cost of the first Mega Manager-Bot (double `bot_cost_base`) |
| `MEGA_BOT_INCOME_PER_CAT` | `float` | `1.0` | Added $/cat/sec per mega bot (double `onlypaws_income_per_bot`) |
| `MEGA_BOT_TOKEN_DRAIN` | `float` | `4.0` | Tokens drained per mega bot per second (double `token_drain_per_bot`) |
| `token_pack_cost` | `float` | `20.0` | Cost per token pack |
| `token_pack_amount` | `float` | `100.0` | Tokens added per token pack |
| `cat_cost_base` | `float` | `5.0` | Starting cost of the first cat |
| `cat_cost_growth_rate` | `float` | `1.3` | Default multiplier applied to cat cost after each purchase |
| `only_paws_unlock_cats` | `int` | `3` | Cat count that unlocks OnlyPaws |
| `only_paws_cats_per_tier` | `int` | `3` | Cats per $1/sec OnlyPaws income tier |
| `onlypaws_income_per_cat` | `float` | `0.25` | Base $/sec per cat for OnlyPaws income; at unlock (3 cats) = $0.75/sec |
| `onlypaws_income_per_bot` | `float` | `0.50` | Additional $/sec per cat added per bot; stacks additively with base rate |
| `bot_shop_unlock_cats` | `int` | `6` | Cat count that unlocks the bot shop |
| `bot_cost_base` | `float` | `50.0` | Starting cost of the first bot |
| `bot_cost_multiplier` | `float` | `1.6` | Multiplier applied to bot cost after each purchase |
| `breeder_contract_cost` | `float` | `2000.0` | Cost of the breeder contract upgrade |
| `breeder_contract_growth_rate` | `float` | `1.25` | Cat cost growth rate after breeder contract |
| `bot_manager_cost` | `float` | `4000.0` | Cost of the Manager-bot Manager upgrade |
| `bot_manager_unlock_bots` | `int` | `6` | Bot count that unlocks the Manager-bot Manager shop item |
| `bot_manager_token_threshold` | `float` | `1.0` | Token level at or below which the bot manager auto-buys a token pack |
| `auto_feeder_cost` | `float` | `2000.0` | Cost of the Auto-Feeder upgrade |
| `auto_feeder_unlock_cats` | `int` | `10` | Cat count that unlocks the Auto-Feeder shop item |
| `auto_feeder_food_threshold` | `float` | `1.0` | Food level at or below which the auto feeder buys a cat food pack |
| `pawsco_membership_cost` | `float` | `800.0` | Cost of the PawsCo Membership upgrade |
| `cat_food_pack_cost_discounted` | `float` | `9.0` | Cat food pack cost after PawsCo membership purchased |
| `ai_enterprise_membership_cost` | `float` | `1000.0` | Cost of the AI Enterprise Membership upgrade |
| `token_pack_cost_discounted` | `float` | `15.0` | Token pack cost after AI Enterprise membership purchased |
| `ROBO_SWEEPER_FUND_COST` | `float` | `4000.0` | Fund cost of the `robo_shit_sweeper` research item |
| `ROBO_SWEEPER_POINTS_COST` | `float` | `2400.0` | Research points to complete `robo_shit_sweeper` (2× `ai_model_upgrade`'s 1,200) |
| `ROBO_SWEEPER_PURCHASE_COST` | `float` | `10000.0` | Money cost to buy the Robo-Shit Sweeper shop upgrade once its research completes |
| `base_max_cats` | `int` | `10` | Baseline cat cap before any housing upgrades; used by `get_max_cats()` |
| `HOUSING_UPGRADE_PROMPT_THRESHOLD` | `int` | `8` | Cat count that fires the "cats are cramped" popup and reveals the Home tab; shared by GameState._process() and Main.gd._process() |
| `happiness_fifty_break_offset` | `int` | `2` | Cats over max_cats where happiness hits 50% (before housing bonus); ratio 2:5 with zero_break_offset |
| `happiness_zero_break_offset` | `int` | `5` | Cats over max_cats where happiness hits 0% (before housing bonus); ratio 2:5 with fifty_break_offset |
| `happiness_cat_loss_activate` | `float` | `20.0` | Happiness % at/below which the cat-loss drain turns on; read by GameState._process() |
| `happiness_cat_loss_deactivate` | `float` | `60.0` | Happiness % above which the cat-loss drain turns off; read by GameState._process() |
| `happiness_income_floor` | `float` | `0.30` | OnlyPaws income multiplier at 0% happiness; read by GameState._process() |
| `happiness_income_range` | `float` | `0.70` | Multiplier range added linearly on top of the floor up to 100% happiness; read by GameState._process() |
| `housing_tiers` | `Array` | 5 entries | Housing upgrade chain; each entry has `id`, `label`, `cost`, `max_cats_increase`; costs: 0 / 500 / 3.5k / 11.5k / 46k; tier 1 label is "Luxury Cat Trees" |
| `BUBBLE_SPAWN_MIN` | `float` | `5.0` | Minimum seconds of a per-cat bubble cooldown; each cat picks a fresh random cooldown in `[MIN, MAX]` after every attempt; read by Main.gd `_process()` and `_on_cat_purchased()` |
| `BUBBLE_SPAWN_MAX` | `float` | `15.0` | Maximum seconds of a per-cat bubble cooldown (see `BUBBLE_SPAWN_MIN`) |
| `BUBBLE_LIFETIME` | `float` | `4.5` | Seconds a bubble lives before fading out and being removed |
| `BUBBLE_MAX_ON_SCREEN` | `int` | `4` | Cap on simultaneous active bubbles; spawn is skipped at the cap |
| `BUBBLE_VIRAL_MULTIPLIER` | `float` | `4.0` | Viral bubble reward = `paws_income_rate × this` (min 1.0) |
| `BUBBLE_INSPIRATION_SECONDS` | `float` | `3.0` | Inspiration bubble reward = `get_research_cats() × this` research points (min 1.0) |
| `BUBBLE_GLOBAL_CD_MIN` | `float` | `20.0` | Min seconds of the idle cooldown between burst windows; read by Main.gd `_process()` |
| `BUBBLE_GLOBAL_CD_MAX` | `float` | `40.0` | Max seconds of the idle cooldown between burst windows |
| `BUBBLE_BURST_WINDOW_MIN` | `float` | `2.0` | Min seconds a burst window stays open (per-cat timers may fire) |
| `BUBBLE_BURST_WINDOW_MAX` | `float` | `10.0` | Max seconds a burst window stays open |
| `POOP_SPAWN_MIN` | `float` | `30.0` | Min seconds of a per-cat poop cooldown; each cat independently picks a fresh `randf_range(MIN, MAX)` after every poop; read by Main.gd `_process()` and `_on_cat_purchased()` |
| `POOP_SPAWN_MAX` | `float` | `90.0` | Max seconds of a per-cat poop cooldown (see `POOP_SPAWN_MIN`) |
| `POOP_MAX_RATIO` | `float` | `3.0` | Poop-per-cat ratio (`poop_count / cats`) at which `get_happiness()` reaches 0%. Happiness = `100 * (1 - (ratio/3)^2)`: ratio 1.0 ≈ 89%, 2.0 ≈ 56%, 3.0 = 0% |
| `SWEEPER_MOVE_SPEED` | `float` | `80.0` | Robo-Shit Sweeper travel speed (px/sec); read by Main.gd `_process_sweeper()` in the MOVING state |
| `SWEEPER_CLEAN_DELAY` | `float` | `1.5` | Seconds the sweeper lingers on a poop before removing it (CLEANING state) |
| `CAT_MOVE_SPEED` | `float` | `40.0` | Pixels per second a cat walks toward its wander target; read by CatCharacter.gd |
| `CAT_WANDER_MIN` | `float` | `25.0` | Min seconds between a cat's movement decisions |
| `CAT_WANDER_MAX` | `float` | `60.0` | Max seconds between a cat's movement decisions |
| `RESEARCH_MAX_VISIBLE` | `int` | `4` | Max research panels shown at once by Main.gd's `_refresh_research_slots()` queued slot system |
| `UI_BASE_FONT_SIZE` | `int` | `22` | Global fallback font size (set on `ThemeDB.fallback_font_size` in `_ready()`); all labels/buttons inherit it; bubble glyphs use `roundi(UI_BASE_FONT_SIZE * 2.2)` |
| `UI_HEADER_FONT_SIZE` | `int` | `28` | Section-header font size (larger + bold) applied by `_style_as_header()` to CatsLabel, the happiness title, and the Shop label |

### Strings (`res://Strings.gd`)

Autoloaded singleton holding **every user-visible string** as a named `const` (54 string
constants; registered in `project.godot` after `Config`, before `GameState`). No mutable state.
Edit this one file to change any displayed text. Sections:

- **HUD templates** (`HUD_MONEY`, `HUD_CATS`, `HUD_TOKENS`, `HUD_BOTS`, `HUD_MEGA_BOTS`, `HUD_ONLY_PAWS_RATE`, `HUD_CAT_FOOD`, `HUD_RESEARCH_CATS`, `HUD_CAT_INTELLIGENCE`) — use `%s`/`%.2f` slots filled via the `%` operator in `_process()`.
- **Research panel state** (`RESEARCH_NO_ACTIVE`, `RESEARCH_IN_PROGRESS`, `RESEARCH_NEEDS_CATS`).
- **Buttons** — static labels (`BTN_EARN_MONEY`, `BTN_ONLY_PAWS`, `BTN_ONLY_PAWS_ON/OFF`), per-frame cost templates (`BTN_PURCHASE_CAT`, `BTN_MANAGER_BOT`, `BTN_MEGA_BOT`, `BTN_BUY_FOOD`(`_AUTO`), `BTN_BUY_TOKENS`(`_AUTO`), `BTN_FUND_RESEARCH`), and shop items with embedded cost (`BTN_AUTO_FEEDER`, `BTN_BOT_MANAGER`, `BTN_PAWSCO`, `BTN_AI_ENTERPRISE` use `\n$%s`; `BTN_ROBO_SWEEPER` uses inline `($%s)`).
- **Bubbles** (`BUBBLE_VIRAL` = 💰, `BUBBLE_INSPIRATION` = 💡).
- **Poop** (`POOP_EMOJI` = 💩) — glyph shown on the clickable poop button.
- **Robo-Shit Sweeper** (`SWEEPER_EMOJI` = 🤖) — glyph shown on the autonomous sweeper Node2D's label.
- **Developer debug menu** (`DEBUG_MENU_TITLE` = "Debug Menu", `DEBUG_POOP_OFF_LABEL` = "Poop Off") — title and toggle labels for the code-only debug overlay.
- **Research item copy** (`RESEARCH_CAT_POWER_NAME/SUB/DESC`, `RESEARCH_AI_MODEL_NAME/SUB/DESC`, `RESEARCH_ROBO_SWEEPER_NAME/SUB/DESC`) — referenced directly by `Config.RESEARCH_ITEMS`; a `const` cross-autoload reference that compiles because Strings has no initialization dependency on Config. `RESEARCH_NAMES: Dictionary` maps item id → display name for the active-research label (includes `robo_shit_sweeper`).
- **Popups** (`POPUP_*`, 17 of them) — the body text of every scene popup. `_ready()` overrides each `Main.tscn` PopupLabel from these consts via `_set_popup_text()`, so the `.tscn` text is now editor-placeholder only. Text matches the original `.tscn` copy exactly (centralization was a pure refactor, no visible change). `POPUP_VIRAL`, `POPUP_AI_OVERLORDS`, and `POPUP_INSPIRATION` are used only by the in-code popup builders (`_show_*_popup()`); `POPUP_INSPIRATION` is a placeholder string awaiting final copy.

### Util (`res://autoloads/Util.gd`)

Autoloaded singleton containing stateless helper functions. No mutable state.

| Function | Signature | Description |
|---|---|---|
| `format_number` | `(value: float) -> String` | Returns the integer portion of `value` formatted with comma separators (e.g. `1000.0` → `"1,000"`). Never uses scientific notation. |

---

### CatCharacter (`res://scripts/CatCharacter.gd`)

Sprite-based cat with autonomous wander behaviour. Frame data lives in the `AnimatedSprite2D` child configured in the editor; the script never touches SpriteFrames.

Wander state machine (`enum State { IDLE, WALKING }`):
- `_ready()` seeds `_wander_timer` with `randf_range(Config.CAT_WANDER_MIN, CAT_WANDER_MAX)`.
- `_process(delta)`: returns early while `_bubble_paused` (no movement, no timer tick). Otherwise counts `_wander_timer` down; on expiry picks a new `_target_pos` inside the safe zone (40px inset, top 10% excluded — same formula as `_place_cat`), enters `WALKING`, re-rolls the timer, flips `AnimatedSprite2D.flip_h` toward the target, and plays `"walk"`. While `WALKING`, moves toward `_target_pos` at `Config.CAT_MOVE_SPEED` px/s; on arrival snaps to target, returns to `IDLE`, and plays `"idle"`.
- `pause_for_bubble()`: sets `_bubble_paused = true`, forces `IDLE`, plays `"idle"`. Called by Main.gd only for **viral** bubbles spawned over this cat.
- `resume_from_bubble()`: clears `_bubble_paused` and re-rolls `_wander_timer`. Called by Main.gd when a bubble over this cat is collected or expires.
- `_play_anim(name)`: private; plays the named animation only if the `AnimatedSprite2D` exists and its SpriteFrames defines that animation, else leaves the current animation unchanged. (The editor SpriteFrames currently only defines `"default"`; `"idle"`/`"walk"` are no-ops until those animations are authored in the editor — never created in code.)

Scene tree:
```
CatCharacter (Node2D) ← CatCharacter.gd (wander state machine)
└── AnimatedSprite2D  ← SpriteFrames and animations set up in editor
```

---

### Main UI (`res://scenes/Main.gd`)

Drives the root scene. Reads from and delegates to `GameState`; the only local mutable state is UI-latch flags plus the bubble mechanic's `_cat_bubble_timers` (Dictionary: cat `instance_id` → seconds remaining), `_active_bubbles` (Array of `{node, timer, type, research_id, cat_node}` dicts), the global burst-window state (`_burst_window_active`, `_burst_window_timer`, `_global_cd_timer`), and the poop mechanic's `_cat_poop_timers` (Dictionary: cat `instance_id` → seconds remaining; same structure as `_cat_bubble_timers`) and `_active_poops` (Array of `{node}` dicts), and the Robo-Shit Sweeper's inline state machine (`_sweeper_node`/`_sweeper_label` Node2D+Label built in `_ready()`, `SweeperState` enum with INACTIVE/MOVING/CLEANING, `_sweeper_state`, `_sweeper_target_poop`, `_sweeper_clean_timer`), and the developer debug menu (`_debug_panel`/`_debug_poop_check` built in `_ready()` as a code-only overlay never added to Main.tscn, `_debug_menu_visible`, `_debug_poop_disabled`).

| Method | Description |
|---|---|
| `_ready()` | First sets `ThemeDB.fallback_font_size = Config.UI_BASE_FONT_SIZE` (22) so every label/button inherits the base; connects `cat_purchased` → `_on_cat_purchased`, `cat_lost` → `_on_cat_lost`, `research_completed` → `_on_research_completed`; builds per-item research panels in `ResearchItemList` from `Config.RESEARCH_ITEMS` (PanelContainer → VBoxContainer → NameLabel, DescriptionLabel, FundButton, ProgressLabel); stores refs in `_research_panels`, `_research_fund_buttons`, `_research_progress_labels`, `_research_panel_hidden`, and `_research_panel_unlocked` (false per item; **every panel starts `visible = false`** so `_refresh_research_slots()` is the sole authority that reveals eligible panels — this prevents tier-0 items other than `cat_power_unite`, e.g. `robo_shit_sweeper`, from showing before the global `cat_power_unite` gate is satisfied, since that gate only adds visibility and never hides); finally overrides all static scene-node text from `Strings` consts — `EarnMoneyButton`, `OnlyPawsButton`, the four dynamic shop-button labels (via `Strings.BTN_*`), and every popup body via `_set_popup_text()`; applies `_style_as_header()` to `CatsLabel`, `HappinessBarContainer/HappinessTitleLabel`, and `ShopPanel/ShopLabel`; finally calls `_refresh_research_slots()` so any immediately-eligible research panels show without waiting for the first frame |
| `_set_popup_text(popup, body)` | Sets `popup`'s body Label text; all popups share the inner path `DialogPanel/VBoxContainer/PopupLabel` |
| `_style_as_header(label)` | Applies the section-header style to a Label: `UI_HEADER_FONT_SIZE` (28) font-size override + a bold (`font_weight = 700`) `SystemFont` override |
| `_process(delta)` | **Popup queue discipline:** every popup trigger block (first_cat, only_paws, bot_unlock, upgrades_tab, bot_manager_unlock, starvation 1/2/recurring, happiness_cramped/riot, cat_crusher, viral) is wrapped in an inner `if not get_tree().paused:` guard and only sets its shown-flag when the popup is actually displayed — so if multiple conditions become true on the same frame, popups show one at a time (the later condition stays true and re-fires the frame after the earlier popup is dismissed) instead of stacking. Updates all labels every frame; one-time visibility latches for `only_paws_unlocked`, `bot_shop_unlocked`, `home_shop_unlocked`, `housing_tier_index >= 1` (reveals CenterColumn), and `bot_manager_unlocked OR auto_feeder_unlocked`; shows `OnlyPawsPopup` and pauses tree the first time `only_paws_unlocked` triggers; updates `CatFoodLabel`; sets `OnlyPawsButton` label and modulate; `PurchaseCatButton` and `ManagerBotButton` cost labels use `Util.format_number()` (`PurchaseCatButton.disabled` is now gated on `GameState.cats >= GameState.get_max_cats()` — the hard cat cap — replacing the former `get_happiness() <= 0.0` gate); reveals `MegaManagerBotButton` + `MegaBotsRateLabel` via one-way latch once `research_complete["ai_model_upgrade"]` is true, updating the button's `Mega-Bot ($X)` label/disabled state and the `Mega-Bots: X` count each frame; calls `_refresh_research_slots()` each frame to reveal eligible research panels via the queued slot system (global `cat_power_unite`-complete gate that hides every other panel until the first item finishes, then housing-tier + predecessor-complete gates, `Config.RESEARCH_MAX_VISIBLE` cap); `OnlyPawsIncomeLabel` shows `paws_income_rate` when `bots_active`, else `get_onlypaws_cats() * Config.onlypaws_income_per_cat` (matches effective income rate used by GameState); updates `HappinessBar` value and fill colour (red→green via `Color.lerp`); updates `ResearchActiveLabel`, `ResearchProgressBar`, `ResearchCatsLabel` every frame; shows cramped/riot popups when triggered; updates housing chain display; one-way latch fires the whale popup via `_show_viral_popup()` the instant `GameState.viral_bubbles_unlocked` flips (sets `viral_popup_shown`); ticks the global burst window (when closed, counts `_global_cd_timer` down and, on reaching 0, opens a window of `randf_range(BUBBLE_BURST_WINDOW_MIN, MAX)`; when open, counts `_burst_window_timer` down and, on reaching 0, closes and re-rolls `_global_cd_timer` to `randf_range(BUBBLE_GLOBAL_CD_MIN, MAX)`); decrements each entry in `_cat_bubble_timers` by `delta` and, when a cat's timer expires, always resets it to a new `randf_range(BUBBLE_SPAWN_MIN, BUBBLE_SPAWN_MAX)` but only spawns (finds the cat node by `instance_id` and calls `_try_spawn_bubble_for_cat(cat_node)`) if `_burst_window_active` — triggers that miss the window are discarded, never queued; **poop timers** (no burst window — unconditional): decrements each entry in `_cat_poop_timers` by `delta` and, when a cat's timer expires, resets it to a new `randf_range(POOP_SPAWN_MIN, POOP_SPAWN_MAX)` and calls `_spawn_poop(cat_node)` (cat found by `instance_id`) **unless `_debug_poop_disabled`** is set via the debug menu — the timer still ticks and resets so toggling poop back on resumes the normal cadence rather than firing all cats at once; calls `_process_sweeper(delta)` immediately after the poop timers to drive the Robo-Shit Sweeper state machine; advances each active bubble's timer, fades its alpha to `1.0 - timer/BUBBLE_LIFETIME`, and frees/removes it once `timer >= BUBBLE_LIFETIME` (calling `bubble.cat_node.resume_from_bubble()` on expiry if that cat is still valid) |
| `_sort_shop_list` | `() -> void` | Private; updates dynamic `shop_cost` metadata (housing next-tier cost, manager-bot live cost) then sorts `ShopList` children ascending by `shop_cost`; invisible items sink to bottom; called whenever any item's visibility changes |
| `_on_earn_money_button_pressed()` | Calls `GameState.click()` |
| `_on_purchase_cat_button_pressed()` | Calls `GameState.buy_cat()` |
| `_on_only_paws_button_pressed()` | Flips `GameState.only_paws_active`; turning OFF sets `bots_active = false`; turning ON re-enables bots if `tokens > 0` |
| `_on_only_paws_popup_ok_pressed()` | Hides `OnlyPawsPopup` and unpauses tree |
| `_on_manager_bot_button_pressed()` | Calls `GameState.buy_bot()` |
| `_on_mega_manager_bot_button_pressed()` | Calls `GameState.buy_mega_bot()` |
| `_on_cat_purchased()` | Instantiates `CatCharacter` at scale 0.4, adds to `CatContainer`, calls `_place_cat(cat)`, and registers the cat in `_cat_bubble_timers` with an initial `randf_range(BUBBLE_SPAWN_MIN, BUBBLE_SPAWN_MAX)` cooldown and in `_cat_poop_timers` with `randf_range(POOP_SPAWN_MIN, POOP_SPAWN_MAX)` |
| `_on_cat_lost()` | Removes the last `CatContainer` child: erases its `instance_id` from `_cat_bubble_timers` and `_cat_poop_timers`, then `queue_free()`s the node. If the sweeper is in CLEANING and `_active_poops` is now empty, clears `_sweeper_target_poop` and sends it to MOVING so it doesn't chase a freed target |
| `_unhandled_key_input(event)` | Toggles the developer debug menu when the backtick key (`KEY_QUOTELEFT`) is pressed (non-echo). Flips `_debug_menu_visible`/`_debug_panel.visible` and calls `get_viewport().set_input_as_handled()`. Uses `_unhandled_key_input` (not `_input`/`_gui_input`) so it only sees keys no control consumed and never interferes with existing input/`gui_input` handlers |
| `_on_debug_poop_toggled(pressed)` | Debug menu "Poop Off" `CheckButton` handler; sets `_debug_poop_disabled = pressed`, which gates the `_spawn_poop()` call in the `_process()` poop-timer loop (timers keep ticking) |
| `_process_sweeper(delta)` | Robo-Shit Sweeper inline state machine (`match _sweeper_state`); the sweeper cleans continuously with no charging or per-run cap. **INACTIVE:** returns unless `GameState.robo_sweeper_purchased`; otherwise places `_sweeper_node` at viewport center, makes it visible, and enters MOVING immediately. **MOVING:** if `_active_poops` is empty, `return`s (idles in MOVING until a poop appears); else finds the nearest poop (`Vector2.distance_to` on the poop Button's `Control.position`), `move_toward`s it at `Config.SWEEPER_MOVE_SPEED * delta`, and when within 8px enters CLEANING (`_sweeper_clean_timer = Config.SWEEPER_CLEAN_DELAY`). **CLEANING:** counts `_sweeper_clean_timer` down; at 0, if the target still exists in `_active_poops`, removes it via `_on_poop_pressed()`, then clears the target and returns to MOVING. Built entirely in Main.gd (no new scene/script) and reads `_active_poops` without mutating it directly |
| `_spawn_poop(cat_node)` | Creates a clickable poop Button (text `Strings.POOP_EMOJI` 💩, `font_size` 36, `custom_minimum_size` 64×64) at `cat_node.global_position + Vector2(randf_range(-40,40), randf_range(10,30))`, `z_index = 50`, child of Main; stores a `{node}` dict in `_active_poops`, binds `pressed` → `_on_poop_pressed(poop)`, and increments `GameState.poop_count`. Poop does **not** expire automatically — it persists until clicked |
| `_on_poop_pressed(poop)` | Removes the poop from `_active_poops`, `queue_free()`s its node, and decrements `GameState.poop_count` (clamped at 0 via `max`) |
| `_on_buy_cat_food_x1_button_pressed()` | Calls `GameState.buy_cat_food_pack(1)` |
| `_on_buy_cat_food_x10_button_pressed()` | Calls `GameState.buy_cat_food_pack(10)` |
| `_on_buy_token_x1_button_pressed()` | Calls `GameState.buy_tokens(1)` |
| `_on_buy_token_x10_button_pressed()` | Calls `GameState.buy_tokens(10)` |
| `_on_buy_bot_manager_button_pressed()` | Calls `GameState.buy_bot_manager()` |
| `_place_cat(cat: Node2D)` | Places a newly added cat at a random position within a safe spawn zone: 40 px inset from all edges with the top 10% of the viewport excluded (so bubbles spawned above cats don't render off-screen). Up to 30 attempts to avoid UI rects (+ 16 px padding) and existing cats (64 px radius). Falls back to ignoring cat spacing, then to an unconstrained position — all attempts stay within the safe zone. |
| `_try_spawn_bubble_for_cat(cat_node)` | Spawn guard called when a specific cat's cooldown expires. Returns early (no spawn) if any of: `GameState.viral_bubbles_unlocked == false`, `GameState.only_paws_active == false`, or `_active_bubbles.size() >= Config.BUBBLE_MAX_ON_SCREEN`. Otherwise calls `_spawn_bubble(cat_node)` |
| `_spawn_bubble(cat_node, force_type = "")` | Picks bubble type: if `force_type` is non-empty it is used directly (skipping selection); else `"viral"` when no research is active (`GameState.get_active_research_id() == ""`), otherwise `"inspiration"` with probability `research_cat_fraction`, else `"viral"`. Creates a clickable Button over `cat_node` (text `"💰"` viral / `"💡"` inspiration; `font_size` override `roundi(Config.UI_BASE_FONT_SIZE * 2.2)`, `custom_minimum_size` 80×80), positioned at `cat_node.global_position + Vector2(randf_range(-30,30), randf_range(-50,-20))`, `z_index = 100` (renders in front of all UI panels), child of Main; stores a `{node, timer, type, research_id, cat_node}` dict in `_active_bubbles` and binds `gui_input` → `_on_bubble_gui_input(event, bubble)`. `research_id` is captured at spawn so collection still works if research changes mid-flight. After appending, if the type is `"viral"` and `cat_node` is valid, calls `cat_node.pause_for_bubble()` to freeze that cat (inspiration bubbles do not pause) |
| `_show_viral_popup()` | Builds the one-time "Whale Hunting Baby!" achievement popup entirely in code (full-screen `ColorRect` overlay with `process_mode = WHEN_PAUSED` and `z_index = 20` → `CenterContainer` → `PanelContainer` → `VBoxContainer` with an autowrapped `Label` and OK `Button`); pauses the tree on show; OK button frees the overlay, unpauses, and calls `_force_first_viral_bubble()` |
| `_on_research_completed(id)` | Hides and latches the completed item's panel (`_research_panel_hidden[id] = true`), then calls `_refresh_research_slots()` so a freed slot fills immediately (not on the next frame); if `id == "ai_model_upgrade"`, calls `_show_ai_overlords_popup()` |
| `_show_ai_overlords_popup()` | Builds the one-time "AI Overlords" achievement popup in code, mirroring `_show_viral_popup()` but with a 600×360 `PanelContainer`; pauses the tree on show; OK button frees the overlay and unpauses |
| `_show_inspiration_popup()` | Builds the one-time inspiration-bubble popup in code, mirroring `_show_viral_popup()` (overlay → CenterContainer → PanelContainer → VBox → autowrapped `Strings.POPUP_INSPIRATION` label + OK); pauses on show; OK frees the overlay and unpauses. Gated by `GameState.inspiration_popup_shown` so it fires exactly once |
| `_force_first_viral_bubble()` | Called once when the viral popup is dismissed. Picks a random `CatContainer` child (returns if none) and calls `_spawn_bubble(cat_node, "viral")`, bypassing every guard (burst window, `viral_bubbles_unlocked`, `BUBBLE_MAX_ON_SCREEN`) so the player sees their first bubble immediately. Normal burst-window scheduling resumes afterward |
| `_on_bubble_gui_input(event, bubble)` | On a left mouse-button press (`InputEventMouseButton`, `MOUSE_BUTTON_LEFT`, `pressed`): collects the clicked `bubble` via `_on_bubble_pressed`, then reads the cursor position (`get_viewport().get_mouse_position()`) and collects every other bubble in `_active_bubbles` whose `node.get_global_rect().has_point(click_pos)` — so one click harvests all bubbles stacked at that spot (intentional) |
| `_on_bubble_pressed(bubble)` | Removes the bubble from `_active_bubbles`; if `bubble.cat_node` is still valid, calls `resume_from_bubble()` on it; then frees its node. Viral: adds `max(per_cat_rate × Config.BUBBLE_VIRAL_MULTIPLIER, 1.0)` to `GameState.money`, where `per_cat_rate = onlypaws_income_per_cat + onlypaws_income_per_bot × manager_bots + MEGA_BOT_INCOME_PER_CAT × mega_bots` — **one cat's** $/sec, not the total across all cats (one cat went viral). Inspiration: if `bubble.research_id` is still funded and not complete, adds `max(1.0 × Config.BUBBLE_INSPIRATION_SECONDS, 1.0)` to `research_points[id]` (**one cat's** research contribution, not all research cats), clamped to the item's `points_cost`; on the first such successful award (gated by `GameState.inspiration_popup_shown`), sets that flag and calls `_show_inspiration_popup()` |
| `_overlaps_ui(pos, ui_rects)` | Returns `true` if `pos` falls inside any rect in `ui_rects`. |
| `_too_close_to_cats(pos, existing_positions)` | Returns `true` if `pos` is within `CAT_SPACING_RADIUS` of any element in `existing_positions`. |

---

## Current Features

- [x] **"Work at McPawnalds" button** — manual click adds $1.0 to `money`
- [x] **Money counter** — label refreshes every frame, displayed to 2 decimal places (`$X.XX`)
- [x] **Cats counter** — label refreshes every frame showing `X/MAX` (e.g. `0/10`); MAX from `GameState.get_max_cats()` = `base_max_cats` + 10 per purchased housing tier; turns red when cats exceed MAX
- [x] **GameState singleton** — autoloaded; holds `money`, `cats`, `next_cat_cost`, `only_paws_unlocked`, `paws_income_rate`; emits `cat_purchased`
- [x] **Purchase Cat button** — unconditionally visible from game start; label shows live cost to 2 decimal places; cost starts at $5.00 and multiplies by `cat_cost_growth_rate` each purchase (default 1.3, reduced to 1.25 by breeder contract)
- [x] **OnlyPaws passive income** — unlocks at 3 cats; base rate `cats * 0.25` $/sec (e.g. $0.75/sec at unlock); each Manager-Bot adds $0.50/cat/sec additively: formula `cats * (0.25 + 0.50 * bots)`; income only runs when `only_paws_active` and `cat_food > 0`
- [x] **OnlyPaws button + income label** — revealed together when `only_paws_unlocked`; first reveal shows modal popup (pauses tree) explaining the feature
- [x] **OnlyPaws unlock popup** — modal overlay shown once when `only_paws_unlocked` first triggers; pauses game loop; dismissed with OK button
- [x] **Cat spawning** — each purchase instances `CatCharacter` at scale 0.4 into `CatContainer`; placed at a random viewport position avoiding UI elements (16 px padding) and other cats (64 px radius); cats keep their position when new ones are added or one is lost
- [x] **Sprite-based cat character** — `CatCharacter` scene contains an `AnimatedSprite2D` child; animations configured in the Godot editor
- [x] **OnlyPaws Manager-Bot** — unlocks at 6 cats; costs $50 (multiplies by 1.6× each purchase); each bot adds $0.50/cat/sec on top of the $0.25/cat/sec base (`onlypaws_income_per_bot`); formula: `cats * (0.25 + 0.50 * bots)`; button shows live cost, disabled when unaffordable; `BotsRateLabel` shows bot count
- [x] **OnlyPaws ON/OFF toggle** — `OnlyPawsButton` flips `only_paws_active`; income only runs while active; toggling OFF also sets `bots_active = false` stopping token drain; toggling ON re-enables bots if tokens > 0; button label and green modulate reflect state
- [x] **Upgrade stubs (GameState only)** — `buy_breeder_contract()` exists in GameState but is not wired to any UI
- [x] **Flat shop list** — ShopPanel contains a ScrollContainer with a single VBoxContainer; items are individual Button nodes sorted ascending by cost each time visibility changes; no tabs
- [x] **Housing upgrade chain** — in Home tab; 4 purchasable tiers (Basic Studio is free starting state); costs: 500 / 3.5k / 11.5k / 46k; tier 1 renamed to "Luxury Cat Trees"; each purchased tier adds 10 to max_cats (20 → 30 → 40 → 50 → 60); UI shows current tier (green label) + next tier (name, cost, buy button), or "Max Upgrade Reached" at cap; sliding window: always exactly one current + one next visible
- [x] **Shop panel always visible** — `ShopPanel` is shown from game start; no unlock gate
- [x] **Cat food** — `cat_food` starts at 1000; drains at `cats * 1.0` per second (`Config.cat_food_drain_rate = 1.0`, always active, not gated); clamped to 0; when food hits 0, OnlyPaws income stops; `CatFoodLabel` shows `floor(cat_food)` in the HUD
- [x] **Cat Food Pack shop item** — buy x1 ($10, +100 food) or x10 ($100, +1000 food); both buttons disabled when `money < 10`
- [x] **Token system** — `tokens` drains at `manager_bots * token_drain_per_bot` per second (clamped to 0); `TokensLabel` shows `floor(tokens)` in HUD; unlocks alongside Token Pack shop item on first bot purchase
- [x] **Token Pack shop item** — hidden until `tokens_shop_unlocked`; buy x1 ($20, +100 tokens) or x10 ($200, +1000 tokens); both buttons disabled when `money < 20`
- [x] **Manager-bot Manager upgrade** — hidden until `bot_manager_unlocked` (tokens hit 0 or 6 bots owned); one-time $4,000 purchase; after purchase auto-calls `buy_tokens(1)` each frame tokens fall to ≤ 1; button turns green and disables on purchase
- [x] **Auto-Feeder upgrade** — hidden until `auto_feeder_unlocked` (10+ cats or food has ever hit 0); one-time $2,000 purchase; after purchase auto-calls `buy_cat_food_pack(1)` each frame food falls to ≤ 1; button turns green and disables on purchase; description hides on purchase
- [x] **PawsCo Membership upgrade** — hidden until `bot_manager_unlocked`; one-time $800 purchase; reduces cat food pack cost from $10 to $9 via `get_cat_food_pack_cost()`; button created dynamically in `_ready()`, disappears on purchase
- [x] **AI Enterprise Membership upgrade** — hidden until `bot_manager_unlocked`; one-time $1,000 purchase; reduces token pack cost from $20 to $15 via `get_token_pack_cost()`; button created dynamically in `_ready()`, disappears on purchase
- [x] **Cat Happiness** — reactive value 0–100%; 100% while cats ≤ max_cats; above max: two-segment quadratic ease-in decay scaled by housing tier. `fifty_break = max_cats + Config.happiness_fifty_break_offset + housing_tier_index` (happiness = 50%); `zero_break = max_cats + Config.happiness_zero_break_offset + housing_tier_index * 2` (happiness = 0%). Drops from 100%→50% on segment 1 then 50%→0% on segment 2, each using `t^2` (slow start, accelerating end); always-visible progress bar at top-centre; fill colour transitions red→green via lerp; applies continuous income multiplier `happiness_income_floor + (happiness / 100) * happiness_income_range` (0.30 at 0% → 1.00 at 100%); riot popup appears once when happiness first hits 0%, sets `happiness_riot_triggered`
- [x] **Cramped popup** — shown once when `cats >= Config.HOUSING_UPGRADE_PROMPT_THRESHOLD` (8 cats); pauses game loop; on dismiss sets `home_shop_unlocked = true`
- [x] **Bubble mechanic** — clickable floating Button bubbles spawn over individual cats. Each cat runs its own randomized cooldown (`_cat_bubble_timers`, keyed by `instance_id`) of `randf_range(Config.BUBBLE_SPAWN_MIN, BUBBLE_SPAWN_MAX)` = 5–15s, registered on purchase and erased on loss; when a cat's timer expires it always resets but only attempts a spawn if a global **burst window** is currently open. The screen alternates between an idle global cooldown (`BUBBLE_GLOBAL_CD_MIN..MAX` = 20–40s, no spawns) and a brief open burst window (`BUBBLE_BURST_WINDOW_MIN..MAX` = 2–10s) during which expiring per-cat timers may fire; the first window does not open immediately on start. Triggers that land outside a window are discarded, never queued. Capped at `BUBBLE_MAX_ON_SCREEN` (4) total. Gated behind `viral_bubbles_unlocked` (set 20s after the **second** Manager-Bot is owned) and `only_paws_active`. Two types: Viral (💰, reward = one cat's $/sec `per_cat_rate × 4`, min $1) and Inspiration (💡, reward = one cat's contribution `1 × 3` research points, min 1, clamped to `points_cost`). Rewards reflect the single cat that spawned the bubble, not the whole population. Viral always spawns when no research is active; with active research, Inspiration spawns with probability `research_cat_fraction` else Viral. The one-time "Whale Hunting Baby!" achievement popup (built in code, pauses tree) fires from a `_process` latch the instant the mechanic unlocks — not from the spawn pipeline — so it appears right at unlock rather than waiting for a random burst window. Dismissing it calls `_force_first_viral_bubble()`, which spawns one guaranteed viral bubble immediately (bypassing all guards), after which normal burst-window scheduling takes over. Bubbles fade out over `BUBBLE_LIFETIME` (4.5s) and disappear if not clicked. Bubble Buttons are large (font `roundi(UI_BASE_FONT_SIZE × 2.2)`, 80×80 min size) and use `z_index = 100` to render in front of all UI; a left-click collects the clicked bubble plus any other bubbles stacked under the cursor in one click (via `gui_input` + `get_global_rect().has_point`). Created in code (no scene file), children of Main. While a **viral** bubble is live over a cat, that cat is frozen via `pause_for_bubble()` and resumes (`resume_from_bubble()`) when the bubble is collected or expires
- [x] **Cat wandering** — each `CatCharacter` autonomously wanders: after a `randf_range(CAT_WANDER_MIN, CAT_WANDER_MAX)` = 25–60s idle, it picks a random destination inside the safe zone (40px inset, top 10% excluded) and walks there at `CAT_MOVE_SPEED` = 40 px/s, flipping its sprite toward the target and playing the `"walk"`/`"idle"` animations defined in the SpriteFrames (autoplay = `"idle"`). Movement and the wander timer freeze while a viral money bubble is active above the cat

---

## Planned Features

### Phase 1 — Core Click Loop *(in progress)*
- [x] "Work at McPawnalds" button with money counter
- [x] Purchase Cat button (gated at $100) with cat spawning
- [x] Idle/passive income (OnlyPaws: `floor(cats/3)` $/sec, unlocks at 3 cats)
- [ ] Basic UI polish (centered layout, styled labels & buttons)

### Phase 1 — Core Click Loop (continued)
- [x] OnlyPaws Manager-Bot (additive $0.50/cat/sec per bot, unlocks at 6 cats)

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
