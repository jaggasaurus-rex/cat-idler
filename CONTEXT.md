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
├── CatCharacter (Node2D)        ← instanced from CatCharacter.tscn; pos (576, 300)
├── FishLabel (Label)            ← updated every _process() frame
└── PetCatButton (Button)        ← pressed → GameState.click()
```

---

## Game Systems

### GameState (`res://autoloads/GameState.gd`)

Central singleton that owns all game variables. Accessed globally as `GameState`.

| Variable | Type | Default | Description |
|---|---|---|---|
| `fish` | `float` | `0.0` | Current fish (primary currency) |
| `fish_per_click` | `float` | `1.0` | Fish awarded per manual click |

| Method | Signature | Description |
|---|---|---|
| `click` | `() -> void` | Adds `fish_per_click` to `fish` |

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

Drives the root scene. No state lives here — reads from `GameState` only.

| Method | Description |
|---|---|
| `_process(delta)` | Refreshes `FishLabel` every frame: `"Fish: %.1f" % GameState.fish` |
| `_on_pet_cat_button_pressed()` | Calls `GameState.click()` |

---

## Current Features

- [x] **Pet Cat button** — manual click awards `fish_per_click` fish
- [x] **Fish counter** — label refreshes every frame, displayed to 1 decimal place
- [x] **GameState singleton** — autoloaded, holds `fish` and `fish_per_click`
- [x] **Procedural cat character** — drawn with `_draw()` primitives (body, head, ears, eyes, nose, tail); smooth vertical bob animation via sine wave

---

## Planned Features

### Phase 1 — Core Click Loop *(in progress)*
- [x] Pet Cat button with fish counter
- [ ] Idle/passive fish income (`fish_per_second` variable + `_process` accumulation)
- [ ] Basic UI polish (centered layout, styled label & button)

### Phase 2 — Upgrades
- [ ] Upgrade: increase `fish_per_click` (e.g. "Better Petting Technique")
- [ ] Upgrade: increase `fish_per_second` (e.g. "Autonomous Purring")
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
