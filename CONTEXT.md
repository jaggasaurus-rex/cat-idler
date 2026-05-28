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
│   └── GameState.gd        # Global state singleton
├── scenes/
│   ├── CatCharacter.tscn   # Procedural cat (instances scripts/CatCharacter.gd)
│   ├── Main.gd             # Root scene script
│   └── Main.tscn           # Root scene
├── scripts/
│   └── CatCharacter.gd     # Cat draw + bob animation
├── CONTEXT.md              # This file
├── ROADMAP.md              # Phase plan and design intent
└── project.godot
```

### Autoloads

| Singleton name | Path | Purpose |
|---|---|---|
| `GameState` | `res://autoloads/GameState.gd` | Holds all persistent game state; the single source of truth for currency and rates |

### Scene structure

```
Main (Control, full-rect)             ← Main.gd
├── MoneyLabel (Label)                ← updated every _process() frame
├── CatsLabel (Label)                 ← updated every _process() frame
├── CatFoodLabel (Label)              ← "Cat Food: X" where X = floor(cat_food); updated every frame
├── EarnMoneyButton (Button)          ← pressed → GameState.click()
├── PurchaseCatButton (Button)        ← permanently shown once shop_unlocked; label updates every frame
├── OnlypawsButton (Button)           ← permanently shown once onlypaws_unlocked; toggles onlypaws_active;
│                                       label = "Onlypaws: ON/OFF"; green modulate when active
├── OnlypawsIncomeLabel (Label)       ← shown with OnlypawsButton; "Onlypaws: $X.XX/sec" updates every frame
├── OnlypawsInfoPanel (PanelContainer)← hidden permanently (legacy node, not wired to button anymore)
│   └── InfoLabel (Label)             ← static info text, autowrap enabled
├── ManagerBotButton (Button)         ← hidden until bot_shop_unlocked; label shows live cost; disabled when unaffordable
├── BotsRateLabel (Label)             ← shown with ManagerBotButton; "Bots: X | Rate: $X.XX/sec" updates every frame
├── ShopPanel (VBoxContainer)         ← right-anchored, always visible; offset_left=-380, offset_right=-10 (370px wide)
│   ├── ShopLabel (Label "Shop")
│   └── CatFoodItem (VBoxContainer)
│       ├── CatFoodNameLabel (Label "Cat Food Pack")
│       ├── CatFoodDescLabel (Label "100 cat food — $10", autowrap_mode=3)
│       ├── BuyCatFoodX1Button (Button "Buy x1 ($10)")  ← calls buy_cat_food_pack(1); disabled when money < 10
│       └── BuyCatFoodX10Button (Button "Buy x10 ($100)") ← calls buy_cat_food_pack(10); disabled when money < 10
└── CatContainer (Node2D)             ← pos (576, 530); purchased cats added here, auto-recentred
```

---

## Game Systems

### GameState (`res://autoloads/GameState.gd`)

Central singleton that owns all game variables. Accessed globally as `GameState`.

| Variable | Type | Default | Description |
|---|---|---|---|
| `money` | `float` | `0.0` | Current money (primary currency) |
| `cats` | `int` | `0` | Number of cats purchased |
| `cat_food` | `float` | `1000.0` | Cat food supply; each cat drains 1 unit per 10 sec; never goes below 0 |
| `next_cat_cost` | `float` | `5.0` | Cost of the next cat; multiplied by `cat_cost_growth_rate` after each purchase |
| `shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `click()` the first time `money >= next_cat_cost` |
| `onlypaws_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_cat()` when `cats >= 3` |
| `paws_income_rate` | `float` | `0.0` | Passive $/sec; recalculated by `_update_paws_rate()` after each cat purchase or bot purchase |
| `manager_bots` | `int` | `0` | Number of Manager-Bots purchased; each one doubles total Onlypaws output |
| `next_bot_cost` | `float` | `50.0` | Cost of the next bot; doubles after every successful purchase |
| `bot_shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `buy_cat()` when `cats >= 6` |
| `shop_unlocked_bots` | `bool` | `false` | One-way latch; set to `true` in `buy_bot()` when `manager_bots == 4`; reveals the attrition-reduction shop |
| `onlypaws_active` | `bool` | `false` | Player-toggled; income only ticks when `true` |
| `cat_cost_growth_rate` | `float` | `1.5` | Multiplier applied to `next_cat_cost` each purchase; reduced to 1.25 by breeder contract |
| `breeder_purchased` | `bool` | `false` | One-way latch; set by `buy_breeder_contract()` |
| `cat_trees_purchased` | `bool` | `false` | One-way latch; set by `buy_cat_trees()` |

