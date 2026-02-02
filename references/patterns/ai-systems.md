# AI Systems

Reusable patterns for NPC behavior, pathfinding, and dynamic difficulty.

**Use cases:** Horror pursuers, combat enemies, friendly NPCs, pets, guards, bosses

---

## State Machine Pattern (Typed Luau)

A flexible state machine that works for any NPC type. Each state has `enter`, `step`, and `exit` handlers.

```luau
-- Server: NPCStateMachine.luau
local PathfindingService = game:GetService("PathfindingService")

export type NPCState = string -- Define your states: "Idle" | "Patrol" | "Chase" | etc.

type StateHandler = {
    enter: (self: NPCController) -> (),
    step: (self: NPCController, dt: number) -> NPCState?, -- Return new state or nil to stay
    exit: (self: NPCController) -> (),
}

type NPCController = {
    npc: Model,
    state: NPCState,
    target: Player?,
    lastKnownPosition: Vector3?,
    stuckTime: number,
    lastPosition: Vector3?,
    customData: { [string]: any }, -- Game-specific data
    states: { [NPCState]: StateHandler },
}

local NPCStateMachine = {}

function NPCStateMachine.new(npcModel: Model, initialState: NPCState): NPCController
    local self: NPCController = {
        npc = npcModel,
        state = initialState,
        target = nil,
        lastKnownPosition = nil,
        stuckTime = 0,
        lastPosition = nil,
        customData = {},
        states = {},
    }
    return self
end

function NPCStateMachine.addState(controller: NPCController, stateName: NPCState, handler: StateHandler)
    controller.states[stateName] = handler
end

function NPCStateMachine.setState(controller: NPCController, newState: NPCState)
    if controller.state == newState then return end

    local currentHandler = controller.states[controller.state]
    if currentHandler and currentHandler.exit then
        currentHandler.exit(controller)
    end

    controller.state = newState

    local newHandler = controller.states[newState]
    if newHandler and newHandler.enter then
        newHandler.enter(controller)
    end
end

function NPCStateMachine.update(controller: NPCController, dt: number)
    local stateHandler = controller.states[controller.state]
    if not stateHandler then return end

    local newState = stateHandler.step(controller, dt)
    if newState and newState ~= controller.state then
        NPCStateMachine.setState(controller, newState)
    end

    -- Stuck detection
    checkStuck(controller, dt)
end

local function checkStuck(controller: NPCController, dt: number)
    local currentPos = controller.npc.PrimaryPart and controller.npc.PrimaryPart.Position
    if not currentPos then return end

    if controller.lastPosition then
        local moved = (currentPos - controller.lastPosition).Magnitude
        if moved < 0.5 then
            controller.stuckTime += dt
            if controller.stuckTime > 3 then
                -- Fire stuck callback or handle unstuck
                if controller.onStuck then
                    controller.onStuck(controller)
                end
                controller.stuckTime = 0
            end
        else
            controller.stuckTime = 0
        end
    end
    controller.lastPosition = currentPos
end

return NPCStateMachine
```

### Example: Combat Enemy States

```luau
local enemy = NPCStateMachine.new(enemyModel, "Patrol")

NPCStateMachine.addState(enemy, "Patrol", {
    enter = function(controller)
        controller.npc.Humanoid.WalkSpeed = 8
    end,
    step = function(controller, dt)
        local target = findNearestPlayer(controller)
        if target then
            controller.target = target
            return "Chase"
        end
        moveToNextWaypoint(controller)
        return nil
    end,
    exit = function(controller) end,
})

NPCStateMachine.addState(enemy, "Chase", {
    enter = function(controller)
        controller.npc.Humanoid.WalkSpeed = 16
    end,
    step = function(controller, dt)
        if not controller.target then return "Patrol" end

        local distance = getDistanceToTarget(controller)
        if distance < 5 then
            return "Attack"
        elseif distance > 50 then
            controller.target = nil
            return "Patrol"
        end

        moveToTarget(controller)
        return nil
    end,
    exit = function(controller) end,
})
```

---

## Line of Sight Detection

Check if an NPC can see a target, using vision cones and raycasting.

