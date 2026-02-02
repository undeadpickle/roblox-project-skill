# Trigger Systems

Patterns for proximity-based events, cooldowns, and interactive zones.

**Use cases:** Pickups, doors, checkpoints, cutscene triggers, damage zones, teleporters

---

## Basic Proximity Trigger

Fire events when players enter/exit zones.

```luau
-- Server: TriggerZone.luau
local Players = game:GetService("Players")

local TriggerZone = {}
TriggerZone.__index = TriggerZone

type TriggerCallbacks = {
    onEnter: ((Player) -> ())?,
    onExit: ((Player) -> ())?,
    onStay: ((Player, number) -> ())?, -- Player, time in zone
}

type TriggerConfig = {
    cooldown: number?,        -- Seconds before can trigger again
    requireLineOfSight: boolean?,
    maxActivations: number?,  -- Per player, nil = unlimited
    teamFilter: { string }?,  -- Only these teams can trigger
    debounce: number?,        -- Seconds between enter/exit
}

function TriggerZone.new(part: BasePart, callbacks: TriggerCallbacks, config: TriggerConfig?)
    local self = setmetatable({}, TriggerZone)

    self.part = part
    self.callbacks = callbacks
    self.config = config or {}

    self.playersInZone: { [Player]: { enterTime: number, activations: number } } = {}
    self.cooldowns: { [Player]: number } = {}

    self:init()
    return self
end

function TriggerZone:init()
    -- Track players entering
    self.part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then return end
        if self.playersInZone[player] then return end -- Already in zone

        if not self:canTrigger(player) then return end

        self.playersInZone[player] = {
            enterTime = os.clock(),
            activations = (self.playersInZone[player] and self.playersInZone[player].activations or 0) + 1,
        }

        self:setCooldown(player)

        if self.callbacks.onEnter then
            self.callbacks.onEnter(player)
        end
    end)

    -- Track players exiting
    self.part.TouchEnded:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then return end
        if not self.playersInZone[player] then return end

        -- Debounce exit (prevent rapid enter/exit)
        if self.config.debounce then
            local timeInZone = os.clock() - self.playersInZone[player].enterTime
            if timeInZone < self.config.debounce then
                return
            end
        end

        self.playersInZone[player] = nil

        if self.callbacks.onExit then
            self.callbacks.onExit(player)
        end
    end)

    -- "Stay" callback loop
    if self.callbacks.onStay then
        task.spawn(function()
            while true do
                task.wait(0.5)
                for player, data in self.playersInZone do
                    local timeInZone = os.clock() - data.enterTime
                    self.callbacks.onStay(player, timeInZone)
                end
            end
        end)
    end

    -- Cleanup on player leave
    Players.PlayerRemoving:Connect(function(player)
        self.playersInZone[player] = nil
        self.cooldowns[player] = nil
    end)
end

function TriggerZone:canTrigger(player: Player): boolean
    -- Check cooldown
    local cooldownEnd = self.cooldowns[player]
    if cooldownEnd and os.clock() < cooldownEnd then
        return false
    end

    -- Check max activations
    if self.config.maxActivations then
        local data = self.playersInZone[player]
        if data and data.activations >= self.config.maxActivations then
            return false
        end
    end

    -- Check team filter
    if self.config.teamFilter and player.Team then
        if not table.find(self.config.teamFilter, player.Team.Name) then
            return false
        end
    end

    return true
end

function TriggerZone:setCooldown(player: Player)
    if self.config.cooldown and self.config.cooldown > 0 then
        self.cooldowns[player] = os.clock() + self.config.cooldown
    end
end

function TriggerZone:isPlayerInZone(player: Player): boolean
    return self.playersInZone[player] ~= nil
end

function TriggerZone:getPlayersInZone(): { Player }
    local players = {}
    for player in self.playersInZone do
        table.insert(players, player)
    end
    return players
end

function TriggerZone:destroy()
    -- Cleanup if needed
    self.playersInZone = {}
    self.cooldowns = {}
end

return TriggerZone
```

### Usage

```luau
local TriggerZone = require(path.to.TriggerZone)

-- Damage zone
local damageZone = TriggerZone.new(workspace.LavaPool, {
    onEnter = function(player)
        print(player.Name, "entered lava!")
    end,
    onStay = function(player, timeInZone)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:TakeDamage(10) -- Damage every 0.5s
            end
        end
    end,
    onExit = function(player)
        print(player.Name, "escaped lava!")
    end,
})

-- Checkpoint (one-time per player)
local checkpoint = TriggerZone.new(workspace.Checkpoint1, {
    onEnter = function(player)
        setPlayerCheckpoint(player, "checkpoint1")
    end,
}, {
    maxActivations = 1,
})

-- Restricted area (team-based)
local vipArea = TriggerZone.new(workspace.VIPRoom, {
    onEnter = function(player)
        -- Only VIP team can enter (filtered by config)
    end,
}, {
    teamFilter = { "VIP" },
})
```

---

## Trigger Manager

Central system for managing many triggers.

