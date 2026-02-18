# AI Systems

Reusable patterns for NPC behavior, pathfinding, and dynamic difficulty. Each pattern includes **when/why/related** metadata to help identify the right pattern for a given problem.

**Use cases:** Horror pursuers, combat enemies, friendly NPCs, pets, guards, bosses

---

## State Machine Pattern

> **When:** Any NPC needs multiple behaviors (idle, patrol, chase, attack, flee). Reach for this whenever an NPC has more than one "mode" of operation.
>
> **Why:** Without a state machine, NPC logic devolves into nested if/else chains that are painful to debug and extend. States provide clear entry/exit points for cleanup, and typed state names catch typos at analysis time.
>
> **Related:** Player Lifecycle (`luau-patterns.md`) for per-NPC cleanup on removal, Connection Management (`luau-patterns.md`) for state-scoped connections

```luau
--!strict
-- Server: NPCStateMachine.luau

-- Union type catches typos at analysis time (see Pitfalls)
export type NPCState = "Idle" | "Patrol" | "Chase" | "Attack" | "Flee" | "Stunned"

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
    onStuck: ((self: NPCController) -> ())?,
}

local NPCStateMachine = {}

-- Stuck detection: must be declared before update() which references it
local function checkStuck(controller: NPCController, dt: number)
    local primaryPart = controller.npc.PrimaryPart
    if not primaryPart then return end

    local currentPos = primaryPart.Position

    if controller.lastPosition then
        local moved = (currentPos - controller.lastPosition).Magnitude
        if moved < 0.5 then
            controller.stuckTime += dt
            if controller.stuckTime > 3 then
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
        onStuck = nil,
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

    checkStuck(controller, dt)
end

return NPCStateMachine
```

### Example: Combat Enemy States

```luau
--!strict
local enemy = NPCStateMachine.new(enemyModel, "Patrol")

NPCStateMachine.addState(enemy, "Patrol", {
    enter = function(controller)
        local humanoid = controller.npc:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 8 end
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
    exit = function(_controller) end,
})

NPCStateMachine.addState(enemy, "Chase", {
    enter = function(controller)
        local humanoid = controller.npc:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
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
    exit = function(_controller) end,
})
```

---

## Line of Sight Detection

> **When:** NPC needs to "see" or "hear" a player — vision cones, raycasting through walls, sound-based detection with obstruction.
>
> **Why:** Pure distance checks feel cheap. Vision cones + raycasting create believable AI that players can learn to outsmart (hide behind cover, stay outside the cone, crouch to reduce noise).
>
> **Related:** AI Director (detection range can scale with difficulty), State Machine (detection results drive state transitions)

```luau
--!strict
-- Server: Detection.luau
local Workspace = game:GetService("Workspace")

local Detection = {}

-- Module-level RaycastParams reused across calls.
-- Safe for single-threaded code (no yields between set and use).
-- For parallel Luau (Actor scripts), create params locally instead.
local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

function Detection.hasLineOfSight(origin: Vector3, target: Vector3, ignoreList: { Instance }?): boolean
    local direction = target - origin

    if ignoreList then
        RAYCAST_PARAMS.FilterDescendantsInstances = ignoreList
    end

    local result = Workspace:Raycast(origin, direction, RAYCAST_PARAMS)
    return result == nil
end

function Detection.isInVisionCone(
    observerPosition: Vector3,
    observerLookVector: Vector3,
    targetPosition: Vector3,
    maxAngle: number -- Total cone angle in degrees
): boolean
    local directionToTarget = (targetPosition - observerPosition).Unit
    local dotProduct = observerLookVector:Dot(directionToTarget)

    -- cos(angle/2) gives the threshold for half the cone
    local threshold = math.cos(math.rad(maxAngle / 2))
    return dotProduct >= threshold
end

-- Full detection check with distance tiers.
-- Closer = wider vision cone (peripheral vision at close range).
function Detection.checkDetection(
    npc: Model,
    targetPosition: Vector3,
    config: {
        close: { range: number, angle: number },
        medium: { range: number, angle: number },
        far: { range: number, angle: number },
    }?
): (boolean, string?) -- detected, tier name
    local npcHead = npc:FindFirstChild("Head")
    if not npcHead then return false, nil end

    local npcPosition = (npcHead :: BasePart).Position
    local npcLookVector = (npcHead :: BasePart).CFrame.LookVector
    local distance = (targetPosition - npcPosition).Magnitude

    local tiers = config or {
        close = { range = 15, angle = 180 },  -- Behind counts
        medium = { range = 30, angle = 120 }, -- Wide cone
        far = { range = 60, angle = 60 },     -- Narrow cone
    }

    for tier, tierConfig in tiers do
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

-- Hearing detection (for sound-based games like horror)
function Detection.canHear(
    listenerPosition: Vector3,
    soundPosition: Vector3,
    soundRadius: number,
    obstructionReduction: number? -- How much walls reduce hearing (0-1)
): boolean
    local distance = (soundPosition - listenerPosition).Magnitude
    if distance > soundRadius then return false end

    if obstructionReduction and obstructionReduction > 0 then
        local hasLOS = Detection.hasLineOfSight(listenerPosition, soundPosition, {})
        if not hasLOS then
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

> **When:** Game difficulty should adapt to player performance — enemies get smarter when players dominate, show mercy when players struggle.
>
> **Why:** Static difficulty either bores skilled players or frustrates new ones. An AI Director creates tension curves (escalate → peak → release) that keep sessions engaging. Left 4 Dead popularized this; it works just as well in Roblox horror/combat games.
>
> **Related:** State Machine (difficulty feeds into state transition thresholds), RunService Frame Loop (`luau-patterns.md`) for calling `update()` each frame

**Note:** This implementation is a singleton (module-level state). If you need per-player or per-team difficulty tracking, refactor `state` and `config` into a constructor that returns instances. For most games, a single shared director is correct.

```luau
--!strict
-- Server: AIDirector.luau

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
            (config :: any)[key] = value
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

