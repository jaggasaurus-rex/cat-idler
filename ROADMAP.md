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
- Passive income via Onlypaws (floor(cats/3) $/sec, unlocks at 3 cats)
- Procedural cat character with bob animation

### Phase 2 — Automation & attrition ✅ *(current phase)*

Introduce Manager-Bots as an income multiplier that brings a meaningful downside.

| Milestone | Trigger | Effect |
|---|---|---|
| Bot shop unlocks | `cats >= 6` | Player can buy bots |
| Onlypaws toggle | Always visible once Onlypaws unlocked | Player can pause income + attrition |
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
- Cat generator objects (produce $/sec independently of Onlypaws)
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

## Known design tensions to revisit

- **Attrition vs. income scaling** — bots double income but attrition grows linearly;
  at high bot counts income vastly outpaces cat loss. May need a cap or exponential
  attrition curve in a later pass.
- **Cat Trees retroactivity** — the current halving applies immediately to the live
  rate; cats already lost are not refunded. Acceptable for now.
- **Breeder contract retroactivity** — recalculates `next_cat_cost` from scratch at
  the new rate. If the player has many cats this could make the next purchase very
  cheap. Intentional for now as a meaningful reward.
