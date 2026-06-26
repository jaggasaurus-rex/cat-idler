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
│   ├── agents/             # Seven-agent sub-agent pipeline (see Agent Pipeline below)
│   └── skills/             # run-cat-idler skill (build/run/screenshot harness)
├── assets/
│   └── cats/               # Cat sprite sheets; cat_1..5.png (idle) + cat_walk_1..5.png (walk); cat_frames_1..5.tres (SpriteFrames variants); cat_1-sheet.png (combined sheet, not yet wired up)
├── autoloads/
│   ├── GameState.gd        # Global state singleton
│   └── Util.gd             # Stateless helper functions (format_number)
├── docs/
│   └── adr/                # Architecture Decision Records (0001–0004)
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

Seven agents in `.claude/agents/` — six run automatically at defined points in every task; one (`architect`) runs on-demand at the start of a task when opted in (see CLAUDE.md).
Automatic: `context-validator` and `pre-task-scaffolder` before starting; `gdscript-reviewer`,
`strings-guardian`, and `adversarial-reviewer` after implementation, before committing; `commit-auditor` after committing.

### Autoloads

| Singleton name | Path | Purpose |
|---|---|---|
| `Util` | `res://autoloads/Util.gd` | Stateless helper functions; no mutable state |
| `Config` | `res://Config.gd` | Static tuning constants; no mutable state; referenced by GameState and Main |
| `Strings` | `res://Strings.gd` | All user-visible text as named string consts; registered after Config, before GameState; `Config.RESEARCH_ITEMS` and `Config.ENRICHMENT_ITEMS` reference its research/enrichment consts and Main.gd pulls every label/popup/button string from here |
| `GameState` | `res://autoloads/GameState.gd` | Holds all persistent game state; the single source of truth for currency and rates |

### Scene structure

```
Main (Control, full-rect)             ← Main.gd
├── TextureRect                       ← full-screen lofi-studio background image (res://assets/lofi-studio.png)
├── PanelLayout (HBoxContainer)       ← full-rect; three-panel frame: left HUD | center play area | right shop/research
│   ├── LeftPanel (PanelContainer, min_x=270)
│   │   └── MarginContainer → LeftVBox (VBoxContainer)
│   │       ├── CatsLabel (Label)     ← section header; styled via _style_as_header(); "Cats: X/MAX"
│   │       ├── MoneyLabel (Label)    ← updated every frame
│   │       ├── EarnMoneyButton       ← pressed → GameState.click()
│   │       ├── PurchaseCatButton     ← always visible from start; label updates every frame
│   │       ├── CatFoodLabel          ← hidden until cats_ever_purchased >= 1 (one-way latch)
│   │       ├── BuyCatFoodButton      ← revealed with CatFoodLabel
│   │       ├── OnlyPawsButton        ← shown once only_paws_unlocked; green modulate when active
│   │       ├── OnlyPawsIncomeLabel   ← shown with OnlyPawsButton
│   │       ├── BotTokenRow (HBoxContainer) ← BotsRateLabel | TokensLabel | MegaBotsRateLabel
│   │       ├── ManagerBotButton      ← shown once bot_shop_unlocked
│   │       ├── MegaManagerBotButton  ← shown once ai_model_upgrade research completes
│   │       ├── BuyTokensButton       ← shown once tokens_shop_unlocked
│   │       └── PrideLabel (Label)    ← hidden until dog_attack_unlocked (one-way latch in Main.gd._process()); "Pride: X" updated every frame
│   ├── CenterPanel (Control, EXPAND_FILL, mouse_filter=IGNORE) ← %CenterPanel; split vertically
│   │   └── CenterVBox (VBoxContainer, EXPAND_FILL)
│   │       ├── CatPlayArea (Control, EXPAND_FILL) ← %CatPlayArea; cats wander here
│   │       │   └── CatContainer (Node2D) ← %CatContainer; purchased cats added here; position 0,0 local
│   │       └── DogBattlePanel (PanelContainer, EXPAND_FILL, visible=false) ← %DogBattlePanel; shown during WARNING/RESOLVING; visibility driven by dog_attack_state in _process()
│   │           └── BattleVBox (VBoxContainer, EXPAND_FILL)
│   │               ├── WarningLabel (Label) ← %WarningLabel; visible=false; shown on dog_attack_warning_started; text set in _ready() from Strings.DOG_ATTACK_WARNING_LABEL
│   │               ├── LanesContainer (VBoxContainer, EXPAND_FILL) ← three equal-height lane Controls for battle animation
│   │               │   ├── TopLane (Control, EXPAND_FILL, clip_contents) ← %TopLane; dynamic cat/dog Labels added as children per-battle, freed after
│   │               │   ├── MiddleLane (Control, EXPAND_FILL, clip_contents) ← %MiddleLane
│   │               │   └── BottomLane (Control, EXPAND_FILL, clip_contents) ← %BottomLane
│   │               └── ResultLabel (Label) ← %ResultLabel; visible=false; text set per-battle in _on_dog_attack_resolved()
│   └── RightPanel (PanelContainer)
│       └── RightVBox (VBoxContainer)
│           ├── ResearchSubPanel (PanelContainer) ← top half of right column; size_flags_vertical=EXPAND_FILL
│           │   └── CenterColumn (VBoxContainer) ← %CenterColumn; hidden until housing_tier_index >= 1
│           │       ├── ResearchTitle (Label)
│           │       ├── ResearchActiveLabel (Label) ← %ResearchActiveLabel
│           │       ├── ResearchProgressBar ← %ResearchProgressBar
│           │       ├── ResearchSlider (HSlider) ← %ResearchSlider; hidden until first item funded
│           │       ├── SliderLabels (HBoxContainer) ← OnlyPawsHint | ResearchHint
│           │       ├── ResearchCatsLabel (Label) ← %ResearchCatsLabel
│           │       └── ResearchScroll (ScrollContainer)
│           │           └── ResearchItemList (VBoxContainer) ← %ResearchItemList; dynamically populated in _ready()
│           └── ShopSubPanel (PanelContainer) ← bottom half of right column; size_flags_vertical=EXPAND_FILL
│               └── ShopPanel (VBoxContainer) ← %ShopPanel
│                   ├── ShopLabel (Label) ← %ShopLabel; section header styled via _style_as_header()
│                   └── ShopScroll (ScrollContainer)
│                       └── ShopList (VBoxContainer) ← %ShopList; dynamically sorted by cost
│                           ├── HousingButton (hidden until home_shop_unlocked)
│                           ├── AutoFeederButton (hidden until auto_feeder_unlocked)
│                           └── BotManagerShopButton (hidden until bot_manager_unlocked)
├── HappinessBarContainer (VBoxContainer) ← top-center of screen (anchor_left=0.5, anchor_right=0.5, offset_top=10); always visible
│   ├── HappinessTitleLabel (Label "Cat Happiness") ← %HappinessTitleLabel; horizontally centred
│   └── HappinessRow (HBoxContainer)
│       ├── HappinessMinLabel (Label "0%")
│       ├── HappinessBar (ProgressBar) ← %HappinessBar; fill colour interpolated red→green each frame
│       └── HappinessMaxLabel (Label "100%")
├── StarvationPopup (ColorRect)        ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when starvation_count first reaches 1; pauses tree; on dismiss calls GameState.grant_cat_food_pack(); gated by _starvation_popup_shown (Main.gd local)
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Fasting Never Hurt Anyone"
├── Starvation2Popup (ColorRect)       ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when starvation_count reaches 2; pauses tree; on dismiss: grants food, loses cat, checks game-over; gated by _starvation_2_popup_shown (Main.gd local)
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Third-World Dictator"
├── BotUnlockPopup (ColorRect)         ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when bot_shop_unlocked first becomes true; pauses tree; gated by GameState.bot_unlock_popup_shown
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Cat Harem" achievement
├── StarvationRecurringPopup (ColorRect) ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown each time starvation_count advances past a new count >= 3; gated by _starvation_handled_count (Main.gd local int); chains directly to StarvationAssholePopup on dismiss (tree stays paused)
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Recidivist" achievement
├── StarvationAssholePopup (ColorRect) ← second popup in recurring sequence; on dismiss: unpauses, grants food, loses cat, checks game-over
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Perfect Consistency" achievement
├── GameOverPopup (ColorRect)          ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown when cats==0 AND starvation_cats_lost>=1 AND cats_ever_purchased>0 after any starvation cat loss; chains to GameOver2Popup on dismiss
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "Literally Hitler" achievement
├── GameOver2Popup (ColorRect)         ← final popup; on dismiss calls get_tree().quit()
│   └── DialogPanel / VBoxContainer / PopupLabel + OKButton ← "The End" achievement
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
├── HappinessCrampedPopup (ColorRect) ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when happiness_cramped_triggered first sets (cats>=10); on dismiss sets home_shop_unlocked=true; pauses tree; "Sardine Can Chic" achievement; reward = Home Tab Unlocked
│   └── DialogPanel (PanelContainer)  ← centered 500×200 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← cramped message, autowrap
│           └── OKButton (Button)     ← hides popup, unpauses, sets home_shop_unlocked=true
├── HappinessRiotPopup (ColorRect)    ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when happiness_riot_triggered first sets; pauses tree; "Zero Stars on Yelp" achievement
│   └── DialogPanel (PanelContainer)  ← centered 500×200 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← riot message, autowrap
│           └── OKButton (Button)     ← hides popup and unpauses tree
├── BotManagerUnlockPopup (ColorRect) ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when bot_manager_unlocked first becomes true (gated by GameState.bot_manager_unlock_popup_shown); "Management Has Management Now" achievement; pauses tree; dismiss unpauses only
├── UpgradesTabPopup (ColorRect)      ← full-screen dark overlay; process_mode=WHEN_PAUSED; shown once when bot_manager_unlocked OR auto_feeder_unlocked first becomes true (gated by GameState.upgrades_tab_popup_shown); pauses tree; dismiss unpauses only
│   └── DialogPanel (PanelContainer)  ← centered 600×260 dialog
│       └── VBoxContainer
│           ├── PopupLabel (Label)    ← "NEW ACHIEVEMENT! ADHD Cat Parent" message, autowrap
│           └── OKButton (Button)     ← hides popup and unpauses tree
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
| `cat_cost_growth_rate` | `float` | `Config.cat_cost_growth_rate` | Multiplier applied to `next_cat_cost` each purchase; always >= 1.05 (floor enforced by `multiply_cat_cost_growth`); capped at 1.25 by the shop Breeder Contract (`min()` no-ops when research already brought it lower); research reductions apply to the premium above 1.0 — rate never inverts so cats always get more expensive |
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
| `poop_recyclers_researched` | `bool` | `false` | One-way latch; set by `set_poop_recyclers_researched()` when `cybernetic_poop_recyclers` research completes; causes poop spawn interval to double (×`Config.POOP_RECYCLER_INTERVAL_MULTIPLIER` = 2.0) |
| `enrichment_store_unlocked` | `bool` | `false` | One-way latch; set by `unlock_enrichment_store()` when `cat_enrichment_program` research completes; triggers the enrichment store button to appear in ShopList |
| `enrichment_purchases` | `Array[String]` | `[]` | List of purchased enrichment item ids; appended by `buy_enrichment()`; checked at overlay build time to disable already-owned buttons |
| `own_llm_researched` | `bool` | `false` | One-way latch; set by `set_own_llm_researched()` when `research_your_own_llms` research completes; adds the cheapest tier to `get_token_pack_cost()` ($10.0 via `Config.TOKEN_PACK_COST_OWN_LLM`) |
| `robo_sweeper_count` | `int` | `0` | Number of Robo-Shit Sweepers purchased. Each purchase increments this by 1 and multiplies `next_robo_sweeper_cost` by `Config.ROBO_SWEEPER_COST_MULTIPLIER` (3×). Main.gd's `_process()` spawns a new sweeper Node2D for each count above `_sweepers.size()` |
| `next_robo_sweeper_cost` | `float` | `Config.ROBO_SWEEPER_PURCHASE_COST` | Cost of the next sweeper purchase; starts at $10,000 and triples with each buy ($10k → $30k → $90k …). Seeds from `Config.ROBO_SWEEPER_PURCHASE_COST` |
| `first_cat_popup_shown` | `bool` | `false` | Set to `true` in Main.gd the first time `cats >= 1`; gates the first-cat achievement popup so it fires exactly once |
| `starvation_count` | `int` | `0` | Increments each time the starvation condition transitions from inactive to active (cat_food <= 0 AND money < 10) |
| `starvation_active` | `bool` | `false` | Frame-level debounce; `true` while the starvation condition persists; resets when cat_food > 0 or money >= 10 |
| `starvation_cats_lost` | `int` | `0` | Tracks cats lost specifically via the starvation mechanic; used in game-over condition |
| `cats_ever_purchased` | `int` | `0` | Lifetime cat purchase counter; incremented in `buy_cat()`; used to gate game-over so it only triggers if the player has owned at least one cat |
| `happiness_cramped_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `cats >= Config.HOUSING_UPGRADE_PROMPT_THRESHOLD` (8 cats); used by Main.gd to show the cramped popup once |
| `happiness_riot_triggered` | `bool` | `false` | One-way latch; set to `true` in `_process()` the first time `get_happiness() <= 0.0` (6 over max, e.g. cats = 26 with default max 20); used by Main.gd to show the riot popup once |
| `poop_count` | `int` | `0` | Number of uncleaned poops currently on screen. Incremented by Main.gd `_spawn_poop()` each time a cat poops, decremented (clamped at 0) by `_on_poop_pressed()` when the player clicks a poop. Drives `get_happiness()`: happiness decays quadratically with the `poop_count / cats` ratio toward `Config.POOP_MAX_RATIO`. |
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
| `pride` | `int` | `0` | Player's Pride score; incremented by `Config.PRIDE_GAIN_WIN` on dog attack win, decremented by `Config.PRIDE_LOSS_LOSE` on loss (clamped at 0) |
| `dog_attack_unlocked` | `bool` | `false` | One-way latch; set by `unlock_dog_attacks()` when `dog_defence` research popup is dismissed |
| `dog_attack_state` | `int` | `DogAttackState.IDLE` | Current phase of the dog attack state machine (IDLE/WAITING/WARNING/RESOLVING) |
| `_dog_attack_timer` | `float` | `0.0` | Counts down in WAITING (to next warning) and WARNING (to battle resolution) |

