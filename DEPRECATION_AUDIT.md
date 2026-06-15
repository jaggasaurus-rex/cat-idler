# Deprecation Audit — Cat Idler

> **Read-only audit.** No game code, scene, asset, Config, or Strings file was modified
> in producing this report. Nothing here has been acted upon. Findings are grouped by the
> three requested categories, HIGH-confidence items first within each category.
>
> **Scope note:** Per the audit brief, *merely* zero-reference functions, variables, Config
> constants, or Strings consts are out of scope and are NOT reported as standalone findings.
> Where a write-only flag or unwired function is reported below, it is because it represents a
> **whole feature / system left inert or superseded** (Category 3) or an **orphaned scene node**
> (Category 1) — not because the symbol alone is unused. Tension with the exclusion rule is
> called out explicitly in each such case.
>
> Verification commands were run across `*.gd` (`grep -rn`), `Main.tscn`, and `CatCharacter.tscn`.

---

## Category 1 — Orphaned Scene Nodes

### 1.1 `OnlyPawsInfoPanel` (+ child `InfoLabel`) — **HIGH**

- **Location:** `scenes/Main.tscn`
  - `OnlyPawsInfoPanel` (PanelContainer): node path `OnlyPawsInfoPanel`, lines **95–101**
  - `InfoLabel` (Label): node path `OnlyPawsInfoPanel/InfoLabel`, lines **103–108**
- **What it is / why it's dead:** A legacy panel that once displayed OnlyPaws explanatory text.
  It is `visible = false` in the scene, has **no `@onready` reference** in `Main.gd`, has **no
  signal connection** in the scene's `[connection]` block (lines 814–838), and is never shown or
  mutated anywhere in code. The OnlyPaws explanation now lives in `OnlyPawsPopup` + `POPUP_ONLY_PAWS`.
- **Evidence:**
  - `grep -rn "OnlyPawsInfoPanel\|InfoLabel" --include=*.gd .` → **no matches** (zero code references).
  - Scene declares it hidden: `scenes/Main.tscn:96` → `visible = false`.
  - No entry for `OnlyPawsInfoPanel` among the 25 `[connection]` lines (`Main.tscn:814–838`).
  - CONTEXT.md already flags it: line 76 — *"hidden permanently (legacy node, not wired to button
    anymore)"*; and feature line 439 — *"OnlyPaws info panel … (legacy node, permanently hidden)."*
- **Confidence:** HIGH — provably dead; safe to remove.
- **Removal blast radius:**
  - Delete the two nodes from `scenes/Main.tscn` (lines 95–108).
  - Update CONTEXT.md: scene-tree lines 76–77 and Current-Features line 439 reference it.
  - No `.gd` change required (nothing references it). No signal/handler cleanup needed.
  - `InfoLabel` text is inline in the `.tscn` and not mirrored in `Strings.gd`, so no Strings change.

*(No other orphaned scene nodes were found. Every other node in `Main.tscn` is either bound by an
`@onready` var in `Main.gd`, wired via a `[connection]`, or a static always-visible label
(`HappinessMinLabel` "0%", `HappinessMaxLabel` "100%", `OnlyPawsHint`, `ResearchHint`, etc.).
Code-built nodes — the sweeper, debug menu, `CatIntelligenceLabel`, and the dynamic shop buttons —
are all referenced and shown.)*

---

## Category 2 — Commented-Out / Dead Blocks

### 2.1 Stale `get_happiness()` docstring describing the removed two-segment model — **LOW**

- **Location:** `autoloads/GameState.gd`, lines **375–381** (the `##` docstring above
  `get_happiness()`), tied to the dead helper `_happiness_breakpoints()` (lines 398–402).
- **What it is / why it's (partially) dead:** The docstring describes an algorithm the function no
  longer implements:
  > `## Two-segment quadratic ease-in decay above max_cats, breakpoints scaled by housing tier:`
  > `##   fifty_break = max_cats + Config.happiness_fifty_break_offset + housing_tier_index  → happiness = 50%`
  > `##   zero_break  = max_cats + Config.happiness_zero_break_offset + housing_tier_index * 2  → happiness = 0%`
  > `## Segment 1 (max_cats < cats < fifty_break): t^2 ease-in from 100% down to 50%.`
  > `## Segment 2 (fifty_break <= cats < zero_break): t^2 ease-in from 50% down to 0%.`

  The actual body (lines 382–392) is the **poop-driven** model: `100 * (1 - t*t)` where
  `t = clamp((poop_count / cats) / Config.POOP_MAX_RATIO, 0, 1)`. The cats-over-max breakpoint logic
  it describes survives only in the unused `_happiness_breakpoints()` helper.
- **Evidence:** Body at `GameState.gd:382–392` reads `poop_count`, not the breakpoints; the only
  consumer of the documented breakpoint formula is `_happiness_breakpoints()` (line 398), which
  `grep -rn "_happiness_breakpoints"` shows is **never called**.
