# Horror / Exploration Games

Story-driven games with survival elements, chase mechanics, and atmospheric exploration.

**Examples:** Piggy, Granny, Flee the Facility, Doors, The Mimic, Rainbow Friends

---

## Implied Decisions

When you say "horror," "escape," or "story game," you're usually implying:

| Decision | Typical Answer | Why |
|----------|---------------|-----|
| Session format | Chapters/rounds | Discrete episodes with clear start, escape goal, end |
| Persistence | Medium | Chapter unlocks, skins, stats — not heavy economy |
| Exploit sensitivity | Medium-High | Speed/noclip exploits ruin tension; progression exploits less critical |
| Authority model | Server-authoritative | NPC positions, item states, progression all validated server-side |
| Structure | Layered | Complex server logic for AI behavior, puzzle states, progression |

**If these don't match your vision, adjust during wizard setup.** But this is the default.

---

## Recommended Packages

```toml
[dependencies]
Promise = "evaera/promise"        # Async operations (cutscenes, timed events)
GoodSignal = "stravant/goodsignal" # Custom events (AI state changes, triggers)
Trove = "sleitnick/trove"         # Cleanup between chapters

[server-dependencies]
ProfileStore = "lm-loleris/profilestore"  # Chapter progress, unlocks
```

**Consider adding:**
- Custom state machine module — Essential for NPC AI behavior (idle/patrol/chase/search)
- Audio layering system — Atmosphere depends on dynamic soundscapes
- Camera manipulation utilities — For cutscenes and jump scares

---

## MVP Checklist

Build these in order for a playable vertical slice:

### Phase 1: Core Loop (build first)
- [ ] **One playable map** — Escape-room scale, 3-5 rooms minimum
- [ ] **Working AI pursuer** — PathfindingService, basic chase behavior
- [ ] **Key/door puzzle** — Collect item → unlock path → progress
- [ ] **Win/lose conditions** — Escape = win, caught = lose
- [ ] **Basic atmosphere** — Dim lighting, ambient audio, footstep sounds

**Milestone:** Player spawns, AI hunts them, they find a key, unlock a door, escape (or get caught). The experience feels tense.

### Phase 2: Depth
- [ ] Multiple chapters with unique layouts
- [ ] Chapter progression persistence (unlock chapter 2 after beating chapter 1)
- [ ] NPC behavior variations (patrol vs. chase vs. ambush)
- [ ] Additional puzzle types (codes, sequence puzzles, item combinations)
- [ ] Cutscene system for story beats

### Phase 3: Engagement
- [ ] Multiplayer support (co-op survival)
- [ ] Cosmetic unlocks (skins, effects)
- [ ] Difficulty modes
- [ ] Endless/survival mode (post-story replayability)
- [ ] Chapter badges and achievements

---

## Common Patterns

### Architecture Overview

```
Server                          Client
──────                          ──────
NPCManager                      NPCController
  ├─ state machine                ├─ visual/audio feedback
  ├─ pathfinding logic            └─ proximity warnings
  └─ chase/catch detection
                    ↕ Remotes ↕
ChapterManager                  ChapterUI
  ├─ chapter state                ├─ objective display
  ├─ puzzle validation            ├─ inventory UI
  └─ win/lose conditions          └─ cutscene player

DataManager                     AtmosphereController
  ├─ ProfileStore                 ├─ dynamic lighting
  └─ chapter/unlock schema        ├─ audio layers
                                  └─ camera effects
PuzzleService
  ├─ item tracking (server-side)
  └─ door/lock states
```

### NPC AI State Machine

