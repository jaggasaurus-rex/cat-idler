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
└── project.godot
```

### Autoloads

| Singleton name | Path | Purpose |
|---|---|---|
| `GameState` | `res://autoloads/GameState.gd` | Holds all persistent game state; the single source of truth for currency and rates |

### Scene structure

```
Main (Control, full-rect)        ← Main.gd
├── MoneyLabel (Label)           ← updated every _process() frame
├── CatsLabel (Label)            ← updated every _process() frame
├── EarnMoneyButton (Button)     ← pressed → GameState.click()
├── PurchaseCatButton (Button)   ← permanently shown once shop_unlocked; label updates every frame
└── CatContainer (Node2D)        ← pos (576, 530); purchased cats added here, auto-recentred
```

---

## Game Systems

### GameState (`res://autoloads/GameState.gd`)

Central singleton that owns all game variables. Accessed globally as `GameState`.

| Variable | Type | Default | Description |
|---|---|---|---|
| `money` | `float` | `0.0` | Current money (primary currency) |
| `cats` | `int` | `0` | Number of cats purchased |
| `next_cat_cost` | `float` | `20.0` | Cost of the next cat; doubles after every successful purchase |
| `shop_unlocked` | `bool` | `false` | One-way latch; set to `true` in `click()` the first time `money >= next_cat_cost` |

| Signal | Description |
|---|---|
| `cat_purchased` | Emitted by `buy_cat()` after a successful purchase |

| Method | Signature | Description |
|---|---|---|
| `click` | `() -> void` | Adds `1.0` to `money`; sets `shop_unlocked = true` the first time `money >= next_cat_cost` |
| `buy_cat` | `() -> void` | Guards `money >= next_cat_cost`, deducts cost, increments `cats`, doubles `next_cat_cost`, emits `cat_purchased` |

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
| `_ready()` | Connects `GameState.cat_purchased` → `_on_cat_purchased` |
| `_process(delta)` | Updates `MoneyLabel`, `CatsLabel`; updates `PurchaseCatButton.text`; one-time latch: shows button when `shop_unlocked` first becomes true |
| `_on_earn_money_button_pressed()` | Calls `GameState.click()` |
| `_on_purchase_cat_button_pressed()` | Calls `GameState.buy_cat()` |
| `_on_cat_purchased()` | Instantiates `CatCharacter` at scale 0.4, adds to `CatContainer`, calls `_reposition_cats()` |
| `_reposition_cats()` | Spaces all `CatContainer` children evenly (72 px) and re-centres the row around the container origin |

---

## Current Features

- [x] **Earn Money button** — manual click adds $1.0 to `money`
- [x] **Money counter** — label refreshes every frame, displayed to 1 decimal place (`$X.X`)
- [x] **Cats counter** — label refreshes every frame showing total purchased cats
- [x] **GameState singleton** — autoloaded; holds `money`, `cats`, `next_cat_cost`; emits `cat_purchased` signal
- [x] **Purchase Cat button** — permanently revealed (one-way latch via `shop_unlocked`) the first time `money >= next_cat_cost`; label shows live cost; cost starts at $20 and doubles each purchase
- [x] **Cat spawning** — each purchase instances `CatCharacter` at scale 0.4 into `CatContainer`; row auto-centres as it grows
- [x] **Procedural cat character** — drawn with `_draw()` primitives (body, head, ears, eyes, nose, tail); smooth vertical bob animation via sine wave

---

## Planned Features

### Phase 1 — Core Click Loop *(in progress)*
- [x] Earn Money button with money counter
- [x] Purchase Cat button (gated at $100) with cat spawning
- [ ] Idle/passive income (`income_per_second` driven by owned cats)
- [ ] Basic UI polish (centered layout, styled labels & buttons)

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
