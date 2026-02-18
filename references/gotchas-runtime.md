# Gotchas: Runtime & Replication

Issues that show up at runtime — memory leaks, DataStore behavior, streaming, Studio vs Live differences.

**AI agents:** Update this file when you discover runtime surprises or "works in Studio but breaks in prod" behaviors.

## Contents

- [Memory Leaks](#memory-leaks) — Connection circular references, PlayerAdded nesting
- [DataStores](#datastores) — Throttling, UpdateAsync
- [StreamingEnabled](#streamingenabled) — Instances not existing on client
- [BindToClose Timeout](#bindtoclose-timeout) — 30s in prod, unlimited in Studio
- [Deferred Signal Behavior](#deferred-signal-behavior) — Default since Feb 2024
- [Studio vs Live Differences](#studio-vs-live-differences) — Comprehensive comparison
- [Common Mistakes](#common-mistakes) — WaitForChild, script timeout

---

## Memory Leaks

### Connection Circular References (Classic Gotcha)

One of the most common causes of server lag over time. If a connection's callback references the instance it's connected to, you create a circular reference the garbage collector can't clean up.

```luau
-- ❌ MEMORY LEAK: Part references itself through the connection
do
    local p = Instance.new("Part")
    p.Touched:Connect(function()
        print(p)  -- References 'p' → circular reference → never GC'd
    end)
end

-- ❌ STILL LEAKS: Indirect reference through a table
do
    local p = Instance.new("Part")
    local data = { Part = p, Message = "Test" }
    p.Touched:Connect(function()
        print(data.Message)  -- 'data' references 'p' → still leaks
    end)
end

-- ✅ OK: No reference to the part in the callback
do
    local p = Instance.new("Part")
    p.Touched:Connect(function()
        print("Touched")  -- No reference to 'p' → GC works
    end)
end

-- ✅ OK: Disconnect or Destroy breaks the cycle
do
    local p = Instance.new("Part")
    p.Touched:Connect(function() print(p) end)
    p:Destroy()  -- Breaks all connections on 'p'
end
```

For cleanup patterns, see `libraries.md` → Trove / Janitor. For custom signals, use GoodSignal (pure Lua, can't leak).

Source: [stravant's PSA on DevForum](https://devforum.roblox.com/t/psa-connections-can-memory-leak-instances/90082)

### PlayerAdded/CharacterAdded Nesting

A common pattern that doesn't leak (but confuses people):

```luau
-- ✅ This is actually fine
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        -- When player leaves, Player instance is destroyed
        -- → all connections on it are disconnected automatically
    end)
end)
```

When a Player leaves, Roblox destroys the Player instance, which disconnects all connections. **However**, if you store references to player data elsewhere, you need to clean those up on `PlayerRemoving`.

---

## DataStores

### Throttling from Frequent Saves

DataStores have rate limits. Saving on every value change will throttle:

```luau
-- ❌ WILL THROTTLE: Saving every coin pickup
coin.Touched:Connect(function()
    player.Coins.Value += 1
    DataStore:SetAsync(player.UserId, player.Coins.Value)  -- Too frequent!
end)

-- ✅ CORRECT: Save periodically + on leave
task.spawn(function()
    while true do
        task.wait(60)  -- Save every 60 seconds
        saveAllPlayers()
    end
end)

Players.PlayerRemoving:Connect(savePlayer)
game:BindToClose(saveAllPlayers)
```

### Use UpdateAsync for Concurrent Access

`SetAsync` can cause data loss if two servers write simultaneously. Use `UpdateAsync`:

```luau
-- ❌ Can lose data in edge cases
DataStore:SetAsync(key, newData)

-- ✅ Atomic update
DataStore:UpdateAsync(key, function(oldData)
    oldData = oldData or {}
    oldData.coins = (oldData.coins or 0) + 10
    return oldData
end)
```

**Better:** Use ProfileStore which handles all this for you.

---

## StreamingEnabled

When `StreamingEnabled` is true (Workspace property), instances may not exist on the client when scripts run. This is the #1 cause of "works in Studio, breaks in live."

```luau
-- ❌ May error if the part hasn't streamed in yet
local part = workspace.LevelAssets.Door

-- ✅ Wait for it to exist
local part = workspace:WaitForChild("LevelAssets"):WaitForChild("Door", 10)
if not part then
    warn("Door didn't stream in within 10 seconds")
    return
end
```

**Best approach:** Use CollectionService tags + `GetInstanceAddedSignal()` / `GetInstanceRemovedSignal()` to react to instances streaming in and out. See `luau-patterns.md` → CollectionService Tag Pattern.

Source: [Official streaming docs](https://create.roblox.com/docs/workspace/streaming)

---

## BindToClose Timeout

`game:BindToClose()` callbacks get **30 seconds** in live servers before the server force-shuts down. In Studio, there's no enforced timeout.

This means DataStore save logic that works fine in Studio (taking 45+ seconds) will silently fail in production.

```luau
game:BindToClose(function()
    -- You have 30 seconds max in production
    -- Design saves to complete well within this window
    saveAllPlayers()
end)
```

Source: [DataModel:BindToClose docs](https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose)

---

## Deferred Signal Behavior

Since ~February 2024, new Roblox places default to **Deferred** signal behavior (`Workspace.SignalBehavior`). Events fire at the end of the current resumption cycle, not immediately inline.

**What breaks:**
- Code that expects a value to be set immediately after firing a BindableEvent
- Calling `Play()`, `Stop()`, `Play()` on AnimationTracks in sequence (the middle `Stop()` may not register)
- Reading attribute values inside `GetAttributeChangedSignal` connections (may see the new value, not the old)

**Check your setting:** `Workspace.SignalBehavior` — existing places may still be `Immediate`.

Source: [Rollout announcement](https://devforum.roblox.com/t/deferred-engine-events-rollout-update/2723113)

---

## Studio vs Live Differences

Common "works in Studio, breaks in production" scenarios:

| Behavior | Studio | Live Server |
|----------|--------|-------------|
| Network latency | None in solo mode | Real latency — race conditions appear |
| `BindToClose` timeout | No enforced limit | 30 seconds |
| DataStore throttling | Relaxed | Enforced rate limits |
| `FilteringEnabled` | Always true | Always true (legacy, can't change) |
| StreamingEnabled | Often disabled in test places | Enabled in production for performance |
| Signal behavior | May be Immediate (older places) | Deferred for new places since Feb 2024 |

---

## Common Mistakes

### WaitForChild Infinite Yield

"Infinite yield possible" warnings mean the child doesn't exist (yet, or ever).

**Common causes even when you think the child exists:**
- **Case sensitivity:** `"myPart"` ≠ `"MyPart"`
- **Race condition:** Script runs before instance replicates
- **Wrong parent:** Looking in `Workspace` when it's in `ReplicatedStorage`

Always use a timeout to avoid hanging: `parent:WaitForChild("Name", 5)`. See `luau-conventions.md` → WaitForChild for usage patterns.

### "Script exhausted allowed execution time"

Long-running loops without yields:

```luau
-- ❌ Will timeout
while true do
    doExpensiveWork()
end

-- ✅ Yields to scheduler
while true do
    doExpensiveWork()
    task.wait()
end
```