```luau
-- Server: TriggerManager.luau
local Players = game:GetService("Players")

local TriggerManager = {}

type TriggerType = "event" | "checkpoint" | "teleport" | "damage" | "heal" | "pickup" | "custom"

type TriggerData = {
    part: BasePart,
    triggerType: TriggerType,
    data: { [string]: any },
    cooldown: number,
    oneTime: boolean,
}

local triggers: { [BasePart]: TriggerData } = {}
local playerCooldowns: { [Player]: { [BasePart]: number } } = {}
local playerActivations: { [Player]: { [BasePart]: boolean } } = {}

-- Callbacks by trigger type
local typeHandlers: { [TriggerType]: (Player, TriggerData) -> () } = {}

function TriggerManager.init()
    -- Scan for trigger parts (tagged or in folder)
    for _, trigger in workspace.Triggers:GetChildren() do
        if trigger:IsA("BasePart") then
            TriggerManager.register(trigger)
        end
    end

    -- Cleanup on player leave
    Players.PlayerRemoving:Connect(function(player)
        playerCooldowns[player] = nil
        playerActivations[player] = nil
    end)
end

function TriggerManager.register(part: BasePart)
    local triggerType = part:GetAttribute("TriggerType") or "custom"
    local cooldown = part:GetAttribute("Cooldown") or 0
    local oneTime = part:GetAttribute("OneTime") or false

    triggers[part] = {
        part = part,
        triggerType = triggerType,
        data = {
            -- Read any custom attributes
            target = part:GetAttribute("Target"),
            amount = part:GetAttribute("Amount"),
            eventId = part:GetAttribute("EventId"),
        },
        cooldown = cooldown,
        oneTime = oneTime,
    }

    part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            TriggerManager.onTrigger(player, part)
        end
    end)
end

function TriggerManager.registerHandler(triggerType: TriggerType, handler: (Player, TriggerData) -> ())
    typeHandlers[triggerType] = handler
end

function TriggerManager.onTrigger(player: Player, part: BasePart)
    local triggerData = triggers[part]
    if not triggerData then return end

    -- Check one-time
    if triggerData.oneTime then
        if not playerActivations[player] then
            playerActivations[player] = {}
        end
        if playerActivations[player][part] then
            return -- Already activated
        end
    end

    -- Check cooldown
    if triggerData.cooldown > 0 then
        if not playerCooldowns[player] then
            playerCooldowns[player] = {}
        end
        local cooldownEnd = playerCooldowns[player][part]
        if cooldownEnd and os.clock() < cooldownEnd then
            return -- On cooldown
        end
        playerCooldowns[player][part] = os.clock() + triggerData.cooldown
    end

    -- Mark as activated (for one-time triggers)
    if triggerData.oneTime then
        playerActivations[player][part] = true
    end

    -- Call type handler
    local handler = typeHandlers[triggerData.triggerType]
    if handler then
        handler(player, triggerData)
    end
end

return TriggerManager
```

### Default Handlers

```luau
-- Register default handlers
TriggerManager.registerHandler("checkpoint", function(player, data)
    setPlayerCheckpoint(player, data.data.eventId or data.part.Name)
    Remotes.CheckpointReached:FireClient(player)
end)

TriggerManager.registerHandler("teleport", function(player, data)
    local target = workspace:FindFirstChild(data.data.target)
    if target and player.Character then
        player.Character:PivotTo(target.CFrame)
    end
end)

TriggerManager.registerHandler("damage", function(player, data)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:TakeDamage(data.data.amount or 10)
        end
    end
end)

TriggerManager.registerHandler("heal", function(player, data)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (data.data.amount or 10))
        end
    end
end)

TriggerManager.registerHandler("event", function(player, data)
    Remotes.TriggerEvent:FireClient(player, data.data.eventId, data.data)
end)

TriggerManager.registerHandler("pickup", function(player, data)
    giveItem(player, data.data.itemId)
    data.part:Destroy() -- Remove pickup
end)
```

---

## Interactive Objects

Objects that require player input to activate.