| Signal | Description |
|---|---|
| `cat_purchased` | Emitted by `buy_cat()` after a successful purchase |
| `cat_lost` | Emitted by `starvation_lose_cat()` when a cat is lost to starvation; Main.gd removes the last CatCharacter node from CatContainer |
| `research_completed(id: String)` | Emitted by `_process()` the frame a research item finishes accumulating its required points |
| `dog_attack_warning_started` | Emitted when dog attack state transitions from WAITING → WARNING; Main.gd triggers hissing + warning label |
| `dog_attack_resolved(player_won: bool, pride_delta: int)` | Emitted by `resolve_dog_attack()` after pre-calculating battle outcome; Main.gd runs battle visualization then calls `schedule_next_dog_attack()` |

| Method | Signature | Description |
|---|---|---|
| `_ready` | `() -> void` | Sets `process_mode = PROCESS_MODE_ALWAYS` so income ticks even while tree is paused |
| `_process` | `(delta) -> void` | Always drains `cat_food`; sets `food_hit_zero` the first time food reaches 0; checks and sets `auto_feeder_unlocked`; if `auto_feeder_purchased` and food low: calls `buy_cat_food_pack(1)`; if `bots_active`: drains tokens, sets `bots_active = false` when tokens reach 0; checks and sets `bot_manager_unlocked`; if `bot_manager_purchased` and tokens low: calls `buy_tokens(1)`; sets `happiness_riot_triggered` the first time `get_happiness() <= 0`; caches `get_happiness()` once per tick into a local `happiness`; if `only_paws_active and cat_food > 0.0`: earns `effective_rate * happiness_multiplier * delta` where `happiness_multiplier = Config.happiness_income_floor + (happiness / 100.0) * Config.happiness_income_range` (0.90–1.00 range) and `effective_rate = paws_income_rate` when `bots_active`, else `float(get_onlypaws_cats()) * Config.onlypaws_income_per_cat * get_cyborg_multiplier()` (no-bot base rate with cyborg multiplier); income stops when food reaches 0; research tick: for each funded, incomplete item in `Config.RESEARCH_ITEMS`, adds `get_research_cats() * get_cyborg_multiplier() * delta` to `research_points[id]` (skips items with `min_cats_required > get_research_cats()`); on completion sets `research_complete[id] = true`, calls `update_paws_rate()`, emits `research_completed(id)`; idle-research intelligence: after the research tick, when `get_active_research_id() == "" and get_research_cats() > 0 and research_complete["cat_power_unite"]`, accumulates `get_research_cats() * Config.IDLE_RESEARCH_INTEL_RATE * delta` into `_idle_intel_accumulator`, banking whole points into `cat_intelligence`; viral unlock: once `manager_bots >= 2`, accumulates `_viral_delay_timer` and sets `viral_bubbles_unlocked = true` after 20s |
| `click` | `() -> void` | Adds `1.0` to `money` |
| `buy_cat` | `() -> void` | Guards `money >= next_cat_cost`, then a **hard cap guard** (`cats >= get_max_cats()` → no-op) so the player can never exceed the current housing tier's cat limit; deducts cost, increments `cats`, applies `cat_cost_growth_rate`, sets `only_paws_unlocked` when `cats >= 3`, sets `bot_shop_unlocked` when `cats >= 6`, calls `update_paws_rate()`, emits `cat_purchased`. |
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
| `get_token_pack_cost` | `() -> float` | Three-tier priority: returns `Config.TOKEN_PACK_COST_OWN_LLM` (10.0) if `own_llm_researched`, else `Config.token_pack_cost_discounted` (15.0) if `ai_enterprise_purchased`, else `Config.token_pack_cost` (20.0); used by `buy_tokens` |
| `multiply_cat_cost_growth` | `(factor: float) -> void` | Applies `factor` to the **premium above 1.0** (`cat_cost_growth_rate - 1.0`), floors the premium at 0.05 (so rate never drops below 1.05), sets `cat_cost_growth_rate = 1.0 + premium`, then retroactively recalculates `next_cat_cost`. Example: rate=1.3, premium=0.3 → factor 0.9 → premium 0.27 → rate 1.27; second factor 0.8 → premium 0.216 → rate 1.216. Called with 0.9 on `cat_breeder_contract` completion and 0.8 on `cat_breeders_contract` completion. Stacks correctly with `buy_breeder_contract()` in any order (shop uses `min()` so it never raises a rate already below 1.25) |
| `set_poop_recyclers_researched` | `() -> void` | Sets `poop_recyclers_researched = true`; called on `cybernetic_poop_recyclers` completion |
| `set_own_llm_researched` | `() -> void` | Sets `own_llm_researched = true`; called on `research_your_own_llms` completion |
| `unlock_enrichment_store` | `() -> void` | Sets `enrichment_store_unlocked = true`; called on `cat_enrichment_program` completion |
| `buy_enrichment` | `(id: String, cost: float) -> bool` | Guards `id not in enrichment_purchases` and `money >= cost`; deducts cost; appends id to `enrichment_purchases`; returns `true` on success, `false` otherwise. Cosmetic only — no gameplay effect beyond the purchase itself |
| `buy_pawsco_membership` | `() -> void` | Guards `money >= Config.pawsco_membership_cost and not pawsco_membership_purchased`; deducts cost; sets `pawsco_membership_purchased = true` |
| `buy_ai_enterprise_membership` | `() -> void` | Guards `money >= Config.ai_enterprise_membership_cost and not ai_enterprise_purchased`; deducts cost; sets `ai_enterprise_purchased = true` |
| `buy_robo_sweeper` | `() -> void` | No-ops if `research_complete["robo_shit_sweeper"]` is false or `money < next_robo_sweeper_cost`; otherwise deducts `next_robo_sweeper_cost`, increments `robo_sweeper_count`, and multiplies `next_robo_sweeper_cost` by `Config.ROBO_SWEEPER_COST_MULTIPLIER` (3×). Repeatable — each call adds one more sweeper. Cost sequence: $10,000 / $30,000 / $90,000 / … |
| `buy_breeder_contract` | `() -> void` | Guards `money >= 2000 and not breeder_purchased`; sets `cat_cost_growth_rate = min(cat_cost_growth_rate, 1.25)` — caps the rate at 1.25 but never raises it, so purchasing after research reductions have already brought the rate lower is safe; retroactively recalculates `next_cat_cost = Config.cat_cost_base * pow(cat_cost_growth_rate, float(cats))`; not currently wired to any UI button |
| `get_max_cats` | `() -> int` | Returns `Config.base_max_cats` plus the sum of `max_cats_increase` for each purchased housing tier (1..housing_tier_index) |
| `get_happiness` | `() -> float` | **Poop-driven happiness.** Returns `100.0` if total cats (`cats + cyborg_cats`) `<= 0` or `poop_count <= 0`; otherwise `100 * (1 - t^2)` where `t = clamp((poop_count / total) / Config.POOP_MAX_RATIO, 0, 1)`. Cyborgs never poop but share the denominator, so converting cats raises happiness. Happiness falls quadratically as the poop-per-cat ratio rises toward `Config.POOP_MAX_RATIO` (3.0 = 0% happiness). Scales to any cat count: 1 poop/cat ≈ 89%, 2/cat ≈ 56%, 3/cat = 0%. Feeds the income multiplier in `_process()` and the happiness bar in Main.gd. (Replaced the earlier flat-100 stub; the original over-max two-segment quadratic decay remains removed.) The hard cat cap in `buy_cat()` (`cats >= get_max_cats()`) is still in place. Because happiness can reach 0% (poop-per-cat ratio ≥ `Config.POOP_MAX_RATIO`), the dependent system `happiness_riot_triggered` is reachable and active. |
| `buy_housing_upgrade` | `() -> void` | Guards `housing_tier_index + 1 < Config.housing_tiers.size()` and `money >= cost`; deducts cost; increments `housing_tier_index` |
| `get_active_research_id` | `() -> String` | Iterates `Config.RESEARCH_ITEMS` in order; returns the id of the first item that is funded but not complete, or `""` if none. Used by Main.gd bubble spawning to pick bubble type |
| `get_research_cats` | `() -> int` | Returns `int(floor(float(cats) * research_cat_fraction))`; number of cats assigned to research. Drives research-point accumulation and the research slider split |
| `get_onlypaws_cats` | `() -> int` | Returns `cats - get_research_cats()`; number of cats contributing to OnlyPaws income |
| `get_cyborg_multiplier` | `() -> float` | Returns `pow(2.0, count)` where `count` is the number of cyborg research tiers completed (`cyborg_cats`, `cyborg_level_2`, `cyborg_level_3`, `cyborg_level_4`). Returns 1.0 when none are complete; 2× per completed tier (2×/4×/8×/16× at tiers 1–4). Applied to every cat's full income rate and to research point generation |
| `fund_research` | `(id: String) -> void` | Finds item in `Config.RESEARCH_ITEMS` by id; if `money >= fund_cost` and not yet funded: deducts cost, sets `research_funded[id] = true`, initialises `research_points[id] = 0.0` |
| `update_paws_rate` | `() -> void` | Computes `rate = (onlypaws_income_per_cat + onlypaws_income_per_bot * manager_bots + MEGA_BOT_INCOME_PER_CAT * mega_bots) * get_cyborg_multiplier()`, then `paws_income_rate = rate * float(get_onlypaws_cats())`. Must be called whenever cat count, bot/mega-bot count, cyborg research completion, or `research_cat_fraction` change. Called automatically at every research completion (including cyborg tiers) via `_process()` |
| `unlock_dog_attacks` | `() -> void` | Sets `dog_attack_unlocked = true`, transitions to WAITING, seeds `_dog_attack_timer = Config.DOG_ATTACK_FIRST_DELAY`. Called by Main.gd when the dog_defence unlock popup is dismissed |
| `get_cat_strength` | `() -> float` | Returns `float(cats) * get_cyborg_multiplier() * Config.DOG_ATTACK_STRATEGY_MODIFIER`. Example at 10 cats, no cyborg: 10.0 |
| `_roll_dog_strength` | `() -> float` | Private. Returns a randomized dog strength as a fraction of current cat strength. Both roll bounds scale with `cats / 10` and `housing_tier_index` so dogs get bolder with progression. Only called from `resolve_dog_attack()` |
| `resolve_dog_attack` | `() -> void` | Pre-calculates battle outcome (`cat_str >= dog_str` = win), applies pride delta (gain on win, loss on loss, clamped to 0), transitions to RESOLVING, emits `dog_attack_resolved`. Main.gd calls `schedule_next_dog_attack()` after visualization |
| `schedule_next_dog_attack` | `() -> void` | Computes next interval as `randf_range(DOG_ATTACK_INTERVAL_MIN, MAX) * pow(DOG_ATTACK_INTERVAL_SCALE, housing_tier_index)`, floored at 60s, transitions to WAITING. Called by Main.gd after the battle visualization finishes |

