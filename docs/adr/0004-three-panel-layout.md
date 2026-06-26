# ADR: Restructure Main.tscn into a three-panel layout with injected play-area bounds

## Status
Accepted

## Context
`Main.tscn` currently free-places every HUD label/button as absolutely-offset (`layout_mode=0`) direct children of the root `Control`, with `ShopPanel` right-anchored, `CenterColumn` free-placed, and `CatContainer` a `Node2D` at `(576,530)`. Cats, poop, bubbles, and sweepers all live in `Main`'s global coordinate space and derive their wander/placement bounds from `get_viewport_rect()`. We want a Spaceplan-style three-panel frame — fixed dark left/right panels flanking a wide transparent center playground — without touching `GameState.gd`, `Config.gd`, or `Strings.gd`, and without altering the cat wander state machine beyond the source of its bounds rect.

## Decision
Wrap the framed UI in a single full-rect `HBoxContainer` ("PanelLayout") inserted as a sibling between the background `TextureRect` and the runtime-spawned poop/bubble/sweeper nodes, so the existing global-coordinate overlay system is untouched.

### Node tree, before → after

```
BEFORE                              AFTER
Main (Control, full-rect)           Main (Control, full-rect, origin 0,0 — unchanged)
├── TextureRect (bg)                ├── TextureRect (bg, full-screen — unchanged)
├── CatContainer (Node2D)           ├── PanelLayout (HBoxContainer, full-rect, mouse_filter=PASS)
├── MoneyLabel ...HUD nodes...      │   ├── LeftPanel (PanelContainer, custom_minimum_size.x≈270, opaque dark)
├── HappinessBarContainer           │   │   └── MarginContainer → VBoxContainer (HUD + action buttons)
├── ShopPanel                       │   │        CatsLabel, MoneyLabel, EarnMoneyButton, PurchaseCatButton,
├── CenterColumn                    │   │        CatFoodLabel, BuyCatFoodButton, OnlyPawsButton,
└── …popups (full-rect overlays)    │   │        OnlyPawsIncomeLabel, ManagerBotButton, MegaManagerBotButton,
                                    │   │        BotTokenRow(HBox), BuyTokensButton, HappinessBarContainer
                                    │   ├── CenterPanel (Control, size_flags_horizontal=EXPAND_FILL,
                                    │   │   │   transparent, mouse_filter=IGNORE)
                                    │   │   └── CatContainer (Node2D, position reset to 0,0)
                                    │   └── RightPanel (PanelContainer, custom_minimum_size.x≈270, opaque dark)
                                    │        └── VBoxContainer → ShopPanel, CenterColumn
                                    └── …popups (full-rect overlays — unchanged)
```

### Key choices

- **Containers, not absolute offsets, inside panels.** Relocated HUD nodes switch from `layout_mode=0`/offsets to `layout_mode=2` (container-controlled) inside a `MarginContainer → VBoxContainer`. They exceed 270px at their current offsets, so reflow containers are required; they also reflow cleanly as latched nodes toggle visible. `LeftPanel`/`RightPanel` keep dark opaque backgrounds; `CenterPanel` is transparent so the lofi background shows through the playground.

- **CatContainer reparents under CenterPanel**, local `position` zeroed. Cats, poop, bubbles, and sweepers continue to operate in global coordinates via `to_global`/`to_local` and `global_position`, so nesting under a `Control` is transform-safe. Poop/bubble/sweeper nodes stay direct children of `Main`, added after `PanelLayout` in tree order, so they render and receive clicks above the panels.

- **Bounds by injection (option a).** Add `func set_bounds(rect: Rect2) -> void` to `CatCharacter.gd` storing `_bounds: Rect2` (default-initialized in `_ready()` to `get_viewport_rect()` as a fallback). The wander-target block computes inside `_bounds` with the existing 40px inset and top-10%-excluded formula. `Main._on_cat_purchased()` calls `cat.set_bounds(center_panel.get_global_rect())` after `add_child`. This keeps `CatCharacter` self-contained — it never reaches into `CenterPanel`.

- **Main.gd bounds sources** all switch from viewport to `center_panel.get_global_rect()`: `_place_cat()` and `_spawn_sweeper_instance()` use that rect. `_spawn_poop()` and `_spawn_bubble()` need no formula change.

- **Node references switch to unique names.** Relocated nodes get `unique_name_in_owner = true` and their `@onready` vars switch from `$`-paths to `%Name`. Add `@onready var center_panel` for the new rect source.

- **`CenterPanel` set to `mouse_filter=IGNORE`** ensures it never swallows clicks intended for poop/bubble buttons layered above it.

## Alternatives considered
- Keep `layout_mode=0` absolute offsets inside the panels — rejected: nodes are wider than 270px and would not reflow as latched controls appear.
- Leave `CatContainer` a direct child of `Main` — rejected: less faithful to the "cats live in the center playground" intent and forgoes `clip_contents` containment.
- Read play-area bounds from a `Config`/`GameState` constant — rejected: violates the no-`Config`-change constraint and can't track a panel that resizes with the window.
- Keep `$` nested node paths — rejected: brittle, re-breaks on any future panel reshuffle; `%` unique names are stable.

## Consequences
- Makes the layout responsive: center play area auto-fills remaining width, side panels stay fixed.
- Makes bounds correct and future-proof: one injected rect drives wander, placement, and sweeper spawn.
- Introduces an assumption that `Main` stays anchored at global origin `(0,0)` — preserved by keeping `PanelLayout` a sibling and not reparenting poop/bubble/sweeper overlays.
- Introduces a layout-timing assumption: `center_panel.get_global_rect()` is only read at runtime (cat purchase, sweeper spawn), after first-frame layout, so it is never zero-sized in practice.
- Right-panel vertical space is tight (~270px wide for ShopPanel + CenterColumn); a `ScrollContainer` around the right `VBoxContainer` is likely needed.
- `[connection]` `from=` paths in `Main.tscn` for relocated nodes must be repointed to their new full paths; a missed connection silently disables a button, so each must be verified.

## Affected files
- `res://scenes/Main.tscn` — new `PanelLayout` HBox + `LeftPanel`/`CenterPanel`/`RightPanel`; reparent HUD/buttons/`HappinessBarContainer` into LeftPanel VBox, `ShopPanel`+`CenterColumn` into RightPanel VBox, `CatContainer` into CenterPanel; `layout_mode` and `unique_name_in_owner` edits; `[connection]` path updates for relocated emitters; background `TextureRect` and all popups untouched.
- `res://scenes/Main.gd` — `@onready` refs for relocated nodes switch to `%Name`; add `@onready var center_panel`; update `_place_cat()` and `_spawn_sweeper_instance()` to use `center_panel.get_global_rect()`; `_on_cat_purchased()` calls `cat.set_bounds(...)`.
- `res://scripts/CatCharacter.gd` — new `_bounds: Rect2`, `set_bounds(rect)` public method, `_ready()` fallback init, wander-target block reads `_bounds` instead of `get_viewport_rect()`.
- No changes to `Config.gd`, `Strings.gd`, `GameState.gd`, `CatCharacter.tscn`, or any popup.
