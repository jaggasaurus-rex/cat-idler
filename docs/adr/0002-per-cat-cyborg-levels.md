# ADR: Replace global cyborg-multiplier tier with per-cat research-gated cyborg leveling

## Status
Proposed

## Context
Cyborg cats currently share one global multiplier `cyborg_multiplier_tier` (0-2) indexing `Config.CYBORG_MULTIPLIERS = [2.0, 4.0, 8.0]`, bought with money via `buy_cyborg_multiplier_upgrade()` and a shop button. Income is `rate * (onlypaws_normal + global_M * onlypaws_cyborg)`. We are replacing this with per-cyborg levels (V1=2, V2=4, V3=8), where converting always yields V1 and leveling V1→V2 / V2→V3 is gated only by completing research items `cyborg_level_2` / `cyborg_level_3` (no money cost). The global tier, its upgrade method, and `CYBORG_MULTIPLIER_UPGRADE_COSTS` are removed. This must fit the existing pattern where per-cat identity lives in `Main.gd._cyborg_cat_ids` but income math lives in `GameState.update_paws_rate()`.

## Decision

**State ownership (Q1, Q2).** Per-cat level lives in `GameState`, not Main.gd. Add `var cyborg_levels: Array[int] = []` to GameState — one entry per cyborg, each in {1,2,3}, order-independent (a flat multiset of levels). `buy_cyborg_cat()` appends a `1`. This keeps the income sum inside GameState where `update_paws_rate()` already lives, avoiding any cross-scene reach into Main.gd's node dictionary. Main.gd's `_cyborg_cat_ids` changes from `instance_id -> true` to `instance_id -> level_int` purely for the visual tint and the cat-loss exclusion; it is the rendering mirror, never the income source of truth. Rejected (b)/(c): a Main-populated helper or passing a sum into `update_paws_rate()` would scatter the income invariant across two scenes and break the no-bot fallback in `GameState._process()`, which must compute the same population without Main's help.

**Income formula (Q2, Q5).** Replace `get_cyborg_multiplier() * float(get_onlypaws_cyborg_cats())` with a new helper `get_onlypaws_cyborg_earning_units() -> float` that returns the research-split, multiplier-weighted cyborg contribution: of `cyborg_levels.size()` cyborgs, `get_research_cats_for(cyborg_cats)` are on research (excluded), and the remaining earners contribute `sum(CYBORG_MULTIPLIERS[level-1])`. Because the research split removes a *count* of cyborgs (not specific levels), apply it by summing the multipliers of the earning subset deterministically: sort `cyborg_levels` (or iterate as stored) and skip the first `research_count` entries, summing `CYBORG_MULTIPLIERS[level-1]` for the rest. `update_paws_rate()` becomes `paws_income_rate = rate * (float(get_onlypaws_normal_cats()) + get_onlypaws_cyborg_earning_units())`. The no-bot fallback in `_process()` (lines 117-122) and the display fallback in `Main.gd._process()` (lines 274-279) both switch to the same helper: `no_bot_population = float(get_onlypaws_normal_cats()) + get_onlypaws_cyborg_earning_units()`.

**Leveling and storage of who-levels (Q1, Q4).** Add `GameState.level_up_cyborg() -> bool` that finds the lowest-level cyborg eligible for the next completed research tier (a `1` if `cyborg_level_2` complete, else a `2` if `cyborg_level_3` complete), increments that entry, calls `update_paws_rate()`, and emits a new signal `cyborg_leveled(instance_target_hint)`. To keep the visual mirror in sync without GameState knowing about nodes, the chosen approach is: GameState exposes `count_cyborgs_eligible_to_level() -> int` and `level_up_cyborg()` returns the new level reached; Main.gd owns the mapping from that level-up to a specific tinted node. **UI (Q4): a single shop-style "Level Up Cyborg" button** (option a, batch-of-one per click), mirroring the existing single `make_cyborg_button` next to the cyborg count label — not per-cyborg buttons (does not fit any existing list UI) and not click-the-sprite (no existing sprite-click affordance). The button is visible only when `count_cyborgs_eligible_to_level() > 0`, disabled otherwise, and its label names the target level via a new string template.

**Visual sync (Q1, Q6).** Main.gd keeps `_cyborg_cat_ids: Dictionary` as `instance_id -> level`. On `cyborg_cat_created`, tint a new node `CYBORG_TINT_V1` and store level 1. On `cyborg_leveled`, Main.gd picks the tinted node whose stored level is the lowest eligible level, bumps its stored value, and re-tints to the new level's colour. Tints: `CYBORG_TINT_V1 = Color(0.5, 0.85, 1.0)` (existing CYBORG_TINT, renamed), `CYBORG_TINT_V2 = Color(0.85, 0.7, 1.0)` (violet), `CYBORG_TINT_V3 = Color(1.0, 0.65, 0.4)` (hot amber). Defined as a Main.gd const array `CYBORG_TINTS` indexed by `level-1`.

**Research items (Q3, Q7).** Two new items inserted into `Config.RESEARCH_ITEMS` immediately after `cyborg_cats`, so the predecessor-complete gate chains naturally: `cyborg_level_2` requires `cyborg_cats` complete, `cyborg_level_3` requires `cyborg_level_2` complete (both enforced by the existing index-order predecessor loop in `_refresh_research_slots()`). No `unlock_requires_cats`/`unlock_requires_research` OR-gate is needed since the predecessor chain alone is the intended gate; `min_housing_tier: 2` matches `cyborg_cats`. Costs escalate over `cyborg_cats` (fund 3000 / points 1800):
- `cyborg_level_2`: fund_cost 6000.0, points_cost 3000.0, min_cats_required 1, cat_intelligence_gain 0, min_housing_tier 2.
- `cyborg_level_3`: fund_cost 12000.0, points_cost 5000.0, min_cats_required 1, cat_intelligence_gain 0, min_housing_tier 2.