function AIDirector.getDifficulty(): number
    return state.difficulty
end

function AIDirector.getMultiplier(): number
    return state.difficulty / 100
end

-- Linearly interpolate between min and max based on difficulty.
-- Example: AIDirector.scale(10, 20) returns 10 at difficulty 0, 20 at difficulty 100.
function AIDirector.scale(minValue: number, maxValue: number): number
    local t = state.difficulty / 100
    return minValue + (maxValue - minValue) * t
end

return AIDirector
```

### Usage Examples

```luau
-- Combat game: enemy speed scales with difficulty
local enemySpeed = AIDirector.scale(12, 20)

-- Horror game: detection range scales
local detectionRange = AIDirector.scale(30, 60)

-- Wave spawner: spawn rate scales (lower = faster, so min/max are inverted)
local spawnInterval = AIDirector.scale(5, 2)

-- Boss fight: attack frequency
local attackCooldown = AIDirector.scale(3, 1)
```

---

## PathfindingService Best Practices

> **When:** NPC needs to navigate around obstacles to reach a position or follow a moving target.
>
> **Why:** Raw `MoveTo()` walks in a straight line and gets stuck on any obstacle. PathfindingService computes paths around geometry. But it has critical gotchas (8-second timeout, waypoint iteration) that cause most first-attempt NPC scripts to silently break.
>
> **Related:** State Machine (pathfinding lives inside Chase/Patrol states), Delta-Time Scaling (`luau-patterns.md`) if doing custom movement

### Waypoint Walking

Each `MoveTo()` call overrides the previous target — you **must** wait for each waypoint before issuing the next one. `MoveToFinished` has an 8-second timeout: if the humanoid doesn't arrive in 8 seconds, the event fires with `reached = false`. For slow NPCs or long distances, re-issue `MoveTo` before the timeout expires.

```luau
--!strict
local PathfindingService = game:GetService("PathfindingService")

-- Walk an NPC along a computed path, waypoint by waypoint.
-- Returns true if the NPC reached the final waypoint.
local function walkPath(npc: Model, targetPosition: Vector3): boolean
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local rootPart = npc.PrimaryPart
    if not humanoid or not rootPart then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 4,
    })

    local ok, _err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()
    for _, waypoint in waypoints do
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)

        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            -- 8-second timeout hit or humanoid couldn't reach waypoint
            return false
        end
    end

    return true
end
```

### PathfindingLinks for Doors/Vents

Use `PathfindingLink` to connect non-adjacent areas (through doors, vents, teleporters).

```luau
--!strict
-- Setup: Create PathfindingLink instances in workspace
-- Link.Attachment0 = door entrance, Link.Attachment1 = door exit
-- Link.Label = "Door" or "Vent" or custom label

local PathfindingService = game:GetService("PathfindingService")

local function createPathWithLinks(): Path
    return PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        Costs = {
            Door = 1.5,  -- Slightly discourage doors unless needed
            Vent = 2.0,  -- More costly to use vents
        },
    })
end

-- Handle special waypoints during path traversal
local function processWaypoint(waypoint: PathWaypoint, npc: Model)
    if waypoint.Label == "Door" then
        openDoor(waypoint.Position)
        task.wait(1)
    elseif waypoint.Label == "Vent" then
        playCrawlAnimation(npc)
    end
