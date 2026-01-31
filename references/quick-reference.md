# Quick Reference

Single-page cheat sheet for common Luau/Roblox patterns.

---

## Service Imports

```luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TextService = game:GetService("TextService")
local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ContextActionService = game:GetService("ContextActionService")
```

---

## Task Library (Use These, Not Legacy)

```luau
-- Wait
task.wait(1)           -- Wait 1 second (precise)
-- NOT: wait(1)

-- Spawn (run in parallel)
task.spawn(function()
    -- Runs immediately in new thread
end)
-- NOT: spawn(fn)

-- Delay
task.delay(2, function()
    -- Runs after 2 seconds
end)
-- NOT: delay(2, fn)

-- Defer (runs next frame)
task.defer(function()
    -- Runs next resumption cycle
end)

-- Cancel a thread
local thread = task.spawn(function()
    while true do task.wait(1) end
end)
task.cancel(thread)
```

---

## Type Assertions

```luau
-- Basic cast
local part = workspace:FindFirstChild("MyPart") :: Part

-- Nullable cast
local maybePart = workspace:FindFirstChild("MyPart") :: Part?

-- After WaitForChild (always returns something)
local gui = player.PlayerGui:WaitForChild("MainGui") :: ScreenGui

-- Function parameter/return types
function calculate(a: number, b: number): number
    return a + b
end

-- Table types
local scores: { [string]: number } = {}
local items: { string } = {}

-- Type alias
type PlayerData = {
    coins: number,
    inventory: { string },
}
```

---

## Remote Event Validation

```luau
-- Server: Always validate client input
Remote.OnServerEvent:Connect(function(player: Player, ...: unknown)
    local args = { ... }

    -- 1. Type check
    if typeof(args[1]) ~= "string" then
        warn("Invalid type from", player.Name)
        return
    end
    local action: string = args[1]

    -- 2. Value check
    if action ~= "buy" and action ~= "sell" then
        warn("Invalid action from", player.Name)
        return
    end

    -- 3. Numeric bounds
    if typeof(args[2]) ~= "number" then return end
    local amount: number = args[2]
    if amount < 1 or amount > 100 or amount ~= math.floor(amount) then
        return
    end

    -- 4. Player can perform action
    if not canPlayerAct(player) then return end

    -- Now safe to process
    processAction(player, action, amount)
end)
```

---

## Remote Function Pattern

RemoteFunctions return values to the client. Use for request-response patterns.

```luau
-- Server: Return data to client
local GetInventory = Remotes.getFunction("GetInventory")

GetInventory.OnServerInvoke = function(player: Player): { string }?
    local data = DataManager.getData(player)
    if not data then
        return nil
    end
    return data.Inventory
end

-- Client: Request data from server
local GetInventory = Remotes.getFunction("GetInventory")

local inventory = GetInventory:InvokeServer()
if inventory then
    for _, item in inventory do
        print("Has item:", item)
    end
end
```

**When to use which:**
- **RemoteEvent**: Fire-and-forget (damage dealt, sound played, UI update)
- **RemoteFunction**: Need a response (get data, validate purchase, check permission)

**Warning:** RemoteFunctions can yield indefinitely if server doesn't respond. Consider timeouts:

```luau
local Promise = require(Packages.Promise)

local function invokeWithTimeout(remote: RemoteFunction, timeout: number, ...: any)
    return Promise.race({
        Promise.new(function(resolve)
            resolve(remote:InvokeServer(...))
        end),
        Promise.delay(timeout):andThen(function()
            return Promise.reject("Request timed out")
        end),
    })
end

-- Usage
invokeWithTimeout(GetInventory, 5)
    :andThen(function(inventory)
        print("Got inventory:", inventory)
    end)
    :catch(function(err)
        warn("Failed:", err)
    end)
```

---

## Rate Limiting Remotes

Protect your RemoteEvents from exploit spam using the RateLimiter module.

```luau
local RateLimiter = require(ServerModules.RateLimiter)

-- Create limiters for different actions
local attackLimiter = RateLimiter.new({
    rate = 5,       -- 5 attacks per second max
    capacity = 8,   -- Allow short bursts of 8
})

local chatLimiter = RateLimiter.new({
    rate = 2,       -- 2 messages per second
    capacity = 5,   -- Burst of 5 messages
})

-- Use in RemoteEvent handlers
AttackRemote.OnServerEvent:Connect(function(player, ...)
    if not attackLimiter:check(player) then
        -- Player is spamming - silently ignore or warn
        return
    end

    -- Process legitimate attack
    processAttack(player, ...)
end)
```

**Recommended limits by action type:**

| Action | Rate | Capacity | Notes |
|--------|------|----------|-------|
| Combat/attacks | 5-10/s | 10-15 | Match animation speed |
| UI interactions | 10/s | 20 | Clicks, hovers |
| Chat messages | 2/s | 5 | Prevent spam |
| Data requests | 1/s | 3 | GetInventory, GetStats |
| Purchases | 0.5/s | 2 | Slow, important actions |

---

## Instance Patterns

