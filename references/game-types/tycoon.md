# Tycoon Games

Economy and building games where players establish and grow a business, factory, or base.

**Examples:** Factory Tycoon, Restaurant Tycoon, Mining Simulator (tycoon variant), Lumber Tycoon

---

## Implied Decisions

When you say "tycoon," you're usually implying:

| Decision | Typical Answer | Why |
|----------|---------------|-----|
| Session format | Continuous world | Players expect to return to their plot in the same state |
| Persistence | Core economy | Plots, currency, upgrades, and unlocks must save |
| Exploit sensitivity | Medium-High | Currency/progression exploits break game balance |
| Authority model | Server-authoritative for purchases | Never trust client for transactions |
| Structure | Layered | Clear server/client boundaries for economy safety |

**If these don't match your vision, adjust during wizard setup.** But this is the default.

---

## Recommended Packages

```toml
[dependencies]
Promise = "evaera/promise"        # Async operations
GoodSignal = "stravant/goodsignal" # Custom events
Trove = "sleitnick/trove"         # Cleanup management

[server-dependencies]
ProfileStore = "lm-loleris/profilestore"  # Data persistence (required for tycoons)
```

**Optional but common:**
- Zone detection library for plot boundaries
- UI framework (Fusion) for complex upgrade menus

---

## MVP Checklist

Build these in order for a playable vertical slice:

### Phase 1: Core Loop (build first)
- [ ] **Plot claiming** — Player joins → gets assigned a plot
- [ ] **Basic dropper/collector** — One income source that works
- [ ] **Currency + UI** — Show the number going up
- [ ] **One purchasable upgrade** — Button that costs currency and does something visible
- [ ] **Data persistence** — Progress saves when player leaves

**Milestone:** Player can join, claim plot, earn currency, buy something, leave, rejoin with progress intact.

### Phase 2: Depth
- [ ] Multiple dropper types or tiers
- [ ] Upgrade paths (faster droppers, better collectors)
- [ ] Offline income calculation (optional)
- [ ] Plot expansion or new areas

### Phase 3: Engagement
- [ ] Rebirth/prestige system
- [ ] Daily rewards or login bonuses
- [ ] Quests or achievements
- [ ] Social features (visiting other plots)

---

## Common Patterns

### Architecture Overview

```
Server                          Client
──────                          ──────
PlotManager                     PlotController
  ├─ assigns plots                ├─ renders plot UI
  ├─ validates ownership          └─ sends purchase requests
  └─ stores plot state
                    ↕ Remotes ↕
DataManager                     TycoonUI
  ├─ ProfileStore integration     ├─ currency display
  └─ schema versioning            ├─ upgrade buttons
                                  └─ rebirth UI
UpgradeManager
  ├─ validates purchases
  ├─ applies effects
  └─ updates DataManager
```

### Plot Claiming Pattern

```luau
-- Server: PlotManager.luau
local PlotManager = {}

local plots = {}  -- plotId -> { owner: Player?, data: {} }
local playerPlots = {}  -- Player -> plotId

function PlotManager.claimPlot(player: Player): string?
    -- Find unclaimed plot
    for plotId, plot in plots do
        if not plot.owner then
            plot.owner = player
            playerPlots[player] = plotId
            return plotId
        end
    end
    return nil  -- No plots available
end

function PlotManager.getPlayerPlot(player: Player): string?
    return playerPlots[player]
end

function PlotManager.releasePlot(player: Player)
    local plotId = playerPlots[player]
    if plotId then
        plots[plotId].owner = nil
        playerPlots[player] = nil
    end
end

return PlotManager
```

### Purchase Validation Pattern

```luau
-- Server: UpgradeManager.luau
function UpgradeManager.purchaseUpgrade(player: Player, upgradeId: string): (boolean, string?)
    local playerData = DataManager.getPlayerData(player)
    if not playerData then
        return false, "Data not loaded"
    end

    local upgrade = GameConfig.Upgrades[upgradeId]
    if not upgrade then
        return false, "Invalid upgrade"
    end

    -- Check if already owned
    if playerData.upgrades[upgradeId] then
        return false, "Already owned"
    end

    -- Check currency (SERVER-SIDE - never trust client)
    if playerData.currency < upgrade.cost then
        return false, "Insufficient funds"
    end

    -- Deduct and grant
    playerData.currency -= upgrade.cost
    playerData.upgrades[upgradeId] = true

    -- Apply effect
    applyUpgradeEffect(player, upgrade)

    return true, nil
end
```

### Data Schema Pattern

```luau
-- Shared: DataTemplate.luau
return {
    -- Version for migrations
    schemaVersion = 1,

    -- Economy
    currency = 0,
    lifetimeCurrency = 0,  -- For rebirth calculations

    -- Progression
    upgrades = {},  -- upgradeId -> true
    rebirths = 0,

    -- Plot state
    plotData = {
        droppers = {},  -- dropperId -> { level: number, ... }
        collectors = {},
        decorations = {},
    },

    -- Timestamps
    lastPlayed = 0,  -- For offline income
}
```

---

## Pitfalls

### ❌ Storing plot state client-side
**Problem:** Exploiters can give themselves infinite upgrades.
**Fix:** All plot state lives on server. Client only renders what server tells it.

### ❌ Trusting client for purchase requests
**Problem:** Client says "I bought this for 0 currency."
**Fix:** Server validates currency, deducts, and grants. Client just sends intent.

### ❌ No offline income cap
**Problem:** Player disconnects for a week, comes back to infinite currency.
**Fix:** Cap offline income to reasonable maximum (e.g., 8 hours worth).

### ❌ Saving every currency change
**Problem:** DataStore throttling from constant writes.
**Fix:** Batch saves on intervals (every 30-60 seconds) and on player leave.

### ❌ No schema versioning
**Problem:** You change the data structure, existing players' data breaks.
**Fix:** Include `schemaVersion` and write migration logic. See `references/luau-patterns.md`.

### ❌ Plot collision on rejoin
**Problem:** Player rejoins, old plot hasn't released yet, gets assigned new plot.
**Fix:** Check for existing session, implement proper cleanup with `PlayerRemoving`.

---

## When This Profile Doesn't Fit

Consider adjustments if:

- **No persistence needed** — Maybe it's an arcade tycoon where progress resets. Use lower persistence setting.
- **Purely single-player** — Exploit sensitivity can be lower if there's no economy interaction between players.
- **Instanced plots** — Some tycoons use private servers or instanced areas. Session format may be "instanced" not "continuous."