```luau
-- Server: Detection.luau
local Workspace = game:GetService("Workspace")

local Detection = {}

local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

-- Check if there's a clear path between two points
function Detection.hasLineOfSight(origin: Vector3, target: Vector3, ignoreList: { Instance }?): boolean
    local direction = target - origin

    if ignoreList then
        RAYCAST_PARAMS.FilterDescendantsInstances = ignoreList
    end

    local result = Workspace:Raycast(origin, direction, RAYCAST_PARAMS)
    return result == nil
end

-- Check if a target is within a vision cone
function Detection.isInVisionCone(
    observerPosition: Vector3,
    observerLookVector: Vector3,
    targetPosition: Vector3,
    maxAngle: number -- Total cone angle in degrees
): boolean
    local directionToTarget = (targetPosition - observerPosition).Unit
    local dotProduct = observerLookVector:Dot(directionToTarget)

    -- cos(angle/2) gives the threshold
    local threshold = math.cos(math.rad(maxAngle / 2))
    return dotProduct >= threshold
end

-- Full detection check with distance tiers
-- Closer = wider vision cone (can see behind at close range)
function Detection.checkDetection(
    npc: Model,
    targetPosition: Vector3,
    config: {
        close: { range: number, angle: number },
        medium: { range: number, angle: number },
        far: { range: number, angle: number },
    }?
): (boolean, string?) -- detected, tier
    local npcHead = npc:FindFirstChild("Head")
    if not npcHead then return false, nil end

    local npcPosition = npcHead.Position
    local npcLookVector = npcHead.CFrame.LookVector
    local distance = (targetPosition - npcPosition).Magnitude

    -- Default detection tiers
    config = config or {
        close = { range = 15, angle = 180 },  -- Behind counts
        medium = { range = 30, angle = 120 }, -- Wide cone
        far = { range = 60, angle = 60 },     -- Narrow cone
    }

    for tier, tierConfig in pairs(config) do
        if distance <= tierConfig.range then
            if Detection.isInVisionCone(npcPosition, npcLookVector, targetPosition, tierConfig.angle) then
                if Detection.hasLineOfSight(npcPosition, targetPosition, { npc }) then
                    return true, tier
                end
            end
        end
    end

    return false, nil
end

-- Hearing detection (for sound-based games)
function Detection.canHear(
    listenerPosition: Vector3,
    soundPosition: Vector3,
    soundRadius: number,
    obstructionReduction: number? -- How much walls reduce hearing (0-1)
): boolean
    local distance = (soundPosition - listenerPosition).Magnitude
    if distance > soundRadius then return false end

    -- Check for obstructions
    if obstructionReduction and obstructionReduction > 0 then
        local hasLOS = Detection.hasLineOfSight(listenerPosition, soundPosition, {})
        if not hasLOS then
            -- Reduce effective hearing range through walls
            local effectiveRadius = soundRadius * (1 - obstructionReduction)
            return distance <= effectiveRadius
        end
    end

    return true
end

return Detection
```

---

## AI Director (Dynamic Difficulty)

Adjusts game difficulty based on player performance. Works for any game with enemies or challenges.

```luau
-- Server: AIDirector.luau
local Players = game:GetService("Players")

local AIDirector = {}

type DirectorConfig = {
    baseDifficulty: number,      -- Starting difficulty (0-100)
    maxDifficulty: number,       -- Cap
    minDifficulty: number,       -- Floor

    decayRate: number,           -- Difficulty decrease per second when calm
    decayDelay: number,          -- Seconds before decay starts

    onSuccess: number,           -- Difficulty increase on player success
    onFailure: number,           -- Difficulty change on player failure (usually negative)
    onDamage: number,            -- Change when player takes damage
}

type DirectorState = {
    difficulty: number,
    lastEventTime: number,
    consecutiveSuccesses: number,
    consecutiveFailures: number,
}

local state: DirectorState = {
    difficulty = 50,
    lastEventTime = 0,
    consecutiveSuccesses = 0,
    consecutiveFailures = 0,
}

local config: DirectorConfig = {
    baseDifficulty = 50,
    maxDifficulty = 100,
    minDifficulty = 0,
    decayRate = 2,
    decayDelay = 30,
    onSuccess = 10,
    onFailure = -15,
    onDamage = 5,
}

function AIDirector.init(customConfig: DirectorConfig?)
    if customConfig then
        for key, value in customConfig do
            config[key] = value
        end
    end
    state.difficulty = config.baseDifficulty
end

function AIDirector.onPlayerSuccess()
    state.lastEventTime = os.clock()
    state.consecutiveSuccesses += 1
    state.consecutiveFailures = 0

    -- Escalating difficulty on streaks
    local bonus = math.min(state.consecutiveSuccesses - 1, 5) * 2
    state.difficulty = math.min(config.maxDifficulty, state.difficulty + config.onSuccess + bonus)
end

function AIDirector.onPlayerFailure()
    state.lastEventTime = os.clock()
    state.consecutiveFailures += 1
    state.consecutiveSuccesses = 0

    -- Mercy on repeated failures
    local mercy = math.min(state.consecutiveFailures - 1, 3) * 5
    state.difficulty = math.max(config.minDifficulty, state.difficulty + config.onFailure - mercy)
end

function AIDirector.onPlayerDamage(damagePercent: number)
    state.lastEventTime = os.clock()
    state.difficulty = math.min(config.maxDifficulty, state.difficulty + config.onDamage * damagePercent)
end

function AIDirector.update(dt: number)
    local timeSinceEvent = os.clock() - state.lastEventTime
    if timeSinceEvent > config.decayDelay then
        state.difficulty = math.max(config.minDifficulty, state.difficulty - config.decayRate * dt)
    end
end

-- Get values scaled by difficulty (0-100 -> multiplier)
function AIDirector.getDifficulty(): number
    return state.difficulty
end

function AIDirector.getMultiplier(): number
    return state.difficulty / 100
end

-- Scale a value based on difficulty
-- Example: AIDirector.scale(10, 20) returns 10 at difficulty 0, 20 at difficulty 100
function AIDirector.scale(minValue: number, maxValue: number): number
    local t = state.difficulty / 100
    return minValue + (maxValue - minValue) * t
end

return AIDirector
```