```luau
-- Create instance (set properties BEFORE parent)
local part = Instance.new("Part")
part.Size = Vector3.new(4, 1, 4)
part.Anchored = true
part.Parent = workspace  -- Parent LAST

-- Safe child access
local child = parent:FindFirstChild("Name")
if child then
    -- Use child
end

-- Wait with timeout
local child = parent:WaitForChild("Name", 5)  -- 5 second timeout
if not child then
    warn("Child not found after 5 seconds")
    return
end

-- Find by class
local humanoid = character:FindFirstChildOfClass("Humanoid")

-- Find in descendants
local part = model:FindFirstChild("Target", true)  -- recursive

-- Get all of type
for _, part in workspace:GetDescendants() do
    if part:IsA("Part") then
        -- Process part
    end
end
```

---

## Connection Management

```luau
-- Track connections for cleanup
local connections: { RBXScriptConnection } = {}

table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
table.insert(connections, RunService.Heartbeat:Connect(onHeartbeat))

-- Cleanup function
local function cleanup()
    for _, conn in connections do
        conn:Disconnect()
    end
    table.clear(connections)
end

-- Or use Trove
local Trove = require(Packages.Trove)
local trove = Trove.new()

trove:Connect(Players.PlayerAdded, onPlayerAdded)
trove:Add(part)  -- Will destroy

-- Later
trove:Destroy()  -- Cleans everything
```

---

## Iteration

```luau
-- Arrays (use generalized iteration)
for index, value in myArray do
    print(index, value)
end
-- NOT: for i, v in ipairs(myArray)

-- Dictionaries
for key, value in myDict do
    print(key, value)
end
-- NOT: for k, v in pairs(myDict)

-- Instances
for _, child in parent:GetChildren() do
    print(child.Name)
end

-- Numeric range
for i = 1, 10 do
    print(i)
end

-- Numeric range with step
for i = 10, 1, -1 do  -- Countdown
    print(i)
end
```

---

## Common Gotchas Reminders

```luau
-- 1. Luau arrays are 1-indexed
local arr = { "a", "b", "c" }
print(arr[1])  -- "a", NOT arr[0]

-- 2. Not equal is ~=, not !=
if value ~= nil then end

-- 3. No ternary operator - use if-then-else expression
local result = if condition then valueA else valueB

-- 4. String concatenation is ..
local msg = "Hello " .. name .. "!"

-- 5. Length operator is #
local count = #myArray

-- 6. Boolean coercion: only false and nil are falsy
if 0 then print("0 is truthy!") end
if "" then print("empty string is truthy!") end

-- 7. Tables are references
local a = { x = 1 }
local b = a
b.x = 2
print(a.x)  -- 2 (same table!)

-- 8. No undefined, only nil
local x
print(x)  -- nil
```

---

## Async Patterns

```luau
-- Promise (with evaera/promise)
local Promise = require(Packages.Promise)

DataManager.loadDataAsync(player)
    :andThen(function(data)
        print("Got data:", data)
        return process(data)
    end)
    :andThen(function(result)
        print("Processed:", result)
    end)
    :catch(function(err)
        warn("Error:", err)
    end)

-- pcall for error handling
local success, result = pcall(function()
    return riskyOperation()
end)

if success then
    print("Result:", result)
else
    warn("Failed:", result)
end

-- xpcall with stack trace
local success, result = xpcall(function()
    return riskyOperation()
end, function(err)
    return debug.traceback(err)
end)
```

---

## Tween Animation

```luau
local TweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(
    1,                          -- Duration
    Enum.EasingStyle.Quad,      -- Style
    Enum.EasingDirection.Out,   -- Direction
    0,                          -- Repeat count (0 = no repeat)
    false,                      -- Reverses
    0                           -- Delay
)

local tween = TweenService:Create(part, tweenInfo, {
    Position = Vector3.new(0, 10, 0),
    Transparency = 0.5,
})

tween:Play()

-- Wait for completion
tween.Completed:Wait()
```

---

## Module Pattern

```luau
--!strict

local MyModule = {}

-- Types
export type Config = {
    enabled: boolean,
    value: number,
}

-- Constants
local DEFAULT_VALUE = 100

-- Public functions
function MyModule.doSomething(config: Config): boolean
    if not config.enabled then
        return false
    end
    -- Implementation
    return true
end

-- Private function (not exported)
local function helperFunction()
    -- Internal use only
end

return MyModule
```

---

## Signals (GoodSignal)

```luau
local GoodSignal = require(Packages.GoodSignal)

-- Create
local OnDamaged = GoodSignal.new()

-- Connect
local connection = OnDamaged:Connect(function(amount, source)
    print("Took", amount, "damage from", source)
end)

-- Fire
OnDamaged:Fire(25, "Enemy")

-- Once (auto-disconnects)
OnDamaged:Once(function(amount)
    print("First damage:", amount)
end)

-- Wait (yields)
local amount = OnDamaged:Wait()

-- Disconnect
connection:Disconnect()

-- Destroy signal
OnDamaged:Destroy()
```