end
```

### Continuous Chase (Moving Targets)

For chasing players, recompute the path on an interval instead of walking the full path. The `active` flag allows external cancellation (e.g., when the NPC state changes or the NPC is destroyed).

See: Connection Management, Instance Destruction Safety in `luau-patterns.md`.

```luau
--!strict
local RECOMPUTE_INTERVAL = 0.5

type ChaseHandle = {
    active: boolean,
    stop: () -> (),
}

local function chaseTarget(npc: Model, target: Player): ChaseHandle
    local handle: ChaseHandle = {
        active = true,
        stop = function() end, -- replaced below
    }

    handle.stop = function()
        handle.active = false
    end

    task.spawn(function()
        local lastCompute = 0

        while handle.active do
            local character = target.Character
            if not character then break end

            -- Check NPC still exists (may have been destroyed during yield)
            if not npc.PrimaryPart then break end

            local now = os.clock()
            if now - lastCompute >= RECOMPUTE_INTERVAL then
                local targetPos = character:GetPivot().Position
                walkPath(npc, targetPos)
                lastCompute = now
            end

            task.wait(0.1)
        end
    end)

    return handle
end

-- Usage in a state machine:
-- local chase = chaseTarget(npc, target)
-- On state exit: chase.stop()
```

---

## Common AI Patterns

### Patrol Waypoints

> **When:** NPC should walk a repeating route between predefined positions.
>
> **Why:** Simple closure pattern — no class needed. The index wraps automatically.

```luau
--!strict
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

> **When:** NPC should target whichever player has generated the most "threat" — damage dealt, noise made, proximity, etc.
>
> **Why:** Without aggro, NPCs either target the closest player (ignoring the one attacking them) or randomly switch targets. An aggro table with decay creates natural target-switching behavior.
>
> **Related:** Player Lifecycle (`luau-patterns.md`) — clean up aggro entries on PlayerRemoving

```luau
--!strict
local aggroTable: { [Player]: number } = {}

local function addAggro(player: Player, amount: number)
    aggroTable[player] = (aggroTable[player] or 0) + amount
end

local function removePlayer(player: Player)
    aggroTable[player] = nil
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
    local highestPlayer: Player? = nil
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

> **When:** NPC should give up chasing and return home after the player runs too far away.
>
> **Why:** Without a leash, NPCs chase forever, leaving their patrol area permanently. Players exploit this to kite enemies away from objectives.

```luau
--!strict
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

### ❌ MoveTo 8-second timeout
**Problem:** `Humanoid:MoveTo()` silently gives up after 8 seconds if the NPC hasn't arrived. `MoveToFinished` fires with `reached = false`. Slow NPCs walking long distances will stop mid-path with no error.
**Fix:** For long-distance movement, re-issue `MoveTo` to the same target before the 8-second window expires. Or use short waypoint segments so each leg completes well within the timeout.

### ❌ Calling MoveTo in a loop without waiting
**Problem:** Each `MoveTo()` overrides the previous target. Iterating waypoints without `MoveToFinished:Wait()` between them means only the last waypoint is ever walked to.
**Fix:** Wait for each waypoint: `humanoid:MoveTo(pos); humanoid.MoveToFinished:Wait()`. For moving targets, use the Continuous Chase pattern above instead.

### ❌ Blocking on MoveToFinished:Wait() during chase
**Problem:** Waiting for path completion while chasing a moving target means the NPC walks to a stale position before recomputing.
**Fix:** Recompute path every 0.5s. Use the chase handle pattern to cancel the previous path when recomputing.

### ❌ No stuck detection
**Problem:** NPC gets caught on geometry and walks into a wall forever.
**Fix:** Track position over time. If NPC hasn't moved >0.5 studs in 3+ seconds, teleport to last known good position or force a repath.

### ❌ Computing paths every frame
**Problem:** `ComputeAsync` is expensive. Calling it 60 times/second with many NPCs tanks server performance.
**Fix:** Recompute at intervals (0.5-1s). Skip recomputation if the target hasn't moved significantly since last compute.

### ❌ Ignoring PathfindingLinks
**Problem:** NPCs can't navigate through doors, vents, or teleporters. They path to the closest reachable point and get stuck.
**Fix:** Set up `PathfindingLink` instances with labeled attachments. Handle labels during waypoint processing.

### ❌ Using `string` type for states instead of union types
**Problem:** `export type NPCState = string` accepts any string, so typos like `"Chasing"` instead of `"Chase"` silently create unreachable states.
**Fix:** Use union types: `export type NPCState = "Idle" | "Patrol" | "Chase" | "Attack"`. The type checker flags invalid state names.

### ❌ No cleanup on NPC chase loops
**Problem:** A `while` loop chasing a target runs forever if nothing stops it — even after the NPC is destroyed or the state changes.
**Fix:** Use a cancellation handle (see Continuous Chase pattern). Set `handle.active = false` on state exit or NPC removal.
