# Library Recommendations

What to use, what to avoid, and how they work together.

## Quick Reference: The 2025 Stack

| Category | Recommended | Notes |
|----------|-------------|-------|
| **Async** | Promise (evaera) | Industry standard |
| **Signals** | GoodSignal (stravant) | Full RBXScriptSignal API parity |
| **Cleanup** | Trove or Janitor | Pick one, not both |
| **Data** | ProfileStore (loleris) | Successor to ProfileService |
| **UI** | Fusion 0.3 (Elttob) | Luau-native, built-in cleanup |
| **Networking** | Raw RemoteEvents | Fine for most games |

---

## Frameworks: Go Framework-less

**Do not use Knit** — archived July 2024. The author recommends against it for new projects.

**Nevermore** is actively maintained (270+ packages) but complex—better suited for experienced teams building large games.

**Recommended approach:** Use individual utilities (Promise, Trove, GoodSignal) with explicit module-based architecture. No framework abstractions to learn or maintain.

---

## Data Persistence

| Library | Status | Recommendation |
|---------|--------|----------------|
| **ProfileStore** | Active | ✅ Use for new projects |
| ProfileService | Maintained | Fine for existing projects |
| DataStore2 | Low activity | ❌ Avoid for new projects |

### Why ProfileStore?

ProfileStore is the successor to ProfileService by the same author (loleris):

- **Faster cross-server:** Uses MessagingService for near-instant session lock release (vs 30+ second waits)
- **Fewer API calls:** 300-second auto-save reduces DataStore throttling risk
- **Session locking:** Prevents item duplication exploits
- **Luau types:** Built-in type checking support

### When ProfileService is fine

- Existing projects already using it
- Simple games without trading/economies
- You don't need cross-server speed

---

## UI Frameworks

| Library | Status | Recommendation |
|---------|--------|----------------|
| **Fusion 0.3** | Active | ✅ Recommended for new projects |
| React-lua | Active | Good if you already know React |
| Roact | Deprecated | ❌ Migrate to React-lua or Fusion |

### Why Fusion 0.3?

- **Luau-native:** No JavaScript paradigm translation
- **Reactive:** UI automatically updates when state changes
- **Built-in cleanup:** Scopes act like Janitor/Trove (see Cleanup Strategy below)
- **Built-in animation:** Springs and tweens as first-class features
- **Gentler learning curve:** Easier than React ports

### When React-lua makes sense

- Team already knows React
- Porting existing React components
- Preference for component-based architecture

---

## Networking

For most solo/small team games, **raw RemoteEvents work fine**. Bandwidth gains from networking libraries are marginal except in high-frequency scenarios (60+ events/second).

| Library | Status | Notes |
|---------|--------|-------|
| **Raw RemoteEvents** | Always works | ✅ Default choice |
| Zap 0.6.x | Active (rewrite in progress) | Use stable branch if needed |
| BridgeNet2 | Archived | ❌ Don't use |
| ByteNet | Archived | ❌ Don't use |
| Red | Low activity | Works but not recommended |

### When to consider Zap

- MMO-scale player counts
- High-frequency replication (physics sync, real-time combat)
- You need buffer-based serialization

---

## Utility Libraries

### Promise (evaera)

**Status:** Active, industry standard

Use for any async operation: DataStore calls, HTTP requests, animations with timeouts.

```luau
local Promise = require(Packages.Promise)

Promise.new(function(resolve, reject)
    local success, result = pcall(DataStore.GetAsync, DataStore, key)
    if success then resolve(result) else reject(result) end
end)
:andThen(function(data) print("Got:", data) end)
:catch(function(err) warn("Failed:", err) end)
```

### GoodSignal (stravant)

**Status:** Stable, feature-complete

Pure Luau signal implementation. Faster than BindableEvents, preserves metatables.

```luau
local GoodSignal = require(Packages.GoodSignal)

local OnDamaged = GoodSignal.new()
OnDamaged:Connect(function(amount) print("Took", amount, "damage") end)
OnDamaged:Fire(25)
```

