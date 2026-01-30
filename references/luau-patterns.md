# Luau Code Patterns

## Remote Event Validation (Server)

Always validate untrusted client data:

```luau
MyEvent.OnServerEvent:Connect(function(player: Player, data: unknown)
    -- Type check
    if typeof(data) ~= "string" then
        return
    end
    
    -- Now safe to use as string
    local validData: string = data
end)
```

For complex data:

```luau
type ActionData = {
    action: string,
    targetId: number,
}

local function validateActionData(data: unknown): ActionData?
    if typeof(data) ~= "table" then return nil end
    
    local t = data :: {[string]: unknown}
    if typeof(t.action) ~= "string" then return nil end
    if typeof(t.targetId) ~= "number" then return nil end
    
    return t :: ActionData
end

MyEvent.OnServerEvent:Connect(function(player: Player, data: unknown)
    local validated = validateActionData(data)
    if not validated then return end
    
    -- Safe to use validated.action and validated.targetId
end)
```

## Model Animation (CFrameValue + PivotTo)

TweenService can't directly tween `model:PivotTo()`. Use CFrameValue as intermediary:

```luau
local TweenService = game:GetService("TweenService")

local function tweenModel(model: Model, targetCFrame: CFrame, duration: number): ()
    local cfValue = Instance.new("CFrameValue")
    cfValue.Value = model:GetPivot()
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(cfValue, tweenInfo, { Value = targetCFrame })
    
    local connection = cfValue.Changed:Connect(function(newCFrame)
        model:PivotTo(newCFrame)
    end)
    
    tween.Completed:Once(function()
        connection:Disconnect()
        cfValue:Destroy()
    end)
    
    tween:Play()
end
```

## Error Handling Pattern

Return success/result tuple instead of throwing:

```luau
local function loadData(key: string): (boolean, string)
    local success, result = pcall(function()
        return DataStore:GetAsync(key)
    end)
    
    if not success then
        return false, `DataStore error: {result}`
    end
    
    if result == nil then
        return false, "No data found"
    end
    
    return true, result
end

-- Usage
local success, data = loadData("player_123")
if not success then
    warn("Failed:", data)
    return
end
-- Use data safely
```

## Safe Instance Access

```luau
-- FindFirstChild with type cast
local part = workspace:FindFirstChild("SpawnPoint") :: Part?
if not part then
    warn("SpawnPoint not found")
    return
end

-- WaitForChild with timeout
local gui = player.PlayerGui:WaitForChild("MainGui", 5) :: ScreenGui?
if not gui then
    warn("MainGui did not load in time")
    return
end
```

## Connection Management

```luau
local connections: {RBXScriptConnection} = {}

local function setupConnections(): ()
    table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
    table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))
end

local function cleanup(): ()
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
end
```

## Debounce Pattern

```luau
local debounces: {[Player]: boolean} = {}

local function onTouched(player: Player): ()
    if debounces[player] then return end
    debounces[player] = true
    
    -- Do action
    print("Touched by", player.Name)
    
    task.delay(1, function()
        debounces[player] = nil
    end)
end
```

## Attribute-Based Behavior (Registry Pattern)

Use string attributes on instances to drive behavior:

```luau
-- In GameConfig
local INTERACTION_TYPES = {
    button = { sound = "Click", cooldown = 0.5 },
    portal = { sound = "Whoosh", destination = "Spawn" },
    pickup = { sound = "Grab", destroyOnUse = true },
}

-- In interaction handler
local function handleInteraction(part: BasePart, player: Player): ()
    local interactionType = part:GetAttribute("InteractionType")
    if typeof(interactionType) ~= "string" then return end
    
    local config = INTERACTION_TYPES[interactionType]
    if not config then return end
    
    -- Use config to drive behavior
end
```

## Promise-like Pattern (Without External Library)

```luau
type Callback<T> = (T) -> ()

local function asyncOperation<T>(
    operation: () -> T,
    onSuccess: Callback<T>,
    onError: Callback<string>
): ()
    task.spawn(function()
        local success, result = pcall(operation)
        if success then
            onSuccess(result)
        else
            onError(tostring(result))
        end
    end)
end
```
