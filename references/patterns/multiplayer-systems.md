# Multiplayer Systems

Patterns for spectating, reviving, event synchronization, and team coordination.

**Use cases:** Round-based games, co-op survival, battle royale, team games, horror multiplayer

---

## Spectate System

Allow dead/eliminated players to watch living teammates.

```luau
-- Client: SpectateController.luau
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SpectateController = {}

local isSpectating = false
local spectateIndex = 1
local spectateTargets: { Player } = {}
local inputConnection: RBXScriptConnection?

-- Configuration
local config = {
    prevKey = Enum.KeyCode.Q,
    nextKey = Enum.KeyCode.E,
    exitKey = Enum.KeyCode.Escape,
    autoSwitchOnDeath = true,
    showUI = true,
}

-- Callbacks for UI updates
local onSpectateStart: ((Player) -> ())?
local onSpectateEnd: (() -> ())?
local onTargetChange: ((Player) -> ())?

function SpectateController.configure(newConfig: { [string]: any })
    for key, value in newConfig do
        config[key] = value
    end
end

function SpectateController.setCallbacks(callbacks: {
    onStart: ((Player) -> ())?,
    onEnd: (() -> ())?,
    onChange: ((Player) -> ())?,
})
    onSpectateStart = callbacks.onStart
    onSpectateEnd = callbacks.onEnd
    onTargetChange = callbacks.onChange
end

function SpectateController.start(validTargets: { Player }?)
    if isSpectating then return end

    isSpectating = true
    spectateTargets = validTargets or getAliveTeammates()
    spectateIndex = 1

    if #spectateTargets > 0 then
        spectatePlayer(spectateTargets[1])
    end

    -- Listen for input
    inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        if input.KeyCode == config.prevKey then
            switchTarget(-1)
        elseif input.KeyCode == config.nextKey then
            switchTarget(1)
        elseif input.KeyCode == config.exitKey then
            SpectateController.stop()
        end
    end)

    if onSpectateStart and #spectateTargets > 0 then
        onSpectateStart(spectateTargets[1])
    end
end

function SpectateController.stop()
    if not isSpectating then return end

    isSpectating = false

    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end

    -- Reset camera
    local camera = Workspace.CurrentCamera
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character

    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
    end

    if onSpectateEnd then
        onSpectateEnd()
    end
end

function SpectateController.updateTargets(newTargets: { Player })
    spectateTargets = newTargets

    if isSpectating and #spectateTargets == 0 then
        -- No one left to spectate
        if onSpectateEnd then
            onSpectateEnd()
        end
        return
    end

    -- If current target is no longer valid, switch
    local currentTarget = spectateTargets[spectateIndex]
    if not currentTarget or not table.find(spectateTargets, currentTarget) then
        spectateIndex = math.min(spectateIndex, #spectateTargets)
        if spectateTargets[spectateIndex] then
            spectatePlayer(spectateTargets[spectateIndex])
        end
    end
end

function SpectateController.isSpectating(): boolean
    return isSpectating
end

function SpectateController.getCurrentTarget(): Player?
    if isSpectating and spectateTargets[spectateIndex] then
        return spectateTargets[spectateIndex]
    end
    return nil
end

local function spectatePlayer(player: Player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid

    if onTargetChange then
        onTargetChange(player)
    end
end

local function switchTarget(direction: number)
    if #spectateTargets == 0 then return end

    spectateIndex = ((spectateIndex - 1 + direction) % #spectateTargets) + 1
    spectatePlayer(spectateTargets[spectateIndex])
end

local function getAliveTeammates(): { Player }
    local teammates = {}
    local localPlayer = Players.LocalPlayer

    for _, player in Players:GetPlayers() do
        if player ~= localPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    table.insert(teammates, player)
                end
            end
        end
    end

    return teammates
end

return SpectateController
```

### Usage

```luau
-- When local player dies
SpectateController.setCallbacks({
    onStart = function(player)
        SpectateUI:Show(player.Name)
    end,
    onChange = function(player)
        SpectateUI:UpdateTarget(player.Name)
    end,
    onEnd = function()
        SpectateUI:Hide()
    end,
})

SpectateController.start()

-- When round ends
SpectateController.stop()
```

---

## Revive System

Allow teammates to revive downed players.