### Config (`res://Config.gd`)

Autoloaded singleton containing only `const` tuning values. No mutable state. Loaded before `GameState`.

| Constant | Type | Value | Description |
|---|---|---|---|
| `RESEARCH_ITEMS` | `Array` | 15 entries | Research item definitions. Each entry: `{id, name, subtitle, description, fund_cost: float, points_cost: float, min_cats_required: int, cat_intelligence_gain: int, min_housing_tier: int}`; some entries add optional `unlock_requires_cats: int` / `unlock_requires_research: String` keys. `min_housing_tier` is one of the gates on panel visibility in Main.gd's `_refresh_research_slots()` queued slot system (housing-tier gate + predecessor-complete gate + optional OR unlock gate + `Config.RESEARCH_MAX_VISIBLE` cap). Items 0–6 (original): `cat_power_unite` ($1,000 fund, 200 pts, 10 cats, +1 cat_intelligence, min_housing_tier 0); `ai_model_upgrade` ($2,000 fund, 1,200 pts, 1 cat, min_housing_tier 1; unlocks Mega Manager-Bots); `robo_shit_sweeper` ($4,000 fund, 2,400 pts, 1 cat, min_housing_tier 0; OR-gate: cats>=20); `cyborg_cats` ($3,000 fund, 1,800 pts, 1 cat, min_housing_tier 2, unlock_requires_cats:20; 2× global multiplier); `cyborg_level_2` ($6,000 fund, 3,000 pts, 1 cat, min_housing_tier 2; 4×); `cyborg_level_3` ($12,000 fund, 5,000 pts, 1 cat, min_housing_tier 2; 8×); `cyborg_level_4` ($25,000 fund, 10,000 pts, 1 cat, min_housing_tier 2; 16×). Items 7–14 (effects wired in GameState/Main via `_on_research_completed`): `cat_breeder_contract` ($30,000 fund, 10,000 pts, min_housing_tier 3; subtitle "−10% cat cost growth rate"); `cybernetic_poop_recyclers` ($50,000 fund, 15,000 pts, min_housing_tier 2; subtitle "Cats poop 50% less"); `burst_of_brilliance` ($40,000 fund, 12,000 pts, min_housing_tier 2; +5 cat_intelligence); `cat_breeders_contract` ($80,000 fund, 25,000 pts, min_housing_tier 3; subtitle "−20% cat cost growth rate"); `cat_enrichment_program` ($100,000 fund, 30,000 pts, min_housing_tier 3; subtitle "Unlocks Cat Toy Store"); `further_the_cat_race` ($150,000 fund, 50,000 pts, min_housing_tier 4; +10 cat_intelligence); `dog_defence` ($200,000 fund, 60,000 pts, min_housing_tier 4; +2 cat_intelligence); `research_your_own_llms` ($500,000 fund, 100,000 pts, min_housing_tier 5; subtitle "Token cost reduced to $10"). The `name`/`subtitle`/`description` values reference `Strings.RESEARCH_*` consts rather than inline literals. |
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
| `ROBO_SWEEPER_PURCHASE_COST` | `float` | `10000.0` | Base/first-sweeper cost; seeds `GameState.next_robo_sweeper_cost` |
| `ROBO_SWEEPER_COST_MULTIPLIER` | `float` | `3.0` | Each additional sweeper costs this multiple of the previous (3×); applied in `buy_robo_sweeper()` after each purchase. Cost sequence: $10,000 → $30,000 → $90,000 → … |
| `base_max_cats` | `int` | `10` | Baseline cat cap before any housing upgrades; used by `get_max_cats()` |
| `HOUSING_UPGRADE_PROMPT_THRESHOLD` | `int` | `8` | Cat count that fires the "cats are cramped" popup and reveals the Home tab; shared by GameState._process() and Main.gd._process() |
| `happiness_fifty_break_offset` | `int` | `2` | Cats over max_cats where happiness hits 50% (before housing bonus); ratio 2:5 with zero_break_offset |
| `happiness_zero_break_offset` | `int` | `5` | Cats over max_cats where happiness hits 0% (before housing bonus); ratio 2:5 with fifty_break_offset |
| `happiness_income_floor` | `float` | `0.90` | OnlyPaws income multiplier at 0% happiness (minimum penalty = 10% reduction); read by GameState._process() |
| `happiness_income_range` | `float` | `0.10` | Multiplier range added linearly on top of the floor up to 100% happiness; together with floor gives 0.90–1.00 range; read by GameState._process() |
| `housing_tiers` | `Array` | 11 entries | Housing upgrade chain; each entry has `id`, `label`, `cost`, `max_cats_increase`; labels reference `Strings.HOUSING_LABEL_*`. Original 5 tiers (indices 0–4): studio_basic (free, +0), studio_upgraded ($500, +10), bedroom_1 ($3,500, +10), bedroom_2 ($11,500, +10), bedroom_3 ($46,000, +10). New 6 tiers (indices 5–10): house ($150,000, +30), house_floor_2 ($500,000, +50), house_floor_3 ($1,500,000, +75), neighbor_house ($5,000,000, +100), whole_block ($25,000,000, +200), warehouse ($100,000,000, +500) |
| `ENRICHMENT_ITEMS` | `Array` | 5 entries | Enrichment store items unlocked by `cat_enrichment_program` research (wiring to UI is a future task); each entry: `{id, label, cost}`; label references `Strings.ENRICHMENT_*`; ids: diamond_litter_box ($1M), silk_cat_bed ($2.5M), cat_chandelier ($5M), personal_masseuse ($10M), cat_yacht ($50M) |
| `TOKEN_PACK_COST_OWN_LLM` | `float` | `10.0` | Token pack price once `research_your_own_llms` completes; referenced by `get_token_pack_cost()` in GameState as the highest-priority tier (cheapest) |
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
| `DOG_ATTACK_WARNING_DURATION` | `float` | `10.0` | Seconds cats hiss in WARNING state before battle resolves |
| `DOG_ATTACK_FIRST_DELAY` | `float` | `30.0` | Seconds after `unlock_dog_attacks()` before the first attack |
| `DOG_ATTACK_INTERVAL_MIN/MAX` | `float` | `300.0/600.0` | Base interval range between attacks (5–10 min); shrinks via `DOG_ATTACK_INTERVAL_SCALE` per housing tier |
| `DOG_ATTACK_INTERVAL_SCALE` | `float` | `0.92` | Interval multiplier per housing tier; dogs get bolder as player progresses |
| `DOG_STRENGTH_BASE_MIN/MAX` | `float` | `0.3/0.7` | Dog strength roll bounds as a fraction of `get_cat_strength()` |
| `DOG_STRENGTH_SCALE_CATS/HOUSING` | `float` | `0.08/0.12` | Additive scaling to both bounds per 10 cats and per housing tier |
| `PRIDE_GAIN_WIN` / `PRIDE_LOSS_LOSE` | `int` | `5/3` | Pride delta on win/loss |
| `DOG_ATTACK_STRATEGY_MODIFIER` | `float` | `1.0` | Multiplier applied to cat strength; future stances will vary this |