| Signal | Description |
|---|---|
| `cat_purchased` | Emitted by `buy_cat()` after a successful purchase |

| Method | Signature | Description |
|---|---|---|
| `_ready` | `() -> void` | Sets `process_mode = PROCESS_MODE_ALWAYS` so income ticks even while tree is paused |
| `_process` | `(delta) -> void` | Always drains `cat_food` by `(cats / 10.0) * delta` (clamped to 0); if `onlypaws_active`: earns `paws_income_rate * delta` |
| `click` | `() -> void` | Adds `1.0` to `money`; sets `shop_unlocked = true` the first time `money >= next_cat_cost` |
| `buy_cat` | `() -> void` | Guards `money >= next_cat_cost`, deducts cost, increments `cats`, applies `cat_cost_growth_rate`, sets `onlypaws_unlocked` when `cats >= 3`, sets `bot_shop_unlocked` when `cats >= 6`, calls `_update_paws_rate()`, emits `cat_purchased` |
| `buy_bot` | `() -> void` | Guards `money >= next_bot_cost`, deducts cost, increments `manager_bots`, doubles `next_bot_cost`, calls `_update_paws_rate()`, sets `shop_unlocked_bots = true` when `manager_bots == 4` |
| `get_cat_food_packs_affordable` | `() -> int` | Returns `int(money / 10.0)` |
| `buy_cat_food_pack` | `(quantity: int) -> void` | Guards `money >= 10.0 * quantity`; deducts cost; adds `100.0 * quantity` to `cat_food` |
| `buy_breeder_contract` | `() -> void` | Guards `money >= 2000 and not breeder_purchased`; sets `cat_cost_growth_rate = 1.25`; retroactively recalculates `next_cat_cost = 5.0 * pow(1.25, cats)` |
| `buy_cat_trees` | `() -> void` | Guards `money >= 4000 and not cat_trees_purchased`; deducts cost; sets `cat_trees_purchased = true` |
| `_update_paws_rate` | `() -> void` | `paws_income_rate = float(cats / 3) * pow(2.0, manager_bots)` |

### CatCharacter (`res://scripts/CatCharacter.gd`)

Procedurally drawn cat rendered entirely with `_draw()` primitives. No sprites or textures.

| Part | Primitive | Notes |
|---|---|---|
| Body | `draw_circle` | radius 52, ginger orange |
| Head | `draw_circle` | radius 38, offset (0, -78) |
| Ears | `draw_polygon` (×4) | outer + inner pink triangle per ear |
| Eyes | `draw_circle` (×6) | white + pupil + gleam highlight |
| Nose | `draw_polygon` | small pink triangle |
| Tail | `draw_polyline` | 16-point sine curve from right flank |

| Variable | Type | Description |
|---|---|---|
| `base_y` | `float` | Initial `position.y` captured in `_ready()` |

| Method | Description |
|---|---|
| `_ready()` | Stores `base_y = position.y` |
| `_process(delta)` | `position.y = base_y + sin(Time.get_ticks_msec() * 0.002) * 6.0` — vertical bob |
| `_draw()` | Calls all `_draw_*` helpers in back-to-front order |

---

### Main UI (`res://scenes/Main.gd`)

Drives the root scene. No mutable state lives here — reads from and delegates to `GameState`.