```luau
-- Server: ReviveManager.luau
local Players = game:GetService("Players")

local ReviveManager = {}

type DownedPlayer = {
    player: Player,
    position: Vector3,
    timeRemaining: number,
    reviveProgress: number,
    reviver: Player?,
}

local downedPlayers: { [Player]: DownedPlayer } = {}
local reviveCallbacks: {
    onDowned: ((Player, Vector3) -> ())?,
    onRevived: ((Player, Player) -> ())?,
    onDied: ((Player) -> ())?,
}  = {}

-- Configuration
local config = {
    bleedoutTime = 30,     -- Seconds before fully dead
    reviveTime = 3,        -- Seconds to complete revive
    reviveDistance = 8,    -- Max distance to revive
    reviveHealth = 0.5,    -- Health percentage on revive
}

function ReviveManager.configure(newConfig: { [string]: any })
    for key, value in newConfig do
        config[key] = value
    end
end

function ReviveManager.setCallbacks(callbacks: typeof(reviveCallbacks))
    reviveCallbacks = callbacks
end

function ReviveManager.init()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                ReviveManager.onPlayerDowned(player)
            end)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        downedPlayers[player] = nil
    end)
end

function ReviveManager.onPlayerDowned(player: Player)
    local character = player.Character
    if not character then return end

    local position = character:GetPivot().Position

    downedPlayers[player] = {
        player = player,
        position = position,
        timeRemaining = config.bleedoutTime,
        reviveProgress = 0,
        reviver = nil,
    }

    if reviveCallbacks.onDowned then
        reviveCallbacks.onDowned(player, position)
    end

    -- Bleedout timer
    task.spawn(function()
        while downedPlayers[player] do
            task.wait(1)

            local data = downedPlayers[player]
            if not data then break end

            data.timeRemaining -= 1

            if data.timeRemaining <= 0 then
                -- Fully dead
                downedPlayers[player] = nil
                if reviveCallbacks.onDied then
                    reviveCallbacks.onDied(player)
                end
                break
            end
        end
    end)
end

function ReviveManager.startRevive(reviver: Player, target: Player): boolean
    local data = downedPlayers[target]
    if not data then return false end
    if data.reviver then return false end -- Already being revived

    local reviverCharacter = reviver.Character
    if not reviverCharacter then return false end

    local reviverPos = reviverCharacter:GetPivot().Position
    local distance = (reviverPos - data.position).Magnitude

    if distance > config.reviveDistance then return false end

    data.reviver = reviver
    return true
end

function ReviveManager.updateRevive(reviver: Player, target: Player, dt: number): (boolean, number)
    local data = downedPlayers[target]
    if not data or data.reviver ~= reviver then
        return false, 0
    end

    -- Check distance still valid
    local reviverCharacter = reviver.Character
    if not reviverCharacter then
        data.reviver = nil
        data.reviveProgress = 0
        return false, 0
    end

    local reviverPos = reviverCharacter:GetPivot().Position
    local distance = (reviverPos - data.position).Magnitude

    if distance > config.reviveDistance then
        data.reviver = nil
        data.reviveProgress = 0
        return false, 0
    end

    -- Progress revive
    data.reviveProgress += dt / config.reviveTime

    if data.reviveProgress >= 1 then
        -- Revive complete
        ReviveManager.completeRevive(target)
        return true, 1
    end

    return true, data.reviveProgress
end

function ReviveManager.cancelRevive(reviver: Player, target: Player)
    local data = downedPlayers[target]
    if data and data.reviver == reviver then
        data.reviver = nil
        data.reviveProgress = 0
    end
end

function ReviveManager.completeRevive(target: Player)
    local data = downedPlayers[target]
    if not data then return end

    local reviver = data.reviver
    downedPlayers[target] = nil

    -- Respawn player
    target:LoadCharacter()

    task.defer(function()
        local character = target.Character
        if character then
            character:PivotTo(CFrame.new(data.position + Vector3.new(0, 3, 0)))

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth * config.reviveHealth
            end
        end
    end)

    if reviver and reviveCallbacks.onRevived then
        reviveCallbacks.onRevived(target, reviver)
    end
end

function ReviveManager.isDowned(player: Player): boolean
    return downedPlayers[player] ~= nil
end

function ReviveManager.getDownedPlayers(): { DownedPlayer }
    local result = {}
    for _, data in downedPlayers do
        table.insert(result, data)
    end
    return result
end

function ReviveManager.getBleedoutTime(player: Player): number?
    local data = downedPlayers[player]
    return data and data.timeRemaining
end

return ReviveManager
```

---

## Event Synchronization

Ensure all players experience events at the same time.