**Why not sleitnick/signal?** Both work, but GoodSignal has full RBXScriptSignal API parity (`:Wait()`, `:Once()`, etc.) and is the community standard.

### Trove (sleitnick)

**Status:** Active

Modern cleanup library. Track instances, connections, signals—destroy all at once.

```luau
local Trove = require(Packages.Trove)

local trove = Trove.new()
trove:Add(workspace.Part)
trove:Connect(Players.PlayerAdded, onPlayerAdded)
trove:Add(GoodSignal.new())

-- Later: clean everything
trove:Destroy()
```

### Janitor (howmanysmall)

**Status:** Active

Feature-rich alternative to Trove. More methods, native Promise support.

```luau
local Janitor = require(Packages.Janitor)

local janitor = Janitor.new()
janitor:Add(workspace.Part, "Destroy")
janitor:Add(myPromise, "cancel")
janitor:LinkToInstance(player.Character)

janitor:Cleanup()
```

### Which cleanup library?

**Pick one.** Using both is redundant.

| Choose | If you want |
|--------|-------------|
| **Trove** | Simpler API, RbxUtil ecosystem |
| **Janitor** | More features, Promise-first, max performance |

---

## Cleanup Strategy by Layer

This is critical for avoiding memory leaks:

| Layer | Cleanup Tool | Why |
|-------|-------------|-----|
| **UI (Fusion 0.3)** | Fusion Scope | Built-in. Don't wrap Fusion objects in Trove/Janitor. |
| **Game Logic** | Trove or Janitor | Weapons, NPCs, data managers, non-UI systems |
| **Promises** | Add to Trove/Janitor | Always. Prevents ghost logic when player leaves. |
| **GoodSignal** | Add to Trove/Janitor/Scope | Auto-disconnects when parent is destroyed |

### The Fusion 0.3 "Gotcha"

Fusion 0.3's Scope acts like a built-in Janitor. **Don't double-manage:**

```luau
-- ❌ Wrong: Two cleanup systems fighting
local trove = Trove.new()
local scope = Fusion:scoped()
trove:Add(scope:New("Frame")(...)) -- Conflict!

-- ✅ Right: Let Fusion handle UI cleanup
local scope = Fusion:scoped()
local frame = scope:New("Frame")(...)
-- Later: scope:doCleanup() handles everything
```

Use Trove/Janitor for **non-Fusion** systems (game logic, data, etc.).

---

## Compatibility Matrix

| Pairing | Relationship | Best Practice |
|---------|--------------|---------------|
| Fusion + Promise | Excellent | Fetch data with Promise, bind UI to result |
| Fusion + GoodSignal | Good | Use Observers to bridge reactive UI and signals |
| Fusion + Trove | Redundant for UI | Let Scope handle UI; use Trove for game logic |
| Promise + Janitor/Trove | Essential | Always add Promises to cleanup |
| ProfileStore + Promise | Essential | Wrap `StartSessionAsync` in Promise |
| ProfileStore + Fusion | Powerful | Map `Profile.Data` to Fusion state |

---

## Archived/Deprecated — Do Not Use

| Library | Status | Replacement |
|---------|--------|-------------|
| **Knit** | Archived July 2024 | Framework-less approach |
| **Roact** | Deprecated | Fusion 0.3 or React-lua |
| **BridgeNet2** | Archived | Raw RemoteEvents or Zap |
| **ByteNet** | Archived | Raw RemoteEvents or Zap |
| **DataStore2** | Low maintenance | ProfileStore |

---

## A Note on GitHub Activity

Some libraries show infrequent commits. This usually means **"stable and feature-complete,"** not "abandoned."

**GoodSignal** and **ProfileStore** are examples—they work, they're done, they don't need constant updates.

Before panicking about an "inactive" repo, check:
- Are issues being responded to?
- Are there recent releases (even without commits)?
- Is it still recommended in DevForum discussions?