**Removals.** Delete `GameState.cyborg_multiplier_tier`, `GameState.get_cyborg_multiplier()`, `GameState.buy_cyborg_multiplier_upgrade()`, `Config.CYBORG_MULTIPLIER_UPGRADE_COSTS`, Main.gd's `_cyborg_multiplier_button` and its `_ready()` creation block, its `_process()` visibility block (lines 521-535), `_on_buy_cyborg_multiplier_button_pressed()`, and `Strings.BTN_CYBORG_MULTIPLIER`.

## Alternatives considered
- Levels in Main.gd `_cyborg_cat_ids` only: rejected — `GameState.update_paws_rate()` and its no-bot fallback cannot read Main's dictionary.
- Pass the cyborg multiplier sum into `update_paws_rate()` as an argument: rejected — the autonomous `_process()` fallback has no caller to supply it.
- Per-cyborg level buttons or click-the-sprite leveling: rejected — no existing per-entity list or sprite-click UI to extend.
- Money cost on leveling: rejected — target model is research-gated only.
- New OR-gate (`unlock_requires_research`) on the level items: rejected — index-order predecessor gate already enforces the chain.

## Consequences
- Makes per-cyborg scaling and future level tiers easy: extend `CYBORG_MULTIPLIERS`, `CYBORG_TINTS`, and add a `cyborg_level_N` research item; the income sum and predecessor gate absorb it.
- Keeps income single-sourced in GameState; the no-bot fallback and Main's display fallback stay correct by calling one shared helper.
- Harder: GameState now owns an array whose size must stay equal to `cyborg_cats`, and Main's `_cyborg_cat_ids` is a parallel mirror keyed by node id. Two structures must move together on create/level/loss. The research split removes a *count* of cyborgs without choosing which levels, so the earning sum must apply the split deterministically (skip-first-N over the level list) to avoid frame-to-frame jitter.
- New coupling: `cyborg_leveled` signal between GameState and Main for the tint update; the eligible-target selection logic (lowest level that the completed research unlocks) must match in both `level_up_cyborg()` and Main's tint handler.

## Affected areas
- `autoloads/GameState.gd`: add `cyborg_levels: Array[int]`; new `cyborg_leveled` signal; new `get_onlypaws_cyborg_earning_units()`, `level_up_cyborg()`, `count_cyborgs_eligible_to_level()`; edit `buy_cyborg_cat()` (append level 1), `update_paws_rate()`, `_process()` no-bot fallback; remove `cyborg_multiplier_tier`, `get_cyborg_multiplier()`, `buy_cyborg_multiplier_upgrade()`. Verify `starvation_lose_cat()` does not touch cyborgs (it does not — confirmed, it decrements `cats` only).
- `scenes/Main.gd`: change `_cyborg_cat_ids` to `id -> level`; rename `CYBORG_TINT`→`CYBORG_TINT_V1`, add `CYBORG_TINTS` const; remove `_cyborg_multiplier_button` (declaration, `_ready()` block, `_process()` block, handler); add a "Level Up Cyborg" button near `make_cyborg_button` with visibility on `count_cyborgs_eligible_to_level() > 0`; connect `cyborg_leveled`; update `_on_cyborg_cat_created()` to store level 1; add `_on_cyborg_leveled()` tint handler; update both income-display fallbacks to `get_onlypaws_cyborg_earning_units()`.
- `Config.gd`: remove `CYBORG_MULTIPLIER_UPGRADE_COSTS`; add the two `cyborg_level_2` / `cyborg_level_3` entries to `RESEARCH_ITEMS` after `cyborg_cats`. `CYBORG_MULTIPLIERS`, `CYBORG_COST_BASE`, `CYBORG_COST_GROWTH` unchanged.
- `Strings.gd`: remove `BTN_CYBORG_MULTIPLIER`; add `BTN_LEVEL_UP_CYBORG` ("Level Up Cyborg → V%s"); add `RESEARCH_CYBORG_L2_NAME/SUB/DESC`, `RESEARCH_CYBORG_L3_NAME/SUB/DESC`; add both ids to `RESEARCH_NAMES`; review `POPUP_CYBORG` to drop the "Upgrade the multiplier in tiers" sentence in favor of research-gated leveling wording.
- Verified locked constraints already hold: food drain is `cats * drain_rate` (cyborgs excluded), cyborgs never poop (poop timers exclude cyborg ids), research fraction applies to both pools via `get_research_cats_for()`, conversion cost curve untouched.

## SHOULD NOT CHANGE
Starvation, housing (`get_max_cats`, `buy_housing_upgrade`), sweeper system, bubble/poop systems, happiness model (`get_happiness` already uses total cats), bot/mega-bot income, `CatCharacter.tscn`, `Main.tscn`.

## Confirmation comments
- (a) Per-cat level is stored in `GameState.cyborg_levels` (source of truth for income), mirrored as `Main._cyborg_cat_ids` `id -> level` (source of truth for tint/loss only).
- (b) Income bridges via `GameState.get_onlypaws_cyborg_earning_units()`, used by `update_paws_rate()`, the GameState no-bot fallback, and Main's display fallback — no cross-scene reach.
- (c) Leveling UI is a single batch-of-one "Level Up Cyborg" button gated on completed research, consistent with the existing single `make_cyborg_button`.