### Strings (`res://Strings.gd`)

Autoloaded singleton holding **every user-visible string** as a named `const` (registered in `project.godot` after `Config`, before `GameState`). No mutable state.
Edit this one file to change any displayed text. Sections:

- **HUD templates** (`HUD_MONEY`, `HUD_CATS`, `HUD_TOKENS`, `HUD_BOTS`, `HUD_MEGA_BOTS`, `HUD_ONLY_PAWS_RATE`, `HUD_CAT_FOOD`, `HUD_RESEARCH_CATS`, `HUD_CAT_INTELLIGENCE`) — use `%s`/`%.2f` slots filled via the `%` operator in `_process()`.
- **Research panel state** (`RESEARCH_NO_ACTIVE`, `RESEARCH_IN_PROGRESS`, `RESEARCH_NEEDS_CATS`).
- **Buttons** — static labels (`BTN_OK` = "OK", `BTN_EARN_MONEY`, `BTN_ONLY_PAWS`, `BTN_ONLY_PAWS_ON/OFF`), per-frame cost templates (`BTN_PURCHASE_CAT`, `BTN_MANAGER_BOT`, `BTN_MEGA_BOT`, `BTN_BUY_FOOD`(`_AUTO`), `BTN_BUY_TOKENS`(`_AUTO`), `BTN_FUND_RESEARCH`), and shop items with embedded cost (`BTN_AUTO_FEEDER`, `BTN_BOT_MANAGER`, `BTN_PAWSCO`, `BTN_AI_ENTERPRISE` use `\n$%s`; `BTN_ROBO_SWEEPER` uses inline `($%s)`).
- **Housing tier labels** (`BTN_HOUSING_UPGRADE` = `"%s\n$%s"` template for the shop button; `HOUSING_LABEL_STUDIO_BASIC`, `HOUSING_LABEL_STUDIO_UPGRADED`, `HOUSING_LABEL_BEDROOM_1/2/3`; new tiers: `HOUSING_LABEL_HOUSE`, `HOUSING_LABEL_HOUSE_FLOOR_2`, `HOUSING_LABEL_HOUSE_FLOOR_3`, `HOUSING_LABEL_NEIGHBOR_HOUSE`, `HOUSING_LABEL_WHOLE_BLOCK`, `HOUSING_LABEL_WAREHOUSE`) — referenced by `Config.housing_tiers` array and displayed in Main.gd's housing shop button via `Strings.BTN_HOUSING_UPGRADE % [label, cost]`.
- **Bubbles** (`BUBBLE_VIRAL` = 💰, `BUBBLE_INSPIRATION` = 💡).
- **Poop** (`POOP_EMOJI` = 💩) — glyph shown on the clickable poop button.
- **Robo-Shit Sweeper** (`SWEEPER_EMOJI` = 🤖) — glyph shown on the autonomous sweeper Node2D's label.
- **Developer debug menu** (`DEBUG_MENU_TITLE` = "Debug Menu", `DEBUG_POOP_OFF_LABEL` = "Poop Off", `DEBUG_GRANT_10K` = "Grant $10,000", `DEBUG_GRANT_100K` = "Grant $100,000", `DEBUG_GRANT_1M` = "Grant $1,000,000", `DEBUG_AUTOCOMPLETE_RESEARCH` = "Autocomplete Research") — title, toggle, and action button labels for the code-only debug overlay.
- **Research panel separator** (`RESEARCH_NAME_SUBTITLE_SEP` = " — ") — inserted between item name and subtitle in the research panel name label; moved out of inline concatenation.
- **Research item copy** — original 7: `RESEARCH_CAT_POWER_NAME/SUB/DESC`, `RESEARCH_AI_MODEL_NAME/SUB/DESC`, `RESEARCH_ROBO_SWEEPER_NAME/SUB/DESC`, `RESEARCH_CYBORG_NAME/SUB/DESC`, `RESEARCH_CYBORG_L2_NAME/SUB/DESC`, `RESEARCH_CYBORG_L3_NAME/SUB/DESC`, `RESEARCH_CYBORG_L4_NAME/SUB/DESC`; new 8: `RESEARCH_BREEDER_CONTRACT_NAME/SUB/DESC`, `RESEARCH_POOP_RECYCLER_NAME/SUB/DESC`, `RESEARCH_BURST_BRILLIANCE_NAME/SUB/DESC`, `RESEARCH_BREEDERS_CONTRACT_NAME/SUB/DESC`, `RESEARCH_ENRICHMENT_NAME/SUB/DESC`, `RESEARCH_FURTHER_CAT_RACE_NAME/SUB/DESC`, `RESEARCH_DOG_DEFENCE_NAME/SUB/DESC`, `RESEARCH_OWN_LLMS_NAME/SUB/DESC` — all referenced directly by `Config.RESEARCH_ITEMS`; a `const` cross-autoload reference. `RESEARCH_NAMES: Dictionary` maps all 15 item ids → display name for the active-research label.
- **Enrichment store items** (`ENRICHMENT_DIAMOND_LITTER`, `ENRICHMENT_SILK_BED`, `ENRICHMENT_CHANDELIER`, `ENRICHMENT_MASSEUSE`, `ENRICHMENT_YACHT`) — referenced by `Config.ENRICHMENT_ITEMS`; displayed as button labels in the enrichment store panel.
- **Popups** (`POPUP_*`, incl. `POPUP_CYBORG` for the Cyborg Cats achievement) — the body text of every scene popup. `_ready()` overrides each `Main.tscn` PopupLabel from these consts via `_set_popup_text()`, so the `.tscn` text is now editor-placeholder only. Text matches the original `.tscn` copy exactly (centralization was a pure refactor, no visible change). `POPUP_VIRAL`, `POPUP_AI_OVERLORDS`, and `POPUP_INSPIRATION` are used only by the in-code popup builders (`_show_*_popup()`). Every `POPUP_*` constant now follows the `NEW ACHIEVEMENT: <title>\n\n<flavor>\n\nREWARD: <name>\n\n<description>` template.