```luau
-- Server: NPCManager.luau
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local NPCManager = {}

export type NPCState = "Idle" | "Patrol" | "Chase" | "Search" | "Stunned"

local npc: Model
local npcState: NPCState = "Patrol"
local currentTarget: Player? = nil
local lastKnownPosition: Vector3? = nil

local DETECTION_RANGE = 40
local CHASE_SPEED = 18
local PATROL_SPEED = 10

function NPCManager.init(npcModel: Model)
    npc = npcModel
    NPCManager.setState("Patrol")
end

function NPCManager.setState(newState: NPCState)
    if npcState == newState then return end
    npcState = newState

    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if newState == "Chase" then
        humanoid.WalkSpeed = CHASE_SPEED
        Remotes.NPCStateChanged:FireAllClients("Chase", currentTarget)
    elseif newState == "Patrol" then
        humanoid.WalkSpeed = PATROL_SPEED
        currentTarget = nil
        Remotes.NPCStateChanged:FireAllClients("Patrol")
    elseif newState == "Search" then
        humanoid.WalkSpeed = PATROL_SPEED
        Remotes.NPCStateChanged:FireAllClients("Search", lastKnownPosition)
    end
end

function NPCManager.update()
    if npcState == "Stunned" then return end

    local nearestPlayer, distance = findNearestPlayer()

    if nearestPlayer and distance < DETECTION_RANGE then
        if hasLineOfSight(nearestPlayer) then
            currentTarget = nearestPlayer
            local character = nearestPlayer.Character
            if character then
                lastKnownPosition = character:GetPivot().Position
            end
            NPCManager.setState("Chase")
        end
    elseif npcState == "Chase" and not currentTarget then
        NPCManager.setState("Search")
    end
end

function NPCManager.moveToTarget()
    if npcState ~= "Chase" or not currentTarget then return end

    local targetCharacter = currentTarget.Character
    if not targetCharacter then return end

    local npcRoot = npc.PrimaryPart
    if not npcRoot then return end

    local targetPosition = targetCharacter:GetPivot().Position
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,
    })

    local success = pcall(function()
        path:ComputeAsync(npcRoot.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return
    end

    local waypoints = path:GetWaypoints()
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    for _, waypoint in waypoints do
        if npcState ~= "Chase" then break end
        humanoid:MoveTo(waypoint.Position)
        -- Don't block — recompute path frequently instead
        task.wait(0.1)
    end
end

return NPCManager
```

### Chapter Progress Data Schema

```luau
-- Shared: DataTemplate.luau
return {
    schemaVersion = 1,

    -- Chapter progression
    chaptersCompleted = {},  -- { chapter1 = true, chapter2 = true }
    currentChapter = "chapter1",

    -- Stats
    totalEscapes = 0,
    totalDeaths = 0,
    fastestTimes = {},  -- { chapter1 = 145.2, chapter2 = 203.8 }

    -- Unlocks
    skins = { "default" },
    equippedSkin = "default",

    -- Achievements
    achievements = {},

    -- Timestamps
    lastPlayed = 0,
}
```

### Proximity-Based Event Triggers

```luau
-- Server: TriggerManager.luau
local Players = game:GetService("Players")

local TriggerManager = {}

local playerCooldowns: { [Player]: { [BasePart]: number } } = {}
local TRIGGER_COOLDOWN = 2

function TriggerManager.init()
    for _, trigger in workspace.Triggers:GetChildren() do
        if trigger:IsA("BasePart") then
            setupTrigger(trigger)
        end
    end
end

local function setupTrigger(trigger: BasePart)
    trigger.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then return end

        if isOnCooldown(player, trigger) then return end
        setCooldown(player, trigger)

        local triggerType = trigger:GetAttribute("TriggerType")
        if typeof(triggerType) ~= "string" then return end

        if triggerType == "jumpscare" then
            Remotes.TriggerJumpscare:FireClient(player, trigger:GetAttribute("ScareId"))
        elseif triggerType == "audio" then
            Remotes.TriggerAudio:FireClient(player, trigger:GetAttribute("SoundId"))
        elseif triggerType == "cutscene" then
            Remotes.TriggerCutscene:FireClient(player, trigger:GetAttribute("CutsceneId"))
        elseif triggerType == "checkpoint" then
            ChapterManager.setCheckpoint(player, trigger:GetAttribute("CheckpointId"))
        end
    end)
end

local function isOnCooldown(player: Player, trigger: BasePart): boolean
    local cooldowns = playerCooldowns[player]
    if not cooldowns then return false end
    local lastTrigger = cooldowns[trigger]
    if not lastTrigger then return false end
    return (os.clock() - lastTrigger) < TRIGGER_COOLDOWN
end

local function setCooldown(player: Player, trigger: BasePart)
    if not playerCooldowns[player] then
        playerCooldowns[player] = {}
    end
    playerCooldowns[player][trigger] = os.clock()
end

return TriggerManager
```

### Dynamic Audio Manager