### Usage Examples

```luau
-- Combat game: enemy speed scales with difficulty
local enemySpeed = AIDirector.scale(12, 20) -- 12-20 based on difficulty

-- Horror game: detection range scales
local detectionRange = AIDirector.scale(30, 60)

-- Wave spawner: spawn rate scales
local spawnInterval = AIDirector.scale(5, 2) -- Faster spawns at high difficulty

-- Boss fight: attack frequency
local attackCooldown = AIDirector.scale(3, 1)
```

---

## PathfindingService Best Practices

### Basic Pathfinding

```luau
local PathfindingService = game:GetService("PathfindingService")

local function moveToPosition(npc: Model, targetPosition: Vector3)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local rootPart = npc.PrimaryPart
    if not humanoid or not rootPart then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 4,
    })

    local success, errorMessage = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()
    for i, waypoint in waypoints do
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        humanoid:MoveTo(waypoint.Position)

        -- Don't wait for completion - let caller handle recomputation
        -- This prevents blocking on stale paths
    end

    return true
end
```

### PathfindingLinks for Doors/Vents

Use `PathfindingLink` to connect non-adjacent areas (through doors, vents, teleporters).

```luau
-- Setup: Create PathfindingLink in workspace
-- Link.Attachment0 = door entrance attachment
-- Link.Attachment1 = door exit attachment
-- Link.Label = "Door" or "Vent" or custom

local function setupPathfindingWithLinks(npc: Model)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        Costs = {
            Door = 1.5,  -- Slightly discourage doors unless needed
            Vent = 2.0,  -- More costly to use vents
        },
    })

    return path
end

-- Handle special waypoints
local function processWaypoint(waypoint: PathWaypoint, npc: Model)
    if waypoint.Label == "Door" then
        -- Play door open animation, wait, then continue
        openDoor(waypoint.Position)
        task.wait(1)
    elseif waypoint.Label == "Vent" then
        -- Play crawl animation
        playCrawlAnimation(npc)
    end
end
```

### Continuous Path Recomputation

For moving targets, recompute paths regularly instead of waiting for completion.

```luau
local RECOMPUTE_INTERVAL = 0.5

local function chaseTarget(npc: Model, target: Player)
    local lastCompute = 0

    while target and target.Character do
        local now = os.clock()
        if now - lastCompute >= RECOMPUTE_INTERVAL then
            local targetPos = target.Character:GetPivot().Position
            moveToPosition(npc, targetPos)
            lastCompute = now
        end
        task.wait(0.1)
    end
end
```

---

## Common AI Patterns

### Patrol Waypoints

```luau
local function createPatrolBehavior(waypoints: { Vector3 })
    local currentIndex = 1

    return {
        getNextWaypoint = function(): Vector3
            local waypoint = waypoints[currentIndex]
            currentIndex = (currentIndex % #waypoints) + 1
            return waypoint
        end,

        reset = function()
            currentIndex = 1
        end,
    }
end
```

### Aggro Table (Multiple Targets)

```luau
local aggroTable: { [Player]: number } = {}

local function addAggro(player: Player, amount: number)
    aggroTable[player] = (aggroTable[player] or 0) + amount
end

local function decayAggro(dt: number, decayRate: number)
    for player, aggro in aggroTable do
        aggroTable[player] = math.max(0, aggro - decayRate * dt)
        if aggroTable[player] <= 0 then
            aggroTable[player] = nil
        end
    end
end

local function getHighestAggroTarget(): Player?
    local highestPlayer = nil
    local highestAggro = 0

    for player, aggro in aggroTable do
        if aggro > highestAggro then
            highestAggro = aggro
            highestPlayer = player
        end
    end

    return highestPlayer
end
```

### Leash Range (Return to Origin)

```luau
local function createLeashBehavior(origin: Vector3, maxRange: number)
    return {
        shouldReturn = function(currentPosition: Vector3): boolean
            return (currentPosition - origin).Magnitude > maxRange
        end,

        getReturnPosition = function(): Vector3
            return origin
        end,
    }
end
```

---

## Pitfalls

### ❌ Blocking on MoveToFinished:Wait()
**Problem:** NPC walks to stale position while target moves.
**Fix:** Recompute path every 0.5s. Never block waiting for path completion.

### ❌ No stuck detection
**Problem:** NPC gets caught on geometry forever.
**Fix:** Track position over time. If NPC hasn't moved in 3+ seconds, teleport or repath.

### ❌ Computing paths every frame
**Problem:** Performance issues, especially with many NPCs.
**Fix:** Recompute at intervals (0.5-1s). Cache paths when target hasn't moved significantly.

### ❌ Ignoring PathfindingLinks
**Problem:** NPCs can't navigate through doors or special areas.
**Fix:** Set up PathfindingLinks and handle their labels in waypoint processing.

### ❌ Not using typed Luau for states
**Problem:** State machine bugs from typos in state names.
**Fix:** Define states as union types: `export type NPCState = "Idle" | "Chase" | "Attack"`