- **Confidence:** LOW — this is a *dead/misleading comment block*, not commented-out code or an
  unreachable branch. It is reported here only because it documents removed logic; a maintainer may
  intend to keep it as design intent for a future redesign (see `_happiness_breakpoints` note in
  CONTEXT.md line 260: *"kept in place for when the happiness mechanic is redesigned"*).
- **Removal blast radius:** Rewriting the docstring is doc-only and touches nothing else. If the
  intent were also to retire the helper it documents, see the Questions section (excluded by the
  zero-reference rule).

> **No literal commented-out code and no unreachable code branches were found.**
> `grep -rnE "^[[:space:]]*#[[:space:]]*(var |func |if |for |else|elif |return|GameState\.|...)"`
> over all `*.gd` returned only ordinary explanatory comments (`Main.gd:545`, `CatCharacter.gd:4`),
> not disabled code. Every conditional branch checked is reachable under current constants — in
> particular, happiness **can** reach 0% in the poop model (ratio ≥ `POOP_MAX_RATIO` ⇒ `t=1` ⇒ 0),
> so the riot / cat-crusher / cat-loss-drain branches gated on `happiness <= 0` and `<= 20` are
> **live**, not dead. (Note: CONTEXT.md lines 242 & 259 assert happiness "can no longer reach 0";
> that assertion is itself stale — see Questions — but the code it would render dead is actually
> reachable, so there is no dead branch to report.)

---

## Category 3 — Disabled Features Behind Flags / Inert Systems

### 3.1 `shop_unlocked_bots` — gate for a never-built "attrition-reduction shop" — **MEDIUM**

- **Location:** `autoloads/GameState.gd`
  - declaration line **20**: `var shop_unlocked_bots: bool = false`
  - set-site lines **225 / 235–236** (in `buy_bot()`):
    `## Unlocks the attrition-reduction shop (shop_unlocked_bots) at manager_bots == 4.`
    … `if manager_bots == 4:` → `shop_unlocked_bots = true`
- **What it is / why it's dead:** A flag that **is set true** (at the 4th Manager-Bot) but is **never
  read** anywhere. Its stated purpose — revealing an "attrition-reduction shop" — does not exist in
  the codebase; no UI, no handler, and no logic consumes it. The feature was evidently planned or
  removed, leaving the flag and its set-site as vestigial scaffolding.
- **Evidence:** `grep -rn "shop_unlocked_bots" --include=*.gd .` → only the declaration (line 20),
  the docstring (225), and the assignment (236). **Zero reads.** No "attrition" shop node exists in
  `Main.tscn`; `grep -rn "attrition"` → only the GameState comment.
- **Confidence:** MEDIUM — provably write-only and its target system is absent, but the brief
  excludes *merely* unreferenced variables; reported because it documents an inert/never-built
  **system**. A human should confirm the attrition shop is abandoned (vs. planned) before removal.
- **Removal blast radius:** Remove the var (line 20), the `if manager_bots == 4:` block (lines
  235–236), and the line-225 docstring clause. `buy_bot()` otherwise unaffected. Update CONTEXT.md
  line 185. No UI or signal impact (nothing reads it).

### 3.2 `shop_unlocked` — superseded gate; Purchase Cat button is now always visible — **MEDIUM**

- **Location:** `autoloads/GameState.gd`
  - declaration line **11**: `var shop_unlocked: bool = false`
  - set-site lines **199–201** (in `click()`): `if not shop_unlocked and money >= next_cat_cost:` →
    `shop_unlocked = true`
- **What it is / why it's dead:** A one-way latch that historically revealed the Purchase Cat button.
  It **is set true** but is **never read**. In the current scene the `PurchaseCatButton` is visible
  from game start (`Main.tscn:51–57` has no `visible = false`) and `Main.gd` never gates it on
  `shop_unlocked`. The gating mechanic was superseded by an always-visible button.
- **Evidence:**
  - `grep -rn "shop_unlocked" scenes/Main.gd` returns only `bot_shop_unlocked`, `tokens_shop_unlocked`,
    and `home_shop_unlocked` — **never plain `shop_unlocked`.**
  - In `GameState.gd`, plain `shop_unlocked` appears only at declaration (11) and set (200–201).
  - CONTEXT.md line 436 still claims the button is *"permanently revealed (one-way latch via
    `shop_unlocked`)"* — stale; the button is unconditionally visible.
- **Confidence:** MEDIUM — write-only and functionally superseded; flagged (not HIGH) because of the
  exclusion-rule tension (it is technically a single-symbol write-only variable) and because a human
  should confirm no future save/serialization use is intended (no save system exists today — Phase 4
  in CONTEXT.md is unchecked).
- **Removal blast radius:** Remove the var (line 11) and the `if not shop_unlocked …` block in
  `click()` (lines 199–201). Update CONTEXT.md line 436 (and the var table line 177). No scene or UI
  change — the button is already always visible.

### 3.3 Breeder Contract — fully implemented feature with no entry point — **LOW**