```luau
-- Server: Interactable.luau
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Interactable = {}

type InteractConfig = {
    actionText: string?,
    objectText: string?,
    holdDuration: number?,
    maxDistance: number?,
    requiresKey: boolean?,
    keyCode: Enum.KeyCode?,
    cooldown: number?,
    oneTime: boolean?,
}

function Interactable.create(
    part: BasePart,
    onInteract: (Player) -> (),
    config: InteractConfig?
)
    config = config or {}

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = config.actionText or "Interact"
    prompt.ObjectText = config.objectText or ""
    prompt.HoldDuration = config.holdDuration or 0
    prompt.MaxActivationDistance = config.maxDistance or 10
    prompt.RequiresLineOfSight = true
    prompt.Parent = part

    if config.keyCode then
        prompt.KeyboardKeyCode = config.keyCode
    end

    local cooldowns: { [Player]: number } = {}
    local activated: { [Player]: boolean } = {}

    prompt.Triggered:Connect(function(player)
        -- Check one-time
        if config.oneTime and activated[player] then
            return
        end

        -- Check cooldown
        if config.cooldown and config.cooldown > 0 then
            local cooldownEnd = cooldowns[player]
            if cooldownEnd and os.clock() < cooldownEnd then
                return
            end
            cooldowns[player] = os.clock() + config.cooldown
        end

        if config.oneTime then
            activated[player] = true
        end

        onInteract(player)
    end)

    return prompt
end

-- Create a door that can be opened
function Interactable.door(doorPart: BasePart, openPosition: CFrame, closePosition: CFrame)
    local isOpen = false
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad)

    local prompt = Interactable.create(doorPart, function(player)
        isOpen = not isOpen
        local targetCFrame = isOpen and openPosition or closePosition

        tweenService:Create(doorPart, tweenInfo, {
            CFrame = targetCFrame,
        }):Play()

        prompt.ActionText = isOpen and "Close" or "Open"
    end, {
        actionText = "Open",
        holdDuration = 0,
    })

    return prompt
end

-- Create a button with cooldown
function Interactable.button(buttonPart: BasePart, onPress: (Player) -> (), cooldown: number?)
    return Interactable.create(buttonPart, onPress, {
        actionText = "Press",
        holdDuration = 0,
        cooldown = cooldown or 1,
    })
end

-- Create a hold-to-activate object
function Interactable.holdAction(part: BasePart, onComplete: (Player) -> (), duration: number)
    return Interactable.create(part, onComplete, {
        actionText = "Hold",
        holdDuration = duration,
    })
end

return Interactable
```

---

## Cooldown Manager

Reusable cooldown system for any action.

```luau
-- Shared: CooldownManager.luau
local CooldownManager = {}

type CooldownData = {
    endTime: number,
    duration: number,
}

local cooldowns: { [any]: { [string]: CooldownData } } = {}

-- Start a cooldown for an entity (player, NPC, etc.) and action
function CooldownManager.start(entity: any, action: string, duration: number)
    if not cooldowns[entity] then
        cooldowns[entity] = {}
    end

    cooldowns[entity][action] = {
        endTime = os.clock() + duration,
        duration = duration,
    }
end

-- Check if action is on cooldown
function CooldownManager.isOnCooldown(entity: any, action: string): boolean
    local entityCooldowns = cooldowns[entity]
    if not entityCooldowns then return false end

    local data = entityCooldowns[action]
    if not data then return false end

    return os.clock() < data.endTime
end

-- Get remaining cooldown time
function CooldownManager.getRemaining(entity: any, action: string): number
    local entityCooldowns = cooldowns[entity]
    if not entityCooldowns then return 0 end

    local data = entityCooldowns[action]
    if not data then return 0 end

    return math.max(0, data.endTime - os.clock())
end

-- Get cooldown progress (0 = just started, 1 = done)
function CooldownManager.getProgress(entity: any, action: string): number
    local entityCooldowns = cooldowns[entity]
    if not entityCooldowns then return 1 end

    local data = entityCooldowns[action]
    if not data then return 1 end

    local remaining = data.endTime - os.clock()
    if remaining <= 0 then return 1 end

    return 1 - (remaining / data.duration)
end

-- Clear a specific cooldown
function CooldownManager.clear(entity: any, action: string)
    local entityCooldowns = cooldowns[entity]
    if entityCooldowns then
        entityCooldowns[action] = nil
    end
end

-- Clear all cooldowns for an entity
function CooldownManager.clearAll(entity: any)
    cooldowns[entity] = nil
end

-- Attempt action (returns true if not on cooldown, starts cooldown)
function CooldownManager.try(entity: any, action: string, duration: number): boolean
    if CooldownManager.isOnCooldown(entity, action) then
        return false
    end

    CooldownManager.start(entity, action, duration)
    return true
end

return CooldownManager
```

### Usage

```luau
local CooldownManager = require(path.to.CooldownManager)

-- Ability usage
Remotes.UseAbility.OnServerEvent:Connect(function(player, abilityId)
    local ability = Abilities[abilityId]
    if not ability then return end

    if not CooldownManager.try(player, "ability_" .. abilityId, ability.cooldown) then
        -- Still on cooldown
        local remaining = CooldownManager.getRemaining(player, "ability_" .. abilityId)
        Remotes.CooldownFeedback:FireClient(player, abilityId, remaining)
        return
    end

    -- Use ability
    ability:activate(player)
end)

-- Interaction cooldown
if CooldownManager.try(player, "interact", 0.5) then
    -- Allow interaction
end
```

---

## Pitfalls

### ❌ Using Touched without debounce
**Problem:** Touched fires multiple times as character body parts enter.
**Fix:** Track which players are in zone, only fire once per enter.

### ❌ Not cleaning up on player leave
**Problem:** Memory leak from storing player data.
**Fix:** Always clean up cooldowns/activations in PlayerRemoving.

### ❌ Client-side trigger validation
**Problem:** Exploiter can trigger events they shouldn't.
**Fix:** All trigger logic on server. Client only shows UI feedback.

### ❌ No cooldown between enter/exit
**Problem:** Player can spam enter/exit by walking on edge.
**Fix:** Add debounce time (0.5-1s minimum between state changes).

### ❌ TouchEnded unreliability
**Problem:** TouchEnded doesn't fire if character dies or teleports.
**Fix:** Also check on character removal, periodic zone validation.