| Method | Description |
|---|---|
| `_ready()` | Connects `cat_purchased` → `_on_cat_purchased` |
| `_process(delta)` | Updates all labels every frame; one-time visibility latches for `shop_unlocked`, `onlypaws_unlocked`, `bot_shop_unlocked`; updates `CatFoodLabel`; disables cat food buy buttons when `money < 10.0`; sets `OnlypawsButton` label and modulate |
| `_on_earn_money_button_pressed()` | Calls `GameState.click()` |
| `_on_purchase_cat_button_pressed()` | Calls `GameState.buy_cat()` |
| `_on_onlypaws_button_pressed()` | Flips `GameState.onlypaws_active` |
| `_on_manager_bot_button_pressed()` | Calls `GameState.buy_bot()` |
| `_on_cat_purchased()` | Instantiates `CatCharacter` at scale 0.4, adds to `CatContainer`, calls `_reposition_cats()` |
| `_on_buy_cat_food_x1_button_pressed()` | Calls `GameState.buy_cat_food_pack(1)` |
| `_on_buy_cat_food_x10_button_pressed()` | Calls `GameState.buy_cat_food_pack(10)` |
| `_reposition_cats()` | Spaces all `CatContainer` children evenly (72 px) and re-centres the row around the container origin |

---

## Current Features

- [x] **Earn Money button** — manual click adds $1.0 to `money`
- [x] **Money counter** — label refreshes every frame, displayed to 2 decimal places (`$X.XX`)
- [x] **Cats counter** — label refreshes every frame showing total purchased cats
- [x] **GameState singleton** — autoloaded; holds `money`, `cats`, `next_cat_cost`, `shop_unlocked`, `onlypaws_unlocked`, `paws_income_rate`; emits `cat_purchased`
- [x] **Purchase Cat button** — permanently revealed (one-way latch via `shop_unlocked`) the first time `money >= next_cat_cost`; label shows live cost to 2 decimal places; cost starts at $5.00 and multiplies by `cat_cost_growth_rate` each purchase (default 1.5, reduced to 1.25 by breeder contract)
- [x] **Onlypaws passive income** — unlocks at 3 cats; base rate `floor(cats/3)` $/sec; each Manager-Bot doubles total output via `pow(2, manager_bots)`
- [x] **Onlypaws button + income label** — revealed together when `onlypaws_unlocked`; button toggles info panel popup
- [x] **Onlypaws info panel** — PanelContainer with static description text; shown/hidden by button press; positioned above button
- [x] **Cat spawning** — each purchase instances `CatCharacter` at scale 0.4 into `CatContainer`; row auto-centres as it grows
- [x] **Procedural cat character** — drawn with `_draw()` primitives (body, head, ears, eyes, nose, tail); smooth vertical bob animation via sine wave
- [x] **Onlypaws Manager-Bot** — unlocks at 6 cats; costs $50 (doubles each purchase); each bot doubles total Onlypaws income rate; button shows live cost, disabled when unaffordable; `BotsRateLabel` shows bot count and current rate
- [x] **Onlypaws ON/OFF toggle** — `OnlypawsButton` flips `onlypaws_active`; income only runs while active; button label and green modulate reflect state
- [x] **Upgrade stubs (GameState only)** — `buy_breeder_contract()` and `buy_cat_trees()` exist in GameState (`cat_trees_purchased` flag retained) but are not wired to any UI
- [x] **Shop panel always visible** — `ShopPanel` is shown from game start; no unlock gate
- [x] **Cat food** — `cat_food` starts at 1000; drains at `cats / 10` per second (always, not gated); clamped to 0; `CatFoodLabel` shows `floor(cat_food)` in the HUD
- [x] **Cat Food Pack shop item** — buy x1 ($10, +100 food) or x10 ($100, +1000 food); both buttons disabled when `money < 10`

---

## Planned Features

### Phase 1 — Core Click Loop *(in progress)*
- [x] Earn Money button with money counter
- [x] Purchase Cat button (gated at $100) with cat spawning
- [x] Idle/passive income (Onlypaws: `floor(cats/3)` $/sec, unlocks at 3 cats)
- [ ] Basic UI polish (centered layout, styled labels & buttons)

### Phase 1 — Core Click Loop (continued)
- [x] Onlypaws Manager-Bot (doubling multiplier, unlocks at 6 cats)

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
- [x] Procedural cat character with bob animation
- [ ] Click reaction animation on cat (squash/stretch or color flash)
- [ ] Fish count formatted with suffixes (K, M, B…)
- [ ] Sound effects (click, purchase)
- [ ] Settings menu (mute, reset save)
