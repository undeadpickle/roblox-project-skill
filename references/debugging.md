# Debugging in Roblox

How to find and fix issues in your Roblox game.

## Studio Output Window

The Output window is your primary debugging tool. Open it via **View → Output** or press **F9**.

### Output Types

| Prefix | Meaning | Color |
|--------|---------|-------|
| (none) | `print()` output | White |
| ⚠️ | `warn()` output | Yellow |
| ❌ | `error()` or runtime error | Red |
| 🔵 | System messages (Roblox engine) | Blue |

### Filtering Output

Click the filter icons to show/hide:
- **🖥️ Server** — Server-side output
- **💻 Client** — Client-side output
- **⚙️ Command bar** — Manual command execution

---

## print, warn, error

### print()

Basic output. Use for general debugging:

```luau
print("Player joined:", player.Name)
print("Position:", part.Position)
print("Data:", data)  -- Tables print as "table: 0x..."
```

**Tip:** For tables, use a helper:

```luau
local HttpService = game:GetService("HttpService")

local function printTable(t)
    print(HttpService:JSONEncode(t))
end

printTable({ coins = 100, inventory = { "sword", "shield" } })
-- Output: {"coins":100,"inventory":["sword","shield"]}
```

### warn()

Yellow output for non-critical issues:

```luau
warn("Player data not found, using defaults")
warn("Deprecated function called from:", debug.traceback())
```

Use when something is wrong but the game can continue.

### error()

Red output that **stops script execution**:

```luau
error("Invalid argument: expected number, got " .. typeof(value))
```

For errors you want to catch:

```luau
local success, result = pcall(function()
    return riskyOperation()
end)

if not success then
    warn("Operation failed:", result)
end
```

---

## Reading Stack Traces

When an error occurs, Roblox shows a stack trace:

```
ServerScriptService.Server.modules.DataManager:45: attempt to index nil with 'Coins'
Stack:
  ServerScriptService.Server.modules.DataManager:45 function addCoins
  ServerScriptService.Server.init:23 function onPlayerAdded
  ServerScriptService.Server.init:31
```

**How to read it:**

1. **First line:** The error message and location (`DataManager:45` = line 45)
2. **Stack:** Call chain from most recent to oldest
   - `DataManager:45 function addCoins` — Error happened in `addCoins`
   - `init:23 function onPlayerAdded` — Called from `onPlayerAdded`
   - `init:31` — Which was called from line 31 (likely `Players.PlayerAdded:Connect`)

**Common error messages:**

| Error | Meaning |
|-------|---------|
| `attempt to index nil with 'X'` | Trying to access `.X` on a nil value |
| `attempt to call a nil value` | Function doesn't exist or is nil |
| `invalid argument #1 (expected X, got Y)` | Wrong type passed to function |
| `X is not a valid member of Y` | Instance property/child doesn't exist |

---

## Breakpoints (Studio Debugger)

### Setting Breakpoints

1. Open script in Studio
2. Click the gray margin left of a line number
3. A red dot appears — execution will pause here

### Debugger Controls

When paused at a breakpoint:

- **▶️ Continue (F5)** — Resume execution
- **⏭️ Step Over (F10)** — Execute current line, move to next
- **⬇️ Step Into (F11)** — Enter function call
- **⬆️ Step Out (Shift+F11)** — Exit current function

### Watch Window

View variable values while paused:

1. **View → Watch**
2. Add expressions like `player.Name`, `data.Coins`, `#items`
3. Values update as you step through code

### Call Stack Window

See the full call chain:

1. **View → Call Stack**
2. Click entries to jump to that location

---

## Common Debugging Patterns

### 1. Isolate the Problem

```luau
-- Comment out code to find what's breaking
function processData(data)
    print("1. Got data")
    local validated = validate(data)
    print("2. Validated")
    local transformed = transform(validated)
    print("3. Transformed")
    save(transformed)
    print("4. Saved")
end
```

If you see "2. Validated" but not "3. Transformed", the bug is in `transform()`.

### 2. Check for nil

Most errors come from nil values:

```luau
local player = Players:GetPlayerByUserId(userId)
print("Player:", player)  -- Check if nil

if not player then
    warn("Player not found for userId:", userId)
    return
end

local data = DataManager.getData(player)
print("Data:", data)  -- Check if nil

if not data then
    warn("Data not loaded for:", player.Name)
    return
end
```

### 3. Verify Instance Paths

```luau
local part = workspace:FindFirstChild("SpawnPoint")
print("SpawnPoint exists:", part ~= nil)

-- Or with full path debugging
local function findPath(path)
    local current = game
    for _, name in string.split(path, ".") do
        current = current:FindFirstChild(name)
        if not current then
            warn("Path broken at:", name)
            return nil
        end
    end
    return current
end

local result = findPath("Workspace.SpawnPoints.Spawn1")
```

### 4. Type Checking

```luau
local function safeProcess(value)
    print("Type:", typeof(value))

    if typeof(value) ~= "number" then
        warn("Expected number, got:", typeof(value), value)
        return
    end

    -- Process value...
end
```

### 5. Event Debugging

```luau
-- Check if event is firing
remote.OnServerEvent:Connect(function(player, ...)
    print("Remote fired by:", player.Name)
    print("Arguments:", ...)

    -- Rest of handler...
end)
```

---

## Remote Debugging

For client-server issues:

### Server Side

```luau
remote.OnServerEvent:Connect(function(player, action, data)
    print("[Server] Received from", player.Name, ":", action, data)

    -- Process...

    print("[Server] Responding...")
    remote:FireClient(player, "response", result)
end)
```

### Client Side

```luau
remote:FireServer("purchase", { itemId = "sword" })
print("[Client] Sent purchase request")

remote.OnClientEvent:Connect(function(action, data)
    print("[Client] Received:", action, data)
end)
```

---

## Performance Debugging

### MicroProfiler

Press **Ctrl+F6** in Studio to open the MicroProfiler. Shows:
- Frame time breakdown
- Script execution time
- Rendering performance

### Script Performance Stats

**View → Script Performance** shows:
- Which scripts use the most time
- How often they run
- Memory usage

### Memory Debugging

```luau
-- Check memory usage
print("Memory:", math.floor(gcinfo()) .. " KB")

-- Force garbage collection (debugging only)
collectgarbage("collect")
```

---

## Tips

1. **Add context to logs** — Include player names, IDs, state
2. **Use the Logger module** — Structured logging with prefixes
3. **Check both client and server** — Filter Output appropriately
4. **Reproduce consistently** — Find the exact steps to trigger the bug
5. **Binary search** — Comment out half the code, narrow down
6. **Check recent changes** — Git diff shows what you changed

---

## Quick Reference

```luau
-- Basic debugging
print("Value:", value)
print("Type:", typeof(value))
print("Exists:", instance ~= nil)
warn("Something wrong:", details)

-- Table debugging
local HttpService = game:GetService("HttpService")
print(HttpService:JSONEncode(myTable))

-- Stack trace
print(debug.traceback())

-- Safe access with fallback
local value = data and data.coins or 0
```
