# ADR 0001: Make the Robo-Shit Sweeper a Repeatable, Multi-Instance Purchase

## Status
Accepted

## Context
The Robo-Shit Sweeper is currently a one-shot upgrade: `GameState.robo_sweeper_purchased: bool` is set once by `buy_robo_sweeper()` at fixed cost `Config.ROBO_SWEEPER_PURCHASE_COST` ($10,000), and `Main.gd` drives a single inline `Node2D` (`_sweeper_node`) through one `SweeperState` state machine (`_sweeper_state`, `_sweeper_target_poop`, `_sweeper_clean_timer`) in `_process_sweeper()`. We need each purchase to cost 3× the last (10k → 30k → 90k…), spawn its own autonomous cleaner Node2D, and guarantee that two sweepers never target the same poop. Per-sweeper movement/cleaning constants, poop spawn logic, and the research gate must not change.

## Decision

**State (GameState).** Replace the single `robo_sweeper_purchased: bool` with a count plus a running cost:
- `var robo_sweeper_count: int = 0`
- `var next_robo_sweeper_cost: float = Config.ROBO_SWEEPER_PURCHASE_COST`

`buy_robo_sweeper()` keeps its research gate, drops the "already purchased" no-op, guards `money >= next_robo_sweeper_cost`, then deducts that cost, does `robo_sweeper_count += 1`, and multiplies `next_robo_sweeper_cost *= Config.ROBO_SWEEPER_COST_GROWTH` (new const, `3.0`). The growth factor lives in Config, not inline. The shop button's eligibility no longer flips on a purchased bool — it stays available as long as the player can pay.

**Sweeper instances (Main.gd).** Collapse the four scalar `_sweeper_*` fields into one `Array[Dictionary]` named `_sweepers`, each entry `{node: Node2D, label: Label, state: int, target: Dictionary, clean_timer: float}` where `target` is an entry from `_active_poops` (or empty `{}`). Keep the existing `SweeperState` enum and the per-sweeper movement/cleaning logic verbatim — `_process_sweeper(delta)` becomes a loop over `_sweepers`, running the same MOVING/CLEANING transitions per entry against `Config.SWEEPER_MOVE_SPEED` / `Config.SWEEPER_CLEAN_DELAY`. A small `_spawn_sweeper_instance()` helper builds the Node2D + Label (reusing the current `_ready()` construction code, glyph `Strings.SWEEPER_EMOJI`) and appends to `_sweepers`.

**Target exclusion (claim set).** When a sweeper in MOVING needs a target, it picks the nearest poop in `_active_poops` whose node `instance_id` is not currently claimed by another sweeper. Claiming is derived, not stored separately: build a transient set of `instance_id`s from every other sweeper's non-empty `target` at selection time and skip those. This avoids a parallel claim structure that could desync from `_active_poops`. When a sweeper finishes CLEANING (removes the poop) or finds its target freed/missing, it clears `target` to `{}` and returns to MOVING, freeing the claim implicitly.

**Activation — poll, no new signal.** `Main.gd._process()` already runs every frame and reads GameState freely. It compares `_sweepers.size()` to `GameState.robo_sweeper_count` each frame and calls `_spawn_sweeper_instance()` for the difference. This matches the existing polling pattern (housing tier, mega-bot latch, research slots) and avoids adding a signal for a value that is already trivially observable. No new GameState signal.

**Shop button (Main.gd).** `_robo_sweeper_button` stays visible once `research_complete["robo_shit_sweeper"]` is true and never disappears on purchase. Its label reads the live next cost each frame via `Strings.BTN_ROBO_SWEEPER` (template with `%s` cost slot), and `disabled` is set when `money < next_robo_sweeper_cost`. Its `shop_cost` meta is updated per frame so `_sort_shop_list()` keeps it ordered, mirroring the cyborg-multiplier button.

**Tunables.** `Config.ROBO_SWEEPER_PURCHASE_COST` stays as the base/first cost (seeds `next_robo_sweeper_cost`). New `Config.ROBO_SWEEPER_COST_GROWTH: float = 3.0`.

## Alternatives considered
- Keep `robo_sweeper_purchased` bool and add a separate count alongside it — redundant state with two sources of truth for the same fact.
- Per-frame exclusion (each sweeper skips poops another sweeper sits on this frame) instead of a claim set — two idle sweepers equidistant from one poop both select it on the same frame before either marks it.
- Persisted claim Dictionary in GameState/Main — a second structure to keep in sync with `_active_poops` on every poop removal and cat loss; the derived set has no desync surface.
- New `robo_sweeper_purchased` signal to notify Main — unnecessary; Main already polls GameState every frame.
- Store next cost only in Config as a formula `BASE * 3^count` computed on read — works, but the codebase's convention is a mutable `next_*_cost` var escalated in the buy method (cats, bots, mega-bots, cyborgs), and honoring that pattern keeps `buy_robo_sweeper()` uniform.

## Consequences
- Makes adding more sweepers a pure data operation (increment count); the cleaning loop scales automatically.
- The claim-by-derivation rule keeps "no double-targeting" correct through poop removal, cat loss, and concurrent selection without extra bookkeeping.
- The button now behaves like every other repeatable shop item (live cost, affordability-gated, persistent), so it fits `_sort_shop_list()` and the membership/cyborg patterns.
- `_on_cat_lost()`'s current special-case must now iterate `_sweepers` and clear any entry whose `target` points at a freed poop — an O(N) scan instead of one check.
- `_process()` must reconcile `_sweepers.size()` with `robo_sweeper_count` before `_process_sweeper()` runs.
- Edge cases: more sweepers than poops (extras stay in MOVING/idle — fine); a target poop clicked away mid-CLEANING (detect missing entry, reset to MOVING); growth applied only on successful purchase.

## Affected files
- `autoloads/GameState.gd` — remove `robo_sweeper_purchased`; add `robo_sweeper_count: int`, `next_robo_sweeper_cost: float`; rewrite `buy_robo_sweeper()`.
- `scenes/Main.gd` — replace scalar `_sweeper_*` fields with `_sweepers: Array[Dictionary]`; add `_spawn_sweeper_instance()`; rewrite `_process_sweeper()` as a loop; reconcile count in `_process()`; update `_robo_sweeper_button` to persist with live cost; update `_on_cat_lost()`.
- `Config.gd` — add `ROBO_SWEEPER_COST_GROWTH: float = 3.0`.
- `Strings.gd` — `BTN_ROBO_SWEEPER` already has `($%s)` template; confirm it can be filled with live cost.
- `CONTEXT.md` — update sweeper state description.

## Should NOT change
- Poop spawn logic, `POOP_SPAWN_MIN/MAX`, `_spawn_poop`, `_on_poop_pressed`, `poop_count`.
- `SWEEPER_MOVE_SPEED`, `SWEEPER_CLEAN_DELAY`, `SweeperState` enum semantics.
- The `robo_shit_sweeper` research item, its gates, fund/points costs, or thresholds.
- Happiness, cyborg, and cat-purchase systems.
