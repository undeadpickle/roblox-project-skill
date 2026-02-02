# Simulator Games

Collection and progression games focused on gathering, hatching, upgrading, and prestige mechanics.

**Examples:** Pet Simulator, Bee Swarm Simulator, Mining Simulator, Anime-themed simulators, Clicker/Idle games

---

## Implied Decisions

When you say "simulator" or "pet game," you're usually implying:

| Decision | Typical Answer | Why |
|----------|---------------|-----|
| Session format | Continuous world | Players grind in persistent areas |
| Persistence | Core economy | Pets, currency, upgrades, rebirths all must save |
| Exploit sensitivity | High | Duplication exploits destroy economy; trading makes it worse |
| Authority model | Server-authoritative | All inventory changes validated server-side |
| Structure | Layered | Complex server logic for economy, inventory, trading |

**If these don't match your vision, adjust during wizard setup.** But this is the default.

---

## Recommended Packages

```toml
[dependencies]
Promise = "evaera/promise"        # Async operations (critical for egg hatching)
GoodSignal = "stravant/goodsignal" # Custom events
Trove = "sleitnick/trove"         # Cleanup management

[server-dependencies]
ProfileStore = "lm-loleris/profilestore"  # Required - heavy data needs
```

**Consider adding:**
- RateLimiter module (included in skill starter code) — Essential for exploit protection
- Transaction logging — For investigating duplication reports

---

## MVP Checklist

Build these in order for a playable vertical slice:

### Phase 1: Core Loop (build first)
- [ ] **One collectible type** — Coins, gems, or whatever the primary resource is
- [ ] **Collection mechanic** — Click/touch to collect, or auto-collect in area
- [ ] **Currency display** — UI showing current amount
- [ ] **One egg/crate** — Purchasable thing that gives random pet/item
- [ ] **Basic inventory** — Store and display owned pets/items
- [ ] **Data persistence** — Currency and inventory save

**Milestone:** Player can collect currency, buy an egg, get a pet, see it in inventory, leave and rejoin with everything intact.

### Phase 2: Depth
- [ ] Multiple egg tiers (common → legendary)
- [ ] Pet stats/power affecting collection rate
- [ ] Pet equipping (limited active slots)
- [ ] Multiple collection areas with requirements

### Phase 3: Engagement
- [ ] Rebirth/prestige system
- [ ] Trading between players (careful — exploit risk)
- [ ] Pet fusion/upgrading
- [ ] Quests and achievements
- [ ] Limited-time eggs/events

---

## Reusable Patterns

See [patterns/](../patterns/INDEX.md) for code that applies across game types.

| Pattern | Use in Simulators |
|---------|-------------------|
| [Anti-Exploit](../patterns/anti-exploit.md) | Rate limiting purchases, validating collection, stat validation |
| [Trigger Systems](../patterns/trigger-systems.md) | Area triggers for collection zones, unlock zone detection |
| [Audio Systems](../patterns/audio-systems.md) | Collection sounds, egg hatching audio, area ambient music |
| [AI Systems](../patterns/ai-systems.md) | Pet AI for following player, combat pet behavior |

---

## Common Patterns

### Architecture Overview

```
Server                          Client
──────                          ──────
InventoryManager                InventoryUI
  ├─ add/remove items             ├─ displays owned pets
  ├─ validate operations          └─ equip/unequip buttons
  └─ duplication protection
                    ↕ Remotes ↕
EggManager                      EggUI
  ├─ purchase validation          ├─ egg purchase buttons
  ├─ random roll logic            └─ hatching animation
  └─ grants to inventory

DataManager                     CollectionController
  ├─ ProfileStore                 └─ sends collection events
  └─ schema versioning

CollectionService               GameUI
  ├─ validates collection          ├─ currency display
  └─ applies pet multipliers       └─ area requirements
```

### Inventory Management Pattern

```luau
-- Server: InventoryManager.luau
local InventoryManager = {}

local MAX_INVENTORY_SIZE = 100  -- Prevent infinite inventory exploits

function InventoryManager.addItem(player: Player, itemId: string, amount: number?): boolean
    local playerData = DataManager.getPlayerData(player)
    if not playerData then return false end

    amount = amount or 1

    -- Validate item exists
    if not GameConfig.Items[itemId] then
        warn(`Invalid item: {itemId}`)
        return false
    end

    -- Check inventory space
    local currentCount = #playerData.inventory
    if currentCount + amount > MAX_INVENTORY_SIZE then
        return false  -- Inventory full
    end

    -- Add items
    for i = 1, amount do
        table.insert(playerData.inventory, {
            id = itemId,
            uuid = HttpService:GenerateGUID(false),  -- Unique ID for each instance
            obtained = os.time(),
        })
    end

    return true
end

function InventoryManager.removeItem(player: Player, uuid: string): boolean
    local playerData = DataManager.getPlayerData(player)
    if not playerData then return false end

    for i, item in playerData.inventory do
        if item.uuid == uuid then
            table.remove(playerData.inventory, i)
            return true
        end
    end

    return false  -- Item not found
end

return InventoryManager
```

### Egg Hatching Pattern

