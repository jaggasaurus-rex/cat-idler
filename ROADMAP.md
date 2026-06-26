# Cat Idler — Roadmap

> Design intent and phase plan. Update as the game evolves.
> For current implementation state, see `CONTEXT.md`.

---

## Design pillars

1. **Tension through automation** — each upgrade that earns money passively also
   introduces a cost (cat attrition, growth rate, etc.) that the player must
   manage with further purchases.
2. **Readable numbers** — rates and costs stay in ranges the player can reason
   about without scientific notation or suffix abbreviations for as long as possible.
3. **One-way latches** — UI elements unlock permanently; nothing is hidden again
   once revealed.

---

## Phase overview

### Phase 1 — Core click loop ✅
- Manual earn button → money counter
- Cat purchase (escalating cost)
- Passive income via OnlyPaws (floor(cats/3) $/sec, unlocks at 3 cats)
- Procedural cat character with bob animation

### Phase 2 — Automation & attrition ✅ *(current phase)*

Introduce Manager-Bots as an income multiplier that brings a meaningful downside.

| Milestone | Trigger | Effect |
|---|---|---|
| Bot shop unlocks | `cats >= 6` | Player can buy bots |
| OnlyPaws toggle | Always visible once OnlyPaws unlocked | Player can pause income + attrition |
| Attrition begins | `manager_bots == 2` | Theft warning popup; 0.5 cats/min stolen per additional bot |
| Attrition-reduction shop | `manager_bots == 4` | Two one-time countermeasures unlock |

**Attrition-reduction shop items** (unlocked at 4 bots):

| Item | Cost | Effect |
|---|---|---|
| Contract w/ a Breeder | $2,000 | `cat_cost_growth_rate` 1.5 → 1.25; retroactive `next_cat_cost` recalc |
| Purchase Cat Trees | $4,000 | `attrition_rate_per_bot` 0.5 → 0.25; immediate rate recalc |

**Attrition formula:**
```
attrition cats/min = (manager_bots - 1) × attrition_rate_per_bot
```
Default: 1 cat/min per additional bot (0 at bot 1, 0.5/min at bot 2, 1.0/min at bot 3, …).
After Cat Trees: 0.5 cat/min per additional bot.

### Phase 3 — Upgrades *(planned)*
- Click value upgrade ("Better Petting Technique")
- Passive income upgrade ("Autonomous Purring")
- Upgrade panel scene (`res://scenes/UpgradePanel.tscn`)
- Upgrade cost system with disabled state when unaffordable

### Phase 4 — Generators / additional passive income *(planned)*
- Cat generator objects (produce $/sec independently of OnlyPaws)
- Generator data resource (`res://resources/GeneratorData.gd`)
- Generator list UI panel

### Phase 5 — Persistence *(planned)*
- Save/load to `user://save.json`
- Auto-save on timer
- Offline earnings calculation on load

### Phase 6 — Polish *(ongoing)*
- Click reaction animation (squash/stretch or colour flash on cat)
- Large-number formatting (K, M, B suffixes)
- Sound effects (click, purchase, attrition event)
- Settings menu (mute, reset save)
- Centred layout and styled labels/buttons

---

## 3-Panel Layout Overhaul — Designed, Not Yet Implemented

**Must ship before the Dog Attack system.** Reference: Spaceplan (see screenshot in design notes).

### Panel Structure
Three fixed vertical panels filling the full window width. Left and right panels are narrow and equal width (~270px). Center panel takes the remainder.

| Panel | Contents |
|---|---|
| **Left** | All current HUD labels (money, cats, food, tokens, bots, mega-bots, OnlyPaws rate, cat intelligence, happiness bar) + all action buttons (earn money, purchase cat, OnlyPaws toggle, buy food, buy tokens, manager bot, mega bot) |
| **Center** | Cat playground — cats wander freely here. Also the dog attack battlefield once that system ships. Replaces the current `CatContainer` free-placement approach; cats are now bounded to the center panel. |
| **Right** | Shop panel + Research column (currently `ShopPanel` and `CenterColumn`). Scrollable. |

