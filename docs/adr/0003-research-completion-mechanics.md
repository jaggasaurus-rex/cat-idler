# ADR: Wire five research-completion mechanics through GameState methods and Main view effects

## Status
Proposed

## Context
Config.gd already defines research items 7–14 and `ENRICHMENT_ITEMS` as data only; their runtime effects are unwired. We must add five mechanics (intelligence-gated unlock, a stacking cat-cost multiplier, a poop-interval multiplier, a glitch overlay, and a one-time enrichment store) plus an updated token-pack price tier. The existing system already separates concerns cleanly: GameState owns all economy/persistent state and emits `research_completed(id)`, while Main.gd reacts in `_on_research_completed(id)` for view work (panel hide, popups) and owns its local poop/bubble timer dictionaries. The change must fit that split rather than have Main reach into GameState's economy fields.

## Decision
Keep the state/view split the codebase already uses: **all persistent state lives in GameState behind intent-named methods; Main.gd's `_on_research_completed(id)` dispatches by id and performs only Main-local/view effects.**

GameState additions:
- New vars: `poop_recyclers_researched: bool = false`, `enrichment_store_unlocked: bool = false`, `enrichment_purchases: Array[String] = []`, `own_llm_researched: bool = false`.
- `multiply_cat_cost_growth(factor: float)`: `cat_cost_growth_rate *= factor` then `next_cat_cost = Config.cat_cost_base * pow(cat_cost_growth_rate, float(cats))`. Called with `0.9` for `cat_breeder_contract` and `0.8` for `cat_breeders_contract`. Multiplication is commutative and re-derives `next_cat_cost` from the canonical formula each time, so it stacks correctly on top of the shop `buy_breeder_contract()` path regardless of order.
- Small setters/unlockers: `set_poop_recyclers_researched()`, `set_own_llm_researched()`, `unlock_enrichment_store()`.
- `buy_enrichment(id: String)`: guards `money >= cost` and `id not in enrichment_purchases`; deducts money; appends id. Cosmetic only.
- `get_token_pack_cost()` priority becomes: `own_llm_researched → Config.TOKEN_PACK_COST_OWN_LLM (10.0)`, else `ai_enterprise_purchased → 15.0`, else base `20.0`.

Main.gd additions:
- `_refresh_research_slots()`: add one additive gate alongside the others — `if GameState.cat_intelligence < int(item.get("unlock_requires_intelligence", 0)): continue` (place with the other `continue` gates, before the slot-count cap). Inert until a Config item declares the key; data-driven.
- `_on_research_completed(id)` dispatch: `cat_breeder_contract`/`cat_breeders_contract` → `GameState.multiply_cat_cost_growth(...)`; `cybernetic_poop_recyclers` → `GameState.set_poop_recyclers_researched()` then re-roll every `_cat_poop_timers` entry × `Config.POOP_RECYCLER_INTERVAL_MULTIPLIER`; `cat_enrichment_program` → `GameState.unlock_enrichment_store()`; `research_your_own_llms` → `GameState.set_own_llm_researched()`; `further_the_cat_race`/`research_your_own_llms` → `_trigger_glitch_effect()`.
- Poop reset line in `_process()` multiplies the fresh `randf_range(...)` by `Config.POOP_RECYCLER_INTERVAL_MULTIPLIER` when `GameState.poop_recyclers_researched` (single shared constant, no magic 2.0).
- `_trigger_glitch_effect()`: build a cyan full-rect `ColorRect` (`z_index = 200`, `process_mode = ALWAYS`), child of Main; `create_tween()` bound to the rect chaining 5 alpha flickers (0.05s each); finish with `tween_callback(rect.queue_free)`. No stored reference, no tree pause.
- Enrichment store: create the shop button once in `_ready()` (hidden, `shop_cost` meta set, added to `shop_list`), mirroring the `_robo_sweeper_button` pattern; reveal via a one-way visibility latch in `_process()` when `enrichment_store_unlocked`, then `_sort_shop_list()`. Pressing it builds a code-built `ColorRect` overlay panel with one button per `Config.ENRICHMENT_ITEMS`; each button's owned state is derived from `GameState.enrichment_purchases` at build time. Purchase handler calls `GameState.buy_enrichment(id)` and, only on success, disables the button and appends the owned suffix. Panel is built fresh each open so state is always current.

## Alternatives considered
- Put the cat-cost and flag mutations directly in Main's `_on_research_completed` (literal spec wording): rejected — Main would mutate GameState's core economy fields, violating the scenes-don't-touch-internals rule.
- Fold all id-specific effects into GameState `_process()`'s completion block: rejected — that block is data-driven over RESEARCH_ITEMS; per-id `if` branches there erode its purity and the poop re-roll needs Main-local timers anyway.

## Consequences
- Easy/safe: the cat-cost multiplier stacks with the shop contract by construction; the poop multiplier lives in one constant used in both the re-roll and the reset; the glitch tween self-frees; the enrichment overlay is always current on open.
- Harder/assumptions: introduces a small surface of intent-named GameState methods Main depends on. `cat_breeder_contract` vs `cat_breeders_contract` are near-identical ids — a dispatch typo silently no-ops; verify against Config exactly. With growth rate driven below 1.0 (0.9 after both contracts), `next_cat_cost` *decreases* as `cats` rises — intended but a balance surprise worth confirming.

## Affected areas
- `res://autoloads/GameState.gd`: new vars; new methods `multiply_cat_cost_growth`, `set_poop_recyclers_researched`, `set_own_llm_researched`, `unlock_enrichment_store`, `buy_enrichment`; updated `get_token_pack_cost`.
- `res://scenes/Main.gd`: `_refresh_research_slots` (intelligence gate), `_on_research_completed` (id dispatch), poop re-roll + `_process` poop-reset doubling, `_trigger_glitch_effect`, enrichment shop button + `_process` latch + overlay builder/handlers.
- `res://Config.gd`: add `POOP_RECYCLER_INTERVAL_MULTIPLIER = 2.0`.
- `res://Strings.gd`: add enrichment store button label, panel title, owned suffix, and close-button text.
- Signal: existing `research_completed(id: String)` — no new signals.