```luau
-- Server: EggManager.luau
local EggManager = {}

function EggManager.purchaseEgg(player: Player, eggId: string): string?
    local playerData = DataManager.getPlayerData(player)
    if not playerData then return nil end

    local egg = GameConfig.Eggs[eggId]
    if not egg then return nil end

    -- Check currency (SERVER-SIDE)
    if playerData.currency < egg.cost then
        return nil  -- Can't afford
    end

    -- Check inventory space BEFORE deducting currency
    if #playerData.inventory >= MAX_INVENTORY_SIZE then
        return nil
    end

    -- Deduct currency
    playerData.currency -= egg.cost

    -- Roll for pet
    local pet = rollForPet(egg.drops)

    -- Add to inventory
    local success = InventoryManager.addItem(player, pet.id)
    if not success then
        -- Refund if something went wrong (shouldn't happen but safety)
        playerData.currency += egg.cost
        return nil
    end

    return pet.id
end

local function rollForPet(drops: { { id: string, weight: number } }): { id: string }
    local totalWeight = 0
    for _, drop in drops do
        totalWeight += drop.weight
    end

    local roll = math.random() * totalWeight
    local cumulative = 0

    for _, drop in drops do
        cumulative += drop.weight
        if roll <= cumulative then
            return { id = drop.id }
        end
    end

    -- Fallback (shouldn't reach)
    return drops[1]
end

return EggManager
```

### Pet Equipping Pattern

```luau
-- Server: PetManager.luau
local PetManager = {}

local MAX_EQUIPPED = 3  -- Limit equipped pets

function PetManager.equipPet(player: Player, uuid: string): boolean
    local playerData = DataManager.getPlayerData(player)
    if not playerData then return false end

    -- Verify player owns this pet
    local pet = nil
    for _, item in playerData.inventory do
        if item.uuid == uuid then
            pet = item
            break
        end
    end

    if not pet then return false end  -- Doesn't own it

    -- Check if already equipped
    if table.find(playerData.equipped, uuid) then
        return false  -- Already equipped
    end

    -- Check slot limit
    if #playerData.equipped >= MAX_EQUIPPED then
        return false  -- No slots
    end

    table.insert(playerData.equipped, uuid)
    return true
end

function PetManager.unequipPet(player: Player, uuid: string): boolean
    local playerData = DataManager.getPlayerData(player)
    if not playerData then return false end

    local index = table.find(playerData.equipped, uuid)
    if index then
        table.remove(playerData.equipped, index)
        return true
    end

    return false
end

return PetManager
```

### Data Schema for Simulators

```luau
-- Shared: DataTemplate.luau
return {
    schemaVersion = 1,

    -- Currencies (often multiple)
    coins = 0,
    gems = 0,  -- Premium currency

    -- Inventory (array of item instances)
    inventory = {},  -- { { id: string, uuid: string, obtained: number }, ... }

    -- Equipped items (array of UUIDs)
    equipped = {},

    -- Progression
    rebirths = 0,
    multiplier = 1,  -- From rebirths

    -- Stats
    totalCollected = 0,
    eggsOpened = 0,

    -- Unlocks
    unlockedAreas = { "Starter" },

    -- Timestamps
    lastPlayed = 0,
}
```

---

## Pitfalls

### ❌ Client-side inventory management
**Problem:** Exploiters duplicate pets by manipulating client state.
**Fix:** Inventory is SERVER-ONLY. Client displays what server tells it. All changes go through server validation.

### ❌ No UUID on items
**Problem:** Can't distinguish between two of the same pet. Trading/deleting breaks.
**Fix:** Every item instance gets a unique UUID when created.

### ❌ Roll logic on client
**Problem:** Exploiters can manipulate RNG to always get legendaries.
**Fix:** All random rolls happen server-side. Client only sees the result.

### ❌ Trading without transaction logging
**Problem:** Duplication exploit happens, no way to investigate or rollback.
**Fix:** Log every trade with timestamps, player IDs, and item UUIDs. Review suspicious patterns.

### ❌ No inventory limit
**Problem:** Players (or exploiters) accumulate thousands of items, data size explodes.
**Fix:** Hard cap on inventory size. Provide ways to delete/fuse unwanted items.

### ❌ Currency overflow
**Problem:** Player hits number limits, currency goes negative or wraps.
**Fix:** Cap currencies at safe maximum (e.g., 10^15). Use proper number types.

### ❌ Rebirth deletes items unexpectedly
**Problem:** Player rebirths, loses pets they thought were safe.
**Fix:** Clearly communicate what resets and what doesn't. Consider "permanent" slots.

---

## Trading Considerations

Trading is **high risk** for simulators. If you add it:

1. **Server-authoritative trades** — Both parties must confirm on server
2. **Item locking** — Items in trade are locked from other operations
3. **Transaction logging** — Log every trade for investigation
4. **Trade limits** — Cooldowns, daily limits, level requirements
5. **Scam prevention** — Clear UI showing exactly what's being exchanged

Many successful simulators **don't have trading** to avoid these issues entirely.

---

## Variations

### Idle/Clicker Simulator
- Auto-collection over time
- Offline progress calculation
- Prestige multipliers are the core loop
- Less pet-focused, more upgrade-focused

### Combat Simulator
- Pets/units have combat stats
- Area clear mechanics instead of just collection
- Boss battles and dungeons
- Closer to RPG than traditional simulator

### Crafting Simulator
- Collection feeds into crafting system
- Recipes and combinations
- More inventory management complexity