### Util (`res://autoloads/Util.gd`)

Autoloaded singleton containing stateless helper functions. No mutable state.

| Function | Signature | Description |
|---|---|---|
| `format_number` | `(value: float) -> String` | Returns the integer portion of `value` formatted with comma separators (e.g. `1000.0` → `"1,000"`). Never uses scientific notation. |

---

### CatCharacter (`res://scripts/CatCharacter.gd`)

Sprite-based cat with autonomous wander behaviour and randomized color on spawn.

Color-variant system: `const COLOR_VARIANTS: Array[SpriteFrames]` preloads `cat_frames_1.tres` through `cat_frames_5.tres` from `res://assets/cats/`. In `_ready()`, the script picks one at random (`randi() % 5`) and assigns it to `AnimatedSprite2D.sprite_frames`, then plays `"idle"`. All five .tres files define identical animations (`"idle"` 19 frames, `"walk"` 25 frames, 6 fps, loop=true) and only differ in their atlas texture paths (`cat_N.png` / `cat_walk_N.png`). The script never builds or mutates SpriteFrames data — variant selection is the only SpriteFrames assignment.

Wander state machine (`enum State { IDLE, WALKING, HISSING }`):
- `_ready()` picks a random color variant (see above), then seeds `_wander_timer` with `randf_range(Config.CAT_WANDER_MIN, CAT_WANDER_MAX)`.
- `_bounds: Rect2` — injected via `set_bounds(rect)` by Main after `add_child`; falls back to `get_viewport_rect()` if never set. Wander targets are always computed inside this rect.
- `set_bounds(rect: Rect2) -> void` — public method; stores `rect` in `_bounds`. Called once per cat at purchase time with `center_panel.get_global_rect()` so bounds are stable regardless of DogBattlePanel visibility.
- `_process(delta)`: returns early while `_bubble_paused` (no movement, no timer tick). Otherwise counts `_wander_timer` down; on expiry picks a new `_target_pos` inside `_bounds` (40px inset, top 10% excluded — same formula as `_place_cat`), enters `WALKING`, re-rolls the timer, flips `AnimatedSprite2D.flip_h` toward the target, and plays `"walk"`. While `WALKING`, moves toward `_target_pos` at `Config.CAT_MOVE_SPEED` px/s; on arrival snaps to target, returns to `IDLE`, and plays `"idle"`.
- `pause_for_bubble()`: sets `_bubble_paused = true`, forces `IDLE`, plays `"idle"`. Called by Main.gd only for **viral** bubbles spawned over this cat.
- `resume_from_bubble()`: clears `_bubble_paused` and re-rolls `_wander_timer`. Called by Main.gd when a bubble over this cat is collected or expires.
- `start_hissing()`: public; sets `_state = HISSING`, plays `"idle"` (TODO: swap for `"hiss"` animation when sprite sheet is ready). Freezes movement and wander timer. Composes with `_bubble_paused` — a cat can be both bubble-paused and hissing simultaneously; the `_bubble_paused` guard fires first in `_process()`.
- `stop_hissing()`: public; returns to `IDLE`, plays `"idle"`, re-rolls `_wander_timer`. Called by Main.gd's `_on_dog_attack_resolved` cleanup after battle animation finishes.
- `_play_anim(name)`: private; plays the named animation only if the `AnimatedSprite2D` exists and its SpriteFrames defines that animation, else leaves the current animation unchanged. SpriteFrames defines `"idle"` (19 frames, 6 fps, loop) and `"walk"` (25 frames, 6 fps, loop) — both backed by the active color-variant resource assigned in `_ready()`.

Scene tree:
```
CatCharacter (Node2D) ← CatCharacter.gd (wander state machine)
└── AnimatedSprite2D  ← SpriteFrames and animations set up in editor
```

---

### Main UI (`res://scenes/Main.gd`)