```luau
-- Client: AudioManager.luau
local SoundService = game:GetService("SoundService")

local AudioManager = {}

local layers: { [string]: Sound } = {}
local currentIntensity: number = 0  -- 0 = calm, 1 = tense, 2 = chase

local LERP_SPEED = 0.5

function AudioManager.init()
    layers.ambient = createSoundLayer("AmbientLoop", 0.3)
    layers.tension = createSoundLayer("TensionLoop", 0)
    layers.chase = createSoundLayer("ChaseLoop", 0)

    for _, sound in layers do
        sound:Play()
    end
end

function AudioManager.setIntensity(targetIntensity: number)
    currentIntensity = math.clamp(targetIntensity, 0, 2)
end

function AudioManager.update(dt: number)
    local ambientTarget = if currentIntensity == 0 then 0.3 else 0.1
    local tensionTarget = if currentIntensity >= 1 then 0.4 else 0
    local chaseTarget = if currentIntensity >= 2 then 0.6 else 0

    layers.ambient.Volume = lerp(layers.ambient.Volume, ambientTarget, dt * LERP_SPEED)
    layers.tension.Volume = lerp(layers.tension.Volume, tensionTarget, dt * LERP_SPEED)
    layers.chase.Volume = lerp(layers.chase.Volume, chaseTarget, dt * LERP_SPEED)
end

local function lerp(a: number, b: number, t: number): number
    return a + (b - a) * math.min(1, t)
end

local function createSoundLayer(name: string, volume: number): Sound
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = GameConfig.Sounds[name]
    sound.Volume = volume
    sound.Looped = true
    sound.Parent = SoundService
    return sound
end

-- Respond to NPC state changes
Remotes.NPCStateChanged.OnClientEvent:Connect(function(state: string)
    if state == "Chase" then
        AudioManager.setIntensity(2)
    elseif state == "Search" then
        AudioManager.setIntensity(1)
    else
        AudioManager.setIntensity(0)
    end
end)

return AudioManager
```

---

## Pitfalls

### ❌ Blocking on MoveToFinished:Wait()
**Problem:** PathfindingService examples use `Humanoid.MoveToFinished:Wait()` which blocks the thread. If the player moves, NPC walks to stale position.
**Fix:** Recompute path every 0.5-1 second. Don't wait for full path completion before checking target position again.

### ❌ Cutscene escape exploits
**Problem:** Players jump, reset, or teleport during cutscenes to skip content or gain unfair positioning.
**Fix:** During cutscenes: disable controls, anchor the character, or teleport to a safe location. Validate cutscene completion server-side before unlocking progression.

### ❌ Client-trusted progression
**Problem:** Exploiter fires "I completed chapter 5" without actually playing.
**Fix:** Server tracks all puzzle states, key pickups, and escape conditions. Chapter completion is calculated server-side, not accepted from client.

### ❌ Over-relying on jump scares
**Problem:** First playthrough is scary, replays become tedious.
**Fix:** Build sustained tension through audio, lighting, and unpredictable AI. Use jump scares sparingly. Randomize some scare triggers for replayability.

### ❌ Speed/noclip exploits ruining tension
**Problem:** Exploiters move at 100 WalkSpeed or clip through walls, trivializing the challenge.
**Fix:** Server validates WalkSpeed (cap + kick for violations). Use invisible collision barriers at map boundaries. Raycast checks for impossible movement.

### ❌ NPC stuck on geometry
**Problem:** AI gets caught on corners, stairs, or tight spaces — breaks immersion.
**Fix:** Test pathfinding thoroughly. Add `PathfindingModifier` to problem areas. Implement "unstuck" teleport if NPC hasn't moved in X seconds.

### ❌ Audio desync in multiplayer
**Problem:** One player triggers a sound, others don't hear it or hear it late.
**Fix:** Positional audio should be client-side. Story-critical audio (narrator, chapter events) should fire via RemoteEvents to all clients simultaneously.

---

## When This Profile Doesn't Fit

Consider adjustments if:

- **Solo-only experience** — Exploit sensitivity can be lower. Focus more on atmosphere, less on anti-cheat.
- **No chapter structure** — Endless/wave survival uses "runs" session format instead of chapters.
- **Asymmetric multiplayer** — One player is the monster (like Piggy infected mode). Needs different authority model for the hunter player.
- **Heavy story focus** — May need more cutscene infrastructure, dialogue systems, and longer session times.