---

## Migration Paths

Guides for moving from older libraries to recommended alternatives.

### ProfileService → ProfileStore

ProfileStore is the successor by the same author (loleris). Key differences:

| ProfileService | ProfileStore |
|----------------|--------------|
| `ProfileService.GetProfileStore()` | `ProfileStore.New()` |
| `Profile:Release()` | `Profile:EndSession()` |
| `Profile:ListenToRelease()` | `Profile.OnSessionEnd` |
| 30+ second session locks | Near-instant via MessagingService |

**Migration steps:**

1. Install ProfileStore alongside ProfileService
2. Create new data key (e.g., `PlayerData_v2`)
3. On player join: load ProfileStore, migrate data from ProfileService if needed
4. Remove ProfileService after all players have migrated

```luau
-- Simple migration check
local oldProfile = ProfileService.GetProfileStore("PlayerData"):LoadProfileAsync(key)
local newProfile = ProfileStore.New("PlayerData_v2", DEFAULT_DATA):StartSessionAsync(key)

if oldProfile and newProfile.Data.migratedAt == 0 then
    -- Copy old data to new
    for key, value in oldProfile.Data do
        newProfile.Data[key] = value
    end
    newProfile.Data.migratedAt = os.time()
    oldProfile:Release()
end
```

### Roact → Fusion 0.3

Fusion uses different paradigms than Roact:

| Roact | Fusion 0.3 |
|-------|------------|
| `Roact.createElement()` | `scope:New()` |
| `Roact.mount()` | Direct parenting |
| `Roact.unmount()` | `scope:doCleanup()` |
| `useState` hook | `scope:Value()` |
| Props drilling | Computed values |

**Key concept changes:**

- **No virtual DOM** — Fusion creates real instances
- **Reactive by default** — Values auto-update UI
- **Scoped cleanup** — Scope replaces Roact lifecycle

```luau
-- Roact
local element = Roact.createElement("TextLabel", {
    Text = self.state.count,
})
Roact.mount(element, parent)

-- Fusion 0.3
local scope = Fusion:scoped()
local count = scope:Value(0)

scope:New("TextLabel")({
    Parent = parent,
    Text = scope:Computed(function(use)
        return tostring(use(count))
    end),
})
```

**Migration strategy:** Rewrite components one at a time. Fusion and Roact can coexist during migration.

### Knit → Framework-less

Knit was archived July 2024. The author recommends not using it for new projects.

**What Knit provided:**

| Knit Feature | Replacement |
|--------------|-------------|
| `Knit.CreateService()` | Plain ModuleScript |
| `Knit.CreateController()` | Plain ModuleScript |
| `Knit.Start()` | Manual initialization |
| `service.Client` remotes | Remotes.luau helper |
| `Knit.GetService()` | Direct require |

**Migration approach:**

1. **Services become modules** — Same code, just export functions directly
2. **Remove Knit.Start()** — Call init functions explicitly from entry points
3. **Replace service.Client** — Use centralized Remotes module

```luau
-- Before (Knit)
local DataService = Knit.CreateService({
    Name = "DataService",
    Client = {
        GetData = Knit.CreateSignal(),
    },
})

function DataService:KnitStart()
    -- init
end

-- After (framework-less)
local DataService = {}

function DataService.init()
    -- init
end

function DataService.getData(player)
    -- implementation
end

return DataService
```

The main loss is automatic service discovery. In practice, explicit requires are clearer and easier to trace.

---

## Wally Package Names

For `wally.toml`:

```toml
[dependencies]
Promise = "evaera/promise"
GoodSignal = "stravant/goodsignal"
Trove = "sleitnick/trove"

[server-dependencies]
ProfileStore = "loleris/profilestore"
```

**Notes:**
- ProfileStore goes in `[server-dependencies]` (server-only)
- Fusion is typically vendored or submoduled, not on Wally
- Don't pin versions unless you have a specific reason—let Wally resolve latest
