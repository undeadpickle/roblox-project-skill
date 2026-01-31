# Known Gotchas

Common issues and their solutions, sourced from DevForum, GitHub issues, and community experience. Check here before debugging.

## Contents

- [Memory Leaks](#memory-leaks) — Connection circular references, PlayerAdded nesting
- [Rojo](#rojo) — Script Sync vs Rojo, `$ignoreUnknownInstances`, sync issues, Team Create conflicts
- [Wally](#wally) — Private flag, realm separation, dependency resolution
- [RemoteEvents / Security](#remoteevents--security) — Client validation, server-side checks
- [DataStores](#datastores) — Throttling, pcall usage, UpdateAsync
- [Type Checking / Luau LSP](#type-checking--luau-lsp) — New solver, strict mode, sourcemaps
- [MCP Servers](#mcp-servers) — NVM paths, port conflicts, plugin connection
- [Common Mistakes](#common-mistakes) — Instance.new parent, WaitForChild, deprecated APIs
- [Git](#git) — Place files, wally.lock, line endings
- [Studio / Roblox](#studio--roblox) — Script timeouts, FilteringEnabled

---

## Memory Leaks

### Connection Circular References (Classic Gotcha)

This is one of the most common causes of server lag over time. If a connection's callback references the instance it's connected to, you create a circular reference the garbage collector can't clean up.

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

-- ✅ OK: Disconnect breaks the cycle
do
    local p = Instance.new("Part")
    local conn = p.Touched:Connect(function() print(p) end)
    conn:Disconnect()  -- Breaks the cycle
end

-- ✅ OK: Destroy() disconnects all connections
do
    local p = Instance.new("Part")
    p.Touched:Connect(function() print(p) end)
    p:Destroy()  -- Breaks all connections on 'p'
end
```

**Solutions:**
- **Always `:Destroy()` instances you're done with.** Destroy is recursive—destroying a parent destroys children.
- Use cleanup patterns like **Trove** or **Janitor** to track connections.
- For custom Signal classes, use **GoodSignal** (pure Lua, no BindableEvent, can't leak).

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

## Rojo

### Studio Script Sync vs Rojo

Roblox released **Studio Script Sync** (beta, Nov 2025) which syncs scripts to local files without Rojo. Should you switch?

| Use Case | Recommendation |
|----------|----------------|
| Solo dev, simple project, staying in Studio | Script Sync may work |
| Team project, Git workflow, CI/CD | **Rojo** (more mature, full ecosystem) |
| External tooling (Selene, StyLua, Wally) | **Rojo** (Script Sync doesn't integrate) |
| Full project structure control | **Rojo** (Script Sync is script-only) |

**Bottom line:** Script Sync is promising but still beta with limitations. Rojo remains the production-grade choice for serious projects. This skill defaults to Rojo.

### Rojo Deletes Studio-Created Assets (`$ignoreUnknownInstances`)

> **What is `$ignoreUnknownInstances`?**
> A Rojo setting that tells it to leave Studio-created objects alone. Without it, Rojo deletes anything it doesn't recognize in the filesystem—including your hand-placed models and particles.

By default, Rojo deletes any instances in Studio that don't exist in your filesystem. This means particles, models, sounds, and other Studio-created assets disappear on sync.

```json
// ❌ DEFAULT BEHAVIOR: Studio assets get deleted
"Workspace": {
  "$properties": { "FilteringEnabled": true }
}

// ✅ RECOMMENDED: Preserve Studio-created instances
"Workspace": {
  "$properties": { "FilteringEnabled": true },
  "$ignoreUnknownInstances": true
}
```

**Best practice:** Add `"$ignoreUnknownInstances": true` to every service in your project.json. This enables a "hybrid workflow" where Rojo manages code and Studio manages assets.

Services that commonly need it: `Workspace`, `ServerStorage`, `StarterGui`, `Lighting`, `SoundService`, `ReplicatedStorage`, `StarterPlayer`.

Source: [GitHub issue #716](https://github.com/rojo-rbx/rojo/issues/716)

### Don't use `$schema` in project.json

Current Rojo versions throw parse errors if you include a `$schema` field.

```json
// ❌ Causes parse error
{
  "$schema": "...",
  "name": "MyGame"
}

// ✅ Works
{
  "name": "MyGame"
}
```

### Scripts Not Syncing After Edits

Most common Rojo complaint. Checklist:

1. **Is the Rojo plugin actually connected?** The icon should be green/active.
2. **Did you restart Studio without reconnecting?** Rojo doesn't auto-reconnect.
3. **Multiple Rojo plugins installed?** Remove duplicates from Studio plugins folder.
4. **File saved?** Rojo syncs on file save, not on every keystroke.
5. **Check port conflicts:** `lsof -i :34872` (default Rojo port)

### Two-Way Sync Crashes ("Access Denied")

> **What is two-way sync?**
> Normally, Rojo syncs one direction: files → Studio. Two-way sync is an experimental feature that also syncs Studio → files, so changes you make in Studio appear in your code files. It's useful but can be unstable.

Two-way sync (experimental) can crash with permission errors:

```
[ERROR rojo] Details: called `Result::unwrap()` on an `Err` value: 
Os { code: 5, kind: PermissionDenied, message: "Access is denied." }
```

**Causes:**
- Project on OneDrive/Dropbox with sync conflicts
- Files on external/SD drives with permission issues
- Antivirus blocking file writes

**Fix:** Move project to a local, non-synced folder. Or disable two-way sync.

### macOS: Paths with `../` Ancestors Don't Trigger Sync

Known bug: If your project.json references paths above the project root (like `../../shared/`), changes in those folders won't trigger sync on macOS.

**Workaround:** Keep all source files inside the project directory, or manually reconnect when editing shared files.

### MeshPart/UnionOperation Not Syncing Properly

After a Roblox update, `Instance.new("MeshPart")` succeeds but creates an empty mesh. Rojo can't set `MeshContent` after creation.

**Workaround:** Keep complex MeshParts in a separate `.rbxm` file and use `$path` to reference it, or create them manually in Studio.

### Team Create Confusion

Rojo syncs on file save—it doesn't integrate with Team Create's commit workflow. If your team uses both:

- Rojo changes bypass Team Create and apply immediately
- This can cause conflicts if someone is editing in Studio without Rojo

**Recommendation:** Pick one workflow. For code: Rojo + Git. For level design: Team Create.

### Sync Issues Checklist (Comprehensive)

If Rojo isn't syncing properly:

1. **Is Rojo plugin installed AND connected in Studio?** Check the Rojo toolbar button.
2. **Do project.json paths match actual file structure?** Typos in `$path` are common.
3. **Naming conflicts?** Studio instance names vs filesystem names must align.
4. **init.luau vs .src.luau?** Pick one convention. `init.luau` inside a folder = ModuleScript with folder name.
5. **Rojo version mismatch?** CLI and plugin versions should match. Run `rojo --version` and check plugin.
6. **Multiple plugins?** Remove duplicates from Roblox plugins folder.
7. **Port in use?** Check `lsof -i :34872` and kill any conflicting processes.

---

## Wally

### Add `private = true`

Prevents accidental publishing to the Wally registry:

```toml
[package]
name = "username/project-name"
version = "0.1.0"
private = true
```

### "Resolved 0 Dependencies"

If `wally install` outputs "Resolved 0 dependencies" but you have packages listed:

1. **Check section names:** It's `[dependencies]`, not `[dependancies]` or `[dependency]`
2. **Packages must be under correct section:**
```toml
# ❌ Wrong - packages outside sections
Promise = "evaera/promise@4"

# ✅ Correct
[dependencies]
Promise = "evaera/promise@4"
```

### Packages Installing "Outside DataModel"

Wally creates a `Packages/` folder on disk. If you see packages in the Explorer but they're grayed out or "outside" the DataModel, your `default.project.json` doesn't reference them:

```json
"ReplicatedStorage": {
  "Packages": {
    "$path": "Packages"
  }
}
```

### Shared Dependency Missing from ServerPackages

Bug: When a server-only package depends on a shared package, Wally may install the shared package only in `ServerPackages/`, but the link still looks for it in `Packages/`.

**Workaround:** Add the shared dependency explicitly to your `[dependencies]` section:

```toml
[dependencies]
Promise = "evaera/promise@4"  # Explicitly add shared deps

[server-dependencies]
ProfileStore = "loleris/profilestore@1"  # Uses Promise internally
```

### Realm Separation

| Realm | Use For |
|-------|---------|
| `[dependencies]` | Shared code (client + server access) |
| `[server-dependencies]` | Server-only (ProfileStore, data libs) |
| `[dev-dependencies]` | Testing tools, not shipped |

### "Package not found" errors

1. Check spelling and case (Wally is case-sensitive)
2. Verify package exists on [wally.run](https://wally.run)
3. Try clearing cache: `rm -rf ~/.wally && wally install`

---

## RemoteEvents / Security

### Never Trust the Client

Everything from the client can be spoofed. Exploiters can:
- Fire any RemoteEvent with any arguments
- Modify LocalScripts
- See and intercept all client-side code

```luau
-- ❌ INSECURE: Trusting client-provided damage value
DealDamage.OnServerEvent:Connect(function(player, target, damage)
    target.Humanoid:TakeDamage(damage)  -- Exploiter sends damage = 9999999
end)

-- ✅ SECURE: Server calculates damage
DealDamage.OnServerEvent:Connect(function(player, target)
    -- Validate target exists and is hittable
    if not target or not target:FindFirstChild("Humanoid") then return end
    
    -- Server decides damage based on player's weapon
    local weapon = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not weapon then return end
    
    local damage = weapon:GetAttribute("Damage") or 10
    target.Humanoid:TakeDamage(damage)
end)
```

### Validate EVERYTHING Server-Side

```luau
Remote.OnServerEvent:Connect(function(player, ...)
    local args = {...}
    
    -- 1. Validate argument types
    if typeof(args[1]) ~= "string" then return end
    if typeof(args[2]) ~= "number" then return end
    
    -- 2. Validate argument values (sanity checks)
    if args[2] < 0 or args[2] > 1000 then return end
    
    -- 3. Validate player can perform action
    if not canPlayerDoThis(player) then return end
    
    -- 4. Rate limit
    if isRateLimited(player) then return end
    
    -- Now safe to proceed
end)
```

### Don't Use "Secret Keys" for Security

Exploiters can see any LocalScript code. "Secret keys" sent from client are useless:

```luau
-- ❌ USELESS: Exploiter can read the key from LocalScript
local SECRET_KEY = "super_secret_123"
Remote:FireServer(SECRET_KEY, data)

-- Server checks if key == "super_secret_123"
-- Exploiter just sends the same key
```

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

### Always Use pcall

DataStore calls can fail. Always wrap in pcall:

```luau
-- ❌ Can error and break your script
local data = DataStore:GetAsync(key)

-- ✅ Handle failures
local success, data = pcall(function()
    return DataStore:GetAsync(key)
end)

if success then
    -- Use data
else
    warn("DataStore failed:", data)
    -- Handle failure (retry, use defaults, etc.)
end
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

## Type Checking / Luau LSP

### Deprecated: `luau-lsp.types.roblox`

The old setting `luau-lsp.types.roblox: true` shows a deprecation warning. Use the new setting:

```json
// ❌ Deprecated
{
  "luau-lsp.types.roblox": true
}

// ✅ Current
{
  "luau-lsp.platform.type": "roblox"
}
```

### New Type Solver (Default as of Nov 2025)

Roblox's new type solver is now **out of beta and enabled by default**. Some patterns that worked before may show warnings:
- `__call` metamethods may cause "Cannot call non-function" warnings
- `coroutine.wrap` iterators may show "next() does not return enough values"
- Some generic type inference behaves differently

**Workarounds:**
- Use `:: any` type assertions for problematic patterns
- Toggle solver in Studio: File → Studio Settings → Script Analysis → Type Check Mode
- The new solver is stricter but catches more real bugs — worth adapting to

### Project-level strict vs per-file strict

Two common patterns:

**Pattern A: Global strict (recommended for new projects)**
```json
// .luaurc
{
  "languageMode": "strict"
}
```

**Pattern B: Opt-in strict (for existing projects)**
```json
// .luaurc
{
  "languageMode": "nonstrict"
}
```
Then add `--!strict` to files that benefit from it.

### Luau LSP not showing DataModel types

Enable sourcemap generation in VS Code settings:

```json
{
  "luau-lsp.sourcemap.enabled": true,
  "luau-lsp.sourcemap.rojoProjectFile": "default.project.json"
}
```

### "Unknown require" warnings

Ensure `.luaurc` has aliases matching your project:

```json
{
  "aliases": {
    "Packages": "Packages"
  }
}
```

---

## MCP Servers

### NVM users: "npx not found"

Claude Code doesn't load your shell profile, so NVM's npx isn't in PATH.

**Fix:** Use the full path to npx:

```bash
which npx  # Find your path
# Use full path in MCP config
```

### Port conflicts

```bash
lsof -i :3003           # Find what's using port
lsof -ti :3003 | xargs kill  # Kill it
```

### Plugin stuck on "Retrying"

1. Restart VS Code (restarts MCP server)
2. In Studio, click the MCP plugin → Reconnect
3. Check Studio Output for errors

---

## Common Mistakes

### Instance.new Parent Argument (Deprecated)

The second argument to `Instance.new` is deprecated for performance reasons:

```luau
-- ❌ DEPRECATED: Causes extra replication overhead
local part = Instance.new("Part", workspace)
part.Size = Vector3.new(10, 10, 10)
part.Anchored = true

-- ❌ STILL BAD: Setting Parent before properties
local part = Instance.new("Part")
part.Parent = workspace  -- Parent set too early!
part.Size = Vector3.new(10, 10, 10)
part.Anchored = true

-- ✅ CORRECT: Set all properties, THEN parent
local part = Instance.new("Part")
part.Size = Vector3.new(10, 10, 10)
part.Anchored = true
part.Parent = workspace  -- Parent last!
```

**Why:** When you set Parent, the instance replicates. Each subsequent property change sends another network packet. Setting properties first = one packet with everything.

### WaitForChild Infinite Yield

"Infinite yield possible" warnings mean the child doesn't exist (yet, or ever):

```luau
-- ❌ Will warn/hang if "MissingChild" doesn't exist
local child = parent:WaitForChild("MissingChild")

-- ✅ Use timeout to avoid infinite wait
local child = parent:WaitForChild("MissingChild", 5)  -- 5 second timeout
if not child then
    warn("MissingChild not found after 5 seconds")
    return
end

-- ✅ Or check if it exists first
local child = parent:FindFirstChild("MissingChild")
if child then
    -- Use child
end
```

**Common causes of "infinite yield" even when child exists:**
- **Case sensitivity:** `"myPart"` ≠ `"MyPart"`
- **Race condition:** Script runs before instance replicates
- **Wrong parent:** Looking in `Workspace` when it's in `ReplicatedStorage`

### Using Deprecated APIs

| Deprecated | Use Instead |
|------------|-------------|
| `wait()` | `task.wait()` |
| `spawn()` | `task.spawn()` |
| `delay()` | `task.delay()` |
| `Instance.new("Part", parent)` | Set `.Parent` last |

**Why task library is better:**
- More precise timing (doesn't throttle under load like `wait()`)
- Clearer semantics
- Better performance

### Editing files in Packages/

`Packages/` is auto-generated by Wally. Your changes will be overwritten on next `wally install`.

If you need to modify a package, fork it and point to your fork in `wally.toml`.

### Requiring packages before Wally install

```luau
-- ❌ Fails if Packages/ doesn't exist yet
local Promise = require(ReplicatedStorage.Packages.Promise)
```

Run `wally install` first, then connect Rojo.

---

## Git

### Large place files

Don't commit `.rbxl` files to git—they're large binaries:

```gitignore
*.rbxl
*.rbxlx
```

### wally.lock: commit or not?

**Commit it.** Ensures everyone on the team gets the same package versions.

### Line ending issues (Windows)

Use `.gitattributes` to enforce LF endings:

```
* text=auto
*.luau text eol=lf
*.lua text eol=lf
```

---

## Studio / Roblox

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

### FilteringEnabled warning

`FilteringEnabled` is always true now (legacy property). You can remove it from project.json.