Drives the root scene. Reads from and delegates to `GameState`; the only local mutable state is UI-latch flags (including `_enrichment_store_shown`) plus the bubble mechanic's `_cat_bubble_timers` (Dictionary: cat `instance_id` → seconds remaining), `_active_bubbles` (Array of `{node, timer, type, research_id, cat_node}` dicts), the global burst-window state (`_burst_window_active`, `_burst_window_timer`, `_global_cd_timer`), and the poop mechanic's `_cat_poop_timers` (Dictionary: cat `instance_id` → seconds remaining; same structure as `_cat_bubble_timers`) and `_active_poops` (Array of `{node}` dicts), and the Robo-Shit Sweeper collection `_sweepers` (Array[Dictionary]; one entry per purchased sweeper, each `{node: Node2D, label: Label, state: int, target: Dictionary, clean_timer: float}`; `SweeperState` enum has MOVING/CLEANING; new sweeper Node2Ds are built by `_spawn_sweeper_instance()` and appended here as `robo_sweeper_count` grows; each sweeper's `target` holds a `_active_poops` entry or `{}` when idle), and the developer debug menu (`_debug_panel`/`_debug_poop_check` built in `_ready()` as a code-only overlay never added to Main.tscn, `_debug_menu_visible`, `_debug_poop_disabled`). Additional shop buttons: `_enrichment_store_button` (created in `_ready()`, hidden until `enrichment_store_unlocked`, `shop_cost` meta = 999999999.0 so it sorts last).

| Method | Description |
|---|---|
| `_ready()` | First sets `ThemeDB.fallback_font_size = Config.UI_BASE_FONT_SIZE` (22) so every label/button inherits the base; connects `cat_purchased` → `_on_cat_purchased`, `cat_lost` → `_on_cat_lost`, `research_completed` → `_on_research_completed`; builds per-item research panels in `ResearchItemList` from `Config.RESEARCH_ITEMS` (PanelContainer → VBoxContainer → NameLabel, DescriptionLabel, FundButton, ProgressLabel); stores refs in `_research_panels`, `_research_fund_buttons`, `_research_progress_labels`, `_research_panel_hidden`, and `_research_panel_unlocked` (false per item; **every panel starts `visible = false`** so `_refresh_research_slots()` is the sole authority that reveals eligible panels — this prevents tier-0 items other than `cat_power_unite`, e.g. `robo_shit_sweeper`, from showing before the global `cat_power_unite` gate is satisfied, since that gate only adds visibility and never hides); finally overrides all static scene-node text from `Strings` consts — `EarnMoneyButton`, `OnlyPawsButton`, the four dynamic shop-button labels (via `Strings.BTN_*`), and every popup body via `_set_popup_text()`; applies `_style_as_header()` to `%CatsLabel`, `%HappinessTitleLabel`, and `%ShopLabel`; finally calls `_refresh_research_slots()` so any immediately-eligible research panels show without waiting for the first frame |
| `_set_popup_text(popup, body)` | Sets `popup`'s body Label text; all popups share the inner path `DialogPanel/VBoxContainer/PopupLabel` |
| `_style_as_header(label)` | Applies the section-header style to a Label: `UI_HEADER_FONT_SIZE` (28) font-size override + a bold (`font_weight = 700`) `SystemFont` override |
| `_process(delta)` | **Popup queue discipline:** every popup trigger block (first_cat, only_paws, bot_unlock, upgrades_tab, bot_manager_unlock, starvation 1/2/recurring, happiness_cramped/riot, viral) is wrapped in an inner `if not get_tree().paused:` guard and only sets its shown-flag when the popup is actually displayed — so if multiple conditions become true on the same frame, popups show one at a time (the later condition stays true and re-fires the frame after the earlier popup is dismissed) instead of stacking. Updates all labels every frame; one-time visibility latches for `only_paws_unlocked`, `bot_shop_unlocked`, `home_shop_unlocked`, `housing_tier_index >= 1` (reveals CenterColumn), and `bot_manager_unlocked OR auto_feeder_unlocked`; shows `OnlyPawsPopup` and pauses tree the first time `only_paws_unlocked` triggers; updates `CatFoodLabel`; sets `OnlyPawsButton` label and modulate; `PurchaseCatButton` and `ManagerBotButton` cost labels use `Util.format_number()` (`PurchaseCatButton.disabled` is now gated on `GameState.cats >= GameState.get_max_cats()` — the hard cat cap — replacing the former `get_happiness() <= 0.0` gate); reveals `MegaManagerBotButton` + `MegaBotsRateLabel` via one-way latch once `research_complete["ai_model_upgrade"]` is true, updating the button's `Mega-Bot ($X)` label/disabled state and the `Mega-Bots: X` count each frame; calls `_refresh_research_slots()` each frame to reveal eligible research panels via the queued slot system (global `cat_power_unite`-complete gate that hides every other panel until the first item finishes, then housing-tier + predecessor-complete gates, `Config.RESEARCH_MAX_VISIBLE` cap); `OnlyPawsIncomeLabel` shows `paws_income_rate` when `bots_active`, else `get_onlypaws_cats() * Config.onlypaws_income_per_cat` (matches effective income rate used by GameState); updates `HappinessBar` value and fill colour (red→green via `Color.lerp`); updates `ResearchActiveLabel`, `ResearchProgressBar`, `ResearchCatsLabel` every frame; shows cramped/riot popups when triggered; updates housing chain display; one-way latch fires the whale popup via `_show_viral_popup()` the instant `GameState.viral_bubbles_unlocked` flips (sets `viral_popup_shown`); ticks the global burst window (when closed, counts `_global_cd_timer` down and, on reaching 0, opens a window of `randf_range(BUBBLE_BURST_WINDOW_MIN, MAX)`; when open, counts `_burst_window_timer` down and, on reaching 0, closes and re-rolls `_global_cd_timer` to `randf_range(BUBBLE_GLOBAL_CD_MIN, MAX)`); decrements each entry in `_cat_bubble_timers` by `delta` and, when a cat's timer expires, always resets it to a new `randf_range(BUBBLE_SPAWN_MIN, BUBBLE_SPAWN_MAX)` but only spawns (finds the cat node by `instance_id` and calls `_try_spawn_bubble_for_cat(cat_node)`) if `_burst_window_active` — triggers that miss the window are discarded, never queued; **poop timers** (no burst window — unconditional): decrements each entry in `_cat_poop_timers` by `delta` and, when a cat's timer expires, resets it to a new `randf_range(POOP_SPAWN_MIN, POOP_SPAWN_MAX)` and calls `_spawn_poop(cat_node)` (cat found by `instance_id`) **unless `_debug_poop_disabled`** is set via the debug menu — the timer still ticks and resets so toggling poop back on resumes the normal cadence rather than firing all cats at once; calls `_process_sweeper(delta)` immediately after the poop timers to drive the Robo-Shit Sweeper state machine; advances each active bubble's timer, fades its alpha to `1.0 - timer/BUBBLE_LIFETIME`, and frees/removes it once `timer >= BUBBLE_LIFETIME` (calling `bubble.cat_node.resume_from_bubble()` on expiry if that cat is still valid) |
| `_sort_shop_list` | `() -> void` | Private; updates dynamic `shop_cost` metadata (housing next-tier cost, manager-bot live cost) then sorts `ShopList` children ascending by `shop_cost`; invisible items sink to bottom; called whenever any item's visibility changes |
| `_on_earn_money_button_pressed()` | Calls `GameState.click()` |
| `_on_purchase_cat_button_pressed()` | Calls `GameState.buy_cat()` |
| `_on_only_paws_button_pressed()` | Flips `GameState.only_paws_active`; turning OFF sets `bots_active = false`; turning ON re-enables bots if `tokens > 0` |
| `_on_only_paws_popup_ok_pressed()` | Hides `OnlyPawsPopup` and unpauses tree |
| `_on_manager_bot_button_pressed()` | Calls `GameState.buy_bot()` |
| `_on_mega_manager_bot_button_pressed()` | Calls `GameState.buy_mega_bot()` |
| `_on_cat_purchased()` | Instantiates `CatCharacter` at scale 0.4, adds to `CatContainer`, calls `cat.set_bounds(center_panel.get_global_rect())` to inject the play-area rect (uses `center_panel` rather than `cat_play_area` so bounds are stable even if a battle is active and DogBattlePanel is visible), calls `_place_cat(cat)`, and registers the cat in `_cat_bubble_timers` and `_cat_poop_timers` with initial random cooldowns |
| `_on_cat_lost()` | Removes the last **non-cyborg** `CatContainer` child (scans from the back, skipping ids in `_cyborg_cat_ids`; falls back to the last child only if all remaining are cyborgs), since `cat_lost` only decrements the normal `cats` count: erases its `instance_id` from `_cat_bubble_timers`, `_cat_poop_timers`, and `_cyborg_cat_ids`, then `queue_free()`s the node. Then iterates `_sweepers` and resets any whose `target` is no longer in `_active_poops` to MOVING with empty target, so no sweeper chases a freed node |
| `_unhandled_key_input(event)` | Toggles the developer debug menu when the backtick key (`KEY_QUOTELEFT`) is pressed (non-echo). Flips `_debug_menu_visible`/`_debug_panel.visible` and calls `get_viewport().set_input_as_handled()`. Uses `_unhandled_key_input` (not `_input`/`_gui_input`) so it only sees keys no control consumed and never interferes with existing input/`gui_input` handlers |
| `_on_debug_poop_toggled(pressed)` | Debug menu "Poop Off" `CheckButton` handler; sets `_debug_poop_disabled = pressed`, which gates the `_spawn_poop()` call in the `_process()` poop-timer loop (timers keep ticking) |
| `_on_debug_grant_10k()` | Debug menu handler; adds $10,000 to `GameState.money` |
| `_on_debug_grant_100k()` | Debug menu handler; adds $100,000 to `GameState.money` |
| `_on_debug_grant_1m()` | Debug menu handler; adds $1,000,000 to `GameState.money` |
| `_on_debug_autocomplete_research()` | Debug menu handler; for each `Config.RESEARCH_ITEMS` entry that is funded but not yet complete, directly completes it: sets `research_points`, `research_complete`, adds `cat_intelligence`, calls `update_paws_rate()`, and emits `research_completed`. Bypasses `min_cats_required` so it works even with too few cats assigned. Does NOT auto-fund items |
| `_process_sweeper(delta)` | Loops over `_sweepers` and runs each entry's state machine. **MOVING:** idles if `_active_poops` is empty; discards stale `target` (player-clicked poop removed from `_active_poops`); only picks a new target when `target` is empty — builds a claim set of poop instance_ids held by other sweepers, then selects the nearest unclaimed poop; once a target is committed, `move_toward`s it at `Config.SWEEPER_MOVE_SPEED * delta` and enters CLEANING when within 8px. **CLEANING:** counts `clean_timer` down; at 0, if the target is still in `_active_poops` removes it via `_on_poop_pressed()`, then clears target and returns to MOVING. Each sweeper commits to its target for the full approach — no zig-zagging. Two sweepers never target the same poop because the claim set excludes all other sweepers' active targets |
| `_spawn_sweeper_instance()` | Builds one sweeper Node2D + Label (emoji `Strings.SWEEPER_EMOJI`, font 40, centered at -20,-20), positioned at `center_panel.get_global_rect().get_center()`, adds it to Main (above PanelLayout in draw order), and appends a `{node, label, state: MOVING, target: {}, clean_timer: 0.0}` dict to `_sweepers`. Called by `_process()` inside a `while _sweepers.size() < GameState.robo_sweeper_count` loop so newly-purchased sweepers appear the same frame they are bought |
| `_spawn_poop(cat_node)` | Creates a clickable poop Button (text `Strings.POOP_EMOJI` 💩, `font_size` 36, `custom_minimum_size` 64×64) at `cat_node.global_position + Vector2(randf_range(-40,40), randf_range(10,30))`, `z_index = 50`, child of Main; stores a `{node}` dict in `_active_poops`, binds `pressed` → `_on_poop_pressed(poop)`, and increments `GameState.poop_count`. Poop does **not** expire automatically — it persists until clicked |
| `_on_poop_pressed(poop)` | Removes the poop from `_active_poops`, `queue_free()`s its node, and decrements `GameState.poop_count` (clamped at 0 via `max`) |
| `_on_buy_cat_food_x1_button_pressed()` | Calls `GameState.buy_cat_food_pack(1)` |
| `_on_buy_cat_food_x10_button_pressed()` | Calls `GameState.buy_cat_food_pack(10)` |
| `_on_buy_token_x1_button_pressed()` | Calls `GameState.buy_tokens(1)` |
| `_on_buy_token_x10_button_pressed()` | Calls `GameState.buy_tokens(10)` |
| `_on_buy_bot_manager_button_pressed()` | Calls `GameState.buy_bot_manager()` |
| `_place_cat(cat: Node2D)` | Places a newly added cat at a random position inside `center_panel.get_global_rect()`: 40 px inset, top 10% excluded. Uses `center_panel` (not `cat_play_area`) so placement is stable regardless of DogBattlePanel visibility. Up to 30 attempts to avoid existing cats (64 px radius). Falls back to an unconstrained position within the same bounds. |
| `_try_spawn_bubble_for_cat(cat_node)` | Spawn guard called when a specific cat's cooldown expires. Returns early (no spawn) if any of: `GameState.viral_bubbles_unlocked == false`, `GameState.only_paws_active == false`, or `_active_bubbles.size() >= Config.BUBBLE_MAX_ON_SCREEN`. Otherwise calls `_spawn_bubble(cat_node)` |
| `_spawn_bubble(cat_node, force_type = "")` | Picks bubble type: if `force_type` is non-empty it is used directly (skipping selection); else `"viral"` when no research is active (`GameState.get_active_research_id() == ""`), otherwise `"inspiration"` with probability `research_cat_fraction`, else `"viral"`. Creates a clickable Button over `cat_node` (text `"💰"` viral / `"💡"` inspiration; `font_size` override `roundi(Config.UI_BASE_FONT_SIZE * 2.2)`, `custom_minimum_size` 80×80), positioned at `cat_node.global_position + Vector2(randf_range(-30,30), randf_range(-50,-20))`, `z_index = 100` (renders in front of all UI panels), child of Main; stores a `{node, timer, type, research_id, cat_node}` dict in `_active_bubbles` and binds `gui_input` → `_on_bubble_gui_input(event, bubble)`. `research_id` is captured at spawn so collection still works if research changes mid-flight. After appending, if the type is `"viral"` and `cat_node` is valid, calls `cat_node.pause_for_bubble()` to freeze that cat (inspiration bubbles do not pause) |
| `_show_viral_popup()` | Builds the one-time "Whale Hunting Baby!" achievement popup entirely in code (full-screen `ColorRect` overlay with `process_mode = WHEN_PAUSED` and `z_index = 20` → `CenterContainer` → `PanelContainer` → `VBoxContainer` with an autowrapped `Label` and OK `Button`); pauses the tree on show; OK button frees the overlay, unpauses, and calls `_force_first_viral_bubble()` |
| `_on_research_completed(id)` | Hides and latches the completed item's panel (`_research_panel_hidden[id] = true`), then calls `_refresh_research_slots()`. Dispatch by id: `ai_model_upgrade` → `_show_ai_overlords_popup()`; `cyborg_cats` → `_show_cyborg_popup()`; `cat_breeder_contract` → `GameState.multiply_cat_cost_growth(0.9)`; `cat_breeders_contract` → `GameState.multiply_cat_cost_growth(0.8)`; `cybernetic_poop_recyclers` → `GameState.set_poop_recyclers_researched()` + re-roll all `_cat_poop_timers` × `Config.POOP_RECYCLER_INTERVAL_MULTIPLIER`; `cat_enrichment_program` → `GameState.unlock_enrichment_store()`; `further_the_cat_race` → `_trigger_glitch_effect()`; `research_your_own_llms` → `GameState.set_own_llm_researched()` + `_trigger_glitch_effect()`; `dog_defence` → `_show_dog_attack_unlock_popup()` |
| `_show_dog_attack_unlock_popup()` | Builds the one-time "Self-Fulfilling Prophecy" achievement popup in code (full-screen overlay, 600×360 dialog, process_mode=WHEN_PAUSED, z_index=20, pauses tree). OK button frees overlay, unpauses, then calls `GameState.unlock_dog_attacks()`. Text uses `Strings.POPUP_DOG_ATTACK_UNLOCK_TITLE` + `Strings.POPUP_DOG_ATTACK_UNLOCK_BODY` |
| `_on_dog_attack_warning_started()` | Signal handler; calls `start_hissing()` on every cat in `cat_container`, then shows `battle_warning_label` and hides `battle_result_label`. `DogBattlePanel` visibility is driven by `_process()` from `dog_attack_state`, not set here |
| `_on_dog_attack_resolved(player_won, pride_delta)` | Signal handler; runs the full battle visualization: hides `battle_warning_label`; distributes cat emoji Labels across TopLane/MiddleLane/BottomLane Controls (lane-local positions), and creates dog emoji Labels at each lane's right edge; tweens dogs in from right over 1.5s; after arrival fades losers, shows `battle_result_label` for 2s via chained tweens. On completion hides `battle_result_label`, `queue_free()`s all dynamic lane labels, calls `stop_hissing()` on all cats, and calls `GameState.schedule_next_dog_attack()` (which transitions state to WAITING, causing `_process()` to hide `DogBattlePanel` next frame) |
| `_show_cyborg_popup()` | Builds the one-time "Resistance Is Fur-tile" achievement popup in code, mirroring `_show_ai_overlords_popup()` (600×360 `PanelContainer`); pauses the tree on show; OK button frees the overlay and unpauses. Fired exactly once when `cyborg_cats` research completes |
| `_show_ai_overlords_popup()` | Builds the one-time "AI Overlords" achievement popup in code, mirroring `_show_viral_popup()` but with a 600×360 `PanelContainer`; pauses the tree on show; OK button frees the overlay and unpauses |
| `_show_inspiration_popup()` | Builds the one-time inspiration-bubble popup in code, mirroring `_show_viral_popup()` (overlay → CenterContainer → PanelContainer → VBox → autowrapped `Strings.POPUP_INSPIRATION` label + OK); pauses on show; OK frees the overlay and unpauses. Gated by `GameState.inspiration_popup_shown` so it fires exactly once |
| `_force_first_viral_bubble()` | Called once when the viral popup is dismissed. Picks a random `CatContainer` child (returns if none) and calls `_spawn_bubble(cat_node, "viral")`, bypassing every guard (burst window, `viral_bubbles_unlocked`, `BUBBLE_MAX_ON_SCREEN`) so the player sees their first bubble immediately. Normal burst-window scheduling resumes afterward |
| `_trigger_glitch_effect()` | Builds a cyan full-rect `ColorRect` (z_index=200, `MOUSE_FILTER_IGNORE`, `PROCESS_MODE_ALWAYS`), then runs a 5-flicker alpha tween (0.05s each step, `TWEEN_PAUSE_PROCESS` so it runs even when tree is paused) and frees the rect when complete. Called on `further_the_cat_race` and `research_your_own_llms` completions. No tree pause |
| `_show_enrichment_store()` | Builds and shows a code-built enrichment store overlay (full-screen ColorRect, pauses tree, z_index=20). Panel contains a title, subtitle, one Button per `Config.ENRICHMENT_ITEMS` entry (disabled + `[Owned]` suffix if already purchased, disabled if unaffordable at open time), and a Close button. Built fresh each open so `GameState.enrichment_purchases` is always reflected. Purchase handler: `_on_enrichment_purchase()` |
| `_on_enrichment_purchase(id, cost, btn, overlay)` | Calls `GameState.buy_enrichment(id, cost)`. On success: disables `btn` and appends `Strings.ENRICHMENT_STORE_OWNED`. On failure (auto-buys drained money while store was paused): disables `btn` with no owned suffix, providing feedback without crashing |
| `_on_bubble_gui_input(event, bubble)` | On a left mouse-button press (`InputEventMouseButton`, `MOUSE_BUTTON_LEFT`, `pressed`): collects the clicked `bubble` via `_on_bubble_pressed`, then reads the cursor position (`get_viewport().get_mouse_position()`) and collects every other bubble in `_active_bubbles` whose `node.get_global_rect().has_point(click_pos)` — so one click harvests all bubbles stacked at that spot (intentional) |
| `_on_bubble_pressed(bubble)` | Removes the bubble from `_active_bubbles`; if `bubble.cat_node` is still valid, calls `resume_from_bubble()` on it; then frees its node. Viral: adds `max(per_cat_rate × Config.BUBBLE_VIRAL_MULTIPLIER, 1.0)` to `GameState.money`, where `per_cat_rate = onlypaws_income_per_cat + onlypaws_income_per_bot × manager_bots + MEGA_BOT_INCOME_PER_CAT × mega_bots` — **one cat's** $/sec, not the total across all cats (one cat went viral). Inspiration: if `bubble.research_id` is still funded and not complete, adds `max(1.0 × Config.BUBBLE_INSPIRATION_SECONDS, 1.0)` to `research_points[id]` (**one cat's** research contribution, not all research cats), clamped to the item's `points_cost`; on the first such successful award (gated by `GameState.inspiration_popup_shown`), sets that flag and calls `_show_inspiration_popup()` |
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
- [x] **Cat spawning** — each purchase instances `CatCharacter` at scale 0.4 into `CatContainer` (child of CatPlayArea); `set_bounds(center_panel.get_global_rect())` is injected at spawn so bounds are stable during battles; placed at a random position within CenterPanel bounds (40 px inset, top 10% excluded) avoiding other cats (64 px radius)
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
- [x] **Cat Happiness** — poop-driven value 0–100%; `100.0` while `cats <= 0` or `poop_count <= 0`, otherwise `100 * (1 - t^2)` where `t = clamp((poop_count / cats) / Config.POOP_MAX_RATIO, 0, 1)` (ratio 1.0 ≈ 89%, 2.0 ≈ 56%, 3.0 = 0%). Always-visible progress bar at top-centre; fill colour transitions red→green via lerp; applies continuous income multiplier `happiness_income_floor + (happiness / 100) * happiness_income_range` (0.90 at 0% → 1.00 at 100%; maximum penalty is a 10% income reduction); riot popup appears once when happiness first hits 0%, sets `happiness_riot_triggered`. (The former over-max two-segment quadratic decay model, cat-loss drain, and Cat Crusher mechanic were all removed; `_happiness_breakpoints()` is now unused.)
- [x] **Cramped popup** — shown once when `cats >= Config.HOUSING_UPGRADE_PROMPT_THRESHOLD` (8 cats); pauses game loop; on dismiss sets `home_shop_unlocked = true`
- [x] **Bubble mechanic** — clickable floating Button bubbles spawn over individual cats. Each cat runs its own randomized cooldown (`_cat_bubble_timers`, keyed by `instance_id`) of `randf_range(Config.BUBBLE_SPAWN_MIN, BUBBLE_SPAWN_MAX)` = 5–15s, registered on purchase and erased on loss; when a cat's timer expires it always resets but only attempts a spawn if a global **burst window** is currently open. The screen alternates between an idle global cooldown (`BUBBLE_GLOBAL_CD_MIN..MAX` = 20–40s, no spawns) and a brief open burst window (`BUBBLE_BURST_WINDOW_MIN..MAX` = 2–10s) during which expiring per-cat timers may fire; the first window does not open immediately on start. Triggers that land outside a window are discarded, never queued. Capped at `BUBBLE_MAX_ON_SCREEN` (4) total. Gated behind `viral_bubbles_unlocked` (set 20s after the **second** Manager-Bot is owned) and `only_paws_active`. Two types: Viral (💰, reward = one cat's $/sec `per_cat_rate × 4`, min $1) and Inspiration (💡, reward = one cat's contribution `1 × 3` research points, min 1, clamped to `points_cost`). Rewards reflect the single cat that spawned the bubble, not the whole population. Viral always spawns when no research is active; with active research, Inspiration spawns with probability `research_cat_fraction` else Viral. The one-time "Whale Hunting Baby!" achievement popup (built in code, pauses tree) fires from a `_process` latch the instant the mechanic unlocks — not from the spawn pipeline — so it appears right at unlock rather than waiting for a random burst window. Dismissing it calls `_force_first_viral_bubble()`, which spawns one guaranteed viral bubble immediately (bypassing all guards), after which normal burst-window scheduling takes over. Bubbles fade out over `BUBBLE_LIFETIME` (4.5s) and disappear if not clicked. Bubble Buttons are large (font `roundi(UI_BASE_FONT_SIZE × 2.2)`, 80×80 min size) and use `z_index = 100` to render in front of all UI; a left-click collects the clicked bubble plus any other bubbles stacked under the cursor in one click (via `gui_input` + `get_global_rect().has_point`). Created in code (no scene file), children of Main. While a **viral** bubble is live over a cat, that cat is frozen via `pause_for_bubble()` and resumes (`resume_from_bubble()`) when the bubble is collected or expires
- [x] **Cyborg Research Tiers** — four global research upgrades (`cyborg_cats` → `cyborg_level_2` → `cyborg_level_3` → `cyborg_level_4`; fund costs $3k/$6k/$12k/$25k; points costs 1,800/3,000/5,000/10,000; all require min_housing_tier 2). Each completed tier doubles the global `get_cyborg_multiplier()` — `pow(2.0, count)` where count = tiers complete. Multiplier applies to every cat's full income rate (base + bot + mega-bot contributions) via `update_paws_rate()` and to research point generation each tick. `cyborg_cats` completion fires the "Resistance Is Fur-tile" achievement popup (code-built, same pattern as ai_overlords). All four cats poop equally; no conversion cost; no per-cat levels. Slider assigns all cats to research/income proportionally as before
- [x] **Cat wandering** — each `CatCharacter` autonomously wanders inside its injected `_bounds` rect (set to `center_panel.get_global_rect()` at spawn): after a 25–60s idle, it picks a random destination (40px inset, top 10% excluded) and walks there at 40 px/s, flipping its sprite toward the target. Movement and the wander timer freeze while a viral money bubble is active above the cat
- [x] **Dog Attack system** — passive auto-battler mini-game that unlocks when the `dog_defence` research popup is dismissed. `GameState` runs a four-state machine (IDLE → WAITING → WARNING → RESOLVING). After `DOG_ATTACK_FIRST_DELAY` (30s), a 10s WARNING phase begins: cats freeze in a hissing state (`CatCharacter.start_hissing()`) and `WarningLabel` shows inside `DogBattlePanel`. When WARNING expires, `resolve_dog_attack()` pre-calculates outcome as `get_cat_strength() >= _roll_dog_strength()`: cat strength = `cats × cyborg_multiplier × strategy_modifier`; dog strength is a fraction of cat strength with both bounds rising with cats and housing tier. Player wins apply `+Config.PRIDE_GAIN_WIN` (5) to `pride`; losses apply `-Config.PRIDE_LOSS_LOSE` (3) (clamped to 0). The `dog_attack_resolved` signal triggers Main.gd's battle visualization: cat emoji labels in `TopLane`/`MiddleLane`/`BottomLane` Controls, dog emoji labels tweened in from each lane's right edge over 1.5s, then losers fade out, `ResultLabel` shows for 2s, then cleanup and `schedule_next_dog_attack()`. `DogBattlePanel.visible` is driven frame-by-frame in `_process()` from `GameState.dog_attack_state` (visible during WARNING and RESOLVING only). Interval between attacks shrinks via `pow(DOG_ATTACK_INTERVAL_SCALE, housing_tier_index)` as the player progresses, floored at 60s. `PrideLabel` in the left panel shows `Pride: X` hidden until unlock. Dog/hiss sprites use placeholder emoji pending sprite sheets

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