- **Location:**
  - `Config.gd:37–38` — `breeder_contract_cost` (2000.0), `breeder_contract_growth_rate` (1.25)
  - `autoloads/GameState.gd:22` — `var breeder_purchased: bool = false`
  - `autoloads/GameState.gd:251–259` — `func buy_breeder_contract()` (deducts cost, sets
    `breeder_purchased`, lowers `cat_cost_growth_rate`, recomputes `next_cat_cost`)
  - `cat_cost_growth_rate` var consumes `breeder_contract_growth_rate` only via this function.
- **What it is / why it may be dead:** A complete, self-consistent upgrade (cost + flag + purchase
  method) that is **never invoked** — there is no shop button, no scene node, and no caller of
  `buy_breeder_contract()`. The whole feature is inert from the player's perspective.
- **Evidence:** `grep -rn "breeder" --include=*.gd .` shows the only references are the definitions
  themselves; `buy_breeder_contract` has **no callers**. No "breeder" node in `Main.tscn`.
- **Confidence:** LOW — likely **intentional**, not abandoned. CONTEXT.md line 445 lists it under
  *Current Features*: *"Upgrade stubs (GameState only) — `buy_breeder_contract()` exists in GameState
  but is not wired to any UI."* That phrasing marks it as a deliberate stub awaiting UI wiring, so it
  is suspicious-but-plausibly-intentional rather than safe-to-delete.
- **Removal blast radius (if ever retired):** Remove `buy_breeder_contract()` (251–259),
  `breeder_purchased` (22), the two Config consts (37–38), and simplify the `cat_cost_growth_rate`
  description. The `cat_cost_growth_rate` var itself must stay (it is read live in `buy_cat()`),
  only its breeder-driven reassignment goes away. Update CONTEXT.md lines 187, 188, 257, 295, 296,
  436, 445. **Recommend confirming with the designer first** — this reads as planned content.

---

## Questions / Ambiguous

These could not be classified as in-scope findings with confidence, or are explicitly excluded by the
audit's "no zero-reference symbols" rule but are worth a human's attention:

1. **`_happiness_breakpoints()` + `Config.happiness_fifty_break_offset` / `happiness_zero_break_offset`**
   (`GameState.gd:398–402`, `Config.gd:61–62`). The helper is **never called** and the two offsets
   feed **only** that helper, so the whole cluster is dead. It is **excluded** from the formal
   findings above because the brief puts zero-reference functions/constants out of scope, and because
   CONTEXT.md line 260 says it is *"kept in place for when the happiness mechanic is redesigned"*
   (intentional retention). Flagged here so a human can decide whether the "future redesign" intent
   still holds. This is the logic the stale docstring (Finding 2.1) describes.

2. **CONTEXT.md internal contradiction about happiness reaching 0** (doc issue, not code). Lines 242
   and 259 state happiness "can no longer reach 0%" / "legacy happiness state vars remain inert," but
   the live poop-driven `get_happiness()` *can* return 0, and `happiness_riot_triggered`,
   `cat_crusher_triggered`, and the cat-loss drain are reachable and active. context-validator
   reported CONTEXT.md as IN SYNC, so this was left untouched, but the prose is misleading and may
   warrant correction in a separate (non-audit) change.

3. **CONTEXT.md duplicated/garbled `GameOver2Popup` sub-tree** (lines 99–102) appears to be a
   copy-paste artifact (a stray second `DialogPanel`/`PopupLabel` describing the *Fasting* popup under
   GameOver2). This is a documentation glitch, not dead game code; noted for completeness only.

4. **`only_paws_cats_per_tier`** (`Config.gd:21`) is a zero-reference constant (declared, never used).
   Excluded by the rule; mentioned only so it is not mistaken for an oversight.

5. **`POPUP_INSPIRATION`** (`Strings.gd:106`) is the literal placeholder
   `"[PLACEHOLDER — edit this string in Strings.gd]"`. It is **not dead** — it is rendered by
   `_show_inspiration_popup()` — but it is unfinished copy. Out of scope for deprecation; flagged so
   it is not shipped as-is.

---

### Verification appendix (commands run)

```
grep -rn "OnlyPawsInfoPanel\|InfoLabel" --include=*.gd .        # → no matches (1.1)
grep -rn "shop_unlocked\b"             --include=*.gd .         # plain shop_unlocked write-only (3.2)
grep -rn "shop_unlocked"               scenes/Main.gd           # only bot_/tokens_/home_ variants (3.2)
grep -rn "shop_unlocked_bots"          --include=*.gd .         # decl + comment + set, no reads (3.1)
grep -rn "breeder"                     --include=*.gd .         # defs only, no callers (3.3)
grep -rn "_happiness_breakpoints"      --include=*.gd .         # defined, never called (Q1)
grep -rn "happiness_fifty_break_offset\|happiness_zero_break_offset" --include=*.gd .  # feed only the dead helper (Q1)
grep -rnE "^\s*#\s*(var |func |if |for |else|elif |return|GameState\.|...)" --include=*.gd .  # no commented-out code (Cat 2)
```