### Key Architectural Changes
- `CatContainer` bounds become the center panel rect (cats can no longer walk over UI buttons).
- `CenterColumn` (research) and `ShopPanel` move into the right panel.
- Cat placement logic (`_place_cat`) must be updated to use center panel bounds instead of full viewport.
- Bubble and poop spawn positions must be updated to stay within center panel bounds.
- Sweeper movement must be bounded to the center panel.

---

## Dog Attack System — Designed, Not Yet Implemented

**Prerequisites:** 3-panel layout overhaul must ship first (center panel is the battlefield).

### Overview
A passive auto-battler mini-game. Cats defend against randomized dog attacks. Intentionally lightweight — should not overshadow the main idle loop.

### Unlock & First Attack
- `dog_defence` research completes → **"Self-fulfilling Prophecy"** achievement popup fires immediately.
  - Body: *"The dogs, generally speaking, are pretty chill. However, they noticed that your cats are planning something. They don't like that. In fact, they fucking hate that."*
  - Reward: *"WAR BABYYYYYYY — The dogs are a-comin, better watch out."*
- 30 seconds after popup dismissed → first attack warning begins.

### Attack Cycle
1. No countdown shown. Attacks feel spontaneous.
2. **Warning (10s):** Cats randomly hiss/growl (new sprite sheet needed).
3. **Resolution:** Outcome pre-calculated instantly at battle start; sprites animate the result.
4. **Outcome:** Win = gain Pride. Lose = lose Pride.
5. Timer resets for next attack.

### Attack Frequency
- Early game: 5–10 min randomized.
- Scales shorter as `housing_tier_index` and `cats` grow — dogs get bolder.

### Battlefield
- Center panel. 3 lanes (top, middle, bottom).
- Cats auto-distributed evenly; overflow to middle lane.
- Cats play hiss-and-charge animation transitioning to battle positions.
- No manual asset placement in v1 (deferred; revisit later).

### Strategy
- Single stance to start: **"Survive"**.
- Additional stances unlockable via future research (not yet designed).

### Battle Resolution
- **Cat strength** (deterministic): `cat_count × cyborg_multiplier × strategy_modifier`
- **Dog strength** (randomized): rolled within a range scaling with `housing_tier_index` and `cats`. Early game ceiling stays below typical cat strength — player wins more than loses. Both floor and ceiling rise with progression.
- Cat strength > dog strength → Win. Else → Lose.
- All constants in `Config.gd` for playtesting.

### Pride
- New `GameState` stat.
- Won on battle win; lost on battle loss. **Loss is the only drain.**
- Dual purpose:
  1. Progress meter toward late-game state flip (combined threshold with `cat_intelligence`).
  2. Minimum threshold gate for new dog-defence research (not spent — just a prerequisite).

### Dog-Defence Research Items (not yet defined)
- Three requirements per item: money cost + `min_intelligence` + `min_pride`.
- Example: `{ cost: 3_000_000, min_intelligence: 50, min_pride: 20 }`
- Specific items TBD.

### Late-Game State Flip (not yet designed)
- Pride + `cat_intelligence` hit a combined threshold → game flips to offensive mode.
- New UI: **"Total Dogs on Earth"** counter. Goal: reach 0.
- Thresholds and mechanics TBD.

### Assets (Deferred from v1)
- Purchasable lane assets (e.g. Mortars): researched to unlock, bought with money, destroyed on loss.
- Revisit after core battle loop is playtested.

### Sprites Needed
- Cat hissing/growling (warning phase)
- Dog unit (at least one type for v1)
- Battle visualization (cats and dogs in lanes)

---

## Known design tensions to revisit

- **Attrition vs. income scaling** — bots double income but attrition grows linearly;
  at high bot counts income vastly outpaces cat loss. May need a cap or exponential
  attrition curve in a later pass.
- **Cat Trees retroactivity** — the current halving applies immediately to the live
  rate; cats already lost are not refunded. Acceptable for now.
- **Breeder contract retroactivity** — recalculates `next_cat_cost` from scratch at
  the new rate. If the player has many cats this could make the next purchase very
  cheap. Intentional for now as a meaningful reward.