```luau
-- Server: EventSync.luau
local Players = game:GetService("Players")

local EventSync = {}

local Remotes = {} -- Reference to your RemoteEvents

function EventSync.init(remoteFolder: Folder)
    Remotes.GlobalEvent = remoteFolder:WaitForChild("GlobalEvent")
    Remotes.ProximityEvent = remoteFolder:WaitForChild("ProximityEvent")
    Remotes.TeamEvent = remoteFolder:WaitForChild("TeamEvent")
end

-- Fire event to all players simultaneously
function EventSync.global(eventType: string, data: any)
    Remotes.GlobalEvent:FireAllClients(eventType, data)
end

-- Fire event to players within radius
function EventSync.proximity(
    position: Vector3,
    radius: number,
    eventType: string,
    data: any
)
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - position).Magnitude
                if distance <= radius then
                    Remotes.ProximityEvent:FireClient(player, eventType, data, distance)
                end
            end
        end
    end
end

-- Fire event to specific team
function EventSync.team(teamName: string, eventType: string, data: any)
    for _, player in Players:GetPlayers() do
        if player.Team and player.Team.Name == teamName then
            Remotes.TeamEvent:FireClient(player, eventType, data)
        end
    end
end

-- Fire event to specific players
function EventSync.players(playerList: { Player }, eventType: string, data: any)
    for _, player in playerList do
        Remotes.GlobalEvent:FireClient(player, eventType, data)
    end
end

-- Fire event with delay compensation
-- All clients will trigger at approximately the same real time
function EventSync.synchronized(eventType: string, data: any, delaySeconds: number?)
    local triggerTime = os.clock() + (delaySeconds or 0)
    Remotes.GlobalEvent:FireAllClients(eventType, data, triggerTime)
end

return EventSync
```

### Client Handler

```luau
-- Client: EventHandler.luau
local EventHandler = {}

local handlers: { [string]: (any, number?) -> () } = {}

function EventHandler.init(remoteFolder: Folder)
    local globalEvent = remoteFolder:WaitForChild("GlobalEvent")
    local proximityEvent = remoteFolder:WaitForChild("ProximityEvent")

    globalEvent.OnClientEvent:Connect(function(eventType, data, triggerTime)
        if triggerTime then
            -- Synchronized event - wait until trigger time
            local delay = triggerTime - os.clock()
            if delay > 0 then
                task.wait(delay)
            end
        end

        local handler = handlers[eventType]
        if handler then
            handler(data)
        end
    end)

    proximityEvent.OnClientEvent:Connect(function(eventType, data, distance)
        local handler = handlers[eventType]
        if handler then
            handler(data, distance)
        end
    end)
end

function EventHandler.on(eventType: string, callback: (any, number?) -> ())
    handlers[eventType] = callback
end

return EventHandler
```

### Usage

```luau
-- Server: Trigger a synchronized event
EventSync.global("round_start", { roundNumber = 5 })

-- Proximity-based event (explosion)
EventSync.proximity(explosionPos, 50, "explosion", { intensity = 1 })

-- Client: Handle events
EventHandler.on("round_start", function(data)
    print("Round", data.roundNumber, "starting!")
end)

EventHandler.on("explosion", function(data, distance)
    local intensity = data.intensity * (1 - distance / 50)
    CameraShake.shake(intensity, 10, 0.5)
end)
```

---

## Team Coordination

Patterns for team-based gameplay.

```luau
-- Server: TeamManager.luau
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local TeamManager = {}

function TeamManager.getTeamPlayers(teamName: string): { Player }
    local team = Teams:FindFirstChild(teamName)
    if not team then return {} end

    local players = {}
    for _, player in Players:GetPlayers() do
        if player.Team == team then
            table.insert(players, player)
        end
    end
    return players
end

function TeamManager.getAliveTeamPlayers(teamName: string): { Player }
    local players = {}
    for _, player in TeamManager.getTeamPlayers(teamName) do
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(players, player)
            end
        end
    end
    return players
end

function TeamManager.isTeamAlive(teamName: string): boolean
    return #TeamManager.getAliveTeamPlayers(teamName) > 0
end

function TeamManager.getTeamHealth(teamName: string): (number, number) -- current, max
    local current, max = 0, 0

    for _, player in TeamManager.getTeamPlayers(teamName) do
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                current += humanoid.Health
                max += humanoid.MaxHealth
            end
        end
    end

    return current, max
end

function TeamManager.assignToTeam(player: Player, teamName: string)
    local team = Teams:FindFirstChild(teamName)
    if team then
        player.Team = team
    end
end

function TeamManager.balanceTeams(teamNames: { string })
    local players = Players:GetPlayers()
    local teamsCount = #teamNames

    for i, player in players do
        local teamIndex = ((i - 1) % teamsCount) + 1
        TeamManager.assignToTeam(player, teamNames[teamIndex])
    end
end

return TeamManager
```

---

## Pitfalls

### ❌ Not cleaning up spectate connections
**Problem:** Memory leak and input conflicts.
**Fix:** Always disconnect input listeners when stopping spectate.

### ❌ Revive exploit via teleporting away
**Problem:** Player starts revive then teleports, keeping progress.
**Fix:** Check distance continuously, not just at start.

### ❌ Event timing differences across clients
**Problem:** Events feel out of sync in multiplayer.
**Fix:** Use `EventSync.synchronized()` with server timestamp.

### ❌ No validation of team operations
**Problem:** Exploiters could change their own team.
**Fix:** All team changes should go through server-side TeamManager.

### ❌ Spectating enemy players
**Problem:** Players can spectate opponents and share info.
**Fix:** Filter spectate targets to teammates only.
